import Foundation
import NaturalLanguage

enum TopicExtractor {
  /// Extracts a dominant topic per cluster using c-TF-IDF: rewards terms that are
  /// frequent within a cluster but rare across the rest of the corpus.
  /// Returns an array aligned with `clusters` — `nil` for clusters where no candidate qualifies.
  static func extractTopics(for clusters: [[String]]) -> [String?] {
    guard !clusters.isEmpty else { return [] }

    // Detect dominant language across the whole corpus once.
    let combined = clusters.joined().joined(separator: "\n\n")
    let language = detectLanguage(combined)
    let stopwords = stopwords(for: language)
    let minLen = minLength(for: language)

    // Per-document candidate sets + per-cluster fallback (suspect oblique-RU) tokens.
    var clusterFallbacks: [Set<String>] = Array(repeating: [], count: clusters.count)
    var docCandidates: [[Set<String>]] = clusters.indices.map { ci in
      clusters[ci].map { doc -> Set<String> in
        var fb = Set<String>()
        let terms = candidates(in: doc, language: language, stopwords: stopwords, minLen: minLen, fallbacks: &fb)
        clusterFallbacks[ci].formUnion(fb)
        return Set(terms)
      }
    }

    // Global document frequency across the whole corpus (count each card once).
    var globalDF: [String: Int] = [:]
    var totalDocs = 0
    for cluster in docCandidates {
      for set in cluster {
        totalDocs += 1
        for term in set { globalDF[term, default: 0] += 1 }
      }
    }
    let N = max(totalDocs, 1)

    // For Russian single-token candidates, group by 5-char prefix to merge inflected forms;
    // keep the SHORTEST surface form per group as the canonical label.
    let useLemmaGrouping = language == .russian
    var canonical: [String: String] = [:]    // surface form → canonical (shortest in group)
    if useLemmaGrouping {
      var groups: [String: [String]] = [:]   // prefix → [surface]
      for term in globalDF.keys where !term.contains(" ") && term.count >= 5 {
        let prefix = String(term.prefix(5))
        groups[prefix, default: []].append(term)
      }
      for (_, members) in groups where members.count > 1 {
        let chosen = members.min(by: { (a, b) in
          let sa = nominativeScore(a), sb = nominativeScore(b)
          if sa != sb { return sa > sb }
          return a.count < b.count
        }) ?? members[0]
        for m in members { canonical[m] = chosen }
      }
    }
    let canonicalize: (String) -> String = { useLemmaGrouping ? (canonical[$0] ?? $0) : $0 }

    // Re-fold globalDF by canonical form.
    var foldedGlobalDF: [String: Int] = [:]
    for (term, df) in globalDF {
      foldedGlobalDF[canonicalize(term), default: 0] += df
    }

    // Score each cluster.
    return clusters.indices.map { idx in
      let docs = docCandidates[idx]
      guard !docs.isEmpty else { return nil }
      let fallbacks = clusterFallbacks[idx]

      var clusterDF: [String: Int] = [:]
      for set in docs {
        for term in set {
          clusterDF[canonicalize(term), default: 0] += 1
        }
      }

      let clusterSize = max(docs.count, 1)
      let minDF = max(1, clusterSize / 4)
      var bestKey: String?
      var bestScore: Float = 0
      for (term, df) in clusterDF where df >= minDF {
        let parts = term.split(separator: " ").map(String.init)
        if parts.contains(where: { stopwords.contains($0) }) { continue }
        if language == .russian, parts.contains(where: { isVerbalRussian($0, isAdj: false) }) { continue }
        if parts.count >= 2 {
          let scripts = Set(parts.map { tokenScript($0) }).subtracting([.other])
          if scripts.count > 1 { continue }
        }
        if parts.contains(where: { fallbacks.contains($0) }) { continue }
        let tfc = Float(df) / Float(clusterSize)
        let gdf = foldedGlobalDF[term] ?? df
        let idf = log((Float(N) + 1) / (Float(gdf) + 1)) + 1
        let tokens = term.split(separator: " ").count
        let phraseBonus: Float = 1 + 0.4 * Float(max(tokens - 1, 0))
        let score = tfc * idf * phraseBonus
        if score > bestScore || (score == bestScore && (bestKey.map { term.count > $0.count } ?? true)) {
          bestScore = score
          bestKey = term
        }
      }

      guard let key = bestKey else { return nil }
      return titleCase(key, language: language)
    }
  }

  /// KeyBERT-style topic selection: ranks NP candidates by cosine similarity to the
  /// cluster centroid (mean of card embeddings), with a small bonus for multi-token
  /// phrases. Falls back to `nil` when a cluster has no candidates.
  /// `embed` is called with the deduplicated set of all candidate phrases across
  /// every cluster so the caller can batch a single embedder pass.
  static func extractTopicsSemantic(
    clusters: [[String]],
    clusterVectors: [[[Float]]],
    excludedPhrases: Set<String> = [],
    diversityAnchorVectors: [[Float]] = [],
    diversityWeight: Float = 0.5,
    embed: ([String]) async throws -> [[Float]]
  ) async throws -> [String?] {
    guard !clusters.isEmpty else { return [] }
    precondition(clusters.count == clusterVectors.count, "clusters/vectors length mismatch")

    let combined = clusters.joined().joined(separator: "\n\n")
    let language = detectLanguage(combined)
    let stopwords = stopwords(for: language)
    let minLen = minLength(for: language)

    // Per-cluster candidate sets + suspect-oblique RU fallbacks per cluster.
    var clusterFallbacks: [Set<String>] = Array(repeating: [], count: clusters.count)
    let perClusterDocCandidates: [[Set<String>]] = clusters.indices.map { ci in
      clusters[ci].map { doc -> Set<String> in
        var fb = Set<String>()
        let terms = candidates(in: doc, language: language, stopwords: stopwords, minLen: minLen, fallbacks: &fb)
        clusterFallbacks[ci].formUnion(fb)
        return Set(terms)
      }
    }

    // Collect unique candidate phrases across all clusters for one batched embed.
    var uniquePhrases: [String] = []
    var seen = Set<String>()
    for clusterDocs in perClusterDocCandidates {
      for set in clusterDocs {
        for term in set where !seen.contains(term) {
          seen.insert(term)
          uniquePhrases.append(term)
        }
      }
    }
    guard !uniquePhrases.isEmpty else { return Array(repeating: nil, count: clusters.count) }

    // Batch embed phrases (stride keeps the ONNX session input small).
    var phraseVecs: [String: [Float]] = [:]
    let stride = 64
    var idx = 0
    while idx < uniquePhrases.count {
      let end = min(idx + stride, uniquePhrases.count)
      let chunk = Array(uniquePhrases[idx..<end])
      let vecs = try await embed(chunk)
      for (j, p) in chunk.enumerated() where j < vecs.count {
        phraseVecs[p] = vecs[j]
      }
      idx = end
    }

    var results: [String?] = []
    results.reserveCapacity(clusters.count)
    for (cIdx, docs) in perClusterDocCandidates.enumerated() {
      let vectors = clusterVectors[cIdx]
      guard !docs.isEmpty, !vectors.isEmpty else { results.append(nil); continue }

      // Centroid = normalized mean of card vectors.
      let dim = vectors[0].count
      var centroid = [Float](repeating: 0, count: dim)
      for v in vectors where v.count == dim {
        for h in 0..<dim { centroid[h] += v[h] }
      }
      let inv = 1 / Float(vectors.count)
      for h in 0..<dim { centroid[h] *= inv }
      CosineSimilarity.l2Normalize(&centroid)

      // Aggregate candidate df within cluster.
      var clusterDF: [String: Int] = [:]
      for set in docs {
        for term in set { clusterDF[term, default: 0] += 1 }
      }
      let clusterSize = max(docs.count, 1)
      let minDF = clusterSize >= 5 ? 2 : 1

      let scoreTerm: (String, [Float]) -> Float = { term, pv in
        let cos = CosineSimilarity.cosine(centroid, pv)
        let tokens = term.split(separator: " ").count
        let phraseBonus: Float = 0.15 * Float(max(tokens - 1, 0))
        var anchorPenalty: Float = 0
        if !diversityAnchorVectors.isEmpty {
          var maxAnchor: Float = 0
          for av in diversityAnchorVectors where av.count == pv.count {
            let s = CosineSimilarity.cosine(av, pv)
            if s > maxAnchor { maxAnchor = s }
          }
          anchorPenalty = diversityWeight * maxAnchor
        }
        return cos + phraseBonus - anchorPenalty
      }

      let fallbacks = clusterFallbacks[cIdx]
      func pickBest(filterExcluded: Bool) -> String? {
        var bestKey: String?
        var bestScore: Float = -.infinity
        for (term, df) in clusterDF where df >= minDF {
          guard let pv = phraseVecs[term] else { continue }
          if filterExcluded, isExcluded(term, by: excludedPhrases) { continue }
          let parts = term.split(separator: " ").map(String.init)
          if parts.count >= 2 {
            let scripts = Set(parts.map { tokenScript($0) }).subtracting([.other])
            if scripts.count > 1 { continue }
          }
          if parts.contains(where: { fallbacks.contains($0) }) { continue }
          let score = scoreTerm(term, pv)
          if score > bestScore || (score == bestScore && (bestKey.map { term.count > $0.count } ?? true)) {
            bestScore = score
            bestKey = term
          }
        }
        return bestKey
      }

      let bestKey = pickBest(filterExcluded: !excludedPhrases.isEmpty) ?? pickBest(filterExcluded: false)
      results.append(bestKey.map { titleCase($0, language: language) })
    }
    return results
  }

  // MARK: - Candidate extraction

  enum Script { case cyrillic, latin, other }

  /// Returns the dominant script for letter chars in `s` (first letter wins).
  static func tokenScript(_ s: String) -> Script {
    for ch in s where ch.isLetter {
      if ("а"..."я").contains(ch) || ch == "ё" || ("А"..."Я").contains(ch) || ch == "Ё" { return .cyrillic }
      return .latin
    }
    return .other
  }

  /// Single nouns plus 2–3 token noun-phrases (adj/noun runs) found in `text`.
  /// `fallbacks` accumulates lemmas where NLTagger returned no real lemma — these
  /// are likely oblique RU forms (e.g. "пакета") masquerading as nominative.
  private static func candidates(in text: String, language: NLLanguage, stopwords: Set<String>, minLen: Int, fallbacks: inout Set<String>) -> [String] {
    let tagger = NLTagger(tagSchemes: [.lemma, .lexicalClass])
    tagger.string = text
    if language != .undetermined {
      tagger.setLanguage(language, range: text.startIndex..<text.endIndex)
    }

    struct Token {
      let lemma: String
      let surface: String
      let isNoun: Bool
      let isAdj: Bool
      let isFallback: Bool
    }

    let opts: NLTagger.Options = [.omitWhitespace, .omitPunctuation, .omitOther, .joinNames]
    var sentenceTokens: [[Token]] = []
    var current: [Token] = []

    tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .sentence, scheme: .lexicalClass, options: [.omitWhitespace, .omitPunctuation]) { _, sentenceRange in
      current.removeAll(keepingCapacity: true)
      tagger.enumerateTags(in: sentenceRange, unit: .word, scheme: .lexicalClass, options: opts) { tag, range in
        let isNoun = tag == .noun || tag == .placeName || tag == .organizationName || tag == .personalName
        let isAdj = tag == .adjective
        if !isNoun && !isAdj {
          if !current.isEmpty { sentenceTokens.append(current); current.removeAll(keepingCapacity: true) }
          return true
        }
        let surface = String(text[range]).lowercased()
        let (rawLemma, lemmaTagFound) = lemmatizeWithFlag(tagger: tagger, range: range, original: String(text[range]))
        let lemma = rawLemma.lowercased()
        let isFallback = !lemmaTagFound || lemma == surface
        let scriptHere = tokenScript(lemma)
        // Per-token min length: RU=4, EN=3 — applies whatever the corpus-level language was detected as.
        let perTokenMinLen = scriptHere == .cyrillic ? 4 : 3
        // Always check union of RU+EN stopwords so Russian function-words don't slip through
        // when the corpus was detected as English (mixed code-heavy cards).
        guard lemma.count >= perTokenMinLen,
              !STOPWORDS_RU.contains(lemma), !STOPWORDS_RU.contains(surface),
              !STOPWORDS_EN.contains(lemma), !STOPWORDS_EN.contains(surface),
              lemma.contains(where: { $0.isLetter }) else {
          if !current.isEmpty { sentenceTokens.append(current); current.removeAll(keepingCapacity: true) }
          return true
        }
        // Drop RU verb infinitives / participles regardless of corpus-level language.
        if scriptHere == .cyrillic, isVerbalRussian(lemma, isAdj: isAdj) {
          if !current.isEmpty { sentenceTokens.append(current); current.removeAll(keepingCapacity: true) }
          return true
        }
        // Drop RU oblique singletons (e.g. "финансовой", "управляют") here — never let them into the candidate set.
        if scriptHere == .cyrillic, nominativeScore(lemma) < 0 {
          if !current.isEmpty { sentenceTokens.append(current); current.removeAll(keepingCapacity: true) }
          return true
        }
        // Mark RU tokens that NLTagger failed to lemmatize and end in case-ambiguous suffixes.
        let suspectRU = isFallback && tokenScript(lemma) == .cyrillic
          && lemma.count <= 8
          && ["а","я","у","ю"].contains(String(lemma.last ?? Character(" ")))
        if suspectRU { fallbacks.insert(lemma) }
        current.append(Token(lemma: lemma, surface: surface, isNoun: isNoun, isAdj: isAdj, isFallback: isFallback))
        return true
      }
      if !current.isEmpty { sentenceTokens.append(current); current.removeAll(keepingCapacity: true) }
      return true
    }

    var result: [String] = []
    for run in sentenceTokens {
      for tok in run where tok.isNoun {
        result.append(tok.lemma)
      }
      for i in 0..<(max(run.count - 1, 0)) {
        let a = run[i], b = run[i + 1]
        guard b.isNoun else { continue }
        let sa = tokenScript(a.lemma), sb = tokenScript(b.lemma)
        if sa != .other, sb != .other, sa != sb { continue }
        if (a.isAdj && b.isNoun) || (a.isNoun && b.isNoun) {
          result.append("\(a.lemma) \(b.lemma)")
        }
      }
    }
    return result
  }

  /// Higher = more likely a Russian nominative-case form. Used to pick the
  /// canonical surface form within a prefix-grouped lemma cluster so that
  /// "любовь" beats "любви", "люди" beats "людей".
  private static func nominativeScore(_ word: String) -> Int {
    let obliqueSuffixes = ["ями","ами","ях","ах","ой","ом","ей","ями","ою","ью","ии","ие","ия"]
    for s in obliqueSuffixes where word.hasSuffix(s) && word.count > s.count + 1 {
      return -2
    }
    let obliqueShort = ["и","е","у","ю"]
    if let last = word.last, obliqueShort.contains(String(last)) { return -1 }
    let nominativeShort: Set<Character> = ["ь","а","я","о"]
    if let last = word.last, nominativeShort.contains(last) { return 1 }
    if let last = word.last, last.isLetter,
       !"аеёиоуыэюяйьъ".contains(last) { return 2 }  // ends in consonant
    return 0
  }

  /// Heuristic filter for Russian verb infinitives and short past-participles
  /// that NLTagger mistakenly tags as nouns or adjectives.
  private static func isVerbalRussian(_ word: String, isAdj: Bool) -> Bool {
    if word.hasSuffix("ться") || word.hasSuffix("ть") { return true }
    // Present-tense personal endings — heuristic, only on long enough surface forms
    // to avoid clipping short nouns like "уют" (3) / "приют" (5).
    if word.count >= 7 {
      let presentEndings = ["ют","ут","ят","ат","ишь","ёшь","ешь","ете","ёте","ите","ишь","ём","ем","им"]
      for end in presentEndings where word.hasSuffix(end) { return true }
    }
    // Long-form participles (active & passive): работающий, удаленный, объявленный, абстрактным, написанный...
    let longParticiples = [
      "ющий","ющая","ющее","ющие","ющим","ющей","ющих","ющую",
      "ущий","ущая","ущее","ущие","ущим","ущей","ущих","ущую",
      "ащий","ащая","ащее","ащие","ащим","ащей","ащих","ащую",
      "ящий","ящая","ящее","ящие","ящим","ящей","ящих","ящую",
      "вший","вшая","вшее","вшие","вшим","вшей","вших","вшую",
      "нный","нная","нное","нные","нным","нной","нных","нную",
      "тый","тая","тое","тые","тым","той","тых","тую",
      "емый","емая","емое","емые","имый","имая","имое","имые"
    ]
    for end in longParticiples where word.hasSuffix(end) && word.count > end.count + 1 {
      return true
    }
    if isAdj {
      let shortParticiples = ["ан","ана","ано","аны","ян","яна","яно","яны","ен","ена","ено","ены","т","та","то","ты"]
      for end in shortParticiples where word.hasSuffix(end) && word.count > end.count + 1 {
        return true
      }
    }
    return false
  }

  private static func lemmatize(tagger: NLTagger, range: Range<String.Index>, original: String) -> String {
    lemmatizeWithFlag(tagger: tagger, range: range, original: original).0
  }

  private static func lemmatizeWithFlag(tagger: NLTagger, range: Range<String.Index>, original: String) -> (String, Bool) {
    let (lemmaTag, _) = tagger.tag(at: range.lowerBound, unit: .word, scheme: .lemma)
    if let lemma = lemmaTag?.rawValue, !lemma.isEmpty {
      return (lemma, true)
    }
    return (original, false)
  }

  // MARK: - Language detection

  private static func detectLanguage(_ text: String) -> NLLanguage {
    let recognizer = NLLanguageRecognizer()
    recognizer.processString(text)
    return recognizer.dominantLanguage ?? .undetermined
  }

  private static func minLength(for language: NLLanguage) -> Int {
    switch language {
    case .russian: 4
    case .english: 3
    default: 3
    }
  }

  // MARK: - Title case

  private static func titleCase(_ s: String, language: NLLanguage) -> String {
    s.split(separator: " ").map { word -> String in
      guard let first = word.first else { return String(word) }
      return first.uppercased() + word.dropFirst()
    }.joined(separator: " ")
  }

  // MARK: - Stopwords

  private static func stopwords(for language: NLLanguage) -> Set<String> {
    switch language {
    case .russian: STOPWORDS_RU
    case .english: STOPWORDS_EN
    default: STOPWORDS_EN.union(STOPWORDS_RU)
    }
  }

  /// `term` is excluded if its normalized form equals any excluded phrase
  /// or if the tokens of any excluded phrase are a subset of `term`'s tokens.
  static func isExcluded(_ term: String, by excluded: Set<String>) -> Bool {
    guard !excluded.isEmpty else { return false }
    let normTerm = term.lowercased()
    let termTokens = Set(normTerm.split(separator: " ").map(String.init))
    for phrase in excluded {
      let normPhrase = phrase.lowercased()
      if normTerm == normPhrase { return true }
      let phraseTokens = Set(normPhrase.split(separator: " ").map(String.init))
      if !phraseTokens.isEmpty, phraseTokens.isSubset(of: termTokens) { return true }
    }
    return false
  }
}

private let STOPWORDS_EN: Set<String> = [
  "the","a","an","and","or","but","if","then","else","when","while","of","in","on","at","by","for","to","from","with","about","into","through","during","before","after","above","below","up","down","out","off","over","under","again","further","is","am","are","was","were","be","been","being","have","has","had","having","do","does","did","doing","this","that","these","those","i","you","he","she","it","we","they","them","their","our","my","your","his","her","its","what","which","who","whom","why","how","all","any","both","each","few","more","most","other","some","such","no","nor","not","only","own","same","so","than","too","very","can","will","just","should","now","one","two","three","thing","things","way","ways","time","times","day","days","year","years","people","person","man","men","woman","women","child","children","life","world","place","work","fact","kind","sort","point","case","part","side","end","beginning","matter","reason","result","example","instance","number","amount","level","group","type","form","sense","idea","meaning","value","experience","feeling","important","good","bad","new","old","big","small","high","low","right","wrong"
]

private let STOPWORDS_RU: Set<String> = [
  "и","в","во","не","что","он","она","они","оно","на","я","с","со","как","а","то","все","так","его","но","да","ты","к","у","же","вы","за","бы","по","только","ее","мне","было","вот","от","меня","еще","нет","о","из","ему","теперь","когда","даже","ну","вдруг","ли","если","уже","или","ни","быть","был","него","до","вас","нибудь","опять","уж","вам","ведь","там","потом","себя","ничего","ей","может","тут","где","есть","надо","ней","для","мы","тебя","их","чем","была","сам","чтоб","без","будто","чего","раз","тоже","себе","под","будет","ж","тогда","кто","этот","того","потому","этого","какой","совсем","ним","здесь","этом","один","почти","мой","тем","чтобы","нее","сейчас","были","куда","зачем","всех","никогда","можно","при","наконец","два","об","другой","хоть","после","над","больше","тот","через","эти","нас","про","всего","них","какая","много","разве","три","эту","моя","впрочем","хорошо","свою","этой","перед","иногда","лучше","чуть","нельзя","такой","им","более","всегда","конечно","всю","между","например","словно","вместо","вдруг","точно","примерно","итак","разновидности","предположим","допустим",
  "человек","человека","люди","людей","людях","людьми","год","годы","день","дни","часть","вещь","вещи","способ","способы","место","работа","факт","мир","жизнь","дело","время","момент","сторона","вид","рука","голова","слово","слова","мысль","мысли","мыслью","мыслях","друг","друзья","конец","начало","ребенок","дети","причина","результат","пример","примеры","смысл","значение","опыт","чувство","ощущение","взгляд","точка","зрение","зрения","ситуация","состояние","состояния","состоянии","состоянием","процесс","действие","основа","группа","форма","тип","роль","уровень","количество","число","область","тема","вопрос","ответ","автор","книга","глава","страница","текст","фраза","предложение","новое","старое","большое","маленькое","важное","главное","основной","основное","главный","большой","новый","старый","задача","задачи","элемент","элементы",
  "это","этот","эта","эти","того","тот","та","те","такой","такая","такое","такие","какой","какая","какое","какие","любой","любая","любое","любые","весь","вся","всё","все","сам","сама","само","сами","свой","своя","своё","свои","мой","моя","моё","мои","твой","твоя","твоё","твои","наш","наша","наше","наши","ваш","ваша","ваше","ваши",
  "который","которая","которое","которые","которого","которой","которыми","которым","которых","котором","которому","которую",
  "любви","любовью","любимый","любимая","любимое",
  "исключение","исключения","исключений",
  "знание","знания","знаний","знанием"
]

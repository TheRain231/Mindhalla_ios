import Foundation
import NaturalLanguage

enum TopicExtractor {
  /// KeyBERT-style topic selection: ranks unigram + bigram candidates by cosine
  /// similarity to the cluster centroid. No POS, no lemmatization — semantics
  /// decide. Stopword filtering removes pure noise; mixed-script bigrams are
  /// dropped (a Cyrillic+Latin pair is never a real phrase).
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

    let rawPerCluster: [[Set<String>]] = clusters.map { docs in
      docs.map { Set(candidates(in: $0)) }
    }

    // Corpus-level RU noun folding: group surface forms by 4-char prefix; canonical = consonant-ending if seen,
    // else the shortest form. Folds "класса"/"класс" → "класс", "объекта"/"объект" → "объект".
    var allRussianTokens = Set<String>()
    for cluster in rawPerCluster {
      for set in cluster {
        for term in set {
          for part in term.split(separator: " ") {
            let s = String(part)
            if tokenScript(s) == .cyrillic, s.count >= 4 { allRussianTokens.insert(s) }
          }
        }
      }
    }
    // Fold a surface to its consonant-ending base ONLY when the base also appears in the corpus
    // and the surface is base + a known oblique suffix. Avoids cross-stem collisions like "компоновщик"/"компромисс".
    let obliqueSuffixes = ["а", "я", "у", "ю", "ом", "ой", "ем", "ей", "е", "и", "ами", "ями", "ах", "ях", "ов", "ев", "ью", "ою"]
    var canonical: [String: String] = RU_IRREGULAR_LEMMAS
    for tok in allRussianTokens {
      guard let last = tok.last, "аеёиоуыэюя".contains(last) || tok.hasSuffix("ом") || tok.hasSuffix("ой") || tok.hasSuffix("ем") || tok.hasSuffix("ей") || tok.hasSuffix("ами") || tok.hasSuffix("ями") || tok.hasSuffix("ах") || tok.hasSuffix("ях") || tok.hasSuffix("ов") || tok.hasSuffix("ев") || tok.hasSuffix("ью") || tok.hasSuffix("ою") else { continue }
      for suffix in obliqueSuffixes where tok.hasSuffix(suffix) && tok.count > suffix.count + 2 {
        let base = String(tok.dropLast(suffix.count))
        if allRussianTokens.contains(base),
           let bc = base.last, !"аеёиоуыэюяьъ".contains(bc) {
          canonical[tok] = base
          break
        }
      }
    }
    let fold: (String) -> String = { term in
      term.split(separator: " ")
        .map { canonical[String($0)] ?? String($0) }
        .joined(separator: " ")
    }

    let perClusterDocCandidates: [[Set<String>]] = rawPerCluster.map { cluster in
      cluster.map { Set($0.map { fold($0) }) }
    }

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

      let dim = vectors[0].count
      var centroid = [Float](repeating: 0, count: dim)
      for v in vectors where v.count == dim {
        for h in 0..<dim {
          centroid[h] += v[h]
        }
      }
      let inv = 1 / Float(vectors.count)
      for h in 0..<dim {
        centroid[h] *= inv
      }
      CosineSimilarity.l2Normalize(&centroid)

      var clusterDF: [String: Int] = [:]
      for set in docs {
        for term in set {
          clusterDF[term, default: 0] += 1
        }
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
          let score = scoreTerm(term, pv)
          if score > bestScore || (score == bestScore && (bestKey.map { term.count > $0.count } ?? true)) {
            bestScore = score
            bestKey = term
          }
        }
        return bestKey
      }

      let bestKey = pickBest(filterExcluded: !excludedPhrases.isEmpty) ?? pickBest(filterExcluded: false)
      results.append(bestKey.map { titleCase($0) })
    }
    return results
  }

  // MARK: - Candidate extraction

  enum Script { case cyrillic, latin, other }

  static func tokenScript(_ s: String) -> Script {
    for ch in s where ch.isLetter {
      if ("а"..."я").contains(ch) || ch == "ё" || ("А"..."Я").contains(ch) || ch == "Ё" { return .cyrillic }
      return .latin
    }
    return .other
  }

  private struct PosToken { let surface: String; let isNoun: Bool; let isAdj: Bool }

  /// Noun unigrams + (adj+noun | noun+noun) bigrams, same script, no verbs, no stopwords.
  /// For Russian: lemmatizes via NLTagger, rejects oblique-case singletons, and reclassifies
  /// adj-shaped surfaces that NLTagger mistakenly tags as nouns.
  private static func candidates(in text: String) -> [String] {
    let tagger = NLTagger(tagSchemes: [.lexicalClass, .lemma])
    tagger.string = text
    let opts: NLTagger.Options = [.omitWhitespace, .omitPunctuation, .omitOther, .joinNames]

    var runs: [[PosToken]] = []
    var current: [PosToken] = []
    let flush = {
      if !current.isEmpty { runs.append(current); current.removeAll(keepingCapacity: true) }
    }

    let recognizer = NLLanguageRecognizer()
    recognizer.processString(text)
    if let lang = recognizer.dominantLanguage {
      tagger.setLanguage(lang, range: text.startIndex..<text.endIndex)
    }

    tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word, scheme: .lexicalClass, options: opts) { tag, range in
      let raw = String(text[range]).lowercased()
      var isNoun = tag == .noun || tag == .placeName || tag == .organizationName || tag == .personalName
      var isAdj = tag == .adjective
      let isVerb = tag == .verb
      let isCyrillic = tokenScript(raw) == .cyrillic
      // Surface-level verb check — runs before POS so NLTagger's noun-mis-tags don't slip through.
      if isCyrillic, looksVerbalRussian(raw) { flush(); return true }
      guard isNoun || isAdj, !isVerb else { flush(); return true }
      var surface = raw
      if isCyrillic, let lemma = tagger.tag(at: range.lowerBound, unit: .word, scheme: .lemma).0?.rawValue, !lemma.isEmpty {
        surface = lemma.lowercased()
      }
      if isCyrillic, looksVerbalRussian(surface) { flush(); return true }
      if isCyrillic, isNoun, looksAdjectiveRussian(surface) { isNoun = false; isAdj = true }
      if isCyrillic, isObliqueRussian(surface) { flush(); return true }
      guard isAcceptableToken(surface) else { flush(); return true }
      current.append(PosToken(surface: surface, isNoun: isNoun, isAdj: isAdj))
      return true
    }
    flush()

    var out: [String] = []
    for run in runs {
      for tok in run where tok.isNoun {
        out.append(tok.surface)
      }
      if run.count >= 2 {
        for i in 0..<(run.count - 1) {
          let a = run[i], b = run[i + 1]
          guard b.isNoun else { continue }
          guard a.isAdj || a.isNoun else { continue }
          let sa = tokenScript(a.surface), sb = tokenScript(b.surface)
          if sa != .other, sb != .other, sa != sb { continue }
          let aSurface: String
          if a.isAdj, sa == .cyrillic, sb == .cyrillic {
            aSurface = agreeRussianAdjective(a.surface, with: b.surface)
          } else {
            aSurface = a.surface
          }
          out.append("\(aSurface) \(b.surface)")
        }
      }
    }
    return out
  }

  private static func isAcceptableToken(_ t: String) -> Bool {
    guard t.count >= 3 else { return false }
    if STOPWORDS_EN.contains(t) || STOPWORDS_RU.contains(t) { return false }
    if EN_VERBS.contains(t) { return false }
    if !t.contains(where: \.isLetter) { return false }
    // English -ing / -ed forms (gerunds, participles) — block when long enough to avoid "ring", "thing".
    if tokenScript(t) == .latin, t.count >= 6 {
      if t.hasSuffix("ing") || t.hasSuffix("ed") { return false }
    }
    return true
  }

  // MARK: - Adjective–noun agreement (Russian)

  private enum RussianGender { case masculine, feminine, neuter }

  /// Грубая эвристика рода по окончанию существительного в начальной форме (после лемматизации).
  /// Покрывает основной случай: -а/-я → ж, -о/-е/-ё → ср, остальное → м.
  /// Слова на -ь (день/ночь) считаем мужскими — без словаря не различить.
  private static func russianNounGender(_ noun: String) -> RussianGender {
    guard let last = noun.last else { return .masculine }
    switch last {
    case "а", "я": return .feminine
    case "о", "е", "ё": return .neuter
    default: return .masculine
    }
  }

  /// Меняет окончание прилагательного м.р. на согласованное с родом существительного.
  /// Лемма NLTagger всегда даёт м.р. им.п. (-ый/-ий/-ой), что после склейки с леммой
  /// существительного даёт нелепые "математический статистика". Корректируем:
  ///   математический + статистика → математическая статистика
  ///   арестантский   + дело        → арестантское дело
  ///   синий          + море        → синее море
  private static func agreeRussianAdjective(_ adj: String, with noun: String) -> String {
    let gender = russianNounGender(noun)
    guard gender != .masculine else { return adj }

    func replaceSuffix(_ old: String, with new: String) -> String? {
      guard adj.hasSuffix(old), adj.count > old.count else { return nil }
      return String(adj.dropLast(old.count)) + new
    }

    // -ой (молодой, дорогой) — всегда hard stem: молодой → молодая/молодое.
    if let r = replaceSuffix("ой", with: gender == .feminine ? "ая" : "ое") { return r }
    // -ый — hard stem: новый → новая/новое.
    if let r = replaceSuffix("ый", with: gender == .feminine ? "ая" : "ое") { return r }
    // -ий — три варианта в зависимости от предпоследнего согласного:
    //   • шипящие (ж/ш/ч/щ) и ц: ж.р. -ая, ср.р. -ее (правило «о/е после шипящих»
    //     в безударной позиции: хороший → хорошее, общий → общее, рыжий → рыжее).
    //     Ударные исключения типа «большой» идут через -ой и обрабатываются выше.
    //   • hard velar (г/к/х): ж.р. -ая, ср.р. -ое (русский → русское, тихий → тихое).
    //   • soft stem (остальные согласные): ж.р. -яя, ср.р. -ее (синий → синее, средний → среднее).
    if adj.hasSuffix("ий"), adj.count > 2 {
      let beforeIy = adj.dropLast(2).last
      let stem = String(adj.dropLast(2))
      if let bl = beforeIy {
        if "жшчщц".contains(bl) {
          return stem + (gender == .feminine ? "ая" : "ее")
        }
        if "гкх".contains(bl) {
          return stem + (gender == .feminine ? "ая" : "ое")
        }
      }
      return stem + (gender == .feminine ? "яя" : "ее")
    }
    return adj
  }

  /// Detects Russian adjective surface endings — used to reclassify tokens NLTagger mis-tags as nouns.
  private static func looksAdjectiveRussian(_ word: String) -> Bool {
    guard word.count >= 4 else { return false }
    let endings = [
      "ыми", "ими", "ого", "его", "ому", "ему", "ую", "юю",
      "ый", "ий", "ой", "ая", "яя", "ое", "ее", "ые", "ие",
      "ым", "им", "ых", "их",
    ]
    for end in endings where word.hasSuffix(end) && word.count > end.count + 1 {
      return true
    }
    return false
  }

  /// True for clearly-oblique Russian noun surfaces (genitive/dative/instrumental/locative).
  /// Conservative: only flags unambiguous oblique suffixes so nominative forms like "книга", "вода", "поле" pass.
  private static func isObliqueRussian(_ word: String) -> Bool {
    guard word.count >= 4 else { return false }
    let strongOblique = [
      "ями", "ами", "ях", "ах", "ой", "ом", "ей", "ою", "ью",
      "ии", "иям", "иях", "иями", "ев", "ов",
    ]
    for end in strongOblique where word.hasSuffix(end) && word.count > end.count + 1 {
      return true
    }
    // Short oblique vowels: -и, -е, -у, -ю at the end (genitive sg, dative/locative, accusative fem).
    // Excludes -ия/-ие which can be nominative neuter (e.g. "решение") — handled above.
    if let last = word.last, ["и", "е", "у", "ю"].contains(String(last)) { return true }
    return false
  }

  /// Backup verb detector for Russian — NLTagger sometimes tags conjugated forms as nouns.
  private static func looksVerbalRussian(_ word: String) -> Bool {
    if word.hasSuffix("ться") || word.hasSuffix("ть") { return true }
    let reflexive = ["ются", "ятся", "ится", "ется", "ётся", "ишься", "ешься", "ёшься", "лся", "лась", "лось", "лись"]
    for end in reflexive where word.hasSuffix(end) && word.count > end.count {
      return true
    }
    // Gerunds (деепричастия): "увеличивая", "делая", "читая", "сделав", "уйдя".
    let gerunds = ["вая", "ивая", "ывая", "уя", "юя", "вши", "вшись", "ючи", "учи"]
    for end in gerunds where word.hasSuffix(end) && word.count > end.count + 1 {
      return true
    }
    guard word.count >= 5 else { return false }
    let present = [
      "ишь",
      "ёшь",
      "ешь",
      "ете",
      "ёте",
      "ите",
      "ают",
      "яют",
      "уют",
      "юют",
      "ует",
      "ьет",
      "ют",
      "ут",
      "ят",
      "ат",
      "ит",
      "ет",
      "ёт",
      "ем",
      "им",
      "ём",
    ]
    for end in present where word.hasSuffix(end) {
      return true
    }
    let past = ["ал", "ял", "ел", "ил", "ыл", "ул"]
    for end in past where word.hasSuffix(end) {
      return true
    }
    return false
  }

  // MARK: - Title case

  private static func titleCase(_ s: String) -> String {
    s.split(separator: " ").map { word -> String in
      guard let first = word.first else { return String(word) }
      return first.uppercased() + word.dropFirst()
    }.joined(separator: " ")
  }

  // MARK: - Exclusion

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

/// Irregular Russian forms that NLTagger fails to lemmatize and that don't follow the simple
/// "stem + oblique suffix" pattern (mostly pluralia tantum and stem-mutation cases).
private let RU_IRREGULAR_LEMMAS: [String: String] = [
  "денег": "деньги",
  "деньгам": "деньги",
  "деньгами": "деньги",
  "деньгах": "деньги",
  "людей": "люди",
  "людям": "люди",
  "людьми": "люди",
  "людях": "люди",
  "детей": "дети",
  "детям": "дети",
  "детьми": "дети",
  "детях": "дети",
]

private let EN_VERBS: Set<String> = [
  "consists", "contains", "computes", "depends", "shows", "means", "represents", "generates", "increases", "decreases",
  "includes", "provides", "returns", "creates", "makes", "gives", "takes", "sends", "receives", "calls", "sets", "gets",
  "adds", "removes", "deletes", "updates", "reads", "writes", "stores", "loads", "initializes", "destroys", "starts", "stops",
  "uses", "using", "builds", "runs", "handles", "performs", "executes", "accepts", "rejects", "emits", "fires", "triggers",
  "subscribes", "publishes", "wraps", "unwraps", "maps", "filters", "reduces", "collects", "produces", "consumes",
]

private let STOPWORDS_EN: Set<String> = [
  "the", "a", "an", "and", "or", "but", "if", "then", "else", "when", "while", "of", "in", "on", "at", "by", "for", "to", "from", "with", "about", "into", "through", "during", "before", "after", "above", "below", "up", "down", "out", "off", "over", "under", "again", "further", "is", "am", "are", "was", "were", "be", "been", "being", "have", "has", "had", "having", "do", "does", "did", "doing", "this", "that", "these", "those", "i", "you", "he", "she", "it", "we", "they", "them", "their", "our", "my", "your", "his", "her", "its", "what", "which", "who", "whom", "why", "how", "all", "any", "both", "each", "few", "more", "most", "other", "some", "such", "no", "nor", "not", "only", "own", "same", "so", "than", "too", "very", "can", "will", "just", "should", "now", "one", "two", "three", "thing", "things", "way", "ways", "time", "times", "day", "days", "year", "years", "people", "person", "man", "men", "woman", "women", "child", "children", "life", "world", "place", "work", "fact", "kind", "sort", "point", "case", "part", "side", "end", "beginning", "matter", "reason", "result", "example", "instance", "number", "amount", "level", "group", "type", "form", "sense", "idea", "meaning", "value", "experience", "feeling", "important", "good", "bad", "new", "old", "big", "small", "high", "low", "right", "wrong",
]

private let STOPWORDS_RU: Set<String> = [
  "и", "в", "во", "не", "что", "он", "она", "они", "оно", "на", "я", "с", "со", "как", "а", "то", "все", "так", "его", "но", "да", "ты", "к", "у", "же", "вы", "за", "бы", "по", "только", "ее", "мне", "было", "вот", "от", "меня", "еще", "нет", "о", "из", "ему", "теперь", "когда", "даже", "ну", "вдруг", "ли", "если", "уже", "или", "ни", "быть", "был", "него", "до", "вас", "нибудь", "опять", "уж", "вам", "ведь", "там", "потом", "себя", "ничего", "ей", "может", "тут", "где", "есть", "надо", "ней", "для", "мы", "тебя", "их", "чем", "была", "сам", "чтоб", "без", "будто", "чего", "раз", "тоже", "себе", "под", "будет", "ж", "тогда", "кто", "этот", "того", "потому", "этого", "какой", "совсем", "ним", "здесь", "этом", "один", "почти", "мой", "тем", "чтобы", "нее", "сейчас", "были", "куда", "зачем", "всех", "никогда", "можно", "при", "наконец", "два", "об", "другой", "хоть", "после", "над", "больше", "тот", "через", "эти", "нас", "про", "всего", "них", "какая", "много", "разве", "три", "эту", "моя", "впрочем", "хорошо", "свою", "этой", "перед", "иногда", "лучше", "чуть", "нельзя", "такой", "им", "более", "всегда", "конечно", "всю", "между", "например", "словно", "вместо", "вдруг", "точно", "примерно", "итак", "разновидности", "предположим", "допустим",
  "это", "этот", "эта", "эти", "того", "тот", "та", "те", "такой", "такая", "такое", "такие", "какой", "какая", "какое", "какие", "любой", "любая", "любое", "любые", "весь", "вся", "всё", "все", "сам", "сама", "само", "сами", "свой", "своя", "своё", "свои", "мой", "моя", "моё", "мои", "твой", "твоя", "твоё", "твои", "наш", "наша", "наше", "наши", "ваш", "ваша", "ваше", "ваши",
  "который", "которая", "которое", "которые", "которого", "которой", "которыми", "которым", "которых", "котором", "которому", "которую",
]

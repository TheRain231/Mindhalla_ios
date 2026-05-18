# Synapps iOS

## Описание проекта

Synapps — мобильное приложение для iOS, предназначенное для работы с книгами и сохраненными идеями. Пользователь может загружать книги в форматах PDF, EPUB и FB2, получать с сервера обработанные карточки, изучать материалы в карточном формате, проходить задания по книге, сохранять важные цитаты и идеи в коллекции, а также просматривать майнд-карты по сохраненным карточкам.

Приложение реализовано на Swift и SwiftUI, использует SwiftData для локального хранения, URLSession для сетевого слоя, локальную ONNX-модель для embeddings и App Groups для обмена данными между основным приложением, виджетом и share extension.

## Структура проекта

- **Основное приложение Synapps**:
  - Реализовано на SwiftUI.
  - Основная навигация построена через `TabView`: книги, сохраненные материалы, майнд-карты и профиль.
  - Используется фабрика `ViewModelFactory` для сборки зависимостей экранов.

- **Модуль загрузки и обработки книг**:
  - Поддерживает импорт файлов PDF, EPUB и FB2 через системный file importer.
  - Загружает книги на backend через multipart-запрос `POST /api/v1/uploads`.
  - Синхронизирует список книг и статусы обработки через периодический polling.
  - Сохраняет pending uploads из share extension и догружает их при запуске приложения.

- **Модуль карточек и обучения**:
  - Получает детальную информацию о книге через `GET /api/v1/books/{id}`.
  - Отображает карточки в swipe-интерфейсе.
  - Позволяет сохранять карточки в коллекции.
  - Поддерживает задания по книге через `GET /api/v1/books/{bookId}/tasks`.

- **Модуль сохраненных материалов**:
  - Использует SwiftData для локального хранения карточек, коллекций, книг и заданий.
  - Поддерживает просмотр сохраненных цитат и карточек по коллекциям.
  - Реализует экспорт и импорт данных в собственном формате `.synapps`.

- **Модуль майнд-карт и автотегирования**:
  - Строит тематические карты по сохраненным карточкам.
  - Использует локальные embeddings на базе `distiluse-base-multilingual-cased-v2`, экспортированной в ONNX.
  - Выполняет кластеризацию карточек и группировку по темам.

- **Модуль авторизации**:
  - Выполняет автоматический login по устройству через `POST /api/v1/auth/login`.
  - Хранит access и refresh токены в Keychain.
  - Автоматически обновляет access token через `POST /api/v1/auth/refresh`.
  - Повторяет login при истечении refresh token.

- **Сетевой слой**:
  - Построен поверх URLSession.
  - Разделен на `APIService`, `AuthenticatedAPIService`, `Client` и `NetworkManager`.
  - Поддерживает авторизованные запросы и обработку ошибок токенов.
  - DTO генерируются из `openapi.json` скриптом `scripts/generate_dto_from_openapi.py`.

- **Widget Extension**:
  - Цель `QuotesWidgetExtension`.
  - Показывает сохраненные цитаты и данные из общего SwiftData-хранилища.
  - Использует App Group для доступа к данным основного приложения.

- **Share Extension**:
  - Цель `SynappsShareExtension`.
  - Позволяет отправлять книги в Synapps из системного share sheet.
  - Сохраняет файлы как pending uploads для последующей обработки основным приложением.

## Технологический стек

- iOS SDK 17+
- Swift, SwiftUI
- SwiftData
- WidgetKit
- App Groups
- Keychain
- URLSession
- ONNX Runtime
- Hugging Face Swift Transformers / Tokenizers
- Lottie
- Kingfisher
- AnyCodable
- Atlantis для debug-сетевого мониторинга
- XcodeGen (`project.yml`)

## Локальная ML-модель

Для работы локальных embeddings необходимо скачать модель `distiluse-multilingual.onnx` и положить ее в директорию:

```text
Synapps/Resources/MLModels/Distiluse/
```

В этой же директории уже находятся файлы tokenizer/config. Ссылка на модель:

```text
https://drive.google.com/drive/u/0/folders/1BfoM9ta1k9NwYKQ9_Rs7AENGProgbiA1
```

Ожидаемая структура:

```text
Synapps/Resources/MLModels/Distiluse/
├── distiluse-multilingual.onnx
├── tokenizer.json
├── tokenizer_config.json
├── special_tokens_map.json
├── config.json
└── vocab.txt
```

## Генерация проекта

Проект описан в `project.yml`. При необходимости `.xcodeproj` можно пересоздать через XcodeGen:

```bash
xcodegen generate
```

После генерации откройте:

```text
Synapps.xcodeproj
```

## Генерация DTO из OpenAPI

DTO-модели генерируются из `openapi.json`:

```bash
python3 scripts/generate_dto_from_openapi.py
```

По умолчанию скрипт обновляет файл:

```text
Synapps/Models/DTO.swift
```

## Backend

Базовый URL backend задан в:

```text
Synapps/Fundamentals/Constants.swift
```

Текущие основные API-сценарии:

- `POST /api/v1/auth/login` — авторизация устройства.
- `POST /api/v1/auth/refresh` — обновление токенов.
- `GET /api/v1/books` — получение списка книг.
- `GET /api/v1/books/{id}` — получение книги с карточками.
- `GET /api/v1/books/{bookId}/tasks` — получение заданий по книге.
- `POST /api/v1/uploads` — загрузка книги.

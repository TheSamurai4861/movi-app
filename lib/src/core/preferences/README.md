## Core Preferences

Local persisted preferences with change notifications.

### Scope / Clean Architecture

These classes are **infrastructure**: they depend on Flutter types and on `flutter_secure_storage`.
Do not import them from `domain/`. Access them via DI + controllers/usecases.

### Streams

All preference streams are **broadcast** and emit **only changes**.
If you need an initial value on subscription, use the `*StreamWithInitial()` helpers.

### Language codes

- `LocalePreferences.languageCode` stores a locale tag as provided (e.g. `en-US`).
- `PlayerPreferences` stores **base language** codes (`en`, `fr`, ...) because media track
  selection is usually language-based; it intentionally strips region/script subtags.


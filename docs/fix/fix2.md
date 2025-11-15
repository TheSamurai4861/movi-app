Globalement ton plan **respecte bien la Clean Architecture telle que tu l’appliques dans Movi** 👍
Mais il y a 2–3 points à cadrer pour être sûr que ça ne fuit pas entre les couches.

Je te fais ça en mode rapide :

---

## 1. Ce qui est clean dans ton plan ✅

### a) UI / présentation

* Tout ce qui est :

  * `MaterialApp` + `localizationsDelegates` + `supportedLocales`
  * `locale` liée à `AppState.preferredLocale`
  * remplacement des chaînes par `AppLocalizations.of(context)...`

→ Ça reste **strictement dans `presentation`** (ou `app.dart/main.dart`), donc c’est parfait pour la Clean Architecture.

### b) Persistance de la langue

* `LocalePreferences` dans `core/preferences`
* `AppStateController` dans `core/state` qui écoute `LocalePreferences.languageStream` et met à jour `AppState.preferredLocale`.

→ Ça ressemble à une **couche application/core** qui orchestre, sans mélanger avec le `domain/*.dart` des features. Pour ton projet, c’est cohérent et propre.

### c) Données TMDB & cache

* Suffixer les clés cache avec la langue :
  `tmdb_movie_detail_${id}_${lang}`, `tmdb_tv_detail_${id}_${lang}` → **logique purement data**, très bien.
* Le fallback `en-US` géré côté TMDB (remote data source / repository impl) → ça reste dans **`data`**, et le `domain` voit juste des entités déjà “résolues”.

Tout ça respecte bien le schéma :

**presentation → core/application → domain → data**
et **jamais l’inverse**.

---

## 2. Les points à surveiller ⚠️

Les petites zones grises sont ici :

### 2.1. `currentLanguageCodeProvider` et TMDB

Tu écris :

> * Créer un provider `currentLanguageCodeProvider` (String) lisant `AppState.preferredLocale`.
> * Propager `language: ref.watch(currentLanguageCodeProvider)` vers les appels :
>
>   * `TmdbMovieRemoteDataSource...`
>   * `TmdbTvRemoteDataSource...`

Ça peut rester clean **à une seule condition** :

* ✅ Le `ref.watch(currentLanguageCodeProvider)` est utilisé **uniquement dans la couche présentation / providers** (ex. `home_providers.dart`, `movie_providers.dart`, etc.)
* ✅ Et tu passes ensuite `languageCode` **en paramètre** à ton **use case** ou à ton **repository**.

En revanche, il ne faut PAS que :

* un `RemoteDataSource` (`tmdb_movie_remote_data_source.dart`, `tmdb_tv_remote_data_source.dart`) importe Riverpod,
* ni qu’il aille lire un provider pour connaître la langue.

👉 **Règle :**

* `RemoteDataSource` ne dépend que de : `Dio/TmdbClient` + primitives (`String languageCode`, `int id`, etc.)
* Riverpod reste limité à `presentation` et éventuellement `core/state`.

### 2.2. Mention “(domain/data)” dans l’étape 3

> 3. Persistance et diffusion (domain/data)

En réalité, dans ton plan, ce qui se passe vraiment :

* `LocalePreferences` → **infra / data (core/preferences)**
* `AppStateController` → **application/core**
* `domain` (dans `features/.../domain`) ne devrait **rien savoir** de `LocalePreferences` ni de `AppStateController`.

Donc c’est plus juste de dire :

* **Persistance** : data/infra (`LocalePreferences`)
* **Diffusion** : application/core (`AppStateController` + Riverpod providers)

Le **domain** reste **muet sur le mécanisme de persistance de la langue**. Il ne connaît que des `LanguageCode`, éventuellement via `settings/domain/value_objects/language_code.dart` (que tu as déjà).

---

## 3. Variante “ultra clean” (optionnelle, plus tard)

Si tu veux pousser le truc au max :

1. Utiliser `LanguageCode` du module `settings/domain/value_objects/language_code.dart` comme type central.
2. Créer un petit service de domaine (ou d’application) du style :

```dart
// domain/shared/services/metadata_locale_service.dart (ou similaire)
class MetadataLocaleService {
  final UserSettingsRepository _settingsRepository;

  MetadataLocaleService(this._settingsRepository);

  LanguageCode resolveMetadataLanguage() {
    final preferred = _settingsRepository.getPreferredMetadataLanguage();
    // ici tu mets la logique de fallback (en-US si vide, etc.)
    return preferred;
  }
}
```

3. Dans un use case :

```dart
class GetMovieDetail {
  final MovieRepository _movieRepository;
  final MetadataLocaleService _metadataLocaleService;

  GetMovieDetail(this._movieRepository, this._metadataLocaleService);

  Future<Movie> call(MediaId id) async {
    final lang = _metadataLocaleService.resolveMetadataLanguage();
    return _movieRepository.getMovieDetail(id, lang);
  }
}
```

4. Côté `data` :

```dart
class MovieRepositoryImpl implements MovieRepository {
  final TmdbMovieRemoteDataSource _remote;
  final TmdbCacheDataSource _cache;

  @override
  Future<Movie> getMovieDetail(MediaId id, LanguageCode lang) async {
    final key = 'tmdb_movie_detail_${id.value}_${lang.code}';
    // cache + remote en utilisant lang.code
  }
}
```

👉 Avec ça, **tout le jeu de fallback et de langue est derrière des abstractions domain/app**, et la présentation ne fait que déclencher les use cases.

Mais ce n’est pas obligatoire pour ton MVP : ton plan actuel peut déjà rester clean si tu gères bien les dépendances.

---

## 4. Verdict

🟢 **Oui, ton plan est compatible avec ta Clean Architecture actuelle**, à condition de respecter ces règles concrètes :

1. **Aucun `feature/*/domain` n’importe :**

   * `flutter_riverpod`, `flutter`, `dio`, TMDB, `LocalePreferences`, etc.
2. **Les `RemoteDataSource` ne voient jamais Riverpod ni AppState** : ils reçoivent des `String languageCode` en argument.
3. **Les providers Riverpod (`currentLocaleProvider`, `currentLanguageCodeProvider`) restent dans `presentation` ou à la rigueur `core/state`, jamais dans `data` ni `domain`.
4. **Le fallback de langue** est implémenté en **data (repository / remote)** ou en **service d’application/domain**, mais pas en UI.

Si tu veux, au prochain message, tu peux me montrer **un exemple concret de provider + use case + repo** pour `getMovieDetail` avec la langue, et je te le réécris en version “ultra clean” adaptée à ton projet.

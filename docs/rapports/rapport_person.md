# Rapport d’analyse — `src/features/person`

> Plan d’implémentation associé: `docs/steps/person_feature_impl_plan.md`

## Checklist d’exécution (référence rapide)
- [ ] Unifier la DI via Providers Riverpod (sans `slProvider` en présentation)
- [ ] Découper `PersonDetailPage` en sous-widgets (hero, actions, bio, filmographie)
- [ ] Déplacer `PersonDetailViewModel` dans `presentation/models`
- [ ] Corriger i18n (ajouter clés, remplacer chaînes en dur) et error handling
- [ ] Clarifier/améliorer `GetFeaturedPeople` (popular TMDB ou liste curatée)
- [ ] Polishing (const, espacements, layout biographie) + tests ciblés

---

## 1. Résumé global (vue d’ensemble)

Le dossier `features/person` est globalement **propre et bien structuré**, dans la continuité de la feature `movie` :

- Séparation claire entre **Data / Domain / Presentation**.
- Domain pur (entités, repo, use cases) **sans dépendance à Flutter**.
- Data layer bien isolé avec **remote + cache local** dépendant de la locale. :contentReference[oaicite:0]{index=0}  
- `PersonDetailPage` propose une UX complète (hero, biographie, filmographie IPTV, favoris) sans logique métier “sale” dans les widgets.
- Les providers Riverpod jouent bien leur rôle d’orchestrateurs.

Les principaux points qui manquent pour atteindre un niveau “vraiment pro” :

- **Mix DI service locator + Riverpod** dans la couche présentation (person detail + favoris).
- **Widget de détail assez massif** (hero + CTA + biographie + listes) dans une seule classe.
- Quelques **problèmes d’i18n et d’error handling** (strings en dur, affichage brut des erreurs).
- Un use case “featured” encore très **placeholder** côté repository.

---

## 2. Architecture & organisation

### 2.1 Rôle du dossier

La feature `person` gère tout ce qui touche à une **personnalité TMDB** (acteur, réalisateur, etc.) :

- Récupération/caching des détails (bio, dates, rôles, filmographie).
- Filmographie filtrée sur le **catalogue IPTV disponible**.
- Page de détail : hero, stats, biographie, listes de films/séries jouables.
- Gestion des **favoris** pour les personnes.

### 2.2 Structure et responsabilités

- `person.dart`  
  → Fichier *barrel* qui ré-exporte entités, repo, use cases et DTO principal.

- `data/`
  - `datasources/person_local_data_source.dart`  
    → Cache local par personne + par langue (`person_detail_<locale>_<id>`), TTL 3 jours. :contentReference[oaicite:1]{index=1}
  - `datasources/tmdb_person_remote_data_source.dart`  
    → Appels TMDB (fiche + `combined_credits`), parsing en `TmdbPersonDetailDto`. :contentReference[oaicite:2]{index=2}
  - `dtos/tmdb_person_detail_dto.dart`  
    → DTO complet (fiche + credits), logique de fusion cast/crew, extraction de rôles, (dé)serialisation pour le cache.
  - `repositories/person_repository_impl.dart`  
    → Implémentation concrète de `PersonRepository` (mapping DTO → Domain, filtrage de filmographie, recherche, featured). :contentReference[oaicite:3]{index=3}
  - `person_data_module.dart`  
    → Enregistre `TmdbPersonRemoteDataSource`, `PersonLocalDataSource` et `PersonRepository` dans le service locator.

- `domain/`
  - `entities/person.dart`  
    → `Person` + `PersonCredit`, entités immuables `Equatable`.
  - `repositories/person_repository.dart`  
    → Contrat Domain.
  - `usecases/*`  
    → `GetPersonDetail`, `GetPersonFilmography`, `SearchPeople`, `GetFeaturedPeople`, chacun mono-responsabilité.

- `presentation/`
  - `pages/person_detail_page.dart`  
    → Page UI : auto-refresh, gestion loading/erreur, hero, CTA, biographie, listes filmographie. :contentReference[oaicite:4]{index=4}
  - `providers/person_detail_providers.dart`  
    → Providers pour favoris, détail personne filtré par IPTV, et `PersonDetailViewModel`.

### 2.3 Architecture & dépendances

- **Domain ne dépend pas de Flutter** → ✅
- **Data dépend de services infra (TmdbClient, CacheRepository, LocalePreferences)** → ✅
- **Presentation dépend de Domain + Data via DI (sl + Riverpod)** → ✅ mais avec mélange de patterns.

**Sens des dépendances globalement respecté**, mais :

- `person_detail_controller_provider` va chercher `PersonRepository` et `IptvLocalRepository` via `slProvider`, donc la couche présentation dépend directement de `sl` pour récupérer des repos d’autres features (person + iptv). :contentReference[oaicite:5]{index=5}  
- Il n’y a pas de dépendance circulaire évidente, mais la frontière “feature person / feature iptv” est un peu floue dans ce provider.

---

## 3. Problèmes identifiés (classés par sévérité)

### 3.1 Critique

**Aucun problème vraiment “bloquant”/structurel de niveau critique** (type dépendances circulaires, logique métier noyée partout, architecture complètement cassée).  
Les points suivants sont importants mais restent corrigibles sans tout casser.

---

### 3.2 Important

#### 3.2.1 Mix DI service locator + Riverpod dans la même feature

- **Fichiers concernés**  
  - `data/person_data_module.dart`  
  - `presentation/providers/person_detail_providers.dart`

- **Problème**  
  - Les repos/datasources sont enregistrés dans le service locator global (`sl`) côté `PersonDataModule`. :contentReference[oaicite:6]{index=6}  
  - En présentation, les providers lisent **à nouveau** dans `sl` via `slProvider` :
    - `personDetailControllerProvider` : `locator<PersonRepository>()`, `locator<IptvLocalRepository>()`.
    - `personToggleFavoriteProvider` : `ref.read(slProvider)<PersonRepository>()`, `WatchlistLocalRepository`, etc.
  - Du coup, la source de vérité pour les dépendances est un peu ambivalente :  
    - le code “prétend” utiliser Riverpod, mais continue à faire de la DI globale via `sl`.

- **Pourquoi c’est un problème**
  - **Lisibilité** : difficile pour un nouveau dev de comprendre “où” est réellement instancié un `PersonRepository`.
  - **Testabilité** : on doit parfois mocker `sl` **et** override des providers Riverpod.
  - **Évolutivité** : introduire de nouveaux environnements/configs devient plus complexe.

- **Suggestion de correction**
  - Choisir une stratégie claire :
    - **Option A (recommandée)** : tout faire passer par des providers :
      - Provider pour `TmdbPersonRemoteDataSource`, `PersonLocalDataSource`, `PersonRepository`, `IptvLocalRepository`, etc.
      - `PersonDataModule` devient optionnel (ou limité aux parties hors Riverpod).
    - **Option B** : considérer `sl` comme source unique, et exposer juste :
      ```dart
      final personRepositoryProvider = Provider<PersonRepository>(
        (ref) => sl<PersonRepository>(),
      );
      ```
  - L’important : **ne pas reconstruire les mêmes services deux fois avec des chemins différents**.

---

#### 3.2.2 `PersonDetailPage` + `_PersonDetailContent` : widget “multi-responsabilités”

- **Fichier / éléments**  
  - `presentation/pages/person_detail_page.dart`  
  - Classes `PersonDetailPage`, `_PersonDetailPageState`, `_PersonDetailContent`, `_PersonDetailContentState`.

- **Problème**
  - `PersonDetailPage` gère :
    - récupération de `PersonSummary` depuis `widget` ou `GoRouter extra`,
    - gestion d’un **timer d’auto-refresh** + stratégie de retry en cas de loading trop long ou d’erreur, :contentReference[oaicite:7]{index=7}
    - affichage loading / erreur / data.
  - `_PersonDetailContent` gère dans un seul widget :
    - hero image + gradients + header back,
    - titres, stats (films/séries), CTA “lecture aléatoire”,
    - button favoris avec provider dédié,
    - biographie avec logique d’expansion + TextPainter,
    - listes de films et séries IPTV (cards + navigation).
  - Le tout dans **un seul gros arbre de widgets** (beaucoup de responsabilités).

- **Pourquoi c’est un problème**
  - **Complexité cognitive** : difficile de se concentrer sur une seule responsabilité (hero, CTA, bio, liste…).
  - Difficile de tester de manière ciblée (ex. behaviour du CTA “Play random” vs. favoris).
  - Tout changement UX sur une section (ex. biographie) devient un changement dans un gros fichier.

- **Suggestion de correction**
  - Extraire plusieurs widgets stateless dédiés :
    - `PersonDetailHeroSection` (hero + back + titre + compteur films/séries),
    - `PersonDetailActionsRow` (bouton play + favoris),
    - `PersonBiographySection` (titre + biographie + “voir plus/moins”),
    - `PersonFilmographySection` (2 sous-listes films/séries).
  - `PersonDetailPage` doit surtout :
    - récupérer l’ID,
    - lire le provider,
    - router loading / error / data,
    - passer `PersonDetailViewModel` et `PersonSummary` vers `_PersonDetailContent`.

---

#### 3.2.3 ViewModel + logique IPTV directement dans `person_detail_providers.dart`

- **Fichier / éléments**  
  `presentation/providers/person_detail_providers.dart` → `PersonDetailViewModel` + `personDetailControllerProvider`.

- **Problème**
  - `PersonDetailViewModel` est défini dans le même fichier que les providers alors que, côté `movie`, tu as un fichier `models/movie_detail_view_model.dart`. Ici la **cohérence inter-feature** est un peu brisée. :contentReference[oaicite:8]{index=8}  
  - Le provider `personDetailControllerProvider` :
    - parle à `PersonRepository` **et** à `IptvLocalRepository`,
    - filtre la filmographie pour ne garder que le contenu disponible dans la playlist IPTV (avec posters non nuls, etc.).
  - C’est du **cross-feature orchestration** (person + iptv) dans un provider unique.

- **Pourquoi c’est un problème**
  - Le mélange ViewModel / orchestration cross-feature dans un même fichier est moins lisible à moyen terme.
  - Test unitaire plus lourd : il faut mocker PersonRepo **et** IptvLocalRepo pour un seul provider.

- **Suggestion de correction**
  - Aligner la structure sur la feature `movie` :
    - créer `presentation/models/person_detail_view_model.dart`,
    - garder `person_detail_providers.dart` pour les providers uniquement.
  - Envisager un use case ou un “application service” :
    - ex. `GetPersonDetailForIptvAvailability`, qui encapsule la logique de filtrage IPTV,
    - le provider ne ferait plus que consommer ce use case.

---

#### 3.2.4 Gestion des erreurs & i18n sur la page

- **Fichier / éléments**  
  - `PersonDetailPage.build`
  - `_PersonDetailContent._buildBiography`

- **Problème**
  - En cas de `person == null`, la page affiche :
    ```dart
    Text('Aucune personnalité à afficher.', ...)
    ```
  - En cas d’erreur sur le provider :
    ```dart
    Text('Erreur: $e', ...)
    ```
  - Dans la biographie, le titre est hardcodé :
    ```dart
    Text('Biographie', ...)
    ``` :contentReference[oaicite:9]{index=9}  

- **Pourquoi c’est un problème**
  - **i18n cassée** : ces strings ne passent pas par `AppLocalizations`.
  - Message d’erreur brute `Erreur: $e` :
    - risque de fuite d’infos internes,
    - peu user-friendly,
    - impossible à traduire proprement.

- **Suggestion de correction**
  - Ajouter dans `AppLocalizations` :
    - `personNoData`, `personGenericError`, `personBiographyTitle`, etc.
  - Changer l’erreur :
    ```dart
    child: Text(
      AppLocalizations.of(context)!.personGenericError,
      ...
    )
    ```
    et éventuellement afficher un bouton “Réessayer” qui invalide explicitement le provider.

---

#### 3.2.5 Use case `GetFeaturedPeople` encore très “placeholder”

- **Fichiers / éléments**  
  - `domain/usecases/get_featured_people.dart`  
  - `data/repositories/person_repository_impl.dart` → `getFeaturedPeople()`.

- **Problème**
  - `getFeaturedPeople()` fait :
    ```dart
    return searchPeople('a');
    ```
    donc renvoie “les personnes dont le nom contient ‘a’” — approximation assez arbitraire.

- **Pourquoi c’est un problème**
  - Niveau Domain, le nom `getFeaturedPeople` laisse penser à :
    - “trending”, “popular”, “curated list”…  
  - L’implémentation actuelle ressemble plutôt à un **hack temporaire** :
    - résultats peu contrôlables,
    - UX improbable (toujours les mêmes personnes).

- **Suggestion de correction**
  - Documenter explicitement que c’est un placeholder (TODO).
  - À terme :
    - soit appeler un endpoint TMDB plus précis (`/person/popular`),
    - soit basculer vers une liste configurée côté backend / locale.

---

### 3.3 Nice to have

#### 3.3.1 Timer d’auto-refresh dans `PersonDetailPage`

- **Fichier / élément**  
  `PersonDetailPage._startAutoRefreshTimer`.

- **Problème**
  - Timer de 15s qui :
    - lit l’état actuel du provider avec `ref.read`,
    - si toujours `isLoading`, invalide le provider et relance un timer (max 3 fois),
    - logique d’auto-retry doublée par le `whenOrNull(error: ...)` qui relance aussi avec un délai. :contentReference[oaicite:10]{index=10}  
  - Même si la logique est correcte, ça reste un bloc non trivial à comprendre.

- **Pourquoi c’est un problème**
  - La logique d’auto-retry est un peu éclatée entre timer et handler d’erreur.
  - Un futur dev doit lire plusieurs blocs pour comprendre le “cycle de retry”.

- **Suggestion de correction**
  - Regrouper l’auto-retry dans un petit helper/service :
    - ex. `PersonDetailRetryController` ou passer par un provider de type `AsyncNotifier` qui intègre la logique de retry.
  - Documenter clairement la stratégie : “max 3 tentatives, 15s de timeout, 2s après erreur”.

---

#### 3.3.2 Micro-optimisations et style UI

- **Fichier / éléments**  
  `_PersonDetailContent.build`, `_buildHeroImage`, `_buildBiography`.

- **Problème**
  - Quelques widgets pourraient être marqués `const` (espacements, textes statiques).
  - On pourrait factoriser les `SizedBox(height: 16/32)` et autres en constantes `AppSpacing`.
  - `_buildBiography` :
    - `maxWidth` est calculé à partir de la largeur écran et d’un padding supposé (20+20), alors que `LayoutBuilder` fournit déjà `constraints.maxWidth`.

- **Pourquoi c’est un problème**
  - Petits points de style qui n’impactent pas fortement la perf, mais qui polissent le code.
  - Moins de “magie” si on utilise les `constraints` du layout plutôt qu’une valeur calculée à la main.

- **Suggestion de correction**
  - Ajouter `const` là où possible.
  - Utiliser une classe d’espacements partagée.
  - Dans `_needsExpansion`, utiliser plutôt `constraints.maxWidth` passé par le `LayoutBuilder`.

---

## 4. Plan de refactorisation par étapes

### Étape 1 — Clarifier et unifier la DI (structurant)

1. Décider si `PersonRepository` et `IptvLocalRepository` sont gérés :
   - uniquement via `sl` **ou**
   - uniquement via des providers Riverpod.
2. Mettre à jour `person_detail_providers.dart` pour ne plus reconstruire des services qui existent déjà dans `PersonDataModule`.
3. Introduire éventuellement un `personRepositoryProvider` unique, qui sera la seule manière d’obtenir `PersonRepository` dans la feature.

---

### Étape 2 — Découper `PersonDetailPage` en sous-widgets

1. Extraire depuis `_PersonDetailContent.build` :
   - `PersonDetailHeroSection`,
   - `PersonDetailActionsRow`,
   - `PersonBiographySection`,
   - `PersonFilmographySection`.
2. Garder `_buildHeroImage` dans `PersonDetailHeroSection`.
3. Résultat souhaité :
   - `PersonDetailPage` se lit rapidement,
   - `_PersonDetailContent` devient un simple composite de 4–5 widgets.

---

### Étape 3 — Isoler le ViewModel & la logique cross-feature IPTV

1. Créer `presentation/models/person_detail_view_model.dart` avec `PersonDetailViewModel`.
2. Laisser dans `person_detail_providers.dart` uniquement :
   - `PersonDetailViewModel` importé,
   - `personDetailControllerProvider` qui instancie le VM.
3. Si tu veux aller plus loin :
   - créer un use case ou service d’application pour le filtrage IPTV :
     - `GetPersonFilmographyAvailableOnIptv(PersonId)` → `[MovieSummary], [TvShowSummary]`.

---

### Étape 4 — Corriger l’i18n et l’error handling

1. Ajouter les clés de traduction manquantes dans tes ARB :
   - “Aucune personnalité à afficher”,
   - “Erreur lors du chargement de la fiche”,
   - “Biographie”, etc.
2. Remplacer les strings hardcodées par les appels `AppLocalizations.of(context)!`.
3. Ne plus afficher l’exception brute (`$e`) à l’utilisateur, mais logguer l’erreur et afficher un message plus propre + éventuellement un bouton de retry.

---

### Étape 5 — Améliorer `GetFeaturedPeople` (si utilisé en prod)

1. Documenter clairement dans un commentaire que `searchPeople('a')` est un fallback temporaire.
2. Définir une implémentation plus cohérente :
   - endpoint TMDB dédié (popular/trending),
   - ou logique métier pilotée par un backend / fichier local.
3. Ajouter des tests unitaires pour `getFeaturedPeople` afin de fixer son contrat métier.

---

### Étape 6 — Polishing & micro-optimisations

1. Ajout de `const` sur les widgets statiques.
2. Factorisation des espacions dans une classe `AppSpacing`.
3. Simplification de la logique de layout de la biographie (`_needsExpansion`).
4. Ajout de quelques tests :
   - mapping DTO → Domain (`PersonRepositoryImpl._mapPerson`, `_mapCredit`),
   - `personDetailControllerProvider` (avec overrides de `PersonRepository` et `IptvLocalRepository`).

---

## 5. Bonnes pratiques à adopter pour la suite

- **Garder Domain pur** et sans import de Flutter ou d’infra (continuer comme actuellement).
- **Limiter les “god widgets”** : un widget = une responsabilité claire (hero, actions, bio, listes…).
- **Unifier la DI** : ne pas mélanger plusieurs stratégies pour le même service (service locator vs providers).
- **Centraliser les ViewModels** dans `presentation/models/` et ne pas les mélanger aux providers.
- **Respecter strictement l’i18n** : aucun texte user-facing en dur dans le code, que ce soit pour les messages d’erreur ou les titres.
- **Isoler la logique cross-feature** (person + iptv + favoris) dans des services ou use cases dédiés, pas dans les pages UI.
- **Utiliser les providers Riverpod comme “colle”** entre Domain/Data et UI, pas comme lieu pour ré-instancier la DI.
- **Ajouter des tests unitaires** sur :
  - les mappers DTO → Domain,
  - les use cases (`GetPersonDetail`, `GetPersonFilmography`, `SearchPeople`, `GetFeaturedPeople`),
  - les providers complexes (`personDetailControllerProvider`, `personToggleFavoriteProvider`).
- **Documenter les hacks/placeholder** avec des TODO clairs pour ne pas les oublier.
- **Appliquer des micro-optimisations régulières** (const, AppSpacing, factorisation de patterns récurrents) pour garder le code agréable à lire.

---

Tu peux enregistrer ce rapport sous un nom du type :

`docs/rapports/features_person.md`

Si tu veux, on peut maintenant attaquer une étape précise du plan (par exemple le découpage de `PersonDetailPage`) et faire le refactor concret ensemble.
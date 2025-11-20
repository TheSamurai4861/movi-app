# Rapport d’analyse — `src/features/player`

## 1. Résumé global (vue d’ensemble)

Le dossier `features/player` est globalement **bien structuré** et conforme à une approche “feature-first” avec une séparation claire entre **domain**, **data** et **presentation**.  
Le choix de `media_kit` et `media_kit_video` est cohérent pour un player custom, et la gestion de l’historique, des préférences de langue, des pistes audio/sous-titres et du “next episode” est déjà très avancée. :contentReference[oaicite:0]{index=0}  

Cependant, certains points empêchent d’atteindre un niveau “clean architecture pro” :

- La **couche “domain” dépend directement de l’infra** (`IptvLocalRepository`, `CredentialsVault`, `NetworkExecutor`) via `XtreamStreamUrlBuilder`.
- `VideoPlayerPage` concentre **beaucoup de logique métier cross-feature** (TV, IPTV, historique, préférences) dans une seule classe/state.
- La page instancie directement `MediaKitVideoPlayerRepository` au lieu de dépendre de l’abstraction `VideoPlayerRepository`, ce qui **réduit la testabilité**.
- Plusieurs **strings en dur** cassent l’i18n et quelques détails (double écoute de `tracks`, doc de volume incohérente) méritent un polish. :contentReference[oaicite:1]{index=1}  

---

## 2. Architecture & organisation

### 2.1 Rôle du dossier

La feature `player` encapsule tout ce qui concerne :

- La **représentation d’une source vidéo** (`VideoSource`).
- L’**abstraction d’un player vidéo** (`VideoPlayerRepository`) + implémentation concrète `MediaKitVideoPlayerRepository`.
- La **construction d’URL Xtream** pour les flux IPTV (`XtreamStreamUrlBuilder`).
- Des utilitaires de **langue** (nom des langues pour les pistes audio/sous-titres).
- La **page de lecture vidéo plein écran** + contrôles custom + menus de sélection de pistes. :contentReference[oaicite:2]{index=2}  

### 2.2 Structure

- `player.dart`  
  → Barrel file qui exporte `VideoSource`, `VideoPlayerRepository`, `MediaKitVideoPlayerRepository`, `VideoPlayerPage`.

- `data/repositories/media_kit_video_player_repository.dart`  
  → Implémentation concrète basée sur `media_kit.Player` (open, play/pause, seek, volume, audio/subtitle tracks). :contentReference[oaicite:3]{index=3}  

- `domain/entities/video_source.dart`  
  → Entité simple, immutable, sans dépendance Flutter : URL, titre, type de contenu, poster, saison/épisode, position de reprise.

- `domain/repositories/video_player_repository.dart`  
  → Contrat abstrait pour contrôler un player vidéo (open, play/pause, seek, volume, pistes).

- `domain/services/xtream_stream_url_builder.dart`  
  → Service pour construire les URLs Xtream pour films/épisodes (utilise comptes IPTV, vault, network executor). :contentReference[oaicite:4]{index=4}  

- `domain/utils/language_formatter.dart`  
  → Utilitaire pour transformer un code de langue en nom lisible (Français, English, etc.). :contentReference[oaicite:5]{index=5}  

- `presentation/pages/video_player_page.dart`  
  → Page principale de lecture : orientation forcée paysage, plein écran, contrôles overlay, auto-hide, gestion des pistes, “next episode”, sauvegarde de l’historique, etc. :contentReference[oaicite:6]{index=6}  

- `presentation/widgets/track_selection_menu.dart`  
  → Bottom sheets de sélection des pistes audio et sous-titres.

- `presentation/widgets/video_player_controls.dart`  
  → Overlay de contrôles custom (top bar, contrôles centraux, progress bar, boutons sous-titres/audio/Chromecast, “Episode suivant”, “Recommencer”). :contentReference[oaicite:7]{index=7}  

### 2.3 Points forts

- **Séparation globale Data / Domain / Presentation respectée**.
- Entité `VideoSource` propre, adaptée au reste du domaine (historiques, ContentType…).
- Abstraction `VideoPlayerRepository` claire et minimale, facile à mocker côté tests.
- `XtreamStreamUrlBuilder` encapsule bien la complexité Xtream (URL, fallback, cache épisodes).
- UX du player **riche** : auto-hide des contrôles, double-tap pour seek, next episode, sélection automatique des pistes selon les préférences, reprise à la dernière position. :contentReference[oaicite:8]{index=8}  

### 2.4 Points à corriger (architecture)

- **Service “domain” couplé à l’infrastructure** (`XtreamStreamUrlBuilder` dépend de `IptvLocalRepository`, `CredentialsVault`, `NetworkExecutor`).
- `VideoPlayerPage` fait à la fois :
  - contrôle du player,
  - orchestration cross-feature (TV detail, IPTV, historique, préférences),
  - UI (gestures, animations, overlays).
- La page dépend directement de **l’implémentation concrète** `MediaKitVideoPlayerRepository` au lieu de l’interface `VideoPlayerRepository`. :contentReference[oaicite:9]{index=9}  

---

## 3. Problèmes identifiés (classés par sévérité)

### 3.1 Critique

#### 3.1.1 Service “domain” couplé à l’infra : `XtreamStreamUrlBuilder`

- **Fichier / élément**  
  `domain/services/xtream_stream_url_builder.dart` — classe `XtreamStreamUrlBuilder`. :contentReference[oaicite:10]{index=10}  

- **Problème**  
  Ce service est placé dans `domain/services` mais dépend directement de types “infra” :
  - `IptvLocalRepository` (core/storage),
  - `CredentialsVault` (core/security),
  - `NetworkExecutor` (core/network),
  - `Dio` et `jsonDecode` pour les appels HTTP.  

  Le “domain” au sens Clean Architecture ne devrait pas connaître ces détails.

- **Pourquoi c’est un problème**
  - **Violation du sens des dépendances** : le domaine dépend des couches inférieures (I/O, storage, HTTP).
  - Rend le domaine **moins testable** : les tests de ce service doivent mocker de l’infra très concrète.
  - Complexifie l’évolution : un changement dans la façon d’appeler l’API Xtream impacte directement le dossier `domain`.

- **Suggestion de correction**
  - Déplacer `XtreamStreamUrlBuilder` dans une couche **Data / Infrastructure** (ex. `features/player/data/services` ou `features/iptv/data/services`).
  - Ou :
    - Introduire une interface “domain” (ex. `XtreamStreamUrlBuilder` dans `domain`),  
    - Puis fournir une implémentation concrète `InfraXtreamStreamUrlBuilder` dans `data/services` qui dépend de `IptvLocalRepository`, `CredentialsVault`, `NetworkExecutor`.
  - Consommer ensuite l’interface via DI (Riverpod / `sl`).

---

#### 3.1.2 `VideoPlayerPage` = widget très chargé (UI + orchestration métier)

- **Fichier / élément**  
  `presentation/pages/video_player_page.dart` — `_VideoPlayerPageState`, notamment `_setupListeners`, `_selectPreferredTracks`, `_goToNextEpisode`. :contentReference[oaicite:11]{index=11}  

- **Problème**
  - Le State gère :
    - configuration système (orientation, UI Mode),
    - logique de player (listeners, buffering, durée, pistes),
    - logique de préférences utilisateur (`PlayerPreferences` via `slProvider`),
    - logique de **next episode** très poussée :
      - récupération de `TvDetailViewModel` via `tvDetailProgressiveControllerProvider`,
      - conversion de numérotation globale ↔ relative pour Xtream,
      - recherche de `XtreamPlaylistItem` dans toutes les playlists IPTV,
      - construction de l’URL via `XtreamStreamUrlBuilder`,
      - sauvegarde de l’historique via `HistoryLocalRepository`, et relecture de la position.
  - Tout ceci est concentré dans une **seule classe stateful**.

- **Pourquoi c’est un problème**
  - **Complexité cognitive très élevée** : difficile à lire, modifier, tester.
  - Mélange **UI + orchestration cross-feature** (TV, IPTV, historique, player) → pas Single Responsibility.
  - Tests unitaires quasi impossibles sans gros systèmes de mocks/stubs.

- **Suggestion de correction**
  - Extraire les responsabilités en couches :
    - Un **service / use case “next episode player”** (par ex. `PlayNextEpisodeService`) qui :
      - prend `VideoSource` courant,
      - parle à `tvDetailProgressiveControllerProvider`, `IptvLocalRepository`, `HistoryLocalRepository`, `XtreamStreamUrlBuilder`,
      - renvoie un `VideoSource` pour l’épisode suivant (ou une erreur métier).
    - Un **service “preferred tracks selector”** (par ex. `PreferredTracksSelector`) pour `_selectPreferredTracks`.
  - Dans `VideoPlayerPage`, ne garder que :
    - gestion de l’UI et des gestures,
    - appels à ces services via providers/DI.

---

### 3.2 Important

#### 3.2.1 Utilisation directe de `MediaKitVideoPlayerRepository` dans la page

- **Fichier / élément**  
  `video_player_page.dart` → `late final MediaKitVideoPlayerRepository _playerRepository;` + instanciation dans `initState()`. :contentReference[oaicite:12]{index=12}  

- **Problème**
  - La page dépend **directement** de l’implémentation concrète, alors qu’une interface `VideoPlayerRepository` existe dans `domain`.
  - DI locale manuelle (`MediaKitVideoPlayerRepository()` dans le widget) au lieu d’utiliser un provider ou une abstraction.

- **Pourquoi c’est un problème**
  - **Testabilité réduite** : impossible d’injecter un fake/mocked `VideoPlayerRepository` pour des tests UI.
  - Couplage fort à `media_kit` depuis la page (alors que l’objectif de l’interface Domain est justement de l’éviter).
  - Difficile de remplacer la techno de player (autre package, player natif, etc.).

- **Suggestion de correction**
  - Introduire un provider :
    ```dart
    final videoPlayerRepositoryProvider = Provider<VideoPlayerRepository>((ref) {
      return MediaKitVideoPlayerRepository();
    });
    ```
  - Dans `VideoPlayerPage`, récupérer via `ref.read(videoPlayerRepositoryProvider)` et stocker un `VideoPlayerRepository` (interface).
  - Pour les tests, override du provider avec un fake repository.

---

#### 3.2.2 Double abonnement au stream `tracks`

- **Fichier / élément**  
  `_setupListeners()` dans `video_player_page.dart`. :contentReference[oaicite:13]{index=13}  

- **Problème**
  - Il y a **deux listeners successifs** sur `player.stream.tracks` :
    - Le premier met à jour `_hasSubtitles`, `_subtitleTracks`, `_audioTracks`.
    - Le second gère la sélection automatique des pistes, `_tracksInitialized`, `_currentSubtitleTrack`, `_currentAudioTrack`, `_subtitlesEnabled`.
  - Même stream, deux subscriptions, logique très liée.

- **Pourquoi c’est un problème**
  - Redondance et risque de **comportement non évident** (ordre d’exécution, race conditions).
  - Complexité inutile pour un flux qui pourrait être géré dans un seul bloc.

- **Suggestion de correction**
  - Fusionner les deux listeners :
    - Mise à jour des listes + appel à `_selectPreferredTracks` + mise à jour des pistes courantes dans un seul callback.
  - Éventuellement factoriser la sélection automatique dans une méthode bien documentée.

---

#### 3.2.3 Doc de `setVolume` incohérente avec l’implémentation

- **Fichiers / éléments**  
  - `VideoPlayerRepository.setVolume(double volume)` (commentaire : “0.0 à 1.0”). :contentReference[oaicite:14]{index=14}  
  - `MediaKitVideoPlayerRepository.setVolume` :
    ```dart
    await _player.setVolume(volume.clamp(0.0, 100.0));
    ```

- **Problème**
  - Le contrat d’interface indique “0.0 à 1.0”,  
    l’implémentation clamp sur “[0.0, 100.0]” et passe tel quel à `media_kit`.

- **Pourquoi c’est un problème**
  - Incohérence de contrat → risque de mauvais usage de l’API interne.
  - Si l’appelant envoie 0.5 pensant “50 %”, le player reçoit un volume “0.5” (0.5 %), ou inversement.

- **Suggestion de correction**
  - Décider clairement :
    - Soit conserver une API **0.0–1.0** côté domaine → multiplier par 100 dans l’implémentation.
    - Soit assumer une API **0.0–100.0** → mettre à jour le commentaire de `VideoPlayerRepository`.
  - Ajouter un test unitaire sur `MediaKitVideoPlayerRepository.setVolume()` pour fixer le comportement.

---

#### 3.2.4 Dupli de logique d’analyse de langue (LanguageFormatter vs menus)

- **Fichiers / éléments**  
  - `domain/utils/language_formatter.dart`. :contentReference[oaicite:15]{index=15}  
  - `_extractLanguageCodeFromTrack` dans `video_player_page.dart`.  
  - `_formatTrackTitle` dans `SubtitleTrackSelectionMenu` et `AudioTrackSelectionMenu`. :contentReference[oaicite:16]{index=16}  

- **Problème**
  - Plusieurs mappings et heuristiques pour inférer le code de langue à partir d’un titre → duplication de logique, patterns imbriqués.
  - `LanguageFormatter` fait déjà ce travail pour certains cas, mais les menus refont des tests sur `fr`, `french`, `français`, etc.

- **Pourquoi c’est un problème**
  - Comportement potentiellement incohérent entre la sélection auto, le menu et l’affichage.
  - Plus difficile à maintenir/faire évoluer (ajouter une langue nécessite de changer plusieurs endroits).

- **Suggestion de correction**
  - Centraliser la logique d’inférence dans une **API unique** :
    - ex. `LanguageFormatter.detectLanguageCodeFromTitle(String title)`.
  - Utiliser cette API :
    - dans `_extractLanguageCodeFromTrack`,
    - dans les menus `_formatTrackTitle`.

---

#### 3.2.5 Strings en dur (i18n / UX)

- **Fichiers / éléments**  
  - `video_player_page.dart` → SnackBars :
    - `'Impossible de charger les données de la série'`,
    - `'Aucun épisode suivant disponible'`,
    - `'Épisode non disponible dans la playlist'`,
    - `'Impossible de construire l\'URL de streaming'`,
    - `'Erreur: $e'`,
    - `'Fonctionnalité Chromecast à venir'`. :contentReference[oaicite:17]{index=17}  
  - `video_player_controls.dart` :
    - `'Quitter'`, `'Episode suivant'`, `'Recommencer'`. :contentReference[oaicite:18]{index=18}  
  - `track_selection_menu.dart` :
    - `'Sous-titres'`, `'Désactiver'`, `'Audio'`, `'Piste ${track.id}'`.

- **Problème**
  - Texte UI en dur en français alors que le reste du projet semble viser l’i18n.
  - Message d’erreur brute `'Erreur: $e'` peu user-friendly et non traduisible.

- **Pourquoi c’est un problème**
  - **i18n cassée** : impossible de traduire proprement la feature player.
  - Risque de fuite d’infos techniques à l’utilisateur via `$e`.

- **Suggestion de correction**
  - Déplacer tous ces textes dans les fichiers de localisation (ARB) et utiliser `AppLocalizations`.
  - Logger les erreurs techniques (`debugPrint/logger`) et afficher un message générique à l’utilisateur.
  - Prévoir éventuellement des messages différenciés : “pas d’épisode suivant”, “URL de streaming indisponible”, etc.

---

### 3.3 Nice to have

#### 3.3.1 `_goToNextEpisode` très long et très spécifique

- **Fichier / élément**  
  `_goToNextEpisode` dans `video_player_page.dart`. :contentReference[oaicite:19]{index=19}  

- **Problème**
  - Méthode longue (~200 lignes) avec :
    - dépendances sur `slProvider`, `IptvLocalRepository`, `CredentialsVault`, `NetworkExecutor`, `HistoryLocalRepository`, `tvDetailProgressiveControllerProvider`,
    - logique de mapping TMDB → Xtream,
    - fallback sur différentes stratégies de recherche d’item Xtream,
    - gestion de l’historique.

- **Pourquoi c’est un problème**
  - Difficile à tester/faire évoluer (ex. ajout d’options de “play next” différentes).
  - Mélange de responsabilités (trouver l’épisode, trouver l’item IPTV, construire l’URL, gérer l’historique).

- **Suggestion de correction**
  - Extraire en un **service “NextEpisodeResolver”** (dans une couche application) qui :
    - prend `VideoSource` + `TvDetailViewModel`,
    - renvoie `(VideoSource nextVideoSource)` ou une erreur métier.
  - `_goToNextEpisode` se réduit à :
    - appel du service,
    - affichage éventuel de SnackBar,
    - `setState` + `_playerRepository.open(nextVideoSource)`.

---

#### 3.3.2 LanguageFormatter couplé au français

- **Fichier / élément**  
  `domain/utils/language_formatter.dart`. :contentReference[oaicite:20]{index=20}  

- **Problème**
  - Les noms de langues retournés sont en français (“Français”, “Anglais”, “Inconnu”, etc.).
  - C’est un utilitaire placé dans `domain/utils`, pas dans `presentation`.

- **Pourquoi c’est un problème**
  - Le domain devrait être indépendant de la langue UI.
  - Si un jour tu veux une UI en anglais, ce formatter continue de produire du français.

- **Suggestion de correction**
  - Soit déplacer ce formatter dans une couche présentation/shared UI (et accepter le caractère FR-only).
  - Soit renvoyer un code “neutre” (ex. le code ISO, ex. “fr”, “en”) et laisser la présentation mapper vers un label i18n.

---

## 4. Plan de refactorisation par étapes

### Étape 1 — Replacer `XtreamStreamUrlBuilder` au bon niveau

- Déplacer `XtreamStreamUrlBuilder` de `domain/services` vers une couche **infra/data** :
  - ex. `features/iptv/data/services/xtream_stream_url_builder.dart` ou `features/player/data/services`.
- Introduire au besoin une interface “domain” si tu veux l’injecter proprement.
- Mettre à jour les imports (player, tv feature, etc.) pour dépendre d’une abstraction si nécessaire.

---

### Étape 2 — Injecter le `VideoPlayerRepository` via DI (plus d’instanciation directe)

- Créer un provider :
  ```dart
  final videoPlayerRepositoryProvider = Provider<VideoPlayerRepository>((ref) {
    return MediaKitVideoPlayerRepository();
  });
```

* Dans `VideoPlayerPage`, remplacer :

  ```dart
  _playerRepository = MediaKitVideoPlayerRepository();
  _videoController = VideoController(_playerRepository.player);
  ```

  par :

  ```dart
  final repo = ref.read(videoPlayerRepositoryProvider);
  _playerRepository = repo;
  _videoController = VideoController(repo.player);
  ```
* Pour les tests, override le provider avec un fake repo.

---

### Étape 3 — Simplifier `VideoPlayerPage` (extraction de services / logique)

* Extraire un service ou use case :

  * `NextEpisodeService` (ou similaire) pour la logique de `_goToNextEpisode`.
  * `PreferredTracksSelector` pour la logique de `_selectPreferredTracks`, `_extractLanguageCodeFromTrack`.
* Consommer ces services via DI (providers) dans la page :

  * `_goToNextEpisode` devient essentiellement :

    * appeler le service,
    * gérer les erreurs via SnackBar,
    * mettre à jour `_currentVideoSource` + `_resumePositionApplied` + `_tracksInitialized`.
* Fusionner les deux listeners sur `player.stream.tracks` en un seul.

---

### Étape 4 — Corriger le contrat `setVolume` & centraliser la logique de langue

* Décider du **range “officiel”** de `setVolume` côté `VideoPlayerRepository` :

  * 0.0–1.0 (recommandé) ou 0.0–100.0.
* Adapter `MediaKitVideoPlayerRepository` pour respecter ce contrat.
* Créer des fonctions utilitaires dans `LanguageFormatter` pour :

  * inférer un code de langue depuis un titre,
  * formater une piste (Subtitle/Audio) en label.
* Utiliser ces fonctions dans `video_player_page.dart` et `track_selection_menu.dart`.

---

### Étape 5 — i18n & UX des messages

* Ajouter les clés ARB pour tous les textes en dur des menus, boutons, SnackBars.
* Remplacer les strings par `AppLocalizations` dans :

  * `VideoPlayerControls`,
  * `TrackSelectionMenu`,
  * `VideoPlayerPage` (SnackBars).
* Remplacer `SnackBar(content: Text('Erreur: $e'))` par :

  * un log interne (`debugPrint` ou logger),
  * un message user-friendly (`l10n.playerGenericError`).

---

### Étape 6 — Tests & polishing

* Ajouter des tests unitaires sur :

  * `MediaKitVideoPlayerRepository.setVolume`, `seekForward`, `seekBackward` (logique simple mais utile à figer).
  * `LanguageFormatter` (formatLanguageCode, formatLanguageCodeWithRegion).
  * La logique “next episode” une fois extraite dans un service.
* Micro-optimisations :

  * Ajouter des `const` sur les widgets statiques.
  * Factoriser les `SizedBox(height: …)` fréquents dans un `AppSpacing`.
  * Commenter les parties “magiques” (calcul d’ID Xtream, fallback episodes).

---

## 5. Bonnes pratiques à adopter pour la suite

* **Domain sans infra** : ne jamais faire dépendre la couche Domain de services HTTP, de storage, ni de packages tiers (dio, media_kit…).
* **Toujours coder contre des interfaces** (`VideoPlayerRepository`) et injecter les implémentations via DI (Riverpod ou `sl`).
* **Éviter les “god widgets”** : dès qu’un State commence à gérer 3–4 responsabilités métiers, extraire en services/use cases + widgets dédiés.
* **Centraliser les utilitaires** (langues, formattage) pour éviter duplication / divergences de comportement.
* **i18n stricte** : aucun texte user-facing en dur, même dans les SnackBars (toujours passer par `AppLocalizations`).
* **Streams & listeners maîtrisés** : éviter les abonnements multiples au même stream pour des responsabilités entremêlées.
* **Contrats clairs** : documenter précisément les ranges/contrats de tes APIs internes (`setVolume`, `resumePosition`, etc.) et t’y tenir.
* **Logs vs messages utilisateur** : les détails techniques dans les logs, des messages simples et traduits dans l’UI.
* **Tests sur la logique critique** : numéro d’épisode suivant, mapping TMDB ↔ Xtream, sélection automatique des pistes, etc., dans des services découplés de l’UI.

---

Si tu veux, on peut maintenant prendre **une étape précise** (par exemple l’injection du `VideoPlayerRepository` via un provider) et je te propose le diff concret à appliquer dans tes fichiers.

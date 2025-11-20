# Rapport d’analyse — `src/features/playlist`

## 1. Résumé global (vue d’ensemble)

Le dossier `features/playlist` est **globalement très propre** et bien aligné avec une approche Clean Architecture :  
- séparation nette **Domain / Data**,  
- entités et use cases **simples, purs et testables**,  
- un repository d’implémentation qui joue bien son rôle d’adaptateur vers le stockage local. :contentReference[oaicite:0]{index=0}  

La complexité est faible, il n’y a ni “god class” ni widget lourd à ce stade (feature purement métier / storage).  
Les principaux points d’attention sont plutôt **architecturaux et métier** :  
- un **couplage cross-feature** playlist ↔ IPTV via `PlaylistFilterService`,  
- quelques **raccourcis métier** dans `PlaylistRepositoryImpl` (création de header implicite, fallback “Playlist”/`owner: 'local'`),  
- une définition un peu “légère” de `getFeaturedPlaylists` (placeholder déguisé),  
- quelques décisions à clarifier autour de l’**ordre des items** (positions nulles, normalisation).  

Rien de critique, mais plusieurs petits ajustements peuvent faire passer la feature au niveau “code pro très lisible et documenté”.

---

## 2. Architecture & organisation

### 2.1 Rôle du dossier

La feature `playlist` regroupe la **gestion métier des playlists utilisateur** :

- définition des entités `Playlist`, `PlaylistItem`, `PlaylistSummary`,  
- contrat `PlaylistRepository` + implémentation locale,  
- use cases CRUD (create, rename, delete, add/remove/reorder item, listes utilisateur, recherche…),  
- services métiers auxiliaires pour **filtrer** et **ordonner** les playlists en fonction d’IPTV et des positions. :contentReference[oaicite:1]{index=1}  

Il s’agit donc clairement d’une **feature de domaine métier + data locale**, sans UI.

### 2.2 Structure et responsabilités

- `playlist.dart`  
  → Barrel file qui ré-exporte les entités, le repository et tous les use cases Domain. :contentReference[oaicite:2]{index=2}  

- `data/playlist_data_module.dart`  
  → Module d’initialisation DI : enregistre `PlaylistLocalRepository` (infra) et `PlaylistRepository` dans le service locator `sl`. :contentReference[oaicite:3]{index=3}  

- `data/repositories/playlist_repository_impl.dart`  
  → Implémentation concrète de `PlaylistRepository` au-dessus de `PlaylistLocalRepository` : mapping entre `PlaylistHeader`/`PlaylistDetailRow` (infra) et `Playlist`/`PlaylistSummary` (domaine). Gère aussi quelques règles métier simples (création implicite, totalDuration). :contentReference[oaicite:4]{index=4}  

- `data/services/playlist_filter_service.dart`  
  → Service qui filtre une `Playlist` pour ne conserver que les items réellement disponibles dans l’IPTV (via `IptvLocalRepository` et `XtreamPlaylistItemType`). :contentReference[oaicite:5]{index=5}  

- `data/services/playlist_ordering_service.dart`  
  → Service qui **normalise** les positions des items (tri + renumérotation `1..n`). :contentReference[oaicite:6]{index=6}  

- `domain/entities/playlist.dart`  
  → Entités métier `Playlist`, `PlaylistItem`, `PlaylistSummary` basées sur des value objects (`PlaylistId`, `MediaTitle`, `Synopsis`, `ContentReference`). :contentReference[oaicite:7]{index=7}  

- `domain/repositories/playlist_repository.dart`  
  → Contrat métier pour toutes les opérations playlist (lecture, CRUD, search, reorder). :contentReference[oaicite:8]{index=8}  

- `domain/usecases/*.dart`  
  → Chacun encapsule une opération unique du repository : `CreatePlaylist`, `GetPlaylistDetail`, `GetUserPlaylists`, `AddPlaylistItem`, `RemovePlaylistItem`, `ReorderPlaylistItem`, etc. API claire et très testable. :contentReference[oaicite:9]{index=9}  

### 2.3 Points forts

- **Domain pur** : entités / repository / usecases ne dépendent pas de Flutter ni de l’infra.  
- **Use cases fins** (un par action), parfaitement adaptés à une approche “command-like”.  
- **Mapping Data → Domain propre** (`_mapDetail`), avec agrégation du `totalDuration`. :contentReference[oaicite:10]{index=10}  
- Services `PlaylistFilterService` et `PlaylistOrderingService` **purs en sortie** (retournent un nouvel objet `Playlist`), ce qui facilite la testabilité.

### 2.4 Points à corriger

- **Couplage cross-feature** playlist ↔ IPTV au niveau Data (`PlaylistFilterService`), qui mérite d’être clarifié et documenté.  
- Quelques **raccourcis métier** dans `PlaylistRepositoryImpl` (création implicite de header, fallback constants `'Playlist'` et `'local'`, `getFeaturedPlaylists` très approximatif). :contentReference[oaicite:11]{index=11}  
- Services utiles (`filter`, `normalize`) qui ne sont pas exposés via le barrel `playlist.dart` : réfléchir à leur place (Domain vs Data).

---

## 3. Problèmes identifiés (classés par sévérité)

### 3.1 Critique

**Aucun problème de niveau “critique”** (pas de dépendance circulaire, pas de violation grave de la séparation Domain/Data, pas de classe ingérable).  
Les soucis sont plutôt de niveau “Important” / “Nice to have”.

---

### 3.2 Important

#### 3.2.1 Couplage cross-feature dans `PlaylistFilterService`

- **Fichier / élément**  
  `data/services/playlist_filter_service.dart` → `PlaylistFilterService`. :contentReference[oaicite:12]{index=12}  

- **Problème**  
  - Ce service dépend de :
    - `IptvLocalRepository` (feature IPTV, stockage),
    - `XtreamPlaylistItemType` (modèle IPTV),
    - `ContentType` (value object partagé).  
  - Il vit dans `features/playlist/data` mais son rôle est “filtrer une Playlist selon la disponibilité IPTV”, ce qui est **fonctionnellement multi-feature** (playlist + iptv).

- **Pourquoi c’est un problème**
  - Couplage direct entre la feature Playlist et la feature IPTV.
  - Rend la feature Playlist moins réutilisable dans un contexte sans IPTV (ex. playlists purement locales).
  - Si on change la façon de représenter l’IPTV, on impacte immédiatement ce service.

- **Suggestion de correction**
  - Positionner clairement ce service comme **“application service cross-feature”** :
    - soit dans un module `features/iptv/application` ou `features/playlist/application`,
    - soit dans un dossier partagé `features/playlist_iptv` s’il y a plusieurs comportements similaires.
  - Côté playlist, garder le domaine **agnostique** de l’IPTV (juste `ContentReference`), et déléguer l’adaptation à ce service d’application.
  - Documenter dans un commentaire que ce service n’est pas “Domain playlist pur”, mais bien un orchestrateur Playlist+IPTV.

---

#### 3.2.2 Règle métier implicite dans `addItem` (création de header “magique”)

- **Fichier / élément**  
  `data/repositories/playlist_repository_impl.dart` → `addItem`. :contentReference[oaicite:13]{index=13}  

- **Problème**
  - Si le header n’existe pas :
    ```dart
    final header = await _local.getPlaylist(playlistId.value);
    if (header == null) {
      await _local.upsertHeader(
        PlaylistHeader(
          id: playlistId.value,
          title: 'Playlist',
          description: null,
          cover: null,
          owner: 'local',
          isPublic: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
    }
    ```
  - `addItem` devient implicitement “créer une playlist minimale si besoin” avec un titre `'Playlist'` et `owner: 'local'`.

- **Pourquoi c’est un problème**
  - Ambiguïté métier :
    - `CreatePlaylist` existe déjà comme use case explicite.
    - `AddPlaylistItem` a un comportement “surprise” (peut créer une playlist sans que l’appelant le sache).
  - Problèmes d’i18n et de cohérence :
    - titre `'Playlist'` et owner `'local'` sont codés en dur.
  - Plus difficile de raisonner sur les invariants :
    - une playlist peut exister sans passer par `createPlaylist`.

- **Suggestion de correction**
  - Décider explicitement :
    - soit l’API **ne crée jamais de playlist** → lever une exception métier si le header est absent.
    - soit l’API autorise la création implicite → documenter clairement cette règle dans le contrat et encapsuler la logique dans un use case dédié (ex. `EnsurePlaylistExistsAndAddItem`).
  - Si tu gardes la création implicite :
    - externaliser les valeurs par défaut (titre, owner) dans une configuration/i18n plutôt que les hardcoder.

---

#### 3.2.3 `getFeaturedPlaylists` : implémentation “placeholder” non alignée avec le commentaire

- **Fichier / élément**  
  `playlist_repository_impl.dart` → `getFeaturedPlaylists()`. :contentReference[oaicite:14]{index=14}  

- **Problème**
  - Commentaire :
    ```dart
    // Use most recently updated playlists as featured
    ```
  - Implémentation :
    ```dart
    final headers = await _local.searchByTitle('');
    return headers.take(10)...
    ```
  - On suppose que `searchByTitle('')` renvoie “tout” dans un ordre implicitement pertinent, mais ce n’est ni garanti ni explicité.

- **Pourquoi c’est un problème**
  - Le contrat métier “featured” n’est pas clair :
    - “les plus récemment mises à jour” vs “les 10 premières retournées”.
  - Difficulté à tester et à faire évoluer sans connaître l’ordre interne de `PlaylistLocalRepository`.

- **Suggestion de correction**
  - Si tu veux vraiment les plus récemment modifiées :
    - exposer une méthode dédiée dans `PlaylistLocalRepository` (ex. `getMostRecentlyUpdated(limit: 10)`).
  - Ou documenter que “featured = n’importe quelle playlist trouvée” tant que la feature n’est pas finalisée (avec un TODO clair).
  - Ajouter idéalement un test unitaire sur `getFeaturedPlaylists` pour fixer la règle métier.

---

#### 3.2.4 Gestion des positions et normalisation

- **Fichiers / éléments**  
  - `playlist_repository_impl.dart` → `addItem`, `reorderItem`. :contentReference[oaicite:15]{index=15}  
  - `playlist_ordering_service.dart` → `normalizePositions`.

- **Problème**
  - `addItem` :
    ```dart
    position: item.position ??
      DateTime.now().millisecondsSinceEpoch, // naive ordering if missing
    ```
    → fallback sur un timestamp pour garantir l’unicité.
  - `PlaylistOrderingService.normalizePositions` :
    - trie par `position ?? 0`,
    - renumérote 1..n.
  - Les deux couches ne sont pas clairement liées (qui appelle `normalizePositions` ? quand ?).

- **Pourquoi c’est un problème**
  - La stratégie d’ordre est un peu implicite :  
    - à la création, position = timestamp (donc l’ordre dépend du temps),  
    - plus tard, on peut “normaliser” pour avoir des positions consécutives, mais ce n’est pas automatique.
  - Si plusieurs appels concurrents à `addItem`, l’ordre peut devenir “bizarre” avant normalisation.

- **Suggestion de correction**
  - Documenter le contrat :
    - “Les positions sont utilisées pour l’ordre affiché. À défaut, on utilise la date de création, puis on normalise à la demande.”
  - Envisager une politique plus déterministe :
    - ex. `position = maxPosition+1` côté storage, ou normalisation automatique après add/remove.
  - Clarifier qui appelle `PlaylistOrderingService.normalizePositions` (use case dédié ? service d’application ?).

---

### 3.3 Nice to have

#### 3.3.1 Domain vs Data : services playlist pas exposés

- **Fichier / élément**  
  - `playlist_filter_service.dart`  
  - `playlist_ordering_service.dart`  
  - `playlist.dart` (barrel). :contentReference[oaicite:16]{index=16}  

- **Problème**
  - Les services `PlaylistFilterService` et `PlaylistOrderingService` sont dans `data/services`, mais fonctionnent principalement sur des entités Domain (`Playlist`).
  - Ils ne sont pas ré-exportés par `playlist.dart`, ce qui peut surprendre si on les considère comme “domaine avancé de playlists”.

- **Pourquoi c’est un problème**
  - L’intention architecturale n’est pas claire :
    - sont-ce des “domain services” (mettables dans `domain/services`) ?
    - ou des “application services” propres à une couche supérieure ?
  - Un autre dev peut les chercher côté domain.

- **Suggestion de correction**
  - Décider et documenter :
    - soit les déplacer en `domain/services` (s’ils doivent être proches du domaine playlist pur),
    - soit les garder en “application/cross-feature” et assumer qu’ils ne font pas partie du kernel Domain.
  - Optionnel : ajouter un barrel `playlist_services.dart` si tu veux les exposer proprement.

---

#### 3.3.2 Détails métier / style

- **Valeur par défaut de `isPublic`**  
  - Dans `Playlist`, `isPublic` a par défaut `true`, mais `createPlaylist` a par défaut `isPublic = false`.  
  - C’est cohérent techniquement (c’est `PlaylistHeader` qui porte la vérité), mais gagnerait à être **documenté** pour éviter les malentendus.

- **`searchPlaylists` et `getUserPlaylists`**  
  - `itemCount` est toujours `null` dans `PlaylistSummary`. Peut-être volontaire, mais si l’UI a besoin d’un nombre d’items, il faudra le calculer ou l’exposer.

- **Documentation / commentaires**  
  - La plupart des méthodes Domain sont auto-explicites, mais un peu de doc sur les points non-triviaux (création implicite, featured, normalisation) aiderait pour la maintenance.

---

## 4. Plan de refactorisation par étapes

### Étape 1 — Clarifier et repositionner `PlaylistFilterService`

- Déplacer ce service vers un endroit clairement identifié comme **application cross-feature** (playlist + iptv).
- Ajouter un commentaire explicite :  
  “Filtre les items d’une playlist en fonction de la disponibilité IPTV (dépend de IptvLocalRepository).”
- Adapter les imports pour que la feature Playlist “pure” n’ait pas besoin de connaître IPTV.

---

### Étape 2 — Rendre explicite la règle métier d’`addItem`

- Décider si `addItem` a le droit de **créer une playlist implicite**.
- Si **non** :
  - remplacer la création implicite par une exception métier (ex. `PlaylistNotFoundException`).
- Si **oui** :
  - documenter la règle dans `PlaylistRepository.addItem` et `PlaylistRepositoryImpl.addItem`.
  - externaliser les valeurs par défaut (titre, owner) dans une config (et/ou les faire passer en paramètre d’un use case dédié).

---

### Étape 3 — Solidifier `getFeaturedPlaylists`

- Choisir une stratégie claire pour “featured” :
  - soit des playlists “les plus récemment mises à jour” via une API dédiée de `PlaylistLocalRepository`,
  - soit une autre règle (top X plus utilisés, pré-configurés, etc.).
- Implémenter cette stratégie dans `PlaylistRepositoryImpl`.
- Ajouter un test unitaire sur `GetFeaturedPlaylists` pour figer le contrat.

---

### Étape 4 — Clarifier la stratégie d’ordre & positions

- Documenter dans `PlaylistOrderingService` et `PlaylistRepositoryImpl` la stratégie :
  - fallback sur timestamp,
  - normalisation optionnelle via `normalizePositions`.
- Envisager un use case :
  - `NormalizePlaylistPositions(playlistId)` qui combine `GetPlaylistDetail` + `PlaylistOrderingService.normalizePositions` + persistance.
- Si besoin, faire évoluer `PlaylistLocalRepository` pour supporter une normalisation plus automatique.

---

### Étape 5 — Polishing & documentation

- Ajouter des **doc comments** (`///`) sur :
  - `PlaylistRepository` (contrat métier de chaque méthode),
  - `PlaylistFilterService` (cross-feature),
  - `PlaylistOrderingService` (ordre logique vs ordre stockage),
  - `PlaylistRepositoryImpl` (règles implicites).
- Vérifier que les constantes textuelles (“Playlist”, “local”) sont soit documentées, soit déplacées dans une couche i18n/config.

---

## 5. Bonnes pratiques à adopter pour la suite

- **Garder le Domain pur** : entités, repository, usecases ne doivent dépendre ni de Flutter ni des détails d’infra (HTTP, storage, IPTV concret…).
- **Éviter les règles métiers cachées** dans les implémentations (ex. création implicite dans `addItem`) : les rendre explicites via des use cases ou de la documentation claire.
- **Isoler les services cross-feature** (playlist+IPTV, playlist+movie, etc.) dans une couche d’application dédiée, pas dans le cœur du domaine.
- **Centraliser la logique d’ordre** (positions) et la documenter pour éviter les comportements “magiques”.
- **Tester les use cases** clés (`CreatePlaylist`, `GetPlaylistDetail`, `SearchPlaylists`, `GetFeaturedPlaylists`) et les services (`PlaylistFilterService`, `PlaylistOrderingService`) avec des doubles de `PlaylistRepository`/`PlaylistLocalRepository`.
- **Soigner les contrats d’interface** (commentaires sur les valeurs par défaut, exceptions possibles).
- **Limiter les strings en dur**, même côté Data, si ces valeurs sont susceptibles d’apparaître dans l’UI (ex. titre par défaut).
- **Utiliser les value objects partout où il y a des invariants** (titres non vides, ids valides) et éviter de “casser” ces invariants par des fallback arbitraires.

---

Tu peux enregistrer ce rapport sous un nom du type :

`docs/rapports/features_playlist.md`

Si tu veux, on peut ensuite faire ensemble un **use case concret**, par exemple :  
> “Normaliser les positions d’une playlist et filtrer les contenus IPTV indisponibles avant affichage”,  
et je te propose le design (use case + services + wiring Riverpod) étape par étape.

# Flux complet de library sync — Movi
## A3 — Cartographie de la synchronisation bibliothèque

## 1. Objet du document

Ce document cartographie le flux réel de synchronisation de la bibliothèque utilisateur dans Movi.

L’objectif est de répondre à ces questions :
- qui déclenche la sync ;
- à quel niveau elle est montée dans l’application ;
- quels objets transitent ;
- quelles étapes sont exécutées ;
- où se mélangent local, cloud, UI, état global et comportements transverses.

Ce document ne propose pas encore de nouvelle architecture.
Il décrit l’existant pour préparer le futur refactor.

---

## 2. Résumé exécutif

La sync bibliothèque de Movi est un sous-système en 4 couches.

### Couche 1 — Bootstrap global
`LibraryCloudSyncBootstrapper` est monté très haut dans l’application pour s’assurer que le contrôleur de sync est initialisé tôt et puisse écouter les changements de profil et de client Supabase afin de lancer la sync en arrière-plan. :contentReference[oaicite:7]{index=7}

### Couche 2 — Contrôleur Riverpod
Le contrôleur de sync :
- expose l’état de sync ;
- gère l’auto-sync ;
- gère le “sync now” manuel ;
- valide profil + client Supabase ;
- annule les syncs obsolètes ;
- émet `AppEventType.librarySynced` ;
- invalide certains providers UI après succès. :contentReference[oaicite:8]{index=8} :contentReference[oaicite:9]{index=9}

### Couche 3 — Service “complet”
`ComprehensiveCloudSyncService` ne synchronise pas seulement la bibliothèque :
il enchaîne aussi profils, sources IPTV et préférences utilisateur. :contentReference[oaicite:10]{index=10} :contentReference[oaicite:11]{index=11}

### Couche 4 — Moteur bibliothèque spécialisé
`LibraryCloudSyncService` exécute le cœur du flux bibliothèque avec une séquence explicite :
1. push outbox
2. pull favorites
3. pull history
4. pull playlists :contentReference[oaicite:12]{index=12} :contentReference[oaicite:13]{index=13}

Conclusion :
la “library sync” actuelle est en réalité un **pipeline global de synchronisation utilisateur**, dont la bibliothèque n’est qu’un sous-ensemble central.

---

## 3. Fichiers centraux du flux

Les éléments explicitement présents dans le snapshot sont :

### Cœur bibliothèque
- `library_cloud_sync_service.dart`
- `cloud_sync_cursor_store.dart`
- `cloud_sync_preferences.dart`
- `history_sync_applier.dart`
- `playlists_sync_applier.dart`
- `watchlist_sync_applier.dart` :contentReference[oaicite:14]{index=14}

### Data sources cloud
- `supabase_favorites_sync_data_source.dart`
- `supabase_history_sync_data_source.dart`
- `supabase_playlists_sync_data_source.dart` :contentReference[oaicite:15]{index=15}

### Couche de présentation / orchestration
- `library_cloud_sync_providers.dart`
- `library_cloud_sync_bootstrapper.dart` :contentReference[oaicite:16]{index=16} :contentReference[oaicite:17]{index=17}

### Surcouche transverse
- `comprehensive_cloud_sync_service.dart` :contentReference[oaicite:18]{index=18} :contentReference[oaicite:19]{index=19}

---

## 4. Ce qui est synchronisé exactement

La lecture du snapshot permet d’identifier au minimum ces familles d’objets.

### Bibliothèque stricte
- favoris / watchlist
- historique
- playlists :contentReference[oaicite:20]{index=20} :contentReference[oaicite:21]{index=21}

### État et préférences de sync
- curseurs de sync par table et profil
- préférence `auto_sync_enabled` stockée en secure storage :contentReference[oaicite:22]{index=22} :contentReference[oaicite:23]{index=23}

### Éléments hors bibliothèque mais inclus dans la sync complète
- profils
- sources IPTV
- préférences utilisateur (accent color, player prefs, locale, etc.) :contentReference[oaicite:24]{index=24} :contentReference[oaicite:25]{index=25}

### Conclusion
Le nom “library sync” est partiellement trompeur :
le flux utilisateur exposé en UI déclenche en pratique une sync plus large que la seule bibliothèque. :contentReference[oaicite:26]{index=26} :contentReference[oaicite:27]{index=27}

---

## 5. Déclenchement du flux

## 5.1 Bootstrap précoce

`LibraryCloudSyncBootstrapper` est monté tôt pour garantir que le contrôleur est actif rapidement et peut réagir aux changements de profil ou de client Supabase. :contentReference[oaicite:28]{index=28}

### Conséquence
La sync bibliothèque n’est pas attachée seulement à la page `library`.
Elle fait partie du comportement global de l’application.

---

## 5.2 Auto-sync

Le contrôleur écoute :
- `selectedProfileIdProvider`
- `supabaseClientProvider` :contentReference[oaicite:29]{index=29}

Il conserve aussi :
- un `autoSyncEnabled` persistant ;
- un debounce ;
- une protection contre des tentatives trop rapprochées. :contentReference[oaicite:30]{index=30} :contentReference[oaicite:31]{index=31}

### Interprétation
L’auto-sync dépend au minimum :
- de l’existence d’un profil sélectionné ;
- de la disponibilité de Supabase ;
- de la préférence locale d’activation.

---

## 5.3 Sync manuelle

`syncNow(reason: 'manual')` :
- vérifie qu’un profil est sélectionné ;
- vérifie que Supabase est disponible ;
- refuse si une sync est déjà en cours ;
- crée un token d’annulation logique ;
- peut faire en best-effort un refresh profils + IPTV avant la sync complète ;
- exécute ensuite la sync complète ;
- pull les préférences après le push ;
- invalide `libraryPlaylistsProvider` ;
- émet `AppEventType.librarySynced`. :contentReference[oaicite:32]{index=32}

### Interprétation
Le bouton “sync now” n’est pas limité à la bibliothèque :
il sert aussi de point de rafraîchissement global pour une partie de l’état utilisateur. :contentReference[oaicite:33]{index=33}

---

## 6. Le pipeline réel

Voici la meilleure lecture du pipeline à partir du snapshot.

## Étape 1 — Préconditions
Le contrôleur récupère :
- `profileId`
- `SupabaseClient`
- l’état courant de sync
- le service de sync complet
- `slProvider` pour certaines opérations auxiliaires. :contentReference[oaicite:34]{index=34}

Si profil ou client manquent, la sync manuelle échoue côté UI avec un message d’erreur adapté. :contentReference[oaicite:35]{index=35}

---

## Étape 2 — Annulation logique / cohérence
Le contrôleur incrémente un `_syncToken` et utilise `shouldCancel()` pour annuler implicitement une sync :
- si une autre sync démarre ;
- si le profil courant change pendant l’exécution. :contentReference[oaicite:36]{index=36}

### Interprétation
Le système ne repose pas seulement sur des `Future` simples.
Il intègre déjà une logique de cohérence de contexte utilisateur.

---

## Étape 3 — Sync complète transverse
Le contrôleur appelle `comprehensiveService.syncAll(...)`. :contentReference[oaicite:37]{index=37}

Le `ComprehensiveCloudSyncService` exécute ensuite cette séquence :
1. synchroniser la bibliothèque via `LibraryCloudSyncService`
2. synchroniser les profils
3. pousser les sources IPTV
4. synchroniser les préférences utilisateur :contentReference[oaicite:38]{index=38}

### Interprétation
La bibliothèque est le premier maillon d’une sync plus large,
mais elle n’est pas le seul domaine concerné.

---

## Étape 4 — Moteur bibliothèque spécialisé
À l’intérieur, `LibraryCloudSyncService.syncAll(...)` exécute la séquence suivante :
1. `_pushOutbox(...)`
2. `_pullFavorites(...)`
3. `_pullHistory(...)`
4. `_pullPlaylists(...)` :contentReference[oaicite:39]{index=39} :contentReference[oaicite:40]{index=40}

### Lecture importante
La sync bibliothèque suit un modèle :
- d’abord pousser les changements locaux ;
- ensuite récupérer les changements distants.

C’est une architecture de type :
**local-first avec réconciliation cloud**.

---

## 7. Le cœur de la sync bibliothèque

## 7.1 Push local -> cloud via outbox

`LibraryCloudSyncService` dépend de `SyncOutboxRepository` et boucle sur les éléments pending avec une limite de 200. :contentReference[oaicite:41]{index=41} :contentReference[oaicite:42]{index=42}

### Interprétation
Les mutations locales ne sont pas poussées immédiatement de manière ad hoc.
Elles passent par une file de sortie locale.

### Implication architecture
C’est un vrai mécanisme de synchronisation différée, pas un simple “save remote”.

---

## 7.2 Pull favorites

Le service crée `SupabaseFavoritesSyncDataSource(client)`. :contentReference[oaicite:43]{index=43}

La présence de `SupabaseFavoriteRow` avec :
- `id`
- `mediaType`
- `mediaId`
- `updatedAt`
- `deletedAtUtc`
montre que les favoris distants sont synchronisés avec métadonnées de dernière mise à jour et suppression logique possible. :contentReference[oaicite:44]{index=44}

L’application locale de ces changements se fait via `WatchlistSyncApplier`, qui :
- upsert dans `watchlist`
- ou remove selon le cas :contentReference[oaicite:45]{index=45}

### Interprétation
Les favoris sont synchronisés comme un flux incrémental appliqué sur la base locale.

---

## 7.3 Pull history

Le service utilise `SupabaseHistorySyncDataSource(client)` et applique ensuite les données distantes via `HistorySyncApplier`. :contentReference[oaicite:46]{index=46}

`HistorySyncApplier` :
- met à jour `history`
- insère si nécessaire
- conserve position, durée, saison, épisode, titre, poster, timestamp localisé en millisecondes :contentReference[oaicite:47]{index=47}

### Interprétation
L’historique est traité comme un état métier riche, pas juste une trace de contenu vu.

---

## 7.4 Pull playlists

Le service utilise `SupabasePlaylistsSyncDataSource(client)` puis applique localement via `PlaylistsSyncApplier`. :contentReference[oaicite:48]{index=48} :contentReference[oaicite:49]{index=49}

Le data source playlists documente explicitement :
- une table `playlists`
- une table `playlist_items`
- un `local_id` pour garder des identifiants locaux stables entre appareils tout en laissant Supabase gérer un UUID distant :contentReference[oaicite:50]{index=50}

### Interprétation
Les playlists ont le modèle de sync le plus sophistiqué :
elles ont une identité locale et distante, des items ordonnés, du soft-delete possible, et une couche de mapping.

---

## 7.5 Curseurs de sync

`CloudSyncCursorStore` stocke les curseurs par :
- table
- profil
avec une clé du type `cloud_sync.cursor.<table>.<profileId>` dans le secure storage. :contentReference[oaicite:51]{index=51}

Chaque curseur contient :
- `updated_at`
- `id`
et l’état initial remonte à `1970-01-01T00:00:00.000Z`. :contentReference[oaicite:52]{index=52}

### Interprétation
La sync est conçue pour être incrémentale et reprise table par table.

---

## 8. Sorties du flux

Quand la sync réussit, le contrôleur :
- met à jour l’état UI (`lastSuccessAtUtc`, fin de sync, clear error) ;
- invalide `libraryPlaylistsProvider` ;
- émet `AppEventType.librarySynced`. :contentReference[oaicite:53]{index=53}

Le bus d’événements global contient bien `librarySynced` comme type d’événement applicatif. :contentReference[oaicite:54]{index=54}

### Conséquence
Le succès de sync ne reste pas enfermé dans la feature `library`.
Il peut provoquer des rechargements dans d’autres sous-systèmes, comme `home`, qui écoute `iptvSynced` et `librarySynced`. :contentReference[oaicite:55]{index=55}

---

## 9. Ce que la sync library mélange aujourd’hui

La vérification du snapshot montre que ce sous-système mélange au moins 5 natures de responsabilité.

### 1. Persistance locale
- SQLite
- outbox
- watchlist/history/playlists local repositories
- secure storage pour préférences et curseurs :contentReference[oaicite:56]{index=56} :contentReference[oaicite:57]{index=57}

### 2. Accès cloud
- Supabase data sources dédiées pour favorites/history/playlists :contentReference[oaicite:58]{index=58} :contentReference[oaicite:59]{index=59} :contentReference[oaicite:60]{index=60}

### 3. Réconciliation / application locale
- appliers spécialisés par domaine :
  - watchlist
  - history
  - playlists :contentReference[oaicite:61]{index=61} :contentReference[oaicite:62]{index=62} :contentReference[oaicite:63]{index=63}

### 4. Orchestration UI / état
- contrôleur Riverpod
- auto-sync
- erreurs utilisateur
- sync manuelle
- invalidations de providers :contentReference[oaicite:64]{index=64} :contentReference[oaicite:65]{index=65}

### 5. Synchronisation utilisateur élargie
- profils
- IPTV
- préférences utilisateur via `ComprehensiveCloudSyncService` :contentReference[oaicite:66]{index=66}

### Conclusion
La dette principale n’est pas que le code de sync est “long”.
La dette principale est que plusieurs niveaux de responsabilité sont imbriqués.

---

## 10. Problèmes structurels confirmés

## 10.1 “Library sync” ne correspond pas au vrai périmètre
Le contrôleur de sync expose une action utilisateur unique, mais cette action déclenche plus que la bibliothèque : profils, IPTV et préférences y sont aussi inclus. :contentReference[oaicite:67]{index=67} :contentReference[oaicite:68]{index=68}

---

## 10.2 Le bootstrap est global
La sync est montée tôt et globalement via `LibraryCloudSyncBootstrapper`. :contentReference[oaicite:69]{index=69}

### Effet
Le comportement de sync devient une propriété globale de l’app, pas seulement de la feature `library`.

---

## 10.3 Le contrôleur UI orchestre encore des choses très profondes
Le contrôleur gère :
- validation contexte utilisateur ;
- annulation logique ;
- refresh best-effort de profils/IPTV ;
- lancement de la sync complète ;
- invalidations et event bus. :contentReference[oaicite:70]{index=70}

### Effet
La frontière entre contrôleur UI et orchestration transverse est poreuse.

---

## 10.4 L’outbox et les curseurs rendent la sync plus robuste, mais plus difficile à raisonner
Ils montrent une vraie architecture offline/local-first, mais augmentent aussi la complexité mentale. :contentReference[oaicite:71]{index=71} :contentReference[oaicite:72]{index=72}

---

## 10.5 Les playlists sont le sous-domaine le plus complexe
Elles ont :
- identité locale + distante
- items ordonnés
- table dédiée
- mapping stable entre devices :contentReference[oaicite:73]{index=73}

### Effet
Tout refactor de `library` devra traiter `playlist` comme un sous-domaine spécial, pas comme un simple tableau de favoris.

---

## 11. Carte synthétique du flux

```text
LibraryCloudSyncBootstrapper
  -> monte tôt le contrôleur de sync
  -> écoute profil + Supabase

LibraryCloudSyncController
  -> auto sync / manual sync
  -> vérifie profileId + client
  -> gère token d’annulation
  -> best-effort refresh profils + IPTV
  -> ComprehensiveCloudSyncService.syncAll(...)
  -> pullUserPreferences(...)
  -> invalide providers UI
  -> émet librarySynced

ComprehensiveCloudSyncService
  -> LibraryCloudSyncService.syncAll(...)
  -> sync profils
  -> push sources IPTV
  -> sync préférences utilisateur

LibraryCloudSyncService
  -> push outbox
  -> pull favorites
  -> pull history
  -> pull playlists

Sous-couches
  -> secure storage : prefs + cursors
  -> SQLite : watchlist/history/playlists/outbox
  -> Supabase data sources
  -> appliers locaux
```

---

## 12. Conclusion

A3 confirme que la sync bibliothèque de Movi est un **sous-système critique et distribué**.

Le point le plus important à retenir est le suivant :

### La sync bibliothèque actuelle mélange 3 niveaux qui devraient être plus distincts

1. moteur de synchronisation bibliothèque
2. synchronisation utilisateur globale
3. orchestration UI / bootstrap applicatif

Autrement dit :
le futur refactor ne devra pas simplement “nettoyer library”.
Il devra décider plus clairement :

* ce qui appartient à la bibliothèque ;
* ce qui appartient à la sync utilisateur globale ;
* ce qui appartient à la couche contrôleur / bootstrap.


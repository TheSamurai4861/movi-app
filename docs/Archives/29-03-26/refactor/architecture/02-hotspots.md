# Hotspots techniques — Movi
## Version 2 — lecture par propagation de complexité

## 1. Objet du document

Ce document identifie les zones du projet qui coûtent le plus cher à comprendre, à modifier et à stabiliser.

Un hotspot n’est pas forcément une zone “mal codée”.
C’est une zone qui :
- concentre plusieurs responsabilités ;
- relie plusieurs sous-systèmes ;
- propage facilement ses effets de bord ;
- rend le projet plus difficile à faire évoluer.

Cette V2 remplace la version précédente avec une approche plus stricte :
on cherche moins les gros dossiers, et plus les **points où la complexité se diffuse**.

---

## 2. Règle de lecture

Pour ce projet, un hotspot important n’est pas simplement :
- un dossier volumineux ;
- un module technique riche ;
- ou une feature qui a beaucoup de fichiers.

Un hotspot prioritaire est une zone qui remplit au moins 3 de ces conditions :

- elle traverse plusieurs sous-systèmes ;
- elle décide de comportements applicatifs globaux ;
- elle mélange logique technique et logique métier ;
- elle impose un coût mental élevé pour suivre un flux ;
- elle dépend d’un état global ou d’un mécanisme d’invalidation ;
- elle contient de la compatibilité legacy ;
- elle rend les frontières du projet moins lisibles.

---

## 3. Résumé exécutif

Les hotspots les plus importants ne sont pas tous du même type.

### Hotspots structurels majeurs
Ce sont les vrais centres de gravité à traiter en premier :
1. startup / bootstrap
2. bridge Riverpod / GetIt / état global
3. bibliothèque synchronisée

### Hotspots d’organisation architecturale
Ils augmentent le coût du projet à moyen terme :
4. frontières `core` / `features` / `shared`
5. sous-système IPTV dispersé
6. settings à double responsabilité

### Hotspots secondaires
Ils méritent un passage plus tard :
7. invalidations / événements globaux
8. search trop spécialisé côté navigation/models
9. i18n / artefacts legacy
10. `core/widgets` trop large

Conclusion directe :
le projet doit d’abord être simplifié là où la complexité **circule**, pas là où elle est juste visible.

---

## 4. Hotspot n°1 — Startup / Bootstrap
**Gravité : critique**

## Pourquoi ce hotspot est prioritaire
Le startup est aujourd’hui une zone où se mélangent :
- initialisation technique ;
- injection de dépendances ;
- état global ;
- vérifications d’environnement ;
- logging ;
- sync IPTV ;
- routage implicite du lancement. :contentReference[oaicite:3]{index=3} :contentReference[oaicite:4]{index=4}

Le snapshot montre explicitement :
- `WidgetsFlutterBinding.ensureInitialized()`
- chargement d’environnement
- `registerConfig(...)`
- `initDependencies(...)`
- replacement de `AppStateController` dans GetIt
- sanity check Supabase
- `LoggingModule.register()`
- setup du `XtreamSyncService`
- écoute des préférences de sync
- arrêt du service au `dispose`. :contentReference[oaicite:5]{index=5}

En parallèle, `core/startup` contient déjà plusieurs briques :
- `app_launch_criteria.dart`
- `app_launch_orchestrator.dart`
- `app_startup_gate.dart`
- `app_startup_provider.dart` :contentReference[oaicite:6]{index=6}

## Pourquoi c’est plus grave qu’un simple “startup un peu gros”
Parce que le bootstrap ne sert plus seulement à préparer l’app :
il influence déjà la manière dont plusieurs sous-systèmes existent ensemble.

Autrement dit :
**le startup n’est plus un préambule, c’est un moteur de composition du projet.**

## Symptômes
- responsabilité trop large ;
- ordre d’initialisation important ;
- plusieurs effets de bord cachés au lancement ;
- dépendance à DI, Supabase, sync, état global.

## Risque principal
Chaque refactor important devra “passer par” cette zone, donc tant qu’elle reste floue, tout le reste reste plus risqué.

## Décision
C’est le premier hotspot à cartographier en détail.

---

## 5. Hotspot n°2 — Bridge Riverpod / GetIt / état global
**Gravité : critique**

## Pourquoi ce hotspot est prioritaire
Le projet utilise simultanément :
- `flutter_riverpod`
- `get_it` :contentReference[oaicite:7]{index=7}

Mais le vrai signal fort, ce n’est pas juste la coexistence des deux.
C’est le fait que `app_startup_provider` expose explicitement l’instance Riverpod de `AppStateController` dans GetIt pour les services legacy qui attendent encore `sl<AppStateController>()`. :contentReference[oaicite:8]{index=8}

Le commentaire du code dit clairement que :
- `AppStateController` est un `Notifier<AppState>` Riverpod ;
- il ne doit pas être instancié via GetIt ;
- mais un bridge est maintenu pour compatibilité legacy. :contentReference[oaicite:9]{index=9}

## Pourquoi c’est un hotspot structurel
Parce qu’ici, la dette n’est pas locale.
Elle change la façon de raisonner sur tout le projet :
- où vit la source de vérité ?
- comment un service obtient ses dépendances ?
- comment tester un flux ?
- comment migrer proprement ?

## Symptômes
- deux systèmes mentaux de dépendances ;
- migration incomplète ;
- services legacy encore branchés sur GetIt ;
- état global utilisé comme charnière.

## Risque principal
Continuer à ajouter du code alors que la règle d’injection n’est pas stabilisée.

## Décision
Ce hotspot doit être traité comme un **problème de gouvernance de l’architecture**, pas comme un simple détail technique.

---

## 6. Hotspot n°3 — Bibliothèque synchronisée
**Gravité : critique**

## Pourquoi ce hotspot est prioritaire
La feature `library` n’est pas juste une page ou un ensemble de favoris.

Elle contient :
- curseurs de sync
- préférences de sync
- services de sync multiples
- appliers spécialisés
- datasources Supabase
- repositories locaux et distants
- bootstrapper de sync en présentation. :contentReference[oaicite:10]{index=10}

Le projet montre aussi que la sync library est branchée haut dans l’application via `LibraryCloudSyncBootstrapper` dans le `builder` global de `MaterialApp.router`. :contentReference[oaicite:11]{index=11}

## Pourquoi ce hotspot est plus dangereux qu’il n’en a l’air
Parce qu’il combine à la fois :
- données locales ;
- données cloud ;
- fusion d’état ;
- invalidations UI ;
- logique de démarrage ;
- état utilisateur.

Ce n’est donc pas une feature isolée, mais un **sous-système distribué**.

## Symptômes
- plusieurs services spécialisés ;
- logique éclatée entre `application`, `data`, `presentation` ;
- lien avec l’état global ;
- couplage fort avec playlists, historique, watchlist, playback progress.

## Risque principal
Vouloir corriger des bugs localement sans voir que le vrai problème vient de la topologie globale de la sync.

## Décision
Le refactor devra prendre `library` et `playlist` ensemble, avec les repositories locaux/cloud, pas séparément.

---

## 7. Hotspot n°4 — Frontière floue entre `core`, `features` et `shared`
**Gravité : élevée**

## Pourquoi ce hotspot est important
Le projet a une structure ambitieuse, mais les frontières sont devenues moins évidentes.

`core` contient énormément de responsabilités :
- auth
- config
- di
- network
- parental
- performance
- preferences
- profile
- reporting
- router
- security
- startup
- state
- storage
- supabase
- theme
- widgets, etc. :contentReference[oaicite:12]{index=12}

En parallèle, `shared` héberge des services loin d’être anodins :
- `iptv_content_resolver_impl.dart`
- `hybrid_similarity_service.dart`
- `tmdb_cache_data_source.dart`
- `tmdb_client.dart`
- `tmdb_image_resolver.dart`
- `playlist_tmdb_enrichment_service.dart`
- `tmdb_id_resolver_service.dart` :contentReference[oaicite:13]{index=13}

## Pourquoi c’est un vrai hotspot
Parce qu’un projet devient difficile à maintenir quand on ne sait plus intuitivement :
- ce qui appartient à une feature ;
- ce qui relève de l’infra pure ;
- ce qui peut être partagé ;
- ce qui ne devrait pas l’être.

## Symptômes
- `shared` porte des responsabilités métier structurantes ;
- `core` porte à la fois infra, état, UI et logique transverse ;
- la géographie du projet ne raconte plus clairement son architecture.

## Risque principal
Continuer à ajouter du code dans une structure déjà floue, ce qui rendra les futurs refactors plus chers.

## Décision
Ce hotspot ne se corrige pas d’abord avec des déplacements de fichiers, mais avec des règles d’appartenance claires.

---

## 8. Hotspot n°5 — Sous-système IPTV dispersé
**Gravité : élevée**

## Pourquoi ce hotspot est important
`features/iptv` est un pilier métier du produit :
- ajout de sources Xtream/Stalker
- refresh de catalogues
- playlists
- datasources cache/remote
- repositories
- services credentials / stream URL builders. :contentReference[oaicite:14]{index=14}

Mais ce n’est pas tout :
- le startup pilote aussi un `XtreamSyncService` ;
- `core/storage` contient plusieurs stores IPTV ;
- `settings` contient une grande partie de l’UI d’administration des sources. :contentReference[oaicite:15]{index=15} :contentReference[oaicite:16]{index=16}

## Pourquoi c’est un hotspot de propagation
Parce que la logique IPTV ne vit pas à un seul endroit :
elle est éclatée entre feature métier, stockage, settings, startup et sécurité.

## Symptômes
- fort volume de fichiers ;
- cycle de vie d’une source difficile à suivre ;
- responsabilité répartie entre plusieurs familles de dossiers.

## Risque principal
Avoir une complexité légitime, mais mal contenue.

## Décision
Le bon refactor ne sera pas “réduire iptv”, mais reconstituer un flux lisible bout en bout :
source → validation → stockage → refresh → sélection active → consommation par l’app.

---

## 9. Hotspot n°6 — `settings` à double responsabilité
**Gravité : élevée**

## Pourquoi ce hotspot est important
`features/settings` contient à la fois :
- réglages utilisateur ;
- profil utilisateur ;
- about ;
- mais aussi toute l’administration des sources IPTV :
  - `iptv_connect_page.dart`
  - `iptv_source_add_page.dart`
  - `iptv_source_edit_page.dart`
  - `iptv_source_organize_page.dart`
  - `iptv_source_select_page.dart`
  - `iptv_sources_page.dart` :contentReference[oaicite:17]{index=17}

## Pourquoi ce hotspot est trompeur
Parce que le nom `settings` donne l’impression d’une feature secondaire ou de confort, alors qu’elle sert aussi d’interface à un cœur métier critique.

## Symptômes
- mélange entre préférences et administration IPTV ;
- lecture trompeuse de l’arborescence ;
- couplage implicite entre settings et moteur IPTV.

## Risque principal
Sous-estimer la portée d’un refactor dans `settings`.

## Décision
Il faut distinguer conceptuellement :
- settings utilisateur
- settings IPTV / source management

Même si le code n’est pas encore déplacé.

---

## 10. Hotspot n°7 — Événements globaux et invalidations
**Gravité : moyenne à élevée**

## Pourquoi ce hotspot existe
Le projet a :
- `app_event_bus.dart`
- `app_state.dart`
- `app_state_controller.dart`
- `app_state_provider.dart` :contentReference[oaicite:18]{index=18}

L’event bus expose déjà des événements globaux comme :
- `iptvSynced`
- `librarySynced` :contentReference[oaicite:19]{index=19}

## Pourquoi ce hotspot n’est pas au niveau des trois premiers
Parce que l’existence d’un bus ou d’un état global n’est pas un problème en soi.

Le problème apparaît quand ils deviennent :
- le raccourci par défaut entre sous-systèmes ;
- un moyen d’éviter des frontières claires ;
- un diffuseur d’effets de bord difficiles à tracer.

## Symptômes
- événements applicatifs globaux ;
- dépendances diffuses ;
- risque d’invalidation manuelle excessive.

## Risque principal
Créer un système où les causes et effets sont trop éloignés.

## Décision
À surveiller de près pendant les refactors, mais pas nécessairement le tout premier chantier isolé.

---

## 11. Hotspot n°8 — Search trop spécialisée côté navigation
**Gravité : moyenne**

## Pourquoi ce hotspot existe
La feature `search` montre un pattern de spécialisation poussée :
- instant search
- paginated search
- history
- watch providers
- plusieurs pages de résultats
- plusieurs modèles d’args proches :
  - `genre_all_results_args.dart`
  - `genre_results_args.dart`
  - `provider_all_results_args.dart`
  - `provider_results_args.dart`
  - `search_results_args.dart` :contentReference[oaicite:20]{index=20}

## Pourquoi ce n’est pas un hotspot prioritaire
Parce que cette complexité semble surtout locale à la feature, et beaucoup moins propagée que celle de startup ou library.

## Symptômes
- verbosité ;
- duplication légère probable ;
- multiplication des modèles de navigation.

## Risque principal
Accumuler de la friction de maintenance.

## Décision
Bon candidat à une simplification secondaire, pas à un chantier de départ.

---

## 12. Hotspot n°9 — i18n / legacy résiduel
**Gravité : moyenne**

## Pourquoi ce hotspot existe
Le snapshot montre :
- `app_fr_MM.arb`
- `app_localizations_bu.dart` :contentReference[oaicite:21]{index=21}

## Pourquoi ce hotspot reste secondaire
Parce qu’il ressemble davantage à du bruit ou de la dette locale qu’à un nœud de propagation majeur.

## Symptômes
- fichiers atypiques ;
- possible backup ou génération obsolète ;
- source de vérité potentiellement floue pour la localisation.

## Risque principal
Bruit structurel inutile.

## Décision
À qualifier puis nettoyer, mais après les grands sous-systèmes.

---

## 13. Hotspot n°10 — `core/widgets` comme zone d’accumulation
**Gravité : moyenne**

## Pourquoi ce hotspot existe
`core/widgets` contient :
- nav bar
- boutons
- cards média/personne
- placeholder
- splash
- refresh indicator
- wrappers UI divers. :contentReference[oaicite:22]{index=22}

## Pourquoi ce n’est pas prioritaire
Parce que ce type de dette UI est gênant, mais ne structure pas tout le projet autant que startup, IPTV ou library.

## Symptômes
- mélange possible entre design system, widgets d’app et widgets métier partagés ;
- risque de dossier “commode”.

## Risque principal
Continuer à diluer les frontières UI.

## Décision
À traiter plus tard, quand la structure globale sera stabilisée.

---

## 14. Classement final révisé

## Niveau 1 — Hotspots qui pilotent la roadmap
1. startup / bootstrap
2. bridge Riverpod / GetIt / état global
3. bibliothèque synchronisée

## Niveau 2 — Hotspots d’architecture
4. frontières `core` / `features` / `shared`
5. sous-système IPTV dispersé
6. `settings` à double responsabilité

## Niveau 3 — Hotspots secondaires
7. événements globaux / invalidations
8. search trop spécialisée
9. i18n / legacy
10. `core/widgets`

---

## 15. Conséquence directe pour le refactor

La conséquence la plus importante de cette seconde analyse est la suivante :

### Il ne faut pas commencer par les zones les plus visibles
Par exemple :
- `movie`
- `tv`
- `person`
- `saga`
- certaines pages UI

ne sont pas les meilleurs premiers candidats, même si elles ont beaucoup de fichiers.

### Il faut commencer par les zones qui propagent la complexité
En priorité :
1. startup
2. injection / état global
3. bibliothèque synchronisée
4. frontières de structure
5. cycle de vie IPTV

---

## 16. Conclusion

La dette principale du projet n’est pas celle d’une app “désorganisée”.
C’est celle d’une app **trop composée**, où certains nœuds ont pris une importance disproportionnée :
- ils orchestrent ;
- ils relient ;
- ils diffusent ;
- ils servent de charnière entre plusieurs couches.

La bonne stratégie de simplification est donc :
- moins de refactor “par écran” ;
- plus de refactor “par point de propagation”.

Autrement dit :
le vrai enjeu n’est pas seulement de raccourcir le code,
mais de **réduire le nombre d’endroits depuis lesquels la complexité peut contaminer le reste du projet**.
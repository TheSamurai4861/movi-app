# Audit initial — Movi

## 1. Objet du document

Ce document constitue la première photographie d’ensemble du projet Movi avant toute phase de simplification ou de refactor majeur.

L’objectif n’est pas encore de corriger le projet, mais de :
- comprendre sa structure réelle ;
- identifier les zones de complexité ;
- distinguer la complexité utile de la complexité accidentelle ;
- préparer une roadmap de transformation propre et progressive.

Ce document sert de base de référence pour les phases suivantes.

---

## 2. Résumé du projet

Movi est une application Flutter multi-plateforme orientée lecture et gestion de contenus IPTV légaux, avec :
- authentification utilisateur ;
- gestion de profils ;
- ajout et gestion de sources IPTV ;
- navigation type plateforme de streaming ;
- lecture vidéo ;
- bibliothèque utilisateur ;
- synchronisation cloud ;
- internationalisation ;
- adaptation à plusieurs formats d’écran.

Le projet vise clairement une expérience riche, ambitieuse et premium, avec une séparation entre couches techniques, couches métier et couches UI déjà bien engagée. :contentReference[oaicite:0]{index=0}

---

## 3. Stack et dépendances majeures

Le snapshot montre une stack Flutter moderne avec notamment :
- `flutter_riverpod`
- `get_it`
- `go_router`
- `dio`
- `supabase_flutter`
- `sqflite`
- `flutter_secure_storage`
- `media_kit`
- `media_kit_video`
- `flutter_svg`
- `google_fonts` :contentReference[oaicite:1]{index=1}

### Lecture initiale
Cette stack est cohérente pour le produit visé. En revanche, la présence simultanée de **Riverpod** et **GetIt** signale déjà une architecture potentiellement plus complexe à comprendre et maintenir qu’un système unifié. :contentReference[oaicite:2]{index=2} :contentReference[oaicite:3]{index=3}

---

## 4. Structure générale observée

Le projet est structuré autour de grands blocs :

- `lib/l10n`
- `lib/src/core`
- `lib/src/features`
- `lib/src/shared`

Cette structure montre une volonté de séparation forte entre :
- le socle technique transversal ;
- les fonctionnalités métier ;
- certains services et modèles mutualisés ;
- les ressources de localisation. :contentReference[oaicite:4]{index=4}

### 4.1 `core`
Le dossier `core` regroupe une très grande partie de l’infrastructure et des briques transverses :
- auth
- config
- di
- error
- logging
- network
- parental
- performance
- preferences
- profile
- reporting
- responsive
- router
- security
- startup
- state
- storage
- supabase
- theme
- utils
- widgets :contentReference[oaicite:5]{index=5}

### 4.2 `features`
Le dossier `features` contient les blocs produit principaux :
- category_browser
- home
- iptv
- library
- movie
- person
- player
- playlist
- saga
- search
- settings
- shell
- tv
- welcome
- auth (côté feature) :contentReference[oaicite:6]{index=6}

### 4.3 `shared`
Le dossier `shared` contient des services et objets mutualisés importants, notamment autour de :
- TMDB
- similarité
- résolution de contenu IPTV
- value objects média
- ui models
- route args partagés :contentReference[oaicite:7]{index=7}

### 4.4 `l10n`
Le projet est internationalisé avec plusieurs fichiers ARB et générés, dont :
- `app_en.arb`
- `app_fr.arb`
- `app_de.arb`
- `app_es.arb`
- `app_it.arb`
- `app_nl.arb`
- `app_pl.arb`
- `app_pt.arb`
- `app_fr_MM.arb`
- `app_localizations_bu.dart` :contentReference[oaicite:8]{index=8}

---

## 5. Constats globaux

## 5.1 Le projet est riche et sérieusement structuré
Premier constat important : le projet n’est pas désorganisé au sens “chaotique”.  
Au contraire, il montre une vraie intention d’architecture :
- modularisation poussée ;
- séparation data/domain/presentation dans plusieurs features ;
- présence de services dédiés ;
- gestion du responsive ;
- gestion du player ;
- gestion des profils ;
- gestion de la sync. :contentReference[oaicite:9]{index=9}

Le problème perçu n’est donc pas un manque de structure, mais plutôt une **sur-densité structurelle**.

## 5.2 Le projet semble avoir dépassé son modèle d’organisation initial
La structure actuelle donne l’impression d’un projet qui a grandi par ajouts successifs, avec des couches et modules ajoutés au fur et à mesure.  
Cela produit un effet “usine à gaz” :
- beaucoup de dossiers ;
- beaucoup de services ;
- beaucoup de sous-couches ;
- plusieurs systèmes transverses qui se croisent.

Le projet n’est pas illogique, mais il devient coûteux à lire mentalement.

## 5.3 Le socle `core` est devenu très large
`core` contient à la fois :
- de l’infrastructure pure ;
- de l’état global ;
- des modules de démarrage ;
- des éléments UI ;
- des services proches du métier ;
- des utilitaires ;
- des widgets applicatifs. :contentReference[oaicite:10]{index=10}

Cela peut rendre la frontière entre :
- technique transverse,
- logique applicative,
- et UI partagée
moins nette qu’elle ne devrait l’être.

## 5.4 `shared` semble porter plus que du vrai “partagé neutre”
Le dossier `shared` contient plusieurs briques importantes :
- `tmdb_client`
- `tmdb_cache_data_source`
- `tmdb_image_resolver`
- `tmdb_id_resolver_service`
- `hybrid_similarity_service`
- `iptv_content_resolver_impl` :contentReference[oaicite:11]{index=11}

Cela suggère que `shared` n’est pas seulement un endroit de petits helpers réutilisables, mais aussi un lieu où vivent des services métier structurants.  
C’est potentiellement une source de flou architectural.

---

## 6. Point majeur : coexistence Riverpod + GetIt

Le projet utilise à la fois :
- Riverpod pour une partie de l’état et des providers ;
- GetIt pour l’injection de dépendances et l’enregistrement de modules. :contentReference[oaicite:12]{index=12}

Cette coexistence devient particulièrement visible dans le startup.

Dans `app_startup_provider`, l’application :
- initialise l’environnement ;
- enregistre la config ;
- initialise les dépendances ;
- puis expose explicitement l’instance Riverpod de `AppStateController` dans GetIt pour les services legacy qui dépendent encore de `sl<AppStateController>()`. :contentReference[oaicite:13]{index=13} :contentReference[oaicite:14]{index=14}

Le commentaire du code indique clairement que :
- `AppStateController` est un `Notifier<AppState>` Riverpod ;
- il ne doit pas être instancié via GetIt ;
- mais une compatibilité legacy est maintenue en le remplaçant dans GetIt. :contentReference[oaicite:15]{index=15}

### Interprétation
C’est un signal très fort de dette architecturale contrôlée :
- le projet a déjà commencé à basculer vers Riverpod ;
- mais conserve encore une dépendance legacy à GetIt ;
- ce qui oblige à maintenir un bridge explicite entre deux systèmes.

### Conséquence
Comprendre le flux réel de dépendances est plus difficile que nécessaire.  
Ce point sera probablement un des plus gros leviers de simplification future.

---

## 7. Point majeur : startup très chargé

Le startup fait beaucoup de choses :
- `WidgetsFlutterBinding.ensureInitialized()`
- chargement de l’environnement ;
- enregistrement de la configuration ;
- initialisation des dépendances ;
- bridge Riverpod / GetIt pour `AppStateController` ;
- sanity check Supabase ;
- enregistrement du logging ;
- setup de la sync IPTV ;
- écoute dynamique des préférences de sync ;
- arrêt propre du service au dispose. :contentReference[oaicite:16]{index=16} :contentReference[oaicite:17]{index=17}

À cela s’ajoutent plusieurs fichiers dédiés au lancement :
- `app_launch_criteria.dart`
- `app_launch_orchestrator.dart`
- `app_startup_gate.dart`
- `app_startup_provider.dart` :contentReference[oaicite:18]{index=18}

L’orchestrateur de lancement référence en plus :
- auth
- profile
- selected source
- credentials vault
- app event bus
- app state
- local repository IPTV
- refresh catalog IPTV
- preload home
- destination bootstrap. :contentReference[oaicite:19]{index=19}

### Interprétation
Le démarrage n’est plus un simple bootstrap technique.  
Il est devenu un **sous-système applicatif complet**, avec :
- état ;
- phases ;
- critères ;
- destination ;
- orchestration ;
- effets de bord. :contentReference[oaicite:20]{index=20}

### Risque
Quand le startup devient trop intelligent :
- il devient plus dur à tester ;
- plus dur à raisonner ;
- plus sensible aux effets de bord ;
- et plus difficile à refactorer sans casser des parcours critiques.

---

## 8. Point majeur : zone library / sync particulièrement dense

La feature `library` apparaît comme un hotspot fort.

Le snapshot montre notamment :
- `cloud_sync_cursor_store.dart`
- `cloud_sync_preferences.dart`
- `comprehensive_cloud_sync_service.dart`
- `history_sync_applier.dart`
- `library_cloud_sync_service.dart`
- `playlists_sync_applier.dart`
- `watchlist_sync_applier.dart`
- plusieurs repositories locaux et Supabase
- des providers dédiés
- un bootstrapper de sync côté présentation. :contentReference[oaicite:21]{index=21}

Dans `LibraryCloudSyncService`, on voit clairement :
- un cursor store ;
- un outbox ;
- trois appliers distincts ;
- une sync séquencée `push -> pull favorites -> pull history -> pull playlists`. :contentReference[oaicite:22]{index=22}

### Interprétation
La bibliothèque ne gère pas seulement des favoris ou playlists.  
Elle embarque un véritable moteur de synchronisation multi-source.

### Conclusion provisoire
Cette zone mérite une attention particulière en phase de refactor, car elle concentre :
- de la logique locale ;
- de la logique remote ;
- de la fusion d’état ;
- des curseurs ;
- des files d’attente ;
- plusieurs types d’objets synchronisés.

C’est probablement un des endroits où la simplification apportera le plus de valeur.

---

## 9. Point majeur : `core/widgets` et UI partagée volumineux

Le dossier `core/widgets` contient beaucoup de composants UI applicatifs :
- `movi_bottom_nav_bar`
- `movi_favorite_button`
- `movi_items_list`
- `movi_media_card`
- `movi_person_card`
- `movi_pill`
- `movi_placeholder_card`
- `movi_primary_button`
- `overlay_splash`
- `syncable_refresh_indicator`
- etc. :contentReference[oaicite:23]{index=23}

### Interprétation
Il existe déjà une forme de design system / UI kit applicatif.  
C’est positif.

### Vigilance
Mais ce dossier peut facilement devenir :
- soit un vrai socle design system,
- soit un dépôt hétérogène de widgets “pratiques”.

Il faudra plus tard clarifier quels widgets sont :
- réellement génériques ;
- liés à la navigation shell ;
- liés à des features métier ;
- ou simplement partagés “par commodité”.

---

## 10. Point de vigilance : i18n et artefacts potentiellement legacy

Le snapshot montre :
- plusieurs langues principales ;
- un fichier `app_fr_MM.arb` ;
- un fichier `app_localizations_bu.dart`. :contentReference[oaicite:24]{index=24}

### Interprétation provisoire
À ce stade, il est impossible d’affirmer que ces fichiers sont inutiles.  
En revanche, ils sont suffisamment atypiques pour être considérés comme **suspects**.

### Hypothèse
Ils peuvent correspondre à :
- des expérimentations anciennes ;
- un backup manuel ;
- une génération obsolète ;
- une locale de test restée dans le projet.

### Décision phase 0
Ne pas les supprimer maintenant.  
Les marquer comme **éléments à vérifier**.

---

## 11. Parcours critiques identifiés

Les parcours suivants sont considérés comme critiques pour la stabilité et la lisibilité future du projet.

### 11.1 Lancement de l’application
Raisons :
- startup dense ;
- orchestration de lancement ;
- dépendances multiples ;
- lien fort avec auth, profils, IPTV et home. :contentReference[oaicite:25]{index=25} :contentReference[oaicite:26]{index=26}

### 11.2 Authentification et accès
Raisons :
- `core/auth`
- `auth_gate`
- repository Supabase auth
- liens avec startup et routing. :contentReference[oaicite:27]{index=27}

### 11.3 Gestion des profils
Raisons :
- création, sélection, persistance, profil courant, chiffrement IPTV, use cases multiples. :contentReference[oaicite:28]{index=28}

### 11.4 Gestion des sources IPTV
Raisons :
- sources Xtream / Stalker
- stockage local
- synchronisation
- pages de settings dédiées
- services de credentials et catalog refresh. :contentReference[oaicite:29]{index=29}

### 11.5 Home / preload home
Raisons :
- enrichissement continue watching ;
- hero metadata ;
- dépendances TMDB, IPTV, app state ;
- preload depuis le lancement. :contentReference[oaicite:30]{index=30} :contentReference[oaicite:31]{index=31}

### 11.6 Player
Raisons :
- media_kit
- PIP
- brightness / volume
- sélection de tracks
- services d’épisode suivant
- gestion de sources vidéo. :contentReference[oaicite:32]{index=32}

### 11.7 Library / sync cloud
Raisons :
- multiplicité des repositories ;
- logique locale + cloud ;
- outbox + cursor + appliers ;
- providers de bootstrap et sync. :contentReference[oaicite:33]{index=33} :contentReference[oaicite:34]{index=34}

### 11.8 Navigation shell et routing
Raisons :
- `go_router`
- shell multi-layout
- politique de rétention des onglets
- redirect guard
- routes nombreuses. :contentReference[oaicite:35]{index=35} :contentReference[oaicite:36]{index=36}

---

## 12. Hypothèses de complexité accidentelle

À ce stade, plusieurs hypothèses de complexité accidentelle sont retenues.

### H1 — Double système d’injection
Riverpod + GetIt + bridge explicite entre les deux. :contentReference[oaicite:37]{index=37}

### H2 — Startup devenu trop responsable
Le bootstrap ne fait plus seulement de l’initialisation technique ; il orchestre aussi une partie du comportement applicatif. :contentReference[oaicite:38]{index=38} :contentReference[oaicite:39]{index=39}

### H3 — Frontière floue entre `core`, `features` et `shared`
Certains services majeurs vivent dans `shared`, d’autres dans `core`, d’autres dans les features, ce qui peut compliquer la compréhension du “bon endroit” pour une responsabilité donnée. :contentReference[oaicite:40]{index=40}

### H4 — Sync bibliothèque très éclatée
Le modèle de sync semble riche mais dispersé entre plusieurs couches, appliers, datasources et providers. :contentReference[oaicite:41]{index=41} :contentReference[oaicite:42]{index=42}

### H5 — Présence possible de legacy
Certains fichiers ou variantes de localisation paraissent suspects et doivent être qualifiés. :contentReference[oaicite:43]{index=43}

### H6 — `core` trop large
Le socle porte beaucoup de responsabilités et pourrait masquer plusieurs sous-domaines qui mériteraient des frontières plus nettes. :contentReference[oaicite:44]{index=44}

---

## 13. Forces du projet à préserver

L’objectif de la future transformation ne doit pas être de “casser” l’ambition du projet.

Les qualités visibles à préserver sont :

### 13.1 Vision produit forte
Le projet couvre déjà des usages riches et cohérents :
- onboarding ;
- profil ;
- IPTV ;
- home ;
- player ;
- bibliothèque ;
- recherche ;
- détails média ;
- shell multi-device. :contentReference[oaicite:45]{index=45}

### 13.2 Modularisation déjà avancée
Même si elle semble aujourd’hui trop dense, la modularisation actuelle donne une bonne base pour une simplification structurée.

### 13.3 Capacité multi-plateforme réelle
Le shell dispose de layouts large, mobile et TV, avec une politique de rétention explicite des onglets. :contentReference[oaicite:46]{index=46} :contentReference[oaicite:47]{index=47}

### 13.4 Richesse fonctionnelle du player et de la bibliothèque
Ce sont des zones complexes, mais aussi différenciantes.

---

## 14. Faiblesses perçues à confirmer

Les faiblesses suivantes sont probables mais restent à confirmer dans les documents suivants :

- trop de responsabilités dans le lancement ;
- difficulté de lecture globale du graphe de dépendances ;
- trop de points d’entrée mentaux pour comprendre une logique ;
- frontière imparfaite entre infra, métier transverse et feature ;
- coût de maintenance élevé sur la sync bibliothèque ;
- présence possible de fichiers résiduels / legacy.

---

## 15. Décisions de phase 0

Pour la suite du chantier, les décisions suivantes sont retenues :

### 15.1 Gel fonctionnel
Pendant la phase de simplification :
- pas de nouvelle feature majeure ;
- pas d’ajout d’abstraction non nécessaire ;
- priorité à la lisibilité, à la cartographie et au tri.

### 15.2 Principe directeur
Le but n’est pas de “rendre l’architecture plus théorique”.  
Le but est de :
- réduire le nombre de chemins mentaux ;
- clarifier les responsabilités ;
- supprimer les couches qui n’apportent pas de valeur ;
- rendre le projet plus facile à faire évoluer.

### 15.3 Zones prioritaires à cartographier ensuite
Les prochains documents devront détailler en priorité :
1. startup ;
2. DI / dépendances ;
3. library sync ;
4. frontières `core` / `features` / `shared` ;
5. routing / shell ;
6. éléments legacy potentiels.

---

## 16. Conclusion

Le projet Movi n’est pas un projet “sale” ou “mal conçu”.  
C’est un projet ambitieux, structuré, riche, mais qui semble avoir accumulé plus de sophistication que ce qu’un seul développeur peut facilement manipuler au quotidien.

Le problème principal n’est pas l’absence d’architecture.  
Le problème principal est probablement une **architecture devenue trop coûteuse à lire et à porter mentalement**.

La suite du travail devra donc viser non pas à ajouter de nouvelles couches, mais à :
- clarifier ;
- fusionner ;
- réduire ;
- documenter ;
- hiérarchiser.

Ce document constitue la base de départ de cette transformation.
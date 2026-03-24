# Cartographie des features — Movi
## Version 2 — lecture par sous-systèmes et parcours

## 1. Objet du document

Ce document ne cherche pas à lister chaque dossier du projet comme une feature autonome.

Son rôle est de :
- reconstituer les **vrais sous-systèmes fonctionnels** de Movi ;
- distinguer les blocs visibles en UI des moteurs métier qu’ils masquent ;
- repérer les zones qui doivent être pensées ensemble pendant le refactor ;
- éviter une erreur classique : refactorer “page par page” alors que la dette est en réalité transverse.

Cette V2 remplace la première cartographie trop proche de l’arborescence.

---

## 2. Principe de lecture retenu

Le projet sera lu selon 4 niveaux :

### Niveau A — Parcours fondateurs
Ce sont les grands flux sans lesquels l’application ne fonctionne pas :
- entrer dans l’application ;
- avoir un profil valide ;
- disposer d’une source IPTV active ;
- arriver sur le shell ;
- lire un contenu ;
- retrouver sa bibliothèque.

### Niveau B — Sous-systèmes métier
Ce sont les moteurs internes du produit :
- bootstrap / lancement ;
- identité utilisateur ;
- gestion IPTV ;
- découverte de contenus ;
- lecture ;
- bibliothèque synchronisée.

### Niveau C — Façades UI
Certaines “features” du dossier `features/` sont en réalité surtout des façades de présentation :
- `settings`
- `welcome`
- `search`
- `movie`
- `tv`
- `person`
- `saga`

### Niveau D — Support transverse
Ce niveau regroupe ce qui alimente presque tout le reste :
- router
- state
- storage
- preferences
- supabase
- shared services
- responsive
- security

---

## 3. Vue d’ensemble révisée

Au lieu de voir 15 features à peu près équivalentes, il est plus juste de voir **6 gros sous-systèmes**.

### 3.1 Système d’entrée dans l’application
Bloc composé de :
- `core/startup`
- `features/welcome`
- `core/router`
- `features/shell`
- une partie de `core/auth`
- une partie de `core/profile`

C’est le système qui décide :
- si l’app peut démarrer ;
- si l’utilisateur est authentifié ;
- si un profil existe ;
- si une source IPTV est prête ;
- où envoyer l’utilisateur ensuite. :contentReference[oaicite:5]{index=5}

### 3.2 Système d’identité utilisateur
Bloc composé de :
- `core/auth`
- `core/profile`
- `core/parental`
- certains providers transverses

Il gère :
- session ;
- profils ;
- règles enfant / PIN ;
- contraintes liées au profil courant. :contentReference[oaicite:6]{index=6}

### 3.3 Système IPTV
Bloc composé de :
- `features/iptv`
- stockage local IPTV dans `core/storage`
- credentials/security
- pages d’administration dans `features/settings`

Il gère :
- ajout de source Xtream / Stalker ;
- comptes et endpoints ;
- refresh catalogues ;
- playlists ;
- chiffrement / credentials ;
- persistance locale et parfois sync distante. :contentReference[oaicite:7]{index=7}

### 3.4 Système de découverte / navigation contenu
Bloc composé de :
- `features/home`
- `features/search`
- `features/category_browser`
- `features/movie`
- `features/tv`
- `features/person`
- `features/saga`
- services partagés TMDB / enrichissement / résolution

Il gère :
- accueil ;
- résultats de recherche ;
- catégories ;
- fiches détail ;
- enrichissement de contenu ;
- affichage de metadata. :contentReference[oaicite:8]{index=8} :contentReference[oaicite:9]{index=9}

### 3.5 Système de lecture
Bloc composé de :
- `features/player`
- parties streaming de `movie` et `tv`
- services Xtream / URL builders
- historique de lecture / progression

Il gère :
- player vidéo ;
- tracks ;
- PIP ;
- luminosité/volume ;
- épisode suivant ;
- source vidéo exploitable. :contentReference[oaicite:10]{index=10}

### 3.6 Système de bibliothèque synchronisée
Bloc composé de :
- `features/library`
- `features/playlist`
- repositories locaux dans `core/storage`
- sync Supabase
- historique / continue watching / favoris

Il gère :
- favoris ;
- historique ;
- progression ;
- playlists ;
- sync cloud ;
- bootstrap de sync côté UI. :contentReference[oaicite:11]{index=11}

---

## 4. Sous-systèmes prioritaires réels

Le refactor ne doit pas partir des noms de pages mais des blocs qui concentrent le plus de dette structurelle.

### Priorité 1 — Bootstrap / entrée
Pourquoi :
- cœur du démarrage ;
- touche auth, profil, IPTV, home, shell ;
- concentre beaucoup de décisions applicatives.

Blocs concernés :
- `core/startup`
- `features/welcome`
- `core/router`
- `features/shell` :contentReference[oaicite:12]{index=12}

### Priorité 2 — IPTV
Pourquoi :
- métier central du produit ;
- beaucoup de couches ;
- source de dépendances avec settings, player, home, profile, storage.

Blocs concernés :
- `features/iptv`
- pages IPTV dans `features/settings`
- stockage IPTV dans `core/storage`
- security/credentials associés. :contentReference[oaicite:13]{index=13}

### Priorité 3 — Bibliothèque synchronisée
Pourquoi :
- forte densité ;
- logique locale + cloud ;
- plusieurs repositories et services spécialisés ;
- probablement un des plus gros coûts mentaux du projet.

Blocs concernés :
- `features/library`
- `features/playlist`
- local repositories
- Supabase sync datasources. :contentReference[oaicite:14]{index=14}

### Priorité 4 — Support transverse trop central
Pourquoi :
- une partie de la dette ne vient pas des features mais de la structure qui les relie.

Blocs concernés :
- `core/state`
- `core/di`
- `shared`
- `core/storage`
- `core/preferences` :contentReference[oaicite:15]{index=15}

---

## 5. Cartographie réécrite par familles

## 5.1 Famille A — Entrée dans l’application

### A1. startup
**Nature réelle**  
Sous-système d’orchestration, pas simple utilitaire de lancement.

**Contenu visible**
- critères de lancement
- gate de startup
- orchestrateur
- provider de startup :contentReference[oaicite:16]{index=16}

**Rôle**
- préparer l’application ;
- décider des prérequis ;
- orchestrer le passage vers l’état “app utilisable”.

**Constat**
Ce bloc n’est pas une feature UI.  
C’est un moteur applicatif transversal.

**Priorité**
Très haute.

---

### A2. welcome
**Nature réelle**  
Façade de parcours d’entrée.

**Contenu visible**
- pages welcome user
- source select
- source loading
- splash bootstrap
- child profile preload
- bootstrap providers :contentReference[oaicite:17]{index=17}

**Rôle**
- recueillir les premières infos utilisateur ;
- guider l’ajout / chargement d’une source ;
- afficher la couche UX du bootstrap.

**Constat**
Une partie de la complexité de `welcome` appartient en fait à `startup` et au système IPTV.

**Priorité**
Haute, mais surtout comme interface du bootstrap.

---

### A3. shell
**Nature réelle**  
Système de navigation applicative multi-formats.

**Contenu visible**
- layouts mobile / large / TV
- destinations
- retention policy
- shell page
- shell controller/providers :contentReference[oaicite:18]{index=18}

**Rôle**
- stabiliser la navigation principale ;
- adapter l’expérience selon le device.

**Constat**
Le shell doit être pensé avec le routeur, pas séparément.

**Priorité**
Haute.

---

### A4. router
**Nature réelle**  
Infrastructure produit, pas simple support technique.

**Contenu visible**
- route ids / names / paths
- app router
- route catalog
- launch redirect guard
- player route args :contentReference[oaicite:19]{index=19}

**Rôle**
- exprimer les parcours réels ;
- articuler bootstrap, welcome, shell, player et détails contenus.

**Constat**
Le routeur participe à la dette d’entrée au même titre que startup.

**Priorité**
Haute.

---

## 5.2 Famille B — Identité utilisateur

### B1. auth
**Nature réelle**  
Socle d’accès à l’application.

**Contenu visible**
- auth repository
- supabase auth repository
- auth providers
- auth gate
- OTP page côté feature :contentReference[oaicite:20]{index=20}

**Rôle**
- authentification ;
- contrôle d’accès de base ;
- lien avec session Supabase.

**Constat**
Bloc important, mais visiblement moins volumineux que startup/library/IPTV.

**Priorité**
Moyenne à haute.

---

### B2. profile
**Nature réelle**  
Système de contexte utilisateur actif.

**Contenu visible**
- CRUD profils
- sélection du profil courant
- providers nombreux
- `iptv_cipher_provider`
- service de profil sélectionné :contentReference[oaicite:21]{index=21}

**Rôle**
- définir le profil courant ;
- injecter contexte et préférences ;
- porter certaines règles parentales et IPTV.

**Constat**
Ce n’est pas un simple détail de personnalisation ; c’est un pivot transversal.

**Priorité**
Haute.

---

### B3. parental
**Nature réelle**  
Extension de l’identité et des règles d’accès.

**Contenu visible**
- session parentale
- recovery PIN
- content rating
- age policy
- maturity classifiers :contentReference[oaicite:22]{index=22}

**Rôle**
- protéger certains contenus ;
- dépendre du profil ;
- influencer éventuellement recherche, lecture ou affichage.

**Constat**
Bloc sensible, mais pas premier candidat au refactor initial.

**Priorité**
Moyenne.

---

## 5.3 Famille C — Moteur IPTV

### C1. iptv
**Nature réelle**  
Sous-système métier principal de l’application.

**Contenu visible**
- ajout Xtream / Stalker
- refresh catalogues
- comptes
- playlists Xtream
- repositories et datasources dédiés
- URL builders / credentials edge services :contentReference[oaicite:23]{index=23}

**Rôle**
- connecter la promesse produit au contenu réel ;
- fournir catalogues, playlists et accès lecture.

**Constat**
`iptv` n’est pas une feature parmi d’autres : c’est un pilier métier central.

**Priorité**
Très haute.

---

### C2. settings (partie IPTV)
**Nature réelle**  
Façade d’administration du sous-système IPTV.

**Contenu visible**
- `iptv_connect_page`
- `iptv_source_add_page`
- `iptv_source_edit_page`
- `iptv_source_organize_page`
- `iptv_source_select_page`
- `iptv_sources_page` :contentReference[oaicite:24]{index=24}

**Rôle**
- exposer à l’utilisateur la gestion des sources ;
- servir de point d’entrée administratif au moteur IPTV.

**Constat**
`settings` mélange deux choses :
- préférences utilisateur classiques ;
- console de gestion des sources IPTV.

Cette double responsabilité devra probablement être clarifiée plus tard.

**Priorité**
Haute, mais surtout en lien avec `iptv`.

---

## 5.4 Famille D — Découverte et détails contenus

Cette famille doit être pensée comme un **continuum** :
recherche → catégorie → détail → lecture / ajout bibliothèque

### D1. home
**Nature réelle**  
Façade principale de découverte.

**Contenu visible**
- home feed
- hero metadata
- continue watching enrichment
- IPTV sections
- widgets d’accueil nombreux :contentReference[oaicite:25]{index=25}

**Rôle**
- afficher la proposition de valeur immédiatement ;
- agréger contenus IPTV, métadonnées et historique.

**Constat**
Le home dépend fortement d’autres sous-systèmes, mais n’est pas forcément la source principale de la dette.

**Priorité**
Moyenne à haute.

---

### D2. search
**Nature réelle**  
Porte d’entrée universelle vers les contenus.

**Contenu visible**
- instant search
- paginated search
- history
- genres
- watch providers
- pages de résultats multiples
- modèles d’args nombreux et parfois très proches :contentReference[oaicite:26]{index=26} :contentReference[oaicite:27]{index=27}

**Rôle**
- interroger films, séries, personnes, sagas ;
- ouvrir des vues de résultats ;
- relancer certaines recherches selon le profil courant. :contentReference[oaicite:28]{index=28}

**Constat**
La feature semble fonctionnellement utile, mais verbeuse côté présentation/navigation.

**Priorité**
Moyenne à haute.

---

### D3. category_browser
**Nature réelle**  
Extension de navigation, plutôt que feature indépendante majeure.

**Contenu visible**
- repository de catégorie
- page de catégorie
- grid/header
- args dédiés :contentReference[oaicite:29]{index=29}

**Rôle**
- explorer un ensemble paginé par catégorie.

**Constat**
Bloc secondaire, sans priorité immédiate de refactor.

**Priorité**
Moyenne basse.

---

### D4. movie / tv / person / saga
**Nature réelle**  
Famille unifiée de détails contenus.

**Contenu visible**
- un module par type de contenu
- data source locale + remote pour plusieurs d’entre eux
- repository
- use cases de détail, recherche, enrichissement, watchlist
- pages detail et view models dédiés :contentReference[oaicite:30]{index=30}

**Rôle**
- afficher la fiche détaillée ;
- relier metadata, disponibilité, bibliothèque et lecture.

**Constat**
Ces modules sont séparés physiquement mais ont une structure très similaire.
Pour le refactor initial, il vaut mieux les lire comme une famille cohérente plutôt que comme quatre priorités indépendantes.

**Priorité**
Moyenne.

**Note particulière**
Leur simplification passera probablement davantage par :
- clarification de ce qui est mutualisable ;
- meilleure frontière avec `shared` ;
- limitation des abstractions répétées.

---

## 5.5 Famille E — Lecture

### E1. player
**Nature réelle**  
Sous-système autonome de lecture.

**Contenu visible**
- repositories `media_kit`
- PIP
- system control
- track selection
- next episode
- use cases volume/luminosité
- widgets de contrôles dédiés :contentReference[oaicite:31]{index=31}

**Rôle**
- jouer le contenu ;
- gérer les interactions natives ;
- faire le pont entre source vidéo et expérience utilisateur.

**Constat**
La complexité y est probablement en partie légitime.  
Le vrai enjeu n’est pas de “réduire le player” à tout prix, mais de vérifier que sa complexité reste bien confinée.

**Priorité**
Moyenne à haute.

---

## 5.6 Famille F — Bibliothèque utilisateur

### F1. library
**Nature réelle**  
Moteur de bibliothèque + sync, déguisé en feature UI.

**Contenu visible**
- repositories favoris / historique / continue watching / playback
- sync datasources Supabase
- cursor store
- sync preferences
- sync services multiples
- sync bootstrapper côté présentation :contentReference[oaicite:32]{index=32}

**Rôle**
- centraliser l’état utilisateur sur les contenus ;
- réconcilier local et cloud ;
- exposer cette bibliothèque dans l’UI.

**Constat**
`library` est un sous-système complet, pas une simple page.

**Priorité**
Très haute.

---

### F2. playlist
**Nature réelle**  
Sous-domaine de la bibliothèque.

**Contenu visible**
- repository dédié
- ordering service
- CRUD playlists
- reorder / pin / search playlists :contentReference[oaicite:33]{index=33}

**Rôle**
- gérer les listes utilisateur.

**Constat**
`playlist` a son module propre, mais reste conceptuellement dépendant du système `library`.
Pour la roadmap, il faut éviter de le traiter comme totalement séparé.

**Priorité**
Moyenne, mais incluse dans le périmètre de `library`.

---

## 5.7 Famille G — Réglages utilisateur purs

### G1. settings (partie user prefs)
**Nature réelle**  
Préférences et profil utilisateur côté interface.

**Contenu visible**
- `settings_page`
- `about_page`
- préférences utilisateur
- language / metadata / profil utilisateur :contentReference[oaicite:34]{index=34}

**Rôle**
- modifier préférences applicatives ;
- exposer l’UI des réglages classiques.

**Constat**
Cette partie est plus simple et plus “saine” que la partie IPTV.
Le vrai problème de `settings`, c’est son mélange de responsabilités.

**Priorité**
Moyenne.

---

## 6. Les faux amis de la cartographie

Cette seconde lecture montre plusieurs “pièges”.

### 6.1 `settings` n’est pas une seule feature homogène
Il y a au moins deux blocs dedans :
- réglages utilisateur
- administration des sources IPTV

### 6.2 `welcome` n’est pas seulement de l’onboarding
Il sert aussi d’habillage au bootstrap réel.

### 6.3 `library` n’est pas qu’une page de favoris
C’est un moteur de sync et de persistance utilisateur.

### 6.4 `movie`, `tv`, `person`, `saga` ne doivent pas monopoliser la priorité
Ils sont visibles, mais la dette structurelle semble plus concentrée dans bootstrap / IPTV / library / transverse.

### 6.5 `shared` n’est pas un simple fourre-tout de helpers
Il contient des services structurants :
- TMDB client/cache/image resolver
- IPTV content resolver
- similarity
- enrichment services :contentReference[oaicite:35]{index=35}

---

## 7. Blocs transverses à lire comme “infrastructure produit”

Ces blocs ne sont pas des features visibles, mais ils modèlent fortement la complexité réelle.

### 7.1 state
- `app_state`
- `app_state_controller`
- `app_event_bus`
- provider associé :contentReference[oaicite:36]{index=36}

Rôle :
porter un état global et potentiellement connecter plusieurs sous-systèmes.

### 7.2 storage
- base SQLite
- migrations
- repositories locaux
- outbox sync
- stores IPTV
- secure storage :contentReference[oaicite:37]{index=37}

Rôle :
servir d’infrastructure persistante commune.

### 7.3 preferences
- locale
- player
- accent color
- source IPTV sélectionnée
- profil sélectionné
- sync IPTV :contentReference[oaicite:38]{index=38}

Rôle :
porter le contexte utilisateur courant.

### 7.4 shared
- TMDB
- enrichissement
- résolution contenu
- value objects transverses
- route args partagés
- playback history providers :contentReference[oaicite:39]{index=39}

Rôle :
mutualiser des services qui deviennent parfois quasi centraux.

---

## 8. Nouvelle priorisation

## P1 — Sous-systèmes à traiter en premier
1. startup / welcome / router / shell
2. iptv + admin IPTV dans settings
3. library + playlist + sync
4. state / storage / shared / preferences

## P2 — Blocs à clarifier ensuite
1. profile
2. search
3. settings utilisateur pur
4. home

## P3 — Blocs à documenter sans les refactorer d’abord
1. movie
2. tv
3. person
4. saga
5. category_browser
6. parental
7. player

Note :
`player` reste techniquement dense, mais sa complexité semble davantage métier/légitime que celle de certains blocs transverses.

---

## 9. Carte finale simplifiée

### Entrer dans Movi
- startup
- welcome
- auth
- profile
- router
- shell

### Brancher le contenu réel
- iptv
- security/credentials
- stockage IPTV
- admin IPTV dans settings

### Découvrir le contenu
- home
- search
- category_browser
- movie
- tv
- person
- saga

### Lire le contenu
- player
- builders de sources
- historique / progression

### Retrouver son univers perso
- library
- playlist
- favoris
- continue watching
- sync cloud

### Support produit transverse
- state
- storage
- preferences
- supabase
- shared
- responsive
- theme
- logging
- network

---

## 10. Conclusion

La bonne lecture du projet Movi n’est pas :
“beaucoup de petites features à nettoyer”.

La bonne lecture est plutôt :
“quelques gros sous-systèmes fortement connectés, entourés de façades UI”.

Les blocs qui ressortent comme **vrais centres de gravité** sont :
- le système d’entrée (`startup` / `welcome` / `router` / `shell`) ;
- le système IPTV ;
- le système bibliothèque/sync ;
- la couche transverse (`state`, `storage`, `shared`, `preferences`). :contentReference[oaicite:40]{index=40}

La conséquence pour la roadmap est simple :
- ne pas refactorer “movie puis tv puis person” en premier ;
- commencer par les endroits où se décide la structure globale de l’application.
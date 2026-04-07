# Phase 1 — Cadrage et inventaire complet des règles de focus TV

## 1. Objet du document

Ce document clôt la **phase 1** du chantier TV pour le projet.

Il constitue la **source de vérité fonctionnelle** avant toute modification large de l’implémentation focus.

Il est construit à partir :
- du routeur `GoRouter`
- des pages réellement présentes dans le projet
- des onglets internes du shell
- des écrans ouverts hors route directe depuis l’UI
- des arbitrages métier déjà validés

Ce document ne décrit pas encore le code cible de phase 2.  
Il décrit **quoi doit être vrai** sur chaque écran TV.

---

## 2. Périmètre couvert

## 2.1 Inclus

Le périmètre couvre :
- les routes `GoRouter`
- les onglets internes du shell
- les pages poussées via `MaterialPageRoute`
- les écrans interactifs nécessaires au parcours utilisateur TV
- les états `loading`, `error`, `empty`
- les règles de sortie et de restauration du focus

## 2.2 Exclus

Sont exclus du périmètre produit TV principal :
- les écrans de debug purs
- les widgets non navigables seuls
- les détails d’implémentation des overlays, traités en phase 7
- les considérations d’animation ou de style non liées au focus

---

## 3. Glossaire des règles communes

## 3.1 Point d’entrée

Chaque page doit avoir un **point d’entrée de focus unique, explicite et déterministe**.

Si la restauration est impossible, le focus revient à ce point d’entrée.

## 3.2 Stop horizontal

Dans toute rangée, grille ou ligne d’actions :
- si le focus est au maximum à droite : **stop**
- si le focus est au maximum à gauche : **stop** ou **sortie explicite**
- aucun wrap implicite
- aucun passage automatique à la ligne suivante par débordement horizontal

Cette règle est obligatoire, notamment sur :
- `HomePage`
- `SearchPage`
- `SettingsPage`
- toutes les grilles et rangées de contenus

## 3.3 Navigation verticale

Le changement de ligne ou de section se fait uniquement via :
- `up`
- `down`
- ou une règle locale explicite

Jamais par débordement latéral implicite.

## 3.4 Sortie de page

Chaque page doit définir explicitement comment le focus sort :
- vers la sidebar shell
- vers le bouton retour
- vers la page précédente
- vers le déclencheur d’un overlay
- ou ne sort pas si la page est un terminal de navigation local

## 3.5 Restauration

Au retour sur une page :
- restaurer le **dernier élément focusé** si encore valide
- sinon revenir au **point d’entrée officiel**
- si l’élément restauré a disparu, revenir au fallback prévu de la page

## 3.6 États techniques

Chaque page doit documenter :
- `loading`
- `error`
- `empty`

Règles générales :
- `loading` : pas de navigation parasite ; focus absent ou conteneur neutre
- `error` : focus sur l’action corrective principale
- `empty` : focus sur l’action utile disponible

## 3.7 Shell

Dans le shell TV :
- `left` depuis le contenu tente d’abord un déplacement local
- si aucun déplacement local n’est possible, le focus revient à la sidebar
- `right` depuis la sidebar entre dans le contenu via le point d’entrée de l’onglet actif
- le shell mémorise le dernier focus du contenu par onglet

## 3.8 Formulaires

Dans les formulaires :
- entrée sur le premier champ utile
- `up/down` : champ précédent / suivant
- `left/right` : uniquement local au champ si pertinent
- `back` : ferme d’abord clavier/overlay, puis sort de la page

## 3.9 Overlays

Tout overlay doit :
- prendre le focus à l’ouverture
- garder le focus dans son scope
- rendre le focus au déclencheur à la fermeture

---

## 4. Inventaire exhaustif des écrans à couvrir

## 4.1 Lancement, bootstrap, onboarding, auth

- `LaunchGate` — `/launch`
- `WelcomeUserPage` — `/welcome/user`
- `WelcomeSourcePage` — `/welcome/sources`
- `WelcomeSourceSelectPage` — `/welcome/sources/select`
- `WelcomeSourceLoadingPage` — `/welcome/sources/loading`
- `AuthOtpPage` — `/auth/otp`
- `SplashBootstrapPage` — `/bootstrap`
- `ChildProfilePreloadPage` — écran présent dans le projet, hors route publique directe

## 4.2 Shell

- `AppShellPage` — `/`
- `HomePage` — onglet shell
- `SearchPage` — onglet shell
- `LibraryPage` — onglet shell
- `SettingsPage` — onglet shell

## 4.3 Recherche, résultats, catalogue

- `SearchResultsPage` — `/search_results`
- `ProviderResultsPage` — `/provider_results`
- `ProviderAllResultsPage` — `/provider_all_results`
- `GenreResultsPage` — `/genre_results`
- `GenreAllResultsPage` — `/genre_all_results`
- `CategoryPage` — `/category`

## 4.4 Bibliothèque

- `LibraryPlaylistDetailPage` — `/library/playlist`

## 4.5 Settings et IPTV

- `AboutPage` — `/settings/about`
- `SettingsSubtitlesPage` — `/settings/subtitles`
- `IptvConnectPage` — `/settings/iptv/connect`
- `IptvSourcesPage` — `/settings/iptv/sources`
- `IptvSourceSelectPage` — `/settings/iptv/sources/select-active`
- `IptvSourceAddPage` — `/settings/iptv/sources/add`
- `IptvSourceEditPage` — `/settings/iptv/sources/edit`
- `IptvSourceOrganizePage` — `/settings/iptv/sources/organize`
- `MoviPremiumPage` — écran poussé depuis l’UI hors route dédiée

## 4.6 Détails contenus

- `MovieDetailPage` — `/movie`, `/movie/:id`
- `TvDetailPage` — `/tv`, `/tv/:id`
- `PersonDetailPage` — `/person`, `/person/:id`
- `SagaDetailPage` — `/saga/detail`, `/saga/detail/:id`

## 4.7 Lecture et sécurité

- `VideoPlayerPage` — `/player`
- `PinRecoveryPage` — `/pin/recovery`

## 4.8 Fallback système

- `NotFoundPage` — écran de repli si route invalide ou arguments manquants

## 4.9 Debug

- `HomeHeroOverlayDebugPage` — `/debug/hero-overlays`
- hors périmètre produit TV principal

---

## 5. Matrice de focus par page

## 5.1 LaunchGate

- **Entry focus** : aucun focus interactif requis si redirection immédiate ; sinon action principale de reprise
- **Navigation** : pas de navigation libre ; écran transitoire
- **Sortie** : redirection automatique vers la prochaine étape
- **Restauration** : non applicable
- **Loading** : focus neutre
- **Error** : action principale de reprise ou retour
- **Empty** : non applicable

## 5.2 SplashBootstrapPage

- **Entry focus** : aucun si bootstrap purement transitoire
- **Navigation** : aucune navigation libre
- **Sortie** : automatique vers shell ou flow welcome
- **Restauration** : non applicable
- **Loading** : focus neutre
- **Error** : focus sur action de reprise si affichée
- **Empty** : non applicable

## 5.3 WelcomeUserPage

- **Entry focus** : premier champ ou première action principale du formulaire
- **Navigation** :
  - `down` : champ/action suivante
  - `up` : champ/action précédente
  - `left/right` : local au champ si nécessaire, sinon stop
- **Sortie** : page suivante du flow welcome ou retour précédent si autorisé
- **Restauration** : dernier champ focusé, sinon premier champ
- **Loading** : focus neutre
- **Error** : focus sur action principale de correction
- **Empty** : focus sur l’action principale disponible

## 5.4 WelcomeSourcePage

- **Entry focus** : première action principale d’ajout/connexion de source
- **Navigation** :
  - verticale entre sections et actions
  - horizontale seulement dans une ligne d’actions si présente
  - stop en bord de ligne
- **Sortie** : vers étape suivante du flow ou retour à l’étape précédente
- **Restauration** : dernier focus, sinon action principale
- **Loading** : focus neutre ou action de progression si applicable
- **Error** : focus sur action `Réessayer` ou alternative principale
- **Empty** : focus sur action d’ajout de source

## 5.5 WelcomeSourceSelectPage

- **Entry focus** : première source sélectionnable
- **Navigation** :
  - `up/down` : élément précédent / suivant
  - `left/right` : local à la ligne si plusieurs actions
- **Sortie** : validation de la source ou retour
- **Restauration** : dernière source focusée, sinon première source
- **Loading** : focus neutre
- **Error** : focus sur retour ou reprise
- **Empty** : focus sur retour ou ajout de source

## 5.6 WelcomeSourceLoadingPage

- **Entry focus** : aucun focus si écran purement de chargement
- **Navigation** : aucune navigation libre
- **Sortie** : automatique vers shell ou écran suivant
- **Restauration** : non applicable
- **Loading** : focus neutre
- **Error** : focus sur action principale de reprise
- **Empty** : non applicable

## 5.7 AuthOtpPage

- **Entry focus** : premier champ OTP ou premier caractère du composant OTP
- **Navigation** :
  - `left/right` : cellule OTP précédente / suivante si applicable
  - `down` : action principale
  - `up` : retour vers la zone OTP
- **Sortie** : validation, retour précédent, ou retour configuré après succès
- **Restauration** : dernier sous-champ focusé, sinon premier
- **Loading** : focus bloqué sur l’action en cours ou neutre
- **Error** : focus sur le premier champ invalide ou action de renvoi
- **Empty** : focus sur premier champ OTP

## 5.8 ChildProfilePreloadPage

- **Entry focus** : aucun si écran purement transitoire ; sinon action principale si interruption utilisateur possible
- **Navigation** : pas de navigation libre
- **Sortie** : automatique vers l’écran suivant
- **Restauration** : non applicable
- **Loading** : focus neutre
- **Error** : focus sur reprise ou retour
- **Empty** : non applicable

## 5.9 AppShellPage

- **Entry focus** :
  - sidebar si arrivée primaire shell en mode TV
  - ou restauration du dernier focus onglet si retour interne contrôlé
- **Navigation** :
  - `up/down` dans la sidebar
  - `right` depuis sidebar : entrée dans le point d’entrée de l’onglet actif
  - `left` depuis contenu : retour sidebar si aucun déplacement local n’est possible
- **Sortie** : vers pages poussées hors shell
- **Restauration** : dernier focus par onglet + dernier onglet actif
- **Loading** : shell navigable si contenu disponible ; sinon focus sidebar
- **Error** : bannière/action de reprise focusable sans casser le shell
- **Empty** : non applicable

## 5.10 HomePage

- **Entry focus** : action principale du hero
- **Navigation** :
  - `right` : élément suivant de la même ligne
  - en fin de ligne à droite : **stop**
  - `left` : élément précédent ; si bord gauche sans déplacement local, retour sidebar
  - `down` : section suivante
  - `up` : hero ou section précédente
- **Sortie** : retour sidebar via règle shell ; ouverture détail via `select`
- **Restauration** : dernier focus de l’onglet, sinon CTA principal
- **Loading** : focus neutre ou hero si déjà affiché
- **Error** : focus sur action principale de reprise
- **Empty** : focus sur action utile visible

## 5.11 SearchPage

- **Entry focus** : champ de recherche ou premier contrôle de recherche
- **Navigation** :
  - dans la zone de saisie : ne pas perturber l’édition
  - hors saisie :
    - `right` : élément suivant de la même ligne
    - fin de ligne à droite : **stop**
    - `left` : élément précédent ou retour sidebar si bord gauche sans déplacement local
    - `down` : ligne/section suivante
    - `up` : ligne/section précédente ou retour header
- **Sortie** : retour sidebar ; ouverture des résultats/détails
- **Restauration** : dernier focus de recherche ou dernier résultat local si retour court
- **Loading** : focus sur contrôle principal de recherche si la page reste active
- **Error** : focus sur action de reprise
- **Empty** : focus sur champ de recherche ou premier filtre

## 5.12 SearchResultsPage

- **Entry focus** : premier résultat de la grille
- **Navigation** :
  - `right` : item suivant même ligne, sinon **stop**
  - `left` : item précédent même ligne, sinon retour header ou stop selon position
  - `down` : item même colonne ligne suivante si disponible
  - `up` : item même colonne ligne précédente ou contrôles de recherche
  - si ligne suivante plus courte : choisir l’item le plus proche
- **Sortie** : retour page précédente ou retour à la recherche
- **Restauration** : dernier résultat focusé, sinon premier résultat
- **Loading** : focus neutre ou maintien sur la zone résultat si pagination
- **Error** : focus sur action `Réessayer`
- **Empty** : focus sur retour ou premier filtre de recherche

## 5.13 ProviderResultsPage

- **Entry focus** : premier résultat ou premier filtre d’en-tête si présent
- **Navigation** :
  - logique grille/liste stricte
  - `right` : suivant même ligne, sinon stop
  - `left` : précédent même ligne, sinon retour header/retour
  - `down/up` : même colonne ligne suivante/précédente
- **Sortie** : retour page précédente
- **Restauration** : dernier résultat focusé, sinon premier
- **Loading** : focus neutre
- **Error** : focus sur reprise
- **Empty** : focus sur retour

## 5.14 ProviderAllResultsPage

- **Entry focus** : premier résultat
- **Navigation** : identique à `ProviderResultsPage`
- **Sortie** : retour page précédente
- **Restauration** : dernier résultat, sinon premier
- **Loading** : focus neutre
- **Error** : focus sur reprise
- **Empty** : focus sur retour

## 5.15 GenreResultsPage

- **Entry focus** : premier résultat
- **Navigation** :
  - grille stricte
  - stop en bord de ligne
  - `up` vers l’en-tête ou les filtres
- **Sortie** : retour page précédente
- **Restauration** : dernier résultat, sinon premier
- **Loading** : focus neutre
- **Error** : focus sur reprise
- **Empty** : focus sur retour

## 5.16 GenreAllResultsPage

- **Entry focus** : premier résultat
- **Navigation** : identique à `GenreResultsPage`
- **Sortie** : retour page précédente
- **Restauration** : dernier résultat, sinon premier
- **Loading** : focus neutre
- **Error** : focus sur reprise
- **Empty** : focus sur retour

## 5.17 CategoryPage

- **Entry focus** : premier item de la grille
- **Navigation** :
  - `right` : item suivant même ligne, sinon stop
  - `left` : item précédent même ligne ; si première colonne, retour header/back ou stop
  - `down` : item même colonne ligne suivante
  - `up` : item même colonne ligne précédente ou header si première ligne
- **Sortie** : retour page précédente
- **Restauration** : dernier item focusé, sinon premier
- **Loading** : focus neutre
- **Error** : focus sur `Réessayer` ou retour
- **Empty** : focus sur retour

## 5.18 LibraryPage

- **Entry focus** : image de la première playlist ; sinon premier filtre
- **Navigation** :
  - zone hero/playlist :
    - `right` : actions voisines ou élément adjacent
    - `down` : premier bloc de contenu
  - filtres :
    - `left/right` : navigation dans les filtres
    - `down` : première playlist ou premier contenu
  - contenus :
    - `right` : suivant de la rangée, sinon stop
    - `left` : précédent de la rangée ; si bord gauche sans déplacement local, retour logique vers filtre/sidebar
    - `up/down` : bloc précédent/suivant
- **Sortie** : retour sidebar via shell ; ouverture détail playlist ou détail média
- **Restauration** : dernier focus, sinon image première playlist, sinon premier filtre
- **Loading** : focus neutre
- **Error** : focus sur reprise
- **Empty** : focus sur action de création/ajout la plus utile

## 5.19 LibraryPlaylistDetailPage

- **Entry focus** : action principale playlist ; sinon premier média
- **Navigation** :
  - hero : `down` vers la liste de médias
  - liste/grille :
    - `right` : suivant même ligne, sinon stop
    - `left` : précédent même ligne, sinon retour hero/back selon structure
    - `up/down` : ligne ou section précédente/suivante
- **Sortie** : retour page précédente
- **Restauration** : dernier élément focusé, sinon action principale ou premier média
- **Loading** : focus neutre
- **Error** : focus sur reprise ou retour
- **Empty** : focus sur retour ou action playlist utile

## 5.20 SettingsPage

- **Entry focus** : premier item interactif du niveau racine
- **Navigation** :
  - verticale stricte entre sections
  - si une ligne comporte plusieurs contrôles :
    - `right` : contrôle suivant
    - fin de ligne : **stop**
    - `left` : contrôle précédent ; si bord gauche racine shell, retour sidebar
  - `down/up` : réglage suivant/précédent
- **Sortie** : vers sous-pages settings, auth, premium, sidebar
- **Restauration** : dernier réglage focusé, sinon premier item
- **Loading** : focus sur premier réglage déjà interactif si la page reste utilisable
- **Error** : focus sur reprise ou retour
- **Empty** : focus sur premier contrôle utile

## 5.21 SettingsSubtitlesPage

- **Entry focus** : premier contrôle de sous-titres
- **Navigation** :
  - verticale par groupe
  - horizontale à l’intérieur d’une ligne de choix
  - stop en bord
- **Sortie** : retour page précédente
- **Restauration** : dernier contrôle focusé, sinon premier
- **Loading** : focus neutre
- **Error** : focus sur reprise ou retour
- **Empty** : focus sur retour

## 5.22 AboutPage

- **Entry focus** : premier élément interactif ; si page majoritairement informative, premier bouton retour/lien/action
- **Navigation** :
  - verticale simple
  - horizontale seulement si ligne d’actions
- **Sortie** : retour page précédente
- **Restauration** : dernier élément interactif, sinon premier
- **Loading** : non applicable ou neutre
- **Error** : focus sur retour
- **Empty** : focus sur retour

## 5.23 IptvConnectPage

- **Entry focus** : premier champ de connexion ou première action principale
- **Navigation** :
  - `down/up` : champ/action suivante/précédente
  - `left/right` : local au champ si pertinent, sinon stop
- **Sortie** : validation, retour settings, ou retour home selon le contexte
- **Restauration** : dernier champ, sinon premier
- **Loading** : focus bloqué sur l’action de connexion ou neutre
- **Error** : focus sur le champ/action à corriger
- **Empty** : focus sur premier champ

## 5.24 IptvSourcesPage

- **Entry focus** : première source de la liste ou action principale d’ajout
- **Navigation** :
  - verticale entre sources
  - horizontale entre actions d’une ligne si présentes
  - stop en bord
- **Sortie** : vers ajout, édition, organisation, sélection active, retour settings
- **Restauration** : dernière source ou action focusée, sinon première source
- **Loading** : focus neutre
- **Error** : focus sur action de reprise
- **Empty** : focus sur action d’ajout de source

## 5.25 IptvSourceSelectPage

- **Entry focus** : première source sélectionnable
- **Navigation** :
  - verticale sur la liste
  - horizontale locale si plusieurs actions sur une ligne
- **Sortie** : validation ou retour
- **Restauration** : dernière source focusée, sinon première
- **Loading** : focus neutre
- **Error** : focus sur reprise ou retour
- **Empty** : focus sur retour ou ajout de source

## 5.26 IptvSourceAddPage

- **Entry focus** : premier champ du formulaire
- **Navigation** :
  - `down/up` : champ/action suivante/précédente
  - `left/right` : local au champ
- **Sortie** : validation ou retour
- **Restauration** : dernier champ, sinon premier
- **Loading** : focus neutre ou action en cours
- **Error** : focus sur le premier champ invalide ou action de correction
- **Empty** : focus sur premier champ

## 5.27 IptvSourceEditPage

- **Entry focus** : premier champ éditable
- **Navigation** : identique à `IptvSourceAddPage`
- **Sortie** : validation ou retour
- **Restauration** : dernier champ, sinon premier
- **Loading** : focus neutre
- **Error** : focus sur le premier champ en erreur ou reprise
- **Empty** : focus sur retour si source introuvable

## 5.28 IptvSourceOrganizePage

- **Entry focus** : premier élément réorganisable ou première action principale
- **Navigation** :
  - verticale entre lignes
  - horizontale entre poignées/actions si présentes
  - aucune ambiguïté entre mode lecture et mode réorganisation
- **Sortie** : validation ou retour
- **Restauration** : dernier élément focusé, sinon premier
- **Loading** : focus neutre
- **Error** : focus sur reprise ou retour
- **Empty** : focus sur retour

## 5.29 MoviPremiumPage

- **Entry focus** : CTA principal d’abonnement/restauration
- **Navigation** :
  - `right` : autre action du hero si présente
  - `down` : avantages, offres, restauration
  - stop en bord de ligne
- **Sortie** : fermeture et retour au déclencheur
- **Restauration** : retour au déclencheur à la fermeture ; à la réouverture, CTA principal
- **Loading** : focus neutre ou CTA déjà visible selon état
- **Error** : focus sur action de reprise/restauration
- **Empty** : focus sur CTA principal

## 5.30 MovieDetailPage

- **Entry focus** : action principale `Regarder`
- **Navigation** :
  - hero :
    - `right` : autres actions
    - `left` : action précédente ou retour
    - `down` : synopsis / sections / recommandations
  - sections :
    - `right` : suivant même ligne, sinon stop
    - `left` : précédent même ligne ou retour logique vers début de section
    - `up/down` : section précédente/suivante
- **Sortie** : retour page précédente
- **Restauration** : dernier focus, sinon action principale
- **Loading** : focus neutre
- **Error** : focus sur retour ou reprise
- **Empty** : focus sur retour

## 5.31 TvDetailPage

- **Entry focus** : action principale de lecture/reprise
- **Navigation** :
  - hero :
    - `right` : autres actions
    - `down` : saisons/épisodes puis sections
  - saisons/épisodes :
    - navigation locale explicite
    - stop en bord
    - pas de wrap implicite
  - `up` : retour hero
- **Sortie** : retour page précédente
- **Restauration** : dernier focus, sinon action principale
- **Loading** : focus neutre
- **Error** : focus sur retour ou reprise
- **Empty** : focus sur retour

## 5.32 PersonDetailPage

- **Entry focus** : action principale
- **Navigation** :
  - `right` : autre action du header si présente
  - `down` : biographie / filmographie / sections associées
  - `up` : retour header
  - dans les rangées : stop en bord, pas de wrap
- **Sortie** : retour page précédente
- **Restauration** : dernier focus, sinon action principale
- **Loading** : focus neutre
- **Error** : focus sur retour ou reprise
- **Empty** : focus sur retour

## 5.33 SagaDetailPage

- **Entry focus** : action principale
- **Navigation** :
  - hero :
    - `right` : autres actions
    - `down` : contenus de la saga
  - contenus :
    - `right` : suivant même ligne, sinon stop
    - `left` : précédent même ligne
    - `up` : retour hero ou section précédente
- **Sortie** : retour page précédente
- **Restauration** : dernier focus, sinon action principale
- **Loading** : focus neutre
- **Error** : focus sur retour ou reprise
- **Empty** : focus sur retour

## 5.34 VideoPlayerPage

- **Entry focus** : surface player ou contrôle principal visible
- **Navigation** :
  - sans overlay :
    - `select` : affiche/masque les contrôles
    - `back` : sort du player ou ferme l’état courant
  - avec overlay :
    - `left/right` : seek ou navigation entre contrôles selon le mode
    - `up/down` : groupe de contrôle précédent/suivant
- **Sortie** : fermeture overlay puis retour page précédente
- **Restauration** : si overlay se ferme, retour au contrôle principal pertinent
- **Loading** : focus neutre ou contrôle principal si prêt
- **Error** : focus sur retour ou reprise
- **Empty** : non applicable

## 5.35 PinRecoveryPage

- **Entry focus** : premier champ ou première action principale
- **Navigation** :
  - verticale simple
  - horizontale seulement localement si besoin
- **Sortie** : validation ou retour
- **Restauration** : dernier contrôle, sinon premier
- **Loading** : focus neutre
- **Error** : focus sur correction principale
- **Empty** : focus sur premier champ ou retour

## 5.36 NotFoundPage

- **Entry focus** : action principale de retour vers un écran stable
- **Navigation** : très simple ; pas de navigation complexe
- **Sortie** : retour, home, ou fermeture selon contexte
- **Restauration** : non applicable ; toujours revenir à l’action principale
- **Loading** : non applicable
- **Error** : non applicable
- **Empty** : non applicable

---

## 6. Routes alias, redirections et implications focus

Les chemins suivants ne doivent pas être traités comme des pages autonomes avec focus propre durable :

- `/welcome` redirige vers `/welcome/user`
- `/search` redirige vers `/`
- `/library` redirige vers `/`
- `/settings` redirige vers `/`

Conséquence :
- la matrice de focus doit porter sur le **shell** et ses **onglets internes**
- pas sur ces alias comme écrans indépendants

---

## 7. Inventaire complémentaire des écrans ouverts hors route directe

Ces écrans doivent être inclus dans le périmètre fonctionnel TV car ils sont ouverts depuis l’UI :

- `MoviPremiumPage`
- dialogs de confirmation en bibliothèque
- dialogs de confirmation dans settings/IPTV
- bottom sheet `mark_as_unwatched`
- sheets de contenu restreint / premium lock si utilisées dans le parcours TV

Leur implémentation détaillée est traitée en phase 7, mais leur existence est désormais reconnue dans l’inventaire.

---

## 8. Pages critiques prioritaires pour la suite

Ordre de priorité de correction recommandé à partir de cette phase 1 :

1. `AppShellPage`
2. `HomePage`
3. `SearchPage`
4. `SearchResultsPage`
5. `LibraryPage`
6. `SettingsPage`
7. `MovieDetailPage`
8. `TvDetailPage`
9. `PersonDetailPage`
10. `SagaDetailPage`
11. `VideoPlayerPage`

Puis :
- `CategoryPage`
- `ProviderResultsPage`
- `GenreResultsPage`
- `LibraryPlaylistDetailPage`
- pages settings secondaires
- pages IPTV
- auth / onboarding
- overlays

---

## 9. Critère de fin de la phase 1

La phase 1 est considérée comme **terminée** car :

- toutes les pages navigables du projet ont été inventoriées
- les onglets shell sont explicitement couverts
- les écrans ouverts hors route directe depuis l’UI sont identifiés
- chaque page dispose d’une règle définie pour :
  - entry focus
  - navigation directionnelle
  - sortie
  - restauration
  - loading/error/empty
- les exceptions métier validées sont intégrées :
  - `HomePage` : stop en fin de ligne à droite
  - `SearchPage` : stop en fin de ligne à droite + grille à comportement strict
  - `LibraryPage` : entrée image première playlist sinon premier filtre
  - `SettingsPage` : même contrainte de stop horizontal
  - `PersonDetailPage` : entrée action principale

La phase 2 peut commencer sans ambiguïté fonctionnelle.
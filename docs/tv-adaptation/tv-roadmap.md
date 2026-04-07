J’ai inspecté le projet et je peux déjà te donner une base propre pour piloter l’adaptation TV.

Mon analyse est basée sur le code fourni, pas sur une exécution réelle de l’app. Donc ce qui suit est **vérifié par lecture de code**, mais **à confirmer par tests clavier/télécommande** sur device ou émulateur TV. Je m’aligne sur tes règles de séparation des responsabilités, de clarté et d’évolution progressive 

## Diagnostic

### Ce qui est déjà bien en place

Le projet a déjà une vraie fondation TV.

* Il existe une couche globale de navigation télécommande avec `MoviRemoteNavigation`.
* Il existe un composant réutilisable pour les éléments focusables, `MoviFocusableAction`, avec mise en valeur visuelle et `ensureVisible`.
* Le shell a déjà un coordinateur de focus (`ShellFocusCoordinator`) pour la sidebar et le retour au contenu.
* Certaines pages critiques ont déjà une logique TV explicite :

  * `Home`
  * `Library`
  * `Search`
  * `Settings`
  * `TvDetailPage`
  * plusieurs pages IPTV/formulaires

Donc on n’est pas face à un projet “non TV”. On est face à un projet **partiellement TV, mais pas encore homogène**.

### Le vrai problème actuel

Le focus est aujourd’hui **présent**, mais la règle de focus n’est pas **formalisée par page**.

En pratique, j’ai trouvé 4 niveaux de logique qui coexistent :

1. **globale**

   * `MoviRemoteNavigation` intercepte flèches / select / back

2. **shell**

   * `ShellFocusCoordinator`
   * sidebar ↔ contenu

3. **composants**

   * `MoviFocusableAction`
   * `MoviPrimaryButton`
   * `MoviEnsureVisibleOnFocus`

4. **pages locales**

   * règles ad hoc dans certaines pages (`TvDetailPage`, `CategoryGrid`, `LibraryPlaylistHero`, etc.)

Le résultat : la base est bonne, mais le comportement risque d’être **incohérent selon les écrans**.

## Constats importants

### 1. Le shell est le socle le plus mature

Le shell gère déjà correctement :

* autofocus sidebar en layout TV
* passage `sidebar -> contenu`
* retour `contenu -> sidebar`
* mémorisation partielle du dernier focus dans un onglet

C’est la bonne direction.

### 2. Les pages n’appliquent pas toutes le même contrat

Certaines pages enregistrent un **point d’entrée de focus** via `registerPreferredNode`, d’autres non.

Exemples déjà structurés :

* `Home`
* `Library`
* `Search`
* `Settings`

Exemples encore faibles ou partiels :

* `MovieDetailPage`
* `SagaDetailPage`
* `PersonDetailPage`
* `SearchResultsPage`
* `CategoryPage`
* `SettingsSubtitlesPage`

### 3. Certaines pages utilisent des widgets peu robustes pour TV

J’ai repéré des écrans où le focus repose encore beaucoup sur des widgets pas vraiment pensés comme contrat TV explicite.

Exemples typiques :

* `ChoiceChip`
* `GestureDetector`
* `ListTile`
* certains `ElevatedButton` sans nœud ni règle d’entrée
* `GridView` sans stratégie d’entrée/restauration cohérente

Ça peut fonctionner “par chance” avec le traversal Flutter, mais ce n’est pas assez robuste pour une app TV.

### 4. Les deep links / sous-pages n’ont pas encore de stratégie commune

Le shell a une vraie logique, mais les pages ouvertes hors shell ou en sous-navigation n’ont pas toutes :

* un focus initial déterministe
* une règle de retour
* une restauration du focus après fermeture de sheet/dialog
* une gestion uniforme des états loading / error / empty

### 5. Le projet manque d’une spécification de focus

Aujourd’hui, la logique est surtout dans le code.
Il manque un livrable simple du type :

* page
* point d’entrée focus
* ordre principal
* règle flèche gauche/droite/haut/bas
* sortie
* retour arrière
* restauration

C’est la première chose à produire avant de corriger massivement.

---

# Proposition de cible

Je te recommande une cible simple, sans sur-abstraction.

## Contrat de focus par page

Chaque page doit définir explicitement :

* **entry focus** : premier élément focusé à l’ouverture
* **primary axis** : vertical, horizontal, grille, mixte
* **left boundary**
* **right boundary**
* **up/down behavior**
* **back behavior**
* **restore behavior**
* **fallback state** si contenu vide / erreur / loading

## Règles globales à imposer

### Règle 1

Toute page navigable au remote doit avoir **un point d’entrée focusable déterministe**.

### Règle 2

Toute page doit avoir **une règle de sortie explicite** :

* retour page précédente
* retour sidebar
* fermeture overlay
* retour au trigger précédent

### Règle 3

Les layouts de type :

* formulaire
* liste horizontale
* grille
* hero + actions
  doivent partager des conventions communes.

### Règle 4

Le focus ne doit jamais dépendre uniquement du traversal implicite Flutter quand la page a une structure riche.

### Règle 5

Les états `loading`, `error`, `empty` doivent eux aussi avoir un comportement TV défini.

---

# Règles de focus proposées par famille de pages

## 1. Shell tabs

### Home

**Entrée**

* focus sur l’action principale du hero

**Navigation**

* droite : autres actions du hero puis contenu
* bas : première rangée de contenu
* gauche depuis contenu de premier niveau : retour sidebar

**Restauration**

* retour sur dernier élément focusé de l’onglet
* à défaut, retour sur action principale du hero

### Search

**Entrée**

* champ de recherche ou premier filtre, selon mode actif

**Navigation**

* si saisie active : ne pas détourner les flèches du champ
* hors saisie :

  * bas : résultats / genres / providers
  * gauche en bord : sidebar

**Restauration**

* revenir sur le champ si la page est rechargée
* revenir au dernier résultat si l’utilisateur revient d’un détail

### Library

**Entrée**

* premier filtre ou premier bloc action de bibliothèque

**Navigation**

* haut : header/filters
* bas : playlists / watchlist / history
* gauche en bord de page : sidebar

**Restauration**

* dernier élément de contenu si retour depuis détail playlist / détail média

### Settings

**Entrée**

* premier item de réglages

**Navigation**

* verticale stricte par section
* gauche : sidebar seulement si on est sur le premier niveau shell
* sous-pages settings : gauche/back = retour page précédente, pas sidebar

**Restauration**

* dernier réglage focusé dans l’onglet

---

## 2. Pages détail

### Movie detail

**Entrée**

* bouton principal “Regarder”

**Navigation**

* droite : autres actions (watchlist, playlist, signalement, etc.)
* bas : synopsis, saga, casting, recommandations
* haut depuis contenu : remonte au bloc hero

**Restauration**

* si retour depuis section basse, revenir sur dernier item focusé
* si ouverture fraîche, focus sur CTA principal

**Constat actuel**

* la page est moins explicitement pilotée TV que `TvDetailPage`
* il faudra l’aligner sur la même stratégie

### TV detail

**Entrée**

* bouton principal de lecture / reprise

**Navigation**

* hero très structuré
* saison/épisodes avec règles locales explicites
* retour gauche cohérent vers back/more

**Constat**

* c’est aujourd’hui une des pages les plus avancées
* elle doit devenir le modèle de référence pour les pages détail

### Person detail

**Entrée**

* bouton retour ou première action principale

**Navigation**

* bas : sections filmographie / séries
* les carrousels doivent conserver une règle uniforme avec les autres pages

### Saga detail

**Entrée**

* action principale

**Navigation**

* identique à `MovieDetailPage`
* bas vers liste des films de la saga

---

## 3. Pages liste / résultats

### Category page

**Entrée**

* premier item de grille

**Navigation**

* grille explicite
* gauche sur première colonne : back header ou page précédente
* haut sur première ligne : header
* bas sur dernière ligne : stop net, pas de comportement implicite étrange

**Constat**

* `CategoryGrid` a déjà une logique locale intéressante
* il faut la rattacher à un contrat page complet

### Search results

**Entrée**

* premier item résultat

**Navigation**

* grille explicite
* header focusable si présent
* bouton “charger plus” doit entrer dans l’ordre de focus de manière prévisible

**Constat**

* actuellement, la page est trop “mobile/desktop” dans son contrat

### Provider / Genre results

**Entrée**

* premier filtre ou premier item
* si header avec retour, celui-ci doit être joignable par `up`

### Library playlist detail

**Entrée**

* action principale playlist ou premier média
* si hero playlist existe, il doit porter les règles de transition vers la grille/liste

---

## 4. Onboarding / auth / formulaires

### Welcome user / source / auth OTP / IPTV connect / add / edit

**Entrée**

* premier champ

**Navigation**

* verticale stricte champ -> champ -> action principale
* select/enter sur champ ne doit pas casser la saisie
* back ferme clavier puis remonte au niveau précédent

**Constat**

* ces pages sont déjà plutôt bien préparées avec des `FocusNode`

### Source select / sources page / organize

**Entrée**

* première source ou première action principale

**Navigation**

* liste verticale ou grille simple
* retour explicite vers header ou page précédente

---

## 5. Player

### Video player

**Entrée**

* surface player focusée

**Navigation**

* select : afficher/masquer contrôles
* gauche/droite : seek ou navigation contrôles selon mode actif
* haut/bas : menus pistes / sous-titres / options si overlay ouvert
* back : ferme overlay, sinon sort du player

**Constat**

* il existe déjà une logique clavier
* elle doit être documentée comme contrat officiel TV

---

# Problèmes à traiter en priorité

## P0 — cohérence

Il faut arrêter d’ajouter du focus “au cas par cas” sans contrat commun.

## P1 — pages les plus visibles

À corriger d’abord :

* `Home`
* `Search`
* `Library`
* `Settings`
* `MovieDetailPage`
* `TvDetailPage`
* `SearchResultsPage`
* `CategoryPage`
* `VideoPlayerPage`

## P2 — widgets non standardisés

À normaliser :

* chips
* tiles
* boutons secondaires
* menus d’action
* grilles
* carrousels
* headers retour

## P3 — overlays

Dialogs, sheets, action menus et modales doivent :

* prendre le focus à l’ouverture
* piéger le focus localement
* rendre le focus au déclencheur à la fermeture

---

# Roadmap proposée

## Phase 1 — cadrage et inventaire complet

Livrable attendu :

* une **matrice de focus exhaustive par route/page**
* un **glossaire de règles communes**
* un **inventaire complet des écrans interactifs**, y compris pages shell, pages détail, listes, résultats, formulaires, overlays et player

À produire :

* liste de **toutes** les pages navigables du projet
* pour chacune :

  * entry focus
  * navigation directionnelle
  * sortie
  * restauration
  * état loading/error/empty

Contraintes :

* aucune implémentation large ne commence tant que la matrice n’est pas complète
* les exceptions validées métier doivent déjà être intégrées dans cette phase
* les pages non encore corrigées doivent tout de même être spécifiées

C’est la phase indispensable avant modification large.

## Phase 2 — stabilisation de l’infra focus

Objectif :

* consolider le socle sans surconcevoir
* fournir un cadre unique réutilisable par toutes les pages inventoriées en phase 1

Je recommande d’introduire au plus :

* un widget de type `MoviRouteFocusBoundary`
* un petit contrat `initialFocusNode` / `restoreFocusOnPop`
* un helper simple pour groupes directionnels

Contraintes :

* pas de framework interne complexe
* pas de logique métier déplacée inutilement hors des pages
* l’infra doit rester lisible, locale et testable

Mais pas une usine à gaz.

## Phase 3 — shell first

Traiter proprement :

* sidebar
* entrée dans chaque onglet
* sortie vers sidebar
* mémorisation / restauration du focus par onglet

Objectif :

* verrouiller le comportement global de navigation avant de corriger les écrans internes
* garantir une grammaire commune entre shell et contenu

Le shell est déjà le meilleur point d’appui.

## Phase 4 — pages détail

Aligner :

* `MovieDetailPage`
* `TvDetailPage`
* `SagaDetailPage`
* `PersonDetailPage`

Objectif :

* même grammaire de focus
* hero standardisé
* sections basses cohérentes
* retour fiable

Contraintes :

* utiliser un point d’entrée explicite par page
* interdire les débordements latéraux implicites
* homogénéiser la restauration du focus après retour depuis une sous-section ou une page liée

## Phase 5 — pages listes et résultats

Traiter :

* `CategoryPage`
* `SearchResultsPage`
* `ProviderResultsPage`
* `GenreResultsPage`
* `LibraryPlaylistDetailPage`

Objectif :

* standard grille/liste
* point d’entrée unique
* bordures de navigation nettes
* “load more” focusable et prévisible

Contraintes :

* pas de wrap implicite
* pas de passage automatique à la ligne suivante en fin de rangée
* navigation verticale explicite entre lignes et sections

## Phase 6 — settings et formulaires

Traiter :

* settings page
* subtitles page
* about
* IPTV pages
* onboarding
* auth

Objectif :

* navigation verticale simple
* widgets focusables homogènes
* plus de dépendance implicite à `GestureDetector` ou au focus Flutter par défaut

Contraintes :

* chaque champ, action ou choix important doit avoir un comportement télécommande explicite
* les sous-pages doivent avoir une sortie cohérente et une restauration fiable

## Phase 7 — overlays et player

Traiter :

* sheets
* dialogs
* menus contextuels
* player controls

Objectif :

* capture du focus
* restitution au bon élément
* back uniforme

Contraintes :

* tout overlay doit prendre le focus à l’ouverture
* le focus doit être restitué au déclencheur à la fermeture
* aucune fuite de focus vers l’écran sous-jacent

## Phase 8 — tests

À ajouter :

* widget tests clavier/télécommande
* tests de non-régression sur routes critiques
* checklist manuelle Android TV / Fire TV / Google TV si pertinent

Tests minimum par page critique :

* focus initial
* flèche gauche/droite/haut/bas
* select
* back
* restauration après retour

Critère de sortie :

* aucune page critique sans test de focus minimal
* aucune règle globale non couverte sur le shell, les détails, les listes et les overlays

---

# Organisation technique recommandée

Pour rester conforme à tes règles, je recommande :

## Dans `core/widgets` ou `core/focus`

Un petit sous-ensemble seulement :

* `movi_route_focus_boundary.dart`
* `movi_focus_scope_helpers.dart`
* `movi_focus_restoration.dart`

## Dans chaque page

La page garde :

* ses `FocusNode`
* ses règles métier de navigation locale
* son enregistrement éventuel dans le shell

Donc :

* **la stratégie globale est centralisée**
* **la règle métier locale reste dans la page**

C’est le meilleur compromis entre clarté et maintenabilité.

---

# Recommandation de démarrage concrète

Je te conseille de lancer le chantier dans cet ordre :

1. écrire la **spec de focus** de toutes les pages
2. verrouiller le **contrat shell**
3. prendre `TvDetailPage` comme **référence de détail**
4. refactorer `MovieDetailPage` pour l’aligner dessus
5. corriger `SearchResultsPage` et `CategoryPage`
6. normaliser `SettingsSubtitlesPage` et les pages settings/formulaires
7. finir par overlays et player

---

# Conclusion

Le projet n’a pas besoin d’une réécriture TV.
Il a besoin d’un **cadre unique de focus**, puis d’une mise à niveau progressive page par page.

En résumé :

* la base technique TV existe déjà
* le shell est bien engagé
* la dette principale est l’**hétérogénéité des règles de focus**
* le bon chantier est : **spécifier, standardiser, puis corriger par familles de pages**

La prochaine étape la plus utile est de te produire un **document de spécification page par page**, déjà rempli pour tout le routeur actuel, avec pour chaque écran :

* entrée focus
* déplacements
* sortie
* restauration
* priorité d’implémentation.

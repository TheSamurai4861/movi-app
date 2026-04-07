# Sous-phase 5.1 - Epic map et backlog des lots

## Objectif

Transformer la refonte du tunnel en:
- epics de livraison coherents
- lots executables assez petits pour etre revus et rollbackes
- backlog initial ordonne par logique produit et technique

Cette sous-phase ne fixe pas encore les dependances exactes entre tous les lots. Elle produit la structure de base sur laquelle `5.2` va ensuite travailler.

## Principe de decoupage retenu

Le decoupage retenu suit trois regles:

1. un lot doit avoir un objectif principal unique
2. un lot doit produire une sortie observable
3. un lot ne doit pas melanger coeur d'etat, UI et nettoyage legacy sauf si cela reduit clairement le risque

## Epic map recommandee

La refonte est regroupee en 8 epics coherents.

### Epic A - Observabilite et securisation de migration

But:
- rendre le tunnel mesurable avant les grosses bascules

Contenu:
- telemetry minimale
- reason codes
- correlation des transitions
- flags de migration

### Epic B - Coeur de tunnel: etat et orchestration

But:
- poser la nouvelle source de verite et le moteur du tunnel

Contenu:
- `TunnelState`
- derives critiques
- `EntryJourneyOrchestrator`
- bridge de compatibilite

### Epic C - Contrats metier du tunnel

But:
- brancher les contrats auth, profile, source et preload au nouveau coeur

Contenu:
- ports
- adapters
- timeouts/retries
- snapshots de selection

### Epic D - Projection routeur et compatibilite de navigation

But:
- faire projeter le routeur par l'etat cible sans casser les URLs et guards existants

Contenu:
- derive `TunnelSurface`
- projection routeur
- simplification progressive des guards

### Epic E - Design system tunnel et composants UI communs

But:
- construire les briques communes avant de migrer les surfaces

Contenu:
- shell
- hero
- form shell
- galerie de choix
- feedback inline / recovery
- focus TV commun

### Epic F - Surfaces `Preparation systeme`, `Auth`, `Profil`

But:
- migrer les premieres surfaces du tunnel sur le nouveau contrat

Contenu:
- splash / preparation systeme
- auth
- creation profil
- choix profil

### Epic G - Surface `Choix / ajout source`

But:
- fusionner et migrer tout le bloc source sur la logique cible

Contenu:
- hub source
- choix source
- ajout source
- recovery source

### Epic H - `Chargement medias`, preload final et nettoyage legacy

But:
- finaliser le pre-home borne puis retirer les anciens branchements

Contenu:
- `Chargement medias`
- separation `catalog minimal` / `catalog full`
- bascule finale du tunnel
- suppression des ponts legacy

## Backlog initial des lots

Le backlog ci-dessous est volontairement formule en lots executables, pas encore en stories fines.

## Epic A - Observabilite et securisation de migration

### Lot `A1` - Evenements telemetry du tunnel existant

Objectif:
- ajouter les evenements critiques de phase 4 sur le tunnel actuel ou en bridge

Entree:
- tunnel actuel en production
- plan d'instrumentation valide

Sortie observable:
- `entry_journey_started`, evenements de stage et retries emis

Impact principal:
- mesure
- zero changement UX attendu

### Lot `A2` - Reason codes et correlation IDs

Objectif:
- normaliser les `reason_codes`, `journey_run_id` et champs minimaux

Entree:
- `A1`

Sortie observable:
- telemetry exploitable par scenario

Impact principal:
- mesure

### Lot `A3` - Flags techniques de migration

Objectif:
- introduire les flags structurants du nouveau tunnel

Entree:
- strategie de flags phase 3

Sortie observable:
- flags de bascule disponibles en code

Impact principal:
- migration / rollback

## Epic B - Coeur de tunnel: etat et orchestration

### Lot `B1` - Modele `TunnelState` et reason codes du domaine

Objectif:
- introduire le modele canonique sans changer encore les surfaces

Entree:
- schema architecture phase 3

Sortie observable:
- modele compile et utilisable par bridge

Impact principal:
- architecture

### Lot `B2` - Bridge de compatibilite `legacy -> TunnelState`

Objectif:
- produire un `TunnelState` depuis l'orchestrateur actuel pour ne pas couper le tunnel

Entree:
- `B1`

Sortie observable:
- derive lisible pour tests et telemetry

Impact principal:
- migration sans big bang

### Lot `B3` - `EntryJourneyOrchestrator` cible en mode shadow

Objectif:
- brancher le nouvel orchestrateur sans encore lui donner toute la responsabilite visible

Entree:
- `B1`, `B2`

Sortie observable:
- nouvel orchestrateur actif en parallele controlee

Impact principal:
- architecture / migration

### Lot `B4` - Bascule de la source de verite vers le nouvel orchestrateur

Objectif:
- faire du nouvel orchestrateur la source de verite du tunnel

Entree:
- `B3`

Sortie observable:
- ancien orchestrateur reduit a bridge ou retire du chemin critique

Impact principal:
- coeur du tunnel

## Epic C - Contrats metier du tunnel

### Lot `C1` - Contrat session et auth

Objectif:
- brancher `session_resolve` et `auth_required` au nouveau coeur

Entree:
- `B3` minimum

Sortie observable:
- session resolue via port explicite

Impact principal:
- auth

### Lot `C2` - Contrats profiles et selection

Objectif:
- brancher inventaire profils et derive de selection

Entree:
- `B3`

Sortie observable:
- `profile_required` fiable

Impact principal:
- profils

### Lot `C3` - Contrats sources et selection active

Objectif:
- brancher inventaire sources et derive de source active

Entree:
- `B3`

Sortie observable:
- `source_required` fiable

Impact principal:
- sources

### Lot `C4` - Contrat validation source et recovery

Objectif:
- borner la validation source, ses timeouts et sa recovery

Entree:
- `C3`

Sortie observable:
- `source_invalid` et `source_recovery_required` fiables

Impact principal:
- resilience source

### Lot `C5` - Contrat pre-home minimal

Objectif:
- sortir le catalogue complet du pre-home et definir `catalog minimal ready`

Entree:
- `C3`, `C4`

Sortie observable:
- `preloading_home` borne

Impact principal:
- performance / resilience

## Epic D - Projection routeur et compatibilite de navigation

### Lot `D1` - Derive `TunnelSurface`

Objectif:
- produire la projection de surface depuis `TunnelState`

Entree:
- `B4`

Sortie observable:
- derive unique de routing disponible

Impact principal:
- navigation

### Lot `D2` - Routeur branche sur `TunnelSurface`

Objectif:
- faire lire la projection cible par le routeur

Entree:
- `D1`

Sortie observable:
- routeur projete l'etat au lieu de le recalculer

Impact principal:
- navigation / migration

### Lot `D3` - Simplification des guards legacy

Objectif:
- reduire `LaunchRedirectGuard` et les bridges de compatibilite

Entree:
- `D2`

Sortie observable:
- moins de logique tunnel dans les guards

Impact principal:
- nettoyage progressif

## Epic E - Design system tunnel et composants UI communs

### Lot `E1` - Shells et layout tunnel

Objectif:
- construire `TunnelPageShell`, `TunnelHeroBlock`, `TunnelFormShell`

Entree:
- spec UI phase 2

Sortie observable:
- briques communes utilisables sans migrer les ecrans

Impact principal:
- UI shared

### Lot `E2` - Composants de selection et de feedback

Objectif:
- construire galerie profil/source, messages inline, recovery banner, empty state

Entree:
- `E1`

Sortie observable:
- briques de choix et recovery disponibles

Impact principal:
- UI shared

### Lot `E3` - Focus TV et interactions communes

Objectif:
- brancher les regles de focus communes du tunnel

Entree:
- `E1`, `E2`

Sortie observable:
- focus stable pour les futures surfaces migrees

Impact principal:
- TV / accessibilite

## Epic F - Surfaces `Preparation systeme`, `Auth`, `Profil`

### Lot `F1` - Surface `Preparation systeme`

Objectif:
- migrer le splash / preparation systeme sur le nouveau contrat

Entree:
- `A1`, `B4`, `D2`, `E1`

Sortie observable:
- etat systeme et offline visibles sur la surface cible

Impact principal:
- UX early tunnel

### Lot `F2` - Surface `Auth`

Objectif:
- migrer auth sur le nouveau contrat et les nouveaux composants

Entree:
- `C1`, `E1`

Sortie observable:
- `auth_required` alimente la bonne surface

Impact principal:
- auth UI

### Lot `F3` - Surface `Creation profil`

Objectif:
- migrer creation profil

Entree:
- `C2`, `E1`

Sortie observable:
- creation profil sur contrat cible

Impact principal:
- profile UI

### Lot `F4` - Surface `Choix profil`

Objectif:
- migrer choix profil sur galerie et contrat cible

Entree:
- `C2`, `E2`, `E3`

Sortie observable:
- `profile_required` stable mobile / TV

Impact principal:
- profile selection

## Epic G - Surface `Choix / ajout source`

### Lot `G1` - Hub source unifie

Objectif:
- fusionner `welcome/sources` et `welcome/sources/select` dans une surface unique

Entree:
- `C3`, `E2`, `E3`

Sortie observable:
- une seule surface source dans le nouveau tunnel

Impact principal:
- source UX

### Lot `G2` - Ajout source et validation guidee

Objectif:
- brancher l'ajout source et la validation sur les contrats cibles

Entree:
- `G1`, `C4`

Sortie observable:
- source ajoutee / validee via le nouveau flux

Impact principal:
- source flow

### Lot `G3` - Recovery source

Objectif:
- finaliser les cas `source invalide`, `retry`, `changer de source`

Entree:
- `G2`

Sortie observable:
- safe states source respectes

Impact principal:
- resilience UI

## Epic H - `Chargement medias`, preload final et nettoyage legacy

### Lot `H1` - Surface `Chargement medias`

Objectif:
- migrer la surface pre-home sur la logique minimale validee en phase 4

Entree:
- `C5`, `E1`, `E2`

Sortie observable:
- `preloading_home` borne et visible

Impact principal:
- pre-home UI

### Lot `H2` - Separation `catalog minimal` / `catalog full`

Objectif:
- finaliser la separation fonctionnelle et telemetry entre pre-home et post-home

Entree:
- `C5`, `H1`

Sortie observable:
- `Home` n'attend plus le catalogue complet

Impact principal:
- performance release

### Lot `H3` - Nettoyage des preferences comme source de verite

Objectif:
- sortir les preferences de selection de la logique metier du tunnel

Entree:
- `B4`, `C2`, `C3`

Sortie observable:
- preferences reduites a un role de persistence

Impact principal:
- architecture cleanup

### Lot `H4` - Nettoyage final legacy

Objectif:
- retirer les ponts legacy, pages hybrides et branches obsoletes

Entree:
- tous les lots coeur et surfaces finalises

Sortie observable:
- tunnel cible propre sans duplication systemique

Impact principal:
- finalisation

## Lots qui paraissent encore trop gros

Les lots suivants sont encore a surveiller en taille:

### `B4` - Bascule de la source de verite

Risque:
- trop central

Recommendation:
- possible sous-decoupage en:
  - `B4a` activation source de verite
  - `B4b` retrait du chemin critique legacy

### `G1` - Hub source unifie

Risque:
- risque de melanger fusion UX et migration technique

Recommendation:
- possible sous-decoupage en:
  - `G1a` structure de surface
  - `G1b` fusion navigation / routes internes

### `H4` - Nettoyage final legacy

Risque:
- lot fourre-tout de fin de projet

Recommendation:
- ne le lancer que avec une checklist stricte de suppressions eligibles

## Lots les plus aptes a etre implementes en parallele plus tard

Candidates probables a la parallelisation, sous reserve de `5.2`:
- `E1`, `E2`, `E3` apres stabilisation du contrat UI
- `F2` et `F3` si les composants communs sont deja prets
- `G3` peut suivre `G2` avec une frontiere claire

## Lecture rapide du backlog

Le coeur minimal du projet est:
- `A1` a `A3`
- `B1` a `B4`
- `C1` a `C5`
- `D1` a `D2`

Le coeur visible ensuite est:
- `E1` a `E3`
- `F1` a `F4`
- `G1` a `G3`
- `H1` a `H2`

La fermeture du chantier est:
- `D3`
- `H3`
- `H4`

## Verdict

La sous-phase `5.1` est suffisamment stable si l'on retient ces points:
- l'epic map de la refonte est claire
- le backlog initial est deja decoupe en lots executables
- les lots trop gros sont identifies
- la suite peut maintenant traiter les dependances reelles et le chemin critique

La suite logique est la sous-phase `5.2`, pour cartographier les dependances, l'ordre d'execution et les lots parallelisables.

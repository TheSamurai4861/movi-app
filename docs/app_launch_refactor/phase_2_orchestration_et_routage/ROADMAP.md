# Phase 2 - Orchestration et routage

## Objectif

Faire de l'orchestrateur la source de verite du boot et eviter les navigations
concurrentes depuis les widgets.

Cette phase transforme les decisions documentees en Phase 1 en points
d'execution stables. Elle ne doit pas encore remplacer toute l'UI boot : les
widgets legacy peuvent rester en fallback tant que les decisions de navigation
et les actions boot sont centralisees.

## Regles de travail

- Chaque etape indique explicitement si elle est documentaire ou si elle peut
  modifier le code applicatif.
- Garder `AppLaunchOrchestrator` comme source de decision boot.
- Garder le router responsable de l'application de la destination.
- Garder les pages auth/profil/source proprietaires de la saisie utilisateur.
- Supprimer ou isoler les navigations directes quand elles representent une
  decision boot.
- Ne pas deplacer la logique catalogue critique dans les widgets.
- Conserver un fallback legacy tant que le renderer boot final n'est pas pret.
- Tester les decisions de route et les actions avant de remplacer les ecrans.

## Etape 1 - Relecture cible du routage actuel

### But

Verifier l'etat exact de `LaunchRedirectGuard`, du catalogue de routes et des
destinations boot avant modification.

### Nature

Documentation uniquement. Aucune modification de code applicatif attendue.

### Actions

- Relire le catalogue de routes.
- Relire `LaunchRedirectGuard`.
- Relire les providers router lies au lancement.
- Rechercher les usages des routes :
  - `launch` ;
  - `auth` ;
  - `welcomeUser` ;
  - `welcomeSources` ;
  - `welcomeSourceSelect` ;
  - `welcomeSourceLoading` ;
  - `home`.
- Identifier les redirections deja decidees par le guard.
- Identifier les redirections encore decidees par les widgets.

### Sortie attendue

Completer une table :

```text
route | source de decision actuelle | source cible | guard | widget | risque
```

### Definition de fini

- Les decisions router et widgets sont separees.
- Les routes qui doivent rester accessibles directement sont identifiees.
- Les routes qui doivent devenir des destinations appliquees par le router sont
  identifiees.

## Etape 2 - Contrat de responsabilite orchestration/router/UI

### But

Figer qui decide, qui applique et qui collecte les donnees utilisateur.

### Nature

Documentation uniquement. Aucune modification de code applicatif attendue.

### Actions

- Definir le role cible de `AppLaunchOrchestrator`.
- Definir le role cible de `LaunchRedirectGuard`.
- Definir le role cible des pages auth existantes.
- Definir le role cible des pages profil/source existantes.
- Definir le role cible du futur renderer `BootScreenModel`.
- Identifier les transitions qui doivent etre interdites depuis les widgets.

### Sortie attendue

Completer une table :

```text
couche | responsabilite cible | decisions autorisees | decisions interdites | contrat
```

### Definition de fini

- Une decision boot a une seule source.
- Le router n'invente pas de decision metier.
- Les pages d'action collectent des donnees sans piloter le tunnel global.

## Etape 3 - Definition de `BootActionHandler`

### But

Centraliser l'execution des actions produites par les ecrans boot.

### Nature

Implementation attendue si le contrat n'existe pas encore. Cette etape peut
creer ou modifier du code applicatif et des tests.

### Actions

- Definir le contrat `BootActionHandler` ou equivalent.
- Mapper les intentions Phase 1 :
  - `retry` ;
  - `exportLogs` ;
  - `login` ;
  - `createProfile` ;
  - `chooseProfile` ;
  - `addSource` ;
  - `chooseSource` ;
  - `reconnectSource` ;
  - `resyncSource` ;
  - `retryHomeSections` ;
  - `retryLibrary`.
- Distinguer les actions qui naviguent, celles qui relancent l'orchestrateur et
  celles qui deleguent a un controller metier.
- Definir le resultat attendu de chaque action.

### Sortie attendue

Completer une table :

```text
action | handler cible | dependance | effet attendu | destination | test
```

### Definition de fini

- Chaque action boot a un handler cible.
- Les actions ne sont pas des callbacks anonymes disperses dans les widgets.
- Les actions critiques sont testables sans rendu UI complet.

## Etape 4 - Branchement minimal du `BootScreenModel`

### But

Exposer le modele UI sans remplacer encore toutes les surfaces legacy.

### Nature

Implementation partielle attendue si le point de branchement est confirme. Cette
etape peut creer ou modifier un provider, un mapper ou un fallback temporaire.

### Actions

- Identifier le provider definitif du `BootScreenModel`.
- Brancher ou planifier le mapper depuis `AppLaunchState`.
- Verifier que le provider ne duplique pas les decisions de
  `LaunchRedirectGuard`.
- Definir le fallback vers les widgets legacy si le modele est incomplet.
- Documenter les limites de ce branchement pour la Phase 4.

### Sortie attendue

Completer une table :

```text
source | projection | provider | consommateur temporaire | consommateur cible | fallback
```

### Definition de fini

- Le point d'exposition runtime du modele UI est connu.
- Le fallback legacy est explicite.
- La Phase 4 pourra consommer le meme provider sans redefinir les contrats.

## Etape 5 - Alignement `LaunchRedirectGuard` avec l'orchestrateur

### But

Faire appliquer au router les decisions de l'orchestrateur sans navigation
concurrente.

### Nature

Implementation attendue. Cette etape peut modifier `LaunchRedirectGuard`, ses
providers et les tests router associes.

### Actions

- Identifier les donnees exactes que le guard doit lire.
- Definir les destinations router depuis les decisions boot.
- Verifier les cas de non-redirection.
- Verifier les cas de redirection vers action utilisateur.
- Verifier les cas d'ouverture Home.
- Verifier les cas recovery avant Home.
- Verifier les cas Home partiel apres Home.

### Sortie attendue

Completer une table :

```text
etat runtime | destination cible | redirection guard | action utilisateur | fallback | test router
```

### Definition de fini

- Le guard applique les destinations boot sans recreer la logique metier.
- Les cas Home partiel ne renvoient pas vers la recovery source.
- Les cas action utilisateur conservent les pages metier existantes.

## Etape 6 - Remplacement des navigations directes dispersees

### But

Supprimer les navigations directes qui representent une decision boot.

### Nature

Implementation attendue apres classification. Cette etape peut modifier les
widgets boot/welcome concernes et ajouter des tests de non-regression.

### Actions

- Rechercher les appels directs a `go`, `push`, `replace`, `pop` dans les
  widgets boot et welcome.
- Classer chaque navigation :
  - navigation UI locale ;
  - navigation metier conservee ;
  - decision boot a centraliser.
- Remplacer les decisions boot par une action ou par une mise a jour
  orchestration.
- Garder les navigations internes auth/login/signup/reset si elles ne changent
  pas la decision boot globale.

### Sortie attendue

Completer une table :

```text
fichier | navigation actuelle | type | remplacement cible | risque | test
```

### Definition de fini

- Les widgets ne decident plus seuls des destinations boot.
- Les navigations metier conservees sont justifiees.
- Les suppressions de navigation sont couvertes par des tests router ou action.

## Etape 7 - Raccordement pages auth/profil/source aux actions boot

### But

Conserver les pages de saisie existantes tout en les reliant au tunnel boot.

### Nature

Implementation attendue si les pages ne notifient pas encore l'orchestrateur via
un contrat stable. Cette etape peut modifier pages, controllers ou handlers.

### Actions

- Identifier les sorties success/failure des pages auth.
- Identifier les sorties success/failure des pages profil.
- Identifier les sorties success/failure des pages source.
- Definir comment chaque sortie notifie l'orchestrateur.
- Verifier le focus/action principale sur les pages TV.
- Eviter de dupliquer les validations metier dans le handler boot.

### Sortie attendue

Completer une table :

```text
page | evenement success | evenement failure | notification orchestrateur | route suivante | test
```

### Definition de fini

- Les pages d'action restent proprietaires de leur formulaire.
- Le retour dans le tunnel boot est explicite.
- Les erreurs metier restent dans la page concernee quand elles ne changent pas
  la decision boot globale.

### Resultat

Table et decisions documentees dans `ACTION_PAGE_HANDOFF.md`.

## Etape 8 - Rollout et fallback legacy

### But

Prevoir une migration reversible pendant le remplacement progressif.

### Nature

Documentation puis implementation si un flag manque. Cette etape peut modifier
la configuration des feature flags et les logs de rollout.

### Actions

- Identifier les feature flags existants reutilisables.
- Decider si un flag `newBootRenderer` ou equivalent est necessaire.
- Definir le fallback vers l'ancien tunnel.
- Definir le rollback attendu si le nouveau handler ou guard echoue.
- Verifier que les logs distinguent chemin legacy et chemin refactor.

### Sortie attendue

Completer une table :

```text
flag | valeur defaut | chemin active | chemin fallback | rollback | log attendu
```

### Definition de fini

- La migration peut etre activee progressivement.
- Le fallback ne recree pas deux sources concurrentes permanentes.
- Le rollback est simple a expliquer et a tester.

### Resultat

Table, strategie de rollback et logs attendus documentes dans
`ROLLOUT_FALLBACK.md`.

## Etape 9 - Tests router et actions boot

### But

Verrouiller les transitions avant le remplacement UI complet.

### Nature

Implementation tests attendue. Cette etape ajoute ou modifie des tests, et peut
ajuster le code si les tests revelent un ecart avec les contrats Phase 1/2.

### Actions

- Ajouter ou preparer les tests router pour chaque destination boot.
- Ajouter ou preparer les tests de `BootActionHandler`.
- Verifier les destinations :
  - `launch` ;
  - `auth` ;
  - `welcomeUser` ;
  - `welcomeSources` ;
  - `welcomeSourceSelect` ;
  - `welcomeSourceLoading` ;
  - `home`.
- Verifier que les actions actionnables produisent une route, un controller ou
  une relance orchestration.
- Verifier que les etats non interactifs ne produisent pas d'action focusable.

### Sortie attendue

Completer une table :

```text
test | scenario | entree runtime | action | destination attendue | assertion critique
```

### Definition de fini

- Chaque destination boot critique a un test.
- Chaque action principale Phase 1 a une assertion.
- Les anciennes navigations dispersees ne sont plus necessaires pour passer les
  tests.

### Resultat

Table de couverture documentee dans `BOOT_TEST_COVERAGE.md`.

## Etape 10 - Synthese Phase 2

### But

Transformer le raccordement orchestration/router en plan d'implementation pour
les phases catalogue, UI et nettoyage legacy.

### Nature

Documentation uniquement, sauf mise a jour mineure de checklist.

### Actions

- Produire une synthese courte :
  - decisions centralisees ;
  - actions boot raccordees ;
  - navigations directes supprimees ou conservees ;
  - routes encore legacy ;
  - tests ajoutes ;
  - risques restants pour Phase 3 et Phase 4.
- Mettre a jour la checklist de definition de fini.

### Sortie attendue

Creer ou completer :

```text
docs/app_launch_refactor/phase_2_orchestration_et_routage/DECISIONS.md
```

### Definition de fini

- Une seule couche decide les transitions boot.
- Le router applique les destinations sans dupliquer la logique metier.
- Les widgets n'embarquent plus de logique catalogue critique.
- Le bouton principal de chaque ecran produit une action testable.
- La Phase 3 peut traiter le catalogue sans redecouvrir le routage.
- La Phase 4 peut remplacer l'UI avec un provider et un handler stables.

### Resultat

Synthese et plan de suite documentes dans `DECISIONS.md`.

## Checklist Phase 2

- [x] Routage actuel relu.
- [x] Responsabilites orchestration/router/UI figees.
- [x] `BootActionHandler` defini ou equivalent documente.
- [x] `BootScreenModel` raccorde ou point de raccordement confirme.
- [x] `LaunchRedirectGuard` aligne avec l'orchestrateur.
- [x] Navigations directes dispersees classees.
- [x] Decisions boot retirees des widgets concernes.
- [x] Pages auth/profil/source raccordees aux actions boot.
- [x] Rollout/fallback legacy documente.
- [x] Tests router et actions listes ou ajoutes.
- [x] Synthese Phase 2 produite.

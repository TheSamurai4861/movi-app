# Phase 4 - Etape 2 - Contrat visuel BootScreenModel -> Widget

## Objectif

Figer comment `BootScreenModel` devient une surface Flutter sans dupliquer les
decisions d'orchestration, de routage ou de catalogue.

## Etat actuel

Le modele existe deja :

- `BootScreenModel` porte `screenType`, textes, actions, destination, focus,
  severity, logo/progress et metadata.
- `bootScreenModelProvider` projette `AppLaunchState` via `BootScreenMapper`.
- `bootScreenModelProvider` est read-only et ne fait ni navigation, ni logging,
  ni reseau, ni stockage.
- `executeBootAction` sait convertir un `BootActionRequest` en navigation,
  relance boot ou commande controller.

Le renderer unifie n'existe pas encore sous un seul widget nomme.
`SplashBootstrapPage` enchaine chargements (`BootSimpleLoadingScreen`,
`BootCatalogLoadingScreen`) et recovery (`BootRecoveryPanel.fromBootModel`).

## Decision

Creer un renderer presentation-only, par exemple `BootScreenRenderer`, qui prend
un `BootScreenModel` et expose les intentions d'action sans connaitre
`AppLaunchOrchestrator`.

Le renderer cible ne doit pas :

- lire `appLaunchStateProvider` ;
- lire `bootScreenModelProvider` directement ;
- appeler `AppLaunchOrchestrator` ;
- appeler `GoRouter` ;
- relire les reason codes pour decider d'une destination ;
- acceder au catalogue, aux sources ou aux profiles.

Il peut :

- choisir un widget selon `BootScreenType` ;
- rendre `title`, `message`, `secondaryMessage` ;
- rendre le logo si `showLogo` ;
- rendre un indicateur si `showProgress` ;
- rendre les actions fournies par le modele ;
- demander le focus initial indique par `BootFocusTarget` ;
- emettre un callback `onAction(BootActionIntent intent)`.

## Contrat d'entree

```text
entree | type | responsabilite
model | BootScreenModel | source unique du contenu et des actions visibles
onAction | ValueChanged<BootActionIntent> ou equivalent | sortie action utilisateur vers BootActionHandler/executeBootAction
primaryFocusNode | FocusNode optionnel | focus initial action principale si ecran interactif
secondaryFocusNode | FocusNode optionnel | focus action secondaire si presente
loadingFocusNode | FocusNode optionnel | cible focus non interactive pour regions TV
constraints/layout | via BuildContext/MediaQuery/LayoutBuilder | responsive mobile, desktop, TV
```

Le renderer ne recoit pas de callback metier specifique comme `onRetry`,
`onChooseSource` ou `onReconnectSource`. Ces decisions restent dans
`BootActionIntent`.

## Contrat de sortie

```text
sortie | condition | contrainte
widget non interactif | model.isInteractive == false | aucun bouton, initialFocus none, pas d'action focusable
widget actionnable | model.isInteractive == true | action principale obligatoire, focus initial primaryAction
action secondaire | model.secondaryAction != null | bouton/lien focusable et atteignable au clavier
semantic labels | logo/actions/progress | labels utilisateur, jamais reason code brut
metadata debug | optionnel | non visible par defaut
```

## Table BootScreenType

```text
BootScreenType | widget cible | action | focus initial | responsive | test
simpleLoading | BootSimpleLoadingScreen, base OverlaySplash ou equivalent | aucune | none/loading node non actionnable | logo centre, texte bas ecran, mobile 393x852, desktop full surface | chargement simple sans action, logo reel, texte bas
catalogLoading | BootCatalogLoadingScreen | aucune tant que model.isInteractive=false | none/loading node non actionnable | surface enrichie, texte court, sous-message possible, pas de bouton immediat | catalog_preparing non interactif
openingHome | BootSimpleLoadingScreen ou BootOpeningHomeScreen | aucune | none/loading node non actionnable | transition breve, peut reutiliser simple loading | opening_home/home_ready sans action
actionRequired | BootRecoveryPanel ou BootActionPanel | primaryAction obligatoire, secondaryAction optionnelle | primaryAction | contenu contraint, boutons max 250/largeur adaptee, action secondaire atteignable | source timeout/provider/credentials/catalog empty/profile/source selection
technicalFailure | BootRecoveryPanel severity error | retry + exportLogs si fournis | primaryAction | panneau centre, details techniques non visibles par defaut | technical failure retry/export logs
recovery | BootRecoveryPanel si conserve dans modele | actions du modele | primaryAction si interactif | meme contrat que actionRequired | a couvrir seulement si encore emis
homePartialNotice | HomePartialBanner | actions de degradation Home | primaryAction si action presente | compact mobile, non bloquant dans Home | Home partial banner
```

## Mapping visuel cible

```text
screenType | composant de base | notes
simpleLoading | OverlaySplash extrait/enveloppe | conserver logo centre + texte bas ecran, ne pas afficher reasonCode
catalogLoading | nouveau widget ou variante simple loading | gerer message + secondaryMessage, aucune action pendant preparation normale
openingHome | simple loading | peut etre tres bref, aucune recovery
actionRequired | nouveau BootRecoveryPanel | support titre, message, action principale, action secondaire
technicalFailure | BootRecoveryPanel | severity error, export logs secondaire
homePartialNotice | Home partial banner dediee | reste dans Home, pas dans le tunnel boot bloquant
```

## Flux d'action

```text
BootRecoveryPanel bouton principal
-> onAction(model.primaryAction)
-> BootActionRequest(intent, reasonCode: model.reasonCode)
-> executeBootAction / BootActionHandler
-> route, relance boot, diagnostic ou commande controller
```

Le renderer ne choisit jamais la route. Le planner/handler garde cette
responsabilite.

## Focus TV

```text
etat | focus attendu
non interactif | aucun bouton ; focus region peut pointer un Focus neutre
interactive + primaryAction | primaryFocusNode autofocus ou focus request via region
interactive + secondaryAction | secondaryFocusNode atteignable apres primary
technicalFailure | retry en premier, export logs ensuite
```

Le renderer doit accepter des `FocusNode` injectables ou creer des focus nodes
internes dans un widget stateful. La decision finale dependra de l'integration
avec `FocusRegionScope` existant.

## Responsive

```text
format | regle
mobile 393x852 | largeur boutons autour de 250, inputs 300, padding horizontal 20
desktop | contenu contraint, pas de formulaire pleine largeur
TV | textes plus lisibles si breakpoint large, focus visible, action principale immediate
```

Les dimensions Figma sont des references, pas une raison pour casser les
contraintes existantes hors boot.

## Tests attendus

```text
test | entree | assertion critique
simple loading | BootScreenType.simpleLoading, isInteractive=false | logo AppAssets.iconAppLogoSvg, message visible, aucun bouton
catalog loading | BootScreenType.catalogLoading, reason catalog_preparing | message visible, no primary/secondary action
action required | primary + secondary actions | deux actions visibles, primary focusable, callbacks intents corrects
technical failure | retry + exportLogs | retry primary, export logs secondary, no raw reasonCode visible
opening home | BootScreenType.openingHome | no action, progress/logo selon modele
home partial notice | Home partial model/notice | banniere compacte, action limitee a Home
```

## Point de branchement cible

`SplashBootstrapPage` est le consommateur initial le plus probable :

```text
bootScreenModelProvider -> BootScreenRenderer -> onAction -> executeBootAction
```

Le remplacement doit rester progressif : tant que le renderer n'est pas complet,
les surfaces legacy peuvent rester fallback.

## Definition de fini de l'etape 2

- [x] Le renderer a une responsabilite purement presentation.
- [x] Les actions passent par `BootActionIntent` ou `BootActionHandler`.
- [x] Les etats non interactifs ne produisent aucune action focusable.
- [x] Le renderer unifie reste a implementer dans l'etape suivante dediee.

# Definition de BootActionHandler

## Decision

Le contrat `BootActionHandler` est ajoute comme point unique d'execution des
intentions d'action boot.

Emplacement :

```text
lib/src/core/startup/presentation/boot_action_handler.dart
```

Le fichier contient :

- `BootActionIntent`, enum presentation des intentions actionnables ;
- `BootActionRequest`, entree du handler avec reason code log-safe ;
- `BootActionPlan`, cible d'execution pure et testable ;
- `BootActionPlanner`, mapping sans side effect ;
- `BootActionHandler`, interface runtime a implementer lors du branchement ;
- `BootActionIntentFromRecoveryAction`, pont depuis `RecoveryAction`.

Cette etape ne branche pas encore le handler a `GoRouter`, aux widgets legacy ou
aux controllers. Elle verrouille le contrat et les destinations cibles.

## Table action -> handler cible

| action | handler cible | dependance | effet attendu | destination | test |
| --- | --- | --- | --- | --- | --- |
| `retry` | `BootActionHandler.handle(BootActionIntent.retry)` | `AppLaunchOrchestrator` via runner a brancher. | Relancer le tunnel boot avec reason `boot_action_retry`. | `/launch` fallback tant que le guard applique ensuite la destination. | `boot_action_handler_test.dart` verifie `launchRun`, route `/launch`, run reason. |
| `exportLogs` | `BootActionHandler.handle(BootActionIntent.exportLogs)` | Service export/logs a definir. | Lancer une action diagnostic sans navigation. | Aucune. | Test verifie `diagnostic`, pas de route. |
| `login` | `BootActionHandler.handle(BootActionIntent.login)` | `GoRouter`. | Ouvrir la page auth existante. | `/auth/otp`. | Test verifie route auth. |
| `createProfile` | `BootActionHandler.handle(BootActionIntent.createProfile)` | `GoRouter`. | Ouvrir la page profil existante en mode action. | `/welcome/user`. | Test verifie route profil. |
| `chooseProfile` | `BootActionHandler.handle(BootActionIntent.chooseProfile)` | `GoRouter`. | Ouvrir la page selection profil existante. | `/welcome/user`. | Test verifie route profil. |
| `addSource` | `BootActionHandler.handle(BootActionIntent.addSource)` | `GoRouter`. | Ouvrir la page ajout source existante. | `/welcome/sources`. | Test verifie route source. |
| `chooseSource` | `BootActionHandler.handle(BootActionIntent.chooseSource)` | `GoRouter`. | Ouvrir la page selection source existante. | `/welcome/sources/select`. | Test verifie route selection source. |
| `reconnectSource` | `BootActionHandler.handle(BootActionIntent.reconnectSource)` | `GoRouter`, puis controller source legacy. | Ouvrir la page source pour reconnecter credentials/source. | `/welcome/sources` pour l'instant. | Test verifie route source. |
| `resyncSource` | `BootActionHandler.handle(BootActionIntent.resyncSource)` | Controller/orchestrateur catalogue a brancher. | Relancer la sync source/catalogue. | `/welcome/sources/loading` fallback legacy. | Test verifie `sourceResync` + route loading. |
| `openHome` | `BootActionHandler.handle(BootActionIntent.openHome)` | `GoRouter`, guard. | Ouvrir Home seulement si l'orchestrateur expose un etat ouvrable. | `/`. | Test verifie route Home. |
| `retryHomeSections` | `BootActionHandler.handle(BootActionIntent.retryHomeSections)` | Home controller/feed refresh. | Relancer les sections Home degradees. | `/`. | Test verifie `retryHomeSections` + route Home. |
| `retryLibrary` | `BootActionHandler.handle(BootActionIntent.retryLibrary)` | Library/home controller. | Relancer la bibliotheque ou la reprise. | `/`. | Test verifie `retryLibrary` + route Home. |

## Distinction des effets

| effet | actions | branchement cible |
| --- | --- | --- |
| `launchRun` | `retry` | Reset/run orchestrateur puis laisser le guard appliquer la destination. |
| `navigation` | `login`, `createProfile`, `chooseProfile`, `addSource`, `chooseSource`, `reconnectSource`, `openHome` | `GoRouter` uniquement. |
| `controllerCommand` | `resyncSource`, `retryHomeSections`, `retryLibrary` | Delegation aux controllers/use cases sans logique UI. |
| `diagnostic` | `exportLogs` | Service logs/export, jamais action principale seule. |

## Regles

- Le handler execute une intention, pas un callback anonyme.
- `BootActionPlanner` reste pur et sans side effect.
- Le renderer boot n'appelle pas directement `context.go`.
- Les pages d'action restent proprietaires de leurs formulaires.
- `exportLogs` ne doit pas etre la seule action utile d'un ecran recovery.
- `openHome` ne doit pas contourner `LaunchRedirectGuard` ni Home readiness.

## Tests ajoutes

| test | comportement couvert | contrat teste | donnees d'entree | assertion critique |
| --- | --- | --- | --- | --- |
| `maps retry to a launch rerun target` | Retry boot centralise. | `BootActionPlanner`. | `BootActionIntent.retry`. | Effet `launchRun`, route `/launch`, reason `boot_action_retry`. |
| `maps action page intents to boot routes` | Actions auth/profil/source. | `BootActionPlanner`. | `login`, `createProfile`, `chooseProfile`, `addSource`, `reconnectSource`, `chooseSource`. | Routes cibles stables. |
| `maps source and Home actions to controller commands` | Delegation source/Home. | `BootActionPlanner`. | `resyncSource`, `retryHomeSections`, `retryLibrary`. | Commandes controllers et routes fallback. |
| `keeps export logs diagnostic and non navigational` | Export logs non bloquant. | `BootActionPlanner`. | `exportLogs`. | Pas de route, commande diagnostic. |
| `maps every RecoveryAction to a boot action intent` | Pont domaine -> presentation. | Extension `toBootActionIntent`. | Toutes les valeurs `RecoveryAction`. | Chaque action a une intention cible. |

## Limites pour les etapes suivantes

- Le handler concret n'est pas encore branche a `GoRouter`.
- Les widgets legacy n'appellent pas encore `BootActionHandler`.
- `resyncSource`, `retryHomeSections`, `retryLibrary` ont une commande stable,
  mais leur delegation concrete reste a implementer avec les controllers.
- Le fallback `/welcome/sources/loading` reste temporaire jusqu'a extraction du
  catalogue en Phase 3.

## Definition de fini - etape 3

- Chaque action boot a un handler cible ou un effet cible documente.
- Les actions sont des intentions testables et non des callbacks anonymes.
- Les actions critiques sont couvertes par un test unitaire sans rendu UI.

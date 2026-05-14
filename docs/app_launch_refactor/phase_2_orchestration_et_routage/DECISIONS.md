# Decisions Phase 2 - Orchestration et routage

## Synthese courte

La Phase 2 stabilise le contrat entre orchestration, router et surfaces UI sans
remplacer encore le rendu boot final.

Le principe retenu est :

```text
AppLaunchOrchestrator -> decide
LaunchRedirectGuard / GoRouter -> applique
Pages auth/profil/source -> collectent les donnees
BootScreenModel -> decrit l'ecran
BootActionHandler -> execute l'intention utilisateur
```

Le renderer Figma et l'extraction catalogue restent pour les phases suivantes.

## Decisions centralisees

| sujet | decision |
| --- | --- |
| Source de verite boot | `AppLaunchOrchestrator` reste proprietaire des decisions runtime : session, profil, source, catalogue, Home readiness et destination. |
| Application de route | `LaunchRedirectGuard` applique les destinations depuis `AppLaunchState` ou `TunnelState` quand les flags V2 sont actifs. |
| Pages d'action | Les pages auth/profil/source gardent les formulaires, validations, erreurs metier et focus TV. |
| Renderer UI | `BootScreenModel` est la projection UI cible; il ne navigue pas et ne lit pas le stockage/reseau. |
| Actions utilisateur | `BootActionIntent` et `BootActionPlanner` donnent une cible testable pour chaque action boot. |
| Rollout | `enableBootScreenRenderer` est ajoute, desactive par defaut, separe des flags de routage V2. |

## Actions boot raccordees

| action | statut Phase 2 | cible actuelle |
| --- | --- | --- |
| `retry` | raccorde | relance via `/launch`, reset orchestrateur best-effort |
| `login` | mappe | `/auth/otp` |
| `createProfile` / `chooseProfile` | mappe et utilise par les pages profil | `/welcome/user` puis retour tunnel |
| `addSource` / `reconnectSource` | mappe | `/welcome/sources` |
| `chooseSource` | mappe et utilise par loading source | `/welcome/sources/select` |
| `resyncSource` | mappe et utilise apres ajout/selection source | `/welcome/sources/loading` fallback legacy |
| `openHome` | mappe et utilise apres chargement manuel source | `/` |
| `retryHomeSections` / `retryLibrary` | mappe | commande controller + fallback Home, branchement detaille a renforcer avec Home partial |
| `exportLogs` | mappe | commande diagnostic sans navigation |

## Navigations directes

| categorie | decision |
| --- | --- |
| Supprimees ou encapsulees | Retry recovery, retour post-auth primaire, profil cree/selectionne, source connectee/selectionnee, ouverture Home apres loading manuel. |
| Conservees localement | `pop`, back fallback, auth password/OTP, forgot/update password, `return_to=previous`, ajout source depuis selection. |
| Encore legacy | `WelcomeForm` vers Home direct, si ce composant reste utilise. |
| Encore transitoire | `/welcome/sources/loading` reste un fallback catalogue jusqu'a Phase 3. |

## Routes encore legacy

| route | statut |
| --- | --- |
| `/launch` | Surface canonique d'entree du tunnel pendant la migration. |
| `/bootstrap` | Fallback legacy pour `SplashBootstrapPage`, failure et Home non pret. A remplacer ou supprimer en Phase 4/5. |
| `/welcome/sources/loading` | Fallback legacy de preparation catalogue. A extraire en Phase 3. |
| `/auth/otp` | Page auth existante conservee comme page d'action. |
| `/welcome/user` | Page profil existante conservee comme page d'action. |
| `/welcome/sources` | Page ajout/reconnexion source existante conservee comme page d'action. |
| `/welcome/sources/select` | Page selection source existante conservee comme page d'action. |

## Tests ajoutes ou renforces

| zone | couverture |
| --- | --- |
| `BootActionPlanner` | Chaque `BootActionIntent` produit une route, une commande controller ou un diagnostic testable. |
| `RecoveryAction` | Chaque action recovery Phase 1 mappe vers une intention boot. |
| `LaunchRedirectGuard` legacy | Destinations `launch`, `auth`, `welcomeUser`, `welcomeSources`, `welcomeSourceSelect`, `welcomeSourceLoading`, `home`. |
| `LaunchRedirectGuard` V2 | Surfaces `authRequired`, `sourceRequired`, `preloadingHome`, Home ready et routes auth recovery. |
| `BootScreenMapper` | Etats interactifs avec action/focus, etats non interactifs sans action focusable, absence de fuite de reason code dans les textes. |
| `FeatureFlags` | `enableBootScreenRenderer` desactive par defaut et activable sans activer le routing V2. |

La table detaillee est dans `BOOT_TEST_COVERAGE.md`.

## Risques restants

| risque | phase cible | action attendue |
| --- | --- | --- |
| `WelcomeSourceLoadingPage` contient encore refresh catalogue, erreurs et readiness Home. | Phase 3 | Extraire la preparation catalogue dans l'orchestrateur/use cases et rendre l'etat `catalog_preparing` explicite. |
| `/bootstrap` reste une deuxieme surface boot. | Phase 4/5 | Brancher le renderer `BootScreenModel` puis retirer ou fusionner `/bootstrap`. |
| `WelcomeForm` peut encore contourner Home si encore utilise. | Phase 4/5 | Confirmer usage, supprimer ou raccorder au handler. |
| `retryHomeSections` / `retryLibrary` sont contractuels mais pas encore branches aux controllers finaux. | Phase Home partial | Brancher aux controllers Home/library et ajouter tests widget/flow. |
| Logs rollout renderer non encore emis. | Phase 4 | Ajouter logs `boot_renderer` quand le renderer consomme le provider. |

## Plan pour Phase 3

Phase 3 peut demarrer sans nouvelle exploration large du routage.

Priorites :

1. Extraire le chemin `catalog_snapshot_missing -> refresh -> cached -> home`
   hors de `WelcomeSourceLoadingPage`.
2. Ajouter ou concretiser l'etat runtime `catalog_preparing`.
3. Mapper les erreurs catalogue vers reason codes stables :
   `source_timeout`, `provider_error`, `credentials_invalid`, `catalog_empty`.
4. Faire produire `home_ready` par l'orchestrateur apres catalogue exploitable.
5. Garder `/welcome/sources/loading` comme fallback de rollout tant que le
   renderer catalogue n'est pas pret.

## Plan pour Phase 4

Phase 4 peut consommer les contrats deja poses :

- `bootScreenModelProvider`;
- `BootScreenMapper`;
- `BootActionIntent`;
- `executeBootAction`;
- `enableBootScreenRenderer`;
- fallback legacy documente.

Le renderer Figma doit afficher le modele et appeler le handler, sans navigation
directe ni logique catalogue.

## Definition de fini Phase 2

| critere | statut |
| --- | --- |
| Une seule couche decide les transitions boot. | Atteint pour les decisions router/action; le catalogue reste fallback legacy jusqu'a Phase 3. |
| Le router applique les destinations sans dupliquer la logique metier. | Atteint et teste sur destinations critiques. |
| Les widgets n'embarquent plus de logique catalogue critique. | Partiellement atteint : les widgets ne decident plus les transitions boot principales, mais `WelcomeSourceLoadingPage` garde le refresh catalogue temporaire. |
| Le bouton principal de chaque ecran produit une action testable. | Atteint pour les actions boot raccordees et mappees. |
| La Phase 3 peut traiter le catalogue sans redecouvrir le routage. | Atteint. |
| La Phase 4 peut remplacer l'UI avec un provider et un handler stables. | Atteint. |

## References Phase 2

- `ROUTING_REVIEW.md`
- `RESPONSIBILITY_CONTRACT.md`
- `BOOT_ACTION_HANDLER.md`
- `BOOT_SCREEN_RUNTIME.md`
- `GUARD_ALIGNMENT.md`
- `NAVIGATION_REPLACEMENT.md`
- `ACTION_PAGE_HANDOFF.md`
- `ROLLOUT_FALLBACK.md`
- `BOOT_TEST_COVERAGE.md`

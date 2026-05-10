# Phase 4 - Debloquer Home

## Contrat d'execution

Cette phase doit etre executee en appliquant strictement :

- `docs/codex_execution_contract.md` ;
- `docs/rules.md` ;
- `docs/run_logs_commands.md` uniquement si une reproduction runtime ou une
  capture de logs devient necessaire.

La phase 4 doit separer les erreurs de contenu Home des erreurs catalogue/source.
Une erreur de feed Home, une section vide ou un timeout de bibliotheque ne doit
plus empecher l'ouverture de Home quand l'entree et le catalogue local sont
exploitables.

## Objectif

Transformer les echecs non critiques de Home en etats partiels actionnables.

Le demarrage doit repondre a deux questions distinctes :

```text
Home peut-il s'ouvrir avec le minimum metier deja valide ?
Quelles sections Home sont degradees et quelle action proposer ?
```

Resultat attendu :

- Home s'ouvre si l'entree est valide et si le catalogue/source est considere
  exploitable par la phase 3 ;
- `homeState.error != null` devient un `HomePartial`, pas un echec de lancement ;
- `homeState.iptvLists.isEmpty` n'est plus un echec global si la readiness
  catalogue est deja ouvrable ;
- le timeout de `homeInProgressProvider` devient un `HomePartial` lie a la
  bibliotheque/reprise ;
- Home affiche une banniere actionnable pour les sections degradees ;
- les cas catalogue/source restent routes vers la recuperation source dediee.

## Non-objectifs

Ne pas faire dans cette phase :

- changer les routes publiques ;
- changer la decision auth/profil/source ;
- changer le contrat catalogue ou le refresh bloquant de la phase 3 ;
- supprimer `AppLaunchOrchestrator` ;
- reecrire tout Home ;
- creer les ecrans finaux de recuperation source ;
- masquer les erreurs source/catalogue sous une banniere Home generique.

Ces sujets appartiennent aux phases precedentes ou suivantes. La phase 4 doit
uniquement rendre Home tolerant aux erreurs de sections non critiques.

## Fichiers a inspecter avant modification

Avant toute modification de code, lire au minimum :

- `lib/src/core/startup/app_launch_orchestrator.dart`
- `lib/src/core/startup/domain/boot_contracts.dart`
- `lib/src/core/startup/domain/resolve_catalog_readiness.dart`
- `lib/src/core/startup/domain/startup_recovery_mapper.dart`
- `lib/src/core/router/launch_redirect_guard.dart`
- `lib/src/features/home/presentation/providers/home_providers.dart`
- `lib/src/features/home/presentation/widgets/home_content.dart`
- `lib/src/features/home/presentation/widgets/home_desktop_layout.dart`
- `lib/src/features/home/presentation/widgets/home_mobile_layout.dart`
- `lib/src/features/home/presentation/widgets/home_error_banner.dart`
- `lib/src/features/home/presentation/widgets/home_continue_watching_section.dart`
- `lib/src/features/welcome/presentation/pages/splash_bootstrap_page.dart`
- `lib/src/features/welcome/presentation/providers/bootstrap_providers.dart`

Verifier aussi les tests existants :

```powershell
rg --files test | rg "startup|home|bootstrap|shell|library"
```

## Etat actuel a corriger

Le lancement peut encore traiter des erreurs Home comme des echecs globaux :

- `homeState.error != null` apres preload ;
- `homeState.iptvLists.isEmpty` avec source active ;
- timeout de `homeInProgressProvider.future`.

Ces conditions melangent deux niveaux :

- catalogue/source : condition minimale pour ouvrir Home ;
- sections Home : contenu enrichi, feed, reprise, bibliotheque.

La phase 4 doit garder le premier niveau bloquant quand il est vraiment source,
mais transformer le second niveau en `HomePartial`.

## Contrat Home partiel cible

Le contrat existant `HomeReadiness` doit etre utilise comme frontiere :

```text
HomeReady
HomePartial
SourceRecoveryRequired
```

Regle centrale :

- `SourceRecoveryRequired` appartient aux problemes source/catalogue ;
- `HomePartial` appartient aux sections Home degradables ;
- `HomeReady` signifie qu'aucune degradation critique n'a ete detectee.

Reason codes recommandes :

| Situation | Reason code | Actions |
| --- | --- | --- |
| Feed Home en erreur | `home_feed_failed` | `retryHomeSections` |
| IPTV Home vide mais catalogue ouvrable | `home_iptv_sections_empty` | `retryHomeSections`, `resyncSource` |
| Reprise/bibliotheque en timeout | `library_preload_timeout` | `retryLibrary` |
| Reprise/bibliotheque en erreur | `library_preload_failed` | `retryLibrary` |
| Home partiel multiple | `home_partial` | actions combinees |

Si un reason code n'existe pas encore dans `StartupRecoveryReasonCodes`, il doit
etre ajoute dans la phase 4 avec un test du mapper.

## Banniere Home cible

La banniere Home doit etre visible dans Home, pas dans le tunnel de boot, et
doit rester actionnable.

Comportement attendu :

- afficher une seule banniere compacte si une ou plusieurs sections sont
  degradees ;
- prioriser l'action la plus utile (`retryHomeSections` ou `retryLibrary`) ;
- ne pas afficher de message source/catalogue si la recuperation source dediee
  est requise ;
- rester compatible desktop, mobile et TV/focus ;
- ne pas bloquer le rendu des autres sections.

## Roadmap phase 4

### Etape 1 - Audit cible sans modification

Objectif : localiser tous les blocages Home restants.

Actions :

- lire les fichiers listes dans "Fichiers a inspecter avant modification" ;
- lister les usages de `homeState.error`, `iptvLists.isEmpty`,
  `homeInProgressProvider.future`, `homePreloadInvalidState` et
  `libraryPreloadTimeout` ;
- distinguer les erreurs catalogue/source des erreurs de sections Home ;
- verifier si `home_error_banner.dart` est deja exploitable ou doit etre adapte ;
- lister les tests Home/startup existants qui couvrent ces chemins.

Livrable :

- aucune modification de code ;
- decision sur les fichiers a modifier et les reason codes a ajouter.

Verification :

- aucune commande Flutter obligatoire.

### Etape 2 - Ajouter le contrat de degradation Home

Objectif : representer les sections Home degradees sans bloquer Home.

Actions :

- ajouter ou completer les reason codes Home partiel ;
- ajouter un modele minimal si necessaire, par exemple `HomePartialIssue` ou
  `HomeDegradation`, uniquement si le code existant ne suffit pas ;
- mapper feed, IPTV sections vides et bibliotheque vers `HomePartial` ;
- ne pas mapper les echecs catalogue/source vers `HomePartial`.

Livrable :

- contrat testable sans UI ;
- reason codes stables et logs-safe.

Verification :

```powershell
flutter test test/core/startup/startup_recovery_mapper_test.dart
flutter analyze
```

### Etape 3 - Rendre le preload Home non bloquant

Objectif : supprimer les echecs globaux causes par les sections Home.

Actions :

- dans `AppLaunchOrchestrator`, ne plus throw si `homeState.error != null` ;
- ne plus throw si `homeState.iptvLists.isEmpty` alors que le catalogue est
  ouvrable ;
- convertir ces situations en `HomePartial` ou en etat de degradation expose a
  Home ;
- conserver les throws uniquement pour les transitions invalides techniques ou
  les cas source/catalogue deja decides par la phase 3 ;
- logger un `reasonCode` Home partiel sans IDs bruts.

Livrable :

- Home peut s'ouvrir avec feed ou sections IPTV degradees ;
- aucune route publique ne change.

Verification :

```powershell
flutter test test/core/startup/app_launch_orchestrator_local_mode_test.dart
flutter analyze
```

### Etape 4 - Rendre la reprise/bibliotheque non bloquante

Objectif : transformer le timeout de `homeInProgressProvider` en degradation.

Actions :

- remplacer le timeout bloquant de `homeInProgressProvider.future` par un
  signal `HomePartial` ;
- exposer une action `retryLibrary` ;
- verifier que la section "continuer a regarder" peut echouer sans casser le
  reste de Home ;
- ne pas relancer tout le bootstrap pour une erreur de reprise.

Livrable :

- Home s'ouvre meme si la reprise est lente ou indisponible ;
- l'utilisateur dispose d'une action de retry ciblee.

Verification :

```powershell
flutter test test/core/startup/app_launch_orchestrator_local_mode_test.dart
flutter test test/features/home/presentation/widgets/home_continue_watching_section_test.dart
flutter analyze
```

Le second test peut etre adapte au fichier existant le plus proche.

### Etape 5 - Ajouter ou adapter la banniere Home actionnable

Objectif : rendre les degradations visibles et recuperables dans Home.

Actions :

- reutiliser `home_error_banner.dart` si possible ;
- afficher les degradations Home partiel dans `home_content.dart`,
  `home_desktop_layout.dart` et `home_mobile_layout.dart` selon la structure
  reelle ;
- brancher les actions :
  - `retryHomeSections` -> recharge des sections Home ;
  - `retryLibrary` -> refresh/invalidation de `homeInProgressProvider` ;
  - `resyncSource` seulement si l'etat reste un probleme IPTV non bloquant ;
- verifier focus clavier/TV sur les actions de la banniere.

Livrable :

- banniere Home compacte, actionnable et non bloquante ;
- comportement coherent desktop/mobile/TV.

Verification :

```powershell
flutter test test/features/home/presentation/widgets/home_iptv_section_test.dart
flutter test test/features/home/presentation/widgets/home_continue_watching_section_test.dart
flutter analyze
```

Adapter les noms de tests aux fichiers reellement disponibles.

### Etape 6 - Ajouter les tests de regression startup/Home

Objectif : proteger les anciens chemins qui menaient au blocage generique.

Actions :

- tester `homeState.error != null` -> destination `home` + `HomePartial` ;
- tester `iptvLists.isEmpty` avec catalogue ouvrable -> destination `home` +
  degradation Home, pas recuperation source ;
- tester timeout `homeInProgressProvider` -> destination `home` + action
  `retryLibrary` ;
- tester erreur catalogue/source sans snapshot -> recuperation source dediee ;
- tester qu'une erreur feed ne produit pas `SourceRecoveryRequired` ;
- tester que la banniere expose au moins une action primaire.

Verification :

```powershell
flutter test test/core/startup/app_launch_orchestrator_local_mode_test.dart
flutter test test/features/home/presentation/widgets/home_error_banner_test.dart
flutter analyze
```

### Etape 7 - Revue de fin de phase

Objectif : confirmer que Home n'est plus bloque par des erreurs de sections.

Checklist :

- `homeState.error != null` ne bloque plus le lancement ;
- `homeState.iptvLists.isEmpty` n'est plus un echec global si le catalogue est
  ouvrable ;
- `homeInProgressProvider` ne bloque plus Home ;
- les erreurs Home deviennent `HomePartial` ;
- les erreurs catalogue/source restent `SourceRecoveryRequired` ;
- une banniere Home actionnable existe ;
- les actions de retry sont ciblees ;
- les logs utilisent des `reasonCode`, pas des IDs bruts ;
- les tests cibles passent ;
- `flutter analyze` passe.

Livrable :

- note finale avec fichiers modifies, commandes executees, resultats et risques
  restants, conformement a `docs/codex_execution_contract.md`.

## Tests attendus

Tests startup :

```text
test/core/startup/app_launch_orchestrator_local_mode_test.dart
test/core/startup/startup_recovery_mapper_test.dart
```

Tests Home widgets/providers, selon les fichiers existants :

```text
test/features/home/presentation/widgets/home_error_banner_test.dart
test/features/home/presentation/widgets/home_iptv_section_test.dart
test/features/home/presentation/widgets/home_continue_watching_section_test.dart
```

Commande de decouverte :

```powershell
rg --files test | rg "startup|home|bootstrap|shell|library"
```

## Criteres d'acceptation

- Home s'ouvre quand l'entree et le catalogue/source sont valides.
- Les erreurs feed Home ne bloquent pas le lancement.
- Les sections IPTV vides ne sont pas un echec global quand le catalogue est
  ouvrable.
- Le timeout de reprise/bibliotheque ne bloque pas le lancement.
- Les degradations Home sont visibles dans Home et proposent une action.
- Les erreurs catalogue/source restent traitees par la recuperation source.
- Les destinations publiques restent inchangees.
- Les tests cibles passent.
- `flutter analyze` passe apres integration.

## Risques a surveiller

- Confondre section IPTV vide et catalogue source vide : le premier est un
  `HomePartial`, le second reste une recuperation source.
- Ouvrir Home avec un catalogue non exploitable : la phase 3 doit rester la
  frontiere minimale.
- Ajouter une banniere trop generique qui masque la vraie action a effectuer.
- Relancer tout le bootstrap pour une simple erreur de section Home.
- Oublier les comportements TV/focus sur la banniere.
- Multiplier les etats partiels sans mapping centralise.

## Definition of done

La phase 4 est terminee quand :

1. les blocages `homeState.error`, `iptvLists.isEmpty` et
   `homeInProgressProvider` sont retires du chemin critique ;
2. les degradations Home sont mappees en `HomePartial` ;
3. les cas catalogue/source restent separes en `SourceRecoveryRequired` ;
4. une banniere Home actionnable est disponible ;
5. les actions de retry ciblent la section concernee ;
6. les tests de regression startup/Home couvrent les anciens blocages ;
7. `flutter analyze` passe ;
8. une note de revue de fin de phase documente commandes, resultats et risques.

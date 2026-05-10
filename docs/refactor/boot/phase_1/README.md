# Phase 1 - Clarifier les contrats de demarrage

## Contrat d'execution

Cette phase doit etre executee en appliquant strictement :

- `docs/codex_execution_contract.md` ;
- `docs/rules.md` ;
- `docs/run_logs_commands.md` uniquement si une reproduction runtime ou une
  capture de logs devient necessaire.

La phase 1 est une phase de fondation. Elle doit introduire les contrats qui
permettront ensuite de simplifier le tunnel de demarrage sans changer encore le
comportement utilisateur principal.

## Objectif

Remplacer les etats implicites et les erreurs generiques du boot par des
contrats explicites, typables, testables et actionnables.

Le but n'est pas de reecrire le demarrage dans cette phase. Le but est de poser
le vocabulaire stable qui servira aux phases suivantes :

- `EntryDecision` : ou envoyer l'utilisateur ;
- `HomeReadiness` : quel niveau de contenu Home est disponible ;
- `CatalogMode` : etat exploitable du catalogue local ;
- `RecoveryAction` : action utilisateur ou systeme proposee ;
- `StartupRecoveryMapper` : traduction unique des erreurs techniques en
  decisions/actions lisibles.

## Non-objectifs

Ne pas faire dans cette phase :

- reecrire `AppLaunchOrchestrator` ;
- changer les routes ;
- changer les ecrans ;
- supprimer `LaunchErrorPanel` ;
- modifier le comportement de preload Home ;
- rendre le catalogue non bloquant ;
- modifier la strategie cloud/local-first.

Ces sujets appartiennent aux phases suivantes. La phase 1 doit rester petite,
lisible et reversible.

## Fichiers a inspecter avant modification

Avant toute modification de code, lire au minimum :

- `lib/src/core/startup/app_launch_orchestrator.dart`
- `lib/src/core/startup/app_startup_gate.dart`
- `lib/src/core/startup/domain/startup_contracts.dart`
- `lib/src/core/startup/domain/tunnel_state.dart`
- `lib/src/features/welcome/presentation/pages/splash_bootstrap_page.dart`
- `lib/src/features/welcome/presentation/providers/bootstrap_providers.dart`
- `lib/src/features/home/presentation/providers/home_providers.dart`
- `lib/src/core/widgets/launch_error_panel.dart`

Si le mapping touche les erreurs IPTV, lire aussi :

- `lib/src/features/iptv/domain/failures/iptv_failures.dart`
- `lib/src/core/network/network_failures.dart`
- `lib/src/core/shared/failure.dart`

## Emplacement recommande

Creer un nouveau petit module dans le domaine startup :

```text
lib/src/core/startup/domain/boot_contracts.dart
lib/src/core/startup/domain/startup_recovery_mapper.dart
```

Alternative acceptable si le codebase prefere moins de fichiers :

```text
lib/src/core/startup/domain/startup_recovery_contracts.dart
```

La decision finale doit suivre les conventions observees dans les fichiers
existants. Ne pas creer de dossier generique `utils` ou `helpers`.

## Contrats a creer

### CatalogMode

`CatalogMode` decrit si le catalogue local est exploitable pour ouvrir Home.

```dart
enum CatalogMode {
  fresh,
  cached,
  stale,
  missing,
  empty,
  unavailable,
}
```

Definition attendue :

- `fresh` : snapshot local present et considere a jour ;
- `cached` : snapshot local present, utilisable, fraicheur inconnue ;
- `stale` : snapshot local present, ancien mais utilisable ;
- `missing` : aucun snapshot local exploitable ;
- `empty` : snapshot ou sync terminee, mais aucun contenu utile ;
- `unavailable` : impossible de determiner l'etat du catalogue.

Invariant :

- `fresh`, `cached` et `stale` peuvent ouvrir Home ;
- `missing`, `empty` et `unavailable` doivent mener a une surface de
  preparation ou de recuperation source.

### RecoveryAction

`RecoveryAction` liste les actions possibles sans encoder d'UI.

```dart
enum RecoveryAction {
  retry,
  exportLogs,
  login,
  createProfile,
  chooseProfile,
  addSource,
  chooseSource,
  reconnectSource,
  resyncSource,
  openHomeCached,
  retryHomeSections,
  retryLibrary,
}
```

Invariant :

- toute erreur visible doit exposer au moins une `RecoveryAction` primaire ;
- `exportLogs` ne doit jamais etre la seule action ;
- les actions restent des intentions, pas des callbacks UI.

### EntryDecision

`EntryDecision` remplace les destinations implicites du tunnel par un resultat
type.

```dart
sealed class EntryDecision {
  const EntryDecision({required this.reasonCode});

  final String reasonCode;
}

final class OpenHome extends EntryDecision {
  const OpenHome({
    required super.reasonCode,
    required this.profileId,
    required this.sourceId,
    required this.catalogMode,
  });

  final String profileId;
  final String sourceId;
  final CatalogMode catalogMode;
}

final class RequireAuth extends EntryDecision {
  const RequireAuth({required super.reasonCode});
}

final class RequireProfile extends EntryDecision {
  const RequireProfile({required super.reasonCode});
}

final class RequireSource extends EntryDecision {
  const RequireSource({required super.reasonCode});
}

final class RequireSourceSelection extends EntryDecision {
  const RequireSourceSelection({required super.reasonCode});
}

final class TechnicalBootFailure extends EntryDecision {
  const TechnicalBootFailure({
    required super.reasonCode,
    required this.message,
    required this.actions,
  });

  final String message;
  final List<RecoveryAction> actions;
}
```

Invariants :

- `OpenHome` exige un `profileId`, un `sourceId` et un `CatalogMode`
  exploitable ;
- `RequireAuth`, `RequireProfile`, `RequireSource` et
  `RequireSourceSelection` ne sont pas des erreurs techniques ;
- `TechnicalBootFailure` est reserve aux echecs de boot critique ;
- les `reasonCode` doivent etre stables et logs-safe.

### HomeReadiness

`HomeReadiness` decrit le niveau de contenu disponible une fois Home atteignable.

```dart
sealed class HomeReadiness {
  const HomeReadiness({required this.reasonCode});

  final String reasonCode;
}

final class HomeReady extends HomeReadiness {
  const HomeReady({
    required super.reasonCode,
    required this.catalogMode,
  });

  final CatalogMode catalogMode;
}

final class HomePartial extends HomeReadiness {
  const HomePartial({
    required super.reasonCode,
    required this.catalogMode,
    required this.actions,
  });

  final CatalogMode catalogMode;
  final List<RecoveryAction> actions;
}

final class SourceRecoveryRequired extends HomeReadiness {
  const SourceRecoveryRequired({
    required super.reasonCode,
    required this.actions,
  });

  final List<RecoveryAction> actions;
}
```

Invariants :

- `HomeReady` signifie que les contenus principaux sont disponibles ;
- `HomePartial` signifie que Home peut s'afficher mais qu'une zone est degradee ;
- `SourceRecoveryRequired` signifie que Home ne doit pas etre affiche comme si
  le contenu etait vide par choix utilisateur ;
- une erreur feed ou bibliotheque ne doit pas produire
  `SourceRecoveryRequired`.

## StartupRecoveryMapper

Ajouter un mapper unique dont le role est de transformer les erreurs actuelles
en `reasonCode` et `RecoveryAction`.

Signature recommandee :

```dart
final class StartupRecoveryMapper {
  const StartupRecoveryMapper();

  StartupRecoveryPlan mapBootFailure(Object error);

  StartupRecoveryPlan mapLaunchFailure({
    required String step,
    required String? errorCode,
    required Object original,
  });

  StartupRecoveryPlan mapHomeFailure({
    required String reasonCode,
    Object? original,
  });
}

final class StartupRecoveryPlan {
  const StartupRecoveryPlan({
    required this.reasonCode,
    required this.actions,
    this.message,
  });

  final String reasonCode;
  final List<RecoveryAction> actions;
  final String? message;
}
```

Regles :

- le mapper ne doit pas dependre de Flutter UI ;
- le mapper ne doit pas lire Riverpod ;
- le mapper ne doit pas lancer de logs lui-meme ;
- il doit etre testable par simples tests unitaires Dart ;
- il doit centraliser les correspondances entre erreurs techniques et actions.

## Reason codes stables

Utiliser des `reasonCode` courts, explicites et sans donnees sensibles.

Liste initiale recommandee :

| Reason code | Sens | Actions |
| --- | --- | --- |
| `boot_config_timeout` | config trop longue | `retry`, `exportLogs` |
| `boot_dependencies_timeout` | init dependances trop longue | `retry`, `exportLogs` |
| `boot_technical_failure` | erreur critique non classee | `retry`, `exportLogs` |
| `auth_required` | connexion necessaire | `login` |
| `profile_required` | aucun profil exploitable | `createProfile` |
| `profile_selection_required` | selection profil invalide | `chooseProfile` |
| `source_required` | aucune source exploitable | `addSource` |
| `source_selection_required` | plusieurs sources, aucune valide | `chooseSource` |
| `catalog_snapshot_missing` | pas de catalogue local | `resyncSource`, `chooseSource` |
| `catalog_sync_timeout` | sync IPTV timeout | `retry`, `chooseSource` |
| `catalog_provider_error` | provider IPTV en erreur | `retry`, `chooseSource` |
| `catalog_credentials_invalid` | identifiants source invalides | `reconnectSource` |
| `catalog_empty` | catalogue vide | `resyncSource`, `chooseSource` |
| `home_feed_failed` | sections Home en erreur | `retryHomeSections` |
| `library_preload_timeout` | reprise/bibliotheque timeout | `retryLibrary` |

## Mapping minimal a couvrir en phase 1

Phase 1 doit couvrir au minimum les erreurs deja identifiees :

| Source actuelle | Nouveau reasonCode | Actions |
| --- | --- | --- |
| `StartupFailureCode.configTimeout` | `boot_config_timeout` | `retry`, `exportLogs` |
| `StartupFailureCode.dependenciesInitTimeout` | `boot_dependencies_timeout` | `retry`, `exportLogs` |
| `StartupFailureCode.configInvalid` | `boot_technical_failure` | `retry`, `exportLogs` |
| `StartupFailureCode.dependenciesInitFailed` | `boot_technical_failure` | `retry`, `exportLogs` |
| `AppLaunchErrorCode.iptvNetworkTimeout` | `catalog_sync_timeout` | `retry`, `chooseSource` |
| `AppLaunchErrorCode.iptvProviderError` | `catalog_provider_error` | `retry`, `chooseSource` |
| `AppLaunchErrorCode.iptvEmptyData` | `catalog_empty` | `resyncSource`, `chooseSource` |
| `AppLaunchErrorCode.homePreloadInvalidState` | `home_feed_failed` ou `catalog_snapshot_missing` selon contexte | action selon contexte |
| `AppLaunchErrorCode.libraryPreloadTimeout` | `library_preload_timeout` | `retryLibrary` |

Si le contexte ne permet pas encore de distinguer `homePreloadInvalidState`, le
mapper doit garder un fallback explicite :

```text
home_preload_invalid_state
```

avec actions :

```text
retry, exportLogs
```

## Roadmap phase 1

### Etape 1 - Audit cible sans modification

Objectif : confirmer les points d'accroche et les erreurs deja presentes.

Actions :

- lire les fichiers listes dans "Fichiers a inspecter avant modification" ;
- lister les erreurs et reason codes deja presents ;
- confirmer ou ajuster l'emplacement des nouveaux contrats ;
- verifier les tests existants autour du startup.

Livrable :

- aucune modification de code ;
- notes courtes dans le message de travail ou dans le ticket ;
- decision sur le ou les fichiers a creer.

Verification :

- aucune commande Flutter obligatoire.

### Etape 2 - Ajouter les contrats purs

Objectif : creer les types sans les brancher a la navigation.

Actions :

- creer `CatalogMode` ;
- creer `RecoveryAction` ;
- creer `EntryDecision` ;
- creer `HomeReadiness` ;
- ajouter les commentaires utiles sur les invariants non evidents ;
- eviter toute dependance Flutter UI ou Riverpod.

Livrable :

- fichier de contrats dans `lib/src/core/startup/domain/` ;
- export eventuel si une convention locale le demande.

Verification :

- `flutter analyze` si le code est ajoute avant les tests ;
- sinon poursuivre vers l'etape 3 et verifier avec les tests cibles.

### Etape 3 - Ajouter `StartupRecoveryMapper`

Objectif : centraliser la traduction des erreurs actuelles en plans de
recuperation.

Actions :

- creer `StartupRecoveryPlan` ;
- creer `StartupRecoveryMapper` ;
- mapper les erreurs minimales listees dans cette phase ;
- ajouter un fallback stable pour les erreurs inconnues ;
- ne pas logger dans le mapper ;
- ne pas lire d'etat global dans le mapper.

Livrable :

- mapper testable sans environnement Flutter complet ;
- aucun changement de navigation.

Verification :

- analyse locale si necessaire ;
- tests a l'etape suivante.

### Etape 4 - Couvrir le mapper par tests unitaires

Objectif : verrouiller le vocabulaire avant integration dans le tunnel.

Actions :

- creer `test/core/startup/startup_recovery_mapper_test.dart` ;
- tester les cas nominaux du mapping minimal ;
- tester le fallback inconnu ;
- tester que chaque plan expose au moins une action ;
- tester que les erreurs techniques ont `retry`.

Livrable :

- tests unitaires lisibles, sans reseau, sans storage, sans Riverpod.

Verification :

```powershell
flutter test test/core/startup/startup_recovery_mapper_test.dart
```

### Etape 5 - Integration minimale et non comportementale

Objectif : rendre le nouveau contrat disponible sans changer le flux utilisateur.

Actions acceptables :

- ajouter un provider simple du mapper si utile ;
- utiliser le mapper uniquement pour enrichir un log ou un diagnostic ;
- ne pas remplacer encore les destinations legacy ;
- ne pas modifier les textes utilisateur.

Livrable :

- integration additive ;
- aucun changement visible attendu.

Verification :

```powershell
flutter analyze
```

### Etape 6 - Revue de fin de phase

Objectif : s'assurer que la phase est une base saine pour la phase 2.

Checklist :

- les contrats sont petits et comprehensibles ;
- les noms correspondent a la roadmap principale ;
- les reason codes sont stables et logs-safe ;
- chaque erreur mappee a une action ;
- `EntryDecision` et `HomeReadiness` restent separes ;
- aucun changement UI/navigation n'a ete introduit ;
- les tests cibles passent ;
- `flutter analyze` passe.

Livrable :

- note finale avec fichiers modifies, commandes executees, resultats et risques
  restants, conformement a `docs/codex_execution_contract.md`.

## Integration attendue en phase 1

Cette phase peut rester additive, mais elle doit etre utile.

Minimum attendu :

- les nouveaux contrats existent ;
- le mapper existe ;
- les tests du mapper existent ;
- aucune route ou UI n'est modifiee ;
- les fichiers legacy continuent de compiler sans changement fonctionnel.

Integration optionnelle acceptable :

- exposer le mapper via un provider simple ;
- utiliser le mapper dans un seul endroit de log sans modifier la navigation.

Ne pas brancher toute la navigation sur ces nouveaux contrats en phase 1.

## Tests attendus

Creer des tests unitaires proches du nouveau mapper, par exemple :

```text
test/core/startup/startup_recovery_mapper_test.dart
```

Cas minimaux :

- timeout config -> `boot_config_timeout` + `retry/exportLogs` ;
- timeout dependances -> `boot_dependencies_timeout` + `retry/exportLogs` ;
- IPTV network timeout -> `catalog_sync_timeout` + `retry/chooseSource` ;
- IPTV provider error -> `catalog_provider_error` + `retry/chooseSource` ;
- IPTV empty data -> `catalog_empty` + `resyncSource/chooseSource` ;
- library timeout -> `library_preload_timeout` + `retryLibrary` ;
- erreur inconnue -> fallback stable + `retry/exportLogs`.

Verification a lancer apres implementation :

```powershell
flutter test test/core/startup/startup_recovery_mapper_test.dart
flutter analyze
```

Si seule cette documentation est modifiee, aucune commande Flutter n'est
obligatoire. Verifier alors uniquement la coherence lisible du Markdown.

## Criteres d'acceptation

- Les nouveaux contrats sont nommes selon le vocabulaire de la roadmap.
- Les contrats ne dependent pas de Flutter UI.
- Les etats invalides sont difficiles a construire ou documentes.
- Chaque erreur mappee expose au moins une action primaire.
- Aucun secret ou identifiant brut n'est inclus dans les `reasonCode`.
- Le mapper est couvert par des tests unitaires.
- Aucun comportement de navigation n'est modifie dans cette phase.
- Le code reste compatible avec l'orchestrateur actuel.

## Risques a surveiller

- Trop abstraire trop tot : garder les modeles petits et directement relies aux
  erreurs actuelles.
- Confondre `EntryDecision` et `HomeReadiness` : l'un route l'utilisateur,
  l'autre decrit le niveau de contenu.
- Utiliser des messages localises comme contrats : les contrats doivent utiliser
  des `reasonCode`, pas des textes UI.
- Transformer `RecoveryAction` en logique UI : les actions doivent rester des
  intentions.
- Cacher `homePreloadInvalidState` derriere un fallback trop vague : documenter
  explicitement les cas non distinguables jusqu'a la phase suivante.

## Definition of done

La phase 1 est terminee quand :

1. les contrats sont ajoutes dans le domaine startup ;
2. le mapper central existe ;
3. les reason codes initiaux sont couverts ;
4. les tests cibles passent ;
5. `flutter analyze` passe ;
6. la roadmap principale peut pointer vers cette phase comme reference
   d'implementation.

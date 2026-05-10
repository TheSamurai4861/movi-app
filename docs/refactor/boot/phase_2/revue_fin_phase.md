# Revue de fin de phase 2

Date : 2026-04-28

## Synthese

La phase 2 est validee pour preparer la phase 3.

`ResolveEntryDecision` existe dans le domaine startup et concentre la decision
d'entree auth/profil/source a partir de snapshots deja lus. Le service reste pur
et ne depend pas de Flutter UI, Riverpod, GetIt, storage, repositories, reseau ou
logs.

`AppLaunchOrchestrator` conserve le role d'integration temporaire. Il adapte les
donnees legacy vers `EntryDecisionInput`, appelle `ResolveEntryDecision`, puis
mappe la decision vers les destinations legacy existantes.

## Fichiers modifies pendant la phase

- `docs/refactor/boot/phase_2/README.md`
- `lib/src/core/startup/domain/resolve_entry_decision.dart`
- `test/core/startup/resolve_entry_decision_test.dart`
- `lib/src/features/welcome/presentation/providers/bootstrap_providers.dart`
- `lib/src/core/startup/app_launch_orchestrator.dart`
- `docs/refactor/boot/phase_2/revue_fin_phase.md`

## Checklist

- `ResolveEntryDecision` est pur et testable : OK.
- Toutes les destinations legacy sont couvertes : OK.
  - `RequireAuth` -> `auth`
  - `RequireProfile` -> `welcomeUser`
  - `RequireSource` -> `welcomeSources`
  - `RequireSourceSelection` -> `chooseSource`
  - `OpenHome` -> `home`
- Les `reasonCode` sont stables et logs-safe : OK.
- `AppLaunchOrchestrator` ne porte plus directement la decision finale
  auth/profil/source : OK, il agit comme adaptateur temporaire.
- Aucun changement UI ou route publique n'a ete introduit : OK.
- Les preloads Home et catalogue n'ont pas ete remplaces dans cette phase : OK.
- La gestion des erreurs techniques reste sur le chemin existant : OK.

## Commandes executees

```powershell
rg --files test | rg "startup|entry|bootstrap|launch"
flutter test test\core\startup\resolve_entry_decision_test.dart
flutter test test\core\startup\app_launch_orchestrator_local_mode_test.dart
flutter analyze
```

## Resultats

- `resolve_entry_decision_test.dart` : 9 tests passes.
- `app_launch_orchestrator_local_mode_test.dart` : 24 tests passes.
- `flutter analyze` : aucun probleme detecte.

## Risques restants

- L'adaptation legacy reste dans `AppLaunchOrchestrator`. C'est acceptable pour
  cette phase, mais la phase suivante devra reduire ce bloc ou le deplacer si le
  tunnel de demarrage continue a grossir.
- Le catalogue reste un invariant bloquant pour `OpenHome` via
  `CatalogMode.canOpenHome`. La recuperation catalogue et les solutions
  utilisateur associees ne sont pas traitees ici.
- Les tests valident les destinations principales et le chemin local/orchestrateur
  existant. Ils ne remplacent pas une verification runtime complete sur device ou
  emulateur.

## Decision

La phase 2 peut etre consideree comme terminee. La phase 3 peut se concentrer sur
la readiness Home/catalogue et les actions de recuperation sans recreer la logique
auth/profil/source dans l'orchestrateur.

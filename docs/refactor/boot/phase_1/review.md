# Phase 1 - Revue de fin de phase

## Statut

Phase 1 terminee.

Les contrats de demarrage et le mapper de recuperation sont ajoutes de maniere
additive. La navigation, les routes, les ecrans et les textes utilisateur ne
sont pas modifies dans cette phase.

## Checklist

- [x] Les contrats sont petits et comprehensibles.
- [x] Les noms correspondent a la roadmap principale :
  `EntryDecision`, `HomeReadiness`, `CatalogMode`, `RecoveryAction`.
- [x] Les `reasonCode` sont stables, courts et logs-safe.
- [x] Chaque erreur mappee expose au moins une `RecoveryAction`.
- [x] `EntryDecision` et `HomeReadiness` restent separes.
- [x] Aucun changement UI ou navigation n'a ete introduit.
- [x] Les tests cibles passent.
- [x] `flutter analyze` passe.

## Fichiers de phase

- `lib/src/core/startup/domain/boot_contracts.dart`
- `lib/src/core/startup/domain/startup_recovery_mapper.dart`
- `lib/src/features/welcome/presentation/providers/bootstrap_providers.dart`
- `test/core/startup/startup_recovery_mapper_test.dart`
- `docs/refactor/boot/phase_1/README.md`
- `docs/refactor/boot/phase_1/review.md`

## Commandes executees

```powershell
Get-Content docs\codex_execution_contract.md
Get-Content docs\rules.md
Get-Content docs\refactor\boot\phase_1\README.md
Get-Content lib\src\core\startup\domain\boot_contracts.dart
Get-Content lib\src\core\startup\domain\startup_recovery_mapper.dart
Get-Content lib\src\features\welcome\presentation\providers\bootstrap_providers.dart
Get-Content test\core\startup\startup_recovery_mapper_test.dart
git status --short
git diff -- lib\src\core\startup\domain\boot_contracts.dart lib\src\core\startup\domain\startup_recovery_mapper.dart lib\src\features\welcome\presentation\providers\bootstrap_providers.dart test\core\startup\startup_recovery_mapper_test.dart docs\refactor\boot\phase_1\README.md
flutter test test\core\startup\startup_recovery_mapper_test.dart
flutter analyze
```

## Resultats

- `flutter test test\core\startup\startup_recovery_mapper_test.dart` :
  14 tests passent.
- `flutter analyze` : aucun probleme detecte.

## Risques restants

- `StartupRecoveryMapper` est expose via provider, mais il n'est pas encore
  consomme par l'orchestrateur legacy. C'est volontaire en phase 1.
- `homePreloadInvalidState` reste un fallback explicite
  `home_preload_invalid_state` tant que le contexte ne permet pas de distinguer
  proprement feed, bibliotheque et catalogue.
- Les reason codes legacy et les nouveaux contrats coexistent encore. La phase
  2 devra brancher progressivement le tunnel de demarrage sur ces contrats.
- Les assertions garantissent les invariants simples. La regle "`exportLogs` ne
  doit jamais etre la seule action" est verifiee par `hasPrimaryAction` et par
  les tests du mapper, pas imposee globalement a toute construction manuelle.

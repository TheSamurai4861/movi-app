# Phase 4 - Revue de fin de phase

Date : 2026-04-29

## Statut

Phase 4 terminee.

Home n'est plus bloque par les erreurs de sections non critiques quand l'entree
et le catalogue local sont exploitables. Les erreurs feed, IPTV Home vide et
reprise/bibliotheque sont converties en `HomePartial`, exposees a Home via une
banniere actionnable.

Les erreurs catalogue/source restent separees et continuent de router vers la
recuperation source dediee.

## Checklist

- [x] `homeState.error != null` ne bloque plus le lancement.
- [x] `homeState.iptvLists.isEmpty` n'est plus un echec global si le catalogue
  est ouvrable.
- [x] `homeInProgressProvider` ne bloque plus Home.
- [x] Les erreurs Home deviennent `HomePartial`.
- [x] Les erreurs catalogue/source restent `SourceRecoveryRequired`.
- [x] Une banniere Home actionnable existe.
- [x] Les actions de retry sont ciblees :
  - `retryHomeSections` recharge les sections Home ;
  - `retryLibrary` invalide la reprise/bibliotheque ;
  - `resyncSource` relance la synchronisation source uniquement pour le cas IPTV
    Home non bloquant.
- [x] Les logs utilisent des `reasonCode` stables et pas d'IDs bruts pour les
  erreurs Home partiel.
- [x] Les tests cibles passent.
- [x] `flutter analyze` passe.

## Comportement valide

- Feed Home en erreur :
  - destination finale : `home` ;
  - readiness : `HomePartial` ;
  - reason code : `home_feed_failed` ;
  - action : `retryHomeSections`.

- Sections IPTV Home vides avec catalogue ouvrable :
  - destination finale : `home` ;
  - readiness : `HomePartial` ;
  - reason code : `home_iptv_sections_empty` ;
  - actions : `retryHomeSections`, `resyncSource`.

- Timeout reprise/bibliotheque :
  - destination finale : `home` ;
  - readiness : `HomePartial` ;
  - reason code : `library_preload_timeout` ;
  - action : `retryLibrary`.

- Catalogue/source sans snapshot exploitable :
  - destination finale : recuperation source ;
  - readiness : `SourceRecoveryRequired` ;
  - aucune banniere Home generique n'est publiee.

## Fichiers de phase

- `lib/src/core/startup/domain/boot_contracts.dart`
- `lib/src/core/startup/domain/startup_recovery_mapper.dart`
- `lib/src/core/startup/domain/resolve_home_degradation.dart`
- `lib/src/core/startup/app_launch_orchestrator.dart`
- `lib/src/features/home/presentation/providers/home_providers.dart`
- `lib/src/features/home/presentation/widgets/home_error_banner.dart`
- `lib/src/features/home/presentation/widgets/home_content.dart`
- `lib/src/features/home/presentation/widgets/home_desktop_layout.dart`
- `lib/src/features/home/presentation/widgets/home_mobile_layout.dart`
- `test/core/startup/resolve_home_degradation_test.dart`
- `test/core/startup/startup_recovery_mapper_test.dart`
- `test/core/startup/app_launch_orchestrator_local_mode_test.dart`
- `test/features/home/presentation/widgets/home_error_banner_test.dart`
- `test/features/home/presentation/widgets/home_iptv_section_test.dart`
- `docs/refactor/boot/phase_4/README.md`
- `docs/refactor/boot/phase_4/review.md`

## Commandes executees

Commandes de validation utilisees pendant la phase :

```powershell
flutter test test/core/startup/startup_recovery_mapper_test.dart
flutter test test/core/startup/resolve_home_degradation_test.dart
flutter test test/core/startup/app_launch_orchestrator_local_mode_test.dart
flutter test test/features/home/presentation/widgets/home_error_banner_test.dart
flutter test test/features/home/presentation/widgets/home_iptv_section_test.dart
flutter analyze
```

Commandes d'inspection utilisees pendant la revue :

```powershell
Get-Content -Raw docs/codex_execution_contract.md
Get-Content -Raw docs/rules.md
Get-Content -Raw docs/refactor/boot/phase_4/README.md
rg --files docs/refactor/boot
rg -n "homeState\.error|iptvLists\.isEmpty|homeInProgressProvider\.future|HomePartial|SourceRecoveryRequired|homeDegradationNoticeProvider|HomeErrorBanner|reasonCode|retryLibrary|retryHomeSections|resyncSource" lib/src/core/startup lib/src/features/home/presentation test/core/startup test/features/home/presentation/widgets
```

## Resultats

- `startup_recovery_mapper_test.dart` : passe.
- `resolve_home_degradation_test.dart` : passe.
- `app_launch_orchestrator_local_mode_test.dart` : passe.
- `home_error_banner_test.dart` : passe.
- `home_iptv_section_test.dart` : passe.
- `flutter analyze` : aucun probleme detecte.

## Risques restants

- `AppLaunchOrchestrator` reste l'adaptateur principal du boot legacy. La phase
  reduit les blocages Home, mais ne supprime pas encore l'orchestrateur.
- La recuperation source finale reste portee par les destinations existantes. La
  phase 4 preserve ce routage, mais ne cree pas de nouvel ecran dedie.
- Le focus TV de la banniere est couvert par des boutons Material focusables et
  des tests widget. Il n'y a pas encore de test directionnel TV complet.
- Les messages de banniere sont volontairement courts et non bloquants. Une
  future passe i18n pourra les deplacer dans les localizations.
- Les erreurs de catalogue avec snapshot `cached` ou `stale` restent ouvrables
  par contrat phase 3. C'est voulu, mais cela depend de la fiabilite de la
  lecture du snapshot local.

## Decision

La phase 4 peut etre consideree comme terminee.

La phase suivante peut partir du principe que Home est ouvrable avec un catalogue
local exploitable, meme si certaines sections Home sont degradees. Les travaux
suivants devraient se concentrer sur l'ecran de recuperation source et sur la
reduction progressive de l'adaptateur legacy.

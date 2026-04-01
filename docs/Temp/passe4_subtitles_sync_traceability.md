# Passe 4 - Traceabilite Sous-titres/Audio Sync

## Portee

- Module concerne: synchronisation audio/sous-titres (offsets) introduite en passes 1-3.
- Niveau cible: durcissement "haute assurance" aligne sur `docs/rules_nasa.md`.
- Hors portee: nouvelles features produit, changement de monnetisation.

## Exigences testables

| ID | Exigence | Criticite interne | Fichier(s) implementation |
|---|---|---|---|
| SYNC-REQ-001 | Le systeme clamp les offsets dans `[-5000ms, +5000ms]`. | C1/L1 | `lib/src/core/preferences/playback_sync_offset_preferences.dart`, `lib/src/features/player/data/repositories/media_kit_video_player_repository.dart` |
| SYNC-REQ-002 | La persistance est scopee par profil et restauree apres relance. | C1/L1 | `lib/src/core/preferences/playback_sync_offset_preferences.dart`, `lib/src/core/state/app_state_provider.dart` |
| SYNC-REQ-003 | Si backend non supporte, le comportement est explicite et deterministe (fallback + UI desactivee). | C1/L1 | `lib/src/features/player/domain/repositories/video_player_repository.dart`, `lib/src/features/player/data/repositories/media_kit_video_player_repository.dart`, `lib/src/features/player/presentation/pages/video_player_page.dart`, `lib/src/features/settings/presentation/pages/settings_subtitles_page.dart` |
| SYNC-REQ-004 | L'application des offsets est live et ne casse pas la lecture. | C1/L1 | `lib/src/features/player/presentation/pages/video_player_page.dart`, `lib/src/features/player/presentation/widgets/track_selection_menu.dart` |
| SYNC-REQ-005 | Les actions offset sont observables via logs/diagnostic sans donnees sensibles. | C1/L1 | `lib/src/core/state/app_state_provider.dart`, `lib/src/features/player/data/repositories/media_kit_video_player_repository.dart`, `lib/src/features/player/presentation/pages/video_player_page.dart` |
| SYNC-REQ-006 | L'utilisateur peut appliquer presets rapides et reset depuis Settings/Player sheet. | C2/L2 | `lib/src/features/settings/presentation/pages/settings_subtitles_page.dart`, `lib/src/features/player/presentation/widgets/track_selection_menu.dart` |

## Matrice Exigence -> Test -> Evidence

| Exigence | Tests automatises | Evidence attendue |
|---|---|---|
| SYNC-REQ-001 | `test/core/preferences/playback_sync_offset_preferences_test.dart` | Tests verts + assertion clamp min/max |
| SYNC-REQ-002 | `test/core/preferences/playback_sync_offset_preferences_test.dart`, `test/core/state/playback_sync_offset_controller_test.dart` | Tests verts + verification isolation profils |
| SYNC-REQ-003 | `test/core/state/playback_sync_offset_controller_test.dart` + validations UI/widget existantes | Tests verts + logs fallback + controles desactives |
| SYNC-REQ-004 | `test/core/state/playback_sync_offset_controller_test.dart` (invariants controller) + non regression player tests existants | Tests verts + absence de plantage/pauses forcees |
| SYNC-REQ-005 | Analyse du code + execution scenario tests | Logs `PlayerSync` et `PlayerSyncPrefs` observes |
| SYNC-REQ-006 | `test/core/state/playback_sync_offset_controller_test.dart` + tests settings existants | Presets/reset valident les valeurs attendues |

## Risques residuels

- Le support reel de certaines proprietes mpv depend de la plateforme runtime exacte.
- La preuve "jank notable absent" reste best-effort tant qu'une campagne profile-device exhaustive n'est pas automatisee.

## Mitigations

- Fallback explicite avec `PlayerOffsetUnsupportedException` + UI desactivee.
- Diagnostics structures pour accelerer l'analyse terrain.
- Extension prevue des campagnes profile/replay sur devices cibles.

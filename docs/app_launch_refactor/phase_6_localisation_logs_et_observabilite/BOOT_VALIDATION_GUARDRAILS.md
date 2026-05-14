# Etape 6.6 - Validation et garde-fous

## Cible

Valider le contrat d'observabilite boot et ajouter des garde-fous de non
regression pour:

- transitions critiques tracees;
- absence de fuite de details reseau/id internes vers l'UI;
- lisibilite complete d'un run via `run_id`.

## Garde-fous ajoutes

### 1) Snapshots de logs critiques (`startup_contract`)

Fichier test mis a jour:

- `test/core/startup/app_launch_orchestrator_local_mode_test.dart`

Nouveaux controles:

- coherence `run_id` unique sur un run complet;
- presence des transitions critiques:
  - `boot_state_changed`
  - `catalog_preparation_started`
  - `catalog_preparation_completed`
  - `entry_journey_completed`
- absence de fuite brute dans les logs de contrat:
  - pas de `source_id=...`
  - pas d'endpoint brut (`example.com`)
  - utilisation de `source_key` pseudonymisee.

### 2) Garde-fou UI anti-fuite technique

Fichier test mis a jour:

- `test/core/startup/boot_critical_screens_widget_test.dart`

Nouveau controle:

- verification qu'aucune URL brute (`http://`, `https://`) ni identifiant
  interne de source (`local_xtream_account_`) n'apparait dans les textes UI.

Ce controle complete les assertions deja existantes de non-affichage du
`reasonCode` brut.

## Lisibilite run-to-run (`run_id`)

Le contrat `startup_contract` emet un `run_id` sur chaque evenement structurel.
Les tests valident que ce `run_id` est stable pour un run complet.

## Verification executee

- `flutter analyze` (fichiers modifies)
- `flutter test test/core/startup/app_launch_orchestrator_local_mode_test.dart`
- `flutter test test/core/startup/boot_critical_screens_widget_test.dart`
- `flutter test test/core/startup/boot_action_handler_test.dart`

Tous ces controles doivent rester verts pour considerer 6.6 validee.

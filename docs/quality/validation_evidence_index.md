# Index des preuves de validation — Movi

**Document ID** : `QUAL-EVD-INDEX-001`  
**Version** : `v1`  
**Date d’initialisation** : `2026-04-02`  
**Statut** : `actif`  
**Références** : [`docs/rules_nasa.md`](../rules_nasa.md) §6 (traçabilité), §20 (pipeline), §25 (artefacts de preuve), §26 (dérogations), §27 (quality gates) ; plan [`docs/Refactor/movi_nasa_refactor_plan_v3.md`](../Refactor/movi_nasa_refactor_plan_v3.md).

---

## Objet

Ce fichier est le **point de regroupement** pour les preuves reproductibles de validation (analyse, tests, builds, CI, etc.), conformément au programme phase 0 et aux gates du référentiel NASA-like.

- Chaque preuve **présente** renvoie vers un artefact versionné ou un document d’exécution.
- Chaque preuve **absente** est listée explicitement (**absence de preuve = non validé** jusqu’à comblement ou dérogation formelle `PH0-WVR-*` / équivalent programme).

---

## Phase 0 — Baseline qualité (`roadmap` étapes 5.1 à 5.4)

### Synthèse d’environnement (capture **2026-04-02**)

| Champ | Valeur |
|--------|--------|
| OS hôte principal | Windows **10+** (`win32`, `x64`) |
| Flutter | **3.38.3** (stable) |
| Dart | **3.10.1** (stable) |
| Version applicative (`pubspec.yaml`) | **1.0.2+5** |
| Git `HEAD` (baseline) | **f17921d9d8a12299b17cf02497f227decafa960e** |
| Branche de référence programme | `main` (cf. décision de gel phase 0) |

**Limite** : une autre machine ou une autre révision Git peut produire des résultats différents ; toute campagne ultérieure doit **ré-archiver** les sorties avec une **date** ou identifiant de campagne.

### Tableau des preuves — étape 5 (chemins relatifs à la racine du dépôt)

| ID | Sujet | Commande de référence | Document d’analyse | Artefact(s) brut(s) | Résultat constaté |
|----|--------|------------------------|---------------------|----------------------|-------------------|
| **PH0-BL-Q-501** | Analyse statique | `dart analyze .` | [`docs/Refactor/phase_0_baseline_inventaire_gel_photographie/07_baseline_analyse_statique.md`](../Refactor/phase_0_baseline_inventaire_gel_photographie/07_baseline_analyse_statique.md) | [`docs/Refactor/phase_0_baseline_inventaire_gel_photographie/artifacts/dart_analyze_2026-04-02.txt`](../Refactor/phase_0_baseline_inventaire_gel_photographie/artifacts/dart_analyze_2026-04-02.txt) | **0** issue |
| **PH0-BL-Q-502** | Tests automatisés | `flutter test` | [`docs/Refactor/phase_0_baseline_inventaire_gel_photographie/08_baseline_tests_automatises.md`](../Refactor/phase_0_baseline_inventaire_gel_photographie/08_baseline_tests_automatises.md) | [`docs/Refactor/phase_0_baseline_inventaire_gel_photographie/artifacts/flutter_test_R1_2026-04-02.txt`](../Refactor/phase_0_baseline_inventaire_gel_photographie/artifacts/flutter_test_R1_2026-04-02.txt) | **200** pass, **0** fail — gate tests **satisfaite** |
| **PH0-BL-Q-503** | Build Android | `flutter build apk --debug --flavor dev` | [`docs/Refactor/phase_0_baseline_inventaire_gel_photographie/09_baseline_build_packaging.md`](../Refactor/phase_0_baseline_inventaire_gel_photographie/09_baseline_build_packaging.md) §2.1 | [`docs/Refactor/phase_0_baseline_inventaire_gel_photographie/artifacts/flutter_build_android_dev_debug_2026-04-02.txt`](../Refactor/phase_0_baseline_inventaire_gel_photographie/artifacts/flutter_build_android_dev_debug_2026-04-02.txt) | **Succès** |
| **PH0-BL-Q-504** | Build Windows | `flutter build windows` | [`09_baseline_build_packaging.md`](../Refactor/phase_0_baseline_inventaire_gel_photographie/09_baseline_build_packaging.md) §2.2 | [`artifacts/flutter_build_windows_2026-04-02.txt`](../Refactor/phase_0_baseline_inventaire_gel_photographie/artifacts/flutter_build_windows_2026-04-02.txt) | **Succès** |
| **PH0-BL-Q-505** | Build iOS | `flutter build ios --release` (réf.) | [`09_baseline_build_packaging.md`](../Refactor/phase_0_baseline_inventaire_gel_photographie/09_baseline_build_packaging.md) §2.3 | [`docs/Refactor/phase_0_baseline_inventaire_gel_photographie/artifacts/flutter_build_ios_non_execute_2026-04-02.txt`](../Refactor/phase_0_baseline_inventaire_gel_photographie/artifacts/flutter_build_ios_non_execute_2026-04-02.txt) | **Non exécuté** sur l’hôte de capture (Windows) |

**Commandes regroupées** (reproduction) : voir aussi [`docs/Refactor/phase_0_baseline_inventaire_gel_photographie/artifacts/reproduce_commands_baseline_2026-04-02.txt`](../Refactor/phase_0_baseline_inventaire_gel_photographie/artifacts/reproduce_commands_baseline_2026-04-02.txt).

**Journal des lots** : entrées `LOG-2026-04-02-012` à `LOG-2026-04-02-015` (étape 5) et `LOG-2026-04-02-024` à `LOG-2026-04-02-026` (étapes 9.1–9.3) dans [`docs/traceability/change_logbook.md`](../traceability/change_logbook.md).

---

## Preuves absentes ou partielles (étape 5.4.2)

Alignement `rules_nasa.md` §25 / §27 : les lignes ci-dessous ne sont **pas** des dérogations ; elles nomment des **lacunes** et une orientation de comblement. Toute release ou merge sous discipline NASA exige de traiter ou de formaliser une **dérogation** selon §26.

| ID lacune | Preuve manquante ou insuffisante | Impact gate | Plan de comblement (indicatif) | Dérogation |
|-----------|-----------------------------------|-------------|--------------------------------|------------|
| **PH0-BL-GAP-001** | **CI / pipeline automatisé** (pas de `.github/workflows` versionné exécuté à chaque PR) | Analyse, tests, builds **non** attestés en continu sur l’infra de l’équipe | **Levée (R4)** : pipeline versionné via `codemagic.yaml` + workflow qualité `ci-quality-proof` + doc `docs/operations/ci/codemagic_pipeline_minimum.md` + preuves R4 (artefacts datés) | Aucun besoin |
| **PH0-BL-GAP-007** | installation (exigence pipeline §20.1) exécutée en CI | Analyse/tests/build CI non attestés de bout en bout | **Levée (R4)** : `flutter pub get` en CI + logs `ci_proofs/flutter_pub_get.log` (exportables) | Aucun besoin |
| **PH0-BL-GAP-008** | résolution contrôlée des dépendances (exigence §20.1) en CI | lockfile / résolution pas attestés en CI | **Levée (R4)** : `flutter pub get` en CI + logs ; rehearsal local `r4_local_quality_proof_2026-04-02.txt` | Aucun besoin |
| **PH0-BL-GAP-009** | analyse statique exécutée en CI (exigence §20.1) | `dart analyze` non attesté en CI | **Levée (R4)** : `flutter analyze` **bloquant** en CI + logs `ci_proofs/flutter_analyze.log` | Aucun besoin |
| **PH0-BL-GAP-010** | tests automatisés exécutés en CI (exigence §20.1) | `flutter test` non attesté en CI | **Levée (R4)** : `flutter test` en CI + logs `ci_proofs/flutter_test.log` | Aucun besoin |
| **PH0-BL-GAP-011** | build reproductible attesté en CI (exigence §20.1) | Builds CI non traçables/rejouables | **Levée (R4)** : workflow Android (`android-closed-test`) + workflows iOS (macOS) produisent artefacts build ; rehearsal local Android `r4_local_android_aab_proof_2026-04-02.txt` | Aucun besoin |
| **PH0-BL-GAP-012** | packaging traçable en CI (exigence §20.1) | release packaging non attesté | **Levée (R4)** : artefacts binaires (`*.aab` / `*.ipa` unsigned / `*.xcarchive`) + logs + checklist d’export `r4_codemagic_trigger_run_export_checklist_2026-04-02.txt` | Aucun besoin |
| **PH0-BL-GAP-002** | **Suite `flutter test` verte** | Gate §27 « tests automatisés en échec » : satisfaite après **R1** | Corrigée et re-archivée par `08_baseline_tests_automatises.md` (artefact `flutter_test_R1_2026-04-02.txt`) : **0** échec / **200** pass | Levée — R1 (tests verts) |
| **PH0-BL-GAP-003** | **Build iOS** archivé (log reproductible) | Pas de preuve de compilation pour la cible App Store sur l’hôte de référence | Exécuter sur **macOS** / CI macOS et ajouter l’artefact + entrée tableau | Aucune — constat d’environnement |
| **PH0-BL-GAP-004** | **`integration_test/`** absent à la racine | Pas de preuve E2E instrumentée standard | Ajouter scénarios critiques + job CI dédié si retenu par le produit | Aucune |
| **PH0-BL-GAP-005** | **AAB / APK release prod** avec même traçabilité que la baseline debug | Preuve release partielle (seul `dev` debug archivé en 5.3) | Lancer `flutter build appbundle --release --flavor prod` (ou équivalent) sur machine avec signing complet ; archiver log | Aucune — aligner avec politique release |
| **PH0-BL-GAP-006** | **Corpus incidents / postmortems** exploitables dans le dépôt | Traçabilité amélioration continue §24 affaiblie | Enrichir au fil des releases ou qualifier explicitement « vide » en phase 0 | Aucune |
| **PH0-BL-GAP-013** | Release taguée + associée à un changelog (NASA §20.1) | Traçabilité release ↔ preuve ↔ rollback impossible | Versionner tags de release + fournir `CHANGELOG.md` versionné ; associer chaque release à une entrée de preuves | Aucune |
| **PH0-BL-GAP-014** | Procédure de rollback opérationnelle versionnée | Gate NASA : “rollback défini” : traité en R3 (procédure + rehearsal) | **Levée (R3)** : stratégie rollback + runbooks Android/Windows/iOS + rehearsal (artefacts datés) | Aucun besoin |

---

## Réserve R4 — Pipeline CI/CD minimal “preuves” (re-basinage)

### Preuves R4 (CI/pipeline)

| ID | Sujet | Document / preuve | Résultat constaté |
|---|---|---|---|
| **PH0-R4-CI-001** | Pipeline versionné (Codemagic) + workflow qualité sans secrets | `codemagic.yaml` (workflow `ci-quality-proof`) + `docs/operations/ci/codemagic_pipeline_minimum.md` | Pipeline minimal qualité versionné + logs `ci_proofs/*` |
| **PH0-R4-CI-002** | Preuve qualité (rehearsal local) | `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/artifacts/r4_local_quality_proof_2026-04-02.txt` | `flutter pub get` + `flutter analyze` + `flutter test` : succès |
| **PH0-R4-CI-003** | Preuve build/packaging Android (AAB) (rehearsal local) | `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/artifacts/r4_local_android_aab_proof_2026-04-02.txt` | `flutter build appbundle --release` : succès + liste des artefacts produits |
| **PH0-R4-CI-004** | Triggers + export de preuves Codemagic (procédure) | `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/artifacts/r4_codemagic_trigger_run_export_checklist_2026-04-02.txt` | Procédure versionnée d’activation et d’archivage des preuves CI |

## Étape 9 — Zones sans preuve (observabilité / runbooks / secrets)

### Tableau des preuves — étape 9 (9.1–9.2)

| ID | Sujet | Document d’exécution / analyse | Résultat constaté |
|---|--------|--------------------------------|-------------------|
| **PH0-BL-ZNP-901** | Couverture flux critiques : tests / logs structurés / runbook | `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/15_flux_critiques_couverture_9_1.md` | Runbooks absents ; logs structurés minimaux (timestamp/level/category) ; baselines non “vert” sur 3 tests liés |
| **PH0-BL-ZNP-902** | Constat secrets et configuration (sans valeurs) | `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/16_constat_secrets_configuration_9_2.md` | Injection via `--dart-define` + `SecretStore` ; sanitization logs ; aucune anomalie critique détectée (constat uniquement) |

### Lacunes identifiées — étape 9.1 (observabilité / runbooks)

| ID lacune | Preuve manquante ou insuffisante | Impact gate | Plan de comblement (indicatif) | Dérogation |
|-----------|-----------------------------------|-------------|--------------------------------|------------|
| **PH0-BL-GAP-015** | Runbooks opérationnels (exploitation/détection/diagnostic) versionnés et liés aux flux critiques | Gate NASA : observabilité minimale absente et diagnostic non exploitable | **Levée (R2)** : `docs/operations/runbooks/RBK-000..RBK-108` + liens flux ; preuves archivée | Aucun besoin |
| **PH0-BL-GAP-016** | Corrélation opérationnelle “exploitables” non démontrée | Gate NASA : corrélation événements critiques insuffisante | **Levée (R2)** : `operationId` injecté dans logs (Zone) + test + artefacts | Aucun besoin |
| **PH0-BL-GAP-017** | Métriques de santé non démontrées comme preuve en baseline | Gate NASA : métriques minimales absentes | **Levée (R2)** : doc métriques minimum + preuve crash/error monitoring (Sentry) + plan alerting minimal | Aucun besoin |

### Lacunes déjà listées ailleurs (rappel)

- E2E : `PH0-BL-GAP-004` (absence `integration_test/` à la racine).
- Tests non “verts” baseline : `PH0-BL-GAP-002` (3 tests en échec).

---

## Réserve R2 — Observabilité & runbooks (re-basinage)

### Preuves R2 (runbooks / corrélation / métriques / Sentry)

| ID | Sujet | Document / preuve | Résultat constaté |
|---|---|---|---|
| **PH0-R2-OBS-001** | Runbooks flux critiques | `docs/operations/runbooks/RBK-000_incident_triage.md` + `docs/operations/runbooks/RBK-101..RBK-108` | Runbooks présents pour les 8 flux + triage commun |
| **PH0-R2-OBS-002** | Schéma logs corrélables | `docs/operations/observability/logging_schema.md` | Modèle minimal `operationId`/`feature`/`action`/`result` |
| **PH0-R2-OBS-003** | Preuve `operationId` (test) | `test/core/logging/operation_id_correlation_test.dart` + artefact `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/artifacts/r2_operationid_correlation_test_2026-04-02.txt` | Test vert ; `operationId` injecté automatiquement |
| **PH0-R2-OBS-004** | Métriques minimum & alerting | `docs/operations/observability/metrics_minimum.md` | Minimum NASA §14.1 documenté |
| **PH0-R2-OBS-005** | Sentry setup + preuve capture | `docs/operations/observability/sentry_setup.md` + test `test/core/observability/sentry_capture_test.dart` + artefact `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/artifacts/r2_sentry_capture_test_2026-04-02.txt` | Capture non-fatale démontrée (release/env/opId) sans réseau |

---

## Réserve R3 — Rollback opérationnel versionné (re-basinage)

### Preuves R3 (rollback)

| ID | Sujet | Document / preuve | Résultat constaté |
|---|---|---|---|
| **PH0-R3-RBK-001** | Stratégie rollback (centrale) | `docs/operations/rollback/rollback_strategy.md` | Stratégie définie (rollback vs hotfix, triggers, validation) |
| **PH0-R3-RBK-002** | Runbook Android Play rollback | `docs/operations/rollback/RBK-201_android_playstore_rollback.md` | Procédure opératoire Play + contraintes versionCode |
| **PH0-R3-RBK-003** | Runbook Windows rollback | `docs/operations/rollback/RBK-202_windows_rollback.md` | Procédure opératoire réinstall N-1 |
| **PH0-R3-RBK-004** | Runbook iOS rollback (contraint) | `docs/operations/rollback/RBK-203_ios_rollback.md` | Procédure réaliste App Store (stop rollout + hotfix) |
| **PH0-R3-RBK-005** | Rehearsal Android (artefact) | `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/artifacts/r3_rollback_rehearsal_android_playstore_2026-04-02.txt` | Checklist rehearsal versionnée |
| **PH0-R3-RBK-006** | Rehearsal Windows (artefact) | `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/artifacts/r3_rollback_rehearsal_windows_2026-04-02.txt` | Checklist rehearsal versionnée |
| **PH0-R3-RBK-007** | Rehearsal iOS (artefact) | `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/artifacts/r3_rollback_rehearsal_ios_2026-04-02.txt` | Rehearsal documentaire + plan CI/macOS |

---

## Évolutions futures

- Toute **nouvelle campagne** de baseline doit dupliquer la structure (nouvelle date dans les noms de fichiers ou nouvelle section datée dans ce document).
- Les entrées **Phase 1+** (autres gates, SBOM, scans sécurité) pourront être ajoutées en sections distinctes sous le même `QUAL-EVD-INDEX-001` ou un document fils, selon gouvernance du programme.

---

*Document produit dans le cadre de la roadmap phase 0 — étape **5.4**.*

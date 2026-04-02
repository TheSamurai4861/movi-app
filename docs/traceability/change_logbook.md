# Journal des changements structurels

## Statut du document

- **Document ID** : `TRACE-LOG-001`
- **Version** : `v1`
- **Date d'initialisation** : `2026-04-02`
- **Statut** : `actif`
- **Reference principale** : `docs/rules_nasa.md` (§6, §25, §26, §27)
- **Programme associe** : `docs/Refactor/movi_nasa_refactor_plan_v3.md`

## Objet

Ce journal assure la tracabilite minimale exigee par `docs/rules_nasa.md` pour les changements significatifs du programme de refactorisation Movi.

Pour chaque lot significatif, il doit permettre de retrouver au minimum :

- la source de besoin ;
- le composant ou document modifie ;
- la criticite ;
- les risques identifies ;
- les preuves de validation ;
- les decisions, derogations et rollback associes si applicables.

## Convention d'identifiants pour la phase 0

Format retenu :

- **Lots de phase** : `PH0-LOT-XXX`
- **Decisions** : `PH0-DEC-XXX`
- **Exceptions / derogations** : `PH0-WVR-XXX`
- **Evidences** : `PH0-EVD-XXX`

## Convention d'identifiants pour la phase 1

Format retenu (aligné même logique que phase 0) :

- **Lots de phase** : `PH1-LOT-XXX`
- **Decisions** : `PH1-DEC-XXX`
- **Exceptions / derogations** : `PH1-WVR-XXX`
- **Evidences** : `PH1-EVD-XXX`

### Registre initial des lots phase 1

| Lot ID | Source de besoin | Objet | Statut initial | Notes |
|--------|------------------|-------|----------------|-------|
| `PH1-LOT-001` | Phase 1 / travail obligatoire #1 | Registre de risques systeme sous controle | ouvert | `docs/risk/system_risk_register.md` + gate C1 (mitigation/containment/rollback/detectabilite) |
| `PH1-LOT-002` | Phase 1 / travail obligatoire #2 | Inventaire secrets/tokens/PII/donnees sensibles | ouvert | `docs/security/secret_inventory.md` |
| `PH1-LOT-003` | Phase 1 / travail obligatoire #3 | Matrice privileges / acces externes / dependances critiques | ouvert | `docs/security/privilege_matrix.md` |
| `PH1-LOT-004` | Phase 1 / travail obligatoire #4 | Failure modes par domaine (startup/auth/network/storage/player/IPTV/parental) | ouvert | `docs/risk/failure_modes.md` |
| `PH1-LOT-005` | Phase 1 / travail obligatoire #5 | Hazard analysis + etats sûrs (fail-safe / fail-closed) | ouvert | `docs/risk/hazard_analysis.md` |
| `PH1-LOT-006` | Phase 1 / travail obligatoire #6 | Kill switches / feature flags requis | ouvert | (sera relie au registre de risques + docs ops/runbooks) |

## Convention d'identifiants pour la phase 2

Format retenu :

- **Lots de phase** : `PH2-LOT-XXX`
- **Decisions** : `PH2-DEC-XXX`
- **Exceptions / derogations** : `PH2-WVR-XXX`
- **Evidences** : `PH2-EVD-XXX`

### Registre initial des lots phase 2

| Lot ID | Source de besoin | Objet | Statut initial | Notes |
|--------|------------------|-------|----------------|-------|
| `PH2-LOT-001` | Phase 2 / Jalon M1 | Règles d’import autorisées/interdites par couche + frontières feature + locator UI | ouvert | `docs/architecture/dependency_rules.md` ; prépare M2 (contrôles CI) |
| `PH2-LOT-002` | Phase 2 / Jalon M2 | Contrôle automatique imports interdits (local + CI) + rapport violations | ouvert | `tool/arch_lint.dart` + rapport baseline + step Codemagic |
| `PH2-LOT-003` | Phase 2 / Jalon M3 | Preuve canary (R1..R5) + mur anti-réintroduction (baseline) en CI | ouvert | fixtures `tool/arch_lint_canary` + mode `--baseline` + step CI canary |
| `PH2-LOT-004` | Phase 2 / Jalon M4 | Rapport initial des violations restantes (baseline) | ouvert | `docs/architecture/reports/phase2_violation_inventory_2026-04-02.md` + rapport brut `arch_violations_2026-04-02.md` |
| `PH2-LOT-005` | Phase 2 / Jalon M5 | Classement violations (criticité + coût) | ouvert | Section M5 dans `phase2_violation_inventory_2026-04-02.md` (backlog prêt à traiter) |

### Registre initial des lots phase 0

| Lot ID | Source de besoin | Objet | Statut initial | Notes |
|--------|------------------|-------|----------------|-------|
| `PH0-LOT-001` | roadmap etape `1.1` | Decision de gel, regles autorisees/interdites, roles minimaux | cloture | realise via `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/01_decision_de_gel_phase_0.md` |
| `PH0-LOT-002` | roadmap etape `1.2` | Initialisation du journal de changements et convention de tracabilite | cloture | present document |
| `PH0-LOT-003` | roadmap etape `1.3` | Qualification des entrees documentaires et des corpus incidents/anomalies | cloture | realise via `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/02_qualification_entrees_documentaires_phase_0.md` |
| `PH0-LOT-004` | roadmap etape `2` | Photographie structurelle du depot et `current_state.md` | cloture | etapes `2.1` a `2.3` : `current_state.md` complet + artefacts arbre |
| `PH0-LOT-005` | roadmap etape `3` | Inventaire des dependances internes et externes | cloture | `3.1`-`3.3` : docs `03`-`05` + artefacts pub_deps, native_tooling_snapshot |
| `PH0-LOT-006` | roadmap etape `4` | Matrice plateformes / environnements supportes | cloture | `4.1`+`4.2` : doc `06` + artefacts `flutter_android_defaults`, `reproduce_commands` |
| `PH0-LOT-007` | roadmap etape `5` | Baseline analyse statique / tests / build / packaging | cloture | etapes `5.1`-`5.4` : docs `07`-`09` + `docs/quality/validation_evidence_index.md` + artefacts |
| `PH0-LOT-008` | roadmap etape `6` | Cartographie initiale `C/L` par domaine | cloture | 6.1–6.3 : doc criticité C/L + granularisation + alignement P0/P1 |
| `PH0-LOT-009` | roadmap etape `7` | Inventaire CI/CD, release et rollback existants | cloture | inventaire 7.1, écart 7.2, constat 7.3 |
| `PH0-LOT-010` | roadmap etape `8` | Liste initiale des violations d'architecture | cloture | 8.1–8.2 : regles cibles + liste brute de violations
| `PH0-LOT-011` | roadmap etape `9` | Liste des zones sans preuve | cloture | absence de preuve = non valide |
| `PH0-LOT-012` | roadmap etape `10` | Revue de fin de phase et verdict | cloture | gate de sortie phase 0 |

## Regles d'usage

- Chaque nouveau lot significatif de phase 0 doit etre rattache a un identifiant du registre ci-dessus ou a un nouvel identifiant ajoute avant execution.
- Tout changement hors registre est presume non conforme jusqu'a qualification.
- Toute reduction de controle standard doit produire une entree `PH0-WVR-XXX` avant merge ou release.
- Toute evidence importante doit etre referencee depuis ce journal ou depuis `docs/quality/validation_evidence_index.md`.

## Entrees du journal

## Entree `LOG-2026-04-02-034`

- **Date** : `2026-04-02`
- **Lot ID** : `PH1-LOT-001`
- **Type** : phase 1 — registre de risques systeme
- **Source de besoin** : plan Phase 1 (Qualification sécurité/données/risques) + `docs/rules_nasa.md` §8 + §27
- **Composants produits / modifies** :
  - `docs/risk/system_risk_register.md`
- **Criticite du changement** : `C2` (cadre de controle)
- **Classe principale** : `L2` (mais traite des risques `C1/L1`)
- **Decision / resultat** :
  - registre normalise (schema + table) ;
  - couverture explicite des domaines Phase 1 (startup/auth/network/storage/player/IPTV/parental) ;
  - checklist C1 et liste initiale de kill switches/flags (a qualifier).
- **Risques identifies** :
  - presence de risques `C1/L1` a qualifier dans les lots `PH1-LOT-004/005/006`.
- **Rollback / mitigation** :
  - documents additifs ; rollback = revert ; usage = no evidence, no merge.
- **Preuves / validation** :
  - `docs/quality/validation_evidence_index.md` : `PH1-EVD-001`.
- **Derogation** : aucune.
- **Statut** : ouvert (Phase 1 en cours).

## Entree `LOG-2026-04-02-035`

- **Date** : `2026-04-02`
- **Lot ID** : `PH1-LOT-002`
- **Type** : phase 1 — secrets / PII / threat model
- **Source de besoin** : `docs/rules_nasa.md` §12–§13 + criteres d'arret Phase 1
- **Composants produits / modifies** :
  - `docs/security/secret_inventory.md`
  - `docs/security/threat_model.md`
  - `.env` (constat : fichier present avec valeurs)
- **Criticite du changement** : `C1`
- **Classe principale** : `L1`
- **Decision / resultat** :
  - inventaire secrets/PII sans valeurs versionne ;
  - menace "secret en clair" identifiee (decision immediate requise).
- **Risques identifies** :
  - fuite potentielle via `.env` versionne.
- **Rollback / mitigation** :
  - retrait du fichier versionne + rotation si compromis + injection via mecanisme approuve.
- **Preuves / validation** :
  - `docs/quality/validation_evidence_index.md` : `PH1-EVD-002` et `PH1-EVD-006`.
- **Derogation** : aucune (si acceptation necessaire, produire `PH1-WVR-XXX`).
- **Statut** : ouvert (decision immediate requise).

## Entree `LOG-2026-04-02-036`

- **Date** : `2026-04-02`
- **Lot ID** : `PH1-LOT-003`
- **Type** : phase 1 — privileges / dependances critiques
- **Source de besoin** : `docs/rules_nasa.md` §12 + moindre privilege
- **Composants produits / modifies** :
  - `docs/security/privilege_matrix.md`
- **Criticite du changement** : `C2`
- **Classe principale** : `L2`
- **Decision / resultat** :
  - dependances critiques listées (Supabase, TMDB, Sentry, proxy) ;
  - modes degradés attendus definis a niveau minimum.
- **Preuves / validation** :
  - `docs/quality/validation_evidence_index.md` : `PH1-EVD-003`.
- **Derogation** : aucune.
- **Statut** : ouvert.

## Entree `LOG-2026-04-02-037`

- **Date** : `2026-04-02`
- **Lot ID** : `PH1-LOT-004`
- **Type** : phase 1 — failure modes
- **Source de besoin** : plan Phase 1 / travail obligatoire #4 + `docs/rules_nasa.md` §11 + §21
- **Composants produits / modifies** :
  - `docs/risk/failure_modes.md`
- **Criticite du changement** : `C2`
- **Classe principale** : `L2` (inclut cas `L1`)
- **Decision / resultat** :
  - modes d’echec documentes par domaine + detectabilite + containment/rollback minimum.
- **Preuves / validation** :
  - `docs/quality/validation_evidence_index.md` : `PH1-EVD-004`.
- **Derogation** : aucune.
- **Statut** : ouvert.

## Entree `LOG-2026-04-02-038`

- **Date** : `2026-04-02`
- **Lot ID** : `PH1-LOT-005`
- **Type** : phase 1 — hazard analysis / etats sûrs
- **Source de besoin** : plan Phase 1 / travail obligatoire #5 + `docs/rules_nasa.md` §8–§9
- **Composants produits / modifies** :
  - `docs/risk/hazard_analysis.md`
- **Criticite du changement** : `C1`
- **Classe principale** : `L1`
- **Decision / resultat** :
  - hazards conservatoires identifies ;
  - etats sûrs attendus definis (L1 fail-closed).
- **Preuves / validation** :
  - `docs/quality/validation_evidence_index.md` : `PH1-EVD-005`.
- **Derogation** : aucune.
- **Statut** : ouvert.

## Entree `LOG-2026-04-02-039`

- **Date** : `2026-04-02`
- **Lot ID** : `PH2-LOT-001`
- **Type** : phase 2 — règles d’import / mur de dépendances (Jalon M1)
- **Source de besoin** : `movi_nasa_refactor_plan_v3.md` Phase 2 (travaux obligatoires #1) + `docs/rules_nasa.md` §5 + §27
- **Composants produits / modifies** :
  - `docs/architecture/dependency_rules.md`
  - `docs/quality/validation_evidence_index.md`
  - `docs/traceability/change_logbook.md`
- **Criticite du changement** : `C2`
- **Classe principale** : `L2`
- **Decision / resultat** :
  - règles testables `ARCH-R1..R5` définies (4 familles + locator UI) ;
  - conventions de couches et frontières features documentées ;
  - préparation de l’automatisation (M2) : output attendu (ID règle, rapport, exit code non-zero).
- **Risques identifies** :
  - règles trop vagues/non discriminantes => stop avant M2 et renforcement conventions (naming/paths).
- **Rollback / mitigation** :
  - documents additifs ; rollback = revert.
- **Preuves / validation** :
  - `docs/quality/validation_evidence_index.md` : `PH2-EVD-001`.
- **Derogation** : aucune.
- **Statut** : ouvert (Phase 2 en cours).

## Entree `LOG-2026-04-02-040`

- **Date** : `2026-04-02`
- **Lot ID** : `PH2-LOT-002`
- **Type** : phase 2 — contrôle automatique des imports interdits (Jalon M2)
- **Source de besoin** : Phase 2 (travaux obligatoires #2–#4) + `docs/rules_nasa.md` §17 + §27
- **Composants produits / modifies** :
  - `tool/arch_lint.dart`
  - `docs/architecture/dependency_rules.md` (section exécution locale)
  - `docs/architecture/reports/arch_violations_baseline.md`
  - `codemagic.yaml` (step architecture wall dans `ci-quality-proof`)
  - `docs/quality/validation_evidence_index.md`
  - `docs/traceability/change_logbook.md`
- **Criticite du changement** : `C2`
- **Classe principale** : `L2`
- **Decision / resultat** :
  - script local `arch_lint` : scanne `lib/`, applique `ARCH-R1..R5`, génère rapport et échoue si violation ;
  - preuve minimale via `--canary` (self-check) ;
  - intégration CI : étape bloquante + archivage logs/rapport.
- **Risques identifies** :
  - forte dette existante (nombreuses violations) : la gate sert de **mur anti-réintroduction**, pas de “cleanup” immédiat.
- **Rollback / mitigation** :
  - documents/outillage additifs ; rollback = revert ; possibilité d’ajuster allow/denylist si faux positifs.
- **Preuves / validation** :
  - `docs/quality/validation_evidence_index.md` : `PH2-EVD-002`.
- **Derogation** : aucune.
- **Statut** : ouvert (Phase 2 en cours).

## Entree `LOG-2026-04-02-041`

- **Date** : `2026-04-02`
- **Lot ID** : `PH2-LOT-003`
- **Type** : phase 2 — interdictions CI explicites + canary (Jalon M3)
- **Source de besoin** : Phase 2 (travaux obligatoires #3–#4) + `docs/rules_nasa.md` §27
- **Composants produits / modifies** :
  - `tool/arch_lint_canary/**` (fixtures)
  - `tool/arch_lint.dart` (modes `--canary-fixtures`, `--expect-all-rules`, `--baseline`)
  - `docs/architecture/reports/arch_canary_report.md`
  - `codemagic.yaml` (step canary + mur baseline)
  - `docs/quality/validation_evidence_index.md`
  - `docs/traceability/change_logbook.md`
- **Criticite du changement** : `C2`
- **Classe principale** : `L2`
- **Decision / resultat** :
  - preuve canary : les règles `ARCH-R1..R5` déclenchent chacune sur des fixtures minimales ;
  - politique mur : CI échoue uniquement sur **nouvelles** violations vs baseline (anti-réintroduction) ;
  - artefacts CI : rapport delta + rapport canary archivés.
- **Risques identifies** :
  - si la baseline n’est pas tenue à jour lors des refactors, risque de faux positifs sur “nouveaux” écarts.
- **Rollback / mitigation** :
  - ajuster fingerprints si besoin ; sinon rollback = revert.
- **Preuves / validation** :
  - `docs/quality/validation_evidence_index.md` : `PH2-EVD-003`.
- **Derogation** : aucune.
- **Statut** : ouvert (Phase 2 en cours).

## Entree `LOG-2026-04-02-042`

- **Date** : `2026-04-02`
- **Lot ID** : `PH2-LOT-004`
- **Type** : phase 2 — rapport initial violations restantes (Jalon M4)
- **Source de besoin** : Phase 2 (travaux obligatoires #5) + critères d’arrêt (mesure graphe) + `docs/rules_nasa.md` §25/§27
- **Composants produits / modifies** :
  - `docs/architecture/reports/arch_violations_2026-04-02.md` (rapport brut daté)
  - `docs/architecture/reports/phase2_violation_inventory_2026-04-02.md` (rapport opposable + mapping V1–V4)
  - `docs/quality/validation_evidence_index.md`
  - `docs/traceability/change_logbook.md`
- **Criticite du changement** : `C2`
- **Classe principale** : `L2`
- **Decision / resultat** :
  - baseline violations produite, datée et archivée ;
  - mapping familles Phase 0 (V1–V4) vers règles Phase 2 (ARCH-R*) documenté ;
  - rapport comparable dans le temps (daté, reproductible via commande).
- **Rollback / mitigation** :
  - documents additifs ; rollback = revert.
- **Preuves / validation** :
  - `docs/quality/validation_evidence_index.md` : `PH2-EVD-004`.
- **Derogation** : aucune.
- **Statut** : ouvert (Phase 2 en cours).

## Entree `LOG-2026-04-02-043`

- **Date** : `2026-04-02`
- **Lot ID** : `PH2-LOT-005`
- **Type** : phase 2 — classement violations (criticité + coût) (Jalon M5)
- **Source de besoin** : Phase 2 (travaux obligatoires #6) + `docs/rules_nasa.md` §25/§27
- **Composants produits / modifies** :
  - `docs/architecture/reports/phase2_violation_inventory_2026-04-02.md` (section \"Priorisation (M5)\")
  - `docs/quality/validation_evidence_index.md`
  - `docs/traceability/change_logbook.md`
- **Criticite du changement** : `C2`
- **Classe principale** : `L2` (inclut identification explicite des zones `L1`)
- **Decision / resultat** :
  - backlog priorisé produit : `C/L` + coût `S/M/L` + dépendances ;
  - violations touchant zones `L1` identifiées et promues.
- **Rollback / mitigation** :
  - document additif ; rollback = revert ; révision possible à mesure que le refactor progresse.
- **Preuves / validation** :
  - `docs/quality/validation_evidence_index.md` : `PH2-EVD-005`.
- **Derogation** : aucune.
- **Statut** : ouvert (Phase 2 en cours).

## Entree `LOG-2026-04-02-001`

- **Date** : `2026-04-02`
- **Lot ID** : `PH0-LOT-001`
- **Type** : decision structurante / gouvernance
- **Source de besoin** : `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/roadmap.md` etape `1.1`
- **Composants modifies** :
  - `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/01_decision_de_gel_phase_0.md`
  - `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/roadmap.md`
- **Criticite du changement** : `C3`
- **Classe principale** : `L3`
- **Decision / resultat** :
  - branche principale du programme fixee a `main` ;
  - gel de phase 0 active ;
  - merges limites, releases standard suspendues ;
  - changements autorises / interdits formalises ;
  - roles minimaux nommes par responsabilite.
- **Risques identifies** :
  - depot deja modifie au moment de l'initialisation ;
  - confusion possible entre baseline documentaire et validation reelle du depot ;
  - independance de revue potentiellement insuffisante si une seule personne cumule les roles.
- **Rollback / mitigation** :
  - document de decision reversible par une nouvelle decision explicite ;
  - aucun impact runtime direct ;
  - si contradiction detectee, emettre une decision corrective et tracer l'ecart.
- **Preuves / validation** :
  - coherence verifiee avec `docs/rules_nasa.md` ;
  - reference explicite ajoutee dans la roadmap phase 0.
- **Derogation** : aucune a ce stade
- **Statut** : cloture

## Entree `LOG-2026-04-02-002`

- **Date** : `2026-04-02`
- **Lot ID** : `PH0-LOT-002`
- **Type** : tracabilite documentaire
- **Source de besoin** : `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/roadmap.md` etape `1.2`
- **Composants modifies** :
  - `docs/traceability/change_logbook.md`
- **Criticite du changement** : `C3`
- **Classe principale** : `L3`
- **Decision / resultat** :
  - creation du journal de changements structurels ;
  - definition d'une convention d'identifiants pour la phase 0 ;
  - enregistrement initial des lots `PH0-LOT-001` a `PH0-LOT-012`.
- **Risques identifies** :
  - identifiants non utilises de facon consistente dans les etapes suivantes ;
  - lots futurs executes sans mise a jour du journal ;
  - confusion entre statut documentaire et statut de preuve technique.
- **Rollback / mitigation** :
  - convention modifiable par nouvelle entree de journal ;
  - tout ecart constate doit etre regularise avant cloture de phase.
- **Preuves / validation** :
  - alignement avec `docs/rules_nasa.md` §6.1 et §25 ;
  - registre initial des lots present dans ce document.
- **Derogation** : aucune a ce stade
- **Statut** : cloture

## Entree `LOG-2026-04-02-003`

- **Date** : `2026-04-02`
- **Lot ID** : `PH0-LOT-003`
- **Type** : qualification documentaire / lacunes de preuve
- **Source de besoin** : `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/roadmap.md` etape `1.3`
- **Composants modifies** :
  - `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/02_qualification_entrees_documentaires_phase_0.md`
  - `docs/traceability/change_logbook.md`
- **Criticite du changement** : `C3`
- **Classe principale** : `L3`
- **Decision / resultat** :
  - qualification des sources documentaires actives, temporaires et archivees ;
  - constat explicite d'absence de corpus incidents / anomalies / postmortem exploitable dans le depot ;
  - identification des lacunes documentaires visibles, dont l'absence de `README.md` et `CHANGELOG.md` a la racine.
- **Risques identifies** :
  - absence de preuve historique sur incidents et anomalies ;
  - confusion possible entre archives historiques et documentation active ;
  - couverture documentaire de racine insuffisante pour l'onboarding et la traçabilite release.
- **Rollback / mitigation** :
  - document purement documentaire, reversible par une nouvelle qualification ;
  - toute source externe retrouvee devra etre rattachee a ce lot ou a un lot derive ;
  - les archives ne sont pas considerees actives sans requalification explicite.
- **Preuves / validation** :
  - inventaire `docs/**/*.md` consulte ;
  - verification negative de `README.md` et `CHANGELOG.md` a la racine ;
  - recherches documentaires cibles sur incidents / anomalies / postmortems.
- **Derogation** : aucune a ce stade
- **Statut** : cloture

## Entree `LOG-2026-04-02-004`

- **Date** : `2026-04-02`
- **Lot ID** : `PH0-LOT-004` (sous-etape `2.1` uniquement)
- **Type** : baseline structurelle / photographie arborescence
- **Source de besoin** : `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/roadmap.md` etape `2.1`
- **Composants modifies / produits** :
  - `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/artifacts/repo_tree_2026-04-02.txt`
  - `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/artifacts/generate_repo_tree.ps1`
  - `docs/architecture/current_state.md`
  - `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/roadmap.md`
  - `docs/traceability/change_logbook.md`
- **Criticite du changement** : `C3`
- **Classe principale** : `L3`
- **Decision / resultat** :
  - liste des fichiers pertinents exportee avec exclusions documentees ;
  - script de reproduction archive ;
  - `current_state.md` cree avec reference aux artefacts et exclusions.
- **Risques identifies** :
  - `output/` exclu par defaut : risque de sous-estimer une source de verite si mal classe ;
  - liste volumineuse : derive possible si non regeneree avant cloture de phase ;
  - absence de `integration_test/` a la racine : couverture E2E non visible dans cet artefact.
- **Rollback / mitigation** :
  - artefacts remplacables par regeneration ;
  - ajuster le script et le tableau des exclusions si le perimetre change.
- **Preuves / validation** :
  - execution reussie de `generate_repo_tree.ps1` ;
  - coherence avec la roadmap et `docs/rules_nasa.md` §25.
- **Derogation** : aucune a ce stade
- **Statut** : cloture (pour la sous-etape `2.1` seule ; le lot `PH0-LOT-004` reste `en_cours`)

## Entree `LOG-2026-04-02-005`

- **Date** : `2026-04-02`
- **Lot ID** : `PH0-LOT-004` (sous-etape `2.2` uniquement)
- **Type** : cartographie modules / photographie structurelle
- **Source de besoin** : `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/roadmap.md` etape `2.2`
- **Composants modifies** :
  - `docs/architecture/current_state.md`
  - `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/roadmap.md`
  - `docs/traceability/change_logbook.md`
- **Criticite du changement** : `C3`
- **Classe principale** : `L3`
- **Decision / resultat** :
  - cartographie `lib/` : `l10n`, `core`, `features` avec liste des features ;
  - frontieres reelles : auth core vs features, couplage orchestrateur -> features, DI GetIt + Riverpod ;
  - points d'entree et chaine demarrage documentes ;
  - tableau des fichiers volumineux pour phase 6.
- **Risques identifies** :
  - analyse basee sur structure et echantillons de code, pas sur un graphe d'imports automatise ;
  - volumetrie l10n peut masquer d'autres hotspots dans les metriques globales.
- **Rollback / mitigation** :
  - mise a jour incrementale de `current_state.md` si la structure evolue ;
  - completer par un rapport d'imports en phase 2 ou 8 si requis.
- **Preuves / validation** :
  - lecture de `main.dart`, `app.dart`, `app_startup_gate.dart`, `app_router.dart`, `app_launch_orchestrator.dart` (debut) ;
  - comptage de lignes sur les plus gros `.dart` sous `lib/`.
- **Derogation** : aucune a ce stade
- **Statut** : cloture (sous-etape `2.2` ; lot `PH0-LOT-004` complete lors de `LOG-2026-04-02-006`)

## Entree `LOG-2026-04-02-006`

- **Date** : `2026-04-02`
- **Lot ID** : `PH0-LOT-004` (sous-etape `2.3` ; cloture lot `2`)
- **Type** : redaction synthese / hypotheses et limites baseline
- **Source de besoin** : `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/roadmap.md` etape `2.3`
- **Composants modifies** :
  - `docs/architecture/current_state.md`
  - `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/roadmap.md`
  - `docs/traceability/change_logbook.md`
- **Criticite du changement** : `C3`
- **Classe principale** : `L3`
- **Decision / resultat** :
  - synthese et index des artefacts bruts en section 1 ;
  - section `Hypotheses et limites de la baseline` alignee plan v3 §1.4 et `rules_nasa.md` ;
  - cloture de l'etape 2 roadmap phase 0 pour le volet `current_state.md`.
- **Risques identifies** :
  - le document peut diverger du code si non maintenu ;
  - les lacunes de preuve listees restent ouvertes jusqu'aux etapes suivantes.
- **Rollback / mitigation** :
  - versions ulterieures par commits / entrees de journal ;
  - regeneration `repo_tree_*.txt` pour nouvelle baseline.
- **Preuves / validation** :
  - conformite aux intitules roadmap 2.3.1 et 2.3.2 ;
  - liens relatifs verifies vers artefacts phase 0.
- **Derogation** : aucune a ce stade
- **Statut** : cloture (lot `PH0-LOT-004`)

## Entree `LOG-2026-04-02-007`

- **Date** : `2026-04-02`
- **Lot ID** : `PH0-LOT-005` (sous-etape `3.1`)
- **Type** : inventaire dependances Dart / Flutter
- **Source de besoin** : `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/roadmap.md` etape `3.1`
- **Composants produits / modifies** :
  - `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/03_inventaire_dependances_dart_flutter.md`
  - `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/artifacts/pub_deps_2026-04-02.txt`
  - `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/roadmap.md`
  - `docs/traceability/change_logbook.md`
- **Criticite du changement** : `C3`
- **Classe principale** : `L3`
- **Decision / resultat** :
  - synthese directes / transitives ;
  - table des directes avec usage, L presumes, licences indicatives ;
  - strategie caret + lockfile vs cible NASA §18 documentee.
- **Risques identifies** :
  - licences non verifiees une par une sur pub.dev ;
  - SDK machine de capture peuvent differer d'autres environnements ;
  - L presumes non substituts a `component_criticality.md`.
- **Rollback / mitigation** :
  - regenerer `pub_deps_*.txt` apres `pub get` ;
  - completer politique dependances en phase ulterieure.
- **Preuves / validation** :
  - `pubspec.yaml`, `pubspec.lock`, `dart pub deps --style=list` executes avec succes.
- **Derogation** : aucune a ce stade
- **Statut** : cloture (sous-etape `3.1` ; lot complete lors de `LOG-2026-04-02-009`)

## Entree `LOG-2026-04-02-008`

- **Date** : `2026-04-02`
- **Lot ID** : `PH0-LOT-005` (sous-etape `3.2`)
- **Type** : inventaire natif / tooling
- **Source de besoin** : `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/roadmap.md` etape `3.2`
- **Composants produits / modifies** :
  - `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/04_inventaire_dependances_natives_tooling.md`
  - `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/artifacts/native_tooling_snapshot_2026-04-02.txt`
  - `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/roadmap.md`
  - `docs/traceability/change_logbook.md`
  - `docs/architecture/current_state.md`
- **Criticite du changement** : `C3`
- **Classe principale** : `L3`
- **Decision / resultat** :
  - Gradle 8.12, AGP 8.9.1, Kotlin 2.1.0, Java 11 cible app documentes ;
  - iOS sans Podfile versionne, cible iOS 13 / Swift 5 ;
  - Windows CMake 3.14+ ;
  - versions Flutter / Dart / JDK / CMake sur machine de capture archivees.
- **Risques identifies** :
  - absence Podfile.lock : derive iOS ;
  - local.properties specifique machine ;
  - presence possible de secrets dans gradle.properties (audit securite recommande, non reproduits dans les artefacts).
- **Rollback / mitigation** :
  - regenerer snapshot apres changement toolchain ;
  - ne pas versionner secrets ; migrer vers env / magasin securise.
- **Preuves / validation** :
  - lecture des manifests android/ios/windows ;
  - commandes `flutter --version`, `dart --version`, `java -version`, `cmake --version`.
- **Derogation** : aucune a ce stade
- **Statut** : cloture (sous-etape `3.2` ; lot complete lors de `LOG-2026-04-02-009`)

## Entree `LOG-2026-04-02-009`

- **Date** : `2026-04-02`
- **Lot ID** : `PH0-LOT-005` (sous-etape `3.3` ; cloture lot etape `3`)
- **Type** : inventaire processus / scripts / analyse statique
- **Source de besoin** : `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/roadmap.md` etape `3.3`
- **Composants produits / modifies** :
  - `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/05_inventaire_dependances_processus.md`
  - `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/roadmap.md` (renumerotation `3.3.1`)
  - `docs/traceability/change_logbook.md`
  - `docs/architecture/current_state.md`
- **Criticite du changement** : `C3`
- **Classe principale** : `L3`
- **Decision / resultat** :
  - inventaire `tool/` et `scripts/` avec role dans la chaine de preuve ;
  - absence Makefile racine et absence `.github/` constatee ;
  - `analysis_options.yaml` qualifie ;
  - cloture `PH0-LOT-005`.
- **Risques identifies** :
  - pas de CI versionnee dans le depot a la baseline ;
  - scripts Python sans version Python figee ;
  - dependance `rg` pour hardcoded_strings_pass.ps1.
- **Rollback / mitigation** :
  - mettre a jour le doc 05 si de nouveaux scripts apparaissent ;
  - ajouter CI et reference dans ce document ou `validation_evidence_index.md`.
- **Preuves / validation** :
  - inventaire fichiers par glob + lecture d'en-tetes de scripts.
- **Derogation** : aucune a ce stade
- **Statut** : cloture (lot `PH0-LOT-005`)

## Entree `LOG-2026-04-02-010`

- **Date** : `2026-04-02`
- **Lot ID** : `PH0-LOT-006` (sous-etape `4.1`)
- **Type** : matrice plateformes / environnements
- **Source de besoin** : `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/roadmap.md` etape `4.1`
- **Composants produits / modifies** :
  - `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/06_matrice_plateformes_et_environnements.md`
  - `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/artifacts/flutter_android_defaults_2026-04-02.txt`
  - `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/roadmap.md`
  - `docs/traceability/change_logbook.md`
  - `docs/architecture/current_state.md`
- **Criticite du changement** : `C3`
- **Classe principale** : `L3`
- **Decision / resultat** :
  - matrice Android / iOS / Windows / absences web-linux-macos ;
  - TV qualifie comme partiel ;
  - flavors dev/stage/prod et lacunes CI / preuves test documentees ;
  - defaults API Android references depuis FlutterExtension SDK.
- **Risques identifies** :
  - defaults Flutter evoluent avec le SDK ;
  - absence de preuve test sur devices pour chaque plateforme.
- **Rollback / mitigation** :
  - mettre a jour doc 06 et artefact apres upgrade Flutter ou nouvelles plateformes.
- **Preuves / validation** :
  - lecture depots android/ios/windows, build.gradle.kts, Info.plist, FlutterExtension.kt du SDK installe.
- **Derogation** : aucune a ce stade
- **Statut** : cloture (sous-etape `4.1` ; lot complete lors de `LOG-2026-04-02-011`)

## Entree `LOG-2026-04-02-011`

- **Date** : `2026-04-02`
- **Lot ID** : `PH0-LOT-006` (sous-etape `4.2` ; cloture lot etape `4`)
- **Type** : matrice de reproduction / commandes qualite
- **Source de besoin** : `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/roadmap.md` etape `4.2`
- **Composants produits / modifies** :
  - `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/06_matrice_plateformes_et_environnements.md`
  - `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/artifacts/reproduce_commands_baseline_2026-04-02.txt`
  - `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/roadmap.md`
  - `docs/traceability/change_logbook.md`
  - `docs/architecture/current_state.md`
- **Criticite du changement** : `C3`
- **Classe principale** : `L3`
- **Decision / resultat** :
  - commandes documentees : pub get, analyze, format, test, build Android/Windows/iOS ;
  - tableau ecarts local vs CI ;
  - constat ponctuel : analyze vert, 3 tests en echec sur suite complete (dette preuve jusqu'etape 5).
- **Risques identifies** :
  - sans CI, pas de gate automatise ;
  - tests rouges bloqueraient une release NASA sans derogation.
- **Rollback / mitigation** :
  - mettre a jour doc 06 et artefact si commandes changent ;
  - corriger tests ou documenter waiver.
- **Preuves / validation** :
  - `flutter analyze` execute avec succes ;
  - `flutter test` execute (echecs partiels constates).
- **Derogation** : aucune a ce stade
- **Statut** : cloture (lot `PH0-LOT-006`)

## Entree `LOG-2026-04-02-012`

- **Date** : `2026-04-02`
- **Lot ID** : `PH0-LOT-007` (sous-etape `5.1`)
- **Type** : baseline qualite / analyse statique
- **Source de besoin** : `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/roadmap.md` etape `5.1`
- **Composants produits / modifies** :
  - `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/07_baseline_analyse_statique.md`
  - `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/artifacts/dart_analyze_2026-04-02.txt`
  - `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/roadmap.md`
  - `docs/traceability/change_logbook.md`
  - `docs/architecture/current_state.md`
- **Criticite du changement** : `C3`
- **Classe principale** : `L3`
- **Decision / resultat** :
  - `dart analyze .` execute avec succes : **0** issue (erreur / warning / info) ;
  - exclusions `analysis_options.yaml` et suppressions `ignore` inventoriees ;
  - ecart NASA §17 : analyse statique **non** executee en CI sur chaque PR (dette deja signalee etape 4).
- **Risques identifies** :
  - resultat local sans workflow : derive possible non detectee avant merge ;
  - suppressions inline masquent des smells sans revue systematique.
- **Rollback / mitigation** :
  - reexecuter `dart analyze .` et archiver un nouvel artefact date apres changement SDK ou YAML ;
  - etape `5.4` : consolider dans `validation_evidence_index.md`.
- **Preuves / validation** :
  - artefact `dart_analyze_2026-04-02.txt` ;
  - doc `07_baseline_analyse_statique.md`.
- **Derogation** : aucune formelle (`PH0-WVR-*`) pour les exclusions standard `build/` / `.dart_tool/` / `docs/` / `output/`.
- **Statut** : cloture sous-etape `5.1`.

## Entree `LOG-2026-04-02-013`

- **Date** : `2026-04-02`
- **Lot ID** : `PH0-LOT-007` (sous-etape `5.2`)
- **Type** : baseline qualite / tests automatises
- **Source de besoin** : `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/roadmap.md` etape `5.2`
- **Composants produits / modifies** :
  - `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/08_baseline_tests_automatises.md`
  - `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/artifacts/flutter_test_2026-04-02.txt`
  - `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/roadmap.md`
  - `docs/traceability/change_logbook.md`
  - `docs/architecture/current_state.md`
- **Criticite du changement** : `C2` (non-conformite gate tests)
- **Classe principale** : `L2` (couverture transverse tests)
- **Decision / resultat** :
  - `flutter test` : **197** reussis, **3** echecs (movie playback provider, movie detail playback, settings subtitles sync) ;
  - 61 fichiers `*_test.dart` sous `test/` ; pas d'`integration_test/` a la racine ;
  - cartographie qualitative domaines : zones sans preuve nommees (auth, category_browser, search, shell, etc.).
- **Risques identifies** :
  - release ou merge NASA **bloques** tant que la suite n'est pas verte ou derogation ;
  - ecarts fonctionnels reels possibles (regressions playback / sous-titres).
- **Rollback / mitigation** :
  - corriger les 3 tests ou le code sous-jacent puis re-archiver `flutter_test_YYYY-MM-DD.txt` ;
  - etape `5.4` : entree dans `validation_evidence_index.md`.
- **Preuves / validation** :
  - artefact `flutter_test_2026-04-02.txt` ;
  - doc `08_baseline_tests_automatises.md`.
- **Derogation** : aucune (`PH0-WVR-*`) pour les echecs constates — dette explicite.
- **Statut** : cloture sous-etape `5.2` ; lot `PH0-LOT-007` ouvert jusqu'a `5.3`-`5.4`.

## Entree `LOG-2026-04-02-014`

- **Date** : `2026-04-02`
- **Lot ID** : `PH0-LOT-007` (sous-etape `5.3`)
- **Type** : baseline qualite / build / packaging
- **Source de besoin** : `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/roadmap.md` etape `5.3`
- **Composants produits / modifies** :
  - `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/09_baseline_build_packaging.md`
  - `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/artifacts/flutter_build_android_dev_debug_2026-04-02.txt`
  - `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/artifacts/flutter_build_windows_2026-04-02.txt`
  - `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/artifacts/flutter_build_ios_non_execute_2026-04-02.txt`
  - `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/roadmap.md`
  - `docs/traceability/change_logbook.md`
  - `docs/architecture/current_state.md`
- **Criticite du changement** : `C2`
- **Classe principale** : `L2`
- **Decision / resultat** :
  - `flutter build apk --debug --flavor dev` : succes (APK `app-dev-debug.apk`) ;
  - `flutter build windows` : succes (`movi.exe` Release) ;
  - iOS : non execute sur hote Windows ; artefact constat separe ;
  - version `pubspec` **1.0.2+5**, HEAD **f17921d9d8a12299b17cf02497f227decafa960e** ;
  - packaging/signing decrit par references (`PLAY_CONSOLE_CHECKLIST`, `SIGNING_SETUP`, `build.gradle.kts`) sans secrets.
- **Risques identifies** :
  - pipeline global encore non vert (tests en echec etape 5.2) ;
  - pas de preuve build iOS sur cet hote ;
  - release Android prod/AAB non rejouee dans cette capture (debug dev seulement).
- **Rollback / mitigation** :
  - rejouer builds et logs dates apres upgrade Flutter ou changement Gradle ;
  - completer build iOS sur macOS et archiver log.
- **Preuves / validation** :
  - logs archives dans `artifacts/flutter_build_*_2026-04-02.txt` ;
  - doc `09_baseline_build_packaging.md`.
- **Derogation** : aucune pour l'absence iOS (constat environnement ; pas de contournement de regle).
- **Statut** : cloture sous-etape `5.3` ; lot `PH0-LOT-007` ouvert jusqu'a `5.4`.

## Entree `LOG-2026-04-02-015`

- **Date** : `2026-04-02`
- **Lot ID** : `PH0-LOT-007` (sous-etape `5.4` ; cloture lot etape `5`)
- **Type** : index des preuves de validation / baseline phase 0
- **Source de besoin** : `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/roadmap.md` etape `5.4`
- **Composants produits / modifies** :
  - `docs/quality/validation_evidence_index.md`
  - `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/roadmap.md`
  - `docs/traceability/change_logbook.md`
  - `docs/architecture/current_state.md`
- **Criticite du changement** : `C3`
- **Classe principale** : `L3`
- **Decision / resultat** :
  - creation de l'index central `QUAL-EVD-INDEX-001` avec entree **Phase 0 — Baseline** : environnement, commandes, liens artefacts `PH0-BL-Q-501` a `505` ;
  - section **preuves absentes** : CI, tests non verts, build iOS, integration_test, release prod, corpus incidents — plans de comblement references (pas de `PH0-WVR-*` pour ces lacunes a ce stade) ;
  - cloture du lot `PH0-LOT-007`.
- **Risques identifies** :
  - l'index doit etre tenu a jour sous peine de derive documentaire ;
  - lacunes listees restent des risques programme tant qu'non resolues.
- **Rollback / mitigation** :
  - completer l'index lors des prochaines campagnes de validation ;
  - lier les futurs `PH0-WVR-*` aux IDs GAP si derogation necessaire.
- **Preuves / validation** :
  - fichier `docs/quality/validation_evidence_index.md` ;
  - coherence avec `07` a `09` et artefacts dates.
- **Derogation** : aucune pour l'etablissement de l'index (constats et lacunes explicites).
- **Statut** : cloture sous-etape `5.4` ; cloture lot `PH0-LOT-007`.

## Entree `LOG-2026-04-02-016`

- **Date** : `2026-04-02`
- **Lot ID** : `PH0-LOT-008` (sous-etape `6.1`)
- **Type** : cartographie criticité C/L par domaine (grille initiale)
- **Source de besoin** : `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/roadmap.md` etape `6.1`
- **Composants produits / modifies** :
  - `docs/risk/component_criticality.md`
  - `docs/traceability/change_logbook.md`
  - `docs/architecture/current_state.md`
- **Criticite du changement** : `C3`
- **Classe principale** : `L3`
- **Decision / resultat** :
  - adoption des définitions `L1–L4` et `C1–C4` telles que dans `docs/rules_nasa.md` (§3) ;
  - création d’une grille initiale “domaines -> classe présumée” (conservatrice) avec justifications courtes ;
  - explicitation des incertitudes à compléter dans l’étape **6.2** (granularisation composant/zone) et l’alignement étape **6.3** (priorités P0/P1).
- **Risques identifies** :
  - risque de mauvaise classification si des sous-modules portent une criticité différente ;
  - nécessité de traiter l’absence de classe explicite en 6.2 (sinon risque de “programme” au sens `rules_nasa.md`).
- **Rollback / mitigation** :
  - mise à jour de `component_criticality.md` lors de 6.2/6.3 ;
  - si une classification L1 est rendue impossible par manque d’information, déclencher la logique “risque de programme” documentée en 6.2.
- **Preuves / validation** :
  - existence de [`docs/risk/component_criticality.md`](../risk/component_criticality.md).
- **Derogation** : aucune (`PH0-WVR-*`) requise pour une cartographie initiale.
- **Statut** : cloture sous-etape `6.1` ; lot `PH0-LOT-008` reste ouvert jusqu'a `6.2`-`6.3`.

## Entree `LOG-2026-04-02-017`

- **Date** : `2026-04-02`
- **Lot ID** : `PH0-LOT-008` (sous-etape `6.2`)
- **Type** : cartographie criticité C/L par composant (granularisation)
- **Source de besoin** : `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/roadmap.md` etape `6.2`
- **Composants produits / modifies** :
  - `docs/risk/component_criticality.md`
  - `docs/traceability/change_logbook.md`
  - `docs/architecture/current_state.md`
- **Criticite du changement** : `C3`
- **Classe principale** : `L3`
- **Decision / resultat** :
  - rédaction du tableau granulaire “composant / zone / L” conformément au référentiel `docs/rules_nasa.md` (§3) ;
  - assignation conservatrice d’un `L` pour chaque unité fonctionnelle listée ;
  - section “non classé faute d’information” explicitée (aucun composant L1 non classé à ce stade) et rappel de la règle d’arrêt si un L1 ne peut pas être classé.
- **Risques identifies** :
  - classification trop large (perte de précision) avant 6.3 ;
  - omission potentielle de sous-modules si la granularisation devait être ajustée.
- **Rollback / mitigation** :
  - mise à jour du document lors de 6.3 après alignement priorités P0/P1 et revue d’architecture ;
  - si un composant L1 ne peut pas être classé : marquer “risque de programme” et bloquer les étapes suivantes du lot.
- **Preuves / validation** :
  - document `docs/risk/component_criticality.md` avec la table “composant / zone / L”.
- **Derogation** : aucune (`PH0-WVR-*`) requise (classification conservatrice avec incertitudes).
- **Statut** : cloture sous-etape `6.2` ; lot `PH0-LOT-008` reste ouvert jusqu'a `6.3`.

## Entree `LOG-2026-04-02-018`

- **Date** : `2026-04-02`
- **Lot ID** : `PH0-LOT-008` (sous-etape `6.3`)
- **Type** : cartographie criticité C/L — cohérence priorités P0/P1
- **Source de besoin** : `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/roadmap.md` etape `6.3`
- **Composants produits / modifies** :
  - `docs/risk/component_criticality.md`
  - `docs/traceability/change_logbook.md`
  - `docs/architecture/current_state.md`
- **Criticite du changement** : `C3`
- **Classe principale** : `L3`
- **Decision / resultat** :
  - vérification d’alignement avec l’ordre concret recommandé P0/P1 du plan v3 (`docs/Refactor/movi_nasa_refactor_plan_v3.md` §23) ;
  - ajout d’un mapping “zone/composant -> priorité plan” et explicitation des divergences/arbitrages (feature “settings”/UI vs services ; movies/tv vs priorities P3) ;
  - mise à jour du statut “étape 6.3” (lot `PH0-LOT-008` clôturé à l’issue).
- **Risques identifies** :
  - priorités mal interprétées si le découpage “unités fonctionnelles” diffère des “zones core/feature” du plan.
- **Rollback / mitigation** :
  - ajuster le mapping en 6.3/8 si des résultats de revue d’architecture contredisent l’arbitrage ;
  - si un composant L1 ne peut pas être classé en cohérence, déclencher le mécanisme “risque de programme”.
- **Preuves / validation** :
  - présence des sections d’alignement dans `docs/risk/component_criticality.md`.
- **Derogation** : aucune (`PH0-WVR-*`) requise.
- **Statut** : cloture sous-etape `6.3` ; lot `PH0-LOT-008` cloturé.

## Lacunes deja visibles

- Aucun corpus incidents / anomalies / postmortem exploitable n'a ete trouve dans le depot a ce stade (reference aussi `PH0-BL-GAP-006` dans [`docs/quality/validation_evidence_index.md`](../quality/validation_evidence_index.md)).
- Les responsables nominatifs restent implicites tant qu'un document de gouvernance projet ne les designe pas nominativement.

## Entree `LOG-2026-04-02-019`

- **Date** : `2026-04-02`
- **Lot ID** : `PH0-LOT-009` (sous-etape `7.1`)
- **Type** : inventaire pipelines CI/CD (workflows)
- **Source de besoin** : `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/roadmap.md` etape `7.1`
- **Composants produits / modifies** :
  - `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/10_inventaire_ci_cd_pipelines.md`
  - `docs/traceability/change_logbook.md`
- **Criticite du changement** : `C3`
- **Classe principale** : `L3`
- **Decision / resultat** :
  - constats : absence de `.github/` et donc de workflows versionnés ; aucun manifest CI/CD détecté (Jenkins/Azure/GitLab/etc.) ;
  - conséquence : pipeline minimal NASA (§20.1) non implémenté côté dépôt à ce stade ; la preuve sera ajoutée en 7.2–7.3 via index ou dérogations formelles.
- **Risques identifies** :
  - risque de dérive : absence d’attestation CI pour analyse/tests/build ;
  - difficulté à satisfaire “no green pipeline, no release”.
- **Rollback / mitigation** :
  - lors de 7.2 : ajouter le tableau exigence vs implémenté et inscrire les lacunes dans l’index de preuves / dérogations ;
  - en 7.3 : définir release/rollback existants (ou documenter lacune).
- **Preuves / validation** :
  - existence du document `10_inventaire_ci_cd_pipelines.md` (constat absence de workflows/manifests).
- **Derogation** : aucune (`PH0-WVR-*`) ; c’est un constat de lacune.
- **Statut** : cloture sous-etape `7.1` ; lot `PH0-LOT-009` reste ouvert jusqu’a `7.2`-`7.3`.

## Entree `LOG-2026-04-02-020`

- **Date** : `2026-04-02`
- **Lot ID** : `PH0-LOT-009` (sous-etape `7.2`)
- **Type** : ecart vs pipeline minimal NASA §20.1 (table exigences → manques)
- **Source de besoin** : `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/roadmap.md` etape `7.2`
- **Composants produits / modifies** :
  - `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/11_ecart_pipeline_minimal_nasa_7_2.md`
  - `docs/quality/validation_evidence_index.md` (ajout lacunes granularisées PH0-BL-GAP-007..012)
  - `docs/traceability/change_logbook.md`
- **Criticite du changement** : `C3`
- **Classe principale** : `L3`
- **Decision / resultat** :
  - creation du tableau “exigence §20.1” vs “implémenté/manquant” sur la base du constat 7.1 (absence de workflows CI/CD versionnés) ;
  - granularisation des lacunes pipeline en entrées “GAP” pour aligner l’index preuves avec le détail §20.1.
- **Risques identifies** :
  - dérive documentaire entre constats CI et réalité dès qu’un workflow serait ajouté sans mise à jour de l’index ;
  - risque de contournement des gates “no green pipeline, no release”.
- **Rollback / mitigation** :
  - ré-exécuter l’inventaire CI (7.1) et régénérer l’écart (7.2) si un workflow est ajouté ;
  - mettre à jour les GAP (ou ajouter PH0-WVR-* si des contrôles sont temporairement réduits).
- **Preuves / validation** :
  - doc `11_ecart_pipeline_minimal_nasa_7_2.md` ;
  - coherence avec `docs/rules_nasa.md` §20.1 et la section “preuves absentes” de `validation_evidence_index.md`.
- **Derogation** : aucune (`PH0-WVR-*`) — lacunes nommées, pas de waiver.
- **Statut** : cloture sous-etape `7.2` ; lot `PH0-LOT-009` reste ouvert jusqu’a `7.3`.

## Entree `LOG-2026-04-02-021`

- **Date** : `2026-04-02`
- **Lot ID** : `PH0-LOT-009` (sous-etape `7.3`)
- **Type** : constat release et rollback
- **Source de besoin** : `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/roadmap.md` etape `7.3`
- **Composants produits / modifies** :
  - `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/12_constat_release_rollback_7_3.md`
  - `docs/quality/validation_evidence_index.md` (ajout lacunes PH0-BL-GAP-013..014)
  - `docs/traceability/change_logbook.md`
- **Criticite du changement** : `C3`
- **Classe principale** : `L3`
- **Decision / resultat** :
  - constats : aucun tag Git de release détecté, absence de `README.md` / `CHANGELOG.md` à la racine, absence de runbook opérationnel de rollback dans le périmètre versionné ;
  - relance NASA §20.1 : les releases standard restent suspendues pendant phase 0 et toute release devra ensuite être taguée, changelogée et associée à un rollback défini.
- **Risques identifies** :
  - impossibilité de prouver la traçabilité release ↔ changelog ↔ rollback ;
  - risque de difficulté de retour en conformité lors d’un incident si un rollback n’est pas défini.
- **Rollback / mitigation** :
  - préparer en phase ultérieure : versionner tags, `CHANGELOG.md`, runbook rollback ; associer à preuves indexées ;
  - si une réduction de contrôle est nécessaire : documenter une dérogation `PH0-WVR-*` avec date d’expiration et plan de retour.
- **Preuves / validation** :
  - doc `12_constat_release_rollback_7_3.md` ;
  - présence des GAP PH0-BL-GAP-013 et PH0-BL-GAP-014 dans `validation_evidence_index.md`.
- **Derogation** : aucune.
- **Statut** : cloture sous-etape `7.3` ; lot `PH0-LOT-009` clôturé.

## Entree `LOG-2026-04-02-022`

- **Date** : `2026-04-02`
- **Lot ID** : `PH0-LOT-010` (sous-etape `8.1`)
- **Type** : règles d’architecture cibles (rappel plan v3 §4.3)
- **Source de besoin** : `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/roadmap.md` etape `8.1`
- **Composants produits / modifies** :
  - `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/13_rappels_regles_architecture_cibles_8_1.md`
  - `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/roadmap.md`
  - `docs/architecture/current_state.md`
  - `docs/traceability/change_logbook.md`
- **Criticite du changement** : `C3`
- **Classe principale** : `L3`
- **Decision / resultat** :
  - transfert des règles “architecture bloquantes” depuis `movi_nasa_refactor_plan_v3.md` §4.3 en un livrable exploitable pour 8.2 ;
  - explicitation d’une méthode de détection (périmètre de recherche, production d’une liste brute de violations, puis classement).
- **Risques identifies** :
  - interprétation divergente en 8.2 si les règles cibles ne sont pas strictement suivies.
- **Rollback / mitigation** :
  - ajuster le livrable “8.1” si une ambiguïté est identifiée pendant 8.2.
- **Preuves / validation** :
  - présence du document `13_rappels_regles_architecture_cibles_8_1.md`.
- **Derogation** : aucune.
- **Statut** : cloture sous-etape `8.1` ; lot `PH0-LOT-010` reste ouvert jusqu’a `8.2`.

## Entree `LOG-2026-04-02-023`

- **Date** : `2026-04-02`
- **Lot ID** : `PH0-LOT-010` (sous-etape `8.2`)
- **Type** : inventaire initial violations d’architecture
- **Source de besoin** : `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/roadmap.md` etape `8.2`
- **Composants produits / modifies** :
  - `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/14_inventaire_violations_architecture_8_2.md`
  - `docs/traceability/change_logbook.md`
- **Criticite du changement** : `C3`
- **Classe principale** : `L3`
- **Decision / resultat** :
  - production d’une liste brute de violations à partir des règles bloquantes cibles (rappel 8.1) ;
  - classement conservateur par type (`V1`–`V4`) et assignation d’un `L` présumé + `C` et coût estimés.
- **Risques identifies** :
  - les heuristiques peuvent être incomplètes ou sur-approximer certaines catégories (ex. V3 selon définition “accès locator”) ;
  - besoin d’une revue de code ciblée avant toute correction.
- **Rollback / mitigation** :
  - n’implique aucun changement code ; uniquement documentaire ;
  - compléter/ajuster la liste en 8.2/8.3 si la revue de code infirme un point.
- **Preuves / validation** :
  - présence de `14_inventaire_violations_architecture_8_2.md`.
- **Derogation** : aucune.
- **Statut** : cloture sous-etape `8.2` ; lot `PH0-LOT-010` clôturé côté phase 0.

## Entree `LOG-2026-04-02-024`

- **Date** : `2026-04-02`
- **Lot ID** : `PH0-LOT-011` (sous-etape `9.1`)
- **Type** : couverture test / observabilité / doc (flux critiques présumés)
- **Source de besoin** : `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/roadmap.md` etape `9.1`
- **Composants produits / modifies** :
  - `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/15_flux_critiques_couverture_9_1.md`
  - `docs/traceability/change_logbook.md`
- **Criticite du changement** : `C3`
- **Classe principale** : `L3`
- **Decision / resultat** :
  - liste des flux critiques présumés (amorce phase 3) ;
  - coche “tests / logs structurés / runbook” sur la base des preuves baseline et du constat d’absence de runbooks ;
  - explicitation de l’état baseline “non-vert” sur certains flux liés aux 3 tests en échec.
- **Risques identifies** :
  - ambiguïté si “logs structurés” est compris comme JSON corrélé ; en phase 0, on atteste seulement une structure minimale (timestamp/level/category).
- **Rollback / mitigation** :
  - enrichir en 9.2–9.3 avec une classification de lacunes et une liste de preuves absentes (puis actionner dérogations si nécessaire).
- **Preuves / validation** :
  - présence du document `15_flux_critiques_couverture_9_1.md` et des références `08_baseline_tests_automatises.md`.
- **Derogation** : aucune.
- **Statut** : cloture sous-etape `9.1` ; lot `PH0-LOT-011` reste ouvert jusqu’a `9.3`.

## Entree `LOG-2026-04-02-025`

- **Date** : `2026-04-02`
- **Lot ID** : `PH0-LOT-011` (sous-etape `9.2`)
- **Type** : secrets et configuration (constat)
- **Source de besoin** : `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/roadmap.md` etape `9.2`
- **Composants produits / modifies** :
  - `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/16_constat_secrets_configuration_9_2.md`
  - `docs/traceability/change_logbook.md`
- **Criticite du changement** : `C3`
- **Classe principale** : `L3`
- **Decision / resultat** :
  - constat des mécanismes d’injection (`--dart-define` + `SecretStore`) ;
  - constat de protections logs (sanitization) ;
  - aucun indice critique de secrets en clair dans les fichiers versionnés (sous-ensemble scanné par mots-clés).
- **Risques identifies** :
  - `.env` peut contenir des secrets côté poste si présent ; ne doit jamais être versionné.
- **Rollback / mitigation** :
  - pas de changement code ; maintenir `.gitignore` et éviter tout export des valeurs vers artefacts/logs.
- **Preuves / validation** :
  - présence du document `16_constat_secrets_configuration_9_2.md`.
- **Derogation** : aucune.
- **Statut** : cloture sous-etape `9.2` ; lot `PH0-LOT-011` reste ouvert jusqu’a `9.3`.

## Entree `LOG-2026-04-02-026`

- **Date** : `2026-04-02`
- **Lot ID** : `PH0-LOT-011` (sous-etape `9.3`)
- **Type** : mise à jour index preuves (consolidation)
- **Source de besoin** : `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/roadmap.md` etape `9.3`
- **Composants produits / modifies** :
  - `docs/quality/validation_evidence_index.md`
  - `docs/traceability/change_logbook.md`
- **Criticite du changement** : `C2`
- **Classe principale** : `L2`
- **Decision / resultat** :
  - consolidation des preuves issues de `9.1` (`15_flux_critiques_couverture_9_1.md`) et `9.2` (`16_constat_secrets_configuration_9_2.md`) ;
  - ajout des lacunes dédiées observabilité / runbooks (PH0-BL-GAP-015 à PH0-BL-GAP-017) + rappels des lacunes déjà listées.
- **Risques identifies** :
  - risque de dérive si les preuves changent sans mise à jour de l’index.
- **Rollback / mitigation** :
  - documenter toute correction via nouvelles entrées d’index et/ou dérogations si nécessaire.
- **Preuves / validation** :
  - présence d’entrées “Étape 9 — Zones sans preuve” dans `validation_evidence_index.md`.
- **Derogation** : aucune.
- **Statut** : cloture sous-etape `9.3` ; lot `PH0-LOT-011` cloturé phase 0.

## Entree `LOG-2026-04-02-027`

- **Date** : `2026-04-02`
- **Lot ID** : `PH0-LOT-012` (sous-etape `10.1`)
- **Type** : revue croisée documentaire (existence livrables + checklist Annexe A)
- **Source de besoin** : `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/roadmap.md` etape `10.1`
- **Composants produits / modifies** :
  - `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/17_revue_croisee_10_1.md`
  - `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/roadmap.md`
  - `docs/traceability/change_logbook.md`
  - `docs/architecture/current_state.md`
- **Criticite du changement** : `C2`
- **Classe principale** : `L2`
- **Decision / resultat** :
  - verification par desk-check que les livrables cibles phase 0 existent ;
  - production d’une checklist Annexe A adaptée à la livraison documentaire.
- **Risques identifies** :
  - revue indépendante humaine non explicitement tracée pour cette livraison documentaire (contrôle §16 incomplet).
- **Rollback / mitigation** :
  - rattraper par une vérification indépendante lors de 10.2 (verdict de sortie) et/ou lors de la revue de phase 1.
- **Preuves / validation** :
  - présence du document `17_revue_croisee_10_1.md`.
- **Derogation** : aucune.
- **Statut** : cloture sous-etape `10.1` ; lot `PH0-LOT-012` reste ouvert jusqu’à 10.2.

## Entree `LOG-2026-04-02-028`

- **Date** : `2026-04-02`
- **Participants** : `Desk-check documentaire (auteur) + relecteur indépendant (à nommer)`
- **Lot ID** : `PH0-LOT-012` (sous-etape `10.2`)
- **Type** : verdict de sortie phase 0
- **Source de besoin** : `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/roadmap.md` etape `10.2`
- **Composants produits / modifies** :
  - `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/18_verdict_sortie_phase_0_10_2.md`
  - `docs/traceability/change_logbook.md`
- **Criticite du changement** : `C3`
- **Classe principale** : `L3`
- **Decision / resultat** :
  - dossier de verdict : **Bloqué** pour démarrer la phase 1 ;
  - justification : qualité gates §27 non satisfaites par preuves/gaps existants.
- **Risques identifies** :
  - risque de démarrage phase 1 sans traitement des gaps (tests non-verts, observabilité/runbooks, rollback).
- **Rollback / mitigation** :
  - traiter les réserves R1–R4 listées dans le document de verdict avant toute phase 1 ;
  - toute dérogation doit être formalisée selon §26 si nécessaire.
- **Preuves / validation** :
  - présence du document `18_verdict_sortie_phase_0_10_2.md`.
- **Derogation** : aucune.
- **Statut** : cloture sous-etape `10.2` ; lot `PH0-LOT-012` clôturé phase 0.

## Entree `LOG-2026-04-02-029`

- **Date** : `2026-04-02`
- **Lot ID** : `PH0-LOT-012` (sous-etape `10.3`)
- **Type** : transmission risques & violations vers registre Phase 1
- **Source de besoin** : `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/roadmap.md` etape `10.3`
- **Composants produits / modifies** :
  - `docs/risk/system_risk_register.md`
  - `docs/traceability/change_logbook.md`
- **Criticite du changement** : `C2`
- **Classe principale** : `L2`
- **Decision / resultat** :
  - création d’un registre initial Phase 1 (`system_risk_register.md`) ;
  - transmission explicite des risques résiduels (depuis verdict 10.2) et des familles de violations d’architecture (depuis 8.2).
- **Risques identifies** :
  - registre incomplet tant que Phase 1 n’enrichit pas (hazard analysis, threat model, détectabilité, rollback, etc.).
- **Rollback / mitigation** :
  - enrichir en Phase 1 selon plan v3 ; ne pas modifier la source Phase 0 sans mise à jour de la traçabilité.
- **Preuves / validation** :
  - présence de `docs/risk/system_risk_register.md` et liens vers preuves Phase 0.
- **Derogation** : aucune.
- **Statut** : cloture sous-etape `10.3` ; passage à Phase 1 conditionné au verdict déjà publié en 10.2.

## Entree `LOG-2026-04-02-030`

- **Date** : `2026-04-02`
- **Lot ID** : `PH0-LOT-012` (sous-etape `R1`)
- **Type** : re-basinage R1 — passage gate « tests automatisés » vert
- **Source de besoin** : `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/18_verdict_sortie_phase_0_10_2.md` (réserve **R1**)
- **Composants produits / modifies** :
  - `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/08_baseline_tests_automatises.md`
  - `docs/quality/validation_evidence_index.md`
  - `docs/traceability/change_logbook.md`
- **Criticite du changement** : `C2`
- **Classe principale** : `L2`
- **Decision / resultat** :
  - re-run `flutter test` : **200** pass / **0** fail ;
  - gate NASA §27 « tests automatisés en échec » satisfaite ;
  - levée du gap `PH0-BL-GAP-002` (et mise à jour `PH0-BL-Q-502`).
- **Risques identifies** :
  - aucun risque bloquant identifié : action de stabilisation tests uniquement.
- **Rollback / mitigation** :
  - en cas de régression ultérieure, réutiliser les artefacts du re-run R1 et re-baser la campagne de correction.
- **Preuves / validation** :
  - présence de l’artefact `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/artifacts/flutter_test_R1_2026-04-02.txt` ;
  - mise à jour des docs `08_baseline_tests_automatises.md` et `validation_evidence_index.md`.
- **Derogation** : aucune.
- **Statut** : cloture sous-etape `R1` ; la disponibilité de Phase 1 reste conditionnée aux réserves **R2/R3/R4**.

## Entree `LOG-2026-04-02-031`

- **Date** : `2026-04-02`
- **Lot ID** : `PH0-LOT-012` (sous-etape `R2`)
- **Type** : réserve R2 — observabilité & runbooks (preuves minimales)
- **Source de besoin** : `docs/rules_nasa.md` §14 + `docs/quality/validation_evidence_index.md` (gaps `PH0-BL-GAP-015..017`)
- **Composants produits / modifies** :
  - `docs/operations/runbooks/RBK-000_incident_triage.md`
  - `docs/operations/runbooks/RBK-101_startup_orchestration.md`
  - `docs/operations/runbooks/RBK-102_session_restore.md`
  - `docs/operations/runbooks/RBK-103_auth_gating.md`
  - `docs/operations/runbooks/RBK-104_playback_source_selection.md`
  - `docs/operations/runbooks/RBK-105_playback_variant_resolution.md`
  - `docs/operations/runbooks/RBK-106_parental_profiles.md`
  - `docs/operations/runbooks/RBK-107_library_sync.md`
  - `docs/operations/runbooks/RBK-108_settings_sync_offsets.md`
  - `docs/operations/observability/logging_schema.md`
  - `docs/operations/observability/metrics_minimum.md`
  - `docs/operations/observability/sentry_setup.md`
  - `lib/src/core/logging/operation_context.dart`
  - `lib/src/core/logging/adapters/console_logger.dart`
  - `lib/src/core/logging/adapters/file_logger.dart`
  - `lib/src/core/observability/sentry_bootstrap.dart`
  - `lib/main.dart`
  - `test/core/logging/operation_id_correlation_test.dart`
  - `test/core/observability/sentry_capture_test.dart`
  - `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/artifacts/r2_operationid_correlation_test_2026-04-02.txt`
  - `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/artifacts/r2_sentry_capture_test_2026-04-02.txt`
- **Criticite du changement** : `C2`
- **Classe principale** : `L2`
- **Decision / resultat** :
  - production de runbooks versionnés pour les 8 flux critiques (R2) ;
  - ajout d’une corrélation `operationId` (logs) + preuve par test ;
  - définition d’un minimum de métriques + preuve crash/error monitoring via Sentry (test transport in-memory).
- **Risques identifies** :
  - instrumentation minimaliste : certaines métriques restent “définies” plutôt que totalement industrialisées (alerting/outillage à durcir en phase suivante).
- **Rollback / mitigation** :
  - les changements observabilité sont principalement additifs (docs + instrumentation non bloquante) ;
  - en cas d’effets indésirables, désactiver Sentry via `SENTRY_DSN` vide.
- **Preuves / validation** :
  - preuves consolidées dans `docs/quality/validation_evidence_index.md` (section “Réserve R2”).
- **Derogation** : aucune.
- **Statut** : cloture sous-etape `R2` ; verdict Phase 0 reste conditionné à **R3/R4**.

## Entree `LOG-2026-04-02-032`

- **Date** : `2026-04-02`
- **Lot ID** : `PH0-LOT-012` (sous-etape `R3`)
- **Type** : réserve R3 — rollback opérationnel versionné
- **Source de besoin** : `docs/rules_nasa.md` §20.1 + §23 + §27 ; gap `PH0-BL-GAP-014`
- **Composants produits / modifies** :
  - `docs/operations/rollback/rollback_strategy.md`
  - `docs/operations/rollback/RBK-201_android_playstore_rollback.md`
  - `docs/operations/rollback/RBK-202_windows_rollback.md`
  - `docs/operations/rollback/RBK-203_ios_rollback.md`
  - `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/artifacts/r3_rollback_rehearsal_android_playstore_2026-04-02.txt`
  - `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/artifacts/r3_rollback_rehearsal_windows_2026-04-02.txt`
  - `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/artifacts/r3_rollback_rehearsal_ios_2026-04-02.txt`
  - `docs/quality/validation_evidence_index.md`
  - `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/18_verdict_sortie_phase_0_10_2.md`
  - `docs/traceability/change_logbook.md`
- **Criticite du changement** : `C2`
- **Classe principale** : `L2`
- **Decision / resultat** :
  - stratégie rollback versionnée définie ;
  - runbooks par plateforme (Android Play, Windows, iOS) ;
  - rehearsal minimal archivé (Android obligatoire + Windows/iOS documentaire) ;
  - gap `PH0-BL-GAP-014` traité (R3).
- **Risques identifies** :
  - iOS : rollback strict limité ; stratégie repose sur stop rollout + hotfix.
- **Rollback / mitigation** :
  - documents et artefacts additifs ; mise à jour par versions ultérieures en phase R4/CI.
- **Preuves / validation** :
  - section “Réserve R3” dans `docs/quality/validation_evidence_index.md`.
- **Derogation** : aucune.
- **Statut** : cloture sous-etape `R3` ; verdict Phase 0 reste conditionné à **R4**.

## Entree `LOG-2026-04-02-033`

- **Date** : `2026-04-02`
- **Lot ID** : `PH0-LOT-012` (sous-etape `R4`)
- **Type** : réserve R4 — pipeline CI/CD minimal “preuves” (Codemagic)
- **Source de besoin** : `docs/rules_nasa.md` §20 + §27 ; gaps `PH0-BL-GAP-001` et `PH0-BL-GAP-007..012`
- **Composants produits / modifies** :
  - `codemagic.yaml` (workflow `ci-quality-proof` + logs CI `ci_proofs/*` + analyse bloquante)
  - `docs/operations/ci/codemagic_pipeline_minimum.md`
  - `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/10_inventaire_ci_cd_pipelines.md`
  - `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/11_ecart_pipeline_minimal_nasa_7_2.md`
  - `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/artifacts/r4_local_quality_proof_2026-04-02.txt`
  - `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/artifacts/r4_local_android_aab_proof_2026-04-02.txt`
  - `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/artifacts/r4_codemagic_trigger_run_export_checklist_2026-04-02.txt`
  - `docs/quality/validation_evidence_index.md`
  - `docs/Refactor/phase_0_baseline_inventaire_gel_photographie/18_verdict_sortie_phase_0_10_2.md`
- **Criticite du changement** : `C2`
- **Classe principale** : `L2`
- **Decision / resultat** :
  - pipeline minimal §20 outillé via Codemagic et versionné ;
  - preuves “qualité” (analyze/tests) et “build/packaging Android” démontrées par artefacts datés ;
  - procédure d’activation triggers + export preuves CI versionnée.
- **Risques identifies** :
  - preuve d’exécution CI dépendante de l’outillage externe (Codemagic UI) ; la procédure d’export doit être respectée pour chaque release.
- **Rollback / mitigation** :
  - en cas de changement d’outil CI, conserver la discipline §20 en re-versionnant un pipeline équivalent et en re-basinant les preuves.
- **Preuves / validation** :
  - section “Réserve R4” dans `docs/quality/validation_evidence_index.md` + artefacts R4.
- **Derogation** : aucune.
- **Statut** : cloture sous-etape `R4` ; verdict Phase 0 peut passer à **Ready** pour Phase 1.

## Entree `LOG-2026-04-02-044`

- **Date** : `2026-04-02`
- **Lot ID** : `PH2-LOT-003` (clôture — preuve CI `ci-quality-proof`)
- **Type** : preuve CI exportée — mur d’architecture (baseline) + canary
- **Source de besoin** : `docs/rules_nasa.md` §20 (pipeline) + §25 (artefacts de preuve) + §27 (quality gates) ; roadmap Phase 2 (M3)
- **Composants produits / modifies** :
  - `analysis_options.yaml` (exclusion fixtures canary de `flutter analyze`)
  - `docs/Refactor/phase_2_arch_wall/artifacts/ci_quality_proof_2026-04-02/manifest.md`
  - `docs/Refactor/phase_2_arch_wall/artifacts/ci_quality_proof_2026-04-02/ci_proofs/*`
  - `docs/quality/validation_evidence_index.md`
  - `docs/traceability/change_logbook.md`
- **Criticite du changement** : `C2`
- **Classe principale** : `L2`
- **Decision / resultat** :
  - workflow `ci-quality-proof` exécuté sur `main` ;
  - artefacts exportés et archivés dans le dépôt pour audit (logs + rapports) ;
  - preuve de fonctionnement : delta baseline + rapport canary déclenchant `ARCH-R1..R5`.
- **Risques identifies** :
  - la preuve CI reste dépendante d’un outillage externe ; obligation d’archiver à chaque release “preuve” (discipline §25).
- **Rollback / mitigation** :
  - changement additif (fichiers de preuve) ; en cas de volumétrie excessive, compresser/archiver hors dépôt en conservant le manifest et les hashes.
- **Preuves / validation** :
  - voir entrée Phase 2 dans `docs/quality/validation_evidence_index.md` + manifest `ci_quality_proof_2026-04-02`.
- **Derogation** : aucune.
- **Statut** : preuve CI Phase 2 **archivée** ; gate “mur anti-réintroduction” démontrée.

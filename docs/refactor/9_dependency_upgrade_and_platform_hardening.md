# PRD — Refactor Dependency Upgrade & Platform Hardening

## 1. Contexte

Après les chantiers:

1. `1_localizations.md`
2. `2_focus.md`
3. `3_architecture_boundaries.md`
4. `4_monolith_pages_decomposition.md`
5. `5_quality_gates_and_repo_hygiene.md`
6. `6_data_contracts_and_error_boundaries.md`
7. `7_observability_and_runtime_diagnostics.md`
8. `8_performance_and_render_stability.md`

la prochaine source de risque structurel est la dérive des dépendances et la fragilité de la chaîne build/release multi-plateforme.

Le projet repose sur un ensemble de packages Flutter/Dart, plugins natifs et outils de build (Android/iOS/Windows, CI, signing). Sans politique d'upgrade et de hardening explicite, les incidents apparaissent souvent tardivement: incompatibilités, breakages en release, problèmes de sécurité, builds non reproductibles.

Ce PRD définit le chantier 9: sécuriser la gestion des dépendances et renforcer la fiabilité plateforme/build.

---

## 2. Problème à résoudre

### 2.1 Symptômes observés

1. Upgrades irréguliers et opportunistes
   - dépendances mises à jour au fil de l'eau sans cadence stable.

2. Risque de dette de compatibilité
   - accumulation de versions obsolètes,
   - sauts de versions majeures plus risqués.

3. Fragilité multi-plateforme
   - variations Android/iOS/Windows selon environnement local/CI.

4. Reproductibilité build incomplète
   - résultats différents selon machine, cache, versions outils.

5. Visibilité sécurité limitée
   - suivi CVE/advisories/transitives pas toujours industrialisé.

### 2.2 Causes racines

- absence de policy explicite de lifecycle dépendances.
- manque de process centralisé upgrade -> validation -> rollout.
- hardening build/signing/documentation hétérogène par plateforme.
- contrôles CI dépendances/sécurité incomplets.

---

## 3. Objectifs

### 3.1 Objectif principal

Établir une gouvernance durable des dépendances et une chaîne build/release robuste, reproductible et sécurisée sur toutes les plateformes ciblées.

### 3.2 Objectifs détaillés

1. Formaliser une politique de versions et de cadence d'upgrade.
2. Réduire les risques sécurité des dépendances directes et transitives.
3. Standardiser la validation multi-plateforme avant merge/release.
4. Garantir la reproductibilité des builds critiques.
5. Définir un plan de rollback lors d'upgrade majeure.

### 3.3 KPI de succès

1. Diminution des incidents liés aux upgrades dépendances.
2. Réduction des divergences build local vs CI.
3. Taux élevé de builds reproductibles sur plateformes cibles.
4. Diminution des vulnérabilités ouvertes au-delà du SLA défini.

---

## 4. Hors périmètre

Ne font pas partie du chantier, sauf ajustement strictement nécessaire:

- migration de framework hors Flutter/Dart.
- refonte fonctionnelle produit.
- changement de store distribution strategy.
- remplacement global de la CI platform.

Le chantier cible la fiabilité technique du socle dépendances/build.

---

## 5. Principes directeurs

1. Upgrade continu et incrémental plutôt que rattrapage massif tardif.
2. Chaque upgrade critique doit avoir plan de validation + rollback.
3. Reproductibilité d'abord: même entrée, même résultat.
4. La sécurité dépendances est un critère de release, pas un bonus.
5. La complexité d'outillage reste minimale et documentée.

---

## 6. Architecture cible du cycle dépendances/platforme

## 6.1 Politique de versions

Définir:

1. cadence patch/minor/major (ex: patch hebdo, minor mensuelle, major planifiée),
2. SLA de traitement vulnérabilités,
3. règles de pinning et exceptions.

## 6.2 Pipeline upgrade standard

1. détection (updates + advisories),
2. classification impact (low/medium/high/risky),
3. upgrade incrémental,
4. validation automatique,
5. canary/release progressive,
6. rollback prêt.

## 6.3 Hardening build multi-plateforme

1. Android:
   - cohérence Gradle/SDK/plugins,
   - signature et config release reproductibles.
2. iOS:
   - cohérence Xcode/cocoapods/settings signing,
   - scripts de build déterministes.
3. Windows:
   - toolchain et artefacts de packaging stabilisés.

## 6.4 Reproductibilité

Règles:

1. lockfiles cohérents et commités selon conventions projet.
2. versions outils minimales/recommandées documentées.
3. scripts build normalisés (local/CI).
4. dépendance explicite aux secrets/signing sans fuite.

## 6.5 Sécurité dépendances

1. scan régulier dependencies + transitives.
2. triage vulnérabilités par sévérité/exploitabilité.
3. exceptions temporaires tracées avec échéance.

---

## 7. Périmètres prioritaires (ordre)

## 7.1 Priorité P1

1. dépendances Flutter/Dart critiques (`pubspec`).
2. chaîne Android build/signing.
3. dépendances auth/network/storage/security.

## 7.2 Priorité P2

1. iOS build/signing hardening.
2. Windows runner/toolchain hardening.
3. plugins transitifs à fort risque de breakage.

## 7.3 Priorité P3

1. optimisation process release cross-plateforme.
2. automatisations avancées de maintenance dépendances.

---

## 8. Chantiers techniques prioritaires

## Lot A — Dependency governance

Objectif:

- rendre la gestion dépendances prédictive.

Actions:

1. inventaire dépendances critiques/directes/transitives.
2. policy versions + SLA sécurité.
3. calendrier upgrade continu.

Résultat attendu:

- réduction dette de versions et surprises de compatibilité.

## Lot B — Automated dependency checks

Objectif:

- détecter tôt risques et vulnérabilités.

Actions:

1. checks updates + advisories en CI.
2. rapport de risques classé.
3. blocage conditionnel selon sévérité.

Résultat attendu:

- visibilité fiable avant merge/release.

## Lot C — Platform hardening

Objectif:

- fiabiliser builds Android/iOS/Windows.

Actions:

1. normaliser scripts/platform configs.
2. verrouiller prérequis toolchains.
3. valider packaging/signing en pipeline.

Résultat attendu:

- builds reproductibles et stables multi-plateforme.

## Lot D — Upgrade safety net

Objectif:

- sécuriser le changement lors d'upgrades majeures.

Actions:

1. playbook upgrade major.
2. matrice de tests de compatibilité.
3. procédure rollback documentée et testée.

Résultat attendu:

- upgrades majeures contrôlées sans incidents critiques.

---

## 9. Backlog initial (ordre imposé)

## Epic A — Baseline dépendances

Story A1:

- snapshot complet des versions et criticité.

Story A2:

- classification des packages par risque.

Story A3:

- policy de maintenance dépendances formalisée.

## Epic B — CI dependency/security gates

Story B1:

- checks automatiques upgrades disponibles.

Story B2:

- scan vulnérabilités + reporting.

Story B3:

- seuils de blocage selon criticité.

## Epic C — Platform hardening

Story C1:

- Android build/signing reproductible.

Story C2:

- iOS build/signing reproductible.

Story C3:

- Windows packaging/build reproductible.

## Epic D — Upgrade execution model

Story D1:

- workflow upgrade patch/minor.

Story D2:

- playbook major upgrade.

Story D3:

- rollback readiness.

## Epic E — Consolidation

Story E1:

- documentation runbook complète.

Story E2:

- formation équipe sur process.

Story E3:

- baseline post-chantier et suivi continu.

---

## 10. Critères d'acceptation

## 10.1 Critères gouvernance

1. policy versions/SLA sécurité validée et appliquée.
2. calendrier upgrade continu actif.
3. exceptions dépendances tracées avec échéance.

## 10.2 Critères techniques

1. checks dépendances/sécurité intégrés en CI.
2. builds Android/iOS/Windows reproductibles sur pipeline de référence.
3. process rollback major upgrade documenté et testable.

## 10.3 Critères opérationnels

1. rapport dépendances/sécurité disponible à chaque cycle.
2. baisse mesurable des incidents liés aux upgrades.
3. convergence local/CI sur résultats build.

---

## 11. Plan de test

## 11.1 Tests de compatibilité dépendances

À couvrir:

1. upgrade patch/minor sur dépendances critiques.
2. smoke fonctionnel post-upgrade.
3. validation absence de break API runtime.

## 11.2 Tests multi-plateforme build

À couvrir:

1. Android debug/release + signing.
2. iOS debug/release + signing.
3. Windows build/package.

## 11.3 Tests sécurité

À couvrir:

1. scan vulnérabilités directes/transitives.
2. validation traitement selon SLA.
3. vérification des exceptions temporaires.

## 11.4 Tests rollback

À couvrir:

1. simulation échec upgrade major.
2. retour version stable précédente.
3. confirmation intégrité build/release post-rollback.

---

## 12. Plan de migration

## Étape 1 — Baseline et policy

Livrables:

1. inventaire dépendances + criticité.
2. policy versions/sécurité.

## Étape 2 — CI checks et reporting

Livrables:

1. checks dépendances/sécurité actifs.
2. reporting standardisé.

## Étape 3 — Hardening plateformes P1/P2

Livrables:

1. Android puis iOS puis Windows stabilisés.
2. scripts/documentation unifiés.

## Étape 4 — Upgrade model + rollback

Livrables:

1. playbooks patch/minor/major.
2. procédure rollback validée.

## Étape 5 — Consolidation continue

Livrables:

1. runbook final,
2. suivi KPI et revues périodiques.

---

## 13. Risques et mitigations

## Risque 1 — Blocage CI trop agressif

Mitigation:

- seuils progressifs et calibration initiale.

## Risque 2 — Surcharge de maintenance process

Mitigation:

- automatiser au maximum et limiter règles utiles.

## Risque 3 — Incompatibilités plateforme inattendues

Mitigation:

- validation matrice multi-plateforme en continu.

## Risque 4 — Faux sentiment de sécurité

Mitigation:

- corréler scans automatiques avec revue humaine ciblée.

---

## 14. Indicateurs de succès

Le chantier est considéré réussi si:

1. les upgrades deviennent réguliers et contrôlés.
2. les incidents dépendances/plateforme diminuent.
3. les builds release sont reproductibles et fiables.
4. les vulnérabilités critiques sont traitées dans le SLA.

---

## 15. Décisions de conception à retenir

1. La dette dépendances est traitée en continu, pas par rattrapage.
2. Les checks sécurité/dépendances sont des gates qualité.
3. Le hardening plateforme est un prérequis release.
4. Toute montée majeure dispose d'un rollback prêt.
5. La reproductibilité build est un critère de done.

---

## 16. Résultat attendu final

À l'issue du chantier 9, le projet doit disposer:

1. d'une gouvernance dépendances claire et durable,
2. d'une chaîne build/release multi-plateforme plus robuste,
3. d'une meilleure maîtrise des risques sécurité/compatibilité.

Le gain attendu est une release cadence plus sûre, moins d'incidents externes et une maintenance technique prévisible.

---

## 17. Annexe — Résumé opérationnel

### En une phrase

Le chantier 9 transforme la gestion dépendances et la fiabilité plateforme en processus continu, mesuré et sécurisé.

### Priorités absolues

1. policy versions + SLA sécurité.
2. checks CI dépendances/vulnérabilités.
3. hardening Android/iOS/Windows.
4. playbook upgrade major + rollback.

### Règle d'or

Une dépendance non gouvernée finit par devenir un incident de production.

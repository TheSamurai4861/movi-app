# Plan directeur v3 de transformation « NASA-like » pour le projet Movi

## Statut du document
- **Version** : v3
- **Nature** : plan directeur de transformation haute assurance
- **But** : préparer et piloter une refactorisation complète de Movi au plus près de `rules_nasa.md`
- **Portée visée** : dépôt complet (`lib/`, `test/`, racine projet, CI/CD, scripts, configuration, plateformes, documentation, artefacts de release, dépendances)
- **Portée réellement auditée à ce stade** : sous-ensemble déjà fourni antérieurement (`lib/`, `assets/`) ; le reste doit être qualifié en phase 0
- **Usage attendu** : document de gouvernance, de séquencement, de contrôle, de preuve, de qualification et de préparation de livraison
- **Limite explicite** : ce plan n’est **pas** une preuve de conformité du projet ; il organise la production de cette preuve

---

## 1. Qualification

### 1.1 Résumé du besoin
Le projet Movi doit être repris comme un système à enjeux élevés et refactoré selon une discipline proche d’une ingénierie mission-grade : architecture vérifiable, couplage réduit, effets de bord isolés, sécurité et confidentialité durcies, erreurs observables, tests adaptés, traçabilité et rollback systématiques.

### 1.2 Périmètre impacté
Le périmètre cible comprend :
- code applicatif ;
- configuration ;
- scripts ;
- tests ;
- observabilité ;
- CI/CD ;
- dépendances ;
- documentation technique et d’exploitation ;
- plateformes supportées ;
- packaging, release, rollback, migrations.

### 1.3 Classification prudente
- **Programme global de transformation** : **C1**
- **Zones présumées L1** : auth, sécurité, stockage, startup, réseau, parental, player, IPTV, diagnostics, persistance sensible
- **Zones présumées L2** : movie, tv, library, search, settings, home, profile, router, subscription
- **Zones présumées L3/L4** : thème, responsive, widgets génériques, assets non critiques

### 1.4 Hypothèses minimales prudentes
En l’absence de preuve complète sur le dépôt racine, la stratégie doit considérer par défaut :
- exposition élevée aux régressions structurelles ;
- niveau de contrôle renforcé ;
- absence de preuve = non validé ;
- toute réduction de contrôle = dérogation formelle.

---

## 2. Alignement explicite avec `rules_nasa.md`

Le programme v3 est construit pour satisfaire le plus directement possible les exigences suivantes du référentiel :
- sûreté, sécurité et correction avant vitesse ;
- aucun changement critique sans preuve suffisante ;
- traçabilité entre besoin, code, risques, tests et validation ;
- aucun comportement implicite, non observé ou non déterministe sur chemin critique ;
- architecture fondée sur des abstractions stables ;
- dépendances circulaires interdites ;
- effets de bord identifiables ;
- erreurs catégorisées, fallbacks explicites, observabilité exploitable ;
- tests adaptés au niveau de criticité ;
- quality gates bloquants ;
- rollback et mitigation obligatoires ;
- dérogations uniquement formelles, datées et traçables.

---

## 3. Objectif final de transformation

L’objectif n’est pas seulement de « rendre le code plus propre ». L’objectif final est de disposer d’un produit et d’un dépôt qui puissent être évalués comme suit :

1. **Architecture maîtrisée**
   - frontières de modules explicites ;
   - logique métier découplée de l’UI, des SDK, de la base et de l’infrastructure ;
   - DI centralisée et invisible depuis l’UI.

2. **Sûreté de fonctionnement**
   - transitions d’état explicites ;
   - comportement sûr en cas d’échec partiel ;
   - modes dégradés définis ;
   - absence d’échec silencieux sur les flux critiques.

3. **Sécurité et confidentialité durcies**
   - secrets et données sensibles protégés ;
   - stockage local requalifié ;
   - privilèges minimisés ;
   - logs et diagnostics nettoyés.

4. **Observabilité et exploitation prêtes**
   - logs structurés ;
   - corrélation ;
   - métriques minimales ;
   - runbooks et rollback exploitables.

5. **Preuve et traçabilité**
   - matrice exigences ↔ composants ↔ risques ↔ tests ↔ validation ;
   - documentation à jour ;
   - quality gates opposables.

---

## 4. Modèle d’architecture cible

### 4.1 Structure recommandée

```text
features/<feature>/
  presentation/
    pages/
    widgets/
    controllers/
    view_models/
  application/
    use_cases/
    services/
    orchestrators/
    policies/
  domain/
    entities/
    value_objects/
    repositories/
    failures/
    rules/
  data/
    repositories/
    dto/
    mappers/
    local/
    remote/
  infrastructure/
    clients/
    adapters/
    persistence/
    monitoring/
    config/

core/
  <cross-cutting-domain>/
    presentation/       # uniquement si justifié
    application/
    domain/
    data/
    infrastructure/

shared/
  domain/
  application/
  infrastructure/
  presentation/         # uniquement composants passifs et helpers non métiers
```

### 4.2 Règles d’orientation des dépendances
- `presentation` peut dépendre de `application` et de modèles de lecture explicitement exposés.
- `application` peut dépendre de `domain`.
- `domain` ne dépend que de lui-même ou de contrats très stables partagés.
- `data/infrastructure` implémentent les contrats du `domain` ou de `application`.
- Aucun widget/page ne dépend directement d’un SDK, d’un client réseau, d’un repository concret, d’un service locator ou d’un schéma de persistance.

### 4.3 Règles d’architecture bloquantes
- Pas d’import `presentation -> data`
- Pas d’import `domain -> data`
- Pas d’import `presentation -> SDK externe`
- Pas d’accès direct à `GetIt`, `slProvider` ou équivalent dans l’UI
- Pas d’import `feature -> feature` sans contrat partagé explicitement documenté
- Pas de logique métier significative dans les widgets
- Pas de dépendance circulaire
- Pas de fallback implicite non observé
- Pas de stockage de secret ou token en clair sans décision documentée et contrôlée

---

## 5. Gouvernance et operating model du programme

### 5.1 Rôles minimaux
- **Responsable programme / architecture** : arbitre l’architecture cible, tient les ADR, contrôle les frontières.
- **Responsable sûreté / risques** : classe C/L, tient le registre de risques, valide les critères d’arrêt et de rollback.
- **Responsable sécurité / données** : secrets, privilèges, données sensibles, menaces, dépendances.
- **Responsable qualité / validation** : tests, quality gates, analyse statique, index de preuves.
- **Responsable observabilité / exploitation** : logs, métriques, alertes, runbooks, rollback opératoire.
- **Référents domaine** : startup, auth, storage, player, IPTV, parental, profile, search, settings, movie, tv, library.

### 5.2 Rituels obligatoires
- revue architecture hebdomadaire ;
- revue risques hebdomadaire ;
- revue sécurité bihebdomadaire ;
- revue quality gates sur chaque lot ;
- revue de readiness avant tout lot C1 ;
- revue de sortie de phase avec artefacts et preuves.

### 5.3 Règles de décision
- toute décision structurante laisse un **ADR** ;
- tout lot C1/C2 dispose d’une analyse de risque ;
- toute réduction de contrôle standard passe par **dérogation** ;
- aucun lot n’entre en exécution sans objectif, périmètre, invariants, tests, rollback, critères d’arrêt et sortie attendue.

---

## 6. Artefacts obligatoires du programme

### 6.1 Dossier documentaire minimum

```text
docs/
  README_refactor_program.md
  architecture/
    current_state.md
    target_architecture.md
    module_boundaries.md
    dependency_rules.md
    adr/
  risk/
    system_risk_register.md
    component_criticality.md
    failure_modes.md
    hazard_analysis.md
  quality/
    test_strategy.md
    quality_gates.md
    static_analysis_policy.md
    validation_evidence_index.md
    review_policy.md
  operations/
    rollback_strategy.md
    observability_plan.md
    deployment_plan.md
    runbooks/
  security/
    threat_model.md
    secret_inventory.md
    privilege_matrix.md
    dependency_policy.md
    vulnerability_register.md
  migration/
    storage_migrations.md
    compatibility_matrix.md
    data_retention_and_privacy.md
  traceability/
    requirements_traceability.md
    change_logbook.md
    exceptions_register.md
    verification_matrix.md
  templates/
    adr_template.md
    risk_assessment_template.md
    waiver_template.md
    rollback_template.md
    independent_verification_template.md
    postmortem_template.md
```

### 6.2 Fichiers racine à qualifier ou créer
- `pubspec.yaml`
- `analysis_options.yaml`
- `README.md`
- `CHANGELOG.md`
- scripts de qualité
- scripts de release
- workflows CI/CD
- inventaire dépendances / SBOM ou équivalent
- politique de versionning et de pinning

### 6.3 Index de preuves attendu
Chaque lot significatif doit alimenter l’index de preuves avec :
- besoin / ticket / exigence ;
- criticité ;
- composants touchés ;
- risques ;
- fichiers modifiés ;
- tests ;
- validation ;
- reviewers ;
- rollback ;
- dérogations éventuelles.

---

## 7. Definition of Ready et Definition of Done

### 7.1 Definition of Ready d’un lot
Un lot est **READY** uniquement si :
- le besoin est formulé ;
- le périmètre est borné ;
- la criticité est classée ;
- les composants impactés sont identifiés ;
- les invariants à préserver sont listés ;
- le risque initial est documenté ;
- le plan de tests est défini ;
- le rollback est défini ;
- les critères d’arrêt sont définis ;
- la validation indépendante requise est planifiée.

### 7.2 Definition of Done d’un lot
Un lot est **DONE** uniquement si :
- les changements sont traçables ;
- les frontières d’architecture visées sont respectées ;
- les tests prévus existent et sont verts ;
- l’analyse statique est verte ;
- la documentation obligatoire est mise à jour ;
- l’observabilité exigée est en place ;
- le rollback est testable ou justifié ;
- la revue requise est faite ;
- les risques résiduels sont visibles ;
- les dérogations éventuelles sont formelles et non expirées.

---

## 8. Template standard de lot de refactor

Chaque lot doit suivre la structure suivante :

```text
Lot ID :
Titre :
Objectif :
Criticité :
Classe(s) composant(s) :
Périmètre :
Fichiers / modules concernés :
Invariants à préserver :
Hypothèses prudentes :
Risques principaux :
Surface exposée :
Détectabilité :
Mitigation :
Containment :
Rollback :
Critères d’arrêt :
Tests requis :
Observabilité requise :
Documentation à mettre à jour :
Validation indépendante recommandée / requise :
Conditions de sortie :
Points non vérifiés :
```

---

## 9. Roadmap maître du programme

Le programme doit être mené en **phases séquencées**, avec lots cohérents, jamais en big bang.

### Vue synthétique
1. Phase 0 — Baseline, inventaire, gel et photographie du système
2. Phase 1 — Qualification sécurité / données / risques / criticité
3. Phase 2 — Mur de dépendances et gel des violations futures
4. Phase 3 — Inventaire des flux critiques et des invariants
5. Phase 4 — Refondation du noyau critique (startup, auth, storage, network, parental)
6. Phase 5 — Reprise player / IPTV / flux média
7. Phase 6 — Décomposition des monolithes applicatifs et UI
8. Phase 7 — Gestion d’erreurs, résilience, modes dégradés
9. Phase 8 — Observabilité, diagnostic, exploitation
10. Phase 9 — Tests, validation indépendante, non-régression
11. Phase 10 — Supply chain, CI/CD, release, rollback, packaging
12. Phase 11 — Documentation vivante, runbooks, traçabilité complète
13. Phase 12 — Qualification finale et readiness de release

---

## 10. Phase 0 — Baseline, gel, inventaire et preuve initiale

### Objectif
Produire une photographie opposable de l’existant et empêcher toute aggravation structurelle non tracée.

### Entrées requises
- dépôt complet ;
- historique incidents/anomalies ;
- plateformes supportées ;
- dépendances actuelles ;
- pipelines existants ;
- documentation actuelle.

### Travaux obligatoires
1. Geler la branche principale du programme.
2. Capturer l’arborescence complète du dépôt.
3. Inventorier dépendances internes/externes.
4. Lister les plateformes et versions réellement supportées.
5. Capturer l’état de l’analyse statique, des tests, du build, du packaging.
6. Produire une première cartographie C/L par domaine.
7. Lister les workflows CI/CD et scripts de release existants.
8. Établir la liste initiale des violations d’architecture.
9. Identifier les zones sans preuve.

### Livrables
- `docs/architecture/current_state.md`
- `docs/risk/component_criticality.md`
- `docs/traceability/change_logbook.md`
- `docs/quality/validation_evidence_index.md`
- baseline analyse statique / tests / build / packaging

### Gate de sortie
La phase ne se clôture que si l’équipe sait précisément :
- ce qui existe ;
- ce qui est critique ;
- ce qui est supporté ;
- ce qui manque ;
- ce qui n’est pas prouvé.

### Critères d’arrêt
- dépôt incomplet ;
- plateformes inconnues ;
- absence de baseline fiable ;
- incapacité à classer les composants critiques.

---

## 11. Phase 1 — Qualification sécurité, données, risques et criticité

### Objectif
Ramener sous contrôle la connaissance du risque système avant de modifier le noyau du produit.

### Travaux obligatoires
1. Construire le registre de risques système.
2. Identifier secrets, tokens, sessions, identifiants, PII et données sensibles.
3. Cartographier privilèges, accès externes, dépendances critiques.
4. Analyser les modes d’échec du startup, auth, network, storage, player, IPTV, parental.
5. Définir les états sûrs attendus en cas d’échec partiel.
6. Identifier les kill switches / feature flags requis.

### Livrables
- `docs/security/threat_model.md`
- `docs/security/secret_inventory.md`
- `docs/security/privilege_matrix.md`
- `docs/risk/system_risk_register.md`
- `docs/risk/hazard_analysis.md`
- `docs/risk/failure_modes.md`

### Gate de sortie
Aucun risque C1 connu ne doit rester non visible, non classé, sans stratégie de mitigation, containment, rollback et détectabilité.

### Critères d’arrêt
- token/secret en clair sans décision immédiate ;
- zone L1 non classée ;
- menace évidente non traitée ou non documentée.

---

## 12. Phase 2 — Mur de dépendances et gel des violations futures

### Objectif
Empêcher toute aggravation de l’architecture avant même de corriger l’existant.

### Travaux obligatoires
1. Définir les règles d’import autorisées par couche.
2. Mettre en place des contrôles automatiques des imports interdits.
3. Interdire en CI :
   - `presentation -> data`
   - `domain -> data`
   - `presentation -> SDK externe`
   - `feature -> feature` hors contrats approuvés
4. Interdire l’accès direct au locator en pages/widgets/controllers UI.
5. Produire un rapport des violations restantes.
6. Classer ces violations par criticité et coût de correction.

### Livrables
- `docs/architecture/dependency_rules.md`
- scripts / lint de contrôle d’architecture
- rapport initial des violations

### Gate de sortie
Aucun nouveau code ne doit pouvoir réintroduire une violation bloquante.

### Critères d’arrêt
- règles non automatisées ;
- violations nouvelles encore acceptées ;
- impossibilité de mesurer l’évolution du graphe de dépendances.

---

## 13. Phase 3 — Inventaire des flux critiques et des invariants

### Objectif
Définir ce qui ne doit pas casser avant de refactorer structurellement.

### Flux minimaux à modéliser
- démarrage applicatif ;
- restauration de session ;
- authentification / déconnexion ;
- sélection et lecture d’une source vidéo ;
- résolution movie/tv ;
- profils et restrictions parentales ;
- synchronisation locale/cloud ;
- settings impactant le runtime ;
- diagnostics et remontée de problèmes.

### Pour chaque flux
Documenter :
- préconditions ;
- transitions d’état ;
- invariants ;
- effets de bord ;
- erreurs nominales et anormales ;
- état sûr ;
- observabilité ;
- tests requis ;
- rollback possible.

### Livrables
- `docs/traceability/requirements_traceability.md`
- `docs/traceability/verification_matrix.md`
- matrice des invariants et non-régressions critiques

### Gate de sortie
Aucun lot critique ne démarre sans invariants formalisés et scénarios de non-régression associés.

---

## 14. Phase 4 — Refondation du noyau critique

### Objectif
Stabiliser les domaines L1 avant tout refactor large de surface.

### Ordre recommandé
1. `core/startup`
2. `core/auth`
3. `core/storage`
4. `core/network`
5. `core/parental`
6. `core/profile` si impact sur sécurité ou données

### Principes d’exécution
- contracts first ;
- side effects encapsulated ;
- transitions d’état explicites ;
- pas de mélange UI / logique métier / infrastructure ;
- un lot par sous-domaine critique.

### Travaux obligatoires
1. Extraire ou clarifier les contrats du domaine.
2. Déplacer les appels SDK/DB/HTTP vers `data`/`infrastructure`.
3. Introduire use cases / orchestrators / policies pour les flux critiques.
4. Encapsuler la DI au niveau module.
5. Remplacer les accès directs UI aux implémentations concrètes.
6. Ajouter tests de non-régression avant découpage lourd.

### Livrables
- ADR par frontière critique ;
- ports/adapters introduits ;
- lot de tests correspondant ;
- rollback documenté par sous-domaine.

### Gate de sortie
- réduction mesurable des dépendances interdites ;
- contrats explicités ;
- comportement critique nominal et dégradé couvert par tests adaptés.

### Critères d’arrêt
- régression startup/auth ;
- perte de données locales ;
- stockage sensible non maîtrisé ;
- rollback non démontrable.

---

## 15. Phase 5 — Reprise player / IPTV / flux média

### Objectif
Traiter les zones où erreurs de séquencement, de réseau, de restrictions parentales et de lecture peuvent produire des incidents utilisateurs majeurs.

### Travaux obligatoires
1. Clarifier les contrats de source média.
2. Isoler résolution de source, contrôle parental, reprise, historique, préférences et télémétrie.
3. Encadrer timeouts, offline, latence, indisponibilité partielle.
4. Définir les états sûrs de lecture et d’échec.
5. Renforcer les tests d’intégration et E2E sur les parcours média.

### Livrables
- ADR flux média
- spécification des transitions d’état player
- plan de tests player/IPTV
- runbook incident de lecture

### Gate de sortie
Lecture nominale, panne réseau, source invalide, restriction parentale et reprise doivent être observables et testées.

---

## 16. Phase 6 — Décomposition des monolithes applicatifs et UI

### Objectif
Réduire la complexité et rendre les composants remplaçables, lisibles et testables.

### Candidats prioritaires
- `core/startup/app_launch_orchestrator.dart`
- `features/player/presentation/pages/video_player_page.dart`
- `features/movie/presentation/pages/movie_detail_page.dart`
- `features/tv/presentation/pages/tv_detail_page.dart`
- `features/settings/presentation/pages/settings_page.dart`
- `features/home/presentation/widgets/home_hero_carousel.dart`
- tout fichier dépassant les seuils retenus par la politique statique

### Stratégie de découpage
- isoler orchestration, état, validation, mapping, side effects et UI ;
- convertir les widgets massifs en sections passives ;
- déplacer logique métier vers `application`/`domain` ;
- supprimer code mort et contrats incohérents ;
- préférer petits lots vérifiables.

### Gate de sortie
Chaque découpage doit réduire la complexité **sans** augmenter la surface de dépendances interdites.

### Critères d’arrêt
- découpage sans tests de non-régression ;
- mélange simultané refactor structurel + changement fonctionnel non borné.

---

## 17. Phase 7 — Gestion d’erreurs, résilience et modes dégradés

### Objectif
Éliminer les échecs silencieux, standardiser la taxonomie d’erreurs et rendre les fallbacks explicites.

### Travaux obligatoires
1. Définir une taxonomie commune : métier, technique, sécurité, utilisateur, intégration, données.
2. Remplacer les `catch` génériques non qualifiés sur chemins critiques.
3. Encadrer tous les appels réseau critiques avec timeout, annulation, retry contrôlé, idempotence si applicable.
4. Documenter les fallbacks autorisés.
5. Vérifier la sécurité des messages d’erreur utilisateur et des erreurs internes.
6. Tester offline, timeout, indisponibilité partielle, corruption, état partiellement initialisé.

### Livrables
- taxonomie d’erreurs documentée
- matrice des fallbacks critiques
- tests négatifs et de mode dégradé

### Gate de sortie
Aucun flux critique ne doit conserver d’échec silencieux ou de fallback implicite non observé.

---

## 18. Phase 8 — Observabilité, diagnostic et exploitation

### Objectif
Rendre les flux critiques détectables, corrélables et exploitables.

### Travaux obligatoires
1. Uniformiser le logger et bannir `debugPrint`/`print` sur chemins critiques de production.
2. Définir les événements structurés minimum pour startup, auth, profile, player, IPTV, sync, parental, diagnostics.
3. Ajouter métriques minimales :
   - taux d’échec des opérations critiques ;
   - taux de crash ;
   - latence des appels clés ;
   - disponibilité des dépendances externes ;
   - volume d’erreurs par catégorie.
4. Garantir corrélation sans fuite de données sensibles.
5. Mettre à jour runbooks, alertes et procédures de diagnostic.

### Livrables
- `docs/operations/observability_plan.md`
- `docs/operations/runbooks/*`
- matrice événements / métriques / alertes

### Gate de sortie
Chaque flux critique doit produire une trace exploitable, diagnostiquer un échec et respecter la confidentialité.

---

## 19. Phase 9 — Tests, validation indépendante et preuve de non-régression

### Objectif
Construire une chaîne de preuve opposable au niveau de criticité du programme.

### Travaux obligatoires
1. Réorganiser `test/` selon la pyramide : unitaires, widget/composant, intégration, E2E.
2. Associer chaque flux critique à scénarios nominaux, négatifs et limites.
3. Ajouter un test de non-régression par bug corrigé.
4. Définir les seuils minimaux par domaine critique.
5. Pour les lots C1/L1, prévoir selon le cas :
   - tests de migration ;
   - tests de rollback ;
   - tests de défaillance contrôlée ;
   - tests sécurité ciblés ;
   - compatibilité environnementale.
6. Définir la validation indépendante : périmètre, responsable, livrable, critères de rejet.

### Livrables
- `docs/quality/test_strategy.md`
- `docs/traceability/verification_matrix.md`
- suites de tests par lot
- comptes-rendus de validation indépendante

### Gate de sortie
Aucun lot C1/C2 ne passe sans tests adaptés, non-régression démontrée et validation indépendante requise.

---

## 20. Phase 10 — Supply chain, qualité statique, CI/CD, release et rollback

### Objectif
Rendre les contrôles automatiques, les dépendances et la release traçables et reproductibles.

### Travaux obligatoires
1. Durcir `analysis_options.yaml`.
2. Traiter warnings critiques comme erreurs.
3. Définir seuils de complexité, taille, duplication.
4. Inventorier et justifier les dépendances ; produire une SBOM ou équivalent si applicable.
5. Établir version pinning / stratégie d’upgrade.
6. Construire un pipeline minimal obligatoire : installation, dépendances, analyse statique, tests, build reproductible, packaging traçable.
7. Versionner les scripts de release, changelog, rollback, déploiement.

### Livrables
- `docs/quality/quality_gates.md`
- `docs/security/dependency_policy.md`
- `docs/operations/deployment_plan.md`
- scripts CI/CD et qualité
- inventaire dépendances / SBOM

### Gate de sortie
Aucune release ne peut être envisagée sans pipeline vert, artefacts complets et rollback défini.

---

## 21. Phase 11 — Documentation vivante, runbooks et traçabilité complète

### Objectif
Rendre le projet transmissible, exploitable et auditable sans dépendre de la mémoire orale de l’équipe.

### Travaux obligatoires
1. Mettre à jour README, architecture, ADR, runbooks, rollback, migration.
2. Maintenir la matrice de traçabilité besoins ↔ code ↔ risques ↔ tests ↔ validation.
3. Tenir un journal des changements structurels et des dérogations.
4. Préparer la documentation d’exploitation et de support incident.

### Gate de sortie
Toute divergence connue entre code et documentation doit être identifiée comme dette explicite et tracée.

---

## 22. Phase 12 — Qualification finale et readiness de release

### Objectif
Décider honnêtement si le produit peut être qualifié pour une release selon le niveau de preuve disponible.

### Checklist de qualification finale
- quality gates verts ;
- risques résiduels connus et approuvés ;
- défauts C1/C2 non acceptés absents ;
- rollback prêt ;
- observabilité minimale présente ;
- migrations validées ;
- documentation critique à jour ;
- dérogations formelles non expirées ;
- validation indépendante requise disponible ;
- index de preuves complet.

### Verdicts possibles
- **CONFORME SOUS RÉSERVE DE VALIDATION**
- **PARTIELLEMENT CONFORME**
- **NON CONFORME**
- **DÉROGATION FORMELLE REQUISE**

### Interdictions
- pas de qualification “conforme” sans preuve suffisante ;
- pas de release si pipeline non vert ;
- pas de release avec migration non validée ;
- pas de release avec risque résiduel critique non approuvé.

---

## 23. Ordre concret recommandé pour Movi

### Priorité absolue P0/P1
1. `core/startup`
2. `core/auth`
3. `core/storage`
4. `core/network`
5. `core/security`
6. `core/parental`
7. `features/player`
8. `features/iptv`

### Priorité élevée P2
9. `core/profile`
10. `features/settings`
11. `features/library`
12. `features/search`
13. `features/welcome`

### Priorité modérée P3
14. `features/movie`
15. `features/tv`
16. `features/home`
17. `shared/*` hors utilitaires critiques

### Règle d’arbitrage
Toujours traiter d’abord ce qui :
- réduit le risque structurel ;
- réduit la surface d’effet de bord ;
- réduit l’exposition sécurité/données ;
- améliore la testabilité ;
- facilite les lots suivants.

---

## 24. Anti-patterns explicitement interdits pendant le programme

- déplacer la logique métier vers l’UI ou l’infrastructure ;
- introduire une dépendance circulaire ;
- laisser un fallback implicite non observé ;
- ajouter un SDK en accès direct depuis la présentation ;
- masquer une erreur au nom du « best effort » sans observabilité ;
- mélanger refactor massif, migration de données et changement fonctionnel non borné dans un même lot ;
- conserver du code mort en commentaire ;
- ajouter une dépendance sans justification ;
- déclarer un changement prêt sans preuve ;
- affaiblir un contrôle sans dérogation formelle.

---

## 25. Métriques de pilotage recommandées

### 25.1 Structure
- nombre d’imports interdits restants ;
- nombre de dépendances feature → feature ;
- nombre d’accès directs au locator depuis l’UI ;
- nombre de fichiers au-dessus des seuils de complexité / volumétrie.

### 25.2 Qualité
- taux de tests par type ;
- nombre de warnings bloquants ;
- taux de non-régression sur flux critiques ;
- temps de build et stabilité du pipeline.

### 25.3 Risque et exploitation
- volume d’erreurs critiques par catégorie ;
- taux d’échec auth/startup/player ;
- latence des dépendances externes ;
- taux de crash ;
- nombre de dérogations ouvertes / expirées.

---

## 26. Dérogations

Toute dérogation au programme ou au référentiel doit contenir :
- règle contournée ;
- justification ;
- risque accepté ;
- portée ;
- responsable ;
- date d’expiration ;
- plan de retour en conformité.

Aucune dérogation implicite n’est admise.

---

## 27. Conditions de réussite du programme

Le programme ne peut être considéré comme réussi que si, à la fin :
- les frontières d’architecture sont mesurables et tenues ;
- les domaines critiques sont stabilisés et documentés ;
- les données sensibles sont traitées selon une politique explicite ;
- les flux critiques sont testés nominalement et en dégradé ;
- l’observabilité minimale est en place ;
- la documentation et le rollback sont opérationnels ;
- les quality gates sont automatisés ;
- les preuves sont indexées ;
- les risques résiduels sont connus et approuvés.

---

## 28. Verdict sur ce document

### Valeur du document
Cette v3 est un **plan de transformation plus strictement aligné** avec `rules_nasa.md` que les versions précédentes. Elle ajoute :
- qualification explicite ;
- DoR / DoD ;
- template standard de lot ;
- gates de sortie ;
- critères d’arrêt ;
- operating model ;
- conditions de réussite ;
- séquencement renforcé du noyau critique ;
- articulation plus directe avec la preuve, la traçabilité et la release.

### Limite honnête
Ce document reste un **plan**. Il ne remplace ni l’audit complet du dépôt, ni la production des artefacts, ni l’exécution prouvée des tests, ni la validation indépendante.

### Verdict
**CONFORME SOUS RÉSERVE DE VALIDATION DOCUMENTAIRE**

Ce verdict signifie :
- le document est cohérent avec le référentiel comme plan directeur ;
- la conformité du projet Movi lui-même reste à démontrer par exécution du programme et production de preuves.

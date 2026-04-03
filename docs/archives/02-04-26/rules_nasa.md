# RÈGLES D’INGÉNIERIE LOGICIELLE — HAUTE ASSURANCE  
## Référentiel mission-grade inspiré NASA / NIST

## 0. Objet

Ce document définit les exigences minimales de qualité, sûreté, sécurité, fiabilité et traçabilité applicables à tout logiciel livré dans un contexte à enjeu élevé.

L’objectif n’est pas seulement de produire du code fonctionnel, mais de produire un système :
- vérifiable,
- traçable,
- auditable,
- résilient,
- maintenable,
- exploitable en conditions dégradées.

Toute exigence non respectée doit être :
- identifiée,
- tracée,
- justifiée,
- approuvée,
- datée,
- assortie d’un plan de correction.

---

## 1. Portée

Ces règles s’appliquent à :
- tout le code applicatif,
- les scripts,
- la configuration,
- les migrations,
- les tests,
- l’observabilité,
- les pipelines CI/CD,
- les composants tiers,
- l’infrastructure définie comme code,
- toute modification : feature, bugfix, refactor, suppression, dette technique.

Elles s’appliquent à tous les environnements supportés :
- développement,
- intégration,
- staging,
- production.

---

## 2. Principes directeurs

1. **La sûreté, la sécurité et la correction priment sur la vitesse d’exécution du projet.**
2. **Aucun changement critique n’est accepté sans preuve suffisante.**
3. **Toute exigence importante doit être reliée à une implémentation et à une vérification.**
4. **Tout comportement non déterministe, implicite ou non observé est présumé risqué.**
5. **Toute dérogation est temporaire et explicitement acceptée.**

---

## 3. Classification de criticité

### 3.1 Criticité de changement

- **C1 — Critique**  
  Impact possible sur : sécurité, confidentialité, auth, paiement, intégrité des données, corruption, crash au démarrage, indisponibilité majeure, exécution de commande non autorisée.

- **C2 — Élevé**  
  Régression majeure, blocage utilisateur, perte partielle de fonctionnalité critique, dégradation importante de performance ou de fiabilité.

- **C3 — Modéré**  
  Défaut non bloquant avec impact sur UX, maintenabilité, observabilité, performance secondaire ou robustesse locale.

- **C4 — Mineur**  
  Cosmétique, wording, nettoyage local, amélioration sans impact fonctionnel significatif.

### 3.2 Classe logicielle interne

Chaque composant doit être classé selon son impact métier et opérationnel :

- **L1 — Safety / Security / Data Critical**
- **L2 — Business Critical**
- **L3 — Supporting**
- **L4 — Non critical / internal convenience**

Le niveau de preuve, de revue et de test augmente avec la classe.

---

## 4. Règle d’or

Une release n’est autorisée que si :
- aucun défaut **C1** ou **C2** ouvert n’est accepté sans dérogation formelle,
- tous les **Quality Gates** sont verts,
- les risques résiduels sont connus, visibles et approuvés,
- la capacité de rollback ou de mitigation est démontrée.

**No green pipeline, no release.**  
**No evidence, no merge.**

---

## 5. Architecture et séparation des responsabilités

- La logique métier ne dépend jamais directement :
  - de l’UI,
  - de la base de données,
  - du framework,
  - d’un SDK externe,
  - d’un détail d’infrastructure.
- Les dépendances pointent vers des abstractions stables.
- Un module porte une responsabilité explicite et limitée.
- Les dépendances circulaires sont interdites.
- Toute logique métier localisée hors de la couche métier doit être extraite ou justifiée.
- Les effets de bord doivent être contenus et identifiables.
- Toute décision d’architecture non triviale doit laisser une trace.

---

## 6. Exigences et traçabilité

Tout changement significatif doit être relié à :
- une exigence,
- un ticket,
- une anomalie,
- une décision d’architecture,
- ou un besoin opérationnel documenté.

### 6.1 Traçabilité minimale

Pour chaque changement significatif, il doit exister un lien entre :
- **source de besoin**,
- **composant modifié**,
- **tests associés**,
- **risques identifiés**,
- **evidence de validation**.

### 6.2 Exigences critiques

Toute exigence critique doit être couverte par au moins :
- un test automatisé,
- une vérification indépendante adaptée au niveau de criticité,
- une preuve d’observabilité ou de détection en production si applicable.

---

## 7. Tailoring et niveau d’exigence

Le niveau d’application des règles dépend de :
- la criticité du changement,
- la classe logicielle du composant,
- l’exposition sécurité,
- l’impact sur les données,
- la difficulté de rollback,
- le caractère réversible ou non du changement.

Toute réduction de contrôle standard doit être considérée comme une dérogation.

---

## 8. Gestion des risques

Tout changement **C1** ou **C2** doit inclure une analyse de risque documentée comprenant :
- cause probable d’échec,
- impact maximal,
- surface exposée,
- détectabilité,
- stratégie de mitigation,
- stratégie de containment,
- stratégie de rollback,
- critères d’arrêt ou de désactivation.

Les risques non résolus doivent être visibles avant merge et avant release.

---

## 9. Sûreté logicielle et composants safety-critical

Pour tout composant **L1** ou tout changement pouvant produire un état dangereux, il faut documenter :
- le danger redouté,
- les conditions d’activation,
- les barrières logiques ou opérationnelles,
- l’état sûr attendu,
- les mécanismes empêchant une action unique d’entraîner un dommage majeur.

Exigences minimales :
- pas de commande dangereuse sans contrôle explicite,
- pas d’hypothèse non vérifiée sur l’état système,
- pas de dépendance cachée à l’ordre d’exécution,
- transitions d’état explicites et vérifiables,
- comportement sûr en cas d’échec partiel,
- journalisation exploitable des événements critiques.

---

## 10. Standards de code

- Le code lisible prime sur le code “astucieux”.
- Les fonctions doivent rester courtes, cohérentes et à intention claire.
- Les noms doivent être explicites et porter le vocabulaire métier.
- Sont interdits comme noms génériques sans contexte :
  - `data`,
  - `temp`,
  - `obj`,
  - `thing`,
  - `misc`,
  - `manager`.
- Les commentaires expliquent le **pourquoi**, pas l’évidence.
- Le code mort doit être supprimé, jamais conservé en commentaire.
- Les conventions de style doivent être automatiques et homogènes.
- Toute complexité excessive déclenche refactor ou justification.

---

## 11. Gestion des erreurs, résilience et modes dégradés

- Les erreurs doivent être catégorisées :
  - métier,
  - technique,
  - sécurité,
  - utilisateur,
  - intégration,
  - données.
- Tout appel réseau doit gérer :
  - timeout,
  - annulation,
  - retry contrôlé,
  - idempotence si nécessaire.
- Aucun échec silencieux n’est acceptable sur un chemin critique.
- Les fallbacks doivent être :
  - explicites,
  - prévisibles,
  - testés,
  - observables.
- Les messages d’erreur utilisateur doivent être compréhensibles et actionnables.
- Les erreurs internes doivent préserver le diagnostic sans exposer d’information sensible.

---

## 12. Sécurité applicative

- Aucun secret dans le code, la configuration versionnée, les logs ou l’historique Git.
- Validation stricte des entrées.
- Encodage ou échappement adapté des sorties.
- Principe du moindre privilège sur tous les accès :
  - API,
  - DB,
  - filesystems,
  - queues,
  - services tiers.
- Authentification et autorisation testées sur :
  - chemin nominal,
  - contournement,
  - élévation de privilège,
  - accès indirect,
  - multi-tenant si applicable.
- Toute vulnérabilité connue doit être traitée selon sa criticité.
- Les dépendances tierces doivent être évaluées avant introduction.

---

## 13. Données et confidentialité

- Les données sensibles sont protégées en transit et au repos.
- Les logs, traces et exports ne doivent jamais exposer :
  - token,
  - mot de passe,
  - secret,
  - PII en clair,
  - donnée sensible inutile au diagnostic.
- La collecte de données doit être minimisée.
- La rétention doit suivre la politique projet ou réglementaire.
- Les migrations et transformations de données doivent être :
  - sûres,
  - traçables,
  - testées,
  - idempotentes si possible.

---

## 14. Observabilité et diagnostic

Tout service ou composant critique doit fournir :
- logs structurés,
- corrélation de requête ou d’opération,
- événements métiers importants,
- métriques de santé,
- détection d’erreurs exploitables.

### 14.1 Minimum requis

- taux d’échec des opérations critiques,
- taux de crash,
- latence des API ou opérations clés,
- disponibilité des dépendances externes,
- volume d’erreurs par catégorie.

### 14.2 Diagnostic

- Les erreurs critiques doivent produire une trace exploitable.
- Les événements critiques doivent être corrélables à :
  - utilisateur,
  - feature,
  - action,
  - composant,
  - résultat,
  dans le respect de la confidentialité.

---

## 15. Tests automatisés

La pyramide de tests est obligatoire :

- **unitaires** pour la logique métier,
- **tests de composant / widget / interface** pour les comportements clés,
- **intégration** pour les contrats et flux inter-composants,
- **E2E** pour les parcours critiques.

### 15.1 Exigences minimales

- Les tests doivent être :
  - déterministes,
  - isolés,
  - lisibles,
  - rapides autant que raisonnable,
  - non fragiles.
- Tout bug corrigé doit ajouter au moins un test de non-régression.
- Aucun changement **C1/C2** ne peut être mergé sans tests adaptés.
- Les mocks excessifs sur logique métier critique sont interdits.
- Les scénarios négatifs et limites doivent être couverts sur les chemins critiques.

### 15.2 Preuves renforcées pour C1 / L1

Pour un changement à fort enjeu, prévoir selon le cas :
- tests de charge ciblés,
- tests de chaos ou de défaillance contrôlée,
- tests de sécurité,
- tests de migration,
- tests de rollback,
- tests de compatibilité environnementale.

---

## 16. Revue technique et vérification indépendante

### 16.1 Revue par pair

Tout merge nécessite au minimum une revue par pair.

### 16.2 Contrôle renforcé

Tout changement **C1** ou impactant un composant **L1** nécessite :
- **2 reviewers minimum**,
- dont **au moins 1 indépendant de l’auteur**,
- et, si possible, **1 reviewer non impliqué dans l’implémentation initiale du composant**.

### 16.3 Vérification indépendante

Les changements les plus sensibles doivent faire l’objet d’une vérification indépendante portant sur :
- conformité à l’exigence,
- sécurité,
- robustesse,
- testabilité,
- dette introduite,
- performance,
- exploitabilité,
- conformité au plan de rollback.

Aucun point bloquant ne peut être reporté sans dérogation formelle.

---

## 17. Qualité statique

- Lint et analyse statique sont exécutés en CI à chaque PR.
- Les warnings critiques sont traités comme des erreurs.
- Le formatter est obligatoire et automatique.
- Toute fonction ou classe dépassant les seuils de complexité définis doit être refactorée ou justifiée.
- Les règles de qualité doivent être versionnées et appliquées uniformément.

---

## 18. Dépendances et supply chain

- L’inventaire des dépendances doit être maintenu.
- Toute nouvelle dépendance doit être justifiée par :
  - le besoin,
  - l’alternative écartée,
  - la surface de risque,
  - la maintenance attendue,
  - la licence,
  - l’impact sécurité.
- Le version pinning ou le contrôle d’upgrade est obligatoire.
- Les dépendances inutilisées doivent être supprimées.
- Les vulnérabilités connues doivent être suivies et priorisées.
- Une **SBOM** ou un inventaire équivalent doit pouvoir être produit pour les livrables critiques.

---

## 19. Configuration et environnement

- Toute configuration critique doit être explicite.
- Aucune valeur implicite dangereuse n’est acceptable.
- Les comportements diffèrent par environnement de manière documentée.
- Les flags dangereux sont interdits en production par défaut.
- Les fonctionnalités expérimentales doivent être isolées par feature flags.
- Les secrets et paramètres sensibles doivent être injectés via un mécanisme approuvé.

---

## 20. CI/CD et discipline de release

Le pipeline minimal obligatoire comprend :
- installation,
- résolution contrôlée des dépendances,
- analyse statique,
- tests,
- build reproductible,
- packaging traçable.

### 20.1 Release

Toute release doit être :
- taguée,
- traçable,
- reproductible,
- associée à un changelog,
- associée à un plan de rollback,
- associée à un niveau de risque connu.

### 20.2 Changelog minimal

- breaking changes,
- migrations,
- risques connus,
- limitations,
- dépendances affectées,
- actions opératoires éventuelles.

---

## 21. Compatibilité et robustesse runtime

- Tester les plateformes réellement supportées.
- Tester les versions réellement ciblées.
- Gérer explicitement :
  - offline,
  - latence élevée,
  - timeouts,
  - redémarrages,
  - interruptions système,
  - indisponibilité partielle de dépendance.
- Aucune hypothèse fragile sur le réseau, l’horloge, l’ordre des événements ou l’état mémoire ne doit rester implicite.
- Les migrations doivent être sûres et réexécutables lorsque possible.

---

## 22. Performance et capacité

- Les parcours critiques ont des objectifs mesurables.
- Toute régression notable est bloquante avant release.
- Les opérations coûteuses doivent être instrumentées.
- Les optimisations doivent être pilotées par mesure.
- Aucun arbitrage performance vs sûreté ne peut être pris implicitement.

---

## 23. Documentation vivante

Doivent être tenus à jour selon le niveau de criticité :
- README,
- documentation technique,
- documentation d’exploitation,
- ADR,
- runbooks,
- procédures de rollback,
- guides de migration.

Toute divergence connue entre code et documentation constitue une dette explicite.

---

## 24. Gestion des défauts et incidents

Chaque incident doit produire au minimum :
- un ticket,
- une sévérité,
- une description d’impact,
- une cause racine ou hypothèse,
- une action corrective,
- une action préventive si applicable.

### 24.1 Post-mortem

Un post-mortem est obligatoire pour :
- tout incident **C1**,
- tout incident répété,
- tout incident révélant une faiblesse systémique.

Les actions décidées doivent être suivies jusqu’à clôture.

---

## 25. Artefacts de preuve obligatoires

Pour tout changement significatif, les éléments suivants doivent pouvoir être retrouvés :

- exigence ou ticket lié,
- classification de criticité,
- analyse de risque si requise,
- preuves de test,
- résultat CI,
- reviewers,
- documentation associée,
- dérogations éventuelles,
- stratégie de rollback.

Pour les changements critiques, ajouter si applicable :
- ADR,
- check de sécurité,
- résultats de scan dépendances,
- preuve de compatibilité,
- plan de déploiement,
- plan d’observabilité,
- preuve de validation indépendante.

---

## 26. Dérogations

Toute dérogation doit inclure :
- la règle contournée,
- la justification,
- le risque accepté,
- la portée,
- le responsable,
- la date d’expiration,
- le plan de retour en conformité.

Une dérogation expirée rend le changement non conforme.

Aucune dérogation ne peut être implicite, orale ou indatable.

---

## 27. Quality Gates bloquants

Le merge est interdit si l’un des points suivants échoue :

- analyse statique en échec,
- tests automatisés en échec,
- absence de tests pour un changement **C1/C2**,
- reviewer requis manquant,
- documentation critique absente,
- vulnérabilité élevée non traitée ou non dérogée,
- rollback non défini pour changement à risque,
- traçabilité insuffisante,
- dérogation requise mais absente.

La release est interdite si l’un des points suivants échoue :

- pipeline non vert,
- incident critique ouvert non approuvé,
- observabilité minimale absente,
- migration non validée,
- artefacts de release incomplets,
- risque résiduel non approuvé.

---

## Annexe A — Checklist PR rapide

- [ ] Exigence / ticket lié
- [ ] Criticité évaluée
- [ ] Risques identifiés
- [ ] Rollback défini
- [ ] Tests ajoutés ou ajustés
- [ ] Non-régression couverte
- [ ] Logs / métriques / erreurs exploitables
- [ ] Aucun secret exposé
- [ ] Dépendances revues
- [ ] Documentation mise à jour
- [ ] Reviewer(s) requis présents
- [ ] Dérogation formalisée si nécessaire

---

## Annexe B — Checklist changement critique

- [ ] Analyse de risque documentée
- [ ] Impact maximal explicité
- [ ] Mode dégradé défini
- [ ] Observabilité prête avant déploiement
- [ ] Rollback ou kill switch validé
- [ ] Scénarios d’échec testés
- [ ] Vérification indépendante réalisée
- [ ] Documentation d’exploitation mise à jour
- [ ] Déploiement progressif défini si applicable

---

## Annexe C — Références de cadrage

- NASA NPR 7150.2 — Software Engineering Requirements
- NASA-STD-8739.8 — Software Assurance and Software Safety
- NASA Software Engineering Handbook
- NIST SP 800-218 — Secure Software Development Framework (SSDF)

---

## Formule de conformité

Un changement est dit **conforme** lorsqu’il satisfait :
1. les exigences applicables à son niveau de criticité,
2. les contrôles applicables à la classe du composant,
3. les quality gates,
4. les exigences de traçabilité,
5. les obligations de preuve,
6. et ne laisse aucune dérogation expirée.

À défaut, il est **non conforme**.
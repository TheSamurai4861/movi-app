# Roadmap — Phase 1 : Qualification sécurité, données, risques et criticité

## Références et conformité
- **Plan source** : `movi_nasa_refactor_plan_v3.md` — Phase 1 (Qualification sécurité, données, risques et criticité).
- **Règles applicables** : `docs/rules_nasa.md` (preuve, traçabilité, quality gates, gestion des risques).
- **Traçabilité changement** : `docs/traceability/change_logbook.md` (entrées à ajouter pour chaque modification).
- **Index des preuves** : `docs/quality/validation_evidence_index.md` (référencer chaque preuve produite).

## Objectif (Phase 1)
Ramener sous contrôle la connaissance du **risque système** avant de modifier le noyau du produit, afin d’éviter toute modification **C1/C2** sans visibilité, mitigation, rollback et détectabilité.

## Périmètre
### Composants / zones minimales à couvrir
- **Startup / orchestration de démarrage**
- **Auth / session**
- **Network**
- **Storage**
- **Player / playback**
- **IPTV**
- **Parental / profils**

### Hors périmètre (par défaut)
- Changements fonctionnels non nécessaires à la qualification (sauf si requis pour stopper un risque C1).

## Hypothèses et décisions de cadrage
- La Phase 1 est traitée comme **travail à risque élevé** : la production d’artefacts et de preuves prime sur la vitesse.
- Tout élément identifié comme **C1** déclenche une stratégie explicite : **mitigation + containment + rollback + détectabilité** (ou **dérogation formelle** selon `docs/rules_nasa.md`).

## Quality gates (bloquants)
- **No evidence, no merge** : toute action produisant/modifiant un artefact doit être référencée dans `docs/quality/validation_evidence_index.md`.
- **Traçabilité minimale** : chaque décision/artefact doit être relié à une entrée dans `docs/traceability/change_logbook.md`.
- **Stop immédiat** (critères d’arrêt Phase 1) :
  - token/secret en clair **sans décision immédiate** ;
  - zone **L1** non classée ;
  - menace évidente non traitée ou non documentée.

## Livrables attendus (issus du plan)
- `docs/security/threat_model.md`
- `docs/security/secret_inventory.md`
- `docs/security/privilege_matrix.md`
- `docs/risk/system_risk_register.md`
- `docs/risk/hazard_analysis.md`
- `docs/risk/failure_modes.md`

## Roadmap (WBS) — activités obligatoires, critères d’acceptation et preuves

### Jalon M1 — Registre de risques système sous contrôle
**But** : rendre visibles tous les risques connus, classés, et traitables.

- **Travaux**
  - Construire / compléter `docs/risk/system_risk_register.md`.
  - Définir un schéma minimal par risque : *ID, description, cause, impact, composant(s), criticité (C1–C4), détectabilité, mitigation, containment, rollback, owner, statut, date*.
  - Lier les risques aux composants critiques si possible (référence `docs/risk/component_criticality.md`).
- **Critères d’acceptation**
  - Aucun risque **C1** ne reste : **non visible**, **non classé**, **sans** mitigation/containment/rollback/détectabilité.
  - Pour chaque composant du périmètre Phase 1, au moins un statut : *risques connus* ou *analyse effectuée — aucun risque identifié (justifié)*.
- **Preuves à indexer**
  - Snapshot daté du registre (révision Git) + lien d’index dans `docs/quality/validation_evidence_index.md`.
  - Revue par pair conforme au niveau de criticité (au minimum 1 reviewer ; viser 2 si risques C1 identifiés).

### Jalon M2 — Inventaire des secrets / PII / données sensibles
**But** : éliminer l’inconnu sur l’exposition (code, config, logs, runtime).

- **Travaux**
  - Produire `docs/security/secret_inventory.md` :
    - secrets/tokens/identifiants : localisation, mode d’injection, rotation, stockage, logs, contrôles.
    - PII/données sensibles : nature, minimisation, transit/repos, rétention (si connue), accès.
  - Définir une politique de redaction minimale pour logs/traces si nécessaire (références ops existantes).
- **Critères d’acceptation**
  - Tout secret/PII détecté a une décision explicite : supprimer, migrer, masquer, rotation, ou dérogation formelle.
  - Aucun secret ne doit être acceptable en clair dans : repo, config versionnée, logs, traces (selon `docs/rules_nasa.md`).
- **Preuves à indexer**
  - `secret_inventory.md` versionné + entrée dans `validation_evidence_index.md`.
  - Liste des emplacements contrôlés (répertoire/clé/log event) et actions décidées.

### Jalon M3 — Matrice privilèges / accès externes / dépendances critiques
**But** : appliquer le moindre privilège et maîtriser les dépendances à risque.

- **Travaux**
  - Produire `docs/security/privilege_matrix.md` :
    - acteurs (app, modules, SDK, services) × ressources (API, storage, filesystem, analytics, IPTV, etc.)
    - niveau d’accès, justification, environnement(s), données manipulées.
  - Cartographier les dépendances critiques externes (API, services, SDK) et le mode dégradé attendu.
- **Critères d’acceptation**
  - Chaque accès externe critique a : *owner*, *justification*, *risques*, *observabilité minimale*.
  - Toute surface d’accès non justifiée est marquée comme risque et planifiée en mitigation.
- **Preuves à indexer**
  - Matrice versionnée + revue.
  - (Si applicable) preuve de conformité “moindre privilège” sur les accès majeurs (revue de config/permissions).

### Jalon M4 — Analyse des modes d’échec (startup/auth/network/storage/player/IPTV/parental)
**But** : documenter comment le système échoue, comment on le détecte, et comment il reste sûr.

- **Travaux**
  - Produire `docs/risk/failure_modes.md` couvrant au minimum :
    - conditions d’activation, symptômes, impact utilisateur/système,
    - détectabilité (logs/metrics/events),
    - mitigation/containment,
    - rollback/désactivation.
  - Produire `docs/risk/hazard_analysis.md` :
    - dangers redoutés, barrières, état sûr, transitions d’état critiques.
- **Critères d’acceptation**
  - Chaque zone du périmètre Phase 1 a au moins :
    - un mode d’échec nominal (panne réseau, timeouts, storage indispo, session invalide, etc.),
    - un scénario “échec partiel” (dépendance partielle indispo),
    - un état sûr attendu et observabilité.
- **Preuves à indexer**
  - Les documents `failure_modes.md` et `hazard_analysis.md` versionnés + revues.
  - Références croisées vers runbooks existants si pertinents (ex. `docs/operations/runbooks/`).

### Jalon M5 — États sûrs attendus et comportements dégradés explicités
**But** : éviter les comportements implicites/non observés (présumés risqués).

- **Travaux**
  - Pour chaque flux/zone : définir l’**état sûr** et la réponse (fallback, blocage, message utilisateur, retry contrôlé).
  - Définir les erreurs “catégorisées” (sécurité/données/réseau/etc.) et attentes de log/trace.
- **Critères d’acceptation**
  - Aucun échec silencieux sur chemin critique.
  - Les fallbacks sont explicites, prévisibles, testables et observables (aligné `docs/rules_nasa.md`).
- **Preuves à indexer**
  - Table de synthèse “zone → état sûr → observabilité → action opératoire”.

### Jalon M6 — Kill switches / feature flags requis identifiés
**But** : permettre containment/rollback opérationnel sans livraison lourde.

- **Travaux**
  - Produire une liste de kill switches / flags nécessaires, rattachés à :
    - risque(s) couvert(s),
    - condition d’activation,
    - effet attendu (désactivation, fallback, blocage),
    - observabilité et runbook associé.
  - Référencer où ces flags seront implémentés (si non existants) sans forcément les coder en Phase 1.
- **Critères d’acceptation**
  - Pour chaque risque **C1** où le rollback est difficile, un kill switch ou un mécanisme équivalent est défini (ou dérogé).
- **Preuves à indexer**
  - Liste versionnée + entrée de traçabilité.

## Rôles, responsabilités et revue
- **Owner Phase 1** : responsable de la complétude des livrables et de l’application des quality gates.
- **Reviewers** :
  - au minimum 1 revue par pair pour chaque livrable ;
  - viser un contrôle renforcé si risque **C1** (2 reviewers dont 1 indépendant), conformément à `docs/rules_nasa.md`.

## Gate de sortie (Phase 1)
La phase ne se clôture que si :
- **aucun risque C1 connu** ne reste non visible, non classé, **sans** mitigation/containment/rollback/détectabilité ;
- les livrables de la Phase 1 existent, sont revus, et sont indexés comme preuves ;
- les critères d’arrêt n’ont pas été déclenchés (ou ont été traités par décision immédiate et traçable).

## Check-list “fin de phase” (à cocher avant clôture)
- [ ] `docs/risk/system_risk_register.md` complété + risques C1 traités (ou dérogés formellement)
- [ ] `docs/security/secret_inventory.md` complété + décisions immédiates sur tout secret en clair
- [ ] `docs/security/privilege_matrix.md` complété + accès non justifiés traités ou planifiés
- [ ] `docs/risk/failure_modes.md` complété (startup/auth/network/storage/player/IPTV/parental)
- [ ] `docs/risk/hazard_analysis.md` complété (danger, barrières, état sûr)
- [ ] `docs/security/threat_model.md` complété (menaces majeures, surface, contrôles, détectabilité)
- [ ] Kill switches / feature flags requis listés et reliés aux risques
- [ ] Entrées ajoutées dans `docs/traceability/change_logbook.md`
- [ ] Preuves référencées dans `docs/quality/validation_evidence_index.md`


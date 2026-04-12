# PRD — Refactor Observability & Runtime Diagnostics

## 1. Contexte

Après les chantiers:

1. `1_localizations.md`
2. `2_focus.md`
3. `3_architecture_boundaries.md`
4. `4_monolith_pages_decomposition.md`
5. `5_quality_gates_and_repo_hygiene.md`
6. `6_data_contracts_and_error_boundaries.md`

le socle de code devient plus propre et plus testable. Le prochain levier est la capacité à comprendre rapidement ce qui se passe en runtime.

Le projet contient déjà des briques de diagnostics/logging, mais elles restent partielles selon les flux et les features. Le résultat est un temps de diagnostic encore trop variable, surtout sur incidents cross-layer (startup/auth/playback/sync/network).

Ce PRD formalise le chantier 7: établir une observabilité runtime cohérente, corrélée et exploitable, sans fuite de données sensibles.

---

## 2. Problème à résoudre

### 2.1 Symptômes observés

1. Corrélation incomplète des événements
   - logs de la même opération répartis sans identifiant commun systématique.

2. Signal runtime hétérogène
   - niveaux de logs et format variables selon modules.

3. Diagnostics difficiles à exploiter
   - messages parfois riches localement mais faibles globalement.

4. Frontière sensible insuffisamment explicitée
   - risque de fuite d'information technique/sensible sans policy unique.

5. Détection tardive des régressions
   - incidents parfois compris après plusieurs allers-retours manuels.

### 2.2 Causes racines

- conventions d'observabilité non uniformisées.
- absence de taxonomie d'événements runtime transverses.
- corrélation opérationnelle partielle.
- export diagnostics pas encore standardisé de bout en bout.

---

## 3. Objectifs

### 3.1 Objectif principal

Mettre en place un système d'observabilité runtime cohérent, corrélé, sécurisé et actionnable.

### 3.2 Objectifs détaillés

1. Introduire un `operationId` corrélé sur flux critiques.
2. Uniformiser la structure des événements de diagnostic.
3. Définir une policy stricte de sanitization/redaction.
4. Standardiser les niveaux de logs et le contexte minimal obligatoire.
5. Fiabiliser l'export diagnostics pour support/debug.
6. Réduire le temps moyen d'analyse d'un incident runtime.

### 3.3 KPI de succès

1. Augmentation du taux d'événements corrélés sur flux critiques.
2. Diminution du temps de triage incident.
3. 0 fuite de secrets/données sensibles dans logs/export.
4. Couverture observabilité sur parcours critiques (startup, auth, playback, sync).

---

## 4. Hors périmètre

Ne font pas partie du chantier, sauf ajustement strictement nécessaire:

- migration vers une nouvelle plateforme APM externe.
- redesign des écrans produit.
- refonte complète du stockage de logs local.
- remplacement des mécanismes de crash reporting tiers.

Le chantier porte sur l'observabilité applicative et les diagnostics runtime existants.

---

## 5. Principes directeurs

1. Chaque incident critique doit être traçable de bout en bout.
2. Les logs doivent être utiles, pas verbeux par défaut.
3. Aucune donnée sensible en clair dans les diagnostics.
4. Les conventions doivent être simples et appliquées partout.
5. L'observabilité doit aider la décision opérationnelle, pas seulement le debug local.

---

## 6. Architecture cible

## 6.1 Modèle d'événement runtime

Chaque événement doit porter au minimum:

1. `timestamp`
2. `level` (`debug/info/warn/error`)
3. `category` (startup/auth/playback/sync/network/ui)
4. `operationId` (quand applicable)
5. `message` court orienté diagnostic
6. `context` structuré non sensible
7. `errorCode`/`failureType` (si erreur)

## 6.2 Corrélation opérationnelle

Règles:

1. toute opération critique crée ou récupère un `operationId`.
2. sous-opérations réutilisent le même `operationId`.
3. transitions cross-feature conservent la corrélation.

## 6.3 Taxonomie d'événements

Familles minimales:

1. Startup journey
2. Auth/session
3. Network requests & retries
4. Playback lifecycle
5. Sync & background tasks
6. Error boundary rendering

## 6.4 Sanitization / redaction

Règles obligatoires:

1. jamais de secret/token/credential en clair.
2. jamais de payload utilisateur sensible non redigé.
3. hash ou masque sur identifiants sensibles.
4. tests dédiés de sanitization.

## 6.5 Export diagnostics

Objectifs:

1. format stable et lisible.
2. contenu corrélé par `operationId`.
3. filtrage configurable par période/catégorie/niveau.
4. versionnage format export.

---

## 7. Périmètres prioritaires (ordre)

## 7.1 Priorité P1

1. startup + bootstrap
2. auth/session
3. playback launch/resume

## 7.2 Priorité P2

1. sync library/history/playlists
2. flows IPTV connectivité
3. recherche/enrichissement

## 7.3 Priorité P3

1. uniformisation globale des catégories restantes
2. reporting opérationnel consolidé

---

## 8. Chantiers techniques prioritaires

## Lot A — Standard d'événements

Objectif:

- imposer une structure commune.

Actions:

1. définir schéma runtime event.
2. normaliser wrappers/helpers logging.
3. migrer progressivement les zones P1.

Résultat attendu:

- événements comparables et exploitables.

## Lot B — Corrélation `operationId`

Objectif:

- tracer une opération complète sans ambiguïté.

Actions:

1. générer/propager `operationId` sur flux P1.
2. relier erreurs et retries au même id.
3. tester propagation cross-layer.

Résultat attendu:

- timeline incident lisible de bout en bout.

## Lot C — Sanitization hardening

Objectif:

- empêcher fuite de données sensibles.

Actions:

1. centraliser redaction/masquage.
2. couvrir les champs sensibles connus.
3. ajouter tests de non-fuite.

Résultat attendu:

- diagnostics sûrs par défaut.

## Lot D — Export & exploitation

Objectif:

- améliorer usage concret du diagnostic.

Actions:

1. stabiliser format d'export.
2. ajouter filtres pratiques.
3. documenter guide de triage.

Résultat attendu:

- support/debug plus rapide et reproductible.

---

## 9. Backlog initial (ordre imposé)

## Epic A — Runtime event standard

Story A1:

- définir schéma événement.

Story A2:

- implémenter helpers communs.

Story A3:

- migrer flux P1.

## Epic B — Operation correlation

Story B1:

- générer `operationId` sur entrées critiques.

Story B2:

- propager `operationId` dans services/use-cases.

Story B3:

- corréler erreurs/retries.

## Epic C — Security & sanitization

Story C1:

- inventaire données sensibles.

Story C2:

- règles de redaction centralisées.

Story C3:

- tests de sanitization.

## Epic D — Diagnostics export

Story D1:

- format export versionné.

Story D2:

- filtres exploitation.

Story D3:

- documentation support.

## Epic E — Consolidation

Story E1:

- extension P2/P3.

Story E2:

- revue qualité observabilité.

Story E3:

- baseline KPI post-chantier.

---

## 10. Critères d'acceptation

## 10.1 Critères structure

1. Schéma d'événement runtime commun défini et appliqué sur périmètre migré.
2. `operationId` propagé sur flux critiques P1.
3. Sanitization centralisée et systématique.
4. Export diagnostics stable et filtrable.

## 10.2 Critères fonctionnels

1. Les parcours critiques restent fonctionnellement inchangés.
2. Les erreurs critiques incluent un contexte exploitable.
3. Les retries/logiques de récupération sont corrélés correctement.

## 10.3 Critères sécurité/qualité

1. Aucun secret en clair dans logs/export.
2. Tests de non-fuite présents sur mécanismes sensibles.
3. Régression observabilité détectable via quality gates.

---

## 11. Plan de test

## 11.1 Unit tests

À couvrir:

1. formatage événement standard.
2. propagation `operationId`.
3. sanitization champs sensibles.
4. classification des niveaux/catégories.

## 11.2 Integration/widget tests

À couvrir:

1. corrélation sur flux startup/auth/playback.
2. chaîne erreur -> boundary UI -> diagnostic.
3. export diagnostics avec filtres.

## 11.3 Non-régression manuelle

Parcours minimaux:

1. bootstrap app avec incident simulé.
2. login/session expire.
3. lancement playback puis retry.
4. sync bibliothèque avec erreur réseau.

## 11.4 Validation qualité

1. vérifier absence données sensibles dans exports test.
2. vérifier présence `operationId` sur événements P1.
3. vérifier lisibilité des messages de triage.

---

## 12. Plan de migration

## Étape 1 — Baseline observabilité

Livrables:

1. inventaire événements existants.
2. baseline KPI triage/corrélation.

## Étape 2 — Pilote P1

Livrables:

1. schéma événement + `operationId` sur startup/auth/playback.
2. tests de sanitization de base.

## Étape 3 — Extension P2

Livrables:

1. sync/IPTV/recherche alignés.
2. export diagnostics harmonisé.

## Étape 4 — Consolidation P3

Livrables:

1. uniformisation catégories restantes.
2. documentation et playbook triage final.

---

## 13. Risques et mitigations

## Risque 1 — Trop de logs, faible signal

Mitigation:

- niveaux stricts, messages courts, contexte structuré utile.

## Risque 2 — Coût perf runtime

Mitigation:

- sampling/verbosity adaptés par environnement, éviter surcharge en release.

## Risque 3 — Fuite d'informations sensibles

Mitigation:

- sanitizer central + tests dédiés + revue sécurité des champs.

## Risque 4 — Adoption partielle

Mitigation:

- migration par priorités P1/P2/P3 + quality gates sur nouveaux flux.

---

## 14. Indicateurs de succès

Le chantier est réussi si:

1. incidents P1 sont triageables rapidement via corrélation.
2. logs/export sont homogènes et actionnables.
3. aucun secret n'est exposé dans diagnostics.
4. l'équipe support/dev réduit le temps de diagnostic.

---

## 15. Décisions de conception à retenir

1. `operationId` est le pivot de corrélation runtime.
2. Un schéma d'événement commun est obligatoire.
3. La sanitization est centralisée et testée.
4. L'export diagnostics est un produit d'exploitation, pas un dump brut.

---

## 16. Résultat attendu final

À l'issue du chantier 7, le projet doit disposer d'une observabilité runtime:

1. cohérente entre features,
2. sûre vis-à-vis des données sensibles,
3. utile pour diagnostiquer incidents sans exploration manuelle excessive.

Le gain attendu est un support plus rapide, des incidents mieux compris et une exploitation plus fiable en production.

---

## 17. Annexe — Résumé opérationnel

### En une phrase

Le chantier 7 industrialise le diagnostic runtime: chaque incident critique devient corrélable, lisible et sécurisé.

### Priorités absolues

1. Schéma événement standard.
2. Corrélation `operationId` sur P1.
3. Sanitization stricte.
4. Export diagnostics exploitable.

### Règle d'or

Un log qui n'aide pas à diagnostiquer une décision ou une erreur critique n'a pas sa place dans le signal principal.

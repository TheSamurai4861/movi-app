# PRD — Refactor Data Contracts & Error Boundaries

## 1. Contexte

Après les chantiers:

1. `1_localizations.md`
2. `2_focus.md`
3. `3_architecture_boundaries.md`
4. `4_monolith_pages_decomposition.md`
5. `5_quality_gates_and_repo_hygiene.md`

le prochain risque structurel porte sur la fiabilité des flux de données et la cohérence des erreurs.

Le projet manipule plusieurs sources (local, remote, cache, supabase, IPTV providers) avec des transformations multiples entre:

- DTOs techniques,
- entités/value objects métier,
- modèles UI.

Sans contrats explicites et sans frontières d'erreurs homogènes, les régressions deviennent difficiles à prévenir: erreurs silencieuses, états incohérents, retries hasardeux, messages utilisateur variables selon feature.

Ce PRD définit la cible du chantier 6: standardiser les contrats de données et instaurer des error boundaries cohérentes, testables et observables.

---

## 2. Problème à résoudre

### 2.1 Symptômes observés

1. Contrats data implicites
   - mapping/marshalling dispersés,
   - hypothèses non documentées sur champs optionnels/nullables,
   - comportement divergent selon feature.

2. Validation inégale des entrées
   - certaines validations tôt, d'autres tard,
   - fallback non uniformes,
   - erreurs techniques parfois remontées telles quelles en UI.

3. Taxonomie d'erreurs fragmentée
   - exceptions brutes mélangées aux failures métier,
   - classification variable (network/auth/not found/validation),
   - logique de retry peu harmonisée.

4. Error boundaries UI non homogènes
   - messages hétérogènes,
   - actions de récupération (retry/reload) inconsistantes,
   - manque de règles communes sur erreurs recoverable vs terminales.

5. Coût de non-régression élevé
   - faibles garanties sur compatibilité de payloads,
   - tests de mapping insuffisamment systématiques.

### 2.2 Causes racines

- absence de standard global de contrats DTO/domain.
- manque de stratégie partagée de mapping et validation.
- gestion d'erreurs pilotée localement par feature.
- peu de tests contractuels transverses.

---

## 3. Objectifs

### 3.1 Objectif principal

Rendre les flux data explicites, validés et robustes, avec une gestion d'erreurs cohérente de l'infrastructure jusqu'à la présentation.

### 3.2 Objectifs détaillés

1. Standardiser les contrats d'entrée/sortie de données critiques.
2. Centraliser les règles de mapping DTO -> domain -> UI model.
3. Formaliser une taxonomie d'erreurs commune.
4. Définir des error boundaries UI uniformes.
5. Uniformiser la politique de retry/fallback selon classe d'erreur.
6. Couvrir les contrats et mappers par tests robustes.

### 3.3 KPI de succès

1. Réduction des incidents liés à parsing/mapping/nullable inattendu.
2. Diminution des états d'erreur non traités en UI.
3. Augmentation du taux de couverture des mappers/contrats critiques.
4. Cohérence observable des messages/actions d'erreur entre features.

---

## 4. Hors périmètre

Ne font pas partie de ce chantier, sauf ajustement strictement nécessaire:

- redesign UX global des écrans d'erreur.
- remplacement de toutes les sources de données externes.
- refonte complète des repositories métier.
- changement de framework de state management.

Le chantier cible la fiabilité des contrats et le traitement cohérent des erreurs.

---

## 5. Principes directeurs

1. Un contrat de données critique doit être explicite et testable.
2. Une erreur technique n'est jamais exposée brute en UI.
3. Les mappers doivent être déterministes et sans side effects.
4. Les fallbacks doivent être intentionnels et documentés.
5. La stratégie de retry doit dépendre de la classe d'erreur, pas du hasard.
6. Pas de sur-abstraction: standardiser d'abord les cas réellement fréquents.

---

## 6. Architecture cible

## 6.1 Contrats de données

Pour chaque flux critique:

1. définir contrat d'entrée DTO (source externe/cache),
2. définir entité/value object de sortie métier,
3. définir mapping explicite et validé,
4. définir règles de compatibilité et fallback.

Règle:

- aucun accès UI direct à DTOs techniques.

## 6.2 Pipeline de transformation cible

1. `Data source`:
   - lecture payload,
   - validation structure minimale.
2. `Mapper data`:
   - conversion DTO -> objets domain via règles explicites.
3. `Application/domain`:
   - décisions métier sur données validées.
4. `Presentation adapter`:
   - conversion domain -> UI model.

## 6.3 Taxonomie d'erreurs cible

Classes minimales:

1. `ValidationFailure`
2. `NetworkFailure`
3. `AuthFailure`
4. `PermissionFailure`
5. `NotFoundFailure`
6. `RateLimitFailure`
7. `ConflictFailure`
8. `TimeoutFailure`
9. `UnexpectedFailure`

Chaque erreur doit porter:

1. catégorie stable,
2. contexte technique minimal (non sensible),
3. signal recoverable/non-recoverable,
4. recommandation de traitement (retry/fallback/abort).

## 6.4 Error boundaries UI cibles

La présentation doit appliquer un comportement uniforme:

1. Erreur recoverable:
   - message clair orienté action,
   - bouton retry standard.
2. Erreur non recoverable:
   - message stable,
   - action alternative (retour/changement de source).
3. Erreur d'auth/session:
   - redirection ou revalidation contrôlée.

Règle:

- toute erreur présentée doit provenir d'un mapping d'erreur centralisé.

---

## 7. Contrats publics à introduire ou stabiliser

1. Contrat de résultat typé (succès/échec) transverse:
   - format commun pour use-cases critiques.

2. Contrat de mapping d'erreur infra -> domaine:
   - adaptateurs dédiés par source (network/supabase/local).

3. Contrat de présentation d'erreur:
   - modèle UI d'erreur standard (titre/message/actions/code diagnostic).

4. Contrat de politique retry:
   - décision retry autorisé/interdit selon catégorie d'erreur.

Règle:

- ces contrats sont versionnés et documentés; les changements cassants sont explicités.

---

## 8. Périmètres prioritaires (ordre)

## 8.1 Priorité P1

1. Flows lecture média (movie/tv/player):
   - mapping de sélection lecture,
   - fallback data/caches.

2. Flows settings/connectivité (IPTV, profil, bootstrap):
   - erreurs réseau/auth/config.

## 8.2 Priorité P2

1. Recherche et enrichissement métadonnées.
2. Bibliothèque (favoris, historique, playlists sync).

## 8.3 Priorité P3

1. Flows secondaires restants.
2. Harmonisation complète des messages d'erreur UI.

---

## 9. Chantiers techniques prioritaires

## Lot A — Standard des contrats data

Objectif:

- rendre explicites les contrats des flux critiques.

Actions:

1. inventorier DTO/domain/UI models critiques.
2. formaliser schémas et règles de mapping.
3. aligner nullability/fallback par contrat.

Résultat attendu:

- contrats data audités et stables sur périmètre P1.

## Lot B — Taxonomie d'erreurs unifiée

Objectif:

- converger vers une classification unique et actionable.

Actions:

1. définir la hiérarchie failures commune.
2. mapper exceptions SDK vers failures stables.
3. centraliser helpers de classification.

Résultat attendu:

- disparition progressive des exceptions brutes en presentation.

## Lot C — Error boundaries UI

Objectif:

- uniformiser le rendu des erreurs et actions utilisateur.

Actions:

1. créer modèle UI d'erreur standard.
2. introduire widgets/handlers de rendu d'erreur harmonisés.
3. brancher retry/fallback selon policy.

Résultat attendu:

- UX d'erreur cohérente cross-feature.

## Lot D — Tests contractuels

Objectif:

- verrouiller le comportement pour éviter régressions silencieuses.

Actions:

1. tests mappers (nominal + payload partiel + payload invalide).
2. tests mapping erreurs infra -> failures.
3. tests UI error boundary (recoverable vs terminale).

Résultat attendu:

- non-régression fiable sur contrats et erreurs.

---

## 10. Backlog initial (ordre imposé)

## Epic A — Data contracts baseline

Story A1:

- catalogue des flux data critiques P1.

Story A2:

- définition des contrats cibles.

Story A3:

- documentation de compatibilité/fallback.

## Epic B — Error taxonomy

Story B1:

- création taxonomie failures commune.

Story B2:

- adaptateurs d'erreurs pour sources principales.

Story B3:

- suppression remontées d'exceptions brutes en UI sur P1.

## Epic C — UI boundaries

Story C1:

- modèle d'erreur UI standard.

Story C2:

- composants de rendu d'erreur réutilisables.

Story C3:

- policy retry/fallback connectée à la taxonomie.

## Epic D — Validation et tests

Story D1:

- tests mappers et contrats sur P1.

Story D2:

- tests error mapping.

Story D3:

- smoke non-régression des flows critiques.

## Epic E — Extension P2/P3

Story E1:

- migration recherche/enrichissement.

Story E2:

- migration bibliothèque/sync.

Story E3:

- consolidation finale et durcissement règles.

---

## 11. Critères d'acceptation

## 11.1 Critères de structure

1. Les flux migrés disposent de contrats data explicites.
2. Les mappings DTO -> domain sont isolés et testés.
3. Les erreurs remontées en présentation sont typées et classifiées.
4. Les exceptions techniques brutes ne sortent plus vers l'UI sur périmètre migré.

## 11.2 Critères fonctionnels

1. Comportement métier inchangé sur cas nominaux.
2. Les scénarios d'erreur déclenchent des actions utilisateur cohérentes.
3. Les politiques retry/fallback sont déterministes.

## 11.3 Critères qualité

1. Tests contractuels ajoutés sur mappers critiques.
2. Tests error boundaries ajoutés sur flows P1.
3. Aucune régression architecture introduite (alignement PRD 3/5).

---

## 12. Plan de test

## 12.1 Unit tests — contrats et mapping

À couvrir:

1. mapping nominal DTO -> domain.
2. champs manquants/nullables inattendus.
3. valeurs invalides et erreurs de format.
4. fallback déterministe documenté.

## 12.2 Unit tests — erreurs

À couvrir:

1. mapping exceptions infra -> failures.
2. classification recoverable vs non-recoverable.
3. décision retry/fallback.

## 12.3 Widget/Integration tests — boundaries UI

À couvrir:

1. rendu message d'erreur standard.
2. action retry opérationnelle.
3. comportement erreur terminale.
4. continuité navigation après erreur.

## 12.4 Non-régression manuelle ciblée

Parcours minimaux:

1. lancement lecture movie/tv avec cas nominal et échec.
2. connectivité/settings IPTV (erreur auth/network/config).
3. recherche + enrichissement en mode dégradé.
4. bibliothèque sync en présence d'erreurs réseau.

---

## 13. Plan de migration

## Étape 1 — Baseline des contrats et erreurs

Livrables:

1. inventaire P1 des flux et erreurs.
2. taxonomie d'erreurs validée.
3. contrats cibles priorisés.

## Étape 2 — Pilote vertical P1

Livrables:

1. un flux complet migré (data -> domain -> UI boundary).
2. tests contractuels et erreurs associés.

## Étape 3 — Extension P1 complète

Livrables:

1. migration des autres flux P1.
2. harmonisation retry/fallback.

## Étape 4 — Extension P2/P3

Livrables:

1. migration progressive recherche/bibliothèque.
2. consolidation globale des patterns.

## Étape 5 — Stabilisation finale

Livrables:

1. documentation contracts/errors à jour.
2. quality gates adaptés aux nouveaux standards.

---

## 14. Risques et mitigations

## Risque 1 — Sur-standardisation

Effet:

- complexité accrue sans gain pratique.

Mitigation:

- prioriser les flux fréquents/à risque (P1), éviter le framework interne excessif.

## Risque 2 — Régression fonctionnelle cachée

Effet:

- changement involontaire de comportement sur cas limites.

Mitigation:

- tests contractuels exhaustifs + smoke ciblés.

## Risque 3 — Ambiguïté recoverable/non-recoverable

Effet:

- UX incohérente en erreur.

Mitigation:

- règles explicites par catégorie d'erreur + mapping centralisé.

## Risque 4 — Adoption partielle

Effet:

- coexistence prolongée anciens/nouveaux patterns.

Mitigation:

- plan par lots courts + policy "no new raw error handling" sur périmètre migré.

---

## 15. Indicateurs de succès

Le chantier est considéré réussi si:

1. les flux P1 utilisent des contrats data explicites.
2. les erreurs UI passent par une taxonomie commune.
3. les tests contractuels mappers/erreurs couvrent les scénarios critiques.
4. les incidents de parsing/mapping non gérés diminuent.
5. la cohérence de l'expérience d'erreur est visible entre features.

---

## 16. Décisions de conception à retenir

1. Les contrats data critiques sont explicites et versionnés.
2. Les erreurs sont classifiées avant d'arriver en présentation.
3. Le retry/fallback dépend de la catégorie d'erreur.
4. Les mappers sont isolés, déterministes, testés.
5. Aucune erreur technique brute n'est exposée en UI sur périmètre migré.

---

## 17. Résultat attendu final

À l'issue du chantier 6, le projet doit disposer de flux de données:

- robustes aux variations de payload,
- cohérents dans la transformation data -> domain -> UI,
- prévisibles dans la gestion des erreurs.

Le gain attendu est une baisse des bugs silencieux, une meilleure résilience runtime et une maintenance plus sûre.

---

## 18. Annexe — Résumé opérationnel

### En une phrase

Le chantier 6 transforme des flux data implicites et un traitement d'erreurs hétérogène en système contractuel, testable et uniforme.

### Priorités absolues

1. Contrats data critiques P1.
2. Taxonomie d'erreurs commune.
3. Error boundaries UI uniformes.
4. Tests contractuels et erreurs robustes.

### Règle d'or

Si un payload ou une erreur n'a pas de contrat explicite, le flux n'est pas considéré comme prêt pour la production.

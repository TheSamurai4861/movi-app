# PRD — Refactor des frontières d'architecture

## 1. Contexte

Le projet dispose d'une base fonctionnelle riche, mais l'état actuel des frontières d'architecture crée un coût de maintenance élevé et une dérive structurelle visible.

La source de vérité de ce constat est le rapport:

- `docs/architecture/reports/arch_violations_2026-04-12.md`

Ce rapport (`dart run tool/arch_lint.dart`, mode `enforce`) remonte une baseline de **475 violations bloquantes** au **12 avril 2026**.

Répartition:

- `ARCH-R4` (couplage inter-features interdit): **323**
- `ARCH-R1` (presentation -> data): **68**
- `ARCH-R5` (accès locator direct en UI): **53**
- `ARCH-R2` (domain -> data): **21**
- `ARCH-R3` (presentation -> SDK externe): **10**

L'existant n'est pas inutilisable, mais il est de moins en moins scalable. Chaque évolution fonctionnelle traverse trop de couches et multiplie les imports transverses.

Ce PRD définit la cible du chantier 3: restaurer des frontières d'architecture explicites, testables et durables, sans réécriture massive.

---

## 2. Problème à résoudre

### 2.1 Symptômes observés

1. Couplage inter-features massif
   - imports directs `feature -> feature` en presentation, domain et data.
   - circulation de types métier entre features sans contrat partagé.

2. Accès direct à l'infrastructure depuis l'UI
   - usage de `di/get_it/slProvider` dans la présentation.
   - accès direct à des `datasources` ou `repositories` data dans des pages/providers UI.

3. Fuite de responsabilités de couches
   - domain qui dépend de `data/*`.
   - presentation qui dépend de `data/*` et parfois de SDK externes.

4. Fichiers hotspots type "god objects"
   - orchestration métier + wiring + accès infra + logique UI regroupés.
   - effet domino: un changement local entraîne des impacts multiples.

5. Coût test et non-régression élevé
   - injection difficile à mocker correctement.
   - scénarios d'intégration plus fragiles car trop de dépendances concrètes.

### 2.2 Causes racines

- frontières architecture non imposées dans le flux quotidien de dev.
- absence de pattern contractuel systématique pour les usages cross-feature.
- dépendance historique au service locator dans la couche présentation.
- migration progressive jamais formalisée à l'échelle du repo.

---

## 3. Objectifs

### 3.1 Objectif principal

Restaurer des frontières propres:

- `presentation -> application/domain -> data/infra`

et rendre les dépendances explicites, contractuelles et testables.

### 3.2 Objectifs détaillés

1. Supprimer l'accès locator direct depuis la présentation.
2. Supprimer les dépendances `presentation -> data`.
3. Supprimer les dépendances `domain -> data`.
4. Réduire fortement les imports `feature -> feature` non contractuels.
5. Rendre les flux cross-feature contractuels via `shared/core` (ou `core/contracts`).
6. Diminuer le coût de test en rendant l'injection UI mockable par providers/facades.
7. Instaurer un garde-fou "no new violations" sur les PR.

### 3.3 Indicateurs de succès (KPI)

1. `arch_lint` baisse de manière mesurable à chaque lot.
2. Aucun nouveau leak d'architecture introduit dans les PR.
3. Les modules migrés passent sans:
   - `presentation -> data`,
   - locator direct en UI,
   - dépendances cross-feature non approuvées.
4. Les tests providers/contracts sont ajoutés sur chaque lot.

---

## 4. Hors périmètre

Ne font pas partie de ce chantier, sauf adaptation strictement nécessaire:

- refonte UX/UI des pages.
- redesign navigation/focus.
- réécriture complète des features métier.
- migration big-bang de tout le repo en une passe.
- optimisation perf non justifiée par mesure.

Le chantier 3 cible la **structure d'architecture**, pas la refonte produit.

---

## 5. Principes directeurs

Le refactor respecte les règles projet:

- simplicité avant framework interne complexe.
- frontières explicites, pas de magie implicite.
- migration incrémentale par lots courts.
- compatibilité transitoire maîtrisée.
- testabilité systématique des contrats et adaptateurs.
- aucune régression fonctionnelle volontaire.

Règle de gouvernance clé:

- **Aucune violation nouvelle n'est acceptée**, même si la baseline globale n'est pas encore à zéro.

---

## 6. Architecture cible

## 6.1 Règles de dépendances cibles

1. `presentation`:
   - dépend de `application/domain` et d'abstractions contractuelles.
   - ne dépend jamais de `data/*`.
   - ne dépend jamais d'un locator concret (`get_it`, `di.dart`).

2. `domain`:
   - contient les règles métier et interfaces.
   - ne dépend jamais de `data/*`.

3. `data/infra`:
   - implémente les interfaces du domain/application.
   - encapsule SDK externes (supabase, dio, etc.).

4. Cross-feature:
   - interdit par défaut.
   - autorisé uniquement via contrats partagés approuvés.

## 6.2 Pattern contractuel cible

Pour toute collaboration cross-feature:

1. définir une interface contractuelle dans `shared/core` (ou `core/contracts`).
2. implémenter l'adaptateur dans la feature propriétaire.
3. exposer l'implémentation via provider injectable.
4. consommer le contrat depuis l'autre feature, jamais l'impl concrète.

## 6.3 Injection cible en présentation

La présentation consomme:

- providers Riverpod d'abstractions métier.
- facades applicatives testables.

La présentation ne consomme pas:

- service locator brut.
- classes data concrètes.

---

## 7. Contrats publics à introduire ou consolider

Cette section fixe les interfaces cross-feature minimales à stabiliser.

1. Contrats de lecture d'état de lecture/historique
   - usage actuel dispersé entre library/player/movie/tv.
   - cible: interface unique orientée use-case.

2. Contrats de résolution de sélection de lecture
   - dépendances player <-> movie/tv.
   - cible: types d'entrée/sortie stables côté contrat, impl par feature propriétaire.

3. Contrats de préférences utilisateur utiles hors feature settings
   - éviter import direct de providers/settings domain depuis d'autres features.
   - passer par un contrat de consultation applicative.

4. Contrats IPTV de haut niveau
   - éviter imports directs de modules/data IPTV en presentation d'autres features.
   - exposer des use-cases applicatifs ciblés.

Règle:

- pas de sur-design. Introduire uniquement les contrats nécessaires pour supprimer les violations réelles.

---

## 8. Hotspots prioritaires

Les hotspots suivants doivent être traités explicitement en premier, car ils concentrent le plus de violations:

1. `lib/src/features/movie/presentation/providers/movie_detail_providers.dart`
2. `lib/src/features/tv/presentation/pages/tv_detail_page.dart`
3. `lib/src/features/tv/presentation/providers/tv_detail_providers.dart`
4. `lib/src/features/search/presentation/providers/search_providers.dart`
5. `lib/src/features/settings/presentation/providers/iptv_connect_providers.dart`
6. `lib/src/features/library/presentation/providers/library_cloud_sync_providers.dart`

Ces hotspots sont la priorité car ils combinent:

- couplage inter-features,
- accès locator direct,
- fuite de couches.

---

## 9. Chantiers techniques prioritaires

## Lot A — DI en présentation

Objectif:

- retirer les usages `slProvider/get_it/di.dart` de la UI.

Actions:

1. créer des providers/facades d'abstraction par périmètre.
2. migrer pages/providers UI vers ces facades.
3. ajouter tests provider avec mocks/fakes.

Résultat attendu:

- aucune UI migrée ne dépend d'un locator concret.

## Lot B — Leaks de couches

Objectif:

- supprimer `presentation -> data` et `domain -> data`.

Actions:

1. extraire interfaces côté domain/application.
2. déplacer impl concrètes côté data.
3. basculer les appels existants vers interfaces.

Résultat attendu:

- règles `ARCH-R1` et `ARCH-R2` en baisse nette sur périmètre migré.

## Lot C — Couplage inter-features

Objectif:

- réduire `ARCH-R4` via contrats partagés.

Actions:

1. identifier flux cross-feature les plus fréquents.
2. créer contrats partagés minimaux.
3. remplacer imports directs feature->feature par contrats.

Résultat attendu:

- baisse de `ARCH-R4` sur modules ciblés sans régression fonctionnelle.

## Lot D — Décomposition hotspots

Objectif:

- réduire le risque de régression et la complexité locale.

Actions:

1. isoler orchestration applicative de la logique de rendu.
2. découper les providers/pages saturés en composants/facades cohérents.
3. conserver comportement UI identique.

Résultat attendu:

- maintenance simplifiée et tests plus ciblés.

---

## 10. Backlog initial (ordre imposé)

## Epic A — Guardrails CI

Story A1:

- exécuter `dart run tool/arch_lint.dart` dans la pipeline.

Story A2:

- refuser toute PR qui augmente le nombre de violations (policy: no new violations).

Story A3:

- publier un rapport de delta par règle.

## Epic B — Assainissement providers UI

Story B1:

- retirer locator direct sur hotspots prioritaires.

Story B2:

- introduire facades/providers testables.

Story B3:

- couvrir les providers migrés par tests unitaires/widget ciblés.

## Epic C — Contrats cross-feature

Story C1:

- définir contrats partagés minimaux.

Story C2:

- adapter impl côté features propriétaires.

Story C3:

- migrer imports directs vers contrats.

## Epic D — Refactor hotspots

Story D1:

- traiter `movie_detail_providers.dart`.

Story D2:

- traiter `tv_detail_page.dart` et `tv_detail_providers.dart`.

Story D3:

- traiter `search_providers.dart`, `iptv_connect_providers.dart`, `library_cloud_sync_providers.dart`.

## Epic E — Durcissement qualité

Story E1:

- tests de non-régression architecture.

Story E2:

- documentation des conventions d'import et d'injection.

Story E3:

- revue finale de baseline et nouveau point de référence.

---

## 11. Plan de migration

Migration incrémentale obligatoire, sans freeze.

## Étape 1 — Baseline + garde-fous

Livrables:

- baseline datée (12 avril 2026) documentée.
- règle "no new violations" active.

Critère de sortie:

- chaque PR sait prouver qu'elle n'aggrave pas la dette.

## Étape 2 — Premier vertical pilot

Livrables:

- migration complète d'un hotspot (DI UI + contracts + tests).

Critère de sortie:

- pattern de migration validé et reproductible.

## Étape 3 — Extension par lots

Livrables:

- migration successive des hotspots restants.
- réduction mesurable des violations à chaque lot.

Critère de sortie:

- trajectoire de baisse stable sans regressions majeures.

## Étape 4 — Consolidation

Livrables:

- documentation d'architecture mise à jour.
- conventions de dev alignées avec lint.

Critère de sortie:

- architecture compréhensible et maintenable sans dépendance implicite.

---

## 12. Exigences fonctionnelles

1. Les flows critiques (welcome, movie/tv detail, settings) restent fonctionnels.
2. Le comportement utilisateur n'est pas dégradé par le refactor.
3. L'injection des dépendances en UI reste compatible avec tests et overrides.
4. Les collaborations cross-feature continuent de fonctionner via contrats.

---

## 13. Exigences non fonctionnelles

## 13.1 Lisibilité

- les dépendances utiles d'un module doivent être explicites et locales.

## 13.2 Maintenabilité

- un changement métier local ne doit plus imposer des imports transverses non liés.

## 13.3 Testabilité

- tout provider/facade introduit doit être testable en isolation.

## 13.4 Robustesse

- réduction des points d'accès directs à l'infrastructure depuis l'UI.

## 13.5 Gouvernance

- lint architecture devient un garde-fou opérationnel, pas un simple rapport.

---

## 14. Critères d'acceptation

## 14.1 Critères d'architecture

1. Plus de `presentation -> data` sur modules migrés.
2. Plus d'accès locator direct en UI sur modules migrés.
3. Dépendances inter-features remplacées par contrats approuvés sur modules migrés.
4. `domain` n'importe plus `data/*` sur modules migrés.

## 14.2 Critères qualité

1. Tests unitaires sur contrats et adaptateurs.
2. Tests providers avec injection mockable.
3. `arch_lint` vert sur périmètre migré.
4. Tendance globale à la baisse de la baseline violations.

## 14.3 Critères opérationnels

1. Policy "no new violations" active dans la CI.
2. Rapport de delta disponible à chaque lot.
3. Convention d'import/documentation mise à jour.

---

## 15. Plan de test

## 15.1 Tests unitaires

À couvrir:

- contrats partagés (signatures, invariants).
- adaptateurs data -> contrats.
- facades applicatives introduites.

## 15.2 Tests providers/widgets

À couvrir:

- injection sans locator direct.
- orchestration de cas nominal/erreur.
- compatibilité des overrides de tests.

## 15.3 Tests architecture

À exécuter:

- `dart run tool/arch_lint.dart`

En gate:

- rejet si nouvelles violations.
- suivi du delta par règle (`R1..R5`).

## 15.4 Non-régression manuelle ciblée

Parcours minimum:

1. welcome source / bootstrap.
2. détail movie + actions principales.
3. détail tv + actions principales.
4. settings et connexions IPTV.

---

## 16. Plan de validation du document

Le PRD est valide si:

1. cohérent avec `docs/rules.md`.
2. cohérent avec les règles effectives de `tool/arch_lint.dart`.
3. traçable: chaque objectif référence un type de violation (`R1..R5`).
4. mesurable: baseline datée et KPI de baisse explicites.

Checklist de validation:

1. baseline `2026-04-12` explicitement citée.
2. objectifs traduits en backlog actionnable.
3. critères d'acceptation testables.
4. risques et mitigations non ambigus.

---

## 17. Risques

## Risque 1 — Sur-abstraction des contrats

Effet:

- couche contractuelle trop générique, faible adoption.

Mitigation:

- contrats minimaux, orientés cas réels de violations.

## Risque 2 — Migration hybride trop longue

Effet:

- coexistence prolongée de patterns anciens et nouveaux.

Mitigation:

- lots courts avec date cible, pilot puis extension rapide.

## Risque 3 — Régressions runtime sur hotspots

Effet:

- incidents fonctionnels sur pages critiques.

Mitigation:

- tests ciblés par hotspot + smoke tests systématiques.

## Risque 4 — Garde-fou CI contourné

Effet:

- dette continue à croître malgré le chantier.

Mitigation:

- gate obligatoire sur PR, non optionnelle.

---

## 18. Indicateurs de succès

Le chantier est considéré réussi si:

1. le nombre total de violations diminue de lot en lot.
2. `ARCH-R4`, `ARCH-R1` et `ARCH-R5` baissent significativement sur les hotspots.
3. les modules migrés ne réintroduisent pas de locator en UI.
4. les flux cross-feature passent majoritairement par contrats.
5. le coût de test et de revue sur modules migrés diminue.

---

## 19. Décisions de conception à retenir

1. Les frontières de couches sont strictes et non négociables.
2. Le locator n'est pas autorisé dans la présentation.
3. Les échanges cross-feature se font par contrats approuvés.
4. Le refactor est incrémental et piloté par métriques.
5. Aucune nouvelle violation architecture n'est tolérée.

---

## 20. Résultat attendu final

À l'issue du chantier 3, le projet doit disposer d'une architecture qui:

- réduit nettement les imports transverses non contractuels.
- supprime les fuites de couches sur les modules migrés.
- rend la présentation indépendante de l'infrastructure concrète.
- permet des tests isolés plus fiables.
- maintient la vélocité via une structure claire et stable.

---

## 21. Annexe — Résumé opérationnel

### En une phrase

Le chantier 3 transforme une architecture couplée et permissive en architecture contractuelle, testable et gouvernée par un lint bloquant.

### Priorités absolues

1. Guardrails CI no new violations.
2. Retrait locator direct de la présentation.
3. Suppression `presentation -> data` et `domain -> data`.
4. Contrats cross-feature minimaux.
5. Migration hotspots à plus forte densité de violations.

### Baseline de référence

- Date: **2026-04-12**
- Total violations: **475**
- Détail:
  - `ARCH-R4=323`
  - `ARCH-R1=68`
  - `ARCH-R5=53`
  - `ARCH-R2=21`
  - `ARCH-R3=10`

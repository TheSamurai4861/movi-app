# Sous-phase 5.0 - Preparation et alignement du decoupage d'implementation

## Objectif

Cadrer le decoupage d'implementation avant de produire le backlog des lots, afin d'eviter:
- un plan trop gros pour etre livre
- un ordre de travail qui casse le tunnel actuel
- des migrations sans rollback
- des lots qui melangent architecture, UI et legacy cleanup sans frontiere claire

Cette sous-phase ne cree pas encore le backlog detaille. Elle verrouille les contraintes qui vont gouverner le decoupage de `5.1` a `5.7`.

## Synthese des contraintes non negociables

Les phases 1 a 4 imposent deja plusieurs contraintes fortes.

### 1. Contraintes produit et UX

- le tunnel cible est deja fige
- `Home` ne doit apparaitre que lorsque le minimum utile est pret
- `Home vide` reste une issue fonctionnelle, pas une erreur tunnel
- les recoveries critiques doivent reutiliser les surfaces deja validees:
  - `Preparation systeme`
  - `Auth`
  - `Choix profil`
  - `Choix / ajout source`
  - `Chargement medias`

Consequence implementation:
- aucun lot ne doit recreer de pages techniques non prevues
- les lots UI doivent s'aligner sur les surfaces ciblees, pas sur l'ancien routing

### 2. Contraintes architecture

- `TunnelState` est la source de verite cible
- `EntryJourneyOrchestrator` est le moteur unique du tunnel
- `GoRouter` doit projeter l'etat, pas le recalculer
- `GetIt` assemble, `Riverpod` expose, l'UI consomme
- les ports `startup`, `session`, `profiles`, `sources`, `source validation`, `pre-home`, `continuity` sont deja cadres

Consequence implementation:
- les lots coeur `state + orchestrator + ports` doivent arriver avant les gros lots d'ecrans
- le routeur et les guards ne doivent pas etre refactorises "au fil de l'eau" sans derive stable

### 3. Contraintes performance et resilience

- le pre-home doit etre borne
- le catalogue complet `10-15 s` ne doit plus bloquer `Home`
- les retries et timeouts doivent etre explicites
- les safe states `offline`, `session invalide`, `source invalide` sont obligatoires
- l'instrumentation minimale doit exister avant de juger la refonte

Consequence implementation:
- instrumentation et mesures doivent arriver tres tot
- le preload exhaustif doit sortir du chemin critique avant la bascule finale
- aucun lot d'ecrans ne doit masquer un comportement non borne

## Contraintes de livraison et de migration

Le decoupage devra respecter ces contraintes de livraison:

### A. Tous les lots doivent etre rollbackables

Chaque lot critique doit avoir:
- un flag clair ou un point de rollback clair
- une surface d'impact limitee
- une verification post-merge simple

### B. La coexistence legacy est autorisee mais bornee

La coexistence ancien / nouveau tunnel peut exister temporairement pour:
- `TunnelState` vs derive legacy
- nouveaux composants tunnel vs composants existants
- nouveau routage projete vs guards legacy de transition

Mais elle ne doit pas:
- durer sur toute la phase 5
- devenir une architecture parallele durable

### C. Les gros chantiers doivent etre decoupes par type de risque

Un lot ne doit pas melanger trop de categories a la fois:
- coeur d'etat et orchestration
- contrats backend / data
- composants UI communs
- ecrans
- nettoyage legacy

Regle:
- melanger deux categories n'est acceptable que si le lot est tres petit et qu'il reduit le risque

### D. Les migrations visibles doivent suivre un ordre defendable

Ordre de principe retenu:
1. mesurer
2. stabiliser l'etat
3. brancher les contrats
4. construire les briques UI
5. migrer les surfaces
6. nettoyer le legacy

## Zones a fort couplage ou fort risque

Les zones suivantes imposent une vigilance speciale dans le decoupage.

### 1. Routeur / guards / etat de tunnel

Risque:
- garder des decisions tunnel dans le routeur pendant que l'orchestrateur migre

Impact:
- redirections contradictoires
- bascule de surface non fiable
- rollback complexe

Consequence de decoupage:
- il faudra un lot dedie au derive de surface et a la projection routeur
- le nettoyage complet des guards viendra apres validation de la nouvelle projection

### 2. Orchestrateur actuel / ports / dependances concretes

Risque:
- refactorer `AppLaunchOrchestrator` et les ports en meme temps que les ecrans

Impact:
- regressions difficiles a isoler
- lots trop gros

Consequence de decoupage:
- coeur orchestration en lots propres avant les migrations d'ecrans

### 3. Preferences persistantes / selections / source de verite

Risque:
- conserver les preferences de selection comme source de verite implicite

Impact:
- branchements incoherents entre ancien et nouveau tunnel

Consequence de decoupage:
- il faudra un lot qui stabilise le derive `selected profile / selected source` avant les surfaces finales

### 4. Source validation / preload / home readiness

Risque:
- laisser du travail lourd avant `Home`
- ne pas distinguer `catalogue minimal` et `catalogue complet`

Impact:
- budgets de phase 4 intenables
- perception produit degradee

Consequence de decoupage:
- le lot preload doit arriver tard mais avec preconditions fortes deja remplies

### 5. Composants tunnel / pages existantes `welcome/*`

Risque:
- refaire les ecrans directement sans extraire les briques communes

Impact:
- duplication UI
- refactor plus long
- rollback difficile

Consequence de decoupage:
- composants UI communs avant bascule des pages

### 6. Telemetry / flags / rollback

Risque:
- ajouter les flags sans telemetry ou inversement

Impact:
- migration non pilotable
- difficultes a savoir quand couper le legacy

Consequence de decoupage:
- instrumentation minimale et flags de bascule doivent etre definis des premiers lots

## Hypotheses de rollout retenues

Les hypotheses de livraison recommandees pour la suite sont:

### 1. Pas de big bang

Le nouveau tunnel ne doit pas etre livre en une seule bascule globale.

Hypothese retenue:
- migration par paliers avec compatibilite temporaire

### 2. Les flags portent des blocs coherents

On evite les micro-flags ecran par ecran si cela fragilise la lecture du systeme.

Hypothese retenue:
- flags de blocs coherents:
  - instrumentation
  - state model / orchestrator
  - route projection
  - composants UI tunnel
  - surfaces `auth/profile`
  - surfaces `source`
  - `preloading_home`

### 3. Les migrations peuvent se chevaucher mais pas les sources de verite

Hypothese retenue:
- deux implementations UI peuvent coexister temporairement
- deux sources de verite tunnel ne doivent pas coexister longtemps

### 4. Le legacy reste lisible tant qu'il n'est pas supprime

Hypothese retenue:
- pas de suppression partielle opaque
- tout legacy conserve doit avoir une raison temporaire documentee

### 5. Le succes d'un lot se juge aussi par la mesure

Hypothese retenue:
- un lot coeur n'est pas considere fini si ses transitions critiques ne sont pas observables

## Contraintes de taille des lots

Pour rester revuable et rollbackable, un lot doit idealement:
- avoir un objectif unique
- toucher un nombre borne de surfaces ou modules
- avoir un impact lisible sur le routing
- avoir une verification post-merge courte

Anti-patterns de lots a eviter:
- "migrer tout le tunnel source"
- "refactor orchestrator + routeur + preload"
- "nouveaux composants + nouveaux ecrans + nettoyage legacy"

## Criteres de qualite du futur backlog

Le backlog de `5.1` devra respecter ces criteres:

1. chaque lot a un objectif lisible en une phrase
2. chaque lot a une precondition claire
3. chaque lot a une sortie observable
4. chaque lot peut etre teste sans terminer toute la refonte
5. chaque lot critique a un rollback ou un flag de bascule

## Ambiguities restantes a lever avant 5.1

Les points suivants restent ouverts, mais ils ne bloquent pas le lancement de `5.1`.

### 1. Granularite exacte des epics

Question:
- faut-il des epics par couche technique ou par tranche utilisateur

Recommandation:
- epics hybrides, mais lots concretement classes par type de risque

### 2. Niveau exact de granularite des flags

Question:
- combien de flags le projet accepte sans devenir difficile a operer

Recommandation:
- peu de flags, chacun portant une tranche fonctionnelle coherente

### 3. Place exacte du routeur dans le plan

Question:
- faut-il traiter la projection routeur dans le meme lot que l'orchestrateur ou juste apres

Recommandation:
- juste apres le coeur d'orchestration, dans un lot voisin mais distinct

### 4. Place exacte du preload dans le plan

Question:
- faut-il sortir d'abord le catalogue complet du pre-home, puis refaire la surface `Chargement medias`, ou l'inverse

Recommandation:
- securiser d'abord la logique de preload, puis finaliser la surface

## Verdict

La sous-phase `5.0` est suffisamment stable si l'on retient ces points:
- les contraintes de decoupage sont explicites
- les zones de fort couplage sont identifiees
- les hypotheses de rollout sont claires
- les ambiguities restantes sont bornees

La suite logique est la sous-phase `5.1`, pour produire l'epic map et le backlog initial des lots.

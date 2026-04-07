# Sous-phase 4.0 - Preparation et alignement performance/resilience

## Objectif

Cadrer la phase performance/resilience avant de fixer des budgets, des timeouts et des safe states.

Cette sous-phase ne fixe pas encore les chiffres cibles. Elle verrouille:
- les zones critiques a budgeter
- les risques de lenteur et de fragilite deja connus
- les inconnues qu'il faudra mesurer ou borner
- les ambiguities restantes a lever avant la sous-phase `4.1`

## Base de travail confirmee

Les phases 1, 2 et 3 ont deja stabilise:
- le parcours cible du tunnel
- les surfaces UI cibles
- le modele d'etat canonique du tunnel
- les contrats critiques du tunnel
- la distinction `must-have before home` vs `can-load-after-home`
- la strategie de migration progressive

La phase 4 doit donc servir le tunnel canonique suivant:
- `preparing_system`
- `auth_required`
- `profile_required`
- `source_required`
- `preloading_home`
- `ready_for_home`

Et ses qualifiers critiques:
- `execution_mode`
  - `nominal`
  - `degraded`
  - `blocked`
- `continuity_mode`
  - `cloud`
  - `local_fallback`
- `content_state`
  - `ready`
  - `empty`
- `loading_state`
  - `normal`
  - `slow`

## Zones critiques a budgeter

Les budgets de la sous-phase `4.1` devront porter en priorite sur ces zones.

## 1. `preparing_system`

Pourquoi c'est critique:
- c'est le premier temps percu par l'utilisateur
- il concentre bootstrap, connectivite, resolution initiale et signaux de recoveries
- c'est l'endroit ou une lenteur se transforme le plus vite en impression d'app cassee

Sous-zones a borner:
- bootstrap systeme
- exposition de l'etat initial
- premiere evaluation du contexte reseau et auth

## 2. Resolution session / auth

Pourquoi c'est critique:
- elle conditionne l'entree dans le nominal
- elle peut etre lente, timeout ou tomber en `reauth`
- elle influence tres vite la perception de fiabilite du tunnel

Sous-zones a borner:
- restore session
- refresh session
- verification auth
- transition vers `auth_required`

## 3. Resolution profils

Pourquoi c'est critique:
- elle reste `must-have before home`
- elle conditionne le passage vers `source_required` ou `preloading_home`
- elle peut etre impactee par cloud/local fallback

Sous-zones a borner:
- chargement inventaire profils
- resolution du profil selectionne
- creation profil si necessaire

## 4. Resolution sources

Pourquoi c'est critique:
- c'est une zone historiquement fragile
- elle concentre inventaire, selection, validation et erreurs source
- elle pilote beaucoup de cas de recovery

Sous-zones a borner:
- chargement inventaire sources
- resolution source active
- validation source
- fallback vers choix manuel

## 5. `preloading_home`

Pourquoi c'est critique:
- c'est la derniere etape avant la promesse `home prete`
- c'est la zone la plus exposee au risque de surcharger le tunnel
- elle concentre `catalogReady`, `libraryReady` et `homePreloaded`

Sous-zones a borner:
- demarrage preload
- attente du minimum utile
- detection `catalog empty`
- detection `preload_slow`

## 6. Transitions degradees et recoveries

Pourquoi c'est critique:
- la lenteur et la fragilite ne se jouent pas seulement en nominal
- offline, timeout, source invalide et fallback local doivent etre bornes
- ces cas pilotent la resilience percue du tunnel

Sous-zones a borner:
- entree en fallback local
- retry utilisateur
- retour a un etat stable
- sortie d'un blocage

## Risques de lenteur et de fragilite deja connus

## 1. Trop de travail avant `home`

Risque:
- le tunnel attend trop de choses avant d'afficher `home`

Consequence:
- temps cold start et warm start trop longs
- mauvaise perception de fluidite

Origine probable:
- frontiere encore trop large entre `must-have before home` et `can-load-after-home`

## 2. Resolution auth / cloud non bornee

Risque:
- restore session ou verification auth trop lentes ou trop implicites

Consequence:
- `preparing_system` trop longue
- transitions peu previsibles entre nominal, degrade et bloque

Origine probable:
- variabilite reseau
- dependance cloud
- retries non encore bornees

## 3. Validation source couteuse ou fragile

Risque:
- la source active est absente, invalide ou lente a verifier

Consequence:
- tunnel bloque trop tard
- retour arriere confus
- `source_required` trop couteux

Origine probable:
- couplage inventaire / selection / validation
- heterogeneite des providers IPTV

## 4. `preloading_home` trop large

Risque:
- le preload attend plus que le strict necessaire

Consequence:
- `home` arrive tard
- perception de tunnel lourd

Origine probable:
- chargements non critiques encore attaches au pre-home
- porosite entre tunnel et logique interne de `home`

## 5. Timeouts et retries encore non stabilises

Risque:
- comportements de patience et de recovery differents selon les contrats

Consequence:
- tunnel imprevisible
- experience inegale selon les cas reseau

Origine probable:
- timeouts historiques heterogenes
- retrys implicites ou distribues

## 6. Double source de verite temporaire pendant migration

Risque:
- coexistence `BootstrapDestination` / `TunnelState`
- coexistence `LaunchRedirectGuard` historique / derive `TunnelSurface`

Consequence:
- mesures brouillees
- attribution difficile des lenteurs

Origine probable:
- migration par paliers necessaire

## 7. Manque d'observabilite

Risque:
- impossible de distinguer lent, degrade, bloque et retryable

Consequence:
- budgets impossibles a piloter en production
- QA difficile a orienter

Origine probable:
- telemetry encore insuffisamment normalisee

## Inconnues a mesurer ou a borner

Ces inconnues ne bloquent pas `4.0`, mais devront etre tranchees par mesure ou convention.

## 1. Baselines de temps reel

Inconnues:
- cold start reel du tunnel
- warm start reel du tunnel
- temps nominal par etape
- distribution mobile vs TV

Besoin:
- baseline de reference avant budgets definitifs

## 2. Cout reel de la resolution auth

Inconnues:
- temps median / p95 de restore session
- comportement en cloud lent
- delai acceptable avant `auth_required`

## 3. Cout reel de la resolution profils

Inconnues:
- temps de chargement inventaire profils
- impact du fallback local
- cout d'une creation profil dans le tunnel

## 4. Cout reel de la resolution sources

Inconnues:
- temps de chargement inventaire sources
- temps de validation d'une source active
- variabilite selon type de source

## 5. Cout reel du `preloading_home`

Inconnues:
- part catalogue
- part library
- part home preload
- ce qui peut etre deferre sans casser la promesse UX

Contrainte produit ajoutee:
- un chargement complet de catalogue avec des milliers d'elements peut legitimement prendre `10-15 s`
- ce temps ne doit donc pas devenir le budget cible du pre-home nominal
- la phase 4 devra distinguer `catalogue minimal exploitable` et `catalogue complet`

## 6. Seuil de `slow` acceptable par surface

Inconnues:
- a partir de quand `preparing_system` est percue comme trop longue
- a partir de quand `preloading_home` doit afficher un recovery explicite
- a partir de quand un retry devient preferable a l'attente

## 7. Robustesse des timeouts actuels

Inconnues:
- timeouts existants deja en place
- retries caches dans les adapters ou use cases
- comportements fail-open vs fail-closed encore presents

## 8. Couverture telemetry actuelle

Inconnues:
- quelles transitions sont deja mesurees
- quelles transitions sont muettes
- quels reason codes sont deja disponibles et reutilisables

## Hypotheses de travail retenues pour la phase 4

Pour pouvoir avancer sans re-ouvrir les phases precedentes, les hypotheses suivantes sont prises:

1. `home` ne doit apparaitre qu'une fois le minimum requis pret.
2. `preloading_home` restera une etape explicite, mais bornee.
3. Le flow de retour utilisateur sain doit tendre vers un tunnel quasi invisible.
4. Les recoveries critiques doivent rester inline quand c'est possible.
5. Les budgets devront couvrir mobile et TV sans architecture parallele.
6. La migration progressive doit etre compatible avec l'instrumentation.

## Ambiguities restantes a lever avant la sous-phase 4.1

Ces points ne bloquent pas `4.0`, mais doivent etre assumes explicitement au moment de fixer les budgets.

1. Les budgets de `4.1` seront-ils fixes:
   - comme cible produit ambitieuse
   - ou comme budget reellement defendable a court terme pour la release initiale

2. Le budget `cold start` doit-il inclure:
   - uniquement le tunnel jusqu'a `ready_for_home`
   - ou aussi le temps avant premiere peinture utile de `home`

3. Le budget `preloading_home` doit-il etre:
   - unique
   - ou separe en sous-budgets `catalog / library / home preload`

4. En mode degrade, veut-on budgeter:
   - le temps avant entree en safe state
   - ou le temps total avant issue finale

5. Les budgets de `source_required` doivent-ils distinguer:
   - inventaire source
   - validation source
   - ajout manuel de source

6. La performance TV doit-elle etre:
   - mesuree avec les memes budgets que mobile
   - ou avec des seuils adaptes a ses contraintes d'affichage et d'interaction

## Ce qui est fixe et ne doit plus etre re-ouvert en phase 4

- le parcours cible issu de la phase 1
- la cible UI issue de la phase 2
- le modele d'etat canonique issu de la phase 3
- la distinction `must-have before home` vs `can-load-after-home`
- la strategie d'orchestrateur unique
- la migration progressive par paliers

## Verdict de sortie de la sous-phase 4.0

Verdict:
- la sous-phase `4.0` est suffisamment cadree pour lancer `4.1`

Pourquoi:
- les zones critiques a budgeter sont explicites
- les risques de lenteur et de fragilite majeurs sont nommes
- les inconnues a mesurer sont bornees
- les ambiguities restantes sont assez claires pour fixer des budgets en `4.1`

## Prochaine etape recommandee

La suite logique est:
1. fixer les budgets de temps par etape
2. definir les seuils `nominal / slow / blocked`
3. poser les budgets agreges `cold start / warm start / retour sain / premier parcours`

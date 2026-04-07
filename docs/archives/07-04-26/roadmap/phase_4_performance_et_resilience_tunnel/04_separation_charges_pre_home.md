# Sous-phase 4.3 - Separation des charges pre-home

## Objectif

Separer strictement ce qui doit etre charge avant `home` de ce qui peut etre charge apres l'entree dans `home`.

Cette sous-phase transforme en decisions concretes:
- la distinction `must-have before home`
- la distinction `can-load-after-home`
- les optimisations de sequence du tunnel

## Principe directeur

Le tunnel ne doit garder avant `home` que ce qui est necessaire pour tenir la promesse suivante:
- l'utilisateur entre dans une `home` exploitable
- la surface n'est pas trompeuse
- l'action primaire reste possible

Tout ce qui n'est pas strictement requis pour cette promesse doit sortir du tunnel.

## Regle produit clarifiee

Contrainte confirmee:
- un chargement complet de catalogue avec des milliers d'elements peut legitimement prendre `10-15 s`

Decision:
- ce chargement complet ne peut pas faire partie du `must-have before home`
- le pre-home n'attend qu'un **catalogue minimal exploitable**
- le reste du catalogue devient une charge differee post-home

## Definition des deux categories

## `must-have before home`

Est `must-have` toute charge qui, si elle manque:
- empeche la navigation normale dans `home`
- rend l'arrivee trompeuse ou incoherente
- empeche l'orchestrateur de garantir `ready_for_home`

## `can-load-after-home`

Est `can-load-after-home` toute charge qui:
- enrichit `home`
- ameliore la profondeur de contenu
- augmente le confort, mais n'est pas necessaire pour la premiere arrivee exploitable

## Matrice `must-have before home` vs `can-load-after-home`

| Charge | Categorie | Decision | Raison |
| --- | --- | --- | --- |
| `startupReady` | `must-have` | garder pre-home | prerequis systeme absolu |
| `networkAvailable` si flow reseau requis | `must-have` | garder pre-home | condition d'entree nominale |
| `sessionResolved` | `must-have` | garder pre-home | decide auth ou progression |
| `hasSession` ou issue auth explicite | `must-have` | garder pre-home | prerequis de parcours |
| `profilesResolved` | `must-have` | garder pre-home | prerequis de selection/continuite |
| `hasSelectedProfile` | `must-have` | garder pre-home | prerequis d'entree `home` |
| `sourcesResolved` | `must-have` | garder pre-home | prerequis de parcours |
| `hasSelectedSource` | `must-have` | garder pre-home | prerequis d'entree `home` |
| `selectedSourceValid` | `must-have` | garder pre-home | evite une `home` trompeuse |
| `catalogReady` minimal | `must-have` | garder pre-home | garantit une arrivee exploitable |
| `catalogHasContent` minimal | `must-have` derive | garder pre-home | permet `home` normale vs `home vide` |
| `libraryReady` minimal | `must-have` | garder pre-home | prerequis retenu par phase 3 |
| `homePreloaded` minimal | `must-have` | garder pre-home | prerequis retenu par phase 3 |
| catalogue exhaustif complet | `can-load-after-home` | sortir du tunnel | peut prendre `10-15 s` legitimes |
| enrichissements secondaires de bibliotheque | `can-load-after-home` | sortir du tunnel | non requis pour premiere arrivee |
| sections editoriales secondaires | `can-load-after-home` | sortir du tunnel | confort, pas prerequis |
| sync cloud non bloquante | `can-load-after-home` | sortir du tunnel | utile mais non critique pour premiere peinture utile |
| telemetry de confort / detail | `can-load-after-home` | sortir du tunnel | aucune valeur utilisateur immediate |
| preload de contenus annexes | `can-load-after-home` | sortir du tunnel | doit etre lazy ou background |

## Catalogue minimal exploitable

Le terme `catalogReady` doit maintenant etre compris comme:
- un sous-ensemble de donnees suffisant pour ouvrir `home`
- pas comme la totalite du catalogue provider

Le minimum exploitable pre-home peut inclure:
- existence valide de la source active
- metadonnees minimales de catalogue
- index ou snapshot minimal de navigation
- premiers blocs exploitables de contenu

Il n'inclut pas necessairement:
- la liste exhaustive de tous les contenus
- tous les enrichissements ou images
- tous les calculs derives de catalogue

## Charges a sortir explicitement du tunnel

Les charges suivantes sont recommandees pour sortie explicite du tunnel:

1. chargement complet du catalogue source
2. enrichissement profond de bibliotheque
3. sync cloud non critique
4. sections `home` secondaires non necessaires a la premiere interaction
5. post-traitements analytics non critiques

## Charges a garder explicitement dans le tunnel

Les charges suivantes doivent rester dans le tunnel:

1. bootstrap systeme
2. resolution session
3. resolution profil
4. resolution source
5. validation source active
6. preload minimal `catalogReady + libraryReady + homePreloaded`

## Optimisations de sequence recommandees

## 1. Paralleliser ce qui est independant

Recommandation:
- lancer en parallele tout ce qui ne depend pas d'un choix utilisateur

Candidats:
- verification connectivite
- restore session
- startup status
- certains chargements pre-home secondaires tant qu'ils restent annulables

## 2. Retarder le catalogue exhaustif

Recommandation:
- charger un snapshot minimal pre-home
- deferer le catalogue exhaustif apres `home`

Impact:
- gros gain sur `preloading_home`
- reduction du risque de tunnel percu comme lourd

## 3. Annuler les charges devenues inutiles

Recommandation:
- si le tunnel bifurque vers `auth_required`, `profile_required` ou `source_required`, annuler les charges pre-home non encore utiles

Impact:
- evite de gaspiller du temps et du reseau sur des charges qui seront invalidees

## 4. Prioriser les donnees de premiere peinture utile

Recommandation:
- trier les charges `home` en:
  - premiere peinture utile
  - enrichissement proche
  - enrichissement differe

Impact:
- meilleure predictibilite
- meilleur respect du budget `ready_for_home -> first_home_paint_useful`

## 5. Conserver `home vide` comme issue fonctionnelle

Recommandation:
- si le minimum pre-home est satisfait mais que le contenu est vide, entrer dans `home vide`

Impact:
- evite d'attendre inutilement un catalogue complet
- garde une issue produit claire

## Sequence cible du pre-home apres arbitrage

Sequence recommandee:

1. `startupReady`
2. `sessionResolved`
3. `profilesResolved + hasSelectedProfile`
4. `sourcesResolved + hasSelectedSource + selectedSourceValid`
5. `catalogReady minimal`
6. `libraryReady minimal`
7. `homePreloaded minimal`
8. entree dans `home`
9. chargements differes post-home

## Charges differees post-home

Une fois `home` ouverte, les charges suivantes peuvent continuer:

1. catalogue exhaustif complet
2. enrichissement de sections secondaires
3. sync cloud non critique
4. telemetry detaillee
5. caches et optimisations de confort

## Impacts sur les budgets de phase 4

Impacts directs:
- le budget `catalog_ready` de `4.1` s'applique au **minimum exploitable**
- le budget global `preloading_home <= 2500 ms` reste defendable
- le chargement `10-15 s` du catalogue complet sort des KPI pre-home

## Impacts sur l'instrumentation

La phase `4.4` devra distinguer:
- `catalog_minimal_ready`
- `catalog_full_load_started`
- `catalog_full_load_completed`

Sans cette distinction:
- les budgets pre-home seraient melanges avec le post-home
- la telemetry deviendrait trompeuse

## Points encore a arbitrer

Ces points ne bloquent pas `4.3`, mais devront etre precises ensuite:

1. quelle est la definition exacte du `catalogue minimal exploitable`
2. quelles sections de `home` doivent etre garanties a la premiere peinture utile
3. quelle part minimale de `libraryReady` doit rester pre-home

## Decision log

1. Le catalogue complet sort explicitement du tunnel.
2. `catalogReady` est redefini comme `catalogue minimal exploitable`.
3. `home vide` reste une issue valide si le minimum pre-home est satisfait.
4. Toute charge non critique pour la premiere arrivee utile doit etre differee.
5. Les charges differees devront etre instrumentees separement du pre-home.

## Verdict de sortie de la sous-phase 4.3

Verdict:
- la sous-phase `4.3` est suffisamment stable pour lancer `4.4`

Pourquoi:
- la frontiere `must-have / can-load-after-home` est maintenant explicite
- le catalogue complet est sorti du tunnel
- les optimisations de sequence principales sont cadrees

## Prochaine etape recommandee

La suite logique est:
1. instrumenter distinctement les charges pre-home et post-home
2. definir les evenements de mesure et reason codes
3. fiabiliser l'observabilite des seuils `nominal / slow / blocked`

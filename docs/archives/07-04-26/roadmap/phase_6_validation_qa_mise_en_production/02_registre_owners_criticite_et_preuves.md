# Registre - Owners, criticite et preuves minimales

## Objectif

Associer chaque epic critique a:
- un owner par role
- une criticite de changement
- une classe logicielle
- un niveau minimal de preuve
- un rollback attendu

Ce registre applique la doctrine des phases 3 a 5 et les regles de haute assurance du referentiel NASA/NIST.

## Owners par role

| Epic | Scope | Owner recommande | Reviewer principal recommande | Reviewer independant requis |
| --- | --- | --- | --- | --- |
| `A` | observabilite, reason codes, flags | lead observabilite / platform | lead architecture | oui si le lot impacte les signaux critiques |
| `B` | `TunnelState`, bridge, orchestrateur | lead architecture tunnel | lead routing ou domain | oui pour `B4` |
| `C` | contrats auth, profils, sources, pre-home | lead domain tunnel | lead architecture tunnel | oui pour `C4`, `C5` |
| `D` | projection routeur, guards, navigation | lead routing | lead architecture tunnel | oui pour `D2` |
| `E` | composants UI communs, focus TV | lead UI tunnel | lead UX/UI technique | non sauf si impact navigation/focus critique |
| `F` | surfaces `Preparation systeme`, `Auth`, `Profil` | lead UI tunnel | lead QA produit | non sauf si surface porte un safe state critique |
| `G` | hub source, ajout source, recovery | lead domaine source | lead UI tunnel | oui pour `G1`, `G2` |
| `H` | `Chargement medias`, separation minimal/full, cleanup | lead pre-home / startup | lead architecture tunnel | oui pour `H2`, `H4` |
| `QA` | campagnes, matrices, release checks | lead QA / release | lead architecture ou product | oui sur gate release final |

## Classification recommandee des lots sensibles

| Lot | Description courte | Criticite changement | Classe logicielle | Justification |
| --- | --- | --- | --- | --- |
| `A1` | telemetry tunnel existant | `C2` | `L3` | faux negatif possible sur pilotage du programme |
| `A2` | reason codes et correlation IDs | `C2` | `L3` | observabilite critique pour diagnostic |
| `B1` | modele `TunnelState` | `C2` | `L2` | source de verite future |
| `B2` | bridge `legacy -> TunnelState` | `C2` | `L2` | coexistence transitoire sensible |
| `B3` | orchestrateur shadow | `C2` | `L2` | derive critique mais non encore maitre |
| `B4` | bascule nouvelle source de verite | `C1` | `L2` | impact direct startup, routing, safe states |
| `C1` | contrat session/auth | `C1` | `L1` | auth et session |
| `C2` | contrat profils | `C2` | `L2` | blocage parcours possible |
| `C3` | contrat sources | `C2` | `L2` | prerequis du tunnel |
| `C4` | validation source / recovery | `C1` | `L2` | hotspot de robustesse et performance |
| `C5` | pre-home minimal | `C1` | `L2` | acces a `Home`, budgets critiques |
| `D1` | derive `TunnelSurface` | `C2` | `L2` | projection centrale |
| `D2` | routeur branche sur `TunnelSurface` | `C1` | `L2` | loops, blocage, surface incorrecte |
| `E1-E3` | composants UI communs | `C3` | `L3` | support UI, risque localise |
| `F1` | `Preparation systeme` | `C2` | `L2` | premier safe state visible |
| `F2` | `Auth` | `C1` | `L1` | auth visible et reprise session |
| `F3-F4` | profil | `C2` | `L2` | etapes obligatoires du tunnel |
| `G1` | hub source unifie | `C1` | `L2` | remplace plusieurs surfaces legacy |
| `G2` | ajout source + validation guidee | `C1` | `L2` | logique utilisateur + validation technique |
| `G3` | recovery source | `C2` | `L2` | issue claire en degrade |
| `H1` | `Chargement medias` | `C2` | `L2` | surface pre-home visible |
| `H2` | separation `minimal/full` | `C1` | `L2` | contrainte majeure de performance |
| `H3` | sortie preferences de la logique metier | `C2` | `L3` | nettoyage sensible mais localise |
| `H4` | cleanup final legacy | `C2` | `L3` | suppression irreversible potentielle |

## Niveau minimal de preuve par criticite

### Regle `C1`

Chaque lot `C1` doit avoir:
- 2 reviewers minimum
- 1 reviewer independant de l'auteur
- analyse de risque documentee
- plan de rollback explicite
- tests unitaires et integration adaptes
- verification de telemetry si le lot touche un stage critique
- evidence de bascule par flag si applicable

### Regle `C2`

Chaque lot `C2` doit avoir:
- 1 reviewer principal
- 1 verification independante recommandee
- tests adaptes au risque
- rollback documente si sous flag
- traceabilite requirement -> code -> test -> evidence

### Regle `C3-C4`

Chaque lot `C3-C4` doit avoir:
- revue par pair
- tests widget ou unit si logique
- verification qu'aucun effet de bord critique n'est introduit

## Mapping lots critiques -> rollback attendu

| Lot | Flag | Rollback minimal attendu |
| --- | --- | --- |
| `B4` | `entry_journey_state_model_v2` | retour a `destination + phase + status` |
| `D2` | `entry_journey_routing_v2` | retour `LaunchRedirectGuard` et derives legacy |
| `C4` | `entry_journey_source_hub_v2` | retour flux source legacy |
| `C5` | `entry_journey_prehome_v2` | retour pre-home historique borne aux limites connues |
| `G1` | `entry_journey_source_hub_v2` | retour `welcome/sources` + `welcome/sources/select` |
| `G2` | `entry_journey_source_hub_v2` | retour ajout source legacy |
| `H2` | `entry_journey_prehome_v2` | retour comportement historique si necessaire, avec telemetry active |
| `H4` | `entry_journey_cleanup_v2` | rollback par non activation du cleanup et conservation des ponts |

## Exigences de traceabilite minimale

Chaque PR significative doit referencer:
- le lot `A1-H4`
- la vague de livraison
- la criticite `C1-C4`
- la classe logicielle `L1-L4`
- le flag associe s'il existe
- le rollback attendu
- les tests obligatoires
- la documentation modifiee

## Verdict

Ce registre suffit a nominaliser la responsabilite avant implementation.

Il doit etre complete par des noms individuels uniquement si l'organisation du projet l'exige. La roadmap, elle, peut rester stable avec des owners par role.

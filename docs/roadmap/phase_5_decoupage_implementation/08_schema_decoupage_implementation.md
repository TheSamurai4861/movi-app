# Schema de synthese - Decoupage d'implementation

## Vue d'ensemble

La phase 5 convertit la refonte du tunnel en:
- lots executables
- vagues de livraison
- flags de bascule
- points de rollback
- nettoyage legacy borne

## Sequence de livraison

```text
Vague 0
  -> instrumentation / flags / modele de base
Vague 1
  -> coeur du tunnel
Vague 2
  -> projection routeur
Vague 3
  -> composants UI + surfaces amont
Vague 4
  -> bloc source
Vague 5
  -> pre-home borne
Vague 6
  -> nettoyage legacy
```

## Backlog ordonne simplifie

### Vague 0

- `A1` telemetry tunnel existant
- `A2` reason codes et correlation IDs
- `A3` flags techniques
- `B1` modele `TunnelState`
- `E1` shells et layout tunnel

### Vague 1

- `B2` bridge legacy -> `TunnelState`
- `B3` orchestrateur shadow
- `C1` contrat session/auth
- `C2` contrats profils
- `C3` contrats sources

### Vague 2

- `B4` bascule source de verite
- `D1` derive `TunnelSurface`
- `D2` routeur projete

### Vague 3

- `E2` composants de selection / feedback
- `E3` focus TV commun
- `F1` `Preparation systeme`
- `F2` `Auth`
- `F3` `Creation profil`
- `F4` `Choix profil`

### Vague 4

- `C4` validation source et recovery
- `G1` hub source unifie
- `G2` ajout source et validation guidee
- `G3` recovery source

### Vague 5

- `C5` contrat pre-home minimal
- `H1` `Chargement medias`
- `H2` separation `catalog minimal / catalog full`

### Vague 6

- `D3` simplification guards legacy
- `H3` preferences hors logique metier
- `H4` nettoyage final legacy

## Flags de bascule

| Flag | Porte quoi |
| --- | --- |
| `entry_journey_telemetry_v2` | telemetry cible |
| `entry_journey_state_model_v2` | coeur `TunnelState` / orchestrateur |
| `entry_journey_routing_v2` | projection routeur |
| `entry_journey_ui_v2` | surfaces amont + composants UI |
| `entry_journey_source_hub_v2` | bloc source |
| `entry_journey_prehome_v2` | pre-home borne |
| `entry_journey_cleanup_v2` | nettoyage final |

## Chemin critique

Le chemin critique simplifie est:

```text
A1 -> A2
   -> B1 -> B2 -> B3 -> B4
   -> C3 -> C4 -> C5
   -> D1 -> D2
   -> G1 -> G2 -> G3
   -> H1 -> H2
   -> D3 -> H3 -> H4
```

## Jalons

| Jalon | Condition |
| --- | --- |
| `J1` | mesure et coeur lisible |
| `J2` | nouveau coeur actif |
| `J3` | routing cible stable |
| `J4` | surfaces amont migrees |
| `J5` | bloc source cible |
| `J6` | pre-home borne |
| `J7` | tunnel cible propre |

## Lots les plus sensibles

- `B4` bascule source de verite
- `C4` validation source
- `C5` pre-home minimal
- `D2` routeur projete
- `G1` hub source unifie
- `G2` ajout / validation source
- `H2` separation pre-home / post-home
- `H4` nettoyage final legacy

## Regles de gouvernance

- pas de big bang
- pas d'activation simultanee des flags critiques
- pas de nettoyage legacy avant stabilisation des vagues precedentes
- pas de lot critique sans telemetry, test et rollback clairs

## Conclusion

La phase 5 fournit un plan d'execution:
- progressif
- mesurable
- rollbackable
- coherent avec les phases 1 a 4

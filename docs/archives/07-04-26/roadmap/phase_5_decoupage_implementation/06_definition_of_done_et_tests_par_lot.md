# Sous-phase 5.5 - Definition of done, tests et criteres de revue par lot

## Objectif

Rendre chaque lot de la phase 5:
- testable
- revuable
- fermable
- rollbackable

Cette sous-phase ne recree pas le backlog. Elle fixe le niveau minimal de preuve attendu avant de considerer qu'un lot est vraiment termine.

## Principe directeur

Un lot n'est pas `done` parce qu'il compile.

Un lot du tunnel est `done` seulement si:
- sa sortie observable existe
- ses risques critiques sont couverts
- sa telemetry est exploitable si le lot touche le chemin critique
- son rollback ou sa bascule est connue

## Regles globales de `definition of done`

Tout lot de la phase 5 doit respecter les points suivants:

1. le perimetre du lot reste lisible en une phrase
2. les fichiers cibles et la zone d'impact sont identifiables
3. au moins un comportement observable prouve que le lot est actif
4. la bascule par flag ou le rollback est documente si le lot est critique
5. la telemetry necessaire est presente si le lot touche le chemin critique
6. la documentation de migration est mise a jour si le lot modifie l'ordre de bascule

## Regles de test par categorie de lot

### Lots coeur domaine / orchestration

Exemples:
- `B1`
- `B2`
- `B3`
- `B4`
- `C1-C5`
- `D1-D2`

Attentes minimales:
- tests unitaires sur logique de decision
- tests de transitions ou derives critiques
- verification telemetry si le lot impacte un stage critique
- verification rollback si le lot est sous flag

### Lots UI communs

Exemples:
- `E1`
- `E2`
- `E3`

Attentes minimales:
- tests widget des etats principaux
- verification mobile / TV
- verification focus si pertinent
- verification qu'aucune logique metier n'est reenfouie dans le composant

### Lots surfaces tunnel

Exemples:
- `F1-F4`
- `G1-G3`
- `H1-H2`

Attentes minimales:
- tests widget ou integration par surface
- verification de l'etat nominal
- verification d'au moins un etat degrade ou recovery si la surface en porte
- verification de la projection de surface depuis le state

### Lots cleanup / migration

Exemples:
- `D3`
- `H3`
- `H4`

Attentes minimales:
- preuve qu'aucun consumer critique du legacy ne reste
- verification des flags et rollback residuels
- verification qu'aucune route ou provider cle n'est orphelin

## Checklist de revue commune a tous les lots

Chaque revue de lot doit verifier:

- le lot respecte son objectif unique
- la taille du diff reste defendable
- les dependances du lot n'ont pas ete etendues sans raison
- le flag ou rollback du lot est clair si necessaire
- la telemetry ajoutee ou modifiee est correcte si attendue
- la documentation roadmap est encore coherente

## Definition of done par famille de lots

## Famille A - Observabilite et securisation de migration

Lots:
- `A1`
- `A2`
- `A3`

Definition of done:
- les evenements cibles sont effectivement emis
- les `reason_codes` et `journey_run_id` sont lisibles dans les sorties
- les flags existent et sont testables localement
- aucun changement UX non voulu n'est introduit

Tests minimum:
- unit ou integration sur emission d'evenements
- verification manuelle de presence des champs critiques
- test simple d'activation / desactivation des flags

Fragilites a surveiller:
- telemetry branchee trop tard dans le cycle
- flags sans vraie couverture de bascule

## Famille B - Coeur de tunnel: etat et orchestration

Lots:
- `B1`
- `B2`
- `B3`
- `B4`

Definition of done:
- les transitions ou derives critiques du lot sont testees
- la sortie du lot est observable sans l'UI finale
- le nouveau coeur ne cree pas de double source de verite durable
- les reason codes importants sont portes correctement

Tests minimum:
- unit tests de transitions et derives
- tests d'integration legers sur le bridge legacy
- verification comparee legacy / nouveau coeur pour `B2-B3`
- verification de bascule et rollback pour `B4`

Fragilites a surveiller:
- `B4` est un lot a risque eleve
- aucune revue rapide ne doit accepter `B4` sans preuve de comportement nominal et degrade

## Famille C - Contrats metier du tunnel

Lots:
- `C1`
- `C2`
- `C3`
- `C4`
- `C5`

Definition of done:
- le port ou contrat du lot est branche a la bonne source
- le resultat du contrat distingue nominal, degrade et blocked si attendu
- les timeouts / retries du lot respectent la phase 4
- la sortie du lot alimente correctement le coeur du tunnel

Tests minimum:
- unit tests sur resultats de ports / adapters
- tests d'integration pour les contrats critiques reseau
- cas limites:
  - session absente / expiree
  - profil manquant
  - source absente / invalide
  - `catalog minimal ready`

Fragilites a surveiller:
- `C4` validation source
- `C5` separation `catalog minimal / catalog full`

## Famille D - Projection routeur et navigation

Lots:
- `D1`
- `D2`
- `D3`

Definition of done:
- la projection `TunnelSurface` est stable
- le routeur ne recalcule plus de logique metier qu'il ne devrait pas porter
- les redirections critiques sont testees
- le guard historique peut encore servir de filet pendant la migration si necessaire

Tests minimum:
- tests de mapping `TunnelState -> surface`
- tests integration ou golden navigation sur cas cold / warm
- verification explicite de l'absence de loop de redirect

Fragilites a surveiller:
- `D2` est critique
- `D3` ne doit pas partir tant que les surfaces finales ne sont pas stabilisees

## Famille E - Composants UI communs

Lots:
- `E1`
- `E2`
- `E3`

Definition of done:
- les composants respectent la spec UI phase 2
- ils restent decouples de la logique de parcours
- ils marchent sur mobile et TV
- ils supportent correctement focus et etats inline si attendus

Tests minimum:
- widget tests de structure et etats
- verification de focus pour `E3`
- verification de coherence visuelle minimale

Fragilites a surveiller:
- regression de focus TV
- duplication d'anciennes patterns UI dans les nouveaux composants

## Famille F - Surfaces amont

Lots:
- `F1`
- `F2`
- `F3`
- `F4`

Definition of done:
- la surface lit le nouvel etat ou contrat attendu
- la surface respecte la structure UI cible
- au moins un cas de recovery critique de la surface est couvert si applicable
- la surface peut etre reactiver / desactiver par flag si prevu

Tests minimum:
- widget tests par surface
- integration sur navigation depuis le routeur projete
- cas critiques:
  - `offline` pour `F1`
  - `auth_required` pour `F2`
  - `profile_required` pour `F3-F4`

Fragilites a surveiller:
- `F1` car il porte le premier safe state visible

## Famille G - Bloc source

Lots:
- `G1`
- `G2`
- `G3`

Definition of done:
- le hub source unifie remplace bien l'ancien decoupage
- la validation source est bornee
- les etats `source_required` et `source_recovery_required` sont correctement servis
- le rollback vers l'ancien flux source reste possible tant que le flag existe

Tests minimum:
- integration sur choix / ajout / changement de source
- cas degrade:
  - source invalide
  - timeout validation
  - retry
- verification TV du focus et de la selection

Fragilites a surveiller:
- `G1` et `G2` sont les plus exposes aux regressions produit

## Famille H - Pre-home et cleanup

Lots:
- `H1`
- `H2`
- `H3`
- `H4`

Definition of done:
- `H1-H2`: `Home` n'attend plus le catalogue complet
- `H3`: les preferences ne pilotent plus la logique metier
- `H4`: les ponts legacy retires ne sont plus references

Tests minimum:
- integration `preloading_home -> Home`
- verification telemetry `catalog_minimal_ready` / `catalog_full_load_completed`
- verification `time_to_safe_state`
- verification grep / compile / usages pour `H4`

Fragilites a surveiller:
- `H2` pour la separation pre/post-home
- `H4` pour le risque de lot fourre-tout

## Criteres de revue renforces pour les lots critiques

Les lots suivants demandent une revue plus stricte:
- `B4`
- `C4`
- `C5`
- `D2`
- `G1`
- `G2`
- `H2`
- `H4`

Pour ces lots, la revue doit verifier explicitement:
- preuve de comportement nominal
- preuve de comportement degrade ou recovery si applicable
- impact routing si present
- rollback ou flag de bascule
- telemetry associee

## Tableau synthetique par lot

| Lot | Tests minimum | Telemetry requise | Rollback / flag requis | Niveau de vigilance |
| --- | --- | --- | --- | --- |
| `A1-A2` | integration mesure | oui | non critique | moyen |
| `A3` | config / activation | non | oui | moyen |
| `B1-B3` | unit + integration legere | oui | oui | eleve |
| `B4` | unit + integration + bascule | oui | oui | tres eleve |
| `C1-C3` | unit + integration | oui | selon flag coeur | eleve |
| `C4-C5` | integration + cas limites | oui | oui | tres eleve |
| `D1` | unit mapping | oui | oui | eleve |
| `D2` | integration navigation | oui | oui | tres eleve |
| `D3` | integration + grep usages | utile | oui | eleve |
| `E1-E3` | widget | non obligatoire sauf si etat critique | via `ui_v2` | moyen |
| `F1-F4` | widget + integration | utile | via `ui_v2` | eleve |
| `G1-G3` | integration + recovery | oui | via `source_hub_v2` | tres eleve |
| `H1-H2` | integration pre-home | oui | via `prehome_v2` | tres eleve |
| `H3-H4` | integration + usages residuels | utile | via `cleanup_v2` | tres eleve |

## Zones encore fragiles

Malgre cette definition, certaines zones resteront plus fragiles:
- la preuve de non-regression routing
- la preuve de separation pre-home / post-home
- la suppression finale des usages legacy reels
- la validation source sur reseau lent ou incoherent

## Verdict

La sous-phase `5.5` est suffisamment stable si l'on retient ces points:
- chaque famille de lots a maintenant une `definition of done`
- les attentes de test sont explicites
- les criteres de revue sont homogenes
- les lots critiques ont un niveau de preuve renforce

La suite logique est la sous-phase `5.6`, pour assembler backlog, dependances, flags et migrations dans un plan de migration consolide.

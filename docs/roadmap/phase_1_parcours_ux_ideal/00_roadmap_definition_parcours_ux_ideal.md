# Roadmap detaillee - Phase 1 : Definition du parcours UX ideal

## Role de ce document

Ce document detaille la `Phase 1 - Definition du parcours UX ideal` de la roadmap principale:
- [refonte_parcours_welcome_auth_source_prehome.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/refonte_parcours_welcome_auth_source_prehome.md)

Il sert a cadrer le travail de conception UX avant toute refonte UI lourde ou implementation technique du tunnel d'entree.

## Objectif

Decider, documenter et valider le chemin utilisateur cible entre l'ouverture de l'application et l'entree dans `home`, en reduisant les embranchements opaques et en rendant chaque etape utile, explicite et coherente.

Cette phase doit repondre a quatre questions:
- quel est le chemin nominal ideal si tout va bien
- quelles branches alternatives sont legitimes
- quels ecrans doivent exister, fusionner ou disparaitre
- quelle information doit etre visible a chaque instant pour mobile et TV

## Perimetre

Inclus:
- `launch` / bootstrap
- `auth`
- `profile`
- `sources`
- `source selection`
- `source loading`
- `pre-home`

Exclus:
- la refonte fonctionnelle de `home`
- les surfaces browse apres l'arrivee sur `home`
- le detail d'implementation technique de l'orchestrateur

## Etat de depart a challenger

Le tunnel actuel expose au moins ces etapes:
- `/launch`
- `/welcome/user`
- `/auth/otp`
- `/welcome/sources`
- `/welcome/sources/select`
- `/welcome/sources/loading`
- transition vers `/`

Les points a challenger pendant cette phase:
- `welcome/user` et `auth/otp` doivent-ils rester separes
- `welcome/sources` et `welcome/sources/select` doivent-ils fusionner
- `welcome/sources/loading` doit-il rester une page pleine ou devenir un etat inline
- quels cas de recovery meritent un ecran dedie vs une banniere vs un bloc inline
- quelles etapes doivent etre invisibles quand l'utilisateur est deja valide

## Resultat attendu en fin de phase

A la fin de cette phase, l'equipe doit disposer de:
- un blueprint UX du tunnel cible
- un flux nominal valide
- une matrice des flux alternatifs
- une fiche de cadrage par ecran cible
- des wireframes basse fidelite
- une decision explicite sur les fusions, suppressions et etats inline

## Avancement courant

- sous-phase `1.0` : complete
- sous-phase `1.1` : complete via [03_blueprint_ux_tunnel_cible.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_1_parcours_ux_ideal/03_blueprint_ux_tunnel_cible.md)
- sous-phase `1.2` : complete via [04_user_flows_tunnel_entree.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_1_parcours_ux_ideal/04_user_flows_tunnel_entree.md)
- sous-phase `1.3` : complete via [05_contrat_ux_par_ecran.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_1_parcours_ux_ideal/05_contrat_ux_par_ecran.md)
- sous-phase `1.4` : complete via [06_decisions_fusion_suppression_inline.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_1_parcours_ux_ideal/06_decisions_fusion_suppression_inline.md)
- sous-phase `1.5` : complete via [07_microcopy_messages_critiques.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_1_parcours_ux_ideal/07_microcopy_messages_critiques.md)
- sous-phase `1.6` : complete via [08_wireframes_low_fi_tunnel_entree.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_1_parcours_ux_ideal/08_wireframes_low_fi_tunnel_entree.md)
- sous-phase `1.7` : complete via [09_validation_finale_phase_1.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_1_parcours_ux_ideal/09_validation_finale_phase_1.md)

## Sequence de travail recommandee

### Sous-phase 1.0 - Preparation et alignement

But: partir d'une base commune avant de redesigner le parcours.

Travaux:
- relire la roadmap principale et figer le perimetre exact de la phase
- reprendre les ecrans et routes reelles du tunnel existant
- rassembler les contraintes fortes deja connues:
  - session et auth
  - profils
  - sources IPTV
  - offline et recovery
  - mobile et TV
- lister les decisions deja prises et celles encore ouvertes

Livrables:
- liste des ecrans a traiter
- liste des contraintes produit et plateforme
- liste des questions UX ouvertes

Gate:
- plus aucune ambiguite sur le perimetre de la phase

### Sous-phase 1.1 - Dessin du flux nominal ideal

But: produire le chemin principal a viser quand l'utilisateur est dans un etat sain.

Travaux:
- definir le point d'entree ideal apres ouverture de l'app
- definir la sequence minimale avant `home`
- reduire le nombre d'etapes visibles pour:
  - utilisateur deja authentifie
  - profil deja connu
  - source deja active
  - preload non bloquant
- formaliser la logique "next best action" a chaque etat

Questions a trancher:
- quel est l'ecran le plus probable apres `launch`
- quelle etape peut etre sautee automatiquement
- quelle etape doit toujours rester visible pour rassurer ou orienter

Livrables:
- diagramme du flux nominal cible
- principe de routage UX "one clear next step"

Gate:
- le flux nominal ne contient aucune etape redondante ou sans valeur utilisateur

### Sous-phase 1.2 - Definition des flux alternatifs

But: expliciter les branches autorisees sans multiplier les cas speciaux opaques.

Scenarios minimum a traiter:
- premier lancement
- session valide
- session expiree
- session non verifiable mais retryable
- utilisateur offline au lancement
- aucun profil
- aucun source
- une seule source disponible
- plusieurs sources disponibles
- echec de connexion source
- echec de preload recuperable

Travaux:
- decrire pour chaque scenario:
  - etat detecte
  - ecran ou variante cible
  - message visible
  - action primaire
  - action secondaire
  - issue attendue
- distinguer:
  - branche legitime
  - simple etat inline
  - erreur bloquante
  - recovery non bloquante

Livrables:
- matrice des flux alternatifs
- table de decision UX par contexte

Gate:
- chaque branche alternative a une raison explicite, un message clair et une sortie unique

### Sous-phase 1.3 - Contrat UX par ecran

But: decrire chaque ecran cible avant de le dessiner visuellement.

Ecrans cibles a cadrer au minimum:
- `launch / bootstrap`
- `auth`
- `profile setup or confirmation`
- `source hub`
- `source selection`
- `source sync / pre-home`
- `recovery state` si un ecran dedie reste necessaire

Pour chaque ecran, produire:
- objectif unique
- precondition d'entree
- information critique a afficher
- action primaire
- action secondaire
- action de retour ou d'annulation
- condition de sortie
- comportement mobile
- comportement TV
- version nominale
- version degradee

Livrables:
- fiche de cadrage par ecran

Gate:
- aucun ecran n'a plus d'un objectif principal

### Sous-phase 1.4 - Decisions de simplification structurelle

But: arbitrer ce qui doit etre fusionne, supprime ou converti en etat inline.

Decisions attendues:
- `welcome/user` + `auth/otp`
- `welcome/sources` + `welcome/sources/select`
- `welcome/sources/loading` comme page ou comme etat dans le meme ecran source
- `LaunchRecoveryBanner` comme pattern transverse ou comme logique specifique par ecran
- place des erreurs de session et de preload: full page, banner, sheet ou inline card

Critere de decision:
- moins de friction
- moins de changements de contexte
- meilleure comprehension immediate
- meilleure compatibilite TV
- moindre cout technique futur

Livrables:
- decision log des fusions et suppressions
- mapping `existant -> cible`

Gate:
- chaque ecran existant a une destination cible explicite: conserve, fusionne, supprime ou converti

### Sous-phase 1.5 - Microcopy et messages systeme

But: rendre le tunnel lisible meme en cas d'etat sensible ou degrade.

Travaux:
- definir les messages critiques du tunnel
- harmoniser ton, longueur et clarte des messages
- separer:
  - message de progression
  - message d'erreur
  - message de blocage
  - message de recovery
  - message de confirmation
- limiter le vocabulaire technique visible

Zones minimum a couvrir:
- verification de session
- demande d'auth
- code OTP envoye / verification
- aucun profil
- aucune source
- plusieurs sources
- sync source en cours
- tentative de recuperation
- mode degrade
- echec recuperable

Livrables:
- table de microcopy critique
- principes de ton et de formulation

Gate:
- chaque message critique explique clairement ce qui se passe et quoi faire ensuite

### Sous-phase 1.6 - Wireframes basse fidelite

But: traduire les decisions UX en structures d'ecrans simples et testables.

Travaux:
- dessiner la version low-fi de chaque ecran cible
- dessiner les variantes importantes si la structure change vraiment
- privilegier la hierarchie, les actions et l'information critique
- verifier la lisibilite mobile et TV des layouts

Livrables:
- wireframes basse fidelite du flux nominal
- wireframes des variantes majeures

Gate:
- chaque wireframe confirme un chemin clair, une information priorisee et une action dominante

### Sous-phase 1.7 - Consolidation et validation

But: sortir de la phase avec une cible exploitable par la suite.

Travaux:
- consolider le blueprint final
- verifier la coherence entre flux, ecrans, microcopy et wireframes
- revalider les decisions de fusion et suppression
- identifier les questions restantes qui relevent de la phase UI ou architecture

Livrables:
- blueprint UX final
- recap des decisions
- liste des points deferes vers phase 2 ou phase 3

Gate:
- le parcours UX ideal est valide comme cible de travail

## Artefacts a produire dans ce dossier

Le dossier `docs/roadmap/phase_1_parcours_ux_ideal/` est prevu pour accueillir a terme:
- `00_roadmap_definition_parcours_ux_ideal.md`
- `01_preparation_alignement.md`
- `02_workflow_accueil_mermaid_professional.md`
- `03_blueprint_ux_tunnel_cible.md`
- `04_user_flows_tunnel_entree.md`
- `05_contrat_ux_par_ecran.md`
- `06_decisions_fusion_suppression_inline.md`
- `07_microcopy_messages_critiques.md`
- `08_wireframes_low_fi_tunnel_entree.md`
- `09_validation_finale_phase_1.md`

## Workflow retenu

Le workflow d'accueil retenu pour la suite de la phase est:
- [02_workflow_accueil_mermaid_professional.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_1_parcours_ux_ideal/02_workflow_accueil_mermaid_professional.md)
- [02_workflow_accueil_mermaid_professional.png](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_1_parcours_ux_ideal/02_workflow_accueil_mermaid_professional.png)

Decision actee:
- cette version devient la reference de travail pour les prochaines sous-phases
- les anciennes versions Mermaid plus brouillonnes sont retirees du dossier de travail

## Matrice de travail par ecran

### 1. Launch / Bootstrap

Questions a resoudre:
- faut-il montrer un ecran dedie ou seulement un etat tres bref
- quelle progression est utile a afficher
- a quel moment faut-il montrer un recovery explicite

Sortie attendue:
- cadrage UX du point d'entree systeme

### 2. Auth

Questions a resoudre:
- l'OTP reste-t-il un ecran autonome
- l'auth doit-elle etre inline dans l'etape utilisateur
- quelle information rassure sans ralentir

Sortie attendue:
- contrat UX de l'etape d'authentification

### 3. Profile

Questions a resoudre:
- cette etape est-elle autonome ou absorbee par l'auth / welcome
- quand faut-il creer un profil vs confirmer un profil
- comment eviter un ecran visible si tout est deja pret

Sortie attendue:
- regle d'apparition UX de l'etape profil

### 4. Source Hub

Questions a resoudre:
- faut-il un seul ecran pour ajouter, voir et activer une source
- quelle priorite entre "ajouter" et "activer"
- comment traiter les sources sauvegardees sans surcharger l'ecran

Sortie attendue:
- structure UX cible du hub source

### 5. Source Selection

Questions a resoudre:
- doit-elle rester separee du hub source
- quand est-elle utile vs superflue
- quelle navigation est la plus naturelle sur TV

Sortie attendue:
- decision de separation ou de fusion

### 6. Source Loading / Pre-home

Questions a resoudre:
- page dediee, overlay ou etat embarque
- quand montrer le progres reel
- quand autoriser "continuer quand meme"

Sortie attendue:
- modele UX de transition finale vers `home`

## Rythme recommande

Ordre conseille:
1. flux nominal
2. flux alternatifs
3. contrat par ecran
4. decisions de fusion/suppression
5. microcopy critique
6. wireframes low-fi
7. validation finale

## Prompts a me redonner pour lancer chaque sous-phase

Tu peux copier-coller ces prompts tels quels pour demarrer chaque sous-phase.

### Lancer la sous-phase 1.0

```text
Nous lancons la sous-phase 1.0 de preparation et alignement pour le tunnel welcome -> auth -> source -> pre-home.
Travaille sur cette sous-phase uniquement.
Je veux:
- la liste des ecrans et routes a traiter
- la liste des contraintes produit et plateforme
- la liste des questions UX encore ouvertes
- les ambiguities restantes a lever avant la sous-phase 1.1
Mets a jour la documentation dans docs/roadmap/phase_1_parcours_ux_ideal/ si necessaire.
```

### Lancer la sous-phase 1.1

```text
Nous lancons la sous-phase 1.1 sur le flux nominal ideal du tunnel welcome -> auth -> source -> pre-home.
Travaille sur cette sous-phase uniquement.
Je veux:
- le flux principal etape par etape
- les etapes visibles vs invisibles
- les etapes qui peuvent etre sautees automatiquement
- les points de decision qui restent a arbitrer
- les impacts sur mobile et TV
Mets a jour la documentation de la phase 1 si necessaire.
```

### Lancer la sous-phase 1.2

```text
Nous lancons la sous-phase 1.2 sur les flux alternatifs du tunnel welcome -> auth -> source -> pre-home.
Travaille sur cette sous-phase uniquement.
Je veux:
- les scenarios minimum a couvrir
- pour chaque scenario: etat detecte, ecran cible, message visible, action primaire, action secondaire, issue attendue
- la distinction entre branche legitime, etat inline, erreur bloquante et recovery non bloquante
- les incoherences ou duplications a supprimer
Mets a jour la documentation dans le dossier phase_1_parcours_ux_ideal.
```

### Lancer la sous-phase 1.3

```text
Nous lancons la sous-phase 1.3 sur le contrat UX par ecran du tunnel welcome -> auth -> source -> pre-home.
Travaille sur cette sous-phase uniquement.
Redige le cadrage UX de chaque ecran cible du tunnel.
Je veux pour chaque ecran:
- objectif unique
- precondition d'entree
- information critique a afficher
- action primaire
- action secondaire
- action de retour ou d'annulation
- condition de sortie
- comportement mobile
- comportement TV
- variante nominale et degradee
Signale les ecrans qui ont encore plus d'un objectif principal.
```

### Lancer la sous-phase 1.4

```text
Nous lancons la sous-phase 1.4 sur les decisions de simplification structurelle du tunnel welcome -> auth -> source -> pre-home.
Travaille sur cette sous-phase uniquement.
Arbitre et documente les decisions de fusion, suppression ou conversion inline pour les ecrans du tunnel.
Je veux:
- le mapping existant -> cible
- les ecrans a conserver
- les ecrans a fusionner
- les ecrans a supprimer
- les etats a convertir en inline
- les raisons UX et produit de chaque decision
- les impacts mobile, TV et architecture
Mets a jour la documentation de phase 1 avec un decision log explicite.
```

### Lancer la sous-phase 1.5

```text
Nous lancons la sous-phase 1.5 sur la microcopy et les messages systeme du tunnel d'entree.
Travaille sur cette sous-phase uniquement.
Prepare la table de microcopy critique du tunnel d'entree.
Je veux:
- les messages de progression
- les messages d'erreur
- les messages de blocage
- les messages de recovery
- les messages de confirmation
- le ton recommande
- les formulations a eviter
Le tout doit rester premium, clair, court et actionnable.
```

### Lancer la sous-phase 1.6

```text
Nous lancons la sous-phase 1.6 sur les wireframes basse fidelite du tunnel welcome -> auth -> source -> pre-home.
Travaille sur cette sous-phase uniquement.
Transforme les decisions UX en wireframes low-fi textuels pour chaque ecran du tunnel.
Je veux:
- une structure d'ecran claire
- la hierarchie des blocs
- l'action primaire dominante
- les variantes majeures
- les differences mobile vs TV
- les points ou un ecran dedie doit devenir un etat inline
Mets a jour la documentation du dossier phase_1_parcours_ux_ideal.
```

### Lancer la sous-phase 1.7

```text
Nous lancons la sous-phase 1.7 de consolidation et validation de la phase 1.
Travaille sur cette sous-phase uniquement.
Fais la synthese finale de la phase 1 et prepare la transition vers la phase 2 et la phase 3.
Je veux:
- le blueprint UX final du tunnel cible
- le recap des decisions prises
- les questions deferrees a la phase UI
- les questions deferrees a la phase architecture
- les risques restants
- la liste des artefacts finaux produits dans docs/
Dis explicitement si la phase 1 est suffisamment stable pour passer a la suite.
```

## Prompts a me redonner a la fin de chaque sous-phase

Tu peux copier-coller ces prompts tels quels pour me faire enchainer proprement.

### Fin de la sous-phase 1.0

```text
Nous avons termine la sous-phase 1.0 de preparation et alignement.
Fais la synthese de cette sous-phase pour le tunnel welcome -> auth -> source -> pre-home.
Je veux:
- la liste des ecrans et routes a traiter
- la liste des contraintes produit et plateforme
- la liste des questions UX encore ouvertes
- les ambiguities restantes a lever avant la sous-phase 1.1
Mets a jour la documentation dans docs/roadmap/phase_1_parcours_ux_ideal/ si necessaire.
```

### Fin de la sous-phase 1.1

```text
Nous avons termine la sous-phase 1.1 sur le flux nominal ideal.
Propose le parcours UX nominal cible entre launch et pre-home.
Je veux:
- le flux principal etape par etape
- les etapes visibles vs invisibles
- les etapes qui peuvent etre sautees automatiquement
- les points de decision qui restent a arbitrer
- les impacts sur mobile et TV
Mets a jour la documentation de la phase 1 si necessaire.
```

### Fin de la sous-phase 1.2

```text
Nous avons termine la sous-phase 1.2 sur les flux alternatifs.
Construis la matrice des variantes du tunnel welcome -> auth -> source -> pre-home.
Je veux:
- les scenarios minimum a couvrir
- pour chaque scenario: etat detecte, ecran cible, message visible, action primaire, action secondaire, issue attendue
- la distinction entre branche legitime, etat inline, erreur bloquante et recovery non bloquante
- les incoherences ou duplications a supprimer
Mets a jour la documentation dans le dossier phase_1_parcours_ux_ideal.
```

### Fin de la sous-phase 1.3

```text
Nous avons termine la sous-phase 1.3 sur le contrat UX par ecran.
Redige le cadrage UX de chaque ecran cible du tunnel.
Je veux pour chaque ecran:
- objectif unique
- precondition d'entree
- information critique a afficher
- action primaire
- action secondaire
- action de retour ou d'annulation
- condition de sortie
- comportement mobile
- comportement TV
- variante nominale et degradee
Signale les ecrans qui ont encore plus d'un objectif principal.
```

### Fin de la sous-phase 1.4

```text
Nous avons termine la sous-phase 1.4 sur les decisions de simplification structurelle.
Arbitre et documente les decisions de fusion, suppression ou conversion inline pour les ecrans du tunnel.
Je veux:
- le mapping existant -> cible
- les ecrans a conserver
- les ecrans a fusionner
- les ecrans a supprimer
- les etats a convertir en inline
- les raisons UX et produit de chaque decision
- les impacts mobile, TV et architecture
Mets a jour la documentation de phase 1 avec un decision log explicite.
```

### Fin de la sous-phase 1.5

```text
Nous avons termine la sous-phase 1.5 sur la microcopy et les messages systeme.
Prepare la table de microcopy critique du tunnel d'entree.
Je veux:
- les messages de progression
- les messages d'erreur
- les messages de blocage
- les messages de recovery
- les messages de confirmation
- le ton recommande
- les formulations a eviter
Le tout doit rester premium, clair, court et actionnable.
```

### Fin de la sous-phase 1.6

```text
Nous avons termine la sous-phase 1.6 sur les wireframes basse fidelite.
Transforme les decisions UX en wireframes low-fi textuels pour chaque ecran du tunnel.
Je veux:
- une structure d'ecran claire
- la hierarchie des blocs
- l'action primaire dominante
- les variantes majeures
- les differences mobile vs TV
- les points ou un ecran dedie doit devenir un etat inline
Mets a jour la documentation du dossier phase_1_parcours_ux_ideal.
```

### Fin de la sous-phase 1.7

```text
Nous avons termine la sous-phase 1.7 de consolidation et validation.
Fais la synthese finale de la phase 1 et prepare la transition vers la phase 2 et la phase 3.
Je veux:
- le blueprint UX final du tunnel cible
- le recap des decisions prises
- les questions deferrees a la phase UI
- les questions deferrees a la phase architecture
- les risques restants
- la liste des artefacts finaux produits dans docs/
Dis explicitement si la phase 1 est suffisamment stable pour passer a la suite.
```

## Risques a eviter pendant cette phase

- dessiner l'UI avant d'avoir fige les etats et les branches
- conserver des ecrans historiques par inertie
- confondre besoin technique et besoin visible utilisateur
- sous-traiter la TV a une simple adaptation du mobile
- multiplier les messages systeme verbeux ou peu actionnables
- laisser survivre plusieurs actions primaires sur un meme ecran

## Criteres de sortie de la phase

La phase est terminee seulement si:
- un flux nominal ideal est valide
- chaque branche alternative est justifiee
- chaque ecran cible a un objectif unique
- les ecrans existants ont tous une destination cible explicite
- la microcopy critique est definie
- les wireframes basse fidelite couvrent le flux nominal et les variantes majeures
- les sujets restants sont clairement deferes vers la phase 2 ou 3

## Prochaine etape recommandee

Apres validation de cette roadmap detaillee, produire d'abord:
1. `03_blueprint_ux_tunnel_cible.md`
2. `04_user_flows_tunnel_entree.md`
3. `06_decisions_fusion_suppression_inline.md`

Les wireframes low-fi peuvent ensuite etre realises sur une base deja stable.

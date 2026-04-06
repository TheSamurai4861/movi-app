# Phase 2 - Cible UI/UX et systeme visuel

## Objectif

Transformer les decisions de la phase 1 en specification d'interface exploitable, coherente et implementable pour le tunnel d'entree `welcome -> auth -> source -> pre-home`.

La phase 2 ne re-ouvre pas les grands arbitrages de parcours. Elle part des decisions deja actees pour produire:
- une direction visuelle claire
- une structure d'ecran cible
- un systeme de composants reutilisables
- des regles responsive, accessibilite et TV
- une checklist directement exploitable par l'implementation

## Entrees de reference

La phase 2 s'appuie directement sur les artefacts valides de la phase 1:
- [09_validation_finale_phase_1.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_1_parcours_ux_ideal/09_validation_finale_phase_1.md)
- [03_blueprint_ux_tunnel_cible.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_1_parcours_ux_ideal/03_blueprint_ux_tunnel_cible.md)
- [04_user_flows_tunnel_entree.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_1_parcours_ux_ideal/04_user_flows_tunnel_entree.md)
- [05_contrat_ux_par_ecran.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_1_parcours_ux_ideal/05_contrat_ux_par_ecran.md)
- [06_decisions_fusion_suppression_inline.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_1_parcours_ux_ideal/06_decisions_fusion_suppression_inline.md)
- [07_microcopy_messages_critiques.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_1_parcours_ux_ideal/07_microcopy_messages_critiques.md)
- [08_wireframes_low_fi_tunnel_entree.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_1_parcours_ux_ideal/08_wireframes_low_fi_tunnel_entree.md)

## Resultat attendu

A la fin de la phase 2:
- chaque ecran du tunnel a une structure cible lisible
- la hierarchie visuelle est stable
- les composants communs sont identifies avant implementation
- mobile et TV ont des regles claires, sans derive opportuniste pendant le dev
- les etats de chargement, erreur, recovery et empty state ont un traitement visuel coherent

## Avancement courant

- sous-phase `2.0` : complete via [01_preparation_alignement_ui.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_2_cible_ui_ux_systeme_visuel/01_preparation_alignement_ui.md)
- sous-phase `2.1` : complete via [02_direction_visuelle_tunnel.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_2_cible_ui_ux_systeme_visuel/02_direction_visuelle_tunnel.md)
- sous-phase `2.2` : complete via [03_hierarchie_visuelle_ecrans.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_2_cible_ui_ux_systeme_visuel/03_hierarchie_visuelle_ecrans.md)
- sous-phase `2.3` : complete via [04_systeme_composants_tunnel.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_2_cible_ui_ux_systeme_visuel/04_systeme_composants_tunnel.md)
- sous-phase `2.4` : complete via [05_etats_feedback_et_motion.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_2_cible_ui_ux_systeme_visuel/05_etats_feedback_et_motion.md)
- sous-phase `2.5` : complete via [06_responsive_accessibilite_et_tv.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_2_cible_ui_ux_systeme_visuel/06_responsive_accessibilite_et_tv.md)
- sous-phase `2.6` : complete via [07_spec_ui_tunnel.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_2_cible_ui_ux_systeme_visuel/07_spec_ui_tunnel.md) et [08_checklist_implementation_ui_ux.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_2_cible_ui_ux_systeme_visuel/08_checklist_implementation_ui_ux.md)
- sous-phase `2.7` : complete via [09_validation_finale_phase_2.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_2_cible_ui_ux_systeme_visuel/09_validation_finale_phase_2.md)

## Principes directeurs de la phase 2

- `UX decisions stay fixed`: la phase 2 precise la forme, pas le parcours.
- `One visual language`: un seul systeme visuel pour tout le tunnel.
- `Hierarchy before decoration`: priorite a la clarte des actions et des etats.
- `Action-first surfaces`: chaque ecran doit rendre evidente l'action principale.
- `Mobile and TV by design`: pas de portage TV tardif.
- `States are part of the design`: chargement, erreur, retry et empty state font partie du systeme, pas des ajouts.
- `Implementation-ready`: chaque sortie doit pouvoir nourrir une story ou une spec de composant.

## Sous-phases proposees

### Sous-phase 2.0 - Preparation et alignement UI

But: cadrer les contraintes de design avant de produire de la spec visuelle.

Travaux:
- relire les artefacts de la phase 1 utiles a la phase UI
- lister les ecrans cibles et les variantes deja actees
- recenser les contraintes fortes:
  - mobile
  - TV
  - accessibilite
  - focus telecommande
  - densite d'information
  - temps de comprehension
- lister les decisions de parcours qui ne doivent plus etre remises en question
- identifier les arbitrages encore ouverts purement visuels

Livrables:
- liste des surfaces UI a specifier
- liste des contraintes de design et d'accessibilite
- liste des arbitrages visuels encore ouverts

Gate:
- le perimetre de la phase UI est verrouille
- aucune ambiguite ne subsiste sur ce qui releve encore de l'UX ou deja de l'UI

### Sous-phase 2.1 - Direction visuelle du tunnel

But: definir la personnalite visuelle et les fondations du systeme graphique.

Travaux:
- definir le niveau d'expressivite du tunnel:
  - premium
  - sobre
  - guide
  - technique invisible
- definir les principes de composition:
  - fond
  - hero
  - surface carte
  - respiration
  - rapport texte / illustration / logo
- fixer les fondations visuelles:
  - palette
  - typographie
  - echelle de spacing
  - rayons
  - elevations ou separations
  - iconographie
- definir les regles de motion utiles:
  - transition d'entree
  - progression
  - feedback d'etat

Livrables:
- direction visuelle du tunnel
- fondations du systeme visuel
- principes de motion et d'ambiance

Gate:
- la direction visuelle est suffisamment claire pour guider toutes les surfaces suivantes

### Sous-phase 2.2 - Hierarchie visuelle des ecrans

But: fixer la structure cible des ecrans avant de detailler les composants.

Travaux:
- definir pour chaque ecran la structure dominante:
  - hero plein ecran
  - carte centrale
  - layout split
  - hub de choix
  - etat de chargement
- clarifier la place de:
  - titre
  - sous-texte
  - message systeme inline
  - action primaire
  - action secondaire
  - feedback de progression
- definir la hierarchie cible des ecrans:
  - Preparation systeme
  - Auth
  - Creation profil
  - Choix profil
  - Choix / ajout source
  - Chargement medias
  - Home vide
- preciser ce qui change vraiment entre mobile et TV

Livrables:
- spec de structure par ecran
- regles de hierarchie visuelle
- mapping mobile / TV par surface

Gate:
- chaque ecran a une structure cible stable
- la lecture visuelle de l'action principale est evidente

### Sous-phase 2.3 - Systeme de composants du tunnel

But: transformer la structure cible en composants reutilisables et coherents.

Travaux:
- definir les composants communs du tunnel:
  - page shell
  - header
  - hero block
  - formulaire
  - field group
  - bouton principal / secondaire
  - liste ou grille de profils
  - source card
  - source picker hub
  - loading module
  - recovery banner
  - empty / error state
- definir pour chaque composant:
  - responsabilite
  - variantes
  - contenu attendu
  - etats
  - contraintes mobile
  - contraintes TV
- distinguer:
  - composant a creer
  - composant a refactorer
  - composant a supprimer

Livrables:
- inventaire des composants du tunnel
- decision log create / refactor / remove
- spec des variantes critiques

Gate:
- les composants communs sont identifies avant implementation
- les zones de duplication connues sont neutralisees

### Sous-phase 2.4 - Etats, feedback et motion

But: unifier visuellement les etats systeme du tunnel.

Travaux:
- definir la presentation cible de:
  - chargement court
  - chargement long
  - retry
  - sync partielle
  - erreur source
  - absence de reseau
  - fallback local
  - confirmation breve
  - home vide
- definir quand un etat reste inline et quand il prend plus de place
- harmoniser:
  - codes couleur
  - icones
  - densite de texte
  - position du message
  - rapport message / action
- definir les animations et transitions utiles, sans bruit

Livrables:
- spec des etats systeme et feedback
- regles d'affichage inline vs bloc
- guide de motion du tunnel

Gate:
- les etats critiques ont un traitement visuel coherent d'un bout a l'autre

### Sous-phase 2.5 - Responsive, accessibilite et TV

But: verrouiller les regles d'adaptation et de navigation avant implementation.

Travaux:
- definir les breakpoints et principes d'adaptation
- definir les tailles minimales utiles:
  - typo
  - boutons
  - champs
  - cartes
  - marges
- definir les regles d'accessibilite:
  - contraste
  - lisibilite
  - focus visible
  - ordre de lecture
  - messages relies aux actions
- definir la navigation TV:
  - focus order
  - focus trap
  - CTA dominant
  - retour
  - changement d'etat sans perdre le focus
- definir les ecarts autorises entre mobile et TV

Livrables:
- regles responsive
- regles d'accessibilite
- spec de focus management et navigation TV

Gate:
- la cible UI est defendable sur mobile et sur TV
- le focus management ne sera pas improvise en implementation

### Sous-phase 2.6 - Spec UI consolidee du tunnel

But: assembler la cible UI dans un document unique directement exploitable.

Travaux:
- consolider la direction visuelle, la structure ecran, les composants et les etats
- produire une spec UI ecran par ecran
- relier chaque ecran a ses composants dependants
- ajouter les notes de comportement mobile et TV
- preparer une checklist d'implementation UX/UI

Livrables:
- spec UI consolidee du tunnel
- checklist d'implementation UX/UI
- liste des dependances de composants par ecran

Gate:
- la spec peut etre utilisee par design et dev sans re-ouvrir les arbitrages majeurs

### Sous-phase 2.7 - Validation finale de la phase 2

But: clore la phase UI avec une cible stable avant architecture detaillee et implementation.

Travaux:
- verifier la coherence entre phase 1 et phase 2
- confirmer que tous les ecrans cibles sont couverts
- confirmer que tous les etats critiques ont un traitement visuel
- verifier que les composants communs sont bien identifies
- lister les sujets deferes a la phase architecture ou implementation

Livrables:
- synthese finale de la phase 2
- recap des decisions UI prises
- liste des sujets deferes
- verdict de stabilite

Gate:
- la phase 2 est suffisamment stable pour entrer en phase architecture et implementation UI

## Sequence de travail recommandee

Ordre conseille:
1. preparation et alignement UI
2. direction visuelle
3. hierarchie visuelle des ecrans
4. systeme de composants
5. etats, feedback et motion
6. responsive, accessibilite et TV
7. spec UI consolidee
8. validation finale

## Artefacts a produire dans ce dossier

Le dossier `docs/roadmap/phase_2_cible_ui_ux_systeme_visuel/` est prevu pour accueillir a terme:
- `00_roadmap_definition_cible_ui_ux_systeme_visuel.md`
- `01_preparation_alignement_ui.md`
- `02_direction_visuelle_tunnel.md`
- `03_hierarchie_visuelle_ecrans.md`
- `04_systeme_composants_tunnel.md`
- `05_etats_feedback_et_motion.md`
- `06_responsive_accessibilite_et_tv.md`
- `07_spec_ui_tunnel.md`
- `08_checklist_implementation_ui_ux.md`
- `09_validation_finale_phase_2.md`

## Points de validation avec le stakeholder

Les checkpoints ou une validation produit / design est utile sont:

1. fin de `2.0`
Pour confirmer le perimetre visuel et les contraintes non negociables.

2. fin de `2.1`
Pour arbitrer la direction visuelle retenue.

3. fin de `2.3`
Pour confirmer le systeme de composants et eviter des refactors tardifs.

4. fin de `2.5`
Pour verrouiller les concessions ou differenciations mobile / TV.

5. fin de `2.7`
Pour acter la cible UI finale avant implementation.

## Prompts a me redonner pour lancer chaque sous-phase

Tu peux copier-coller ces prompts tels quels pour demarrer chaque sous-phase.

### Lancer la sous-phase 2.0

Nous lancons la sous-phase 2.0 de preparation et alignement UI pour le tunnel welcome -> auth -> source -> pre-home.
Travaille sur cette sous-phase uniquement.
Je veux:
- la liste des surfaces UI a specifier
- la liste des contraintes de design, mobile, TV et accessibilite
- la liste des arbitrages visuels encore ouverts
- les ambiguities restantes a lever avant la sous-phase 2.1
Mets a jour la documentation dans docs/roadmap/phase_2_cible_ui_ux_systeme_visuel/ si necessaire.

### Lancer la sous-phase 2.1

Nous lancons la sous-phase 2.1 de direction visuelle du tunnel d'entree.
Travaille sur cette sous-phase uniquement.
Je veux:
- une proposition de direction visuelle cible
- les principes de palette, typo, spacing, surfaces et motion
- les options eventuelles si un arbitrage visuel reste ouvert
- les decisions recommandees pour mobile et TV
Mets a jour la documentation dans docs/roadmap/phase_2_cible_ui_ux_systeme_visuel/ si necessaire.

### Lancer la sous-phase 2.2

Nous lancons la sous-phase 2.2 de hierarchie visuelle des ecrans.
Travaille sur cette sous-phase uniquement.
Je veux:
- la structure cible de chaque ecran
- la hierarchie de l'information et des actions
- les differences utiles entre mobile et TV
- les zones qui doivent rester inline
Mets a jour la documentation dans docs/roadmap/phase_2_cible_ui_ux_systeme_visuel/ si necessaire.

### Lancer la sous-phase 2.3

Nous lancons la sous-phase 2.3 de systeme de composants du tunnel.
Travaille sur cette sous-phase uniquement.
Je veux:
- l'inventaire des composants a creer, refactorer ou supprimer
- les responsabilites et variantes de chaque composant cle
- les impacts mobile et TV
- les risques de duplication ou de couplage a eviter
Mets a jour la documentation dans docs/roadmap/phase_2_cible_ui_ux_systeme_visuel/ si necessaire.

### Lancer la sous-phase 2.4

Nous lancons la sous-phase 2.4 sur les etats, feedback et motion du tunnel.
Travaille sur cette sous-phase uniquement.
Je veux:
- la spec visuelle des etats critiques
- les regles inline vs bloc
- les principes d'animation et de transition utiles
- les points de vigilance pour ne pas degrader la clarte
Mets a jour la documentation dans docs/roadmap/phase_2_cible_ui_ux_systeme_visuel/ si necessaire.

### Lancer la sous-phase 2.5

Nous lancons la sous-phase 2.5 de responsive, accessibilite et TV.
Travaille sur cette sous-phase uniquement.
Je veux:
- les regles responsive
- les regles d'accessibilite
- la spec de focus management et navigation telecommande
- les arbitrages mobile / TV a acter
Mets a jour la documentation dans docs/roadmap/phase_2_cible_ui_ux_systeme_visuel/ si necessaire.

### Lancer la sous-phase 2.6

Nous lancons la sous-phase 2.6 de spec UI consolidee du tunnel.
Travaille sur cette sous-phase uniquement.
Je veux:
- une spec UI ecran par ecran
- le rattachement des composants a chaque surface
- les notes de comportement mobile et TV
- une checklist d'implementation UX/UI
Mets a jour la documentation dans docs/roadmap/phase_2_cible_ui_ux_systeme_visuel/ si necessaire.

### Lancer la sous-phase 2.7

Nous lancons la sous-phase 2.7 de validation finale de la phase 2.
Travaille sur cette sous-phase uniquement.
Je veux:
- une synthese finale de la phase
- le recap des decisions UI prises
- la liste des sujets deferes a la phase architecture ou implementation
- un verdict explicite sur la stabilite de la phase 2
Mets a jour la documentation dans docs/roadmap/phase_2_cible_ui_ux_systeme_visuel/ si necessaire.

## Prompts a me redonner pour clore chaque sous-phase

Tu peux aussi utiliser ces prompts de cloture si tu veux formaliser la sortie d'une sous-phase avant de passer a la suivante.

### Clore la sous-phase 2.0

La sous-phase 2.0 est-elle suffisamment cadree pour lancer la direction visuelle ? Donne-moi le verdict, les points fixes et les questions restantes.

### Clore la sous-phase 2.1

La direction visuelle est-elle assez stable pour specifier les ecrans ? Donne-moi le verdict, les choix retenus et les arbitrages encore ouverts.

### Clore la sous-phase 2.2

La structure des ecrans est-elle assez stable pour definir les composants ? Donne-moi le verdict, les points fixes et les zones fragiles.

### Clore la sous-phase 2.3

Le systeme de composants est-il assez clair pour specifier les etats et l'implementation ? Donne-moi le verdict, les composants critiques et les risques restants.

### Clore la sous-phase 2.4

Les etats et feedback sont-ils assez coherents pour verrouiller la phase responsive et accessibilite ? Donne-moi le verdict et les points faibles encore ouverts.

### Clore la sous-phase 2.5

La cible mobile + TV est-elle assez stable pour consolider la spec UI finale ? Donne-moi le verdict, les arbitrages retenus et les risques d'implementation.

### Clore la sous-phase 2.6

La spec UI consolidee est-elle assez complete pour cloturer la phase 2 ? Donne-moi le verdict, les manques eventuels et les points a surveiller en implementation.

## Prochaine etape recommandee

Apres validation de cette roadmap detaillee, produire d'abord:
1. `01_preparation_alignement_ui.md`
2. `02_direction_visuelle_tunnel.md`
3. `03_hierarchie_visuelle_ecrans.md`

La spec UI consolidee ne doit arriver qu'une fois les fondations visuelles et structurelles stabilisees.

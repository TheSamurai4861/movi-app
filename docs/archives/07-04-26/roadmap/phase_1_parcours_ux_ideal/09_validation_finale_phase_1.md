# Sous-phase 1.7 - Validation finale de la phase 1

## Objectif

Clore la phase 1 `Definition du parcours UX ideal` avec:
- une synthese du blueprint UX final
- un recap des decisions prises
- les sujets deferes vers la phase UI
- les sujets deferes vers la phase architecture
- les risques restants
- la liste des artefacts produits
- un verdict explicite sur la stabilite de la phase

## Blueprint UX final du tunnel cible

Le tunnel cible retenu est organise autour d'un principe simple:
- tant qu'aucune action utilisateur n'est necessaire, le systeme reste dans une experience unique de `Preparation systeme`
- des qu'une action est requise, l'utilisateur voit une etape claire avec une action primaire unique
- `Home` n'apparait qu'une fois l'etat juge necessaire pret

Le tunnel cible se decompose ainsi:

### Retour utilisateur sain

`Ouverture app -> Preparation systeme -> verifications absorbees -> chargement medias si necessaire -> Home`

### Premiere connexion saine

`Ouverture app -> Preparation systeme breve -> Auth -> Creation profil -> Choix / ajout source -> Chargement medias -> Home`

### Variantes clefs absorbees dans ce cadre

- choix profil obligatoire si aucun profil n'est selectionne
- choix / ajout source si la source active est absente ou invalide
- `Retry` ou continuation locale si la sync cloud est partiellement indisponible
- `Home vide` comme etat d'arrivee legitime si la source est valide mais sans contenu

## Decisions principales actees

### Structure du tunnel

- `launch` n'est plus un ecran produit
- `bootstrap` est absorbe dans une seule surface `Preparation systeme`
- le retour utilisateur sain doit tendre vers un tunnel quasi invisible
- le premier parcours reste guide et assume des etapes visibles

### Ecrans et responsabilites

- `welcome/user` est abandonne comme ecran hybride de reference
- `Auth` reste une vraie etape cible
- `Choix profil` reste visible seulement quand il est vraiment necessaire
- `welcome/sources` devient la base du futur hub `Choix / ajout source`
- `welcome/sources/select` est fusionne dans le hub source
- `welcome/sources/loading` est remplace par une surface `Chargement medias`

### Etats inline

- erreur source inline
- sync cloud partielle inline
- chargement long inline
- `Home vide` comme empty state de destination

### Messaging

- ton premium, court, rassurant et actionnable
- pas de jargon systeme dans le tunnel
- chaque blocage a une action primaire evidente

## Questions deferrees a la phase UI

Ces sujets ne sont pas bloques conceptuellement, mais doivent etre tranches visuellement en phase UI:

- direction visuelle precise de `Preparation systeme`
- style exact des headers, formulaires et cartes
- forme finale des listes / grilles de profils
- composition finale du hub source sur mobile
- composition finale du hub source sur TV
- forme visuelle du feedback inline pour erreurs source et chargement long
- traitement visuel exact de `Home vide`
- style des indicateurs de progression et des animations de transition

## Questions deferrees a la phase architecture

Ces sujets doivent etre traites en phase architecture / implementation:

- mapping exact entre routes actuelles et surfaces UX cibles
- definition de la machine d'etat du tunnel d'entree
- orchestration technique de `Preparation systeme`
- strategie de fallback local et de reprise cloud
- conditions exactes de `home ready`
- seuils techniques du `chargement long`
- regles d'auto-skip robustes
- traitement de la reprise apres interruption du tunnel
- preparation du futur flow TV par QR code

## Risques restants

Les principaux risques encore ouverts sont:

- surcharger `Preparation systeme` avec trop de messages ou de logique visible
- recreer un ecran hybride lors de l'implementation du hub source
- mal gerer la frontiere entre ecran dedie et etat inline
- sous-estimer les contraintes TV dans les ecrans de choix
- laisser revenir du jargon technique dans la microcopy finale
- faire apparaitre `Home` trop tot ou trop tard par rapport a la promesse retenue

## Artefacts produits dans cette phase

- [01_preparation_alignement.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_1_parcours_ux_ideal/01_preparation_alignement.md)
- [02_workflow_accueil_mermaid_professional.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_1_parcours_ux_ideal/02_workflow_accueil_mermaid_professional.md)
- [02_workflow_accueil_mermaid_professional.png](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_1_parcours_ux_ideal/02_workflow_accueil_mermaid_professional.png)
- [03_blueprint_ux_tunnel_cible.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_1_parcours_ux_ideal/03_blueprint_ux_tunnel_cible.md)
- [04_user_flows_tunnel_entree.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_1_parcours_ux_ideal/04_user_flows_tunnel_entree.md)
- [05_contrat_ux_par_ecran.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_1_parcours_ux_ideal/05_contrat_ux_par_ecran.md)
- [06_decisions_fusion_suppression_inline.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_1_parcours_ux_ideal/06_decisions_fusion_suppression_inline.md)
- [07_microcopy_messages_critiques.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_1_parcours_ux_ideal/07_microcopy_messages_critiques.md)
- [08_wireframes_low_fi_tunnel_entree.md](/mnt/c/Users/berny/DEV/Flutter/movi/docs/roadmap/phase_1_parcours_ux_ideal/08_wireframes_low_fi_tunnel_entree.md)

## Verdict de stabilite

Verdict:
- la phase 1 est suffisamment stable pour passer a la suite

Pourquoi:
- le flux nominal est defini
- les variantes critiques sont couvertes
- les ecrans cibles ont un contrat clair
- les decisions structurelles sont explicites
- la microcopy critique est posee
- les wireframes low-fi confirment la structure

Ce qui n'est pas encore final:
- le design visuel detaille
- l'architecture technique cible
- les seuils et regles d'implementation

## Recommandation de suite

La suite recommandee est:
1. phase UI: transformer ces artefacts en spec visuelle plus precise
2. phase architecture: definir l'orchestrateur, la machine d'etat et le mapping des routes

## Conclusion

La phase 1 a converti un tunnel existant, technique et partiellement hybride, en une cible UX defendable, lisible et structurante. Le projet peut maintenant avancer sans re-ouvrir les grands arbitrages de parcours, sauf changement produit volontaire.

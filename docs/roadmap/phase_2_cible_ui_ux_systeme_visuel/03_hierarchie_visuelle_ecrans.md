# Sous-phase 2.2 - Hierarchie visuelle des ecrans

## Objectif

Fixer la structure cible de chaque ecran du tunnel d'entree avant de basculer sur le systeme de composants.

Cette sous-phase repond a quatre questions:
- quels blocs composent chaque ecran
- dans quel ordre ils doivent etre lus
- ce qui change vraiment entre mobile et TV
- quels etats doivent rester inline au lieu de devenir de nouveaux ecrans

## Regles generales de hierarchie du tunnel

Les regles suivantes s'appliquent a toutes les surfaces:

1. une action principale dominante par ecran
2. un titre court visible rapidement
3. un sous-texte utile mais jamais dominant
4. un seul message systeme prioritaire a la fois
5. les erreurs et recoveries restent au plus pres de l'action concernee
6. la TV garde la meme structure que mobile, avec plus d'espace et un focus plus fort

## Structure cible par ecran

## 1. Preparation systeme

### Structure cible

Ordre des blocs:
1. fond de marque sombre
2. logo centre
3. indicateur de progression bas
4. message de progression en bas
5. message degrade inline + `Retry` seulement si necessaire

### Hierarchie de l'information et des actions

- niveau 1: logo
- niveau 2: message principal de progression
- niveau 3: indicateur visuel
- niveau 4: message secondaire eventuel
- niveau 5: action `Retry` uniquement en degrade

La surface doit etre lue en moins de deux secondes.

### Mobile

- logo centre
- message bas centre
- indicateur compact
- aucune surcharge

### TV

- meme structure
- logo plus grand
- plus d'espace vertical
- message encore plus court
- bouton `Retry` plus visible si l'etat degrade apparait

### Zones qui doivent rester inline

- chargement long
- reprise de verification
- recovery bref

Ne pas creer un nouvel ecran dedie pour chaque etat de preparation.

## 2. Auth

### Structure cible

Ordre des blocs:
1. fond tunnel
2. hero haut ou centre-haut
3. titre
4. sous-texte court
5. bloc formulaire
6. message inline de validation ou erreur
7. CTA principal
8. action secondaire `Retour`

### Hierarchie de l'information et des actions

- niveau 1: titre de connexion
- niveau 2: formulaire
- niveau 3: CTA principal
- niveau 4: aide courte
- niveau 5: retour

L'utilisateur doit comprendre tout de suite:
- pourquoi il est la
- quoi saisir
- quelle est la prochaine action

### Mobile

- colonne unique
- hero compact
- formulaire plein largeur utile
- CTA visible sans seconde lecture

### TV

- meme logique `hero + form`
- hero plus respirant
- bloc form plus grand et plus focalise
- pas plus de champs simultanes que sur mobile

### Zones qui doivent rester inline

- erreur de code
- erreur d'envoi
- confirmation `code envoye`
- aide contextuelle sur le fonctionnement du code

Ne pas isoler ces etats dans des modales ou surfaces separees.

## 3. Creation profil

### Structure cible

Ordre des blocs:
1. fond tunnel
2. hero compact
3. titre
4. sous-texte explicatif court
5. bloc formulaire
6. options visuelles simples avatar / couleur
7. message inline d'erreur si besoin
8. CTA principal
9. action secondaire `Retour`

### Hierarchie de l'information et des actions

- niveau 1: titre `Creez votre premier profil`
- niveau 2: champ principal nom
- niveau 3: CTA
- niveau 4: options avatar / couleur
- niveau 5: message d'aide ou de recovery

La structure doit rendre evidente que l'effort demande est faible.

### Mobile

- hero tres compact
- un bloc formulaire central
- options visuelles en dessous du champ principal

### TV

- meme ordre
- options visuelles plus grandes
- moins de saisie libre si possible
- focus direct sur le champ ou le premier preset

### Zones qui doivent rester inline

- erreur de validation de champ
- erreur de creation
- aide courte sur l'utilite du profil

## 4. Choix profil

### Structure cible

Ordre des blocs:
1. fond tunnel
2. hero compact ou header titre
3. titre
4. sous-texte tres court si necessaire
5. galerie de profils
6. action secondaire `Retour`

### Hierarchie de l'information et des actions

- niveau 1: galerie de profils
- niveau 2: titre
- niveau 3: sous-texte eventuel
- niveau 4: retour

L'action primaire est la selection d'une carte profil. Il ne faut pas un second CTA principal concurrent.

### Mobile

- grille simple ou liste-carte selon nombre de profils
- avatar rond dominant
- nom sous l'avatar
- retour discret

### TV

- meme logique de galerie
- cartes plus grandes
- halo de focus fort
- espacement plus important entre les profils

### Zones qui doivent rester inline

- message `aucun profil exploitable`
- eventuelle aide contextuelle

Ne pas transformer un probleme de liste vide en nouvel ecran si la surface peut encore porter l'action utile.

## 5. Choix / ajout source

### Structure cible

Ordre des blocs:
1. fond tunnel
2. hero compact ou header titre
3. titre
4. message contextuel
5. inventaire des sources existantes si applicable
6. separateur ou transition visuelle
7. bloc ajout / edition de source
8. message inline d'erreur ou de recovery
9. CTA principal
10. action secondaire `Retour`

### Hierarchie de l'information et des actions

- niveau 1: titre + message contextuel
- niveau 2: zone de choix existant ou ajout
- niveau 3: CTA principal `Utiliser` ou `Ajouter`
- niveau 4: message d'erreur inline
- niveau 5: retour

La structure doit rester orientee tache:
- comprendre le contexte
- choisir ou ajouter
- continuer

### Mobile

- pile verticale
- sources existantes d'abord si elles existent
- ajout de source ensuite
- erreur inline directement sous le sous-bloc concerne ou sous le CTA

### TV

- meme logique generale
- separation visuelle plus nette entre inventaire et edition
- deux zones possibles a l'ecran si la lisibilite y gagne
- focus stable entre galerie et formulaire

### Zones qui doivent rester inline

- source active invalide
- erreur de connexion source
- sync cloud partielle liee aux sources
- aide sur la raison du blocage

Ne pas creer un ecran d'erreur source dedie.

## 6. Chargement medias

### Structure cible

Ordre des blocs:
1. fond tunnel
2. hero minimal ou logo discret
3. titre de progression
4. indicateur de chargement
5. message secondaire
6. bloc inline `chargement plus long que prevu` si necessaire
7. CTA `Retry` seulement si seuil depasse

### Hierarchie de l'information et des actions

- niveau 1: message de progression principal
- niveau 2: indicateur
- niveau 3: message secondaire
- niveau 4: recovery eventuel

La surface doit etre plus legere que `Choix / ajout source`, mais plus explicite que `Preparation systeme`.

### Mobile

- lecture tres rapide
- centre ecran ou centre-haut
- recovery bas si necessaire

### TV

- meme structure
- message plus grand
- plus d'air autour de l'indicateur
- recovery clairement separe mais pas dramatise

### Zones qui doivent rester inline

- chargement long
- retry
- progression secondaire

## 7. Home vide

### Structure cible

Ordre des blocs:
1. structure de destination `Home`
2. bloc empty state dans la zone de contenu principale
3. titre
4. texte explicatif
5. action primaire sobre
6. action secondaire eventuelle

### Hierarchie de l'information et des actions

- niveau 1: message de comprehension `la source est connectee mais vide`
- niveau 2: action primaire de reassurance
- niveau 3: action secondaire eventuelle

Le but est d'eviter la sensation de bug, pas de recreer un tunnel.

### Mobile

- bloc empty state centre dans la premiere zone utile
- message court
- peu d'actions

### TV

- meme logique
- bloc un peu plus large
- visuel ou icone possible si cela aide la comprehension

### Zones qui doivent rester inline

- confirmation breve
- details secondaires sur la source

Ne pas sortir l'utilisateur de `Home` vers un ecran a part.

## Differences utiles entre mobile et TV

Les differences utiles retenues sont:

1. taille et respiration
La TV augmente d'abord les marges, les dimensions et l'espace entre blocs.

2. focus
Le focus devient un element de hierarchie visuelle sur TV. Il ne doit pas seulement etre fonctionnel.

3. densite
La TV montre moins d'informations secondaires simultanees.

4. galeries
Les galeries de profils et de sources ont plus d'espace et des cartes plus lisibles sur TV.

5. formulaires
Les formulaires restent les memes dans leur logique, mais doivent limiter la surcharge et guider le focus plus explicitement.

Ce qui ne doit pas changer:
- l'ordre logique des blocs
- l'action primaire
- le vocabulaire visuel general
- la nature des etats inline

## Zones qui doivent rester inline a l'echelle du tunnel

Ces etats ne doivent pas devenir de nouveaux ecrans dans la cible UI:

- erreur de champ
- erreur de code auth
- confirmation `code envoye`
- source invalide
- source active absente avec explication
- sync cloud partielle
- chargement long
- retry de preparation
- fallback local explicatif
- confirmation breve

## Decision de sortie de la sous-phase 2.2

Verdict:
- la structure des ecrans est suffisamment stable pour passer au systeme de composants

Pourquoi:
- chaque surface a une composition cible claire
- la hierarchie de lecture est definie
- les differences utiles mobile / TV sont bornees
- les etats qui doivent rester inline sont identifies

## Prochaine etape recommandee

La suite logique est:
1. transformer ces structures en composants reutilisables
2. distinguer ce qui doit etre cree, refactore ou supprime
3. eviter que les futurs ecrans reconstruisent chacun leur propre grammaire

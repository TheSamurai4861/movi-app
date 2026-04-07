# Sous-phase 2.1 - Direction visuelle du tunnel

## Objectif

Definir une direction visuelle cible pour le tunnel d'entree, coherente avec l'app existante et suffisamment stable pour guider la spec des ecrans.

Cette sous-phase fixe:
- l'ambiance generale du tunnel
- les principes de palette, typo, spacing, surfaces et motion
- les options encore possibles si un arbitrage visuel reste ouvert
- les decisions recommandees pour mobile et TV

## Proposition de direction visuelle cible

### Direction recommandee

La direction recommandee est:
- `premium sobre`
- `cinema controle`
- `coherente avec home`
- `guidee sans etre demonstrationnelle`

En pratique, cela signifie:
- un tunnel sombre par defaut, ancre dans la palette Movi existante
- des surfaces tres lisibles, avec peu d'effets gratuits
- un logo et un hero qui donnent une presence de marque, sans concurrencer l'action principale
- des ecrans de saisie en `hero + form`
- des ecrans de choix en `galerie premium`
- une motion discrete qui rassure sans ralentir

Le tunnel ne doit pas ressembler a un setup technique. Il doit donner l'impression que l'app prepare quelque chose de deja maitrise.

## ADN visuel retenu

### Impression generale

- sombre
- calme
- dense juste ce qu'il faut
- premium sans theatrale
- directif sur l'action

### Vocabulaire visuel

- fonds profonds et propres
- surfaces legerement detachees du fond
- cartes arrondies, nettes, peu chargees
- accent bleu Movi reserve aux actions, focus et points de progression
- typographie Montserrat deja presente dans l'app
- iconographie simple et legere via `Lucide Icons`

### Rapport a `home`

Le tunnel doit apparaitre comme la `porte d'entree` de `home`, pas comme un mini-produit different.

Donc:
- meme famille de couleurs
- meme logique de contrastes
- meme signature des actions principales
- meme idee de hero sombre et immersif
- mais une composition plus simple, plus centree et plus directive

## Principes de palette

## Palette recommandee

La palette de reference reste celle de l'app:
- accent principal: bleu Movi existant
- fond principal: noir / anthracite tres profond
- surfaces: noirs adoucis et gris profonds
- texte principal: blanc
- texte secondaire: gris desature

References code existantes:
- [app_colors.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/theme/app_colors.dart)
- [app_theme.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/theme/app_theme.dart)

### Regles d'usage

- `accent` seulement pour:
  - CTA principal
  - focus
  - progression
  - points d'etat positifs
- `rouge` reserve aux erreurs bloquantes ou source invalide
- `orange` ou `ambre` reserve aux recoveries ou etats de vigilance
- `vert` a utiliser tres peu, uniquement pour une confirmation breve si necessaire
- ne pas multiplier les couleurs fonctionnelles dans un meme ecran

### Decision recommandee

- tunnel sombre par defaut en phase 2
- variante claire eventuellement derivee plus tard, pas specifiee comme axe prioritaire du tunnel

## Principes de typographie

### Base recommandee

Conserver `Montserrat` et la hierarchie deja visible dans le theme.

References code:
- [app_theme.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/theme/app_theme.dart)

### Hierarchie recommandee

- titre ecran:
  - fort
  - compact
  - 1 a 2 lignes max
- sous-titre:
  - descriptif
  - lisible
  - court
- libelles de champ:
  - simples
  - fonctionnels
- texte secondaire:
  - discret, mais jamais faible au point d'etre perdu sur TV
- CTA:
  - poids moyen a fort
  - jamais trop petit

### Intention

Le tunnel doit utiliser moins de texte que `home`, mais rendre chaque ligne plus utile.

## Principes de spacing et densite

### Base recommandee

Conserver l'echelle existante:
- `8 / 12 / 16 / 24 / 32`

Reference code:
- [app_spacing.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/utils/app_spacing.dart)

### Regles de densite

- mobile:
  - une colonne dominante
  - respirations franches entre hero, form et CTA
  - pas de blocs secondaires parasites
- TV:
  - plus d'air autour des blocs
  - plus de taille avant plus de complexite
  - garder la meme structure, pas une nouvelle logique de layout

### Decision recommandee

- conserver une densite compacte-premium sur mobile
- agrandir d'abord les marges, les tailles et le focus sur TV
- eviter de multiplier les colonnes tant que la lisibilite n'en tire pas un vrai benefice

## Principes de surfaces

### Fond

Le fond du tunnel doit etre plus vivant qu'un aplat noir, mais plus calme qu'un hero media de `home`.

Recommendation:
- fond sombre
- leger travail de gradient ou halo
- texture visuelle tres discrete
- aucun bruit graphique fort derriere les formulaires

### Hero

Le hero doit:
- ancrer la marque
- poser le titre
- donner de la respiration
- ne jamais repousser le CTA trop bas

Recommendation:
- `Preparation systeme`: logo centre, spinner et message bas
- `Auth` / `Creation profil`: hero haut ou centre-haut + form en dessous
- `Choix profil` / `Choix source`: hero plus compact pour laisser la priorite a la galerie

### Cartes

Les cartes doivent exprimer:
- choix
- focus
- qualite percue

Recommendation:
- bords arrondis
- separation par contraste de surface plus que par gros contour
- focus visible par halo + contour accent
- leger scale en focus sur TV et clavier

### Formulaires

Les formulaires doivent paraitre:
- simples
- propres
- directs

Recommendation:
- champs pleins, arrondis, lisibles
- labels simples au-dessus
- erreurs inline proches du champ ou du groupe
- CTA primaire plein large en bas du bloc

## Principes de motion

### Intention

La motion du tunnel doit:
- rassurer
- donner une impression de fluidite
- signaler les changements d'etat
- ne jamais allonger artificiellement la perception du temps

### Motion recommandee

- fade court sur les transitions d'entree
- apparition douce des messages inline
- scale discret sur focus TV
- progression continue ou spinner sobre sur les ecrans de chargement
- pas de choregraphie decorative

### Regles

- durees courtes
- easing doux
- pas d'animations concurrentes dans une meme surface
- un seul point d'attention en mouvement a la fois

## Options si un arbitrage visuel reste ouvert

### Option A - Recommandee

`Premium sobre`

Caracteristiques:
- fond sombre elegant
- accent bleu present mais contenu
- hero simple
- surfaces propres
- motion discrete

Avantages:
- coherence forte avec l'app existante
- faible risque de vieillissement
- plus simple a systematiser

### Option B

`Premium cinema`

Caracteristiques:
- gradients plus visibles
- hero plus dramatique
- separation plus marquee entre fond et surface
- motion un peu plus presente

Avantages:
- perception plus premium
- plus memorable

Risques:
- peut entrer en concurrence avec `home`
- peut surjouer sur les ecrans de setup

### Option C

`Systeme minimal invisible`

Caracteristiques:
- surfaces tres sobres
- presque pas d'ambiance
- tunnel percu comme purement fonctionnel

Avantages:
- tres efficace
- simple a maintenir

Risques:
- perte de desirabilite
- moins coherent avec l'ambition premium du produit

### Recommandation d'arbitrage

Prendre `Option A` comme base.

Autoriser seulement quelques touches de `Option B`:
- gradient de fond leger
- hero un peu plus marque sur `Preparation systeme`
- meilleur traitement des galleries de choix

## Decisions recommandees pour mobile et TV

### Mobile

- colonne unique dominante
- hero + form comme pattern prioritaire
- CTA primaire visible rapidement
- cartes profil et source avec forte lisibilite, peu de meta
- messages inline courts et immediatement lies a l'action

### TV

- meme logique de layout que mobile
- surfaces plus larges, plus hautes, plus espacees
- focus tres visible
- titre et sous-titre plus courts
- galleries plus aeriennes
- pas d'ajout de complexite structurelle

### Decision commune mobile + TV

- meme systeme visuel
- memes composants de base
- memes codes de couleur
- memes principes de hero et de surface
- seules changent:
  - taille
  - espace
  - poids du focus
  - densite de contenu

## Arbitrages restant ouverts apres 2.1

Ils pourront etre confirmes dans `2.2` sans bloquer la direction visuelle:

1. hero centre-haut ou hero plus hautement editorialise sur `Auth`
2. niveau exact de gradient de fond
3. niveau de relief des cards profil et source
4. traitement final du `Chargement medias` par rapport au splash
5. forme finale de `Home vide`

## Verdict de sortie de la sous-phase 2.1

Verdict:
- la direction visuelle est suffisamment claire pour lancer la hierarchie visuelle des ecrans

Pourquoi:
- une direction cible est definie
- palette, typo, spacing, surfaces et motion ont une base claire
- les options alternatives sont bornees
- mobile et TV ont une doctrine commune

## Prochaine etape recommandee

La suite logique est:
1. traduire cette direction en structures d'ecrans
2. fixer la place exacte du hero, des titres, des messages inline et des CTA
3. preparer le futur systeme de composants sur une base visuelle stable

# Sous-phase 2.6 - Spec UI consolidee du tunnel

## Objectif

Assembler les decisions des sous-phases `2.0` a `2.5` dans une spec UI unique, exploitable ecran par ecran.

Cette spec consolide:
- la direction visuelle
- la structure de chaque surface
- les composants attendus
- les etats autorises
- les notes mobile / TV

## Fondations communes a tout le tunnel

### Direction visuelle commune

- direction `premium sobre`
- tunnel sombre par defaut
- coherence forte avec `home`
- hero de marque discret mais present
- CTA principal bleu Movi
- surfaces sombres detachees du fond par contraste doux
- focus TV visible par contour + halo + scale discret

### Regles communes de structure

- une action principale dominante par surface
- titre court et lisible rapidement
- sous-texte utile mais secondaire
- erreurs et recoveries proches de l'action ou du champ concerne
- pas de nouvel ecran pour des etats qui peuvent rester inline

### Composants communs de reference

- `TunnelPageShell`
- `TunnelHeader`
- `TunnelHeroBlock`
- `TunnelFormShell`
- `TunnelField`
- `TunnelPrimaryAction`
- `TunnelSecondaryAction`
- `TunnelLoadingBlock`
- `TunnelInlineMessage`
- `TunnelRecoveryBanner`
- `ProfileChoiceGallery`
- `ProfileChoiceCard`
- `SourceChoiceGallery`
- `SourceFormBlock`
- `SourcePickerHub`
- `TunnelEmptyState`

## Spec UI ecran par ecran

## 1. `Preparation systeme`

### Role visuel

Surface immersive de preparation, tres courte en nominal, plus explicite en degrade.

### Structure cible

Ordre des blocs:
1. fond sombre avec legere ambiance
2. logo centre
3. indicateur de progression bas
4. message principal en bas
5. sous-texte optionnel
6. bloc inline ou banner de recovery si necessaire

### Composants relies

- `TunnelPageShell` variante `immersive`
- `TunnelHeroBlock` variante `splash_centered`
- `TunnelLoadingBlock`
- `TunnelInlineMessage` ou `TunnelRecoveryBanner`

### Etats autorises

- progression nominale
- chargement long
- absence de reseau
- fallback local
- retry

### Mobile

- logo centre
- message tres court en bas
- aucun detail inutile

### TV

- meme structure
- logo plus grand
- plus d'espace vertical
- recovery plus lisible si visible

### Notes d'implementation

- garder l'ecran ultra stable
- ne pas empiler plusieurs messages en meme temps
- en nominal, aucun focus visible

## 2. `Auth`

### Role visuel

Surface `hero + form` simple, directe, rassurante.

### Structure cible

Ordre des blocs:
1. fond tunnel
2. hero haut ou centre-haut
3. titre
4. sous-texte court
5. bloc formulaire
6. message inline
7. CTA principal
8. action secondaire

### Composants relies

- `TunnelPageShell` variante `hero_form`
- `TunnelHeroBlock`
- `TunnelFormShell`
- `TunnelField`
- `TunnelPrimaryAction`
- `TunnelSecondaryAction`
- `TunnelInlineMessage`

### Etats autorises

- aide contextuelle
- confirmation `code envoye`
- erreur d'envoi
- erreur de code

### Mobile

- colonne unique
- CTA principal pleine largeur
- bloc formulaire compact

### TV

- meme logique
- hero plus respirant
- largeur de form plus confortable
- focus ordre: champs -> CTA -> secondaire

### Notes d'implementation

- deux etats de form a supporter:
  - email
  - email + code
- l'erreur reste inline
- pas de popup de confirmation

## 3. `Creation profil`

### Role visuel

Surface `hero + form` tres courte, qui rend faible l'effort demande.

### Structure cible

Ordre des blocs:
1. fond tunnel
2. hero compact
3. titre
4. sous-texte
5. bloc formulaire
6. options avatar / couleur
7. message inline
8. CTA principal
9. action secondaire

### Composants relies

- `TunnelPageShell` variante `hero_form`
- `TunnelHeroBlock`
- `TunnelFormShell`
- `TunnelField`
- composant d'avatar / couleur
- `TunnelPrimaryAction`
- `TunnelSecondaryAction`
- `TunnelInlineMessage`

### Etats autorises

- erreur de validation
- erreur de creation
- aide courte

### Mobile

- form centree
- options visuelles sous le champ principal

### TV

- meme structure
- options plus grandes
- saisie reduite si possible

### Notes d'implementation

- un seul objectif par surface
- ne pas faire remonter d'informations secondaires non necessaires

## 4. `Choix profil`

### Role visuel

Surface de selection premium ou la carte est l'action principale.

### Structure cible

Ordre des blocs:
1. fond tunnel
2. header ou hero compact
3. titre
4. sous-texte eventuel
5. galerie de profils
6. action secondaire

### Composants relies

- `TunnelPageShell` variante `selection`
- `TunnelHeader` ou `TunnelHeroBlock` compact
- `ProfileChoiceGallery`
- `ProfileChoiceCard`
- `TunnelSecondaryAction`
- `TunnelInlineMessage`

### Etats autorises

- aucun profil exploitable
- aide contextuelle breve

### Mobile

- galerie simple
- avatar rond dominant
- nom sous l'avatar

### TV

- cartes plus grandes
- halo de focus plus fort
- plus d'espace entre cartes

### Notes d'implementation

- pas de CTA principal supplementaire
- la carte porte l'action
- pas de focus interne dans la carte

## 5. `Choix / ajout source`

### Role visuel

Hub source unifie, oriente tache, combinant inventaire, ajout et recovery.

### Structure cible

Ordre des blocs:
1. fond tunnel
2. header ou hero compact
3. titre
4. message contextuel
5. galerie ou liste des sources existantes
6. separateur visuel
7. bloc ajout / edition de source
8. message inline ou banner de recovery
9. CTA principal
10. action secondaire

### Composants relies

- `TunnelPageShell` variante `selection`
- `TunnelHeader` ou `TunnelHeroBlock` compact
- `SourcePickerHub`
- `SourceChoiceGallery`
- `SourceFormBlock`
- `TunnelInlineMessage`
- `TunnelRecoveryBanner`
- `TunnelPrimaryAction`
- `TunnelSecondaryAction`

### Etats autorises

- source active invalide
- erreur de connexion source
- sync cloud partielle
- aide contextuelle

### Mobile

- pile verticale
- sources existantes d'abord
- formulaire ensuite

### TV

- meme logique
- deux zones possibles si cela clarifie la lecture
- focus stable entre galerie et formulaire

### Notes d'implementation

- aucune erreur source ne doit ouvrir un ecran a part
- si aucune source existante, le hub commence directement par le formulaire
- si plusieurs sources existent, la galerie garde la priorite visuelle

## 6. `Chargement medias`

### Role visuel

Surface de progression avant `Home`, plus explicite que le splash mais tout aussi calme.

### Structure cible

Ordre des blocs:
1. fond tunnel
2. hero minimal ou logo discret
3. message principal
4. indicateur
5. message secondaire
6. inline recovery si seuil depasse
7. CTA `Retry` seulement si necessaire

### Composants relies

- `TunnelPageShell` variante `immersive`
- `TunnelLoadingBlock`
- `TunnelInlineMessage`

### Etats autorises

- progression nominale
- chargement long
- retry

### Mobile

- lecture tres rapide
- centre ou centre-haut

### TV

- meme structure
- message plus grand
- recovery plus lisible

### Notes d'implementation

- surface plus simple que `Choix / ajout source`
- pas de surcouche technique ou statistique

## 7. `Home vide`

### Role visuel

Etat d'arrivee valide, rassurant, integre a `Home`.

### Structure cible

Ordre des blocs:
1. structure `Home`
2. bloc empty state principal
3. titre
4. texte explicatif
5. action primaire
6. action secondaire optionnelle

### Composants relies

- `TunnelEmptyState`

### Etats autorises

- information
- confirmation sobre

### Mobile

- bloc centre dans la zone utile

### TV

- meme logique
- bloc plus large
- respiration plus importante

### Notes d'implementation

- ton d'information, jamais ton d'erreur
- ne pas renvoyer l'utilisateur dans un tunnel secondaire

## Notes transverses mobile / TV

### Ce qui reste identique

- ordre logique des blocs
- action principale
- systeme visuel
- type de composants utilises
- etats inline critiques

### Ce qui peut varier

- largeur utile
- densite de texte
- taille des cartes
- intensite visuelle du focus
- respiration entre sections

## Checklist de verification de la spec UI

1. chaque ecran a une action principale dominante
2. chaque ecran reference ses composants communs
3. les etats autorises sont bornes
4. mobile et TV restent dans la meme grammaire
5. les etats inline ne sont pas transformes en nouveaux ecrans

## Verdict de sortie de la sous-phase 2.6

Verdict:
- la spec UI du tunnel est suffisamment consolidee pour cloturer la phase par une validation finale

Pourquoi:
- chaque surface a une structure cible claire
- les composants relies sont identifies
- les regles mobile / TV sont integrees a la spec
- les etats et feedbacks sont cadres

## Prochaine etape recommandee

La suite logique est:
1. finaliser la checklist d'implementation UX/UI
2. cloturer la phase 2 avec un recap des decisions prises et des sujets deferes

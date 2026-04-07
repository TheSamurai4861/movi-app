# Sous-phase 2.4 - Etats, feedback et motion

## Objectif

Definir un traitement visuel coherent des etats systeme du tunnel d'entree, ainsi que les regles de feedback et de motion qui les accompagnent.

Cette sous-phase fixe:
- quels etats existent dans le tunnel
- comment ils s'affichent
- quand ils restent inline et quand ils prennent plus de place
- comment la motion accompagne ces etats sans nuire a la clarte

## Principes directeurs

1. un etat ne doit jamais voler la priorite a l'action principale sans raison
2. un etat doit etre visible a la bonne proximite de l'action qu'il concerne
3. un etat systeme doit etre traite de la meme maniere sur toutes les surfaces comparables
4. la motion doit signaler, pas divertir
5. le tunnel doit paraitre maitrise meme quand il passe en recovery

## Taxonomie des etats du tunnel

Les etats du tunnel se regroupent en cinq familles:

1. `progression`
Le systeme travaille normalement.

2. `confirmation`
Une etape a bien avance ou s'est bien terminee.

3. `information`
L'utilisateur doit comprendre une situation valide mais inhabituelle.

4. `recovery`
Le tunnel rencontre une friction recuperable et propose une issue.

5. `erreur bloquante`
Le tunnel ne peut pas continuer sans action utilisateur.

## Regles inline vs bloc vs surface

### Inline

Un etat reste `inline` si:
- il concerne directement un champ, un bloc ou une action precise
- il ne change pas la structure globale de l'ecran
- il ne demande pas une reorientation complete du parcours

Exemples:
- erreur de code auth
- confirmation `code envoye`
- erreur source
- sync cloud partielle
- chargement long
- aide contextuelle

### Bloc dedie dans la surface

Un etat devient un bloc plus visible si:
- il doit capter l'attention sans devenir un ecran a part
- il influe sur la lecture de la surface
- il demande une action explicite dans le meme contexte

Exemples:
- absence de reseau dans `Preparation systeme`
- fallback local propose
- source precedente invalide avec choix alternatif

### Surface entiere

Un etat prend une surface entiere seulement si:
- il devient lui-meme l'objectif principal de l'ecran
- aucune autre action du contexte precedent n'a encore de sens
- le tunnel change de phase

Exemples:
- `Preparation systeme`
- `Chargement medias`
- `Home vide`

## Matrice des etats critiques

## 1. Progression nominale

### `Preparation systeme`

Type:
- progression

Support visuel:
- surface immersive

Composants:
- `TunnelPageShell`
- `TunnelHeroBlock` variante `splash_centered`
- `TunnelLoadingBlock`

Hierarchie:
- logo
- message principal
- indicateur
- sous-texte optionnel

Motion:
- fade-in court
- spinner ou progression continue

Recommandation:
- pas d'action visible en nominal

### `Chargement medias`

Type:
- progression

Support visuel:
- surface dediee plus legere que le splash

Composants:
- `TunnelPageShell`
- `TunnelLoadingBlock`

Hierarchie:
- message principal
- indicateur
- message secondaire

Motion:
- progression continue
- eventuelle transition douce depuis l'ecran precedent

Recommandation:
- plus explicite que `Preparation systeme`, mais jamais plus dramatique

## 2. Confirmation

### `Code envoye`

Type:
- confirmation breve

Support visuel:
- inline dans `Auth`

Composant:
- `TunnelInlineMessage` variante `success_brief`

Position:
- entre formulaire et CTA

Motion:
- apparition douce
- pas d'animation de celebration

### `Tout est pret`

Type:
- confirmation breve

Support visuel:
- souvent implicite

Position:
- optionnel, tres bref avant transition

Motion:
- fondu ou transition simple vers la suite

Recommandation:
- ne pas ralentir l'acces a `Home` pour surjouer la confirmation

## 3. Information

### `Home vide`

Type:
- information

Support visuel:
- bloc central dans la surface `Home`

Composant:
- `TunnelEmptyState`

Hierarchie:
- titre de comprehension
- texte explicatif
- action primaire sobre
- action secondaire eventuelle

Motion:
- apparition douce, sans dramatisation

Recommandation:
- faire comprendre que l'etat est valide, pas une panne

## 4. Recovery

### `Chargement long`

Type:
- recovery

Support visuel:
- inline dans `Chargement medias` ou `Preparation systeme`

Composant:
- `TunnelInlineMessage` variante `recovery`

Position:
- sous le module de loading

Actions:
- `Reessayer`
- `Attendre`

Motion:
- apparition apres seuil
- aucune secousse ni clignotement

### `Sync cloud partielle`

Type:
- recovery

Support visuel:
- bloc visible dans la surface courante

Composant:
- `TunnelRecoveryBanner`

Position:
- sous le hero ou au-dessus du bloc principal concerne

Actions:
- `Reessayer`
- `Continuer en local`

Motion:
- apparition douce depuis le haut ou simple fade

### `Fallback local`

Type:
- recovery

Support visuel:
- bloc dedie dans `Preparation systeme` ou dans la surface suivante

Composant:
- `TunnelRecoveryBanner`

Actions:
- `Continuer en local`
- `Reessayer`

Recommandation:
- ton calme
- largeur suffisante pour etre comprise en une lecture

### `Reprise apres interruption`

Type:
- recovery

Support visuel:
- inline ou bloc compact selon le contexte

Composant:
- `TunnelInlineMessage` variante `info` ou `recovery`

Recommandation:
- rester tres bref
- ne pas recreer un ecran intermediaire

## 5. Erreurs bloquantes

### `Absence de reseau`

Type:
- blocage

Support visuel:
- bloc fort dans `Preparation systeme`

Composant:
- `TunnelRecoveryBanner` variante `error/recovery`

Actions:
- `Reessayer`

Hierarchie:
- message principal
- eventuel sous-texte
- CTA primaire

Motion:
- aucune animation agressive

Recommandation:
- priorite haute
- occuper assez de place pour etre immediatement comprise

### `Source invalide`

Type:
- erreur liee a l'action

Support visuel:
- inline dans `SourceFormBlock` ou sous le CTA principal

Composant:
- `TunnelInlineMessage` variante `error`

Actions:
- `Reessayer`
- `Modifier la source`

Recommandation:
- rester dans la surface `Choix / ajout source`
- ne jamais faire sortir l'utilisateur vers une erreur dediee

### `Aucun profil exploitable`

Type:
- blocage localise

Support visuel:
- inline ou bloc compact dans `Choix profil`

Composant:
- `TunnelInlineMessage` ou `TunnelRecoveryBanner` selon severite

Recommandation:
- tant que l'ecran porte encore une action utile, ne pas ouvrir une surface separee

## Regles de presentation par type d'etat

## `TunnelInlineMessage`

Quand l'utiliser:
- message court
- local a un bloc
- action simple

Style:
- faible a moyenne hauteur
- iconographie legere
- texte court
- action adjacente ou juste en dessous

Couleurs recommandees:
- info: surface + outline doux
- recovery: ambre discret
- error: rouge sobre
- success_brief: accent positif discret

## `TunnelRecoveryBanner`

Quand l'utiliser:
- l'etat doit reorganiser la lecture de la surface
- une action de recovery est importante
- l'utilisateur doit comprendre un contexte plus large

Style:
- largeur pleine du bloc principal
- fond detache de la surface
- bord ou accent lateral subtil
- une seule action primaire forte
- eventuelle action secondaire textuelle

## `TunnelLoadingBlock`

Quand l'utiliser:
- toute progression centrale du tunnel

Style:
- message principal dominant
- progression secondaire discrete
- pas de surcharge de chiffres ou details systeme

## Mapping ecran -> etats autorises

### `Preparation systeme`

Autorises:
- progression nominale
- absence de reseau
- chargement long
- fallback local

Interdits:
- details techniques
- empilement de plusieurs banners

### `Auth`

Autorises:
- aide contextuelle
- confirmation `code envoye`
- erreur de code
- erreur d'envoi

Interdits:
- banniere globale dramatique
- modales d'erreur inutiles

### `Creation profil`

Autorises:
- aide breve
- erreur de validation
- erreur de creation

Interdits:
- feedbacks loin du champ ou du CTA

### `Choix profil`

Autorises:
- message `aucun profil exploitable`
- aide contextuelle

Interdits:
- double systeme de messages concurrents

### `Choix / ajout source`

Autorises:
- source active invalide
- erreur source
- sync cloud partielle
- aide contextuelle

Interdits:
- ecran d'erreur source dedie
- popup qui coupe la logique du hub

### `Chargement medias`

Autorises:
- progression
- chargement long
- retry

Interdits:
- surplus d'informations techniques

### `Home vide`

Autorises:
- information
- action de reassurance

Interdits:
- ton d'erreur

## Guide de motion du tunnel

## Ce que la motion doit faire

- rendre l'entree plus fluide
- relier les etapes sans bruit
- souligner le focus sur TV
- rendre les apparitions d'etat plus naturelles

## Ce qu'elle ne doit pas faire

- allonger artificiellement les chargements
- faire clignoter les erreurs
- multiplier les animations simultanees
- introduire des transitions tape-a-l'oeil entre les sous-phases

## Motions recommandees

1. `Fade-in court`
Pour les surfaces de splash, loading et messages inline.

2. `Slide/fade doux`
Pour les banners de recovery lorsqu'elles apparaissent dans une surface.

3. `Scale focus discret`
Pour cartes et actions focusables sur TV.

4. `Transition simple de contenu`
Pour passer d'un etat de formulaire a un autre dans `Auth`.

## Motions a proscrire

- secousses
- pulses permanents
- skeletons trop brillants
- animations de succes demonstratives

## Decision de sortie de la sous-phase 2.4

Verdict:
- les etats, feedbacks et motions du tunnel sont suffisamment cadres pour verrouiller la phase responsive et accessibilite

Pourquoi:
- les etats critiques sont listes et mappees
- les regles inline vs bloc vs surface sont explicites
- les composants de feedback ont un role clair
- la motion est encadree par des regles simples

## Prochaine etape recommandee

La suite logique est:
1. verrouiller responsive, accessibilite et navigation TV
2. relier ces regles aux composants et structures deja definis
3. preparer la spec UI consolidee sur un systeme visuel complet

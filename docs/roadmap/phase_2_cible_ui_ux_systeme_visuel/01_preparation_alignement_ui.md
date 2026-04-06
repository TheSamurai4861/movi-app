# Sous-phase 2.0 - Preparation et alignement UI

## Objectif

Cadrer la phase UI avant de produire une direction visuelle detaillee.

Cette sous-phase ne redefinit pas le parcours. Elle fixe:
- les surfaces UI a specifier
- les contraintes visuelles et techniques a respecter
- les arbitrages visuels encore ouverts
- les ambiguities a lever avant de lancer la direction visuelle

## Base de travail confirmee

La phase 2 part des decisions deja actees en phase 1:
- le parcours cible est stable
- `Home` n'apparait qu'apres preparation jugee necessaire
- `Preparation systeme` remplace les ecrans techniques visibles
- `Auth`, `Creation profil`, `Choix profil`, `Choix / ajout source`, `Chargement medias` et `Home vide` sont les surfaces UX cibles
- les etats inline critiques restent inline autant que possible

Les decisions de cadrage visuel donnees pour cette phase 2 sont:
- reprendre les couleurs et composants deja presents dans l'app
- maintenir une coherence forte avec `home`
- `Preparation systeme` prend la forme d'un splash avec logo centre, indicateur de chargement et message en bas
- `Auth` et `Creation profil` utilisent un layout `hero + form`
- `Choix profil` et `Choix / ajout source` adoptent une logique galerie / cards premium
- les profils sont representes par un rond / avatar rond avec le nom en dessous
- la TV est une version responsive du telephone, pas une UI structurellement differente
- l'iconographie cible repose sur `Lucide Icons`

## Ancrage dans l'existant

Le code confirme deja plusieurs fondations utiles:
- theme centralise via [app_theme.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/theme/app_theme.dart)
- palette de base via [app_colors.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/theme/app_colors.dart)
- splash reutilisable via [overlay_splash.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/widgets/overlay_splash.dart)
- bouton primaire commun via [movi_primary_button.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/widgets/movi_primary_button.dart)
- primitives welcome deja existantes via [welcome_header.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/features/welcome/presentation/widgets/welcome_header.dart) et [welcome_form.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/features/welcome/presentation/widgets/welcome_form.dart)
- infrastructure responsive via [responsive_layout.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/responsive/presentation/widgets/responsive_layout.dart)
- infrastructure de focus / navigation via [movi_focusable.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/widgets/movi_focusable.dart) et [movi_remote_navigation.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/widgets/movi_remote_navigation.dart)

Constats utiles:
- le theme actuel est deja `Material 3` avec palette Movi et typo `Montserrat`
- les boutons primaires ont deja une signature visuelle `pill / stadium`
- le splash existant correspond deja a la structure voulue, mais devra etre harmonise avec la future microcopy et la densite finale
- la TV dispose deja d'une logique de focus et de navigation, ce qui pousse a penser la spec UI avec continuites plutot qu'avec une branche visuelle totalement separee

## Surfaces UI a specifier

### Surfaces ecran principales

1. `Preparation systeme`
Surface plein ecran de splash / bootstrap visuel.

2. `Auth`
Surface de hero + formulaire avec etat avant envoi du code et etat apres envoi du code.

3. `Creation profil`
Surface de hero + formulaire courte, centree sur un seul objectif.

4. `Choix profil`
Surface galerie premium avec avatars ronds et labels sous les cartes.

5. `Choix / ajout source`
Hub source unifie avec:
- galerie ou liste de sources existantes
- action d'ajout
- message inline en cas de source invalide ou absente

6. `Chargement medias`
Surface de progression avant `Home`, distincte du splash systeme mais dans la meme famille visuelle.

7. `Home vide`
Etat d'arrivee visible quand la source est valide mais sans contenu exploitable.

### Sous-surfaces et modules transverses

1. `Header tunnel`
Retour, titre, sous-titre, eventuelle meta de contexte.

2. `Hero tunnel`
Logo, titre, sous-titre, ambiance visuelle, eventuelle illustration abstraite.

3. `Form shell`
Structure standard des formulaires du tunnel.

4. `Selection gallery`
Profils et sources sous forme de cards focusables.

5. `Loading module`
Spinner ou progression, message principal, message secondaire, eventuel retry.

6. `Recovery banner / inline message`
Erreur source, sync partielle, chargement long, absence de reseau, fallback local.

7. `Empty state / confirmation state`
Traitement visuel du `Home vide` et confirmations breves.

## Contraintes de design, mobile, TV et accessibilite

### Contraintes de design

- reutiliser la palette Movi existante, pas de nouvelle identite couleur
- conserver une coherence explicite avec `home`
- partir des primitives deja visibles dans l'app plutot que multiplier de nouveaux patterns
- garder une impression premium, sobre et lisible
- privilegier `hero + form` sur les ecrans de saisie
- privilegier `cards premium` pour les ecrans de choix
- conserver le logo comme ancrage principal de `Preparation systeme`
- utiliser `Lucide Icons` comme reference iconographique cible
- respecter la typo existante de l'app, sauf probleme majeur de lisibilite

### Contraintes mobile

- comprehension rapide en une seule colonne dominante
- action primaire visible sans scroller dans les cas nominaux
- densite maitrisee sur les formulaires
- messages inline visibles sans casser la progression
- cartes profils / sources lisibles sans surcharge textuelle

### Contraintes TV

- la TV doit rester une adaptation responsive du telephone, pas une experience re-concue
- plus d'espace, plus de taille, plus de respiration
- focus visible et stable a tout moment
- la hiérarchie doit rester evidente a distance
- les galeries doivent rester faciles a parcourir a la telecommande
- aucun changement d'etat ne doit perdre le focus de maniere confuse

### Contraintes d'accessibilite

- contrastes suffisants sur fond sombre et clair
- titres, corps, aides et messages systeme distincts visuellement
- focus clairement visible pour clavier et telecommande
- zones d'action suffisantes pour le tactile
- messages relies a la bonne action et au bon champ
- erreurs et recoveries compréhensibles sans jargon
- progression et chargement comprehensibles meme sans animation

### Contraintes d'implementation deja visibles dans le code

- `AppTheme` impose deja certains rayons, couleurs de surface et styles de boutons
- `OverlaySplash` pose deja une structure logo centre / indicateur bas
- `MoviPrimaryButton` cree deja une attente de CTA large et fortement lisible
- `ResponsiveLayout` et `MoviRemoteNavigation` poussent a specifier la TV comme extension du systeme actuel, pas comme exception tardive

## Arbitrages visuels encore ouverts

Ces sujets relevent encore de la phase UI et devront etre tranches en `2.1` ou `2.2`.

1. Niveau exact d'expressivite visuelle du tunnel
Premium sobre ou premium plus cinematographique.

2. Traitement du fond du tunnel
Fond tres epure, gradient subtil, texture douce ou ambiance visuelle plus marquee.

3. Place exacte du logo hors splash
Logo systematique dans le hero ou seulement sur certaines surfaces.

4. Rapport hero / form
Hero plus editorialise ou hero tres compact au profit du formulaire.

5. Style final des cards profil
Niveau de relief, taille de l'avatar rond, poids du nom et gestion du focus.

6. Style final des cards source
Card plus technique ou card plus premium / produit.

7. Forme finale des messages inline
Banniere, encart ton sur ton, ligne d'etat simple ou bloc avec icone.

8. Niveau de motion
Transitions tres discretes ou un peu plus premium sans allonger la perception de chargement.

9. Traitement visuel de `Chargement medias`
Simple derivation du splash ou surface un peu plus riche pour marquer l'avant-`home`.

10. Traitement visuel de `Home vide`
Empty state tres sobre ou empty state plus editorialise.

## Ambiguities restantes a lever avant la sous-phase 2.1

Ces points ne bloquent pas `2.0`, mais doivent etre assumes explicitement au demarrage de la direction visuelle.

1. Le tunnel doit-il etre strictement sombre par defaut, ou la phase 2 doit-elle aussi prevoir la variante claire en meme temps ?

2. `Lucide Icons` devient-il une cible de migration progressive, ou une contrainte immediate pour toute nouvelle spec UI du tunnel ?

3. Pour les cards de profil, veut-on une seule taille cible qui scale responsivement, ou deux densites explicites `mobile` et `TV` ?

4. Pour les cards source, faut-il afficher beaucoup d'informations techniques visibles, ou garder une surface premium avec details techniques secondaires ?

5. Le `hero + form` doit-il rester dans une colonne unique sur tous les formats, ou peut-il passer en composition plus laterale sur les grands ecrans tout en restant cohérent avec mobile ?

6. Le futur flow TV par QR code etant differe, veut-on deja reserver une place visuelle potentielle dans le systeme, ou l'ignorer completement a ce stade ?

## Ce qui est fixe et ne doit plus etre re-ouvert en phase 2

- le parcours cible issu de la phase 1
- la liste des ecrans cibles
- le fait que `Home` n'apparaisse qu'apres preparation terminee
- la logique responsive TV plutot que la creation d'un tunnel TV autonome
- la reutilisation de l'identite visuelle existante de l'app

## Verdict de sortie de la sous-phase 2.0

Verdict:
- la sous-phase `2.0` est suffisamment cadree pour lancer `2.1`

Pourquoi:
- les surfaces UI a specifier sont connues
- les contraintes de design et de plateforme sont explicites
- l'ancrage dans l'existant est assez clair pour eviter une spec deconnectee du code
- les arbitrages encore ouverts sont de nature visuelle et peuvent etre traites proprement en direction visuelle

## Prochaine etape recommandee

La suite logique est:
1. fixer la direction visuelle du tunnel
2. formaliser palette, typo, surfaces, spacing, iconographie et motion
3. choisir le niveau exact d'expressivite premium sans casser la coherence avec `home`

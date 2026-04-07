# Sous-phase 2.5 - Responsive, accessibilite et TV

## Objectif

Verrouiller les regles d'adaptation du tunnel entre mobile et TV, ainsi que les exigences d'accessibilite et de navigation telecommande.

Cette sous-phase fixe:
- les principes responsive du tunnel
- les tailles minimales et regles de densite
- les exigences d'accessibilite
- les regles de focus et navigation TV
- les ecarts autorises entre mobile et TV

## Ancrage dans l'existant

Le code fournit deja des fondations a respecter:
- resolution des types d'ecran via [screen_type_resolver.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/responsive/application/services/screen_type_resolver.dart)
- types `mobile / tablet / desktop / tv` via [screen_type.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/responsive/domain/entities/screen_type.dart)
- primitives de focus via [movi_focusable.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/widgets/movi_focusable.dart)
- navigation telecommande via [movi_remote_navigation.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/widgets/movi_remote_navigation.dart)

Decision de phase:
- la TV reste une version responsive du telephone
- la spec doit donc prioriser des ecarts de densite, de taille et de focus, pas une divergence structurelle

## Principes responsive du tunnel

## Regle directrice

Le tunnel doit garder:
- le meme ordre logique
- les memes actions primaires
- les memes composants de base

Ce qui peut changer:
- largeur utile
- nombre de cartes visibles
- densite de texte
- importance visuelle du focus
- respiration entre les blocs

## Regles par type d'ecran

### Mobile

But:
- lecture immediate
- une colonne dominante
- actions visibles rapidement

Regles:
- hero + contenu dans une colonne centrale
- formulaires plein largeur utile
- galleries de profils ou sources en 1 ou 2 colonnes selon place
- CTA principal visible sans long scroll dans les cas nominaux

### Tablet / desktop

But:
- gagner en respiration sans changer la logique

Regles:
- largeur max plus large
- possibilite d'augmenter la largeur de form et de galerie
- separation visuelle plus confortable entre blocs
- pas de second axe d'information si cela complique la lecture

### TV

But:
- comprehension a distance
- navigation telecommande stable

Regles:
- meme grammaire de layout que mobile
- blocs plus grands et plus aeres
- nombre de mots reduit quand possible
- focus tres visible
- scrolling evite autant que possible sur la premiere vue utile

## Regles de densite et tailles minimales

## Typographie

Exigences:
- le titre doit rester lisible a distance
- le texte secondaire ne doit jamais tomber dans un gris trop faible
- les labels de champs doivent rester nets sur fond sombre

Regles:
- mobile:
  - titres courts et compacts
  - texte secondaire limite
- TV:
  - tailles de texte augmentees
  - sous-textes plus courts plutot que plus petits

## Boutons et actions

Exigences:
- boutons primaires tres lisibles
- zones tactiles confortables
- zones focusables faciles a atteindre en TV

Regles:
- CTA principal plein large sur mobile
- CTA avec hauteur confortable sur tous les formats
- en TV, les actions focusables ne doivent pas etre trop proches les unes des autres

## Champs et formulaires

Exigences:
- champs faciles a lire et a selectionner
- erreurs visibles sans casser la comprehension du formulaire

Regles:
- labels au-dessus du champ
- espacement constant entre champ, aide, erreur et action
- en TV, eviter les empilements trop longs avant le CTA

## Cartes profils et sources

Exigences:
- carte assez grande pour etre selectionnee clairement
- nom lisible sans devoir zoomer mentalement
- focus tres distinct de l'etat `selected`

Regles:
- mobile:
  - cartes compactes mais respirantes
- TV:
  - cartes plus grandes
  - plus d'espace entre cartes
  - focus prioritaire sur la carte, pas sur des sous-elements internes

## Regles d'accessibilite

## Contraste

Le tunnel doit respecter:
- contraste fort entre fond et texte principal
- contraste suffisant pour texte secondaire
- contraste de focus visible sans ambiguite
- contraste des etats `error`, `warning`, `info` lisible sur fond sombre

Regle:
- ne jamais coder un message critique avec couleur seule comme seul signal

## Lisibilite

Le tunnel doit:
- limiter les paragraphes longs
- garder une seule idee principale par bloc
- eviter le jargon technique
- relier chaque message a l'action concernee

## Structure et ordre de lecture

Le tunnel doit:
- presenter le titre avant l'action
- garder une relation claire entre champ, aide et erreur
- garder une relation claire entre message inline et CTA
- ne pas changer brutalement l'ordre logique entre mobile et TV

## Semantique et navigation

Le tunnel doit:
- exposer des labels clairs pour les actions
- distinguer les etats `disabled`, `focused`, `selected`
- garder un ordre de tabulation coherent
- permettre la navigation clavier et telecommande sans pieges

## Regles specifiques de focus TV

## Principes directeurs

1. il doit toujours etre evident ou se trouve le focus
2. le focus ne doit jamais disparaitre apres un changement d'etat
3. le focus doit suivre la logique de l'ecran, pas seulement la geometrie brute
4. le focus doit prioriser l'action principale et la prochaine action utile

## Style de focus recommande

Le focus doit etre compose de:
- contour accent visible
- halo ou elevation legere
- scale discret
- eventuel changement subtil de fond de carte

Le focus ne doit pas:
- clignoter
- pulser en continu
- ressembler a l'etat `selected`

## Focus order par type de surface

### `Preparation systeme`

Ordre:
- aucun focus en nominal
- `Retry` prioritaire si un recovery apparait

### `Auth`

Ordre:
1. premier champ
2. champ suivant
3. CTA principal
4. action secondaire

Regle:
- si une erreur inline apparait, le focus ne saute pas dessus automatiquement
- le focus reste sur le champ ou l'action qui permet de corriger

### `Creation profil`

Ordre:
1. champ nom
2. options avatar / couleur
3. CTA principal
4. action secondaire

### `Choix profil`

Ordre:
- galerie d'abord
- retour ensuite

Regle:
- chaque carte profil est un focus target complet
- pas de focus interne dans une carte simple

### `Choix / ajout source`

Ordre recommande si deux zones:
1. galerie des sources
2. formulaire source
3. CTA principal
4. action secondaire

Regles:
- si aucune source existante, le focus entre directement dans le formulaire
- si une source invalide est signalee, le focus reste sur la zone permettant la correction
- ne pas forcer le focus sur la banniere d'erreur

### `Chargement medias`

Ordre:
- aucun focus en nominal
- `Retry` prioritaire si recovery visible

### `Home vide`

Ordre:
1. action primaire
2. action secondaire eventuelle

## Focus traps et changements d'etat

Le tunnel doit eviter:
- les pieges de focus dans une section secondaire
- la perte du focus apres apparition d'un message inline
- le retour du focus sur le premier element de la page sans raison

Regles:
- un message inline n'intercepte pas le focus par defaut
- une bannere de recovery n'intercepte le focus que si elle devient la priorite d'action de la surface
- lors d'un changement d'etat du formulaire, le focus reste au plus pres de la prochaine action utile

## Ensure visible et scroll

Le code existant montre deja un mecanisme `ensureVisible`.

Regles de spec:
- en TV, tout element focusable hors viewport doit etre amene dans la zone visible sans mouvement brutal
- eviter les scrolls longs provoques par un focus mal ordonne
- sur les ecrans tunnel, preferer des surfaces qui tiennent dans la premiere vue utile

## Ecarts autorises entre mobile et TV

Autorises:
- tailles plus grandes
- marges plus importantes
- densite de texte reduite
- poids du focus renforce
- galerie plus aeree
- separation visuelle plus nette entre inventaire et edition dans le hub source

Non autorises:
- reordonner completement les blocs
- changer l'action principale
- convertir une action inline mobile en parcours autonome TV
- introduire de nouveaux ecrans TV-specifiques dans la phase 2

## Checklist de validation responsive et accessibilite

1. chaque ecran garde la meme logique mobile et TV
2. le titre et le CTA principal sont visibles rapidement
3. le focus est toujours visible sur TV
4. le focus ne saute pas sur les messages inline sans raison
5. les erreurs restent proches des actions ou champs concernes
6. les galleries restent parcourables sans confusion
7. les contrastes restent lisibles sur fond sombre
8. la lecture du tunnel reste claire a distance

## Verdict de sortie de la sous-phase 2.5

Verdict:
- la cible mobile + TV est suffisamment stable pour consolider la spec UI finale

Pourquoi:
- les ecarts autorises sont explicites
- les exigences d'accessibilite sont posees
- la navigation telecommande est cadree
- les regles de focus suivent la logique du tunnel

## Prochaine etape recommandee

La suite logique est:
1. consolider la spec UI ecran par ecran
2. rattacher chaque surface a ses composants et a ses regles responsive
3. produire la checklist d'implementation UX/UI finale

# Phase 4 - Etape 1 - Audit UI et composants existants

## Objectif

Verifier l'etat reel des composants, widgets legacy et specs Figma avant toute
modification UI.

## Sources relues

- `docs/app_launch_refactor/figma_boot_screens_spec.md`
- `docs/app_launch_refactor/designs/json/*.json`
- `lib/src/core/widgets/movi_asset_icon.dart`
- `lib/src/core/widgets/movi_primary_button.dart`
- `lib/src/shared/widgets/app_labeled_text_field.dart`
- `lib/src/core/profile/presentation/ui/widgets/profile_avatar_chip.dart`
- `lib/src/core/widgets/overlay_splash.dart`
- `lib/src/core/widgets/launch_error_panel.dart`
- `lib/src/core/startup/presentation/widgets/launch_recovery_banner.dart`
- `lib/src/core/startup/presentation/boot_screen_model.dart`

## Constats Figma

Les exports JSON disponibles couvrent les surfaces principales :

- chargements simples : demarrage technique, verification session, resolution
  profil, resolution source ;
- catalogue : preparation du catalogue, catalogue pret en cache ;
- recoveries : erreur technique, identifiants invalides, source echec avec ou
  sans alternative ;
- pages d'action : connexion, inscription, mot de passe oublie, profil, source ;
- composants : button, text input, profile avatar.

Les frames critiques sont en `393x852`. Les tokens recurrents sont :

- fond `rgb(20, 20, 20)` ;
- texte blanc ;
- bouton `250x50`, radius `25`, padding horizontal `16`, Inter 16 bold ;
- input `300x50`, radius `25`, fond `rgb(51, 51, 51)`, padding horizontal `20` ;
- logo Figma exporte comme rectangle `150x90`, a remplacer par l'asset reel ;
- recovery mobile avec contenu centre, largeur `393`, padding horizontal `20`,
  titre 28 bold, messages 16.

## Table composants

```text
composant | usage actuel | usage cible boot | adaptation requise | fichier | risque
MoviAssetIcon | rendu generique SVG/raster, fallback dedie app logo | logo boot final avec AppAssets.iconAppLogoSvg | reutilisation directe ; fixer tailles boot 120/150 selon ecran, semantic label propre | lib/src/core/widgets/movi_asset_icon.dart | faible : le composant sait deja rendre le logo et a un fallback PNG
MoviPrimaryButton | bouton primary plein largeur par defaut, height 48, radius theme + focus scale/border | action principale recovery/pages, largeur mobile Figma 250 et hauteur 50 | probablement passer expand=false ou contraindre parent ; possible variante/style boot si theme ne donne pas radius 25/poids 700 | lib/src/core/widgets/movi_primary_button.dart | moyen : bouton actuel ellipsis texte, expand=true par defaut, focus visuel existe mais dimension Figma a verifier
AppLabeledTextField | label + TextFormField, decoration injectable, focus directionnel optionnel | inputs pages auth/source/profil alignes Figma 300x50 radius 25 padding 20 | reutiliser avec decoration boot ; peut necessiter helper/variante pour eviter duplication decoration | lib/src/shared/widgets/app_labeled_text_field.dart | moyen : hauteur/radius/couleurs dependent de decoration/theme, pas verrouilles par defaut
ProfileAvatarChip | cercle couleur + Icon person + label, size 80 par defaut, selected border | avatar Figma initiale + nom, 75x75, lettre 32 bold | adaptation necessaire : variante initiale texte au lieu d'icone, size 75, focus/selection TV a verifier | lib/src/core/profile/presentation/ui/widgets/profile_avatar_chip.dart | moyen : commentaire encode mal certains accents, aucun focus integre, icon au lieu initiale
OverlaySplash | splash centre logo, spinner + message bas ecran, Riverpod pour accent, elapsed seconds | chargements simples logo centre + texte bas ecran | bonne base ; probablement envelopper/extraire pour BootScreenModel, desactiver details elapsed si Figma ne les veut pas, mapper messages | lib/src/core/widgets/overlay_splash.dart | moyen : texte actuel ajoute duree, encodage altere dans fallback, depend de ConsumerWidget/ref
LaunchErrorPanel | panneau centre avec message, details optionnels, un bouton retry | technical failure/recovery action panel | remplacer ou envelopper ; manque titre, action secondaire, severity, mapping BootActionIntent | lib/src/core/widgets/launch_error_panel.dart | eleve : trop generique et mono-action pour Phase 4
LaunchRecoveryBanner | banniere compacte message + bouton Reessayer | Home partial ou recovery compacte selon besoin | ne pas utiliser pour recovery boot bloquante ; peut inspirer Home partial mais manque actions multiples et modele notice | lib/src/core/startup/presentation/widgets/launch_recovery_banner.dart | moyen : texte action code en dur, radius 16, pas de contrat BootScreenModel
BootScreenModel | modele presentation avec screenType, title, message, actions, focus, severity | entree unique du renderer boot | reutilisation directe ; renderer a creer en Phase 4 et tests widget a brancher | lib/src/core/startup/presentation/boot_screen_model.dart | faible : contrat deja stabilise, mais textes encore non localises
BootScreenMapper | projection AppLaunchState -> BootScreenModel | source du contenu pour renderer | ne pas dupliquer ; verifier seulement que les widgets n'affichent pas reasonCode brut | lib/src/core/startup/presentation/boot_screen_mapper.dart | moyen : textes encore hardcodes, a reprendre en Phase 6
```

## Table designs JSON

```text
design | taille | cible Flutter | composant de depart | ecart principal
demarrage-technique | 393x852 | chargement simple | OverlaySplash + MoviAssetIcon | remplacer rectangle logo, texte bas sans duree si Figma strict
verification-de-session | 393x852 | chargement simple | OverlaySplash + BootScreenModel | meme structure que demarrage
resolution-du-profil | 393x852 | chargement simple/action profil | OverlaySplash puis pages profil | distinguer loading et pages action
resolution-de-la-source-iptv | 393x852 | chargement simple/action source | OverlaySplash puis pages source | ne pas remettre logique source dans widget
preparation-du-catalogue | 393x852 | catalogLoading | nouveau BootCatalogLoading ou OverlaySplash enrichi | sous-message, non interactif, pas Changer de source immediat
catalogue-pret-en-cache | 393x852 | openingHome/cache ready | OverlaySplash ou transition courte | peut ne pas avoir surface dediee si transition instantanee
erreur-technique-de-boot | 393x852 | technicalFailure | nouveau BootRecoveryPanel | titre + message + actions multiples
identifiants-source-invalides | 393x852 | actionRequired source credentials | nouveau BootRecoveryPanel | action principale reconnecter, secondaire conditionnelle
button | 250x50 | action buttons | MoviPrimaryButton | expand false/contrainte width, radius/weight a verifier
text-input | 300x81 total, input 300x50 | pages action | AppLabeledTextField | decoration boot commune requise
profile-avatar | 75x106 | selection profil | ProfileAvatarChip | initiale texte + focus/selection
```

## Decisions de l'etape 1

- Reutiliser `MoviAssetIcon` pour le logo boot, avec
  `AppAssets.iconAppLogoSvg`.
- Ne pas reproduire le rectangle logo Figma comme forme finale.
- Repartir de `OverlaySplash` pour les chargements simples, mais eviter que la
  future UI boot depende de la duree elapsed si la maquette ne la demande pas.
- Creer ou envelopper une surface recovery dediee plutot que forcer
  `LaunchErrorPanel`.
- Garder `LaunchRecoveryBanner` pour Home partial seulement si son format est
  adapte apres audit de l'etape 8.
- Adapter `ProfileAvatarChip` pour l'initiale + nom plutot que creer un second
  composant profil sans raison.
- Adapter `AppLabeledTextField` via decoration/API boot si les pages d'action
  doivent suivre strictement les JSON.

## Risques pour les etapes suivantes

- Les strings des composants legacy contiennent des traces d'encodage altere ;
  la Phase 6 devra localiser/nettoyer les textes finaux.
- Les JSON ne suffisent pas pour valider le comportement TV/focus ; il faudra
  tester au clavier.
- Les surfaces recovery Figma semblent plus riches que `LaunchErrorPanel` et
  `LaunchRecoveryBanner`; un nouveau panneau est probablement plus simple qu'une
  extension excessive.
- Les pages d'action existantes sont larges et riches ; l'alignement visuel doit
  rester chirurgical pour ne pas deplacer leur logique metier.

## Definition de fini de l'etape 1

- [x] Les composants a reutiliser sont listes.
- [x] Les ecarts Figma/composants existants sont explicites.
- [x] Aucun composant nouveau n'est cree sans justification.

# Cartographie des composants UI reutilisables

## Synthese

Les composants de base existent deja pour couvrir une grande partie des ecrans
Figma du boot :

- boutons : `MoviPrimaryButton` ;
- champs : `AppLabeledTextField` ;
- avatar profil : `ProfileAvatarChip` ;
- logo/assets : `MoviAssetIcon` + `AppAssets` ;
- focus TV : `FocusRegionScope`, `MoviFocusableAction`,
  `MoviFocusFrame`, `AppDirectionalFocusWrapper`,
  `MoviEnsureVisibleOnFocus`.

La palette Figma est deja alignee avec le theme :

- fond boot Figma `rgb(20, 20, 20)` = `AppColors.darkBackground` ;
- accent Figma `rgb(33, 96, 171)` = `AppColors.accent` / `#2160AB` ;
- police Figma Inter = `AppTheme` utilise deja `fontFamily: 'Inter'`.

Conclusion : il ne faut pas recreer un design system. Il faut creer des
variantes boot fines au-dessus des composants existants.

## Logo asset reel

| besoin | asset existant | notes |
| --- | --- | --- |
| Logo Movi complet des ecrans Figma | `assets/branding/app_logo.svg` via `AppAssets.iconAppLogoSvg` | C'est le logo reel a utiliser pour les ecrans boot. Ne pas le recoloriser si la maquette attend l'image du logo. |
| Fallback raster | `assets/branding/app_icon.png` via `AppAssets.iconAppIconPng` | Deja utilise comme fallback par `MoviAssetIcon` si le SVG du logo echoue. |

Observation : `OverlaySplash` et `WelcomeHeader` utilisent actuellement
`MoviAssetIcon(AppAssets.iconAppLogoSvg, color: accentColor)`. Pour la spec boot,
il faudra probablement rendre le logo sans `color` pour afficher l'image asset
reelle.

## Table composants Figma / existant

| besoin Figma | composant existant | ecart | action recommandee |
| --- | --- | --- | --- |
| Bouton principal 250x50, radius 25, fond `#2160AB`, texte blanc Inter 16/700, padding horizontal 16. | `MoviPrimaryButton` + `FilledButtonTheme`. | Tres proche sur couleur/radius. Hauteur par defaut 48, padding interne 8/2, texte theme 16/600, focus scale/border ajoute. | Reutiliser `MoviPrimaryButton` avec une variante boot : `height: 50`, `expand: false` ou largeur contrainte 250, `buttonStyle` texte 700/padding 16, conserver focus TV. |
| Boutons secondaires dans recovery. | Aucun composant boot dedie. `OutlinedButton`, `TextButton`, `MoviPrimaryButton` existent. | Figma utilise plusieurs instances de `Button`, mais les actions recovery ne sont pas toutes primaires. | Creer `BootActionButton` avec variantes `primary` / `secondary` mappees depuis `RecoveryAction`. Eviter `LaunchRecoveryBanner`. |
| Text input 300x81, label Inter 16/600, champ 300x50, fond `#333333`, radius 25, placeholder Inter 16/500 `#BFBFBF`, padding horizontal 20. | `AppLabeledTextField`. | Structure label + champ deja presente. Theme actuel radius 16, fill `AppColors.darkSurface` `#1E1E1E`, hauteur depend du `TextFormField`, pas de style boot radius 25. | Reutiliser `AppLabeledTextField` avec `decoration` boot : filled `#333333`, radius 25, height stable 50 via constraints/contentPadding, placeholder `#BFBFBF`. |
| Champ password avec toggle visibilite. | `AppLabeledTextField` accepte `obscureText`, mais pas `suffixIcon` direct hors `decoration`. | Les ecrans actuels gerent le toggle a la main dans `WelcomeSourcePage`. | Etendre via `decoration` ou creer un wrapper `BootPasswordField` compose de `AppLabeledTextField`. |
| Avatar profil 75x75, cercle accent, initiale Inter 32/700, label Inter 16/600. | `ProfileAvatarChip`. | Taille par defaut 80, affiche `Icon(Icons.person)` plutot qu'une initiale, label 16/500 blanc, border selected 3. | Adapter `ProfileAvatarChip` avec un mode initiale ou creer `BootProfileAvatarChip` compose. Taille 75, label weight 600. |
| Liste horizontale de profils, 3 avatars sur 305x106. | `ProfileAvatarChip` + focus `MoviFocusableAction` / `MoviFocusFrame`. | Le composant avatar n'est pas focusable seul. | Composer avatar + `MoviFocusableAction`, garder focus frame stable. |
| Checkbox "Se souvenir de mon choix" 20x20, radius 4, fond `#333333`, texte Inter 16/500. | `CheckboxTheme` existe avec radius 6; focus wrappers existent. | Radius et fond legerement differents; pas de composant boot dedie. | Creer `BootRememberChoiceCheckbox` ou utiliser `Checkbox` theme local radius 4/fill `#333333`. |
| Logo + titre + sous-titre d'ecran interactif : logo 150x90 dans zone 150x150, titre 28/700, sous-titre 16/500, largeur 353. | `WelcomeHeader`. | `WelcomeHeader` affiche logo 100/88, recolorise le logo, titre `headlineSmall` 24/600, paddings differents. | Ne pas reutiliser tel quel. Creer `BootHeader` avec `MoviAssetIcon` sans couleur, slots titre/sous-titre et dimensions Figma. |
| Ecrans de chargement non interactifs : fond `#141414`, logo centre, texte court hors flux central en bas selon correction utilisateur. | `OverlaySplash`. | `OverlaySplash` centre le logo mais positionne spinner+message en bas, ajoute compteur secondes, recolorise le logo, texte fallback generique. | Adapter ou creer `BootLoadingScreen` : logo image 150x90 centre, texte court bas d'ecran, spinner optionnel selon etat, pas de compteur par defaut. |
| Ecran `Preparation du catalogue` : titre 16/600 + sous-texte 16/400 sous logo. | `OverlaySplash` partiellement. | `OverlaySplash` n'a qu'un message unique + compteur. | `BootLoadingScreen` doit accepter `title` et `subtitle`, avec position basse conforme spec. |
| Ecran `Catalogue pret en cache` : meme structure loading avec titre/sous-texte. | `OverlaySplash` partiellement. | Pas de distinction titre/sous-titre. | Meme composant `BootLoadingScreen`, alimente par `CatalogMode.cached`. |
| Ecrans recovery : header logo/titre/sous-titre + actions verticales, largeur 353, gaps 32/16. | `LaunchErrorPanel`, `LaunchRecoveryBanner`, `MoviPrimaryButton`. | `LaunchErrorPanel` est trop minimal; `LaunchRecoveryBanner` est une bannier, pas un ecran; pas de mapping multi-actions. | Creer `BootRecoveryScreen` compose de `BootHeader` + `BootActionButton` + sections optionnelles source/profil. |
| Ecran ajout source : header + 4 inputs + bouton. | `WelcomeSourcePage`, `AppLabeledTextField`, `MoviPrimaryButton`. | `WelcomeSourcePage` a trop de logique Supabase et UI legacy; inputs sont `TextField` directs. | Recomposer avec `BootHeader`, `AppLabeledTextField` variante boot, `MoviPrimaryButton` variante boot; extraire logique dans controller/orchestrateur. |
| Ecran choisir source/profil : header + liste d'options + actions. | `IptvSourceSelectionList`, `ProfileAvatarChip`, focus helpers. | Les listes existantes sont fonctionnelles mais pas strictement Figma. | Reutiliser logique/focus, creer presentation boot dediee si la fidelite visuelle est prioritaire. |
| Focus TV / desktop sur boutons, listes, formulaires. | `FocusRegionScope`, `FocusRegionBinding`, `MoviFocusableAction`, `MoviFocusFrame`, `AppDirectionalFocusWrapper`, `MoviEnsureVisibleOnFocus`. | Couche deja solide mais actuellement dispersee dans les pages legacy. | Reutiliser tel quel; definir des regions boot stables pour chaque ecran. |

## Composants reutilisables confirmes

- `MoviPrimaryButton` : base pour toutes les actions principales.
- `AppLabeledTextField` : base pour champs boot.
- `ProfileAvatarChip` : base pour avatar profil, avec adaptation initiale.
- `MoviAssetIcon` : rendu SVG/raster local, a utiliser sans recolorisation pour
  le logo boot.
- `AppAssets` : registre asset officiel, contient le logo reel.
- `FocusRegionScope` et `FocusRegionBinding` : gestion des regions focus.
- `MoviFocusableAction` et `MoviFocusFrame` : interaction focusable pour cartes
  et options.
- `AppDirectionalFocusWrapper` et `MoviEnsureVisibleOnFocus` : navigation
  clavier/TV et scroll automatique.

## Variantes a creer

| variante | base | responsabilite |
| --- | --- | --- |
| `BootLogo` | `MoviAssetIcon` / `AppAssets.iconAppLogoSvg` | Afficher le logo asset reel, dimensions Figma, sans `color` par defaut. |
| `BootHeader` | Nouveau compose | Logo + titre 28/700 + sous-titre 16/500, largeur/paddings boot. |
| `BootLoadingScreen` | `OverlaySplash` a remplacer ou wrapper | Chargements non interactifs avec texte court bas d'ecran, title/subtitle optionnels, pas de details techniques. |
| `BootPrimaryButton` ou config `MoviPrimaryButton.boot` | `MoviPrimaryButton` | Hauteur 50, radius 25, texte 16/700, largeur contrainte. |
| `BootSecondaryButton` | `MoviPrimaryButton` ou `OutlinedButton` | Actions recovery secondaires. |
| `BootTextField` | `AppLabeledTextField` | Decoration Figma radius 25/fond #333/placeholder #BFBFBF. |
| `BootPasswordField` | `BootTextField` | Champ password avec toggle visibilite et focus droit/gauche. |
| `BootProfileAvatarChip` | `ProfileAvatarChip` | Initiale, taille 75, label 16/600, etat selected/focus. |
| `BootRememberChoiceCheckbox` | `Checkbox` + focus wrapper | Checkbox 20x20 radius 4 + label. |
| `BootRecoveryScreen` | `BootHeader` + boutons | Ecran recovery multi-actions base sur `RecoveryAction`. |

## Points d'attention

- Ne pas dupliquer `AppColors.accent` : la couleur Figma existe deja.
- Ne pas dupliquer le systeme focus : il est deja mature et doit etre
  conserve.
- Ne pas continuer a utiliser les ecrans legacy comme source visuelle : ils
  contiennent de la logique metier et des messages hardcodes.
- Pour le logo, eviter `color: accentColor` dans les ecrans boot si la spec
  demande l'image du logo telle quelle.
- Les ecrans Figma sont exportes en largeur 393 ; les composants doivent rester
  responsives pour TV/desktop avec contraintes max, pas avec largeurs fixes
  globales.

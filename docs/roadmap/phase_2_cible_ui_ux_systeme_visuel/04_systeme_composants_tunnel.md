# Sous-phase 2.3 - Systeme de composants du tunnel

## Objectif

Transformer la structure cible du tunnel en systeme de composants reutilisables, coherent avec l'app existante et assez clair pour preparer l'implementation.

Cette sous-phase fixe:
- les composants communs du tunnel
- leur responsabilite
- leurs variantes principales
- les impacts mobile et TV
- ce qui doit etre cree, refactore, conserve ou retire

## Regles directrices

1. un composant doit porter une responsabilite claire
2. les etats du tunnel doivent etre pris en charge dans les composants, pas recodes ecran par ecran
3. la TV doit etre couverte par variantes et regles de focus, pas par un sous-systeme parallele
4. les composants du tunnel doivent s'appuyer au maximum sur le theme et les primitives existantes
5. aucune surface tunnel ne doit reconstruire son propre header, hero, form ou feedback inline

## Inventaire cible des composants du tunnel

## 1. Composants shell

### `TunnelPageShell`

Responsabilite:
- structure de page commune du tunnel
- gestion du fond
- padding principal
- safe areas
- scroll si necessaire
- variation mobile / TV sans changer la grammaire

Variantes:
- `immersive`: splash / chargement
- `hero_form`: auth / creation profil
- `selection`: choix profil / choix source
- `content_state`: home vide

Contraintes mobile:
- colonne dominante
- largeur utile maitrisee

Contraintes TV:
- plus d'air
- largeur max plus grande
- focus order previsible

Decision:
- a creer

Pourquoi:
- aucun shell tunnel dedie n'existe aujourd'hui
- les pages welcome actuelles ont une structure trop locale

### `TunnelHeader`

Responsabilite:
- retour
- titre
- sous-titre optionnel
- meta de contexte optionnelle

Variantes:
- `compact`
- `centered`
- `back_title`

Base existante:
- [movi_subpage_back_title_header.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/widgets/movi_subpage_back_title_header.dart)

Decision:
- a refactorer

Pourquoi:
- la base actuelle couvre le retour + titre
- il manque une version tunnel plus flexible et coherente mobile / TV

### `TunnelHeroBlock`

Responsabilite:
- logo
- titre
- sous-titre
- eventuel fond hero discret

Variantes:
- `splash_centered`
- `hero_compact`
- `hero_form`
- `hero_selection_compact`

Base existante:
- [welcome_header.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/features/welcome/presentation/widgets/welcome_header.dart)
- [overlay_splash.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/widgets/overlay_splash.dart)
- [movi_hero_scene.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/widgets/movi_hero_scene.dart)

Decision:
- a creer en reutilisant des briques existantes

Pourquoi:
- les primitives existent, mais pas un bloc tunnel unifie

## 2. Composants formulaire

### `TunnelFormShell`

Responsabilite:
- largeur de form
- pile des champs
- zones d'aide et d'erreur
- CTA principal / secondaire

Variantes:
- `single_step`
- `two_step_auth`
- `creation_profile`
- `source_form`

Decision:
- a creer

Pourquoi:
- les formulaires welcome sont trop lies a leur page actuelle

### `TunnelField`

Responsabilite:
- label
- champ
- aide
- erreur inline

Base existante:
- [labeled_field.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/features/welcome/presentation/widgets/labeled_field.dart)
- [labeled_field.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/profile/presentation/ui/widgets/labeled_field.dart)

Decision:
- a fusionner puis refactorer

Pourquoi:
- duplication explicite de `LabeledField`
- excellent candidat a un champ tunnel / app commun

### `TunnelPrimaryAction`

Responsabilite:
- CTA principal plein large
- loading
- leading icon eventuel
- etat focus TV

Base existante:
- [movi_primary_button.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/widgets/movi_primary_button.dart)

Decision:
- a conserver comme base et refactorer legerement

Pourquoi:
- le composant est deja coherent avec le theme
- il doit simplement etre inscrit dans un systeme de variantes tunnel

### `TunnelSecondaryAction`

Responsabilite:
- action secondaire du tunnel
- retour
- changer d'adresse
- attendre

Decision:
- a creer legerement au-dessus de `TextButton` ou `OutlinedButton`

Pourquoi:
- le tunnel a besoin d'une action secondaire plus codifiee que de simples boutons disparates

## 3. Composants de selection

### `ProfileChoiceCard`

Responsabilite:
- afficher un profil selectable
- avatar rond
- nom sous l'avatar
- focus / selected state

Variantes:
- `default`
- `selected`
- `focused`
- `disabled`
- `create_new` eventuel plus tard

Base existante exploitable:
- mecaniques de focus via [movi_focusable.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/widgets/movi_focusable.dart)
- elements de profil via les widgets profile existants

Decision:
- a creer

Pourquoi:
- [movi_person_card.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/widgets/movi_person_card.dart) donne des indices de style et de focus, mais ne correspond pas au besoin de profil

### `ProfileChoiceGallery`

Responsabilite:
- grille ou liste responsive de `ProfileChoiceCard`
- focus order stable
- adaptation mobile / TV

Decision:
- a creer

Pourquoi:
- le pattern de galerie devient une brique principale du tunnel

### `SourceChoiceCard`

Responsabilite:
- afficher une source existante
- nom
- meta secondaire utile
- etat active / selectionnee
- focus

Base existante:
- [iptv_source_selection_list.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/features/iptv/presentation/widgets/iptv_source_selection_list.dart)

Decision:
- a refactorer

Pourquoi:
- la base actuelle est une liste fonctionnelle
- il faut l'elever vers une card tunnel plus premium

### `SourceChoiceGallery`

Responsabilite:
- galerie ou liste des sources disponibles
- orchestration des etats selected / focused / invalid

Decision:
- a creer

Pourquoi:
- l'inventaire de sources devient un module reusable entre onboarding et possiblement settings

### `SourceFormBlock`

Responsabilite:
- formulaire d'ajout / edition d'une source
- structure des champs
- aides et erreurs de connexion
- CTA associe

Base existante:
- [welcome_form.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/features/welcome/presentation/widgets/welcome_form.dart)
- [welcome_source_page.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/features/welcome/presentation/pages/welcome_source_page.dart)

Decision:
- a extraire et refactorer

Pourquoi:
- la logique existe, mais la composition est encore trop ecran-centrique

### `SourcePickerHub`

Responsabilite:
- assembler `SourceChoiceGallery`, separateur, `SourceFormBlock`, message contextuel et CTA

Variantes:
- `first_setup`
- `source_missing`
- `source_invalid`
- `cloud_partial`

Decision:
- a creer

Pourquoi:
- c'est le coeur de la future surface `Choix / ajout source`

## 4. Composants d'etat et feedback

### `TunnelLoadingBlock`

Responsabilite:
- spinner ou progression
- message principal
- message secondaire
- recovery si seuil depasse

Variantes:
- `preparation_systeme`
- `chargement_medias`
- `long_loading`

Base existante:
- [overlay_splash.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/widgets/overlay_splash.dart)

Decision:
- a refactorer en deux niveaux

Recommandation:
- garder `OverlaySplash` comme primitive immersive
- creer `TunnelLoadingBlock` pour les autres etats de progression

### `TunnelInlineMessage`

Responsabilite:
- afficher un message inline standardise
- relier message et action
- gerer les niveaux: info, warning, error, recovery

Variantes:
- `info`
- `warning`
- `error`
- `recovery`
- `success_brief`

Base existante:
- [launch_error_panel.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/widgets/launch_error_panel.dart)
- [launch_recovery_banner.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/startup/presentation/widgets/launch_recovery_banner.dart)

Decision:
- a creer en refactorant la logique visuelle des panneaux existants

Pourquoi:
- `LaunchErrorPanel` est trop centre page
- le tunnel a besoin d'un composant inline reutilisable

### `TunnelRecoveryBanner`

Responsabilite:
- version plus visible de `TunnelInlineMessage`
- cas: sync partielle, source invalide, absence de reseau, fallback local

Decision:
- a creer

Pourquoi:
- utile quand un etat doit prendre plus de place sans devenir un ecran

### `TunnelEmptyState`

Responsabilite:
- empty state du `Home vide`
- titre
- texte
- action primaire / secondaire sobre

Decision:
- a creer

Pourquoi:
- aucune brique tunnel dediee n'existe

## 5. Composants focus et navigation TV

### `TunnelFocusFrame`

Responsabilite:
- formaliser le style de focus du tunnel
- unifier halo, contour, scale et contraste

Base existante:
- [movi_focusable.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/widgets/movi_focusable.dart)

Decision:
- a conserver comme base, avec guidelines de style tunnel

Pourquoi:
- la mecanique est deja bonne
- il faut surtout l'encadrer visuellement

### `TunnelFocusGroup`

Responsabilite:
- definir l'ordre logique du focus a l'echelle d'un ecran ou d'un bloc
- eviter les sauts de focus absurdes entre galerie et formulaire

Base existante:
- [movi_remote_navigation.dart](/mnt/c/Users/berny/DEV/Flutter/movi/lib/src/core/widgets/movi_remote_navigation.dart)

Decision:
- a creer legerement au-dessus de l'existant

Pourquoi:
- la navigation TV existe, mais pas encore la notion de groupes de focus metier du tunnel

## Decision log create / refactor / remove

## A creer

- `TunnelPageShell`
- `TunnelHeroBlock`
- `TunnelFormShell`
- `TunnelSecondaryAction`
- `ProfileChoiceCard`
- `ProfileChoiceGallery`
- `SourceChoiceGallery`
- `SourcePickerHub`
- `TunnelInlineMessage`
- `TunnelRecoveryBanner`
- `TunnelEmptyState`
- `TunnelFocusGroup`

## A refactorer

- `MoviSubpageBackTitleHeader` -> base de `TunnelHeader`
- `OverlaySplash` -> primitive de `Preparation systeme` et base du systeme loading
- `MoviPrimaryButton` -> variante tunnel et conventions CTA
- `IptvSourceSelectionList` -> base de `SourceChoiceCard` / `SourceChoiceGallery`
- `WelcomeForm` -> extraction du `SourceFormBlock`
- `WelcomeHeader` -> extraction vers `TunnelHeroBlock`
- `LabeledField` -> fusion en champ commun
- `LaunchErrorPanel` / `LaunchRecoveryBanner` -> base des feedbacks tunnel

## A conserver quasiment tel quel

- `AppTheme` comme fondation theming
- `MoviFocusableAction`
- `MoviFocusFrame`
- `MoviRemoteNavigation`
- `ResponsiveLayout`

## A retirer comme references UI du tunnel

- `welcome/user` comme surface hybride
- constructions ecran-specifiques du welcome qui melangent shell, hero, form et logique
- duplication des `LabeledField`

## Risques de duplication ou de couplage a eviter

1. reconstruire un hero different sur chaque ecran
2. dupliquer les patterns d'erreur inline entre auth, source et loading
3. laisser `WelcomeForm` devenir la base implicite de tous les formulaires tunnel
4. coder un style de focus TV a part dans chaque galerie
5. conserver une liste de sources "settings" et une liste de sources "welcome" sans socle commun
6. recreer des boutons secondaires differents selon les pages

## Mapping ecran -> composants dominants

### `Preparation systeme`

- `TunnelPageShell`
- `TunnelHeroBlock` variante `splash_centered`
- `TunnelLoadingBlock`
- `TunnelInlineMessage` si degrade

### `Auth`

- `TunnelPageShell`
- `TunnelHeroBlock`
- `TunnelFormShell`
- `TunnelField`
- `TunnelPrimaryAction`
- `TunnelSecondaryAction`
- `TunnelInlineMessage`

### `Creation profil`

- `TunnelPageShell`
- `TunnelHeroBlock`
- `TunnelFormShell`
- `TunnelField`
- `TunnelPrimaryAction`
- `TunnelSecondaryAction`
- composant simple d'avatar / couleur

### `Choix profil`

- `TunnelPageShell`
- `TunnelHeader` ou `TunnelHeroBlock` compact
- `ProfileChoiceGallery`
- `ProfileChoiceCard`
- `TunnelSecondaryAction`
- `TunnelInlineMessage`

### `Choix / ajout source`

- `TunnelPageShell`
- `TunnelHeader` ou `TunnelHeroBlock` compact
- `SourcePickerHub`
- `SourceChoiceGallery`
- `SourceFormBlock`
- `TunnelInlineMessage`
- `TunnelRecoveryBanner`
- `TunnelPrimaryAction`
- `TunnelSecondaryAction`

### `Chargement medias`

- `TunnelPageShell`
- `TunnelLoadingBlock`
- `TunnelInlineMessage`

### `Home vide`

- `TunnelEmptyState`

## Verdict de sortie de la sous-phase 2.3

Verdict:
- le systeme de composants du tunnel est suffisamment clair pour specifier les etats et feedbacks de facon transversale

Pourquoi:
- les briques principales sont identifiees
- le create / refactor / remove est explicite
- les bases existantes reutilisables sont connues
- les principaux risques de duplication sont nommes

## Prochaine etape recommandee

La suite logique est:
1. specifier les etats, feedbacks et motion sur ce socle de composants
2. fixer les regles inline vs bloc
3. eviter qu'un meme etat soit traite differemment selon l'ecran

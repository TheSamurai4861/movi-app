# Reorganisation des assets du 17 mars 2026

## But

Ce document realise le `Lot 4.2. Reorganisation`.

Il applique la reorganisation recommandee apres l'audit des assets :

- separation branding / UI ;
- regroupement des icones par usage ;
- suppression du doublon confirme ;
- centralisation des chemins d'assets dans le code.

Document source :

- [roadmap.md](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/docs/04_product_followup/roadmap.md)

Date :

- 17 mars 2026

---

## Changements appliques

### 1. Separation branding / icones UI

Deplacement effectue :

- `assets/icons/app_icon.png` -> `assets/branding/app_icon.png`
- `assets/icons/app_logo.svg` -> `assets/branding/app_logo.svg`

Effet :

- les assets de marque ne sont plus melanges avec les icones UI runtime

### 2. Regroupement des icones de navigation

Creation du dossier :

- `assets/icons/navigation/`

Deplacements effectues :

- `home.svg`
- `search.svg`
- `library.svg`
- `settings.svg`

### 3. Regroupement des icones d'action

Creation du dossier :

- `assets/icons/actions/`

Deplacements effectues :

- `play_arrow.png`
- `back.png`
- `more.png`
- `sort.png`
- `trash.png`
- `pause.png`
- `forward.png`
- `rewind.png`
- `resize.png`
- `plus.png`
- `search.png`
- `star_filled.png`
- `star_unfilled.png`
- `delete.png`

### 4. Regroupement des icones media

Creation du dossier :

- `assets/icons/media/`

Deplacements effectues :

- `audio.png`
- `audio_disabled.png`
- `subtitles.png`
- `subtitles_disabled.png`
- `chromecast.png`
- `movie.png`
- `series.png`
- `playlist.png`

### 5. Suppression du doublon confirme

Suppression effectuee :

- `assets/icons/back.png`

Raison :

- doublon exact de l'ancien asset de retour conserve ensuite sous le nom normalise `back.png`
- aucun usage detecte dans le code

### 6. Centralisation du code

Fichiers mis a jour :

- [app_assets.dart](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/utils/app_assets.dart)
- [add_media_search_modal.dart](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/features/library/presentation/widgets/add_media_search_modal.dart)
- [library_page.dart](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/features/library/presentation/pages/library_page.dart)
- [search_page.dart](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/features/search/presentation/pages/search_page.dart)

Effet :

- les chemins hardcodes restants pour `search.png` et `delete.png` ont ete remplaces par `AppAssets`
- un nouvel identifiant `AppAssets.iconDelete` a ete ajoute

### 7. Mise a jour de la configuration Flutter

Fichier mis a jour :

- [pubspec.yaml](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/pubspec.yaml)

Changements :

- ajout de `assets/branding/` dans les assets Flutter ;
- mise a jour de `flutter_launcher_icons` vers `assets/branding/app_icon.png`

### 8. Convention de rangement et de nommage

Convention retenue :

- tous les noms de fichiers d'assets sont en anglais, en minuscules et en `snake_case`
- `branding/` contient uniquement l'identite applicative et les assets de packaging
- `icons/navigation/` contient les icones de navigation principale
- `icons/actions/` contient les actions generiques d'interface
- `icons/media/` contient les icones liees au media et aux types de contenu
- les suffixes autorises doivent exprimer une vraie variante visuelle ou fonctionnelle, par exemple `_filled`, `_unfilled`, `_disabled`
- le suffixe `_icon` est evite car tout le dossier contient deja des icones
- les chemins d'assets doivent passer par `AppAssets` plutot que par des chemins litteraux dans les widgets

---

## Structure obtenue

```text
assets/
  branding/
    app_icon.png
    app_logo.svg
  icons/
    actions/
    media/
    navigation/
```

---

## Validation

Verifications executees :

- `flutter pub get` : OK
- `flutter analyze` : OK hors 2 `info` preexistants
- `flutter build windows --debug` : OK

Infos restantes non liees a ce lot :

- [settings_page.dart](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/features/settings/presentation/pages/settings_page.dart#L856)
- [settings_page.dart](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/features/settings/presentation/pages/settings_page.dart#L859)

---

## Resultat du lot

Le lot est considere realise.

Etat obtenu :

- structure d'assets plus lisible ;
- branding separe des icones UI ;
- doublon supprime ;
- chemins centralises de facon plus coherente ;
- configuration Flutter alignee avec la nouvelle arborescence.

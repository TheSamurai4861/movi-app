# Audit des assets du 17 mars 2026

## But

Ce document realise le `Lot 4.1. Audit et tri`.

Il couvre :

- l'inventaire du dossier `assets/`
- les formats utilises
- les references reelles dans le code
- les doublons ou assets suspects
- les axes de reorganisation pour la suite

Documents lies :

- [roadmap.md](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/docs/04_product_followup/roadmap.md)
- [modernization_plan.md](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/docs/03_runbook/modernization_plan.md)

Date :

- 17 mars 2026

---

## Synthese

Le dossier `assets/` est tres compact et relativement propre, mais il souffre de trois problemes structurants :

1. tout est melange dans `assets/icons/`
2. un doublon exact a ete trouve
3. certains chemins d'assets sont encore hardcodes hors du registre central `AppAssets`

Le niveau de dette reste modere.

Le dossier n'est pas chaotique, mais il n'est pas encore organise comme un projet pro durable.

---

## Inventaire

Etat observe :

- un seul sous-dossier fonctionnel : `assets/icons/`
- 29 fichiers au total
- poids total du dossier : environ `184K`

Formats observes :

- `svg` : 5 fichiers
- `png` : 24 fichiers

Types d'assets melanges dans le meme dossier :

- icone d'application : `app_icon.png`
- logo applicatif : `app_logo.svg`
- icones de navigation : `home.svg`, `search.svg`, `library.svg`, `settings.svg`
- icones UI raster : actions player, recherche, suppression, tri, favoris, etc.

---

## Qualite generale

Points positifs :

- dossier leger ;
- assets de navigation en `svg`, ce qui est adapte ;
- icone d'application source correcte en `1024x1024` ;
- les icones raster sont petites et legeres ;
- la plupart des assets passent par le registre central [`app_assets.dart`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/utils/app_assets.dart).

Points faibles :

- absence de separation entre branding et icones UI ;
- conventions de nommage heterogenes ;
- coexistence de francais et d'anglais dans les noms ;
- quelques chemins encore utilises en dur dans le code ;
- au moins un doublon exact conserve inutilement.

---

## References reelles dans le projet

La grande majorite des assets sont references.

Constats importants :

- `app_logo.svg` est utilise comme logo visuel applicatif
- `app_icon.png` sert a `flutter_launcher_icons`, pas a l'UI runtime
- les icones de navigation SVG sont utilisees via `AppAssets`
- la plupart des PNG sont references via [`AppAssets`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/utils/app_assets.dart)

Exceptions notables :

- `search.png` est aussi reference en dur dans plusieurs widgets/pages
- `supprimer.png` est reference en dur dans plusieurs widgets/pages

Interpretation :

- le registre `AppAssets` existe, ce qui est tres bien ;
- mais il n'est pas encore utilise de facon uniforme.

---

## Doublons et assets suspects

### Doublon confirme

Doublon exact detecte :

- `back.png`
- `back_icon.png`

Constat :

- les deux fichiers sont byte-identiques ;
- seul `back_icon.png` est reference dans le projet.

Decision recommandee :

- supprimer `back.png`

Priorite :

- forte

### Asset packaging non UI

Fichier concerne :

- `app_icon.png`

Constat :

- le fichier est utile ;
- il ne releve pas des icones UI runtime ;
- il sert au packaging mobile via `flutter_launcher_icons`.

Decision recommandee :

- conserver le fichier
- mais le sortir plus tard de `assets/icons/` vers un dossier dedie branding/app icon

Priorite :

- moyenne

### Semantique potentiellement redondante

Fichiers a surveiller :

- `trash.png`
- `supprimer.png`

Constat :

- les deux assets evoquent une action de suppression ;
- ils ne sont pas des doublons binaires ;
- ils meritent une revue visuelle et semantique pour voir si un seul standard suffit.

Decision recommandee :

- verifier en UI si les deux sont vraiment necessaires

Priorite :

- moyenne

---

## Conventions de nommage

Constats :

- melange anglais / francais :
  - `movie.png`
  - `serie.png`
  - `supprimer.png`
  - `reculer.png`
- suffixes incoherents :
  - `back_icon.png`
  - `more_icon.png`
  - `play_arrow.png`
- une partie des noms exprime l'action, une autre l'objet, une autre le style

Decision recommandee :

- adopter une convention unique de nommage en anglais ;
- reserver les suffixes comme `_filled`, `_outlined`, `_disabled` a des variantes explicites ;
- eviter les suffixes inutiles comme `_icon` si tout le dossier contient deja des icones.

Priorite :

- moyenne

---

## Formats et dimensions

Constats :

- `svg` est bien utilise pour la navigation et le logo ;
- la plupart des PNG font `100x100` ;
- `resize.png` fait `96x96` ;
- `app_icon.png` fait `1024x1024`, ce qui est correct pour une source de launcher icon.

Lecture :

- il n'y a pas de signal de poids ou de dimensions alarmant ;
- le vrai sujet n'est pas la performance du dossier, mais son organisation.

---

## Probleme de gouvernance du code

Le projet dispose deja d'un registre central :

- [`app_assets.dart`](/mnt/c/Users/matte/Documents/DEV/Flutter/movi-app/lib/src/core/utils/app_assets.dart)

Mais certains ecrans utilisent encore des chemins litteraux :

- `assets/icons/search.png`
- `assets/icons/supprimer.png`

Decision recommandee :

- finir de centraliser tous les chemins dans `AppAssets`

Benefices :

- moins de fautes de frappe ;
- plus de facilite pour renommer/deplacer les fichiers ;
- meilleure lisibilite du code.

Priorite :

- forte

---

## Reorganisation cible recommandee

Structure cible suggeree :

```text
assets/
  branding/
    app_icon.png
    app_logo.svg
  icons/
    navigation/
    actions/
    media/
```

Lecture :

- `branding/` pour ce qui releve de l'identite de l'app
- `icons/navigation/` pour home/search/library/settings
- `icons/actions/` pour play/pause/back/trash/sort/plus
- `icons/media/` pour movie/serie/playlist/chromecast/subtitles/audio

---

## Resultat du lot

Ce lot est considere realise au niveau audit.

Conclusions principales :

- dossier `assets/` globalement sain et leger
- organisation encore trop plate
- un doublon exact confirme : `back.png`
- centralisation `AppAssets` incomplete
- separation branding / UI a mettre en place

---

## Prochaine action recommandee

Le prochain lot naturel est :

- `Lot 4.2. Reorganisation`

Ordre suggere :

1. supprimer `back.png`
2. centraliser les chemins hardcodes restants dans `AppAssets`
3. deplacer `app_icon.png` et `app_logo.svg` vers un dossier branding
4. reorganiser les sous-dossiers d'icones
5. ajuster `pubspec.yaml` et les references Dart

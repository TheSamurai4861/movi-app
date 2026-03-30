# Inventaire SVG des icones du 27 mars 2026

## But

Ce document realise l'etape 1 de la migration PNG -> SVG :

- etablir une source de verite pour les correspondances entre les anciens PNG et les nouveaux SVG ;
- normaliser les noms de fichiers SVG quand un equivalent 1:1 existe deja ;
- distinguer les vraies variantes geometriques des simples etats visuels geres par le code.

Ce lot ne modifie pas encore le rendu des widgets. Il prepare les etapes suivantes.

---

## Regles retenues

- Un SVG qui porte le meme stem que le PNG est considere comme son remplacement 1:1.
- Quand plusieurs PNG ne differencient qu'un etat visuel simple, ils peuvent partager un seul SVG de base.
- Les etats visuels simples seront geres plus tard dans le code par la teinte, l'opacite ou l'etat selectionne/desactive.
- Les noms physiques des fichiers SVG doivent rester semantiques et stables. On evite de dupliquer des fichiers uniquement pour encoder une couleur.
- Les chemins utilises en runtime continueront a passer par `AppAssets`.

---

## Normalisations appliquees

Renommages realises pour aligner les stems SVG sur les PNG existants :

- `assets/icons/media/serie.svg` -> `assets/icons/media/series.svg`
- `assets/icons/media/subtitle.svg` -> `assets/icons/media/subtitles.svg`

Raison :

- respecter la convention 1:1 "meme stem = meme icone" ;
- eviter de porter une ambiguite dans `AppAssets` et dans la migration des widgets ;
- reserver les suffixes a de vraies variantes de comportement ou de geometrie.

---

## Inventaire des correspondances

### Navigation

| PNG historique | SVG cible | Strategie |
| --- | --- | --- |
| `home` | `assets/icons/navigation/home.svg` | 1:1 |
| `search` | `assets/icons/navigation/search.svg` | 1:1 |
| `library` | `assets/icons/navigation/library.svg` | 1:1 |
| `settings` | `assets/icons/navigation/settings.svg` | 1:1 |

### Actions

| PNG historique | SVG cible | Strategie |
| --- | --- | --- |
| `back.png` | `assets/icons/actions/back.svg` | 1:1 |
| `delete.png` | `assets/icons/actions/delete.svg` | 1:1 |
| `forward.png` | `assets/icons/actions/forward.svg` | 1:1 |
| `more.png` | `assets/icons/actions/more.svg` | 1:1 |
| `pause.png` | `assets/icons/actions/pause.svg` | 1:1 |
| `play_arrow.png` | `assets/icons/actions/play_arrow.svg` | 1:1 |
| `plus.png` | `assets/icons/actions/plus.svg` | 1:1 |
| `resize.png` | `assets/icons/actions/resize.svg` | 1:1 |
| `rewind.png` | `assets/icons/actions/rewind.svg` | 1:1 |
| `search.png` | `assets/icons/actions/search.svg` | 1:1 |
| `sort.png` | `assets/icons/actions/sort.svg` | 1:1 |
| `trash.png` | `assets/icons/actions/trash.svg` | 1:1 |
| `star_filled.png` | `assets/icons/actions/star_filled.svg` | variante SVG dediee |
| `star_unfilled.png` | `assets/icons/actions/star_unfilled.svg` | variante SVG dediee |

### Media

| PNG historique | SVG cible | Strategie |
| --- | --- | --- |
| `audio.png` | `assets/icons/media/audio.svg` | 1:1 |
| `audio_disabled.png` | `assets/icons/media/audio.svg` | SVG partage, etat gere par le code |
| `chromecast.png` | `assets/icons/media/chromecast.svg` | 1:1 |
| `movie.png` | `assets/icons/media/movie.svg` | 1:1 |
| `playlist.png` | `assets/icons/media/playlist.svg` | 1:1 |
| `series.png` | `assets/icons/media/series.svg` | 1:1 apres normalisation du nom |
| `subtitles.png` | `assets/icons/media/subtitles.svg` | 1:1 apres normalisation du nom |
| `subtitles_disabled.png` | `assets/icons/media/subtitles.svg` | SVG partage, etat gere par le code |

---

## Convention a suivre pour la suite

- Un seul fichier SVG de base par pictogramme quand la geometrie reste identique.
- Un suffixe de type `_filled`, `_unfilled` ou `_disabled` uniquement si la geometrie ou le remplissage change reellement et ne peut pas etre derive proprement au rendu.
- Le code ne doit pas deduire les correspondances a partir des noms de fichiers. Les alias semantiques resteront centralises dans `AppAssets`.
- Avant suppression des PNG, chaque icone partagee entre plusieurs etats doit etre validee visuellement dans les ecrans qui l'utilisent.

---

## Portee du lot

Ce lot couvre uniquement l'inventaire et la normalisation des noms d'assets.

Les prochains travaux restent a faire :

- centraliser le rendu PNG/SVG dans un widget unique ;
- basculer `AppAssets` vers les SVG cibles ;
- migrer les ecrans et valider les etats visuels.

---

## Validation et nettoyage

Le 27 mars 2026, apres migration des widgets et des ecrans :

- les chemins runtime d'icones passent par `AppAssets` et pointent vers les SVG ;
- les etats `filled`, `unfilled` et `disabled` concernes sont geres par le code ;
- les anciens PNG sous `assets/icons/actions/` et `assets/icons/media/` ont ete supprimes.

Verification attendue pour ce lot :

- plus aucune reference runtime vers `assets/icons/*.png` dans `lib/` ;
- `flutter analyze` sans erreur sur le projet ;
- validation visuelle a poursuivre sur mobile, desktop et TV pour les teintes et tailles d'icones.

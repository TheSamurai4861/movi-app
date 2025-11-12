# Hero TMDB — Enrichissement des items

## Vue globale du flux
- Source des tendances: `HomeFeedRepositoryImpl.getHeroMovies()` agrège Trending TMDB et fallback VOD.
- Publication UI: `HomeController.load()` met à jour `state.hero` et `isHeroEmpty`.
- Rendu Hero:
  - Mono-item: `lib/src/features/home/presentation/widgets/home_hero_section.dart`.
  - Multi-items (diaporama): `lib/src/features/home/presentation/widgets/home_hero_carousel.dart`.
- Sélection d’images centralisée, hydratation du cache TMDB, et fallback contrôlés côté widgets.

## Fichiers clés et rôles
- `lib/src/features/home/data/repositories/home_feed_repository_impl.dart`: construit la liste Hero à partir de TMDB/playlist.
- `lib/src/features/home/presentation/providers/home_providers.dart`: charge et expose l’état (`hero`, `isHeroEmpty`).
- `lib/src/features/home/presentation/pages/home_page.dart`: choisit Section vs Carousel selon la longueur du Hero.
- `lib/src/features/home/presentation/widgets/home_hero_section.dart`: affiche un seul item, lit/hydrate cache TMDB.
- `lib/src/features/home/presentation/widgets/home_hero_carousel.dart`: affiche plusieurs items avec rotation, lit/hydrate cache TMDB et précache les fonds.

## HomeHeroSection (mono-item)
- Préparation meta: `lib/src/features/home/presentation/widgets/home_hero_section.dart:86–94`.
- Lecture cache (film puis fallback série) et sélection poster/logo:
  - `home_hero_section.dart:100–111` (récupération cache),
  - `home_hero_section.dart:113–124` (listes `images.posters/logos`, sélection `_ImageSelector`),
  - `home_hero_section.dart:125–134` (construction URLs: poster `w500`, backdrop `w780`, logo).
- Hydratation si cache manquant ou incomplet:
  - Pas de cache → fetch FULL → `put*Detail` → relance lecture: `home_hero_section.dart:171–207`.
  - Cache présent mais incomplet (posters/logos vides, overview vide, vote nul, runtime manquant): `home_hero_section.dart:210–254`.
- Choix du fond (ordre de préférence): poster TMDB → poster playlist → backdrop TMDB → backdrop playlist:
  - `home_hero_section.dart:300–313`.
- Notification première frame fond (`onBackgroundReady`): `home_hero_section.dart:344–354`.
- Sélecteur d’images (algorithme):
  - Poster no-lang → en → meilleur score: `home_hero_section.dart:512–540`.
  - Logo en → no-lang → meilleur score: `home_hero_section.dart:542–570`.

## HomeHeroCarousel (multi-items, rotation)
- Lecture cache et sélection poster/logo pour la slide courante:
  - `home_hero_carousel.dart:200–218` (cache + sélection `_ImageSelector`),
  - `home_hero_carousel.dart:220–227` (URLs poster/backdrop/logo).
- Hydratation si nécessaire:
  - Pas de cache → fetch FULL → `put*Detail` → `setState` pour relire meta: `home_hero_carousel.dart:264–299`.
  - Cache présent mais incomplet: `home_hero_carousel.dart:301–344`.
- Choix du fond (même ordre que Section): `home_hero_carousel.dart:392–401`.
- Rotation automatique et précache du fond de la prochaine slide:
  - Timer/redémarrage: `home_hero_carousel.dart:46–52, 63, 82, 112, 129, 141–152`.
  - Précache fond courant/suivant: `home_hero_carousel.dart:601–632`.
- Sélecteur d’images (algorithme):
  - Poster no-lang → en → meilleur score: `home_hero_carousel.dart:656–684`.
  - Logo en → no-lang → meilleur score: `home_hero_carousel.dart:686–711`.

## Hydratation
- Lit d’abord le cache TMDB pour chaque slide, puis complète via remotes si des champs clés manquent (même logique que la section).
- Sélection d’images centralisée: poster prioritaire, logo sélectionné, fallback sur backdrop/poster de playlist.
- Sélecteur d’images: `_ImageSelector` en `home_hero_carousel.dart:656–711` et choix poster/logo en `home_hero_carousel.dart:217–218`.

## Références rapides
- Choix fond (Section): `home_hero_section.dart:300–313`.
- Choix fond (Carousel): `home_hero_carousel.dart:392–401`.
- `onBackgroundReady` Section: `home_hero_section.dart:344–354`.
- Précache next (Carousel): `home_hero_carousel.dart:601–632`.
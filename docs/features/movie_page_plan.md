# Page Détails Film — Plan d’implémentation

## 1) Structure générale (hiérarchie et conteneurs)
- `top_actions` (h35, w393)
  - `back_btn` (h35, w92) : icône 35×35 + texte « Retour »
  - `back` (h35, w25) : icône « more » 25×25
- `hero` (h688, w393)
  - `hero-image` (h590, w393)
  - `overlays` (h283, w393) : `overlay2` + `overlay1` (283×393 chacun)
  - `hero-content` (h189, w393)
    - `media-title` (309×29)
    - `pills` (209×28) : 3 pills (année, durée, rating+icône)
    - `overview` (353×100)
      - `container-cliper` (353×90) : `synopsis` + `bottom-overlay-over-text`
      - `extend-btn` (102×25) : texte « Agrandir » + icône 25×25
  - `hero-actions` (h55, w393)
    - `watch-btn-to-player` (302×55)
    - `favorite-btn` (instance bouton favori)
- `group-18`
  - `movi-items-list` : liste horizontale de recommandations (cards 150×257)
  - `movi--persons-list` : distribution (liste horizontale personnes, image 150×225)

## 2) Layout & spacing (respect strict)
- Couleur de fond page: `rgb(20,20,20)`
- `top_actions` layout: row, gap `236`, padding `[0,20,0,20]`
- `back_btn` layout: row, align cross center, gap `0`
- `hero-content` layout: column, gap `16`, padding `[0,20,0,20]`, align cross center
- `pills` layout: row, gap `8`
- `pill` paddings: `[4,8,4,8]`, gap `10` (rating: gap `4`), radius `14`, bg `rgb(41,41,41)`
- `overview/container-cliper` layout: row (pour le texte et l’overlay bas)
- `extend-btn` layout: row, gap `4`, align cross center
- `hero-actions` layout: row, gap `16`, padding `[0,20,0,20]`
- `watch-btn-to-player` paddings: `[15,318,15,318]`, radius `32`, bg `rgb(33,96,171)`
- `movi-items-list/list` layout: row, gap `16`, padding `[0,20,0,0]`
- `list-element` (reco): layout column, gap `12`
- `movi--persons-list`
  - header padding `[0,20,0,20]`
  - `list` layout: row, gap `16`, padding `[0,20,0,20]`
  - card layout: column, gap `6`

## 3) Typographie
- Police: `Montserrat`
- Titres (page/sections): `size 20/24`, `weight 600`
- Texte courant (synopsis, pill content): `size 16`, `weight 500`
- Nom dans media secondaire (gris): `size 16`, `weight 400`, color `rgb(166,166,166)`

## 4) Couleurs
- Fond global: `rgb(20,20,20)`
- Textes: `rgb(255,255,255)`
- Pills: fond `rgb(41,41,41)`
- CTA « Regarder maintenant »: fond `rgb(33,96,171)`
- Texte secondaire: `rgb(166,166,166)`

## 5) Composants (Flutter)
- `TopActionsBar`
  - Bouton retour: icône 35×35 + label « Retour »
  - Bouton more (optionnel)
- `MovieHero`
  - Image principale (backdrop)
  - Overlays: 2 rectangles superposés (utiliser `ShaderMask`/`Container` avec `gradient`)
  - Contenu: titre, pills, synopsis tronqué + overlay bas + bouton « Agrandir »
- `HeroActions`
  - Bouton « Regarder maintenant » (CTA large) + `MoviFavoriteButton`
- `RecommendationsList` (horizontal)
  - Card: image 150×225, radius `16` + titre 150×20
- `CastList` (horizontal)
  - Card: image 150×225, radius `16` + nom réel + nom dans media (gris)

## 6) Interactions & états
- Retour: `router.pop()`
- CTA player: navigation vers lecteur (`AppRouteNames.player`) avec `movieId`
- Favori: toggle état local puis persistance (use case favori)
- Synopsis:
  - Clamping visuel à ~90px (selon `container-cliper` h90) avec overlay bas (41px)
  - Bouton « Agrandir » bascule l’état: plein texte vs tronqué
- Lists horizontales: scrollables, item tap -> navigation vers film/personne

## 7) Données & binding
- Titre: `media-title`
- Pills:
  - Année: `year` (from TMDB detail `release_date`)
  - Durée: `runtime` format « Xh Ym »
  - Note: `rating` + icône (source assets); arrondi 1 décimale
- Synopsis: `overview` (localisé)
- Recommandations: TMDB `recommendations` pour le film courant
- Distribution: TMDB `credits.cast` avec `profile_path`, `name`, `character`

## 8) I18n & langue
- Textes statiques: `AppLocalizations` (« Retour », « Regarder maintenant », « Agrandir », « Recommandations », « Distribution »)
- Données TMDB localisées: passer `language` et `Accept-Language`
- Comportement langue: conserver l’ancien contenu pendant chargement, remplacement une fois reçu

## 9) Accessibilité & DX
- Taille tap minimal: 44dp; padding adéquat
- Contraste: respecter couleurs prévues (texte blanc sur fonds foncés)
- Semantics: labels sur boutons et images

## 10) Performances
- Mise en cache TMDB (clé par `id|lang`)
- Images: utiliser `CachedNetworkImage` avec radius `16`
- Pas de préchargement massif; virtualisation liste si nécessaire

## 11) Détails de tailles (extraits clés)
- `top_actions`: padding `[0,20,0,20]`, gap `236`
- Pills: radius `14`, padding `[4,8,4,8]`, gaps `10`/`4`
- `watch-btn-to-player`: radius `32`, padding `[15,318,15,318]`
- Cards image: `150×225` avec radius `16`
- `hero-image`: `393×590`; `overlays`: `393×283`

## 12) Découpage en widgets
- `MovieDetailPage` (scaffold)
- `TopActionsBar`
- `MovieHero` (image + overlays + content + actions)
- `SynopsisClamp`
- `RecommendationsList`
- `CastList`

## 13) État & architecture
- CLEAN Architecture
  - `domain`: modèles `MovieDetail`, `Person`, use cases (fetch movie detail, recommendations, credits)
  - `data`: `TmdbMovieRemoteDataSource`, `TmdbPersonRemoteDataSource`, mappers/DTO
  - `presentation`: widgets + providers (Riverpod), état local (favori, synopsis étendu)
- DI pour clients réseau et repos

## 14) Checklist de conformité
- Espacements, tailles, radius strictement respectés
- Typo Montserrat (poids/sizes conformes)
- Couleurs exactes
- i18n et langue propagée
- Composants interactifs fonctionnels
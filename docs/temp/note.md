UI Accueil — Plan par étapes (basé sur docs/temp/reponse.txt)

Objectif (sections)
- Hero: films tendances TMDB disponibles IPTV (intersection) — poster requis.
- Continue Watching: 2 carrousels (films, séries) — local-only.
- Catégories IPTV: listes horizontales par `<alias>/<categoryName>` (top 20/section).

Étape 1 — Structure & navigation
- Créer `HomePage` (features/home/presentation/pages/home_page.dart).
- Ajouter la route si besoin dans `core/router`.
- Utiliser `CustomScrollView` (ou `NestedScrollView`) pour composer hero + sections. OK

Étape 2 — State/Providers (Riverpod)
- `home_providers.dart`:
  - `homeFeedRepositoryProvider` (GetIt → repo)
  - `homeControllerProvider` (StateNotifier/AsyncValue) avec `HomeState`:
    - `hero`, `cwMovies`, `cwShows`, `iptvLists` (AsyncValue chacun)
- Méthodes: `load()`, `refresh()` (Future.wait sur repo).

Étape 3 — Hero (UI)
- Widget `HomeHero` (features/home/presentation/widgets/home_hero.dart):
  - Entrée: `List<MovieSummary>`.
  - Mise en page: carrousel/grille avec poster + overlay; tap → détail.
  - États: skeleton/shimmer, empty state.

Étape 4 — Continue Watching (UI)
- Réutiliser `MoviItemsList` pour 2 sections: "Reprendre Films" / "Reprendre Séries".
- Cartes `MovieCard`/`ShowCard` minimalistes; tap → détail.
- États: skeletons (3–5 placeholders), empty state.

Étape 5 — Catégories IPTV (UI)
- Boucler sur `iptvLists`: clé `<alias>/<categoryName>` → `MoviItemsList`.
- Map `ContentReference` → carte (movie vs series) selon `type`.
- États: skeletons par section; empty si aucune source active.

Étape 6 — Erreurs, offline & UX
- Gérer AsyncValue.error par section (banner + retry).
- Pull-to-refresh: relance `load()`.
- Si aucune source IPTV active: message + CTA vers paramètres/IPTV.

Étape 7 — Composants & accessibilité
- Cartes réutilisables (poster ratio, coins arrondis, semanticsLabel=title).
- Paddings 20px, espacement 16px; support thèmes clair/sombre.

Étape 8 — Routage & deep links (optionnel)
- Tap carte → `movie_detail` / `tv_detail` avec ID; skeleton court côté détail.

Étape 9 — Tests UI minimes
- Golden pour `HomeHero` et une `MoviItemsList`.
- Test d’intégration léger: providers chargent et sections s’affichent (fakes repos).

Étape 10 — Perf & polish
- Listes builder/SliverList, keys stables, cache images, fade-in.
- KeepAlive si onglets.

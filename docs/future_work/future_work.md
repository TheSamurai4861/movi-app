# Future Work — Null‑safety des timers et guards

Objectif: étendre le durcissement null‑safety appliqué à `movie_detail_page.dart` aux autres écrans ayant des timers et des accès conditionnels aux données.

## Pattern recommandé
- `initState`: ne démarrer un timer que si les données nécessaires existent (ex. `media != null`).
- Méthodes de timer: récupérer un identifiant local (`final id = widget.media?.id; if (id == null) return;`) et l’utiliser partout.
- Providers: lire/invalider via l’ID local, sans utiliser `!`.
- `mounted`/`context.mounted`: vérifier avant d’appeler `setState`, `ScaffoldMessenger`, navigation.
- `dispose`: annuler systématiquement les timers (`_timer?.cancel()`).

## Fichiers cibles à aligner
- `lib/src/features/tv/presentation/pages/tv_detail_page.dart`
  - Sécuriser `_startAutoRefreshTimer` et `_startSeasonsCheckTimer` avec un ID local et guards.
  - Éviter les `!` sur toute donnée optionnelle (ex. `widget.media`/`tvShow`).

- `lib/src/features/person/presentation/pages/person_detail_page.dart`
  - Ajouter guards dans `_startAutoRefreshTimer` et dans les invalidations de providers.

- `lib/src/features/home/presentation/widgets/home_hero_carousel.dart`
  - Timers de rotation: s’assurer des guards `mounted`, annulation en `dispose`, vérifs d’index.

- `lib/src/features/player/presentation/pages/video_player_page.dart`
  - `_startHideControlsTimer`: assurer annulation, `mounted` guards, pas d’accès à état après dispose.

- `lib/src/core/widgets/movi_items_list.dart`
  - Debounce timer: annuler en `dispose`, éviter les effets quand le widget est démonté.

## Checklist d’implémentation
- Remplacer les usages `widget.media!.id` par un ID local validé.
- Encadrer chaque `Timer(...)` par une annulation préalable et un guard `mounted` dans le callback.
- Vérifier l’existence des données avant `ref.watch`, `ref.read`, `ref.invalidate`.
- Supprimer les bangs `!` non nécessaires, préférer des checks explicites.

## Référence
- Modifs réalisées: `lib/src/features/movie/presentation/pages/movie_detail_page.dart` (Étape 7 — Null‑safety des timers et guards).
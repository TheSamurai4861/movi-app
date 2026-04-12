# Architecture violations report

- Scope: `lib/`
- Generated (UTC): `2026-04-12T02:36:14.112770Z`
- Mode: `enforce`
- Violations: **475**

## Summary by rule

- **ARCH-R1**: 68
- **ARCH-R2**: 21
- **ARCH-R3**: 10
- **ARCH-R4**: 323
- **ARCH-R5**: 53

## Details

### ARCH-R5 — lib/src/core/auth/presentation/providers/auth_providers.dart:10

- **Message**: Interdit: accès direct au locator en UI
- **Suggestion**: Passer par providers Riverpod / injection testable.
- **Import**:

```
import 'package:movi/src/core/di/di.dart';
```

### ARCH-R5 — lib/src/core/parental/presentation/providers/parental_access_providers.dart:3

- **Message**: Interdit: accès direct au locator en UI
- **Suggestion**: Passer par providers Riverpod / injection testable.
- **Import**:

```
import 'package:movi/src/core/di/di.dart';
```

### ARCH-R1 — lib/src/core/parental/presentation/providers/parental_access_providers.dart:5

- **Message**: Interdit: presentation -> data
- **Suggestion**: Dépendre de domain/application et exposer une abstraction.
- **Import**:

```
import 'package:movi/src/core/parental/data/services/profile_pin_edge_service.dart';
```

### ARCH-R5 — lib/src/core/parental/presentation/providers/parental_providers.dart:3

- **Message**: Interdit: accès direct au locator en UI
- **Suggestion**: Passer par providers Riverpod / injection testable.
- **Import**:

```
import 'package:movi/src/core/di/di.dart';
```

### ARCH-R1 — lib/src/core/parental/presentation/providers/parental_providers.dart:5

- **Message**: Interdit: presentation -> data
- **Suggestion**: Dépendre de domain/application et exposer une abstraction.
- **Import**:

```
import 'package:movi/src/core/parental/data/repositories/iptv_parental_content_candidate_repository.dart';
```

### ARCH-R1 — lib/src/core/parental/presentation/providers/parental_providers.dart:6

- **Message**: Interdit: presentation -> data
- **Suggestion**: Dépendre de domain/application et exposer une abstraction.
- **Import**:

```
import 'package:movi/src/core/parental/data/services/content_rating_repository_warmup_gateway.dart';
```

### ARCH-R1 — lib/src/core/parental/presentation/providers/parental_providers.dart:7

- **Message**: Interdit: presentation -> data
- **Suggestion**: Dépendre de domain/application et exposer une abstraction.
- **Import**:

```
import 'package:movi/src/core/parental/data/services/noop_content_metadata_resolvers.dart';
```

### ARCH-R5 — lib/src/core/parental/presentation/providers/pin_recovery_providers.dart:3

- **Message**: Interdit: accès direct au locator en UI
- **Suggestion**: Passer par providers Riverpod / injection testable.
- **Import**:

```
import 'package:movi/src/core/di/di.dart';
```

### ARCH-R5 — lib/src/core/profile/presentation/controllers/profiles_controller.dart:6

- **Message**: Interdit: accès direct au locator en UI
- **Suggestion**: Passer par providers Riverpod / injection testable.
- **Import**:

```
import 'package:movi/src/core/di/di.dart';
```

### ARCH-R5 — lib/src/core/profile/presentation/controllers/selected_profile_controller.dart:4

- **Message**: Interdit: accès direct au locator en UI
- **Suggestion**: Passer par providers Riverpod / injection testable.
- **Import**:

```
import 'package:movi/src/core/di/di.dart';
```

### ARCH-R5 — lib/src/core/profile/presentation/providers/iptv_cipher_provider.dart:4

- **Message**: Interdit: accès direct au locator en UI
- **Suggestion**: Passer par providers Riverpod / injection testable.
- **Import**:

```
import 'package:movi/src/core/di/di.dart';
```

### ARCH-R5 — lib/src/core/profile/presentation/providers/profile_di_providers.dart:3

- **Message**: Interdit: accès direct au locator en UI
- **Suggestion**: Passer par providers Riverpod / injection testable.
- **Import**:

```
import 'package:movi/src/core/di/di.dart';
```

### ARCH-R3 — lib/src/core/reporting/presentation/widgets/report_problem_sheet.dart:4

- **Message**: Interdit: presentation -> SDK externe (supabase_flutter)
- **Suggestion**: Isoler le SDK dans core/data (adapter) et exposer une abstraction.
- **Import**:

```
import 'package:supabase_flutter/supabase_flutter.dart';
```

### ARCH-R5 — lib/src/core/reporting/presentation/widgets/report_problem_sheet.dart:7

- **Message**: Interdit: accès direct au locator en UI
- **Suggestion**: Passer par providers Riverpod / injection testable.
- **Import**:

```
import 'package:movi/src/core/di/di.dart';
```

### ARCH-R3 — lib/src/core/subscription/presentation/providers/subscription_providers.dart:3

- **Message**: Interdit: presentation -> SDK externe (get_it)
- **Suggestion**: Isoler le SDK dans core/data (adapter) et exposer une abstraction.
- **Import**:

```
import 'package:get_it/get_it.dart';
```

### ARCH-R5 — lib/src/core/subscription/presentation/providers/subscription_providers.dart:5

- **Message**: Interdit: accès direct au locator en UI
- **Suggestion**: Passer par providers Riverpod / injection testable.
- **Import**:

```
import 'package:movi/src/core/di/di.dart';
```

### ARCH-R3 — lib/src/features/auth/presentation/auth_otp_controller.dart:5

- **Message**: Interdit: presentation -> SDK externe (supabase_flutter)
- **Suggestion**: Isoler le SDK dans core/data (adapter) et exposer une abstraction.
- **Import**:

```
import 'package:supabase_flutter/supabase_flutter.dart';
```

### ARCH-R4 — lib/src/features/auth/presentation/auth_otp_page.dart:16

- **Message**: Interdit: feature "auth" -> feature "welcome"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/welcome/presentation/widgets/labeled_field.dart';
```

### ARCH-R4 — lib/src/features/auth/presentation/auth_otp_page.dart:17

- **Message**: Interdit: feature "auth" -> feature "welcome"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/welcome/presentation/widgets/welcome_header.dart';
```

### ARCH-R4 — lib/src/features/category_browser/data/category_browser_data_module.dart:3

- **Message**: Interdit: feature "category_browser" -> feature "iptv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/iptv/application/iptv_catalog_reader.dart';
```

### ARCH-R4 — lib/src/features/category_browser/data/datasources/category_local_data_source.dart:3

- **Message**: Interdit: feature "category_browser" -> feature "iptv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/iptv/application/iptv_catalog_reader.dart';
```

### ARCH-R5 — lib/src/features/category_browser/presentation/providers/category_providers.dart:7

- **Message**: Interdit: accès direct au locator en UI
- **Suggestion**: Passer par providers Riverpod / injection testable.
- **Import**:

```
import 'package:movi/src/core/di/di.dart';
```

### ARCH-R4 — lib/src/features/home/data/home_feed_data_module.dart:3

- **Message**: Interdit: feature "home" -> feature "iptv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/iptv/application/iptv_catalog_reader.dart';
```

### ARCH-R4 — lib/src/features/home/data/home_feed_data_module.dart:8

- **Message**: Interdit: feature "home" -> feature "movie"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/movie/data/datasources/tmdb_movie_remote_data_source.dart';
```

### ARCH-R4 — lib/src/features/home/data/home_feed_data_module.dart:9

- **Message**: Interdit: feature "home" -> feature "movie"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/movie/domain/repositories/movie_repository.dart';
```

### ARCH-R4 — lib/src/features/home/data/home_feed_data_module.dart:10

- **Message**: Interdit: feature "home" -> feature "tv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/tv/data/datasources/tmdb_tv_remote_data_source.dart';
```

### ARCH-R4 — lib/src/features/home/data/home_feed_data_module.dart:11

- **Message**: Interdit: feature "home" -> feature "tv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/tv/domain/repositories/tv_repository.dart';
```

### ARCH-R4 — lib/src/features/home/data/repositories/home_feed_repository_impl.dart:5

- **Message**: Interdit: feature "home" -> feature "iptv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/iptv/application/iptv_catalog_reader.dart';
```

### ARCH-R4 — lib/src/features/home/data/repositories/home_feed_repository_impl.dart:7

- **Message**: Interdit: feature "home" -> feature "iptv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/iptv/iptv.dart';
```

### ARCH-R4 — lib/src/features/home/data/repositories/home_feed_repository_impl.dart:22

- **Message**: Interdit: feature "home" -> feature "movie"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/movie/data/datasources/tmdb_movie_remote_data_source.dart';
```

### ARCH-R4 — lib/src/features/home/data/repositories/home_feed_repository_impl.dart:23

- **Message**: Interdit: feature "home" -> feature "movie"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/movie/movie.dart';
```

### ARCH-R4 — lib/src/features/home/data/repositories/home_feed_repository_impl.dart:25

- **Message**: Interdit: feature "home" -> feature "tv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/tv/data/datasources/tmdb_tv_remote_data_source.dart';
```

### ARCH-R4 — lib/src/features/home/data/repositories/home_feed_repository_impl.dart:26

- **Message**: Interdit: feature "home" -> feature "tv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/tv/tv.dart';
```

### ARCH-R4 — lib/src/features/home/domain/repositories/home_feed_repository.dart:5

- **Message**: Interdit: feature "home" -> feature "movie"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/movie/domain/entities/movie_summary.dart';
```

### ARCH-R4 — lib/src/features/home/domain/repositories/home_feed_repository.dart:6

- **Message**: Interdit: feature "home" -> feature "tv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/tv/domain/entities/tv_show.dart';
```

### ARCH-R2 — lib/src/features/home/domain/services/continue_watching_enrichment_service.dart:5

- **Message**: Interdit: domain -> data
- **Suggestion**: Extraire une interface (repository) côté domain, impl côté data.
- **Import**:

```
import 'package:movi/src/shared/data/services/tmdb_cache_data_source.dart';
```

### ARCH-R2 — lib/src/features/home/domain/services/continue_watching_enrichment_service.dart:6

- **Message**: Interdit: domain -> data
- **Suggestion**: Extraire une interface (repository) côté domain, impl côté data.
- **Import**:

```
import 'package:movi/src/shared/data/services/tmdb_image_resolver.dart';
```

### ARCH-R2 — lib/src/features/home/domain/services/continue_watching_enrichment_service.dart:7

- **Message**: Interdit: domain -> data
- **Suggestion**: Extraire une interface (repository) côté domain, impl côté data.
- **Import**:

```
import 'package:movi/src/shared/data/services/tmdb_client.dart';
```

### ARCH-R2 — lib/src/features/home/domain/services/continue_watching_enrichment_service.dart:8

- **Message**: Interdit: domain -> data
- **Suggestion**: Extraire une interface (repository) côté domain, impl côté data.
- **Import**:

```
import 'package:movi/src/shared/data/services/xtream_lookup_service.dart';
```

### ARCH-R4 — lib/src/features/home/domain/services/continue_watching_enrichment_service.dart:12

- **Message**: Interdit: feature "home" -> feature "iptv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist_item.dart';
```

### ARCH-R4 — lib/src/features/home/domain/services/continue_watching_enrichment_service.dart:13

- **Message**: Interdit: feature "home" -> feature "movie"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/movie/domain/repositories/movie_repository.dart';
```

### ARCH-R4 — lib/src/features/home/domain/services/continue_watching_enrichment_service.dart:14

- **Message**: Interdit: feature "home" -> feature "tv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/tv/domain/repositories/tv_repository.dart';
```

### ARCH-R2 — lib/src/features/home/domain/services/home_hero_metadata_service.dart:2

- **Message**: Interdit: domain -> data
- **Suggestion**: Extraire une interface (repository) côté domain, impl côté data.
- **Import**:

```
import 'package:movi/src/shared/data/services/tmdb_cache_data_source.dart';
```

### ARCH-R2 — lib/src/features/home/domain/services/home_hero_metadata_service.dart:3

- **Message**: Interdit: domain -> data
- **Suggestion**: Extraire une interface (repository) côté domain, impl côté data.
- **Import**:

```
import 'package:movi/src/shared/data/services/tmdb_image_resolver.dart';
```

### ARCH-R2 — lib/src/features/home/domain/services/home_hero_metadata_service.dart:5

- **Message**: Interdit: domain -> data
- **Suggestion**: Extraire une interface (repository) côté domain, impl côté data.
- **Import**:

```
import 'package:movi/src/features/movie/data/datasources/tmdb_movie_remote_data_source.dart';
```

### ARCH-R2 — lib/src/features/home/domain/services/home_hero_metadata_service.dart:6

- **Message**: Interdit: domain -> data
- **Suggestion**: Extraire une interface (repository) côté domain, impl côté data.
- **Import**:

```
import 'package:movi/src/features/tv/data/datasources/tmdb_tv_remote_data_source.dart';
```

### ARCH-R4 — lib/src/features/home/domain/services/home_hero_metadata_service.dart:7

- **Message**: Interdit: feature "home" -> feature "movie"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/movie/domain/entities/movie_summary.dart';
```

### ARCH-R4 — lib/src/features/home/domain/services/movie_playback_service.dart:5

- **Message**: Interdit: feature "home" -> feature "iptv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist_item.dart';
```

### ARCH-R4 — lib/src/features/home/domain/services/movie_playback_service.dart:6

- **Message**: Interdit: feature "home" -> feature "movie"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/movie/domain/entities/movie_summary.dart';
```

### ARCH-R4 — lib/src/features/home/domain/services/movie_playback_service.dart:7

- **Message**: Interdit: feature "home" -> feature "player"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/player/domain/entities/video_source.dart';
```

### ARCH-R2 — lib/src/features/home/domain/services/movie_playback_service.dart:8

- **Message**: Interdit: domain -> data
- **Suggestion**: Extraire une interface (repository) côté domain, impl côté data.
- **Import**:

```
import 'package:movi/src/features/iptv/data/services/xtream_stream_url_builder_impl.dart';
```

### ARCH-R2 — lib/src/features/home/domain/services/movie_playback_service.dart:9

- **Message**: Interdit: domain -> data
- **Suggestion**: Extraire une interface (repository) côté domain, impl côté data.
- **Import**:

```
import 'package:movi/src/shared/data/services/xtream_lookup_service.dart';
```

### ARCH-R4 — lib/src/features/home/domain/usecases/load_home_continue_watching.dart:2

- **Message**: Interdit: feature "home" -> feature "movie"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/movie/domain/entities/movie_summary.dart';
```

### ARCH-R4 — lib/src/features/home/domain/usecases/load_home_continue_watching.dart:3

- **Message**: Interdit: feature "home" -> feature "tv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/tv/domain/entities/tv_show.dart';
```

### ARCH-R4 — lib/src/features/home/domain/usecases/refresh_home_feed.dart:2

- **Message**: Interdit: feature "home" -> feature "movie"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/movie/domain/entities/movie_summary.dart';
```

### ARCH-R4 — lib/src/features/home/domain/usecases/refresh_home_feed.dart:3

- **Message**: Interdit: feature "home" -> feature "tv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/tv/domain/entities/tv_show.dart';
```

### ARCH-R5 — lib/src/features/home/presentation/providers/home_providers.dart:7

- **Message**: Interdit: accès direct au locator en UI
- **Suggestion**: Passer par providers Riverpod / injection testable.
- **Import**:

```
import 'package:movi/src/core/di/di.dart';
```

### ARCH-R4 — lib/src/features/home/presentation/providers/home_providers.dart:17

- **Message**: Interdit: feature "home" -> feature "movie"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/movie/domain/entities/movie_summary.dart';
```

### ARCH-R4 — lib/src/features/home/presentation/providers/home_providers.dart:18

- **Message**: Interdit: feature "home" -> feature "settings"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/settings/presentation/providers/user_settings_providers.dart';
```

### ARCH-R4 — lib/src/features/home/presentation/providers/home_providers.dart:19

- **Message**: Interdit: feature "home" -> feature "tv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/tv/domain/entities/tv_show.dart';
```

### ARCH-R4 — lib/src/features/home/presentation/widgets/home_content.dart:12

- **Message**: Interdit: feature "home" -> feature "library"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/library/presentation/providers/library_cloud_sync_providers.dart';
```

### ARCH-R5 — lib/src/features/home/presentation/widgets/home_continue_watching_section.dart:6

- **Message**: Interdit: accès direct au locator en UI
- **Suggestion**: Passer par providers Riverpod / injection testable.
- **Import**:

```
import 'package:movi/src/core/di/di.dart';
```

### ARCH-R4 — lib/src/features/home/presentation/widgets/home_continue_watching_section.dart:24

- **Message**: Interdit: feature "home" -> feature "settings"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/settings/presentation/localization/movi_premium_localizer.dart';
```

### ARCH-R4 — lib/src/features/home/presentation/widgets/home_continue_watching_section.dart:25

- **Message**: Interdit: feature "home" -> feature "settings"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/settings/presentation/pages/movi_premium_page.dart';
```

### ARCH-R4 — lib/src/features/home/presentation/widgets/home_desktop_layout.dart:20

- **Message**: Interdit: feature "home" -> feature "library"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/library/presentation/providers/library_cloud_sync_providers.dart';
```

### ARCH-R5 — lib/src/features/home/presentation/widgets/home_hero_carousel.dart:9

- **Message**: Interdit: accès direct au locator en UI
- **Suggestion**: Passer par providers Riverpod / injection testable.
- **Import**:

```
import 'package:movi/src/core/di/di.dart';
```

### ARCH-R1 — lib/src/features/home/presentation/widgets/home_hero_carousel.dart:23

- **Message**: Interdit: presentation -> data
- **Suggestion**: Dépendre de domain/application et exposer une abstraction.
- **Import**:

```
import 'package:movi/src/shared/data/services/tmdb_cache_data_source.dart';
```

### ARCH-R1 — lib/src/features/home/presentation/widgets/home_hero_carousel.dart:24

- **Message**: Interdit: presentation -> data
- **Suggestion**: Dépendre de domain/application et exposer une abstraction.
- **Import**:

```
import 'package:movi/src/shared/data/services/tmdb_image_resolver.dart';
```

### ARCH-R1 — lib/src/features/home/presentation/widgets/home_hero_carousel.dart:29

- **Message**: Interdit: presentation -> data
- **Suggestion**: Dépendre de domain/application et exposer une abstraction.
- **Import**:

```
import 'package:movi/src/features/movie/data/datasources/tmdb_movie_remote_data_source.dart';
```

### ARCH-R1 — lib/src/features/home/presentation/widgets/home_hero_carousel.dart:30

- **Message**: Interdit: presentation -> data
- **Suggestion**: Dépendre de domain/application et exposer une abstraction.
- **Import**:

```
import 'package:movi/src/features/tv/data/datasources/tmdb_tv_remote_data_source.dart';
```

### ARCH-R4 — lib/src/features/home/presentation/widgets/home_hero_carousel.dart:31

- **Message**: Interdit: feature "home" -> feature "movie"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/movie/presentation/providers/movie_detail_providers.dart';
```

### ARCH-R4 — lib/src/features/home/presentation/widgets/home_hero_carousel.dart:38

- **Message**: Interdit: feature "home" -> feature "tv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/tv/presentation/providers/tv_detail_providers.dart';
```

### ARCH-R4 — lib/src/features/home/presentation/widgets/home_iptv_section.dart:13

- **Message**: Interdit: feature "home" -> feature "category_browser"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/category_browser/presentation/models/category_args.dart';
```

### ARCH-R4 — lib/src/features/home/presentation/widgets/home_mobile_layout.dart:15

- **Message**: Interdit: feature "home" -> feature "library"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/library/presentation/providers/library_cloud_sync_providers.dart';
```

### ARCH-R4 — lib/src/features/home/presentation/widgets/mark_as_unwatched_dialog.dart:8

- **Message**: Interdit: feature "home" -> feature "library"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/library/presentation/providers/library_cloud_sync_providers.dart';
```

### ARCH-R4 — lib/src/features/home/presentation/widgets/mark_as_unwatched_dialog.dart:9

- **Message**: Interdit: feature "home" -> feature "library"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/library/presentation/providers/library_providers.dart';
```

### ARCH-R4 — lib/src/features/home/presentation/widgets/mark_as_unwatched_dialog.dart:10

- **Message**: Interdit: feature "home" -> feature "library"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/library/presentation/providers/library_remote_providers.dart';
```

### ARCH-R4 — lib/src/features/home/presentation/widgets/mark_as_unwatched_dialog.dart:11

- **Message**: Interdit: feature "home" -> feature "settings"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/settings/presentation/providers/user_settings_providers.dart';
```

### ARCH-R4 — lib/src/features/iptv/application/iptv_catalog_reader.dart:5

- **Message**: Interdit: feature "iptv" -> feature "category_browser"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/category_browser/domain/value_objects/category_key.dart';
```

### ARCH-R4 — lib/src/features/iptv/data/services/xtream_stream_url_builder_impl.dart:10

- **Message**: Interdit: feature "iptv" -> feature "player"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/player/domain/services/xtream_stream_url_builder.dart';
```

### ARCH-R5 — lib/src/features/iptv/presentation/providers/iptv_accounts_providers.dart:3

- **Message**: Interdit: accès direct au locator en UI
- **Suggestion**: Passer par providers Riverpod / injection testable.
- **Import**:

```
import 'package:movi/src/core/di/di.dart';
```

### ARCH-R4 — lib/src/features/library/application/services/comprehensive_cloud_sync_service.dart:15

- **Message**: Interdit: feature "library" -> feature "iptv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/iptv/data/datasources/supabase_iptv_sources_repository.dart';
```

### ARCH-R4 — lib/src/features/library/application/services/comprehensive_cloud_sync_service.dart:16

- **Message**: Interdit: feature "library" -> feature "iptv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/iptv/data/services/iptv_credentials_edge_service.dart';
```

### ARCH-R4 — lib/src/features/library/data/library_data_module.dart:5

- **Message**: Interdit: feature "library" -> feature "playlist"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/playlist/domain/repositories/playlist_repository.dart';
```

### ARCH-R4 — lib/src/features/library/data/library_data_module.dart:6

- **Message**: Interdit: feature "library" -> feature "person"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/person/person.dart';
```

### ARCH-R4 — lib/src/features/library/data/repositories/library_repository_impl.dart:2

- **Message**: Interdit: feature "library" -> feature "playlist"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/playlist/playlist.dart';
```

### ARCH-R4 — lib/src/features/library/data/repositories/library_repository_impl.dart:3

- **Message**: Interdit: feature "library" -> feature "movie"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/movie/movie.dart';
```

### ARCH-R4 — lib/src/features/library/data/repositories/library_repository_impl.dart:4

- **Message**: Interdit: feature "library" -> feature "tv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/tv/tv.dart';
```

### ARCH-R4 — lib/src/features/library/data/repositories/library_repository_impl.dart:5

- **Message**: Interdit: feature "library" -> feature "saga"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/saga/saga.dart';
```

### ARCH-R4 — lib/src/features/library/data/repositories/library_repository_impl.dart:6

- **Message**: Interdit: feature "library" -> feature "person"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/person/person.dart';
```

### ARCH-R4 — lib/src/features/library/data/repositories/supabase_library_repository.dart:4

- **Message**: Interdit: feature "library" -> feature "movie"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/movie/domain/entities/movie_summary.dart';
```

### ARCH-R4 — lib/src/features/library/data/repositories/supabase_library_repository.dart:5

- **Message**: Interdit: feature "library" -> feature "tv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/tv/domain/entities/tv_show.dart';
```

### ARCH-R4 — lib/src/features/library/data/repositories/supabase_library_repository.dart:6

- **Message**: Interdit: feature "library" -> feature "saga"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/saga/domain/entities/saga.dart';
```

### ARCH-R4 — lib/src/features/library/data/repositories/supabase_library_repository.dart:11

- **Message**: Interdit: feature "library" -> feature "playlist"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/playlist/domain/entities/playlist.dart';
```

### ARCH-R4 — lib/src/features/library/domain/repositories/library_repository.dart:1

- **Message**: Interdit: feature "library" -> feature "movie"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/movie/domain/entities/movie_summary.dart';
```

### ARCH-R4 — lib/src/features/library/domain/repositories/library_repository.dart:2

- **Message**: Interdit: feature "library" -> feature "tv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/tv/domain/entities/tv_show.dart';
```

### ARCH-R4 — lib/src/features/library/domain/repositories/library_repository.dart:3

- **Message**: Interdit: feature "library" -> feature "saga"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/saga/domain/entities/saga.dart';
```

### ARCH-R4 — lib/src/features/library/domain/repositories/library_repository.dart:6

- **Message**: Interdit: feature "library" -> feature "playlist"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/playlist/domain/entities/playlist.dart';
```

### ARCH-R4 — lib/src/features/library/domain/services/library_playlist_sorter.dart:2

- **Message**: Interdit: feature "library" -> feature "playlist"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/playlist/playlist.dart';
```

### ARCH-R2 — lib/src/features/library/domain/services/playlist_backdrop_service.dart:3

- **Message**: Interdit: domain -> data
- **Suggestion**: Extraire une interface (repository) côté domain, impl côté data.
- **Import**:

```
import 'package:movi/src/shared/data/services/tmdb_client.dart';
```

### ARCH-R2 — lib/src/features/library/domain/services/playlist_backdrop_service.dart:4

- **Message**: Interdit: domain -> data
- **Suggestion**: Extraire une interface (repository) côté domain, impl côté data.
- **Import**:

```
import 'package:movi/src/shared/data/services/tmdb_image_resolver.dart';
```

### ARCH-R4 — lib/src/features/library/presentation/pages/library_page.dart:27

- **Message**: Interdit: feature "library" -> feature "settings"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/settings/presentation/providers/user_settings_providers.dart';
```

### ARCH-R4 — lib/src/features/library/presentation/pages/library_playlist_detail_page.dart:20

- **Message**: Interdit: feature "library" -> feature "playlist"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/playlist/playlist.dart';
```

### ARCH-R5 — lib/src/features/library/presentation/pages/library_playlist_detail_page.dart:26

- **Message**: Interdit: accès direct au locator en UI
- **Suggestion**: Passer par providers Riverpod / injection testable.
- **Import**:

```
import 'package:movi/src/core/di/di.dart';
```

### ARCH-R4 — lib/src/features/library/presentation/pages/library_playlist_detail_page.dart:30

- **Message**: Interdit: feature "library" -> feature "settings"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/settings/presentation/providers/user_settings_providers.dart';
```

### ARCH-R4 — lib/src/features/library/presentation/pages/library_playlist_detail_page.dart:31

- **Message**: Interdit: feature "library" -> feature "home"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/home/presentation/providers/home_providers.dart';
```

### ARCH-R4 — lib/src/features/library/presentation/pages/library_playlist_detail_page.dart:32

- **Message**: Interdit: feature "library" -> feature "movie"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/movie/presentation/providers/movie_detail_providers.dart';
```

### ARCH-R4 — lib/src/features/library/presentation/pages/library_playlist_detail_page.dart:33

- **Message**: Interdit: feature "library" -> feature "tv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/tv/presentation/providers/tv_detail_providers.dart';
```

### ARCH-R4 — lib/src/features/library/presentation/pages/library_playlist_detail_page.dart:34

- **Message**: Interdit: feature "library" -> feature "series_tracking"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/series_tracking/presentation/providers/series_tracking_providers.dart';
```

### ARCH-R5 — lib/src/features/library/presentation/providers/library_cloud_sync_access_providers.dart:6

- **Message**: Interdit: accès direct au locator en UI
- **Suggestion**: Passer par providers Riverpod / injection testable.
- **Import**:

```
import 'package:movi/src/core/di/di.dart';
```

### ARCH-R3 — lib/src/features/library/presentation/providers/library_cloud_sync_providers.dart:5

- **Message**: Interdit: presentation -> SDK externe (get_it)
- **Suggestion**: Isoler le SDK dans core/data (adapter) et exposer une abstraction.
- **Import**:

```
import 'package:get_it/get_it.dart';
```

### ARCH-R3 — lib/src/features/library/presentation/providers/library_cloud_sync_providers.dart:6

- **Message**: Interdit: presentation -> SDK externe (sqflite)
- **Suggestion**: Isoler le SDK dans core/data (adapter) et exposer une abstraction.
- **Import**:

```
import 'package:sqflite/sqflite.dart';
```

### ARCH-R3 — lib/src/features/library/presentation/providers/library_cloud_sync_providers.dart:7

- **Message**: Interdit: presentation -> SDK externe (supabase_flutter)
- **Suggestion**: Isoler le SDK dans core/data (adapter) et exposer une abstraction.
- **Import**:

```
import 'package:supabase_flutter/supabase_flutter.dart';
```

### ARCH-R5 — lib/src/features/library/presentation/providers/library_cloud_sync_providers.dart:9

- **Message**: Interdit: accès direct au locator en UI
- **Suggestion**: Passer par providers Riverpod / injection testable.
- **Import**:

```
import 'package:movi/src/core/di/di.dart';
```

### ARCH-R1 — lib/src/features/library/presentation/providers/library_cloud_sync_providers.dart:24

- **Message**: Interdit: presentation -> data
- **Suggestion**: Dépendre de domain/application et exposer une abstraction.
- **Import**:

```
import 'package:movi/src/features/iptv/data/datasources/supabase_iptv_sources_repository.dart';
```

### ARCH-R1 — lib/src/features/library/presentation/providers/library_cloud_sync_providers.dart:25

- **Message**: Interdit: presentation -> data
- **Suggestion**: Dépendre de domain/application et exposer une abstraction.
- **Import**:

```
import 'package:movi/src/features/iptv/data/services/iptv_credentials_edge_service.dart';
```

### ARCH-R4 — lib/src/features/library/presentation/providers/library_cloud_sync_providers.dart:26

- **Message**: Interdit: feature "library" -> feature "iptv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/iptv/application/usecases/refresh_xtream_catalog.dart';
```

### ARCH-R4 — lib/src/features/library/presentation/providers/library_cloud_sync_providers.dart:27

- **Message**: Interdit: feature "library" -> feature "iptv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/iptv/domain/entities/xtream_account.dart';
```

### ARCH-R4 — lib/src/features/library/presentation/providers/library_cloud_sync_providers.dart:28

- **Message**: Interdit: feature "library" -> feature "iptv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/iptv/domain/value_objects/xtream_endpoint.dart';
```

### ARCH-R5 — lib/src/features/library/presentation/providers/library_providers.dart:3

- **Message**: Interdit: accès direct au locator en UI
- **Suggestion**: Passer par providers Riverpod / injection testable.
- **Import**:

```
import 'package:movi/src/core/di/di.dart';
```

### ARCH-R1 — lib/src/features/library/presentation/providers/library_providers.dart:10

- **Message**: Interdit: presentation -> data
- **Suggestion**: Dépendre de domain/application et exposer une abstraction.
- **Import**:

```
import 'package:movi/src/features/library/data/repositories/library_repository_impl.dart';
```

### ARCH-R4 — lib/src/features/library/presentation/providers/library_providers.dart:14

- **Message**: Interdit: feature "library" -> feature "playlist"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/playlist/playlist.dart';
```

### ARCH-R4 — lib/src/features/library/presentation/providers/library_providers.dart:15

- **Message**: Interdit: feature "library" -> feature "person"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/person/person.dart';
```

### ARCH-R4 — lib/src/features/library/presentation/providers/library_providers.dart:16

- **Message**: Interdit: feature "library" -> feature "settings"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/settings/presentation/providers/user_settings_providers.dart';
```

### ARCH-R1 — lib/src/features/library/presentation/providers/library_providers.dart:21

- **Message**: Interdit: presentation -> data
- **Suggestion**: Dépendre de domain/application et exposer une abstraction.
- **Import**:

```
import 'package:movi/src/shared/data/services/tmdb_client.dart';
```

### ARCH-R1 — lib/src/features/library/presentation/providers/library_providers.dart:22

- **Message**: Interdit: presentation -> data
- **Suggestion**: Dépendre de domain/application et exposer une abstraction.
- **Import**:

```
import 'package:movi/src/shared/data/services/tmdb_image_resolver.dart';
```

### ARCH-R5 — lib/src/features/library/presentation/providers/library_remote_providers.dart:3

- **Message**: Interdit: accès direct au locator en UI
- **Suggestion**: Passer par providers Riverpod / injection testable.
- **Import**:

```
import 'package:movi/src/core/di/di.dart';
```

### ARCH-R1 — lib/src/features/library/presentation/providers/library_remote_providers.dart:7

- **Message**: Interdit: presentation -> data
- **Suggestion**: Dépendre de domain/application et exposer une abstraction.
- **Import**:

```
import 'package:movi/src/features/library/data/repositories/supabase_playback_history_repository.dart';
```

### ARCH-R1 — lib/src/features/library/presentation/providers/library_remote_providers.dart:8

- **Message**: Interdit: presentation -> data
- **Suggestion**: Dépendre de domain/application et exposer une abstraction.
- **Import**:

```
import 'package:movi/src/features/library/data/repositories/supabase_library_repository.dart';
```

### ARCH-R1 — lib/src/features/library/presentation/providers/library_remote_providers.dart:9

- **Message**: Interdit: presentation -> data
- **Suggestion**: Dépendre de domain/application et exposer une abstraction.
- **Import**:

```
import 'package:movi/src/features/library/data/repositories/supabase_favorites_repository.dart';
```

### ARCH-R1 — lib/src/features/library/presentation/providers/library_remote_providers.dart:10

- **Message**: Interdit: presentation -> data
- **Suggestion**: Dépendre de domain/application et exposer une abstraction.
- **Import**:

```
import 'package:movi/src/features/library/data/repositories/hybrid_playback_history_repository.dart';
```

### ARCH-R4 — lib/src/features/library/presentation/providers/library_remote_providers.dart:13

- **Message**: Interdit: feature "library" -> feature "settings"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/settings/presentation/providers/user_settings_providers.dart';
```

### ARCH-R4 — lib/src/features/library/presentation/widgets/add_media_search_modal.dart:8

- **Message**: Interdit: feature "library" -> feature "search"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/search/presentation/providers/search_providers.dart';
```

### ARCH-R4 — lib/src/features/library/presentation/widgets/add_media_search_modal.dart:9

- **Message**: Interdit: feature "library" -> feature "search"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/search/presentation/controllers/search_instant_controller.dart';
```

### ARCH-R4 — lib/src/features/library/presentation/widgets/add_media_search_modal.dart:10

- **Message**: Interdit: feature "library" -> feature "playlist"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/playlist/playlist.dart';
```

### ARCH-R4 — lib/src/features/library/presentation/widgets/add_media_search_modal.dart:14

- **Message**: Interdit: feature "library" -> feature "movie"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/movie/domain/entities/movie_summary.dart';
```

### ARCH-R4 — lib/src/features/library/presentation/widgets/add_media_search_modal.dart:15

- **Message**: Interdit: feature "library" -> feature "tv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/tv/domain/entities/tv_show.dart';
```

### ARCH-R4 — lib/src/features/library/presentation/widgets/library_premium_banner.dart:5

- **Message**: Interdit: feature "library" -> feature "settings"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/settings/presentation/localization/movi_premium_localizer.dart';
```

### ARCH-R4 — lib/src/features/library/presentation/widgets/library_premium_banner.dart:6

- **Message**: Interdit: feature "library" -> feature "settings"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/settings/presentation/pages/movi_premium_page.dart';
```

### ARCH-R4 — lib/src/features/library/presentation/widgets/library_premium_banner.dart:7

- **Message**: Interdit: feature "library" -> feature "settings"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/settings/presentation/providers/movi_premium_providers.dart';
```

### ARCH-R4 — lib/src/features/movie/data/movie_data_module.dart:8

- **Message**: Interdit: feature "movie" -> feature "iptv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/iptv/data/services/xtream_stream_url_builder_impl.dart';
```

### ARCH-R4 — lib/src/features/movie/data/movie_data_module.dart:9

- **Message**: Interdit: feature "movie" -> feature "library"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/library/domain/repositories/continue_watching_repository.dart';
```

### ARCH-R4 — lib/src/features/movie/data/movie_data_module.dart:10

- **Message**: Interdit: feature "movie" -> feature "library"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/library/domain/repositories/playback_history_repository.dart';
```

### ARCH-R4 — lib/src/features/movie/data/movie_data_module.dart:30

- **Message**: Interdit: feature "movie" -> feature "player"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/player/application/services/playback_selection_service.dart';
```

### ARCH-R4 — lib/src/features/movie/data/movie_data_module.dart:31

- **Message**: Interdit: feature "movie" -> feature "player"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/player/domain/services/xtream_stream_url_builder.dart';
```

### ARCH-R4 — lib/src/features/movie/data/movie_data_module.dart:32

- **Message**: Interdit: feature "movie" -> feature "playlist"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/playlist/domain/repositories/playlist_repository.dart';
```

### ARCH-R4 — lib/src/features/movie/data/repositories/movie_repository_impl.dart:13

- **Message**: Interdit: feature "movie" -> feature "saga"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/saga/domain/entities/saga.dart';
```

### ARCH-R4 — lib/src/features/movie/data/services/iptv_availability_service_impl.dart:3

- **Message**: Interdit: feature "movie" -> feature "iptv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist_item.dart';
```

### ARCH-R4 — lib/src/features/movie/data/services/movie_playback_variant_resolver_impl.dart:8

- **Message**: Interdit: feature "movie" -> feature "iptv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/iptv/domain/entities/stalker_account.dart';
```

### ARCH-R4 — lib/src/features/movie/data/services/movie_playback_variant_resolver_impl.dart:9

- **Message**: Interdit: feature "movie" -> feature "iptv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/iptv/domain/entities/xtream_account.dart';
```

### ARCH-R4 — lib/src/features/movie/data/services/movie_playback_variant_resolver_impl.dart:10

- **Message**: Interdit: feature "movie" -> feature "iptv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist_item.dart';
```

### ARCH-R4 — lib/src/features/movie/data/services/movie_playback_variant_resolver_impl.dart:12

- **Message**: Interdit: feature "movie" -> feature "player"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/player/domain/entities/playback_variant.dart';
```

### ARCH-R4 — lib/src/features/movie/data/services/movie_playback_variant_resolver_impl.dart:13

- **Message**: Interdit: feature "movie" -> feature "player"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/player/domain/entities/video_source.dart';
```

### ARCH-R4 — lib/src/features/movie/data/services/movie_playback_variant_resolver_impl.dart:14

- **Message**: Interdit: feature "movie" -> feature "player"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/player/domain/services/xtream_stream_url_builder.dart';
```

### ARCH-R4 — lib/src/features/movie/data/services/movie_streaming_service_impl.dart:5

- **Message**: Interdit: feature "movie" -> feature "iptv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist_item.dart';
```

### ARCH-R4 — lib/src/features/movie/data/services/movie_streaming_service_impl.dart:6

- **Message**: Interdit: feature "movie" -> feature "player"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/player/domain/entities/video_source.dart';
```

### ARCH-R4 — lib/src/features/movie/data/services/movie_streaming_service_impl.dart:7

- **Message**: Interdit: feature "movie" -> feature "iptv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/iptv/data/services/xtream_stream_url_builder_impl.dart';
```

### ARCH-R4 — lib/src/features/movie/domain/entities/movie.dart:4

- **Message**: Interdit: feature "movie" -> feature "saga"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/saga/domain/entities/saga.dart';
```

### ARCH-R4 — lib/src/features/movie/domain/services/movie_playback_variant_resolver.dart:1

- **Message**: Interdit: feature "movie" -> feature "player"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/player/domain/entities/playback_variant.dart';
```

### ARCH-R4 — lib/src/features/movie/domain/services/movie_streaming_service.dart:1

- **Message**: Interdit: feature "movie" -> feature "player"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/player/domain/entities/video_source.dart';
```

### ARCH-R4 — lib/src/features/movie/domain/services/movie_variant_matcher.dart:2

- **Message**: Interdit: feature "movie" -> feature "iptv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist_item.dart';
```

### ARCH-R4 — lib/src/features/movie/domain/usecases/add_movie_to_playlist.dart:1

- **Message**: Interdit: feature "movie" -> feature "playlist"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/playlist/domain/entities/playlist.dart';
```

### ARCH-R4 — lib/src/features/movie/domain/usecases/add_movie_to_playlist.dart:2

- **Message**: Interdit: feature "movie" -> feature "playlist"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/playlist/domain/repositories/playlist_repository.dart';
```

### ARCH-R4 — lib/src/features/movie/domain/usecases/build_movie_video_source.dart:1

- **Message**: Interdit: feature "movie" -> feature "player"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/player/domain/entities/playback_launch_plan.dart';
```

### ARCH-R4 — lib/src/features/movie/domain/usecases/build_movie_video_source.dart:2

- **Message**: Interdit: feature "movie" -> feature "player"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/player/domain/entities/video_source.dart';
```

### ARCH-R4 — lib/src/features/movie/domain/usecases/build_movie_video_source.dart:5

- **Message**: Interdit: feature "movie" -> feature "library"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/library/domain/repositories/playback_history_repository.dart';
```

### ARCH-R4 — lib/src/features/movie/domain/usecases/filter_recommendations_by_iptv.dart:2

- **Message**: Interdit: feature "movie" -> feature "iptv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist_item.dart';
```

### ARCH-R4 — lib/src/features/movie/domain/usecases/mark_movie_as_seen.dart:2

- **Message**: Interdit: feature "movie" -> feature "library"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/library/domain/repositories/playback_history_repository.dart';
```

### ARCH-R4 — lib/src/features/movie/domain/usecases/mark_movie_as_unseen.dart:2

- **Message**: Interdit: feature "movie" -> feature "library"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/library/domain/repositories/playback_history_repository.dart';
```

### ARCH-R4 — lib/src/features/movie/domain/usecases/mark_movie_as_unseen.dart:3

- **Message**: Interdit: feature "movie" -> feature "library"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/library/domain/repositories/continue_watching_repository.dart';
```

### ARCH-R4 — lib/src/features/movie/domain/usecases/resolve_movie_playback_selection.dart:3

- **Message**: Interdit: feature "movie" -> feature "library"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/library/domain/repositories/playback_history_repository.dart';
```

### ARCH-R4 — lib/src/features/movie/domain/usecases/resolve_movie_playback_selection.dart:5

- **Message**: Interdit: feature "movie" -> feature "player"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/player/application/services/playback_selection_service.dart';
```

### ARCH-R4 — lib/src/features/movie/domain/usecases/resolve_movie_playback_selection.dart:6

- **Message**: Interdit: feature "movie" -> feature "player"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/player/domain/entities/playback_launch_plan.dart';
```

### ARCH-R4 — lib/src/features/movie/domain/usecases/resolve_movie_playback_selection.dart:7

- **Message**: Interdit: feature "movie" -> feature "player"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/player/domain/entities/playback_selection_decision.dart';
```

### ARCH-R4 — lib/src/features/movie/domain/usecases/resolve_movie_playback_selection.dart:8

- **Message**: Interdit: feature "movie" -> feature "player"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/player/domain/entities/playback_selection_preferences.dart';
```

### ARCH-R4 — lib/src/features/movie/domain/usecases/resolve_movie_playback_selection.dart:9

- **Message**: Interdit: feature "movie" -> feature "player"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/player/domain/entities/playback_variant.dart';
```

### ARCH-R4 — lib/src/features/movie/domain/usecases/resolve_movie_playback_selection.dart:10

- **Message**: Interdit: feature "movie" -> feature "player"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/player/domain/entities/video_source.dart';
```

### ARCH-R4 — lib/src/features/movie/presentation/models/movie_detail_view_model.dart:6

- **Message**: Interdit: feature "movie" -> feature "saga"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/saga/domain/entities/saga.dart';
```

### ARCH-R5 — lib/src/features/movie/presentation/pages/movie_detail_page.dart:17

- **Message**: Interdit: accès direct au locator en UI
- **Suggestion**: Passer par providers Riverpod / injection testable.
- **Import**:

```
import 'package:movi/src/core/di/di.dart';
```

### ARCH-R4 — lib/src/features/movie/presentation/pages/movie_detail_page.dart:24

- **Message**: Interdit: feature "movie" -> feature "home"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/home/presentation/providers/home_providers.dart'
```

### ARCH-R4 — lib/src/features/movie/presentation/pages/movie_detail_page.dart:26

- **Message**: Interdit: feature "movie" -> feature "home"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/home/presentation/widgets/home_layout_constants.dart';
```

### ARCH-R4 — lib/src/features/movie/presentation/pages/movie_detail_page.dart:31

- **Message**: Interdit: feature "movie" -> feature "settings"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/settings/presentation/providers/user_settings_providers.dart';
```

### ARCH-R4 — lib/src/features/movie/presentation/pages/movie_detail_page.dart:33

- **Message**: Interdit: feature "movie" -> feature "saga"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/saga/domain/entities/saga.dart';
```

### ARCH-R4 — lib/src/features/movie/presentation/pages/movie_detail_page.dart:34

- **Message**: Interdit: feature "movie" -> feature "library"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/library/presentation/providers/library_providers.dart';
```

### ARCH-R4 — lib/src/features/movie/presentation/pages/movie_detail_page.dart:35

- **Message**: Interdit: feature "movie" -> feature "library"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/library/presentation/widgets/library_playlist_card.dart';
```

### ARCH-R4 — lib/src/features/movie/presentation/pages/movie_detail_page.dart:36

- **Message**: Interdit: feature "movie" -> feature "playlist"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/playlist/playlist.dart';
```

### ARCH-R4 — lib/src/features/movie/presentation/pages/movie_detail_page.dart:43

- **Message**: Interdit: feature "movie" -> feature "player"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/player/domain/entities/playback_selection_decision.dart';
```

### ARCH-R3 — lib/src/features/movie/presentation/providers/movie_detail_providers.dart:2

- **Message**: Interdit: presentation -> SDK externe (get_it)
- **Suggestion**: Isoler le SDK dans core/data (adapter) et exposer une abstraction.
- **Import**:

```
import 'package:get_it/get_it.dart';
```

### ARCH-R5 — lib/src/features/movie/presentation/providers/movie_detail_providers.dart:3

- **Message**: Interdit: accès direct au locator en UI
- **Suggestion**: Passer par providers Riverpod / injection testable.
- **Import**:

```
import 'package:movi/src/core/di/di.dart';
```

### ARCH-R1 — lib/src/features/movie/presentation/providers/movie_detail_providers.dart:8

- **Message**: Interdit: presentation -> data
- **Suggestion**: Dépendre de domain/application et exposer une abstraction.
- **Import**:

```
import 'package:movi/src/features/movie/data/repositories/movie_repository_impl.dart';
```

### ARCH-R1 — lib/src/features/movie/presentation/providers/movie_detail_providers.dart:9

- **Message**: Interdit: presentation -> data
- **Suggestion**: Dépendre de domain/application et exposer une abstraction.
- **Import**:

```
import 'package:movi/src/features/movie/data/datasources/movie_local_data_source.dart';
```

### ARCH-R1 — lib/src/features/movie/presentation/providers/movie_detail_providers.dart:10

- **Message**: Interdit: presentation -> data
- **Suggestion**: Dépendre de domain/application et exposer une abstraction.
- **Import**:

```
import 'package:movi/src/features/movie/data/datasources/tmdb_movie_remote_data_source.dart';
```

### ARCH-R4 — lib/src/features/movie/presentation/providers/movie_detail_providers.dart:14

- **Message**: Interdit: feature "movie" -> feature "settings"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/settings/presentation/providers/user_settings_providers.dart';
```

### ARCH-R4 — lib/src/features/movie/presentation/providers/movie_detail_providers.dart:15

- **Message**: Interdit: feature "movie" -> feature "library"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/library/presentation/providers/library_providers.dart';
```

### ARCH-R1 — lib/src/features/movie/presentation/providers/movie_detail_providers.dart:16

- **Message**: Interdit: presentation -> data
- **Suggestion**: Dépendre de domain/application et exposer une abstraction.
- **Import**:

```
import 'package:movi/src/shared/data/services/tmdb_image_resolver.dart';
```

### ARCH-R1 — lib/src/features/movie/presentation/providers/movie_detail_providers.dart:17

- **Message**: Interdit: presentation -> data
- **Suggestion**: Dépendre de domain/application et exposer une abstraction.
- **Import**:

```
import 'package:movi/src/shared/data/services/tmdb_detail_cache_data_source.dart';
```

### ARCH-R1 — lib/src/features/movie/presentation/providers/movie_detail_providers.dart:18

- **Message**: Interdit: presentation -> data
- **Suggestion**: Dépendre de domain/application et exposer une abstraction.
- **Import**:

```
import 'package:movi/src/shared/data/services/xtream_lookup_service.dart';
```

### ARCH-R4 — lib/src/features/movie/presentation/providers/movie_detail_providers.dart:20

- **Message**: Interdit: feature "movie" -> feature "saga"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/saga/domain/repositories/saga_repository.dart';
```

### ARCH-R4 — lib/src/features/movie/presentation/providers/movie_detail_providers.dart:21

- **Message**: Interdit: feature "movie" -> feature "saga"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/saga/domain/entities/saga.dart';
```

### ARCH-R4 — lib/src/features/movie/presentation/providers/movie_detail_providers.dart:24

- **Message**: Interdit: feature "movie" -> feature "player"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/player/domain/entities/playback_launch_plan.dart';
```

### ARCH-R4 — lib/src/features/movie/presentation/providers/movie_detail_providers.dart:25

- **Message**: Interdit: feature "movie" -> feature "player"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/player/domain/entities/playback_selection_decision.dart';
```

### ARCH-R4 — lib/src/features/movie/presentation/providers/movie_detail_providers.dart:26

- **Message**: Interdit: feature "movie" -> feature "player"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/player/domain/entities/playback_selection_preferences.dart';
```

### ARCH-R4 — lib/src/features/movie/presentation/providers/movie_detail_providers.dart:27

- **Message**: Interdit: feature "movie" -> feature "player"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/player/domain/entities/playback_variant.dart';
```

### ARCH-R4 — lib/src/features/movie/presentation/providers/movie_detail_providers.dart:28

- **Message**: Interdit: feature "movie" -> feature "player"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/player/domain/entities/video_source.dart';
```

### ARCH-R4 — lib/src/features/movie/presentation/providers/movie_detail_providers.dart:36

- **Message**: Interdit: feature "movie" -> feature "library"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/library/domain/repositories/playback_history_repository.dart';
```

### ARCH-R4 — lib/src/features/movie/presentation/providers/movie_detail_providers.dart:37

- **Message**: Interdit: feature "movie" -> feature "iptv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist_item.dart';
```

### ARCH-R4 — lib/src/features/movie/presentation/providers/movie_detail_providers.dart:38

- **Message**: Interdit: feature "movie" -> feature "player"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/player/domain/value_objects/preferred_playback_quality.dart';
```

### ARCH-R4 — lib/src/features/movie/presentation/widgets/movie_detail_main_actions.dart:8

- **Message**: Interdit: feature "movie" -> feature "home"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/home/presentation/providers/home_providers.dart'
```

### ARCH-R4 — lib/src/features/movie/presentation/widgets/movie_detail_saga_section.dart:7

- **Message**: Interdit: feature "movie" -> feature "saga"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/saga/domain/entities/saga.dart';
```

### ARCH-R4 — lib/src/features/movie/presentation/widgets/movie_playback_variant_sheet.dart:4

- **Message**: Interdit: feature "movie" -> feature "player"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/player/domain/entities/playback_variant.dart';
```

### ARCH-R4 — lib/src/features/person/presentation/models/person_detail_view_model.dart:4

- **Message**: Interdit: feature "person" -> feature "movie"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/movie/domain/entities/movie_summary.dart';
```

### ARCH-R4 — lib/src/features/person/presentation/models/person_detail_view_model.dart:5

- **Message**: Interdit: feature "person" -> feature "tv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/tv/domain/entities/tv_show.dart';
```

### ARCH-R5 — lib/src/features/person/presentation/providers/person_detail_providers.dart:2

- **Message**: Interdit: accès direct au locator en UI
- **Suggestion**: Passer par providers Riverpod / injection testable.
- **Import**:

```
import 'package:movi/src/core/di/di.dart';
```

### ARCH-R4 — lib/src/features/person/presentation/providers/person_detail_providers.dart:6

- **Message**: Interdit: feature "person" -> feature "library"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/library/domain/repositories/favorites_repository.dart';
```

### ARCH-R1 — lib/src/features/person/presentation/providers/person_detail_providers.dart:7

- **Message**: Interdit: presentation -> data
- **Suggestion**: Dépendre de domain/application et exposer une abstraction.
- **Import**:

```
import 'package:movi/src/features/library/data/repositories/favorites_repository_impl.dart';
```

### ARCH-R4 — lib/src/features/person/presentation/providers/person_detail_providers.dart:9

- **Message**: Interdit: feature "person" -> feature "iptv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/iptv/iptv.dart';
```

### ARCH-R4 — lib/src/features/person/presentation/providers/person_detail_providers.dart:10

- **Message**: Interdit: feature "person" -> feature "movie"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/movie/domain/entities/movie_summary.dart';
```

### ARCH-R4 — lib/src/features/person/presentation/providers/person_detail_providers.dart:11

- **Message**: Interdit: feature "person" -> feature "tv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/tv/domain/entities/tv_show.dart';
```

### ARCH-R4 — lib/src/features/person/presentation/providers/person_detail_providers.dart:14

- **Message**: Interdit: feature "person" -> feature "settings"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/settings/presentation/providers/user_settings_providers.dart';
```

### ARCH-R4 — lib/src/features/person/presentation/providers/person_detail_providers.dart:15

- **Message**: Interdit: feature "person" -> feature "library"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/library/presentation/providers/library_providers.dart';
```

### ARCH-R1 — lib/src/features/person/presentation/providers/person_detail_providers.dart:16

- **Message**: Interdit: presentation -> data
- **Suggestion**: Dépendre de domain/application et exposer une abstraction.
- **Import**:

```
import 'package:movi/src/shared/data/services/tmdb_client.dart';
```

### ARCH-R1 — lib/src/features/person/presentation/providers/person_detail_providers.dart:17

- **Message**: Interdit: presentation -> data
- **Suggestion**: Dépendre de domain/application et exposer une abstraction.
- **Import**:

```
import 'package:movi/src/shared/data/services/tmdb_image_resolver.dart';
```

### ARCH-R1 — lib/src/features/person/presentation/providers/person_detail_providers.dart:18

- **Message**: Interdit: presentation -> data
- **Suggestion**: Dépendre de domain/application et exposer une abstraction.
- **Import**:

```
import 'package:movi/src/features/person/data/datasources/tmdb_person_remote_data_source.dart';
```

### ARCH-R1 — lib/src/features/person/presentation/providers/person_detail_providers.dart:19

- **Message**: Interdit: presentation -> data
- **Suggestion**: Dépendre de domain/application et exposer une abstraction.
- **Import**:

```
import 'package:movi/src/features/person/data/datasources/person_local_data_source.dart';
```

### ARCH-R1 — lib/src/features/person/presentation/providers/person_detail_providers.dart:20

- **Message**: Interdit: presentation -> data
- **Suggestion**: Dépendre de domain/application et exposer une abstraction.
- **Import**:

```
import 'package:movi/src/features/person/data/repositories/person_repository_impl.dart';
```

### ARCH-R4 — lib/src/features/player/application/services/next_episode_service.dart:2

- **Message**: Interdit: feature "player" -> feature "iptv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist_item.dart';
```

### ARCH-R4 — lib/src/features/player/application/services/next_episode_service.dart:8

- **Message**: Interdit: feature "player" -> feature "tv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/tv/presentation/models/tv_detail_view_model.dart';
```

### ARCH-R4 — lib/src/features/player/domain/services/xtream_stream_url_builder.dart:1

- **Message**: Interdit: feature "player" -> feature "iptv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist_item.dart';
```

### ARCH-R5 — lib/src/features/player/presentation/pages/video_player_page.dart:20

- **Message**: Interdit: accès direct au locator en UI
- **Suggestion**: Passer par providers Riverpod / injection testable.
- **Import**:

```
import 'package:movi/src/core/di/di.dart';
```

### ARCH-R4 — lib/src/features/player/presentation/pages/video_player_page.dart:25

- **Message**: Interdit: feature "player" -> feature "home"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/home/presentation/providers/home_providers.dart';
```

### ARCH-R4 — lib/src/features/player/presentation/pages/video_player_page.dart:26

- **Message**: Interdit: feature "player" -> feature "library"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/library/presentation/providers/library_providers.dart';
```

### ARCH-R4 — lib/src/features/player/presentation/pages/video_player_page.dart:27

- **Message**: Interdit: feature "player" -> feature "library"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/library/presentation/providers/library_remote_providers.dart';
```

### ARCH-R4 — lib/src/features/player/presentation/pages/video_player_page.dart:28

- **Message**: Interdit: feature "player" -> feature "movie"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/movie/presentation/providers/movie_detail_providers.dart'
```

### ARCH-R4 — lib/src/features/player/presentation/pages/video_player_page.dart:30

- **Message**: Interdit: feature "player" -> feature "settings"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/settings/presentation/providers/user_settings_providers.dart';
```

### ARCH-R4 — lib/src/features/player/presentation/pages/video_player_page.dart:31

- **Message**: Interdit: feature "player" -> feature "tv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/tv/presentation/providers/tv_detail_providers.dart';
```

### ARCH-R4 — lib/src/features/player/presentation/pages/video_player_page.dart:42

- **Message**: Interdit: feature "player" -> feature "library"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/library/domain/repositories/playback_history_repository.dart';
```

### ARCH-R5 — lib/src/features/player/presentation/providers/player_providers.dart:3

- **Message**: Interdit: accès direct au locator en UI
- **Suggestion**: Passer par providers Riverpod / injection testable.
- **Import**:

```
import 'package:movi/src/core/di/di.dart';
```

### ARCH-R1 — lib/src/features/player/presentation/providers/player_providers.dart:8

- **Message**: Interdit: presentation -> data
- **Suggestion**: Dépendre de domain/application et exposer une abstraction.
- **Import**:

```
import 'package:movi/src/features/iptv/data/services/xtream_stream_url_builder_impl.dart';
```

### ARCH-R1 — lib/src/features/player/presentation/providers/player_providers.dart:11

- **Message**: Interdit: presentation -> data
- **Suggestion**: Dépendre de domain/application et exposer une abstraction.
- **Import**:

```
import 'package:movi/src/features/player/data/repositories/media_kit_video_player_repository.dart';
```

### ARCH-R1 — lib/src/features/player/presentation/providers/player_providers.dart:12

- **Message**: Interdit: presentation -> data
- **Suggestion**: Dépendre de domain/application et exposer une abstraction.
- **Import**:

```
import 'package:movi/src/features/player/data/repositories/picture_in_picture_repository_impl.dart';
```

### ARCH-R1 — lib/src/features/player/presentation/providers/player_providers.dart:13

- **Message**: Interdit: presentation -> data
- **Suggestion**: Dépendre de domain/application et exposer une abstraction.
- **Import**:

```
import 'package:movi/src/features/player/data/repositories/system_control_repository_impl.dart';
```

### ARCH-R4 — lib/src/features/playlist/application/services/playlist_filter_service.dart:2

- **Message**: Interdit: feature "playlist" -> feature "iptv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/iptv/iptv.dart';
```

### ARCH-R4 — lib/src/features/saga/presentation/pages/saga_detail_page.dart:11

- **Message**: Interdit: feature "saga" -> feature "movie"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/movie/presentation/providers/movie_detail_providers.dart';
```

### ARCH-R5 — lib/src/features/saga/presentation/providers/saga_detail_providers.dart:2

- **Message**: Interdit: accès direct au locator en UI
- **Suggestion**: Passer par providers Riverpod / injection testable.
- **Import**:

```
import 'package:movi/src/core/di/di.dart';
```

### ARCH-R4 — lib/src/features/saga/presentation/providers/saga_detail_providers.dart:4

- **Message**: Interdit: feature "saga" -> feature "iptv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/iptv/iptv.dart';
```

### ARCH-R1 — lib/src/features/saga/presentation/providers/saga_detail_providers.dart:8

- **Message**: Interdit: presentation -> data
- **Suggestion**: Dépendre de domain/application et exposer une abstraction.
- **Import**:

```
import 'package:movi/src/shared/data/services/tmdb_image_resolver.dart';
```

### ARCH-R1 — lib/src/features/saga/presentation/providers/saga_detail_providers.dart:9

- **Message**: Interdit: presentation -> data
- **Suggestion**: Dépendre de domain/application et exposer une abstraction.
- **Import**:

```
import 'package:movi/src/shared/data/services/tmdb_client.dart';
```

### ARCH-R4 — lib/src/features/search/data/datasources/tmdb_search_remote_data_source.dart:3

- **Message**: Interdit: feature "search" -> feature "movie"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/movie/data/dtos/tmdb_movie_detail_dto.dart';
```

### ARCH-R4 — lib/src/features/search/data/datasources/tmdb_search_remote_data_source.dart:4

- **Message**: Interdit: feature "search" -> feature "tv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/tv/data/dtos/tmdb_tv_detail_dto.dart';
```

### ARCH-R4 — lib/src/features/search/data/datasources/tmdb_search_remote_data_source.dart:5

- **Message**: Interdit: feature "search" -> feature "person"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/person/data/dtos/tmdb_person_detail_dto.dart';
```

### ARCH-R4 — lib/src/features/search/data/datasources/tmdb_watch_providers_remote_data_source.dart:6

- **Message**: Interdit: feature "search" -> feature "movie"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/movie/data/dtos/tmdb_movie_detail_dto.dart';
```

### ARCH-R4 — lib/src/features/search/data/datasources/tmdb_watch_providers_remote_data_source.dart:7

- **Message**: Interdit: feature "search" -> feature "tv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/tv/data/dtos/tmdb_tv_detail_dto.dart';
```

### ARCH-R4 — lib/src/features/search/data/search_data_module.dart:2

- **Message**: Interdit: feature "search" -> feature "iptv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/iptv/application/iptv_catalog_reader.dart';
```

### ARCH-R4 — lib/src/features/search/data/search_repository_impl.dart:1

- **Message**: Interdit: feature "search" -> feature "iptv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/iptv/application/iptv_catalog_reader.dart';
```

### ARCH-R4 — lib/src/features/search/data/search_repository_impl.dart:3

- **Message**: Interdit: feature "search" -> feature "movie"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/movie/domain/entities/movie_summary.dart';
```

### ARCH-R4 — lib/src/features/search/data/search_repository_impl.dart:4

- **Message**: Interdit: feature "search" -> feature "tv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/tv/domain/entities/tv_show.dart';
```

### ARCH-R4 — lib/src/features/search/data/search_repository_impl.dart:5

- **Message**: Interdit: feature "search" -> feature "person"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/person/data/dtos/tmdb_person_detail_dto.dart';
```

### ARCH-R4 — lib/src/features/search/data/search_repository_impl.dart:20

- **Message**: Interdit: feature "search" -> feature "movie"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/movie/data/dtos/tmdb_movie_detail_dto.dart';
```

### ARCH-R4 — lib/src/features/search/data/search_repository_impl.dart:21

- **Message**: Interdit: feature "search" -> feature "tv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/tv/data/dtos/tmdb_tv_detail_dto.dart';
```

### ARCH-R4 — lib/src/features/search/domain/repositories/search_repository.dart:1

- **Message**: Interdit: feature "search" -> feature "movie"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/movie/domain/entities/movie_summary.dart';
```

### ARCH-R4 — lib/src/features/search/domain/repositories/search_repository.dart:2

- **Message**: Interdit: feature "search" -> feature "tv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/tv/domain/entities/tv_show.dart';
```

### ARCH-R4 — lib/src/features/search/domain/usecases/load_watch_providers.dart:3

- **Message**: Interdit: feature "search" -> feature "movie"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/movie/domain/entities/movie_summary.dart';
```

### ARCH-R4 — lib/src/features/search/domain/usecases/load_watch_providers.dart:4

- **Message**: Interdit: feature "search" -> feature "tv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/tv/domain/entities/tv_show.dart';
```

### ARCH-R4 — lib/src/features/search/domain/usecases/search_instant.dart:2

- **Message**: Interdit: feature "search" -> feature "movie"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/movie/domain/entities/movie_summary.dart';
```

### ARCH-R4 — lib/src/features/search/domain/usecases/search_instant.dart:3

- **Message**: Interdit: feature "search" -> feature "tv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/tv/domain/entities/tv_show.dart';
```

### ARCH-R4 — lib/src/features/search/domain/usecases/search_movies.dart:3

- **Message**: Interdit: feature "search" -> feature "movie"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/movie/domain/entities/movie_summary.dart';
```

### ARCH-R4 — lib/src/features/search/domain/usecases/search_paginated.dart:3

- **Message**: Interdit: feature "search" -> feature "movie"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/movie/domain/entities/movie_summary.dart';
```

### ARCH-R4 — lib/src/features/search/domain/usecases/search_paginated.dart:4

- **Message**: Interdit: feature "search" -> feature "tv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/tv/domain/entities/tv_show.dart';
```

### ARCH-R4 — lib/src/features/search/domain/usecases/search_shows.dart:3

- **Message**: Interdit: feature "search" -> feature "tv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/tv/domain/entities/tv_show.dart';
```

### ARCH-R4 — lib/src/features/search/presentation/controllers/search_instant_controller.dart:3

- **Message**: Interdit: feature "search" -> feature "movie"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/movie/domain/entities/movie_summary.dart';
```

### ARCH-R4 — lib/src/features/search/presentation/controllers/search_instant_controller.dart:4

- **Message**: Interdit: feature "search" -> feature "tv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/tv/domain/entities/tv_show.dart';
```

### ARCH-R4 — lib/src/features/search/presentation/controllers/search_instant_controller.dart:6

- **Message**: Interdit: feature "search" -> feature "saga"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/saga/domain/entities/saga.dart';
```

### ARCH-R4 — lib/src/features/search/presentation/controllers/search_instant_controller.dart:7

- **Message**: Interdit: feature "search" -> feature "saga"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/saga/domain/repositories/saga_repository.dart';
```

### ARCH-R5 — lib/src/features/search/presentation/controllers/search_instant_controller.dart:10

- **Message**: Interdit: accès direct au locator en UI
- **Suggestion**: Passer par providers Riverpod / injection testable.
- **Import**:

```
import 'package:movi/src/core/di/di.dart';
```

### ARCH-R4 — lib/src/features/search/presentation/controllers/search_instant_controller.dart:13

- **Message**: Interdit: feature "search" -> feature "saga"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/saga/domain/usecases/search_sagas.dart';
```

### ARCH-R4 — lib/src/features/search/presentation/controllers/search_paged_controller.dart:2

- **Message**: Interdit: feature "search" -> feature "movie"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/movie/domain/entities/movie_summary.dart';
```

### ARCH-R4 — lib/src/features/search/presentation/controllers/search_paged_controller.dart:3

- **Message**: Interdit: feature "search" -> feature "tv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/tv/domain/entities/tv_show.dart';
```

### ARCH-R5 — lib/src/features/search/presentation/controllers/search_paged_controller.dart:6

- **Message**: Interdit: accès direct au locator en UI
- **Suggestion**: Passer par providers Riverpod / injection testable.
- **Import**:

```
import 'package:movi/src/core/di/di.dart';
```

### ARCH-R5 — lib/src/features/search/presentation/pages/genre_all_results_page.dart:9

- **Message**: Interdit: accès direct au locator en UI
- **Suggestion**: Passer par providers Riverpod / injection testable.
- **Import**:

```
import 'package:movi/src/core/di/di.dart';
```

### ARCH-R1 — lib/src/features/search/presentation/pages/genre_all_results_page.dart:19

- **Message**: Interdit: presentation -> data
- **Suggestion**: Dépendre de domain/application et exposer une abstraction.
- **Import**:

```
import 'package:movi/src/features/movie/data/dtos/tmdb_movie_detail_dto.dart';
```

### ARCH-R1 — lib/src/features/search/presentation/pages/genre_all_results_page.dart:21

- **Message**: Interdit: presentation -> data
- **Suggestion**: Dépendre de domain/application et exposer une abstraction.
- **Import**:

```
import 'package:movi/src/features/tv/data/dtos/tmdb_tv_detail_dto.dart';
```

### ARCH-R1 — lib/src/features/search/presentation/pages/genre_all_results_page.dart:22

- **Message**: Interdit: presentation -> data
- **Suggestion**: Dépendre de domain/application et exposer une abstraction.
- **Import**:

```
import 'package:movi/src/shared/data/services/tmdb_client.dart';
```

### ARCH-R1 — lib/src/features/search/presentation/pages/genre_all_results_page.dart:23

- **Message**: Interdit: presentation -> data
- **Suggestion**: Dépendre de domain/application et exposer une abstraction.
- **Import**:

```
import 'package:movi/src/shared/data/services/tmdb_image_resolver.dart';
```

### ARCH-R5 — lib/src/features/search/presentation/pages/genre_results_page.dart:12

- **Message**: Interdit: accès direct au locator en UI
- **Suggestion**: Passer par providers Riverpod / injection testable.
- **Import**:

```
import 'package:movi/src/core/di/di.dart';
```

### ARCH-R1 — lib/src/features/search/presentation/pages/genre_results_page.dart:21

- **Message**: Interdit: presentation -> data
- **Suggestion**: Dépendre de domain/application et exposer une abstraction.
- **Import**:

```
import 'package:movi/src/features/movie/data/dtos/tmdb_movie_detail_dto.dart';
```

### ARCH-R1 — lib/src/features/search/presentation/pages/genre_results_page.dart:24

- **Message**: Interdit: presentation -> data
- **Suggestion**: Dépendre de domain/application et exposer une abstraction.
- **Import**:

```
import 'package:movi/src/features/tv/data/dtos/tmdb_tv_detail_dto.dart';
```

### ARCH-R1 — lib/src/features/search/presentation/pages/genre_results_page.dart:25

- **Message**: Interdit: presentation -> data
- **Suggestion**: Dépendre de domain/application et exposer une abstraction.
- **Import**:

```
import 'package:movi/src/shared/data/services/tmdb_client.dart';
```

### ARCH-R1 — lib/src/features/search/presentation/pages/genre_results_page.dart:26

- **Message**: Interdit: presentation -> data
- **Suggestion**: Dépendre de domain/application et exposer une abstraction.
- **Import**:

```
import 'package:movi/src/shared/data/services/tmdb_image_resolver.dart';
```

### ARCH-R4 — lib/src/features/search/presentation/pages/provider_all_results_page.dart:18

- **Message**: Interdit: feature "search" -> feature "movie"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/movie/domain/entities/movie_summary.dart';
```

### ARCH-R4 — lib/src/features/search/presentation/pages/provider_all_results_page.dart:21

- **Message**: Interdit: feature "search" -> feature "tv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/tv/domain/entities/tv_show.dart';
```

### ARCH-R5 — lib/src/features/search/presentation/pages/provider_results_page.dart:8

- **Message**: Interdit: accès direct au locator en UI
- **Suggestion**: Passer par providers Riverpod / injection testable.
- **Import**:

```
import 'package:movi/src/core/di/di.dart';
```

### ARCH-R1 — lib/src/features/search/presentation/pages/provider_results_page.dart:23

- **Message**: Interdit: presentation -> data
- **Suggestion**: Dépendre de domain/application et exposer une abstraction.
- **Import**:

```
import 'package:movi/src/features/movie/data/dtos/tmdb_movie_detail_dto.dart';
```

### ARCH-R1 — lib/src/features/search/presentation/pages/provider_results_page.dart:26

- **Message**: Interdit: presentation -> data
- **Suggestion**: Dépendre de domain/application et exposer une abstraction.
- **Import**:

```
import 'package:movi/src/features/tv/data/dtos/tmdb_tv_detail_dto.dart';
```

### ARCH-R1 — lib/src/features/search/presentation/pages/provider_results_page.dart:27

- **Message**: Interdit: presentation -> data
- **Suggestion**: Dépendre de domain/application et exposer une abstraction.
- **Import**:

```
import 'package:movi/src/shared/data/services/tmdb_client.dart';
```

### ARCH-R1 — lib/src/features/search/presentation/pages/provider_results_page.dart:28

- **Message**: Interdit: presentation -> data
- **Suggestion**: Dépendre de domain/application et exposer une abstraction.
- **Import**:

```
import 'package:movi/src/shared/data/services/tmdb_image_resolver.dart';
```

### ARCH-R4 — lib/src/features/search/presentation/pages/search_page.dart:21

- **Message**: Interdit: feature "search" -> feature "saga"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/saga/domain/entities/saga.dart';
```

### ARCH-R5 — lib/src/features/search/presentation/providers/search_history_providers.dart:4

- **Message**: Interdit: accès direct au locator en UI
- **Suggestion**: Passer par providers Riverpod / injection testable.
- **Import**:

```
import 'package:movi/src/core/di/di.dart';
```

### ARCH-R3 — lib/src/features/search/presentation/providers/search_providers.dart:2

- **Message**: Interdit: presentation -> SDK externe (dio)
- **Suggestion**: Isoler le SDK dans core/data (adapter) et exposer une abstraction.
- **Import**:

```
import 'package:dio/dio.dart';
```

### ARCH-R5 — lib/src/features/search/presentation/providers/search_providers.dart:5

- **Message**: Interdit: accès direct au locator en UI
- **Suggestion**: Passer par providers Riverpod / injection testable.
- **Import**:

```
import 'package:movi/src/core/di/di.dart';
```

### ARCH-R4 — lib/src/features/search/presentation/providers/search_providers.dart:9

- **Message**: Interdit: feature "search" -> feature "iptv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/iptv/iptv.dart';
```

### ARCH-R4 — lib/src/features/search/presentation/providers/search_providers.dart:16

- **Message**: Interdit: feature "search" -> feature "saga"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/saga/domain/repositories/saga_repository.dart';
```

### ARCH-R4 — lib/src/features/search/presentation/providers/search_providers.dart:17

- **Message**: Interdit: feature "search" -> feature "saga"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/saga/domain/entities/saga.dart';
```

### ARCH-R1 — lib/src/features/search/presentation/providers/search_providers.dart:19

- **Message**: Interdit: presentation -> data
- **Suggestion**: Dépendre de domain/application et exposer une abstraction.
- **Import**:

```
import 'package:movi/src/features/search/data/datasources/tmdb_watch_providers_remote_data_source.dart';
```

### ARCH-R1 — lib/src/features/search/presentation/providers/search_providers.dart:21

- **Message**: Interdit: presentation -> data
- **Suggestion**: Dépendre de domain/application et exposer une abstraction.
- **Import**:

```
import 'package:movi/src/shared/data/services/tmdb_client.dart';
```

### ARCH-R1 — lib/src/features/search/presentation/providers/search_providers.dart:22

- **Message**: Interdit: presentation -> data
- **Suggestion**: Dépendre de domain/application et exposer une abstraction.
- **Import**:

```
import 'package:movi/src/shared/data/services/tmdb_discovery_cache_data_source.dart';
```

### ARCH-R1 — lib/src/features/search/presentation/providers/search_providers.dart:23

- **Message**: Interdit: presentation -> data
- **Suggestion**: Dépendre de domain/application et exposer une abstraction.
- **Import**:

```
import 'package:movi/src/shared/data/services/tmdb_image_resolver.dart';
```

### ARCH-R4 — lib/src/features/series_tracking/presentation/providers/series_tracking_providers.dart:8

- **Message**: Interdit: feature "series_tracking" -> feature "library"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/library/presentation/providers/library_providers.dart';
```

### ARCH-R4 — lib/src/features/series_tracking/presentation/providers/series_tracking_providers.dart:9

- **Message**: Interdit: feature "series_tracking" -> feature "settings"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/settings/presentation/providers/user_settings_providers.dart';
```

### ARCH-R4 — lib/src/features/series_tracking/presentation/providers/series_tracking_providers.dart:10

- **Message**: Interdit: feature "series_tracking" -> feature "tv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/tv/domain/entities/tv_show.dart';
```

### ARCH-R4 — lib/src/features/series_tracking/presentation/providers/series_tracking_providers.dart:11

- **Message**: Interdit: feature "series_tracking" -> feature "tv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/tv/presentation/providers/tv_detail_providers.dart';
```

### ARCH-R4 — lib/src/features/settings/presentation/pages/iptv_connect_page.dart:13

- **Message**: Interdit: feature "settings" -> feature "welcome"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/welcome/presentation/providers/bootstrap_providers.dart';
```

### ARCH-R4 — lib/src/features/settings/presentation/pages/iptv_connect_page.dart:14

- **Message**: Interdit: feature "settings" -> feature "welcome"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/welcome/presentation/widgets/labeled_field.dart';
```

### ARCH-R4 — lib/src/features/settings/presentation/pages/iptv_connect_page.dart:15

- **Message**: Interdit: feature "settings" -> feature "welcome"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/welcome/presentation/widgets/welcome_header.dart';
```

### ARCH-R4 — lib/src/features/settings/presentation/pages/iptv_network_profiles_page.dart:4

- **Message**: Interdit: feature "settings" -> feature "iptv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/iptv/domain/entities/source_connection_models.dart';
```

### ARCH-R5 — lib/src/features/settings/presentation/pages/iptv_sources_page.dart:12

- **Message**: Interdit: accès direct au locator en UI
- **Suggestion**: Passer par providers Riverpod / injection testable.
- **Import**:

```
import 'package:movi/src/core/di/di.dart';
```

### ARCH-R4 — lib/src/features/settings/presentation/pages/iptv_sources_page.dart:30

- **Message**: Interdit: feature "settings" -> feature "home"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/home/presentation/providers/home_providers.dart'
```

### ARCH-R4 — lib/src/features/settings/presentation/pages/iptv_sources_page.dart:32

- **Message**: Interdit: feature "settings" -> feature "iptv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/iptv/application/usecases/refresh_xtream_catalog.dart';
```

### ARCH-R4 — lib/src/features/settings/presentation/pages/iptv_sources_page.dart:33

- **Message**: Interdit: feature "settings" -> feature "iptv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/iptv/application/usecases/refresh_stalker_catalog.dart';
```

### ARCH-R1 — lib/src/features/settings/presentation/pages/iptv_sources_page.dart:34

- **Message**: Interdit: presentation -> data
- **Suggestion**: Dépendre de domain/application et exposer une abstraction.
- **Import**:

```
import 'package:movi/src/features/iptv/data/datasources/supabase_iptv_sources_repository.dart';
```

### ARCH-R4 — lib/src/features/settings/presentation/pages/iptv_sources_page.dart:37

- **Message**: Interdit: feature "settings" -> feature "welcome"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/welcome/presentation/providers/bootstrap_providers.dart';
```

### ARCH-R5 — lib/src/features/settings/presentation/pages/iptv_source_add_page.dart:6

- **Message**: Interdit: accès direct au locator en UI
- **Suggestion**: Passer par providers Riverpod / injection testable.
- **Import**:

```
import 'package:movi/src/core/di/di.dart';
```

### ARCH-R4 — lib/src/features/settings/presentation/pages/iptv_source_add_page.dart:15

- **Message**: Interdit: feature "settings" -> feature "iptv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/iptv/domain/entities/source_connection_models.dart';
```

### ARCH-R4 — lib/src/features/settings/presentation/pages/iptv_source_add_page.dart:16

- **Message**: Interdit: feature "settings" -> feature "iptv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/iptv/domain/value_objects/xtream_endpoint.dart';
```

### ARCH-R4 — lib/src/features/settings/presentation/pages/iptv_source_add_page.dart:21

- **Message**: Interdit: feature "settings" -> feature "welcome"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/welcome/presentation/providers/bootstrap_providers.dart';
```

### ARCH-R4 — lib/src/features/settings/presentation/pages/iptv_source_edit_page.dart:9

- **Message**: Interdit: feature "settings" -> feature "iptv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/iptv/domain/entities/source_connection_models.dart';
```

### ARCH-R4 — lib/src/features/settings/presentation/pages/iptv_source_organize_page.dart:9

- **Message**: Interdit: feature "settings" -> feature "iptv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist.dart';
```

### ARCH-R5 — lib/src/features/settings/presentation/pages/iptv_source_select_page.dart:9

- **Message**: Interdit: accès direct au locator en UI
- **Suggestion**: Passer par providers Riverpod / injection testable.
- **Import**:

```
import 'package:movi/src/core/di/di.dart';
```

### ARCH-R4 — lib/src/features/settings/presentation/pages/iptv_source_select_page.dart:17

- **Message**: Interdit: feature "settings" -> feature "home"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/home/presentation/providers/home_providers.dart'
```

### ARCH-R4 — lib/src/features/settings/presentation/pages/iptv_source_select_page.dart:19

- **Message**: Interdit: feature "settings" -> feature "iptv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/iptv/application/usecases/refresh_stalker_catalog.dart';
```

### ARCH-R4 — lib/src/features/settings/presentation/pages/iptv_source_select_page.dart:20

- **Message**: Interdit: feature "settings" -> feature "iptv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/iptv/application/usecases/refresh_xtream_catalog.dart';
```

### ARCH-R4 — lib/src/features/settings/presentation/pages/iptv_source_select_page.dart:21

- **Message**: Interdit: feature "settings" -> feature "iptv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/iptv/presentation/widgets/iptv_source_selection_list.dart';
```

### ARCH-R4 — lib/src/features/settings/presentation/pages/iptv_source_select_page.dart:22

- **Message**: Interdit: feature "settings" -> feature "library"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/library/presentation/providers/library_cloud_sync_providers.dart';
```

### ARCH-R5 — lib/src/features/settings/presentation/pages/settings_page.dart:16

- **Message**: Interdit: accès direct au locator en UI
- **Suggestion**: Passer par providers Riverpod / injection testable.
- **Import**:

```
import 'package:movi/src/core/di/di.dart';
```

### ARCH-R4 — lib/src/features/settings/presentation/pages/settings_page.dart:47

- **Message**: Interdit: feature "settings" -> feature "iptv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/iptv/application/services/xtream_sync_service.dart';
```

### ARCH-R4 — lib/src/features/settings/presentation/pages/settings_page.dart:48

- **Message**: Interdit: feature "settings" -> feature "library"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/library/presentation/providers/library_cloud_sync_providers.dart';
```

### ARCH-R4 — lib/src/features/settings/presentation/pages/settings_page.dart:49

- **Message**: Interdit: feature "settings" -> feature "player"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/player/domain/value_objects/preferred_playback_quality.dart';
```

### ARCH-R4 — lib/src/features/settings/presentation/pages/settings_page.dart:50

- **Message**: Interdit: feature "settings" -> feature "player"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/player/domain/utils/language_formatter.dart';
```

### ARCH-R4 — lib/src/features/settings/presentation/pages/settings_page.dart:51

- **Message**: Interdit: feature "settings" -> feature "shell"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/shell/presentation/layouts/app_shell_mobile_layout.dart';
```

### ARCH-R4 — lib/src/features/settings/presentation/pages/settings_subtitles_page.dart:20

- **Message**: Interdit: feature "settings" -> feature "player"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/player/presentation/providers/player_providers.dart';
```

### ARCH-R4 — lib/src/features/settings/presentation/pages/xtream_source_test_page.dart:4

- **Message**: Interdit: feature "settings" -> feature "iptv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/iptv/domain/entities/source_probe_models.dart';
```

### ARCH-R5 — lib/src/features/settings/presentation/providers/iptv_connect_providers.dart:7

- **Message**: Interdit: accès direct au locator en UI
- **Suggestion**: Passer par providers Riverpod / injection testable.
- **Import**:

```
import 'package:movi/src/core/di/di.dart';
```

### ARCH-R1 — lib/src/features/settings/presentation/providers/iptv_connect_providers.dart:10

- **Message**: Interdit: presentation -> data
- **Suggestion**: Dépendre de domain/application et exposer une abstraction.
- **Import**:

```
import 'package:movi/src/features/iptv/data/services/iptv_credentials_edge_service.dart';
```

### ARCH-R1 — lib/src/features/settings/presentation/providers/iptv_connect_providers.dart:11

- **Message**: Interdit: presentation -> data
- **Suggestion**: Dépendre de domain/application et exposer une abstraction.
- **Import**:

```
import 'package:movi/src/features/iptv/data/datasources/supabase_iptv_sources_repository.dart';
```

### ARCH-R4 — lib/src/features/settings/presentation/providers/iptv_connect_providers.dart:15

- **Message**: Interdit: feature "settings" -> feature "iptv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/iptv/application/usecases/add_xtream_source.dart';
```

### ARCH-R4 — lib/src/features/settings/presentation/providers/iptv_connect_providers.dart:16

- **Message**: Interdit: feature "settings" -> feature "iptv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/iptv/application/usecases/add_stalker_source.dart';
```

### ARCH-R4 — lib/src/features/settings/presentation/providers/iptv_connect_providers.dart:17

- **Message**: Interdit: feature "settings" -> feature "iptv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/iptv/application/usecases/refresh_xtream_catalog.dart';
```

### ARCH-R4 — lib/src/features/settings/presentation/providers/iptv_connect_providers.dart:18

- **Message**: Interdit: feature "settings" -> feature "iptv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/iptv/application/usecases/refresh_stalker_catalog.dart';
```

### ARCH-R4 — lib/src/features/settings/presentation/providers/iptv_connect_providers.dart:19

- **Message**: Interdit: feature "settings" -> feature "iptv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/iptv/domain/entities/source_connection_models.dart';
```

### ARCH-R4 — lib/src/features/settings/presentation/providers/iptv_connect_providers.dart:20

- **Message**: Interdit: feature "settings" -> feature "iptv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/iptv/domain/entities/xtream_account.dart';
```

### ARCH-R4 — lib/src/features/settings/presentation/providers/iptv_connect_providers.dart:21

- **Message**: Interdit: feature "settings" -> feature "iptv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/iptv/domain/entities/stalker_account.dart';
```

### ARCH-R5 — lib/src/features/settings/presentation/providers/iptv_network_profile_providers.dart:2

- **Message**: Interdit: accès direct au locator en UI
- **Suggestion**: Passer par providers Riverpod / injection testable.
- **Import**:

```
import 'package:movi/src/core/di/di.dart';
```

### ARCH-R1 — lib/src/features/settings/presentation/providers/iptv_network_profile_providers.dart:3

- **Message**: Interdit: presentation -> data
- **Suggestion**: Dépendre de domain/application et exposer une abstraction.
- **Import**:

```
import 'package:movi/src/features/iptv/data/services/route_profile_credentials_store.dart';
```

### ARCH-R4 — lib/src/features/settings/presentation/providers/iptv_network_profile_providers.dart:4

- **Message**: Interdit: feature "settings" -> feature "iptv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/iptv/domain/entities/source_connection_models.dart';
```

### ARCH-R4 — lib/src/features/settings/presentation/providers/iptv_network_profile_providers.dart:5

- **Message**: Interdit: feature "settings" -> feature "iptv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/iptv/domain/entities/source_probe_models.dart';
```

### ARCH-R4 — lib/src/features/settings/presentation/providers/iptv_network_profile_providers.dart:6

- **Message**: Interdit: feature "settings" -> feature "iptv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/iptv/domain/repositories/route_profile_repository.dart';
```

### ARCH-R4 — lib/src/features/settings/presentation/providers/iptv_network_profile_providers.dart:7

- **Message**: Interdit: feature "settings" -> feature "iptv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/iptv/domain/repositories/source_connection_policy_repository.dart';
```

### ARCH-R4 — lib/src/features/settings/presentation/providers/iptv_network_profile_providers.dart:8

- **Message**: Interdit: feature "settings" -> feature "iptv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/iptv/domain/repositories/source_probe_service.dart';
```

### ARCH-R5 — lib/src/features/settings/presentation/providers/iptv_sources_providers.dart:2

- **Message**: Interdit: accès direct au locator en UI
- **Suggestion**: Passer par providers Riverpod / injection testable.
- **Import**:

```
import 'package:movi/src/core/di/di.dart';
```

### ARCH-R4 — lib/src/features/settings/presentation/providers/iptv_sources_providers.dart:4

- **Message**: Interdit: feature "settings" -> feature "iptv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/iptv/domain/entities/xtream_account.dart';
```

### ARCH-R4 — lib/src/features/settings/presentation/providers/iptv_sources_providers.dart:5

- **Message**: Interdit: feature "settings" -> feature "iptv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/iptv/domain/entities/stalker_account.dart';
```

### ARCH-R4 — lib/src/features/settings/presentation/providers/iptv_sources_providers.dart:6

- **Message**: Interdit: feature "settings" -> feature "iptv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist_item.dart';
```

### ARCH-R5 — lib/src/features/settings/presentation/providers/iptv_source_edit_providers.dart:4

- **Message**: Interdit: accès direct au locator en UI
- **Suggestion**: Passer par providers Riverpod / injection testable.
- **Import**:

```
import 'package:movi/src/core/di/di.dart';
```

### ARCH-R1 — lib/src/features/settings/presentation/providers/iptv_source_edit_providers.dart:10

- **Message**: Interdit: presentation -> data
- **Suggestion**: Dépendre de domain/application et exposer une abstraction.
- **Import**:

```
import 'package:movi/src/features/iptv/data/services/iptv_credentials_edge_service.dart';
```

### ARCH-R1 — lib/src/features/settings/presentation/providers/iptv_source_edit_providers.dart:11

- **Message**: Interdit: presentation -> data
- **Suggestion**: Dépendre de domain/application et exposer une abstraction.
- **Import**:

```
import 'package:movi/src/features/iptv/data/datasources/supabase_iptv_sources_repository.dart';
```

### ARCH-R4 — lib/src/features/settings/presentation/providers/iptv_source_edit_providers.dart:13

- **Message**: Interdit: feature "settings" -> feature "iptv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/iptv/application/usecases/add_xtream_source.dart';
```

### ARCH-R4 — lib/src/features/settings/presentation/providers/iptv_source_edit_providers.dart:14

- **Message**: Interdit: feature "settings" -> feature "iptv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/iptv/application/usecases/refresh_xtream_catalog.dart';
```

### ARCH-R4 — lib/src/features/settings/presentation/providers/iptv_source_edit_providers.dart:15

- **Message**: Interdit: feature "settings" -> feature "iptv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/iptv/domain/entities/source_connection_models.dart';
```

### ARCH-R4 — lib/src/features/settings/presentation/providers/iptv_source_edit_providers.dart:16

- **Message**: Interdit: feature "settings" -> feature "iptv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/iptv/domain/entities/xtream_account.dart';
```

### ARCH-R4 — lib/src/features/settings/presentation/providers/iptv_source_edit_providers.dart:17

- **Message**: Interdit: feature "settings" -> feature "iptv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/iptv/domain/repositories/source_connection_policy_repository.dart';
```

### ARCH-R5 — lib/src/features/settings/presentation/providers/iptv_source_organize_providers.dart:4

- **Message**: Interdit: accès direct au locator en UI
- **Suggestion**: Passer par providers Riverpod / injection testable.
- **Import**:

```
import 'package:movi/src/core/di/di.dart';
```

### ARCH-R4 — lib/src/features/settings/presentation/providers/iptv_source_organize_providers.dart:7

- **Message**: Interdit: feature "settings" -> feature "iptv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist.dart';
```

### ARCH-R4 — lib/src/features/settings/presentation/providers/iptv_source_organize_providers.dart:8

- **Message**: Interdit: feature "settings" -> feature "iptv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist_settings.dart';
```

### ARCH-R5 — lib/src/features/settings/presentation/providers/movi_premium_providers.dart:6

- **Message**: Interdit: accès direct au locator en UI
- **Suggestion**: Passer par providers Riverpod / injection testable.
- **Import**:

```
import 'package:movi/src/core/di/di.dart';
```

### ARCH-R5 — lib/src/features/settings/presentation/providers/user_settings_providers.dart:6

- **Message**: Interdit: accès direct au locator en UI
- **Suggestion**: Passer par providers Riverpod / injection testable.
- **Import**:

```
import 'package:movi/src/core/di/di.dart';
```

### ARCH-R1 — lib/src/features/settings/presentation/services/iptv_source_remote_delete_service.dart:1

- **Message**: Interdit: presentation -> data
- **Suggestion**: Dépendre de domain/application et exposer une abstraction.
- **Import**:

```
import 'package:movi/src/features/iptv/data/datasources/supabase_iptv_sources_repository.dart';
```

### ARCH-R5 — lib/src/features/settings/presentation/widgets/export_diagnostics_sheet.dart:7

- **Message**: Interdit: accès direct au locator en UI
- **Suggestion**: Passer par providers Riverpod / injection testable.
- **Import**:

```
import 'package:movi/src/core/di/di.dart';
```

### ARCH-R4 — lib/src/features/settings/presentation/widgets/xtream_route_policy_form_section.dart:2

- **Message**: Interdit: feature "settings" -> feature "iptv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/iptv/domain/entities/source_connection_models.dart';
```

### ARCH-R4 — lib/src/features/shell/presentation/pages/app_shell_page.dart:21

- **Message**: Interdit: feature "shell" -> feature "welcome"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/welcome/presentation/providers/bootstrap_providers.dart';
```

### ARCH-R4 — lib/src/features/shell/presentation/pages/app_shell_page.dart:24

- **Message**: Interdit: feature "shell" -> feature "home"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/home/presentation/pages/home_page.dart';
```

### ARCH-R4 — lib/src/features/shell/presentation/pages/app_shell_page.dart:25

- **Message**: Interdit: feature "shell" -> feature "search"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/search/presentation/pages/search_page.dart';
```

### ARCH-R4 — lib/src/features/shell/presentation/pages/app_shell_page.dart:26

- **Message**: Interdit: feature "shell" -> feature "library"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/library/presentation/pages/library_page.dart';
```

### ARCH-R4 — lib/src/features/shell/presentation/pages/app_shell_page.dart:27

- **Message**: Interdit: feature "shell" -> feature "settings"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/settings/presentation/pages/settings_page.dart';
```

### ARCH-R4 — lib/src/features/tv/data/services/episode_playback_variant_resolver_impl.dart:5

- **Message**: Interdit: feature "tv" -> feature "iptv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist_item.dart';
```

### ARCH-R4 — lib/src/features/tv/data/services/episode_playback_variant_resolver_impl.dart:6

- **Message**: Interdit: feature "tv" -> feature "player"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/player/domain/entities/playback_variant.dart';
```

### ARCH-R4 — lib/src/features/tv/data/services/episode_playback_variant_resolver_impl.dart:7

- **Message**: Interdit: feature "tv" -> feature "player"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/player/domain/entities/video_source.dart';
```

### ARCH-R4 — lib/src/features/tv/data/services/episode_playback_variant_resolver_impl.dart:8

- **Message**: Interdit: feature "tv" -> feature "player"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/player/domain/services/xtream_stream_url_builder.dart';
```

### ARCH-R4 — lib/src/features/tv/data/tv_data_module.dart:9

- **Message**: Interdit: feature "tv" -> feature "iptv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/iptv/data/services/xtream_stream_url_builder_impl.dart';
```

### ARCH-R4 — lib/src/features/tv/data/tv_data_module.dart:10

- **Message**: Interdit: feature "tv" -> feature "library"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/library/domain/repositories/continue_watching_repository.dart';
```

### ARCH-R4 — lib/src/features/tv/data/tv_data_module.dart:11

- **Message**: Interdit: feature "tv" -> feature "library"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/library/domain/repositories/playback_history_repository.dart';
```

### ARCH-R4 — lib/src/features/tv/data/tv_data_module.dart:12

- **Message**: Interdit: feature "tv" -> feature "movie"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/movie/data/datasources/movie_local_data_source.dart';
```

### ARCH-R4 — lib/src/features/tv/data/tv_data_module.dart:13

- **Message**: Interdit: feature "tv" -> feature "player"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/player/application/services/playback_selection_service.dart';
```

### ARCH-R4 — lib/src/features/tv/data/tv_data_module.dart:14

- **Message**: Interdit: feature "tv" -> feature "player"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/player/domain/services/xtream_stream_url_builder.dart';
```

### ARCH-R4 — lib/src/features/tv/domain/services/episode_playback_variant_resolver.dart:1

- **Message**: Interdit: feature "tv" -> feature "player"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/player/domain/entities/playback_variant.dart';
```

### ARCH-R4 — lib/src/features/tv/domain/usecases/ensure_tv_enrichment.dart:8

- **Message**: Interdit: feature "tv" -> feature "iptv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/iptv/iptv.dart';
```

### ARCH-R2 — lib/src/features/tv/domain/usecases/ensure_tv_enrichment.dart:9

- **Message**: Interdit: domain -> data
- **Suggestion**: Extraire une interface (repository) côté domain, impl côté data.
- **Import**:

```
import 'package:movi/src/features/iptv/data/datasources/xtream_remote_data_source.dart';
```

### ARCH-R4 — lib/src/features/tv/domain/usecases/mark_series_as_seen.dart:3

- **Message**: Interdit: feature "tv" -> feature "library"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/library/domain/repositories/continue_watching_repository.dart';
```

### ARCH-R4 — lib/src/features/tv/domain/usecases/mark_series_as_unseen.dart:2

- **Message**: Interdit: feature "tv" -> feature "library"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/library/domain/repositories/continue_watching_repository.dart';
```

### ARCH-R4 — lib/src/features/tv/domain/usecases/mark_series_as_unseen.dart:3

- **Message**: Interdit: feature "tv" -> feature "library"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/library/domain/repositories/playback_history_repository.dart';
```

### ARCH-R4 — lib/src/features/tv/domain/usecases/resolve_episode_playback_selection.dart:3

- **Message**: Interdit: feature "tv" -> feature "library"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/library/domain/repositories/playback_history_repository.dart';
```

### ARCH-R4 — lib/src/features/tv/domain/usecases/resolve_episode_playback_selection.dart:4

- **Message**: Interdit: feature "tv" -> feature "player"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/player/application/services/playback_selection_service.dart';
```

### ARCH-R4 — lib/src/features/tv/domain/usecases/resolve_episode_playback_selection.dart:5

- **Message**: Interdit: feature "tv" -> feature "player"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/player/domain/entities/playback_launch_plan.dart';
```

### ARCH-R4 — lib/src/features/tv/domain/usecases/resolve_episode_playback_selection.dart:6

- **Message**: Interdit: feature "tv" -> feature "player"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/player/domain/entities/playback_selection_decision.dart';
```

### ARCH-R4 — lib/src/features/tv/domain/usecases/resolve_episode_playback_selection.dart:7

- **Message**: Interdit: feature "tv" -> feature "player"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/player/domain/entities/playback_selection_preferences.dart';
```

### ARCH-R4 — lib/src/features/tv/domain/usecases/resolve_episode_playback_selection.dart:8

- **Message**: Interdit: feature "tv" -> feature "player"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/player/domain/entities/playback_variant.dart';
```

### ARCH-R4 — lib/src/features/tv/domain/usecases/resolve_episode_playback_selection.dart:9

- **Message**: Interdit: feature "tv" -> feature "player"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/player/domain/entities/video_source.dart';
```

### ARCH-R4 — lib/src/features/tv/domain/usecases/resolve_series_playback_target.dart:1

- **Message**: Interdit: feature "tv" -> feature "library"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/library/domain/repositories/playback_history_repository.dart';
```

### ARCH-R4 — lib/src/features/tv/domain/usecases/resolve_series_playback_target.dart:2

- **Message**: Interdit: feature "tv" -> feature "player"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/player/domain/entities/playback_launch_plan.dart';
```

### ARCH-R5 — lib/src/features/tv/presentation/pages/tv_detail_page.dart:23

- **Message**: Interdit: accès direct au locator en UI
- **Suggestion**: Passer par providers Riverpod / injection testable.
- **Import**:

```
import 'package:movi/src/core/di/di.dart';
```

### ARCH-R4 — lib/src/features/tv/presentation/pages/tv_detail_page.dart:34

- **Message**: Interdit: feature "tv" -> feature "iptv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/iptv/domain/entities/xtream_playlist_item.dart';
```

### ARCH-R4 — lib/src/features/tv/presentation/pages/tv_detail_page.dart:35

- **Message**: Interdit: feature "tv" -> feature "player"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/player/domain/entities/playback_selection_decision.dart';
```

### ARCH-R4 — lib/src/features/tv/presentation/pages/tv_detail_page.dart:36

- **Message**: Interdit: feature "tv" -> feature "player"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/player/domain/entities/playback_launch_plan.dart';
```

### ARCH-R4 — lib/src/features/tv/presentation/pages/tv_detail_page.dart:37

- **Message**: Interdit: feature "tv" -> feature "player"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/player/domain/entities/playback_selection_preferences.dart';
```

### ARCH-R4 — lib/src/features/tv/presentation/pages/tv_detail_page.dart:38

- **Message**: Interdit: feature "tv" -> feature "player"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/player/domain/entities/playback_variant.dart';
```

### ARCH-R4 — lib/src/features/tv/presentation/pages/tv_detail_page.dart:39

- **Message**: Interdit: feature "tv" -> feature "player"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/player/domain/entities/video_source.dart';
```

### ARCH-R4 — lib/src/features/tv/presentation/pages/tv_detail_page.dart:40

- **Message**: Interdit: feature "tv" -> feature "player"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/player/domain/value_objects/preferred_playback_quality.dart';
```

### ARCH-R4 — lib/src/features/tv/presentation/pages/tv_detail_page.dart:42

- **Message**: Interdit: feature "tv" -> feature "welcome"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/welcome/presentation/utils/error_presenter.dart';
```

### ARCH-R4 — lib/src/features/tv/presentation/pages/tv_detail_page.dart:43

- **Message**: Interdit: feature "tv" -> feature "home"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/home/presentation/providers/home_providers.dart'
```

### ARCH-R4 — lib/src/features/tv/presentation/pages/tv_detail_page.dart:45

- **Message**: Interdit: feature "tv" -> feature "home"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/home/presentation/widgets/home_layout_constants.dart';
```

### ARCH-R4 — lib/src/features/tv/presentation/pages/tv_detail_page.dart:48

- **Message**: Interdit: feature "tv" -> feature "settings"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/settings/presentation/providers/user_settings_providers.dart';
```

### ARCH-R4 — lib/src/features/tv/presentation/pages/tv_detail_page.dart:49

- **Message**: Interdit: feature "tv" -> feature "library"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/library/presentation/providers/library_providers.dart';
```

### ARCH-R4 — lib/src/features/tv/presentation/pages/tv_detail_page.dart:50

- **Message**: Interdit: feature "tv" -> feature "library"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/library/presentation/widgets/library_playlist_card.dart';
```

### ARCH-R4 — lib/src/features/tv/presentation/pages/tv_detail_page.dart:51

- **Message**: Interdit: feature "tv" -> feature "playlist"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/playlist/playlist.dart';
```

### ARCH-R4 — lib/src/features/tv/presentation/pages/tv_detail_page.dart:63

- **Message**: Interdit: feature "tv" -> feature "series_tracking"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/series_tracking/presentation/providers/series_tracking_providers.dart';
```

### ARCH-R3 — lib/src/features/tv/presentation/providers/tv_detail_providers.dart:4

- **Message**: Interdit: presentation -> SDK externe (get_it)
- **Suggestion**: Isoler le SDK dans core/data (adapter) et exposer une abstraction.
- **Import**:

```
import 'package:get_it/get_it.dart';
```

### ARCH-R5 — lib/src/features/tv/presentation/providers/tv_detail_providers.dart:5

- **Message**: Interdit: accès direct au locator en UI
- **Suggestion**: Passer par providers Riverpod / injection testable.
- **Import**:

```
import 'package:movi/src/core/di/di.dart';
```

### ARCH-R1 — lib/src/features/tv/presentation/providers/tv_detail_providers.dart:11

- **Message**: Interdit: presentation -> data
- **Suggestion**: Dépendre de domain/application et exposer une abstraction.
- **Import**:

```
import 'package:movi/src/features/tv/data/repositories/tv_repository_impl.dart';
```

### ARCH-R1 — lib/src/features/tv/presentation/providers/tv_detail_providers.dart:12

- **Message**: Interdit: presentation -> data
- **Suggestion**: Dépendre de domain/application et exposer une abstraction.
- **Import**:

```
import 'package:movi/src/features/tv/data/datasources/tv_local_data_source.dart';
```

### ARCH-R1 — lib/src/features/tv/presentation/providers/tv_detail_providers.dart:13

- **Message**: Interdit: presentation -> data
- **Suggestion**: Dépendre de domain/application et exposer une abstraction.
- **Import**:

```
import 'package:movi/src/features/tv/data/datasources/tmdb_tv_remote_data_source.dart';
```

### ARCH-R4 — lib/src/features/tv/presentation/providers/tv_detail_providers.dart:15

- **Message**: Interdit: feature "tv" -> feature "player"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/player/domain/entities/playback_launch_plan.dart';
```

### ARCH-R4 — lib/src/features/tv/presentation/providers/tv_detail_providers.dart:17

- **Message**: Interdit: feature "tv" -> feature "iptv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/iptv/iptv.dart';
```

### ARCH-R1 — lib/src/features/tv/presentation/providers/tv_detail_providers.dart:20

- **Message**: Interdit: presentation -> data
- **Suggestion**: Dépendre de domain/application et exposer une abstraction.
- **Import**:

```
import 'package:movi/src/features/iptv/data/datasources/xtream_remote_data_source.dart';
```

### ARCH-R1 — lib/src/features/tv/presentation/providers/tv_detail_providers.dart:24

- **Message**: Interdit: presentation -> data
- **Suggestion**: Dépendre de domain/application et exposer une abstraction.
- **Import**:

```
import 'package:movi/src/shared/data/services/tmdb_cache_data_source.dart';
```

### ARCH-R1 — lib/src/features/tv/presentation/providers/tv_detail_providers.dart:25

- **Message**: Interdit: presentation -> data
- **Suggestion**: Dépendre de domain/application et exposer une abstraction.
- **Import**:

```
import 'package:movi/src/shared/data/services/tmdb_detail_cache_data_source.dart';
```

### ARCH-R1 — lib/src/features/tv/presentation/providers/tv_detail_providers.dart:26

- **Message**: Interdit: presentation -> data
- **Suggestion**: Dépendre de domain/application et exposer une abstraction.
- **Import**:

```
import 'package:movi/src/shared/data/services/tmdb_image_resolver.dart';
```

### ARCH-R4 — lib/src/features/tv/presentation/providers/tv_detail_providers.dart:28

- **Message**: Interdit: feature "tv" -> feature "settings"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/settings/presentation/providers/user_settings_providers.dart';
```

### ARCH-R4 — lib/src/features/tv/presentation/providers/tv_detail_providers.dart:29

- **Message**: Interdit: feature "tv" -> feature "library"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/library/domain/repositories/playback_history_repository.dart';
```

### ARCH-R4 — lib/src/features/tv/presentation/providers/tv_detail_providers.dart:30

- **Message**: Interdit: feature "tv" -> feature "library"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/library/presentation/providers/library_providers.dart';
```

### ARCH-R4 — lib/src/features/tv/presentation/services/episode_playback_page_telemetry.dart:1

- **Message**: Interdit: feature "tv" -> feature "player"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/player/domain/entities/playback_selection_decision.dart';
```

### ARCH-R4 — lib/src/features/tv/presentation/services/episode_playback_page_telemetry.dart:2

- **Message**: Interdit: feature "tv" -> feature "player"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/player/domain/entities/playback_variant.dart';
```

### ARCH-R4 — lib/src/features/tv/presentation/widgets/episode_playback_variant_sheet.dart:3

- **Message**: Interdit: feature "tv" -> feature "player"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/player/domain/entities/playback_variant.dart';
```

### ARCH-R4 — lib/src/features/welcome/presentation/pages/splash_bootstrap_page.dart:9

- **Message**: Interdit: feature "welcome" -> feature "home"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/home/presentation/providers/home_providers.dart';
```

### ARCH-R5 — lib/src/features/welcome/presentation/pages/welcome_source_loading_page.dart:9

- **Message**: Interdit: accès direct au locator en UI
- **Suggestion**: Passer par providers Riverpod / injection testable.
- **Import**:

```
import 'package:movi/src/core/di/di.dart';
```

### ARCH-R4 — lib/src/features/welcome/presentation/pages/welcome_source_loading_page.dart:22

- **Message**: Interdit: feature "welcome" -> feature "iptv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/iptv/application/usecases/refresh_stalker_catalog.dart';
```

### ARCH-R4 — lib/src/features/welcome/presentation/pages/welcome_source_loading_page.dart:23

- **Message**: Interdit: feature "welcome" -> feature "iptv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/iptv/application/usecases/refresh_xtream_catalog.dart';
```

### ARCH-R4 — lib/src/features/welcome/presentation/pages/welcome_source_loading_page.dart:24

- **Message**: Interdit: feature "welcome" -> feature "shell"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/shell/presentation/navigation/shell_destinations.dart';
```

### ARCH-R4 — lib/src/features/welcome/presentation/pages/welcome_source_loading_page.dart:25

- **Message**: Interdit: feature "welcome" -> feature "shell"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/shell/presentation/providers/shell_providers.dart';
```

### ARCH-R5 — lib/src/features/welcome/presentation/pages/welcome_source_page.dart:11

- **Message**: Interdit: accès direct au locator en UI
- **Suggestion**: Passer par providers Riverpod / injection testable.
- **Import**:

```
import 'package:movi/src/core/di/di.dart';
```

### ARCH-R1 — lib/src/features/welcome/presentation/pages/welcome_source_page.dart:24

- **Message**: Interdit: presentation -> data
- **Suggestion**: Dépendre de domain/application et exposer une abstraction.
- **Import**:

```
import 'package:movi/src/features/iptv/data/datasources/supabase_iptv_sources_repository.dart';
```

### ARCH-R1 — lib/src/features/welcome/presentation/pages/welcome_source_page.dart:25

- **Message**: Interdit: presentation -> data
- **Suggestion**: Dépendre de domain/application et exposer une abstraction.
- **Import**:

```
import 'package:movi/src/features/iptv/data/services/iptv_credentials_edge_service.dart';
```

### ARCH-R4 — lib/src/features/welcome/presentation/pages/welcome_source_page.dart:26

- **Message**: Interdit: feature "welcome" -> feature "settings"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/settings/presentation/providers/iptv_connect_providers.dart';
```

### ARCH-R5 — lib/src/features/welcome/presentation/pages/welcome_source_select_page.dart:9

- **Message**: Interdit: accès direct au locator en UI
- **Suggestion**: Passer par providers Riverpod / injection testable.
- **Import**:

```
import 'package:movi/src/core/di/di.dart';
```

### ARCH-R4 — lib/src/features/welcome/presentation/pages/welcome_source_select_page.dart:20

- **Message**: Interdit: feature "welcome" -> feature "library"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/library/presentation/providers/library_cloud_sync_providers.dart';
```

### ARCH-R4 — lib/src/features/welcome/presentation/pages/welcome_source_select_page.dart:21

- **Message**: Interdit: feature "welcome" -> feature "iptv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/iptv/presentation/providers/iptv_accounts_providers.dart';
```

### ARCH-R4 — lib/src/features/welcome/presentation/pages/welcome_source_select_page.dart:22

- **Message**: Interdit: feature "welcome" -> feature "iptv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/iptv/presentation/widgets/iptv_source_selection_list.dart';
```

### ARCH-R4 — lib/src/features/welcome/presentation/pages/welcome_source_select_page.dart:23

- **Message**: Interdit: feature "welcome" -> feature "settings"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/settings/presentation/widgets/settings_content_width.dart';
```

### ARCH-R4 — lib/src/features/welcome/presentation/pages/welcome_user_page.dart:26

- **Message**: Interdit: feature "welcome" -> feature "settings"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/settings/domain/entities/user_settings.dart';
```

### ARCH-R4 — lib/src/features/welcome/presentation/pages/welcome_user_page.dart:27

- **Message**: Interdit: feature "welcome" -> feature "settings"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/settings/domain/value_objects/first_name.dart';
```

### ARCH-R4 — lib/src/features/welcome/presentation/pages/welcome_user_page.dart:28

- **Message**: Interdit: feature "welcome" -> feature "settings"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/settings/domain/value_objects/language_code.dart';
```

### ARCH-R4 — lib/src/features/welcome/presentation/pages/welcome_user_page.dart:29

- **Message**: Interdit: feature "welcome" -> feature "settings"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/settings/presentation/providers/user_settings_providers.dart';
```

### ARCH-R5 — lib/src/features/welcome/presentation/providers/bootstrap_providers.dart:7

- **Message**: Interdit: accès direct au locator en UI
- **Suggestion**: Passer par providers Riverpod / injection testable.
- **Import**:

```
import 'package:movi/src/core/di/di.dart';
```

### ARCH-R1 — lib/src/features/welcome/presentation/providers/bootstrap_providers.dart:17

- **Message**: Interdit: presentation -> data
- **Suggestion**: Dépendre de domain/application et exposer une abstraction.
- **Import**:

```
import 'package:movi/src/features/iptv/data/datasources/supabase_iptv_sources_repository.dart';
```

### ARCH-R3 — lib/src/features/welcome/presentation/providers/welcome_providers.dart:1

- **Message**: Interdit: presentation -> SDK externe (dio)
- **Suggestion**: Isoler le SDK dans core/data (adapter) et exposer une abstraction.
- **Import**:

```
import 'package:dio/dio.dart';
```

### ARCH-R5 — lib/src/features/welcome/presentation/providers/welcome_providers.dart:6

- **Message**: Interdit: accès direct au locator en UI
- **Suggestion**: Passer par providers Riverpod / injection testable.
- **Import**:

```
import 'package:movi/src/core/di/di.dart';
```

### ARCH-R4 — lib/src/features/welcome/presentation/providers/welcome_providers.dart:8

- **Message**: Interdit: feature "welcome" -> feature "iptv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/iptv/iptv.dart';
```

### ARCH-R4 — lib/src/features/welcome/presentation/widgets/welcome_form.dart:12

- **Message**: Interdit: feature "welcome" -> feature "iptv"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/iptv/iptv.dart';
```

### ARCH-R4 — lib/src/features/welcome/presentation/widgets/welcome_form.dart:13

- **Message**: Interdit: feature "welcome" -> feature "settings"
- **Suggestion**: Passer par shared/core ou définir un contrat approuvé explicite.
- **Import**:

```
import 'package:movi/src/features/settings/presentation/providers/iptv_connect_providers.dart';
```

### ARCH-R2 — lib/src/shared/domain/services/enrichment_check_service.dart:1

- **Message**: Interdit: domain -> data
- **Suggestion**: Extraire une interface (repository) côté domain, impl côté data.
- **Import**:

```
import 'package:movi/src/features/movie/data/datasources/movie_local_data_source.dart';
```

### ARCH-R2 — lib/src/shared/domain/services/enrichment_check_service.dart:2

- **Message**: Interdit: domain -> data
- **Suggestion**: Extraire une interface (repository) côté domain, impl côté data.
- **Import**:

```
import 'package:movi/src/features/tv/data/datasources/tv_local_data_source.dart';
```

### ARCH-R2 — lib/src/shared/domain/services/playlist_tmdb_enrichment_service.dart:3

- **Message**: Interdit: domain -> data
- **Suggestion**: Extraire une interface (repository) côté domain, impl côté data.
- **Import**:

```
import 'package:movi/src/shared/data/services/tmdb_image_resolver.dart';
```

### ARCH-R2 — lib/src/shared/domain/services/tmdb_id_resolver_service.dart:4

- **Message**: Interdit: domain -> data
- **Suggestion**: Extraire une interface (repository) côté domain, impl côté data.
- **Import**:

```
import 'package:movi/src/features/movie/data/datasources/tmdb_movie_remote_data_source.dart';
```

### ARCH-R2 — lib/src/shared/domain/services/tmdb_id_resolver_service.dart:5

- **Message**: Interdit: domain -> data
- **Suggestion**: Extraire une interface (repository) côté domain, impl côté data.
- **Import**:

```
import 'package:movi/src/features/movie/data/dtos/tmdb_movie_detail_dto.dart';
```

### ARCH-R2 — lib/src/shared/domain/services/tmdb_id_resolver_service.dart:6

- **Message**: Interdit: domain -> data
- **Suggestion**: Extraire une interface (repository) côté domain, impl côté data.
- **Import**:

```
import 'package:movi/src/features/tv/data/datasources/tmdb_tv_remote_data_source.dart';
```

### ARCH-R2 — lib/src/shared/domain/services/tmdb_id_resolver_service.dart:7

- **Message**: Interdit: domain -> data
- **Suggestion**: Extraire une interface (repository) côté domain, impl côté data.
- **Import**:

```
import 'package:movi/src/features/tv/data/dtos/tmdb_tv_detail_dto.dart';
```

### ARCH-R2 — lib/src/shared/domain/services/tmdb_id_resolver_service.dart:8

- **Message**: Interdit: domain -> data
- **Suggestion**: Extraire une interface (repository) côté domain, impl côté data.
- **Import**:

```
import 'package:movi/src/shared/data/services/tmdb_client.dart';
```

### ARCH-R5 — lib/src/shared/presentation/providers/playback_history_providers.dart:3

- **Message**: Interdit: accès direct au locator en UI
- **Suggestion**: Passer par providers Riverpod / injection testable.
- **Import**:

```
import 'package:movi/src/core/di/di.dart';
```


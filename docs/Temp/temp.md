chissement pour tv.id=316481
[2026-03-31T18:36:53.992818][DEBUG] [enrichment_check] 🔍 [CHECK] Aucun cache trouvé pour seriesId=316481 → MISSING
[2026-03-31T18:36:53.995816][DEBUG] [tv_enrichment] 📺 [ENRICH] Statut enrichissement pour seriesId=316481: EnrichmentStatus.missing
[2026-03-31T18:36:53.996820][DEBUG] [tv_enrichment] 📺 [ENRICH] Données incomplètes (status=EnrichmentStatus.missing) pour seriesId=316481, déclenchement enrich (lite)
[2026-03-31T18:36:53.997814][DEBUG] [tv_enrichment] 📺 [ENRICH] Appel _tvRepository.getShowLite() pour seriesId=316481 (plus rapide, sans saisons)...
[2026-03-31T18:36:53.998815][DEBUG] [tv_repository] 📺 [REPO] _loadShowDtoFull() démarré pour showId=316481        
[2026-03-31T18:36:53.999817][DEBUG] [tv_repository] 📺 [REPO] Vérification cache local pour showId=316481...       
[2026-03-31T18:36:54.052338][DEBUG] [tv_repository] 📺 [REPO] Cache local vérifié pour showId=316481 en 52ms (cached=false)
[2026-03-31T18:36:54.053334][DEBUG] [tv_repository] 📺 [REPO] Aucun cache trouvé pour showId=316481, chargement depuis TMDB
[2026-03-31T18:36:54.054338][DEBUG] [tv_repository] 📺 [REPO] Appel _remote.fetchShowFull() pour showId=316481, language=fr...
[2026-03-31T18:36:54.054338][DEBUG] [tv_repository] 📺 [REPO] Début attente fetchShowFull avec timeout 10s pour showId=316481...
[2026-03-31T18:36:54.058373][DEBUG] [tv_remote] 📺 [REMOTE] fetchShowFull() démarré pour id=316481, language=fr    
[2026-03-31T18:36:54.058373][DEBUG] [tv_remote] 📺 [REMOTE] Appel _client.getJson() pour tv/316481 avec append_to_response...
[2026-03-31T18:36:54.311403][DEBUG] [network] Resource not found (404)
[2026-03-31T18:36:54.313404][DEBUG] [Network] key=****
[2026-03-31T18:36:54.318400][WARN] [tv_repository] 📺 [REPO] Erreur dans _loadShowDtoFull pour showId=316481: NotFoundFailure(Not found, 404)
 -> NotFoundFailure(Not found, 404)
#0      NetworkExecutor.run (package:movi/src/core/network/network_executor.dart:337:11)
<asynchronous suspension>
#1      TmdbClient.getJson (package:movi/src/shared/data/services/tmdb_client.dart:79:22)
<asynchronous suspension>
#2      TmdbTvRemoteDataSource.fetchShowFull (package:movi/src/features/tv/data/datasources/tmdb_tv_remote_data_source.dart:138:18)
<asynchronous suspension>
#3      Future.timeout.<anonymous closure> (dart:async/future_impl.dart:1061:7)
<asynchronous suspension>
#4      TvRepositoryImpl._loadShowDtoFull (package:movi/src/features/tv/data/repositories/tv_repository_impl.dart:301:22)
<asynchronous suspension>
#5      TvRepositoryImpl.getShowLite (package:movi/src/features/tv/data/repositories/tv_repository_impl.dart:125:36)
<asynchronous suspension>
#6      Future.timeout.<anonymous closure> (dart:async/future_impl.dart:1061:7)
<asynchronous suspension>
#7      EnsureTvEnrichment.call (package:movi/src/features/tv/domain/usecases/ensure_tv_enrichment.dart:144:7)     
<asynchronous suspension>
#8      tvDetailEnrichmentProvider.<anonymous closure> (package:movi/src/features/tv/presentation/providers/tv_detail_providers.dart:98:18)
<asynchronous suspension>
#9      ElementWithFuture.handleFuture.<anonymous closure>.<anonymous closure> (package:riverpod/src/core/element.dart:220:9)
<asynchronous suspension>

[2026-03-31T18:36:54.322399][WARN] [tv_enrichment] 📺 [ENRICH] Erreur lors du full enrich pour seriesId=316481: NotFoundFailure(Not found, 404)
 -> NotFoundFailure(Not found, 404)
#0      NetworkExecutor.run (package:movi/src/core/network/network_executor.dart:337:11)
<asynchronous suspension>
#1      TmdbClient.getJson (package:movi/src/shared/data/services/tmdb_client.dart:79:22)
<asynchronous suspension>
#2      TmdbTvRemoteDataSource.fetchShowFull (package:movi/src/features/tv/data/datasources/tmdb_tv_remote_data_source.dart:138:18)
<asynchronous suspension>
#3      Future.timeout.<anonymous closure> (dart:async/future_impl.dart:1061:7)
<asynchronous suspension>
#4      TvRepositoryImpl._loadShowDtoFull (package:movi/src/features/tv/data/repositories/tv_repository_impl.dart:301:22)
<asynchronous suspension>
#5      TvRepositoryImpl.getShowLite (package:movi/src/features/tv/data/repositories/tv_repository_impl.dart:125:36)
<asynchronous suspension>
#6      Future.timeout.<anonymous closure> (dart:async/future_impl.dart:1061:7)
<asynchronous suspension>
#7      EnsureTvEnrichment.call (package:movi/src/features/tv/domain/usecases/ensure_tv_enrichment.dart:144:7)     
<asynchronous suspension>
#8      tvDetailEnrichmentProvider.<anonymous closure> (package:movi/src/features/tv/presentation/providers/tv_detail_providers.dart:98:18)
<asynchronous suspension>
#9      ElementWithFuture.handleFuture.<anonymous closure>.<anonymous closure> (package:riverpod/src/core/element.dart:220:9)
<asynchronous suspension>

[2026-03-31T18:36:54.328398][DEBUG] [tv_enrichment] 📺 [PROVIDER] **** terminé pour seriesId=316481, result=false  
PlatformDispatcherError: DioException [bad response]: This exception was thrown because the response has a status code of 404 and RequestOptions.validateStatus was configured to throw for this status code.
The status code of 404 has the following meaning: "Client error - the request contains bad syntax or cannot be fulfilled"
Read more about status codes at https://developer.mozilla.org/en-US/docs/Web/HTTP/Status
In order to resolve this exception you typically have either to verify and fix your request code or you have to fix the server code.

Stack trace:
#0      DioMixin.fetch (package:dio/src/dio_mixin.dart:523:7)
<asynchronous suspension>
#1      Future.timeout.<anonymous closure> (dart:async/future_impl.dart:1061:7)
<asynchronous suspension>
#2      NetworkExecutor.run (package:movi/src/core/network/network_executor.dart:254:28)
<asynchronous suspension>
#3      TmdbClient.getJson (package:movi/src/shared/data/services/tmdb_client.dart:79:22)
<asynchronous suspension>
#4      TmdbTvRemoteDataSource.fetchShowFull (package:movi/src/features/tv/data/datasources/tmdb_tv_remote_data_source.dart:138:18)
<asynchronous suspension>
#5      Future.timeout.<anonymous closure> (dart:async/future_impl.dart:1061:7)
<asynchronous suspension>
#6      TvRepositoryImpl._loadShowDtoFull (package:movi/src/features/tv/data/repositories/tv_repository_impl.dart:301:22)
<asynchronous suspension>
#7      TvRepositoryImpl.getShowLite (package:movi/src/features/tv/data/repositories/tv_repository_impl.dart:125:36)
<asynchronous suspension>
#8      Future.timeout.<anonymous closure> (dart:async/future_impl.dart:1061:7)
<asynchronous suspension>
#9      EnsureTvEnrichment.call (package:movi/src/features/tv/domain/usecases/ensure_tv_enrichment.dart:144:7)     
<asynchronous suspension>
#10     tvDetailEnrichmentProvider.<anonymous closure> (package:movi/src/features/tv/presentation/providers/tv_detail_providers.dart:98:18)
<asynchronous suspension>
#11     ElementWithFuture.handleFuture.<anonymous closure>.<anonymous closure> (package:riverpod/src/core/element.dart:220:9)
<asynchronous suspension>

[2026-03-31T18:36:54.336649][DEBUG] [navigation] 🟢 [NAV] Enrichissement terminé pour tv.id=316481, needsEnrichment=false
[2026-03-31T18:36:54.352167][DEBUG] [navigation] 🟢 [NAV] Navigation vers page détails tv pour id=316481
[2026-03-31T18:36:54.396166][DEBUG] [tv_repository] 📺 [REPO] _loadShowDtoFull() démarré pour showId=316481
[2026-03-31T18:36:54.396166][DEBUG] [tv_repository] 📺 [REPO] Vérification cache local pour showId=316481...
[2026-03-31T18:36:54.432238][DEBUG] [tv_repository] 📺 [REPO] Cache local vérifié pour showId=316481 en 35ms (cached=false)
[2026-03-31T18:36:54.433405][DEBUG] [tv_repository] 📺 [REPO] Aucun cache trouvé pour showId=316481, chargement depuis TMDB
[2026-03-31T18:36:54.434415][DEBUG] [tv_repository] 📺 [REPO] Appel _remote.fetchShowFull() pour showId=316481, language=fr...
[2026-03-31T18:36:54.434415][DEBUG] [tv_repository] 📺 [REPO] Début attente fetchShowFull avec timeout 10s pour showId=316481...
[2026-03-31T18:36:54.434415][DEBUG] [tv_remote] 📺 [REMOTE] fetchShowFull() démarré pour id=316481, language=fr    
[2026-03-31T18:36:54.435495][DEBUG] [tv_remote] 📺 [REMOTE] Appel _client.getJson() pour tv/316481 avec append_to_response...
[2026-03-31T18:36:54.537876][DEBUG] [network] Resource not found (404)
[2026-03-31T18:36:54.538877][DEBUG] [Network] key=****
[2026-03-31T18:36:54.538877][WARN] [tv_repository] 📺 [REPO] Erreur dans _loadShowDtoFull pour showId=316481: NotFoundFailure(Not found, 404)
 -> NotFoundFailure(Not found, 404)
#0      NetworkExecutor.run (package:movi/src/core/network/network_executor.dart:337:11)
<asynchronous suspension>
#1      TmdbClient.getJson (package:movi/src/shared/data/services/tmdb_client.dart:79:22)
<asynchronous suspension>
#2      TmdbTvRemoteDataSource.fetchShowFull (package:movi/src/features/tv/data/datasources/tmdb_tv_remote_data_source.dart:138:18)
<asynchronous suspension>
#3      Future.timeout.<anonymous closure> (dart:async/future_impl.dart:1061:7)
<asynchronous suspension>
#4      TvRepositoryImpl._loadShowDtoFull (package:movi/src/features/tv/data/repositories/tv_repository_impl.dart:301:22)
<asynchronous suspension>
#5      TvRepositoryImpl.getShowLite (package:movi/src/features/tv/data/repositories/tv_repository_impl.dart:125:36)
<asynchronous suspension>
#6      TvDetailProgressiveController._loadProgressive (package:movi/src/features/tv/presentation/providers/tv_detail_providers.dart:447:32)
<asynchronous suspension>

PlatformDispatcherError: DioException [bad response]: This exception was thrown because the response has a status code of 404 and RequestOptions.validateStatus was configured to throw for this status code.
The status code of 404 has the following meaning: "Client error - the request contains bad syntax or cannot be fulfilled"
Read more about status codes at https://developer.mozilla.org/en-US/docs/Web/HTTP/Status
In order to resolve this exception you typically have either to verify and fix your request code or you have to fix the server code.

Stack trace:
#0      DioMixin.fetch (package:dio/src/dio_mixin.dart:523:7)
<asynchronous suspension>
#1      Future.timeout.<anonymous closure> (dart:async/future_impl.dart:1061:7)
<asynchronous suspension>
#2      NetworkExecutor.run (package:movi/src/core/network/network_executor.dart:254:28)
<asynchronous suspension>
#3      TmdbClient.getJson (package:movi/src/shared/data/services/tmdb_client.dart:79:22)
<asynchronous suspension>
#4      TmdbTvRemoteDataSource.fetchShowFull (package:movi/src/features/tv/data/datasources/tmdb_tv_remote_data_source.dart:138:18)
<asynchronous suspension>
#5      Future.timeout.<anonymous closure> (dart:async/future_impl.dart:1061:7)
<asynchronous suspension>
#6      TvRepositoryImpl._loadShowDtoFull (package:movi/src/features/tv/data/repositories/tv_repository_impl.dart:301:22)
<asynchronous suspension>
#7      TvRepositoryImpl.getShowLite (package:movi/src/features/tv/data/repositories/tv_repository_impl.dart:125:36)
<asynchronous suspension>
#8      TvDetailProgressiveController._loadProgressive (package:movi/src/features/tv/presentation/providers/tv_detail_providers.dart:447:32)
<asynchronous suspension>

[2026-03-31T18:36:54.645917][INFO] [home_hero_debug] [HomeHeroDebug] surface=home_page event=build hasMediaQuery=true mediaWidth=1022.4 mediaHeight=682.4 devicePixelRatio=1.25
[2026-03-31T18:36:54.653282][INFO] [home_hero_debug] [HomeHeroDebug] surface=carousel event=build_state platform=windows items=10 index=0 tmdbId=83533 isWideHero=true heroHeight=500 canRunBackgroundWork=false backgroundWorkSuspended=false
[2026-03-31T18:36:55.177147][INFO] [performance_diagnostics] [PerfDiag] op=home_hero_background_work event=suspended reason=hero_not_visible
[2026-03-31T18:36:55.992991][WARN] [tv_detail] Failed to load TMDB show for id=316481: NotFoundFailure(Not found, 404)
[2026-03-31T18:36:58.040838][DEBUG] [tv_repository] 📺 [REPO] _loadShowDtoFull() démarré pour showId=316481
[2026-03-31T18:36:58.047838][DEBUG] [tv_repository] 📺 [REPO] Vérification cache local pour showId=316481...
[2026-03-31T18:36:58.049835][DEBUG] [tv_repository] 📺 [REPO] Cache local vérifié pour showId=316481 en 1ms (cached=false)
[2026-03-31T18:36:58.049835][DEBUG] [tv_repository] 📺 [REPO] Aucun cache trouvé pour showId=316481, chargement depuis TMDB
[2026-03-31T18:36:58.049835][DEBUG] [tv_repository] 📺 [REPO] Appel _remote.fetchShowFull() pour showId=316481, language=fr...
[2026-03-31T18:36:58.050831][DEBUG] [tv_repository] 📺 [REPO] Début attente fetchShowFull avec timeout 10s pour showId=316481...
[2026-03-31T18:36:58.050831][DEBUG] [tv_remote] 📺 [REMOTE] fetchShowFull() démarré pour id=316481, language=fr    
[2026-03-31T18:36:58.050831][DEBUG] [tv_remote] 📺 [REMOTE] Appel _client.getJson() pour tv/316481 avec append_to_response...
[2026-03-31T18:36:58.149702][DEBUG] [network] Resource not found (404)
[2026-03-31T18:36:58.150715][DEBUG] [Network] key=****
[2026-03-31T18:36:58.152784][WARN] [tv_repository] 📺 [REPO] Erreur dans _loadShowDtoFull pour showId=316481: NotFoundFailure(Not found, 404)
 -> NotFoundFailure(Not found, 404)
#0      NetworkExecutor.run (package:movi/src/core/network/network_executor.dart:337:11)
<asynchronous suspension>
#1      TmdbClient.getJson (package:movi/src/shared/data/services/tmdb_client.dart:79:22)
<asynchronous suspension>
#2      TmdbTvRemoteDataSource.fetchShowFull (package:movi/src/features/tv/data/datasources/tmdb_tv_remote_data_source.dart:138:18)
<asynchronous suspension>
#3      Future.timeout.<anonymous closure> (dart:async/future_impl.dart:1061:7)
<asynchronous suspension>
#4      TvRepositoryImpl._loadShowDtoFull (package:movi/src/features/tv/data/repositories/tv_repository_impl.dart:301:22)
<asynchronous suspension>
#5      TvRepositoryImpl.getShowLite (package:movi/src/features/tv/data/repositories/tv_repository_impl.dart:125:36)
<asynchronous suspension>
#6      TvDetailProgressiveController._loadProgressive (package:movi/src/features/tv/presentation/providers/tv_detail_providers.dart:447:32)
<asynchronous suspension>

PlatformDispatcherError: DioException [bad response]: This exception was thrown because the response has a status code of 404 and RequestOptions.validateStatus was configured to throw for this status code.
The status code of 404 has the following meaning: "Client error - the request contains bad syntax or cannot be fulfilled"
Read more about status codes at https://developer.mozilla.org/en-US/docs/Web/HTTP/Status
In order to resolve this exception you typically have either to verify and fix your request code or you have to fix the server code.

Stack trace:
#0      DioMixin.fetch (package:dio/src/dio_mixin.dart:523:7)
<asynchronous suspension>
#1      Future.timeout.<anonymous closure> (dart:async/future_impl.dart:1061:7)
<asynchronous suspension>
#2      NetworkExecutor.run (package:movi/src/core/network/network_executor.dart:254:28)
<asynchronous suspension>
#3      TmdbClient.getJson (package:movi/src/shared/data/services/tmdb_client.dart:79:22)
<asynchronous suspension>
#4      TmdbTvRemoteDataSource.fetchShowFull (package:movi/src/features/tv/data/datasources/tmdb_tv_remote_data_source.dart:138:18)
<asynchronous suspension>
#5      Future.timeout.<anonymous closure> (dart:async/future_impl.dart:1061:7)
<asynchronous suspension>
#6      TvRepositoryImpl._loadShowDtoFull (package:movi/src/features/tv/data/repositories/tv_repository_impl.dart:301:22)
<asynchronous suspension>
#7      TvRepositoryImpl.getShowLite (package:movi/src/features/tv/data/repositories/tv_repository_impl.dart:125:36)
<asynchronous suspension>
#8      TvDetailProgressiveController._loadProgressive (package:movi/src/features/tv/presentation/providers/tv_detail_providers.dart:447:32)
<asynchronous suspension>

[2026-03-31T18:36:59.045625][WARN] [tv_detail] Failed to load TMDB show for id=316481: NotFoundFailure(Not found, 404)
[2026-03-31T18:37:01.087841][DEBUG] [tv_repository] 📺 [REPO] _loadShowDtoFull() démarré pour showId=316481
[2026-03-31T18:37:01.096762][DEBUG] [tv_repository] 📺 [REPO] Vérification cache local pour showId=316481...
[2026-03-31T18:37:01.104134][DEBUG] [tv_repository] 📺 [REPO] Cache local vérifié pour showId=316481 en 6ms (cached=false)
[2026-03-31T18:37:01.105118][DEBUG] [tv_repository] 📺 [REPO] Aucun cache trouvé pour showId=316481, chargement depuis TMDB
[2026-03-31T18:37:01.105118][DEBUG] [tv_repository] 📺 [REPO] Appel _remote.fetchShowFull() pour showId=316481, language=fr...
[2026-03-31T18:37:01.106057][DEBUG] [tv_repository] 📺 [REPO] Début attente fetchShowFull avec timeout 10s pour showId=316481...
[2026-03-31T18:37:01.107057][DEBUG] [tv_remote] 📺 [REMOTE] fetchShowFull() démarré pour id=316481, language=fr    
[2026-03-31T18:37:01.108058][DEBUG] [tv_remote] 📺 [REMOTE] Appel _client.getJson() pour tv/316481 avec append_to_response...
[2026-03-31T18:37:01.160696][DEBUG] [network] Resource not found (404)
[2026-03-31T18:37:01.161696][DEBUG] [Network] key=****
[2026-03-31T18:37:01.162699][WARN] [tv_repository] 📺 [REPO] Erreur dans _loadShowDtoFull pour showId=316481: NotFoundFailure(Not found, 404)
 -> NotFoundFailure(Not found, 404)
#0      NetworkExecutor.run (package:movi/src/core/network/network_executor.dart:337:11)
<asynchronous suspension>
#1      TmdbClient.getJson (package:movi/src/shared/data/services/tmdb_client.dart:79:22)
<asynchronous suspension>
#2      TmdbTvRemoteDataSource.fetchShowFull (package:movi/src/features/tv/data/datasources/tmdb_tv_remote_data_source.dart:138:18)
<asynchronous suspension>
#3      Future.timeout.<anonymous closure> (dart:async/future_impl.dart:1061:7)
<asynchronous suspension>
#4      TvRepositoryImpl._loadShowDtoFull (package:movi/src/features/tv/data/repositories/tv_repository_impl.dart:301:22)
<asynchronous suspension>
#5      TvRepositoryImpl.getShowLite (package:movi/src/features/tv/data/repositories/tv_repository_impl.dart:125:36)
<asynchronous suspension>
#6      TvDetailProgressiveController._loadProgressive (package:movi/src/features/tv/presentation/providers/tv_detail_providers.dart:447:32)
<asynchronous suspension>

PlatformDispatcherError: DioException [bad response]: This exception was thrown because the response has a status code of 404 and RequestOptions.validateStatus was configured to throw for this status code.
The status code of 404 has the following meaning: "Client error - the request contains bad syntax or cannot be fulfilled"
Read more about status codes at https://developer.mozilla.org/en-US/docs/Web/HTTP/Status
In order to resolve this exception you typically have either to verify and fix your request code or you have to fix the server code.

Stack trace:
#0      DioMixin.fetch (package:dio/src/dio_mixin.dart:523:7)
<asynchronous suspension>
#1      Future.timeout.<anonymous closure> (dart:async/future_impl.dart:1061:7)
<asynchronous suspension>
#2      NetworkExecutor.run (package:movi/src/core/network/network_executor.dart:254:28)
<asynchronous suspension>
#3      TmdbClient.getJson (package:movi/src/shared/data/services/tmdb_client.dart:79:22)
<asynchronous suspension>
#4      TmdbTvRemoteDataSource.fetchShowFull (package:movi/src/features/tv/data/datasources/tmdb_tv_remote_data_source.dart:138:18)
<asynchronous suspension>
#5      Future.timeout.<anonymous closure> (dart:async/future_impl.dart:1061:7)
<asynchronous suspension>
#6      TvRepositoryImpl._loadShowDtoFull (package:movi/src/features/tv/data/repositories/tv_repository_impl.dart:301:22)
<asynchronous suspension>
#7      TvRepositoryImpl.getShowLite (package:movi/src/features/tv/data/repositories/tv_repository_impl.dart:125:36)
<asynchronous suspension>
#8      TvDetailProgressiveController._loadProgressive (package:movi/src/features/tv/presentation/providers/tv_detail_providers.dart:447:32)
<asynchronous suspension>

[2026-03-31T18:37:01.992338][WARN] [tv_detail] Failed to load TMDB show for id=316481: NotFoundFailure(Not found, 404)
[2026-03-31T18:37:04.034274][DEBUG] [tv_repository] 📺 [REPO] _loadShowDtoFull() démarré pour showId=316481
[2026-03-31T18:37:04.048856][DEBUG] [tv_repository] 📺 [REPO] Vérification cache local pour showId=316481...
[2026-03-31T18:37:04.048856][DEBUG] [tv_repository] 📺 [REPO] Cache local vérifié pour showId=316481 en 0ms (cached=false)
[2026-03-31T18:37:04.048856][DEBUG] [tv_repository] 📺 [REPO] Aucun cache trouvé pour showId=316481, chargement depuis TMDB
[2026-03-31T18:37:04.048856][DEBUG] [tv_repository] 📺 [REPO] Appel _remote.fetchShowFull() pour showId=316481, language=fr...
[2026-03-31T18:37:04.048856][DEBUG] [tv_repository] 📺 [REPO] Début attente fetchShowFull avec timeout 10s pour showId=316481...
[2026-03-31T18:37:04.048856][DEBUG] [tv_remote] 📺 [REMOTE] fetchShowFull() démarré pour id=316481, language=fr    
[2026-03-31T18:37:04.048856][DEBUG] [tv_remote] 📺 [REMOTE] Appel _client.getJson() pour tv/316481 avec append_to_response...
[2026-03-31T18:37:04.089358][DEBUG] [network] Resource not found (404)
[2026-03-31T18:37:04.089834][DEBUG] [Network] key=****
[2026-03-31T18:37:04.089834][WARN] [tv_repository] 📺 [REPO] Erreur dans _loadShowDtoFull pour showId=316481: NotFoundFailure(Not found, 404)
 -> NotFoundFailure(Not found, 404)
#0      NetworkExecutor.run (package:movi/src/core/network/network_executor.dart:337:11)
<asynchronous suspension>
#1      TmdbClient.getJson (package:movi/src/shared/data/services/tmdb_client.dart:79:22)
<asynchronous suspension>
#2      TmdbTvRemoteDataSource.fetchShowFull (package:movi/src/features/tv/data/datasources/tmdb_tv_remote_data_source.dart:138:18)
<asynchronous suspension>
#3      Future.timeout.<anonymous closure> (dart:async/future_impl.dart:1061:7)
<asynchronous suspension>
#4      TvRepositoryImpl._loadShowDtoFull (package:movi/src/features/tv/data/repositories/tv_repository_impl.dart:301:22)
<asynchronous suspension>
#5      TvRepositoryImpl.getShowLite (package:movi/src/features/tv/data/repositories/tv_repository_impl.dart:125:36)
<asynchronous suspension>
#6      TvDetailProgressiveController._loadProgressive (package:movi/src/features/tv/presentation/providers/tv_detail_providers.dart:447:32)
<asynchronous suspension>

PlatformDispatcherError: DioException [bad response]: This exception was thrown because the response has a status code of 404 and RequestOptions.validateStatus was configured to throw for this status code.
The status code of 404 has the following meaning: "Client error - the request contains bad syntax or cannot be fulfilled"
Read more about status codes at https://developer.mozilla.org/en-US/docs/Web/HTTP/Status
In order to resolve this exception you typically have either to verify and fix your request code or you have to fix the server code.

Stack trace:
#0      DioMixin.fetch (package:dio/src/dio_mixin.dart:523:7)
<asynchronous suspension>
#1      Future.timeout.<anonymous closure> (dart:async/future_impl.dart:1061:7)
<asynchronous suspension>
#2      NetworkExecutor.run (package:movi/src/core/network/network_executor.dart:254:28)
<asynchronous suspension>
#3      TmdbClient.getJson (package:movi/src/shared/data/services/tmdb_client.dart:79:22)
<asynchronous suspension>
#4      TmdbTvRemoteDataSource.fetchShowFull (package:movi/src/features/tv/data/datasources/tmdb_tv_remote_data_source.dart:138:18)
<asynchronous suspension>
#5      Future.timeout.<anonymous closure> (dart:async/future_impl.dart:1061:7)
<asynchronous suspension>
#6      TvRepositoryImpl._loadShowDtoFull (package:movi/src/features/tv/data/repositories/tv_repository_impl.dart:301:22)
<asynchronous suspension>
#7      TvRepositoryImpl.getShowLite (package:movi/src/features/tv/data/repositories/tv_repository_impl.dart:125:36)
<asynchronous suspension>
#8      TvDetailProgressiveController._loadProgressive (package:movi/src/features/tv/presentation/providers/tv_detail_providers.dart:447:32)
<asynchronous suspension>

[2026-03-31T18:37:04.404306][INFO] [performance_diagnostics] [PerfDiag] op=home_hero_background_work event=resume_deferred reason=app_resumed
[2026-03-31T18:37:04.900948][WARN] [tv_detail] Failed to load TMDB show for id=316481: NotFoundFailure(Not found, 404)
[2026-03-31T18:37:05.710935][INFO] [home_hero_debug] [HomeHeroDebug] surface=home_page event=build hasMediaQuery=true mediaWidth=1022.4 mediaHeight=682.4 devicePixelRatio=1.25
[2026-03-31T18:37:05.723935][INFO] [home_hero_debug] [HomeHeroDebug] surface=carousel event=build_state platform=windows items=10 index=0 tmdbId=83533 isWideHero=true heroHeight=500 canRunBackgroundWork=false backgroundWorkSuspended=true

















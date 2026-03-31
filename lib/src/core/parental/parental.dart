// Public barrel for the parental control module.
//
// It exposes the key domain concepts and the main presentation providers used
// to enforce access rules in UI flows.
export 'domain/entities/age_decision.dart';
export 'domain/entities/parental_session.dart';
export 'domain/entities/parental_content_candidate.dart';
export 'domain/repositories/parental_content_candidate_repository.dart';
export 'domain/services/age_policy.dart';
export 'domain/services/content_rating_warmup_gateway.dart';
export 'domain/services/movie_metadata_resolver.dart';
export 'domain/services/series_metadata_resolver.dart';
export 'domain/services/playlist_maturity_classifier.dart';
export 'domain/value_objects/pegi_rating.dart';
export 'presentation/providers/parental_providers.dart';
export 'presentation/providers/parental_access_providers.dart';

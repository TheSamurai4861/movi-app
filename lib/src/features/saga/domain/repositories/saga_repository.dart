import 'package:movi/src/features/saga/domain/entities/saga.dart';
import 'package:movi/src/shared/domain/value_objects/media_id.dart';

/// Contract for saga operations in the Domain layer.
///
/// Implementations should manage localization and caching at the data layer,
/// ensuring that details are coherent with the current UI language while
/// keeping the Domain free of infrastructure specifics.
abstract class SagaRepository {
  /// Returns a full `Saga` by its identifier.
  Future<Saga> getSaga(SagaId id);
  /// Returns user sagas for a given `userId`.
  ///
  /// Implementations may rely on a generic watchlist until user-scoped
  /// storage is available; this behavior must be documented clearly.
  Future<List<SagaSummary>> getUserSagas(String userId);
  /// Performs a search over sagas by query string.
  Future<List<SagaSummary>> searchSagas(String query);
}

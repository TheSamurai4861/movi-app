import 'package:movi/src/features/movie/domain/services/iptv_availability_service.dart';

class GetMovieAvailabilityOnIptv {
  const GetMovieAvailabilityOnIptv(this._availability);
  final IptvAvailabilityService _availability;
  Future<bool> call(String movieId, {Set<String>? candidateSourceIds}) =>
      _availability.isMovieAvailable(
        movieId,
        candidateSourceIds: candidateSourceIds,
      );
}

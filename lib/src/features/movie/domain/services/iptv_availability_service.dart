abstract class IptvAvailabilityService {
  Future<bool> isMovieAvailable(
    String movieId, {
    Set<String>? candidateSourceIds,
  });
}

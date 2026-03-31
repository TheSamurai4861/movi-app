import 'package:movi/src/core/parental/domain/entities/parental_content_candidate.dart';

/// Port d'accès aux contenus à analyser / préchauffer pour le parental.
///
/// L'application ne doit pas connaître l'origine des contenus
/// (IPTV, local DB, API, etc.).
abstract class ParentalContentCandidateRepository {
  Future<List<ParentalContentCandidate>> listCandidates();
}

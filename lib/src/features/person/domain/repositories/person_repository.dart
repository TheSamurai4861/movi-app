import '../entities/person.dart';
import '../../../../shared/domain/entities/person_summary.dart';
import '../../../../shared/domain/value_objects/media_id.dart';

/// Contrat domain pour les opérations liées aux personnes (acteurs, réalisateurs...).
abstract class PersonRepository {
  /// Fiche détaillée d’une personne.
  Future<Person> getPerson(PersonId id);

  /// Filmographie complète (films/séries associés).
  Future<List<PersonCredit>> getFilmography(PersonId id);

  /// Recherche de personnes par nom/alias.
  Future<List<PersonSummary>> searchPeople(String query);

  /// Liste de personnes mises en avant (trending, populaires...).
  Future<List<PersonSummary>> getFeaturedPeople();
}

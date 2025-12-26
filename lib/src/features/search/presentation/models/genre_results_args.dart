// lib/src/features/search/presentation/models/genre_results_args.dart
import 'package:movi/src/shared/presentation/ui_models/ui_models.dart';

class GenreResultsArgs {
  const GenreResultsArgs({
    required this.genreId,
    required this.genreName,
    required this.type,
  });

  final int genreId;
  final String genreName;
  final MoviMediaType type; // movie ou series
}

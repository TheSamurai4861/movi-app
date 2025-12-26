// lib/src/features/search/presentation/models/search_results_args.dart
enum SearchResultsType { movies, shows }

class SearchResultsPageArgs {
  const SearchResultsPageArgs({required this.query, required this.type});

  final String query;
  final SearchResultsType type;
}

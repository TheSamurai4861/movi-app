// ignore_for_file: deprecated_member_use

class SearchQuery {
  const SearchQuery._(this.raw, {this.tmdbId});

  final String raw;
  final int? tmdbId;

  static final RegExp _tmdbPattern = RegExp(r'^t\d{7,}$');

  static SearchQuery parse(String input) {
    final q = input.trim();
    if (q.length < 3) return const SearchQuery._('');
    if (_tmdbPattern.hasMatch(q)) {
      final id = int.tryParse(q.substring(1));
      return SearchQuery._(q, tmdbId: id);
    }
    return SearchQuery._(q);
  }

  bool get isValid => raw.isNotEmpty;
  bool get isTmdbId => tmdbId != null;
}

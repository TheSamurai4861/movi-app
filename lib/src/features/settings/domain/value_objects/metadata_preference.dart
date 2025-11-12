class MetadataPreference {
  const MetadataPreference._(this.value);

  final String value; // e.g. 'tmdb' | 'none'

  static const allowed = <String>{'tmdb', 'none'};

  static MetadataPreference? tryParse(String input) {
    final v = input.trim().toLowerCase();
    if (!allowed.contains(v)) return null;
    return MetadataPreference._(v);
  }
}

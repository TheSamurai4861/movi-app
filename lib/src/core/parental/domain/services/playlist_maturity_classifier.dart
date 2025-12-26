class PlaylistMaturityClassifier {
  const PlaylistMaturityClassifier({
    this.horrorMinPegi = 16,
  });

  final int horrorMinPegi;

  /// Returns a minimum PEGI required to show the playlist, or null if unrestricted.
  int? requiredPegiForPlaylistTitle(String title) {
    final t = title.trim().toLowerCase();
    if (t.isEmpty) return null;

    final horror = RegExp(
      r'(horreur|horror|slasher|gore|zombie|terror|épouvante|epouvante|thriller)',
      caseSensitive: false,
    );
    if (horror.hasMatch(t)) return horrorMinPegi;

    final porn = RegExp(r'(xxx|porno|porn|adult|18\+)', caseSensitive: false);
    if (porn.hasMatch(t)) return 18;

    return null;
  }
}


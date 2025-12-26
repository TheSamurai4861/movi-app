class SyncCursor {
  const SyncCursor({
    required this.updatedAt,
    required this.id,
  });

  /// Raw `updated_at` value as returned by the backend (UTC preferred).
  ///
  /// Kept as a string to preserve precision (microseconds) and make
  /// cursor comparisons exact when querying `updated_at == cursor.updatedAt`.
  final String updatedAt;
  final String id;

  DateTime get updatedAtUtc => DateTime.parse(updatedAt).toUtc();

  static SyncCursor initial() =>
      const SyncCursor(updatedAt: '1970-01-01T00:00:00.000Z', id: '');
}

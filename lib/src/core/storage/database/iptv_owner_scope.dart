/// Resolves the logical owner attached to persisted IPTV rows.
final class IptvOwnerScope {
  const IptvOwnerScope._();

  static const String localOwnerId = '__device_local__';

  static String normalize(String? ownerId) {
    final normalized = ownerId?.trim();
    if (normalized == null || normalized.isEmpty) {
      return localOwnerId;
    }
    return normalized;
  }
}

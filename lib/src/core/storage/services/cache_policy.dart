class CachePolicy {
  const CachePolicy({required this.ttl});

  final Duration ttl;

  bool isExpired(DateTime updatedAt) =>
      DateTime.now().difference(updatedAt) > ttl;
}

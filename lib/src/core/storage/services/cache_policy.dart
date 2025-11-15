import 'package:clock/clock.dart';

class CachePolicy {
  const CachePolicy({required this.ttl, Clock clock = const Clock()})
    : _clock = clock;

  final Duration ttl;
  final Clock _clock;

  bool isExpired(DateTime updatedAt) =>
      _clock.now().difference(updatedAt) > ttl;
}

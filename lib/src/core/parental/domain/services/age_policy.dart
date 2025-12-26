import 'dart:async';
import 'dart:collection';

import 'package:movi/src/core/parental/domain/entities/age_decision.dart';
import 'package:movi/src/core/parental/domain/repositories/content_rating_repository.dart';
import 'package:movi/src/core/parental/domain/value_objects/pegi_rating.dart';
import 'package:movi/src/core/profile/domain/entities/profile.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';

class AgePolicy {
  const AgePolicy(
    this._repo, {
    this.blockUnknownForKids = true,
    this.defaultKidPegi = PegiRating.pegi12,
    this.preferredRegions = const <String>['BE', 'FR', 'US'],
    this.maxConcurrentFilter = 4,
  });

  final ContentRatingRepository _repo;
  final bool blockUnknownForKids;
  final PegiRating defaultKidPegi;
  final List<String> preferredRegions;
  final int maxConcurrentFilter;

  Future<AgeDecision> evaluate(ContentReference ref, Profile profile) async {
    if (ref.type != ContentType.movie && ref.type != ContentType.series) {
      return AgeDecision.allowed(reason: 'non_media_type');
    }

    final int? tmdbId = int.tryParse(ref.id.trim());
    if (tmdbId == null || tmdbId <= 0) {
      // Treat missing/invalid TMDB ids as "unknown rating".
      //
      // For kid profiles, default to blocked (configurable via [blockUnknownForKids])
      // to avoid letting IPTV items bypass restrictions when they lack `tmdb_id`.
      if (profile.isKid && blockUnknownForKids) {
        final PegiRating? profilePegi = PegiRating.tryParse(profile.pegiLimit) ??
            (profile.isKid ? defaultKidPegi : null);
        return AgeDecision.blocked(
          reason: 'invalid_tmdb_id',
          minAge: null,
          requiredPegi: null,
          profilePegi: profilePegi,
          regionUsed: null,
          rawRating: null,
        );
      }
      return AgeDecision.allowed(reason: 'invalid_tmdb_id_allowed');
    }

    final PegiRating? profilePegi = PegiRating.tryParse(profile.pegiLimit) ??
        (profile.isKid ? defaultKidPegi : null);

    // If the profile has no PEGI restriction, allow (but still return info if we can).
    if (profilePegi == null) {
      final res = await _repo.getMinAge(
        type: ref.type,
        tmdbId: tmdbId,
        preferredRegions: preferredRegions,
      );
      final minAge = res.minAge;
      final required = (minAge == null) ? null : PegiRating.snapFromMinAge(minAge);
      return AgeDecision.allowed(
        reason: 'no_profile_restriction',
        minAge: minAge,
        requiredPegi: required,
        profilePegi: null,
        regionUsed: res.regionUsed,
        rawRating: res.rawRating,
      );
    }

    final res = await _repo.getMinAge(
      type: ref.type,
      tmdbId: tmdbId,
      preferredRegions: preferredRegions,
    );

    final int? minAge = res.minAge;
    if (minAge == null) {
      if (profile.isKid && blockUnknownForKids) {
        return AgeDecision.blocked(
          reason: 'unknown_rating',
          minAge: null,
          requiredPegi: null,
          profilePegi: profilePegi,
          regionUsed: res.regionUsed,
          rawRating: res.rawRating,
        );
      }
      return AgeDecision.allowed(
        reason: 'unknown_rating_allowed',
        minAge: null,
        requiredPegi: null,
        profilePegi: profilePegi,
        regionUsed: res.regionUsed,
        rawRating: res.rawRating,
      );
    }

    final required = PegiRating.snapFromMinAge(minAge);
    final allowed = profilePegi.allows(required);
    if (allowed) {
      return AgeDecision.allowed(
        reason: 'ok',
        minAge: minAge,
        requiredPegi: required,
        profilePegi: profilePegi,
        regionUsed: res.regionUsed,
        rawRating: res.rawRating,
      );
    }

    return AgeDecision.blocked(
      reason: 'too_young',
      minAge: minAge,
      requiredPegi: required,
      profilePegi: profilePegi,
      regionUsed: res.regionUsed,
      rawRating: res.rawRating,
    );
  }

  Future<List<ContentReference>> filterAllowed(
    Iterable<ContentReference> items,
    Profile profile,
  ) async {
    final list = items.toList(growable: false);
    if (list.isEmpty) return const <ContentReference>[];

    final int maxConcurrent = maxConcurrentFilter <= 0 ? 1 : maxConcurrentFilter;
    final semaphore = _Semaphore(maxConcurrent);

    final results = await Future.wait<bool>(
      list.map((item) async {
        await semaphore.acquire();
        try {
          final decision = await evaluate(item, profile);
          return decision.isAllowed;
        } finally {
          semaphore.release();
        }
      }),
      eagerError: false,
    );

    final allowed = <ContentReference>[];
    for (var i = 0; i < list.length; i++) {
      if (results[i]) allowed.add(list[i]);
    }
    return allowed;
  }

  /// Returns up to [limit] allowed items, preserving the original order.
  ///
  /// This is useful for UI previews (ex: Home sections) where we want to
  /// "fill" the section after filtering without evaluating the entire list.
  Future<List<ContentReference>> filterAllowedUpTo(
    Iterable<ContentReference> items,
    Profile profile, {
    required int limit,
  }) async {
    final list = items.toList(growable: false);
    if (list.isEmpty) return const <ContentReference>[];
    if (limit <= 0) return const <ContentReference>[];

    final int maxConcurrent = maxConcurrentFilter <= 0 ? 1 : maxConcurrentFilter;
    final allowed = <ContentReference>[];

    var index = 0;
    while (index < list.length && allowed.length < limit) {
      final end = (index + maxConcurrent) > list.length ? list.length : (index + maxConcurrent);
      final batch = list.sublist(index, end);

      final results = await Future.wait<bool>(
        batch.map((item) async {
          final decision = await evaluate(item, profile);
          return decision.isAllowed;
        }),
        eagerError: false,
      );

      for (var i = 0; i < batch.length; i++) {
        if (results[i]) {
          allowed.add(batch[i]);
          if (allowed.length >= limit) break;
        }
      }

      index = end;
    }

    return allowed;
  }
}

class _Semaphore {
  _Semaphore(this._max) : _available = _max;

  final int _max;
  int _available;
  final Queue<Completer<void>> _waiters = Queue<Completer<void>>();

  Future<void> acquire() {
    if (_available > 0) {
      _available--;
      return Future<void>.value();
    }
    final c = Completer<void>();
    _waiters.addLast(c);
    return c.future;
  }

  void release() {
    if (_waiters.isNotEmpty) {
      _waiters.removeFirst().complete();
      return;
    }
    _available++;
    if (_available > _max) _available = _max;
  }
}

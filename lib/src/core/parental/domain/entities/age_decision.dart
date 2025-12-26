import 'package:equatable/equatable.dart';
import 'package:movi/src/core/parental/domain/value_objects/pegi_rating.dart';

enum AgeDecisionStatus { allowed, blocked }

class AgeDecision extends Equatable {
  const AgeDecision({
    required this.status,
    required this.reason,
    this.minAge,
    this.requiredPegi,
    this.profilePegi,
    this.regionUsed,
    this.rawRating,
  });

  final AgeDecisionStatus status;

  /// Machine-readable reason (ex: 'ok', 'unknown_rating', 'too_young', 'no_profile').
  final String reason;

  /// Parsed minimum age (raw).
  final int? minAge;

  /// Required PEGI bucket computed from [minAge].
  final PegiRating? requiredPegi;

  /// Profile PEGI bucket.
  final PegiRating? profilePegi;

  /// Region used to extract the rating (ex: 'BE', 'FR', 'US').
  final String? regionUsed;

  /// Raw rating string as returned by TMDB (ex: 'PG-13', '16', 'TV-MA').
  final String? rawRating;

  bool get isAllowed => status == AgeDecisionStatus.allowed;

  static AgeDecision allowed({
    String reason = 'ok',
    int? minAge,
    PegiRating? requiredPegi,
    PegiRating? profilePegi,
    String? regionUsed,
    String? rawRating,
  }) {
    return AgeDecision(
      status: AgeDecisionStatus.allowed,
      reason: reason,
      minAge: minAge,
      requiredPegi: requiredPegi,
      profilePegi: profilePegi,
      regionUsed: regionUsed,
      rawRating: rawRating,
    );
  }

  static AgeDecision blocked({
    required String reason,
    int? minAge,
    PegiRating? requiredPegi,
    PegiRating? profilePegi,
    String? regionUsed,
    String? rawRating,
  }) {
    return AgeDecision(
      status: AgeDecisionStatus.blocked,
      reason: reason,
      minAge: minAge,
      requiredPegi: requiredPegi,
      profilePegi: profilePegi,
      regionUsed: regionUsed,
      rawRating: rawRating,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        status,
        reason,
        minAge,
        requiredPegi,
        profilePegi,
        regionUsed,
        rawRating,
      ];
}


import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/core/parental/application/services/parental_session_service.dart';
import 'package:movi/src/core/parental/data/services/profile_pin_edge_service.dart';
import 'package:movi/src/core/parental/domain/entities/age_decision.dart';
import 'package:movi/src/core/profile/domain/entities/profile.dart';
import 'package:movi/src/core/profile/presentation/providers/current_profile_provider.dart';
import 'package:movi/src/shared/domain/value_objects/content_reference.dart';
import 'package:movi/src/shared/domain/value_objects/media_title.dart';
import 'package:movi/src/core/parental/presentation/providers/parental_providers.dart';

final parentalSessionServiceProvider = Provider<ParentalSessionService>((ref) {
  return ref.watch(slProvider)<ParentalSessionService>();
});

final profilePinEdgeServiceProvider = Provider<ProfilePinEdgeService>((ref) {
  return ref.watch(slProvider)<ProfilePinEdgeService>();
});

/// Computes the age decision for a given content for the current selected profile.
///
/// If an unlock session is active for the profile, this returns allowed.
final contentAgeDecisionProvider =
    FutureProvider.family<AgeDecision, ContentReference>((ref, content) async {
  // Only guard TMDB IDs.
  if (content.type != ContentType.movie && content.type != ContentType.series) {
    return AgeDecision.allowed(reason: 'non_media_type');
  }

  final Profile? profile = ref.watch(currentProfileProvider);
  if (profile == null) {
    return AgeDecision.allowed(reason: 'no_profile');
  }

  final sessionSvc = ref.read(parentalSessionServiceProvider);
  if (await sessionSvc.isUnlocked(profile.id)) {
    return AgeDecision.allowed(reason: 'unlocked_session');
  }

  final policy = ref.read(agePolicyProvider);
  return policy.evaluate(content, profile);
});

ContentReference contentRefFromId({
  required ContentType type,
  required String id,
}) {
  return ContentReference(
    id: id,
    type: type,
    title: MediaTitle(id),
  );
}

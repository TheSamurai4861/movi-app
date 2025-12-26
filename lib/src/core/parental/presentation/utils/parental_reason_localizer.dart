import 'package:flutter/material.dart';
import 'package:movi/l10n/app_localizations.dart';

/// Converts technical parental control reason codes to user-friendly localized messages.
///
/// Returns null for allowed reasons (no message needed) or if the reason is unknown.
String? getLocalizedParentalReason(BuildContext context, String? reason) {
  if (reason == null) return null;
  final l10n = AppLocalizations.of(context);
  if (l10n == null) return null;

  switch (reason) {
    case 'too_young':
      return l10n.parentalReasonTooYoung;
    case 'unknown_rating':
      return l10n.parentalReasonUnknownRating;
    case 'invalid_tmdb_id':
      return l10n.parentalReasonInvalidTmdbId;
    default:
      // Other reasons are allowed (ok, non_media_type, no_profile, etc.)
      // or unknown - no message needed
      return null;
  }
}


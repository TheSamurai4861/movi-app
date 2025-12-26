import 'package:flutter/widgets.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/network/network.dart';

/// Traduit un NetworkFailure en message localisé et concis pour l’UI.
String presentFailure(BuildContext context, NetworkFailure f) {
  final l10n = AppLocalizations.of(context)!;
  if (f is TimeoutFailure) return l10n.errorConnectionGeneric;
  if (f is ConnectionFailure) return l10n.errorConnectionGeneric;
  if (f is UnauthorizedFailure) return l10n.errorConnectionFailed('401');
  if (f is ForbiddenFailure) return l10n.errorConnectionFailed('403');
  if (f is NotFoundFailure) return l10n.errorConnectionFailed('404');
  if (f is RateLimitedFailure) return l10n.errorConnectionFailed('429');
  if (f is ServerFailure) {
    final code = (f.statusCode ?? '').toString();
    return l10n.errorConnectionFailed(code);
  }
  if (f is EmptyResponseFailure) return l10n.errorConnectionFailed('Empty');
  if (f is CancelledFailure) return l10n.errorConnectionGeneric;
  return l10n.errorUnknown;
}

String presentFailureL10n(AppLocalizations l10n, NetworkFailure f) {
  if (f is TimeoutFailure) return l10n.errorConnectionGeneric;
  if (f is ConnectionFailure) return l10n.errorConnectionGeneric;
  if (f is UnauthorizedFailure) return l10n.errorConnectionFailed('401');
  if (f is ForbiddenFailure) return l10n.errorConnectionFailed('403');
  if (f is NotFoundFailure) return l10n.errorConnectionFailed('404');
  if (f is RateLimitedFailure) return l10n.errorConnectionFailed('429');
  if (f is ServerFailure) {
    final code = (f.statusCode ?? '').toString();
    return l10n.errorConnectionFailed(code);
  }
  if (f is EmptyResponseFailure) return l10n.errorConnectionFailed('Empty');
  if (f is CancelledFailure) return l10n.errorConnectionGeneric;
  return l10n.errorUnknown;
}

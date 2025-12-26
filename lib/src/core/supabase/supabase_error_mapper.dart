import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:movi/src/core/shared/failure.dart';
import 'package:movi/src/core/network/network_failures.dart';

/// Maps Supabase-specific exceptions to domain-level [Failure]s that can be
/// safely exposed to the UI.
Failure mapSupabaseError(Object error, {StackTrace? stackTrace}) {
  if (error is AuthException) {
    final message = error.message;
    final status = error.statusCode;

    if (status == '401') {
      return const UnauthorizedFailure();
    }
    if (status == '403') {
      return const ForbiddenFailure();
    }

    // Typical RLS / permission denied errors surface as 401/403 with a
    // Postgres error message. We normalise them as a forbidden failure.
    if (message.toLowerCase().contains('permission denied')) {
      return const ForbiddenFailure();
    }

    return ServerFailure(message);
  }

  if (error is PostgrestException) {
    final msg = error.message;

    // RLS / policy violations typically use 401/403 with a "permission denied"
    // message. We map them to [ForbiddenFailure].
    if (msg.toLowerCase().contains('permission denied')) {
      return const ForbiddenFailure();
    }

    return ServerFailure(msg);
  }

  // Fallback: wrap unknown errors in a generic Failure while keeping context.
  return Failure.fromException(
    error,
    stackTrace: stackTrace,
    code: 'SUPABASE_UNKNOWN',
  );
}

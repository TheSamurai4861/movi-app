import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';

import 'package:movi/src/core/di/injector.dart';

// Service locator entry-points shared by the app.
export 'package:movi/src/core/di/injector.dart';

/// Expose GetIt via Riverpod so tests can override dependencies easily.
final slProvider = Provider<GetIt>((_) => sl);

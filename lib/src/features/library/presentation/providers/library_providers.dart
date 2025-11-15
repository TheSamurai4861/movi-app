import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/features/library/domain/repositories/library_repository.dart';

/// Exposes the LibraryRepository to the presentation layer.
final libraryRepositoryProvider = Provider<LibraryRepository>(
  (ref) => ref.watch(slProvider)<LibraryRepository>(),
);

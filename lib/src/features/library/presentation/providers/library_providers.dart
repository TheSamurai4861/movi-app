import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/injector.dart';
import '../../domain/repositories/library_repository.dart';

/// Exposes the LibraryRepository to the presentation layer.
final libraryRepositoryProvider = Provider<LibraryRepository>(
  (ref) => sl<LibraryRepository>(),
);


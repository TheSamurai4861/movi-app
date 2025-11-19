import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:movi/src/core/di/di.dart';
import 'package:movi/src/features/category_browser/domain/repositories/category_repository.dart';

/// Providers d'infrastructure pour exposer les repositories aux features
/// sans coupler directement la présentation au service locator global.

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final locator = ref.watch(slProvider);
  return locator<CategoryRepository>();
});

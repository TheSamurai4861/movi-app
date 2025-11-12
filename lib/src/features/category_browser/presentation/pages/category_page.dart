import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../category_browser/presentation/providers/category_providers.dart';
import '../../../category_browser/presentation/widgets/category_header.dart';
import '../../../category_browser/presentation/widgets/category_grid.dart';
import '../../presentation/models/category_args.dart';
import '../../../../shared/domain/value_objects/content_reference.dart';

class CategoryPage extends ConsumerWidget {
  const CategoryPage({super.key, this.args});

  final CategoryPageArgs? args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = args?.title ?? 'Catégorie';
    final visibleKey = args?.categoryKey;
    final CategoryState categoryState = (visibleKey != null)
        ? ref.watch(categoryControllerProvider(visibleKey))
        : const CategoryState(items: <ContentReference>[]);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          children: [
            CategoryHeader(title: title),
            const SizedBox(height: 32),
            Expanded(child: CategoryGrid(items: categoryState.items)),
          ],
        ),
      ),
    );
  }
}

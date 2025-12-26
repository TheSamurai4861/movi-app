// lib/src/features/home/presentation/pages/home_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/src/core/utils/utils.dart';
import 'package:movi/src/features/home/presentation/widgets/home_content.dart';
import 'package:movi/src/features/home/presentation/widgets/home_desktop_layout.dart';

/// Page Home (onglet) — version “Shell-driven”.
///
/// Avant : HomePage gérait la navigation (tabs Home/Search/Library/Settings)
/// via HomeMobileLayout/HomeDesktopLayout + pages.
/// Maintenant : la navigation est gérée par la feature Shell.
/// HomePage ne rend plus que le contenu de l’onglet "Home".
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ResponsiveLayout(
      // Fallback (si ResponsiveLayout utilise `child` comme défaut)
      child: const HomeContent(key: PageStorageKey('home-tab-content')),

      // Mobile : contenu Home (sans navbar)
      mobile: (context) =>
          const HomeContent(key: PageStorageKey('home-tab-content-mobile')),

      // Tablet/Desktop/TV : contenu optimisé grands écrans
      tablet: (context) => const HomeDesktopContent(
        key: PageStorageKey('home-tab-content-large'),
      ),
      desktop: (context) => const HomeDesktopContent(
        key: PageStorageKey('home-tab-content-large'),
      ),
      tv: (context) => const HomeDesktopContent(
        key: PageStorageKey('home-tab-content-large'),
      ),
    );
  }
}

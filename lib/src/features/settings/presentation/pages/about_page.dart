import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/state/app_state_provider.dart' as asp;
import 'package:movi/src/core/utils/app_assets.dart';
import 'package:movi/src/core/widgets/movi_asset_icon.dart';
import 'package:movi/src/core/widgets/movi_bottom_nav_bar.dart';
import 'package:movi/src/core/widgets/movi_focusable.dart';
import 'package:movi/src/features/settings/presentation/widgets/settings_content_width.dart';

class AboutPage extends ConsumerWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = ref.watch(asp.currentAccentColorProvider);
    final l10n = AppLocalizations.of(context)!;
    final bottomInset =
        MoviBottomNavBar.height + moviNavBarBottomOffset(context) + 16;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: SettingsContentWidth(
          child: ListView(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 24 + bottomInset),
            children: [
              _HeaderBar(
                title: l10n.settingsAboutTitle,
                accent: accent,
                onBack: () => context.pop(),
              ),
              const SizedBox(height: 32),

              // Section Application
              const Text(
                'Application',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Movi',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Version ${const String.fromEnvironment('MOVI_VERSION', defaultValue: '1.0.0')}',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 32),

              // Section Crédits / Attribution
              Text(
                l10n.aboutCreditsSectionTitle,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),

              // Attribution TMDB
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C2C2E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Logo TMDB
                    SizedBox(
                      height: 40,
                      child: SvgPicture.network(
                        'https://www.themoviedb.org/assets/2/v4/logos/v2/blue_short-8e7b30f73a4020692ccca9c88bafe5dcb6f8a62a4c6bc55cd9ba82bb2cd95f6c.svg',
                        height: 40,
                        placeholderBuilder: (context) => const SizedBox(
                          height: 40,
                          width: 120,
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF01B4E4),
                            ),
                          ),
                        ),
                        colorFilter: const ColorFilter.mode(
                          Color(0xFF01B4E4),
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.aboutTmdbDisclaimer,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderBar extends StatelessWidget {
  const _HeaderBar({
    required this.title,
    required this.accent,
    required this.onBack,
  });

  final String title;
  final Color accent;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 35,
              height: 35,
              child: MoviFocusableAction(
                onPressed: onBack,
                semanticLabel: AppLocalizations.of(context)!.semanticsBack,
                builder: (context, state) {
                  return MoviFocusFrame(
                    scale: state.focused ? 1.04 : 1,
                    borderRadius: BorderRadius.circular(999),
                    backgroundColor: state.focused
                        ? Colors.white.withValues(alpha: 0.14)
                        : Colors.transparent,
                    child: const SizedBox(
                      width: 35,
                      height: 35,
                      child: MoviAssetIcon(
                        AppAssets.iconBack,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Center(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

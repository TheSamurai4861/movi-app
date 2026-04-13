import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:movi/l10n/app_localizations.dart';
import 'package:movi/src/core/focus/domain/app_focus_region_id.dart';
import 'package:movi/src/core/focus/domain/focus_region_binding.dart';
import 'package:movi/src/core/focus/presentation/focus_region_scope.dart';
import 'package:movi/src/features/settings/presentation/widgets/settings_content_width.dart';
import 'package:movi/src/core/widgets/movi_subpage_back_title_header.dart';

class AboutPage extends ConsumerStatefulWidget {
  const AboutPage({super.key});

  @override
  ConsumerState<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends ConsumerState<AboutPage> {
  final FocusNode _backFocusNode = FocusNode(debugLabel: 'AboutBack');

  @override
  void dispose() {
    _backFocusNode.dispose();
    super.dispose();
  }

  bool _handleBack(BuildContext context) {
    if (!context.mounted || !context.canPop()) {
      return false;
    }
    context.pop();
    return true;
  }

  KeyEventResult _handleRouteBackKey(KeyEvent event, BuildContext context) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.goBack ||
        event.logicalKey == LogicalKeyboardKey.escape ||
        event.logicalKey == LogicalKeyboardKey.backspace) {
      return _handleBack(context)
          ? KeyEventResult.handled
          : KeyEventResult.ignored;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack(context);
      },
      child: FocusRegionScope(
        regionId: AppFocusRegionId.settingsAboutPrimary,
        binding: FocusRegionBinding(
          resolvePrimaryEntryNode: () => _backFocusNode,
          resolveFallbackEntryNode: () => _backFocusNode,
        ),
        requestFocusOnMount: true,
        handleDirectionalExits: false,
        debugLabel: 'AboutRegion',
        child: Focus(
          canRequestFocus: false,
          onKeyEvent: (_, event) => _handleRouteBackKey(event, context),
          child: Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            body: SafeArea(
              child: SettingsContentWidth(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  children: [
                    MoviSubpageBackTitleHeader(
                      title: l10n.settingsAboutTitle,
                      onBack: () => _handleBack(context),
                      focusNode: _backFocusNode,
                    ),
                const SizedBox(height: 24),
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
                  'Version ${const String.fromEnvironment('MOVI_VERSION', defaultValue: '1.0.3')}',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 32),
                Text(
                  l10n.aboutCreditsSectionTitle,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2C2E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
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
          ),
        ),
      ),
    );
  }
}

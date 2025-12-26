// lib/src/features/welcome/presentation/widgets/welcome_header.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:movi/src/core/utils/app_assets.dart';
import 'package:movi/src/core/state/app_state_provider.dart' as asp;
import 'package:movi/l10n/app_localizations.dart';

class WelcomeHeader extends ConsumerWidget {
  const WelcomeHeader({
    super.key,
    this.title,
    this.subtitle,
  });

  final String? title;
  final String? subtitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final accentColor = ref.watch(asp.currentAccentColorProvider);
    final l10n = AppLocalizations.of(context)!;
    final resolvedTitle = title ?? l10n.welcomeTitle;
    final resolvedSubtitle = subtitle ?? l10n.welcomeSubtitle;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: SvgPicture.asset(
            AppAssets.iconAppLogoSvg,
            width: 100,
            height: 100,
            colorFilter: ColorFilter.mode(accentColor, BlendMode.srcIn),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            resolvedTitle,
            style: t.headlineSmall,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            resolvedSubtitle,
            style: t.bodyLarge,
            textAlign: TextAlign.center,
            softWrap: true,
            maxLines: 3,
            overflow: TextOverflow.visible,
          ),
        ),
      ],
    );
  }
}

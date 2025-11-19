// lib/src/features/welcome/presentation/widgets/welcome_header.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:movi/src/core/utils/app_assets.dart';
import 'package:movi/src/core/state/app_state_provider.dart' as asp;

class WelcomeHeader extends ConsumerWidget {
  const WelcomeHeader({
    super.key,
    this.title = 'Bienvenue !',
    this.subtitle = 'Ajouter votre première source',
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final accentColor = ref.watch(asp.currentAccentColorProvider);

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
            title,
            style: t.headlineSmall,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            subtitle,
            style: t.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

// lib/src/features/welcome/presentation/widgets/welcome_header.dart
import 'package:flutter/material.dart';
import '../../../../core/utils/app_assets.dart'; // <-- importe tes assets

class WelcomeHeader extends StatelessWidget {
  const WelcomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Image.asset(
            AppAssets.iconAppLogo,
            width: 100,
            height: 100,
            fit: BoxFit.contain,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text('Bienvenue !', style: t.headlineSmall, textAlign: TextAlign.center),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Ajouter votre première source',
            style: t.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

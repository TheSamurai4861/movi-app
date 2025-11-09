import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:movi/src/core/utils/app_spacing.dart';

import '../widgets/welcome_header.dart';
import '../widgets/welcome_form.dart';
import '../widgets/welcome_faq_row.dart';

class WelcomePage extends ConsumerWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  WelcomeHeader(),
                  SizedBox(height: AppSpacing.xl),
                  WelcomeForm(),
                  SizedBox(height: AppSpacing.xl),
                  WelcomeFaqRow(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/core/responsive/presentation/extensions/tv_ui_scale_context.dart';
import 'package:movi/src/core/responsive/presentation/widgets/responsive_layout.dart';
import 'package:movi/src/core/state/device_capabilities_provider.dart';
import 'package:movi/src/core/widgets/movi_primary_button.dart';

void main() {
  const defaultVerticalPadding = 24.0;
  const nativeTvVerticalPadding = 6.0;

  Widget buildHarness({
    required bool isTelevisionDevice,
    required Size size,
  }) {
    return ProviderScope(
      overrides: [
        isTelevisionDeviceProvider.overrideWith((ref) => isTelevisionDevice),
      ],
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: size),
          child: ResponsiveLayout(
            child: AppTvUiScaleScope(
              child: MoviPrimaryButton(
                label: 'Action',
                onPressed: () {},
              ),
            ),
          ),
        ),
      ),
    );
  }

  EdgeInsets? readButtonPadding(WidgetTester tester) {
    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    final resolved = button.style?.padding?.resolve(const <WidgetState>{});
    return resolved is EdgeInsets ? resolved : null;
  }

  testWidgets(
    'uses default vertical padding without native television device',
    (tester) async {
      await tester.pumpWidget(
        buildHarness(
          isTelevisionDevice: false,
          size: const Size(1920, 1080),
        ),
      );

      final padding = readButtonPadding(tester);
      expect(padding, isNotNull);
      expect(padding!.top, greaterThan(nativeTvVerticalPadding));
      expect(padding.top, closeTo(defaultVerticalPadding, 8));
    },
  );

  testWidgets(
    'uses compact vertical padding on native television device',
    (tester) async {
      await tester.pumpWidget(
        buildHarness(
          isTelevisionDevice: true,
          size: const Size(1920, 1080),
        ),
      );

      final padding = readButtonPadding(tester);
      expect(padding, isNotNull);
      expect(padding!.top, nativeTvVerticalPadding);
      expect(padding.bottom, nativeTvVerticalPadding);
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );
}

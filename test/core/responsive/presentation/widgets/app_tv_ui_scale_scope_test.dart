import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/core/responsive/presentation/extensions/tv_ui_scale_context.dart';
import 'package:movi/src/core/state/device_capabilities_provider.dart';

void main() {
  const probeKey = Key('tv-ui-scale-probe');

  Widget buildHarness({required bool isTelevisionDevice, required Size size}) {
    return ProviderScope(
      overrides: [
        isTelevisionDeviceProvider.overrideWith((ref) => isTelevisionDevice),
      ],
      child: MediaQuery(
        data: MediaQueryData(size: size, textScaler: TextScaler.linear(1.0)),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: AppTvUiScaleScope(
            child: Builder(
              builder: (context) => Text(
                context.tvUiScale.toStringAsFixed(3),
                key: probeKey,
                textDirection: TextDirection.ltr,
              ),
            ),
          ),
        ),
      ),
    );
  }

  double readScale(WidgetTester tester) {
    final text = tester.widget<Text>(find.byKey(probeKey));
    return double.parse(text.data!);
  }

  testWidgets(
    'clamps tv scale to minimum for small logical tv viewports',
    (tester) async {
      await tester.pumpWidget(
        buildHarness(isTelevisionDevice: true, size: const Size(960, 540)),
      );

      expect(readScale(tester), closeTo(0.85, 1e-12));
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'caps tv scale at one for large logical tv viewports',
    (tester) async {
      await tester.pumpWidget(
        buildHarness(isTelevisionDevice: true, size: const Size(1920, 1080)),
      );

      expect(readScale(tester), closeTo(1.0, 1e-12));
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'keeps default scale for non-tv layouts',
    (tester) async {
      await tester.pumpWidget(
        buildHarness(isTelevisionDevice: false, size: const Size(800, 1280)),
      );

      expect(readScale(tester), closeTo(1.0, 1e-12));
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );
}

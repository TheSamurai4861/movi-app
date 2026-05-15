import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/app.dart';
import 'package:movi/src/core/state/device_capabilities_provider.dart';

void main() {
  const probeKey = Key('text-scale-probe');

  Widget buildHarness({
    required bool isTelevisionDevice,
    required Size size,
    required double rootScale,
  }) {
    return ProviderScope(
      overrides: [
        isTelevisionDeviceProvider.overrideWith((ref) => isTelevisionDevice),
      ],
      child: MediaQuery(
        data: MediaQueryData(size: size, textScaler: TextScaler.linear(rootScale)),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: AppTvTextScaleScope(
            child: Builder(
              builder: (context) => Text(
                'probe',
                key: probeKey,
                textScaler: MediaQuery.textScalerOf(context),
                textDirection: TextDirection.ltr,
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets(
    'forces a neutral text scaler for tv layouts',
    (tester) async {
      await tester.pumpWidget(
        buildHarness(
          isTelevisionDevice: true,
          size: const Size(1280, 720),
          rootScale: 1.4,
        ),
      );

      final text = tester.widget<Text>(find.byKey(probeKey));
      expect(text.textScaler!.scale(1.0), closeTo(1.0, 1e-12));
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'preserves host text scaler for non-tv layouts',
    (tester) async {
      await tester.pumpWidget(
        buildHarness(
          isTelevisionDevice: false,
          size: const Size(800, 1280),
          rootScale: 1.35,
        ),
      );

      final text = tester.widget<Text>(find.byKey(probeKey));
      expect(text.textScaler!.scale(1.0), closeTo(1.35, 1e-12));
    },
    variant: TargetPlatformVariant.only(TargetPlatform.android),
  );

  testWidgets(
    'preserves host text scaler on Windows TV layout without native TV',
    (tester) async {
      await tester.pumpWidget(
        buildHarness(
          isTelevisionDevice: false,
          size: const Size(1920, 1080),
          rootScale: 1.4,
        ),
      );

      final text = tester.widget<Text>(find.byKey(probeKey));
      expect(text.textScaler!.scale(1.0), closeTo(1.4, 1e-12));
    },
    variant: TargetPlatformVariant.only(TargetPlatform.windows),
  );
}

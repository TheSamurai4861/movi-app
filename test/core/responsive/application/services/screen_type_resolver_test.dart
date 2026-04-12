import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/core/responsive/application/services/screen_type_resolver.dart';
import 'package:movi/src/core/responsive/domain/entities/screen_type.dart';

void main() {
  final resolver = ScreenTypeResolver.instance;

  test('classifies a wide Android TV viewport as tv', () {
    expect(
      resolver.resolve(960, 540, platform: TargetPlatform.android),
      ScreenType.tv,
    );
  });

  test('forces windows viewport as tv (native and web-on-windows path)', () {
    expect(
      resolver.resolve(390, 844, platform: TargetPlatform.windows),
      ScreenType.tv,
    );
    expect(
      resolver.resolve(800, 1280, platform: TargetPlatform.windows),
      ScreenType.tv,
    );
    expect(
      resolver.resolve(1440, 900, platform: TargetPlatform.windows),
      ScreenType.tv,
    );
  });

  test('applies tablet orientation rule on Android/iOS only', () {
    expect(
      resolver.resolve(800, 1280, platform: TargetPlatform.android),
      ScreenType.mobile,
    );
    expect(
      resolver.resolve(1280, 800, platform: TargetPlatform.android),
      ScreenType.tv,
    );
    expect(
      resolver.resolve(800, 800, platform: TargetPlatform.iOS),
      ScreenType.mobile,
    );
  });

  test('maps tablet band to desktop on non-mobile non-windows platforms', () {
    expect(
      resolver.resolve(1280, 800, platform: TargetPlatform.macOS),
      ScreenType.desktop,
    );
    expect(
      resolver.resolve(1000, 601, platform: TargetPlatform.linux),
      ScreenType.desktop,
    );
    expect(
      resolver.resolve(601, 1000, platform: TargetPlatform.macOS),
      ScreenType.desktop,
    );
  });

  test('classifies phone viewport as mobile on mobile platforms', () {
    expect(
      resolver.resolve(390, 844, platform: TargetPlatform.android),
      ScreenType.mobile,
    );
    expect(
      resolver.resolve(844, 390, platform: TargetPlatform.iOS),
      ScreenType.mobile,
    );
  });

  test('respects tablet band boundaries (600 < shortestSide <= 900)', () {
    expect(
      resolver.resolve(600, 1000, platform: TargetPlatform.android),
      ScreenType.mobile,
    );
    expect(
      resolver.resolve(1000, 600, platform: TargetPlatform.android),
      ScreenType.mobile,
    );
    expect(
      resolver.resolve(601, 1000, platform: TargetPlatform.android),
      ScreenType.mobile,
    );
    expect(
      resolver.resolve(1000, 601, platform: TargetPlatform.android),
      ScreenType.tv,
    );
    expect(
      resolver.resolve(900, 1200, platform: TargetPlatform.android),
      ScreenType.mobile,
    );
    expect(
      resolver.resolve(1200, 900, platform: TargetPlatform.android),
      ScreenType.tv,
    );
    expect(
      resolver.resolve(901, 1300, platform: TargetPlatform.android),
      ScreenType.desktop,
    );
  });
}

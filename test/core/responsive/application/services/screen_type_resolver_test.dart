import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/core/responsive/application/services/screen_type_resolver.dart';
import 'package:movi/src/core/responsive/domain/entities/screen_type.dart';

void main() {
  final resolver = ScreenTypeResolver.instance;

  test('classifies any native Android TV viewport as tv', () {
    expect(
      resolver.resolve(
        390,
        844,
        platform: TargetPlatform.android,
        isTelevisionDevice: true,
      ),
      ScreenType.tv,
    );
    expect(
      resolver.resolve(
        960,
        540,
        platform: TargetPlatform.android,
        isTelevisionDevice: true,
      ),
      ScreenType.tv,
    );
    expect(
      resolver.resolve(
        1920,
        1080,
        platform: TargetPlatform.android,
        isTelevisionDevice: true,
      ),
      ScreenType.tv,
    );
  });

  test('forces windows viewport as tv', () {
    expect(
      resolver.resolve(
        390,
        844,
        platform: TargetPlatform.windows,
        isTelevisionDevice: false,
      ),
      ScreenType.tv,
    );
    expect(
      resolver.resolve(
        800,
        1280,
        platform: TargetPlatform.windows,
        isTelevisionDevice: false,
      ),
      ScreenType.tv,
    );
    expect(
      resolver.resolve(
        1440,
        900,
        platform: TargetPlatform.windows,
        isTelevisionDevice: false,
      ),
      ScreenType.tv,
    );
  });

  test('classifies non-tv Android phone viewport as mobile', () {
    expect(
      resolver.resolve(
        390,
        844,
        platform: TargetPlatform.android,
        isTelevisionDevice: false,
      ),
      ScreenType.mobile,
    );
    expect(
      resolver.resolve(
        844,
        390,
        platform: TargetPlatform.android,
        isTelevisionDevice: false,
      ),
      ScreenType.mobile,
    );
  });

  test('classifies non-tv Android tablet viewports as tablet', () {
    expect(
      resolver.resolve(
        800,
        1280,
        platform: TargetPlatform.android,
        isTelevisionDevice: false,
      ),
      ScreenType.tablet,
    );
    expect(
      resolver.resolve(
        1280,
        800,
        platform: TargetPlatform.android,
        isTelevisionDevice: false,
      ),
      ScreenType.tablet,
    );
    expect(
      resolver.resolve(
        1200,
        900,
        platform: TargetPlatform.android,
        isTelevisionDevice: false,
      ),
      ScreenType.tablet,
    );
  });

  test('maps tablet band to tablet on non-tv non-windows platforms', () {
    expect(
      resolver.resolve(
        1280,
        800,
        platform: TargetPlatform.macOS,
        isTelevisionDevice: false,
      ),
      ScreenType.tablet,
    );
    expect(
      resolver.resolve(
        1000,
        601,
        platform: TargetPlatform.linux,
        isTelevisionDevice: false,
      ),
      ScreenType.tablet,
    );
  });

  test('classifies desktop-sized non-tv viewports as desktop', () {
    expect(
      resolver.resolve(
        901,
        1300,
        platform: TargetPlatform.android,
        isTelevisionDevice: false,
      ),
      ScreenType.desktop,
    );
    expect(
      resolver.resolve(
        1600,
        1000,
        platform: TargetPlatform.macOS,
        isTelevisionDevice: false,
      ),
      ScreenType.desktop,
    );
  });

  test('respects tablet band boundaries (600 < shortestSide <= 900)', () {
    expect(
      resolver.resolve(
        600,
        1000,
        platform: TargetPlatform.android,
        isTelevisionDevice: false,
      ),
      ScreenType.mobile,
    );
    expect(
      resolver.resolve(
        601,
        1000,
        platform: TargetPlatform.android,
        isTelevisionDevice: false,
      ),
      ScreenType.tablet,
    );
    expect(
      resolver.resolve(
        900,
        1200,
        platform: TargetPlatform.android,
        isTelevisionDevice: false,
      ),
      ScreenType.tablet,
    );
    expect(
      resolver.resolve(
        901,
        1200,
        platform: TargetPlatform.android,
        isTelevisionDevice: false,
      ),
      ScreenType.desktop,
    );
  });
}

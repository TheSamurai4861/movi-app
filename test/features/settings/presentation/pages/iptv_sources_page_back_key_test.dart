import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movi/src/features/settings/presentation/pages/iptv_sources_page.dart';

void main() {
  group('shouldHandleIptvSourcesBackKey', () {
    test('returns false for backspace when text input is focused', () {
      expect(
        shouldHandleIptvSourcesBackKey(
          key: LogicalKeyboardKey.backspace,
          isTextInputFocused: true,
        ),
        isFalse,
      );
    });

    test('returns true for backspace when text input is not focused', () {
      expect(
        shouldHandleIptvSourcesBackKey(
          key: LogicalKeyboardKey.backspace,
          isTextInputFocused: false,
        ),
        isTrue,
      );
    });

    test('returns true for escape key', () {
      expect(
        shouldHandleIptvSourcesBackKey(
          key: LogicalKeyboardKey.escape,
          isTextInputFocused: true,
        ),
        isTrue,
      );
    });

    test('returns true for goBack key', () {
      expect(
        shouldHandleIptvSourcesBackKey(
          key: LogicalKeyboardKey.goBack,
          isTextInputFocused: true,
        ),
        isTrue,
      );
    });

    test('returns false for non-back key', () {
      expect(
        shouldHandleIptvSourcesBackKey(
          key: LogicalKeyboardKey.arrowDown,
          isTextInputFocused: false,
        ),
        isFalse,
      );
    });
  });
}

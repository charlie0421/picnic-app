import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/ui/loading_overlay_advanced.dart';
import 'package:picnic_lib/presentation/widgets/ui/loading_overlay_manager.dart';

void main() {
  group('LoadingOverlayState', () {
    test('default values', () {
      const state = LoadingOverlayState();
      expect(state.isLoading, isFalse);
      expect(state.message, isNull);
      expect(state.customWidget, isNull);
      expect(state.animationType, LoadingAnimationType.fade);
      expect(state.theme, LoadingOverlayTheme.dark);
    });

    test('copyWith', () {
      const state = LoadingOverlayState();
      final updated = state.copyWith(
        isLoading: true,
        message: 'Loading...',
        animationType: LoadingAnimationType.scale,
        theme: LoadingOverlayTheme.blur,
      );
      expect(updated.isLoading, isTrue);
      expect(updated.message, 'Loading...');
      expect(updated.animationType, LoadingAnimationType.scale);
      expect(updated.theme, LoadingOverlayTheme.blur);
    });

    test('copyWith preserves unchanged values', () {
      const state = LoadingOverlayState(
        isLoading: true,
        message: 'Original',
      );
      final updated = state.copyWith(theme: LoadingOverlayTheme.light);
      expect(updated.isLoading, isTrue);
      expect(updated.message, 'Original');
      expect(updated.theme, LoadingOverlayTheme.light);
    });

    test('equality', () {
      const a = LoadingOverlayState(isLoading: true, message: 'test');
      const b = LoadingOverlayState(isLoading: true, message: 'test');
      const c = LoadingOverlayState(isLoading: false, message: 'test');
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });

    test('hashCode matches for equal states', () {
      const a = LoadingOverlayState(isLoading: true, message: 'x');
      const b = LoadingOverlayState(isLoading: true, message: 'x');
      expect(a.hashCode, equals(b.hashCode));
    });
  });

  group('LoadingOverlayManager', () {
    late LoadingOverlayManager manager;

    setUp(() {
      manager = LoadingOverlayManager.instance;
      manager.hideAll();
    });

    test('singleton instance', () {
      final a = LoadingOverlayManager.instance;
      final b = LoadingOverlayManager.instance;
      expect(identical(a, b), isTrue);
    });

    test('showWithKey and isLoadingWithKey', () {
      expect(manager.isLoadingWithKey('test'), isFalse);
      manager.showWithKey(key: 'test', message: 'Loading');
      expect(manager.isLoadingWithKey('test'), isTrue);
    });

    test('hideWithKey', () {
      manager.showWithKey(key: 'test');
      manager.hideWithKey('test');
      expect(manager.isLoadingWithKey('test'), isFalse);
    });

    test('hideAll', () {
      manager.showWithKey(key: 'a');
      manager.showWithKey(key: 'b');
      manager.showWithKey(key: 'c');
      expect(manager.isAnyLoading, isTrue);
      expect(manager.activeKeys.length, 3);
      manager.hideAll();
      expect(manager.isAnyLoading, isFalse);
      expect(manager.activeKeys, isEmpty);
    });

    test('activeKeys returns current keys', () {
      manager.showWithKey(key: 'x');
      manager.showWithKey(key: 'y');
      expect(manager.activeKeys, containsAll(['x', 'y']));
    });

    test('getStateWithKey returns state', () {
      manager.showWithKey(key: 'k', message: 'hello');
      final state = manager.getStateWithKey('k');
      expect(state, isNotNull);
      expect(state!.isLoading, isTrue);
      expect(state.message, 'hello');
    });

    test('getStateWithKey returns null for unknown key', () {
      expect(manager.getStateWithKey('unknown'), isNull);
    });

    test('showWithKey with all parameters', () {
      manager.showWithKey(
        key: 'full',
        message: 'msg',
        animationType: LoadingAnimationType.rotate,
        theme: LoadingOverlayTheme.transparent,
      );
      final state = manager.getStateWithKey('full')!;
      expect(state.animationType, LoadingAnimationType.rotate);
      expect(state.theme, LoadingOverlayTheme.transparent);
    });
  });

  group('LoadingAnimationType', () {
    test('all values exist', () {
      expect(LoadingAnimationType.values.length, 5);
      expect(LoadingAnimationType.values, contains(LoadingAnimationType.fade));
      expect(LoadingAnimationType.values, contains(LoadingAnimationType.scale));
      expect(LoadingAnimationType.values, contains(LoadingAnimationType.slideUp));
      expect(LoadingAnimationType.values, contains(LoadingAnimationType.slideDown));
      expect(LoadingAnimationType.values, contains(LoadingAnimationType.rotate));
    });
  });

  group('LoadingOverlayTheme', () {
    test('all values exist', () {
      expect(LoadingOverlayTheme.values.length, 4);
      expect(LoadingOverlayTheme.values, contains(LoadingOverlayTheme.dark));
      expect(LoadingOverlayTheme.values, contains(LoadingOverlayTheme.light));
      expect(LoadingOverlayTheme.values, contains(LoadingOverlayTheme.transparent));
      expect(LoadingOverlayTheme.values, contains(LoadingOverlayTheme.blur));
    });
  });

  group('LoadingOverlayThemeData', () {
    test('getThemeData returns correct theme for dark', () {
      final data = LoadingOverlayThemeData.getThemeData(LoadingOverlayTheme.dark);
      expect(data.barrierColor, Colors.black54);
      expect(data.progressColor, Colors.white);
      expect(data.textColor, Colors.white);
      expect(data.blurSigma, isNull);
    });

    test('getThemeData returns correct theme for light', () {
      final data = LoadingOverlayThemeData.getThemeData(LoadingOverlayTheme.light);
      expect(data.barrierColor, Colors.white70);
      expect(data.textColor, Colors.black87);
    });

    test('getThemeData returns correct theme for blur', () {
      final data = LoadingOverlayThemeData.getThemeData(LoadingOverlayTheme.blur);
      expect(data.blurSigma, 3.0);
    });

    test('getThemeData returns correct theme for transparent', () {
      final data = LoadingOverlayThemeData.getThemeData(LoadingOverlayTheme.transparent);
      expect(data.barrierColor, Colors.transparent);
    });

    test('themes map has all entries', () {
      expect(LoadingOverlayThemeData.themes.length, 4);
    });
  });

  group('LoadingOverlayPresets', () {
    test('theme presets', () {
      expect(LoadingOverlayPresets.dark, LoadingOverlayTheme.dark);
      expect(LoadingOverlayPresets.light, LoadingOverlayTheme.light);
      expect(LoadingOverlayPresets.transparent, LoadingOverlayTheme.transparent);
      expect(LoadingOverlayPresets.blur, LoadingOverlayTheme.blur);
    });

    test('animation presets', () {
      expect(LoadingOverlayPresets.fadeAnimation, LoadingAnimationType.fade);
      expect(LoadingOverlayPresets.scaleAnimation, LoadingAnimationType.scale);
      expect(LoadingOverlayPresets.slideUpAnimation, LoadingAnimationType.slideUp);
      expect(LoadingOverlayPresets.slideDownAnimation, LoadingAnimationType.slideDown);
      expect(LoadingOverlayPresets.rotateAnimation, LoadingAnimationType.rotate);
    });
  });
}

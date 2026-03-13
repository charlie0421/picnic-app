import 'package:flutter_test/flutter_test.dart';

/// Extended tests for AdPlatform logic patterns covering safelyExecute flow,
/// ad limit response parsing, dispose guard, and performance logging patterns.
void main() {
  group('safelyExecute flow pattern', () {
    Future<void> safelyExecute({
      required Future<bool> Function() checkLogin,
      required Future<bool> Function() checkAdsLimit,
      required Future<void> Function() action,
      required void Function() stopAllAnimations,
      required void Function(dynamic, StackTrace?) handleError,
      bool isMission = false,
    }) async {
      if (!await checkLogin()) return;

      try {
        if (!isMission) {
          final checkResult = await checkAdsLimit();
          if (!checkResult) {
            stopAllAnimations();
            return;
          }
        }
        await action();
      } catch (e, s) {
        stopAllAnimations();
        handleError(e, s);
      }
    }

    test('skips everything when login fails', () async {
      bool actionRan = false;
      bool limitChecked = false;

      await safelyExecute(
        checkLogin: () async => false,
        checkAdsLimit: () async {
          limitChecked = true;
          return true;
        },
        action: () async => actionRan = true,
        stopAllAnimations: () {},
        handleError: (_, __) {},
      );

      expect(actionRan, isFalse);
      expect(limitChecked, isFalse);
    });

    test('stops animations when ads limit exceeded', () async {
      bool animationsStopped = false;
      bool actionRan = false;

      await safelyExecute(
        checkLogin: () async => true,
        checkAdsLimit: () async => false,
        action: () async => actionRan = true,
        stopAllAnimations: () => animationsStopped = true,
        handleError: (_, __) {},
      );

      expect(animationsStopped, isTrue);
      expect(actionRan, isFalse);
    });

    test('runs action when all checks pass', () async {
      bool actionRan = false;

      await safelyExecute(
        checkLogin: () async => true,
        checkAdsLimit: () async => true,
        action: () async => actionRan = true,
        stopAllAnimations: () {},
        handleError: (_, __) {},
      );

      expect(actionRan, isTrue);
    });

    test('skips ads limit for missions', () async {
      bool limitChecked = false;
      bool actionRan = false;

      await safelyExecute(
        checkLogin: () async => true,
        checkAdsLimit: () async {
          limitChecked = true;
          return false;
        },
        action: () async => actionRan = true,
        stopAllAnimations: () {},
        handleError: (_, __) {},
        isMission: true,
      );

      expect(limitChecked, isFalse);
      expect(actionRan, isTrue);
    });

    test('handles action error with stopAllAnimations and handleError',
        () async {
      bool animationsStopped = false;
      dynamic capturedError;

      await safelyExecute(
        checkLogin: () async => true,
        checkAdsLimit: () async => true,
        action: () async => throw Exception('Ad load failed'),
        stopAllAnimations: () => animationsStopped = true,
        handleError: (e, _) => capturedError = e,
      );

      expect(animationsStopped, isTrue);
      expect(capturedError, isA<Exception>());
    });
  });

  group('Ad limit response parsing', () {
    test('parses allowed=true', () {
      final data = <String, dynamic>{'allowed': true};
      expect(data['allowed'] == true, isTrue);
    });

    test('parses allowed=false', () {
      final data = <String, dynamic>{'allowed': false};
      expect(data['allowed'] == true, isFalse);
    });

    test('parses disabled=true blocks even if allowed', () {
      final data = <String, dynamic>{'disabled': true, 'allowed': true};
      final disabled = data['disabled'] == true;
      expect(disabled, isTrue);
    });

    test('parses platform-specific limits', () {
      final data = <String, dynamic>{
        'allowed': false,
        'limits': {
          'admob': {'hourly': 5, 'daily': 20},
          'pangle': {'hourly': 3, 'daily': 15},
        },
      };

      final limitsMap = (data['limits'] as Map?) ?? const {};
      final admobLimits = (limitsMap['admob'] as Map?) ?? const {};
      final pangleLimits = (limitsMap['pangle'] as Map?) ?? const {};

      expect((admobLimits['hourly'] as num?)?.toInt() ?? 10, 5);
      expect((admobLimits['daily'] as num?)?.toInt() ?? 50, 20);
      expect((pangleLimits['hourly'] as num?)?.toInt() ?? 10, 3);
      expect((pangleLimits['daily'] as num?)?.toInt() ?? 50, 15);
    });

    test('defaults limits when platform not in response', () {
      final data = <String, dynamic>{
        'allowed': false,
        'limits': {
          'admob': {'hourly': 5, 'daily': 20},
        },
      };

      final limitsMap = (data['limits'] as Map?) ?? const {};
      final unityLimits = (limitsMap['unity'] as Map?) ?? const {};
      final hourly = (unityLimits['hourly'] as num?)?.toInt() ?? 10;
      final daily = (unityLimits['daily'] as num?)?.toInt() ?? 50;

      expect(hourly, 10);
      expect(daily, 50);
    });

    test('defaults limits when limits key missing entirely', () {
      final data = <String, dynamic>{'allowed': false};

      final limitsMap = (data['limits'] as Map?) ?? const {};
      final platformLimits = (limitsMap['admob'] as Map?) ?? const {};
      final hourly = (platformLimits['hourly'] as num?)?.toInt() ?? 10;
      final daily = (platformLimits['daily'] as num?)?.toInt() ?? 50;

      expect(hourly, 10);
      expect(daily, 50);
    });

    test('parses nextAvailableTime as valid DateTime', () {
      final timeStr = '2024-06-15T14:30:00Z';
      final parsed = DateTime.parse(timeStr).toLocal();
      expect(parsed.year, 2024);
      expect(parsed.month, 6);
      expect(parsed.day, 15);
    });

    test('handles invalid nextAvailableTime gracefully', () {
      DateTime? result;
      try {
        result = DateTime.parse('invalid-date');
      } catch (_) {
        result = null;
      }
      expect(result, isNull);
    });

    test('handles null nextAvailableTime', () {
      final data = <String, dynamic>{'allowed': false};
      final nextAvailableTimeStr = data['nextAvailableTime'] as String?;
      expect(nextAvailableTimeStr, isNull);
    });

    test('null data defaults to empty map', () {
      final Map? rawData = null;
      final data = rawData ?? const {};
      expect(data, isEmpty);
      expect(data['allowed'] == true, isFalse);
    });
  });

  group('Dispose guard pattern', () {
    test('guards multiple methods after dispose', () {
      bool isDisposed = false;
      final actions = <String>[];

      void setLoading(bool loading) {
        if (isDisposed) return;
        actions.add('setLoading:$loading');
      }

      void startButtonAnimation() {
        if (isDisposed) return;
        actions.add('startAnimation');
      }

      void stopButtonAnimation() {
        if (isDisposed) return;
        actions.add('stopAnimation');
      }

      setLoading(true);
      startButtonAnimation();
      expect(actions, ['setLoading:true', 'startAnimation']);

      isDisposed = true;
      setLoading(false);
      stopButtonAnimation();
      expect(actions.length, 2); // No new actions after dispose
    });
  });

  group('Performance stopwatch pattern', () {
    test('measures and resets correctly', () {
      final stopwatch = Stopwatch();

      stopwatch.reset();
      stopwatch.start();
      // small computation
      var x = 0;
      for (var i = 0; i < 100; i++) x += i;
      stopwatch.stop();

      final elapsed1 = stopwatch.elapsedMilliseconds;
      expect(elapsed1, greaterThanOrEqualTo(0));

      stopwatch.reset();
      expect(stopwatch.elapsedMilliseconds, 0);
      expect(x, greaterThan(0));
    });
  });

  group('Logging utility format pattern', () {
    test('formats log message with tag', () {
      const id = 'admob';
      const tag = 'init';
      const message = 'initialized';

      final formatted = '[$id:$tag] $message';
      expect(formatted, '[admob:init] initialized');
    });

    test('formats log message without tag', () {
      const id = 'admob';
      String? tag;
      const message = 'initialized';

      final formatted = '[$id${tag != null ? ':$tag' : ''}] $message';
      expect(formatted, '[admob] initialized');
    });
  });
}

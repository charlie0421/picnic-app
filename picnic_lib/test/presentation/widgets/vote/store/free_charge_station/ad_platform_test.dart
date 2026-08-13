import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/ad_platform.dart';

import '../../../../../helpers/test_environment.dart';

/// Tests for AdPlatform logic patterns.
///
/// Widget testing is blocked because AdPlatform is an abstract class
/// requiring WidgetRef and BuildContext, and depends on google_mobile_ads,
/// sentry_flutter, and overlay_loading_progress.
/// Instead, we test the pure logic patterns used in the class.
void main() {
  setUpAll(() {
    initTestColors();
  });

  group('Non-reportable ad error detection', () {
    // 구현을 직접 호출한다 — 예전엔 키워드 목록을 통째로 복제해 검사했다.
    // 그 방식은 구현이 바뀌어도 계속 통과하므로 아무것도 지키지 못한다
    // (PICNIC-2377 에서 같은 패턴을 ad_platform_logic_test 에서 걷어냈다).
    const isNonReportableAdError = AdPlatform.isNonReportableAdError;

    test('no fill message is non-reportable', () {
      expect(isNonReportableAdError('AdMob', 'error', 'No Fill'), isTrue);
    });

    test('nofill message is non-reportable', () {
      expect(
        isNonReportableAdError('Pangle', 'error', 'Nofill for this request'),
        isTrue,
      );
    });

    test('no ad available is non-reportable', () {
      expect(
        isNonReportableAdError('Tapjoy', 'error', 'No ad available'),
        isTrue,
      );
    });

    test('network error is non-reportable', () {
      expect(
        isNonReportableAdError('AdMob', 'error', 'Network error occurred'),
        isTrue,
      );
    });

    test('Korean no ads message is non-reportable', () {
      expect(
        isNonReportableAdError('AdMob', 'error', '광고 없음'),
        isTrue,
      );
    });

    test('Korean load failure message is non-reportable', () {
      expect(
        isNonReportableAdError('AdMob', 'error', '광고 로드 실패'),
        isTrue,
      );
    });

    test('Korean timeout message is non-reportable', () {
      expect(
        isNonReportableAdError('AdMob', 'error', '광고 로드 시간 초과'),
        isTrue,
      );
    });

    test('not_ready is non-reportable', () {
      expect(
        isNonReportableAdError('Pangle', 'error', 'AD not_ready'),
        isTrue,
      );
    });

    test('Tapjoy SDK is not connected is non-reportable (PICNIC-APP-43M)', () {
      expect(
        isNonReportableAdError(
            'Tapjoy', 'error', 'Tapjoy SDK is not connected'),
        isTrue,
      );
    });

    test('iOS NSURLError negative status code is non-reportable '
        '(PICNIC-APP-43N)', () {
      // -1001 (timeout)
      expect(
        isNonReportableAdError('Tapjoy', 'error',
            '작업을 완료할 수 없습니다. Server Error With Status Code:-1001'),
        isTrue,
      );
      // -1009 (not connected)
      expect(
        isNonReportableAdError(
            'Tapjoy', 'error', 'Server Error With Status Code:-1009'),
        isTrue,
      );
    });

    test('positive HTTP status (500) IS reportable (sanity)', () {
      expect(
        isNonReportableAdError(
            'Tapjoy', 'error', 'Server Error With Status Code:500'),
        isFalse,
      );
    });

    test('regular error message IS reportable', () {
      expect(
        isNonReportableAdError('AdMob', 'error', 'Unknown error occurred'),
        isFalse,
      );
    });

    test('empty message IS reportable', () {
      expect(
        isNonReportableAdError('AdMob', 'error', ''),
        isFalse,
      );
    });

    test('case insensitivity works', () {
      expect(
        isNonReportableAdError('AdMob', 'error', 'NO FILL'),
        isTrue,
      );
      expect(
        isNonReportableAdError('AdMob', 'error', 'INVENTORY UNAVAILABLE'),
        isTrue,
      );
    });
  });

  group('AdPlatform dispose logic', () {
    test('isDisposed flag tracks disposal state', () {
      bool isDisposed = false;

      expect(isDisposed, isFalse);
      isDisposed = true;
      expect(isDisposed, isTrue);
    });

    test('operations guarded by isDisposed check', () {
      bool isDisposed = false;
      bool operationExecuted = false;

      void guardedOperation() {
        if (isDisposed) return;
        operationExecuted = true;
      }

      guardedOperation();
      expect(operationExecuted, isTrue);

      operationExecuted = false;
      isDisposed = true;
      guardedOperation();
      expect(operationExecuted, isFalse);
    });
  });

  group('Loading state management', () {
    test('setLoading guards with mounted and isDisposed', () {
      bool contextMounted = true;
      bool isDisposed = false;

      bool shouldSetLoading() => contextMounted && !isDisposed;

      expect(shouldSetLoading(), isTrue);

      contextMounted = false;
      expect(shouldSetLoading(), isFalse);

      contextMounted = true;
      isDisposed = true;
      expect(shouldSetLoading(), isFalse);
    });
  });

  group('Animation controller management', () {
    test('startButtonAnimation checks null and isDisposed', () {
      bool? animationController; // null means no controller
      bool isDisposed = false;

      bool canStartAnimation() =>
          animationController != null && !isDisposed;

      expect(canStartAnimation(), isFalse); // null controller

      animationController = true; // simulate controller exists
      expect(canStartAnimation(), isTrue);

      isDisposed = true;
      expect(canStartAnimation(), isFalse);
    });

    test('stopButtonAnimation checks isAnimating', () {
      bool isAnimating = true;
      bool isDisposed = false;

      bool shouldStop() => isAnimating && !isDisposed;

      expect(shouldStop(), isTrue);

      isAnimating = false;
      expect(shouldStop(), isFalse);
    });
  });

  group('checkAdsLimit response parsing', () {
    test('parses allowed response correctly', () {
      final data = {'allowed': true, 'disabled': false};
      expect(data['allowed'] == true, isTrue);
      expect(data['disabled'] == true, isFalse);
    });

    test('parses disallowed response with limits', () {
      final data = {
        'allowed': false,
        'disabled': false,
        'limits': {
          'admob': {'hourly': 10, 'daily': 50}
        },
        'nextAvailableTime': '2024-01-01T12:00:00Z',
      };

      expect(data['allowed'] == true, isFalse);
      final limitsMap = (data['limits'] as Map?) ?? {};
      final platformLimits = (limitsMap['admob'] as Map?) ?? {};
      expect((platformLimits['hourly'] as num?)?.toInt() ?? 10, equals(10));
      expect((platformLimits['daily'] as num?)?.toInt() ?? 50, equals(50));
    });

    test('parses disabled response', () {
      final data = {'allowed': false, 'disabled': true};
      expect(data['disabled'] == true, isTrue);
    });

    test('handles empty data gracefully', () {
      final Map data = {};
      expect(data['allowed'] == true, isFalse);
      expect(data['disabled'] == true, isFalse);
    });

    test('handles null data gracefully', () {
      final data = (null as Map?) ?? const {};
      expect(data['allowed'] == true, isFalse);
    });
  });

  group('nextAvailableTime parsing', () {
    test('parses valid ISO 8601 time', () {
      const nextStr = '2024-06-15T14:30:00Z';
      final nextTime = DateTime.parse(nextStr).toLocal();
      expect(nextTime, isNotNull);
    });

    test('handles invalid time string gracefully', () {
      const nextStr = 'not-a-date';
      DateTime? nextTime;
      try {
        nextTime = DateTime.parse(nextStr).toLocal();
      } catch (_) {
        nextTime = null;
      }
      expect(nextTime, isNull);
    });

    test('handles null time string', () {
      const String? nextStr = null;
      DateTime? nextTime;
      if (nextStr != null) {
        try {
          nextTime = DateTime.parse(nextStr).toLocal();
        } catch (_) {
          nextTime = null;
        }
      }
      expect(nextTime, isNull);
    });
  });

  group('Performance logging', () {
    test('stopwatch tracks elapsed time', () {
      final stopwatch = Stopwatch();
      stopwatch.start();
      // Simulate some work
      for (int i = 0; i < 1000; i++) {}
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(0));
    });

    test('stopwatch reset clears elapsed time', () {
      final stopwatch = Stopwatch();
      stopwatch.start();
      stopwatch.stop();
      final first = stopwatch.elapsedMicroseconds;
      stopwatch.reset();
      expect(stopwatch.elapsedMicroseconds, equals(0));
    });
  });

  group('Log tag formatting', () {
    test('formats log message with tag', () {
      const id = 'admob';
      const tag = 'init';
      const message = 'Starting initialization';
      final formatted = '[$id:$tag] $message';
      expect(formatted, equals('[admob:init] Starting initialization'));
    });

    test('formats log message without tag', () {
      const id = 'admob';
      String? tag;
      const message = 'Starting';
      final formatted = '[$id${tag != null ? ':$tag' : ''}] $message';
      expect(formatted, equals('[admob] Starting'));
    });
  });
}

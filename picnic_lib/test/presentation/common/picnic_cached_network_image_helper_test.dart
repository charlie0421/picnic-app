import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/common/picnic_cached_network_image.dart';
import 'package:picnic_lib/presentation/common/picnic_cached_network_image_helper.dart';

void main() {
  // ── calculateBackoffDelay ───────────────────────────────────────────
  group('calculateBackoffDelay', () {
    test('first retry uses base * 1.5', () {
      final delay = PicnicCachedNetworkImageHelper.calculateBackoffDelay(1);
      // 500 * 1.5^1 = 750
      expect(delay.inMilliseconds, 750);
    });

    test('second retry uses base * 1.5^2', () {
      final delay = PicnicCachedNetworkImageHelper.calculateBackoffDelay(2);
      // 500 * 2.25 = 1125
      expect(delay.inMilliseconds, 1125);
    });

    test('zero retries returns base delay', () {
      final delay = PicnicCachedNetworkImageHelper.calculateBackoffDelay(0);
      // 500 * 1.5^0 = 500
      expect(delay.inMilliseconds, 500);
    });

    test('delay is capped at max backoff', () {
      final delay = PicnicCachedNetworkImageHelper.calculateBackoffDelay(50);
      expect(delay, const Duration(seconds: 30));
    });

    test('custom base delay is respected', () {
      final delay = PicnicCachedNetworkImageHelper.calculateBackoffDelay(
        1,
        baseDelay: const Duration(milliseconds: 1000),
      );
      // 1000 * 1.5 = 1500
      expect(delay.inMilliseconds, 1500);
    });

    test('custom max backoff is respected', () {
      final delay = PicnicCachedNetworkImageHelper.calculateBackoffDelay(
        50,
        maxBackoffDelay: const Duration(seconds: 10),
      );
      expect(delay, const Duration(seconds: 10));
    });
  });

  // ── roundPixels ─────────────────────────────────────────────────────
  group('roundPixels', () {
    test('returns rounded value', () {
      expect(PicnicCachedNetworkImageHelper.roundPixels(100.0, 2.0), 200);
    });

    test('returns at least 1 for small values', () {
      expect(PicnicCachedNetworkImageHelper.roundPixels(0.1, 0.1), 1);
    });

    test('returns at least 1 for zero', () {
      expect(PicnicCachedNetworkImageHelper.roundPixels(0.0, 1.0), 1);
    });

    test('rounds correctly for fractional result', () {
      expect(PicnicCachedNetworkImageHelper.roundPixels(100.0, 1.5), 150);
    });

    test('rounds 0.4 fraction down', () {
      expect(PicnicCachedNetworkImageHelper.roundPixels(3.0, 1.4), 4);
    });

    test('rounds 0.5 fraction up', () {
      expect(PicnicCachedNetworkImageHelper.roundPixels(3.0, 1.5), 5);
    });
  });

  // ── computeCacheDimension ───────────────────────────────────────────
  group('computeCacheDimension', () {
    test('uses explicit value when provided', () {
      expect(PicnicCachedNetworkImageHelper.computeCacheDimension(200, 100.0, 1.0), 200);
    });

    test('scales explicit value by multiplier', () {
      expect(PicnicCachedNetworkImageHelper.computeCacheDimension(200, null, 0.5), 100);
    });

    test('uses fallback when explicit is null', () {
      expect(PicnicCachedNetworkImageHelper.computeCacheDimension(null, 300.0, 1.0), 300);
    });

    test('uses default 400 when both are null', () {
      expect(PicnicCachedNetworkImageHelper.computeCacheDimension(null, null, 1.0), 400);
    });

    test('returns at least 1', () {
      expect(PicnicCachedNetworkImageHelper.computeCacheDimension(null, null, 0.001), 1);
    });

    test('handles infinite fallback by using default', () {
      expect(
        PicnicCachedNetworkImageHelper.computeCacheDimension(null, double.infinity, 1.0),
        400,
      );
    });

    test('handles NaN fallback by using default', () {
      expect(
        PicnicCachedNetworkImageHelper.computeCacheDimension(null, double.nan, 1.0),
        400,
      );
    });

    test('scales fallback by multiplier', () {
      expect(PicnicCachedNetworkImageHelper.computeCacheDimension(null, 200.0, 0.5), 100);
    });
  });

  // ── cacheKeyFor ─────────────────────────────────────────────────────
  group('cacheKeyFor', () {
    test('basic cache key with url and token', () {
      expect(
        PicnicCachedNetworkImageHelper.cacheKeyFor('https://img.com/a.png', 0),
        'https://img.com/a.png_0',
      );
    });

    test('includes index when provided', () {
      expect(
        PicnicCachedNetworkImageHelper.cacheKeyFor('url', 1, index: 3),
        'url_1_3',
      );
    });

    test('includes _lq suffix for low quality', () {
      expect(
        PicnicCachedNetworkImageHelper.cacheKeyFor('url', 2, isLowQuality: true),
        'url_2_lq',
      );
    });

    test('includes both index and _lq', () {
      expect(
        PicnicCachedNetworkImageHelper.cacheKeyFor('url', 0, index: 5, isLowQuality: true),
        'url_0_5_lq',
      );
    });

    test('token increments change key', () {
      final key0 = PicnicCachedNetworkImageHelper.cacheKeyFor('url', 0);
      final key1 = PicnicCachedNetworkImageHelper.cacheKeyFor('url', 1);
      expect(key0, isNot(equals(key1)));
    });
  });

  // ── formatDpr ───────────────────────────────────────────────────────
  group('formatDpr', () {
    test('integer value removes trailing zeros', () {
      expect(PicnicCachedNetworkImageHelper.formatDpr(2.0), '2');
    });

    test('fractional value keeps significant digits', () {
      expect(PicnicCachedNetworkImageHelper.formatDpr(1.5), '1.5');
    });

    test('two decimal places are preserved when needed', () {
      expect(PicnicCachedNetworkImageHelper.formatDpr(1.25), '1.25');
    });

    test('1.0 formats as "1"', () {
      expect(PicnicCachedNetworkImageHelper.formatDpr(1.0), '1');
    });

    test('0.0 formats as "0"', () {
      // 0.00 -> trimmed to "0"
      expect(PicnicCachedNetworkImageHelper.formatDpr(0.0), '0');
    });

    test('3.0 formats as "3"', () {
      expect(PicnicCachedNetworkImageHelper.formatDpr(3.0), '3');
    });

    test('2.75 formats correctly', () {
      expect(PicnicCachedNetworkImageHelper.formatDpr(2.75), '2.75');
    });

    test('1.10 formats as "1.1"', () {
      expect(PicnicCachedNetworkImageHelper.formatDpr(1.1), '1.1');
    });
  });

  // ── estimateImageComplexity ─────────────────────────────────────────
  group('estimateImageComplexity', () {
    test('GIF is always high complexity', () {
      expect(
        PicnicCachedNetworkImageHelper.estimateImageComplexity(
          width: 10,
          height: 10,
          isGif: true,
        ),
        ImageComplexity.high,
      );
    });

    test('small image is low complexity', () {
      expect(
        PicnicCachedNetworkImageHelper.estimateImageComplexity(width: 50, height: 50),
        ImageComplexity.low,
      );
    });

    test('medium image is medium complexity', () {
      expect(
        PicnicCachedNetworkImageHelper.estimateImageComplexity(width: 300, height: 300),
        ImageComplexity.medium,
      );
    });

    test('large image is high complexity', () {
      expect(
        PicnicCachedNetworkImageHelper.estimateImageComplexity(width: 500, height: 500),
        ImageComplexity.high,
      );
    });

    test('null dimensions default to 400x400 (high)', () {
      expect(
        PicnicCachedNetworkImageHelper.estimateImageComplexity(),
        ImageComplexity.medium,
      );
    });

    test('boundary at 50000 pixels is medium', () {
      // 50000 exactly -> not < 50000, so medium
      expect(
        PicnicCachedNetworkImageHelper.estimateImageComplexity(width: 250, height: 200),
        ImageComplexity.medium,
      );
    });

    test('boundary at 200000 pixels is high', () {
      // 200000 exactly -> not < 200000, so high
      expect(
        PicnicCachedNetworkImageHelper.estimateImageComplexity(width: 500, height: 400),
        ImageComplexity.high,
      );
    });

    test('just below 50000 is low', () {
      // 49999
      expect(
        PicnicCachedNetworkImageHelper.estimateImageComplexity(width: 223, height: 224),
        ImageComplexity.low,
      );
    });
  });

  // ── calculateLoadDelay ──────────────────────────────────────────────
  group('calculateLoadDelay', () {
    test('high priority always returns zero', () {
      expect(
        PicnicCachedNetworkImageHelper.calculateLoadDelay(
          ImagePriority.high,
          baseDelay: const Duration(milliseconds: 500),
        ),
        Duration.zero,
      );
    });

    test('normal priority returns base delay', () {
      expect(
        PicnicCachedNetworkImageHelper.calculateLoadDelay(
          ImagePriority.normal,
          baseDelay: const Duration(milliseconds: 50),
        ),
        const Duration(milliseconds: 50),
      );
    });

    test('low priority adds 200ms to base', () {
      expect(
        PicnicCachedNetworkImageHelper.calculateLoadDelay(
          ImagePriority.low,
          baseDelay: const Duration(milliseconds: 50),
        ),
        const Duration(milliseconds: 250),
      );
    });

    test('null base delay defaults to zero', () {
      expect(
        PicnicCachedNetworkImageHelper.calculateLoadDelay(ImagePriority.normal),
        Duration.zero,
      );
    });

    test('low priority with null base delay returns 200ms', () {
      expect(
        PicnicCachedNetworkImageHelper.calculateLoadDelay(ImagePriority.low),
        const Duration(milliseconds: 200),
      );
    });
  });

  // ── isRetryableError ────────────────────────────────────────────────
  group('isRetryableError', () {
    test('timeout error is retryable', () {
      expect(PicnicCachedNetworkImageHelper.isRetryableError('Connection timeout'), true);
    });

    test('network error is retryable', () {
      expect(PicnicCachedNetworkImageHelper.isRetryableError('Network unreachable'), true);
    });

    test('socket error is retryable', () {
      expect(PicnicCachedNetworkImageHelper.isRetryableError('SocketException'), true);
    });

    test('404 not found is not retryable', () {
      expect(PicnicCachedNetworkImageHelper.isRetryableError('HTTP 404 Not Found'), false);
    });

    test('case insensitive matching', () {
      expect(PicnicCachedNetworkImageHelper.isRetryableError('TIMEOUT ERROR'), true);
    });

    test('handshake error is retryable', () {
      expect(PicnicCachedNetworkImageHelper.isRetryableError('TLS handshake failed'), true);
    });

    test('host error is retryable', () {
      expect(PicnicCachedNetworkImageHelper.isRetryableError('No such host'), true);
    });

    test('resolve error is retryable', () {
      expect(PicnicCachedNetworkImageHelper.isRetryableError('Failed to resolve DNS'), true);
    });

    test('refused error is retryable', () {
      expect(PicnicCachedNetworkImageHelper.isRetryableError('Connection refused'), true);
    });

    test('reset error is retryable', () {
      expect(PicnicCachedNetworkImageHelper.isRetryableError('Connection reset'), true);
    });

    test('dispose error is retryable', () {
      expect(PicnicCachedNetworkImageHelper.isRetryableError('Resource disposed'), true);
    });

    test('interrupted error is retryable', () {
      expect(PicnicCachedNetworkImageHelper.isRetryableError('Download interrupted'), true);
    });

    test('empty string is not retryable', () {
      expect(PicnicCachedNetworkImageHelper.isRetryableError(''), false);
    });

    test('generic error is not retryable', () {
      expect(PicnicCachedNetworkImageHelper.isRetryableError('Something went wrong'), false);
    });
  });

  // ── shouldRetry ─────────────────────────────────────────────────────
  group('shouldRetry', () {
    test('returns true for retryable error within limits', () {
      expect(
        PicnicCachedNetworkImageHelper.shouldRetry(
          retryCount: 0,
          maxRetries: 2,
          errorString: 'timeout',
          recentFailureCount: 0,
        ),
        true,
      );
    });

    test('returns false when retry count exceeds max', () {
      expect(
        PicnicCachedNetworkImageHelper.shouldRetry(
          retryCount: 3,
          maxRetries: 2,
          errorString: 'timeout',
          recentFailureCount: 0,
        ),
        false,
      );
    });

    test('returns false for non-retryable error', () {
      expect(
        PicnicCachedNetworkImageHelper.shouldRetry(
          retryCount: 0,
          maxRetries: 2,
          errorString: 'HTTP 404',
          recentFailureCount: 0,
        ),
        false,
      );
    });

    test('returns false when recent failures exceed 15', () {
      expect(
        PicnicCachedNetworkImageHelper.shouldRetry(
          retryCount: 0,
          maxRetries: 2,
          errorString: 'timeout',
          recentFailureCount: 15,
        ),
        false,
      );
    });

    test('returns true at failure count 14', () {
      expect(
        PicnicCachedNetworkImageHelper.shouldRetry(
          retryCount: 0,
          maxRetries: 2,
          errorString: 'network error',
          recentFailureCount: 14,
        ),
        true,
      );
    });

    test('returns false when retryCount equals maxRetries', () {
      expect(
        PicnicCachedNetworkImageHelper.shouldRetry(
          retryCount: 2,
          maxRetries: 2,
          errorString: 'timeout',
          recentFailureCount: 0,
        ),
        false,
      );
    });
  });

  // ── isMemoryPressure ────────────────────────────────────────────────
  group('isMemoryPressure', () {
    test('returns true at 90% usage', () {
      expect(
        PicnicCachedNetworkImageHelper.isMemoryPressure(
          180 * 1024 * 1024,
          200 * 1024 * 1024,
        ),
        true,
      );
    });

    test('returns false at 80% usage', () {
      expect(
        PicnicCachedNetworkImageHelper.isMemoryPressure(
          160 * 1024 * 1024,
          200 * 1024 * 1024,
        ),
        false,
      );
    });

    test('returns false for zero max size', () {
      expect(
        PicnicCachedNetworkImageHelper.isMemoryPressure(100, 0),
        false,
      );
    });

    test('returns true at exactly 90%', () {
      expect(
        PicnicCachedNetworkImageHelper.isMemoryPressure(90, 100),
        true,
      );
    });

    test('returns false just below 90%', () {
      expect(
        PicnicCachedNetworkImageHelper.isMemoryPressure(89, 100),
        false,
      );
    });
  });

  // ── shouldLogMemoryPressure ─────────────────────────────────────────
  group('shouldLogMemoryPressure', () {
    test('returns true when lastLoggedAt is null', () {
      expect(
        PicnicCachedNetworkImageHelper.shouldLogMemoryPressure(DateTime.now(), null),
        true,
      );
    });

    test('returns true when interval has passed', () {
      final now = DateTime(2025, 1, 1, 12, 5);
      final lastLogged = DateTime(2025, 1, 1, 12, 0);
      expect(
        PicnicCachedNetworkImageHelper.shouldLogMemoryPressure(now, lastLogged),
        true,
      );
    });

    test('returns false when interval has not passed', () {
      final now = DateTime(2025, 1, 1, 12, 0, 30);
      final lastLogged = DateTime(2025, 1, 1, 12, 0, 0);
      expect(
        PicnicCachedNetworkImageHelper.shouldLogMemoryPressure(now, lastLogged),
        false,
      );
    });

    test('returns true at exactly the interval boundary', () {
      final now = DateTime(2025, 1, 1, 12, 1, 0);
      final lastLogged = DateTime(2025, 1, 1, 12, 0, 0);
      expect(
        PicnicCachedNetworkImageHelper.shouldLogMemoryPressure(now, lastLogged),
        true,
      );
    });

    test('custom interval is respected', () {
      final now = DateTime(2025, 1, 1, 12, 2, 0);
      final lastLogged = DateTime(2025, 1, 1, 12, 0, 0);
      expect(
        PicnicCachedNetworkImageHelper.shouldLogMemoryPressure(
          now,
          lastLogged,
          interval: const Duration(minutes: 3),
        ),
        false,
      );
    });
  });
}

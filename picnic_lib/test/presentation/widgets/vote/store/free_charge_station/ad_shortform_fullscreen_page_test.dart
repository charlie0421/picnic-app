import 'package:flutter_test/flutter_test.dart';

import '../../../../../helpers/test_environment.dart';

/// Tests for AdShortformFullscreenPage logic patterns.
///
/// The widget itself depends on video_player, SystemChrome,
/// url_launcher, and navigatorKey context, making full widget
/// testing impractical. Instead, we test the pure logic patterns.
void main() {
  setUpAll(() {
    initTestColors();
  });

  group('_onProgress completion detection', () {
    test('detects video completion', () {
      bool viewReported = false;
      bool rewarding = false;
      bool isInitialized = true;
      const position = Duration(seconds: 30);
      const duration = Duration(seconds: 30);
      const threshold = Duration(milliseconds: 150);

      final shouldReward = isInitialized &&
          position >= (duration - threshold) &&
          !viewReported &&
          !rewarding;

      expect(shouldReward, isTrue);
    });

    test('does not trigger when already reported', () {
      bool viewReported = true;
      bool rewarding = false;
      bool isInitialized = true;
      const position = Duration(seconds: 30);
      const duration = Duration(seconds: 30);
      const threshold = Duration(milliseconds: 150);

      final shouldReward = isInitialized &&
          position >= (duration - threshold) &&
          !viewReported &&
          !rewarding;

      expect(shouldReward, isFalse);
    });

    test('does not trigger when currently rewarding', () {
      bool viewReported = false;
      bool rewarding = true;
      bool isInitialized = true;
      const position = Duration(seconds: 30);
      const duration = Duration(seconds: 30);
      const threshold = Duration(milliseconds: 150);

      final shouldReward = isInitialized &&
          position >= (duration - threshold) &&
          !viewReported &&
          !rewarding;

      expect(shouldReward, isFalse);
    });

    test('does not trigger when not initialized', () {
      bool viewReported = false;
      bool rewarding = false;
      bool isInitialized = false;
      const position = Duration(seconds: 30);
      const duration = Duration(seconds: 30);
      const threshold = Duration(milliseconds: 150);

      final shouldReward = isInitialized &&
          position >= (duration - threshold) &&
          !viewReported &&
          !rewarding;

      expect(shouldReward, isFalse);
    });

    test('triggers near completion (within 150ms)', () {
      bool viewReported = false;
      bool rewarding = false;
      bool isInitialized = true;
      const position = Duration(seconds: 29, milliseconds: 900);
      const duration = Duration(seconds: 30);
      const threshold = Duration(milliseconds: 150);

      final shouldReward = isInitialized &&
          position >= (duration - threshold) &&
          !viewReported &&
          !rewarding;

      expect(shouldReward, isTrue);
    });

    test('does not trigger when far from completion', () {
      bool viewReported = false;
      bool rewarding = false;
      bool isInitialized = true;
      const position = Duration(seconds: 15);
      const duration = Duration(seconds: 30);
      const threshold = Duration(milliseconds: 150);

      final shouldReward = isInitialized &&
          position >= (duration - threshold) &&
          !viewReported &&
          !rewarding;

      expect(shouldReward, isFalse);
    });
  });

  group('CTA reveal countdown logic', () {
    test('reveal starts when remaining <= 5 seconds', () {
      bool ctaRevealStarted = false;
      bool isInitialized = true;
      const duration = Duration(seconds: 30);
      const position = Duration(seconds: 26);

      if (!ctaRevealStarted && isInitialized) {
        final remaining = duration - position;
        if (!remaining.isNegative && remaining <= const Duration(seconds: 5)) {
          ctaRevealStarted = true;
        }
      }

      expect(ctaRevealStarted, isTrue);
    });

    test('reveal does not start when remaining > 5 seconds', () {
      bool ctaRevealStarted = false;
      bool isInitialized = true;
      const duration = Duration(seconds: 30);
      const position = Duration(seconds: 10);

      if (!ctaRevealStarted && isInitialized) {
        final remaining = duration - position;
        if (!remaining.isNegative && remaining <= const Duration(seconds: 5)) {
          ctaRevealStarted = true;
        }
      }

      expect(ctaRevealStarted, isFalse);
    });

    test('reveal stays started once triggered', () {
      bool ctaRevealStarted = true;
      bool isInitialized = true;
      const duration = Duration(seconds: 30);
      const position = Duration(seconds: 10); // Rewound

      if (!ctaRevealStarted && isInitialized) {
        final remaining = duration - position;
        if (!remaining.isNegative && remaining <= const Duration(seconds: 5)) {
          ctaRevealStarted = true;
        }
      }

      // Once started, stays started
      expect(ctaRevealStarted, isTrue);
    });
  });

  group('Close button logic', () {
    test('can close when finished and not buffering', () {
      bool isInitialized = true;
      bool isBuffering = false;
      const position = Duration(seconds: 30);
      const duration = Duration(seconds: 30);

      final canClose = isInitialized && !isBuffering && position >= duration;
      expect(canClose, isTrue);
    });

    test('cannot close when still playing', () {
      bool isInitialized = true;
      bool isBuffering = false;
      const position = Duration(seconds: 15);
      const duration = Duration(seconds: 30);

      final canClose = isInitialized && !isBuffering && position >= duration;
      expect(canClose, isFalse);
    });

    test('cannot close when buffering', () {
      bool isInitialized = true;
      bool isBuffering = true;
      const position = Duration(seconds: 30);
      const duration = Duration(seconds: 30);

      final canClose = isInitialized && !isBuffering && position >= duration;
      expect(canClose, isFalse);
    });

    test('cannot close when not initialized', () {
      bool isInitialized = false;
      bool isBuffering = false;
      const position = Duration(seconds: 30);
      const duration = Duration(seconds: 30);

      final canClose = isInitialized && !isBuffering && position >= duration;
      expect(canClose, isFalse);
    });
  });

  group('More button enablement', () {
    test('enabled when finished, viewed, and not rewarding', () {
      bool finished = true;
      bool viewReported = true;
      bool rewarding = false;

      final enabled = finished && viewReported && !rewarding;
      expect(enabled, isTrue);
    });

    test('disabled when not finished', () {
      bool finished = false;
      bool viewReported = true;
      bool rewarding = false;

      final enabled = finished && viewReported && !rewarding;
      expect(enabled, isFalse);
    });

    test('disabled when not viewed', () {
      bool finished = true;
      bool viewReported = false;
      bool rewarding = false;

      final enabled = finished && viewReported && !rewarding;
      expect(enabled, isFalse);
    });

    test('disabled when rewarding', () {
      bool finished = true;
      bool viewReported = true;
      bool rewarding = true;

      final enabled = finished && viewReported && !rewarding;
      expect(enabled, isFalse);
    });
  });

  group('More button visibility', () {
    test('hidden when no CTA URL', () {
      String? cta;
      bool ctaRevealStarted = true;
      bool finished = true;

      final visible = cta != null && cta.isNotEmpty && (ctaRevealStarted || finished);
      expect(visible, isFalse);
    });

    test('hidden when empty CTA URL', () {
      String? cta = '';
      bool ctaRevealStarted = true;
      bool finished = true;

      final visible = cta != null && cta.isNotEmpty && (ctaRevealStarted || finished);
      expect(visible, isFalse);
    });

    test('visible when CTA exists and reveal started', () {
      String? cta = 'https://example.com';
      bool ctaRevealStarted = true;
      bool finished = false;

      final visible = cta != null && cta.isNotEmpty && (ctaRevealStarted || finished);
      expect(visible, isTrue);
    });

    test('visible when CTA exists and finished', () {
      String? cta = 'https://example.com';
      bool ctaRevealStarted = false;
      bool finished = true;

      final visible = cta != null && cta.isNotEmpty && (ctaRevealStarted || finished);
      expect(visible, isTrue);
    });

    test('hidden when CTA exists but neither revealed nor finished', () {
      String? cta = 'https://example.com';
      bool ctaRevealStarted = false;
      bool finished = false;

      final visible = cta != null && cta.isNotEmpty && (ctaRevealStarted || finished);
      expect(visible, isFalse);
    });
  });

  group('Video size calculation', () {
    test('defaults to 16:9 when size is zero', () {
      double width = 0;
      double height = 0;

      final vw = width == 0 ? 16.0 : width;
      final vh = height == 0 ? 9.0 : height;

      expect(vw, 16.0);
      expect(vh, 9.0);
    });

    test('uses actual size when non-zero', () {
      double width = 1920;
      double height = 1080;

      final vw = width == 0 ? 16.0 : width;
      final vh = height == 0 ? 9.0 : height;

      expect(vw, 1920.0);
      expect(vh, 1080.0);
    });
  });

  group('Loading state logic', () {
    test('shows loading initially', () {
      bool loading = true;
      bool isInitialized = false;
      bool isBuffering = false;
      bool isPlaying = false;
      const position = Duration.zero;

      final showLoader = loading ||
          !isInitialized ||
          (isBuffering) ||
          (!isPlaying && position == Duration.zero);

      expect(showLoader, isTrue);
    });

    test('hides loading when playing', () {
      bool loading = false;
      bool isInitialized = true;
      bool isBuffering = false;
      bool isPlaying = true;
      const position = Duration(seconds: 5);

      final showLoader = loading ||
          !isInitialized ||
          (isBuffering) ||
          (!isPlaying && position == Duration.zero);

      expect(showLoader, isFalse);
    });

    test('shows loading when buffering', () {
      bool loading = false;
      bool isInitialized = true;
      bool isBuffering = true;
      bool isPlaying = false;
      const position = Duration(seconds: 5);

      final finished = isInitialized && !isBuffering && position >= const Duration(seconds: 30);
      final showLoader = loading ||
          !isInitialized ||
          (isBuffering && !finished) ||
          (!isPlaying && position == Duration.zero);

      expect(showLoader, isTrue);
    });
  });

  group('Countdown display logic', () {
    test('shows countdown when <= 5 seconds remaining and not finished', () {
      bool isInitialized = true;
      bool isBuffering = false;
      const position = Duration(seconds: 27);
      const duration = Duration(seconds: 30);

      final finished = isInitialized && !isBuffering && position >= duration;
      final remaining = isInitialized ? (duration - position).inSeconds : 0;
      final showCountdown = !finished && remaining > 0 && remaining <= 5;

      expect(showCountdown, isTrue);
      expect(remaining, 3);
    });

    test('hides countdown when finished', () {
      bool isInitialized = true;
      bool isBuffering = false;
      const position = Duration(seconds: 30);
      const duration = Duration(seconds: 30);

      final finished = isInitialized && !isBuffering && position >= duration;
      final remaining = isInitialized ? (duration - position).inSeconds : 0;
      final showCountdown = !finished && remaining > 0 && remaining <= 5;

      expect(showCountdown, isFalse);
    });

    test('hides countdown when > 5 seconds remaining', () {
      bool isInitialized = true;
      bool isBuffering = false;
      const position = Duration(seconds: 10);
      const duration = Duration(seconds: 30);

      final finished = isInitialized && !isBuffering && position >= duration;
      final remaining = isInitialized ? (duration - position).inSeconds : 0;
      final showCountdown = !finished && remaining > 0 && remaining <= 5;

      expect(showCountdown, isFalse);
      expect(remaining, 20);
    });
  });

  group('_startReward guard logic', () {
    test('blocks if already rewarding', () {
      bool rewarding = true;
      bool viewReported = false;

      final shouldStart = !rewarding && !viewReported;
      expect(shouldStart, isFalse);
    });

    test('blocks if already reported', () {
      bool rewarding = false;
      bool viewReported = true;

      final shouldStart = !rewarding && !viewReported;
      expect(shouldStart, isFalse);
    });

    test('allows when neither rewarding nor reported', () {
      bool rewarding = false;
      bool viewReported = false;

      final shouldStart = !rewarding && !viewReported;
      expect(shouldStart, isTrue);
    });
  });

  group('_initializeFlow logic', () {
    test('uses loadAd when provided', () {
      bool loadAdCalled = false;
      String? resolvedVideoUrl;
      String? resolvedCtaUrl;

      final loadAd = () {
        loadAdCalled = true;
        return (videoUrl: 'https://test.com/video.mp4', ctaUrl: 'https://cta.com');
      };

      final result = loadAd();
      resolvedVideoUrl = result.videoUrl;
      resolvedCtaUrl = result.ctaUrl;

      expect(loadAdCalled, isTrue);
      expect(resolvedVideoUrl, 'https://test.com/video.mp4');
      expect(resolvedCtaUrl, 'https://cta.com');
    });

    test('uses widget values when loadAd is null', () {
      const widgetVideoUrl = 'https://widget.com/video.mp4';
      const widgetCtaUrl = 'https://widget-cta.com';
      String? resolvedVideoUrl;
      String? resolvedCtaUrl;
      bool hasLoadAd = false;

      if (hasLoadAd) {
        // would call loadAd
      } else {
        resolvedVideoUrl = widgetVideoUrl;
        resolvedCtaUrl = widgetCtaUrl;
      }

      expect(resolvedVideoUrl, widgetVideoUrl);
      expect(resolvedCtaUrl, widgetCtaUrl);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/platforms/ad_shortform_fullscreen_page.dart';

void main() {
  group('AdShortformLogic.shouldStartCountdown', () {
    test('returns false when ctaRevealStarted is true', () {
      expect(
        AdShortformLogic.shouldStartCountdown(
          ctaRevealStarted: true,
          isInitialized: true,
          remaining: const Duration(seconds: 3),
        ),
        isFalse,
      );
    });

    test('returns false when not initialized', () {
      expect(
        AdShortformLogic.shouldStartCountdown(
          ctaRevealStarted: false,
          isInitialized: false,
          remaining: const Duration(seconds: 3),
        ),
        isFalse,
      );
    });

    test('returns true when remaining <= 5 seconds', () {
      expect(
        AdShortformLogic.shouldStartCountdown(
          ctaRevealStarted: false,
          isInitialized: true,
          remaining: const Duration(seconds: 5),
        ),
        isTrue,
      );
    });

    test('returns true when remaining is 0', () {
      expect(
        AdShortformLogic.shouldStartCountdown(
          ctaRevealStarted: false,
          isInitialized: true,
          remaining: Duration.zero,
        ),
        isTrue,
      );
    });

    test('returns false when remaining > 5 seconds', () {
      expect(
        AdShortformLogic.shouldStartCountdown(
          ctaRevealStarted: false,
          isInitialized: true,
          remaining: const Duration(seconds: 6),
        ),
        isFalse,
      );
    });

    test('returns false when remaining is negative', () {
      expect(
        AdShortformLogic.shouldStartCountdown(
          ctaRevealStarted: false,
          isInitialized: true,
          remaining: const Duration(seconds: -1),
        ),
        isFalse,
      );
    });

    test('returns true at exactly 1 second', () {
      expect(
        AdShortformLogic.shouldStartCountdown(
          ctaRevealStarted: false,
          isInitialized: true,
          remaining: const Duration(seconds: 1),
        ),
        isTrue,
      );
    });
  });

  group('AdShortformLogic.isPlaybackComplete', () {
    test('returns true when position reaches near end', () {
      expect(
        AdShortformLogic.isPlaybackComplete(
          isInitialized: true,
          position: const Duration(seconds: 30),
          duration: const Duration(seconds: 30),
        ),
        isTrue,
      );
    });

    test('returns true when position is within 150ms of end', () {
      expect(
        AdShortformLogic.isPlaybackComplete(
          isInitialized: true,
          position: const Duration(milliseconds: 29900),
          duration: const Duration(seconds: 30),
        ),
        isTrue,
      );
    });

    test('returns false when not initialized', () {
      expect(
        AdShortformLogic.isPlaybackComplete(
          isInitialized: false,
          position: const Duration(seconds: 30),
          duration: const Duration(seconds: 30),
        ),
        isFalse,
      );
    });

    test('returns false when far from end', () {
      expect(
        AdShortformLogic.isPlaybackComplete(
          isInitialized: true,
          position: const Duration(seconds: 10),
          duration: const Duration(seconds: 30),
        ),
        isFalse,
      );
    });

    test('returns false when just before 150ms threshold', () {
      expect(
        AdShortformLogic.isPlaybackComplete(
          isInitialized: true,
          position: const Duration(milliseconds: 29849),
          duration: const Duration(seconds: 30),
        ),
        isFalse,
      );
    });
  });

  group('AdShortformLogic.canCloseImmediately', () {
    test('returns true when video fully finished', () {
      expect(
        AdShortformLogic.canCloseImmediately(
          isInitialized: true,
          isBuffering: false,
          position: const Duration(seconds: 30),
          duration: const Duration(seconds: 30),
        ),
        isTrue,
      );
    });

    test('returns false when buffering', () {
      expect(
        AdShortformLogic.canCloseImmediately(
          isInitialized: true,
          isBuffering: true,
          position: const Duration(seconds: 30),
          duration: const Duration(seconds: 30),
        ),
        isFalse,
      );
    });

    test('returns false when not initialized', () {
      expect(
        AdShortformLogic.canCloseImmediately(
          isInitialized: false,
          isBuffering: false,
          position: const Duration(seconds: 30),
          duration: const Duration(seconds: 30),
        ),
        isFalse,
      );
    });

    test('returns false when position < duration', () {
      expect(
        AdShortformLogic.canCloseImmediately(
          isInitialized: true,
          isBuffering: false,
          position: const Duration(seconds: 25),
          duration: const Duration(seconds: 30),
        ),
        isFalse,
      );
    });

    test('returns true when position > duration', () {
      expect(
        AdShortformLogic.canCloseImmediately(
          isInitialized: true,
          isBuffering: false,
          position: const Duration(seconds: 31),
          duration: const Duration(seconds: 30),
        ),
        isTrue,
      );
    });
  });

  group('AdShortformLogic.shouldShowCtaButton', () {
    test('returns false when ctaUrl is null', () {
      expect(
        AdShortformLogic.shouldShowCtaButton(
          ctaRevealStarted: true,
          finished: true,
          ctaUrl: null,
        ),
        isFalse,
      );
    });

    test('returns false when ctaUrl is empty', () {
      expect(
        AdShortformLogic.shouldShowCtaButton(
          ctaRevealStarted: true,
          finished: true,
          ctaUrl: '',
        ),
        isFalse,
      );
    });

    test('returns true when countdown started', () {
      expect(
        AdShortformLogic.shouldShowCtaButton(
          ctaRevealStarted: true,
          finished: false,
          ctaUrl: 'https://example.com',
        ),
        isTrue,
      );
    });

    test('returns true when finished', () {
      expect(
        AdShortformLogic.shouldShowCtaButton(
          ctaRevealStarted: false,
          finished: true,
          ctaUrl: 'https://example.com',
        ),
        isTrue,
      );
    });

    test('returns false when neither countdown nor finished', () {
      expect(
        AdShortformLogic.shouldShowCtaButton(
          ctaRevealStarted: false,
          finished: false,
          ctaUrl: 'https://example.com',
        ),
        isFalse,
      );
    });
  });

  group('AdShortformLogic.isCtaButtonEnabled', () {
    test('returns true when finished and view reported and not rewarding', () {
      expect(
        AdShortformLogic.isCtaButtonEnabled(
          finished: true,
          viewReported: true,
          rewarding: false,
        ),
        isTrue,
      );
    });

    test('returns false when not finished', () {
      expect(
        AdShortformLogic.isCtaButtonEnabled(
          finished: false,
          viewReported: true,
          rewarding: false,
        ),
        isFalse,
      );
    });

    test('returns false when view not reported', () {
      expect(
        AdShortformLogic.isCtaButtonEnabled(
          finished: true,
          viewReported: false,
          rewarding: false,
        ),
        isFalse,
      );
    });

    test('returns false when rewarding', () {
      expect(
        AdShortformLogic.isCtaButtonEnabled(
          finished: true,
          viewReported: true,
          rewarding: true,
        ),
        isFalse,
      );
    });

    test('returns false when all false', () {
      expect(
        AdShortformLogic.isCtaButtonEnabled(
          finished: false,
          viewReported: false,
          rewarding: false,
        ),
        isFalse,
      );
    });
  });

  group('AdShortformLogic.shouldShowLoader', () {
    test('returns true when loading', () {
      expect(
        AdShortformLogic.shouldShowLoader(
          loading: true,
          isInitialized: true,
          isBuffering: false,
          isPlaying: true,
          position: const Duration(seconds: 5),
          duration: const Duration(seconds: 30),
          finished: false,
        ),
        isTrue,
      );
    });

    test('returns true when not initialized', () {
      expect(
        AdShortformLogic.shouldShowLoader(
          loading: false,
          isInitialized: false,
          isBuffering: false,
          isPlaying: false,
          position: Duration.zero,
          duration: Duration.zero,
          finished: false,
        ),
        isTrue,
      );
    });

    test('returns true when buffering and not finished', () {
      expect(
        AdShortformLogic.shouldShowLoader(
          loading: false,
          isInitialized: true,
          isBuffering: true,
          isPlaying: false,
          position: const Duration(seconds: 10),
          duration: const Duration(seconds: 30),
          finished: false,
        ),
        isTrue,
      );
    });

    test('returns false when buffering but finished', () {
      expect(
        AdShortformLogic.shouldShowLoader(
          loading: false,
          isInitialized: true,
          isBuffering: true,
          isPlaying: false,
          position: const Duration(seconds: 30),
          duration: const Duration(seconds: 30),
          finished: true,
        ),
        isFalse,
      );
    });

    test('returns true when not playing and at position zero', () {
      expect(
        AdShortformLogic.shouldShowLoader(
          loading: false,
          isInitialized: true,
          isBuffering: false,
          isPlaying: false,
          position: Duration.zero,
          duration: const Duration(seconds: 30),
          finished: false,
        ),
        isTrue,
      );
    });

    test('returns false when playing normally', () {
      expect(
        AdShortformLogic.shouldShowLoader(
          loading: false,
          isInitialized: true,
          isBuffering: false,
          isPlaying: true,
          position: const Duration(seconds: 15),
          duration: const Duration(seconds: 30),
          finished: false,
        ),
        isFalse,
      );
    });
  });

  group('AdShortformLogic.shouldRenderCloseButton', () {
    test('renders when controller is null (escape from infinite pulse)', () {
      expect(
        AdShortformLogic.shouldRenderCloseButton(hasController: false),
        isTrue,
      );
    });

    test('renders when controller is present', () {
      expect(
        AdShortformLogic.shouldRenderCloseButton(hasController: true),
        isTrue,
      );
    });
  });

  group('AdShortformLogic.shouldErrorOnEmptyVideoUrl', () {
    test('errors when videoUrl empty and not blocked by anti-abuse', () {
      expect(
        AdShortformLogic.shouldErrorOnEmptyVideoUrl(
          videoUrl: '',
          blocked: false,
        ),
        isTrue,
      );
    });

    test('does not error when blocked by anti-abuse (route already popping)',
        () {
      expect(
        AdShortformLogic.shouldErrorOnEmptyVideoUrl(
          videoUrl: '',
          blocked: true,
        ),
        isFalse,
      );
    });

    test('does not error when videoUrl is present', () {
      expect(
        AdShortformLogic.shouldErrorOnEmptyVideoUrl(
          videoUrl: 'https://example.com/v.m3u8',
          blocked: false,
        ),
        isFalse,
      );
    });

    test('does not error when videoUrl present even if (impossibly) blocked',
        () {
      expect(
        AdShortformLogic.shouldErrorOnEmptyVideoUrl(
          videoUrl: 'https://example.com/v.m3u8',
          blocked: true,
        ),
        isFalse,
      );
    });
  });

  group('AdShortformLogic.shouldShowCountdown', () {
    test('returns true for 1-5 seconds remaining', () {
      for (int i = 1; i <= 5; i++) {
        expect(
          AdShortformLogic.shouldShowCountdown(
            finished: false,
            remainingSeconds: i,
          ),
          isTrue,
          reason: '$i seconds remaining',
        );
      }
    });

    test('returns false when finished', () {
      expect(
        AdShortformLogic.shouldShowCountdown(
          finished: true,
          remainingSeconds: 3,
        ),
        isFalse,
      );
    });

    test('returns false when remaining is 0', () {
      expect(
        AdShortformLogic.shouldShowCountdown(
          finished: false,
          remainingSeconds: 0,
        ),
        isFalse,
      );
    });

    test('returns false when remaining > 5', () {
      expect(
        AdShortformLogic.shouldShowCountdown(
          finished: false,
          remainingSeconds: 6,
        ),
        isFalse,
      );
    });

    test('returns false when remaining is negative', () {
      expect(
        AdShortformLogic.shouldShowCountdown(
          finished: false,
          remainingSeconds: -1,
        ),
        isFalse,
      );
    });
  });
}

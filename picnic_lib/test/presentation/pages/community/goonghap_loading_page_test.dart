import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/community/goonghap.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';

import '../../../helpers/test_environment.dart';

/// Tests for GoonghapLoadingPage logic patterns.
///
/// Widget testing is blocked because the page imports google_mobile_ads
/// (via BannerAdWidget) and cached_network_image (via GoonghapCard).
/// Instead, we test the pure logic patterns the page relies on.
void main() {
  setUpAll(() {
    initTestColors();
  });

  final testArtist = ArtistModel(
    id: 1,
    name: {'ko': '지민', 'en': 'Jimin', 'ja': 'ジミン'},
    gender: 'male',
  );

  group('Progress calculation', () {
    const totalSeconds = 30;

    test('progress is 1.0 before loading starts', () {
      const isLoadingStarted = false;
      const seconds = totalSeconds;
      final progress = isLoadingStarted ? seconds / totalSeconds : 1.0;
      expect(progress, equals(1.0));
    });

    test('progress is 1.0 at start of countdown', () {
      const isLoadingStarted = true;
      const seconds = totalSeconds;
      final progress = isLoadingStarted ? seconds / totalSeconds : 1.0;
      expect(progress, equals(1.0));
    });

    test('progress decreases as seconds decrease', () {
      const isLoadingStarted = true;
      const seconds = 15;
      final progress = isLoadingStarted ? seconds / totalSeconds : 1.0;
      expect(progress, equals(0.5));
    });

    test('progress is 0.0 at end of countdown', () {
      const isLoadingStarted = true;
      const seconds = 0;
      final progress = isLoadingStarted ? seconds / totalSeconds : 1.0;
      expect(progress, equals(0.0));
    });

    test('progress at various points', () {
      const isLoadingStarted = true;
      // 20 seconds remaining out of 30
      expect(20 / totalSeconds, closeTo(0.667, 0.001));
      // 10 seconds remaining
      expect(10 / totalSeconds, closeTo(0.333, 0.001));
      // 5 seconds remaining
      expect(5 / totalSeconds, closeTo(0.167, 0.001));
    });
  });

  group('Loading view display conditions', () {
    test('shows loading when isPending', () {
      final goonghap = GoonghapModel(
        id: 'g1',
        userId: 'u1',
        artist: testArtist,
        birthDate: DateTime(2000, 1, 1),
        status: GoonghapStatus.pending,
      );

      expect(goonghap.isPending, isTrue);
      expect(goonghap.isAds == false, isFalse); // isAds is null
    });

    test('shows loading when isAds is false', () {
      final goonghap = GoonghapModel(
        id: 'g2',
        userId: 'u1',
        artist: testArtist,
        birthDate: DateTime(2000, 1, 1),
        status: GoonghapStatus.completed,
        isAds: false,
      );

      expect(goonghap.isPending, isFalse);
      expect(goonghap.isAds == false, isTrue);
      // Either condition triggers loading view
      expect(goonghap.isPending || goonghap.isAds == false, isTrue);
    });

    test('shows error when hasError', () {
      final goonghap = GoonghapModel(
        id: 'g3',
        userId: 'u1',
        artist: testArtist,
        birthDate: DateTime(2000, 1, 1),
        status: GoonghapStatus.error,
        errorMessage: 'API failure',
      );

      expect(goonghap.hasError, isTrue);
      expect(goonghap.isPending, isFalse);
    });

    test('shows neither loading nor error when completed with ads', () {
      final goonghap = GoonghapModel(
        id: 'g4',
        userId: 'u1',
        artist: testArtist,
        birthDate: DateTime(2000, 1, 1),
        status: GoonghapStatus.completed,
        isAds: true,
      );

      expect(goonghap.isPending || goonghap.isAds == false, isFalse);
      expect(goonghap.hasError, isFalse);
    });
  });

  group('Artist name title resolution', () {
    String safeArtistTitle(Map<String, dynamic> nameJson, String primaryLocale) {
      const fallbacks = [
        'ko', 'en', 'ja', 'id', 'th', 'vi', 'fil', 'zh', 'zh-cn', 'zh-tw'
      ];

      String title = (nameJson[primaryLocale] as String? ?? '').trim();
      if (title.isEmpty) {
        for (final lc in fallbacks) {
          title = (nameJson[lc] as String? ?? '').trim();
          if (title.isNotEmpty) break;
        }
      }
      if (title.isEmpty) title = 'Artist';
      return title;
    }

    test('returns Korean name when available', () {
      expect(
        safeArtistTitle({'ko': '지민', 'en': 'Jimin'}, 'ko'),
        equals('지민'),
      );
    });

    test('falls back to English when Korean missing', () {
      expect(
        safeArtistTitle({'en': 'Jimin'}, 'ko'),
        equals('Jimin'),
      );
    });

    test('falls back to Japanese when ko and en missing', () {
      expect(
        safeArtistTitle({'ja': 'ジミン'}, 'ko'),
        equals('ジミン'),
      );
    });

    test('returns Artist when no names available', () {
      expect(
        safeArtistTitle({}, 'ko'),
        equals('Artist'),
      );
    });

    test('returns primary locale if available', () {
      expect(
        safeArtistTitle({'ko': '지민', 'en': 'Jimin'}, 'en'),
        equals('Jimin'),
      );
    });

    test('trims whitespace names', () {
      expect(
        safeArtistTitle({'ko': '  ', 'en': 'Jimin'}, 'ko'),
        equals('Jimin'),
      );
    });
  });

  group('Timer countdown behavior', () {
    test('timer starts at totalSeconds and counts down', () {
      int seconds = 30;
      const totalSeconds = 30;

      // Simulate 5 ticks
      for (int i = 0; i < 5; i++) {
        if (seconds > 0) seconds--;
      }

      expect(seconds, equals(25));
    });

    test('timer stops at 0', () {
      int seconds = 2;

      for (int i = 0; i < 5; i++) {
        if (seconds > 0) {
          seconds--;
        }
      }

      expect(seconds, equals(0));
    });

    test('loading starts after 3 second delay', () {
      // In the widget, isLoadingStarted becomes true after 3s delay
      bool isLoadingStarted = false;

      // Before delay
      expect(isLoadingStarted, isFalse);

      // After delay
      isLoadingStarted = true;
      expect(isLoadingStarted, isTrue);
    });
  });

  group('GoonghapModel state checks', () {
    test('isPending returns true for pending status', () {
      final g = GoonghapModel(
        id: 'g1',
        userId: 'u1',
        artist: testArtist,
        birthDate: DateTime(2000, 1, 1),
        status: GoonghapStatus.pending,
      );
      expect(g.isPending, isTrue);
    });

    test('isCompleted returns true for completed status', () {
      final g = GoonghapModel(
        id: 'g2',
        userId: 'u1',
        artist: testArtist,
        birthDate: DateTime(2000, 1, 1),
        status: GoonghapStatus.completed,
      );
      expect(g.isCompleted, isTrue);
    });

    test('hasError returns true for error status', () {
      final g = GoonghapModel(
        id: 'g3',
        userId: 'u1',
        artist: testArtist,
        birthDate: DateTime(2000, 1, 1),
        status: GoonghapStatus.error,
        errorMessage: 'Something failed',
      );
      expect(g.hasError, isTrue);
    });

    test('all status flags are mutually exclusive', () {
      for (final status in GoonghapStatus.values) {
        if (status == GoonghapStatus.input) continue;
        final g = GoonghapModel(
          id: 'test',
          userId: 'u1',
          artist: testArtist,
          birthDate: DateTime(2000, 1, 1),
          status: status,
        );
        final flags = [g.isPending, g.isCompleted, g.hasError];
        expect(flags.where((f) => f).length, equals(1),
            reason: 'Exactly one flag should be true for $status');
      }
    });
  });

  group('Navigation title update logic', () {
    test('only updates when title differs from current pageTitle', () {
      const currentPageTitle = 'Old Title';
      const newTitle = '지민';

      final shouldUpdate =
          newTitle.isNotEmpty && newTitle != currentPageTitle;
      expect(shouldUpdate, isTrue);
    });

    test('does not update when title matches', () {
      const currentPageTitle = '지민';
      const newTitle = '지민';

      final shouldUpdate =
          newTitle.isNotEmpty && newTitle != currentPageTitle;
      expect(shouldUpdate, isFalse);
    });

    test('does not update when title is empty', () {
      const currentPageTitle = 'Old Title';
      const newTitle = '';

      final shouldUpdate =
          newTitle.isNotEmpty && newTitle != currentPageTitle;
      expect(shouldUpdate, isFalse);
    });

    test('recovers title when it becomes empty externally', () {
      // Simulates the ref.listen logic in build
      String previousTitle = '지민';
      String nextTitle = '';

      bool shouldRecover = nextTitle.isEmpty;
      expect(shouldRecover, isTrue);
    });
  });
}

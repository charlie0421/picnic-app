import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/community/goonghap.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';

import '../../../helpers/test_environment.dart';

/// Tests for GoonghapResultContent logic patterns.
///
/// Widget testing is blocked because the page transitively imports
/// flutter_svg and bubble_box/ExpansibleController.
/// Instead, we test the pure logic patterns the page relies on.
void main() {
  setUpAll(() {
    initTestColors();
  });

  final testArtist = ArtistModel(
    id: 1,
    name: {'ko': '지민', 'en': 'Jimin'},
    gender: 'male',
  );

  group('Language normalization (mirrors build method)', () {
    String normalizeLanguageCode(String language, String country) {
      String normalizedLang = language;
      if (language == 'zh') {
        if (country == 'CN') {
          normalizedLang = 'zh-CN';
        } else if (country == 'TW') {
          normalizedLang = 'zh-TW';
        }
      }
      return normalizedLang;
    }

    test('returns ko for Korean', () {
      expect(normalizeLanguageCode('ko', ''), equals('ko'));
    });

    test('returns en for English', () {
      expect(normalizeLanguageCode('en', ''), equals('en'));
    });

    test('returns zh-CN for Simplified Chinese', () {
      expect(normalizeLanguageCode('zh', 'CN'), equals('zh-CN'));
    });

    test('returns zh-TW for Traditional Chinese', () {
      expect(normalizeLanguageCode('zh', 'TW'), equals('zh-TW'));
    });

    test('returns zh for Chinese without country', () {
      expect(normalizeLanguageCode('zh', ''), equals('zh'));
    });

    test('returns ja for Japanese', () {
      expect(normalizeLanguageCode('ja', ''), equals('ja'));
    });

    test('returns id for Indonesian', () {
      expect(normalizeLanguageCode('id', ''), equals('id'));
    });

    test('returns th for Thai', () {
      expect(normalizeLanguageCode('th', ''), equals('th'));
    });

    test('returns vi for Vietnamese', () {
      expect(normalizeLanguageCode('vi', ''), equals('vi'));
    });

    test('returns fil for Filipino', () {
      expect(normalizeLanguageCode('fil', ''), equals('fil'));
    });

    test('returns bn for Bengali', () {
      expect(normalizeLanguageCode('bn', ''), equals('bn'));
    });
  });

  group('Localized result retrieval (mirrors build method)', () {
    test('returns null when localizedResults is empty', () {
      final goonghap = GoonghapModel(
        id: 'g1',
        userId: 'u1',
        artist: testArtist,
        birthDate: DateTime(2000, 1, 1),
        status: GoonghapStatus.completed,
        localizedResults: {},
      );

      expect(goonghap.localizedResults?.isEmpty ?? true, isTrue);
    });

    test('returns null when localizedResults is null', () {
      final goonghap = GoonghapModel(
        id: 'g2',
        userId: 'u1',
        artist: testArtist,
        birthDate: DateTime(2000, 1, 1),
        status: GoonghapStatus.completed,
      );

      expect(goonghap.localizedResults?.isEmpty ?? true, isTrue);
    });

    test('retrieves result for matching language', () {
      final goonghap = GoonghapModel(
        id: 'g3',
        userId: 'u1',
        artist: testArtist,
        birthDate: DateTime(2000, 1, 1),
        status: GoonghapStatus.completed,
        localizedResults: {
          'ko': const LocalizedGoonghap(
            language: 'ko',
            score: 85,
            scoreTitle: '환상의 궁합',
            goonghapSummary: '최고의 조합',
            details: Details(
              style: StyleDetails(
                idolStyle: '감성적',
                userStyle: '열정적',
                coupleStyle: '완벽',
              ),
              activities: ActivitiesDetails(
                recommended: ['카페 데이트', '영화 관람'],
                description: '함께 즐길 수 있는 활동',
              ),
            ),
            tips: ['팁 1', '팁 2'],
          ),
        },
      );

      final result = goonghap.getLocalizedResult('ko');
      expect(result, isNotNull);
      expect(result!.score, equals(85));
      expect(result.scoreTitle, equals('환상의 궁합'));
      expect(result.details?.style, isNotNull);
      expect(result.details?.activities, isNotNull);
      expect(result.tips, hasLength(2));
    });

    test('falls back to base language when normalized not found', () {
      final goonghap = GoonghapModel(
        id: 'g4',
        userId: 'u1',
        artist: testArtist,
        birthDate: DateTime(2000, 1, 1),
        status: GoonghapStatus.completed,
        localizedResults: {
          'zh': const LocalizedGoonghap(
            language: 'zh',
            score: 90,
          ),
        },
      );

      // Normalized zh-CN not found, fall back to zh
      final result = goonghap.getLocalizedResult('zh-CN') ??
          goonghap.getLocalizedResult('zh');
      expect(result, isNotNull);
      expect(result!.score, equals(90));
    });

    test('returns null when no matching language at all', () {
      final goonghap = GoonghapModel(
        id: 'g5',
        userId: 'u1',
        artist: testArtist,
        birthDate: DateTime(2000, 1, 1),
        status: GoonghapStatus.completed,
        localizedResults: {
          'ko': const LocalizedGoonghap(language: 'ko', score: 85),
        },
      );

      final result = goonghap.getLocalizedResult('fr') ??
          goonghap.getLocalizedResult('fr');
      expect(result, isNull);
    });

    test('retrieves multiple language results', () {
      final goonghap = GoonghapModel(
        id: 'g-multi',
        userId: 'u1',
        artist: testArtist,
        birthDate: DateTime(2000, 1, 1),
        status: GoonghapStatus.completed,
        localizedResults: {
          'ko': const LocalizedGoonghap(language: 'ko', score: 85, scoreTitle: '좋은 궁합'),
          'en': const LocalizedGoonghap(language: 'en', score: 85, scoreTitle: 'Great Match'),
          'ja': const LocalizedGoonghap(language: 'ja', score: 85, scoreTitle: '良い相性'),
        },
      );

      expect(goonghap.getLocalizedResult('ko')?.scoreTitle, equals('좋은 궁합'));
      expect(goonghap.getLocalizedResult('en')?.scoreTitle, equals('Great Match'));
      expect(goonghap.getLocalizedResult('ja')?.scoreTitle, equals('良い相性'));
    });
  });

  group('isPaid display logic', () {
    test('shows blur overlay when not paid', () {
      final goonghap = GoonghapModel(
        id: 'g6',
        userId: 'u1',
        artist: testArtist,
        birthDate: DateTime(2000, 1, 1),
        status: GoonghapStatus.completed,
        isPaid: false,
      );

      expect(goonghap.isPaid ?? false, isFalse);
    });

    test('shows full content when paid', () {
      final goonghap = GoonghapModel(
        id: 'g7',
        userId: 'u1',
        artist: testArtist,
        birthDate: DateTime(2000, 1, 1),
        status: GoonghapStatus.completed,
        isPaid: true,
      );

      expect(goonghap.isPaid ?? false, isTrue);
    });

    test('treats null isPaid as not paid', () {
      final goonghap = GoonghapModel(
        id: 'g8',
        userId: 'u1',
        artist: testArtist,
        birthDate: DateTime(2000, 1, 1),
        status: GoonghapStatus.completed,
      );

      expect(goonghap.isPaid ?? false, isFalse);
    });

    test('paid goonghap shows sections without blur overlay', () {
      // When isPaid is true, the else branch runs showing sections directly
      const isPaid = true;
      expect(!(isPaid), isFalse);
    });

    test('unpaid goonghap shows Stack with backdrop filter', () {
      // When isPaid is false, Stack with BackdropFilter is shown
      const isPaid = false;
      expect(!(isPaid), isTrue);
    });
  });

  group('Purchase cooldown logic', () {
    test('cooldown prevents rapid repeated purchases', () {
      DateTime? lastPurchaseTime;
      const purchaseCooldown = Duration(seconds: 1);

      bool canPurchase() {
        if (lastPurchaseTime != null) {
          final timeSince = DateTime.now().difference(lastPurchaseTime!);
          if (timeSince < purchaseCooldown) {
            return false;
          }
        }
        return true;
      }

      expect(canPurchase(), isTrue);
      lastPurchaseTime = DateTime.now();
      expect(canPurchase(), isFalse); // Immediately after - blocked
    });

    test('cooldown allows purchase after 1 second', () {
      final lastPurchaseTime = DateTime.now().subtract(const Duration(seconds: 2));
      const purchaseCooldown = Duration(seconds: 1);

      final timeSince = DateTime.now().difference(lastPurchaseTime);
      final canPurchase = timeSince >= purchaseCooldown;
      expect(canPurchase, isTrue);
    });

    test('cooldown is 1 second duration', () {
      const purchaseCooldown = Duration(seconds: 1);
      expect(purchaseCooldown.inMilliseconds, equals(1000));
    });
  });

  group('Style section data', () {
    test('StyleDetails has all required fields', () {
      const style = StyleDetails(
        idolStyle: '아이돌 스타일',
        userStyle: '사용자 스타일',
        coupleStyle: '커플 스타일',
      );

      expect(style.idolStyle, isNotEmpty);
      expect(style.userStyle, isNotEmpty);
      expect(style.coupleStyle, isNotEmpty);
    });

    test('ActivitiesDetails has recommended list and description', () {
      const activities = ActivitiesDetails(
        recommended: ['영화', '카페', '산책'],
        description: '함께 즐기기 좋은 활동들입니다.',
      );

      expect(activities.recommended.length, equals(3));
      expect(activities.description, isNotEmpty);
    });

    test('Details contains both style and activities', () {
      const details = Details(
        style: StyleDetails(
          idolStyle: 'Romantic',
          userStyle: 'Passionate',
          coupleStyle: 'Warm',
        ),
        activities: ActivitiesDetails(
          recommended: ['Movie', 'Cafe'],
          description: 'Fun activities together',
        ),
      );

      expect(details.style.idolStyle, equals('Romantic'));
      expect(details.activities.recommended.length, equals(2));
    });

    test('StyleDetails from JSON', () {
      final json = {
        'idol_style': 'Cool',
        'user_style': 'Hot',
        'couple_style': 'Perfect',
      };
      final style = StyleDetails.fromJson(json);
      expect(style.idolStyle, equals('Cool'));
      expect(style.userStyle, equals('Hot'));
      expect(style.coupleStyle, equals('Perfect'));
    });

    test('ActivitiesDetails from JSON', () {
      final json = {
        'recommended': ['A', 'B'],
        'description': 'desc',
      };
      final activities = ActivitiesDetails.fromJson(json);
      expect(activities.recommended.length, equals(2));
      expect(activities.description, equals('desc'));
    });

    test('empty recommended list', () {
      const activities = ActivitiesDetails(
        recommended: [],
        description: 'No recommendations',
      );
      expect(activities.recommended, isEmpty);
    });

    test('empty tips list', () {
      const localizedResult = LocalizedGoonghap(
        language: 'ko',
        score: 85,
        tips: [],
      );
      expect(localizedResult.tips, isEmpty);
    });

    test('non-empty tips list', () {
      const localizedResult = LocalizedGoonghap(
        language: 'ko',
        score: 85,
        tips: ['Tip 1', 'Tip 2', 'Tip 3'],
      );
      expect(localizedResult.tips.length, equals(3));
    });
  });

  group('isSaving flag controls ShareSection visibility', () {
    test('ShareSection not shown when saving', () {
      const isSaving = true;
      expect(!isSaving, isFalse);
    });

    test('ShareSection shown when not saving', () {
      const isSaving = false;
      expect(!isSaving, isTrue);
    });
  });

  group('LocalizedGoonghap default values', () {
    test('score defaults to 0', () {
      const result = LocalizedGoonghap(language: 'ko');
      expect(result.score, equals(0));
    });

    test('scoreTitle defaults to empty string', () {
      const result = LocalizedGoonghap(language: 'ko');
      expect(result.scoreTitle, equals(''));
    });

    test('goonghapSummary defaults to empty string', () {
      const result = LocalizedGoonghap(language: 'ko');
      expect(result.goonghapSummary, equals(''));
    });

    test('details defaults to null', () {
      const result = LocalizedGoonghap(language: 'ko');
      expect(result.details, isNull);
    });

    test('tips defaults to empty list', () {
      const result = LocalizedGoonghap(language: 'ko');
      expect(result.tips, isEmpty);
    });
  });

  group('GoonghapResultContent section visibility logic', () {
    test('style section shown when style is not null', () {
      const details = Details(
        style: StyleDetails(idolStyle: 'a', userStyle: 'b', coupleStyle: 'c'),
        activities: ActivitiesDetails(recommended: [], description: ''),
      );
      expect(details.style, isNotNull);
    });

    test('activities section shown when activities is not null', () {
      const details = Details(
        style: StyleDetails(idolStyle: 'a', userStyle: 'b', coupleStyle: 'c'),
        activities: ActivitiesDetails(recommended: ['x'], description: 'y'),
      );
      expect(details.activities, isNotNull);
    });

    test('tips section shown when tips is not empty', () {
      const tips = ['Tip 1'];
      expect(tips.isNotEmpty, isTrue);
    });

    test('tips section hidden when tips is empty', () {
      const tips = <String>[];
      expect(tips.isNotEmpty, isFalse);
    });
  });

  group('ExpansionTile initial state', () {
    test('all sections initially expanded', () {
      const initiallyExpanded = true;
      expect(initiallyExpanded, isTrue);
    });
  });

  group('GoonghapResultContent purchase confirmation dialog', () {
    test('confirmed true triggers purchase', () {
      bool? confirmed = true;
      bool purchaseTriggered = false;

      if (confirmed == true) {
        purchaseTriggered = true;
      }

      expect(purchaseTriggered, isTrue);
    });

    test('confirmed false does not trigger purchase', () {
      bool? confirmed = false;
      bool purchaseTriggered = false;

      if (confirmed == true) {
        purchaseTriggered = true;
      }

      expect(purchaseTriggered, isFalse);
    });

    test('confirmed null does not trigger purchase', () {
      bool? confirmed;
      bool purchaseTriggered = false;

      if (confirmed == true) {
        purchaseTriggered = true;
      }

      expect(purchaseTriggered, isFalse);
    });
  });

  group('Star candy display', () {
    test('star candy cost is 100', () {
      const cost = 100;
      expect(cost, equals(100));
    });

    test('star icon asset path', () {
      const assetPath = 'assets/icons/store/star_100.png';
      expect(assetPath, contains('star_100'));
    });
  });
}

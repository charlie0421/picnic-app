import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/community/goonghap.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';

void main() {
  final testArtist = ArtistModel(
    id: 1,
    name: {'ko': '정국', 'en': 'Jungkook'},
    gender: 'male',
  );

  group('GoonghapModel computed properties', () {
    test('pending 상태', () {
      final model = GoonghapModel(
        id: 'g1',
        userId: 'u1',
        artist: testArtist,
        birthDate: DateTime(2000, 1, 1),
        status: GoonghapStatus.pending,
      );
      expect(model.isPending, isTrue);
      expect(model.isCompleted, isFalse);
      expect(model.hasError, isFalse);
    });

    test('completed 상태', () {
      final model = GoonghapModel(
        id: 'g2',
        userId: 'u1',
        artist: testArtist,
        birthDate: DateTime(2000, 1, 1),
        status: GoonghapStatus.completed,
        score: 85,
        goonghapSummary: '환상의 궁합',
      );
      expect(model.isPending, isFalse);
      expect(model.isCompleted, isTrue);
      expect(model.hasError, isFalse);
      expect(model.score, equals(85));
    });

    test('error 상태', () {
      final model = GoonghapModel(
        id: 'g3',
        userId: 'u1',
        artist: testArtist,
        birthDate: DateTime(2000, 1, 1),
        status: GoonghapStatus.error,
        errorMessage: '서버 오류',
      );
      expect(model.isPending, isFalse);
      expect(model.isCompleted, isFalse);
      expect(model.hasError, isTrue);
      expect(model.errorMessage, equals('서버 오류'));
    });

    test('getLocalizedResult - 존재하는 언어', () {
      final localizedKo = LocalizedGoonghap(
        language: 'ko',
        score: 90,
        scoreTitle: '최고',
        goonghapSummary: '궁합 요약',
      );
      final model = GoonghapModel(
        id: 'g4',
        userId: 'u1',
        artist: testArtist,
        birthDate: DateTime(2000, 1, 1),
        localizedResults: {'ko': localizedKo},
      );
      final result = model.getLocalizedResult('ko');
      expect(result, isNotNull);
      expect(result!.score, equals(90));
      expect(result.scoreTitle, equals('최고'));
    });

    test('getLocalizedResult - 없는 언어', () {
      final model = GoonghapModel(
        id: 'g5',
        userId: 'u1',
        artist: testArtist,
        birthDate: DateTime(2000, 1, 1),
        localizedResults: {},
      );
      expect(model.getLocalizedResult('ja'), isNull);
    });

    test('getLocalizedResult - null localizedResults', () {
      final model = GoonghapModel(
        id: 'g6',
        userId: 'u1',
        artist: testArtist,
        birthDate: DateTime(2000, 1, 1),
      );
      expect(model.getLocalizedResult('ko'), isNull);
    });
  });

  group('GoonghapModel 선택 필드', () {
    test('birthTime 포함', () {
      final model = GoonghapModel(
        id: 'g7',
        userId: 'u1',
        artist: testArtist,
        birthDate: DateTime(2000, 1, 1),
        birthTime: '14:30',
        gender: 'female',
      );
      expect(model.birthTime, equals('14:30'));
      expect(model.gender, equals('female'));
    });

    test('isAds, isPaid 플래그', () {
      final model = GoonghapModel(
        id: 'g8',
        userId: 'u1',
        artist: testArtist,
        birthDate: DateTime(2000, 1, 1),
        isAds: true,
        isPaid: false,
      );
      expect(model.isAds, isTrue);
      expect(model.isPaid, isFalse);
    });

    test('tips 리스트', () {
      final model = GoonghapModel(
        id: 'g9',
        userId: 'u1',
        artist: testArtist,
        birthDate: DateTime(2000, 1, 1),
        tips: ['팁1', '팁2', '팁3'],
      );
      expect(model.tips!.length, equals(3));
    });
  });

  group('LocalizedGoonghap', () {
    test('기본값 확인', () {
      const lg = LocalizedGoonghap(language: 'ko');
      expect(lg.language, equals('ko'));
      expect(lg.score, equals(0));
      expect(lg.scoreTitle, equals(''));
      expect(lg.goonghapSummary, equals(''));
      expect(lg.details, isNull);
      expect(lg.tips, isEmpty);
    });

    test('모든 필드 설정', () {
      const lg = LocalizedGoonghap(
        language: 'en',
        score: 95,
        scoreTitle: 'Perfect Match',
        goonghapSummary: 'You are meant to be!',
        tips: ['Be kind', 'Show interest'],
      );
      expect(lg.score, equals(95));
      expect(lg.tips.length, equals(2));
    });
  });

  group('GoonghapHistoryModel', () {
    test('기본값', () {
      const history = GoonghapHistoryModel(
        items: [],
        hasMore: false,
      );
      expect(history.items, isEmpty);
      expect(history.hasMore, isFalse);
      expect(history.isLoading, isFalse);
    });

    test('로딩 상태', () {
      const history = GoonghapHistoryModel(
        items: [],
        hasMore: true,
        isLoading: true,
      );
      expect(history.isLoading, isTrue);
      expect(history.hasMore, isTrue);
    });
  });

  group('Details & StyleDetails & ActivitiesDetails (from goonghap.dart)', () {
    test('StyleDetails 생성', () {
      const style = StyleDetails(
        idolStyle: '카리스마',
        userStyle: '다정한',
        coupleStyle: '환상의 궁합',
      );
      expect(style.idolStyle, equals('카리스마'));
    });

    test('ActivitiesDetails 생성', () {
      const activities = ActivitiesDetails(
        recommended: ['카페', '영화'],
        description: '함께하면 좋은 활동',
      );
      expect(activities.recommended.length, equals(2));
    });

    test('Details 생성', () {
      const details = Details(
        style: StyleDetails(
          idolStyle: 'cool',
          userStyle: 'warm',
          coupleStyle: 'balance',
        ),
        activities: ActivitiesDetails(
          recommended: ['travel'],
          description: 'Great activities',
        ),
      );
      expect(details.style.idolStyle, equals('cool'));
      expect(details.activities.recommended.first, equals('travel'));
    });
  });
}

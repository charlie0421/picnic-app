import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/providers/community/fortune_provider.dart';

import '../../../helpers/mock_supabase.dart';

void main() {
  group('getFortune', () {
    late ProviderContainer container;

    final fortuneData = {
      'id': 'fortune-1',
      'year': 2026,
      'artist_id': 1,
      'artist': {
        'id': 1,
        'name': {'ko': '아이유', 'en': 'IU'},
        'image': null,
        'artist_group': null,
      },
      'overall_luck': '올해 운세가 좋습니다',
      'monthly_fortunes': [
        {
          'month': 1,
          'honor': '명예 운세',
          'career': '직업 운세',
          'health': '건강 운세',
          'summary': '1월 요약',
        },
      ],
      'aspects': {
        'honor': '명예',
        'career': '직업',
        'health': '건강',
        'finances': '재정',
        'relationships': '인간관계',
      },
      'lucky': {
        'days': ['월요일'],
        'colors': ['빨강'],
        'numbers': [7],
        'directions': ['동쪽'],
      },
      'advice': ['열심히 하세요'],
    };

    setUp(() {
      setupMockSupabase({
        'fortune_telling': [fortuneData],
      });
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('fetches fortune data in Korean (default)', () async {
      final result = await container.read(
        getFortuneProvider(artistId: 1, year: 2026).future,
      );
      expect(result.id, 'fortune-1');
      expect(result.year, 2026);
      expect(result.artistId, 1);
      expect(result.overallLuck, '올해 운세가 좋습니다');
      expect(result.monthlyFortunes.length, 1);
      expect(result.monthlyFortunes[0].month, 1);
      expect(result.aspects.honor, '명예');
      expect(result.lucky.days, ['월요일']);
      expect(result.lucky.numbers, [7]);
      expect(result.advice, ['열심히 하세요']);
    });

    test('fetches fortune with i18n translation', () async {
      container.dispose();
      tearDownMockSupabase();

      final translatedFortune = {
        ...fortuneData,
        'overall_luck': 'Good luck this year',
        'advice': ['Work hard'],
      };

      setupMockSupabase({
        'fortune_telling_i18n': [translatedFortune],
      });
      container = ProviderContainer();

      final result = await container.read(
        getFortuneProvider(artistId: 1, year: 2026, language: 'en').future,
      );
      expect(result.overallLuck, 'Good luck this year');
      expect(result.advice, ['Work hard']);
    });

    test('falls back to Korean when translation not found', () async {
      container.dispose();
      tearDownMockSupabase();

      setupMockSupabase({
        'fortune_telling_i18n': <Map<String, dynamic>>[],
        'fortune_telling': [fortuneData],
      });
      container = ProviderContainer();

      final result = await container.read(
        getFortuneProvider(artistId: 1, year: 2026, language: 'ja').future,
      );
      expect(result.overallLuck, '올해 운세가 좋습니다');
    });
  });
}

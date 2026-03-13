import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/community/fortune.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';
import 'package:picnic_lib/presentation/dialogs/fortune_dialog_helper.dart';

void main() {
  FortuneModel createTestFortune({
    String overallLuck = '좋은 운세',
    int monthCount = 12,
    List<String> advice = const ['조언1', '조언2'],
  }) {
    return FortuneModel(
      id: 'test',
      year: 2025,
      artistId: 1,
      artist: ArtistModel(id: 1, name: {'ko': '지민', 'en': 'Jimin'}),
      overallLuck: overallLuck,
      monthlyFortunes: List.generate(
        monthCount,
        (i) => MonthlyFortuneModel(
          month: i + 1,
          honor: '명예',
          career: '직업',
          health: '건강',
          summary: '요약',
        ),
      ),
      aspects: AspectModel(
        honor: '명예운',
        career: '직업운',
        health: '건강운',
        finances: '재물운',
        relationships: '대인관계운',
      ),
      lucky: LuckyModel(
        days: ['월요일'],
        colors: ['빨간색'],
        numbers: [7],
        directions: ['동쪽'],
      ),
      advice: advice,
    );
  }

  group('FortuneDialogHelper.formatLuckyItems', () {
    test('joins items with comma', () {
      expect(
        FortuneDialogHelper.formatLuckyItems(['월요일', '금요일']),
        '월요일, 금요일',
      );
    });

    test('handles single item', () {
      expect(FortuneDialogHelper.formatLuckyItems(['월요일']), '월요일');
    });

    test('handles empty list', () {
      expect(FortuneDialogHelper.formatLuckyItems([]), '');
    });

    test('handles numbers', () {
      expect(FortuneDialogHelper.formatLuckyItems([3, 7, 11]), '3, 7, 11');
    });
  });

  group('FortuneDialogHelper.findMonthlyFortune', () {
    test('finds correct month', () {
      final fortunes = List.generate(
        12,
        (i) => MonthlyFortuneModel(
          month: i + 1,
          honor: 'h',
          career: 'c',
          health: 'hl',
          summary: 's$i',
        ),
      );
      final result = FortuneDialogHelper.findMonthlyFortune(fortunes, 3);
      expect(result, isNotNull);
      expect(result!.month, 3);
      expect(result.summary, 's2');
    });

    test('returns null for non-existent month', () {
      final fortunes = [
        MonthlyFortuneModel(
            month: 1, honor: 'h', career: 'c', health: 'hl', summary: 's'),
      ];
      expect(FortuneDialogHelper.findMonthlyFortune(fortunes, 13), isNull);
    });

    test('returns null for empty list', () {
      expect(FortuneDialogHelper.findMonthlyFortune([], 1), isNull);
    });
  });

  group('FortuneDialogHelper.countAspectCategories', () {
    test('counts all non-empty aspects', () {
      final aspects = AspectModel(
        honor: '명예',
        career: '직업',
        health: '건강',
        finances: '재물',
        relationships: '대인관계',
      );
      expect(FortuneDialogHelper.countAspectCategories(aspects), 5);
    });

    test('excludes empty aspects', () {
      final aspects = AspectModel(
        honor: '명예',
        career: '',
        health: '건강',
        finances: '',
        relationships: '',
      );
      expect(FortuneDialogHelper.countAspectCategories(aspects), 2);
    });

    test('returns 0 for all empty', () {
      final aspects = AspectModel(
        honor: '',
        career: '',
        health: '',
        finances: '',
        relationships: '',
      );
      expect(FortuneDialogHelper.countAspectCategories(aspects), 0);
    });
  });

  group('FortuneDialogHelper.isLuckyEmpty', () {
    test('returns true when all lists are empty', () {
      final lucky = LuckyModel(
        days: [],
        colors: [],
        numbers: [],
        directions: [],
      );
      expect(FortuneDialogHelper.isLuckyEmpty(lucky), isTrue);
    });

    test('returns false when any list has items', () {
      final lucky = LuckyModel(
        days: ['월요일'],
        colors: [],
        numbers: [],
        directions: [],
      );
      expect(FortuneDialogHelper.isLuckyEmpty(lucky), isFalse);
    });

    test('returns false when all lists have items', () {
      final lucky = LuckyModel(
        days: ['월요일'],
        colors: ['빨간색'],
        numbers: [7],
        directions: ['동쪽'],
      );
      expect(FortuneDialogHelper.isLuckyEmpty(lucky), isFalse);
    });
  });

  group('FortuneDialogHelper.hasValidAdvice', () {
    test('returns true for non-empty advice', () {
      expect(FortuneDialogHelper.hasValidAdvice(['조언1', '조언2']), isTrue);
    });

    test('returns false for empty list', () {
      expect(FortuneDialogHelper.hasValidAdvice([]), isFalse);
    });

    test('returns false for only whitespace strings', () {
      expect(FortuneDialogHelper.hasValidAdvice(['', '  ', '\t']), isFalse);
    });

    test('returns true if at least one non-empty string', () {
      expect(FortuneDialogHelper.hasValidAdvice(['', '유효한 조언']), isTrue);
    });
  });

  group('FortuneDialogHelper.saveOverallExpansionStates', () {
    test('saves states correctly', () {
      final result = FortuneDialogHelper.saveOverallExpansionStates(
        isOverallExpanded: true,
        isLuckyExpanded: false,
        isAdviceExpanded: true,
      );
      expect(result['overall'], isTrue);
      expect(result['lucky'], isFalse);
      expect(result['advice'], isTrue);
    });
  });

  group('FortuneDialogHelper.saveMonthlyExpansionStates', () {
    test('creates a copy of the states', () {
      final original = {1: true, 2: false, 3: true};
      final result = FortuneDialogHelper.saveMonthlyExpansionStates(original);
      expect(result, original);
      // Verify it's a copy, not the same reference
      result[1] = false;
      expect(original[1], isTrue);
    });
  });

  group('FortuneDialogHelper.resolveArtistName', () {
    test('returns locale-matched name', () {
      final name = {'ko': '지민', 'en': 'Jimin'};
      expect(FortuneDialogHelper.resolveArtistName(name, 'ko'), '지민');
      expect(FortuneDialogHelper.resolveArtistName(name, 'en'), 'Jimin');
    });

    test('falls back to ko when locale not found', () {
      final name = {'ko': '지민'};
      expect(FortuneDialogHelper.resolveArtistName(name, 'ja'), '지민');
    });

    test('falls back to en when ko not found', () {
      final name = {'en': 'Jimin'};
      expect(FortuneDialogHelper.resolveArtistName(name, 'ja'), 'Jimin');
    });

    test('returns empty string for null map', () {
      expect(FortuneDialogHelper.resolveArtistName(null, 'ko'), '');
    });

    test('returns empty string when no names available', () {
      expect(FortuneDialogHelper.resolveArtistName({}, 'ko'), '');
    });
  });

  group('FortuneDialogHelper.isFortuneComplete', () {
    test('returns true for complete fortune', () {
      final fortune = createTestFortune();
      expect(FortuneDialogHelper.isFortuneComplete(fortune), isTrue);
    });

    test('returns false when overallLuck is empty', () {
      final fortune = createTestFortune(overallLuck: '');
      expect(FortuneDialogHelper.isFortuneComplete(fortune), isFalse);
    });

    test('returns false when monthlyFortunes incomplete', () {
      final fortune = createTestFortune(monthCount: 6);
      expect(FortuneDialogHelper.isFortuneComplete(fortune), isFalse);
    });

    test('returns false when advice is empty', () {
      final fortune = createTestFortune(advice: []);
      expect(FortuneDialogHelper.isFortuneComplete(fortune), isFalse);
    });
  });
}

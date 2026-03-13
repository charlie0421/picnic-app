import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/pages/my_page/faq_page_helper.dart';

void main() {
  group('FAQPageHelper.getLocalizedText', () {
    test('returns text for requested language', () {
      final json = {'ko': '한국어', 'en': 'English', 'ja': '日本語'};
      expect(FAQPageHelper.getLocalizedText(json, 'ko'), '한국어');
      expect(FAQPageHelper.getLocalizedText(json, 'en'), 'English');
      expect(FAQPageHelper.getLocalizedText(json, 'ja'), '日本語');
    });

    test('falls back to en when language is missing', () {
      final json = {'en': 'English'};
      expect(FAQPageHelper.getLocalizedText(json, 'ko'), 'English');
    });

    test('returns empty string when no en fallback', () {
      final json = <String, dynamic>{'ja': '日本語'};
      expect(FAQPageHelper.getLocalizedText(json, 'ko'), '');
    });

    test('returns empty string for empty map', () {
      expect(FAQPageHelper.getLocalizedText({}, 'ko'), '');
    });

    test('handles null value for language key', () {
      final json = <String, dynamic>{'ko': null, 'en': 'English'};
      expect(FAQPageHelper.getLocalizedText(json, 'ko'), 'English');
    });
  });

  group('FAQPageHelper.getLocalizedDelta', () {
    test('returns null for null input', () {
      expect(FAQPageHelper.getLocalizedDelta(null, 'ko'), isNull);
    });

    test('returns delta for requested language', () {
      final delta = {
        'ko': {'ops': [{'insert': '한국어\n'}]},
        'en': {'ops': [{'insert': 'English\n'}]},
      };
      final result = FAQPageHelper.getLocalizedDelta(delta, 'en');
      expect(result, isNotNull);
      expect((result!['ops'] as List).first['insert'], 'English\n');
    });

    test('falls back to ko when requested language missing', () {
      final delta = {
        'ko': {'ops': [{'insert': '한국어\n'}]},
      };
      final result = FAQPageHelper.getLocalizedDelta(delta, 'en');
      expect(result, isNotNull);
      expect((result!['ops'] as List).first['insert'], '한국어\n');
    });

    test('returns null when no ko fallback either', () {
      final delta = {
        'ja': {'ops': [{'insert': '日本語\n'}]},
      };
      expect(FAQPageHelper.getLocalizedDelta(delta, 'en'), isNull);
    });

    test('prefers exact language match over ko fallback', () {
      final delta = {
        'ko': {'ops': [{'insert': '한국어\n'}]},
        'en': {'ops': [{'insert': 'English\n'}]},
      };
      final result = FAQPageHelper.getLocalizedDelta(delta, 'en');
      expect((result!['ops'] as List).first['insert'], 'English\n');
    });

    test('handles null value for requested language key', () {
      final delta = <String, dynamic>{
        'en': null,
        'ko': {'ops': [{'insert': '한국어\n'}]},
      };
      final result = FAQPageHelper.getLocalizedDelta(delta, 'en');
      expect(result, isNotNull);
      expect((result!['ops'] as List).first['insert'], '한국어\n');
    });
  });

  group('FAQPageHelper.extractPlainTextFromDelta', () {
    test('extracts text from valid delta', () {
      final delta = {
        'ops': [
          {'insert': 'Hello '},
          {'insert': 'World\n'},
        ],
      };
      expect(FAQPageHelper.extractPlainTextFromDelta(delta), 'Hello World\n');
    });

    test('returns empty string for null ops', () {
      expect(FAQPageHelper.extractPlainTextFromDelta({}), '');
    });

    test('returns empty string for empty ops', () {
      expect(FAQPageHelper.extractPlainTextFromDelta({'ops': []}), '');
    });

    test('skips non-string inserts (e.g. image embeds)', () {
      final delta = {
        'ops': [
          {'insert': 'Before '},
          {'insert': {'image': 'https://example.com/img.png'}},
          {'insert': 'After\n'},
        ],
      };
      expect(
        FAQPageHelper.extractPlainTextFromDelta(delta),
        'Before After\n',
      );
    });

    test('skips non-map entries in ops', () {
      final delta = {
        'ops': [
          {'insert': 'Text\n'},
          'not a map',
          42,
        ],
      };
      expect(FAQPageHelper.extractPlainTextFromDelta(delta), 'Text\n');
    });

    test('handles ops with attributes (styled text)', () {
      final delta = {
        'ops': [
          {'insert': 'Bold', 'attributes': {'bold': true}},
          {'insert': ' normal\n'},
        ],
      };
      expect(
        FAQPageHelper.extractPlainTextFromDelta(delta),
        'Bold normal\n',
      );
    });
  });

  group('FAQPageHelper.getFilteredFaqs', () {
    final faqs = [
      {'question': {'ko': 'Q1'}, 'category': 'ACCOUNT'},
      {'question': {'ko': 'Q2'}, 'category': 'PAYMENT'},
      {'question': {'ko': 'Q3'}, 'category': 'ACCOUNT'},
      {'question': {'ko': 'Q4'}, 'category': 'ETC'},
    ];

    test('returns all faqs when category is ALL', () {
      final result = FAQPageHelper.getFilteredFaqs(faqs, 'ALL');
      expect(result.length, 4);
    });

    test('returns all faqs when category is null', () {
      final result = FAQPageHelper.getFilteredFaqs(faqs, null);
      expect(result.length, 4);
    });

    test('filters by specific category', () {
      final result = FAQPageHelper.getFilteredFaqs(faqs, 'ACCOUNT');
      expect(result.length, 2);
      expect(result.every((f) => f['category'] == 'ACCOUNT'), isTrue);
    });

    test('returns empty list for non-existent category', () {
      final result = FAQPageHelper.getFilteredFaqs(faqs, 'NONEXISTENT');
      expect(result, isEmpty);
    });

    test('returns empty list when faqs list is empty', () {
      final result = FAQPageHelper.getFilteredFaqs([], 'ACCOUNT');
      expect(result, isEmpty);
    });

    test('single category match', () {
      final result = FAQPageHelper.getFilteredFaqs(faqs, 'PAYMENT');
      expect(result.length, 1);
      expect(result.first['question'], {'ko': 'Q2'});
    });
  });

  group('FAQPageHelper.buildCategoriesList', () {
    test('returns ALL only for empty data', () {
      final result = FAQPageHelper.buildCategoriesList([]);
      expect(result, ['ALL']);
    });

    test('prepends ALL to category codes', () {
      final categoriesData = [
        {'code': 'ACCOUNT', 'label': {'ko': '계정'}},
        {'code': 'PAYMENT', 'label': {'ko': '결제'}},
      ];
      final result = FAQPageHelper.buildCategoriesList(categoriesData);
      expect(result, ['ALL', 'ACCOUNT', 'PAYMENT']);
    });

    test('skips entries without code', () {
      final categoriesData = [
        {'code': 'ACCOUNT', 'label': {'ko': '계정'}},
        {'label': {'ko': '코드 없음'}},
        {'code': 'PAYMENT', 'label': {'ko': '결제'}},
      ];
      final result = FAQPageHelper.buildCategoriesList(categoriesData);
      expect(result, ['ALL', 'ACCOUNT', 'PAYMENT']);
    });

    test('skips entries with null code', () {
      final categoriesData = <Map<String, dynamic>>[
        {'code': 'ACCOUNT', 'label': {'ko': '계정'}},
        {'code': null, 'label': {'ko': '널'}},
      ];
      final result = FAQPageHelper.buildCategoriesList(categoriesData);
      expect(result, ['ALL', 'ACCOUNT']);
    });
  });

  group('FAQPageHelper.getLocalizedCategoryLabel', () {
    final categoriesData = <Map<String, dynamic>>[
      {
        'code': 'ACCOUNT',
        'label': <String, dynamic>{'ko': '계정', 'en': 'Account'},
      },
      {
        'code': 'PAYMENT',
        'label': <String, dynamic>{'ko': '결제', 'en': 'Payment'},
      },
    ];

    test('returns allLabel for ALL category', () {
      final result = FAQPageHelper.getLocalizedCategoryLabel(
        'ALL',
        'ko',
        categoriesData,
        allLabel: '전체',
      );
      expect(result, '전체');
    });

    test('returns localized label for known category', () {
      final result = FAQPageHelper.getLocalizedCategoryLabel(
        'ACCOUNT',
        'ko',
        categoriesData,
        allLabel: '전체',
      );
      expect(result, '계정');
    });

    test('returns en label when language is en', () {
      final result = FAQPageHelper.getLocalizedCategoryLabel(
        'PAYMENT',
        'en',
        categoriesData,
        allLabel: 'All',
      );
      expect(result, 'Payment');
    });

    test('falls back to categoryCode for unknown category', () {
      final result = FAQPageHelper.getLocalizedCategoryLabel(
        'UNKNOWN',
        'ko',
        categoriesData,
        allLabel: '전체',
      );
      expect(result, 'UNKNOWN');
    });

    test('falls back to categoryCode when label is not a map', () {
      final badData = [
        {'code': 'BAD', 'label': 'plain string'},
      ];
      final result = FAQPageHelper.getLocalizedCategoryLabel(
        'BAD',
        'ko',
        badData,
        allLabel: '전체',
      );
      expect(result, 'BAD');
    });

    test('falls back to categoryCode for empty categoriesData', () {
      final result = FAQPageHelper.getLocalizedCategoryLabel(
        'ACCOUNT',
        'ko',
        [],
        allLabel: '전체',
      );
      expect(result, 'ACCOUNT');
    });

    test('uses en fallback when requested language missing in label', () {
      final data = <Map<String, dynamic>>[
        {
          'code': 'TEST',
          'label': <String, dynamic>{'en': 'Test Category'},
        },
      ];
      final result = FAQPageHelper.getLocalizedCategoryLabel(
        'TEST',
        'ja',
        data,
        allLabel: '全て',
      );
      expect(result, 'Test Category');
    });
  });
}

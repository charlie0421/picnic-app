import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/korean_search_utils.dart';

import '../../helpers/test_environment.dart';

void main() {
  setUpAll(() {
    initTestColors();
  });

  group('extractKoreanInitials', () {
    test('extracts initials from Korean text', () {
      expect(KoreanSearchUtils.extractKoreanInitials('방탄소년단'), 'ㅂㅌㅅㄴㄷ');
    });

    test('keeps non-Korean characters as is', () {
      expect(KoreanSearchUtils.extractKoreanInitials('BTS'), 'BTS');
    });

    test('mixed Korean and English', () {
      expect(KoreanSearchUtils.extractKoreanInitials('방탄BTS'), 'ㅂㅌBTS');
    });

    test('empty string', () {
      expect(KoreanSearchUtils.extractKoreanInitials(''), '');
    });

    test('various Korean words', () {
      expect(KoreanSearchUtils.extractKoreanInitials('블랙핑크'), 'ㅂㄹㅍㅋ');
      expect(KoreanSearchUtils.extractKoreanInitials('가나다'), 'ㄱㄴㄷ');
      expect(KoreanSearchUtils.extractKoreanInitials('아이유'), 'ㅇㅇㅇ');
    });

    test('Korean with numbers', () {
      expect(KoreanSearchUtils.extractKoreanInitials('투표123'), 'ㅌㅍ123');
    });
  });

  group('matchesKoreanInitials', () {
    test('matches by exact text', () {
      expect(KoreanSearchUtils.matchesKoreanInitials('방탄소년단', '방탄'), isTrue);
    });

    test('matches by initials', () {
      expect(
          KoreanSearchUtils.matchesKoreanInitials('방탄소년단', 'ㅂㅌㅅ'), isTrue);
    });

    test('matches case insensitive English', () {
      expect(KoreanSearchUtils.matchesKoreanInitials('BTS', 'bt'), isTrue);
    });

    test('returns false for empty text', () {
      expect(KoreanSearchUtils.matchesKoreanInitials('', 'ㅂㅌ'), isFalse);
    });

    test('returns false for empty query', () {
      expect(KoreanSearchUtils.matchesKoreanInitials('방탄소년단', ''), isFalse);
    });

    test('returns false for non-matching initials', () {
      expect(
          KoreanSearchUtils.matchesKoreanInitials('방탄소년단', 'ㅎㄱ'), isFalse);
    });

    test('matches full initials', () {
      expect(
          KoreanSearchUtils.matchesKoreanInitials('블랙핑크', 'ㅂㄹㅍㅋ'), isTrue);
    });

    test('matches partial initials from middle', () {
      expect(
          KoreanSearchUtils.matchesKoreanInitials('방탄소년단', 'ㅅㄴ'), isTrue);
    });

    test('does not match non-consecutive initials', () {
      expect(
          KoreanSearchUtils.matchesKoreanInitials('방탄소년단', 'ㅂㅅ'), isFalse);
    });

    test('query longer than text does not match', () {
      expect(KoreanSearchUtils.matchesKoreanInitials('가', 'ㄱㄴㄷ'), isFalse);
    });
  });

  group('buildHighlightedTextSpans', () {
    test('returns single span for empty query', () {
      final spans = KoreanSearchUtils.buildHighlightedTextSpans('hello', '');
      expect(spans.length, 1);
      expect(spans[0].text, 'hello');
    });

    test('returns single span for empty text', () {
      final spans = KoreanSearchUtils.buildHighlightedTextSpans('', 'query');
      expect(spans.length, 1);
      expect(spans[0].text, '');
    });

    test('highlights matching text', () {
      final spans =
          KoreanSearchUtils.buildHighlightedTextSpans('hello world', 'world');
      expect(spans.length, 2);
      expect(spans[0].text, 'hello ');
      expect(spans[1].text, 'world');
      expect(spans[1].style?.fontWeight, FontWeight.bold);
    });

    test('highlights multiple matches', () {
      final spans =
          KoreanSearchUtils.buildHighlightedTextSpans('ab ab ab', 'ab');
      expect(spans.length, 5);
    });

    test('case insensitive highlight', () {
      final spans =
          KoreanSearchUtils.buildHighlightedTextSpans('Hello World', 'hello');
      expect(spans.length, 2);
      expect(spans[0].text, 'Hello');
      expect(spans[0].style?.fontWeight, FontWeight.bold);
      expect(spans[1].text, ' World');
    });

    test('highlights Korean initials match', () {
      final spans =
          KoreanSearchUtils.buildHighlightedTextSpans('방탄소년단', 'ㅂㅌㅅㄴㄷ');
      expect(spans.length, 1);
      expect(spans[0].text, '방탄소년단');
      expect(spans[0].style?.fontWeight, FontWeight.bold);
    });

    test('returns plain span for non-matching query', () {
      final spans =
          KoreanSearchUtils.buildHighlightedTextSpans('hello', 'xyz');
      expect(spans.length, 1);
      expect(spans[0].text, 'hello');
      expect(spans[0].style?.fontWeight, isNull);
    });

    test('with custom baseStyle', () {
      const style = TextStyle(fontSize: 16, color: Colors.red);
      final spans = KoreanSearchUtils.buildHighlightedTextSpans(
        'hello world',
        'world',
        baseStyle: style,
      );
      expect(spans[0].style, style);
      expect(spans[1].style?.fontSize, 16);
    });

    test('with custom highlightColor', () {
      final spans = KoreanSearchUtils.buildHighlightedTextSpans(
        'hello world',
        'world',
        highlightColor: Colors.yellow,
      );
      expect(spans[1].style?.backgroundColor, Colors.yellow);
    });

    test('highlight at start of text', () {
      final spans =
          KoreanSearchUtils.buildHighlightedTextSpans('hello world', 'hello');
      expect(spans.length, 2);
      expect(spans[0].text, 'hello');
      expect(spans[0].style?.fontWeight, FontWeight.bold);
      expect(spans[1].text, ' world');
    });

    test('highlight entire text', () {
      final spans =
          KoreanSearchUtils.buildHighlightedTextSpans('hello', 'hello');
      expect(spans.length, 1);
      expect(spans[0].text, 'hello');
      expect(spans[0].style?.fontWeight, FontWeight.bold);
    });
  });

  group('getMatchingText', () {
    test('matches Korean text', () {
      final nameMap = {'ko': '방탄소년단', 'en': 'BTS'};
      expect(KoreanSearchUtils.getMatchingText(nameMap, '방탄'), '방탄소년단');
    });

    test('matches Korean initials', () {
      final nameMap = {'ko': '방탄소년단', 'en': 'BTS'};
      expect(KoreanSearchUtils.getMatchingText(nameMap, 'ㅂㅌㅅ'), '방탄소년단');
    });

    test('matches English text', () {
      final nameMap = {'ko': '방탄소년단', 'en': 'BTS'};
      expect(KoreanSearchUtils.getMatchingText(nameMap, 'bts'), 'BTS');
    });

    test('matches Japanese text', () {
      final nameMap = {'ko': '방탄소년단', 'en': 'BTS', 'ja': '防弾少年団'};
      expect(KoreanSearchUtils.getMatchingText(nameMap, '防弾'), '防弾少年団');
    });

    test('matches simplified Chinese text', () {
      final nameMap = {
        'ko': '방탄소년단',
        'en': 'BTS',
        'zh_CN': '防弹少年团',
      };
      expect(KoreanSearchUtils.getMatchingText(nameMap, '防弹'), '防弹少年团');
    });

    test('matches traditional Chinese text', () {
      final nameMap = {
        'ko': '방탄소년단',
        'en': 'BTS',
        'zh_TW': '防彈少年團',
      };
      expect(KoreanSearchUtils.getMatchingText(nameMap, '防彈'), '防彈少年團');
    });

    test('handles missing language keys', () {
      final nameMap = {'en': 'BTS'};
      final result = KoreanSearchUtils.getMatchingText(nameMap, 'bts');
      expect(result, 'BTS');
    });
  });

  group('buildHighlightedRichText', () {
    test('returns RichText widget', () {
      final widget = KoreanSearchUtils.buildHighlightedRichText(
        'hello world',
        'world',
        const TextStyle(fontSize: 14),
      );
      expect(widget, isA<RichText>());
    });

    test('with overflow and maxLines', () {
      final widget = KoreanSearchUtils.buildHighlightedRichText(
        'hello world',
        'world',
        const TextStyle(fontSize: 14),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      );
      expect(widget, isA<RichText>());
    });
  });

  group('buildConditionalHighlightText', () {
    test('returns Text widget for empty query', () {
      final widget = KoreanSearchUtils.buildConditionalHighlightText(
        'hello',
        '',
        const TextStyle(fontSize: 14),
      );
      expect(widget, isA<Text>());
    });

    test('returns RichText widget for non-empty query', () {
      final widget = KoreanSearchUtils.buildConditionalHighlightText(
        'hello world',
        'world',
        const TextStyle(fontSize: 14),
      );
      expect(widget, isA<RichText>());
    });

    test('with overflow and maxLines for Text', () {
      final widget = KoreanSearchUtils.buildConditionalHighlightText(
        'hello',
        '',
        const TextStyle(fontSize: 14),
        overflow: TextOverflow.ellipsis,
        maxLines: 2,
      );
      expect(widget, isA<Text>());
      final textWidget = widget as Text;
      expect(textWidget.overflow, TextOverflow.ellipsis);
      expect(textWidget.maxLines, 2);
    });
  });
}

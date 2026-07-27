import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/pages/my_page/faq_page.dart';

import '../../../helpers/ignore_image_errors.dart';
import '../../../helpers/mock_supabase.dart';
import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

void main() {
  late void Function() restore;

  setUp(() {
    initTestColors();
    setupMockSupabase({
      'faqs': <dynamic>[],
      'faq_categories': <dynamic>[],
    });
    restore = suppressImageErrors();
  });

  tearDown(() {
    restore();
    tearDownMockSupabase();
  });

  Future<void> pumpAndDrain(WidgetTester tester, Widget widget) async {
    // 첫 프레임부터 필터가 걸려 있어야 한다 — 그래야 그 프레임의 에러가
    // FlutterErrorDetails 째로 잡혀서, 진짜 결함일 때 "어느 위젯이 원인인지"까지
    // 보고된다. raw pumpWidget 으로 먼저 그리면 그 정보가 사라진다.
    await pumpWidgetAndIgnoreErrors(tester, widget);
    await tester.pump(const Duration(seconds: 1));
    drainExpectedImageErrors(tester);
  }

  group('FAQPage render', () {
    testWidgets('renders with empty data shows no results',
        (WidgetTester tester) async {
      await pumpAndDrain(tester, buildTestAppPage(const FAQPage()));
      await tester.pump(const Duration(milliseconds: 500));
      drainExpectedImageErrors(tester);

      expect(find.byType(FAQPage), findsOneWidget);
    });

    testWidgets('renders with FAQ data and categories',
        (WidgetTester tester) async {
      setupMockSupabase({
        'faqs': [
          {
            'id': 1,
            'category': 'general',
            'question': {'ko': 'FAQ 질문 1', 'en': 'FAQ Question 1'},
            'answer': {'ko': 'FAQ 답변 1', 'en': 'FAQ Answer 1'},
            'answer_delta': null,
            'status': 'PUBLISHED',
            'order_number': 1,
          },
          {
            'id': 2,
            'category': 'account',
            'question': {'ko': '계정 질문', 'en': 'Account Question'},
            'answer': {'ko': '계정 답변', 'en': 'Account Answer'},
            'answer_delta': null,
            'status': 'PUBLISHED',
            'order_number': 2,
          },
        ],
        'faq_categories': [
          {
            'code': 'general',
            'label': {'ko': '일반', 'en': 'General'},
            'order_number': 1,
            'active': true,
          },
          {
            'code': 'account',
            'label': {'ko': '계정', 'en': 'Account'},
            'order_number': 2,
            'active': true,
          },
        ],
      });

      await pumpAndDrain(tester, buildTestAppPage(const FAQPage()));
      await tester.pump(const Duration(milliseconds: 500));
      drainExpectedImageErrors(tester);

      expect(find.byType(FAQPage), findsOneWidget);
      // Should show category chips
      expect(find.byType(ChoiceChip), findsWidgets);
    });

    testWidgets('renders with answer_delta (Quill content)',
        (WidgetTester tester) async {
      setupMockSupabase({
        'faqs': [
          {
            'id': 1,
            'category': 'general',
            'question': {'ko': 'Delta 질문', 'en': 'Delta Question'},
            'answer': {'ko': 'Delta 답변', 'en': 'Delta Answer'},
            'answer_delta': {
              'ko': {
                'ops': [
                  {'insert': '이것은 리치 텍스트 답변입니다.\n'},
                ],
              },
              'en': {
                'ops': [
                  {'insert': 'This is a rich text answer.\n'},
                ],
              },
            },
            'status': 'PUBLISHED',
            'order_number': 1,
          },
        ],
        'faq_categories': [
          {
            'code': 'general',
            'label': {'ko': '일반', 'en': 'General'},
            'order_number': 1,
            'active': true,
          },
        ],
      });

      await pumpAndDrain(tester, buildTestAppPage(const FAQPage()));
      await tester.pump(const Duration(milliseconds: 500));
      drainExpectedImageErrors(tester);

      expect(find.byType(FAQPage), findsOneWidget);
      // Tap the expansion tile to show the answer
      final expansionTile = find.byType(ExpansionTile);
      if (expansionTile.evaluate().isNotEmpty) {
        await tester.tap(expansionTile.first);
        await tester.pump(const Duration(milliseconds: 500));
        drainExpectedImageErrors(tester);
      }
    });

    testWidgets('renders with multiple categories and filters',
        (WidgetTester tester) async {
      setupMockSupabase({
        'faqs': [
          {
            'id': 1,
            'category': 'general',
            'question': {'ko': '일반 질문', 'en': 'General Question'},
            'answer': {'ko': '일반 답변', 'en': 'General Answer'},
            'answer_delta': null,
            'status': 'PUBLISHED',
            'order_number': 1,
          },
          {
            'id': 2,
            'category': 'payment',
            'question': {'ko': '결제 질문', 'en': 'Payment Question'},
            'answer': {'ko': '결제 답변', 'en': 'Payment Answer'},
            'answer_delta': null,
            'status': 'PUBLISHED',
            'order_number': 2,
          },
        ],
        'faq_categories': [
          {
            'code': 'general',
            'label': {'ko': '일반', 'en': 'General'},
            'order_number': 1,
            'active': true,
          },
          {
            'code': 'payment',
            'label': {'ko': '결제', 'en': 'Payment'},
            'order_number': 2,
            'active': true,
          },
        ],
      });

      await pumpAndDrain(tester, buildTestAppPage(const FAQPage()));
      await tester.pump(const Duration(milliseconds: 500));
      drainExpectedImageErrors(tester);

      // Tap a category chip to filter
      final chips = find.byType(ChoiceChip);
      if (chips.evaluate().length > 1) {
        await tester.tap(chips.at(1));
        await tester.pump(const Duration(milliseconds: 300));
        drainExpectedImageErrors(tester);
      }

      expect(find.byType(FAQPage), findsOneWidget);
    });

    testWidgets('renders with English locale', (WidgetTester tester) async {
      setupMockSupabase({
        'faqs': [
          {
            'id': 1,
            'category': 'general',
            'question': {'ko': 'FAQ 질문', 'en': 'FAQ Question'},
            'answer': {'ko': 'FAQ 답변', 'en': 'FAQ Answer'},
            'answer_delta': null,
            'status': 'PUBLISHED',
            'order_number': 1,
          },
        ],
        'faq_categories': [
          {
            'code': 'general',
            'label': {'ko': '일반', 'en': 'General'},
            'order_number': 1,
            'active': true,
          },
        ],
      });

      await pumpAndDrain(
        tester,
        buildTestAppPage(const FAQPage(), locale: const Locale('en')),
      );
      await tester.pump(const Duration(milliseconds: 500));
      drainExpectedImageErrors(tester);

      expect(find.byType(FAQPage), findsOneWidget);
    });

    testWidgets('renders with Japanese locale', (WidgetTester tester) async {
      setupMockSupabase({
        'faqs': [
          {
            'id': 1,
            'category': 'general',
            'question': {'ko': 'FAQ 질문', 'ja': 'FAQ質問'},
            'answer': {'ko': 'FAQ 답변', 'ja': 'FAQ回答'},
            'answer_delta': null,
            'status': 'PUBLISHED',
            'order_number': 1,
          },
        ],
        'faq_categories': [
          {
            'code': 'general',
            'label': {'ko': '일반', 'ja': '一般'},
            'order_number': 1,
            'active': true,
          },
        ],
      });

      await pumpAndDrain(
        tester,
        buildTestAppPage(const FAQPage(), locale: const Locale('ja')),
      );
      await tester.pump(const Duration(milliseconds: 500));
      drainExpectedImageErrors(tester);

      expect(find.byType(FAQPage), findsOneWidget);
    });

    testWidgets('renders with category without label map',
        (WidgetTester tester) async {
      setupMockSupabase({
        'faqs': [
          {
            'id': 1,
            'category': 'unknown_cat',
            'question': {'ko': '질문'},
            'answer': {'ko': '답변'},
            'answer_delta': null,
            'status': 'PUBLISHED',
            'order_number': 1,
          },
        ],
        'faq_categories': [
          {
            'code': 'unknown_cat',
            'label': 'not-a-map',
            'order_number': 1,
            'active': true,
          },
        ],
      });

      await pumpAndDrain(tester, buildTestAppPage(const FAQPage()));
      await tester.pump(const Duration(milliseconds: 500));
      drainExpectedImageErrors(tester);

      expect(find.byType(FAQPage), findsOneWidget);
    });
  });
}

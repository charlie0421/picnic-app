import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/pages/my_page/faq_page.dart';
import 'package:picnic_lib/presentation/pages/my_page/notice_page.dart';
import 'package:picnic_lib/presentation/widgets/ui/picnic_filter_chip.dart';

import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

void main() {
  setUp(initTestColors);

  testWidgets('notice distinguishes first failure and retries to true data', (
    tester,
  ) async {
    var attempts = 0;
    await tester.pumpWidget(
      buildTestApp(
        NoticePage(
          loadNotices: () async {
            attempts++;
            if (attempts == 1) throw StateError('private failure');
            return [
              {
                'id': 1,
                'title': {'ko': '공지 성공', 'en': 'success'},
                'content': {'ko': '본문', 'en': 'body'},
                'created_at': '2026-09-13',
              },
            ];
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const ValueKey('notice-retry')), findsOneWidget);
    expect(find.textContaining('private failure'), findsNothing);
    await tester.tap(find.widgetWithText(OutlinedButton, '재시도'));
    await tester.pump();
    await tester.pump();
    expect(find.text('공지 성공'), findsOneWidget);
  });

  testWidgets('FAQ commits rows and categories together after retry', (
    tester,
  ) async {
    var attempts = 0;
    await tester.pumpWidget(
      buildTestApp(
        FAQPage(
          loadContent: () async {
            attempts++;
            if (attempts == 1) throw StateError('private failure');
            return FAQContent(
              faqs: [
                {
                  'id': 1,
                  'category': 'ACCOUNT',
                  'question': {'ko': '질문', 'en': 'question'},
                  'answer': {'ko': '답변', 'en': 'answer'},
                },
              ],
              categories: [
                {
                  'code': 'ACCOUNT',
                  'label': {'ko': '계정', 'en': 'account'},
                },
              ],
            );
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const ValueKey('faq-retry')), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, '재시도'));
    await tester.pump();
    await tester.pump();
    expect(find.text('질문'), findsOneWidget);
    expect(find.text('계정'), findsWidgets);
  });

  testWidgets('notice refresh failure keeps previously loaded rows', (
    tester,
  ) async {
    var attempts = 0;
    await tester.pumpWidget(
      buildTestApp(
        NoticePage(
          loadNotices: () async {
            attempts++;
            if (attempts > 1) throw StateError('refresh failed');
            return [
              {
                'id': 1,
                'title': {'ko': '보존될 공지'},
                'content': {'ko': '본문'},
                'created_at': '2026-09-13',
              },
            ];
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('보존될 공지'), findsOneWidget);

    final refreshFuture = tester
        .state<RefreshIndicatorState>(find.byType(RefreshIndicator))
        .show();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await refreshFuture;
    expect(find.text('보존될 공지'), findsOneWidget);
    expect(find.byKey(const ValueKey('notice-retry')), findsOneWidget);
  });

  testWidgets(
    'successful empty notice and FAQ responses are true empty states',
    (tester) async {
      await tester.pumpWidget(
        buildTestApp(NoticePage(loadNotices: () async => const [])),
      );
      await tester.pump();
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byKey(const ValueKey('notice-retry')), findsNothing);

      await tester.pumpWidget(
        buildTestApp(
          FAQPage(
            loadContent: () async => const FAQContent(faqs: [], categories: []),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byKey(const ValueKey('faq-retry')), findsNothing);
    },
  );

  testWidgets(
    'FAQ refresh failure retains rows and a removed selection resets to ALL',
    (tester) async {
      var attempts = 0;
      var failRefresh = true;
      Future<FAQContent> load() async {
        attempts++;
        if (attempts == 2 && failRefresh) throw StateError('refresh failed');
        if (attempts >= 2) {
          return const FAQContent(
            faqs: [
              {
                'id': 2,
                'category': 'B',
                'question': {'ko': '질문 B'},
                'answer': {'ko': '답 B'},
              },
            ],
            categories: [
              {
                'code': 'B',
                'label': {'ko': '분류 B'},
              },
            ],
          );
        }
        return const FAQContent(
          faqs: [
            {
              'id': 1,
              'category': 'A',
              'question': {'ko': '보존될 질문'},
              'answer': {'ko': '답 A'},
            },
          ],
          categories: [
            {
              'code': 'A',
              'label': {'ko': '분류 A'},
            },
          ],
        );
      }

      await tester.pumpWidget(buildTestApp(FAQPage(loadContent: load)));
      await tester.pump();
      await tester.pump();
      await tester.tap(find.text('분류 A').first);
      await tester.pump();

      var refresh = tester
          .state<RefreshIndicatorState>(find.byType(RefreshIndicator))
          .show();
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await refresh;
      expect(find.text('보존될 질문'), findsOneWidget);
      expect(find.byKey(const ValueKey('faq-retry')), findsOneWidget);

      failRefresh = false;
      refresh = tester
          .state<RefreshIndicatorState>(find.byType(RefreshIndicator))
          .show();
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await refresh;
      expect(find.text('질문 B'), findsOneWidget);
      final allChip = tester.widget<PicnicFilterChip>(
        find.widgetWithText(PicnicFilterChip, '전체'),
      );
      expect(allChip.selected, isTrue);
    },
  );
}

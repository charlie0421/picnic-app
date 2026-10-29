import 'package:picnic_lib/core/services/notification_inbox_service.dart';
import 'package:picnic_lib/data/storage/broadcast_notification_read_store.dart';
import 'package:picnic_lib/presentation/pages/my_page/currency_history_page.dart';
import 'package:picnic_lib/presentation/pages/my_page/vote_history_page.dart';
import 'package:picnic_lib/presentation/pages/notifications/notifications_page.dart';
import 'package:picnic_lib/presentation/providers/wallet_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/store_list_tile.dart';
import 'package:picnic_lib/presentation/widgets/vote/vote_history_list_item.dart';
import 'package:picnic_lib/presentation/widgets/wallet/currency_history_list_item.dart';
import '../../helpers/extended_ui_fixtures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:picnic_lib/data/models/qna/qna_category.dart';
import 'package:picnic_lib/data/repositories/qna_repository.dart';
import 'package:picnic_lib/presentation/pages/my_page/my_profile.dart';
import 'package:picnic_lib/presentation/pages/my_page/setting_page.dart';
import 'package:picnic_lib/presentation/pages/my_page/notice_page.dart';
import 'package:picnic_lib/presentation/pages/my_page/faq_page.dart';
import 'package:picnic_lib/presentation/pages/my_page/qna/qna_thread_create_page.dart';
import 'package:picnic_lib/supabase_options.dart';
import '../../helpers/foldable_test_app.dart';
import '../../helpers/ignore_image_errors.dart';
import '../../helpers/load_test_fonts.dart';
import '../../helpers/mock_supabase.dart';
import '../../helpers/test_environment.dart';

const longCopy =
    'Very long translated information about voting and account settings';

class LayoutQnaRepository extends QnaRepository {
  LayoutQnaRepository() : super(client: testSupabaseClient);
  @override
  Future<List<QnaCategory>> getCategories() async => [
    QnaCategory(code: 'general', label: longCopy),
  ];
}

Future<void> frames(WidgetTester tester, [int count = 12]) async {
  for (var i = 0; i < count; i++) {
    await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));
  }
}

Future<void> showPage(
  WidgetTester tester,
  Widget page,
  Size size,
  double scale,
  String language, {
  List<dynamic> overrides = const [],
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
  await pumpWidgetAndIgnoreErrors(
    tester,
    buildFoldableTestApp(
      page,
      textScale: scale,
      locale: Locale(language),
      overrides: overrides,
    ),
  );
  await frames(tester);
}

// Preserve every digit at the requested text scale. A narrow window may wrap
// an amount; truncation, ellipsis and boxes outside the paragraph are failures.
void expectCompleteAmount(WidgetTester tester, String value, int count) {
  final amounts = find.text(value);
  expect(amounts, findsNWidgets(count));
  for (var i = 0; i < count; i++) {
    final paragraph = tester.renderObject<RenderParagraph>(amounts.at(i));
    expect(paragraph.didExceedMaxLines, isFalse);
    final boxes = paragraph.getBoxesForSelection(
      TextSelection(baseOffset: 0, extentOffset: value.length),
    );
    expect(boxes, isNotEmpty);
    for (final box in boxes) {
      expect(box.left, greaterThanOrEqualTo(-1));
      expect(box.right, lessThanOrEqualTo(paragraph.size.width + 1));
      expect(box.bottom, lessThanOrEqualTo(paragraph.size.height + 1));
    }
  }
}

void main() {
  setUpAll(loadTestFonts);
  setUp(() async {
    initTestColors();
    resetFoldableTestPlugins();
    PackageInfo.setMockInitialValues(
      appName: 'Picnic',
      packageName: 'test.picnic',
      version: '1.0',
      buildNumber: '1',
      buildSignature: '',
    );
    await setupMockSupabaseWithAuth(
      extendedScreenFixtures(),
      userId: 'test-user-id',
    );
  });
  tearDown(tearDownMockSupabase);
  for (final size in [
    const Size(320, 600),
    const Size(800, 600),
    const Size(600, 400),
  ]) {
    for (final scale in [1.0, 2.6]) {
      for (final language in ['ko', 'en', 'es']) {
        final name = '$size text=$scale $language';
        testWidgets('vote history amounts fit $name', (tester) async {
          await showPage(
            tester,
            const VoteHistoryPage(),
            size,
            scale,
            language,
          );
          expect(find.byType(VoteHistoryListItem), findsOneWidget);
          expectCompleteAmount(tester, '123,456,789', 3);
          await tester.drag(
            find.byType(Scrollable).last,
            const Offset(0, -500),
          );
          await frames(tester);
        });
        testWidgets('currency history tabs and large amounts fit $name', (
          tester,
        ) async {
          final session = WalletHistorySession('test-user-id');
          await showPage(
            tester,
            const CurrencyHistoryPage(),
            size,
            scale,
            language,
            overrides: [
              walletHistorySessionProvider.overrideWith((ref) => session),
              walletRepositoryProvider.overrideWithValue(
                LayoutHistoryRepository(),
              ),
            ],
          );
          expect(find.byType(CurrencyHistoryListItem), findsOneWidget);
          expectCompleteAmount(tester, '-123,456,789', 1);
          await tester.ensureVisible(find.byType(Tab).last);
          await tester.tap(find.byType(Tab).last);
          await frames(tester);
          expect(find.byType(CurrencyHistoryListItem), findsOneWidget);
          expectCompleteAmount(tester, '-123,456,789', 1);
        });
        testWidgets('notifications long text fits $name', (tester) async {
          await showPage(
            tester,
            NotificationsPage(
              mode: NotificationsPageMode.embedded,
              service: NotificationInboxService(
                readStore: BroadcastNotificationReadStore(
                  storage: LayoutMemoryStorage(),
                ),
              ),
            ),
            size,
            scale,
            language,
          );
          expect(find.text(extendedLongCopy), findsWidgets);
        });
        testWidgets('free charge rewards and actions remain reachable $name', (
          tester,
        ) async {
          await showPage(
            tester,
            const LayoutChargeContent(),
            size,
            scale,
            language,
            overrides: [walletSummaryProvider.overrideWith(LayoutWallet.new)],
          );
          final target = find.byKey(const ValueKey('free-charge-ad'));
          await tester.scrollUntilVisible(
            target,
            200,
            scrollable: find.byType(Scrollable).first,
          );
          await frames(tester);
          final action = find.descendant(
            of: target,
            matching: find.byKey(const Key('purchase-price-cta')),
          );
          await tester.ensureVisible(action);
          await frames(tester);
          expect(action.hitTestable(), findsOneWidget);
        });
        testWidgets('long price action remains visible and tappable $name', (
          tester,
        ) async {
          var tapped = 0;
          await showPage(
            tester,
            ListView(
              children: [
                StoreListTile(
                  icon: Image.asset(
                    'assets/icons/store/currency_star_candy.png',
                    package: 'picnic_lib',
                  ),
                  title: const Text(extendedLongCopy),
                  buttonText: '123.456.789,00 COP',
                  buttonOnPressed: () {
                    tapped++;
                  },
                ),
              ],
            ),
            size,
            scale,
            language,
          );
          final action = find.byKey(const Key('purchase-price-cta'));
          await tester.ensureVisible(action);
          await frames(tester);
          expect(tester.getRect(action).left, greaterThanOrEqualTo(0));
          expect(tester.getRect(action).right, lessThanOrEqualTo(size.width));
          await tester.tap(action);
          expect(tapped, 1);
        });
        testWidgets('profile draft survives resize $name', (tester) async {
          await showPage(tester, const MyProfilePage(), size, scale, language);
          final input = find.byType(TextFormField);
          await tester.ensureVisible(input);
          await tester.enterText(input, 'FoldableUser');
          await frames(tester);
          tester.view.physicalSize = Size(size.height, size.width);
          tester.view.viewInsets = const FakeViewPadding(bottom: 160);
          await frames(tester);
          await tester.ensureVisible(input);
          await frames(tester);
          final editable = tester.widget<EditableText>(
            find.descendant(of: input, matching: find.byType(EditableText)),
          );
          expect(editable.controller.text, 'FoldableUser');
          expect(
            tester.getRect(input).bottom,
            lessThanOrEqualTo(size.width - 160 + 1),
          );
        });
        testWidgets('QnA draft survives resize $name', (tester) async {
          await showPage(
            tester,
            QnaThreadCreatePage(
              userId: 'test-user-id',
              repository: LayoutQnaRepository(),
            ),
            size,
            scale,
            language,
          );
          final input = find.byType(TextFormField).last;
          await tester.ensureVisible(input);
          await tester.enterText(input, '$longCopy\nSecond line of the draft.');
          await frames(tester);
          tester.view.physicalSize = Size(size.height, size.width);
          tester.view.viewInsets = const FakeViewPadding(bottom: 160);
          await frames(tester);
          await tester.ensureVisible(input);
          await frames(tester);
          expect(
            tester
                .widget<EditableText>(
                  find.descendant(
                    of: input,
                    matching: find.byType(EditableText),
                  ),
                )
                .controller
                .text,
            '$longCopy\nSecond line of the draft.',
          );
        });
        testWidgets('settings controls fit $name', (tester) async {
          await showPage(tester, const SettingPage(), size, scale, language);
          await tester.drag(find.byType(ListView).first, const Offset(0, -500));
          await frames(tester);
          expect(find.byType(SettingPage), findsOneWidget);
        });
        testWidgets('notice long title fits $name', (tester) async {
          await showPage(
            tester,
            NoticePage(
              loadNotices: () async => [
                {
                  'id': 17,
                  'title': {language: longCopy},
                  'content': {language: longCopy},
                  'is_pinned': true,
                  'created_at': '2026-10-29T00:00:00Z',
                },
              ],
            ),
            size,
            scale,
            language,
          );
          expect(find.text(longCopy), findsWidgets);
        });
        testWidgets('FAQ long category and expanded answer fit $name', (
          tester,
        ) async {
          await showPage(
            tester,
            FAQPage(
              loadContent: () async => FAQContent(
                faqs: [
                  {
                    'id': 1,
                    'category': 'general',
                    'question': {language: longCopy},
                    'answer': {language: '$longCopy\n$longCopy'},
                    'answer_delta': null,
                  },
                ],
                categories: [
                  {
                    'code': 'general',
                    'label': {language: longCopy},
                  },
                ],
              ),
            ),
            size,
            scale,
            language,
          );
          final tile = find.byType(ExpansionTile).first;
          await tester.ensureVisible(tile);
          await tester.tap(tile);
          await frames(tester);
          expect(find.text('$longCopy\n$longCopy'), findsOneWidget);
        });
      }
    }
  }
}

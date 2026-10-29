import 'dart:io';
import 'package:flutter/rendering.dart';
import 'package:picnic_lib/presentation/pages/my_page/qna/qna_category_chip.dart';
import 'package:picnic_lib/presentation/pages/my_page/qna/qna_message_list_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/pages/my_page/qna/qna_message_input.dart';
import 'package:picnic_lib/presentation/pages/my_page/qna/qna_thread_detail_page.dart';
import '../../helpers/detail_ui_fixtures.dart';
import '../../helpers/foldable_test_app.dart';
import '../../helpers/ignore_image_errors.dart';
import '../../helpers/load_test_fonts.dart';
import '../../helpers/mock_supabase.dart';
import '../../helpers/test_environment.dart';
import 'active_subpages_foldable_test.dart' show frames;

Future<void> showDetail(
  WidgetTester tester,
  Widget page,
  Size size,
  double scale,
  String language, {
  bool pageHasScaffold = true,
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
      pageHasScaffold: pageHasScaffold,
    ),
  );
  await frames(tester);
}

void main() {
  setUpAll(loadTestFonts);
  setUp(() async {
    initTestColors();
    resetFoldableTestPlugins();
    DetailQnaRepository.sendAttempts = 0;
    await setupMockSupabaseWithAuth(const {}, userId: 'test-user-id');
  });
  tearDown(() {
    expect(DetailQnaRepository.sendAttempts, 0);
    tearDownMockSupabase();
  });
  for (final size in [
    const Size(320, 600),
    const Size(800, 600),
    const Size(600, 400),
  ]) {
    for (final scale in [1.0, 2.6]) {
      for (final language in ['ko', 'en', 'es']) {
        final name = '$size text=$scale $language';
        testWidgets('QnA draft remains reachable above keyboard $name', (
          tester,
        ) async {
          await showDetail(tester, detailQnaPage(), size, scale, language);
          final field = find.byType(TextField);
          await tester.tap(field);
          await tester.enterText(field, 'Draft remains');
          tester.view.viewInsets = const FakeViewPadding(bottom: 180);
          await frames(tester);
          expect(
            tester
                .widget<EditableText>(find.byType(EditableText))
                .focusNode
                .hasFocus,
            isTrue,
          );
          expect(
            tester.getSize(find.byType(QnaMessageListView)).height,
            greaterThan(0),
          );
          expect(field.hitTestable(), findsOneWidget);
          expect(
            tester.getRect(field).bottom,
            lessThanOrEqualTo(size.height - 180 + 1),
          );
          expect(find.text('Draft remains'), findsOneWidget);
        });
        testWidgets('QnA closed notice fits $name', (tester) async {
          await showDetail(
            tester,
            detailQnaPage(repository: DetailQnaRepository(status: 'RESOLVED')),
            size,
            scale,
            language,
          );
          expect(find.byType(TextField), findsNothing);
          final l10n = AppLocalizations.of(
            tester.element(find.byType(QnaThreadDetailPage)),
          );
          final notice = find.text(l10n.qna_cannot_send_message_closed);
          expect(notice.hitTestable(), findsOneWidget);
          final rect = tester.getRect(notice);
          final composer = tester.getRect(find.byType(QnaMessageInput));
          expect(rect.top, greaterThanOrEqualTo(composer.top));
          expect(rect.bottom, lessThanOrEqualTo(composer.bottom));
          expect(rect.bottom, lessThanOrEqualTo(size.height));
        });
        testWidgets('QnA retry remains usable $name', (tester) async {
          await showDetail(
            tester,
            detailQnaPage(repository: DetailQnaRepository(failFirst: true)),
            size,
            scale,
            language,
          );
          await tester.enterText(find.byType(TextField), 'Keep retry draft');
          final retry = find.byIcon(Icons.refresh);
          await tester.ensureVisible(retry);
          expect(retry.hitTestable(), findsOneWidget);
          await tester.tap(retry);
          await frames(tester);
          expect(find.text('$detailLongCopy\n$detailLongCopy'), findsOneWidget);
          expect(
            tester.widget<TextField>(find.byType(TextField)).controller!.text,
            'Keep retry draft',
          );
        });
      }
    }
  }
  testWidgets(
    'QnA attachment remove and send remain reachable in short window',
    (tester) async {
      final controller = TextEditingController(text: 'Draft with attachment');
      addTearDown(controller.dispose);
      var removed = false;
      var sent = false;
      await showDetail(
        tester,
        Scaffold(
          appBar: AppBar(title: const Text('Inquiry')),
          body: LayoutBuilder(
            builder: (_, constraints) => Column(
              children: [
                const Expanded(child: SizedBox.shrink()),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: constraints.maxHeight * 0.6,
                  ),
                  child: QnaMessageInput(
                    isThreadOpen: true,
                    showAutoCloseNotice: true,
                    isSending: false,
                    attachments: [File('/local-fixture.txt')],
                    messageController: controller,
                    onSend: () => sent = true,
                    onPickMedia: () {},
                    onRemoveAttachment: (_) => removed = true,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Size(600, 400),
        2.6,
        'en',
      );
      tester.view.viewInsets = const FakeViewPadding(bottom: 180);
      await frames(tester);
      expect(
        tester.getSize(find.byType(QnaMessageInput)).height,
        lessThanOrEqualTo(99),
      );
      for (final icon in [Icons.close, Icons.send]) {
        final button = find.byIcon(icon);
        await tester.ensureVisible(button);
        await frames(tester);
        expect(button.hitTestable(), findsOneWidget);
        await tester.tap(button);
      }
      expect(removed, isTrue);
      expect(sent, isTrue);
    },
  );
  testWidgets('QnA category remains readable at the start of a long thread', (
    tester,
  ) async {
    await showDetail(
      tester,
      detailQnaPage(repository: DetailQnaRepository(messageCount: 8)),
      const Size(320, 600),
      2.6,
      'en',
    );
    final category = find.byType(QnaCategoryChip);
    await tester.scrollUntilVisible(
      category,
      400,
      scrollable: find
          .descendant(
            of: find.byType(QnaMessageListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await frames(tester);
    expect(category.hitTestable(), findsOneWidget);
    final viewport = tester.getRect(find.byType(QnaMessageListView));
    final rect = tester.getRect(category);
    expect(rect.overlaps(viewport), isTrue);
    final label = find.descendant(of: category, matching: find.byType(Text));
    expect(tester.renderObject<RenderParagraph>(label).didExceedMaxLines, isFalse);
    final scrollable = tester.state<ScrollableState>(find.descendant(of: find.byType(QnaMessageListView), matching: find.byType(Scrollable)).first);
    scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
    await frames(tester);
    expect(tester.getRect(category).top, greaterThanOrEqualTo(viewport.top - 1));
  });
}

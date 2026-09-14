import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/qna/qna_thread.dart';
import 'package:picnic_lib/data/models/qna/qna_category.dart';
import 'package:picnic_lib/data/repositories/qna_repository.dart';
import 'package:picnic_lib/presentation/pages/my_page/qna/qna_submit_button.dart';
import 'package:picnic_lib/presentation/pages/my_page/qna/qna_thread_card.dart';
import 'package:picnic_lib/presentation/pages/my_page/qna/qna_thread_list_page.dart';
import 'package:picnic_lib/presentation/pages/my_page/qna/qna_thread_create_page.dart';
import 'package:picnic_lib/presentation/widgets/ui/picnic_action_button.dart';
import 'package:picnic_lib/presentation/widgets/custom_dropdown_button.dart';
import 'package:picnic_lib/supabase_options.dart';

import '../../../../helpers/load_test_fonts.dart';
import '../../../../helpers/mock_supabase.dart';
import '../../../../helpers/pixel_probe.dart';
import '../../../../helpers/test_app.dart';
import '../../../../helpers/test_environment.dart';

class _PresentationRepository extends QnaRepository {
  _PresentationRepository({
    this.count = 1,
    this.pending,
    this.categories = const [],
  }) : super(client: testSupabaseClient);

  final int count;
  final List<QnaCategory> categories;
  final Future<List<QnaThread>>? pending;

  @override
  Future<List<QnaCategory>> getCategories() async => categories;

  @override
  Future<List<QnaThread>> getQaThreadList({
    required String userId,
    int? lastId,
    DateTime? lastCreatedAt,
    int limit = 20,
  }) async =>
      pending ??
      (lastId != null
          ? []
          : [
              for (var i = 1; i <= count; i++)
                QnaThread(
                  id: i,
                  userId: userId,
                  title: '매우 긴 문의 제목도 상태와 함께 작은 화면에서 읽을 수 있습니다 $i',
                  status: 'IN_PROGRESS',
                  createdAt: DateTime(2026, 9, 14),
                  updatedAt: DateTime(2026, 9, 14),
                ),
            ]);
}

void main() {
  setUpAll(loadTestFonts);
  setUp(initTestColors);

  testWidgets('create submit has its natural height at 200% text', (
    tester,
  ) async {
    setupMockSupabase(const {});
    addTearDown(tearDownMockSupabase);
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    Widget app(Widget child) => buildTestApp(
      child,
      designSize: const Size(393, 892),
      splitScreenMode: true,
      textScaler: TextScaler.linear(2),
    );
    await tester.pumpWidget(
      app(
        QnaThreadCreatePage(
          userId: 'presentation-user',
          repository: _PresentationRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final actual = tester.getSize(
      find.widgetWithText(PicnicActionButton, '문의 등록'),
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(
      app(
        Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: actual.width,
            child: Builder(
              builder: (context) =>
                  QnaSubmitButton.primary(context, onPressed: () {}),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final natural = tester.getSize(
      find.widgetWithText(PicnicActionButton, '문의 등록'),
    );
    expect(actual.height, greaterThanOrEqualTo(natural.height));
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets('create submit stays above the keyboard at $scale', (
      tester,
    ) async {
      setupMockSupabase(const {});
      addTearDown(tearDownMockSupabase);
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        buildTestApp(
          Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(viewInsets: const EdgeInsets.only(bottom: 300)),
              child: QnaThreadCreatePage(
                userId: 'presentation-user',
                repository: _PresentationRepository(
                  categories: [QnaCategory(code: 'GENERAL', label: '일반 문의')],
                ),
              ),
            ),
          ),
          designSize: const Size(393, 892),
          splitScreenMode: true,
          textScaler: TextScaler.linear(scale),
        ),
      );
      await tester.pumpAndSettle();
      final submit = find.widgetWithText(PicnicActionButton, '문의 등록');
      final submitRect = tester.getRect(submit);
      expect(
        submitRect.bottom,
        lessThanOrEqualTo(568 - 300),
        reason: 'The keyboard must not cover the submit action.',
      );
      expect(tester.getSize(submit).height, greaterThanOrEqualTo(48));
      expect(submit.hitTestable(), findsOneWidget);
      final title = find.byType(TextFormField).first;
      await tester.ensureVisible(title);
      await tester.pumpAndSettle();
      expect(title.hitTestable(), findsOneWidget);
      expect(tester.getRect(title).bottom, lessThanOrEqualTo(submitRect.top));
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'create category and attachment actions stay reachable at $scale',
      (tester) async {
        setupMockSupabase(const {});
        addTearDown(tearDownMockSupabase);
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          buildTestApp(
            QnaThreadCreatePage(
              userId: 'presentation-user',
              repository: _PresentationRepository(
                categories: [QnaCategory(code: 'GENERAL', label: '일반 문의')],
              ),
            ),
            designSize: const Size(393, 892),
            splitScreenMode: true,
            textScaler: TextScaler.linear(scale),
          ),
        );
        await tester.pumpAndSettle();
        final category = find
            .descendant(
              of: find.byType(CustomDropdown),
              matching: find.byType(DropdownButton<String>),
            )
            .first;
        expect(tester.getSize(category).height, greaterThanOrEqualTo(48));
        expect(tester.getSize(category).width, greaterThanOrEqualTo(48));
        await tester.tap(category);
        await tester.pumpAndSettle();
        await tester.tap(find.text('일반 문의').last);
        await tester.pumpAndSettle();
        expect(find.text('일반 문의'), findsOneWidget);
        final attachment = find
            .ancestor(
              of: find.byIcon(Icons.perm_media),
              matching: find.byWidgetPredicate((w) => w is ButtonStyleButton),
            )
            .first;
        await tester.ensureVisible(attachment);
        await tester.pumpAndSettle();
        expect(tester.getSize(attachment).height, greaterThanOrEqualTo(48));
        expect(attachment.hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  for (final reducedMotion in [false, true]) {
    testWidgets(
      'QnA skeleton paints separate blocks with reduced motion $reducedMotion',
      (tester) async {
        setupMockSupabase(const {});
        addTearDown(tearDownMockSupabase);
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final pending = Completer<List<QnaThread>>();
        const boundaryKey = Key('qna-loading-capture');
        await tester.pumpWidget(
          buildTestApp(
            RepaintBoundary(
              key: boundaryKey,
              child: QnaThreadListPage(
                userId: 'presentation-user',
                repository: _PresentationRepository(pending: pending.future),
              ),
            ),
            designSize: const Size(393, 892),
            splitScreenMode: true,
            mediaQueryData: MediaQueryData(
              size: const Size(320, 568),
              disableAnimations: reducedMotion,
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 300));
        final title = tester.getRect(
          find.byKey(const ValueKey('qna-skeleton-title-0')),
        );
        final detail = tester.getRect(
          find.byKey(const ValueKey('qna-skeleton-detail-0')),
        );
        final pixels = await capturePixels(tester, find.byKey(boundaryKey));
        final gap = Offset(title.center.dx, (title.bottom + detail.top) / 2);
        expect(pixels.at(gap), colorHex(Colors.white));
        expect(pixels.at(title.center), isNot(pixels.at(gap)));
        expect(pixels.at(detail.center), isNot(pixels.at(gap)));
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }

  for (final scale in [1.0, 2.0]) {
    testWidgets('QnA card and bottom action fit the viewport at $scale', (
      tester,
    ) async {
      setupMockSupabase(const {});
      addTearDown(tearDownMockSupabase);
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildTestApp(
          QnaThreadListPage(
            userId: 'presentation-user',
            repository: _PresentationRepository(count: 20),
          ),
          designSize: const Size(393, 892),
          splitScreenMode: true,
          textScaler: TextScaler.linear(scale),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final list = tester.widget<ListView>(find.byType(ListView));
      for (var i = 0; i < 8; i++) {
        list.controller!.jumpTo(list.controller!.position.maxScrollExtent);
        await tester.pumpAndSettle();
      }
      final lastCard = find.byWidgetPredicate(
        (w) => w is QnaThreadCard && w.thread.id == 20,
      );
      final card = tester.getRect(lastCard);
      final action = tester.getRect(find.byKey(const Key('qna-create-action')));
      expect(action.height, greaterThanOrEqualTo(48));
      expect(action.left, greaterThanOrEqualTo(0));
      expect(action.right, lessThanOrEqualTo(320));
      expect(action.bottom, lessThanOrEqualTo(568));
      expect(card.bottom, lessThanOrEqualTo(action.top));
    });

    testWidgets('QnA submit remains reachable and blocks busy taps at $scale', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var submissions = 0;

      Widget app({required bool busy}) => buildTestApp(
        Builder(
          builder: (context) => Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: QnaSubmitButton.primary(
                context,
                onPressed: () => submissions++,
                isLoading: busy,
              ),
            ),
          ),
        ),
        designSize: const Size(393, 892),
        splitScreenMode: true,
        textScaler: TextScaler.linear(scale),
      );

      final button = find.byWidgetPredicate(
        (widget) => widget is ButtonStyleButton,
      );
      await tester.pumpWidget(app(busy: false));
      await tester.pumpAndSettle();

      expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
      final bounds = tester.getRect(button);
      expect(bounds.left, greaterThanOrEqualTo(0));
      expect(bounds.right, lessThanOrEqualTo(320));
      expect(tester.takeException(), isNull);
      await tester.tap(button);
      expect(submissions, 1);

      await tester.pumpWidget(app(busy: true));
      await tester.pump();
      await tester.tap(button);
      await tester.pump();
      expect(submissions, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}

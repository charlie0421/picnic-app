import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/qna/qna_category.dart';
import 'package:picnic_lib/data/models/qna/qna_thread.dart';
import 'package:picnic_lib/data/repositories/qna_repository.dart';
import 'package:picnic_lib/presentation/pages/my_page/qna/qna_thread_create_page.dart';
import 'package:picnic_lib/presentation/pages/my_page/qna/qna_thread_list_page.dart';
import 'package:picnic_lib/supabase_options.dart';

import '../../../../helpers/mock_supabase.dart';
import '../../../../helpers/test_app.dart';
import '../../../../helpers/test_environment.dart';

class _FakeQnaRepository extends QnaRepository {
  _FakeQnaRepository({
    List<Future<List<QnaThread>>> threadResponses = const [],
    this.categories = const [],
  }) : _threadResponses = List.of(threadResponses),
       super(client: testSupabaseClient);

  final List<Future<List<QnaThread>>> _threadResponses;
  final List<QnaCategory> categories;
  int threadRequestCount = 0;
  final List<int?> requestedLastIds = [];

  @override
  Future<List<QnaThread>> getQaThreadList({
    required String userId,
    int? lastId,
    DateTime? lastCreatedAt,
    int limit = 20,
  }) {
    requestedLastIds.add(lastId);
    final index = threadRequestCount++;
    if (index >= _threadResponses.length) {
      return Future.value(const []);
    }
    return _threadResponses[index];
  }

  @override
  Future<List<QnaCategory>> getCategories() async => categories;
}

QnaThread _thread(int id, {String? title}) => QnaThread(
  id: id,
  userId: 'user-1',
  title: title ?? 'thread-$id',
  createdAt: DateTime.utc(2026, 9, 13, 12, 0).subtract(Duration(seconds: id)),
  updatedAt: DateTime.utc(2026, 9, 13, 12, 0).subtract(Duration(seconds: id)),
  status: 'RECEIVED',
);

Future<void> _selectCategory(WidgetTester tester, String label) async {
  await tester.tap(find.byType(DropdownButtonFormField<String>));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(initTestColors);

  setUp(() {
    setupMockSupabase(const {});
  });

  tearDown(tearDownMockSupabase);

  group('QnaThreadListPage real state path', () {
    testWidgets('empty list refreshes after create route returns true', (
      tester,
    ) async {
      final repo = _FakeQnaRepository(
        threadResponses: [
          Future.value(const []),
          Future.value([_thread(1)]),
        ],
      );
      await tester.pumpWidget(
        buildTestAppPage(QnaThreadListPage(userId: 'user-1', repository: repo)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      Navigator.of(tester.element(find.byType(QnaThreadCreatePage))).pop(true);
      await tester.pumpAndSettle();

      expect(repo.threadRequestCount, 2);
      expect(find.text('thread-1'), findsOneWidget);
    });

    testWidgets('refresh is allowed after append reports exhaustion', (
      tester,
    ) async {
      final first = List.generate(20, (index) => _thread(100 - index));
      final refreshed = [_thread(999, title: 'refreshed')];
      final repo = _FakeQnaRepository(
        threadResponses: [
          Future.value(first),
          Future.value(const []),
          Future.value(refreshed),
        ],
      );
      await tester.pumpWidget(
        buildTestAppPage(QnaThreadListPage(userId: 'user-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      final controller = tester
          .widget<ListView>(find.byType(ListView))
          .controller!;
      controller.jumpTo(controller.position.maxScrollExtent);
      await tester.pumpAndSettle();
      expect(repo.threadRequestCount, 2);

      final refreshFuture = tester
          .state<RefreshIndicatorState>(find.byType(RefreshIndicator))
          .show();
      await tester.pumpAndSettle();
      await refreshFuture;

      expect(repo.threadRequestCount, 3);
      expect(find.text('refreshed'), findsOneWidget);
    });

    testWidgets('refresh wins when an older append completes later', (
      tester,
    ) async {
      final append = Completer<List<QnaThread>>();
      final refresh = Completer<List<QnaThread>>();
      final repo = _FakeQnaRepository(
        threadResponses: [
          Future.value(List.generate(20, (index) => _thread(100 - index))),
          append.future,
          refresh.future,
        ],
      );
      await tester.pumpWidget(
        buildTestAppPage(QnaThreadListPage(userId: 'user-1', repository: repo)),
      );
      await tester.pumpAndSettle();
      final controller = tester
          .widget<ListView>(find.byType(ListView))
          .controller!;
      controller.jumpTo(controller.position.maxScrollExtent);
      await tester.pump();
      final refreshFuture = tester
          .state<RefreshIndicatorState>(find.byType(RefreshIndicator))
          .show();
      await tester.pump();

      refresh.complete([_thread(999, title: 'fresh')]);
      await tester.pumpAndSettle();
      await refreshFuture;
      append.complete([_thread(1, title: 'stale append')]);
      await tester.pumpAndSettle();

      expect(find.text('fresh'), findsOneWidget);
      expect(find.text('stale append'), findsNothing);
    });

    testWidgets(
      'append cannot start during refresh and later uses the refreshed tail',
      (tester) async {
        final refresh = Completer<List<QnaThread>>();
        final append = Completer<List<QnaThread>>();
        final initial = List.generate(20, (index) => _thread(100 - index));
        final fresh = List.generate(
          20,
          (index) => _thread(1000 - index, title: 'fresh-$index'),
        );
        final repo = _FakeQnaRepository(
          threadResponses: [
            Future.value(initial),
            refresh.future,
            append.future,
          ],
        );
        await tester.pumpWidget(
          buildTestAppPage(
            QnaThreadListPage(userId: 'user-1', repository: repo),
          ),
        );
        await tester.pumpAndSettle();

        final refreshFuture = tester
            .state<RefreshIndicatorState>(find.byType(RefreshIndicator))
            .show();
        while (repo.threadRequestCount < 2) {
          await tester.pump(const Duration(milliseconds: 50));
        }
        final controller = tester
            .widget<ListView>(find.byType(ListView))
            .controller!;
        controller.jumpTo(controller.position.maxScrollExtent);
        await tester.pump();
        final requestsWhileRefreshing = repo.threadRequestCount;

        refresh.complete(fresh);
        for (var index = 0; index < 20; index++) {
          await tester.pump(const Duration(milliseconds: 50));
          if (!append.isCompleted && repo.threadRequestCount >= 3) {
            append.complete(const []);
          }
        }
        await tester.pumpAndSettle();
        await refreshFuture;

        if (repo.threadRequestCount < 3) {
          controller.jumpTo(0);
          await tester.pump();
          controller.jumpTo(controller.position.maxScrollExtent);
          while (repo.threadRequestCount < 3) {
            await tester.pump(const Duration(milliseconds: 50));
          }
          append.complete(const []);
          await tester.pumpAndSettle();
        }

        expect(requestsWhileRefreshing, 2);
        expect(repo.requestedLastIds[2], fresh.last.id);
        expect(find.text('fresh-19'), findsOneWidget);
      },
    );

    testWidgets('failed refresh keeps the previous successful list', (
      tester,
    ) async {
      final failedRefresh = Completer<List<QnaThread>>();
      final repo = _FakeQnaRepository(
        threadResponses: [
          Future.value([_thread(1, title: 'kept')]),
          failedRefresh.future,
        ],
      );
      await tester.pumpWidget(
        buildTestAppPage(QnaThreadListPage(userId: 'user-1', repository: repo)),
      );
      await tester.pumpAndSettle();

      final refreshFuture = tester
          .state<RefreshIndicatorState>(find.byType(RefreshIndicator))
          .show();
      while (repo.threadRequestCount < 2) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      failedRefresh.completeError(StateError('offline'));
      await tester.pumpAndSettle();
      await refreshFuture;

      expect(find.text('kept'), findsOneWidget);
    });

    testWidgets('pending initial request does not set state after dispose', (
      tester,
    ) async {
      final pending = Completer<List<QnaThread>>();
      final repo = _FakeQnaRepository(threadResponses: [pending.future]);
      await tester.pumpWidget(
        buildTestAppPage(QnaThreadListPage(userId: 'user-1', repository: repo)),
      );
      await tester.pump();
      await tester.pumpWidget(const SizedBox.shrink());
      pending.complete([_thread(1)]);
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });

  group('QnaThreadCreatePage category template behavior', () {
    late _FakeQnaRepository repo;

    setUp(() {
      repo = _FakeQnaRepository(
        categories: [
          QnaCategory(
            code: 'a',
            label: 'Category A',
            questionTemplate: 'Template A',
          ),
          QnaCategory(
            code: 'b',
            label: 'Category B',
            questionTemplate: 'Template B',
          ),
          QnaCategory(code: 'none', label: 'No template'),
        ],
      );
    });

    testWidgets(
      'manual draft and selection survive category and placeholder changes',
      (tester) async {
        await tester.pumpWidget(
          buildTestAppPage(
            QnaThreadCreatePage(userId: 'user-1', repository: repo),
          ),
        );
        await tester.pumpAndSettle();
        final contentField = find.byType(TextFormField).at(1);
        await tester.enterText(contentField, 'manual draft content');
        final editable = tester.widget<EditableText>(
          find.descendant(
            of: contentField,
            matching: find.byType(EditableText),
          ),
        );
        editable.controller.selection = const TextSelection(
          baseOffset: 2,
          extentOffset: 8,
        );

        await _selectCategory(tester, 'Category A');
        expect(editable.controller.text, 'manual draft content');
        expect(
          editable.controller.selection,
          const TextSelection(baseOffset: 2, extentOffset: 8),
        );
        await _selectCategory(tester, '카테고리');
        expect(editable.controller.text, 'manual draft content');
      },
    );

    testWidgets(
      'manual draft survives selecting a category without a template',
      (tester) async {
        await tester.pumpWidget(
          buildTestAppPage(
            QnaThreadCreatePage(userId: 'user-1', repository: repo),
          ),
        );
        await tester.pumpAndSettle();
        final contentField = find.byType(TextFormField).at(1);
        await tester.enterText(contentField, 'manual draft content');

        await _selectCategory(tester, 'No template');

        expect(find.text('manual draft content'), findsOneWidget);
      },
    );

    testWidgets('an untouched automatic template swaps to the next template', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestAppPage(
          QnaThreadCreatePage(userId: 'user-1', repository: repo),
        ),
      );
      await tester.pumpAndSettle();

      await _selectCategory(tester, 'Category A');
      expect(find.text('Template A'), findsOneWidget);
      await _selectCategory(tester, 'Category B');
      expect(find.text('Template B'), findsOneWidget);
      expect(find.text('Template A'), findsNothing);
    });

    testWidgets(
      'placeholder and template-less choices preserve untouched auto-template eligibility',
      (tester) async {
        await tester.pumpWidget(
          buildTestAppPage(
            QnaThreadCreatePage(userId: 'user-1', repository: repo),
          ),
        );
        await tester.pumpAndSettle();
        final contentField = find.byType(TextFormField).at(1);
        final editable = tester.widget<EditableText>(
          find.descendant(
            of: contentField,
            matching: find.byType(EditableText),
          ),
        );

        await _selectCategory(tester, 'Category A');
        editable.controller.selection = const TextSelection(
          baseOffset: 1,
          extentOffset: 4,
        );
        await _selectCategory(tester, '카테고리');
        expect(editable.controller.text, 'Template A');
        expect(
          editable.controller.selection,
          const TextSelection(baseOffset: 1, extentOffset: 4),
        );
        await _selectCategory(tester, 'No template');
        expect(editable.controller.text, 'Template A');
        expect(
          editable.controller.selection,
          const TextSelection(baseOffset: 1, extentOffset: 4),
        );

        await _selectCategory(tester, 'Category B');
        expect(editable.controller.text, 'Template B');
      },
    );
  });
}

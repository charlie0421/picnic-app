import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/qna/qna_message.dart';
import 'package:picnic_lib/data/models/qna/qna_thread.dart';
import 'package:picnic_lib/data/repositories/qna_repository.dart';
import 'package:picnic_lib/presentation/pages/my_page/qna/qna_thread_detail_page.dart';
import 'package:picnic_lib/supabase_options.dart';

import '../../../../helpers/mock_supabase.dart';
import '../../../../helpers/test_app.dart';
import '../../../../helpers/test_environment.dart';

class _FakeQnaRepository extends QnaRepository {
  _FakeQnaRepository({
    List<Future<QaThreadWithMessages>> detailResponses = const [],
    List<Future<QnaMessage>> sendResponses = const [],
  }) : _detailResponses = List.of(detailResponses),
       _sendResponses = List.of(sendResponses),
       super(client: testSupabaseClient);

  final List<Future<QaThreadWithMessages>> _detailResponses;
  final List<Future<QnaMessage>> _sendResponses;
  int detailRequestCount = 0;
  int sendRequestCount = 0;

  @override
  Future<QaThreadWithMessages> getQaThreadById(int threadId) {
    final index = detailRequestCount++;
    return _detailResponses[index];
  }

  @override
  Future<QnaMessage> createQaMessage({
    required int threadId,
    required String userId,
    required String content,
    List<File>? attachments,
  }) {
    final index = sendRequestCount++;
    return _sendResponses[index];
  }

  @override
  String getPublicUrl(String path) => 'https://example.test/$path';
}

class _StatusSubscriptionHarness {
  ValueChanged<String>? listener;
  bool cancelled = false;

  VoidCallback subscribe({
    required int threadId,
    required ValueChanged<String> onStatusChanged,
  }) {
    listener = onStatusChanged;
    return () => cancelled = true;
  }

  void emit(String status) => listener!(status);
}

QnaThread _thread({String status = 'RECEIVED'}) => QnaThread(
  id: 7,
  userId: 'user-1',
  title: 'Lifecycle question',
  createdAt: DateTime.utc(2026, 9, 14, 1),
  updatedAt: DateTime.utc(2026, 9, 14, 2),
  status: status,
);

QaThreadWithMessages _details({
  String status = 'RECEIVED',
  List<QnaMessage> messages = const [],
}) => QaThreadWithMessages(
  thread: _thread(status: status),
  messages: messages,
);

QnaMessage _message({int id = 1, String content = 'sent reply'}) => QnaMessage(
  id: id,
  threadId: 7,
  userId: 'user-1',
  content: content,
  createdAt: DateTime.utc(2026, 9, 14, 3),
  isAdminMessage: false,
);

Widget _page(
  _FakeQnaRepository repository,
  _StatusSubscriptionHarness status, {
  QnaThread? thread,
}) => buildTestAppPage(
  QnaThreadDetailPage(
    thread: thread ?? _thread(),
    repository: repository,
    statusSubscriber: status.subscribe,
    syncNavigation: false,
  ),
);

Future<void> _pumpFrames(WidgetTester tester, [int count = 4]) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 20));
  }
}

String _draftText(WidgetTester tester) =>
    tester.widget<TextField>(find.byType(TextField)).controller!.text;

void main() {
  setUpAll(initTestColors);

  setUp(() {
    setupMockSupabase(const {});
  });

  tearDown(tearDownMockSupabase);

  group('detail loading lifecycle', () {
    testWidgets('delayed detail success after unmount is ignored', (
      tester,
    ) async {
      final pending = Completer<QaThreadWithMessages>();
      final repository = _FakeQnaRepository(detailResponses: [pending.future]);
      final status = _StatusSubscriptionHarness();

      await tester.pumpWidget(_page(repository, status));
      await tester.pump();
      await tester.pumpWidget(const SizedBox.shrink());
      pending.complete(_details());
      await _pumpFrames(tester);

      expect(tester.takeException(), isNull);
      expect(status.cancelled, isTrue);
    });

    testWidgets('delayed detail failure after unmount is ignored', (
      tester,
    ) async {
      final pending = Completer<QaThreadWithMessages>();
      final repository = _FakeQnaRepository(detailResponses: [pending.future]);
      final status = _StatusSubscriptionHarness();

      await tester.pumpWidget(_page(repository, status));
      await tester.pump();
      await tester.pumpWidget(const SizedBox.shrink());
      pending.completeError(StateError('late server failure'));
      await _pumpFrames(tester);

      expect(tester.takeException(), isNull);
    });

    testWidgets('failure hides the raw exception behind a generic error', (
      tester,
    ) async {
      final failure = Completer<QaThreadWithMessages>();
      final repository = _FakeQnaRepository(detailResponses: [failure.future]);
      final status = _StatusSubscriptionHarness();

      await tester.pumpWidget(_page(repository, status));
      failure.completeError(StateError('raw-server-secret'));
      await _pumpFrames(tester);

      expect(find.text('문의 내역을 불러오는데 실패했습니다'), findsOneWidget);
      expect(find.textContaining('raw-server-secret'), findsNothing);
      expect(find.text('재시도'), findsOneWidget);
    });

    testWidgets(
      'retry remains single-flight while preserving the typed draft',
      (tester) async {
        final first = Completer<QaThreadWithMessages>();
        final retry = Completer<QaThreadWithMessages>();
        final repository = _FakeQnaRepository(
          detailResponses: [first.future, retry.future],
        );
        final status = _StatusSubscriptionHarness();

        await tester.pumpWidget(_page(repository, status));
        first.completeError(StateError('raw-server-secret'));
        await _pumpFrames(tester);

        await tester.enterText(find.byType(TextField), 'keep this draft');
        final retryButton = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, '재시도'),
        );
        retryButton.onPressed!();
        retryButton.onPressed!();
        await tester.pump();

        expect(repository.detailRequestCount, 2);
        expect(find.text('keep this draft'), findsOneWidget);

        retry.complete(_details());
        await _pumpFrames(tester);

        expect(find.text('문의 내역을 불러오는데 실패했습니다'), findsNothing);
        expect(find.text('아직 답변이 없습니다. 잠시만 기다려주세요.'), findsOneWidget);
        expect(find.text('keep this draft'), findsOneWidget);
      },
    );

    testWidgets('live closed status wins over a stale detail response', (
      tester,
    ) async {
      await setupMockSupabaseWithAuth(const {}, userId: 'user-1');
      final pending = Completer<QaThreadWithMessages>();
      final repository = _FakeQnaRepository(
        detailResponses: [pending.future],
        sendResponses: [Future.value(_message())],
      );
      final status = _StatusSubscriptionHarness();

      await tester.pumpWidget(_page(repository, status));
      await tester.enterText(find.byType(TextField), 'must not send');
      final staleSendCallback = tester
          .widget<IconButton>(find.widgetWithIcon(IconButton, Icons.send))
          .onPressed!;

      status.emit('RESOLVED');
      await tester.pump();
      pending.complete(_details(status: 'RECEIVED'));
      await _pumpFrames(tester);

      expect(find.text('해결됨'), findsOneWidget);
      expect(find.text('문의가 종료되어 더 이상 메시지를 보낼 수 없습니다.'), findsOneWidget);
      staleSendCallback();
      await tester.pump();
      expect(repository.sendRequestCount, 0);
    });
  });

  group('message sending lifecycle', () {
    testWidgets('pending detail load blocks send until details are ready', (
      tester,
    ) async {
      await setupMockSupabaseWithAuth(const {}, userId: 'user-1');
      final details = Completer<QaThreadWithMessages>();
      final repository = _FakeQnaRepository(
        detailResponses: [details.future],
        sendResponses: [Future.value(_message(content: 'held while loading'))],
      );
      final status = _StatusSubscriptionHarness();

      await tester.pumpWidget(_page(repository, status));
      await tester.enterText(find.byType(TextField), 'held while loading');
      await tester.tap(find.widgetWithIcon(IconButton, Icons.send));
      await _pumpFrames(tester);

      expect(repository.sendRequestCount, 0);
      expect(_draftText(tester), 'held while loading');

      details.complete(_details());
      await _pumpFrames(tester);
      await tester.tap(find.widgetWithIcon(IconButton, Icons.send));
      await _pumpFrames(tester);

      expect(repository.sendRequestCount, 1);
      expect(find.text('held while loading'), findsOneWidget);
      expect(_draftText(tester), isEmpty);
    });

    testWidgets('failed detail load blocks send until retry succeeds', (
      tester,
    ) async {
      await setupMockSupabaseWithAuth(const {}, userId: 'user-1');
      final first = Completer<QaThreadWithMessages>();
      final retry = Completer<QaThreadWithMessages>();
      final repository = _FakeQnaRepository(
        detailResponses: [first.future, retry.future],
        sendResponses: [Future.value(_message(content: 'held after failure'))],
      );
      final status = _StatusSubscriptionHarness();

      await tester.pumpWidget(_page(repository, status));
      first.completeError(StateError('load failed'));
      await _pumpFrames(tester);
      await tester.enterText(find.byType(TextField), 'held after failure');
      await tester.tap(find.widgetWithIcon(IconButton, Icons.send));
      await _pumpFrames(tester);

      expect(repository.sendRequestCount, 0);
      expect(_draftText(tester), 'held after failure');

      await tester.tap(find.widgetWithText(ElevatedButton, '재시도'));
      retry.complete(_details());
      await _pumpFrames(tester);
      await tester.tap(find.widgetWithIcon(IconButton, Icons.send));
      await _pumpFrames(tester);

      expect(repository.sendRequestCount, 1);
      expect(find.text('held after failure'), findsOneWidget);
      expect(_draftText(tester), isEmpty);
    });

    testWidgets(
      'duplicate send is ignored and successful message appends once',
      (tester) async {
        await setupMockSupabaseWithAuth(const {}, userId: 'user-1');
        final pending = Completer<QnaMessage>();
        final repository = _FakeQnaRepository(
          detailResponses: [Future.value(_details(messages: const []))],
          sendResponses: [pending.future],
        );
        final status = _StatusSubscriptionHarness();

        await tester.pumpWidget(_page(repository, status));
        await _pumpFrames(tester);
        await tester.enterText(find.byType(TextField), 'sent reply');
        final sendButton = tester.widget<IconButton>(
          find.widgetWithIcon(IconButton, Icons.send),
        );
        sendButton.onPressed!();
        sendButton.onPressed!();
        await tester.pump();

        expect(repository.sendRequestCount, 1);
        pending.complete(_message());
        await _pumpFrames(tester);

        expect(find.text('sent reply'), findsOneWidget);
        expect(_draftText(tester), isEmpty);
        expect(find.textContaining('메시지 전송에 실패했습니다'), findsNothing);
      },
    );

    testWidgets('post-success mounted guard protects the disposed controller', (
      tester,
    ) async {
      await setupMockSupabaseWithAuth(const {}, userId: 'user-1');
      final pending = Completer<QnaMessage>();
      final repository = _FakeQnaRepository(
        detailResponses: [Future.value(_details())],
        sendResponses: [pending.future],
      );
      final status = _StatusSubscriptionHarness();

      await tester.pumpWidget(_page(repository, status));
      await _pumpFrames(tester);
      await tester.enterText(find.byType(TextField), 'survives disposal');
      await tester.tap(find.widgetWithIcon(IconButton, Icons.send));
      await tester.pump();
      expect(repository.sendRequestCount, 1);
      await tester.pumpWidget(const SizedBox.shrink());
      pending.complete(_message(content: 'survives disposal'));
      await _pumpFrames(tester);

      // Mutation proof: after the repository-only try/catch is in place,
      // removing only the post-await `if (!mounted) return;` must make this
      // fail on TextEditingController.clear() after disposal.
      expect(status.cancelled, isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('send failure retains the typed draft', (tester) async {
      await setupMockSupabaseWithAuth(const {}, userId: 'user-1');
      final pending = Completer<QnaMessage>();
      final repository = _FakeQnaRepository(
        detailResponses: [Future.value(_details())],
        sendResponses: [pending.future],
      );
      final status = _StatusSubscriptionHarness();

      await tester.pumpWidget(_page(repository, status));
      await _pumpFrames(tester);
      await tester.enterText(find.byType(TextField), 'retry me manually');
      await tester.tap(find.widgetWithIcon(IconButton, Icons.send));
      await tester.pump();
      pending.completeError(StateError('send failed'));
      await _pumpFrames(tester);

      expect(_draftText(tester), 'retry me manually');
      expect(repository.sendRequestCount, 1);
      expect(find.textContaining('메시지 전송에 실패했습니다'), findsOneWidget);
    });

    testWidgets('missing user does not send or clear the draft', (
      tester,
    ) async {
      final repository = _FakeQnaRepository(
        detailResponses: [
          Future.value(
            _details(messages: [_message(content: 'existing message')]),
          ),
        ],
      );
      final status = _StatusSubscriptionHarness();

      await tester.pumpWidget(_page(repository, status));
      await _pumpFrames(tester);
      await tester.enterText(find.byType(TextField), 'stay signed out draft');
      await tester.tap(find.widgetWithIcon(IconButton, Icons.send));
      await _pumpFrames(tester);

      expect(repository.sendRequestCount, 0);
      expect(_draftText(tester), 'stay signed out draft');
      expect(find.text('사용자 인증이 필요합니다. 다시 로그인해주세요.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

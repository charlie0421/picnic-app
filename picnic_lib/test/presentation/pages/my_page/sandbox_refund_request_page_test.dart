import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/services/sandbox_refund_candidate_store.dart';
import 'package:picnic_lib/core/services/storekit_refund_request_channel.dart';
import 'package:picnic_lib/presentation/pages/my_page/sandbox_refund_request_page.dart';

import '../../../helpers/ignore_image_errors.dart';
import '../../../helpers/mock_data.dart';
import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

/// In-memory candidates; [removed] records what the page dropped.
class _FakeCandidateStore extends SandboxRefundCandidateStore {
  _FakeCandidateStore(this.candidates);

  final List<SandboxRefundCandidate> candidates;
  final removed = <String>[];

  @override
  Future<List<SandboxRefundCandidate>> load() async =>
      List.unmodifiable(candidates);

  @override
  Future<void> remove(String transactionId) async {
    removed.add(transactionId);
    candidates.removeWhere((c) => c.transactionId == transactionId);
  }
}

class _FakeRefundChannel implements StoreKitRefundRequestChannel {
  _FakeRefundChannel(this.outcome);

  final StoreKitRefundRequestOutcome outcome;
  final requested = <String>[];

  @override
  Future<StoreKitRefundRequestOutcome> begin(String transactionId) async {
    requested.add(transactionId);
    return outcome;
  }
}

SandboxRefundCandidate _candidate(String transactionId, String productId) =>
    SandboxRefundCandidate(
      transactionId: transactionId,
      productId: productId,
      purchasedAt: DateTime.utc(2026, 10, 29, 6),
    );

Future<void> _pumpPage(
  WidgetTester tester, {
  required _FakeCandidateStore store,
  required _FakeRefundChannel channel,
  bool isAdmin = true,
}) async {
  await tester.pumpWidget(
    buildTestAppPage(
      SandboxRefundRequestPage(candidates: store, refundRequests: channel),
      userProfile: MockData.userProfile(isAdmin: isAdmin),
    ),
  );
  await pumpAndIgnoreErrors(tester);
}

void main() {
  setUpAll(initTestColors);

  testWidgets('lists the sandbox purchases this device recorded', (
    tester,
  ) async {
    final store = _FakeCandidateStore([
      _candidate('2000000000001111', 'STAR200'),
      _candidate('2000000000002222', 'STAR100'),
    ]);

    await _pumpPage(
      tester,
      store: store,
      channel: _FakeRefundChannel(StoreKitRefundRequestOutcome.success),
    );

    expect(find.text('STAR200'), findsOneWidget);
    expect(find.text('STAR100'), findsOneWidget);
    expect(find.textContaining('…1111'), findsOneWidget);
    expect(find.textContaining('DECLINE'), findsOneWidget);
  });

  testWidgets(
    'opens Apple\'s refund sheet for the chosen purchase and drops it '
    'after submission',
    (tester) async {
      final store = _FakeCandidateStore([
        _candidate('2000000000001111', 'STAR200'),
      ]);
      final channel = _FakeRefundChannel(StoreKitRefundRequestOutcome.success);
      await _pumpPage(tester, store: store, channel: channel);

      await tester.tap(find.text('STAR200'));
      await pumpAndIgnoreErrors(tester);
      expect(find.text('환불 요청'), findsOneWidget);

      await tester.tap(find.text('열기'));
      await pumpAndIgnoreErrors(tester);

      expect(channel.requested, ['2000000000001111']);
      expect(store.removed, ['2000000000001111']);
      expect(find.text('환불 요청을 보냈습니다. 서버 반영까지 몇 분 걸릴 수 있습니다.'), findsOneWidget);
      expect(find.text('STAR200'), findsNothing);
    },
  );

  testWidgets('does nothing when the tester backs out of the dialog', (
    tester,
  ) async {
    final store = _FakeCandidateStore([
      _candidate('2000000000001111', 'STAR200'),
    ]);
    final channel = _FakeRefundChannel(StoreKitRefundRequestOutcome.success);
    await _pumpPage(tester, store: store, channel: channel);

    await tester.tap(find.text('STAR200'));
    await pumpAndIgnoreErrors(tester);
    await tester.tap(find.text('취소'));
    await pumpAndIgnoreErrors(tester);

    expect(channel.requested, isEmpty);
    expect(store.removed, isEmpty);
    expect(find.text('STAR200'), findsOneWidget);
  });

  testWidgets('keeps a purchase whose sheet the tester closed', (tester) async {
    final store = _FakeCandidateStore([
      _candidate('2000000000001111', 'STAR200'),
    ]);
    final channel = _FakeRefundChannel(
      StoreKitRefundRequestOutcome.userCancelled,
    );
    await _pumpPage(tester, store: store, channel: channel);

    await tester.tap(find.text('STAR200'));
    await pumpAndIgnoreErrors(tester);
    await tester.tap(find.text('열기'));
    await pumpAndIgnoreErrors(tester);

    expect(store.removed, isEmpty);
    expect(find.text('환불 요청을 취소했습니다.'), findsOneWidget);
    expect(find.text('STAR200'), findsOneWidget);
  });

  testWidgets('explains and drops a purchase that already has a request', (
    tester,
  ) async {
    final store = _FakeCandidateStore([
      _candidate('2000000000001111', 'STAR200'),
    ]);
    final channel = _FakeRefundChannel(
      StoreKitRefundRequestOutcome.duplicateRequest,
    );
    await _pumpPage(tester, store: store, channel: channel);

    await tester.tap(find.text('STAR200'));
    await pumpAndIgnoreErrors(tester);
    await tester.tap(find.text('열기'));
    await pumpAndIgnoreErrors(tester);

    expect(store.removed, ['2000000000001111']);
    expect(find.text('이미 환불을 요청한 구매입니다.'), findsOneWidget);
  });

  testWidgets('reports a build without the native handler', (tester) async {
    final store = _FakeCandidateStore([
      _candidate('2000000000001111', 'STAR200'),
    ]);
    final channel = _FakeRefundChannel(
      StoreKitRefundRequestOutcome.unsupported,
    );
    await _pumpPage(tester, store: store, channel: channel);

    await tester.tap(find.text('STAR200'));
    await pumpAndIgnoreErrors(tester);
    await tester.tap(find.text('열기'));
    await pumpAndIgnoreErrors(tester);

    expect(store.removed, isEmpty);
    expect(find.text('이 앱 빌드는 환불 요청을 지원하지 않습니다.'), findsOneWidget);
  });

  testWidgets('shows an empty state without recorded purchases', (
    tester,
  ) async {
    await _pumpPage(
      tester,
      store: _FakeCandidateStore([]),
      channel: _FakeRefundChannel(StoreKitRefundRequestOutcome.success),
    );

    expect(find.text('이 기기에 기록된 sandbox 구매가 없습니다.'), findsOneWidget);
  });

  testWidgets('denies a non-admin direct access', (tester) async {
    final channel = _FakeRefundChannel(StoreKitRefundRequestOutcome.success);
    await _pumpPage(
      tester,
      store: _FakeCandidateStore([_candidate('2000000000001111', 'STAR200')]),
      channel: channel,
      isAdmin: false,
    );

    expect(find.text('접근 권한이 없습니다.'), findsOneWidget);
    expect(find.text('STAR200'), findsNothing);
  });
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/common/navigator_key.dart';
import 'package:picnic_lib/presentation/pages/my_page/notice_detail_page.dart';

import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

Map<String, dynamic> _notice({
  String title = '복구된 공지',
  String content = '복구된 본문',
}) => {
  'id': 17,
  'title': {'ko': title, 'en': 'Recovered notice'},
  'content': {'ko': content, 'en': 'Recovered body'},
  'created_at': '2026-09-14T01:02:03.000Z',
};

class _NoticeDetailLauncher extends StatelessWidget {
  const _NoticeDetailLauncher({required this.loadNotice});

  final Future<Map<String, dynamic>?> Function(int noticeId) loadNotice;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FilledButton(
        key: const ValueKey('open-notice-detail'),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                NoticeDetailPage(noticeId: 17, loadNotice: loadNotice),
          ),
        ),
        child: const Text('공지 열기'),
      ),
    );
  }
}

void main() {
  setUp(initTestColors);

  testWidgets('load failure exposes retry and retry can recover', (
    tester,
  ) async {
    var attempts = 0;
    await tester.pumpWidget(
      buildTestApp(
        NoticeDetailPage(
          noticeId: 17,
          loadNotice: (noticeId) async {
            expect(noticeId, 17);
            attempts++;
            if (attempts == 1) throw StateError('private server failure');
            return _notice();
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('오류가 발생했습니다.'), findsOneWidget);
    expect(find.textContaining('private server failure'), findsNothing);
    expect(find.byKey(const ValueKey('notice-detail-retry')), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, '재시도'));
    await tester.pump();
    await tester.pump();

    expect(attempts, 2);
    expect(find.text('복구된 공지'), findsOneWidget);
    expect(find.text('복구된 본문'), findsOneWidget);
    expect(find.byKey(const ValueKey('notice-detail-retry')), findsNothing);
  });

  testWidgets('successful missing row is a true absence without retry', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTestApp(
        NoticeDetailPage(noticeId: 404, loadNotice: (_) async => null),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('검색 결과가 없습니다.'), findsOneWidget);
    expect(find.text('오류가 발생했습니다.'), findsNothing);
    expect(find.byKey(const ValueKey('notice-detail-retry')), findsNothing);
  });

  testWidgets('a pending failure can finish safely after route dismissal', (
    tester,
  ) async {
    final pending = Completer<Map<String, dynamic>?>();
    await tester.pumpWidget(
      buildTestApp(_NoticeDetailLauncher(loadNotice: (_) => pending.future)),
    );

    await tester.tap(find.byKey(const ValueKey('open-notice-detail')));
    await tester.pump();
    await tester.pump();
    expect(find.byType(NoticeDetailPage), findsOneWidget);

    navigatorKey.currentState!.pop();
    await tester.pumpAndSettle();
    expect(find.byType(NoticeDetailPage), findsNothing);

    pending.completeError(StateError('late failure'));
    await tester.pump();
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.textContaining('late failure'), findsNothing);
  });
}

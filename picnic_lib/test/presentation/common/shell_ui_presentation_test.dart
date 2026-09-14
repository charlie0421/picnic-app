import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/common/picnic_list_item.dart';
import 'package:picnic_lib/presentation/common/top/top_right_notifications.dart';
import 'package:picnic_lib/presentation/pages/my_page/qna/qna_message_input.dart';
import 'package:picnic_lib/presentation/providers/notifications_unread_count_provider.dart';

import '../../helpers/load_test_fonts.dart';
import '../../helpers/test_app.dart';
import '../../helpers/test_environment.dart';

void main() {
  setUpAll(loadTestFonts);
  setUp(initTestColors);

  void mobile(WidgetTester tester) {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  testWidgets('common settings row grows for long text at 320px and 200%', (
    tester,
  ) async {
    mobile(tester);
    var taps = 0;
    await tester.pumpWidget(
      buildTestApp(
        Padding(
          padding: const EdgeInsets.all(16),
          child: Align(
            alignment: Alignment.topCenter,
            child: PicnicListItem(
              leading: '알림과 이벤트 수신 설정을 변경합니다',
              assetPath: '',
              title: const Text('현재 설정값을 확인하세요'),
              tailing: const Icon(Icons.chevron_right),
              onTap: () => taps++,
            ),
          ),
        ),
        designSize: const Size(393, 892),
        splitScreenMode: true,
        textScaler: TextScaler.linear(2),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    final row = find.byType(InkWell);
    expect(tester.getSize(row).height, greaterThanOrEqualTo(48));
    for (final text in ['알림과 이벤트 수신 설정을 변경합니다', '현재 설정값을 확인하세요']) {
      final bounds = tester.getRect(find.text(text));
      expect(bounds.left, greaterThanOrEqualTo(16));
      expect(bounds.right, lessThanOrEqualTo(304));
      expect(bounds.bottom, lessThanOrEqualTo(tester.getRect(row).bottom));
    }
    await tester.tap(row);
    expect(taps, 1);
  });

  testWidgets('header notification target is at least 48px on both axes', (
    tester,
  ) async {
    mobile(tester);
    await tester.pumpWidget(
      buildTestApp(
        const Align(
          alignment: Alignment.topRight,
          child: TopRightNotifications(),
        ),
        extraOverrides: [
          unreadNotificationsCountProvider.overrideWith((ref) async => 9),
        ],
      ),
    );
    await tester.pumpAndSettle();
    final button = find.byType(IconButton);
    expect(tester.getSize(button).width, greaterThanOrEqualTo(48));
    expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
    expect(find.text('9'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final scale in [1.0, 2.0]) {
    testWidgets(
      'QnA composer controls are reachable and suppress a busy send at $scale',
      (tester) async {
        mobile(tester);
        final controller = TextEditingController(text: '메시지');
        addTearDown(controller.dispose);
        var sends = 0;
        var picks = 0;
        var removes = 0;
        Widget app(bool busy) => buildTestApp(
          Align(
            alignment: Alignment.bottomCenter,
            child: QnaMessageInput(
              isThreadOpen: true,
              showAutoCloseNotice: false,
              isSending: busy,
              attachments: [File('/tmp/qna-ui-attachment.txt')],
              messageController: controller,
              onSend: () => sends++,
              onPickMedia: () => picks++,
              onRemoveAttachment: (_) => removes++,
            ),
          ),
          designSize: const Size(393, 892),
          splitScreenMode: true,
          textScaler: TextScaler.linear(scale),
        );
        await tester.pumpWidget(app(false));
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(
          tester.getSize(find.byType(TextField)).height,
          greaterThanOrEqualTo(48),
        );
        for (final icon in [
          Icons.perm_media_outlined,
          Icons.send,
          Icons.close,
        ]) {
          final control = find.ancestor(
            of: find.byIcon(icon),
            matching: find.byType(IconButton),
          );
          expect(control, findsOneWidget);
          expect(tester.getSize(control).width, greaterThanOrEqualTo(48));
          expect(tester.getSize(control).height, greaterThanOrEqualTo(48));
          expect(control.hitTestable(), findsOneWidget);
          await tester.tap(control);
        }
        expect(sends, 1);
        expect(picks, 1);
        expect(removes, 1);
        await tester.pumpWidget(app(true));
        await tester.pump();
        if (find.byIcon(Icons.send).evaluate().isNotEmpty) {
          await tester.tap(find.byIcon(Icons.send), warnIfMissed: false);
        }
        expect(sends, 1);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}

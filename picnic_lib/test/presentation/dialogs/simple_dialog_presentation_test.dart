import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/dialogs/simple_dialog.dart';
import 'package:picnic_lib/ui/presentation_tokens.dart';

import '../../helpers/test_app.dart';
import '../../helpers/test_environment.dart';

void main() {
  setUp(() {
    initTestColors();
  });

  group('simple dialog actions', () {
    testWidgets('a dialog action owns a 48px tap target', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          Builder(
            builder: (context) => Row(
              children: [buildDialogButton(context, '확인', Colors.blue, () {})],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester.getSize(find.byType(TextButton)).height,
        greaterThanOrEqualTo(PicnicUi.minimumTapTarget),
      );
    });

    testWidgets('a dialog action label uses the readable token style', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          Builder(
            builder: (context) => Row(
              children: [buildDialogButton(context, '확인', Colors.blue, () {})],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final label = tester.widget<Text>(find.text('확인'));
      expect(label.style?.height, 1.45);
      expect(label.style?.letterSpacing, 0);
      expect(label.style?.fontFamily, contains('Pretendard'));
    });

    testWidgets('a long action label wraps instead of overflowing at 200%', (
      tester,
    ) async {
      const longLabel = '지금 바로 결제를 계속 진행하시겠습니까 확인';

      await tester.pumpWidget(
        buildTestApp(
          Builder(
            builder: (context) => SizedBox(
              width: 240,
              child: Row(
                children: [
                  buildDialogButton(context, longLabel, Colors.blue, () {}),
                ],
              ),
            ),
          ),
          textScaler: const TextScaler.linear(2),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final label = tester.widget<Text>(find.text(longLabel));
      expect(label.softWrap, isNot(false));
      expect(label.overflow, isNot(TextOverflow.clip));
      expect(
        tester.getSize(find.text(longLabel)).width,
        lessThanOrEqualTo(tester.getSize(find.byType(TextButton)).width),
      );
    });

    testWidgets('both actions stay reachable inside the dialog at 200%', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => showSimpleDialog(
                title: '알림',
                content: '아주 긴 본문 문구를 읽고 결정해 주세요. 확인 또는 취소를 눌러 주세요.',
                onOk: () {},
                onCancel: () {},
              ),
              child: const Text('Show'),
            ),
          ),
          textScaler: const TextScaler.linear(2),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final actions = find.byType(TextButton);
      expect(actions, findsNWidgets(2));
      for (var index = 0; index < 2; index += 1) {
        expect(
          tester.getSize(actions.at(index)).height,
          greaterThanOrEqualTo(PicnicUi.minimumTapTarget),
        );
      }
    });
  });
}

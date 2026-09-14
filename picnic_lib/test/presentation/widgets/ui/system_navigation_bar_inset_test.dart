import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/ui/system_navigation_bar_inset.dart';

void main() {
  const childKey = Key('inset-child');
  const hostKey = Key('inset-host');

  MediaQueryData? seen;

  Widget buildHost({required MediaQueryData data, Color color = Colors.white}) {
    return MediaQuery(
      data: data,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            key: hostKey,
            width: 400,
            height: 800,
            child: SystemNavigationBarInset(
              color: color,
              child: Builder(
                builder: (context) {
                  seen = MediaQuery.of(context);
                  return const SizedBox.expand(key: childKey);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  const threeButtonBar = MediaQueryData(
    size: Size(400, 800),
    padding: EdgeInsets.only(bottom: 48),
    viewPadding: EdgeInsets.only(bottom: 48),
  );

  // The platform is read at build time, so the override only needs to be
  // active while pumping; the test binding requires it reset before the end.
  Future<void> pumpHost(
    WidgetTester tester, {
    required TargetPlatform platform,
    required MediaQueryData data,
    Color color = Colors.white,
  }) async {
    debugDefaultTargetPlatformOverride = platform;
    try {
      await tester.pumpWidget(buildHost(data: data, color: color));
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  }

  setUp(() => seen = null);

  group('SystemNavigationBarInset', () {
    testWidgets('Android: reserves the system bar height below the child', (
      tester,
    ) async {
      await pumpHost(
        tester,
        platform: TargetPlatform.android,
        data: threeButtonBar,
      );

      final host = tester.getRect(find.byKey(hostKey));
      final child = tester.getRect(find.byKey(childKey));
      expect(child.top, host.top);
      expect(child.bottom, host.bottom - 48);
    });

    testWidgets('Android: descendants see no bottom padding or viewPadding', (
      tester,
    ) async {
      await pumpHost(
        tester,
        platform: TargetPlatform.android,
        data: threeButtonBar,
      );

      expect(seen!.padding.bottom, 0);
      expect(seen!.viewPadding.bottom, 0);
    });

    testWidgets('Android: reserved strip is painted with the given color', (
      tester,
    ) async {
      await pumpHost(
        tester,
        platform: TargetPlatform.android,
        data: threeButtonBar,
        color: Colors.red,
      );

      final boxes = tester.widgetList<ColoredBox>(
        find.descendant(
          of: find.byType(SystemNavigationBarInset),
          matching: find.byType(ColoredBox),
        ),
      );
      expect(boxes.map((b) => b.color), contains(Colors.red));
    });

    testWidgets('Android: keyboard covering the bar reserves nothing', (
      tester,
    ) async {
      // Scaffold removes the covered part from `padding` when the keyboard is
      // up; the widget must follow `padding`, not `viewPadding`.
      await pumpHost(
        tester,
        platform: TargetPlatform.android,
        data: const MediaQueryData(
          size: Size(400, 800),
          padding: EdgeInsets.zero,
          viewPadding: EdgeInsets.only(bottom: 48),
          viewInsets: EdgeInsets.only(bottom: 300),
        ),
      );

      final host = tester.getRect(find.byKey(hostKey));
      final child = tester.getRect(find.byKey(childKey));
      expect(child.bottom, host.bottom);
    });

    testWidgets('iOS: passes through untouched', (tester) async {
      await pumpHost(
        tester,
        platform: TargetPlatform.iOS,
        data: const MediaQueryData(
          size: Size(400, 800),
          padding: EdgeInsets.only(bottom: 34),
          viewPadding: EdgeInsets.only(bottom: 34),
        ),
      );

      final host = tester.getRect(find.byKey(hostKey));
      final child = tester.getRect(find.byKey(childKey));
      expect(child.bottom, host.bottom);
      expect(seen!.padding.bottom, 34);
      expect(seen!.viewPadding.bottom, 34);
    });
  });
}

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/store_list_tile.dart';

import '../../../../../helpers/test_app.dart';
import '../../../../../helpers/test_environment.dart';

// Minimal 1x1 transparent PNG
final _kTransparentPixel = Uint8List.fromList([
  0x89,
  0x50,
  0x4E,
  0x47,
  0x0D,
  0x0A,
  0x1A,
  0x0A,
  0x00,
  0x00,
  0x00,
  0x0D,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x06,
  0x00,
  0x00,
  0x00,
  0x1F,
  0x15,
  0xC4,
  0x89,
  0x00,
  0x00,
  0x00,
  0x0A,
  0x49,
  0x44,
  0x41,
  0x54,
  0x78,
  0x9C,
  0x62,
  0x00,
  0x00,
  0x00,
  0x02,
  0x00,
  0x01,
  0xE5,
  0x27,
  0xDE,
  0xFC,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4E,
  0x44,
  0xAE,
  0x42,
  0x60,
  0x82,
]);

Image _testIcon() => Image.memory(_kTransparentPixel, width: 36, height: 36);

void main() {
  setUpAll(() {
    initTestColors();
  });

  group('StoreListTile', () {
    testWidgets('renders with title and button', (tester) async {
      // Allow overflow in tests (the widget uses ScreenUtil sizing)
      final oldHandler = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.toString().contains('overflowed')) return;
        oldHandler?.call(details);
      };

      await tester.pumpWidget(
        buildTestApp(
          StoreListTile(
            icon: _testIcon(),
            title: const Text('Star Candy 100'),
            buttonText: '₩1,100',
            buttonOnPressed: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Star Candy 100'), findsOneWidget);
      expect(find.text('₩1,100'), findsOneWidget);
      expect(
        find.byWidgetPredicate((widget) => widget is ButtonStyleButton),
        findsOneWidget,
      );

      FlutterError.onError = oldHandler;
    });

    testWidgets('renders with subtitle', (tester) async {
      final oldHandler = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.toString().contains('overflowed')) return;
        oldHandler?.call(details);
      };

      await tester.pumpWidget(
        buildTestApp(
          StoreListTile(
            icon: _testIcon(),
            title: const Text('Star Candy 500'),
            subtitle: const Text('Best Value'),
            buttonText: '₩5,500',
            buttonOnPressed: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Star Candy 500'), findsOneWidget);
      expect(find.text('Best Value'), findsOneWidget);
      expect(find.text('₩5,500'), findsOneWidget);

      FlutterError.onError = oldHandler;
    });

    testWidgets('shares one action width across tiles and centers the label', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const labels = ['₩9,900', '₩110,000'];

      await tester.pumpWidget(
        buildTestApp(
          Builder(
            builder: (context) {
              final width = StoreListTile.uniformActionWidth(context, labels);
              return Column(
                children: [
                  for (final label in labels)
                    StoreListTile(
                      // The 1x1 test PNG above fails to decode and paints an
                      // error label wide enough to overflow the row, which
                      // is what the other tests here filter out. This one
                      // measures layout, so it needs a real asset.
                      icon: Image.asset(
                        'assets/icons/store/currency_bonus_star_candy.png',
                        package: 'picnic_lib',
                        width: 48,
                        height: 48,
                      ),
                      title: Text(label),
                      buttonText: label,
                      buttonOnPressed: () {},
                      actionMinWidth: width,
                    ),
                ],
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final buttons = find.byWidgetPredicate((w) => w is ButtonStyleButton);
      expect(buttons, findsNWidgets(2));
      final short = tester.getRect(buttons.at(0));
      final long = tester.getRect(buttons.at(1));
      expect(short.width, closeTo(long.width, 0.5));
      final shortLabel = find.descendant(
        of: buttons.at(0),
        matching: find.text('₩9,900'),
      );
      expect(
        tester.getRect(shortLabel).center.dx,
        closeTo(short.center.dx, 0.5),
      );
    });

    testWidgets('renders disabled button when buttonOnPressed is null', (
      tester,
    ) async {
      final oldHandler = FlutterError.onError;
      FlutterError.onError = (details) {
        if (details.toString().contains('overflowed')) return;
        oldHandler?.call(details);
      };

      await tester.pumpWidget(
        buildTestApp(
          StoreListTile(
            icon: _testIcon(),
            title: const Text('Item'),
            buttonText: 'Buy',
            buttonOnPressed: null,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final button = tester.widget<ButtonStyleButton>(
        find.byWidgetPredicate((widget) => widget is ButtonStyleButton),
      );
      expect(button.onPressed, isNull);

      FlutterError.onError = oldHandler;
    });
  });
}

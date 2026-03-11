import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/purchase/store_list_tile.dart';

import '../../../../../helpers/test_app.dart';
import '../../../../../helpers/test_environment.dart';

// Minimal 1x1 transparent PNG
final _kTransparentPixel = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
  0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x62, 0x00, 0x00, 0x00, 0x02,
  0x00, 0x01, 0xE5, 0x27, 0xDE, 0xFC, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45,
  0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
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
      expect(find.byType(ElevatedButton), findsOneWidget);

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

    testWidgets('renders disabled button when buttonOnPressed is null',
        (tester) async {
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

      final button =
          tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);

      FlutterError.onError = oldHandler;
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/config/environment.dart';
import 'package:ttja_app/app.dart';

void main() {
  setUpAll(() {
    Environment.initTestConfig({
      'theme': {
        'colors': {
          'primary': '0xFF6200EE',
          'secondary': '0xFF03DAC6',
          'sub': '0xFFBB86FC',
          'point': '0xFFFF0266',
          'point_900': '0xFFCF6679',
        },
      },
      'logging': {'level': 'off'},
    });
  });

  testWidgets('TTJA keeps the splash visible while SDK startup is pending',
      (tester) async {
    await tester.pumpWidget(const ProviderScope(child: App()));
    await tester.pump();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.title, 'TTJA');
    expect(
      find.byWidgetPredicate((widget) =>
          widget is Image &&
          widget.image is AssetImage &&
          (widget.image as AssetImage).assetName == 'assets/splash.webp'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/app_builder.dart';
import 'package:picnic_lib/ui/fixed_width_layout.dart';

class FoldableWidthProbe extends StatelessWidget {
  const FoldableWidthProbe({super.key});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SizedBox(key: const Key('scaled-width'), width: 100.w, height: 10),
      const TextField(key: Key('field')),
    ],
  );
}

void main() {
  testWidgets(
    'production scale follows the single column across fold changes',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(466, 678);
      addTearDown(tester.view.reset);
      final nav = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        AppBuilder.buildApp(
          navigatorKey: nav,
          scaffoldKey: GlobalKey<ScaffoldMessengerState>(),
          routes: const {},
          title: 'Fold layout test',
          theme: ThemeData(),
          home: const FixedWidthLayout(
            child: Scaffold(body: FoldableWidthProbe()),
          ),
          localizationsDelegates: const [],
          supportedLocales: const [Locale('en')],
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('field')), 'keep on fold');
      final field = tester.element(find.byKey(const Key('field')));
      for (final size in const [
        Size(466, 678),
        Size(951, 669),
        Size(400, 640),
        Size(800, 600),
        Size(600, 800),
        Size(320, 400),
      ]) {
        tester.view.physicalSize = size;
        await tester.pumpAndSettle();
        expect(MediaQuery.sizeOf(nav.currentContext!), size);
        expect(
          tester.getSize(find.byKey(const Key('scaled-width'))).width,
          closeTo(100 * math.min(size.width, 600) / kAppDesignSize.width, .01),
          reason: 'UI scale must use content width, window=$size',
        );
        expect(tester.element(find.byKey(const Key('field'))), same(field));
        expect(find.text('keep on fold'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    },
  );
}

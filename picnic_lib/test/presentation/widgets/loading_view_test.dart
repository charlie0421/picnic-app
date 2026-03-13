import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/loading_view.dart';
import 'package:picnic_lib/presentation/widgets/ui/pulse_loading_indicator.dart';

import '../../helpers/test_app.dart';
import '../../helpers/test_environment.dart';

void main() {
  setUp(() {
    initTestColors();
  });

  group('LoadingView', () {
    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(
        buildTestApp(const LoadingView()),
      );
      await tester.pump();
      tester.takeException(); // clear Image.asset errors

      expect(find.byType(LoadingView), findsOneWidget);
    });

    testWidgets('contains Container with center alignment', (tester) async {
      await tester.pumpWidget(
        buildTestApp(const LoadingView()),
      );
      await tester.pump();
      tester.takeException();

      // Find the Container that is a direct child of LoadingView
      final container = tester.widgetList<Container>(
        find.byType(Container),
      ).where((c) => c.alignment == Alignment.center);
      expect(container, isNotEmpty);
    });

    testWidgets('contains LargePulseLoadingIndicator', (tester) async {
      await tester.pumpWidget(
        buildTestApp(const LoadingView()),
      );
      await tester.pump();
      tester.takeException();

      expect(find.byType(LargePulseLoadingIndicator), findsOneWidget);
    });

    testWidgets('timer is properly disposed when widget is removed',
        (tester) async {
      await tester.pumpWidget(
        buildTestApp(const LoadingView()),
      );
      await tester.pump();
      tester.takeException();

      // Remove the widget by pumping a different widget
      await tester.pumpWidget(
        buildTestApp(const SizedBox()),
      );
      await tester.pump();

      // If the timer was not properly cancelled, this would throw
      // "setState() called after dispose()"
      await tester.pump(const Duration(milliseconds: 600));
      expect(tester.takeException(), isNull);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/free_charge_content.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/free_charge_station.dart';

import '../../../../../helpers/ignore_image_errors.dart';
import '../../../../../helpers/test_app.dart';

void main() {
  late RestoreCallback restore;

  setUp(() {
    restore = suppressImageErrors();
    initTestEnvironment();
  });

  tearDown(() {
    restore();
  });

  group('FreeChargeStation', () {
    test('can be instantiated', () {
      const widget = FreeChargeStation();
      expect(widget, isNotNull);
    });

    test('can be instantiated with key', () {
      const widget = FreeChargeStation(key: ValueKey('test'));
      expect(widget.key, isNotNull);
    });

    testWidgets('renders FreeChargeContent inside RefreshIndicator', (tester) async {
      await pumpWidgetAndIgnoreErrors(
        tester,
        buildTestApp(
          const FreeChargeStation(),
          loggedIn: true,
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester);

      expect(find.byType(FreeChargeStation), findsOneWidget);
      expect(find.byType(RefreshIndicator), findsOneWidget);
      expect(find.byType(FreeChargeContent), findsOneWidget);
    });

    testWidgets('renders when logged out', (tester) async {
      await pumpWidgetAndIgnoreErrors(
        tester,
        buildTestApp(
          const FreeChargeStation(),
          loggedIn: false,
        ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester);

      expect(find.byType(FreeChargeStation), findsOneWidget);
    });

  });
}

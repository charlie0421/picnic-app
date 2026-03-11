import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/enums.dart';
import 'package:picnic_lib/presentation/common/portal_menu_item.dart';

import '../../helpers/mock_data.dart';
import '../../helpers/mock_providers.dart';
import '../../helpers/test_app.dart';
import '../../helpers/test_environment.dart';

void main() {
  setUpAll(() {
    initTestColors();
  });

  group('PortalMenuItem', () {
    testWidgets('renders vote portal name', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const PortalMenuItem(portalType: PortalType.vote),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('VOTE'), findsOneWidget);
    });

    testWidgets('renders goongHap display name', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const PortalMenuItem(portalType: PortalType.goongHap),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Goong-Hap'), findsOneWidget);
    });

    testWidgets('renders pic portal name', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const PortalMenuItem(portalType: PortalType.pic),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('PIC'), findsOneWidget);
    });

    testWidgets('selected state when matching portal type', (tester) async {
      await tester.pumpWidget(
        buildTestAppWithNavigation(
          const PortalMenuItem(portalType: PortalType.vote),
          navigation: MockData.navigation(portalType: PortalType.vote),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('VOTE'), findsOneWidget);
    });

    testWidgets('unselected state when not matching portal type', (tester) async {
      await tester.pumpWidget(
        buildTestAppWithNavigation(
          const PortalMenuItem(portalType: PortalType.pic),
          navigation: MockData.navigation(portalType: PortalType.vote),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('PIC'), findsOneWidget);
    });

    testWidgets('tapping calls setPortal', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const PortalMenuItem(portalType: PortalType.pic),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('PIC'));
      await tester.pumpAndSettle();
    });
  });
}

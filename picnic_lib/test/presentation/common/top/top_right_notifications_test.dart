import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/common/top/top_right_notifications.dart';
import 'package:picnic_lib/presentation/providers/notifications_unread_count_provider.dart';

import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

void main() {
  setUp(() {
    initTestColors();
  });

  group('TopRightNotifications', () {
    testWidgets('renders notification bell icon when count is 0 (no badge)', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          const TopRightNotifications(),
          extraOverrides: [
            unreadNotificationsCountProvider.overrideWith((ref) async => 0),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.notifications), findsOneWidget);
      // No badge text should be present
      expect(find.text('0'), findsNothing);
      expect(find.text('9+'), findsNothing);
    });

    testWidgets('shows badge with count when count > 0', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          const TopRightNotifications(),
          extraOverrides: [
            unreadNotificationsCountProvider.overrideWith((ref) async => 5),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.notifications), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('shows "9+" when count > 9', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const TopRightNotifications(),
          extraOverrides: [
            unreadNotificationsCountProvider.overrideWith((ref) async => 15),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('9+'), findsOneWidget);
    });

    testWidgets('contains IconButton with tooltip 알림', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          const TopRightNotifications(),
          extraOverrides: [
            unreadNotificationsCountProvider.overrideWith((ref) async => 0),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final iconButton = tester.widget<IconButton>(find.byType(IconButton));
      expect(iconButton.tooltip, '알림');
    });

    testWidgets('SizedBox has width: 40, height: 40', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          const TopRightNotifications(),
          extraOverrides: [
            unreadNotificationsCountProvider.overrideWith((ref) async => 0),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(sizedBox.width, 40);
      expect(sizedBox.height, 40);
    });
  });
}

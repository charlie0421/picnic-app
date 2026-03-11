import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/common/top/top_right_notifications.dart';
import 'package:picnic_lib/presentation/providers/notifications_unread_count_provider.dart';

import '../../helpers/test_app.dart';
import '../../helpers/test_environment.dart';

void main() {
  setUpAll(() {
    initTestColors();
  });

  group('TopRightNotifications', () {
    testWidgets('renders bell icon with zero unread', (tester) async {
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
      // No badge text when count is 0
      expect(find.text('0'), findsNothing);
    });

    testWidgets('renders badge with unread count', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const TopRightNotifications(),
          extraOverrides: [
            unreadNotificationsCountProvider.overrideWith((ref) async => 5),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('renders 9+ when count exceeds 9', (tester) async {
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

    testWidgets('renders 1 notification badge', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const TopRightNotifications(),
          extraOverrides: [
            unreadNotificationsCountProvider.overrideWith((ref) async => 1),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('has tooltip', (tester) async {
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
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/vote/vote_item_request/status_badge.dart';

import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

void main() {
  setUp(() {
    initTestColors();
  });

  group('StatusBadge', () {
    testWidgets('renders with pending status', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const StatusBadge(status: 'pending'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(StatusBadge), findsOneWidget);
    });

    testWidgets('renders with approved status', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const StatusBadge(status: 'approved'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(StatusBadge), findsOneWidget);
    });

    testWidgets('renders with rejected status', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const StatusBadge(status: 'rejected'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(StatusBadge), findsOneWidget);
    });

    testWidgets('renders with in-progress status',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const StatusBadge(status: 'in-progress'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(StatusBadge), findsOneWidget);
    });

    testWidgets('renders with cancelled status', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const StatusBadge(status: 'cancelled'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(StatusBadge), findsOneWidget);
    });

    testWidgets('renders with unknown status', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const StatusBadge(status: 'unknown'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(StatusBadge), findsOneWidget);
    });
  });
}

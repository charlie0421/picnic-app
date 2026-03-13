import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/list/countdown_timer.dart';

import '../../../../helpers/test_app.dart';
import '../../../../helpers/test_environment.dart';

void main() {
  setUp(() {
    initTestColors();
  });

  group('CountdownTimer', () {
    testWidgets('renders with active status', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          CountdownTimer(
            endTime: DateTime.now().toUtc().add(const Duration(hours: 2)),
            status: VoteStatus.active,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CountdownTimer), findsOneWidget);
    });

    testWidgets('renders with upcoming status', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          CountdownTimer(
            endTime: DateTime.now().toUtc().add(const Duration(days: 3)),
            status: VoteStatus.upcoming,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CountdownTimer), findsOneWidget);
    });

    testWidgets('renders with end status', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          CountdownTimer(
            endTime: DateTime.now().toUtc().subtract(const Duration(hours: 1)),
            status: VoteStatus.end,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CountdownTimer), findsOneWidget);
    });

    testWidgets('renders with past end time', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          CountdownTimer(
            endTime: DateTime.now().toUtc().subtract(const Duration(days: 1)),
            status: VoteStatus.active,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CountdownTimer), findsOneWidget);
    });
  });
}

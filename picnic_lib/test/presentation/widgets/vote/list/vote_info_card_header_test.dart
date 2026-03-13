import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/list/vote_info_card_header.dart';

import '../../../../helpers/test_app.dart';
import '../../../../helpers/test_environment.dart';

void main() {
  setUp(() {
    initTestColors();
  });

  group('VoteCardInfoHeader', () {
    testWidgets('renders with active status', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          VoteCardInfoHeader(
            title: 'Best Artist Vote',
            stopAt: DateTime.now().toUtc().add(const Duration(hours: 5)),
            status: VoteStatus.active,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(VoteCardInfoHeader), findsOneWidget);
      expect(find.text('Best Artist Vote'), findsOneWidget);
    });

    testWidgets('renders with upcoming status', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          VoteCardInfoHeader(
            title: 'Upcoming Vote',
            stopAt: DateTime.now().toUtc().add(const Duration(days: 7)),
            status: VoteStatus.upcoming,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Upcoming Vote'), findsOneWidget);
    });

    testWidgets('renders with end status', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          VoteCardInfoHeader(
            title: 'Ended Vote',
            stopAt: DateTime.now().toUtc().subtract(const Duration(days: 1)),
            status: VoteStatus.end,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Ended Vote'), findsOneWidget);
    });

    testWidgets('renders with long title', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          VoteCardInfoHeader(
            title: 'This is a very long title for testing overflow behavior in the card header',
            stopAt: DateTime.now().toUtc().add(const Duration(hours: 1)),
            status: VoteStatus.active,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(VoteCardInfoHeader), findsOneWidget);
    });
  });
}

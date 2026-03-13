import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/vote/vote_card_skeleton_upcoming.dart';

import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

void main() {
  setUp(() {
    initTestColors();
  });

  group('VoteCardSkeletonUpcoming', () {
    testWidgets('renders without error', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const VoteCardSkeletonUpcoming(),
        ),
      );
      await tester.pump();

      expect(find.byType(VoteCardSkeletonUpcoming), findsOneWidget);
    });
  });
}

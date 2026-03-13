import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/vote/list/vote_detail_title.dart';

import '../../../../helpers/test_app.dart';
import '../../../../helpers/test_environment.dart';

void main() {
  setUp(() {
    initTestColors();
  });

  group('VoteCommonTitle', () {
    testWidgets('renders with title text', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const VoteCommonTitle(title: 'Best Artist Award'),
        ),
      );
      await tester.pump();

      expect(find.byType(VoteCommonTitle), findsOneWidget);
      expect(find.text('Best Artist Award'), findsNWidgets(2)); // stroke + fill
    });

    testWidgets('renders with different title', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const VoteCommonTitle(title: 'K-POP Vote'),
        ),
      );
      await tester.pump();

      expect(find.text('K-POP Vote'), findsNWidgets(2));
    });

    testWidgets('renders with long title', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const VoteCommonTitle(
            title: 'This is a very long title that should overflow',
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(VoteCommonTitle), findsOneWidget);
    });
  });
}

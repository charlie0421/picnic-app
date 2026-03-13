import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/common/no_item_container.dart';

import '../../helpers/test_app.dart';
import '../../helpers/test_environment.dart';

void main() {
  setUp(() {
    initTestColors();
  });

  group('NoItemContainer', () {
    testWidgets('renders with custom message', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const NoItemContainer(message: 'No items found'),
        ),
      );
      await tester.pump();

      expect(find.byType(NoItemContainer), findsOneWidget);
      expect(find.text('No items found'), findsOneWidget);
    });

    testWidgets('renders with default message', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          const NoItemContainer(),
        ),
      );
      await tester.pump();

      expect(find.byType(NoItemContainer), findsOneWidget);
    });
  });
}

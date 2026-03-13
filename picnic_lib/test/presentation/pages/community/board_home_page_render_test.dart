import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/pages/community/board_home_page.dart';

import '../../../helpers/ignore_image_errors.dart';
import '../../../helpers/mock_supabase.dart';
import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

void main() {
  late void Function() restore;

  setUp(() {
    initTestColors();
    setupMockSupabase({
      'boards': <dynamic>[],
      'artist': [
        {
          'id': 1,
          'name': {'ko': '지민', 'en': 'Jimin'},
          'image': null,
          'gender': null,
          'birth_date': null,
        },
      ],
    });
    restore = suppressImageErrors();
  });

  tearDown(() {
    restore();
    tearDownMockSupabase();
  });

  group('BoardHomePage render', () {
    testWidgets('renders with artist id', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestAppPage(const BoardHomePage(1)),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));
      expect(find.byType(BoardHomePage), findsOneWidget);
    });
  });
}

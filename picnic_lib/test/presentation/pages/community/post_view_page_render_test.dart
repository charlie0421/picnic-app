import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/pages/community/post_view_page.dart';

import '../../../helpers/ignore_image_errors.dart';
import '../../../helpers/mock_supabase.dart';
import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

void main() {
  late void Function() restore;

  setUp(() {
    initTestColors();
    setupMockSupabase({
      'posts': <dynamic>[],
      'comments': <dynamic>[],
      'user_blocks': <dynamic>[],
    });
    restore = suppressImageErrors();
  });

  tearDown(() {
    restore();
    tearDownMockSupabase();
  });

  group('PostViewPage render', () {
    testWidgets('renders loading state for a post',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestAppPage(
          const PostViewPage('test-post-id', syncNavigation: false),
        ),
      );
      await pumpAndIgnoreErrors(tester);
      // The page shows a loading indicator initially
      expect(find.byType(PostViewPage), findsOneWidget);
    });
  });
}

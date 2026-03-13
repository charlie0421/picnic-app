import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/pages/community/community_my_comment.dart';

import '../../../helpers/ignore_image_errors.dart';
import '../../../helpers/mock_supabase.dart';
import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

void main() {
  late void Function() restore;

  setUp(() async {
    initTestColors();
    // CommunityMyComment calls supabase.auth.currentUser!.id directly
    // so we must use async setupMockSupabaseWithAuth to actually sign in
    await setupMockSupabaseWithAuth(
      {'comments': <dynamic>[]},
      userId: 'test-user-id',
    );
    restore = suppressImageErrors();
  });

  tearDown(() {
    restore();
    tearDownMockSupabase();
  });

  group('CommunityMyComment render', () {
    testWidgets('renders with empty comments', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestAppPage(const CommunityMyComment()),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));
      expect(find.byType(CommunityMyComment), findsOneWidget);
    });
  });
}

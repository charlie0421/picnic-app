import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/pages/vote/home_page.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../helpers/mock_supabase.dart';
import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

void main() {
  setUp(() {
    initTestColors();
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    setupMockSupabase({
      'banner': <dynamic>[],
      'reward': <dynamic>[],
      'vote': <dynamic>[],
      'media': <dynamic>[],
    });
  });

  tearDown(() {
    tearDownMockSupabase();
  });

  group('HomePage render', () {
    testWidgets('renders empty state without crashing', (tester) async {
      await tester.pumpWidget(buildTestApp(const HomePage()));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(HomePage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

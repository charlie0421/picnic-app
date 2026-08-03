import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/common/navigation.dart';
import 'package:picnic_lib/navigation_stack.dart';
import 'package:picnic_lib/presentation/pages/my_page/admin_menu_page.dart';
import 'package:picnic_lib/presentation/pages/my_page/currency_history_page.dart';
import 'package:picnic_lib/presentation/screens/mypage_screen.dart';

import '../../../helpers/ignore_image_errors.dart';
import '../../../helpers/mock_data.dart';
import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

void main() {
  setUpAll(initTestColors);

  testWidgets('shows all administrator tools and opens candy history', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTestAppPage(
        const MyPageScreen(),
        navigation: Navigation(
          drawerNavigationStack: NavigationStack(
            initialPage: const AdminMenuPage(),
          ),
        ),
        userProfile: MockData.userProfile(isAdmin: true),
      ),
    );
    await pumpAndIgnoreErrors(tester);

    expect(find.text('캔디 내역'), findsOneWidget);
    expect(find.text('충전 내역'), findsOneWidget);
    expect(find.text('Ad Inspector'), findsOneWidget);
    expect(find.text('Reset & Reload GDPR'), findsOneWidget);

    await tester.tap(find.text('캔디 내역'));
    await pumpAndIgnoreErrors(tester);
    expect(find.byType(CurrencyHistoryPage), findsOneWidget);
  });

  testWidgets('denies a non-admin direct access to administrator tools', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTestAppPage(
        const AdminMenuPage(),
        userProfile: MockData.userProfile(isAdmin: false),
      ),
    );
    await pumpAndIgnoreErrors(tester);

    expect(find.text('접근 권한이 없습니다.'), findsOneWidget);
    expect(find.text('캔디 내역'), findsNothing);
  });
}

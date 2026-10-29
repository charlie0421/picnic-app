import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/common/navigation.dart';
import 'package:picnic_lib/navigation_stack.dart';
import 'package:picnic_lib/presentation/controllers/admin_gdpr_reset_controller.dart';
import 'package:picnic_lib/presentation/pages/my_page/admin_menu_page.dart';
import 'package:picnic_lib/presentation/pages/my_page/charge_history_page.dart';
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

  testWidgets(
      'super-admin-only account (is_admin=false) can access the menu - '
      'DB predicate is_super_admin OR is_admin 과 일치해야 한다', (tester) async {
    await tester.pumpWidget(
      buildTestAppPage(
        const MyPageScreen(),
        navigation: Navigation(
          drawerNavigationStack: NavigationStack(
            initialPage: const AdminMenuPage(),
          ),
        ),
        userProfile: MockData.userProfile(isAdmin: false, isSuperAdmin: true),
      ),
    );
    await pumpAndIgnoreErrors(tester);

    expect(find.text('접근 권한이 없습니다.'), findsNothing);
    expect(find.text('캔디 내역'), findsOneWidget);
  });

  testWidgets('opens charge history from the administrator menu', (
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

    await tester.tap(find.text('충전 내역'));
    await pumpAndIgnoreErrors(tester);

    expect(find.byType(ChargeHistoryPage), findsOneWidget);
  });

  testWidgets('uses an exact 16px horizontal content inset', (tester) async {
    await tester.pumpWidget(
      buildTestAppPage(
        const AdminMenuPage(),
        userProfile: MockData.userProfile(isAdmin: true),
      ),
    );
    await pumpAndIgnoreErrors(tester);

    final content = tester.widget<Padding>(
      find.byKey(const Key('admin-menu-content')),
    );
    expect(content.padding, const EdgeInsets.symmetric(horizontal: 16));
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

  testWidgets('reloads the app once after a successful GDPR reset', (
    tester,
  ) async {
    var reloads = 0;
    final controller = AdminGdprResetController(
      resetAndReinitialize: () async => true,
      logCurrentState: () async {},
    );

    await tester.pumpWidget(
      buildTestAppPage(
        AdminMenuPage(
          gdprResetController: controller,
          reloadApp: (_) => reloads++,
        ),
        userProfile: MockData.userProfile(isAdmin: true),
      ),
    );
    await pumpAndIgnoreErrors(tester);

    await tester.tap(find.text('Reset & Reload GDPR'));
    await pumpAndIgnoreErrors(tester);
    await pumpAndIgnoreErrors(tester);

    expect(reloads, 1);
  });

  testWidgets('does not reload the app after a failed GDPR reset', (
    tester,
  ) async {
    var reloads = 0;
    final controller = AdminGdprResetController(
      resetAndReinitialize: () async => false,
      logCurrentState: () async {},
    );

    await tester.pumpWidget(
      buildTestAppPage(
        AdminMenuPage(
          gdprResetController: controller,
          reloadApp: (_) => reloads++,
        ),
        userProfile: MockData.userProfile(isAdmin: true),
      ),
    );
    await pumpAndIgnoreErrors(tester);

    await tester.tap(find.text('Reset & Reload GDPR'));
    await pumpAndIgnoreErrors(tester);
    await pumpAndIgnoreErrors(tester);

    expect(reloads, 0);
  });
}

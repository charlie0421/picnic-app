// Direct production widgets with local data. No live save, ad, vote or purchase.
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/pages/my_page/my_profile.dart';
import 'package:picnic_lib/presentation/pages/my_page/setting_page.dart';
import 'package:picnic_lib/presentation/pages/my_page/vote_history_page.dart';
import 'package:picnic_lib/presentation/providers/wallet_provider.dart';
import '../../../picnic_lib/test/helpers/extended_ui_fixtures.dart';
import '../../../picnic_lib/test/helpers/foldable_test_app.dart';
import '../../../picnic_lib/test/helpers/mock_supabase.dart';
import '../../../picnic_lib/test/helpers/test_environment.dart';
import 'current_service_foldable_device_test.dart'
    show frames, capture, fold, keyboard, window;

class _NoNetwork extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) =>
      throw StateError('External network is forbidden in the UI fixture');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final previous = HttpOverrides.current;
  setUpAll(() => HttpOverrides.global = _NoNetwork());
  tearDownAll(() => HttpOverrides.global = previous);
  setUp(() async {
    initTestColors();
    resetFoldableTestPlugins();
    await setupMockSupabaseWithAuth(extendedScreenFixtures(),
        userId: 'test-user-id');
  });
  tearDown(() {
    expect(
        capturedMockRequests
            .where((uri) => uri.path.contains('/functions/v1/')),
        isEmpty);
    tearDownMockSupabase();
  });
  testWidgets('extended native widgets and profile draft across fold',
      (tester) async {
    tester.testTextInput.unregister();
    addTearDown(tester.testTextInput.register);
    Future<void> show(Widget page, {String language = 'en'}) async {
      await tester.pumpWidget(const SizedBox.shrink());
      await frames(tester, 2);
      await tester.pumpWidget(buildFoldableTestApp(page,
          textScale: 2.6,
          locale: Locale(language),
          deviceAssets: true,
          overrides: [walletSummaryProvider.overrideWith(LayoutWallet.new)]));
      await frames(tester);
    }

    await show(const VoteHistoryPage());
    await capture(tester, 'extended-history');
    await show(const LayoutChargeContent(title: 'Video'));
    final action = find.byKey(const ValueKey('free-charge-ad'));
    await tester.scrollUntilVisible(action, 150,
        scrollable: find.byType(Scrollable).first);
    await frames(tester);
    await capture(tester, 'extended-charge');
    await show(const SettingPage());
    await capture(tester, 'extended-settings');
    await show(const MyProfilePage());
    final field = find.byType(TextFormField);
    final editable = find.byType(EditableText);
    await tester.ensureVisible(field);
    await tester.tap(field);
    await frames(tester);
    tester.state<EditableTextState>(editable).updateEditingValue(
        const TextEditingValue(
            text: 'NewName', selection: TextSelection.collapsed(offset: 3)));
    await frames(tester);
    expect(keyboard(tester), greaterThan(0));
    await capture(tester, 'extended-profile-before');
    await fold(tester, 'extended-profile');
    expect(tester.widget<EditableText>(editable).controller.text, 'NewName');
    expect(
        tester.widget<EditableText>(editable).controller.selection.baseOffset,
        3);
    await tester.ensureVisible(field);
    await tester.tap(field);
    await frames(tester, 25);
    expect(keyboard(tester), greaterThan(0));
    expect(tester.getRect(field).bottom,
        lessThanOrEqualTo(window(tester).height - keyboard(tester) + 1));
    await capture(tester, 'extended-profile-after');
    FocusManager.instance.primaryFocus?.unfocus();
    await frames(tester);
    final l10n =
        AppLocalizations.of(tester.element(find.byType(MyProfilePage)));
    final withdraw = find.text(l10n.label_mypage_withdrawal);
    await tester.scrollUntilVisible(withdraw, 150,
        scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(withdraw);
    await frames(tester);
    expect(withdraw.hitTestable(), findsOneWidget);
    await tester.tap(withdraw);
    await frames(tester);
    final cancel = find.text(l10n.dialog_button_cancel);
    await tester.ensureVisible(cancel);
    await frames(tester);
    expect(cancel.hitTestable(), findsOneWidget);
    await capture(tester, 'extended-withdraw-cancel');
    await tester.tap(cancel);
    await frames(tester);
    expect(find.byType(BottomSheet), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    await frames(tester);
  });
}

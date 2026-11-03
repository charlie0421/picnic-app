import 'dart:ui' show Tristate, SemanticsAction;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/pages/my_page/my_profile.dart';
import 'package:picnic_lib/presentation/pages/my_page/setting_page.dart';
import 'package:picnic_lib/presentation/pages/my_page/qna/qna_thread_create_page.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/free_charge_content.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/ad_loading_state.dart';
import 'package:picnic_lib/presentation/providers/wallet_provider.dart';
import '../../helpers/extended_ui_fixtures.dart';
import '../../helpers/foldable_test_app.dart';
import '../../helpers/load_test_fonts.dart';
import '../../helpers/mock_supabase.dart';
import '../../helpers/test_environment.dart';
import 'active_subpages_foldable_test.dart'
    show showPage, frames, LayoutQnaRepository;

void main() {
  setUpAll(loadTestFonts);
  setUp(() async {
    initTestColors();
    resetFoldableTestPlugins();
    PackageInfo.setMockInitialValues(
      appName: 'Picnic',
      packageName: 'test.picnic',
      version: '1',
      buildNumber: '1',
      buildSignature: '',
    );
    await setupMockSupabaseWithAuth({}, userId: 'test-user-id');
  });
  tearDown(tearDownMockSupabase);
  for (final language in ['ko', 'en', 'es']) {
    for (final scale in [1.0, 2.6]) {
      testWidgets('profile controls have named 48px targets $language $scale', (
        tester,
      ) async {
        final semantics = tester.ensureSemantics();
        try {
          await showPage(
            tester,
            const MyProfilePage(),
            const Size(320, 600),
            scale,
            language,
          );
          final l10n = AppLocalizations.of(
            tester.element(find.byType(MyProfilePage)),
          );
          final camera = find.byTooltip(l10n.profile_photo_change);
          expect(camera, findsOneWidget);
          expect(tester.getSize(camera).shortestSide, greaterThanOrEqualTo(48));
          final input = find.byType(TextFormField);
          final pill = find
              .ancestor(of: input, matching: find.byType(Container))
              .first;
          final pillHeight = tester.getSize(pill).height;
          await tester.enterText(input, 'NewName');
          await frames(tester);
          expect(tester.getSize(pill).height, pillHeight);
          final save = find.byTooltip(l10n.save);
          expect(save, findsOneWidget);
          expect(tester.getSize(save).width, greaterThanOrEqualTo(48));
          expect(tester.getSize(save).height, greaterThanOrEqualTo(48));
          final clear = find.byTooltip(
            MaterialLocalizations.of(tester.element(input)).deleteButtonTooltip,
          );
          expect(clear, findsOneWidget);
          expect(tester.getSize(clear).shortestSide, greaterThanOrEqualTo(48));
          await tester.tap(clear);
          await frames(tester);
          expect(
            tester
                .widget<EditableText>(find.byType(EditableText))
                .controller
                .text,
            isEmpty,
          );
        } finally {
          semantics.dispose();
        }
      });
    }
    testWidgets('settings switch has label state and 48px target $language', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      try {
        await showPage(
          tester,
          const SettingPage(),
          const Size(320, 600),
          2.6,
          language,
        );
        final l10n = AppLocalizations.of(
          tester.element(find.byType(SettingPage)),
        );
        final control = find.byWidgetPredicate(
          (w) =>
              w is Semantics &&
              w.properties.label == l10n.label_setting_push_alarm &&
              w.properties.toggled != null,
        );
        expect(control, findsOneWidget);
        expect(tester.getSize(control).shortestSide, greaterThanOrEqualTo(48));
        final node = tester.getSemantics(control);
        expect(node.label, l10n.label_setting_push_alarm);
        expect(node.flagsCollection.isToggled, Tristate.isFalse);
        expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
        tester
            .renderObject(control)
            .owner!
            .semanticsOwner!
            .performAction(node.id, SemanticsAction.tap);
        await frames(tester, 20);
        expect(
          tester.getSemantics(control).flagsCollection.isToggled,
          Tristate.isTrue,
        );
      } finally {
        semantics.dispose();
      }
    });
    for (final size in [const Size(320, 600), const Size(600, 400)]) {
      for (final scale in [1.0, 2.6]) {
        testWidgets(
          'free charge action stays put while loading $language $size $scale',
          (tester) async {
            await showPage(
              tester,
              const LayoutChargeContent(title: 'Video'),
              size,
              scale,
              language,
              overrides: [walletSummaryProvider.overrideWith(LayoutWallet.new)],
            );
            final tile = find.byKey(const ValueKey('free-charge-ad'));
            await tester.scrollUntilVisible(
              tile,
              150,
              scrollable: find.byType(Scrollable).first,
            );
            await frames(tester);
            final action = find.descendant(
              of: tile,
              matching: find.byKey(const Key('purchase-price-cta')),
            );
            await tester.ensureVisible(action);
            await frames(tester);
            final before = tester.getRect(action);
            final tileBefore = tester.getSize(tile);
            ProviderScope.containerOf(
              tester.element(find.byType(FreeChargeContent)),
            ).read(adLoadingStateProvider.notifier).setLoading('ad', true);
            await frames(tester);
            expect(tester.getSize(tile), tileBefore);
            expect(tester.getRect(action), before);
          },
        );
      }
    }
    testWidgets('short landscape QnA keeps title above keyboard $language', (
      tester,
    ) async {
      await showPage(
        tester,
        QnaThreadCreatePage(
          userId: 'test-user-id',
          repository: LayoutQnaRepository(),
        ),
        const Size(600, 400),
        2.6,
        language,
      );
      final input = find.byType(TextFormField).first;
      await tester.enterText(input, 'Question title');
      tester.view.viewInsets = const FakeViewPadding(bottom: 180);
      await frames(tester);
      await tester.ensureVisible(input);
      await frames(tester);
      final rect = tester.getRect(input);
      expect(rect.bottom, lessThanOrEqualTo(220));
      final appBar = find.descendant(
        of: find.byType(QnaThreadCreatePage),
        matching: find.byType(AppBar),
      );
      expect(rect.top, greaterThanOrEqualTo(tester.getRect(appBar).bottom));
    });
    for (final size in [
      const Size(320, 600),
      const Size(600, 400),
      const Size(800, 600),
    ]) {
      testWidgets('withdrawal sheet cancel remains reachable $language $size', (
        tester,
      ) async {
        await showPage(tester, const MyProfilePage(), size, 2.6, language);
        final l10n = AppLocalizations.of(
          tester.element(find.byType(MyProfilePage)),
        );
        final open = find.text(l10n.label_mypage_withdrawal);
        await tester.scrollUntilVisible(
          open,
          160,
          scrollable: find.byType(Scrollable).first,
        );
        await frames(tester);
        await tester.tap(open);
        await frames(tester);
        final cancel = find.text(l10n.dialog_button_cancel);
        await tester.ensureVisible(cancel);
        await frames(tester);
        expect(cancel.hitTestable(), findsOneWidget);
        await tester.tap(cancel);
        await frames(tester);
        expect(find.byType(BottomSheet), findsNothing);
        expect(
          capturedMockRequests.where(
            (uri) => uri.path.contains('/functions/v1/'),
          ),
          isEmpty,
        );
      });
    }
  }
}

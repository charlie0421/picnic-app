import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/app_builder.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';
import 'package:picnic_lib/presentation/pages/my_page/my_page.dart';
import 'package:picnic_lib/presentation/pages/my_page/my_profile.dart';
import 'package:picnic_lib/presentation/providers/my_page/bookmarked_artists_provider.dart';
import 'package:picnic_lib/presentation/pages/my_page/setting_page.dart';
import 'package:picnic_lib/presentation/pages/signup/login_page.dart';
import 'package:picnic_lib/presentation/providers/check_update_provider.dart';
import 'package:picnic_lib/presentation/providers/patch_info_provider.dart';
import 'package:picnic_lib/presentation/providers/platform_info_provider.dart';

import '../../helpers/ignore_image_errors.dart';
import '../../helpers/l10n_layout_matrix.dart';
import '../../helpers/load_test_fonts.dart';
import '../../helpers/mock_data.dart';
import '../../helpers/mock_supabase.dart';
import '../../helpers/test_app.dart';
import '../../helpers/test_environment.dart';

class _PatchedPatchInfo extends PatchInfoNotifier {
  @override
  PatchInfo build() => const PatchInfo(currentPatch: 12);
}

class _NoBookmarkedArtists extends AsyncBookmarkedArtists {
  @override
  Future<List<ArtistModel>> build() async => [];
}

// PICNIC-2738, page-level cases. See fixed_box_l10n_test.dart for why these
// compare what is drawn with its box instead of only counting overflows.
void main() {
  late void Function() restoreImageErrors;

  setUpAll(() async {
    initTestColors();
    await loadTestFonts();
  });

  setUp(() {
    setupMockSupabase({'user_profiles': <dynamic>[]});
    restoreImageErrors = suppressImageErrors();
  });

  tearDown(() {
    restoreImageErrors();
    tearDownMockSupabase();
  });

  Future<List<String>> pumpPage(
    WidgetTester tester,
    Widget page, {
    required L10nCase l10n,
    required double textScale,
    Future<void> Function()? then,
    Size viewport = const Size(393, 852),
    bool asPage = false,
    bool loggedIn = true,
    List<dynamic> extraOverrides = const [],
  }) {
    tester.view.physicalSize = viewport * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    return collectOverflows(() async {
      await tester.pumpWidget(
        asPage
            ? buildTestAppPage(
                page,
                loggedIn: loggedIn,
                extraOverrides: extraOverrides,
                locale: l10n.locale,
                longestStrings: l10n.longest,
                textScaler: TextScaler.linear(textScale),
                designSize: kAppDesignSize,
                splitScreenMode: kAppSplitScreenMode,
              )
            : buildTestApp(
                page,
                loggedIn: loggedIn,
                userProfile: loggedIn ? MockData.userProfile() : null,
                extraOverrides: extraOverrides,
                locale: l10n.locale,
                longestStrings: l10n.longest,
                textScaler: TextScaler.linear(textScale),
                designSize: kAppDesignSize,
                splitScreenMode: kAppSplitScreenMode,
              ),
      );
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 100));
      if (then != null) await then();
    });
  }

  AppLocalizations l10nOf(WidgetTester tester, Type page) =>
      AppLocalizations.of(tester.element(find.byType(page)));

  group('MyProfilePage nickname validation message', () {
    for (final l10n in l10nLayoutCases) {
      for (final textScale in l10nLayoutTextScales) {
        final label = '$l10n ${textScale}x';
        testWidgets(label, (tester) async {
          final overflows = await pumpPage(
            tester,
            const MyProfilePage(),
            l10n: l10n,
            textScale: textScale,
            then: () async {
              await tester.enterText(find.byType(TextFormField).first, '!@#');
              await pumpAndIgnoreErrors(tester);
              await pumpAndIgnoreErrors(
                tester,
                const Duration(milliseconds: 100),
              );
            },
          );
          expect(overflows, isEmpty, reason: label);

          final text = find.text(
            l10nOf(tester, MyProfilePage).nickname_validation_error,
          );
          expectTextInsideBox(
            tester,
            text: text,
            box: find
                .ancestor(of: text, matching: find.byType(Container))
                .first,
            reason: label,
          );
        });
      }
    }
  });

  group('LoginPage sign-in button', () {
    for (final l10n in l10nLayoutCases) {
      for (final textScale in l10nLayoutTextScales) {
        final label = '$l10n ${textScale}x';
        testWidgets(label, (tester) async {
          final overflows = await pumpPage(
            tester,
            const LoginPage(),
            l10n: l10n,
            textScale: textScale,
            asPage: true,
            loggedIn: false,
          );
          expect(overflows, isEmpty, reason: label);

          final text = find.text(l10nOf(tester, LoginPage).button_login);
          expectTextInsideBox(
            tester,
            text: text,
            box: find
                .ancestor(of: text, matching: find.byType(ElevatedButton))
                .first,
            reason: label,
          );
        });
      }
    }
  });

  group('MyPage artist section', () {
    // The empty state is only built for a signed-in Supabase session.
    setUp(() async {
      tearDownMockSupabase();
      await setupMockSupabaseWithAuth({
        'artist_user_bookmark': <dynamic>[],
      }, userId: 'test-user-id');
    });

    for (final l10n in l10nLayoutCases) {
      for (final textScale in l10nLayoutTextScales) {
        final label = '$l10n ${textScale}x';
        testWidgets(label, (tester) async {
          final overflows = await pumpPage(
            tester,
            const MyPage(),
            l10n: l10n,
            textScale: textScale,
            extraOverrides: [
              asyncBookmarkedArtistsProvider.overrideWith(
                _NoBookmarkedArtists.new,
              ),
            ],
          );
          expect(overflows, isEmpty, reason: label);
          final l = l10nOf(tester, MyPage);

          final title = find.text(l.label_mypage_my_artist);
          expectTextInsideBox(
            tester,
            text: title,
            box: find
                .ancestor(of: title, matching: find.byType(SizedBox))
                .first,
            reason: '$label my artists title',
          );

          final empty = find.text(l.label_mypage_no_artist);
          if (empty.evaluate().isNotEmpty) {
            expectTextInsideBox(
              tester,
              text: empty,
              box: find
                  .ancestor(of: empty, matching: find.byType(SizedBox))
                  .first,
              reason: '$label no-artist message',
            );
          } else {
            markTestSkipped(
              '$label: the empty state needs a logged-in session',
            );
          }
        });
      }
    }
  });

  group('SettingPage patch status row', () {
    for (final l10n in l10nLayoutCases) {
      for (final textScale in l10nLayoutTextScales) {
        final label = '$l10n ${textScale}x';
        testWidgets(label, (tester) async {
          final overflows = await pumpPage(
            tester,
            const SettingPage(),
            l10n: l10n,
            textScale: textScale,
            asPage: true,
            extraOverrides: [
              checkUpdateProvider.overrideWith(
                (ref) async => UpdateInfo(
                  status: UpdateStatus.upToDate,
                  currentVersion: '1.3.5',
                  latestVersion: '1.3.5',
                  forceVersion: '1.0.0',
                ),
              ),
              platformInfoProvider.overrideWith(PlatformInfo.new),
              patchInfoProvider.overrideWith(_PatchedPatchInfo.new),
            ],
          );
          expect(overflows, isEmpty, reason: label);

          final l = l10nOf(tester, SettingPage);
          for (final value in [
            l.label_setting_patch_section_title,
            l.label_setting_patch_status_current_patch(12),
          ]) {
            final text = find.text(value);
            await tester.scrollUntilVisible(
              text,
              200,
              scrollable: find.byType(Scrollable).first,
            );
            expectTextInsideBox(
              tester,
              text: text,
              box: find.ancestor(of: text, matching: find.byType(Row)).first,
              reason: '$label "$value"',
            );
          }
        });
      }
    }
  });
}

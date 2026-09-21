import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/constatns/constants.dart';
import 'package:picnic_lib/data/models/policy.dart';
import 'package:picnic_lib/presentation/pages/signup/agreement_privacy_page.dart';
import 'package:picnic_lib/presentation/pages/signup/agreement_terms_page.dart';
import 'package:picnic_lib/presentation/providers/policy_provider.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';
import 'package:picnic_lib/presentation/widgets/error.dart';
import 'package:picnic_lib/presentation/widgets/vote/vote_item_request/common_artist_widget.dart';
import 'package:picnic_lib/presentation/widgets/vote/vote_item_request/search_result_action_button.dart';
import 'package:picnic_lib/presentation/widgets/vote/vote_no_item.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/rendering.dart';
import 'package:picnic_lib/core/utils/app_builder.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';
import 'package:picnic_lib/presentation/pages/my_page/my_page.dart';
import 'package:picnic_lib/presentation/pages/my_page/my_profile.dart';
import 'package:picnic_lib/presentation/providers/my_page/bookmarked_artists_provider.dart';
import 'package:picnic_lib/presentation/pages/my_page/setting_page.dart';
import 'package:picnic_lib/presentation/pages/signup/login_page.dart';
import 'package:picnic_lib/presentation/pages/vote/vote_detail_achieve_page.dart';
import 'package:picnic_lib/presentation/pages/vote/vote_detail_page.dart';
import 'package:picnic_lib/presentation/pages/vote/vote_home_page.dart';
import 'package:visibility_detector/visibility_detector.dart';
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

Map<String, dynamic> _detailVoteRow({
  String category = 'birthday',
  int id = 1,
  String titleKo = '테스트 투표',
  bool isEnded = false,
  bool isUpcoming = false,
}) {
  final now = DateTime.now().toUtc();
  return {
    'id': id,
    'title': {'ko': titleKo, 'en': 'Test Vote'},
    'vote_category': category,
    'main_image': null,
    'wait_image': null,
    'result_image': null,
    'vote_content': null,
    'vote_item': [
      {
        'id': 1,
        'vote_id': id,
        'vote_total': 5000,
        'artist': {
          'id': 10,
          'name': {'ko': '지민', 'en': 'Jimin'},
          'image': null,
          'artist_group': {
            'id': 1,
            'name': {'ko': 'BTS', 'en': 'BTS'},
            'image': null,
          },
        },
        'artist_group': null,
      },
      {
        'id': 2,
        'vote_id': id,
        'vote_total': 3000,
        'artist': {
          'id': 11,
          'name': {'ko': '정국', 'en': 'Jungkook'},
          'image': null,
          'artist_group': {
            'id': 1,
            'name': {'ko': 'BTS', 'en': 'BTS'},
            'image': null,
          },
        },
        'artist_group': null,
      },
    ],
    'created_at': now.toIso8601String(),
    'visible_at': now.subtract(const Duration(days: 2)).toIso8601String(),
    'start_at': now.subtract(const Duration(days: 1)).toIso8601String(),
    'stop_at': now.add(const Duration(days: 7)).toIso8601String(),
    'is_ended': isEnded,
    'is_upcoming': isUpcoming,
    'is_partnership': false,
    'partner': null,
    'reward': null,
  };
}

Map<String, dynamic> _detailVoteItemRow({
  int id = 1,
  int voteId = 1,
  int voteTotal = 5000,
  String artistNameKo = '지민',
  int artistId = 10,
}) {
  return {
    'id': id,
    'vote_id': voteId,
    'vote_total': voteTotal,
    'artist': {
      'id': artistId,
      'name': {'ko': artistNameKo, 'en': artistNameKo},
      'image': null,
      'artist_group': {
        'id': 1,
        'name': {'ko': 'BTS', 'en': 'BTS'},
        'image': null,
      },
    },
    'artist_group': null,
  };
}

Map<String, dynamic> _achieveVoteRow({int id = 1}) {
  final now = DateTime.now().toUtc();
  return {
    'id': id,
    'title': {'ko': '달성 투표', 'en': 'Achievement Vote'},
    'vote_category': 'achieve',
    'main_image': null,
    'wait_image': null,
    'result_image': null,
    'vote_content': null,
    'vote_item': null,
    'created_at': now.toIso8601String(),
    'visible_at': now.subtract(const Duration(days: 2)).toIso8601String(),
    'start_at': now.subtract(const Duration(days: 1)).toIso8601String(),
    'stop_at': now.add(const Duration(days: 7)).toIso8601String(),
    'is_ended': false,
    'is_upcoming': false,
    'is_partnership': false,
    'partner': null,
    'reward': null,
  };
}

Map<String, dynamic> _achieveVoteItemRow({
  int id = 1,
  int voteId = 1,
  int voteTotal = 5000,
  String artistNameKo = '지민',
  int artistId = 10,
}) {
  return {
    'id': id,
    'vote_id': voteId,
    'vote_total': voteTotal,
    'artist': {
      'id': artistId,
      'name': {'ko': artistNameKo, 'en': artistNameKo},
      'image': null,
      'artist_group': {
        'id': 1,
        'name': {'ko': 'BTS', 'en': 'BTS'},
        'image': null,
      },
    },
    'artist_group': null,
  };
}

/// [nullTitle] 은 운영자가 보상 제목을 비워둔 행을 재현한다.
/// `RewardModel.title` 은 `thumbnail` 과 같은 순수 nullable 컬럼이다.
Map<String, dynamic> _achieveVoteAchieveRow({
  int id = 1,
  int voteId = 1,
  int rewardId = 1,
  int order = 1,
  int amount = 10000,
  bool nullTitle = false,
}) {
  return {
    'id': id,
    'vote_id': voteId,
    'reward_id': rewardId,
    'order': order,
    'amount': amount,
    'reward': {
      'id': rewardId,
      'title': nullTitle ? null : {'ko': '포토카드'},
      'thumbnail': null,
    },
    'vote': _achieveVoteRow(id: voteId),
  };
}

/// 393 is a current iPhone; 360 is the most common Android width, and where a
/// review found this suite's "false positives" were not false.
final _pageCases = <(double, Size)>[
  for (final textScale in l10nLayoutTextScales)
    // 320 is the narrowest screen still in use (iPhone SE 1st gen, small
    // Androids); PICNIC-2746 found the achieve ladder 32px too wide there.
    for (final viewport in const [
      Size(393, 852),
      Size(360, 800),
      Size(320, 640),
    ])
      (textScale, viewport),
];

class _PatchedPatchInfo extends PatchInfoNotifier {
  @override
  PatchInfo build() => const PatchInfo(currentPatch: 12);
}

class _NoBookmarkedArtists extends AsyncBookmarkedArtists {
  @override
  Future<List<ArtistModel>> build() async => [];
}

class _FixedPolicy extends AsyncPolicy {
  @override
  Future<PolicyModel> build() async => const PolicyModel(
    privacyEn: PrivacyModel(content: 'privacy', version: '1'),
    termsEn: TermsModel(content: 'terms', version: '1'),
    privacyKo: PrivacyModel(content: 'privacy', version: '1'),
    termsKo: TermsModel(content: 'terms', version: '1'),
  );
}

/// The union of the rects the text's glyphs are actually painted in. A
/// centred paragraph's box spans its whole slot; its glyphs may not.
Rect _glyphRect(WidgetTester tester, Finder text) {
  final paragraph = tester.renderObject<RenderParagraph>(
    find.descendant(of: text, matching: find.byType(RichText)).first,
  );
  final length = paragraph.text.toPlainText().length;
  final boxes = paragraph.getBoxesForSelection(
    TextSelection(baseOffset: 0, extentOffset: length),
  );
  final origin = paragraph.localToGlobal(Offset.zero);
  return boxes
      .map((b) => b.toRect().shift(origin))
      .reduce((a, b) => a.expandToInclude(b));
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
      for (final (textScale, viewport) in _pageCases) {
        final label = '$l10n ${textScale}x ${viewport.width.toInt()}w';
        testWidgets(label, (tester) async {
          final overflows = await pumpPage(
            tester,
            const MyProfilePage(),
            l10n: l10n,
            textScale: textScale,
            viewport: viewport,
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
      for (final (textScale, viewport) in _pageCases) {
        final label = '$l10n ${textScale}x ${viewport.width.toInt()}w';
        testWidgets(label, (tester) async {
          final overflows = await pumpPage(
            tester,
            const LoginPage(),
            l10n: l10n,
            textScale: textScale,
            viewport: viewport,
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
          // The 48 became a minimum (PICNIC-2746); at 1.0x it must still be
          // exactly the old 48.
          if (textScale == 1.0) {
            expect(
              tester
                  .getSize(
                    find
                        .ancestor(
                          of: text,
                          matching: find.byType(ElevatedButton),
                        )
                        .first,
                  )
                  .height,
              48,
              reason: label,
            );
          }
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
      for (final (textScale, viewport) in _pageCases) {
        final label = '$l10n ${textScale}x ${viewport.width.toInt()}w';
        testWidgets(label, (tester) async {
          final overflows = await pumpPage(
            tester,
            const MyPage(),
            l10n: l10n,
            textScale: textScale,
            viewport: viewport,
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
            box: find.ancestor(of: title, matching: find.byType(Row)).first,
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
      for (final (textScale, viewport) in _pageCases) {
        final label = '$l10n ${textScale}x ${viewport.width.toInt()}w';
        testWidgets(label, (tester) async {
          final overflows = await pumpPage(
            tester,
            const SettingPage(),
            l10n: l10n,
            textScale: textScale,
            viewport: viewport,
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
          // The value is right-aligned to the row, as it was before the fix
          // made it able to wrap. A review caught it drifting 98px left.
          final value = find.text(
            l.label_setting_patch_status_current_patch(12),
          );
          final row = find
              .ancestor(of: value, matching: find.byType(Row))
              .first;
          expect(
            tester.getRect(value).right,
            closeTo(tester.getRect(row).right, 0.5),
            reason: '$label: the patch value must sit at the row\'s right edge',
          );
        });
      }
    }
  });

  group('VoteHomePage section title', () {
    setUp(() {
      tearDownMockSupabase();
      setupMockSupabase({
        'vote': <dynamic>[],
        'pic_vote': <dynamic>[],
        'banner': <dynamic>[],
        'reward': <dynamic>[],
      });
    });

    for (final l10n in l10nLayoutCases) {
      for (final (textScale, viewport) in _pageCases) {
        final label = '$l10n ${textScale}x ${viewport.width.toInt()}w';
        testWidgets(label, (tester) async {
          final overflows = await pumpPage(
            tester,
            const VoteHomePage(),
            l10n: l10n,
            textScale: textScale,
            viewport: viewport,
            asPage: true,
          );
          expect(overflows, isEmpty, reason: label);

          final text = find.text(
            l10nOf(tester, VoteHomePage).label_vote_screen_title,
          );
          expectTextInsideBox(
            tester,
            text: text,
            box: find.ancestor(of: text, matching: find.byType(Row)).first,
            reason: label,
          );
        });
      }
    }
  });

  group('VoteDetailPage call-to-action', () {
    for (final category in const ['birthday', 'weekly']) {
      for (final l10n in l10nLayoutCases) {
        for (final (textScale, viewport) in _pageCases) {
          final label =
              '$category $l10n ${textScale}x ${viewport.width.toInt()}w';
          testWidgets(label, (tester) async {
            VisibilityDetectorController.instance.updateInterval =
                Duration.zero;
            tearDownMockSupabase();
            setupMockSupabase({
              'vote': [_detailVoteRow(category: category)],
              'vote_item': [
                _detailVoteItemRow(id: 1, artistId: 10),
                _detailVoteItemRow(id: 2, artistId: 11, voteTotal: 3000),
              ],
            });
            final overflows = await pumpPage(
              tester,
              const VoteDetailPage(voteId: 1),
              l10n: l10n,
              textScale: textScale,
              viewport: viewport,
              asPage: true,
              then: () async {
                // The button fades and bounces in over 1.5s.
                await pumpAndIgnoreErrors(tester, const Duration(seconds: 2));
                drainExpectedImageErrors(tester);
              },
            );
            expect(overflows, isEmpty, reason: label);

            final l = l10nOf(tester, VoteDetailPage);
            final text = find.text(
              category == 'weekly'
                  ? l.weekly_vote_info_link
                  : l.vote_item_request_button,
            );
            await tester.scrollUntilVisible(
              text,
              200,
              scrollable: find.byType(Scrollable).first,
            );
            if (category != 'weekly' && textScale == 1.0) {
              // The pill is 30 tall by design. A review caught an inner
              // minimum plus the 1px border turning it into 32 and pushing the
              // whole page down 2px.
              final pill = find
                  .ancestor(of: text, matching: find.byType(AnimatedContainer))
                  .first;
              expect(
                tester.getSize(pill).height,
                closeTo(30, 0.01),
                reason: '$label: the request button must stay 30 tall',
              );
            }
            expectTextInsideBox(
              tester,
              text: text,
              box: category == 'weekly'
                  ? find.ancestor(of: text, matching: find.byType(Row)).first
                  : find
                        .ancestor(of: text, matching: find.byType(Container))
                        .first,
              reason: label,
            );
          });
        }
      }
    }
  });

  group('VoteDetailAchievePage reward rung', () {
    for (final l10n in l10nLayoutCases) {
      for (final (textScale, viewport) in _pageCases) {
        final label = '$l10n ${textScale}x ${viewport.width.toInt()}w';
        testWidgets(label, (tester) async {
          VisibilityDetectorController.instance.updateInterval = Duration.zero;
          tearDownMockSupabase();
          setupMockSupabase({
            'vote': [_achieveVoteRow()],
            'vote_item': [
              _achieveVoteItemRow(id: 1, voteTotal: 5000),
              _achieveVoteItemRow(
                id: 2,
                voteTotal: 3000,
                artistId: 11,
                artistNameKo: '정국',
              ),
            ],
            'vote_achieve': [
              _achieveVoteAchieveRow(id: 1, order: 1, amount: 10000),
              _achieveVoteAchieveRow(
                id: 2,
                order: 2,
                rewardId: 2,
                amount: 50000,
              ),
            ],
          });
          final overflows = await pumpPage(
            tester,
            const VoteDetailAchievePage(voteId: 1),
            l10n: l10n,
            textScale: textScale,
            viewport: viewport,
            asPage: true,
            then: () async {
              for (var i = 0; i < 4; i++) {
                await tester.pump(const Duration(milliseconds: 100));
                drainExpectedImageErrors(tester);
              }
            },
          );
          expect(overflows, isEmpty, reason: label);

          final l = l10nOf(tester, VoteDetailAchievePage);
          final text = find.text('${l.reward}1');
          await tester.scrollUntilVisible(
            text,
            200,
            scrollable: find.byType(Scrollable).first,
          );
          final rung = find
              .ancestor(of: text, matching: find.byType(Row))
              .first;
          expectTextInsideBox(tester, text: text, box: rung, reason: label);
          // The progress bar beside the ladder is drawn as 50px per level; a
          // rung of any other height slides the levels out of line with it.
          expect(
            tester.getSize(rung).height,
            closeTo(50, 0.01),
            reason: '$label: a reward rung must stay 50 tall',
          );
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump(const Duration(seconds: 30));
        });
      }
    }
  });

  // ---- MEDIUM measurement (fixed-box audit) --------------------------------

  group('MEDIUM VoteHomePage reward name', () {
    setUp(() {
      tearDownMockSupabase();
      const name = {'ko': '스페셜 포토카드 세트', 'en': '스페셜 포토카드 세트'};
      setupMockSupabase({
        'vote': <dynamic>[],
        'pic_vote': <dynamic>[],
        'banner': <dynamic>[],
        'reward': [
          {'id': 1, 'title': name, 'thumbnail': null},
          {'id': 2, 'title': name, 'thumbnail': null},
        ],
      });
    });

    for (final l10n in l10nLayoutCases) {
      for (final (textScale, viewport) in _pageCases) {
        final label = '$l10n ${textScale}x ${viewport.width.toInt()}w';
        testWidgets(label, (tester) async {
          final overflows = await pumpPage(
            tester,
            const VoteHomePage(),
            l10n: l10n,
            textScale: textScale,
            viewport: viewport,
            asPage: true,
          );
          expect(overflows, isEmpty, reason: label);
          final text = find.text('스페셜 포토카드 세트').first;
          await tester.ensureVisible(text);
          await tester.pump();
          expectTextInsideBox(
            tester,
            text: text,
            box: find
                .ancestor(of: text, matching: find.byType(Container))
                .first,
            allowEllipsis: true,
            reason: label,
          );
        });
      }
    }
  });

  group('MEDIUM MyProfilePage nickname hint', () {
    for (final l10n in l10nLayoutCases) {
      for (final (textScale, viewport) in _pageCases) {
        final label = '$l10n ${textScale}x ${viewport.width.toInt()}w';
        testWidgets(label, (tester) async {
          final overflows = await pumpPage(
            tester,
            const MyProfilePage(),
            l10n: l10n,
            textScale: textScale,
            viewport: viewport,
            then: () async {
              await tester.enterText(find.byType(TextFormField).first, '');
              await pumpAndIgnoreErrors(tester);
            },
          );
          expect(overflows, isEmpty, reason: label);
          final text = find.text(
            l10nOf(tester, MyProfilePage).hint_nickname_input,
          );
          expectTextInsideBox(
            tester,
            text: text,
            box: find
                .ancestor(
                  of: find.byType(Form),
                  matching: find.byType(Container),
                )
                .first,
            reason: label,
          );
        });
      }
    }
  });

  group('MEDIUM VoteNoItem message', () {
    for (final status in [
      VoteStatus.active,
      VoteStatus.end,
      VoteStatus.upcoming,
    ]) {
      for (final l10n in l10nLayoutCases) {
        for (final (textScale, viewport) in _pageCases) {
          final label =
              '${status.name} $l10n ${textScale}x ${viewport.width.toInt()}w';
          testWidgets(label, (tester) async {
            final overflows = await pumpPage(
              tester,
              Builder(
                builder: (c) => VoteNoItem(status: status, context: c),
              ),
              l10n: l10n,
              textScale: textScale,
              viewport: viewport,
            );
            expect(overflows, isEmpty, reason: label);
            final text = find.descendant(
              of: find.byType(VoteNoItem),
              matching: find.byType(Text),
            );
            expectTextInsideBox(
              tester,
              text: text,
              box: find.byType(VoteNoItem),
              reason: label,
            );
          });
        }
      }
    }
  });

  group('MEDIUM error view retry button', () {
    for (final l10n in l10nLayoutCases) {
      for (final (textScale, viewport) in _pageCases) {
        final label = '$l10n ${textScale}x ${viewport.width.toInt()}w';
        testWidgets(label, (tester) async {
          final overflows = await pumpPage(
            tester,
            Builder(
              builder: (c) => buildErrorView(
                c,
                retryFunction: () {},
                error: 'e',
                stackTrace: null,
              ),
            ),
            l10n: l10n,
            textScale: textScale,
            viewport: viewport,
          );
          expect(overflows, isEmpty, reason: label);
          final l = AppLocalizations.of(
            tester.element(find.byType(ElevatedButton)),
          );
          final text = find.text(l.label_retry);
          expectTextInsideBox(
            tester,
            text: text,
            box: find.byType(ElevatedButton),
            reason: label,
          );
          // Wrapping to two or more lines inside the 200-wide button is
          // accepted (the button grows with it); only clipping is a defect.
        });
      }
    }
  });

  for (final (name, page, titleOf)
      in <(String, Widget, String Function(AppLocalizations))>[
        ('terms', const AgreementTermsPage(), (l) => l.label_agreement_terms),
        (
          'privacy',
          const AgreementPrivacyPage(),
          (l) => l.label_agreement_privacy,
        ),
      ]) {
    group('MEDIUM agreement $name page', () {
      for (final l10n in l10nLayoutCases) {
        for (final (textScale, viewport) in _pageCases) {
          final label = '$l10n ${textScale}x ${viewport.width.toInt()}w';
          testWidgets('$label header', (tester) async {
            final overflows = await pumpPage(
              tester,
              page,
              l10n: l10n,
              textScale: textScale,
              viewport: viewport,
              asPage: true,
              extraOverrides: [
                asyncPolicyProvider.overrideWith(_FixedPolicy.new),
              ],
            );
            expect(overflows, isEmpty, reason: label);
            final l = AppLocalizations.of(
              tester.element(find.byType(Stack).first),
            );
            final text = find.text(titleOf(l));
            expectTextInsideBox(
              tester,
              text: text,
              box: find.ancestor(of: text, matching: find.byType(Stack)).first,
              reason: label,
            );
            // The back button sits at left 8, 42 wide, over the centred title.
            final back = find
                .descendant(
                  of: find
                      .ancestor(of: text, matching: find.byType(Stack))
                      .first,
                  matching: find.byType(InkWell),
                )
                .first;
            expect(
              _glyphRect(tester, text).overlaps(tester.getRect(back)),
              isFalse,
              reason: '$label: the title is painted under the back button',
            );
          });
          testWidgets('$label button', (tester) async {
            final overflows = await pumpPage(
              tester,
              page,
              l10n: l10n,
              textScale: textScale,
              viewport: viewport,
              asPage: true,
              extraOverrides: [
                asyncPolicyProvider.overrideWith(_FixedPolicy.new),
              ],
            );
            expect(overflows, isEmpty, reason: label);
            final l = AppLocalizations.of(
              tester.element(find.byType(Stack).first),
            );
            final text = find.text(l.label_button_agreement);
            expectTextInsideBox(
              tester,
              text: text,
              box: find
                  .ancestor(
                    of: text,
                    matching: find.byWidgetPredicate(
                      (w) =>
                          w is SizedBox && w.height != null && w.height! >= 48,
                    ),
                  )
                  .first,
              reason: label,
            );
          });
        }
      }
    });
  }

  group('MEDIUM vote item request action button', () {
    // (label, showButton, status key)
    final states = <(String, bool, String Function(AppLocalizations))>[
      ('submit', true, (l) => l.vote_item_request_can_apply),
      ('pending', false, (l) => l.vote_item_request_status_pending),
      ('waiting', false, (l) => l.vote_item_request_waiting),
      ('approved', false, (l) => l.vote_item_request_status_approved),
      ('rejected', false, (l) => l.vote_item_request_status_rejected),
      ('in_progress', false, (l) => l.vote_item_request_status_in_progress),
      ('cancelled', false, (l) => l.vote_item_request_status_cancelled),
      ('unknown', false, (l) => l.vote_item_request_status_unknown),
    ];
    for (final (state, showButton, statusOf) in states) {
      for (final l10n in l10nLayoutCases) {
        for (final (textScale, viewport) in _pageCases) {
          final label = '$state $l10n ${textScale}x ${viewport.width.toInt()}w';
          testWidgets(label, (tester) async {
            final overflows = await pumpPage(
              tester,
              Builder(
                builder: (c) {
                  final l = AppLocalizations.of(c);
                  // Same insets as the real dialog: Dialog insetPadding 12.w,
                  // list padding 16.r, card padding 6.r and a 1px border.
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12.w),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.r),
                      child: Container(
                        padding: EdgeInsets.all(6.r),
                        decoration: BoxDecoration(border: Border.all()),
                        child: CommonArtistWidget(
                          artist: null,
                          artistName: 'Jungkook',
                          groupName: 'BTS',
                          width: 32.w,
                          height: 32.w,
                          trailing: SearchResultActionButton(
                            shouldShowApplicationButton: showButton,
                            isSubmitting: false,
                            isAlreadyInVote: false,
                            status: statusOf(l),
                            onPressed: () {},
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              l10n: l10n,
              textScale: textScale,
              viewport: viewport,
            );
            expect(overflows, isEmpty, reason: label);
            final l = AppLocalizations.of(
              tester.element(find.byType(SearchResultActionButton)),
            );
            final text = find.descendant(
              of: find.byType(SearchResultActionButton),
              matching: find.text(
                showButton ? l.vote_item_request_submit : statusOf(l),
              ),
            );
            expectTextInsideBox(
              tester,
              text: text,
              box: find.byType(SearchResultActionButton),
              reason: label,
            );
          });
        }
      }
    }
  });

  group('MEDIUM MyPage language grid (wide screens)', () {
    setUp(() async {
      tearDownMockSupabase();
      await setupMockSupabaseWithAuth({
        'artist_user_bookmark': <dynamic>[],
      }, userId: 'test-user-id');
    });
    for (final textScale in l10nLayoutTextScales) {
      for (final viewport in const [
        Size(500, 900),
        Size(600, 960),
        Size(800, 1280),
      ]) {
        final label = '${textScale}x ${viewport.width.toInt()}w';
        testWidgets(label, (tester) async {
          final overflows = await pumpPage(
            tester,
            const MyPage(),
            l10n: l10nLayoutCases.first,
            textScale: textScale,
            viewport: viewport,
            extraOverrides: [
              asyncBookmarkedArtistsProvider.overrideWith(
                _NoBookmarkedArtists.new,
              ),
            ],
            then: () async {
              final selector = find.byWidgetPredicate(
                (w) => w is Text && languageMap.values.contains(w.data),
              );
              await tester.ensureVisible(selector.first);
              await tester.tap(selector.first);
              await pumpAndIgnoreErrors(tester);
              await pumpAndIgnoreErrors(tester, const Duration(seconds: 1));
            },
          );
          expect(overflows, isEmpty, reason: label);
          expect(find.byType(BottomSheet), findsOneWidget, reason: label);
          var checked = 0;
          for (final name in languageMap.values) {
            final text = find.descendant(
              of: find.byType(BottomSheet),
              matching: find.text(name),
            );
            if (text.evaluate().isEmpty) continue;
            expectTextInsideBox(
              tester,
              text: text,
              box: find
                  .ancestor(of: text, matching: find.byType(GestureDetector))
                  .first,
              reason: '$label $name',
            );
            checked++;
          }
          expect(
            checked,
            languageMap.length,
            reason: '$label: every language option must be measured',
          );
        });
      }
    }
  });
}

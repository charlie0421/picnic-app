import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/app_builder.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/data/models/reward.dart';
import 'package:picnic_lib/presentation/dialogs/reward_dialog.dart';
import 'package:picnic_lib/presentation/widgets/vote/list/countdown_timer.dart';
import 'package:picnic_lib/presentation/widgets/vote/list/vote_detail_title.dart';
import 'package:picnic_lib/presentation/widgets/vote/list/vote_info_card_achieve.dart';

import '../../helpers/ignore_image_errors.dart';
import '../../helpers/l10n_layout_matrix.dart';
import '../../helpers/load_test_fonts.dart';
import '../../helpers/test_app.dart';
import '../../helpers/test_environment.dart';

// PICNIC-2738.
//
// Every case here is a localized string inside a box whose size is pinned.
// That is the one shape behind the overflow defects of PICNIC-2694, 2697,
// 2699, 2700 and 2727; text that is free to grow does not overflow. The list
// comes from an audit of the operated screens
// (docs/operations/fixed-box-l10n-audit.html).
//
// A fixed-HEIGHT box is the dangerous kind: text that outgrows it throws
// nothing and is clipped in silence, so these tests compare what is drawn with
// the box it lives in instead of only counting overflow errors.
Map<String, dynamic> _voteRow({int id = 1}) {
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

VoteItemModel _voteItem({int voteTotal = 50000}) {
  return VoteItemModel.fromJson({
    'id': 1,
    'vote_id': 1,
    'vote_total': voteTotal,
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
  });
}

/// [nullThumbnail] 은 운영자가 보상 이미지를 비워둔 행을 재현한다.
/// `RewardModel.thumbnail` 은 순수 nullable DB 컬럼이다.
VoteAchieve _voteAchieve({int amount = 10000, bool nullThumbnail = false}) {
  return VoteAchieve.fromJson({
    'id': 1,
    'vote_id': 1,
    'reward_id': 1,
    'order': 1,
    'amount': amount,
    'reward': {
      'id': 1,
      'title': {'ko': '포토카드'},
      'thumbnail': nullThumbnail ? null : 'https://example.com/thumb.jpg',
    },
    'vote': _voteRow(),
  });
}

void main() {
  setUpAll(() async {
    initTestColors();
    await loadTestFonts();
  });

  Future<List<String>> pumpCase(
    WidgetTester tester,
    Widget child, {
    required L10nCase l10n,
    required double textScale,
    Size viewport = const Size(393, 852),
  }) {
    tester.view.physicalSize = viewport * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    return collectOverflows(() async {
      await tester.pumpWidget(
        buildTestApp(
          Align(alignment: Alignment.topCenter, child: child),
          locale: l10n.locale,
          longestStrings: l10n.longest,
          textScaler: TextScaler.linear(textScale),
          designSize: kAppDesignSize,
          splitScreenMode: kAppSplitScreenMode,
        ),
      );
      await tester.pump();
    });
  }

  group('CountdownTimer "upcoming" label', () {
    for (final l10n in l10nLayoutCases) {
      for (final textScale in l10nLayoutTextScales) {
        final label = '$l10n ${textScale}x';
        testWidgets(label, (tester) async {
          final overflows = await pumpCase(
            tester,
            CountdownTimer(
              endTime: DateTime.now().toUtc().add(const Duration(days: 3)),
              status: VoteStatus.upcoming,
            ),
            l10n: l10n,
            textScale: textScale,
          );
          expect(overflows, isEmpty, reason: label);

          final text = find.text(
            AppLocalizations.of(
              tester.element(find.byType(CountdownTimer)),
            ).label_vote_upcoming,
          );
          expectTextInsideBox(
            tester,
            text: text,
            box: find
                .ancestor(of: text, matching: find.byType(Container))
                .first,
            reason: label,
          );
          await tester.pumpWidget(const SizedBox.shrink());
        });
      }
    }
  });

  // The digit tiles are pinned at 18x18 and each digit paints inside its own
  // paragraph, which clips itself to the height it is given. From 1.2x the
  // digit's line is taller than 18; from about 1.5x the glyphs visibly lose
  // their bottom, and at 2.0x almost half of each digit is gone. Digits are not
  // translated, so the l10n audit missed them; the preview screenshots found
  // them. Scales go past 2.0 on purpose: the app does not clamp text scaling.
  group('CountdownTimer digit tiles', () {
    for (final textScale in const [1.0, 1.3, 1.5, 2.0, 2.6]) {
      final label = 'digits ${textScale}x';
      testWidgets(label, (tester) async {
        final overflows = await pumpCase(
          tester,
          CountdownTimer(
            endTime: DateTime.now().toUtc().add(
              const Duration(days: 12, hours: 3),
            ),
            status: VoteStatus.active,
          ),
          l10n: l10nLayoutCases.first,
          textScale: textScale,
        );
        expect(overflows, isEmpty, reason: label);

        for (var i = 0; i < 8; i++) {
          final tile = find.byKey(CountdownTimer.digitKey(i));
          expect(
            tester.getSize(tile).width,
            // The keyed box includes the tile's 1px side margins.
            closeTo(
              CountdownTimer.digitSize + CountdownTimer.digitGap * 2,
              0.01,
            ),
            reason:
                '$label tile $i: the width is the row\'s budget on a 320dp '
                'card and must not grow',
          );
          expectTextInsideBox(
            tester,
            text: find.descendant(of: tile, matching: find.byType(Text)),
            box: tile,
            reason: '$label tile $i',
          );
        }
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  });

  // Achievement-vote bars are 50px wide and stand five abreast in a 321px row,
  // so each has about 64px. "Achievements!" was 104px at 1.0x in English and
  // ran over its neighbours; the reward label under it wrapped upward past the
  // top of its bar at 2.0x, white text on a white card.
  group('VoteCardColumnAchieve labels', () {
    for (final l10n in l10nLayoutCases) {
      for (final textScale in l10nLayoutTextScales) {
        final label = '$l10n ${textScale}x';
        testWidgets(label, (tester) async {
          final restore = suppressImageErrors();
          addTearDown(restore);
          final overflows = await pumpCase(
            tester,
            Padding(
              padding: const EdgeInsets.only(top: 120),
              child: VoteCardColumnAchieve(
                voteItem: _voteItem(),
                rank: _voteAchieve(),
                opacityAnimation: const AlwaysStoppedAnimation<double>(1),
              ),
            ),
            l10n: l10n,
            textScale: textScale,
          );
          drainExpectedImageErrors(tester);
          expect(overflows, isEmpty, reason: label);
          final l = AppLocalizations.of(
            tester.element(find.byType(VoteCardColumnAchieve)),
          );

          expectTextInsideBox(
            tester,
            text: find.text('${l.achieve}!'),
            box: find.byKey(VoteCardColumnAchieve.achievedLabelKey),
            reason: '$label achieved label',
          );
          final reward = find.text('${l.reward} 1');
          expectTextInsideBox(
            tester,
            text: reward,
            box: find.byKey(VoteCardColumnAchieve.barKey),
            reason: '$label reward label',
          );
        });
      }
    }
  });

  // The reward name comes from the server, not the arb files, so the language
  // axis does not lengthen it. Real reward names are sentences ("2026 시즌
  // 한정 포토카드 세트 + 친필 사인 폴라로이드"); VoteCommonTitle grows for them,
  // but the dialog pinned it inside a fixed 48px box.
  group('RewardDialog title', () {
    const names = <String, String>{
      'short': '포토카드',
      'long': '2026 시즌 한정 포토카드 세트 + 친필 사인 폴라로이드',
    };
    for (final name in names.entries) {
      for (final textScale in l10nLayoutTextScales) {
        final label = '${name.key} ${textScale}x';
        testWidgets(label, (tester) async {
          final restore = suppressImageErrors();
          addTearDown(restore);
          final overflows = await pumpCase(
            tester,
            RewardDialog(
              data: RewardModel(
                id: 1,
                title: {'ko': name.value, 'en': name.value},
                thumbnail: 'https://example.com/reward.jpg',
              ),
            ),
            l10n: l10nLayoutCases.first,
            textScale: textScale,
          );
          await tester.pump(const Duration(seconds: 1));
          drainExpectedImageErrors(tester);
          expect(overflows, isEmpty, reason: label);

          final title = find.byType(VoteCommonTitle);
          final text = find
              .descendant(of: title, matching: find.text(name.value))
              .last;
          expectTextInsideBox(tester, text: text, box: title, reason: label);
        });
      }
    }
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/pages/vote/vote_detail_page.dart';
import 'package:picnic_lib/presentation/pages/vote/vote_item_widget.dart';
import 'package:picnic_lib/presentation/widgets/ui/large_popup.dart';
import 'package:picnic_lib/presentation/widgets/vote/voting/voting_dialog.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../helpers/ignore_image_errors.dart';
import '../../../helpers/mock_supabase.dart';
import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

/// ## `VoteDetailPage._handleVoteItemTap` 회귀
///
/// 후보자 행 탭 → 탈퇴 차단 확인(`user_profiles` 조회) → 투표 다이얼로그.
/// 조회가 느린 동안 행은 계속 탭 가능하므로, 그 창에서 들어온 추가 탭이
/// 다이얼로그를 쌓지 않아야 한다 (PICNIC-2655). 실제 Supabase 없이 다이얼로그가
/// 뜨는 지점까지만 본다 — 투표 제출은 다루지 않는다.

Map<String, dynamic> _voteItemRow({int id = 1, int voteTotal = 5000}) => {
  'id': id,
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
};

Map<String, dynamic> _voteRow() {
  final now = DateTime.now().toUtc();
  return {
    'id': 1,
    'title': {'ko': '테스트 투표', 'en': 'Test Vote'},
    'vote_category': 'birthday',
    'main_image': null,
    'wait_image': null,
    'result_image': null,
    'vote_content': null,
    'vote_item': [_voteItemRow()],
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

/// `deleted_at` 이 널이어야 탈퇴 차단 게이트를 지나 투표 다이얼로그까지 간다.
Map<String, dynamic> _userProfileRow(String userId) => {
  'id': userId,
  'nickname': 'tester',
  'avatar_url': null,
  'deleted_at': null,
  'user_agreement': null,
  'is_admin': false,
  'star_candy': 1000,
  'star_candy_bonus': 0,
  'jma_candy': 0,
  'birth_date': null,
  'gender': null,
  'birth_time': null,
};

void main() {
  setUp(() {
    initTestColors();
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
  });

  tearDown(tearDownMockSupabase);

  Future<void> pumpPage(WidgetTester tester) async {
    // 투표 다이얼로그(LargePopupWidget)가 기본 테스트 서피스에서는 세로로
    // 넘친다. 프로덕션 기하(393x892)로 띄운다.
    tester.view.devicePixelRatio = 3.0;
    tester.view.physicalSize = const Size(393, 892) * 3.0;
    addTearDown(tester.view.reset);
    await setupMockSupabaseWithAuth({
      'vote': [_voteRow()],
      'vote_item': [_voteItemRow()],
      'user_profiles': [_userProfileRow('test-user-1')],
    }, userId: 'test-user-1');
    await pumpWidgetAndIgnoreErrors(
      tester,
      buildTestAppPage(const VoteDetailPage(voteId: 1), loggedIn: true),
    );
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 250));
      drainExpectedImageErrors(tester);
    }
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 30));
  }

  group('VoteDetailPage vote item tap', () {
    testWidgets('single tap opens the voting dialog', (tester) async {
      await pumpPage(tester);

      final row = find.byType(VoteItemWidget);
      expect(row, findsOneWidget, reason: '후보자 행이 그려져 있어야 탭할 수 있다');
      await tester.tap(row, warnIfMissed: false);
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 150));
        drainExpectedImageErrors(tester);
      }

      expect(find.byType(VotingDialog), findsOneWidget);
      await settle(tester);
    });

    testWidgets('closing with the top-right X allows one clean reopen', (
      tester,
    ) async {
      // PICNIC-2695 gave the dialog a close button, so the page's re-entrancy
      // guard now has a path it never had: open, leave, open again. The guard
      // is a `try/finally` around the tap handler — if leaving through the X
      // left it set, the row would be dead on the second tap.
      await pumpPage(tester);

      final row = find.byType(VoteItemWidget);
      await tester.tap(row, warnIfMissed: false);
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 150));
        drainExpectedImageErrors(tester);
      }
      expect(find.byType(VotingDialog), findsOneWidget);

      await tester.tap(find.byKey(kLargePopupTopCloseKey));
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 150));
        drainExpectedImageErrors(tester);
      }
      expect(find.byType(VotingDialog), findsNothing);

      await tester.tap(row, warnIfMissed: false);
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 150));
        drainExpectedImageErrors(tester);
      }
      expect(
        find.byType(VotingDialog),
        findsOneWidget,
        reason: 'leaving through the X must not strand the re-entrancy guard',
      );

      await settle(tester);
    });

    testWidgets(
      'rapid repeated taps while the profile fetch is slow open exactly one voting dialog',
      (tester) async {
        await pumpPage(tester);

        // 페이지 로딩이 끝난 뒤에만 지연을 건다.
        tableResponseDelays['user_profiles'] = const Duration(seconds: 2);

        final row = find.byType(VoteItemWidget);
        expect(row, findsOneWidget);
        for (var i = 0; i < 3; i++) {
          await tester.tap(row, warnIfMissed: false);
          await tester.pump();
        }
        expect(
          find.byType(VotingDialog),
          findsNothing,
          reason: '응답 전에는 어떤 다이얼로그도 뜨지 않아야 한다',
        );

        for (var i = 0; i < 4; i++) {
          await tester.pump(const Duration(seconds: 1));
          drainExpectedImageErrors(tester);
        }

        expect(
          find.byType(VotingDialog),
          findsOneWidget,
          reason: '응답을 기다리는 동안의 추가 탭은 무시되어 다이얼로그가 하나만 떠야 한다',
        );
        await settle(tester);
      },
    );
  });
}

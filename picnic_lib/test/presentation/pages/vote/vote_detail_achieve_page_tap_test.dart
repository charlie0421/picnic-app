import 'package:animated_digit/animated_digit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/pages/vote/vote_detail_achieve_page.dart';
import 'package:picnic_lib/presentation/widgets/vote/voting/voting_dialog.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../helpers/ignore_image_errors.dart';
import '../../../helpers/mock_supabase.dart';
import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

/// ## `_handleVoteItemTap` 경로 회귀
///
/// 아이템 행 탭은 네 갈래로 갈린다 — 종료/예정 게이트(안내 다이얼로그),
/// 비로그인(로그인 유도 다이얼로그), 로그인(탈퇴 차단 확인 후 투표 다이얼로그).
/// 이 파일은 행을 **실제로 탭해서** 각 갈래의 관측 가능한 결과(다이얼로그
/// 종류)를 못 박는다. 실제 Supabase 없이 관측 가능한 지점까지만 간다 —
/// 투표 다이얼로그가 뜨는 것까지가 경계고, 투표 제출은 다루지 않는다.

Map<String, dynamic> _voteRow({int id = 1, DateTime? stopAt}) {
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
    'stop_at': (stopAt ?? now.add(const Duration(days: 7))).toIso8601String(),
    'is_ended': false,
    'is_upcoming': false,
    'is_partnership': false,
    'partner': null,
    'reward': null,
  };
}

Map<String, dynamic> _voteItemRow({int id = 1, int voteTotal = 5000}) {
  return {
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
}

Map<String, dynamic> _voteAchieveRow({int id = 1, int amount = 10000}) {
  return {
    'id': id,
    'vote_id': 1,
    'reward_id': id,
    'order': id,
    'amount': amount,
    'reward': {
      'id': id,
      'title': {'ko': '포토카드'},
      'thumbnail': null,
    },
    'vote': _voteRow(),
  };
}

Map<String, dynamic> _fixtures({DateTime? stopAt}) => {
      'vote': [_voteRow(stopAt: stopAt)],
      'vote_item': [_voteItemRow()],
      'vote_achieve': [_voteAchieveRow()],
    };

/// 로그인 사용자의 프로필 행. `deleted_at` 이 널이어야 탈퇴 차단 다이얼로그를
/// 지나 투표 다이얼로그까지 간다.
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

  Future<void> pumpPage(WidgetTester tester, {required bool loggedIn}) async {
    // 기본 테스트 서피스(800x600)는 실기기보다 낮아서 투표 다이얼로그
    // (LargePopupWidget)가 세로로 넘친다. 프로덕션 기하(393x892)로 띄운다.
    tester.view.devicePixelRatio = 3.0;
    tester.view.physicalSize = const Size(393, 892) * 3.0;
    addTearDown(tester.view.reset);
    await pumpWidgetAndIgnoreErrors(
      tester,
      buildTestAppPage(
        const VoteDetailAchievePage(voteId: 1),
        loggedIn: loggedIn,
      ),
    );
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      drainExpectedImageErrors(tester);
    }
  }

  /// 아이템 행을 탭한다. 행 전체가 `HitTestBehavior.opaque` 인 GestureDetector
  /// 라서, 행에만 존재하는 득표수 위젯을 겨냥하면 정확히 그 행이 맞는다.
  Future<void> tapVoteItemRow(WidgetTester tester) async {
    final row = find.byType(AnimatedDigitWidget);
    expect(row, findsOneWidget, reason: '아이템 행이 그려져 있어야 탭할 수 있다');
    await tester.tap(row, warnIfMissed: false);
    // 다이얼로그 트랜지션(300ms)과 탭 핸들러의 async 구간을 흘려보낸다.
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 150));
      drainExpectedImageErrors(tester);
    }
  }

  /// 페이지 언마운트 후 BannerAdWidget 의 취소 불가 재시도와 1초 폴링 타이머를
  /// 흘려보낸다 (vote_detail_achieve_page_loading_order_test.dart 와 동일).
  Future<void> settle(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 30));
  }

  group('VoteDetailAchievePage vote item tap', () {
    testWidgets('logged-out tap shows the login-required dialog', (
      tester,
    ) async {
      setupMockSupabase(_fixtures());
      await pumpPage(tester, loggedIn: false);

      await tapVoteItemRow(tester);

      // showRequireLoginDialog → showSimpleDialog. 다이얼로그 종류가 아니라
      // 사용자에게 보이는 문구로 단언한다 (ko 하네스 기본 로케일).
      expect(
        find.text('로그인이 필요합니다'),
        findsOneWidget,
        reason: '비로그인 탭은 로그인 유도 다이얼로그를 띄워야 한다',
      );
      expect(
        find.byType(VotingDialog),
        findsNothing,
        reason: '비로그인 상태에서 투표 다이얼로그가 떠서는 안 된다',
      );
      await settle(tester);
    });

    testWidgets('logged-in tap on an active vote opens the voting dialog', (
      tester,
    ) async {
      // isSupabaseLoggedSafely 가 auth.currentUser 를 보므로 세션까지 심는다.
      // user_profiles 픽스처(deleted_at: null)는 탈퇴 차단 게이트를 통과시킨다.
      await setupMockSupabaseWithAuth(
        {
          ..._fixtures(),
          'user_profiles': [_userProfileRow('test-user-1')],
        },
        userId: 'test-user-1',
      );
      await pumpPage(tester, loggedIn: true);

      await tapVoteItemRow(tester);

      expect(
        find.byType(VotingDialog),
        findsOneWidget,
        reason: '로그인 상태에서 진행 중 투표를 탭하면 투표 다이얼로그가 떠야 한다',
      );
      expect(find.text('로그인이 필요합니다'), findsNothing);
      await settle(tester);
    });

    testWidgets('tap on an ended vote shows the ended notice instead', (
      tester,
    ) async {
      // isEnded 게이트가 로그인 여부보다 먼저다 — 로그인 상태로 두고 종료
      // 픽스처만 준다.
      await setupMockSupabaseWithAuth(
        {
          ..._fixtures(
            stopAt: DateTime.now().toUtc().subtract(const Duration(days: 1)),
          ),
          'user_profiles': [_userProfileRow('test-user-1')],
        },
        userId: 'test-user-1',
      );
      await pumpPage(tester, loggedIn: true);

      await tapVoteItemRow(tester);

      expect(
        find.text('투표 마감됨'),
        findsOneWidget,
        reason: '종료된 투표 탭은 마감 안내 다이얼로그를 띄워야 한다',
      );
      expect(find.byType(VotingDialog), findsNothing);
      await settle(tester);
    });
  });
}

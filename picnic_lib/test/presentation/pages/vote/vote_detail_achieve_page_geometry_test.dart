import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/app_builder.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/presentation/pages/vote/vote_detail_achieve_page.dart';
import 'package:picnic_lib/presentation/providers/vote_detail_provider.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../helpers/ignore_image_errors.dart';
import '../../../helpers/mock_supabase.dart';
import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

/// ## 99px 로딩 점프 회귀
///
/// 이 페이지의 로딩 브랜치가 `_buildLoadingShimmer()`(= `Shimmer` 안의
/// `SingleChildScrollView`)를 그대로 돌려주면, 느슨한 제약에서 셔머가 콘텐츠
/// 높이(프로덕션 기하 393x892 기준 793px)로 수축한다. 로드된 페이지는
/// `Column` + `Expanded` 라 뷰포트 전체(892px)를 차지하므로, 데이터가 도착하는
/// 순간 페이지가 뷰포트의 11% 만큼 점프한다.
///
/// `vote_detail_page.dart` 의 로딩 브랜치처럼 `SizedBox.expand` 로 감싸면
/// 로딩·로드 높이가 같아져 점프가 사라진다. 이 파일은 그 높이 동일성을
/// **프로덕션 기하(디자인 393x892 + splitScreenMode, 서피스 393x892)** 에서
/// 못 박는다.
///
/// 하네스는 [buildTestApp](Scaffold body = **느슨한** 제약)을 쓴다 —
/// `buildTestAppPage` 는 Navigator 가 타이트한 제약을 줘서 수축이 관측되지
/// 않는다. 프로덕션에서 이 페이지는 앱 셸의 느슨한 슬롯에 얹힌다.

/// 상세가 계속 `AsyncLoading` 인 상태를 고정한다 (바깥 게이트).
class _PendingVoteDetail extends AsyncVoteDetail {
  @override
  Future<VoteModel?> build({
    required int voteId,
    VotePortal votePortal = VotePortal.vote,
  }) =>
      Completer<VoteModel?>().future;
}

/// 순위 목록이 계속 `AsyncLoading` 인 상태를 고정한다 (안쪽 게이트).
class _PendingVoteItemList extends AsyncVoteItemList {
  @override
  Future<List<VoteItemModel?>> build({
    required int voteId,
    VotePortal votePortal = VotePortal.vote,
  }) =>
      Completer<List<VoteItemModel?>>().future;
}

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

void main() {
  /// 프로덕션 뷰포트 높이 (393x892 논리 픽셀).
  const viewportHeight = 892.0;

  setUp(() {
    initTestColors();
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    setupMockSupabase({
      'vote': [_voteRow()],
      'vote_item': [_voteItemRow()],
      'vote_achieve': [
        _voteAchieveRow(id: 1, amount: 10000),
        _voteAchieveRow(id: 2, amount: 50000),
      ],
    });
  });

  tearDown(tearDownMockSupabase);

  Future<void> pump(WidgetTester tester, List<dynamic> overrides) async {
    tester.view.devicePixelRatio = 3.0;
    tester.view.physicalSize = const Size(393, viewportHeight) * 3.0;
    addTearDown(tester.view.reset);
    await pumpWidgetAndIgnoreErrors(
      tester,
      buildTestApp(
        const VoteDetailAchievePage(voteId: 1),
        extraOverrides: overrides,
        designSize: kAppDesignSize,
        splitScreenMode: kAppSplitScreenMode,
      ),
    );
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      drainExpectedImageErrors(tester);
    }
  }

  /// 페이지가 언마운트된 뒤 BannerAdWidget/폴링 타이머의 잔여 예약을 흘려보낸다
  /// (vote_detail_achieve_page_loading_order_test.dart 의 settle 과 동일).
  Future<void> settle(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 30));
  }

  double pageHeight(WidgetTester tester) =>
      tester.getSize(find.byType(VoteDetailAchievePage)).height;

  group('VoteDetailAchievePage loading geometry', () {
    testWidgets('outer gate: detail loading fills the viewport height', (
      tester,
    ) async {
      await pump(tester, [
        asyncVoteDetailProvider(voteId: 1).overrideWith(_PendingVoteDetail.new),
      ]);

      expect(
        pageHeight(tester),
        moreOrLessEquals(viewportHeight),
        reason: '로딩 셔머가 콘텐츠 높이로 수축하면 데이터 도착 시 페이지가 '
            '점프한다 — SizedBox.expand 로 뷰포트를 가득 채워야 한다',
      );
      await settle(tester);
    });

    testWidgets('inner gate: item list loading fills the viewport height', (
      tester,
    ) async {
      await pump(tester, [
        asyncVoteItemListProvider(voteId: 1)
            .overrideWith(_PendingVoteItemList.new),
      ]);

      expect(
        pageHeight(tester),
        moreOrLessEquals(viewportHeight),
        reason: '아이템 목록 로딩 브랜치도 같은 이유로 뷰포트를 가득 채워야 한다',
      );
      await settle(tester);
    });

    testWidgets('loaded page height equals loading height (no jump)', (
      tester,
    ) async {
      await pump(tester, const []);

      // 콘텐츠가 실제로 로드됐는지 확인 — 로딩 상태끼리 비교하는 무의미한
      // 통과를 막는다.
      expect(find.text('리워드1'), findsOneWidget);
      expect(
        pageHeight(tester),
        moreOrLessEquals(viewportHeight),
        reason: '로드된 페이지도 뷰포트 높이 그대로여야 로딩과의 높이 차 '
            '(= 점프)가 없다',
      );
      await settle(tester);
    });
  });
}

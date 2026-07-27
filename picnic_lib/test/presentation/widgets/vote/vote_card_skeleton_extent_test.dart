import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/app_builder.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/presentation/common/picnic_cached_network_image.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/list/vote_info_card.dart';
import 'package:picnic_lib/presentation/widgets/vote/vote_card_skeleton.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../helpers/ignore_image_errors.dart';
import '../../../helpers/mock_supabase.dart';
import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

/// 스켈레톤과 실카드의 높이가 어긋나면 데이터 도착 순간 리스트가 그 차이만큼
/// 점프한다. upcoming 탭은 한때 386px(뷰포트의 40%) 차이였다 — 스켈레톤엔
/// 실카드의 썸네일 그리드(clamp(200, 340, 화면높이×0.36))에 해당하는 블록이
/// 아예 없었다.
///
/// 실카드를 같은 기하에서 직접 측정해 대조하므로, 실카드 디자인이 바뀌면
/// 이 테스트가 스켈레톤도 따라가야 함을 알려준다.
Map<String, dynamic> _voteItemJson({required int id, required int artistId}) =>
    {
      'id': id,
      'vote_id': 1,
      'vote_total': 5000,
      'artist': {
        'id': artistId,
        'name': {'ko': '아티스트$id', 'en': 'Artist$id'},
        'image': null,
        'artist_group': {
          'id': 1,
          'name': {'ko': '그룹', 'en': 'Group'},
          'image': null,
        },
      },
      'artist_group': null,
    };

VoteModel _buildVote({required bool upcoming}) {
  final now = DateTime.now().toUtc();
  return VoteModel.fromJson({
    'id': 1,
    'title': {'ko': '테스트 투표', 'en': 'Test Vote'},
    'vote_category': 'birthday',
    'main_image': null,
    'wait_image': null,
    'result_image': null,
    'vote_content': null,
    'vote_item': [
      _voteItemJson(id: 1, artistId: 10),
      _voteItemJson(id: 2, artistId: 11),
      _voteItemJson(id: 3, artistId: 12),
    ],
    'created_at': now.toIso8601String(),
    'visible_at': now.subtract(const Duration(days: 2)).toIso8601String(),
    'start_at': (upcoming
            ? now.add(const Duration(days: 1))
            : now.subtract(const Duration(days: 1)))
        .toIso8601String(),
    'stop_at': now.add(const Duration(days: 7)).toIso8601String(),
    'is_ended': false,
    'is_upcoming': upcoming,
    'is_partnership': false,
    'partner': null,
    'reward': null,
  });
}

void main() {
  setUp(() {
    initTestColors();
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    setupMockSupabase({});
    PicnicCachedNetworkImage.disableTimeoutForTest = true;
    suppressImageErrors();
  });

  tearDown(tearDownMockSupabase);

  /// 프로덕션 기하(393x892)에서 [child] 의 자연 높이를 잰다.
  /// 리스트 안에서처럼 세로 무제한 제약을 주기 위해 스크롤 뷰에 담는다.
  Future<double> measure(WidgetTester tester, Widget child) async {
    tester.view.devicePixelRatio = 3.0;
    tester.view.physicalSize = const Size(393, 892) * 3.0;
    addTearDown(tester.view.reset);
    final key = UniqueKey();
    await pumpWidgetAndIgnoreErrors(
      tester,
      buildTestApp(
        SingleChildScrollView(child: KeyedSubtree(key: key, child: child)),
        designSize: kAppDesignSize,
        splitScreenMode: kAppSplitScreenMode,
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    drainExpectedImageErrors(tester);
    final height = tester.getSize(find.byKey(key)).height;
    // 다음 measure 호출을 위해 트리를 비운다.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
    return height;
  }

  Widget realCard(VoteModel vote, VoteStatus status) => Builder(
        builder: (context) =>
            VoteInfoCard(context: context, vote: vote, status: status),
      );

  group('VoteCardSkeleton matches the real card extent', () {
    testWidgets('upcoming: skeleton height within 24px of the real card', (
      tester,
    ) async {
      final real = await measure(
        tester,
        realCard(_buildVote(upcoming: true), VoteStatus.upcoming),
      );
      final skeleton = await measure(
        tester,
        const VoteCardSkeleton(status: VoteCardStatus.upcoming),
      );

      expect(
        (skeleton - real).abs(),
        lessThanOrEqualTo(24),
        reason: 'upcoming 스켈레톤 $skeleton vs 실카드 $real — 차이만큼 '
            '데이터 도착 시 리스트가 점프한다',
      );
    });

    testWidgets('ongoing/ended: gap stays within the accepted 48px', (
      tester,
    ) async {
      // 현재 Δ37/35px 는 체감 미미로 수용된 상태다. 이 단언은 그것이
      // 조용히 더 벌어지는 회귀만 막는다.
      final realActive = await measure(
        tester,
        realCard(_buildVote(upcoming: false), VoteStatus.active),
      );
      final skeletonOngoing = await measure(
        tester,
        const VoteCardSkeleton(status: VoteCardStatus.ongoing),
      );
      expect(
        (skeletonOngoing - realActive).abs(),
        lessThanOrEqualTo(48),
        reason: 'ongoing 스켈레톤 $skeletonOngoing vs 실카드 $realActive',
      );
    });
  });
}

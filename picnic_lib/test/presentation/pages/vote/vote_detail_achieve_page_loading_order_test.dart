import 'dart:async';

import 'package:animated_digit/animated_digit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/presentation/pages/vote/vote_detail_achieve_page.dart';
import 'package:picnic_lib/presentation/providers/vote_detail_provider.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../../../helpers/ignore_image_errors.dart';
import '../../../helpers/mock_supabase.dart';
import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

/// [VoteDetailAchievePage] 는 서로 독립인 두 프로바이더에 얹혀 있다 —
/// `asyncVoteItemListProvider`(순위 목록)와 `asyncVoteDetailProvider`(투표 상세).
/// 두 future 는 각자 완료되므로 "한쪽만 준비된" 프레임이 반드시 존재한다.
///
/// 이 파일은 그 두 순서를 **결정적으로** 재현해서, 어느 쪽이 먼저 와도 페이지가
/// 예외 없이 그려지는지 못 박는다. 재현 방법은 한쪽 프로바이더를 영원히 완료되지
/// 않는 future 로 override 하는 것 — 실제 앱에서 그 프로바이더의 네트워크 응답을
/// 기다리는 구간을 그대로 정지시킨 상태다.

/// 상세가 계속 `AsyncLoading` 인 상태를 고정한다.
class _PendingVoteDetail extends AsyncVoteDetail {
  @override
  Future<VoteModel?> build({
    required int voteId,
    VotePortal votePortal = VotePortal.vote,
  }) => Completer<VoteModel?>().future;
}

/// 상세 fetch 가 실패했을 때의 상태를 고정한다.
///
/// [AsyncVoteDetail.fetch] 는 예외를 삼키고 `null` 을 돌려주므로
/// (vote_detail_provider.dart), 이건 `AsyncError` 가 아니라 **`AsyncData(null)`**
/// 이다. `.value!` 입장에서는 loading 과 구분되지 않는 두 번째 null 원천이다.
class _NullVoteDetail extends AsyncVoteDetail {
  @override
  Future<VoteModel?> build({
    required int voteId,
    VotePortal votePortal = VotePortal.vote,
  }) async => null;
}

/// 순위 목록이 계속 `AsyncLoading` 인 상태를 고정한다(반대 순서).
class _PendingVoteItemList extends AsyncVoteItemList {
  @override
  Future<List<VoteItemModel?>> build({
    required int voteId,
    VotePortal votePortal = VotePortal.vote,
  }) => Completer<List<VoteItemModel?>>().future;
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

Map<String, dynamic> _voteItemRow({
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

Map<String, dynamic> _voteAchieveRow({
  int id = 1,
  int voteId = 1,
  int rewardId = 1,
  int order = 1,
  int amount = 10000,
}) {
  return {
    'id': id,
    'vote_id': voteId,
    'reward_id': rewardId,
    'order': order,
    'amount': amount,
    'reward': {
      'id': rewardId,
      'title': {'ko': '포토카드'},
      'thumbnail': null,
    },
    'vote': _voteRow(id: voteId),
  };
}

void main() {
  setUp(() {
    initTestColors();
    VisibilityDetectorController.instance.updateInterval = Duration.zero;
    setupMockSupabase({
      'vote': [_voteRow()],
      'vote_item': [
        _voteItemRow(id: 1, voteTotal: 5000),
        _voteItemRow(id: 2, voteTotal: 3000, artistId: 11, artistNameKo: '정국'),
      ],
      'vote_achieve': [
        _voteAchieveRow(id: 1, order: 1, amount: 10000),
        _voteAchieveRow(id: 2, order: 2, rewardId: 2, amount: 50000),
      ],
    });
  });

  tearDown(tearDownMockSupabase);

  /// `knownDefects` 없이 띄운다 — 널 체크 예외가 나면 그대로 실패해야 한다.
  ///
  /// 두 프로바이더가 순차로(바깥 → 안쪽) 구독되므로 프레임을 몇 번 더 돌려야
  /// 둘 다 resolve 된다. 1초 주기 타이머에는 못 닿는 구간이다.
  Future<void> pump(WidgetTester tester, List<dynamic> overrides) async {
    await pumpWidgetAndIgnoreErrors(
      tester,
      buildTestAppPage(
        const VoteDetailAchievePage(voteId: 1),
        extraOverrides: overrides,
      ),
    );
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      drainExpectedImageErrors(tester);
    }
  }

  /// 트리를 비우고 남은 예약 작업을 흘려보낸다.
  ///
  /// 이 페이지가 상세를 다 받고 나면 [BannerAdWidget] 이 붙는데, 테스트 환경에선
  /// 광고 로드가 실패해서 `Future.delayed` 로 재시도를 예약한다
  /// (banner_ad_widget.dart `_scheduleRetry`). `Future.delayed` 는 취소가
  /// 안 되므로 dispose 만으로는 안 사라지고, 바인딩의 "A Timer is still pending"
  /// 검사에 걸린다. 트리를 먼저 비워 `_isDisposed` 를 세운 뒤(재예약이 멈춘다)
  /// 남은 한 건이 만료될 만큼 시간을 흘린다 — 최대 재시도 간격은 25초다.
  Future<void> settle(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 30));
  }

  /// 빌드가 터지면 Flutter 는 그 자리에 [ErrorWidget] 을 심는다. 예외를 삼키는
  /// 경로가 생기더라도 이 단언이 남아 있으면 "화면이 에러 박스" 인 상태를 잡는다.
  void expectNoErrorBox() {
    expect(
      find.byType(ErrorWidget),
      findsNothing,
      reason: '페이지 빌드가 예외로 죽어 에러 박스가 그려졌다',
    );
  }

  /// `isEnded` 게이트가 붙였다 뗐다 하는 별사탕 아이콘.
  ///
  /// 페이지에는 이미지 자리표시자로 그려지는 SvgPicture 도 있어서 타입만으로는
  /// 못 고른다. 에셋 이름으로 정확히 지목한다.
  final starCandyIcon = find.byWidgetPredicate((widget) {
    if (widget is! SvgPicture) return false;
    final loader = widget.bytesLoader;
    return loader is SvgAssetLoader &&
        loader.assetName.contains('star_candy_icon');
  }, description: 'star candy icon');

  group('VoteDetailAchievePage two-provider loading order', () {
    testWidgets('item list resolved, vote detail still loading', (tester) async {
      await pump(tester, [
        asyncVoteDetailProvider(voteId: 1).overrideWith(_PendingVoteDetail.new),
      ]);

      expect(find.byType(VoteDetailAchievePage), findsOneWidget);
      expectNoErrorBox();
      // 상세가 없으면 그릴 수 있는 건 로딩 자리표시자뿐이다.
      expect(find.byType(Shimmer), findsWidgets);
      await settle(tester);
    });

    testWidgets('vote detail resolved to null (fetch failed)', (tester) async {
      await pump(tester, [
        asyncVoteDetailProvider(voteId: 1).overrideWith(_NullVoteDetail.new),
      ]);

      expect(find.byType(VoteDetailAchievePage), findsOneWidget);
      expectNoErrorBox();
      await settle(tester);
    });

    testWidgets('vote detail resolved, item list still loading', (tester) async {
      await pump(tester, [
        asyncVoteItemListProvider(voteId: 1)
            .overrideWith(_PendingVoteItemList.new),
      ]);

      expect(find.byType(VoteDetailAchievePage), findsOneWidget);
      expectNoErrorBox();
      expect(find.byType(Shimmer), findsWidgets);
      await settle(tester);
    });

    testWidgets('both resolved renders the vote item row', (tester) async {
      await pump(tester, const []);

      expect(find.byType(VoteDetailAchievePage), findsOneWidget);
      expectNoErrorBox();
      expect(find.byType(Shimmer), findsNothing);
      // 1위 아이템 행이 실제로 그려졌다(득표수 애니메이션 위젯은 이 행에만 있다).
      expect(find.byType(AnimatedDigitWidget), findsOneWidget);
      // 진행 중 투표 → `isEnded` 게이트가 열려 별사탕 아이콘이 붙는다.
      expect(starCandyIcon, findsOneWidget);
      await settle(tester);
    });

    testWidgets('ended vote hides the star candy icon', (tester) async {
      setupMockSupabase({
        'vote': [
          {..._voteRow(), 'stop_at': DateTime.now()
              .toUtc()
              .subtract(const Duration(days: 1))
              .toIso8601String()},
        ],
        'vote_item': [_voteItemRow(id: 1, voteTotal: 5000)],
        'vote_achieve': [_voteAchieveRow(id: 1, order: 1, amount: 10000)],
      });

      await pump(tester, const []);

      expectNoErrorBox();
      expect(find.byType(AnimatedDigitWidget), findsOneWidget);
      expect(starCandyIcon, findsNothing);
      await settle(tester);
    });
  });
}

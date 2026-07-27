import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/presentation/providers/active_featured_votes_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/home_featured_vote_card.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:shimmer/shimmer.dart';

/// 홈 "현재 진행중인 투표" 가로 캐러셀.
///
/// 진행중 투표를 좌우로 넘겨볼 수 있고, viewportFraction < 1 로 다음 카드가
/// 살짝 보이게 해 "다음 장이 있음"을 시각적으로 표현한다. 하단 인디케이터로 위치를 표시.
class HomeFeaturedVoteCarousel extends ConsumerStatefulWidget {
  const HomeFeaturedVoteCarousel({super.key});

  /// 캐러셀이 자식(PageView / 로딩 플레이스홀더)에게 **tight** 하게 물려주는 높이.
  static const double viewportHeight = 372;

  /// PageView 한 장이 차지하는 뷰포트 폭 비율.
  static const double viewportFraction = 0.82;

  /// 페이지 안쪽 카드 여백.
  ///
  /// 로딩 플레이스홀더도 [viewportFraction] 과 이 여백을 그대로 써서 실제 카드와
  /// 같은 사각형을 차지한다. 두 값이 갈라지면 데이터 도착 순간 카드가 튄다.
  static const EdgeInsets pageMargin = EdgeInsets.symmetric(
    horizontal: 6,
    vertical: 4,
  );

  @override
  ConsumerState<HomeFeaturedVoteCarousel> createState() =>
      _HomeFeaturedVoteCarouselState();
}

/// 로딩 플레이스홀더 내부 블록에 붙는 키.
///
/// 테스트가 플레이스홀더 **자체**의 기하와 골격을 잡을 수 있게 공개한다.
/// 이게 없으면 회귀 테스트가 캐러셀 껍데기(고정 372px)만 재게 되고,
/// 플레이스홀더를 통째로 지워도 초록이 뜬다.
@visibleForTesting
abstract final class FeaturedVoteSkeletonKeys {
  /// 카드 프레임(테두리 + 글로우, 안쪽에 흰 배경).
  /// 불투명한 부분은 전부 **Shimmer 바깥**에 있어야 한다.
  static const Key frame = ValueKey('featured_vote_skeleton.frame');
  static const Key title = ValueKey('featured_vote_skeleton.title');
  static const Key timer = ValueKey('featured_vote_skeleton.timer');
  static const Key hero = ValueKey('featured_vote_skeleton.hero');
  static const Key saveButton = ValueKey('featured_vote_skeleton.save');
  static const Key shareButton = ValueKey('featured_vote_skeleton.share');

  /// 위에서 아래로 렌더되는 행. 한 행 안의 키는 왼쪽에서 오른쪽 순서다.
  ///
  /// 테스트는 이 목록만 훑으므로, 여기에 없는 블록은 지워도 초록이 뜬다.
  /// 새 블록을 추가하면 반드시 여기에도 넣을 것.
  static const List<List<Key>> rowsTopToBottom = <List<Key>>[
    <Key>[title],
    <Key>[timer],
    <Key>[hero],
    <Key>[saveButton, shareButton],
  ];
}

class _HomeFeaturedVoteCarouselState
    extends ConsumerState<HomeFeaturedVoteCarousel> {
  late final PageController _controller;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(
      viewportFraction: HomeFeaturedVoteCarousel.viewportFraction,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(asyncActiveFeaturedVotesProvider);

    return entriesAsync.when(
      loading: () => SizedBox(
        // data 브랜치의 PageView 는 뷰포트를 가로로 꽉 채운다. 폭 제약이 loose 인
        // 곳에 놓여도 두 브랜치가 같은 폭을 갖도록 여기서도 최대 폭을 요구한다.
        width: double.infinity,
        height: HomeFeaturedVoteCarousel.viewportHeight,
        // PageView 뷰포트는 자식을 hardEdge 로 자른다. 카드 글로우가 아래쪽에서
        // 잘리는 모양까지 같아야 데이터 도착 시 테두리가 달라 보이지 않는다.
        child: ClipRect(
          // 첫 페이지가 쉬는 위치와 동일한 사각형: 뷰포트 폭 x viewportFraction,
          // 가운데 정렬(PageView 의 padEnds: true 와 같은 결과).
          child: FractionallySizedBox(
            widthFactor: HomeFeaturedVoteCarousel.viewportFraction,
            child: const Padding(
              padding: HomeFeaturedVoteCarousel.pageMargin,
              child: _FeaturedVoteCardSkeleton(),
            ),
          ),
        ),
      ),
      error: (e, s) => const SizedBox.shrink(),
      data: (entries) {
        if (entries.isEmpty) return const SizedBox.shrink();
        return Column(
          children: [
            SizedBox(
              height: HomeFeaturedVoteCarousel.viewportHeight,
              child: PageView.builder(
                controller: _controller,
                itemCount: entries.length,
                padEnds: true,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) {
                  final entry = entries[i];
                  return Padding(
                    padding: HomeFeaturedVoteCarousel.pageMargin,
                    child: HomeFeaturedVoteCard(
                      vote: entry.vote,
                      percent: entry.topPercent,
                    ),
                  );
                },
              ),
            ),
            if (entries.length > 1) ...[
              const SizedBox(height: 12),
              _Dots(count: entries.length, active: _page),
            ],
          ],
        );
      },
    );
  }
}

/// 캐러셀 로딩 플레이스홀더.
///
/// 실제로 렌더되는 모습: [HomeFeaturedVoteCard] 와 같은 자리·같은 크기의 흰 카드
/// (연보라 테두리 + 글로우) 안에, 제목 바 / 타이머 바 / 히어로 블록 / 저장·공유
/// 버튼 두 개가 회색으로 반짝인다. 블록 사이 여백은 카드 흰 배경이 그대로 보인다.
///
/// ## 왜 전용 스켈레톤인가 (높이)
/// 캐러셀은 자식에게 [HomeFeaturedVoteCarousel.viewportHeight] 만큼의 **tight**
/// 높이를 물려주므로 여기에는 그 높이 안에 반드시 들어가는 위젯만 넣을 수 있다.
/// 세로 리스트용 `VoteCardSkeleton` 은 자연 높이가 고정(기기별 460~524px)이라
/// 뷰포트(372px)를 항상 초과해 매 콜드 스타트마다 하단이 잘렸다(iPhone 17 Pro
/// 기준 131px). 여기서는 히어로 영역을 [Expanded] 로 둬서 남는 높이를 흡수하게
/// 한다. 고정 높이 합(상단 74 + 하단 52)만 뷰포트보다 작으면 되므로 어떤 기기/
/// 텍스트 배율에서도 오버플로가 구조적으로 불가능하다.
///
/// ## 왜 프레임이 Shimmer 바깥인가 (가시성)
/// [Shimmer] 는 자식 전체를 `BlendMode.srcIn` 인 ShaderMask 로 덮는다
/// (shimmer 3.0.0 `_Shimmer.paint`). srcIn 은 자식의 **알파만** 남기고 색은 전부
/// 그라디언트로 갈아끼우므로, 불투명 배경을 Shimmer 안에 넣으면 그 위에 무엇을
/// 그리든 배경까지 한 덩어리로 칠해져 아무 구조도 없는 회색 라운드 사각형 하나가
/// 된다. 그래서 카드 프레임(흰 배경 / 테두리 / 글로우)은 Shimmer **바깥**에 두고,
/// Shimmer 는 배경이 없는 [Column] 만 감싼다. 그러면 반짝이는 건 흰색 블록들뿐이고
/// 그 사이 여백은 알파 0 이라 카드 배경이 비쳐, 골격이 실제로 눈에 보인다.
///
/// 저장소 안의 같은 패턴: `VideoListItemSkeleton` — 불투명한 `Card` 가 Shimmer
/// **바깥**에 있고 안쪽에는 흰 블록만 있다. `VoteDetailSkeleton` 의 투표 목록
/// 카드도 같다(예전에는 반대였다 — 최상위 `Shimmer` 안에
/// `Container(color: Colors.white)` 를 둬서 목록 전체가 구조 없는 회색 덩어리
/// 하나로 렌더됐다).
class _FeaturedVoteCardSkeleton extends StatelessWidget {
  const _FeaturedVoteCardSkeleton();

  Widget _bar(Key key, double width, double height, double radius) => Container(
        key: key,
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      key: FeaturedVoteSkeletonKeys.frame,
      // HomeFeaturedVoteCard 의 프레임과 동일 — 테두리와 글로우까지 같아야
      // 데이터가 도착해도 카드 윤곽이 바뀌지 않는다.
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.primary500.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary500.withValues(alpha: 0.18),
            blurRadius: 24,
            spreadRadius: 1,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: ColoredBox(
        color: AppColors.grey00,
        child: Shimmer.fromColors(
          baseColor: AppColors.grey300,
          highlightColor: AppColors.grey100,
          // 이 안에는 불투명 배경을 두지 말 것 (위 "가시성" 문단 참고).
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 제목 + 남은시간 (고정 높이)
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 16, 16.w, 8),
                child: Column(
                  children: [
                    _bar(FeaturedVoteSkeletonKeys.title, 180.w, 22, 8.r),
                    const SizedBox(height: 8),
                    _bar(FeaturedVoteSkeletonKeys.timer, 160.w, 20, 4.r),
                  ],
                ),
              ),
              // 1위 큰 이미지 자리 — 남은 공간을 채운다.
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 4, 16.w, 0),
                  child: DecoratedBox(
                    key: FeaturedVoteSkeletonKeys.hero,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                ),
              ),
              // 저장/공유 바 (ShareSection 과 동일한 세로 예산: 16 + 32 + 4)
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _bar(FeaturedVoteSkeletonKeys.saveButton, 120.w, 32, 16.r),
                    SizedBox(width: 16.w),
                    _bar(FeaturedVoteSkeletonKeys.shareButton, 120.w, 32, 16.r),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  final int count;
  final int active;

  const _Dots({required this.count, required this.active});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final on = i == active;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: on ? 18 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: on ? AppColors.primary500 : AppColors.grey300,
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

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

  @override
  ConsumerState<HomeFeaturedVoteCarousel> createState() =>
      _HomeFeaturedVoteCarouselState();
}

class _HomeFeaturedVoteCarouselState
    extends ConsumerState<HomeFeaturedVoteCarousel> {
  static const double _height = 372;
  late final PageController _controller;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.82);
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
        height: _height,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: const _FeaturedVoteCardSkeleton(),
        ),
      ),
      error: (e, s) => const SizedBox.shrink(),
      data: (entries) {
        if (entries.isEmpty) return const SizedBox.shrink();
        return Column(
          children: [
            SizedBox(
              height: _height,
              child: PageView.builder(
                controller: _controller,
                itemCount: entries.length,
                padEnds: true,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (context, i) {
                  final entry = entries[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
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
/// 캐러셀은 자식에게 `_height` 만큼의 **tight** 높이를 물려주므로, 여기에는
/// 그 높이 안에 반드시 들어가는 위젯만 넣을 수 있다. 세로 리스트용
/// `VoteCardSkeleton` 은 자연 높이가 고정(기기별 460~524px)이라 뷰포트(372px)를
/// 항상 초과해 매 콜드 스타트마다 하단이 잘렸다(iPhone 17 Pro 기준 131px).
///
/// 그래서 실제로 로드될 [HomeFeaturedVoteCard] 와 같은 골격(제목 / 타이머 /
/// 히어로 이미지 / 공유 바)을 쓰되, 히어로 영역을 [Expanded] 로 둬서 남는 높이를
/// 흡수하게 한다. 고정 높이 합(상단 74 + 하단 52)만 뷰포트보다 작으면 되므로
/// 어떤 기기/텍스트 배율에서도 오버플로가 구조적으로 불가능하다.
class _FeaturedVoteCardSkeleton extends StatelessWidget {
  const _FeaturedVoteCardSkeleton();

  Widget _bar(double width, double height, double radius) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.grey300,
      highlightColor: AppColors.grey100,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.grey00,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: AppColors.primary500.withValues(alpha: 0.25),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 제목 + 남은시간 (고정 높이)
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 16, 16.w, 8),
              child: Column(
                children: [
                  _bar(180.w, 22, 8.r),
                  const SizedBox(height: 8),
                  _bar(160.w, 20, 4.r),
                ],
              ),
            ),
            // 1위 큰 이미지 자리 — 남은 공간을 채운다.
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 4, 16.w, 0),
                child: DecoratedBox(
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
                  _bar(120.w, 32, 16.r),
                  SizedBox(width: 16.w),
                  _bar(120.w, 32, 16.r),
                ],
              ),
            ),
          ],
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

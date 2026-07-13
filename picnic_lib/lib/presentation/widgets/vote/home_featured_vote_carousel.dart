import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/presentation/providers/active_featured_votes_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/home_featured_vote_card.dart';
import 'package:picnic_lib/presentation/widgets/vote/vote_card_skeleton.dart';
import 'package:picnic_lib/ui/style.dart';

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
          child: const VoteCardSkeleton(status: VoteCardStatus.ongoing),
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

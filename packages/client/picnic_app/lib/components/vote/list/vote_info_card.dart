import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:picnic_app/components/picnic_cached_network_image.dart';
import 'package:picnic_app/components/vote/list/vote_header.dart';
import 'package:picnic_app/models/pic/artist_vote.dart';
import 'package:picnic_app/models/vote/vote.dart';
import 'package:picnic_app/pages/vote/vote_detail_page.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/ui/common_gradient.dart';
import 'package:picnic_app/ui/style.dart';

class VoteInfoCard extends ConsumerStatefulWidget {
  const VoteInfoCard({
    super.key,
    required this.context,
    required this.vote,
  });

  final BuildContext context;
  final VoteModel vote;

  @override
  ConsumerState<VoteInfoCard> createState() => _VoteInfoCardState();
}

class _VoteInfoCardState extends ConsumerState<VoteInfoCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offsetAnimation;
  late final Animation<double> _opacityAnimation; // 텍스트 위젯용 페이드 애니메이션

  void _restartAnimation() {
    _controller.reset();
    _controller.forward();
  }

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 1), // 총 지속 시간
      vsync: this,
    )..forward();

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, 1.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, .5, curve: Curves.easeOut),
      ),
    );

    // 텍스트에만 적용할 페이드 애니메이션
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );
  }

  @override
  dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) {
    final List<VoteItemModel>? items = widget.vote.vote_item;
    final no1 = items?[0];
    final no2 = items?[1];
    final no3 = items?[2];

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        final navigationInfoNotifier =
            ref.read(navigationInfoProvider.notifier);
        navigationInfoNotifier
            .setCurrentPage(VoteDetailPage(voteId: widget.vote.id));
        navigationInfoNotifier.hidePortal();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16).r,
        margin: const EdgeInsets.only(bottom: 32).r,
        child: Column(
          children: [
            VoteHeader(
              title: widget.vote.title[Intl.getCurrentLocale()],
              stopAt: widget.vote.stop_at,
              onRefresh: _restartAnimation,
            ),
            SizedBox(
              height: 24.w,
            ),
            Container(
              width: double.infinity,
              height: 220.h,
              padding: const EdgeInsets.only(left: 36, right: 36, top: 16),
              clipBehavior: Clip.hardEdge,
              // 추가
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                border: Border.all(
                  color: AppColors.Primary500,
                  width: 1.5.w,
                ),
              ),
              child: Visibility(
                visible: _controller.status == AnimationStatus.forward ||
                    _controller.status == AnimationStatus.completed,
                child: SlideTransition(
                  position: _offsetAnimation,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      VoteCardColumnVertical(
                          rank: 2,
                          voteItem: no2!,
                          opacityAnimation: _opacityAnimation),
                      VoteCardColumnVertical(
                          rank: 1,
                          voteItem: no1!,
                          opacityAnimation: _opacityAnimation),
                      VoteCardColumnVertical(
                          rank: 3,
                          voteItem: no3!,
                          opacityAnimation: _opacityAnimation),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 10.w,
            ),
          ],
        ),
      ),
    );
  }
}

class VoteCardColumnVertical extends StatelessWidget {
  const VoteCardColumnVertical({
    super.key,
    required this.voteItem,
    required this.rank,
    required this.opacityAnimation,
  });

  final VoteItemModel voteItem;
  final int rank;
  final Animation<double> opacityAnimation;

  @override
  Widget build(
    BuildContext context,
  ) {
    final barHeight = rank == 1
        ? 140
        : rank == 2
            ? 104
            : 92;
    return Stack(
      alignment: Alignment.bottomCenter,
      clipBehavior: Clip.none,
      children: [
        SizedBox(
          width: 80.w,
          height: 220.h,
        ),
        Positioned(
          bottom: 0,
          height: barHeight.h,
          width: 80.w,
          child: Container(
            decoration: const BoxDecoration(
              gradient: commonGradient,
            ),
          ),
        ),
        Positioned(
          bottom: barHeight.h + 40.h,
          child: FadeTransition(
            opacity: opacityAnimation,
            child: Text(
              Intl.message('text_vote_rank', args: [rank]).toString(),
              style: getTextStyle(AppTypo.CAPTION12B, AppColors.Point900),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        Positioned(
          bottom: barHeight.h - 40.h,
          child: Container(
            width: 80.w,
            height: 80.w,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: rank == 1
                  ? goldGradient
                  : rank == 2
                      ? silverGradient
                      : bronzeGradient,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Container(
              width: 72.w,
              height: 72.w,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(100),
                border: Border.all(
                  color: AppColors.Grey00,
                  width: 1.w,
                ),
              ),
              child: FadeTransition(
                opacity: opacityAnimation,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: PicnicCachedNetworkImage(
                      imageUrl: voteItem.mystar_member.image ?? '',
                      useScreenUtil: true,
                      width: 100,
                      height: 100),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: barHeight.h - 80.h,
          child: FadeTransition(
            opacity: opacityAnimation,
            child: Column(
              children: [
                Text(
                  voteItem.mystar_member.getTitle(),
                  style: getTextStyle(
                    AppTypo.BODY14B,
                    AppColors.Grey900,
                  ),
                ),
                Text(
                  voteItem.mystar_member.getGroupTitle(),
                  style: getTextStyle(
                    AppTypo.CAPTION10SB,
                    AppColors.Grey00,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class PicVoteInfoCard extends ConsumerStatefulWidget {
  const PicVoteInfoCard({
    super.key,
    required this.context,
    required this.vote,
  });

  final BuildContext context;
  final ArtistVoteModel vote;

  @override
  ConsumerState<PicVoteInfoCard> createState() =>
      _VoteInfoCardHorizontalState();
}

class _VoteInfoCardHorizontalState extends ConsumerState<PicVoteInfoCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offsetAnimation;
  late final Animation<double> _opacityAnimation; // 텍스트 위젯용 페이드 애니메이션

  void _restartAnimation() {
    _controller.reset();
    _controller.forward();
  }

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 1), // 총 지속 시간
      vsync: this,
    )..forward();

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, .5, curve: Curves.easeOut),
      ),
    );

    // 텍스트에만 적용할 페이드 애니메이션
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );
  }

  @override
  dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<ArtistVoteItemModel>? items = widget.vote.artist_vote_item;
    final no1 = items?[0];
    final no2 = items?[1];
    final no3 = items?[2];

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16).w,
        margin: const EdgeInsets.only(bottom: 32).r,
        child: Column(
          children: [
            VoteHeader(
              title: widget.vote.title[Intl.getCurrentLocale()],
              stopAt: widget.vote.stop_at,
              onRefresh: _restartAnimation,
            ),
            SizedBox(
              height: 24.h,
            ),
            Container(
              width: double.infinity,
              height: 220.h,
              padding:
                  const EdgeInsets.only(left: 0, right: 18, top: 16, bottom: 16)
                      .r,
              clipBehavior: Clip.hardEdge,
              // 추가
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                border: Border.all(
                  color: AppColors.Primary500,
                  width: 1.5.w,
                ),
              ),
              child: Visibility(
                visible: _controller.status == AnimationStatus.forward ||
                    _controller.status == AnimationStatus.completed,
                child: SlideTransition(
                  position: _offsetAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      VoteCardColumnHorizontal(
                          rank: 1,
                          voteItem: no1!,
                          opacityAnimation: _opacityAnimation),
                      VoteCardColumnHorizontal(
                          rank: 2,
                          voteItem: no2!,
                          opacityAnimation: _opacityAnimation),
                      VoteCardColumnHorizontal(
                          rank: 3,
                          voteItem: no3!,
                          opacityAnimation: _opacityAnimation),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 10.w,
            ),
          ],
        ),
      ),
    );
  }
}

class VoteCardColumnHorizontal extends StatelessWidget {
  const VoteCardColumnHorizontal({
    super.key,
    required this.voteItem,
    required this.rank,
    required this.opacityAnimation,
  });

  final ArtistVoteItemModel voteItem;
  final int rank;
  final Animation<double> opacityAnimation;

  @override
  Widget build(
    BuildContext context,
  ) {
    final barWidth = rank == 1
        ? 240.w
        : rank == 2
            ? 200.w
            : 160.w;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          color: AppColors.Grey00,
          width: double.infinity,
          child: Container(
            width: barWidth.w,
            height: 50.w,
          ),
        ),
        Positioned(
          width: barWidth,
          child: Container(
            width: barWidth.w,
            height: 50.w,
            decoration: const BoxDecoration(
              gradient: commonGradientReverse,
            ),
          ),
        ),
        Positioned(
          left: barWidth + 50.w,
          height: 50.w,
          child: Align(
            alignment: Alignment.centerRight,
            child: FadeTransition(
              opacity: opacityAnimation,
              child: Text(
                Intl.message('text_vote_rank', args: [rank]).toString(),
                style: getTextStyle(AppTypo.CAPTION12B, AppColors.Point900),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
        Positioned(
          left: 10.w,
          top: 0,
          bottom: 0,
          child: FadeTransition(
            opacity: opacityAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  voteItem.title[Intl.getCurrentLocale()],
                  style: getTextStyle(
                    AppTypo.BODY14B,
                    AppColors.Grey900,
                  ),
                ),
                Text(
                  voteItem.description[Intl.getCurrentLocale()],
                  style: getTextStyle(
                    AppTypo.CAPTION10SB,
                    AppColors.Grey00,
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: barWidth - 25.w,
          child: Container(
            width: 50.w,
            height: 50.w,
            alignment: Alignment.center,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              gradient: rank == 1
                  ? goldGradient
                  : rank == 2
                      ? silverGradient
                      : bronzeGradient,
              borderRadius: BorderRadius.circular(50),
            ),
            child: Container(
              width: 42.w,
              height: 42.w,
              alignment: Alignment.centerRight,
              decoration: BoxDecoration(
                color: AppColors.Grey200,
                borderRadius: BorderRadius.circular(50),
                border: Border.all(
                  color: AppColors.Grey00,
                  width: 1.w,
                ),
              ),
              child: FadeTransition(
                opacity: opacityAnimation,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

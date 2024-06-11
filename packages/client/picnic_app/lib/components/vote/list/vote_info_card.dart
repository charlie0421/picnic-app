import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_app/components/vote/list/vote_header.dart';
import 'package:picnic_app/models/vote/vote.dart';
import 'package:picnic_app/pages/vote/vote_detail_page.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/ui/common_gradient.dart';
import 'package:picnic_app/ui/style.dart';

class VoteInfoCard extends StatefulWidget {
  const VoteInfoCard({
    super.key,
    required this.context,
    required this.ref,
    required this.vote,
  });

  final BuildContext context;
  final WidgetRef ref;
  final VoteModel vote;

  @override
  State<VoteInfoCard> createState() => _VoteInfoCardState();
}

class _VoteInfoCardState extends State<VoteInfoCard>
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
    final List<VoteItemModel> items = widget.vote.vote_item;
    final no1 = items[0];
    final no2 = items[1];
    final no3 = items[2];

    return GestureDetector(
      onTap: () {
        final navigationInfoNotifier =
            widget.ref.read(navigationInfoProvider.notifier);
        navigationInfoNotifier
            .setCurrentPage(VoteDetailPage(voteId: widget.vote.id));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16).r,
        margin: const EdgeInsets.only(bottom: 32).r,
        child: Column(
          children: [
            VoteHeader(
              vote: widget.vote,
              onRefresh: _restartAnimation,
            ),
            SizedBox(
              height: 24.h,
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
                      VoteCardColumn(
                          rank: 2,
                          voteItem: no2,
                          opacityAnimation: _opacityAnimation),
                      VoteCardColumn(
                          rank: 1,
                          voteItem: no1,
                          opacityAnimation: _opacityAnimation),
                      VoteCardColumn(
                          rank: 3,
                          voteItem: no3,
                          opacityAnimation: _opacityAnimation),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 10.h,
            ),
          ],
        ),
      ),
    );
  }
}

class VoteCardColumn extends StatelessWidget {
  const VoteCardColumn({
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
    final imageBottomMargin = barHeight - 40;
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        Container(
          color: AppColors.Gray100,
          height: barHeight.h,
          child: Container(
            width: 80.w,
            height: 100.h,
            decoration: const BoxDecoration(
              gradient: commonGradient,
            ),
          ),
        ),
        Positioned(
          bottom: barHeight.h + 50,
          child: FadeTransition(
            opacity: opacityAnimation,
            child: Text(
              '${rank}위',
              style: getTextStyle(AppTypo.CAPTION12B, AppColors.Point900),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        Positioned(
          bottom: imageBottomMargin.h,
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
              borderRadius: BorderRadius.circular(50),
            ),
            child: Container(
              width: 72.w,
              height: 72.w,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                border: Border.all(
                  color: AppColors.Gray00,
                  width: 1.w,
                ),
              ),
              child: FadeTransition(
                opacity: opacityAnimation,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child: CachedNetworkImage(
                      imageUrl: voteItem.mystar_member.image ?? '',
                      width: 72.w,
                      height: 72.w),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: imageBottomMargin.h - 40.h,
          child: FadeTransition(
            opacity: opacityAnimation,
            child: Column(
              children: [
                Text(
                  voteItem.mystar_member.getTitle(),
                  style: getTextStyle(
                    AppTypo.BODY14B,
                    AppColors.Gray900,
                  ),
                ),
                Text(
                  voteItem.mystar_member.getGroupTitle(),
                  style: getTextStyle(
                    AppTypo.CAPTION10SB,
                    AppColors.Gray00,
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

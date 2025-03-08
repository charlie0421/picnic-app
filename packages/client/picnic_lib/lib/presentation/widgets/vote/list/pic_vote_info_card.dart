import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/core/utils/i18n.dart';
import 'package:picnic_lib/data/models/pic/artist_vote.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/list/vote_info_card_header.dart';
import 'package:picnic_lib/presentation/widgets/vote/list/vote_info_card_horizontal.dart';
import 'package:picnic_lib/ui/style.dart';

class PicVoteInfoCard extends ConsumerStatefulWidget {
  const PicVoteInfoCard(
      {super.key,
      required this.context,
      required this.vote,
      required this.status});

  final BuildContext context;
  final ArtistVoteModel vote;
  final VoteStatus status;

  @override
  ConsumerState<PicVoteInfoCard> createState() => _PicVoteInfoCardState();
}

class _PicVoteInfoCardState extends ConsumerState<PicVoteInfoCard>
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
    final List<ArtistVoteItemModel>? items = widget.vote.artistVoteItem;
    final no1 = items?[0];
    final no2 = items?[1];
    final no3 = items?[2];

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        margin: const EdgeInsets.only(bottom: 32),
        child: Column(
          children: [
            VoteCardInfoHeader(
                title: getLocaleTextFromJson(widget.vote.title),
                stopAt: widget.vote.stopAt,
                onRefresh: _restartAnimation,
                status: widget.status),
            const SizedBox(
              height: 24,
            ),
            Container(
              width: double.infinity,
              height: 220,
              padding:
                  EdgeInsets.only(left: 0, right: 18.w, top: 16, bottom: 16),
              clipBehavior: Clip.hardEdge,
              // 추가
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                border: Border.all(
                  color: AppColors.primary500,
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
            const SizedBox(
              height: 10,
            ),
          ],
        ),
      ),
    );
  }
}

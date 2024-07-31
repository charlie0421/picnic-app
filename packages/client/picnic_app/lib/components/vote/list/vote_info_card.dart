import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_app/components/vote/list/vote_header.dart';
import 'package:picnic_app/components/vote/list/vote_info_card_horizontal.dart';
import 'package:picnic_app/components/vote/list/vote_info_card_vertical.dart';
import 'package:picnic_app/models/pic/artist_vote.dart';
import 'package:picnic_app/models/vote/vote.dart';
import 'package:picnic_app/pages/vote/vote_detail_page.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/providers/vote_detail_provider.dart';
import 'package:picnic_app/providers/vote_list_provider.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/i18n.dart';
import 'package:picnic_app/util/ui.dart';

class VoteInfoCard extends ConsumerStatefulWidget {
  const VoteInfoCard({
    super.key,
    required this.context,
    required this.vote,
    required this.status,
  });

  final BuildContext context;
  final VoteModel vote;
  final VoteStatus status;

  @override
  ConsumerState<VoteInfoCard> createState() => _VoteInfoCardState();
}

class _VoteInfoCardState extends ConsumerState<VoteInfoCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offsetAnimation;
  late final Animation<double> _opacityAnimation;
  bool _showRanking = false;

  void _restartAnimation() {
    _controller.reset();
    _controller.forward();
  }

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(seconds: 1),
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
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTimerEnd() {
    setState(() {
      _showRanking = true;
    });
  }

  Future<void> _handleRefresh() async {
    await ref.refresh(asyncVoteDetailProvider(voteId: widget.vote.id).future);
    await ref.refresh(asyncVoteItemListProvider(voteId: widget.vote.id).future);
    _restartAnimation();
  }

  @override
  Widget build(BuildContext context) {
    final asyncVoteDetail =
        ref.watch(asyncVoteDetailProvider(voteId: widget.vote.id));
    final asyncVoteItemList =
        ref.watch(asyncVoteItemListProvider(voteId: widget.vote.id));

    return asyncVoteDetail.when(
      data: (vote) => _buildCard(context, vote, asyncVoteItemList),
      loading: () => buildLoadingOverlay(),
      error: (error, stack) => Text('Error: $error'),
    );
  }

  Widget _buildCard(BuildContext context, VoteModel? vote,
      AsyncValue<List<VoteItemModel?>> asyncVoteItemList) {
    if (vote == null) return const SizedBox.shrink();

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
        margin: const EdgeInsets.only(top: 24, bottom: 32).r,
        child: Column(
          children: [
            VoteHeader(
              title: getLocaleTextFromJson(vote.title) ?? '',
              stopAt: widget.status == VoteStatus.upcoming
                  ? vote.start_at
                  : vote.stop_at,
              onRefresh:
                  widget.status == VoteStatus.active ? _handleRefresh : null,
              status: widget.status,
            ),
            if (widget.status == VoteStatus.active ||
                widget.status == VoteStatus.end)
              _buildVoteItemList(asyncVoteItemList),
          ],
        ),
      ),
    );
  }

  Widget _buildVoteItemList(
      AsyncValue<List<VoteItemModel?>> asyncVoteItemList) {
    return asyncVoteItemList.when(
      data: (voteItems) => Container(
        width: double.infinity,
        height: 220.h,
        padding: const EdgeInsets.only(left: 36, right: 36, top: 16).r,
        margin: EdgeInsets.only(top: 24.h),
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40).r,
          border: Border.all(
            color: AppColors.Primary500,
            width: 1.5.w,
          ),
        ),
        child: SlideTransition(
          position: _offsetAnimation,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              VoteCardColumnVertical(
                  rank: 2,
                  voteItem: voteItems[1]!,
                  opacityAnimation: _opacityAnimation),
              VoteCardColumnVertical(
                  rank: 1,
                  voteItem: voteItems[0]!,
                  opacityAnimation: _opacityAnimation),
              VoteCardColumnVertical(
                  rank: 3,
                  voteItem: voteItems[2]!,
                  opacityAnimation: _opacityAnimation),
            ],
          ),
        ),
      ),
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => Text('Error: $error'),
    );
  }
}

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
                title: getLocaleTextFromJson(widget.vote.title),
                stopAt: widget.vote.stop_at,
                onRefresh: _restartAnimation,
                status: widget.status),
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_app/components/vote/list/vote_header.dart';
import 'package:picnic_app/components/vote/list/vote_info_card_vertical.dart';
import 'package:picnic_app/models/vote/vote.dart';
import 'package:picnic_app/pages/vote/vote_detail_achieve_page.dart';
import 'package:picnic_app/pages/vote/vote_detail_page.dart';
import 'package:picnic_app/providers/global_media_query.dart';
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

  Future<void> _handleRefresh() async {
    // 현재 순위 정보 저장

    // 데이터 새로고침
    await ref.refresh(asyncVoteDetailProvider(voteId: widget.vote.id).future);
    await ref.refresh(asyncVoteItemListProvider(voteId: widget.vote.id).future);

    _restartAnimation();
    // }
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
        navigationInfoNotifier.setCurrentPage(
            vote.voteCategory == VoteCategory.achieve.name
                ? VoteDetailAchievePage(voteId: widget.vote.id)
                : VoteDetailPage(voteId: widget.vote.id));
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.cw),
        margin: EdgeInsets.only(top: 24.cw, bottom: 32),
        child: Column(
          children: [
            VoteCardInfoHeader(
              title: getLocaleTextFromJson(vote.title),
              stopAt: widget.status == VoteStatus.upcoming
                  ? vote.startAt!
                  : vote.stopAt!,
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
        width: ref.watch(globalMediaQueryProvider).size.width,
        height: 260,
        padding: const EdgeInsets.only(left: 36, right: 36, top: 16),
        margin: const EdgeInsets.only(top: 24),
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40).r,
          border: Border.all(
            color: AppColors.primary500,
            width: 1.5.cw,
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

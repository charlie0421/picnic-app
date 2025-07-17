import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:overlay_loading_progress/overlay_loading_progress.dart';
import 'package:picnic_lib/core/config/environment.dart';
import 'package:picnic_lib/core/utils/deeplink.dart';
import 'package:picnic_lib/core/utils/vote_share_util.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/common/share_section.dart';
import 'package:picnic_lib/presentation/pages/vote/vote_detail_achieve_page.dart';
import 'package:picnic_lib/presentation/pages/vote/vote_detail_page.dart';
import 'package:picnic_lib/presentation/providers/global_media_query.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/providers/vote_detail_provider.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/list/vote_info_card_achieve.dart';
import 'package:picnic_lib/presentation/widgets/vote/list/vote_info_card_header.dart';
import 'package:picnic_lib/presentation/widgets/vote/list/vote_info_card_vertical.dart';
import 'package:picnic_lib/presentation/widgets/vote/vote_card_skeleton.dart';
import 'package:picnic_lib/ui/style.dart';

class VoteInfoCard extends ConsumerStatefulWidget {
  const VoteInfoCard({
    super.key,
    required this.context,
    required this.vote,
    required this.status,
    this.votePortal = VotePortal.vote,
  });

  final BuildContext context;
  final VoteModel vote;
  final VoteStatus status;
  final VotePortal votePortal;

  @override
  ConsumerState<VoteInfoCard> createState() => _VoteInfoCardState();
}

class _VoteInfoCardState extends ConsumerState<VoteInfoCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offsetAnimation;
  late final Animation<double> _opacityAnimation;
  final GlobalKey _globalKey = GlobalKey();
  final GlobalKey _shareKey = GlobalKey();
  bool _isSaving = false;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
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

  void _restartAnimation() {
    _controller.reset();
    _controller.forward();
  }

  Future<void> _handleRefresh() async {
    // ignore: unused_result
    await ref.refresh(asyncVoteDetailProvider(
            voteId: widget.vote.id, votePortal: widget.votePortal)
        .future);
    // ignore: unused_result
    await ref.refresh(asyncVoteItemListProvider(voteId: widget.vote.id).future);
    _restartAnimation();
  }

  void _handleSaveImage() async {
    await ShareUtils.saveImage(
      _globalKey,
      onStart: () {
        OverlayLoadingProgress.start(context, color: AppColors.primary500);
        setState(() => _isSaving = true);
      },
      onComplete: () {
        OverlayLoadingProgress.stop();
        setState(() => _isSaving = false);
      },
    );
  }

  void _handleShareToTwitter() async {
    await ShareUtils.shareToSocial(
      _shareKey,
      message: getLocaleTextFromJson(widget.vote.title, context),
      hashtag:
          '#Picnic #Vote #PicnicApp #${getLocaleTextFromJson(widget.vote.title, context).replaceAll(' ', '')}',
      onStart: () {
        OverlayLoadingProgress.start(context, color: AppColors.primary500);
        setState(() => _isSaving = true);
      },
      downloadLink: await createBranchLink(
          getLocaleTextFromJson(widget.vote.title, context),
          '${Environment.appLinkPrefix}/vote/detail/${widget.vote.id}'),
      onComplete: () {
        OverlayLoadingProgress.stop();
        setState(() => _isSaving = false);
      },
    );
  }

  @override
  void didUpdateWidget(VoteInfoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  void safeSetState(VoidCallback fn) {
    if (mounted && !_disposed) {
      setState(fn);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _controller.dispose();
    super.dispose();
  }

  /// status에 따른 로딩 스켈레톤 생성
  Widget _buildLoadingSkeleton() {
    switch (widget.status) {
      case VoteStatus.upcoming:
        return const VoteCardSkeleton(status: VoteCardStatus.upcoming);
      case VoteStatus.active:
        return const VoteCardSkeleton(status: VoteCardStatus.ongoing);
      case VoteStatus.end:
        return const VoteCardSkeleton(status: VoteCardStatus.ended);
      default:
        return const VoteCardSkeleton(status: VoteCardStatus.ongoing);
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncVoteDetail = ref.watch(asyncVoteDetailProvider(
        voteId: widget.vote.id, votePortal: widget.votePortal));
    final asyncVoteItemList = ref.watch(asyncVoteItemListProvider(
        voteId: widget.vote.id, votePortal: widget.votePortal));

    return Container(
      color: AppColors.grey00,
      child: asyncVoteDetail.when(
        data: (vote) => _buildCard(context, vote, asyncVoteItemList),
        loading: () => _buildLoadingSkeleton(),
        error: (error, stack) => Text('Error: $error'),
      ),
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
              ? VoteDetailAchievePage(
                  voteId: widget.vote.id, votePortal: widget.votePortal)
              : VoteDetailPage(
                  voteId: widget.vote.id, votePortal: widget.votePortal),
        );
      },
      child: RepaintBoundary(
        key: _globalKey,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          margin: EdgeInsets.only(top: 8, bottom: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              RepaintBoundary(
                key: _shareKey,
                child: Column(
                  children: [
                    VoteCardInfoHeader(
                      title: getLocaleTextFromJson(vote.title, context),
                      stopAt: widget.status == VoteStatus.upcoming
                          ? vote.startAt!
                          : vote.stopAt!,
                      onRefresh: widget.status == VoteStatus.active
                          ? _handleRefresh
                          : null,
                      status: widget.status,
                    ),
                    if (widget.status == VoteStatus.active ||
                        widget.status == VoteStatus.end)
                      if (vote.voteCategory != VoteCategory.achieve.name)
                        _buildVoteItemList(asyncVoteItemList),
                    if (widget.status == VoteStatus.active ||
                        widget.status == VoteStatus.end)
                      if (vote.voteCategory == VoteCategory.achieve.name)
                        _buildAchieveVoteItemList(asyncVoteItemList),
                  ],
                ),
              ),
              if (!_isSaving)
                ShareSection(
                  saveButtonText: AppLocalizations.of(context).save,
                  shareButtonText: AppLocalizations.of(context).share,
                  onSave: _handleSaveImage,
                  onShare: _handleShareToTwitter,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVoteItemList(
      AsyncValue<List<VoteItemModel?>> asyncVoteItemList) {
    return asyncVoteItemList.when(
      data: (voteItems) {
        if (voteItems.isEmpty) {
          return const Center(child: Text('No vote items available'));
        }

        // null이 아닌 실제 아이템들만 필터링
        final nonNullItems = voteItems
            .where((item) => item != null)
            .cast<VoteItemModel>()
            .toList();

        // 2개 아이템인 경우 특별 처리
        if (nonNullItems.length == 2) {
          return Container(
            width: ref.watch(globalMediaQueryProvider).size.width,
            height: 260,
            padding:
                const EdgeInsets.only(left: 16, right: 16, top: 16), // 좌우 패딩 줄임
            margin: const EdgeInsets.only(top: 24),
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(40),
              border: Border.all(
                color: AppColors.primary500,
                width: 1.5.w,
              ),
            ),
            child: SlideTransition(
              position: _offsetAnimation,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24.0), // 좌우 패딩 추가
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // 1위 카드
                    VoteCardColumnVertical(
                      rank: 1,
                      voteItem: nonNullItems[0],
                      opacityAnimation: _opacityAnimation,
                      status: widget.status,
                    ),

                    // VS 텍스트
                    Padding(
                      padding: const EdgeInsets.only(bottom: 60),
                      child: FadeTransition(
                        opacity: _opacityAnimation,
                        child: Text(
                          'VS',
                          style: getTextStyle(
                                  AppTypo.caption12B, AppColors.primary500)
                              .copyWith(fontSize: 16.sp),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),

                    // 2위 카드
                    VoteCardColumnVertical(
                      rank: 2,
                      voteItem: nonNullItems[1],
                      opacityAnimation: _opacityAnimation,
                      status: widget.status,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // 3개 이상인 경우 기존 로직 (패딩으로 3개 맞추기)
        final paddedItems = [...voteItems];
        while (paddedItems.length < 3) {
          paddedItems.add(null);
        }

        return Container(
          width: ref.watch(globalMediaQueryProvider).size.width,
          height: 260,
          padding: const EdgeInsets.only(left: 36, right: 36, top: 16),
          margin: const EdgeInsets.only(top: 24),
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(40),
            border: Border.all(
              color: AppColors.primary500,
              width: 1.5.w,
            ),
          ),
          child: SlideTransition(
            position: _offsetAnimation,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (paddedItems[1] != null)
                  VoteCardColumnVertical(
                    rank: 2,
                    voteItem: paddedItems[1]!,
                    opacityAnimation: _opacityAnimation,
                    status: widget.status,
                  ),
                if (paddedItems[0] != null)
                  VoteCardColumnVertical(
                    rank: 1,
                    voteItem: paddedItems[0]!,
                    opacityAnimation: _opacityAnimation,
                    status: widget.status,
                  ),
                if (paddedItems[2] != null)
                  VoteCardColumnVertical(
                    rank: 3,
                    voteItem: paddedItems[2]!,
                    opacityAnimation: _opacityAnimation,
                    status: widget.status,
                  ),
              ],
            ),
          ),
        );
      },
      loading: () => Container(
        width: ref.watch(globalMediaQueryProvider).size.width,
        height: 260,
        margin: const EdgeInsets.only(top: 24),
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary500),
          ),
        ),
      ),
      error: (error, stack) => Text('Error: $error'),
    );
  }

  Widget _buildAchieveVoteItemList(
      AsyncValue<List<VoteItemModel?>> asyncVoteItemList) {
    return asyncVoteItemList.when(
      data: (voteItems) => Container(
        width: ref.watch(globalMediaQueryProvider).size.width,
        height: 260,
        padding: const EdgeInsets.only(left: 36, right: 36, top: 16),
        margin: const EdgeInsets.only(top: 24),
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          border: Border.all(
            color: AppColors.primary500,
            width: 1.5.w,
          ),
        ),
        child: FutureBuilder(
          future: fetchVoteAchieve(ref, voteId: widget.vote.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }
              if (snapshot.hasData) {
                return SlideTransition(
                  position: _offsetAnimation,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: snapshot.data!
                        .map<VoteCardColumnAchieve>((voteAchieve) {
                      return VoteCardColumnAchieve(
                          rank: voteAchieve,
                          voteItem: voteItems[0]!,
                          opacityAnimation: _opacityAnimation);
                    }).toList(),
                  ),
                );
              }
            }
            return const SizedBox.shrink();
          },
        ),
      ),
      loading: () => Container(
        width: ref.watch(globalMediaQueryProvider).size.width,
        height: 260,
        margin: const EdgeInsets.only(top: 24),
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary500),
          ),
        ),
      ),
      error: (error, stack) => Text('Error: $error'),
    );
  }
}

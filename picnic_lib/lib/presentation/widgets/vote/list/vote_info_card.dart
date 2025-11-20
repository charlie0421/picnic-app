import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:overlay_loading_progress/overlay_loading_progress.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/config/environment.dart';
import 'package:picnic_lib/core/utils/deeplink.dart';
import 'package:picnic_lib/core/utils/vote_share_util.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/common/navigator_key.dart';
import 'package:picnic_lib/presentation/common/share_section.dart';
import 'package:picnic_lib/presentation/pages/vote/vote_detail_achieve_page.dart';
import 'package:picnic_lib/presentation/pages/vote/vote_detail_page.dart';
import 'package:picnic_lib/presentation/providers/global_media_query.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/providers/vote_detail_provider.dart';
import 'package:picnic_lib/presentation/common/picnic_cached_network_image.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/list/vote_info_card_achieve.dart';
import 'package:picnic_lib/presentation/widgets/vote/list/vote_info_card_header.dart';
import 'package:picnic_lib/presentation/widgets/vote/list/vote_info_card_vertical.dart';
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
  late final PageController _thumbnailPageController;
  int _thumbnailPageIndex = 0;
  late VoteModel _voteData;
  List<VoteItemModel> _voteItems = [];
  // vote.id 별 랜덤 순서를 캐시해 위젯 수명 동안 안정적으로 유지
  final Map<int, List<int>> _shuffledOrderCache = {};

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _thumbnailPageController = PageController();
    _syncVoteData(widget.vote);
  }

  void _initializeAnimations() {
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..forward();

    _offsetAnimation =
        Tween<Offset>(begin: const Offset(0.0, 1.0), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.0, .5, curve: Curves.easeOut),
          ),
        );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
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

  void _syncVoteData(VoteModel vote) {
    _voteData = vote;
    _voteItems = _prepareVoteItems(vote);
  }

  List<VoteItemModel> _prepareVoteItems(VoteModel vote) {
    final items = List<VoteItemModel>.from(vote.voteItem ?? <VoteItemModel>[]);
    items.sort(
      (a, b) => (b.voteTotal ?? 0).compareTo(a.voteTotal ?? 0),
    );
    if (widget.status == VoteStatus.upcoming) {
      return items;
    }
    return items.length <= 3 ? items : items.take(3).toList();
  }

  Future<void> _handleRefresh() async {
    try {
      final refreshed = await ref.read(
        asyncVoteDetailProvider(
          voteId: widget.vote.id,
          votePortal: widget.votePortal,
        ).future,
      );
      if (mounted && refreshed != null) {
        safeSetState(() {
          _syncVoteData(refreshed);
        });
      }
    } catch (error, stack) {
      logger.e(
        '[VoteInfoCard] refresh error voteId=${widget.vote.id}',
        error: error,
        stackTrace: stack,
      );
    } finally {
      _restartAnimation();
    }
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
      message: getLocaleTextFromJson(
        _voteData.title,
        navigatorKey.currentContext!,
      ),
      hashtag:
          '#Picnic #Vote #PicnicApp #${getLocaleTextFromJson(_voteData.title, navigatorKey.currentContext!).replaceAll(' ', '')}',
      onStart: () {
        OverlayLoadingProgress.start(context, color: AppColors.primary500);
        setState(() => _isSaving = true);
      },
      downloadLink: await createBranchLink(
        getLocaleTextFromJson(_voteData.title, context),
        '${Environment.appLinkPrefix}/vote/detail/${widget.vote.id}',
      ),
      onComplete: () {
        OverlayLoadingProgress.stop();
        setState(() => _isSaving = false);
      },
    );
  }

  @override
  void didUpdateWidget(VoteInfoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.vote != oldWidget.vote || widget.status != oldWidget.status) {
      _syncVoteData(widget.vote);
    }
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
    _thumbnailPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.grey00,
      child: _buildCard(context),
    );
  }

  Widget _buildCard(
    BuildContext context,
  ) {
    final vote = _voteData;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        final navigationInfoNotifier = ref.read(
          navigationInfoProvider.notifier,
        );
        navigationInfoNotifier.setCurrentPage(
          vote.voteCategory == VoteCategory.achieve.name
              ? VoteDetailAchievePage(
                  voteId: widget.vote.id,
                  votePortal: widget.votePortal,
                )
              : VoteDetailPage(
                  voteId: widget.vote.id,
                  votePortal: widget.votePortal,
                ),
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
                    if (widget.status == VoteStatus.upcoming)
                      _buildUpcomingThumbnailGrid(_voteItems),
                    if (widget.status == VoteStatus.active ||
                        widget.status == VoteStatus.end)
                      if (vote.voteCategory != VoteCategory.achieve.name)
                        _buildVoteItemList(_voteItems),
                    if (widget.status == VoteStatus.active ||
                        widget.status == VoteStatus.end)
                      if (vote.voteCategory == VoteCategory.achieve.name)
                        _buildAchieveVoteItemList(_voteItems),
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

  Widget _buildVoteItemList(List<VoteItemModel> voteItems) {
    if (voteItems.isEmpty) {
      return const Center(child: Text('No vote items available'));
    }

    if (voteItems.length == 2) {
      return Container(
        width: ref.watch(globalMediaQueryProvider).size.width,
        height: 260,
        padding: const EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
        ),
        margin: const EdgeInsets.only(top: 24),
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: AppColors.primary500, width: 1.5.w),
        ),
        child: SlideTransition(
          position: _offsetAnimation,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                VoteCardColumnVertical(
                  rank: 1,
                  voteItem: voteItems[0],
                  opacityAnimation: _opacityAnimation,
                  status: widget.status,
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 60),
                  child: FadeTransition(
                    opacity: _opacityAnimation,
                    child: Text(
                      'VS',
                      style: getTextStyle(
                        AppTypo.caption12B,
                        AppColors.primary500,
                      ).copyWith(fontSize: 16.sp),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                VoteCardColumnVertical(
                  rank: 2,
                  voteItem: voteItems[1],
                  opacityAnimation: _opacityAnimation,
                  status: widget.status,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final paddedItems = <VoteItemModel?>[
      ...voteItems.take(3),
    ];
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
        border: Border.all(color: AppColors.primary500, width: 1.5.w),
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
  }

  /// 예정 투표 썸네일 그리드 (4 x 3)
  Widget _buildUpcomingThumbnailGrid(List<VoteItemModel> voteItems) {
    if (voteItems.isEmpty) {
      return const SizedBox.shrink();
    }

    final id = widget.vote.id;
    final needRegen =
        !_shuffledOrderCache.containsKey(id) ||
        _shuffledOrderCache[id]!.length != voteItems.length;
    if (needRegen) {
      final indices = List<int>.generate(voteItems.length, (i) => i);
      indices.shuffle(
        math.Random(DateTime.now().microsecondsSinceEpoch ^ id.hashCode),
      );
      _shuffledOrderCache[id] = indices;
    }
    final order = _shuffledOrderCache[id]!;
    final shuffled = [for (final i in order) voteItems[i]];

    final List<List<VoteItemModel>> pages = [];
    for (int i = 0; i < shuffled.length; i += 12) {
      pages.add(shuffled.sublist(i, math.min(i + 12, shuffled.length)));
    }

    final pageCount = pages.length;

    return Container(
      width: ref.watch(globalMediaQueryProvider).size.width,
      padding: const EdgeInsets.only(
        left: 12,
        right: 12,
        top: 12,
        bottom: 12,
      ),
      margin: const EdgeInsets.only(top: 16),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: AppColors.primary500, width: 1.5.w),
      ),
      child: Column(
        children: [
          SizedBox(
            height: math.max(
              200.0,
              math.min(
                340.0,
                ref.watch(globalMediaQueryProvider).size.height * 0.36,
              ),
            ),
            child: PageView.builder(
              controller: _thumbnailPageController,
              onPageChanged: (index) {
                if (mounted) {
                  setState(() => _thumbnailPageIndex = index);
                }
              },
              itemCount: pageCount,
              itemBuilder: (context, pageIndex) {
                final thumbnails = pages[pageIndex];
                return GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 8,
                    childAspectRatio: 1 / 1.0,
                  ),
                  itemCount: thumbnails.length,
                  itemBuilder: (context, index) {
                    final item = thumbnails[index];
                    final imageUrl =
                        (item.artist?.id != 0
                            ? item.artist?.image
                            : item.artistGroup?.image) ??
                        '';
                    final displayName = (item.artist?.id != 0)
                        ? getLocaleTextFromJson(
                            item.artist?.name ?? {},
                            context,
                          )
                        : getLocaleTextFromJson(
                            item.artistGroup?.name ?? {},
                            context,
                          );
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.grey200,
                              width: 1.w,
                            ),
                          ),
                          clipBehavior: Clip.hardEdge,
                          child: ClipOval(
                            child: PicnicCachedNetworkImage(
                              imageUrl: imageUrl,
                              width: 56,
                              height: 56,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: 56,
                          child: Text(
                            displayName,
                            style: getTextStyle(
                              AppTypo.caption10SB,
                              AppColors.grey900,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Builder(
                builder: (context) {
                  final bool isFirst = _thumbnailPageIndex == 0;
                  final bool isLast = _thumbnailPageIndex >= pageCount - 1;
                  return Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        color:
                            isFirst ? AppColors.grey300 : AppColors.grey800,
                        onPressed: () {
                          if (isFirst) return;
                          _thumbnailPageController.previousPage(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOut,
                          );
                        },
                      ),
                      Text(
                        '${_thumbnailPageIndex + 1}/$pageCount',
                        style: getTextStyle(
                          AppTypo.caption12B,
                          AppColors.grey800,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        color: isLast ? AppColors.grey300 : AppColors.grey800,
                        onPressed: () {
                          if (isLast) return;
                          _thumbnailPageController.nextPage(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOut,
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAchieveVoteItemList(List<VoteItemModel> voteItems) {
    if (voteItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: ref.watch(globalMediaQueryProvider).size.width,
      height: 260,
      padding: const EdgeInsets.only(left: 36, right: 36, top: 16),
      margin: const EdgeInsets.only(top: 24),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: AppColors.primary500, width: 1.5.w),
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
                  children: snapshot.data!.map<VoteCardColumnAchieve>((
                    voteAchieve,
                  ) {
                    return VoteCardColumnAchieve(
                      rank: voteAchieve,
                      voteItem: voteItems.first,
                      opacityAnimation: _opacityAnimation,
                    );
                  }).toList(),
                ),
              );
            }
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

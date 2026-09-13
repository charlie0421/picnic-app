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
import 'package:picnic_lib/presentation/common/picnic_image_prefetch.dart';
import 'package:picnic_lib/presentation/common/picnic_image_request.dart';
import 'package:picnic_lib/presentation/common/share_section.dart';
import 'package:picnic_lib/presentation/pages/vote/vote_detail_achieve_page.dart';
import 'package:picnic_lib/presentation/pages/vote/vote_detail_page.dart';
import 'package:picnic_lib/presentation/providers/global_media_query.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/providers/vote_detail_provider.dart';
import 'package:picnic_lib/presentation/common/picnic_cached_network_image.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';
import 'package:picnic_lib/presentation/widgets/ui/loading_overlay_with_icon.dart';
import 'package:picnic_lib/presentation/widgets/vote/list/vote_card_layout.dart';
import 'package:picnic_lib/presentation/widgets/vote/list/vote_info_card_achieve.dart';
import 'package:picnic_lib/presentation/widgets/vote/list/vote_info_card_helper.dart';
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
  bool _cardDragStartedAtTop = false;
  bool _cardDragStartedAtBottom = false;
  bool _cardDragTransferred = false;
  double _cardEdgeDragDistance = 0;

  // 저장/공유 시작 시 페이지의 로딩 오버레이 State 를 붙잡아 둔다. 수직 PageView 에서
  // 스와이프로 이 카드가 dispose 돼도 이 참조로 hide() 가 도달하므로 오버레이가
  // 화면을 영구히 덮지 않는다. (context 로 hide 하면 dispose 후 no-op)
  LoadingOverlayWithIconState? _overlay;

  void _showOverlay() {
    // 페이지가 공통 펄스 오버레이로 감싸져 있으면(투표 리스트) 펄스를,
    // 없으면(PIC 홈 등) 기존 전역 스피너를 폴백으로 쓴다. 둘 다 dispose-safe
    // (펄스=저장한 State 참조로, 스피너=전역 static 으로 hide).
    _overlay = LoadingOverlayWithIcon.of(context);
    if (_overlay != null) {
      _overlay!.show();
    } else {
      OverlayLoadingProgress.start(context, color: AppColors.primary500);
    }
    if (mounted) setState(() => _isSaving = true);
  }

  void _hideOverlay() {
    if (_overlay != null) {
      _overlay!.hide();
      _overlay = null;
    } else {
      OverlayLoadingProgress.stop();
    }
    if (mounted) setState(() => _isSaving = false);
  }

  bool _disposed = false;
  late PageController _thumbnailPageController;
  int _thumbnailPageIndex = 0;
  int _thumbnailPageSize =
      VoteCardLayout.thumbnailColumns * VoteCardLayout.maximumThumbnailRows;
  late VoteModel _voteData;
  List<VoteItemModel> _voteItems = [];
  final PicnicImagePrefetchScope _thumbnailImagePrefetchScope =
      PicnicImagePrefetchScope();
  int _thumbnailImagePrefetchGeneration = 0;
  Object? _scheduledThumbnailImageSignature;
  Object? _appliedThumbnailImageSignature;
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
      duration: const Duration(milliseconds: 180),
      vsync: this,
    )..forward();

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _opacityAnimation = const AlwaysStoppedAnimation<double>(1);
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
    return VoteInfoCardHelper.prepareVoteItems(vote.voteItem, widget.status);
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
        _clearThumbnailImages();
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
      onStart: _showOverlay,
      onComplete: _hideOverlay,
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
      onStart: _showOverlay,
      downloadLink: await createBranchLink(
        getLocaleTextFromJson(_voteData.title, context),
        '${Environment.appLinkPrefix}/vote/detail/${widget.vote.id}',
      ),
      onComplete: _hideOverlay,
    );
  }

  @override
  void didUpdateWidget(VoteInfoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.vote != oldWidget.vote ||
        widget.status != oldWidget.status ||
        widget.votePortal != oldWidget.votePortal) {
      _clearThumbnailImages();
    }
    if (widget.vote != oldWidget.vote || widget.status != oldWidget.status) {
      _syncVoteData(widget.vote);
      _thumbnailPageIndex = 0;
      final generation = _thumbnailImagePrefetchGeneration;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || generation != _thumbnailImagePrefetchGeneration) {
          return;
        }
        if (_thumbnailPageController.hasClients) {
          _thumbnailPageController.jumpToPage(0);
        }
      });
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
    _thumbnailImagePrefetchGeneration++;
    _thumbnailImagePrefetchScope.dispose();
    _controller.dispose();
    _thumbnailPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(color: AppColors.grey00, child: _buildCard(context));
  }

  Widget _buildCard(BuildContext context) {
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final card = Align(
            alignment: Alignment.topCenter,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              margin: EdgeInsets.only(top: 8, bottom: 16),
              child: LayoutBuilder(
                builder: (context, constraints) => _buildCardContents(
                  context,
                  vote,
                  bounded: constraints.hasBoundedHeight,
                ),
              ),
            ),
          );
          if (!constraints.hasBoundedHeight ||
              vote.voteCategory == VoteCategory.achieve.name) {
            return card;
          }
          final headerHeight = _buildHeader(
            context,
            vote,
          ).heightForWidth(context, constraints.maxWidth - 32.w);
          final bodyHeight = widget.status == VoteStatus.upcoming
              ? 16 +
                    24 +
                    3.w +
                    VoteCardLayout.thumbnailTileExtent(context) +
                    VoteCardLayout.thumbnailPagerHeight
              : 24 + 260.0;
          final minimumHeight =
              (24 +
                      headerHeight +
                      bodyHeight +
                      VoteCardLayout.shareSectionExtent(context))
                  .ceilToDouble();
          if (constraints.maxHeight >= minimumHeight) return card;

          // At accessibility text sizes a short page may not fit even one
          // candidate row. Keep text/images readable and make every action
          // reachable instead of silently clipping the grid or rank area.
          return NotificationListener<ScrollNotification>(
            onNotification: _handleCardScroll,
            child: SingleChildScrollView(
              key: const ValueKey('vote-card-overflow-scroll'),
              physics: const ClampingScrollPhysics(),
              child: SizedBox(height: minimumHeight, child: card),
            ),
          );
        },
      ),
    );
  }

  bool _handleCardScroll(ScrollNotification notification) {
    if (notification.depth != 0 || notification.metrics.axis != Axis.vertical) {
      return false;
    }
    if (notification is ScrollStartNotification &&
        notification.dragDetails != null) {
      _cardDragStartedAtTop = notification.metrics.extentBefore < 1;
      _cardDragStartedAtBottom = notification.metrics.extentAfter < 1;
      _cardDragTransferred = false;
      _cardEdgeDragDistance = 0;
    }
    if (_cardDragTransferred) return true;
    if (notification is! OverscrollNotification ||
        notification.dragDetails == null) {
      return false;
    }
    final next = notification.overscroll > 0;
    if (!(next ? _cardDragStartedAtBottom : _cardDragStartedAtTop)) {
      return false;
    }
    _cardEdgeDragDistance += notification.overscroll;
    if (_cardEdgeDragDistance.abs() < 24) return false;

    // A new outward swipe at the card edge moves the surrounding vote page.
    // The swipe that first reveals the actions stops there, so they stay usable.
    final pageView = context.findAncestorWidgetOfExactType<PageView>();
    final parent = Scrollable.maybeOf(context, axis: Axis.vertical)?.position;
    if (pageView?.scrollDirection != Axis.vertical ||
        parent == null ||
        !parent.hasContentDimensions ||
        parent.viewportDimension <= 0) {
      return false;
    }
    final page = (parent.pixels / parent.viewportDimension).round();
    final target = ((page + (next ? 1 : -1)) * parent.viewportDimension).clamp(
      parent.minScrollExtent,
      parent.maxScrollExtent,
    );
    if ((target - parent.pixels).abs() < 1) return false;
    _cardDragTransferred = true;
    unawaited(
      parent.animateTo(
        target,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      ),
    );
    return true;
  }

  VoteCardInfoHeader _buildHeader(BuildContext context, VoteModel vote) {
    return VoteCardInfoHeader(
      title: getLocaleTextFromJson(vote.title, context),
      stopAt: widget.status == VoteStatus.upcoming
          ? vote.startAt!
          : vote.stopAt!,
      onRefresh: widget.status == VoteStatus.active ? _handleRefresh : null,
      status: widget.status,
    );
  }

  Widget _buildCardContents(
    BuildContext context,
    VoteModel vote, {
    required bool bounded,
  }) {
    final header = _buildHeader(context, vote);
    final voteContent = _buildVoteContent(vote, bounded: bounded);
    final shareCapture = RepaintBoundary(
      key: _globalKey,
      child: RepaintBoundary(
        key: _shareKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            header,
            if (bounded)
              Flexible(fit: FlexFit.loose, child: voteContent)
            else
              voteContent,
          ],
        ),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        if (bounded)
          Flexible(fit: FlexFit.loose, child: shareCapture)
        else
          shareCapture,
        Visibility(
          visible: !_isSaving,
          maintainAnimation: true,
          maintainSize: true,
          maintainState: true,
          child: ShareSection(
            saveButtonText: AppLocalizations.of(context).save,
            shareButtonText: AppLocalizations.of(context).share,
            onSave: _handleSaveImage,
            onShare: _handleShareToTwitter,
          ),
        ),
      ],
    );
  }

  Widget _buildVoteContent(VoteModel vote, {required bool bounded}) {
    if (widget.status == VoteStatus.upcoming) {
      return _buildUpcomingThumbnailGrid(_voteItems, bounded: bounded);
    }
    if (widget.status != VoteStatus.active && widget.status != VoteStatus.end) {
      return const SizedBox.shrink();
    }
    if (vote.voteCategory == VoteCategory.achieve.name) {
      return _buildAchieveVoteItemList(_voteItems);
    }
    return _buildVoteItemList(_voteItems);
  }

  Widget _buildVoteItemList(List<VoteItemModel> voteItems) {
    if (voteItems.isEmpty) {
      return const Center(child: Text('No vote items available'));
    }

    if (voteItems.length == 2) {
      return Container(
        width: ref.watch(globalMediaQueryProvider).size.width,
        height: 260,
        padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
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

    final paddedItems = <VoteItemModel?>[...voteItems.take(3)];
    while (paddedItems.length < 3) {
      paddedItems.add(null);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = math.min(
          36.0,
          math.max(0.0, (constraints.maxWidth - 240 - 3.w) / 2),
        );
        return Container(
          width: ref.watch(globalMediaQueryProvider).size.width,
          height: 260,
          padding: EdgeInsets.only(
            left: horizontalPadding,
            right: horizontalPadding,
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
    );
  }

  /// 예정 투표 썸네일 그리드 (기본 4 x 3, 높이가 부족하면 행 수 축소)
  Widget _buildUpcomingThumbnailGrid(
    List<VoteItemModel> voteItems, {
    required bool bounded,
  }) {
    if (voteItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: ref.watch(globalMediaQueryProvider).size.width,
      padding: const EdgeInsets.only(left: 12, right: 12, top: 12, bottom: 12),
      margin: const EdgeInsets.only(top: 16),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: AppColors.primary500, width: 1.5.w),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableGridHeight = constraints.hasBoundedHeight
              ? math.max(
                  0.0,
                  constraints.maxHeight - VoteCardLayout.thumbnailPagerHeight,
                )
              : double.infinity;
          final rows = bounded
              ? VoteCardLayout.thumbnailRowsForHeight(
                  context,
                  availableGridHeight,
                )
              : VoteCardLayout.maximumThumbnailRows;
          final pageSize = rows * VoteCardLayout.thumbnailColumns;
          _synchronizeThumbnailPagination(pageSize, voteItems.length);

          final pages = _upcomingThumbnailPages(voteItems);
          final pageCount = pages.length;
          _scheduleThumbnailImages();
          final pageView = PageView.builder(
            key: ObjectKey(_thumbnailPageController),
            controller: _thumbnailPageController,
            onPageChanged: (index) {
              if (mounted && _thumbnailPageIndex != index) {
                setState(() => _thumbnailPageIndex = index);
              }
            },
            itemCount: pageCount,
            itemBuilder: (context, pageIndex) =>
                _buildThumbnailPage(context, pages[pageIndex]),
          );

          return Column(
            mainAxisSize: bounded ? MainAxisSize.max : MainAxisSize.min,
            children: [
              if (bounded)
                Expanded(child: pageView)
              else
                SizedBox(
                  height: VoteCardLayout.thumbnailGridExtent(context, rows),
                  child: pageView,
                ),
              SizedBox(
                height: VoteCardLayout.thumbnailPagerHeight,
                child: _buildThumbnailPager(pageCount),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildThumbnailPage(
    BuildContext context,
    List<VoteItemModel> thumbnails,
  ) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: VoteCardLayout.thumbnailColumns,
        mainAxisSpacing: VoteCardLayout.thumbnailRowSpacing,
        crossAxisSpacing: VoteCardLayout.thumbnailColumnSpacing,
        mainAxisExtent: VoteCardLayout.thumbnailTileExtent(context),
      ),
      itemCount: thumbnails.length,
      itemBuilder: (context, index) {
        final item = thumbnails[index];
        final imageRequest = VoteInfoCardHelper.thumbnailImageRequest(
          context,
          item,
        );
        final displayName = (item.artist?.id != 0)
            ? getLocaleTextFromJson(item.artist?.name ?? {}, context)
            : getLocaleTextFromJson(item.artistGroup?.name ?? {}, context);
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: VoteCardLayout.thumbnailSize,
              height: VoteCardLayout.thumbnailSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.grey200, width: 1.w),
              ),
              clipBehavior: Clip.hardEdge,
              child: ClipOval(
                child: PicnicCachedNetworkImage(
                  imageUrl: imageRequest.imageUrl,
                  imageRequest: imageRequest,
                  width: VoteCardLayout.thumbnailSize,
                  height: VoteCardLayout.thumbnailSize,
                ),
              ),
            ),
            const SizedBox(height: VoteCardLayout.thumbnailLabelGap),
            SizedBox(
              width: VoteCardLayout.thumbnailSize,
              child: Text(
                displayName,
                style: getTextStyle(AppTypo.caption10SB, AppColors.grey900),
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
  }

  Widget _buildThumbnailPager(int pageCount) {
    final isFirst = _thumbnailPageIndex == 0;
    final isLast = _thumbnailPageIndex >= pageCount - 1;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          color: isFirst ? AppColors.grey300 : AppColors.grey800,
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
          style: getTextStyle(AppTypo.caption12B, AppColors.grey800),
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
  }

  void _synchronizeThumbnailPagination(int pageSize, int itemCount) {
    final previousPageSize = _thumbnailPageSize;
    final anchorItem = _thumbnailPageIndex * previousPageSize;
    final lastPage = math.max(0, (itemCount - 1) ~/ pageSize);
    final nextPageIndex = math.min(lastPage, anchorItem ~/ pageSize);
    if (pageSize == previousPageSize && nextPageIndex == _thumbnailPageIndex) {
      return;
    }

    final previousController = _thumbnailPageController;
    _thumbnailPageSize = pageSize;
    _thumbnailPageIndex = nextPageIndex;
    _thumbnailPageController = PageController(initialPage: nextPageIndex);
    final generation = ++_thumbnailImagePrefetchGeneration;
    _scheduledThumbnailImageSignature = null;
    _appliedThumbnailImageSignature = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      previousController.dispose();
      if (!mounted || generation != _thumbnailImagePrefetchGeneration) return;
      _thumbnailImagePrefetchScope.replace(
        context,
        const <PicnicImageRequest>[],
      );
      _scheduleThumbnailImages();
    });
  }

  List<List<VoteItemModel>> _upcomingThumbnailPages(
    List<VoteItemModel> voteItems,
  ) {
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

    return VoteInfoCardHelper.paginateItems(shuffled, _thumbnailPageSize);
  }

  void _clearThumbnailImages() {
    _thumbnailImagePrefetchGeneration++;
    _scheduledThumbnailImageSignature = null;
    _appliedThumbnailImageSignature = null;
    if (mounted) {
      _thumbnailImagePrefetchScope.replace(
        context,
        const <PicnicImageRequest>[],
      );
    }
  }

  void _scheduleThumbnailImages() {
    if (!mounted) return;
    final signature = _thumbnailImageSignature();
    if (signature == _scheduledThumbnailImageSignature ||
        signature == _appliedThumbnailImageSignature) {
      return;
    }
    _scheduledThumbnailImageSignature = signature;
    final generation = _thumbnailImagePrefetchGeneration;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          generation != _thumbnailImagePrefetchGeneration ||
          _scheduledThumbnailImageSignature != signature) {
        return;
      }
      if (_thumbnailImageSignature() != signature) {
        _scheduledThumbnailImageSignature = null;
        _scheduleThumbnailImages();
        return;
      }

      _thumbnailImagePrefetchScope.replace(
        context,
        _nextThumbnailImageRequests(),
      );
      _appliedThumbnailImageSignature = signature;
      _scheduledThumbnailImageSignature = null;
    });
  }

  Object _thumbnailImageSignature() {
    final mediaQuery = MediaQuery.of(context);
    if (widget.status != VoteStatus.upcoming || _voteItems.isEmpty) {
      return (
        _thumbnailImagePrefetchGeneration,
        widget.vote.id,
        mediaQuery.devicePixelRatio,
        mediaQuery.size,
        _thumbnailPageSize,
        null,
      );
    }
    final pages = _upcomingThumbnailPages(_voteItems);
    final nextPageIndex = _thumbnailPageIndex + 1;
    if (nextPageIndex >= pages.length) {
      return (
        _thumbnailImagePrefetchGeneration,
        widget.vote.id,
        mediaQuery.devicePixelRatio,
        mediaQuery.size,
        _thumbnailPageIndex,
        _thumbnailPageSize,
        null,
      );
    }
    final nextPage = pages[nextPageIndex];
    final first = nextPage.isEmpty
        ? null
        : _thumbnailRequestSignature(
            VoteInfoCardHelper.thumbnailImageRequest(context, nextPage[0]),
          );
    final second = nextPage.length < 2
        ? null
        : _thumbnailRequestSignature(
            VoteInfoCardHelper.thumbnailImageRequest(context, nextPage[1]),
          );
    return (
      _thumbnailImagePrefetchGeneration,
      widget.vote.id,
      mediaQuery.devicePixelRatio,
      mediaQuery.size,
      _thumbnailPageIndex,
      _thumbnailPageSize,
      first,
      second,
    );
  }

  Object _thumbnailRequestSignature(PicnicImageRequest request) {
    return (
      request.url,
      request.requestWidth,
      request.requestHeight,
      request.decodeWidth,
      request.decodeHeight,
    );
  }

  Iterable<PicnicImageRequest> _nextThumbnailImageRequests() sync* {
    if (widget.status != VoteStatus.upcoming || _voteItems.isEmpty) return;
    final pages = _upcomingThumbnailPages(_voteItems);
    final nextPageIndex = _thumbnailPageIndex + 1;
    if (nextPageIndex >= pages.length) return;
    for (final item in pages[nextPageIndex].take(2)) {
      yield VoteInfoCardHelper.thumbnailImageRequest(context, item);
    }
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

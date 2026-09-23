import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/common/picnic_image_prefetch.dart';
import 'package:picnic_lib/presentation/common/picnic_image_request.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/list/vote_info_card.dart';
import 'package:picnic_lib/presentation/widgets/vote/list/vote_card_layout.dart';
import 'package:picnic_lib/presentation/widgets/vote/list/vote_info_card_helper.dart';
import 'package:picnic_lib/presentation/widgets/vote/vote_no_item.dart';
import 'package:picnic_lib/presentation/widgets/ui/pulse_loading_indicator.dart';
import 'package:picnic_lib/presentation/widgets/vote/vote_card_skeleton.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:picnic_lib/ui/presentation_tokens.dart';
import 'package:picnic_lib/presentation/widgets/ui/picnic_action_button.dart';

class VoteList extends ConsumerStatefulWidget {
  final VoteStatus status;
  final VoteCategory category;
  final String area;
  final VotePortal portal;

  const VoteList(
    this.status,
    this.category,
    this.area, {
    super.key,
    this.portal = VotePortal.vote,
  });

  @override
  ConsumerState<VoteList> createState() => _VoteListState();
}

class _VoteListState extends ConsumerState<VoteList> {
  final List<VoteModel> _items = [];
  bool _isLoading = true;
  bool _isFetchingMore = false;
  bool _noMoreItems = false;
  bool _hasLoadError = false;
  int _pageKey = 1;
  int _requestGeneration = 0;
  int _currentIndex = 0;
  final PicnicImagePrefetchScope _imagePrefetchScope = PicnicImagePrefetchScope(
    maximumCandidates: 3,
  );
  int _imagePrefetchGeneration = 0;
  Object? _scheduledAdjacentImageSignature;
  Object? _appliedAdjacentImageSignature;
  static const _pageSize = 10;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    unawaited(_fetchVotes(isInitialLoad: true));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scheduleAdjacentImages();
  }

  @override
  void didUpdateWidget(covariant VoteList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status != widget.status ||
        oldWidget.category != widget.category ||
        oldWidget.area != widget.area ||
        oldWidget.portal != widget.portal) {
      _clearAdjacentImages();
      _resetForNewGeneration();
      _resetPageController();
      unawaited(_fetchVotes(isInitialLoad: true));
    }
  }

  // setState 호출을 안전하게 하기 위한 헬퍼 메서드
  void _setStateIfMounted(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }

  Future<void> _fetchVotes({
    bool isInitialLoad = false,
    bool isRetry = false,
  }) async {
    if (!isInitialLoad &&
        (_isLoading ||
            _isFetchingMore ||
            _noMoreItems ||
            _items.isEmpty ||
            (_hasLoadError && !isRetry))) {
      return;
    }

    // 첫 await 전에 guard를 올려 재시도 연타와 page callback을 합친다.
    _setStateIfMounted(() {
      _hasLoadError = false;
      if (isInitialLoad) {
        _isLoading = true;
      } else {
        _isFetchingMore = true;
      }
    });

    final requestGeneration = _requestGeneration;
    final requestedPage = _pageKey;
    final requestStatus = widget.status;
    final requestCategory = widget.category;
    final requestArea = widget.area;
    final requestPortal = widget.portal;
    final hadItemsAtStart = _items.isNotEmpty;
    var loadingPage = requestedPage;

    if (requestStatus == VoteStatus.debug) {
      logger.d('🚨🚨🚨 VoteList._fetchVotes 호출됨 - 디버그 모드');
      logger.d(
        '📍 파라미터: status=$requestStatus, category=$requestCategory, area=$requestArea',
      );
      logger.d('📍 페이지: $requestedPage, 사이즈: $_pageSize');
      logger.d('📍 정렬: id DESC (고정값)');
      logger.d('📍 Provider 호출 시작...');
    }

    var shouldCheckInitialBoundary = false;
    try {
      final sortKey = requestStatus == VoteStatus.debug
          ? 'id_${DateTime.now().millisecondsSinceEpoch}'
          : 'id';

      Future<List<VoteModel>> loadPage(int page) {
        loadingPage = page;
        final pageProvider = asyncVoteListProvider(
          page,
          _pageSize,
          sortKey,
          'DESC',
          requestArea,
          status: requestStatus,
          category: requestCategory,
          votePortal: requestPortal,
        );
        // 재시도는 실패 캐시를, 새로고침은 이전 세대의 후속 페이지까지
        // 무효화해야 실제 새 요청을 한다. 세대 가드만으로는 부족하다.
        if (isRetry || requestGeneration > 0) {
          ref.invalidate(pageProvider);
        }
        return ref.read(pageProvider.future);
      }

      final newItems = await loadPage(requestedPage);
      if (!_isCurrentRequest(
        requestGeneration,
        requestStatus,
        requestCategory,
        requestArea,
        requestPortal,
      )) {
        return;
      }

      var filteredItems = _filterItems(newItems, requestPortal);
      var consumedPage = requestedPage;
      var reachedEnd = false;

      // PIC 필터 뒤 빈 페이지도 최대 세 페이지 더 확인한다.
      if (!isInitialLoad && filteredItems.isEmpty && hadItemsAtStart) {
        var attempts = 0;
        while (attempts < 3 && filteredItems.isEmpty) {
          final nextPage = consumedPage + 1;
          // 조회 실패는 목록 끝이 아니다. 바깥 catch가 실패한 페이지를
          // 보존해 그 지점부터 재시도하도록 한다.
          final nextItems = await loadPage(nextPage);
          if (!_isCurrentRequest(
            requestGeneration,
            requestStatus,
            requestCategory,
            requestArea,
            requestPortal,
          )) {
            return;
          }
          consumedPage = nextPage;
          filteredItems = _filterItems(nextItems, requestPortal);
          attempts++;
        }
        reachedEnd = filteredItems.isEmpty;
      }

      if (requestStatus == VoteStatus.debug) {
        logger.d('🚨🚨🚨 VoteList._fetchVotes 결과: ${newItems.length}개 아이템');
      }

      if (_isCurrentRequest(
        requestGeneration,
        requestStatus,
        requestCategory,
        requestArea,
        requestPortal,
      )) {
        _setStateIfMounted(() {
          if (isInitialLoad) {
            _items.clear();
          }
          _items.addAll(filteredItems);
          _pageKey = consumedPage + 1;
          _noMoreItems = reachedEnd;
        });
        _scheduleAdjacentImages();
        shouldCheckInitialBoundary = isInitialLoad && filteredItems.isNotEmpty;
      }
    } catch (e, stackTrace) {
      if (!_isCurrentRequest(
        requestGeneration,
        requestStatus,
        requestCategory,
        requestArea,
        requestPortal,
      )) {
        return;
      }
      _setStateIfMounted(() {
        _hasLoadError = true;
        _pageKey = loadingPage;
      });
      logger.w(
        '투표 목록 조회 실패 (page=$loadingPage)',
        error: e,
        stackTrace: stackTrace,
      );
      if (requestStatus == VoteStatus.debug) {
        logger.d('🚨🚨🚨 VoteList._fetchVotes 오류: $e');
      }
    } finally {
      if (_isCurrentRequest(
        requestGeneration,
        requestStatus,
        requestCategory,
        requestArea,
        requestPortal,
      )) {
        _setStateIfMounted(() {
          if (isInitialLoad) {
            _isLoading = false;
          } else {
            _isFetchingMore = false;
          }
        });
        if (shouldCheckInitialBoundary) {
          _scheduleInitialBoundaryCheck(requestGeneration);
        }
      }
    }
  }

  List<VoteModel> _filterItems(List<VoteModel> items, VotePortal portal) {
    if (portal != VotePortal.pic) return items;
    return items.where((vote) {
      final category = (vote.voteCategory ?? '').toLowerCase();
      return category.contains('image') || category.contains('weekly');
    }).toList();
  }

  bool _isCurrentRequest(
    int generation,
    VoteStatus status,
    VoteCategory category,
    String area,
    VotePortal portal,
  ) {
    return mounted &&
        generation == _requestGeneration &&
        status == widget.status &&
        category == widget.category &&
        area == widget.area &&
        portal == widget.portal;
  }

  void _resetForNewGeneration() {
    _requestGeneration++;
    _items.clear();
    _currentIndex = 0;
    _pageKey = 1;
    _noMoreItems = false;
    _hasLoadError = false;
    _isLoading = true;
    _isFetchingMore = false;
  }

  void _resetPageController() {
    final previousController = _pageController;
    _pageController = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      previousController.dispose();
    });
  }

  Future<void> _refreshVotes() {
    if (!mounted) return Future.value();
    _clearAdjacentImages();
    setState(_resetForNewGeneration);
    _resetPageController();
    return _fetchVotes(isInitialLoad: true);
  }

  Future<void> _retryVotes() {
    if (!mounted || _isLoading || _isFetchingMore || !_hasLoadError) {
      return Future.value();
    }
    return _items.isEmpty ? _refreshVotes() : _fetchVotes(isRetry: true);
  }

  void _scheduleInitialBoundaryCheck(int generation) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          generation != _requestGeneration ||
          _isLoading ||
          _items.isEmpty ||
          _items.length > 3) {
        return;
      }
      final index = _pageController.hasClients
          ? (_pageController.page ?? 0).round()
          : 0;
      _onPageChanged(index);
    });
  }

  void _onPageChanged(int index) {
    _currentIndex = index;
    _scheduleAdjacentImages();
    if (!_isLoading &&
        !_isFetchingMore &&
        !_noMoreItems &&
        _items.isNotEmpty &&
        index >= _items.length - 3) {
      unawaited(_fetchVotes());
    }
  }

  void _clearAdjacentImages() {
    _imagePrefetchGeneration++;
    _scheduledAdjacentImageSignature = null;
    _appliedAdjacentImageSignature = null;
    if (mounted) {
      _imagePrefetchScope.replace(context, const <PicnicImageRequest>[]);
    }
  }

  void _scheduleAdjacentImages() {
    if (!mounted) return;
    final signature = _adjacentImageSignature();
    if (signature == _scheduledAdjacentImageSignature ||
        signature == _appliedAdjacentImageSignature) {
      return;
    }
    _scheduledAdjacentImageSignature = signature;
    final generation = _imagePrefetchGeneration;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          generation != _imagePrefetchGeneration ||
          _scheduledAdjacentImageSignature != signature) {
        return;
      }
      if (_adjacentImageSignature() != signature) {
        _scheduledAdjacentImageSignature = null;
        _scheduleAdjacentImages();
        return;
      }

      _imagePrefetchScope.replace(context, _adjacentImageRequests());
      _appliedAdjacentImageSignature = signature;
      _scheduledAdjacentImageSignature = null;
    });
  }

  Object _adjacentImageSignature() {
    final nextIndex = _currentIndex + 1;
    final mediaQuery = MediaQuery.of(context);
    if (nextIndex < 0 || nextIndex >= _items.length) {
      return (
        _requestGeneration,
        _currentIndex,
        mediaQuery.devicePixelRatio,
        mediaQuery.size,
        null,
      );
    }

    final vote = _items[nextIndex];
    final status = _statusForVote(vote);
    if (!_rendersVerticalRanks(vote, status)) {
      return (
        _requestGeneration,
        _currentIndex,
        mediaQuery.devicePixelRatio,
        mediaQuery.size,
        vote.id,
        status,
        null,
      );
    }
    final preview = VoteInfoCardHelper.previewItems(vote.voteItem, status);
    final first = preview.isEmpty
        ? null
        : _requestSignature(
            VoteInfoCardHelper.rankImageRequest(context, preview[0]),
          );
    final second = preview.length < 2
        ? null
        : _requestSignature(
            VoteInfoCardHelper.rankImageRequest(context, preview[1]),
          );
    final third = preview.length < 3
        ? null
        : _requestSignature(
            VoteInfoCardHelper.rankImageRequest(context, preview[2]),
          );
    return (
      _requestGeneration,
      _currentIndex,
      mediaQuery.devicePixelRatio,
      mediaQuery.size,
      vote.id,
      status,
      first,
      second,
      third,
    );
  }

  Object _requestSignature(PicnicImageRequest request) {
    return (request.url, request.decodeWidth, request.decodeHeight);
  }

  Iterable<PicnicImageRequest> _adjacentImageRequests() sync* {
    final nextIndex = _currentIndex + 1;
    if (nextIndex < 0 || nextIndex >= _items.length) return;
    final vote = _items[nextIndex];
    final status = _statusForVote(vote);
    if (!_rendersVerticalRanks(vote, status)) return;

    for (final item in VoteInfoCardHelper.previewItems(vote.voteItem, status)) {
      yield VoteInfoCardHelper.rankImageRequest(context, item);
    }
  }

  bool _rendersVerticalRanks(VoteModel vote, VoteStatus status) {
    return (status == VoteStatus.active || status == VoteStatus.end) &&
        vote.voteCategory != VoteCategory.achieve.name;
  }

  VoteStatus _statusForVote(VoteModel item) {
    if (widget.status != VoteStatus.debug) return widget.status;
    final now = DateTime.now();
    if (item.startAt != null && now.isBefore(item.startAt!)) {
      return VoteStatus.upcoming;
    }
    if (item.stopAt != null && now.isAfter(item.stopAt!)) {
      return VoteStatus.end;
    }
    return VoteStatus.active;
  }

  VoteCardStatus _getSkeletonStatus(VoteModel? item) {
    if (widget.status == VoteStatus.debug && item != null) {
      final now = DateTime.now();
      if (item.startAt != null && now.isBefore(item.startAt!)) {
        return VoteCardStatus.upcoming;
      } else if (item.stopAt != null && now.isAfter(item.stopAt!)) {
        return VoteCardStatus.ended;
      } else {
        return VoteCardStatus.ongoing;
      }
    }
    switch (widget.status) {
      case VoteStatus.upcoming:
        return VoteCardStatus.upcoming;
      case VoteStatus.active:
        return VoteCardStatus.ongoing;
      case VoteStatus.end:
        return VoteCardStatus.ended;
      default:
        return VoteCardStatus.ongoing;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _items.isEmpty) {
      return Align(
        alignment: Alignment.topCenter,
        child: VoteCardSkeleton(status: _getSkeletonStatus(null)),
      );
    }
    if (_items.isEmpty) {
      if (_hasLoadError) {
        return Center(child: _buildRetryNotice());
      }
      return VoteNoItem(status: widget.status, context: context);
    }
    return RefreshIndicator(
      color: AppColors.primary500,
      backgroundColor: Colors.white,
      onRefresh: _refreshVotes,
      notificationPredicate: (notification) =>
          notification.metrics.axis == Axis.vertical &&
          (notification.depth == 0 ||
              (_currentIndex == 0 && notification.depth == 1)),
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: _items.length,
              onPageChanged: _onPageChanged,
              itemBuilder: (context, index) {
                final item = _items[index];
                final itemStatus = _statusForVote(item);

                return VoteInfoCard(
                  context: context,
                  vote: item,
                  status: itemStatus,
                );
              },
            ),
          ),
          // 필터를 거친 짧은 응답도 다음 페이지가 있을 수 있다. 안내 영역을
          // 유지하여 로딩이 끝나거나 실패해도 후보 페이지 구성이 바뀌지 않는다.
          SizedBox(
            height: math.max(
              40,
              VoteCardLayout.textHeight(
                    context,
                    AppLocalizations.of(context).label_retry,
                    Theme.of(context).textTheme.labelLarge!,
                    maxWidth: double.infinity,
                  ) +
                  8,
            ),
            child: _hasLoadError
                ? Material(
                    color: PicnicUi.surface,
                    elevation: 2,
                    borderRadius: BorderRadius.circular(12),
                    child: _buildRetryNotice(compact: true),
                  )
                : _isFetchingMore
                ? const Center(child: SmallPulseLoadingIndicator())
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildRetryNotice({bool compact = false}) {
    final l10n = AppLocalizations.of(context);
    final message = Text(
      l10n.message_error_occurred,
      textAlign: compact ? TextAlign.start : TextAlign.center,
      style: compact
          ? Theme.of(
              context,
            ).textTheme.labelLarge!.copyWith(color: PicnicUi.secondaryText)
          : PicnicUi.text(color: PicnicUi.secondaryText),
      maxLines: compact ? 1 : null,
      overflow: compact ? TextOverflow.ellipsis : null,
    );
    return Padding(
      padding: compact
          ? const EdgeInsets.symmetric(horizontal: 16)
          : const EdgeInsets.all(16),
      child: compact
          ? Row(
              children: [
                Expanded(child: message),
                TextButton(
                  key: const ValueKey('vote-list-retry'),
                  onPressed: _retryVotes,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 32),
                    foregroundColor: PicnicUi.actionColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(l10n.label_retry),
                ),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 16),
                message,
                const SizedBox(height: 8),
                PicnicActionButton(
                  key: const ValueKey('vote-list-retry'),
                  label: l10n.label_retry,
                  onPressed: _retryVotes,
                  variant: PicnicActionVariant.secondary,
                ),
              ],
            ),
    );
  }

  @override
  void dispose() {
    _requestGeneration++;
    _imagePrefetchGeneration++;
    _imagePrefetchScope.dispose();
    _pageController.dispose();
    super.dispose();
  }
}

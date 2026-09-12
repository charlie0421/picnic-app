import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/presentation/common/picnic_image_prefetch.dart';
import 'package:picnic_lib/presentation/common/picnic_image_request.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/list/vote_info_card.dart';
import 'package:picnic_lib/presentation/widgets/vote/list/vote_info_card_helper.dart';
import 'package:picnic_lib/presentation/widgets/vote/vote_no_item.dart';
import 'package:picnic_lib/presentation/widgets/ui/pulse_loading_indicator.dart';
import 'package:picnic_lib/presentation/widgets/vote/vote_card_skeleton.dart';
import 'package:picnic_lib/ui/style.dart';

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

  Future<void> _fetchVotes({bool isInitialLoad = false}) async {
    if (!isInitialLoad &&
        (_isLoading || _isFetchingMore || _noMoreItems || _items.isEmpty)) {
      return;
    }

    if (isInitialLoad) {
      if (!_isLoading) {
        _setStateIfMounted(() => _isLoading = true);
      }
    } else {
      // async 함수의 첫 await 전에 guard를 올려 연속 page callback을 합친다.
      _setStateIfMounted(() => _isFetchingMore = true);
    }

    final requestGeneration = _requestGeneration;
    final requestedPage = _pageKey;
    final requestStatus = widget.status;
    final requestCategory = widget.category;
    final requestArea = widget.area;
    final requestPortal = widget.portal;
    final hadItemsAtStart = _items.isNotEmpty;

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

      final pageProvider = asyncVoteListProvider(
        requestedPage,
        _pageSize,
        sortKey,
        'DESC',
        requestArea,
        status: requestStatus,
        category: requestCategory,
        votePortal: requestPortal,
      );
      if (isInitialLoad && requestGeneration > 0) {
        ref.invalidate(pageProvider);
      }
      final newItems = await ref.read(pageProvider.future);
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
          try {
            final nextItems = await ref.read(
              asyncVoteListProvider(
                nextPage,
                _pageSize,
                sortKey,
                'DESC',
                requestArea,
                status: requestStatus,
                category: requestCategory,
                votePortal: requestPortal,
              ).future,
            );
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
          } catch (_) {
            if (!_isCurrentRequest(
              requestGeneration,
              requestStatus,
              requestCategory,
              requestArea,
              requestPortal,
            )) {
              return;
            }
            break;
          }
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
    } catch (e) {
      if (!_isCurrentRequest(
        requestGeneration,
        requestStatus,
        requestCategory,
        requestArea,
        requestPortal,
      )) {
        return;
      }
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
    return (
      request.url,
      request.requestWidth,
      request.requestHeight,
      request.decodeWidth,
      request.decodeHeight,
    );
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
      return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [VoteCardSkeleton(status: _getSkeletonStatus(null))],
      );
    }
    if (_items.isEmpty) {
      return VoteNoItem(status: widget.status, context: context);
    }
    return RefreshIndicator(
      color: AppColors.primary500,
      backgroundColor: Colors.white,
      onRefresh: _refreshVotes,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: _items.length,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) {
              final item = _items[index];
              final itemStatus = _statusForVote(item);

              return Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  VoteInfoCard(
                    context: context,
                    vote: item,
                    status: itemStatus,
                  ),
                ],
              );
            },
          ),
          // 추가 로드 중 표시: 카드를 덮는 풀사이즈 스켈레톤 대신 하단 중앙에
          // 작은 펄스만 띄운다(현재 카드를 가려 회색 잔상처럼 보이던 문제 방지).
          if (_isFetchingMore)
            const Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(child: SmallPulseLoadingIndicator()),
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

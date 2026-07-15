import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/list/vote_info_card.dart';
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
  static const _pageSize = 10;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _fetchVotes(isInitialLoad: true);
  }

  // setState 호출을 안전하게 하기 위한 헬퍼 메서드
  void _setStateIfMounted(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }

  Future<void> _fetchVotes({
    bool isInitialLoad = false,
    bool isRefresh = false,
  }) async {
    if (_noMoreItems && !isInitialLoad && !isRefresh) {
      // 더 가져올 게 없으면 즉시 리턴하되, 진행 표시 플래그는 반드시 되돌린다.
      // 안 그러면 하단 VoteCardSkeleton(진행 표시)이 카드를 영구히 덮어
      // 회색 잔상처럼 남는다.
      if (_isFetchingMore) {
        _setStateIfMounted(() => _isFetchingMore = false);
      }
      return;
    }
    // 디버그 상태 로그 추가
    if (widget.status == VoteStatus.debug) {
      logger.d('🚨🚨🚨 VoteList._fetchVotes 호출됨 - 디버그 모드');
      logger.d(
        '📍 파라미터: status=${widget.status}, category=${widget.category}, area=${widget.area}',
      );
      logger.d('📍 페이지: $_pageKey, 사이즈: $_pageSize');
      logger.d('📍 정렬: id DESC (고정값)');
      logger.d('📍 Provider 호출 시작...');
    }

    if (isInitialLoad) {
      _setStateIfMounted(() {
        _isLoading = true;
      });
    }

    if (isRefresh) {
      _pageKey = 1;
      _noMoreItems = false;
    }

    try {
      // 디버그 모드에서는 타임스탬프를 추가하여 캐시 회피
      final sortKey = widget.status == VoteStatus.debug
          ? 'id_${DateTime.now().millisecondsSinceEpoch}'
          : 'id';

      final newItems = await ref.read(
        asyncVoteListProvider(
          _pageKey,
          _pageSize,
          sortKey,
          'DESC',
          widget.area,
          status: widget.status,
          category: widget.category,
          votePortal: widget.portal,
        ).future,
      );

      // vote 포탈 탭은 areas 배열(area)로만 분류 — 카테고리 후처리 없음.
      // 레거시 PIC 포탈(딥링크 전용)만 이미지/위클리 후처리를 유지한다.
      List<VoteModel> filteredItems = widget.portal == VotePortal.pic
          ? newItems.where((v) {
              final cat = (v.voteCategory ?? '').toLowerCase();
              return cat.contains('image') || cat.contains('weekly');
            }).toList()
          : newItems;

      // 빈 페이지가 반환될 경우 몇 페이지 앞당겨 건너뛰기(최대 3회 시도)
      if (!isInitialLoad && filteredItems.isEmpty && _items.isNotEmpty) {
        int attempts = 0;
        int tempPage = _pageKey + 1;
        while (attempts < 3 && filteredItems.isEmpty) {
          try {
            final nextItems = await ref.read(
              asyncVoteListProvider(
                tempPage,
                _pageSize,
                sortKey,
                'DESC',
                widget.area,
                status: widget.status,
                category: widget.category,
                votePortal: widget.portal,
              ).future,
            );
            filteredItems = widget.portal == VotePortal.pic
                ? nextItems.where((v) {
                    final cat = (v.voteCategory ?? '').toLowerCase();
                    return cat.contains('image') || cat.contains('weekly');
                  }).toList()
                : nextItems;
            if (filteredItems.isNotEmpty) {
              // tempPage까지 소비한 것으로 간주하여 pageKey를 넘겨둠
              _pageKey = tempPage + 1;
              break;
            }
            attempts++;
            tempPage++;
          } catch (_) {
            break;
          }
        }
        if (filteredItems.isEmpty) {
          _noMoreItems = true;
        }
      }

      if (widget.status == VoteStatus.debug) {
        logger.d('🚨🚨🚨 VoteList._fetchVotes 결과: ${newItems.length}개 아이템');
      }

      _setStateIfMounted(() {
        if (isRefresh || isInitialLoad) {
          _items.clear();
        }
        _items.addAll(filteredItems);
        if (filteredItems.isNotEmpty && (_pageKey == 1 || !isInitialLoad)) {
          // 일반 흐름에서 pageKey는 한 페이지씩 증가
          _pageKey++;
        }
        _isLoading = false;
        _isFetchingMore = false;
      });
    } catch (e) {
      if (widget.status == VoteStatus.debug) {
        logger.d('🚨🚨🚨 VoteList._fetchVotes 오류: $e');
      }
      _setStateIfMounted(() {
        _isLoading = false;
        _isFetchingMore = false;
      });
    }
  }

  void _onPageChanged(int index) {
    // 마지막 아이템에 도달하면 추가 fetch. 더 없을 땐(_noMoreItems) 트리거하지
    // 않아 진행 스켈레톤이 뜨지 않게 한다.
    if (!_isFetchingMore && !_noMoreItems && index == _items.length - 1) {
      _setStateIfMounted(() {
        _isFetchingMore = true;
      });
      _fetchVotes();
    }
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
      onRefresh: () => _fetchVotes(isRefresh: true),
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: _items.length,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) {
              final item = _items[index];
              final VoteStatus itemStatus;

              if (widget.status == VoteStatus.debug) {
                final now = DateTime.now();
                if (item.startAt != null && now.isBefore(item.startAt!)) {
                  itemStatus = VoteStatus.upcoming;
                } else if (item.stopAt != null && now.isAfter(item.stopAt!)) {
                  itemStatus = VoteStatus.end;
                } else {
                  itemStatus = VoteStatus.active;
                }
              } else {
                itemStatus = widget.status;
              }

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
    _pageController.dispose();
    super.dispose();
  }
}

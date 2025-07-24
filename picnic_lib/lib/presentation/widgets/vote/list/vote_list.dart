import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/list/vote_info_card.dart';
import 'package:picnic_lib/presentation/widgets/vote/vote_no_item.dart';
import 'package:picnic_lib/presentation/widgets/vote/vote_card_skeleton.dart';
import 'package:picnic_lib/ui/style.dart';

class VoteList extends ConsumerStatefulWidget {
  final VoteStatus status;
  final VoteCategory category;
  final String area;

  const VoteList(this.status, this.category, this.area, {super.key});

  @override
  ConsumerState<VoteList> createState() => _VoteListState();
}

class _VoteListState extends ConsumerState<VoteList> {
  final List<VoteModel> _items = [];
  bool _isLoading = true;
  bool _isFetchingMore = false;
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

  Future<void> _fetchVotes(
      {bool isInitialLoad = false, bool isRefresh = false}) async {
    // 디버그 상태 로그 추가
    if (widget.status == VoteStatus.debug) {
      logger.d('🚨🚨🚨 VoteList._fetchVotes 호출됨 - 디버그 모드');
      logger.d(
          '📍 파라미터: status=${widget.status}, category=${widget.category}, area=${widget.area}');
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
    }

    try {
      // 디버그 모드에서는 타임스탬프를 추가하여 캐시 회피
      final sortKey = widget.status == VoteStatus.debug
          ? 'id_${DateTime.now().millisecondsSinceEpoch}'
          : 'id';

      final newItems = await ref.read(asyncVoteListProvider(
        _pageKey,
        _pageSize,
        sortKey,
        'DESC',
        widget.area,
        status: widget.status,
        category: widget.category,
      ).future);

      if (widget.status == VoteStatus.debug) {
        logger.d('🚨🚨🚨 VoteList._fetchVotes 결과: ${newItems.length}개 아이템');
      }

      _setStateIfMounted(() {
        if (isRefresh || isInitialLoad) {
          _items.clear();
        }
        _items.addAll(newItems);
        if (newItems.isNotEmpty) {
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
    // 마지막 아이템에 도달하면 추가 fetch
    if (!_isFetchingMore && index == _items.length - 1) {
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          VoteCardSkeleton(status: _getSkeletonStatus(null)),
        ],
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
                mainAxisAlignment: MainAxisAlignment.center,
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
          if (_isFetchingMore)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: VoteCardSkeleton(
                    status: _getSkeletonStatus(
                        _items.isNotEmpty ? _items[_items.length - 1] : null)),
              ),
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

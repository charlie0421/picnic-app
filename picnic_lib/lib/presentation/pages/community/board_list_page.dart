import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/data/models/common/navigation.dart';
import 'package:picnic_lib/data/models/community/board.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/presentation/common/enhanced_search_box.dart';
import 'package:picnic_lib/presentation/common/no_item_container.dart';
import 'package:picnic_lib/presentation/common/picnic_cached_network_image.dart';
import 'package:picnic_lib/presentation/pages/community/board_home_page.dart';
import 'package:picnic_lib/presentation/providers/community/boards_provider.dart';
import 'package:picnic_lib/presentation/providers/community_navigation_provider.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:rxdart/rxdart.dart';

class BoardListPage extends ConsumerStatefulWidget {
  const BoardListPage({super.key});

  @override
  ConsumerState<BoardListPage> createState() => _BoardPageState();
}

class _BoardPageState extends ConsumerState<BoardListPage> {
  final FocusNode focusNode = FocusNode();
  final TextEditingController _textEditingController = TextEditingController();
  final _searchSubject = BehaviorSubject<String>();
  String _currentSearchQuery = '';
  Key _listKey = const ValueKey('board_list_initial');
  late ScrollController _scrollController;
  
  // 수동 페이징 관리
  List<BoardModel> _allBoards = [];
  bool _isLoading = false;
  bool _hasError = false;
  String _errorMessage = '';
  int _currentPage = 1;
  bool _hasMoreData = true;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(navigationInfoProvider.notifier).settingNavigation(
          showPortal: true,
          showTopMenu: false,
          showBottomNavigation: true,
          topRightMenu: TopRightType.community);
    });

    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    
    _searchSubject
        .debounceTime(const Duration(milliseconds: 300))
        .listen((query) {
          if (mounted) {
            _onSearchChanged(query);
          }
        });
    
    // 초기 데이터 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('🔥 PostFrameCallback triggered');
      if (mounted) {
        print('🔥 Triggering initial load');
        _loadData(isRefresh: true);
      } else {
        print('🔥 Widget not mounted, skipping initial load');
      }
    });
  }

  static const _pageSize = 20;

  void _onSearchChanged(String query) {
    if (!mounted) return;
    
    print('🔥 Search changed: "$query"');
    
    try {
      _currentSearchQuery = query;
      _listKey = ValueKey('board_list_${query.hashCode}');
      
      print('🔥 Loading data with new query: "$query"');
      _loadData(isRefresh: true);
      
      print('🔥 Search refresh triggered for query: "$query"');
    } catch (e) {
      print('🔥 Failed to handle search change: $e');
    }
  }

  void _onScroll() {
    if (!mounted || _isLoading || !_hasMoreData || _hasError) return;
    
    try {
      final position = _scrollController.position;
      if (!position.hasContentDimensions) return;
      
      final maxScroll = position.maxScrollExtent;
      final currentScroll = position.pixels;
      
      if (maxScroll > 0 && currentScroll >= maxScroll * 0.8) {
        print('🔥 Loading next page...');
        // 디바운싱으로 중복 호출 방지
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted && !_isLoading && _hasMoreData && !_hasError) {
            _loadData(isRefresh: false);
          }
        });
      }
    } catch (e) {
      print('🔥 Scroll listener error: $e');
    }
  }

  Future<void> _loadData({required bool isRefresh}) async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      _hasError = false;
      if (isRefresh) {
        _currentPage = 1;
        _hasMoreData = true;
      }
    });
    
    try {
      final result = await _fetch(_currentPage);
      
      if (mounted) {
        // 새로운 리스트 생성으로 동시 수정 방지
        final newBoards = <BoardModel>[];
        
        if (isRefresh) {
          newBoards.addAll(result);
        } else {
          newBoards.addAll(_allBoards);
          newBoards.addAll(result);
        }
        
        setState(() {
          _allBoards = newBoards; // 완전히 새로운 리스트로 교체
          _hasMoreData = result.length >= _pageSize;
          if (!isRefresh) _currentPage++;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    focusNode.dispose();
    _textEditingController.dispose();
    _searchSubject.close();
    _scrollController.dispose();
    super.dispose();
  }

  Future<List<BoardModel>> _fetch(int pageKey) async {
    // 강제로 print 사용 (로거 문제 우회)
    print('🔥 _fetch called with pageKey: $pageKey');
    
    if (!mounted) {
      print('🔥 Widget not mounted, returning empty');
      return [];
    }
    
    try {
      final query = _currentSearchQuery;
      print('🔥 Fetching boards - Query: "$query", Page: $pageKey, PageSize: $_pageSize');
      
      final newItems = await ref.read(boardsByArtistNameNotifierProvider(
              query, pageKey, _pageSize)
          .future);

      if (!mounted) {
        print('🔥 Widget unmounted during fetch, returning empty');
        return [];
      }

      print('🔥 Fetched ${newItems?.length ?? 0} boards');
      
      // 개별 BoardModel 리스트로 반환 (그룹핑 제거)
      final result = newItems ?? [];
      
      // 첫 번째 몇 개 보드 정보 로그
      if (result.isNotEmpty) {
        print('🔥 First board: ${result.first.name}, Artist: ${result.first.artist?.name}');
      } else {
        print('🔥 No boards returned from provider');
      }
      
      return result;
    } catch (e, s) {
      print('🔥 Error fetching boards: $e');
      print('🔥 Stack trace: $s');
      if (!mounted) return [];
      rethrow;
    }
  }

  // 그룹핑 로직을 UI 레벨로 이동
  Map<String, List<BoardModel>> _groupBoardsByArtist(List<BoardModel> boards) {
    if (boards.isEmpty) {
      print('🔥 No boards to group');
      return {};
    }

    try {
      // 리스트 복사로 동시 수정 방지
      final boardsCopy = List<BoardModel>.from(boards);
      final map = <String, List<BoardModel>>{};
      int skippedCount = 0;
      
      for (var board in boardsCopy) {
        if (board.artist == null) {
          skippedCount++;
          print('🔥 Board ${board.boardId} has no artist');
          continue;
        }
        final artistId = board.artist!.id;
        final key = artistId.toString();
        map.putIfAbsent(key, () => <BoardModel>[]).add(board);
      }
      
      print('🔥 Grouped ${boardsCopy.length} boards into ${map.length} artists (skipped: $skippedCount)');
      return map;
    } catch (e) {
      print('🔥 Error grouping boards: $e');
      return {};
    }
  }

      Widget _buildBoardList() {
    print('🔥 _buildBoardList called');
    
    // 안전한 복사본 생성
    final boardsCopy = List<BoardModel>.from(_allBoards);
    final groupedBoards = _groupBoardsByArtist(boardsCopy);
    
    print('🔥 Building board list - Total boards: ${boardsCopy.length}, Grouped: ${groupedBoards.length}, Loading: $_isLoading, Error: $_hasError');
    
    // 에러 상태
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_errorMessage'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadData(isRefresh: true),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    
    // 첫 로딩 상태
    if (boardsCopy.isEmpty && _isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    // 빈 결과
    if (boardsCopy.isEmpty && !_isLoading) {
      return NoItemContainer(
        message: t('common_text_no_search_result'),
      );
    }
    
    // 실제 데이터 표시 - 단순한 ListView.builder 사용
    final allGroupEntries = groupedBoards.entries.toList();
    
    return ListView.builder(
      key: _listKey,
      controller: _scrollController,
      itemCount: allGroupEntries.length + 1, // +1 for debug info
      itemBuilder: (context, index) {
        // 첫 번째 아이템: 디버그 정보
        if (index == 0) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text('Debug Info:', style: getTextStyle(AppTypo.body16B, AppColors.grey900)),
                Text('Total boards: ${boardsCopy.length}'),
                Text('Grouped: ${groupedBoards.length}'),
                Text('Loading: $_isLoading'),
                Text('Current query: "$_currentSearchQuery"'),
                Text('Current page: $_currentPage'),
                Text('Has more data: $_hasMoreData'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    print('🔥 Manual refresh button pressed');
                    _loadData(isRefresh: true);
                  },
                  child: const Text('Manual Refresh'),
                ),
                const Divider(),
              ],
            ),
          );
        }
        
        // 실제 보드 그룹들
        final groupIndex = index - 1;
        if (groupIndex < allGroupEntries.length) {
          final entry = allGroupEntries[groupIndex];
          final artistBoards = entry.value;
          
          return Container(
            key: ValueKey('board_group_${entry.key}_${_currentSearchQuery.hashCode}'),
            child: _buildArtistBoardGroup(artistBoards),
          );
        }
        
        // 로딩 인디케이터 (마지막)
        if (_isLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        return const SizedBox.shrink();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    logger.d('Building BoardListPage widget');
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12),
              child: EnhancedSearchBox(
                hintText: t('text_community_board_search'),
                onSearchChanged: (query) {
                  logger.d('Search box changed: "$query"');
                  if (mounted) {
                    try {
                      _searchSubject.add(query);
                    } catch (e) {
                      logger.w('Failed to update search query: $e');
                    }
                  }
                },
                controller: _textEditingController,
                focusNode: focusNode,
                debounceTime: const Duration(milliseconds: 300),
                showClearButton: true,
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () {
                  print('🔥 RefreshIndicator triggered');
                  return _loadData(isRefresh: true);
                },
                child: _buildBoardList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArtistBoardGroup(List<BoardModel> artistBoards) {
    if (artistBoards.isEmpty) return const SizedBox.shrink();

    final artist = artistBoards.first.artist;
    if (artist == null) return const SizedBox.shrink();

    try {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(32.r),
                    child: PicnicCachedNetworkImage(
                      imageUrl: artist.image ?? '',
                      width: 32,
                      height: 32,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      getLocaleTextFromJson(artist.name),
                      style: getTextStyle(AppTypo.body14B, AppColors.grey900),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Wrap(
                spacing: 8.w,
                runSpacing: 4.w,
                children: artistBoards
                    .where((board) => board.name.isNotEmpty)
                    .map((board) => Container(
                          key: ValueKey('board_chip_${board.boardId}'),
                          child: _buildBoardChip(board),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1, thickness: .5, color: AppColors.grey300),
          ],
        ),
      );
    } catch (e) {
      print('🔥 Error building artist group: $e');
      return const SizedBox.shrink();
    }
  }

  Widget _buildBoardChip(BoardModel board) {
    return GestureDetector(
      onTap: () {
        if (!mounted || board.artist == null) return;

        try {
          ref.read(communityStateInfoProvider.notifier).setCurrentBoard(board);
          ref
              .read(communityStateInfoProvider.notifier)
              .setCurrentArtist(board.artist!);
          ref
              .read(navigationInfoProvider.notifier)
              .setCommunityCurrentPage(BoardHomePage(board.artistId));
        } catch (e) {
          logger.w('Failed to navigate to board: $e');
        }
      },
      child: Chip(
        label: Text(
          getLocaleTextFromJson(board.name),
          style: getTextStyle(
              AppTypo.caption12B,
              (board.isOfficial ?? false)
                  ? AppColors.primary500
                  : AppColors.grey900),
        ),
        side: const BorderSide(color: AppColors.grey300, width: 1),
        backgroundColor: AppColors.grey00,
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4),
      ),
    );
  }
}

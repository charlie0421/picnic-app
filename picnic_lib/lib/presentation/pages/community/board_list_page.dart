import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/core/utils/korean_search_utils.dart';
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
      logger.d('🔥 PostFrameCallback triggered');
      if (mounted) {
        logger.d('🔥 Triggering initial load');
        _loadData(isRefresh: true);
      } else {
        logger.d('🔥 Widget not mounted, skipping initial load');
      }
    });
  }

  static const _pageSize = 20;

  // 개선된 보드 필터링 함수
  List<BoardModel> _getFilteredBoards(List<BoardModel> boards, String query) {
    if (query.isEmpty) return boards;

    logger.d('🔍 보드 검색어: "$query"');

    return boards.where((board) {
      final lowerQuery = query.toLowerCase();

      // 보드 이름 검색 (한국어 + 영어 + 초성)
      final boardNameKo = board.name['ko']?.toString() ?? '';
      final boardNameEn = board.name['en']?.toString() ?? '';

      logger.d('📋 보드 이름 (한국어): "$boardNameKo"');
      logger.d('📋 보드 이름 (영어): "$boardNameEn"');
      logger.d(
          '📋 보드 이름 초성: "${KoreanSearchUtils.extractKoreanInitials(boardNameKo)}"');

      if (KoreanSearchUtils.matchesKoreanInitials(boardNameKo, query) ||
          boardNameEn.toLowerCase().contains(lowerQuery)) {
        logger.d('✅ 보드 이름 매칭: "$boardNameKo" / "$boardNameEn"');
        return true;
      }

      // 아티스트 이름 검색 (한국어 + 영어 + 초성)
      if (board.artist?.name != null) {
        final artistNameKo = board.artist!.name['ko']?.toString() ?? '';
        final artistNameEn = board.artist!.name['en']?.toString() ?? '';

        logger.d('👤 아티스트 (한국어): "$artistNameKo"');
        logger.d('👤 아티스트 (영어): "$artistNameEn"');
        logger.d(
            '👤 아티스트 초성: "${KoreanSearchUtils.extractKoreanInitials(artistNameKo)}"');

        if (KoreanSearchUtils.matchesKoreanInitials(artistNameKo, query) ||
            artistNameEn.toLowerCase().contains(lowerQuery)) {
          logger.d('✅ 아티스트 이름 매칭: "$artistNameKo" / "$artistNameEn"');
          return true;
        }
      }

      return false;
    }).toList();
  }

  void _onSearchChanged(String query) {
    if (!mounted) return;

    try {
      _currentSearchQuery = query;
      _listKey = ValueKey(
          'board_list_${query.hashCode}_${DateTime.now().millisecondsSinceEpoch}');
      _loadData(isRefresh: true);
    } catch (e) {
      logger.w('Failed to handle search change: $e');
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
        // 디바운싱으로 중복 호출 방지
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted && !_isLoading && _hasMoreData && !_hasError) {
            _loadData(isRefresh: false);
          }
        });
      }
    } catch (e) {
      logger.w('Scroll listener error: $e');
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
        // 중복 제거를 위한 Set 사용
        final existingBoardIds = <String>{};
        final newBoards = <BoardModel>[];

        if (isRefresh) {
          // 새로고침 시에는 새 데이터만 사용
          for (var board in result) {
            if (!existingBoardIds.contains(board.boardId)) {
              existingBoardIds.add(board.boardId);
              newBoards.add(board);
            }
          }
        } else {
          // 기존 데이터 먼저 추가
          for (var board in _allBoards) {
            if (!existingBoardIds.contains(board.boardId)) {
              existingBoardIds.add(board.boardId);
              newBoards.add(board);
            }
          }
          // 새 데이터 추가 (중복 제거)
          for (var board in result) {
            if (!existingBoardIds.contains(board.boardId)) {
              existingBoardIds.add(board.boardId);
              newBoards.add(board);
            }
          }
        }

        setState(() {
          _allBoards = newBoards; // 중복이 제거된 리스트로 교체
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
    if (!mounted) return [];

    try {
      final query = _currentSearchQuery;
      // 페이지를 0부터 시작하도록 수정 (Supabase range와 일치)
      final adjustedPage = pageKey - 1;

      final newItems = await ref.read(
          boardsByArtistNameNotifierProvider(query, adjustedPage, _pageSize)
              .future);

      if (!mounted) return [];

      return newItems ?? [];
    } catch (e, s) {
      logger.e('Error fetching boards:', error: e, stackTrace: s);
      if (!mounted) return [];
      rethrow;
    }
  }

  Map<String, List<BoardModel>> _groupBoardsByArtist(List<BoardModel> boards) {
    if (boards.isEmpty) return {};

    try {
      final boardsCopy = List<BoardModel>.from(boards);
      final map = <String, List<BoardModel>>{};

      for (var board in boardsCopy) {
        if (board.artist == null) continue;

        final artistId = board.artist!.id;
        final key = artistId.toString();
        map.putIfAbsent(key, () => <BoardModel>[]).add(board);
      }

      return map;
    } catch (e) {
      logger.w('Error grouping boards: $e');
      return {};
    }
  }

  Widget _buildBoardList() {
    final boardsCopy = List<BoardModel>.from(_allBoards);
    // 검색 필터링 적용
    final filteredBoards = _getFilteredBoards(boardsCopy, _currentSearchQuery);
    final groupedBoards = _groupBoardsByArtist(filteredBoards);

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

    // 빈 결과 (검색어가 있을 때와 없을 때 구분)
    if (filteredBoards.isEmpty && !_isLoading) {
      return NoItemContainer(
        message: _currentSearchQuery.isNotEmpty
            ? t('text_no_search_result')
            : t('common_text_no_search_result'),
      );
    }

    // 실제 데이터 표시 - 단순한 ListView.builder 사용
    final allGroupEntries = groupedBoards.entries.toList();

    return ListView.builder(
      key: _listKey,
      controller: _scrollController,
      itemCount: allGroupEntries.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        // 실제 보드 그룹들
        if (index < allGroupEntries.length) {
          final entry = allGroupEntries[index];
          final artistBoards = entry.value;

          return Container(
            key: ValueKey(
                'board_group_${entry.key}_${_currentSearchQuery.hashCode}_$index'),
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
                onRefresh: () => _loadData(isRefresh: true),
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
                    child: _currentSearchQuery.isNotEmpty
                        ? KoreanSearchUtils.buildHighlightedRichText(
                            KoreanSearchUtils.getMatchingText(
                                artist.name, _currentSearchQuery),
                            _currentSearchQuery,
                            getTextStyle(AppTypo.body14B, AppColors.grey900),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          )
                        : Text(
                            getLocaleTextFromJson(artist.name),
                            style: getTextStyle(
                                AppTypo.body14B, AppColors.grey900),
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
                    .map((board) => _buildBoardChip(board))
                    .toList(),
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1, thickness: .5, color: AppColors.grey300),
          ],
        ),
      );
    } catch (e) {
      logger.w('Error building artist group: $e');
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
        label: _currentSearchQuery.isNotEmpty
            ? KoreanSearchUtils.buildHighlightedRichText(
                KoreanSearchUtils.getMatchingText(
                    board.name, _currentSearchQuery),
                _currentSearchQuery,
                getTextStyle(
                    AppTypo.caption12B,
                    (board.isOfficial ?? false)
                        ? AppColors.primary500
                        : AppColors.grey900),
              )
            : Text(
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/data/models/common/navigation.dart';
import 'package:picnic_lib/data/models/community/post.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/common/comment/post_popup_menu.dart';
import 'package:picnic_lib/presentation/common/enhanced_search_box.dart';
import 'package:picnic_lib/presentation/providers/community/post_provider.dart';
import 'package:picnic_lib/presentation/providers/community_navigation_provider.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/widgets/community/common/post_list_item.dart';
import 'package:picnic_lib/presentation/widgets/ui/pulse_loading_indicator.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PostSearchPage extends ConsumerStatefulWidget {
  const PostSearchPage({super.key});

  @override
  ConsumerState<PostSearchPage> createState() => _PostSearchPageState();
}

class _PostSearchPageState extends ConsumerState<PostSearchPage> {
  final FocusNode focusNode = FocusNode();
  final TextEditingController _textController = TextEditingController();
  late final PagingController<int, PostModel> _pagingController;
  List<String> _searchHistory = [];
  String _currentSearchQuery = '';

  @override
  void initState() {
    super.initState();
    focusNode.addListener(_onFocusChange);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeNavigation();
      _loadSearchHistory();
    });

    _pagingController = PagingController<int, PostModel>(
      getNextPageKey: (state) {
        if (state.items == null) return 1;
        final isLastPage = state.items!.length < _pageSize;
        if (isLastPage) return null;
        return (state.keys?.last ?? 0) + 1;
      },
      fetchPage: _fetch,
    );
  }

  static const _pageSize = 10;

  @override
  void dispose() {
    focusNode.removeListener(_onFocusChange);
    focusNode.dispose();
    _textController.dispose();
    _pagingController.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (!focusNode.hasFocus) setState(() {});
  }

  void _initializeNavigation() {
    if (mounted) {
      ref.read(navigationInfoProvider.notifier).settingNavigation(
            showPortal: true,
            showTopMenu: true,
            showBottomNavigation: true,
            topRightMenu: TopRightType.none,
            pageTitle: AppLocalizations.of(context).text_community_post_search,
          );
    }
  }

  void _executeSearch(String query) {
    if (!mounted) return;

    try {
      setState(() {
        _currentSearchQuery = query.isNotEmpty ? query : '';
      });
      _pagingController.refresh();
      if (query.isNotEmpty) _addToSearchHistory(query);
    } catch (e) {
      logger.w('Failed to execute search: $e');
    }
  }

  Future<List<PostModel>> _fetch(int pageKey) async {
    if (!mounted || _currentSearchQuery.isEmpty) return [];

    final currentArtist = ref.watch(
        communityStateInfoProvider.select((value) => value.currentArtist));

    if (currentArtist == null) return [];

    try {
      final newItems = await postsByQuery(
            ref,
            currentArtist.id,
            _currentSearchQuery,
            pageKey,
            10,
          ) ??
          [];

      if (!mounted) return [];
      return newItems;
    } catch (e, s) {
      logger.e('Error fetching data: $e', stackTrace: s);
      if (!mounted) return [];
      rethrow;
    }
  }

  Future<void> _loadSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _searchHistory = prefs.getStringList('search_history') ?? [];
      });
    } catch (e, s) {
      logger.e('Error loading search history: $e', stackTrace: s);
      rethrow;
    }
  }

  Future<void> _addToSearchHistory(String query) async {
    if (!_searchHistory.contains(query)) {
      setState(() {
        _searchHistory.insert(0, query);
        if (_searchHistory.length > 10) _searchHistory.removeLast();
      });
      await _saveSearchHistory();
    }
  }

  Future<void> _removeFromSearchHistory(String query) async {
    setState(() {
      _searchHistory.remove(query);
    });
    await _saveSearchHistory();
  }

  Future<void> _saveSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('search_history', _searchHistory);
    } catch (e, s) {
      logger.e('Error saving search history: $e', stackTrace: s);
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchBox(),
        Expanded(
          child: _currentSearchQuery.isEmpty
              ? _buildSearchHistory()
              : _buildSearchResults(),
        ),
      ],
    );
  }

  Widget _buildSearchBox() {
    return Container(
      padding: EdgeInsets.only(left: 16.w, right: 16.w, top: 23, bottom: 33),
      child: EnhancedSearchBox(
        hintText: AppLocalizations.of(context).text_community_board_search,
        onSearchChanged: (query) {
          if (mounted) {
            try {
              _executeSearch(query);
            } catch (e) {
              logger.w('Failed to execute search: $e');
            }
          }
        },
        controller: _textController,
        focusNode: focusNode,
        debounceTime: const Duration(milliseconds: 500),
        showClearButton: true,
      ),
    );
  }

  Widget _buildSearchResults() {
    return Column(
      children: [
        Expanded(
          child: PagingListener(
            controller: _pagingController,
            builder: (context, state, fetchNextPage) =>
                PagedListView<int, PostModel>(
              state: _pagingController.value,
              fetchNextPage: _pagingController.fetchNextPage,
              builderDelegate: PagedChildBuilderDelegate<PostModel>(
                itemBuilder: (context, post, index) {
                  if (index == 0) {
                    // 첫 번째 아이템 앞에 검색 결과 레이블 추가
                    return RepaintBoundary(
                      key: ValueKey('search_result_${post.postId}'),
                      child: Column(
                        children: [
                          _buildSearchResultLabel(),
                          const SizedBox(height: 24),
                          PostListItem(
                            post: post,
                            popupMenu: PostPopupMenu(
                                post: post,
                                context: context,
                                refreshFunction: ref.refresh),
                          ),
                        ],
                      ),
                    );
                  }
                  return RepaintBoundary(
                    key: ValueKey('post_${post.postId}'),
                    child: PostListItem(
                        post: post,
                        popupMenu: PostPopupMenu(
                            post: post,
                            context: context,
                            refreshFunction: ref.refresh)),
                  );
                },
                firstPageProgressIndicatorBuilder: (_) => const Center(
                  child: MediumPulseLoadingIndicator(),
                ),
                newPageProgressIndicatorBuilder: (_) => const Center(
                  child: MediumPulseLoadingIndicator(),
                ),
                noItemsFoundIndicatorBuilder: (_) => SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildNoResultsWidget(),
                      _buildSearchHistory(),
                    ],
                  ),
                ),
                noMoreItemsIndicatorBuilder: (_) => const SizedBox.shrink(),
                firstPageErrorIndicatorBuilder: (context) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                          AppLocalizations.of(context).common_text_search_error,
                          style:
                              getTextStyle(AppTypo.body16M, AppColors.grey400)),
                      ElevatedButton(
                        onPressed: () => _pagingController.refresh(),
                        child: Text(
                            AppLocalizations.of(context).common_retry_label),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResultLabel() {
    return Container(
      width: 100.w,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primary500,
        border: Border.all(
            color: AppColors.primary500, width: 1.w, style: BorderStyle.solid),
        borderRadius: BorderRadius.all(Radius.circular(16.r)),
      ),
      child: Text(AppLocalizations.of(context).common_text_search_result_label,
          style: getTextStyle(AppTypo.body14B, AppColors.grey00)),
    );
  }

  Widget _buildSearchHistory() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 24),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.primary500, width: 1),
            borderRadius: BorderRadius.all(Radius.circular(20.r)),
          ),
          child: Text(
              AppLocalizations.of(context).common_text_search_recent_label,
              style: getTextStyle(AppTypo.body14B, AppColors.primary500)),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: _searchHistory.map((item) => _buildChip(item)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildChip(String label) {
    return GestureDetector(
      onTap: () {
        _textController.text = label;
        _executeSearch(label);
      },
      child: Chip(
        label: Text(label,
            style: getTextStyle(AppTypo.caption12B, AppColors.grey500)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.5),
          side: BorderSide(color: AppColors.grey400, width: 1.w),
        ),
        backgroundColor: AppColors.grey00,
        deleteIcon: SvgPicture.asset(
          package: 'picnic_lib',
          'assets/icons/cancel_style=line.svg',
          width: 16,
          height: 16,
          colorFilter:
              const ColorFilter.mode(AppColors.grey400, BlendMode.srcIn),
        ),
        onDeleted: () => _removeFromSearchHistory(label),
      ),
    );
  }

  Widget _buildNoResultsWidget() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 56),
      child: Text(AppLocalizations.of(context).text_no_search_result,
          style: getTextStyle(AppTypo.body16M, AppColors.grey400)),
    );
  }
}

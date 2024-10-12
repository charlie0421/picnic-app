import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:picnic_app/components/common/comment/post_popup_menu.dart';
import 'package:picnic_app/components/common/common_search_box.dart';
import 'package:picnic_app/components/community/common/post_list_item.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/models/common/navigation.dart';
import 'package:picnic_app/models/community/post.dart';
import 'package:picnic_app/providers/community/post_provider.dart';
import 'package:picnic_app/providers/community_navigation_provider.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PostSearchPage extends ConsumerStatefulWidget {
  const PostSearchPage({super.key});

  @override
  ConsumerState<PostSearchPage> createState() => _PostSearchPageState();
}

class _PostSearchPageState extends ConsumerState<PostSearchPage> {
  final FocusNode focusNode = FocusNode();
  final TextEditingController _textController = TextEditingController();
  final PagingController<int, PostModel> _pagingController =
      PagingController(firstPageKey: 0);
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

    _pagingController.addPageRequestListener(_fetch);
  }

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
    ref.read(navigationInfoProvider.notifier).settingNavigation(
          showPortal: true,
          showTopMenu: true,
          showBottomNavigation: true,
          topRightMenu: TopRightType.none,
          pageTitle: S.of(context).text_community_post_search,
        );
  }

  void _executeSearch(String query) {
    logger.i('Executing search with query: $query');
    setState(() {
      _currentSearchQuery = query.isNotEmpty ? query : '';
    });
    _pagingController.refresh();
    if (query.isNotEmpty) _addToSearchHistory(query);
  }

  Future<void> _fetch(int pageKey) async {
    logger.i('Fetching data for page: $pageKey, query: $_currentSearchQuery');
    if (_currentSearchQuery.isEmpty) return;

    final communityNavigationInfo = ref.read(communityStateInfoProvider);

    try {
      final newItems = await postsByQuery(
            ref,
            communityNavigationInfo.currentArtist!.id,
            _currentSearchQuery,
            pageKey,
            10,
          ) ??
          [];

      logger.i('Fetched ${newItems.length} items');

      final isLastPage = newItems.length < 10;
      if (isLastPage) {
        _pagingController.appendLastPage(newItems);
      } else {
        _pagingController.appendPage(newItems, pageKey + 1);
      }
    } catch (e, s) {
      logger.e('Error fetching data: $e', stackTrace: s);
      _pagingController.error = e;
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
      padding: EdgeInsets.only(left: 16.cw, right: 16.cw, top: 23, bottom: 33),
      child: CommonSearchBox(
        focusNode: focusNode,
        textEditingController: _textController,
        hintText: S.of(context).text_community_board_search,
        onSubmitted: _executeSearch,
      ),
    );
  }

  Widget _buildSearchResults() {
    return Column(
      children: [
        Expanded(
          child: PagedListView<int, PostModel>(
            pagingController: _pagingController,
            builderDelegate: PagedChildBuilderDelegate<PostModel>(
              itemBuilder: (context, post, index) {
                if (index == 0) {
                  // 첫 번째 아이템 앞에 검색 결과 레이블 추가
                  return Column(
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
                  );
                }
                return PostListItem(
                    post: post,
                    popupMenu: PostPopupMenu(
                        post: post,
                        context: context,
                        refreshFunction: ref.refresh));
              },
              firstPageProgressIndicatorBuilder: (_) => const Center(
                child: CircularProgressIndicator(),
              ),
              newPageProgressIndicatorBuilder: (_) => const Center(
                child: CircularProgressIndicator(),
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
                    Text('검색 중 오류가 발생했습니다.',
                        style:
                            getTextStyle(AppTypo.body16M, AppColors.grey400)),
                    ElevatedButton(
                      onPressed: () => _pagingController.refresh(),
                      child: const Text('다시 시도'),
                    ),
                  ],
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
      width: 100.cw,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primary500,
        border: Border.all(
            color: AppColors.primary500, width: 1.cw, style: BorderStyle.solid),
        borderRadius: BorderRadius.all(Radius.circular(16.r)),
      ),
      child:
          Text('검색 결과', style: getTextStyle(AppTypo.body14B, AppColors.grey00)),
    );
  }

  Widget _buildSearchHistory() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 24),
          padding: EdgeInsets.symmetric(horizontal: 16.cw, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.primary500, width: 1),
            borderRadius: BorderRadius.all(Radius.circular(20.r)),
          ),
          child: Text('최근 검색어',
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
          side: BorderSide(color: AppColors.grey400, width: 1.cw),
        ),
        backgroundColor: AppColors.grey00,
        deleteIcon: SvgPicture.asset(
          'assets/icons/cancle_style=line.svg',
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
      padding: EdgeInsets.symmetric(horizontal: 16.cw, vertical: 56),
      child: Text(S.of(context).text_no_search_result,
          style: getTextStyle(AppTypo.body16M, AppColors.grey400)),
    );
  }
}

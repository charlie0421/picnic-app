import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:picnic_app/components/common/common_search_box.dart';
import 'package:picnic_app/components/common/picnic_cached_network_image.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/models/community/board.dart';
import 'package:picnic_app/pages/community/post_list_page.dart';
import 'package:picnic_app/providers/community/boards_provider.dart';
import 'package:picnic_app/providers/community_navigation_provider.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/i18n.dart';
import 'package:picnic_app/util/ui.dart';
import 'package:rxdart/rxdart.dart';

class BoardPage extends ConsumerStatefulWidget {
  const BoardPage({super.key});

  @override
  ConsumerState<BoardPage> createState() => _BoardPageState();
}

class _BoardPageState extends ConsumerState<BoardPage> {
  final FocusNode focusNode = FocusNode();
  final TextEditingController _textEditingController = TextEditingController();
  final _pagingController = PagingController<int, BoardModel>(firstPageKey: 0);
  final _searchSubject = BehaviorSubject<String>();

  @override
  initState() {
    super.initState();
    focusNode.addListener(() {
      if (!focusNode.hasFocus) {
        _textEditingController.clear();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(navigationInfoProvider.notifier).settingNavigation(
          showPortal: true, showTopMenu: false, showBottomNavigation: true);
    });
    _pagingController.addPageRequestListener(_fetch);
    _textEditingController.addListener(_onSearchQueryChange);
    _searchSubject
        .debounceTime(const Duration(milliseconds: 300))
        .listen((_) => _pagingController.refresh());
  }

  @override
  void dispose() {
    focusNode.dispose();
    _textEditingController.dispose();
    super.dispose();
  }

  void _onSearchQueryChange() {
    _searchSubject.add(_textEditingController.text);
  }

  Future<void> _fetch(int pageKey) async {
    try {
      final newItems = await boardsByArtistName(
              ref, _textEditingController.text, pageKey, 10) ??
          [];

      final isLastPage = newItems.length < 10;
      isLastPage
          ? _pagingController.appendLastPage(newItems)
          : _pagingController.appendPage(newItems, pageKey + 1);
    } catch (error) {
      _pagingController.error = error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.cw, vertical: 24),
          child: CommonSearchBox(
              focusNode: focusNode,
              textEditingController: _textEditingController,
              hintText: S.of(context).text_community_board_search),
        ),
        Expanded(
          child: PagedListView<int, BoardModel>(
            pagingController: _pagingController,
            builderDelegate: PagedChildBuilderDelegate<BoardModel>(
              itemBuilder: (context, BoardModel board, index) {
                return GestureDetector(
                  onTap: () {
                    ref
                        .read(communityStateInfoProvider.notifier)
                        .setCurrentBoardId(
                            board.board_id,
                            board.is_official
                                ? getLocaleTextFromJson(board.name)
                                : getLocaleTextFromJson(board.name));
                    ref
                        .read(communityStateInfoProvider.notifier)
                        .setCurrentArtistId(board.artist!.id,
                            getLocaleTextFromJson(board.artist!.name));
                    ref
                        .read(navigationInfoProvider.notifier)
                        .setCommunityCurrentPage(PostListPage(board.artist!.id,
                            getLocaleTextFromJson(board.artist!.name)));
                  },
                  child: Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.cw, vertical: 16),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20.r),
                          child: PicnicCachedNetworkImage(
                              imageUrl: board.artist!.image,
                              width: 40,
                              height: 40),
                        ),
                        SizedBox(width: 4.cw),
                        Text(getLocaleTextFromJson(board.artist!.name),
                            style: getTextStyle(
                                AppTypo.body16B, AppColors.grey900)),
                        SizedBox(width: 4.cw),
                        Text(
                          board.is_official
                              ? getLocaleTextFromJson(board.name)
                              : board.name['minor'],
                          style:
                              getTextStyle(AppTypo.body16M, AppColors.grey900),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

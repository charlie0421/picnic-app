import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:picnic_app/components/common/common_search_box.dart';
import 'package:picnic_app/components/common/no_item_container.dart';
import 'package:picnic_app/components/common/picnic_cached_network_image.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/models/community/board.dart';
import 'package:picnic_app/pages/community/post_list_page.dart';
import 'package:picnic_app/providers/community/boards_provider.dart';
import 'package:picnic_app/providers/community_navigation_provider.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/i18n.dart';
import 'package:picnic_app/util/logger.dart';
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
  final _pagingController =
      PagingController<int, List<BoardModel>>(firstPageKey: 0);
  final _searchSubject = BehaviorSubject<String>();

  @override
  void initState() {
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
    _searchSubject.close();
    _pagingController.dispose();
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

      final groupedBoards = _groupBoardsByArtist(newItems);

      final isLastPage = newItems.length < 10;
      if (isLastPage) {
        _pagingController.appendLastPage(groupedBoards);
      } else {
        _pagingController.appendPage(groupedBoards, pageKey + 1);
      }
    } catch (e, s) {
      logger.e(e, stackTrace: s);
      _pagingController.error = e;
      rethrow;
    }
  }

  List<List<BoardModel>> _groupBoardsByArtist(List<BoardModel> boards) {
    final map = <String, List<BoardModel>>{};
    for (var board in boards) {
      final artistId = board.artist!.id;
      if (!map.containsKey(artistId.toString())) {
        map[artistId.toString()] = [];
      }
      map[artistId.toString()]!.add(board);
    }
    return map.values.toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.cw, vertical: 12),
          child: CommonSearchBox(
              focusNode: focusNode,
              textEditingController: _textEditingController,
              hintText: S.of(context).text_community_board_search),
        ),
        Expanded(
          child: PagedListView<int, List<BoardModel>>(
            pagingController: _pagingController,
            builderDelegate: PagedChildBuilderDelegate<List<BoardModel>>(
              itemBuilder: (context, List<BoardModel> artistBoards, index) {
                return _buildArtistBoardGroup(artistBoards);
              },
              noItemsFoundIndicatorBuilder: (context) {
                return const NoItemContainer(
                  message: '검색결과가 없습니다.',
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildArtistBoardGroup(List<BoardModel> artistBoards) {
    final artist = artistBoards.first.artist!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.cw, vertical: 8),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16.r),
                child: PicnicCachedNetworkImage(
                    imageUrl: artist.image ?? '', width: 32, height: 32),
              ),
              SizedBox(width: 8.cw),
              Expanded(
                child: Text(
                  getLocaleTextFromJson(artist.name),
                  style: getTextStyle(AppTypo.body14B, AppColors.grey900),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.cw),
          child: Wrap(
            spacing: 8.cw,
            children:
                artistBoards.map((board) => _buildBoardChip(board)).toList(),
          ),
        ),
        const SizedBox(height: 8),
        const Divider(height: 1, thickness: .5, color: AppColors.grey300),
      ],
    );
  }

  Widget _buildBoardChip(BoardModel board) {
    return GestureDetector(
      onTap: () {
        ref.read(communityStateInfoProvider.notifier).setCurrentBoard(board);
        ref
            .read(communityStateInfoProvider.notifier)
            .setCurrentArtist(board.artist!);
        ref.read(navigationInfoProvider.notifier).setCommunityCurrentPage(
            PostListPage(
                board.artist!.id, getLocaleTextFromJson(board.artist!.name)));
      },
      child: Chip(
        label: Text(
          board.isOfficial
              ? getLocaleTextFromJson(board.name)
              : board.name['minor'],
          style: getTextStyle(AppTypo.caption12B,
              board.isOfficial ? AppColors.primary500 : AppColors.grey900),
        ),
        side: const BorderSide(color: AppColors.grey300, width: 1),
        backgroundColor: AppColors.grey00,
        padding: EdgeInsets.symmetric(horizontal: 8.cw, vertical: 4),
      ),
    );
  }
}

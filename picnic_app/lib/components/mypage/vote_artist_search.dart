import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:intl/intl.dart';
import 'package:overlay_loading_progress/overlay_loading_progress.dart';
import 'package:picnic_app/components/common/common_search_box.dart';
import 'package:picnic_app/components/common/picnic_cached_network_image.dart';
import 'package:picnic_app/components/error.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/dialogs/simple_dialog.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/models/vote/vote.dart';
import 'package:picnic_app/providers/mypage/bookmarked_artists_provider.dart';
import 'package:picnic_app/providers/mypage/vote_artist_list_provider.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/i18n.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shimmer/shimmer.dart';

class VoteArtistSearch extends ConsumerStatefulWidget {
  const VoteArtistSearch({super.key});

  @override
  ConsumerState createState() => _VoteMyArtistState();
}

class _VoteMyArtistState extends ConsumerState<VoteArtistSearch> {
  final _pagingController = PagingController<int, ArtistModel>(firstPageKey: 0);
  final _searchSubject = BehaviorSubject<String>();
  final _textEditingController = TextEditingController();
  final _focusNode = FocusNode();
  Key _listKey = UniqueKey();
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _pagingController.addPageRequestListener(_fetchPage);
    _scrollController = ScrollController();
    _textEditingController.addListener(_onSearchQueryChange);
    _searchSubject
        .debounceTime(const Duration(milliseconds: 300))
        .listen((_) => _pagingController.refresh());
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      final bookmarkedArtists =
          await ref.read(asyncBookmarkedArtistsProvider.future);
      final bookmarkedArtistIds = bookmarkedArtists.map((a) => a.id).toSet();
      final newItems =
          await ref.read(asyncVoteArtistListProvider.notifier).fetchArtists(
                page: pageKey,
                query: _textEditingController.text,
                language: Intl.getCurrentLocale(),
              );
      final filteredItems = newItems
          .where((artist) => !bookmarkedArtistIds.contains(artist.id))
          .toList();
      final isLastPage = filteredItems.length < 20;
      if (isLastPage) {
        _pagingController.appendLastPage(filteredItems);
      } else {
        _pagingController.appendPage(filteredItems, pageKey + 1);
      }
    } catch (error) {
      _pagingController.error = error;
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _textEditingController.dispose();
    _searchSubject.close();
    _pagingController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchQueryChange() {
    _searchSubject.add(_textEditingController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 57.w, vertical: 16),
          child: CommonSearchBox(
            focusNode: _focusNode,
            textEditingController: _textEditingController,
            hintText: S.of(context).text_hint_search,
          ),
        ),
        Expanded(child: _buildArtistList()),
      ],
    );
  }

  void _updateArtistBookmarkStatus(int artistId, bool isBookmarked) {
    final updatedItems = _pagingController.itemList?.map((artist) {
      if (artist.id == artistId) {
        return artist.copyWith(isBookmarked: isBookmarked);
      }
      return artist;
    }).toList();
    if (updatedItems != null) {
      _pagingController.itemList = updatedItems;
    }
    setState(() {});
  }

  Future<void> _updateBookmarkStatus(int artistId, bool isBookmarked) async {
    try {
      OverlayLoadingProgress.start(context,
          barrierDismissible: false, color: AppColors.primary500);
      final success = isBookmarked
          ? await ref
              .read(asyncVoteArtistListProvider.notifier)
              .unBookmarkArtist(
                artistId: artistId,
                bookmarkedArtistsRef:
                    ref.read(asyncBookmarkedArtistsProvider.notifier),
              )
          : await ref
              .read(asyncVoteArtistListProvider.notifier)
              .bookmarkArtist(artistId: artistId);

      if (!mounted) return; // 비동기 작업 후 위젯이 여전히 마운트되어 있는지 다시 확인

      if (success) {
        if (isBookmarked) {
          _updateArtistBookmarkStatus(artistId, false);
        } else {
          setState(() => _listKey = UniqueKey());
          _pagingController.refresh();
        }
        ref.refresh(asyncBookmarkedArtistsProvider);
      } else {
        showSimpleDialog(
          content: isBookmarked
              ? S.of(context).text_bookmark_failed
              : S.of(context).text_bookmark_over_5,
        );
      }
    } catch (e, s) {
      logger.e('북마크 상태 변경 중 오류 발생:', error: e, stackTrace: s);
    } finally {
      if (mounted) {
        // 로딩 progress를 멈추기 전에 위젯이 여전히 마운트되어 있는지 확인
        OverlayLoadingProgress.stop();
      }
    }
  }

  Widget _buildArtistList() {
    return Consumer(builder: (context, ref, child) {
      final artistsAsyncValue = ref.watch(asyncVoteArtistListProvider);
      final bookmarkedArtistsAsyncValue =
          ref.watch(asyncBookmarkedArtistsProvider);
      return artistsAsyncValue.when(
        data: (artists) {
          return bookmarkedArtistsAsyncValue.when(
            data: (bookmarkedArtists) {
              return CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          _buildArtistItem(bookmarkedArtists[index]),
                      childCount: bookmarkedArtists.length,
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.zero,
                    sliver: PagedSliverList<int, ArtistModel>(
                      key: _listKey,
                      pagingController: _pagingController,
                      builderDelegate: PagedChildBuilderDelegate<ArtistModel>(
                        itemBuilder: (context, item, index) =>
                            _buildArtistItem(item),
                        firstPageErrorIndicatorBuilder: (context) => ErrorView(
                          context,
                          error: _pagingController.error.toString(),
                          retryFunction: _pagingController.refresh,
                          stackTrace: _pagingController.error.stackTrace,
                        ),
                        firstPageProgressIndicatorBuilder: (context) =>
                            SizedBox(
                                height: 200, child: _buildShimmerLoading()),
                        noItemsFoundIndicatorBuilder: (context) =>
                            Center(child: Text(S.of(context).text_no_artist)),
                      ),
                    ),
                  ),
                ],
              );
            },
            loading: _buildShimmerLoading,
            error: (error, stack) =>
                ErrorView(context, error: error.toString(), stackTrace: stack),
          );
        },
        loading: _buildShimmerLoading,
        error: (error, s) =>
            ErrorView(context, error: error.toString(), stackTrace: s),
      );
    });
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      itemCount: 20, // 로딩 시 보여줄 아이템 수
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  title: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        width: 40,
                        height: 16,
                        color: Colors.white,
                      ),
                      Container(
                        width: 4,
                        height: 16,
                        color: Colors.transparent,
                      ),
                      Container(
                        width: 120,
                        height: 12,
                        color: Colors.white,
                      ),
                    ],
                  ),
                  trailing: Container(
                    width: 20,
                    height: 20,
                    color: Colors.white,
                  ),
                ),
                const Divider(height: 32, color: AppColors.grey200),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildArtistItem(ArtistModel item) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        children: [
          ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(48),
              child: PicnicCachedNetworkImage(
                width: 48,
                height: 48,
                imageUrl: 'artist/${item.id}/image.png',
              ),
            ),
            title: RichText(
              text: TextSpan(
                children: [
                  ..._buildHighlightedTextSpans(
                    getLocaleTextFromJson(item.name),
                    _textEditingController.text,
                    AppTypo.body16B,
                    AppColors.grey900,
                  ),
                  const TextSpan(text: ' '),
                  ..._buildHighlightedTextSpans(
                    getLocaleTextFromJson(item.artist_group.name),
                    _textEditingController.text,
                    AppTypo.caption12M,
                    AppColors.grey600,
                  ),
                ],
              ),
            ),
            trailing: GestureDetector(
              onTap: () =>
                  _updateBookmarkStatus(item.id, item.isBookmarked ?? false),
              child: SvgPicture.asset(
                'assets/icons/bookmark_style=fill.svg',
                colorFilter: ColorFilter.mode(
                  item.isBookmarked == true
                      ? AppColors.primary500
                      : AppColors.grey300,
                  BlendMode.srcIn,
                ),
                width: 20,
                height: 20,
              ),
            ),
          ),
          const Divider(height: 32, color: AppColors.grey200),
        ],
      ),
    );
  }

  List<TextSpan> _buildHighlightedTextSpans(
      String text, String query, AppTypo typo, Color color) {
    query = query.trim();
    if (query.isEmpty) {
      return [TextSpan(text: text, style: getTextStyle(typo, color))];
    }
    final spans = <TextSpan>[];
    final lowercaseText = text.toLowerCase();
    final lowercaseQuery = query.toLowerCase();
    int startIndex = 0;
    while (true) {
      final index = lowercaseText.indexOf(lowercaseQuery, startIndex);
      if (index == -1) {
        spans.add(TextSpan(
            text: text.substring(startIndex),
            style: getTextStyle(typo, color)));
        break;
      }
      if (index > startIndex) {
        spans.add(TextSpan(
            text: text.substring(startIndex, index),
            style: getTextStyle(typo, color)));
      }
      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style:
            getTextStyle(typo, color).copyWith(backgroundColor: Colors.yellow),
      ));
      startIndex = index + query.length;
    }
    return spans;
  }
}

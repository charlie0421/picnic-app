import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:intl/intl.dart';
import 'package:picnic_app/components/common/common_search_box.dart';
import 'package:picnic_app/components/common/picnic_cached_network_image.dart';
import 'package:picnic_app/components/error.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/models/vote/vote.dart';
import 'package:picnic_app/providers/mypage/vote_artist_list_provider.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/i18n.dart';
import 'package:picnic_app/util/ui.dart';
import 'package:rxdart/rxdart.dart';

class VoteArtistSearch extends ConsumerStatefulWidget {
  const VoteArtistSearch({super.key});

  @override
  ConsumerState createState() => _VoteMyArtistState();
}

class _VoteMyArtistState extends ConsumerState<VoteArtistSearch> {
  final PagingController<int, ArtistModel> _pagingController =
      PagingController(firstPageKey: 0);

  final _searchSubject = BehaviorSubject<String>();
  late TextEditingController _textEditingController;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });

    _focusNode = FocusNode();

    _textEditingController = TextEditingController();
    _textEditingController.addListener(_onSearchQueryChange);

    _searchSubject
        .debounceTime(const Duration(milliseconds: 300))
        .listen((query) {
      logger.i('search query: $query');
      _pagingController.refresh();
    });
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      final newItems =
          await ref.read(asyncVoteArtistListProvider.notifier).fetchArtists(
                page: pageKey,
                query: _textEditingController.text,
                language: Intl.getCurrentLocale(),
              );
      final isLastPage = newItems.length < 20;
      if (isLastPage) {
        _pagingController.appendLastPage(newItems);
      } else {
        _pagingController.appendPage(newItems, pageKey + 1);
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
          padding:
              EdgeInsets.only(left: 57.w, right: 57.w, top: 36, bottom: 16),
          child: CommonSearchBox(
              focusNode: _focusNode,
              textEditingController: _textEditingController,
              hintText: S.of(context).text_hint_search),
        ),
        Expanded(child: _buildArtistList()),
      ],
    );
  }

  Widget _buildArtistList() {
    return PagedListView<int, ArtistModel>(
      pagingController: _pagingController,
      builderDelegate: PagedChildBuilderDelegate<ArtistModel>(
        firstPageErrorIndicatorBuilder: (context) {
          return ErrorView(context,
              error: _pagingController.error.toString(),
              retryFunction: () => _pagingController.refresh(),
              stackTrace: _pagingController.error.stackTrace);
        },
        firstPageProgressIndicatorBuilder: (context) {
          return buildLoadingOverlay();
        },
        noItemsFoundIndicatorBuilder: (context) {
          return const Center(child: Text('No artists found'));
        },
        itemBuilder: (context, item, index) => Container(
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
                          AppTypo.BODY16B,
                          AppColors.Grey900),
                      const TextSpan(text: ' '),
                      ..._buildHighlightedTextSpans(
                          getLocaleTextFromJson(item.artist_group.name),
                          _textEditingController.text,
                          AppTypo.CAPTION12M,
                          AppColors.Grey600),
                    ],
                  ),
                ),
              ),
              const Divider(
                height: 32,
                color: AppColors.Grey200,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<TextSpan> _buildHighlightedTextSpans(
      String text, String query, AppTypo typo, Color color) {
    query = query.trim();
    if (query.isEmpty) {
      return [TextSpan(text: text, style: getTextStyle(typo, color))];
    }

    final List<TextSpan> spans = [];
    final lowercaseText = text.toLowerCase();
    final lowercaseQuery = query.toLowerCase();
    int startIndex = 0;

    while (true) {
      final int index = lowercaseText.indexOf(lowercaseQuery, startIndex);
      if (index == -1) {
        spans.add(TextSpan(
          text: text.substring(startIndex),
          style: getTextStyle(typo, color),
        ));
        break;
      }
      if (index > startIndex) {
        spans.add(TextSpan(
          text: text.substring(startIndex, index),
          style: getTextStyle(typo, color),
        ));
      }
      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: getTextStyle(typo, color).copyWith(
          backgroundColor: Colors.yellow,
        ),
      ));
      startIndex = index + query.length;
    }

    return spans;
  }
}

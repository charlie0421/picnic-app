import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:picnic_app/components/common/picnic_cached_network_image.dart';
import 'package:picnic_app/components/error.dart';
import 'package:picnic_app/models/pic/artist_vote.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/i18n.dart';
import 'package:picnic_app/util/ui.dart';

class VoteMyArtistSearch extends ConsumerStatefulWidget {
  const VoteMyArtistSearch({super.key});

  @override
  ConsumerState createState() => _VoteMyArtistState();
}

class _VoteMyArtistState extends ConsumerState<VoteMyArtistSearch> {
  final PagingController<int, ArtistMemberModel> _pagingController =
      PagingController(firstPageKey: 1);

  @override
  void initState() {
    super.initState();
    _pagingController.addPageRequestListener((pageKey) {
      _fetch(pageKey, 10, 'id', "DESC").then((newItems) {
        final isLastPage = newItems.length < 10;
        if (isLastPage) {
          _pagingController.appendLastPage(newItems);
        } else {
          _pagingController.appendPage(newItems, pageKey + 1);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return _buildArtistList();
  }

  PagedListView<int, ArtistMemberModel> _buildArtistList() {
    return PagedListView<int, ArtistMemberModel>(
      pagingController: _pagingController,
      builderDelegate: PagedChildBuilderDelegate<ArtistMemberModel>(
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
            return const Center(child: Text('No Items Found'));
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
                      title: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: getLocaleTextFromJson(item.name),
                              style: getTextStyle(
                                  AppTypo.BODY16B, AppColors.Grey900),
                            ),
                            const TextSpan(
                              text: ' ',
                              style: TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                            TextSpan(
                              text: getLocaleTextFromJson(
                                  item.artist_group!.name),
                              style: getTextStyle(
                                  AppTypo.CAPTION12M, AppColors.Grey600),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Divider(
                      height: 32,
                      color: AppColors.Grey200,
                    ),
                  ],
                ),
              )),
    );
  }

  Future<List<ArtistMemberModel>> _fetch(
      int page, int limit, String sort, String order) async {
    final response = await supabase.from('artist').select('*, artist_group(*)');

    return List<ArtistMemberModel>.from(
        response.map((e) => ArtistMemberModel.fromJson(e)));
  }
}

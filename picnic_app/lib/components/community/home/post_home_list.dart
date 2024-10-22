import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_app/components/common/comment/post_popup_menu.dart';
import 'package:picnic_app/components/community/common/post_list_item.dart';
import 'package:picnic_app/components/error.dart';
import 'package:picnic_app/dialogs/report_dialog.dart';
import 'package:picnic_app/models/community/post.dart';
import 'package:picnic_app/pages/community/post_list_page.dart';
import 'package:picnic_app/providers/community/post_provider.dart';
import 'package:picnic_app/providers/community_navigation_provider.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/i18n.dart';
import 'package:picnic_app/util/logger.dart';
import 'package:picnic_app/util/ui.dart';

class PostHomeList extends ConsumerStatefulWidget {
  const PostHomeList({super.key});

  @override
  _PostHomeListState createState() => _PostHomeListState();
}

class _PostHomeListState extends ConsumerState<PostHomeList> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final currentArtist = ref.watch(
        communityStateInfoProvider.select((value) => value.currentArtist));
    if (currentArtist == null) {
      return Container();
    }
    final postListAsyncValue =
        ref.watch(postsByArtistProvider(currentArtist.id, 3, 1));

    return Column(
      children: [
        postListAsyncValue.when(
          data: (data) => Column(
            children: [
              if (data == null || data.isEmpty)
                Container(
                  height: 160,
                  alignment: Alignment.center,
                  child: Text('게시글을 작성해 주세요!',
                      style:
                          getTextStyle(AppTypo.caption12B, AppColors.grey500)),
                )
              else
                Column(
                  children: [
                    const SizedBox(height: 19),
                    ...List.generate(
                      data.length,
                      (index) => PostListItem(
                        post: data[index],
                        popupMenu: PostPopupMenu(
                          post: data[index],
                          context: context,
                          openReportModal: (String title, PostModel post) {
                            try {
                              showDialog(
                                context: context,
                                barrierDismissible: true,
                                builder: (BuildContext context) {
                                  return ReportDialog(
                                      title: title, type: ReportType.post, target: post);
                                },
                              ).then((value) {
                                logger.d('ReportDialog result: $value');
                                if (value != null) {
                                  ref.invalidate(postsByArtistProvider(currentArtist.id, 3, 1));

                                }
                              });
                            } catch (e, s) {
                              logger.e('Error: $e, StackTrace: $s');
                            }
                          }
                          ,
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: AppColors.primary500,
                  backgroundColor: AppColors.grey00,
                  textStyle: getTextStyle(AppTypo.body14B),
                  padding:
                      EdgeInsets.symmetric(horizontal: 20.cw, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side:
                        const BorderSide(color: AppColors.primary500, width: 1),
                  ),
                ),
                onPressed: () {
                  ref
                      .read(navigationInfoProvider.notifier)
                      .setCommunityCurrentPage(PostListPage(currentArtist.id,
                          getLocaleTextFromJson(currentArtist.name)));
                },
                child: Text('My Artist 게시판 보기',
                    style: getTextStyle(AppTypo.body14B, AppColors.primary500)),
              ),
            ],
          ),
          error: (err, stack) =>
              ErrorView(context, error: err, stackTrace: stack),
          loading: () => buildLoadingOverlay(),
        ),
      ],
    );
  }

}

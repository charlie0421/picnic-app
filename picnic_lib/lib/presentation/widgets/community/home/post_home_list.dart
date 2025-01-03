import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/presentation/common/comment/post_popup_menu.dart';
import 'package:picnic_lib/presentation/widgets/community/common/post_list_item.dart';
import 'package:picnic_lib/presentation/widgets/error.dart';
import 'package:picnic_lib/presentation/dialogs/report_dialog.dart';
import 'package:picnic_lib/generated/l10n.dart';
import 'package:picnic_lib/data/models/community/post.dart';
import 'package:picnic_lib/presentation/pages/community/post_list_page.dart';
import 'package:picnic_lib/presentation/providers/community/post_provider.dart';
import 'package:picnic_lib/presentation/providers/community_navigation_provider.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:picnic_lib/core/utils/i18n.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/ui.dart';

class PostHomeList extends ConsumerStatefulWidget {
  const PostHomeList({super.key});

  @override
  ConsumerState<PostHomeList> createState() => _PostHomeListState();
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
                  child: Text(S.of(context).post_write_post_recommend_write,
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
                          deletePost: (PostModel post) async {
                            await deletePost(ref, post.postId);
                            ref.invalidate(
                                postsByArtistProvider(currentArtist.id, 3, 1));
                          },
                          openReportModal: (String title, PostModel post) {
                            try {
                              showDialog(
                                context: context,
                                barrierDismissible: true,
                                builder: (BuildContext context) {
                                  return ReportDialog(
                                      postId: post.postId,
                                      title: title,
                                      type: ReportType.post,
                                      target: post);
                                },
                              ).then((value) {
                                logger.d('ReportDialog result: $value');
                                if (value != null) {
                                  ref.invalidate(postsByArtistProvider(
                                      currentArtist.id, 3, 1));
                                }
                              });
                            } catch (e, s) {
                              logger.e('Error: $e, StackTrace: $s');
                            }
                          },
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
                child: Text(S.of(context).post_go_to_boards,
                    style: getTextStyle(AppTypo.body14B, AppColors.primary500)),
              ),
            ],
          ),
          error: (err, stack) =>
              buildErrorView(context, error: err, stackTrace: stack),
          loading: () => buildLoadingOverlay(),
        ),
      ],
    );
  }
}

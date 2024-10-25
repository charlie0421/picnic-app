import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_app/components/common/comment/post_popup_menu.dart';
import 'package:picnic_app/components/community/common/post_list_item.dart';
import 'package:picnic_app/components/error.dart';
import 'package:picnic_app/dialogs/report_dialog.dart';
import 'package:picnic_app/models/community/post.dart';
import 'package:picnic_app/pages/community/post_write_page.dart';
import 'package:picnic_app/providers/community/post_provider.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/logger.dart';
import 'package:picnic_app/util/ui.dart';

enum PostListType { artist, board }

class PostList extends ConsumerStatefulWidget {
  const PostList(this.type, this.id, {super.key});

  final Object id;
  final PostListType type;

  @override
  ConsumerState<PostList> createState() => _PostListState();
}

class _PostListState extends ConsumerState<PostList> {
  @override
  Widget build(BuildContext context) {
    final postListAsyncValue = widget.type == PostListType.artist
        ? ref.watch(postsByArtistProvider(widget.id as int, 10, 1))
        : ref.watch(postsByBoardProvider(widget.id as String, 10, 1));

    return postListAsyncValue.when(
      data: (data) => data == null || data.isEmpty
          ? Container(
              height: 200,
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  const SizedBox(height: 80),
                  Text('게시글을 작성해 주세요!',
                      style:
                          getTextStyle(AppTypo.caption12B, AppColors.grey500)),
                  const SizedBox(height: 54),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        foregroundColor: AppColors.primary500,
                        backgroundColor: AppColors.grey00,
                        textStyle: getTextStyle(AppTypo.body14B),
                        padding: EdgeInsets.symmetric(
                            horizontal: 20.cw, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: const BorderSide(
                            color: AppColors.primary500,
                            width: 1,
                          ),
                        ),
                      ),
                      onPressed: () {
                        ref
                            .read(navigationInfoProvider.notifier)
                            .setCurrentPage(
                              const PostWritePage(),
                            );
                      },
                      child: Text('게시글 작성하기',
                          style: getTextStyle(
                              AppTypo.body14B, AppColors.primary500)))
                ],
              ))
          : ListView.builder(
              itemCount: data.length,
              itemBuilder: (context, index) => PostListItem(
                post: data[index],
                popupMenu: PostPopupMenu(
                  post: data[index],
                  context: context,
                  deletePost: () async {
                    await deletePost(ref, data[index].postId);
                    try {
                      if (widget.type == PostListType.artist) {
                        ref.invalidate(
                            postsByArtistProvider(widget.id as int, 10, 1));
                      } else {
                        ref.invalidate(
                            postsByBoardProvider(widget.id as String, 10, 1));
                      }
                    } catch (e, s) {
                      logger.e('Error: $e, StackTrace: $s');
                    }
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
                          if (widget.type == PostListType.artist) {
                            ref.invalidate(
                                postsByArtistProvider(widget.id as int, 10, 1));
                          } else {
                            ref.invalidate(postsByBoardProvider(
                                widget.id as String, 10, 1));
                          }
                        }
                      });
                    } catch (e, s) {
                      logger.e('Error: $e, StackTrace: $s');
                    }
                  },
                ),
              ),
            ),
      error: (err, stack) => ErrorView(context, error: err, stackTrace: stack),
      loading: () => buildLoadingOverlay(),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/ui.dart';
import 'package:picnic_lib/data/models/community/post.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/common/comment/post_popup_menu.dart';
import 'package:picnic_lib/presentation/dialogs/fortune_dialog.dart';
import 'package:picnic_lib/presentation/dialogs/report_dialog.dart';
import 'package:picnic_lib/presentation/dialogs/require_login_dialog.dart';
import 'package:picnic_lib/presentation/dialogs/simple_dialog.dart';
import 'package:picnic_lib/presentation/pages/community/compatibility_list_page.dart';
import 'package:picnic_lib/presentation/pages/community/post_write_page.dart';
import 'package:picnic_lib/presentation/providers/community/post_provider.dart';
import 'package:picnic_lib/presentation/providers/community_navigation_provider.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/widgets/community/common/post_list_item.dart';
import 'package:picnic_lib/presentation/widgets/error.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:picnic_lib/ui/style.dart';

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
    try {
      final navigationInfoNotifier = ref.read(navigationInfoProvider.notifier);
      final postListAsyncValue = widget.type == PostListType.artist
          ? ref.watch(postsByArtistProvider(widget.id as int, 10, 1))
          : ref.watch(postsByBoardProvider(widget.id as String, 10, 1));

      final currentArtist = ref.watch(
          communityStateInfoProvider.select((value) => value.currentArtist));

      return Column(
        children: [
          InkWell(
            onTap: () async {
              if (!isSupabaseLoggedSafely) {
                showRequireLoginDialog();
                return;
              }

              if (currentArtist == null) {
                return;
              }

              final fortune = await supabase
                  .from("fortune_telling")
                  .select('*, artist(*)')
                  .eq('artist_id', currentArtist.id.toInt())
                  .maybeSingle();

              if (fortune == null) {
                showSimpleDialog(
                  content: '아직 토정비결이 없습니다.',
                  onOk: () {
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                );
                return;
              }

              showFortuneDialog(currentArtist.id.toInt(), 2025);
            },
            child: Container(
              height: 40,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              alignment: Alignment.centerLeft,
              child: Text(AppLocalizations.of(context).fortune_button_title,
                  style: getTextStyle(AppTypo.body14B, AppColors.primary500)),
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: AppColors.grey300,
          ),
          InkWell(
            onTap: () {
              if (isSupabaseLoggedSafely) {
                navigationInfoNotifier.setCommunityCurrentPage(
                    CompatibilityListPage(artistId: currentArtist?.id));
              } else {
                showRequireLoginDialog();
              }
            },
            child: Container(
              height: 40,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              alignment: Alignment.centerLeft,
              child: Text(AppLocalizations.of(context).fortune_with_me,
                  style: getTextStyle(AppTypo.body14B, AppColors.primary500)),
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: AppColors.grey300,
          ),
          Expanded(
            child: postListAsyncValue.when(
              data: (data) {
                return data == null || data.isEmpty
                    ? Container(
                        height: 200,
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            const SizedBox(height: 80),
                            Text(
                                AppLocalizations.of(context)
                                    .post_write_post_recommend_write,
                                style: getTextStyle(
                                    AppTypo.caption12B, AppColors.grey500)),
                            const SizedBox(height: 54),
                            ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: AppColors.primary500,
                                  backgroundColor: AppColors.grey00,
                                  textStyle: getTextStyle(AppTypo.body14B),
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 20.w, vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                    side: BorderSide(
                                      color: AppColors.primary500,
                                      width: 1,
                                    ),
                                  ),
                                ),
                                onPressed: () {
                                  if (!isSupabaseLoggedSafely) {
                                    showRequireLoginDialog();
                                    return;
                                  }
                                  ref
                                      .read(navigationInfoProvider.notifier)
                                      .setCommunityCurrentPage(
                                        const PostWritePage(),
                                      );
                                },
                                child: Text(
                                    AppLocalizations.of(context)
                                        .post_write_board_post,
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
                            deletePost: (PostModel post) async {
                              await deletePost(ref, post.postId);
                              try {
                                if (widget.type == PostListType.artist) {
                                  ref.invalidate(postsByArtistProvider(
                                      widget.id as int, 10, 1));
                                } else {
                                  ref.invalidate(postsByBoardProvider(
                                      widget.id as String, 10, 1));
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
                                      ref.invalidate(postsByArtistProvider(
                                          widget.id as int, 10, 1));
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
                      );
              },
              error: (err, stack) =>
                  buildErrorView(context, error: err, stackTrace: stack),
              loading: () => buildLoadingOverlay(),
            ),
          ),
        ],
      );
    } catch (e, s) {
      logger.e('Error: $e', error: e, stackTrace: s);
      return Container();
    }
  }
}

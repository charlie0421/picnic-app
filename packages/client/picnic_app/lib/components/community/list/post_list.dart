import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_app/components/common/comment/post_popup_menu.dart';
import 'package:picnic_app/components/community/common/post_list_item.dart';
import 'package:picnic_app/components/error.dart';
import 'package:picnic_app/dialogs/fortune_dialog.dart';
import 'package:picnic_app/dialogs/report_dialog.dart';
import 'package:picnic_app/dialogs/require_login_dialog.dart';
import 'package:picnic_app/dialogs/simple_dialog.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/models/community/fortune.dart';
import 'package:picnic_app/models/community/post.dart';
import 'package:picnic_app/pages/community/compatibility_list_page.dart';
import 'package:picnic_app/pages/community/post_write_page.dart';
import 'package:picnic_app/providers/community/post_provider.dart';
import 'package:picnic_app/providers/community_navigation_provider.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/providers/user_info_provider.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/i18n.dart';
import 'package:picnic_app/util/logger.dart';
import 'package:picnic_app/util/ui.dart';
import 'package:supabase_extensions/supabase_extensions.dart';

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
    final navigationInfoNotifier = ref.read(navigationInfoProvider.notifier);
    final postListAsyncValue = widget.type == PostListType.artist
        ? ref.watch(postsByArtistProvider(widget.id as int, 10, 1))
        : ref.watch(postsByBoardProvider(widget.id as String, 10, 1));
    final isAdmin =
        ref.watch(userInfoProvider.select((value) => value.value?.isAdmin));

    final currentArtist = ref.watch(
        communityStateInfoProvider.select((value) => value.currentArtist));

    return Column(
      children: [
        if (isAdmin ?? false) ...[
          GestureDetector(
            onTap: () async {
              if (!supabase.isLogged) {
                showRequireLoginDialog();
                return;
              }

              final fortune = await supabase
                  .from("fortune_telling")
                  .select('*, artist(*)')
                  .eq('artist_id', widget.id)
                  .maybeSingle();

              if (fortune == null) {
                showSimpleDialog(
                  content: '아직 토정비결이 없습니다.',
                  onOk: () {
                    Navigator.of(context).pop();
                  },
                );
                return;
              }

              final fortuneModel = FortuneModel.fromJson(fortune);
              logger.d(fortuneModel);

              showFortuneDialog(widget.id as int, 2025);
            },
            child: Container(
              height: 40,
              padding: EdgeInsets.symmetric(horizontal: 16.cw),
              alignment: Alignment.centerLeft,
              child: Text(S.of(context).fortune_button_title,
                  style: getTextStyle(AppTypo.body14B, AppColors.primary500)),
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: AppColors.grey300,
          ),
          GestureDetector(
            onTap: () {
              if (supabase.isLogged) {
                navigationInfoNotifier.setCurrentPage(
                    CompatibilityHistoryPage(artistId: currentArtist?.id));
              } else {
                showRequireLoginDialog();
              }
            },
            child: Container(
              height: 40,
              padding: EdgeInsets.symmetric(horizontal: 16.cw),
              alignment: Alignment.centerLeft,
              child: Text(
                  '${getLocaleTextFromJson(currentArtist!.name)}와 나의 궁합 맞추기',
                  style: getTextStyle(AppTypo.body14B, AppColors.primary500)),
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: AppColors.grey300,
          ),
        ],
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
                          Text(S.of(context).post_write_post_recommend_write,
                              style: getTextStyle(
                                  AppTypo.caption12B, AppColors.grey500)),
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
                                if (!supabase.isLogged) {
                                  showRequireLoginDialog();
                                  return;
                                }
                                ref
                                    .read(navigationInfoProvider.notifier)
                                    .setCurrentPage(
                                      const PostWritePage(),
                                    );
                              },
                              child: Text(S.of(context).post_write_board_post,
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
                ErrorView(context, error: err, stackTrace: stack),
            loading: () => buildLoadingOverlay(),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_app/components/community/post_list_item.dart';
import 'package:picnic_app/components/error.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/models/community/post.dart';
import 'package:picnic_app/pages/community/post_write_page.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/ui.dart';

class PostListPage extends ConsumerStatefulWidget {
  const PostListPage(this.boardId, {super.key});
  final pageName = 'PostListPage';
  final String boardId;
  @override
  ConsumerState<PostListPage> createState() => _PostListPageState();
}

class _PostListPageState extends ConsumerState<PostListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(navigationInfoProvider.notifier)
          .settingNavigation(showPortal: true, showBottomNavigation: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final postListAsyncValue = ref.watch(postListProvider(widget.boardId));
    logger.i('postListAsyncValue: $postListAsyncValue');

    return Column(
      children: [
        postListAsyncValue.when(
          data: (data) => data == null || data.isEmpty
              ? Container(
                  height: 200,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      const SizedBox(height: 80),
                      Text('게시글을 작성해 주세요!',
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
                                  PostWritePage(
                                      boardId: widget.boardId.toString()),
                                );
                          },
                          child: Text('게시글 작성하기',
                              style: getTextStyle(
                                  AppTypo.body14B, AppColors.primary500)))
                    ],
                  ))
              : SizedBox(
                  height: 288,
                  child: Column(children: [
                    ...List.generate(data.length,
                        (index) => PostListItem(post: data[index])),
                  ]),
                ),
          error: (err, stack) =>
              ErrorView(context, error: err, stackTrace: stack),
          loading: () => buildLoadingOverlay(),
        ),
      ],
    );
  }
}

final postListProvider = FutureProvider.family((ref, String boardId) async {
  try {
    logger.d('Fetching posts for boardId: $boardId');
    final response = await supabase
        .schema('community')
        .from('posts')
        .select('*, boards!inner(*), user_profile!inner(*)')
        .eq('boards.board_id', boardId);
    logger.d('response: $response');
    return response.map((data) => PostModel.fromJson(data)).toList();
  } catch (e, s) {
    logger.e('Error fetching posts:', error: e, stackTrace: s);
    return Future.error(e);
  }
});

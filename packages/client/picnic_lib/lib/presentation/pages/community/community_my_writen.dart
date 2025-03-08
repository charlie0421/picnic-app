import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:picnic_lib/data/models/common/navigation.dart';
import 'package:picnic_lib/data/models/community/post.dart';
import 'package:picnic_lib/generated/l10n.dart';
import 'package:picnic_lib/presentation/common/comment/post_popup_menu.dart';
import 'package:picnic_lib/presentation/common/no_item_container.dart';
import 'package:picnic_lib/presentation/providers/community/post_provider.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/widgets/community/common/post_list_item.dart';
import 'package:picnic_lib/supabase_options.dart';

class CommunityMyWriten extends ConsumerStatefulWidget {
  const CommunityMyWriten({super.key});

  @override
  ConsumerState<CommunityMyWriten> createState() => _CommunityMyWritenState();
}

class _CommunityMyWritenState extends ConsumerState<CommunityMyWriten>
    with SingleTickerProviderStateMixin {
  late final PagingController<int, PostModel> _pagingController =
      PagingController(firstPageKey: 1);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(navigationInfoProvider.notifier).settingNavigation(
          showPortal: true,
          showTopMenu: true,
          topRightMenu: TopRightType.none,
          showBottomNavigation: false,
          pageTitle: S.of(context).post_my_written_post);
    });

    _pagingController.addPageRequestListener((pageKey) async {
      final newItems =
          await postsByUser(pageKey, supabase.auth.currentUser!.id, 10, 1);
      final isLastPage = newItems.length < 10;
      if (isLastPage) {
        _pagingController.appendLastPage(newItems);
      } else {
        final nextPageKey = pageKey + newItems.length;
        _pagingController.appendPage(newItems, nextPageKey);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PagedListView<int, PostModel>(
        pagingController: _pagingController,
        builderDelegate: PagedChildBuilderDelegate<PostModel>(
          itemBuilder: (context, item, index) {
            return PostListItem(
              post: item,
              popupMenu: PostPopupMenu(
                  post: item,
                  context: context,
                  deletePost: (PostModel post) async {
                    await deletePost(ref, post.postId);
                    _pagingController.refresh();
                  },
                  refreshFunction: () => _pagingController.refresh()),
            );
          },
          noItemsFoundIndicatorBuilder: (context) => const NoItemContainer(),
        ));
  }
}

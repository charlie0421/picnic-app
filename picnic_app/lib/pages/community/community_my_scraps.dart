import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:picnic_app/components/common/comment/my_scrap_popup_menu.dart';
import 'package:picnic_app/components/community/common/post_list_item.dart';
import 'package:picnic_app/models/common/navigation.dart';
import 'package:picnic_app/models/community/post_scrap.dart';
import 'package:picnic_app/providers/community/post_provider.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/supabase_options.dart';

class CommunityMyScraps extends ConsumerStatefulWidget {
  const CommunityMyScraps({super.key});

  @override
  ConsumerState<CommunityMyScraps> createState() => _CommunityMyScrapsState();
}

class _CommunityMyScrapsState extends ConsumerState<CommunityMyScraps>
    with SingleTickerProviderStateMixin {
  late final PagingController<int, PostScrapModel> _pagingController =
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
          pageTitle: '내 스크랩');
    });

    _pagingController.addPageRequestListener((pageKey) async {
      final newItems = await postsScrapedByUser(
          pageKey, supabase.auth.currentUser!.id, 10, 1);
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
    return PagedListView<int, PostScrapModel>(
        pagingController: _pagingController,
        builderDelegate: PagedChildBuilderDelegate<PostScrapModel>(
            itemBuilder: (context, item, index) {
          return PostListItem(
            post: item.post!,
            popupMenu: MyScrapPopupMenu(
                post: item.post!,
                context: context,
                refreshFunction: () {
                  _pagingController.refresh();
                  return Future.value();
                }),
          );
        }));
  }
}

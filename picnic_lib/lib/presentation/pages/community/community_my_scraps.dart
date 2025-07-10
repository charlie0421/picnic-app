import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:picnic_lib/data/models/common/navigation.dart';
import 'package:picnic_lib/data/models/community/post_scrap.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/common/comment/my_scrap_popup_menu.dart';
import 'package:picnic_lib/presentation/common/no_item_container.dart';
import 'package:picnic_lib/presentation/providers/community/post_provider.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/widgets/community/common/post_list_item.dart';
import 'package:picnic_lib/supabase_options.dart';

class CommunityMyScraps extends ConsumerStatefulWidget {
  const CommunityMyScraps({super.key});

  @override
  ConsumerState<CommunityMyScraps> createState() => _CommunityMyScrapsState();
}

class _CommunityMyScrapsState extends ConsumerState<CommunityMyScraps>
    with SingleTickerProviderStateMixin {
  late final PagingController<int, PostScrapModel> _pagingController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(navigationInfoProvider.notifier).settingNavigation(
          showPortal: true,
          showTopMenu: true,
          topRightMenu: TopRightType.none,
          showBottomNavigation: false,
          pageTitle: AppLocalizations.of(context).post_my_written_scrap);
    });

    _pagingController = PagingController<int, PostScrapModel>(
      getNextPageKey: (state) {
        if (state.items == null) return 1;
        final isLastPage = state.items!.length < _pageSize;
        if (isLastPage) return null;
        return (state.keys?.last ?? 0) + 1;
      },
      fetchPage: _fetchPage,
    );
  }

  static const _pageSize = 20;

  Future<List<PostScrapModel>> _fetchPage(int pageKey) async {
    final newItems =
        await postsScrapedByUser(pageKey, supabase.auth.currentUser!.id, 10, 1);
    return newItems;
  }

  @override
  Widget build(BuildContext context) {
    return PagingListener(
      controller: _pagingController,
      builder: (context, state, fetchNextPage) =>
          PagedListView<int, PostScrapModel>(
        state: _pagingController.value,
        fetchNextPage: _pagingController.fetchNextPage,
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
          },
          noItemsFoundIndicatorBuilder: (context) => const NoItemContainer(),
        ),
      ),
    );
  }
}

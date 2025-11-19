import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:picnic_lib/data/models/common/navigation.dart';
import 'package:picnic_lib/data/models/community/post.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/core/navigation/route_aware_mixin.dart';
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
    with SingleTickerProviderStateMixin<CommunityMyWriten>, RouteAwareStateMixin<CommunityMyWriten> {
  late final PagingController<int, PostModel> _pagingController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateNavigation();
    });

    _pagingController = PagingController<int, PostModel>(
      getNextPageKey: (state) {
        if (state.items == null) return 1;
        final isLastPage = state.items!.length < _pageSize;
        if (isLastPage) return null;
        return (state.keys?.last ?? 0) + 1;
      },
      fetchPage: _fetchPage,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateNavigation();
  }

  @override
  void onRoutePopNext() {
    super.onRoutePopNext();
    _updateNavigation();
  }

  static const _pageSize = 20;

  Future<List<PostModel>> _fetchPage(int pageKey) async {
    final newItems =
        await postsByUser(pageKey, supabase.auth.currentUser!.id, 10, 1);
    return newItems;
  }

  @override
  Widget build(BuildContext context) {
    return PagingListener(
      controller: _pagingController,
      builder: (context, state, fetchNextPage) => PagedListView<int, PostModel>(
          state: _pagingController.value,
          fetchNextPage: _pagingController.fetchNextPage,
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
          )),
    );
  }

  void _updateNavigation() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(navigationInfoProvider.notifier).settingNavigation(
          showPortal: true,
          showTopMenu: true,
          topRightMenu: TopRightType.none,
          showBottomNavigation: false,
          pageTitle: AppLocalizations.of(context).post_my_written_post);
    });
  }
}

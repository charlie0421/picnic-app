import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:picnic_app/components/error.dart';
import 'package:picnic_app/components/vote/media/video_list_item.dart';
import 'package:picnic_app/models/vote/video_info.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:picnic_app/util/logger.dart';

class VoteMediaListPage extends ConsumerStatefulWidget {
  final String pageName = 'page_title_vote_gather';

  const VoteMediaListPage({super.key});

  @override
  ConsumerState<VoteMediaListPage> createState() => _VoteMediaListPageState();
}

class _VoteMediaListPageState extends ConsumerState<VoteMediaListPage> {
  static const _pageSize = 10;

  final PagingController<int, VideoInfo> _pagingController =
      PagingController(firstPageKey: 1);

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(navigationInfoProvider.notifier).settingNavigation(
          showPortal: true, showTopMenu: true, showBottomNavigation: true);
    });
    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PagedListView<int, VideoInfo>(
      pagingController: _pagingController,
      builderDelegate: PagedChildBuilderDelegate<VideoInfo>(
        itemBuilder: (context, item, index) => VideoListItem(
          item: item,
          onTap: () {},
        ),
        firstPageErrorIndicatorBuilder: (context) {
          return SliverToBoxAdapter(
            child: buildErrorView(
              context,
              error: _pagingController.error.toString(),
              retryFunction: () => _pagingController.refresh(),
              stackTrace: _pagingController.error is Error
                  ? (_pagingController.error as Error).stackTrace
                  : StackTrace.current,
            ),
          );
        },
      ),
    );
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      final response = await supabase
          .from("media")
          .select()
          .order('id', ascending: false)
          .range((pageKey - 1) * _pageSize, pageKey * _pageSize - 1);

      final newItems = response.map((e) => VideoInfo.fromJson(e)).toList();
      final isLastPage = newItems.length < _pageSize;
      if (isLastPage) {
        _pagingController.appendLastPage(newItems);
      } else {
        final nextPageKey = pageKey + newItems.length;
        _pagingController.appendPage(newItems, nextPageKey);
      }
    } catch (e, s) {
      logger.e('error', error: e, stackTrace: s);
      _pagingController.error = e;
      rethrow;
    }
  }
}

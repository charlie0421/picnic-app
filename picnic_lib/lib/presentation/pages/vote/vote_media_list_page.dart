import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/data/models/vote/video_info.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/common/no_item_container.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/widgets/error.dart';
import 'package:picnic_lib/presentation/widgets/vote/media/video_list_item.dart';
import 'package:picnic_lib/presentation/widgets/vote/media/video_list_item_skeleton.dart';
import 'package:picnic_lib/presentation/widgets/ui/pulse_loading_indicator.dart';
import 'package:picnic_lib/supabase_options.dart';

class VoteMediaListPage extends ConsumerStatefulWidget {
  final String pageName = 'page_title_vote_gather';

  const VoteMediaListPage({super.key});

  @override
  ConsumerState<VoteMediaListPage> createState() => _VoteMediaListPageState();
}

class _VoteMediaListPageState extends ConsumerState<VoteMediaListPage> {
  static const _pageSize = 10;
  late final PagingController<int, VideoInfo> _pagingController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(navigationInfoProvider.notifier).settingNavigation(
            showPortal: true,
            showTopMenu: true,
            showMyPoint: false,
            showBottomNavigation: true,
            pageTitle: AppLocalizations.of(context).nav_media,
          );
    });
    _pagingController = PagingController<int, VideoInfo>(
      getNextPageKey: (state) {
        if (state.items == null) return 1;
        final isLastPage = state.items!.length < _pageSize;
        if (isLastPage) return null;
        return (state.keys?.last ?? 0) + 1;
      },
      fetchPage: _fetch,
    );
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }

  // 비디오 ID에서 썸네일 URL 생성
  String _getThumbnailUrl(String videoId) {
    return 'https://img.youtube.com/vi/$videoId/maxresdefault.jpg';
  }

  // 기본 채널 정보 반환
  Map<String, String> _getDefaultChannelInfo() {
    return {
      'channelTitle': '피크닠! - Picnic!',
      'channelId': '@Picnic_official',
      'channelThumbnail':
          'https://yt3.googleusercontent.com/g5g-oUMkvOCzQS4cCsLGGR9s5dRngFqlj93cznJiw_HHAwZ-U_opeZokZb_2MHYUBKeb0IvmCrs=s160-c-k-c0x00ffffff-no-rj',
    };
  }

  Future<List<VideoInfo>> _fetch(int pageKey) async {
    try {
      final response = await supabase
          .from("media")
          .select()
          .filter('deleted_at', 'is', null)
          .order('id', ascending: false)
          .range((pageKey - 1) * _pageSize, pageKey * _pageSize - 1);

      final newItems = response.map((data) {
        final videoId = data['video_id']?.toString() ?? '';
        final channelInfo = _getDefaultChannelInfo();

        return VideoInfo(
          id: data['id'] as int,
          videoId: videoId,
          videoUrl: data['video_url']?.toString() ?? '',
          title: Map<String, String>.from(data['title'] as Map),
          thumbnailUrl: _getThumbnailUrl(videoId),
          createdAt: data['created_at'] != null
              ? DateTime.parse(data['created_at'].toString())
              : null,
          channelTitle: channelInfo['channelTitle']!,
          channelId: channelInfo['channelId']!,
          channelThumbnail: channelInfo['channelThumbnail']!,
        );
      }).toList();

      return newItems;
    } catch (e, s) {
      logger.e('Error fetching page', error: e, stackTrace: s);
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        _pagingController.refresh();
      },
      child: PagingListener(
        controller: _pagingController,
        builder: (context, state, fetchNextPage) =>
            PagedListView<int, VideoInfo>(
          state: _pagingController.value,
          fetchNextPage: _pagingController.fetchNextPage,
          builderDelegate: PagedChildBuilderDelegate<VideoInfo>(
            itemBuilder: (context, item, index) => VideoListItem(
              videoId: item.videoId,
              title: item.title,
              thumbnailUrl: item.thumbnailUrl,
              channelTitle: item.channelTitle,
              channelId: item.channelId,
              channelThumbnail: item.channelThumbnail,
              onTap: () {},
            ),
            firstPageProgressIndicatorBuilder: (context) => SizedBox(
              height: MediaQuery.of(context).size.height * 0.8,
              child: SingleChildScrollView(
                child: Column(
                  children: const [
                    VideoListItemSkeleton(),
                    VideoListItemSkeleton(),
                    VideoListItemSkeleton(),
                  ],
                ),
              ),
            ),
            newPageProgressIndicatorBuilder: (context) => const Center(
              child: MediumPulseLoadingIndicator(),
            ),
            firstPageErrorIndicatorBuilder: (context) {
              return buildErrorView(
                context,
                error: _pagingController.error.toString(),
                retryFunction: () => _pagingController.refresh(),
                stackTrace: _pagingController.error is Error
                    ? (_pagingController.error as Error).stackTrace
                    : StackTrace.current,
              );
            },
            noItemsFoundIndicatorBuilder: (context) => const NoItemContainer(),
          ),
        ),
      ),
    );
  }
}

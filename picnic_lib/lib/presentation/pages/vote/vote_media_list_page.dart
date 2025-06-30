import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:picnic_lib/core/config/environment.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/data/models/vote/video_info.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/presentation/common/no_item_container.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/widgets/error.dart';
import 'package:picnic_lib/presentation/widgets/vote/media/video_list_item.dart';
import 'package:picnic_lib/presentation/widgets/vote/media/video_list_item_skeleton.dart';
import 'package:picnic_lib/presentation/widgets/ui/pulse_loading_indicator.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:googleapis/youtube/v3.dart' as youtube;
import 'package:googleapis_auth/auth_io.dart';

class VoteMediaListPage extends ConsumerStatefulWidget {
  final String pageName = 'page_title_vote_gather';

  const VoteMediaListPage({super.key});

  @override
  ConsumerState<VoteMediaListPage> createState() => _VoteMediaListPageState();
}

class _VoteMediaListPageState extends ConsumerState<VoteMediaListPage> {
  static const _pageSize = 10;
  final Map<String, Map<String, dynamic>> _videoStatsCache = {};
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
            pageTitle: t('nav_media'),
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
    _videoStatsCache.clear();
    super.dispose();
  }

  Future<Map<String, dynamic>> _fetchVideoStats(String videoId) async {
    if (_videoStatsCache.containsKey(videoId)) {
      return _videoStatsCache[videoId]!;
    }

    final apiKey = Environment.youtubeApiKey;
    if (apiKey.isEmpty) {
      logger.e('YouTube API key is not configured');
      return _getDefaultStats();
    }

    try {
      final authClient = clientViaApiKey(apiKey);
      final youtubeApi = youtube.YouTubeApi(authClient);

      final videoResponse = await youtubeApi.videos.list(
        ['snippet'],
        id: [videoId],
      );

      if (videoResponse.items == null || videoResponse.items!.isEmpty) {
        return _getDefaultStats();
      }

      final video = videoResponse.items!.first;
      final channelId = video.snippet?.channelId ?? '';

      final channelResponse = await youtubeApi.channels.list(
        ['snippet'],
        id: [channelId],
      );

      String channelThumbnail = '';
      if (channelResponse.items != null && channelResponse.items!.isNotEmpty) {
        channelThumbnail =
            channelResponse.items!.first.snippet?.thumbnails?.default_?.url ??
                '';
      }

      final stats = {
        'channelId': channelId,
        'channelTitle': video.snippet?.channelTitle ?? '',
        'channelThumbnail': channelThumbnail,
      };

      _videoStatsCache[videoId] = stats;
      return stats;
    } catch (e, s) {
      logger.e('Error fetching video stats', error: e, stackTrace: s);
      return _getDefaultStats();
    }
  }

  Map<String, dynamic> _getDefaultStats() {
    return {
      'channelId': '',
      'channelTitle': '',
      'channelThumbnail': '',
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

      final newItems = await Future.wait(response.map((data) async {
        final videoId = data['video_id']?.toString() ?? '';
        final stats = await _fetchVideoStats(videoId);

        return VideoInfo(
          id: data['id'] as int,
          videoId: videoId,
          videoUrl: data['video_url']?.toString() ?? '',
          title: Map<String, String>.from(data['title'] as Map),
          thumbnailUrl: 'https://img.youtube.com/vi/$videoId/maxresdefault.jpg',
          createdAt: data['created_at'] != null
              ? DateTime.parse(data['created_at'].toString())
              : null,
          channelTitle: stats['channelTitle'] as String,
          channelId: stats['channelId'] as String,
          channelThumbnail: stats['channelThumbnail'] as String,
        );
      }));

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

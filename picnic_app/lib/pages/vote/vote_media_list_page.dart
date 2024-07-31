import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:picnic_app/components/error.dart';
import 'package:picnic_app/models/vote/video_info.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/date.dart';
import 'package:picnic_app/util/i18n.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class VoteMediaListPage extends ConsumerStatefulWidget {
  final String pageName = 'page_title_vote_gather';

  const VoteMediaListPage({super.key});

  @override
  ConsumerState<VoteMediaListPage> createState() => _VoteMediaListPageState();
}

class _VoteMediaListPageState extends ConsumerState<VoteMediaListPage> {
  static const _pageSize = 10;

  final PagingController<int, VideoInfo> _pagingController =
      PagingController(firstPageKey: 0);

  String? _currentPlayingVideoId;

  @override
  void initState() {
    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });
    super.initState();
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
          isPlaying: _currentPlayingVideoId ==
              YoutubePlayer.convertUrlToId(item.video_url),
          onTap: () => _toggleVideoPlay(item.video_url),
        ),
        firstPageErrorIndicatorBuilder: (context) {
          return ErrorView(
            context,
            error: _pagingController.error.toString(),
            retryFunction: () => _pagingController.refresh(),
            stackTrace: _pagingController.error.stackTrace,
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
          .order('created_at', ascending: false)
          .range(pageKey, pageKey + _pageSize - 1);

      final newItems = response.map((e) => VideoInfo.fromJson(e)).toList();
      final isLastPage = newItems.length < _pageSize;
      if (isLastPage) {
        _pagingController.appendLastPage(newItems);
      } else {
        final nextPageKey = pageKey + newItems.length;
        _pagingController.appendPage(newItems, nextPageKey);
      }
    } catch (error) {
      _pagingController.error = error;
    }
  }

  void _toggleVideoPlay(String videoUrl) {
    final videoId = YoutubePlayer.convertUrlToId(videoUrl);
    setState(() {
      if (_currentPlayingVideoId == videoId) {
        _currentPlayingVideoId = null;
      } else {
        _currentPlayingVideoId = videoId;
      }
    });
  }
}

class VideoListItem extends StatelessWidget {
  final VideoInfo item;
  final bool isPlaying;
  final VoidCallback onTap;
  late final YoutubePlayerController _controller;

  VideoListItem({
    Key? key,
    required this.item,
    required this.isPlaying,
    required this.onTap,
  }) : super(key: key) {
    _controller = YoutubePlayerController(
      initialVideoId: YoutubePlayer.convertUrlToId(item.video_url) ?? '',
      flags: const YoutubePlayerFlags(
        mute: false,
        autoPlay: false,
        forceHD: true,
        loop: true,
      ),
    );
  }

  Future<void> _launchYouTube(BuildContext context) async {
    final youtubeUrl =
        'https://www.youtube.com/watch?v=${YoutubePlayer.convertUrlToId(item.video_url)}';
    final uri = Uri.parse(youtubeUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('YouTube를 열 수 없습니다.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16).r,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          YoutubePlayer(
            controller: _controller,
            bottomActions: [
              CurrentPosition(),
              ProgressBar(
                isExpanded: true,
                colors: const ProgressBarColors(
                  playedColor: AppColors.Mint500,
                  handleColor: AppColors.Primary500,
                  bufferedColor: AppColors.Grey500,
                  backgroundColor: AppColors.Grey200,
                ),
              ),
              IconButton(
                icon: const Icon(FontAwesomeIcons.youtube,
                    color: Color.fromRGBO(255, 0, 0, 1)),
                onPressed: () => _launchYouTube(context),
              ),
            ],
            showVideoProgressIndicator: true,
            progressColors: const ProgressBarColors(
              playedColor: AppColors.Primary500,
              handleColor: AppColors.Mint500,
              bufferedColor: AppColors.Grey500,
              backgroundColor: AppColors.Grey200,
            ),
            onReady: () {
              // _controller.load(snapshot.data.videoId);
            },
          ),
          SizedBox(height: 8.h),
          Text(
            getLocaleTextFromJson(item.title),
            style: getTextStyle(AppTypo.BODY14B, AppColors.Grey900),
          ),
          Text(
            formatDateTimeYYYYMMDD(item.created_at),
            style: getTextStyle(AppTypo.CAPTION12M, AppColors.Grey900),
          ),
        ],
      ),
    );
  }
}

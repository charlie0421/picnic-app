import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:picnic_app/components/error.dart';
import 'package:picnic_app/components/picnic_cached_network_image.dart';
import 'package:picnic_app/models/vote/video_info.dart';
import 'package:picnic_app/util/i18n.dart';
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
        itemBuilder: (context, item, index) => GestureDetector(
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => FullScreenVideoPlayer(videoInfo: item),
            ));
          },
          child: Column(
            children: [
              PicnicCachedNetworkImage(
                imageUrl: 'media/${item.id}/${item.thumbnail_url}',
              ),
              Text(getLocaleTextFromJson(item.title)),
            ],
          ),
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
    // ... (이전 코드와 동일)
  }
}

class FullScreenVideoPlayer extends StatefulWidget {
  final VideoInfo videoInfo;

  const FullScreenVideoPlayer({Key? key, required this.videoInfo})
      : super(key: key);

  @override
  _FullScreenVideoPlayerState createState() => _FullScreenVideoPlayerState();
}

class _FullScreenVideoPlayerState extends State<FullScreenVideoPlayer> {
  late YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoInfo.video_id,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
        enableCaption: true,
      ),
    );

    // 자동으로 풀스크린 모드로 전환
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.toggleFullScreenMode();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: YoutubePlayerBuilder(
        onExitFullScreen: () {
          // 풀스크린 모드 종료 시 이전 페이지로 돌아가기
          Navigator.of(context).pop();
        },
        player: YoutubePlayer(
          controller: _controller,
          showVideoProgressIndicator: true,
          progressIndicatorColor: Colors.blueAccent,
          progressColors: const ProgressBarColors(
            playedColor: Colors.blue,
            handleColor: Colors.blueAccent,
          ),
          onReady: () {
            _controller.addListener(() {});
          },
        ),
        builder: (context, player) {
          return Column(
            children: [
              player,
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

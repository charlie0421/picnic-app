import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class YouTubeEmbedBuilder extends EmbedBuilder {
  @override
  String get key => 'youtube';

  @override
  Widget build(BuildContext context, QuillController controller, Embed node,
      bool readOnly, bool inline, TextStyle? textStyle) {
    final String youtubeUrl = node.value.data;
    print('YouTubeEmbedBuilder - Received URL: $youtubeUrl');

    String? youtubeId;
    try {
      youtubeId = YoutubePlayer.convertUrlToId(youtubeUrl);
      print('YouTubeEmbedBuilder - Extracted ID: $youtubeId');
    } catch (e) {
      print('YouTubeEmbedBuilder - Error parsing YouTube URL: $e');
    }

    if (youtubeId == null) {
      print('YouTubeEmbedBuilder - Invalid YouTube URL: $youtubeUrl');
      return Text('Invalid YouTube URL: $youtubeUrl');
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        double width = constraints.maxWidth * 0.5; // 화면 너비의 절반
        double height = width * 9 / 16; // 16:9 비율 유지

        return Center(
          // 가운데 정렬을 위해 Center 위젯 추가
          child: SizedBox(
            width: width,
            height: height,
            child: YoutubePlayer(
              controller: YoutubePlayerController(
                initialVideoId: youtubeId!,
                flags: const YoutubePlayerFlags(
                  autoPlay: false,
                  mute: false,
                ),
              ),
              showVideoProgressIndicator: true,
              progressIndicatorColor: Colors.red,
              progressColors: const ProgressBarColors(
                playedColor: Colors.red,
                handleColor: Colors.redAccent,
              ),
              onReady: () {
                print('YouTubeEmbedBuilder - YouTube Player is ready');
              },
              onEnded: (YoutubeMetaData metaData) {
                print('YouTubeEmbedBuilder - Video ended: ${metaData.videoId}');
              },
            ),
          ),
        );
      },
    );
  }
}

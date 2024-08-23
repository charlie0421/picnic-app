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
    print('YouTubeEmbedBuilder - Received URL: $youtubeUrl'); // 디버깅을 위한 출력

    String? youtubeId;
    try {
      youtubeId = YoutubePlayer.convertUrlToId(youtubeUrl);
      print('YouTubeEmbedBuilder - Extracted ID: $youtubeId'); // 디버깅을 위한 출력
    } catch (e) {
      print('YouTubeEmbedBuilder - Error parsing YouTube URL: $e');
    }

    if (youtubeId == null) {
      print('YouTubeEmbedBuilder - Invalid YouTube URL: $youtubeUrl');
      return Text('Invalid YouTube URL: $youtubeUrl');
    }

    return SizedBox(
      height: 300,
      child: YoutubePlayer(
        controller: YoutubePlayerController(
          initialVideoId: youtubeId,
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
    );
  }
}

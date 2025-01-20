// lib/components/vote/media/video_list_item.dart

import 'package:flutter/material.dart';
import 'package:picnic_lib/presentation/common/webview/video_webview_mobile.dart'
    if (dart.html) 'package:picnic_lib/presentation/common/webview/video_webview_web.dart';

class VideoListItem extends StatelessWidget {
  final String videoId;
  final double? aspectRatio;
  final bool autoPlay;
  final bool showControls;
  final VoidCallback? onTap;

  const VideoListItem({
    super.key,
    required this.videoId,
    this.aspectRatio = 16 / 9,
    this.autoPlay = false,
    this.showControls = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: aspectRatio!,
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              color: Colors.black,
              child: createWebViewProvider(
                videoId: videoId,
                onLoadingChanged: (_) {},
                onProgressChanged: (_) {},
              ).build(context),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

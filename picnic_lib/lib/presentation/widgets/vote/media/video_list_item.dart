// lib/components/vote/media/video_list_item.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/ui.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:url_launcher/url_launcher.dart';

class VideoListItem extends StatelessWidget {
  final String videoId;
  final Map<String, String> title;
  final String thumbnailUrl;
  final String channelTitle;
  final String channelId;
  final String channelThumbnail;
  final VoidCallback? onTap;

  const VideoListItem({
    super.key,
    required this.videoId,
    required this.title,
    required this.thumbnailUrl,
    required this.channelTitle,
    required this.channelId,
    required this.channelThumbnail,
    this.onTap,
  });

  Future<void> _launchVideoUrl() async {
    final appUrl = Uri.parse('vnd.youtube://watch?v=$videoId');
    final webUrl = Uri.parse('https://www.youtube.com/watch?v=$videoId');

    if (await canLaunchUrl(appUrl)) {
      await launchUrl(appUrl, mode: LaunchMode.externalApplication);
    } else if (await canLaunchUrl(webUrl)) {
      await launchUrl(webUrl, mode: LaunchMode.externalApplication);
    } else {
      logger.e('Could not launch video URL');
    }
  }

  Future<void> _launchChannelUrl() async {
    final appUrl = Uri.parse('vnd.youtube://channel/$channelId');
    final webUrl = Uri.parse('https://www.youtube.com/channel/$channelId');

    if (await canLaunchUrl(appUrl)) {
      await launchUrl(appUrl, mode: LaunchMode.externalApplication);
    } else if (await canLaunchUrl(webUrl)) {
      await launchUrl(webUrl, mode: LaunchMode.externalApplication);
    } else {
      logger.e('Could not launch channel URL');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: InkWell(
        onTap: _launchVideoUrl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                CachedNetworkImage(
                  imageUrl: thumbnailUrl,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => buildLoadingOverlay(),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
                const Icon(
                  Icons.play_circle_outline,
                  size: 50,
                  color: AppColors.grey00,
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    getLocaleTextFromJson(title),
                    style: getTextStyle(AppTypo.body16M),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _launchChannelUrl,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundImage:
                              CachedNetworkImageProvider(channelThumbnail),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          channelTitle,
                          style:
                              getTextStyle(AppTypo.body16B, AppColors.grey900),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

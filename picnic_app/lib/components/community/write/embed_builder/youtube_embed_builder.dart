// lib/components/youtube_embed.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:picnic_app/components/community/write/embed_builder/deletable_embed_builder.dart';
import 'package:picnic_app/config/environment.dart';
import 'package:picnic_app/services/youtube_service.dart';
import 'package:picnic_app/util/number.dart';
import 'package:picnic_app/util/ui.dart';
import 'package:url_launcher/url_launcher.dart';

class YouTubeEmbedBuilder extends EmbedBuilder {
  @override
  String get key => 'youtube';

  @override
  Widget build(BuildContext context, QuillController controller, Embed node,
      bool readOnly, bool inline, TextStyle textStyle) {
    return _YouTubeEmbedContent(node: node);
  }
}

class DeletableYouTubeEmbedBuilder extends DeletableEmbedBuilder {
  DeletableYouTubeEmbedBuilder()
      : super(
          embedType: 'youtube',
          contentBuilder: (context, node) => _YouTubeEmbedContent(node: node),
        );
}

class _YouTubeEmbedContent extends StatelessWidget {
  final Embed node;
  final _contentService = YouTubeContentService();

  _YouTubeEmbedContent({required this.node});

  // 썸네일 URL 생성 메서드
  String getThumbnailUrl(String videoId, {bool highQuality = true}) {
    if (kIsWeb) {
      return '${Environment.supabaseUrl}/functions/v1/youtube-thumbnail?videoId=$videoId';
    }
    if (highQuality) {
      return 'https://img.youtube.com/vi/$videoId/mqdefault.jpg';
    }
    return 'https://img.youtube.com/vi/$videoId/default.jpg';
  }

  @override
  Widget build(BuildContext context) {
    final data = node.value.data;
    String youtubeUrl = '';

    if (data is Map<String, dynamic>) {
      youtubeUrl = data['source'] as String? ?? '';
    } else if (data is String) {
      youtubeUrl = data;
    }

    return FutureBuilder<VideoInfo>(
      future: _contentService.fetchYoutubeInfo(youtubeUrl),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: 200,
            child: buildLoadingOverlay(),
          );
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else if (!snapshot.hasData) {
          return const Text('No data available');
        }

        final videoInfo = snapshot.data!;
        return _buildVideoCard(context, videoInfo);
      },
    );
  }

  Widget _buildVideoCard(BuildContext context, VideoInfo videoInfo) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        const aspectRatio = 16 / 9;
        final thumbnailHeight = maxWidth / aspectRatio;

        return Container(
          width: maxWidth,
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 썸네일 영역
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: GestureDetector(
                  onTap: () => _launchYouTubeVideo(videoInfo.id),
                  child: Stack(
                    children: [
                      // 썸네일 이미지 (고품질)
                      Image.network(
                        getThumbnailUrl(videoInfo.id, highQuality: true),
                        width: maxWidth,
                        height: thumbnailHeight,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          // 고품질 썸네일 로드 실패시 저품질 썸네일 시도
                          return Image.network(
                            getThumbnailUrl(videoInfo.id, highQuality: false),
                            width: maxWidth,
                            height: thumbnailHeight,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              // 모든 썸네일 로드 실패시 플레이스홀더 표시
                              return Container(
                                width: maxWidth,
                                height: thumbnailHeight,
                                color: Colors.grey[300],
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.error_outline),
                                    SizedBox(height: 8),
                                    Text('Thumbnail not available'),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                      // 플레이 버튼 오버레이
                      Positioned.fill(
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.play_arrow,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // 비디오 정보 영역
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      videoInfo.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      videoInfo.channelTitle,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          formatViewCountNumberEn(videoInfo.viewCount),
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatPublishedDate(videoInfo.publishedAt),
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatPublishedDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}년 전';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}개월 전';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }

  Future<void> _launchYouTubeVideo(String videoId) async {
    final url = Uri.parse('https://www.youtube.com/watch?v=$videoId');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }
}

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:picnic_app/components/community/write/embed_builder/deletable_embed_builder.dart';
import 'package:picnic_app/config/environment.dart';
import 'package:picnic_app/util/number.dart';

class DeletableYouTubeEmbedBuilder extends DeletableEmbedBuilder {
  DeletableYouTubeEmbedBuilder()
      : super(
          embedType: 'youtube',
          contentBuilder: (context, node) {
            final data = node.value.data;
            String youtubeUrl = '';

            if (data is Map<String, dynamic>) {
              youtubeUrl = data['source'] as String? ?? '';
            } else if (data is String) {
              youtubeUrl = data;
            }

            return FutureBuilder<VideoInfo>(
              future: _fetchVideoInfo(youtubeUrl),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                } else if (!snapshot.hasData) {
                  return const Text('No data available');
                }

                final videoInfo = snapshot.data!;

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final maxWidth = constraints.maxWidth * 0.9;
                    return Container(
                      width: maxWidth,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 1,
                            blurRadius: 3,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12)),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Image.network(
                                  videoInfo.thumbnailUrl,
                                  width: maxWidth,
                                  height: maxWidth * 9 / 16,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                    width: maxWidth,
                                    height: maxWidth * 9 / 16,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.error),
                                  ),
                                ),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.8),
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(12),
                                  child: const Icon(
                                    Icons.play_arrow,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                ),
                              ],
                            ),
                          ),
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
                                Row(
                                  children: [
                                    const CircleAvatar(
                                      backgroundColor: Colors.grey,
                                      radius: 12,
                                      child: Icon(Icons.person,
                                          size: 16, color: Colors.white),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        videoInfo.channelTitle,
                                        style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.remove_red_eye,
                                        size: 16, color: Colors.grey[600]),
                                    const SizedBox(width: 4),
                                    Text(
                                      formatViewCountNumberEn(
                                          videoInfo.viewCount),
                                      style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12),
                                    ),
                                    const SizedBox(width: 12),
                                    Icon(Icons.access_time,
                                        size: 16, color: Colors.grey[600]),
                                    const SizedBox(width: 4),
                                    Text(
                                      _formatDate(videoInfo.publishedAt),
                                      style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12),
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
              },
            );
          },
        );

  static Future<VideoInfo> _fetchVideoInfo(String url) async {
    final videoId = _extractVideoId(url);
    if (videoId == null) {
      return VideoInfo(
        id: 'Invalid ID',
        title: 'Invalid YouTube URL',
        channelTitle: 'Unknown',
        thumbnailUrl: '',
        viewCount: 0,
        publishedAt: DateTime.now(),
      );
    }

    final apiKey =
        Environment.youtubeApiKey; // Replace with your actual API key
    final apiUrl =
        'https://www.googleapis.com/youtube/v3/videos?part=snippet,statistics&id=$videoId&key=$apiKey';

    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final items = data['items'] as List;
        if (items.isNotEmpty) {
          final video = items.first;
          final snippet = video['snippet'];
          final statistics = video['statistics'];
          return VideoInfo(
            id: videoId,
            title: snippet['title'],
            channelTitle: snippet['channelTitle'],
            thumbnailUrl: snippet['thumbnails']['high']['url'],
            viewCount: int.parse(statistics['viewCount']),
            publishedAt: DateTime.parse(snippet['publishedAt']),
          );
        }
      }
    } catch (e) {
      print('Error fetching video info: $e');
    }

    return VideoInfo(
      id: videoId,
      title: 'YouTube Video',
      channelTitle: 'Unknown Channel',
      thumbnailUrl: 'https://img.youtube.com/vi/$videoId/0.jpg',
      viewCount: 0,
      publishedAt: DateTime.now(),
    );
  }

  static String? _extractVideoId(String url) {
    Uri? uri;
    try {
      uri = Uri.parse(url);
    } catch (e) {
      return null;
    }

    if (uri.host == 'youtu.be') {
      return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    } else if (uri.host.contains('youtube.com')) {
      if (uri.pathSegments.contains('watch')) {
        return uri.queryParameters['v'];
      } else if (uri.pathSegments.contains('embed') ||
          uri.pathSegments.contains('shorts')) {
        return uri.pathSegments.isNotEmpty ? uri.pathSegments.last : null;
      }
    }
    return null;
  }

  static String _formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }
}

class VideoInfo {
  final String id;
  final String title;
  final String channelTitle;
  final String thumbnailUrl;
  final int viewCount;
  final DateTime publishedAt;

  VideoInfo({
    required this.id,
    required this.title,
    required this.channelTitle,
    required this.thumbnailUrl,
    required this.viewCount,
    required this.publishedAt,
  });
}

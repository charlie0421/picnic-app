// lib/services/youtube_service.dart
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:picnic_app/config/environment.dart';
import 'package:picnic_app/util/logger.dart';

class VideoInfo {
  final String id;
  final String title;
  final String channelTitle;
  final String channelThumbnail;
  final String thumbnailUrl;
  final int viewCount;
  final DateTime publishedAt;

  VideoInfo({
    required this.id,
    required this.title,
    required this.channelTitle,
    required this.channelThumbnail,
    required this.thumbnailUrl,
    required this.viewCount,
    required this.publishedAt,
  });
}

class YouTubeContentService {
  static final YouTubeContentService _instance =
      YouTubeContentService._internal();

  factory YouTubeContentService() => _instance;

  YouTubeContentService._internal();

  Future<VideoInfo> fetchYoutubeInfo(String url) async {
    if (kIsWeb) {
      return _fetchYoutubeInfoWeb(url);
    } else {
      return _fetchYoutubeInfoNative(url);
    }
  }

  Future<VideoInfo> _fetchYoutubeInfoWeb(String url) async {
    try {
      final videoId = _extractVideoId(url);
      if (videoId == null) {
        throw Exception('Invalid YouTube URL');
      }

      final response = await http.post(
        Uri.parse('${Environment.supabaseUrl}/functions/v1/youtube-preview'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${Environment.supabaseAnonKey}',
        },
        body: json.encode({'url': url}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // API 응답에서 가장 좋은 품질의 썸네일 선택
        final thumbnails = data['thumbnails'] as Map<String, dynamic>?;
        final thumbnailUrl = thumbnails?['maxres']?['url'] ??
            thumbnails?['standard']?['url'] ??
            thumbnails?['high']?['url'] ??
            thumbnails?['medium']?['url'] ??
            thumbnails?['default']?['url'] ??
            'https://img.youtube.com/vi/$videoId/mqdefault.jpg';

        return VideoInfo(
          id: data['videoId'] ?? videoId,
          title: _decodeHtmlEntities(data['title'] ?? 'YouTube Video'),
          channelTitle:
              _decodeHtmlEntities(data['channelTitle'] ?? 'Unknown Channel'),
          channelThumbnail: data['channelThumbnail'] ?? '',
          thumbnailUrl: thumbnailUrl,
          viewCount: int.tryParse(data['viewCount']?.toString() ?? '0') ?? 0,
          publishedAt:
              DateTime.tryParse(data['publishedAt'] ?? '') ?? DateTime.now(),
        );
      }

      throw Exception('Failed to fetch video data: ${response.statusCode}');
    } catch (e, s) {
      logger.e('Error fetching video info: $e', stackTrace: s);
      return _createFallbackVideoInfo(url);
    }
  }

  Future<VideoInfo> _fetchYoutubeInfoNative(String url) async {
    final videoId = _extractVideoId(url);
    if (videoId == null) {
      throw Exception('Invalid YouTube URL');
    }

    final apiKey = Environment.youtubeApiKey;

    try {
      // Fetch video data and channel data in parallel
      final videoFuture =
          http.get(Uri.parse('https://www.googleapis.com/youtube/v3/videos?'
              'part=snippet,statistics&id=$videoId&key=$apiKey'));

      final data = await videoFuture;
      if (data.statusCode != 200) {
        throw Exception('Failed to fetch video data: ${data.statusCode}');
      }

      final videoData = json.decode(data.body);
      if (videoData['items']?.isEmpty ?? true) {
        throw Exception('Video not found');
      }

      final video = videoData['items'][0];
      final snippet = video['snippet'];

      // Fetch channel data separately
      final channelId = snippet['channelId'];
      final channelResponse = await http
          .get(Uri.parse('https://www.googleapis.com/youtube/v3/channels?'
              'part=snippet&id=$channelId&key=$apiKey'));

      final channelData = json.decode(channelResponse.body);
      final channelThumbnail = channelData['items']?[0]?['snippet']
              ?['thumbnails']?['default']?['url'] ??
          '';

      return VideoInfo(
        id: videoId,
        title: _decodeHtmlEntities(snippet['title']),
        channelTitle: _decodeHtmlEntities(snippet['channelTitle']),
        channelThumbnail: channelThumbnail,
        thumbnailUrl: snippet['thumbnails']?['maxres']?['url'] ??
            snippet['thumbnails']?['high']?['url'] ??
            'https://img.youtube.com/vi/$videoId/hqdefault.jpg',
        viewCount: int.tryParse(video['statistics']?['viewCount'] ?? '0') ?? 0,
        publishedAt:
            DateTime.tryParse(snippet['publishedAt']) ?? DateTime.now(),
      );
    } catch (e, s) {
      logger.e('Error fetching video info from native: $e', stackTrace: s);
      return _createFallbackVideoInfo(url);
    }
  }

  VideoInfo _createVideoInfoFromData(Map<String, dynamic> data) {
    return VideoInfo(
      id: data['videoId'] ?? '',
      title: _decodeHtmlEntities(data['title'] ?? 'YouTube Video'),
      channelTitle:
          _decodeHtmlEntities(data['channelTitle'] ?? 'Unknown Channel'),
      channelThumbnail: data['channelThumbnail'] ?? '',
      thumbnailUrl: data['thumbnailUrl'] ?? '',
      viewCount: int.tryParse(data['viewCount']?.toString() ?? '0') ?? 0,
      publishedAt:
          DateTime.tryParse(data['publishedAt'] ?? '') ?? DateTime.now(),
    );
  }

  VideoInfo _createFallbackVideoInfo(String url) {
    final videoId = _extractVideoId(url);
    return VideoInfo(
      id: videoId ?? '',
      title: 'YouTube Video',
      channelTitle: 'Unknown Channel',
      channelThumbnail: '',
      thumbnailUrl: videoId != null
          ? 'https://img.youtube.com/vi/$videoId/hqdefault.jpg'
          : '',
      viewCount: 0,
      publishedAt: DateTime.now(),
    );
  }

  String _decodeHtmlEntities(String text) {
    return text
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&apos;', "'")
        .replaceAll('&#39;', "'")
        .replaceAll('&#x27;', "'")
        .replaceAll('&#x2F;', "/")
        .replaceAll('&#x2f;', "/")
        .replaceAll('&#47;', "/")
        .replaceAll('&nbsp;', " ");
  }

  String? _extractVideoId(String url) {
    Uri? uri;
    try {
      uri = Uri.parse(url);
    } catch (e, s) {
      logger.e('Error parsing URL: $e', stackTrace: s);
      return null;
    }

    if (uri.host == 'youtu.be') {
      return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    } else if (uri.host.contains('youtube.com')) {
      if (uri.pathSegments.contains('watch')) {
        return uri.queryParameters['v'];
      } else if (uri.pathSegments.contains('embed') ||
          uri.pathSegments.contains('shorts')) {
        return uri.pathSegments.lastOrNull;
      }
    }
    return null;
  }
}

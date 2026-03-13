// lib/services/youtube_service.dart
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:picnic_lib/core/config/environment.dart';
import 'package:picnic_lib/core/utils/logger.dart';

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
      final videoId = extractVideoId(url);
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
        return parseWebApiResponse(data, videoId);
      }

      throw Exception('Failed to fetch video data: ${response.statusCode}');
    } catch (e, s) {
      logger.e('Error fetching video info: $e', stackTrace: s);
      return createFallbackVideoInfo(url);
    }
  }

  /// Parses the Supabase youtube-preview proxy response into a [VideoInfo].
  @visibleForTesting
  VideoInfo parseWebApiResponse(Map<String, dynamic> data, String videoId) {
    final thumbnails = data['thumbnails'] as Map<String, dynamic>?;
    final thumbnailUrl = selectBestThumbnail(
      thumbnails,
      videoId,
      fallbackQuality: 'mqdefault',
    );

    return VideoInfo(
      id: data['videoId'] ?? videoId,
      title: decodeHtmlEntities(data['title'] ?? 'YouTube Video'),
      channelTitle:
          decodeHtmlEntities(data['channelTitle'] ?? 'Unknown Channel'),
      channelThumbnail: data['channelThumbnail'] ?? '',
      thumbnailUrl: thumbnailUrl,
      viewCount: int.tryParse(data['viewCount']?.toString() ?? '0') ?? 0,
      publishedAt:
          DateTime.tryParse(data['publishedAt'] ?? '') ?? DateTime.now(),
    );
  }

  Future<VideoInfo> _fetchYoutubeInfoNative(String url) async {
    final videoId = extractVideoId(url);
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
      final channelThumbnail = extractChannelThumbnail(channelData);

      return parseNativeVideoData(video, videoId, channelThumbnail);
    } catch (e, s) {
      logger.e('Error fetching video info from native: $e', stackTrace: s);
      return createFallbackVideoInfo(url);
    }
  }

  /// Parses a YouTube Data API video item into a [VideoInfo].
  @visibleForTesting
  VideoInfo parseNativeVideoData(
    Map<String, dynamic> video,
    String videoId,
    String channelThumbnail,
  ) {
    final snippet = video['snippet'] as Map<String, dynamic>?;
    final statistics = video['statistics'] as Map<String, dynamic>?;
    final thumbnails = snippet?['thumbnails'] as Map<String, dynamic>?;

    // Select best thumbnail: maxres > high > fallback
    final thumbnailUrl = thumbnails?['maxres']?['url'] ??
        thumbnails?['high']?['url'] ??
        'https://img.youtube.com/vi/$videoId/hqdefault.jpg';

    return VideoInfo(
      id: videoId,
      title: decodeHtmlEntities(snippet?['title'] ?? ''),
      channelTitle: decodeHtmlEntities(snippet?['channelTitle'] ?? ''),
      channelThumbnail: channelThumbnail,
      thumbnailUrl: thumbnailUrl,
      viewCount:
          int.tryParse(statistics?['viewCount'] ?? '0') ?? 0,
      publishedAt:
          DateTime.tryParse(snippet?['publishedAt'] ?? '') ?? DateTime.now(),
    );
  }

  /// Extracts channel thumbnail URL from YouTube Data API channel response.
  @visibleForTesting
  static String extractChannelThumbnail(Map<String, dynamic> channelData) {
    final items = channelData['items'] as List?;
    if (items == null || items.isEmpty) return '';
    return items[0]?['snippet']?['thumbnails']?['default']?['url'] ?? '';
  }

  /// Selects the best quality thumbnail URL from a thumbnails map.
  /// Priority: maxres > standard > high > medium > default > fallback.
  @visibleForTesting
  static String selectBestThumbnail(
    Map<String, dynamic>? thumbnails,
    String videoId, {
    String fallbackQuality = 'hqdefault',
  }) {
    return thumbnails?['maxres']?['url'] ??
        thumbnails?['standard']?['url'] ??
        thumbnails?['high']?['url'] ??
        thumbnails?['medium']?['url'] ??
        thumbnails?['default']?['url'] ??
        'https://img.youtube.com/vi/$videoId/$fallbackQuality.jpg';
  }

  @visibleForTesting
  VideoInfo createFallbackVideoInfo(String url) {
    final videoId = extractVideoId(url);
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

  @visibleForTesting
  String decodeHtmlEntities(String text) {
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

  @visibleForTesting
  String? extractVideoId(String url) {
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

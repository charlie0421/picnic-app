import 'package:picnic_lib/core/services/youtube_service.dart';

/// Pure helper methods extracted from [YouTubeContentService] for testability.
///
/// All methods are static, side-effect free, and do not depend on network or
/// platform APIs, making them straightforward to unit-test.
class YouTubeServiceHelper {
  // ---------------------------------------------------------------------------
  // Video ID extraction
  // ---------------------------------------------------------------------------

  /// Extracts a YouTube video ID from a variety of URL formats.
  ///
  /// Supported formats:
  /// - `https://www.youtube.com/watch?v=VIDEO_ID`
  /// - `https://youtu.be/VIDEO_ID`
  /// - `https://www.youtube.com/embed/VIDEO_ID`
  /// - `https://www.youtube.com/shorts/VIDEO_ID`
  /// - `https://m.youtube.com/watch?v=VIDEO_ID`
  ///
  /// Returns `null` when the URL cannot be parsed or does not match any known
  /// YouTube pattern.
  static String? extractVideoId(String url) {
    Uri? uri;
    try {
      uri = Uri.parse(url);
    } catch (_) {
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

  // ---------------------------------------------------------------------------
  // Thumbnail helpers
  // ---------------------------------------------------------------------------

  /// Builds a direct YouTube thumbnail URL for a given [videoId] and [quality].
  ///
  /// Common quality values: `default`, `mqdefault`, `hqdefault`, `sddefault`,
  /// `maxresdefault`.
  static String buildThumbnailUrl(String videoId,
      {String quality = 'hqdefault'}) {
    return 'https://img.youtube.com/vi/$videoId/$quality.jpg';
  }

  /// Selects the best quality thumbnail URL from a thumbnails map returned by
  /// the YouTube Data API.
  ///
  /// Priority: maxres > standard > high > medium > default > fallback.
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
        buildThumbnailUrl(videoId, quality: fallbackQuality);
  }

  // ---------------------------------------------------------------------------
  // Channel thumbnail extraction
  // ---------------------------------------------------------------------------

  /// Extracts the channel thumbnail URL from a YouTube Data API channel
  /// response body (already decoded to a `Map`).
  static String extractChannelThumbnail(Map<String, dynamic> channelData) {
    final items = channelData['items'] as List?;
    if (items == null || items.isEmpty) return '';
    return items[0]?['snippet']?['thumbnails']?['default']?['url'] ?? '';
  }

  // ---------------------------------------------------------------------------
  // HTML entity decoding
  // ---------------------------------------------------------------------------

  /// Decodes common HTML entities found in YouTube API responses.
  static String decodeHtmlEntities(String text) {
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

  // ---------------------------------------------------------------------------
  // Fallback / default VideoInfo
  // ---------------------------------------------------------------------------

  /// Creates a [VideoInfo] with sensible defaults when network fetching fails.
  static VideoInfo createFallbackVideoInfo(String url) {
    final videoId = extractVideoId(url);
    return VideoInfo(
      id: videoId ?? '',
      title: 'YouTube Video',
      channelTitle: 'Unknown Channel',
      channelThumbnail: '',
      thumbnailUrl: videoId != null
          ? buildThumbnailUrl(videoId, quality: 'hqdefault')
          : '',
      viewCount: 0,
      publishedAt: DateTime.utc(1970),
    );
  }

  // ---------------------------------------------------------------------------
  // API response parsing
  // ---------------------------------------------------------------------------

  /// Parses the Supabase `youtube-preview` proxy response into a [VideoInfo].
  static VideoInfo parseWebApiResponse(
      Map<String, dynamic> data, String videoId) {
    final thumbnails = data['thumbnails'] as Map<String, dynamic>?;
    final thumbnailUrl = selectBestThumbnail(
      thumbnails,
      videoId,
      fallbackQuality: 'mqdefault',
    );

    return VideoInfo(
      id: data['videoId']?.toString() ?? videoId,
      title: decodeHtmlEntities(data['title']?.toString() ?? 'YouTube Video'),
      channelTitle: decodeHtmlEntities(
          data['channelTitle']?.toString() ?? 'Unknown Channel'),
      channelThumbnail: data['channelThumbnail']?.toString() ?? '',
      thumbnailUrl: thumbnailUrl,
      viewCount:
          int.tryParse(data['viewCount']?.toString() ?? '0') ?? 0,
      publishedAt:
          DateTime.tryParse(data['publishedAt']?.toString() ?? '') ??
              DateTime.utc(1970),
    );
  }

  /// Parses a single YouTube Data API `video` resource item into a [VideoInfo].
  static VideoInfo parseNativeVideoData(
    Map<String, dynamic> video,
    String videoId,
    String channelThumbnail,
  ) {
    final snippet = video['snippet'] as Map<String, dynamic>?;
    final statistics = video['statistics'] as Map<String, dynamic>?;
    final thumbnails = snippet?['thumbnails'] as Map<String, dynamic>?;

    final thumbnailUrl = thumbnails?['maxres']?['url'] ??
        thumbnails?['high']?['url'] ??
        buildThumbnailUrl(videoId, quality: 'hqdefault');

    return VideoInfo(
      id: videoId,
      title: decodeHtmlEntities(snippet?['title'] ?? ''),
      channelTitle: decodeHtmlEntities(snippet?['channelTitle'] ?? ''),
      channelThumbnail: channelThumbnail,
      thumbnailUrl: thumbnailUrl,
      viewCount:
          int.tryParse(statistics?['viewCount'] ?? '0') ?? 0,
      publishedAt:
          DateTime.tryParse(snippet?['publishedAt'] ?? '') ?? DateTime.utc(1970),
    );
  }

  // ---------------------------------------------------------------------------
  // URL validation
  // ---------------------------------------------------------------------------

  /// Returns `true` when [url] looks like a YouTube video URL.
  static bool isYouTubeUrl(String url) {
    return extractVideoId(url) != null;
  }
}

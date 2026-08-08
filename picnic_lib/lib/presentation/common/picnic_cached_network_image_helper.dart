import 'dart:math' as math;

import 'package:picnic_lib/presentation/common/picnic_cached_network_image.dart';

/// Pure logic helpers extracted from [PicnicCachedNetworkImage] for testability.
///
/// All methods are static and free of widget/state dependencies.
class PicnicCachedNetworkImageHelper {
  PicnicCachedNetworkImageHelper._();

  /// Calculate exponential backoff delay for retry attempts.
  ///
  /// Uses a base delay of 500ms with a 1.5x multiplier per retry.
  /// Caps at [maxBackoffDelay].
  static Duration calculateBackoffDelay(
    int retryCount, {
    Duration baseDelay = const Duration(milliseconds: 500),
    Duration maxBackoffDelay = const Duration(seconds: 30),
  }) {
    final delay = Duration(
      milliseconds:
          (baseDelay.inMilliseconds * math.pow(1.5, retryCount)).toInt(),
    );
    return delay > maxBackoffDelay ? maxBackoffDelay : delay;
  }

  /// Round a pixel value by a multiplier, ensuring at least 1.
  static int roundPixels(double value, double multiplier) {
    final computed = (value * multiplier).round();
    return computed > 0 ? computed : 1;
  }

  /// Compute a cache dimension from explicit, fallback, or default (400) values.
  ///
  /// The result is scaled by [multiplier] and clamped to at least 1.
  static int computeCacheDimension(
    int? explicit,
    double? fallback,
    double multiplier,
  ) {
    if (explicit != null) {
      return math.max(1, (explicit * multiplier).round());
    }
    if (fallback != null && fallback.isFinite) {
      return math.max(1, (fallback * multiplier).round());
    }
    return math.max(1, (400 * multiplier).round());
  }

  /// Generate a cache key for a given URL, reload token, optional index,
  /// and low-quality flag.
  static String cacheKeyFor(
    String url,
    int reloadToken, {
    int? index,
    bool isLowQuality = false,
  }) {
    final buffer = StringBuffer(url)
      ..write('_')
      ..write(reloadToken);
    if (index != null) {
      buffer
        ..write('_')
        ..write(index);
    }
    if (isLowQuality) {
      buffer.write('_lq');
    }
    return buffer.toString();
  }

  /// Estimate image complexity based on pixel count and whether it is a GIF.
  ///
  /// GIF images are always [ImageComplexity.high].
  static ImageComplexity estimateImageComplexity({
    double? width,
    double? height,
    bool isGif = false,
  }) {
    if (isGif) return ImageComplexity.high;

    final w = width ?? 400;
    final h = height ?? 400;
    final pixelCount = w * h;

    if (pixelCount < 50000) return ImageComplexity.low;
    if (pixelCount < 200000) return ImageComplexity.medium;
    return ImageComplexity.high;
  }

  /// Calculate load delay based on priority and optional base delay.
  static Duration calculateLoadDelay(
    ImagePriority priority, {
    Duration? baseDelay,
  }) {
    final base = baseDelay ?? Duration.zero;
    switch (priority) {
      case ImagePriority.high:
        return Duration.zero;
      case ImagePriority.normal:
        return base;
      case ImagePriority.low:
        return base + const Duration(milliseconds: 200);
    }
  }

  /// C3: Apply an optional DPR cap for list-scoped thumbnail weight reduction.
  ///
  /// Returns [multiplier] unchanged when [cap] is null (default behavior).
  /// Otherwise clamps [multiplier] to at most [cap].
  static double capResolution(double multiplier, double? cap) {
    if (cap == null) return multiplier;
    return math.min(multiplier, cap);
  }

  /// Determine if an error string indicates a retryable network error.
  static bool isRetryableError(String errorString) {
    final lower = errorString.toLowerCase();
    const retryableKeywords = [
      'timeout',
      'connection',
      'network',
      'socket',
      'handshake',
      'host',
      'resolve',
      'unreachable',
      'interrupted',
      'refused',
      'reset',
      'dispose',
    ];
    return retryableKeywords.any((keyword) => lower.contains(keyword));
  }

  /// Determine whether to retry a failed image load.
  ///
  /// Returns true when [retryCount] < [maxRetries], the error is retryable,
  /// and the recent failure count is below the threshold (15).
  static bool shouldRetry({
    required int retryCount,
    required int maxRetries,
    required String errorString,
    required int recentFailureCount,
  }) {
    if (retryCount >= maxRetries) return false;
    if (!isRetryableError(errorString)) return false;
    return recentFailureCount < 15;
  }

  /// Check if memory usage percentage indicates memory pressure (>= 90%).
  static bool isMemoryPressure(int currentSizeBytes, int maxSizeBytes) {
    if (maxSizeBytes <= 0) return false;
    final usagePercentage = (currentSizeBytes / maxSizeBytes) * 100;
    return usagePercentage >= 90.0;
  }

  /// Determine whether a memory pressure log should be emitted.
  ///
  /// Returns true if [lastLoggedAt] is null or at least [interval] has passed.
  static bool shouldLogMemoryPressure(
    DateTime now,
    DateTime? lastLoggedAt, {
    Duration interval = const Duration(minutes: 1),
  }) {
    if (lastLoggedAt == null) return true;
    return now.difference(lastLoggedAt) >= interval;
  }
}

import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';
import 'package:picnic_lib/core/config/environment.dart';
import 'package:picnic_lib/core/utils/ui.dart';
import 'package:picnic_lib/presentation/common/picnic_cached_network_image_url_resolver.dart';
import 'package:universal_platform/universal_platform.dart';

/// One first-party CDN transform shared by every device.
///
/// The CDN resizes a new variant slowly on its first request, so a variant is
/// only worth requesting when many users share it. Declare variants as
/// constants per use case; never derive [width] from layout, DPR, platform, or
/// iPad detection.
@immutable
final class PicnicCdnImageVariant {
  const PicnicCdnImageVariant({required this.width, required this.quality})
    : assert(width > 0),
      assert(quality > 0 && quality <= 100);

  /// Avatars and portraits up to about 60 logical pixels.
  static const avatar = PicnicCdnImageVariant(width: 180, quality: 85);

  /// Cards, grid cells, and small thumbnails; the default use case.
  static const thumbnail = PicnicCdnImageVariant(width: 500, quality: 80);

  /// Banners, heroes, and content images as wide as the screen.
  static const large = PicnicCdnImageVariant(width: 1000, quality: 80);

  /// Full-screen viewers and the splash image.
  static const fullscreen = PicnicCdnImageVariant(width: 1600, quality: 80);

  /// Physical pixels. The CDN keeps the source ratio, so no height is sent.
  final int width;
  final int quality;
}

@immutable
final class PicnicImageRequest {
  /// Resolves the exact URL and provider shared by prefetch and display.
  ///
  /// First-party CDN images are always requested at the fixed [cdnVariant],
  /// [PicnicCdnImageVariant.thumbnail] unless the use case names another;
  /// external URLs are always kept verbatim. [width], [height], the
  /// memory-cache sizes, and [maxResolutionMultiplierCap] only bound the local
  /// decode, so they may follow layout and DPR.
  factory PicnicImageRequest.resolve({
    required BuildContext context,
    required String imageUrl,
    double? width,
    double? height,
    int? memCacheWidth,
    int? memCacheHeight,
    double? maxResolutionMultiplierCap,
    PicnicCdnImageVariant cdnVariant = PicnicCdnImageVariant.thumbnail,
  }) {
    final multiplier = _resolutionMultiplier(
      context,
      maxResolutionMultiplierCap,
    );
    final layoutPixels = _physicalLayoutSize(
      _validLogicalDimension(width),
      _validLogicalDimension(height),
      multiplier,
    );
    final decodeSize = _decodeSize(
      layoutWidth: layoutPixels.width,
      layoutHeight: layoutPixels.height,
      memCacheWidth: memCacheWidth,
      memCacheHeight: memCacheHeight,
    );
    final resolver = PicnicCachedNetworkImageUrlResolver(
      cdnUrl: Environment.isInitialized ? Environment.cdnUrl : null,
    );
    final url = imageUrl.trim().isEmpty
        ? ''
        : resolver.resolveFixedWidth(
            imageUrl,
            width: cdnVariant.width,
            quality: _isGif(imageUrl) ? 80 : cdnVariant.quality,
          );
    final provider = ResizeImage(
      CachedNetworkImageProvider(url, cacheKey: url),
      width: decodeSize.width,
      height: decodeSize.height,
      policy: ResizeImagePolicy.fit,
      allowUpscaling: false,
    );
    return PicnicImageRequest._(
      imageUrl: imageUrl,
      url: url,
      decodeWidth: decodeSize.width,
      decodeHeight: decodeSize.height,
      provider: provider,
    );
  }

  const PicnicImageRequest._({
    required this.imageUrl,
    required this.url,
    required this.decodeWidth,
    required this.decodeHeight,
    required this.provider,
  });

  final String imageUrl;

  /// The fetched URL and disk-cache key. It never depends on the device.
  final String url;
  final int decodeWidth;
  final int decodeHeight;
  final ImageProvider<Object> provider;

  Future<Object> obtainKey(ImageConfiguration configuration) {
    return provider.obtainKey(configuration);
  }
}

const int _maximumDimension = 2000;
const int _maximumPixels = 2000000;
const double _maximumExactlyRoundedDouble = 9007199254740991;

double? _validLogicalDimension(double? value) {
  return value != null && value.isFinite && value > 0 ? value : null;
}

double _resolutionMultiplier(BuildContext context, double? requestedCap) {
  final reportedDpr = MediaQuery.devicePixelRatioOf(context);
  final dpr = reportedDpr.isFinite && reportedDpr > 0 ? reportedDpr : 1.0;

  final double platformMultiplier;
  if (UniversalPlatform.isAndroid) {
    platformMultiplier = math.min(dpr * 1.1, 2.5);
  } else if (isIPad(context)) {
    platformMultiplier = math.min(dpr * 1.3, 4.0);
  } else {
    platformMultiplier = math.min(dpr * 1.2, 2.5);
  }

  if (requestedCap != null && requestedCap.isFinite && requestedCap > 0) {
    return math.min(platformMultiplier, requestedCap);
  }
  return platformMultiplier;
}

({int? width, int? height}) _physicalLayoutSize(
  double? logicalWidth,
  double? logicalHeight,
  double multiplier,
) {
  if (logicalWidth == null && logicalHeight == null) {
    return (width: null, height: null);
  }
  if (logicalHeight == null) {
    return (
      width: _singlePhysicalDimension(logicalWidth!, multiplier),
      height: null,
    );
  }
  if (logicalWidth == null) {
    return (
      width: null,
      height: _singlePhysicalDimension(logicalHeight, multiplier),
    );
  }

  final scaledWidth = logicalWidth * multiplier;
  final scaledHeight = logicalHeight * multiplier;
  if (scaledWidth.isFinite &&
      scaledHeight.isFinite &&
      scaledWidth <= _maximumExactlyRoundedDouble &&
      scaledHeight <= _maximumExactlyRoundedDouble) {
    return _capNullableSize(
      math.max(1, scaledWidth.round()),
      math.max(1, scaledHeight.round()),
    );
  }

  final capped = _capLargePhysicalSize(logicalWidth, logicalHeight, multiplier);
  return (width: capped.width, height: capped.height);
}

int _singlePhysicalDimension(double logical, double multiplier) {
  if (logical >= _maximumDimension / multiplier) return _maximumDimension;
  return math.min(
    _maximumDimension,
    math.max(1, (logical * multiplier).round()),
  );
}

({int width, int height}) _capLargePhysicalSize(
  double logicalWidth,
  double logicalHeight,
  double multiplier,
) {
  var scale = multiplier;
  scale = math.min(scale, _maximumDimension / logicalWidth);
  scale = math.min(scale, _maximumDimension / logicalHeight);
  final areaScale = math.exp(
    (math.log(_maximumPixels) -
            math.log(logicalWidth) -
            math.log(logicalHeight)) /
        2,
  );
  scale = math.min(scale, areaScale);

  return _capSize(
    math.max(1, (logicalWidth * scale).round()),
    math.max(1, (logicalHeight * scale).round()),
  );
}

({int? width, int? height}) _capNullableSize(int? width, int? height) {
  if (width == null && height == null) return (width: null, height: null);
  if (height == null) {
    return (width: math.min(width!, _maximumDimension), height: null);
  }
  if (width == null) {
    return (width: null, height: math.min(height, _maximumDimension));
  }
  final capped = _capSize(width, height);
  return (width: capped.width, height: capped.height);
}

({int width, int height}) _capSize(int width, int height) {
  var scale = 1.0;
  if (width > _maximumDimension) {
    scale = math.min(scale, _maximumDimension / width);
  }
  if (height > _maximumDimension) {
    scale = math.min(scale, _maximumDimension / height);
  }
  final pixels = width.toDouble() * height;
  if (pixels > _maximumPixels) {
    scale = math.min(scale, math.sqrt(_maximumPixels / pixels));
  }
  if (scale >= 1) return (width: width, height: height);
  return (
    width: math.max(1, (width * scale).floor()),
    height: math.max(1, (height * scale).floor()),
  );
}

({int width, int height}) _decodeSize({
  required int? layoutWidth,
  required int? layoutHeight,
  required int? memCacheWidth,
  required int? memCacheHeight,
}) {
  if (layoutWidth == null &&
      layoutHeight == null &&
      memCacheWidth == null &&
      memCacheHeight == null) {
    return (width: 400, height: 400);
  }

  final hasExplicitWidth = memCacheWidth != null;
  final hasExplicitHeight = memCacheHeight != null;
  var width = hasExplicitWidth ? math.max(1, memCacheWidth) : layoutWidth;
  var height = hasExplicitHeight ? math.max(1, memCacheHeight) : layoutHeight;

  if (width == null) {
    height = math.min(height!, _maximumDimension);
    return (
      width: math.min(_maximumDimension, _maximumPixels ~/ height),
      height: height,
    );
  }
  if (height == null) {
    width = math.min(width, _maximumDimension);
    return (
      width: width,
      height: math.min(_maximumDimension, _maximumPixels ~/ width),
    );
  }

  if (hasExplicitWidth != hasExplicitHeight) {
    if (hasExplicitWidth) {
      width = math.min(width, _maximumDimension);
      height = math.min(
        height,
        math.min(_maximumDimension, _maximumPixels ~/ width),
      );
    } else {
      height = math.min(height, _maximumDimension);
      width = math.min(
        width,
        math.min(_maximumDimension, _maximumPixels ~/ height),
      );
    }
    return (width: width, height: height);
  }

  return _capSize(width, height);
}

/// GIF variants keep the historical q80 regardless of their use case.
bool _isGif(String imageUrl) {
  final uri = Uri.tryParse(imageUrl.trim());
  final path = uri?.path ?? imageUrl.split('?').first;
  return path.toLowerCase().endsWith('.gif');
}

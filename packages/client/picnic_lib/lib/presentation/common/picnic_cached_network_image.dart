import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:picnic_lib/core/config/environment.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/ui.dart';
import 'package:picnic_lib/core/utils/webp_support_checker.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:universal_platform/universal_platform.dart';

class PicnicCachedNetworkImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final BorderRadius? borderRadius;

  const PicnicCachedNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.memCacheWidth,
    this.memCacheHeight,
    this.borderRadius,
  });

  @override
  State<PicnicCachedNetworkImage> createState() =>
      _PicnicCachedNetworkImageState();
}

class _PicnicCachedNetworkImageState extends State<PicnicCachedNetworkImage> {
  bool _loading = true;

  bool get isGif => widget.imageUrl.toLowerCase().endsWith('.gif');

  @override
  void initState() {
    super.initState();
    if (isGif) {
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
    }
  }

  double _getResolutionMultiplier(BuildContext context) {
    if (UniversalPlatform.isWeb) return 2.0;
    if (UniversalPlatform.isAndroid) return 1.5;
    if (isIPad(context)) return 4.0;
    return 2.0;
  }

  List<String> _getTransformedUrls(
      BuildContext context, double resolutionMultiplier) {
    // 웹 환경에서는 고품질 이미지만 로드 (다중 해상도 불필요)
    if (UniversalPlatform.isWeb) {
      return [
        _getTransformedUrl(
            widget.imageUrl, resolutionMultiplier, 90), // 웹에서는 최고 품질 사용
      ];
    }

    // 모바일 환경에서는 점진적 로딩을 위해 여러 해상도 제공
    return [
      _getTransformedUrl(widget.imageUrl, resolutionMultiplier * .2, 20),
      _getTransformedUrl(widget.imageUrl, resolutionMultiplier * .5, 50),
      // 중간품질
      _getTransformedUrl(widget.imageUrl, resolutionMultiplier, 80),
    ];
  }

  String _getTransformedUrl(
      String key, double resolutionMultiplier, int quality) {
    Uri uri = Uri.parse('${Environment.cdnUrl}/$key');

    Map<String, String> queryParameters = {
      if (widget.width != null)
        'w': ((widget.width!).toInt() * resolutionMultiplier).toString(),
      if (widget.height != null)
        'h': ((widget.height!).toInt() * resolutionMultiplier).toString(),
      'q': quality.toString(),
    };

    // GIF는 변환하지 않고 원본 그대로 사용
    if (!isGif) {
      // 웹 환경에서는 대부분의 브라우저가 webp를 지원한다고 가정
      if (UniversalPlatform.isWeb) {
        // 웹에서는 webp 포맷 사용 (대부분의 모던 브라우저 지원)
        queryParameters['f'] = 'webp';
      } else {
        // 모바일 환경에서는 기존 로직 유지
        queryParameters['f'] =
            WebPSupportChecker.instance.supportInfo != null &&
                    WebPSupportChecker.instance.supportInfo!.webp
                ? 'webp'
                : 'png';
      }
    }

    return uri.replace(queryParameters: queryParameters).toString();
  }

  Widget _buildCachedNetworkImage(
      String url, double? width, double? height, int index) {
    try {
      return Container(
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius ?? BorderRadius.zero,
        ),
        child: ClipRRect(
          borderRadius: widget.borderRadius ?? BorderRadius.zero,
          child: CachedNetworkImage(
            key: ValueKey(
                '${url}_$index${isGif ? '_${DateTime.now().millisecondsSinceEpoch}' : ''}'),
            imageUrl: url,
            width: width,
            height: height,
            fit: widget.fit,
            memCacheWidth: widget.memCacheWidth,
            memCacheHeight: widget.memCacheHeight,
            errorWidget: (context, url, error) {
              logger.e('Image loading error: $error for url: $url');
              // 오류 발생 시 기본 이미지나 오류 표시 위젯 반환
              return Container(
                width: width,
                height: height,
                color: Colors.grey[200],
                child: const Center(
                  child: Icon(Icons.image_not_supported, color: Colors.grey),
                ),
              );
            },
            progressIndicatorBuilder: (context, url, downloadProgress) =>
                buildLoadingOverlay(),
            imageBuilder: (context, imageProvider) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    _loading = false;
                  });
                }
              });

              return Image(
                key: ValueKey(
                    'image_${url}_$index${isGif ? '_${DateTime.now().millisecondsSinceEpoch}' : ''}'),
                image: imageProvider,
                fit: widget.fit,
                width: width,
                height: height,
                gaplessPlayback: false,
              );
            },
          ),
        ),
      );
    } catch (e, s) {
      logger.e('error', error: e, stackTrace: s);
      Sentry.captureException(e, stackTrace: s);
      return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageWidth = widget.width;
    final imageHeight = widget.height;
    final resolutionMultiplier = _getResolutionMultiplier(context);
    final urls = _getTransformedUrls(context, resolutionMultiplier);

    return SizedBox(
      width: imageWidth,
      height: imageHeight,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (_loading)
            ClipRRect(
              borderRadius: widget.borderRadius ?? BorderRadius.zero,
              child: buildLoadingOverlay(),
            ),
          ...urls.asMap().entries.map((entry) => _buildCachedNetworkImage(
                entry.value,
                imageWidth,
                imageHeight,
                entry.key,
              )),
        ],
      ),
    );
  }
}

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_app/config/environment.dart';
import 'package:picnic_app/util/logger.dart';
import 'package:picnic_app/util/ui.dart';
import 'package:picnic_app/util/webp_support_checker.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:universal_platform/universal_platform.dart';

class PicnicCachedNetworkImage extends StatefulWidget {
  final String imageUrl;
  final int? width;
  final int? height;
  final BoxFit? fit;
  final bool useScreenUtil;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final int? duration;

  const PicnicCachedNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.useScreenUtil = true,
    this.memCacheWidth,
    this.memCacheHeight,
    this.duration,
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
    return [
      _getTransformedUrl(widget.imageUrl, resolutionMultiplier * .2, 20),
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

    if (!isGif) {
      queryParameters['f'] =
          WebPSupportChecker.instance.supportsWebP ? 'webp' : 'png';
    }

    return uri.replace(queryParameters: queryParameters).toString();
  }

  Widget _buildCachedNetworkImage(
      String url, double? width, double? height, int index) {
    try {
      return CachedNetworkImage(
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
          return const SizedBox.shrink();
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
      );
    } catch (e, s) {
      logger.e(e, stackTrace: s);
      Sentry.captureException(e, stackTrace: s);
      return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageWidth = widget.useScreenUtil
        ? widget.width?.cw.toDouble()
        : widget.width?.toDouble();
    final imageHeight = widget.useScreenUtil
        ? widget.height?.h.toDouble()
        : widget.height?.toDouble();
    final resolutionMultiplier = _getResolutionMultiplier(context);
    final urls = _getTransformedUrls(context, resolutionMultiplier);

    return SizedBox(
      width: imageWidth,
      height: imageHeight,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (_loading) buildLoadingOverlay(),
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

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_app/config/environment.dart';
import 'package:picnic_app/util/ui.dart';
import 'package:universal_platform/universal_platform.dart';

class PicnicCachedNetworkImage extends StatelessWidget {
  final String imageUrl;
  final int? width;
  final int? height;
  final BoxFit? fit;
  final ImageWidgetBuilder? imageBuilder;
  final bool useScreenUtil;
  final int? memCacheWidth;
  final int? memCacheHeight;

  const PicnicCachedNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.useScreenUtil = true,
    this.imageBuilder,
    this.memCacheWidth,
    this.memCacheHeight,
  });

  double _getResolutionMultiplier(BuildContext context) {
    if (UniversalPlatform.isWeb) return 1.0;
    if (UniversalPlatform.isAndroid) return 1.5;
    if (isIPad(context)) return 4.0;
    return 2.0;
  }

  List<String> _getTransformedUrls(
      BuildContext context, double resolutionMultiplier) {
    return [
      _getTransformedUrl(imageUrl, resolutionMultiplier * 0.1, 20),
      _getTransformedUrl(imageUrl, resolutionMultiplier * .8, 50),
      _getTransformedUrl(imageUrl, resolutionMultiplier, 80),
    ];
  }

  String _getTransformedUrl(
      String key, double resolutionMultiplier, int quality) {
    Uri uri = Uri.parse('${Environment.cdnUrl}/$key');
    Map<String, String> queryParameters = {};
    if (width != null) {
      queryParameters['w'] = (width! * resolutionMultiplier).toInt().toString();
    }
    if (height != null) {
      queryParameters['h'] =
          (height! * resolutionMultiplier).toInt().toString();
    }
    queryParameters['q'] = quality.toString();
    queryParameters['f'] = 'webp';
    return uri.replace(queryParameters: queryParameters).toString();
  }

  Widget _buildCachedNetworkImage(String url, double? width, double? height) {
    return CachedNetworkImage(
      key: ValueKey(url),
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: memCacheWidth,
      memCacheHeight: memCacheHeight,
      errorWidget: (context, url, error) => const SizedBox.shrink(),
      imageBuilder: imageBuilder,
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageWidth = useScreenUtil ? width?.w.toDouble() : width?.toDouble();
    final imageHeight =
        useScreenUtil ? height?.h.toDouble() : height?.toDouble();
    final resolutionMultiplier = _getResolutionMultiplier(context);
    final urls = _getTransformedUrls(context, resolutionMultiplier);

    return SizedBox(
      width: imageWidth,
      height: imageHeight,
      child: Stack(
        alignment: Alignment.center,
        children: [
          buildLoadingOverlay(),
          ...urls.map(
              (url) => _buildCachedNetworkImage(url, imageWidth, imageHeight)),
        ],
      ),
    );
  }
}

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_app/config/environment.dart';
import 'package:picnic_app/util/ui.dart';
import 'package:universal_platform/universal_platform.dart';

class PicnicCachedNetworkImage extends StatefulWidget {
  final String imageUrl;
  final int? width;
  final int? height;
  final BoxFit? fit;
  final ImageWidgetBuilder? imageBuilder;
  bool? useScreenUtil = true;
  final int? memCacheWidth;
  final int? memCacheHeight;

  PicnicCachedNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.useScreenUtil,
    this.imageBuilder,
    this.memCacheWidth,
    this.memCacheHeight,
  });

  @override
  _PicnicCachedNetworkImageState createState() =>
      _PicnicCachedNetworkImageState();
}

class _PicnicCachedNetworkImageState extends State<PicnicCachedNetworkImage> {
  double getResolutionMultiplier(BuildContext context) {
    if (UniversalPlatform.isWeb) {
      return 1.0;
    } else if (UniversalPlatform.isAndroid) {
      return 1.5;
    } else if (isIPad(context)) {
      return 4.0;
    } else {
      return 2.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final resolutionMultiplier = getResolutionMultiplier(context);

    final urls = [
      getTransformedUrl(widget.imageUrl, resolutionMultiplier * 0.1, 20),
      getTransformedUrl(widget.imageUrl, resolutionMultiplier, 50),
      getTransformedUrl(widget.imageUrl, resolutionMultiplier * 3, 80),
    ];
    return widget.useScreenUtil == true
        ? SizedBox(
            width: widget.width?.w.toDouble(),
            height: widget.height?.h.toDouble(),
            child: Stack(alignment: Alignment.center, children: [
              buildLoadingOverlay(),
              ...urls.map(_buildCachedNetworkImage),
            ]),
          )
        : SizedBox(
            width: widget.width?.toDouble(),
            height: widget.height?.toDouble(),
            child: Stack(alignment: Alignment.center, children: [
              buildLoadingOverlay(),
              ...urls.map(_buildCachedNetworkImage),
            ]),
          );
  }

  Widget _buildCachedNetworkImage(String url) {
    return widget.useScreenUtil == true
        ? CachedNetworkImage(
            imageUrl: url,
            width: widget.width?.w.toDouble(),
            height: widget.height?.h.toDouble(),
            fit: widget.fit,
            memCacheWidth: widget.memCacheWidth,
            memCacheHeight: widget.memCacheHeight,
            errorWidget: (context, url, error) => Container(),
          )
        : CachedNetworkImage(
            imageUrl: url,
            width: widget.width?.toDouble(),
            height: widget.height?.toDouble(),
            fit: widget.fit,
            memCacheWidth: widget.memCacheWidth,
            memCacheHeight: widget.memCacheHeight,
            errorWidget: (context, url, error) => Container());
  }

  String getTransformedUrl(
      String key, double resolutionMultiplier, int quality) {
    // return '${Environment.cdnUrl}/$key?w=${(widget.width! * resolutionMultiplier).toInt()}&h=${(widget.height! * resolutionMultiplier).toInt()}&q=$quality&f=webp';
    return '${Environment.cdnUrl}/$key';
  }
}

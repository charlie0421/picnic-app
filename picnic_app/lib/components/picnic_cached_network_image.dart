import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:picnic_app/util.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:universal_platform/universal_platform.dart';

class PicnicCachedNetworkImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final ImageWidgetBuilder? imageBuilder;

  const PicnicCachedNetworkImage({
    Key? key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.imageBuilder,
  }) : super(key: key);

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

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Stack(alignment: Alignment.center, children: [
        buildLoadingOverlay(),
        ...urls.asMap().entries.map((entry) {
          int index = entry.key;
          String url = entry.value;
          return CachedNetworkImage(
            imageUrl: url,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
            imageBuilder: (context, imageProvider) {
              return Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: imageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
            errorWidget: (context, url, error) => Container(),
          );
        }).toList(),
      ]),
    );
  }

  String getTransformedUrl(
      String key, double resolutionMultiplier, int quality) {
    final transformOptions = TransformOptions(
      width: widget.width != null
          ? (widget.width! * resolutionMultiplier).toInt()
          : null,
      height: widget.height != null
          ? (widget.height! * resolutionMultiplier).toInt()
          : null,
      quality: quality,
    );
    return supabase.storage
        .from('picnic')
        .getPublicUrl(key, transform: transformOptions);
  }
}

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/util.dart';

class PicnicCachedNetworkImage extends StatelessWidget {
  PicnicCachedNetworkImage(
      {super.key,
      required this.imageUrl,
      this.width,
      this.height,
      this.fit,
      this.quality = 80,
      this.format = 'webp'});

  final String imageUrl;
  final double? width;
  final double? height;
  BoxFit? fit = BoxFit.cover;
  double quality;
  String format;

  final multiple = 2.0;

  @override
  Widget build(BuildContext context) {
    assert(width != null || height != null, 'Width or height must be provided');

    String modifiedUrl = imageUrl;
    if (width != null) {
      modifiedUrl += '?w=${(width! * multiple).toInt()}';
    }
    if (height != null) {
      modifiedUrl +=
          (width != null ? '&' : '?') + 'h=${(height! * multiple).toInt()}';
    }
    modifiedUrl += '&q=$quality&f=$format';

    return Container(
      width: width,
      height: height,
      child: CachedNetworkImage(
          imageUrl: modifiedUrl,
          width: width,
          height: height,
          placeholder: (context, url) => buildPlaceholderImage(),
          errorWidget: (context, url, error) {
            logger.e('Error loading image: $error');
            return buildPlaceholderImage();
          },
          fit: fit),
    );
  }
}

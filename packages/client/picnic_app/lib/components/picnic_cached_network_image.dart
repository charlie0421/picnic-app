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

  final lowResMultiplier = 0.5;
  final midResMultiplier = 1.5;
  final highResMultiplier = 3.0;

  @override
  Widget build(BuildContext context) {
    assert(width != null || height != null, 'Width or height must be provided');

    String lowResUrl = imageUrl;
    String midResUrl = imageUrl;
    String highResUrl = imageUrl;

    // Construct low resolution URL
    lowResUrl += '?q=10&f=$format';
    if (width != null) {
      lowResUrl += '&w=${(width! * lowResMultiplier).toInt()}';
    }
    if (height != null) {
      lowResUrl += '&h=${(height! * lowResMultiplier).toInt()}';
    }

    // Construct mid resolution URL
    midResUrl += '?q=50&f=$format';
    if (width != null) {
      midResUrl += '&w=${(width! * midResMultiplier).toInt()}';
    }
    if (height != null) {
      midResUrl += '&h=${(height! * midResMultiplier).toInt()}';
    }

    // Construct high resolution URL
    highResUrl += '?q=$quality&f=$format';
    if (width != null) {
      highResUrl += '&w=${(width! * highResMultiplier).toInt()}';
    }
    if (height != null) {
      highResUrl += '&h=${(height! * highResMultiplier).toInt()}';
    }

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          CachedNetworkImage(
            imageUrl: lowResUrl,
            width: width,
            height: height,
            fit: fit,
            // placeholder: (context, url) => buildPlaceholderImage(),
            errorWidget: (context, url, error) {
              logger.e('Error loading low-res image: $error');
              return buildPlaceholderImage();
            },
          ),
          CachedNetworkImage(
            imageUrl: midResUrl,
            width: width,
            height: height,
            fit: fit,
            // placeholder: (context, url) => buildPlaceholderImage(),
            errorWidget: (context, url, error) {
              logger.e('Error loading mid-res image: $error');
              return Container();
            },
          ),
          CachedNetworkImage(
            imageUrl: highResUrl,
            width: width,
            height: height,
            fit: fit,
            // placeholder: (context, url) => buildPlaceholderImage(),
            errorWidget: (context, url, error) {
              logger.e('Error loading high-res image: $error');
              return Container();
            },
          ),
        ],
      ),
    );
  }
}

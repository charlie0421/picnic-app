import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:picnic_app/util.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:universal_platform/universal_platform.dart';

class PicnicCachedNetworkImage extends StatelessWidget {
  PicnicCachedNetworkImage({
    super.key,
    required this.Key,
    this.width,
    this.height,
    this.fit,
  });

  final String Key;
  final double? width;
  final double? height;
  BoxFit? fit = BoxFit.cover;

  // Resolution multipliers
  final double webResMultiplier = 1.0;
  final double androidResMultiplier = 1.5;
  final double iosResMultiplier = 2.0;
  final double ipadResMultiplier = 4.0;

  @override
  Widget build(BuildContext context) {
    double resolutionMultiplier = 1.0; // Default multiplier

    if (kIsWeb) {
      resolutionMultiplier = webResMultiplier;
    } else if (UniversalPlatform.isAndroid) {
      resolutionMultiplier = androidResMultiplier;
    } else if (isIPad(context)) {
      resolutionMultiplier = ipadResMultiplier;
    } else {
      resolutionMultiplier = iosResMultiplier;
    }

    final lowResUrl = supabase.storage.from('picnic').getPublicUrl(
          Key,
          transform: TransformOptions(
            width: width != null
                ? (width! * resolutionMultiplier * 0.05).toInt()
                : null,
            height: height != null
                ? (height! * resolutionMultiplier * 0.05).toInt()
                : null,
            quality: 20,
          ),
        );

    final midResUrl = supabase.storage.from('picnic').getPublicUrl(
          Key,
          transform: TransformOptions(
            width:
                width != null ? (width! * resolutionMultiplier).toInt() : null,
            height: height != null
                ? (height! * resolutionMultiplier).toInt()
                : null,
            quality: 50,
          ),
        );

    final highResUrl = supabase.storage.from('picnic').getPublicUrl(
          Key,
          transform: TransformOptions(
            width: width != null
                ? (width! * resolutionMultiplier * 3).toInt()
                : null,
            height: height != null
                ? (height! * resolutionMultiplier * 3).toInt()
                : null,
            quality: 80,
          ),
        );

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
            errorWidget: (context, url, error) => Container(),
          ),
          CachedNetworkImage(
            imageUrl: midResUrl,
            width: width,
            height: height,
            fit: fit,
            errorWidget: (context, url, error) => Container(),
          ),
          CachedNetworkImage(
            imageUrl: highResUrl,
            width: width,
            height: height,
            fit: fit,
            errorWidget: (context, url, error) => Container(),
          ),
        ],
      ),
    );
  }
}

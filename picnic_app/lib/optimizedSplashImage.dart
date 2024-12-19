import 'dart:io';

import 'package:flutter/material.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/logger.dart';

class OptimizedSplashImage extends StatelessWidget {
  const OptimizedSplashImage({super.key});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      _getOptimizedImagePath(),
      fit: BoxFit.cover,
      cacheWidth: 800,
      cacheHeight: 1600,
      errorBuilder: (context, error, stackTrace) {
        logger.e('error:', error: error, stackTrace: stackTrace);
        return Container(
            width: double.infinity,
            height: double.infinity,
            color: AppColors.primary500);
      },
    );
  }

  String _getOptimizedImagePath() {
    if (Platform.isIOS) {
      try {
        final version = Platform.operatingSystemVersion;
        final major = int.tryParse(
            version.split('.').first.replaceAll(RegExp(r'[^0-9]'), ''));
        if (major != null && major >= 14) {
          return 'assets/splash.webp';
        }
      } catch (e, s) {
        logger.e('Failed to parse iOS version', error: e, stackTrace: s);
      }
      return 'assets/splash.png';
    }
    return 'assets/splash.webp';
  }
}

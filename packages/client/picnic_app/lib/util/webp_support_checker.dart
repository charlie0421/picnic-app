import 'dart:async';

import 'package:flutter/services.dart';
import 'package:picnic_app/util/logger.dart';

class WebPSupportChecker {
  static const platform =
      MethodChannel('io.iconcasting.picnic.app/webp_support');
  static WebPSupportChecker? _instance;
  bool? _supportsWebP;

  WebPSupportChecker._();

  static WebPSupportChecker get instance {
    _instance ??= WebPSupportChecker._();
    return _instance!;
  }

  Future<void> initialize() async {
    try {
      final bool result = await platform.invokeMethod('isWebPSupported');
      _supportsWebP = result;
    } on PlatformException catch (e, s) {
      logger.e("Failed to get WebP support: '${e.message}'.", stackTrace: s);
      _supportsWebP = false;
    }
  }

  bool get supportsWebP => _supportsWebP ?? false;
}

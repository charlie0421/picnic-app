import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:picnic_lib/supabase_options.dart';

class ReceiptVerificationService {
  static const String _sandboxEnvironment = 'sandbox';
  static const String _productionEnvironment = 'production';

  Future<void> verifyReceipt(String receipt, String productId, String userId,
      String environment) async {
    final response = await supabase.functions.invoke('verify_receipt', body: {
      'receipt': receipt,
      'platform': Platform.isIOS ? 'ios' : 'android',
      'productId': productId,
      'user_id': userId,
      'environment': environment,
    });

    if (response.status != 200 || response.data['success'] != true) {
      throw Exception('Receipt verification failed');
    }
  }

  Future<String> getEnvironment() async {
    if (kDebugMode) return _sandboxEnvironment;

    final packageInfo = await PackageInfo.fromPlatform();

    if (Platform.isIOS) {
      return packageInfo.installerStore == 'com.apple.testflight'
          ? _sandboxEnvironment
          : _productionEnvironment;
    } else if (Platform.isAndroid) {
      final installer = packageInfo.installerStore;
      if (installer == null || installer == 'com.android.vending') {
        return _productionEnvironment;
      } else if (installer == 'com.google.android.apps.internal.testing') {
        return _sandboxEnvironment;
      } else {
        return _sandboxEnvironment;
      }
    }

    return 'unknown';
  }
}

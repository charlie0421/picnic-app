import 'dart:io';

import 'package:flutter/services.dart';

/// The shared library's loader uses an asset supplied by the host app.
/// Read its real bytes in widget tests instead of hiding image decode errors.
final hostAppAssetBundle = _HostAppAssetBundle();

class _HostAppAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    if (key != 'assets/app_icon_128.png') return rootBundle.load(key);

    final icon = [
      File('../picnic_app/assets/app_icon_128.png'),
      File('picnic_app/assets/app_icon_128.png'),
    ].firstWhere((file) => file.existsSync());
    return ByteData.sublistView(await icon.readAsBytes());
  }
}

// ignore: file_names
import 'package:universal_platform/universal_platform.dart';

import 'package:flutter/services.dart';
import 'package:picnic_lib/core/utils/logger.dart';

class PincruxOfferwallPlugin {
  static const MethodChannel _channel =
      MethodChannel("com.pincrux.offerwall.flutter");

  static void init(String? pubkey, String? usrkey) async {
    await _channel.invokeMethod("init", {'pubkey': pubkey, 'usrkey': usrkey});
  }

  static void setOfferwallViewControllerType(int type) async {
    if (UniversalPlatform.isIOS) {
      await _channel
          .invokeListMethod("setOfferwallViewControllerType", {'type': type});
    }
  }

  static void startPincruxOfferwall() async {
    logger.i('startPincruxOfferwall');
    await _channel.invokeMethod("startOfferwall");
  }

  static void startPincruxOfferwallViewType() async {
    await _channel.invokeMethod("startPincruxOfferwallViewType");
  }

  static void startPincruxOfferwallAdDetail(String? appkey) async {
    await _channel
        .invokeMethod("startPincruxOfferwallAdDetail", {'appkey': appkey});
  }

  static void startPincruxOfferwallContact() async {
    await _channel.invokeMethod("startPincruxOfferwallContact");
  }

  // Offerwall View Options
  static void setOfferwallType(int type) async {
    await _channel.invokeMethod("setOfferwallType", {'type': type});
    // await _channel.invokeMethod("setOfferwallType", type);
  }

  static void setEnableTab(bool isEnable) async {
    await _channel.invokeMethod("setEnableTab", {'isEnable': isEnable});
  }

  static void setOfferwallTitle(String? title) async {
    await _channel.invokeMethod("setOfferwallTitle", {'title': title});
  }

  static void setOfferwallThemeColor(String? color) async {
    await _channel.invokeMethod("setOfferwallThemeColor", {'color': color});
  }

  static void setEnableScrollTopButton(bool isEnable) async {
    await _channel
        .invokeMethod("setEnableScrollTopButton", {'isEnable': isEnable});
  }

  static void setAdDetail(bool isEnable) async {
    await _channel.invokeMethod("setAdDetail", {'isEnable': isEnable});
  }

  static void setDisableCPS(bool isDisable) async {
    await _channel.invokeMethod("setDisableCPS", {'isDisable': isDisable});
  }

  static void setDarkMode(int mode) async {
    await _channel.invokeMethod("setDarkMode", {'mode': mode});
  }
}

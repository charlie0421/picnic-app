import 'dart:io';

import 'package:flutter/material.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:shimmer/shimmer.dart';
import 'package:universal_platform/universal_platform.dart';

void showOverlayToast(BuildContext context, Widget child) {
  OverlayEntry overlayEntry = OverlayEntry(
    builder: (context) => Center(
      child: Container(
        width: getPlatformScreenSize(context).width * 0.5,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.Grey100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: child,
      ),
    ),
  );

  Overlay.of(context).insert(overlayEntry);

  Future.delayed(const Duration(seconds: 1), () {
    overlayEntry.remove();
  });
}

Widget buildPlaceholderImage() {
  return Shimmer.fromColors(
    baseColor: AppColors.Grey200,
    highlightColor: AppColors.Grey100,
    child: Container(
      color: AppColors.Grey00,
    ),
  );
}

Widget buildLoadingOverlay() {
  return Shimmer.fromColors(
    baseColor: AppColors.Grey300,
    highlightColor: AppColors.Grey100,
    child: Container(
      color: AppColors.Grey00,
    ),
  );
}

Size getPlatformScreenSize(BuildContext context) {
  if (UniversalPlatform.isWeb) {
    return const Size(393 * 2, 852 * 2);
  }
  return MediaQuery.of(context).size;
}

Future<bool> checkSuperAdmin() async {
  final response =
      await supabase.from('auth.users').select('is_super_admin').single();

  logger.i('response[\'is_super_admin\'] : ${response['is_super_admin']}');
  if (response['is_super_admin'] == true) {
    return true;
  }

  return true;
}

bool isIPad(BuildContext context) {
  if (!UniversalPlatform.isIOS) return false;
  final Size screenSize = getPlatformScreenSize(context);
  // Typical iPad screen size ranges
  const double iPadSizeThreshold = 768.0; // Width in portrait mode
  return screenSize.width >= iPadSizeThreshold ||
      screenSize.height >= iPadSizeThreshold;
}

Color getComplementaryColor(Color color) {
  // RGB 채널에서 각 값을 255에서 빼서 보색을 찾습니다.
  int red = 255 - color.red;
  int green = 255 - color.green;
  int blue = 255 - color.blue;

  // 계산된 RGB 값을 사용하여 새로운 Color 객체를 생성합니다.
  return Color.fromARGB(255, red, green, blue);
}

bool isIOS() {
  if (UniversalPlatform.isWeb) {
    return false;
  }
  return Platform.isIOS;
}

bool isAndroid() {
  return Platform.isAndroid;
}

bool isMobile() {
  if (UniversalPlatform.isWeb) {
    return false;
  } else {
    try {
      return Platform.isAndroid || Platform.isIOS;
    } catch (e) {
      return false;
    }
  }
}

bool isDesktop() {
  return Platform.isMacOS || Platform.isWindows || Platform.isLinux;
}

bool isMacOS() {
  return Platform.isMacOS;
}

bool isWindows() {
  return Platform.isWindows;
}

bool isLinux() {
  return Platform.isLinux;
}

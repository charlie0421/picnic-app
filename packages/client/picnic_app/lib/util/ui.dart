import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/logger.dart';
import 'package:shimmer/shimmer.dart';
import 'package:universal_platform/universal_platform.dart';

import '../providers/global_media_query.dart';

void showOverlayToast(BuildContext context, Widget child) {
  OverlayEntry overlayEntry = OverlayEntry(
    builder: (context) => Center(
      child: Container(
        width: getPlatformScreenSize(context).width * 0.5,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.grey100,
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
    baseColor: AppColors.grey200,
    highlightColor: AppColors.grey100,
    child: Container(
      color: AppColors.grey00,
    ),
  );
}

Widget buildLoadingOverlay() {
  return Shimmer.fromColors(
    baseColor: AppColors.grey300,
    highlightColor: AppColors.grey100,
    child: Container(
      color: AppColors.grey00,
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
    } catch (e, s) {
      logger.e(e, stackTrace: s);
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

extension CustomSizeExtension on num {
  double get cw => kIsWeb ? (this * 600 / 393) : w;

  double get ch => kIsWeb ? (this * 800 / 852) : h;
}

double getAppBarHeight(WidgetRef ref) {
  final mediaQuery = ref.watch(globalMediaQueryProvider);
  final double topPadding = mediaQuery.padding.top;

  // 안전 영역 상단 패딩 (노치, 상태 바 등을 포함)
  double safeAreaTop = topPadding;

  // AppBar의 기본 높이
  const double appBarHeight = kToolbarHeight; // 일반적으로 56.0

  // 총 AppBar 높이 (안전 영역 상단 + AppBar)
  return safeAreaTop + appBarHeight;
}

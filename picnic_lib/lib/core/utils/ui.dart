import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/presentation/widgets/ui/pulse_loading_indicator.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:shimmer/shimmer.dart';
import 'package:universal_platform/universal_platform.dart';

import '../../presentation/providers/global_media_query.dart';

void showOverlayToast(BuildContext context, Widget child) {
  // 1) 가능한 모든 경로로 OverlayState 획득 시도
  final overlayState =
      Navigator.maybeOf(context, rootNavigator: true)?.overlay ??
          Overlay.maybeOf(context, rootOverlay: true) ??
          Overlay.maybeOf(context);

  if (overlayState != null) {
    final overlayEntry = OverlayEntry(
      builder: (ctx) => Center(
        child: Container(
          width: getPlatformScreenSize(ctx).width * 0.5,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.grey100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: child,
        ),
      ),
    );
    overlayState.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 1), () => overlayEntry.remove());
    return;
  }

  // 2) Fallback: ScaffoldMessenger 스낵바로 표시
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger != null) {
    messenger.showSnackBar(SnackBar(
      content: child,
      duration: const Duration(seconds: 1),
      behavior: SnackBarBehavior.floating,
    ));
    return;
  }

  // 3) 최후 Fallback: 다이얼로그로 1초 표시 후 자동 닫기
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Center(
        child: Container(
          width: getPlatformScreenSize(ctx).width * 0.6,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.grey100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: child,
        ),
      ),
    ),
  );
  Future.delayed(const Duration(seconds: 1), () {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
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
  return const Center(
    child: MediumPulseLoadingIndicator(),
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
  int red = 255 - color.r.toInt();
  int green = 255 - color.g.toInt();
  int blue = 255 - color.b.toInt();

  return Color.fromARGB(255, red, green, blue);
}

bool isIOS() {
  if (UniversalPlatform.isWeb) return false;
  return UniversalPlatform.isIOS;
}

bool isAndroid() {
  if (UniversalPlatform.isWeb) return false;
  return UniversalPlatform.isAndroid;
}

bool isMobile() {
  if (UniversalPlatform.isWeb) return false;
  return UniversalPlatform.isIOS || UniversalPlatform.isAndroid;
}

bool isDesktop() {
  if (UniversalPlatform.isWeb) return false;
  return UniversalPlatform.isMacOS ||
      UniversalPlatform.isWindows ||
      UniversalPlatform.isLinux;
}

bool isMacOS() {
  if (UniversalPlatform.isWeb) return false;
  return UniversalPlatform.isMacOS;
}

bool isWindows() {
  if (UniversalPlatform.isWeb) return false;
  return UniversalPlatform.isWindows;
}

bool isLinux() {
  if (UniversalPlatform.isWeb) return false;
  return UniversalPlatform.isLinux;
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

double getBottomPadding(BuildContext context) {
  return MediaQuery.of(context).padding.bottom > 34
      ? 20
      : MediaQuery.of(context).padding.bottom + 20;
}

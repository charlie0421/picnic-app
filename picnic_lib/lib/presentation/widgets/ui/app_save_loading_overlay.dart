import 'package:flutter/material.dart';
import 'package:picnic_lib/presentation/widgets/ui/loading_overlay_with_icon.dart';

/// 저장/공유 시 쓰는 앱 공통 아이콘 펄스 오버레이(작은 사이즈로 통일).
///
/// 자식 트리의 위젯이 `context.showLoadingWithIcon()` /
/// `context.hideLoadingWithIcon()` (또는 `LoadingOverlayWithIcon.of(context)`)
/// 로 이 오버레이를 제어한다. 홈·투표 상세·투표 리스트에서 동일하게 쓴다.
class AppSaveLoadingOverlay extends StatelessWidget {
  final Widget child;

  const AppSaveLoadingOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LoadingOverlayWithIcon(
      enableRotation: false,
      enableScale: true,
      enableFade: true,
      loadingMessage: null,
      iconAssetPath: 'assets/app_icon_128.png',
      iconSize: 40, // 기본 64 는 커서 작게 통일
      scaleDuration: const Duration(milliseconds: 800),
      fadeDuration: const Duration(milliseconds: 800),
      minScale: 0.98,
      maxScale: 1.02,
      showProgressIndicator: false,
      child: child,
    );
  }
}

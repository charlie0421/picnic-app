import 'package:flutter/material.dart';
import 'package:overlay_loading_progress/overlay_loading_progress.dart';
import 'package:picnic_lib/presentation/widgets/ui/pulse_loading_indicator.dart';

/// 무료 충전 광고 구좌가 공유하는 중앙 로딩 UI.
///
/// OverlayLoadingProgress의 전역 오버레이는 유지하되, 구좌별로 달랐던
/// CircularProgressIndicator를 Internal 숏폼과 같은 Pulse 인디케이터로
/// 통일한다.
class AdLoadingOverlay {
  const AdLoadingOverlay._();

  static const Widget indicator = MediumPulseLoadingIndicator();

  static Future<void> start(BuildContext context) async {
    await OverlayLoadingProgress.start(
      context,
      widget: indicator,
      barrierColor: Colors.black54,
      barrierDismissible: false,
    );
  }

  static void stop() {
    OverlayLoadingProgress.stop();
  }
}

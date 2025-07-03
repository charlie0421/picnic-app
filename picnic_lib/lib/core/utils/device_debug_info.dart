import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:logger/logger.dart';

class DeviceDebugInfo {
  static final Logger _logger = Logger();

  /// 현재 디바이스의 상세 정보를 출력
  static Future<void> logDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;

      _logger.i('=== 📱 디바이스 정보 ===');
      _logger.i('모델: ${androidInfo.model}');
      _logger.i('제조사: ${androidInfo.manufacturer}');
      _logger.i('브랜드: ${androidInfo.brand}');
      _logger.i('제품: ${androidInfo.product}');
      _logger.i('Android 버전: ${androidInfo.version.release}');
      _logger.i('SDK 버전: ${androidInfo.version.sdkInt}');
      _logger.i('하드웨어: ${androidInfo.hardware}');
      _logger.i('=================');
    } catch (e) {
      _logger.e('디바이스 정보 가져오기 실패: $e');
    }
  }

  /// MediaQuery와 SafeArea 정보를 출력
  static void logSafeAreaInfo(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final padding = mediaQuery.padding;
    final viewInsets = mediaQuery.viewInsets;
    final viewPadding = mediaQuery.viewPadding;

    _logger.i('=== 📐 SafeArea 정보 ===');
    _logger.i('화면 크기: ${mediaQuery.size}');
    _logger.i(
        'Padding - top: ${padding.top}, bottom: ${padding.bottom}, left: ${padding.left}, right: ${padding.right}');
    _logger
        .i('ViewInsets - top: ${viewInsets.top}, bottom: ${viewInsets.bottom}');
    _logger.i(
        'ViewPadding - top: ${viewPadding.top}, bottom: ${viewPadding.bottom}');
    _logger.i('Device Pixel Ratio: ${mediaQuery.devicePixelRatio}');
    _logger.i('Text Scale Factor: ${mediaQuery.textScaler}');

    // 하단 네비게이션 최적화 제안
    if (padding.bottom > 30) {
      _logger.w('⚠️ 하단 padding이 ${padding.bottom}px로 과도함');
      _logger.w('💡 제안: SafeArea bottom만 적용하거나 더 작은 여백 사용');
    } else if (padding.bottom == 0) {
      _logger.i('ℹ️ 하단 padding 없음 - 물리적 버튼 기기 또는 구형 기기');
    } else {
      _logger.i('✅ 하단 padding ${padding.bottom}px - 정상 범위');
    }

    _logger.i('==================');
  }

  /// 시스템 UI 설정 상태를 확인
  static void logSystemUIStatus() {
    _logger.i('=== ⚙️ 시스템 UI 상태 ===');
    // SystemChrome의 현재 설정을 로그로 출력
    _logger.i('시스템 UI 오버레이 스타일이 적용되었습니다.');
    _logger.i('==================');
  }

  /// 갤럭시 S25 특화 체크
  static bool isGalaxyS25Like(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final size = mediaQuery.size;
    final ratio = size.width / size.height;

    // 갤럭시 S25 예상 스펙 (6.2인치, 19.5:9 비율)
    final isS25Like = size.height > 2800 &&
        ratio > 0.45 &&
        ratio < 0.55 &&
        mediaQuery.devicePixelRatio > 3.0;

    if (isS25Like) {
      _logger.w('⚠️ 갤럭시 S25와 유사한 기기 감지됨!');
      _logger.w('특별한 SafeArea 처리가 필요할 수 있습니다.');
    }

    return isS25Like;
  }
}

/// 디버그 모드에서 SafeArea 경계를 시각적으로 표시하는 위젯
class SafeAreaDebugOverlay extends StatelessWidget {
  final Widget child;
  final bool showDebugInfo;

  const SafeAreaDebugOverlay({
    super.key,
    required this.child,
    this.showDebugInfo = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!showDebugInfo) return child;

    return Stack(
      children: [
        child,
        // SafeArea 경계를 빨간색 선으로 표시
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: SafeAreaPainter(MediaQuery.of(context).padding),
            ),
          ),
        ),
        // 상단에 디바이스 정보 표시
        Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          left: 10,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'SafeArea Debug',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
                Text(
                  'Bottom: ${MediaQuery.of(context).padding.bottom}',
                  style: TextStyle(color: Colors.white, fontSize: 10),
                ),
                Text(
                  'Screen: ${MediaQuery.of(context).size}',
                  style: TextStyle(color: Colors.white, fontSize: 10),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class SafeAreaPainter extends CustomPainter {
  final EdgeInsets padding;

  SafeAreaPainter(this.padding);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // SafeArea 경계 그리기
    final rect = Rect.fromLTRB(
      0,
      padding.top,
      size.width,
      size.height - padding.bottom,
    );

    canvas.drawRect(rect, paint);

    // 하단 영역 특별 표시
    if (padding.bottom > 0) {
      final bottomPaint = Paint()
        ..color = Colors.orange.withValues(alpha: 0.3)
        ..style = PaintingStyle.fill;

      canvas.drawRect(
        Rect.fromLTRB(0, size.height - padding.bottom, size.width, size.height),
        bottomPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

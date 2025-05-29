import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/core/services/splash_screen_service.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/presentation/widgets/enhanced_splash_screen.dart';
import 'package:universal_platform/universal_platform.dart';

class SplashImageData {
  final String imageUrl;
  final DateTime startDate;
  final DateTime endDate;

  SplashImageData({
    required this.imageUrl,
    required this.startDate,
    required this.endDate,
  });
}

/// 기존 SplashImage 위젯의 호환성 래퍼
///
/// 기존 코드와의 호환성을 유지하면서 새로운 EnhancedSplashScreen을 사용합니다.
/// @deprecated 새로운 코드에서는 EnhancedSplashScreen을 직접 사용하세요.
class SplashImage extends ConsumerStatefulWidget {
  final Widget? child;

  const SplashImage({
    super.key,
    this.child,
  });

  @override
  ConsumerState<SplashImage> createState() => _SplashImageState();
}

class _SplashImageState extends ConsumerState<SplashImage> {
  @override
  Widget build(BuildContext context) {
    // 웹 환경에서는 간단한 스플래시 표시
    if (UniversalPlatform.isWeb) {
      return _buildSimpleSplash();
    }

    // 모바일 환경에서는 향상된 스플래시 스크린 사용
    return EnhancedSplashScreen(
      config: const SplashScreenConfig(
        minDisplayDuration: Duration(milliseconds: 2000),
        fadeTransitionDuration: Duration(milliseconds: 500),
        showProgressIndicator: true,
        enableBrandingAnimation: true,
      ),
      child: widget.child,
    );
  }

  /// 웹용 간단한 스플래시 화면
  Widget _buildSimpleSplash() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 로고
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.asset(
                  'assets/app_icon_256.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Theme.of(context).primaryColor,
                      child: const Icon(
                        Icons.apps,
                        size: 60,
                        color: Colors.white,
                      ),
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 로딩 인디케이터
            const CircularProgressIndicator(),

            const SizedBox(height: 16),

            // 로딩 텍스트
            Text(
              t('loading'),
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 향상된 스플래시 래퍼 위젯
///
/// 새로운 프로젝트나 코드에서 사용하기 위한 명시적 래퍼입니다.
class PicnicSplashScreen extends ConsumerWidget {
  final Widget child;
  final SplashScreenConfig? config;

  const PicnicSplashScreen({
    super.key,
    required this.child,
    this.config,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return EnhancedSplashScreen(
      config: config ?? _getDefaultConfig(),
      child: child,
    );
  }

  /// 기본 스플래시 설정
  SplashScreenConfig _getDefaultConfig() {
    return const SplashScreenConfig(
      minDisplayDuration: Duration(milliseconds: 2000),
      fadeTransitionDuration: Duration(milliseconds: 500),
      backgroundColor: Color(0xFFFFFFFF),
      darkModeBackgroundColor: Color(0xFF1F2937),
      showProgressIndicator: true,
      enableBrandingAnimation: true,
    );
  }
}

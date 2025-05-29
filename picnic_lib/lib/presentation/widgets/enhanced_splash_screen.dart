import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:picnic_lib/core/services/splash_screen_service.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/shorebird_utils.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/presentation/widgets/lazy_image_widget.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart' as shorebird;
import 'package:flutter_phoenix/flutter_phoenix.dart';

/// 향상된 스플래시 스크린 위젯
///
/// 브랜딩과 일관성 있는 시각적 경험을 제공하는 개선된 스플래시 스크린:
/// - 실시간 초기화 진행률 표시
/// - 매끄러운 애니메이션과 전환
/// - 다크 모드 지원
/// - 동적 스플래시 이미지 로딩
/// - Shorebird 업데이트 상태 표시
class EnhancedSplashScreen extends ConsumerStatefulWidget {
  final Widget? child;
  final SplashScreenConfig? config;

  const EnhancedSplashScreen({
    super.key,
    this.child,
    this.config,
  });

  @override
  ConsumerState<EnhancedSplashScreen> createState() =>
      _EnhancedSplashScreenState();
}

class _EnhancedSplashScreenState extends ConsumerState<EnhancedSplashScreen>
    with TickerProviderStateMixin {
  // 서비스
  final SplashScreenService _splashService = SplashScreenService();

  // 애니메이션 컨트롤러들
  late AnimationController _logoController;
  late AnimationController _progressController;
  late AnimationController _fadeController;

  // 애니메이션들
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _progressOpacity;
  late Animation<double> _fadeTransition;

  // 상태
  SplashScreenState _currentState = SplashScreenState.initializing;
  InitializationProgress? _currentProgress;
  String? _dynamicSplashUrl;
  bool _isCheckingUpdate = false;
  String _updateStatus = '';
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeServices();

    // 웹이 아닌 경우에만 동적 스플래시와 업데이트 확인
    if (!UniversalPlatform.isWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchDynamicSplashImage();
        _checkForUpdates();
      });
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _logoController.dispose();
    _progressController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  /// 애니메이션 초기화
  void _initializeAnimations() {
    // 로고 애니메이션 (3초)
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    // 진행률 애니메이션 (더 빠른 응답성)
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    // 페이드 전환 애니메이션
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // 로고 스케일 및 투명도 애니메이션
    _logoScale = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    ));

    _logoOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeInOut),
    ));

    // 진행률 표시 투명도
    _progressOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));

    // 페이드 전환
    _fadeTransition = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    // 로고 애니메이션 시작
    _logoController.forward();
  }

  /// 서비스 초기화
  void _initializeServices() {
    // 스플래시 서비스 초기화
    final config = widget.config ?? const SplashScreenConfig();
    _splashService.initialize(config: config);

    // 상태 변경 리스너
    _splashService.stateStream.listen((state) {
      if (!mounted || _disposed) return;

      setState(() {
        _currentState = state;
      });

      // 상태별 처리
      switch (state) {
        case SplashScreenState.loading:
          _progressController.forward();
          break;
        case SplashScreenState.transitioning:
          _fadeController.forward();
          break;
        case SplashScreenState.completed:
          // 완료 처리는 부모 위젯에서 담당
          break;
        default:
          break;
      }
    });

    // 진행률 변경 리스너
    _splashService.progressStream.listen((progress) {
      if (!mounted || _disposed) return;

      setState(() {
        _currentProgress = progress;
      });
    });
  }

  /// 동적 스플래시 이미지 가져오기
  Future<void> _fetchDynamicSplashImage() async {
    try {
      final response =
          await supabase.rpc('get_current_splash_image').maybeSingle();

      if (response != null && !_disposed && mounted) {
        setState(() {
          _dynamicSplashUrl = getLocaleTextFromJson(response['image']);
        });
      }
    } catch (e) {
      logger.e('동적 스플래시 이미지 로딩 실패', error: e);
    }
  }

  /// Shorebird 업데이트 확인
  Future<void> _checkForUpdates() async {
    if (_disposed || !mounted) return;

    setState(() {
      _isCheckingUpdate = true;
      _updateStatus = t('patch_check');
    });

    try {
      await Future.delayed(const Duration(milliseconds: 500));

      final status = await updater.checkForUpdate();

      if (!mounted || _disposed) return;

      if (status == shorebird.UpdateStatus.outdated) {
        setState(() => _updateStatus = t('patch_install'));
        await Future.delayed(const Duration(milliseconds: 500));

        await ShorebirdUtils.checkAndUpdate();

        if (mounted && !_disposed) {
          setState(() => _updateStatus = t('patch_restart_app'));
          await Future.delayed(const Duration(milliseconds: 500));
          Phoenix.rebirth(context);
        }
      } else if (status == shorebird.UpdateStatus.restartRequired) {
        setState(() => _updateStatus = t('patch_restart_app'));
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted && !_disposed) {
          Phoenix.rebirth(context);
        }
      }
    } catch (e) {
      logger.e('업데이트 확인 중 오류', error: e);
      if (mounted && !_disposed) {
        setState(() => _updateStatus = t('patch_error'));
      }
    } finally {
      if (mounted && !_disposed) {
        setState(() => _isCheckingUpdate = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 다크 모드 지원
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDarkMode
        ? _splashService.config.darkModeBackgroundColor
        : _splashService.config.backgroundColor;

    return AnimatedBuilder(
      animation: _fadeTransition,
      builder: (context, child) {
        return Stack(
          children: [
            // 메인 스플래시 콘텐츠
            Opacity(
              opacity: _fadeTransition.value,
              child: _buildSplashContent(backgroundColor),
            ),

            // 자식 위젯 (메인 앱)
            if (_currentState == SplashScreenState.transitioning &&
                widget.child != null)
              Opacity(
                opacity: 1.0 - _fadeTransition.value,
                child: widget.child!,
              ),
          ],
        );
      },
    );
  }

  /// 스플래시 콘텐츠 빌드
  Widget _buildSplashContent(Color backgroundColor) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 배경 스플래시 이미지
          _buildBackgroundImage(),

          // 메인 로고 및 브랜딩
          _buildMainContent(),

          // 진행률 표시
          if (_splashService.config.showProgressIndicator)
            _buildProgressIndicator(),

          // 업데이트 상태 표시
          if (_isCheckingUpdate || _updateStatus.isNotEmpty)
            _buildUpdateStatus(),
        ],
      ),
    );
  }

  /// 배경 이미지 빌드
  Widget _buildBackgroundImage() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 기본 로컬 스플래시 이미지
        Image.asset(
          'assets/splash.webp',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(color: Colors.white);
          },
        ),

        // 동적 스플래시 이미지 (있는 경우)
        if (_dynamicSplashUrl != null)
          LazyImageWidget(
            imageUrl: _dynamicSplashUrl!,
            fit: BoxFit.contain,
          ),
      ],
    );
  }

  /// 메인 콘텐츠 (로고 및 브랜딩) 빌드
  Widget _buildMainContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 로고 애니메이션
          AnimatedBuilder(
            animation: _logoController,
            builder: (context, child) {
              return Transform.scale(
                scale: _logoScale.value,
                child: Opacity(
                  opacity: _logoOpacity.value,
                  child: _buildLogo(),
                ),
              );
            },
          ),

          SizedBox(height: 32.h),

          // 브랜딩 애니메이션 (선택사항)
          if (_splashService.config.enableBrandingAnimation)
            _buildBrandingAnimation(),
        ],
      ),
    );
  }

  /// 로고 빌드
  Widget _buildLogo() {
    return Container(
      width: 120.w,
      height: 120.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.r),
        child: Image.asset(
          'assets/app_icon_256.png',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Theme.of(context).primaryColor,
              child: Icon(
                Icons.apps,
                size: 60.sp,
                color: Colors.white,
              ),
            );
          },
        ),
      ),
    );
  }

  /// 브랜딩 애니메이션 빌드
  Widget _buildBrandingAnimation() {
    return AnimatedBuilder(
      animation: _logoController,
      builder: (context, child) {
        final animationValue = _logoController.value;

        return Opacity(
          opacity: math.max(0.0, (animationValue - 0.6) / 0.4),
          child: Column(
            children: [
              // 앱 이름이나 슬로건
              Text(
                'Picnic', // 앱 이름으로 변경
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                  letterSpacing: 2.0,
                ),
              ),

              SizedBox(height: 8.h),

              // 서브 텍스트
              Text(
                '즐거운 소통의 시작', // 슬로건으로 변경
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withOpacity(0.7),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 진행률 표시기 빌드
  Widget _buildProgressIndicator() {
    return Positioned(
      bottom: 120.h,
      left: 40.w,
      right: 40.w,
      child: AnimatedBuilder(
        animation: _progressController,
        builder: (context, child) {
          return Opacity(
            opacity: _progressOpacity.value,
            child: Column(
              children: [
                // 진행률 바
                Container(
                  height: 4.h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2.r),
                    color: Colors.grey.withOpacity(0.3),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: (_currentProgress?.progress ?? 0.0 * 100).round(),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2.r),
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 100 -
                            (_currentProgress?.progress ?? 0.0 * 100).round(),
                        child: const SizedBox(),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 16.h),

                // 진행률 텍스트
                Text(
                  _currentProgress?.description ?? '초기화 중...',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.color
                        ?.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 8.h),

                // 진행률 퍼센트
                Text(
                  '${((_currentProgress?.progress ?? 0.0) * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.color
                        ?.withOpacity(0.5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 업데이트 상태 표시 빌드
  Widget _buildUpdateStatus() {
    return Positioned(
      bottom: 50.h,
      left: 0,
      right: 0,
      child: Container(
        color: Colors.black.withOpacity(0.5),
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _updateStatus,
              style: getTextStyle(AppTypo.body14B, AppColors.grey00)
                  .copyWith(decoration: TextDecoration.none),
              textAlign: TextAlign.center,
            ),
            SizedBox(width: 16.w),
            SizedBox(
              width: 16.w,
              height: 16.h,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

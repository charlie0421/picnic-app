import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:picnic_lib/presentation/widgets/ui/loading_overlay_animations.dart';
import 'package:picnic_lib/presentation/widgets/ui/pulse_loading_indicator.dart';

/// 앱 아이콘이 중앙에서 애니메이션되는 전체화면 로딩 오버레이 위젯.
///
/// ```dart
/// final key = GlobalKey<LoadingOverlayWithIconState>();
/// LoadingOverlayWithIcon(
///   key: key,
///   iconAssetPath: 'assets/app_icon_128.png',
///   child: MyWidget(),
/// );
/// // 로딩 시작/종료
/// key.currentState?.show();
/// key.currentState?.hide();
/// ```
///
/// 주요 파라미터:
/// - [iconAssetPath]: 앱 아이콘 경로
/// - [iconSize]: 아이콘 크기 (기본 64.0)
/// - [enableRotation], [enableScale], [enableFade]: 애니메이션 개별 제어
/// - [barrierColor]: 오버레이 배경 색상
/// - [loadingMessage]: 로딩 메시지
/// - [showProgressIndicator]: 하단 로딩 인디케이터 표시 여부
/// - [enablePerformanceOptimization]: 성능 최적화 모드
/// - [showPerformanceDebugInfo]: 디버그 FPS 정보 표시 (개발 모드 전용)
class LoadingOverlayWithIcon extends StatefulWidget {
  /// 오버레이가 덮을 자식 위젯
  final Widget child;

  /// 오버레이 배경 색상 (기본: Colors.black54)
  final Color barrierColor;

  /// 앱 아이콘 크기 (기본: 64.0)
  final double iconSize;

  /// 커스텀 앱 아이콘 경로 (기본: 'packages/picnic_lib/assets/images/logo.png')
  final String? iconAssetPath;

  /// 커스텀 로딩 메시지
  final String? loadingMessage;

  /// 로딩 메시지 스타일
  final TextStyle? messageStyle;

  /// 배경 터치로 오버레이 해제 가능 여부 (기본: false)
  final bool barrierDismissible;

  /// 접근성을 위한 로딩 메시지
  final String semanticsLabel;

  /// 회전 애니메이션 활성화 여부 (기본: true)
  final bool enableRotation;

  /// 회전 애니메이션 지속 시간 (기본: 2초)
  final Duration rotationDuration;

  /// 시계방향 회전 여부 (기본: true)
  final bool clockwise;

  /// 스케일 애니메이션 활성화 여부 (기본: true)
  final bool enableScale;

  /// 스케일 애니메이션 지속 시간 (기본: 1.5초)
  final Duration scaleDuration;

  /// 최소 스케일 값 (기본: 0.8)
  final double minScale;

  /// 최대 스케일 값 (기본: 1.2)
  final double maxScale;

  /// 페이드 애니메이션 활성화 여부 (기본: true)
  final bool enableFade;

  /// 페이드 애니메이션 지속 시간 (기본: 1초)
  final Duration fadeDuration;

  /// 성능 최적화 모드 활성화 (기본: true)
  final bool enablePerformanceOptimization;

  /// 디버그 성능 정보 표시 (개발 모드에서만, 기본: false)
  final bool showPerformanceDebugInfo;

  /// 하단 로딩 인디케이터 표시 여부 (기본: true)
  final bool showProgressIndicator;

  const LoadingOverlayWithIcon({
    super.key,
    required this.child,
    this.barrierColor = Colors.black54,
    this.iconSize = 64.0,
    this.iconAssetPath,
    this.loadingMessage,
    this.messageStyle,
    this.barrierDismissible = false,
    this.semanticsLabel = '로딩 중입니다',
    this.enableRotation = true,
    this.rotationDuration = const Duration(seconds: 2),
    this.clockwise = true,
    this.enableScale = true,
    this.scaleDuration = const Duration(milliseconds: 1500),
    this.minScale = 0.8,
    this.maxScale = 1.2,
    this.enableFade = true,
    this.fadeDuration = const Duration(seconds: 1),
    this.enablePerformanceOptimization = true,
    this.showPerformanceDebugInfo = false,
    this.showProgressIndicator = true,
  });

  @override
  State<LoadingOverlayWithIcon> createState() => LoadingOverlayWithIconState();

  /// 가장 가까운 LoadingOverlayWithIcon의 상태에 접근
  static LoadingOverlayWithIconState? of(BuildContext context) {
    return context.findAncestorStateOfType<LoadingOverlayWithIconState>();
  }
}

class LoadingOverlayWithIconState extends State<LoadingOverlayWithIcon>
    with TickerProviderStateMixin, LoadingOverlayAnimationsMixin {
  /// 로딩 상태 관리
  final ValueNotifier<bool> _isLoading = ValueNotifier<bool>(false);

  /// Navigator overlay entry
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    initializeAnimations(
      enableRotation: widget.enableRotation,
      enableScale: widget.enableScale,
      enableFade: widget.enableFade,
      rotationDuration: widget.rotationDuration,
      clockwise: widget.clockwise,
      scaleDuration: widget.scaleDuration,
      minScale: widget.minScale,
      maxScale: widget.maxScale,
      fadeDuration: widget.fadeDuration,
    );

    // 성능 디버그 정보가 활성화된 경우 프레임 측정 시작
    if (widget.showPerformanceDebugInfo && kDebugMode) {
      startPerformanceMonitoring(() => _isLoading.value);
    }
  }

  @override
  void dispose() {
    // 오버레이 정리
    _removeOverlayEntry();

    disposeAnimations();
    _isLoading.dispose();
    super.dispose();
  }

  /// 로딩 오버레이 표시
  void show() {
    if (!mounted) return;

    if (!_isLoading.value) {
      _isLoading.value = true;

      // Navigator overlay entry 생성 및 삽입
      _showOverlayEntry();

      overlayFadeController.forward();

      // 성능 모니터링 시작 (디버그 모드에서만)
      if (widget.showPerformanceDebugInfo && kDebugMode) {
        frameCount = 0;
        lastFrameTime = null;
        startPerformanceMonitoring(() => _isLoading.value);
      }

      // 회전 애니메이션 시작 (활성화된 경우)
      if (widget.enableRotation && rotationController != null) {
        rotationController!.repeat();
      }

      // 스케일 애니메이션 시작 (활성화된 경우)
      if (widget.enableScale && scaleController != null) {
        scaleController!.repeat(reverse: true);
      }

      // 아이콘 페이드 애니메이션 시작 (활성화된 경우)
      if (widget.enableFade && iconFadeController != null) {
        iconFadeController!.repeat(reverse: true);
      }
    }
  }

  /// 로딩 오버레이 숨김
  void hide() {
    if (!mounted) return;

    if (_isLoading.value) {
      // 모든 애니메이션 정지
      rotationController?.stop();
      scaleController?.stop();
      iconFadeController?.stop();

      overlayFadeController.reverse().then((_) {
        if (mounted) {
          _isLoading.value = false;
          _removeOverlayEntry();
        }
      });
    }
  }

  /// Navigator overlay entry 생성 및 표시
  void _showOverlayEntry() {
    if (_overlayEntry != null) return;

    final overlay = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder: (context) => _buildFullScreenOverlay(),
    );
    overlay.insert(_overlayEntry!);
  }

  /// Navigator overlay entry 제거
  void _removeOverlayEntry() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  /// 전체 화면 오버레이 구성
  Widget _buildFullScreenOverlay() {
    return Positioned.fill(
      child: Material(
        color: Colors.transparent,
        child: ValueListenableBuilder<bool>(
          valueListenable: _isLoading,
          builder: (context, isLoading, _) {
            if (!isLoading) {
              return const SizedBox.shrink();
            }

            return AnimatedBuilder(
              animation: overlayFadeAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: overlayFadeAnimation.value,
                  child: Stack(
                    children: [
                      // 메인 오버레이 콘텐츠
                      Container(
                        color: widget.barrierColor,
                        child: GestureDetector(
                          onTap: widget.barrierDismissible ? hide : null,
                          child: Semantics(
                            label: widget.semanticsLabel,
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // 앱 아이콘 (최적화된 RepaintBoundary 적용)
                                  RepaintBoundary(
                                    child: _buildOptimizedAppIcon(),
                                  ),

                                  // 로딩 메시지 (있는 경우)
                                  if (widget.loadingMessage != null) ...[
                                    const SizedBox(height: 16),
                                    _buildLoadingMessage(),
                                  ],

                                  // 기본 로딩 인디케이터 (선택적 표시)
                                  if (widget.showProgressIndicator) ...[
                                    const SizedBox(height: 24),
                                    RepaintBoundary(
                                      child: _buildLoadingIndicator(),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // 성능 디버그 정보 (개발 모드에서만, 우상단 고정)
                      if (widget.showPerformanceDebugInfo && kDebugMode)
                        Positioned(
                          top: 50,
                          right: 16,
                          child: buildPerformanceDebugInfo(
                            enablePerformanceOptimization:
                                widget.enablePerformanceOptimization,
                          ),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  /// 현재 로딩 상태 확인
  bool get isVisible => _isLoading.value;

  @override
  Widget build(BuildContext context) {
    // 전체 화면 오버레이는 Navigator overlay를 사용하므로
    // 기본 자식 위젯만 반환
    return widget.child;
  }

  /// 최적화된 앱 아이콘 위젯 구성
  Widget _buildOptimizedAppIcon() {
    // 기본 아이콘 위젯
    Widget iconWidget = Container(
      width: widget.iconSize,
      height: widget.iconSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          widget.iconAssetPath ?? 'packages/picnic_lib/assets/images/logo.png',
          width: widget.iconSize,
          height: widget.iconSize,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: widget.iconSize,
              height: widget.iconSize,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.apps,
                size: widget.iconSize * 0.6,
                color: Colors.white,
              ),
            );
          },
        ),
      ),
    );

    // 성능 최적화된 애니메이션 조합
    return buildCombinedAnimations(
      iconWidget,
      enablePerformanceOptimization: widget.enablePerformanceOptimization,
      enableRotation: widget.enableRotation,
      enableScale: widget.enableScale,
      enableFade: widget.enableFade,
    );
  }

  /// 로딩 메시지 위젯 구성
  Widget _buildLoadingMessage() {
    return Text(
      widget.loadingMessage!,
      style: widget.messageStyle ??
          Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
      textAlign: TextAlign.center,
    );
  }

  /// 로딩 인디케이터 위젯 구성
  Widget _buildLoadingIndicator() {
    return SmallPulseLoadingIndicator();
  }
}

/// BuildContext 확장을 통한 편리한 로딩 관리
extension LoadingOverlayWithIconContext on BuildContext {
  /// 로딩 오버레이 표시
  void showLoadingWithIcon() {
    LoadingOverlayWithIcon.of(this)?.show();
  }

  /// 로딩 오버레이 숨김
  void hideLoadingWithIcon() {
    LoadingOverlayWithIcon.of(this)?.hide();
  }

  /// 로딩 오버레이 표시 상태 확인
  bool get isLoadingWithIconVisible =>
      LoadingOverlayWithIcon.of(this)?.isVisible ?? false;
}

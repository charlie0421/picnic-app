import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:picnic_lib/presentation/widgets/ui/pulse_loading_indicator.dart';

/// # LoadingOverlayWithIcon
///
/// **앱 아이콘이 중앙에서 애니메이션되는 전체화면 로딩 오버레이 위젯**
///
/// 브랜드 일관성을 유지하면서 사용자에게 부드러운 로딩 경험을 제공합니다.
/// 성능 최적화가 적용되어 60FPS 부드러운 애니메이션을 보장합니다.
///
/// ## 주요 특징
///
/// - 🎨 **앱 아이콘 중앙 배치**: 브랜드 일관성 유지
/// - 🎪 **3가지 애니메이션**: 회전, 스케일, 페이드 (개별 제어 가능)
/// - 🚀 **성능 최적화**: RepaintBoundary, 지연 초기화, 60FPS 유지
/// - 🎛️ **커스터마이징**: 애니메이션 속도, 크기, 메시지 등 세밀한 조정
/// - 📱 **반응형**: 다양한 화면 크기 대응
/// - ♿ **접근성**: Semantics 지원
/// - 🔍 **디버그**: 개발 모드에서 FPS 모니터링
///
/// ## 기본 사용법
///
/// ```dart
/// class MyPage extends StatefulWidget {
///   @override
///   State<MyPage> createState() => _MyPageState();
/// }
///
/// class _MyPageState extends State<MyPage> {
///   final GlobalKey<LoadingOverlayWithIconState> _loadingKey =
///       GlobalKey<LoadingOverlayWithIconState>();
///
///   @override
///   Widget build(BuildContext context) {
///     return LoadingOverlayWithIcon(
///       key: _loadingKey,
///       iconAssetPath: 'assets/app_icon_128.png',
///       child: Scaffold(
///         appBar: AppBar(title: Text('내 페이지')),
///         body: Center(
///           child: ElevatedButton(
///             onPressed: () async {
///               _loadingKey.currentState?.show(); // 로딩 시작
///
///               // 비동기 작업 (API 호출, 파일 저장 등)
///               await _performAsyncWork();
///
///               _loadingKey.currentState?.hide(); // 로딩 종료
///             },
///             child: Text('작업 시작'),
///           ),
///         ),
///       ),
///     );
///   }
///
///   Future<void> _performAsyncWork() async {
///     await Future.delayed(Duration(seconds: 3));
///   }
/// }
/// ```
///
/// ## 고급 사용법 (커스터마이징)
///
/// ```dart
/// LoadingOverlayWithIcon(
///   key: _loadingKey,
///
///   // 아이콘 설정
///   iconAssetPath: 'assets/my_app_icon.png',
///   iconSize: 80.0,
///
///   // 애니메이션 설정 (세밀한 제어)
///   enableRotation: false,           // 회전 비활성화
///   enableScale: true,               // 스케일 활성화
///   enableFade: true,                // 페이드 활성화
///
///   // 스케일 애니메이션 커스터마이징
///   minScale: 0.98,                  // 최소 크기 (미묘한 변화)
///   maxScale: 1.02,                  // 최대 크기
///   scaleDuration: Duration(milliseconds: 1200),
///
///   // 페이드 애니메이션 커스터마이징
///   fadeDuration: Duration(milliseconds: 800),
///
///   // UI 설정
///   showProgressIndicator: false,    // 하단 로딩바 숨김
///   loadingMessage: null,            // 메시지 숨김
///   barrierColor: Colors.black.withValues(alpha: 0.7),
///
///   // 성능 최적화
///   enablePerformanceOptimization: true,
///   showPerformanceDebugInfo: true,  // 개발 시 FPS 표시
///
///   child: MyWidget(),
/// )
/// ```
///
/// ## 실제 사용 사례
///
/// ### 이미지 저장
/// ```dart
/// Future<void> _saveImage() async {
///   _loadingKey.currentState?.show();
///
///   try {
///     await ImageService.saveToGallery(imageUrl);
///     showSuccess('이미지가 저장되었습니다');
///   } catch (e) {
///     showError('저장에 실패했습니다');
///   } finally {
///     _loadingKey.currentState?.hide();
///   }
/// }
/// ```
///
/// ### API 요청
/// ```dart
/// Future<void> _loadData() async {
///   _loadingKey.currentState?.show();
///
///   try {
///     final data = await ApiService.fetchData();
///     setState(() => _data = data);
///   } finally {
///     _loadingKey.currentState?.hide();
///   }
/// }
/// ```
///
/// ## 애니메이션 설정 가이드
///
/// ### 미묘한 펄스 효과 (추천)
/// ```dart
/// enableRotation: false,
/// enableScale: true,
/// enableFade: true,
/// minScale: 0.98,      // 2% 변화
/// maxScale: 1.02,
/// ```
///
/// ### 활동적인 효과
/// ```dart
/// enableRotation: true,
/// enableScale: true,
/// enableFade: false,
/// minScale: 0.9,       // 10% 변화
/// maxScale: 1.1,
/// ```
///
/// ### 클래식 회전
/// ```dart
/// enableRotation: true,
/// enableScale: false,
/// enableFade: false,
/// rotationDuration: Duration(seconds: 2),
/// ```
///
/// ## 성능 고려사항
///
/// - ✅ `enablePerformanceOptimization: true` 권장
/// - ✅ 불필요한 애니메이션 비활성화로 성능 향상
/// - ✅ `RepaintBoundary` 자동 적용으로 리페인트 최소화
/// - ✅ 지연 초기화로 메모리 사용량 최적화
/// - ✅ 개발 모드에서 FPS 모니터링 활용
///
/// ## 접근성
///
/// - 기본적으로 접근성 레이블 제공 (`semanticsLabel`)
/// - 스크린 리더 지원
/// - 시각 장애인을 위한 의미있는 설명 제공
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
    with TickerProviderStateMixin {
  /// 로딩 상태 관리
  final ValueNotifier<bool> _isLoading = ValueNotifier<bool>(false);

  /// Navigator overlay entry
  OverlayEntry? _overlayEntry;

  /// 페이드 애니메이션 컨트롤러 (오버레이 전체)
  late AnimationController _overlayFadeController;

  /// 오버레이 페이드 애니메이션
  late Animation<double> _overlayFadeAnimation;

  /// 회전 애니메이션 컨트롤러
  AnimationController? _rotationController;

  /// 회전 애니메이션
  Animation<double>? _rotationAnimation;

  /// 스케일 애니메이션 컨트롤러
  AnimationController? _scaleController;

  /// 스케일 애니메이션
  Animation<double>? _scaleAnimation;

  /// 아이콘 페이드 애니메이션 컨트롤러
  AnimationController? _iconFadeController;

  /// 아이콘 페이드 애니메이션
  Animation<double>? _iconFadeAnimation;

  /// 성능 측정을 위한 변수들
  int _frameCount = 0;
  DateTime? _lastFrameTime;
  double _averageFps = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();

    // 성능 디버그 정보가 활성화된 경우 프레임 측정 시작
    if (widget.showPerformanceDebugInfo && kDebugMode) {
      _startPerformanceMonitoring();
    }
  }

  /// 애니메이션 컨트롤러들을 초기화 (지연 초기화로 메모리 절약)
  void _initializeAnimations() {
    // 오버레이 페이드 애니메이션 컨트롤러 초기화
    _overlayFadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // 오버레이 페이드 애니메이션 설정
    _overlayFadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _overlayFadeController,
      curve: Curves.easeInOut,
    ));

    // 필요한 경우에만 애니메이션 컨트롤러 초기화 (메모리 최적화)
    if (widget.enableRotation) {
      _initializeRotationAnimation();
    }

    if (widget.enableScale) {
      _initializeScaleAnimation();
    }

    if (widget.enableFade) {
      _initializeIconFadeAnimation();
    }
  }

  /// 회전 애니메이션 초기화 (지연 초기화)
  void _initializeRotationAnimation() {
    _rotationController = AnimationController(
      duration: widget.rotationDuration,
      vsync: this,
    );

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: widget.clockwise ? 1.0 : -1.0,
    ).animate(CurvedAnimation(
      parent: _rotationController!,
      curve: Curves.linear,
    ));
  }

  /// 스케일 애니메이션 초기화 (지연 초기화)
  void _initializeScaleAnimation() {
    _scaleController = AnimationController(
      duration: widget.scaleDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: widget.minScale,
      end: widget.maxScale,
    ).animate(CurvedAnimation(
      parent: _scaleController!,
      curve: Curves.easeInOut,
    ));
  }

  /// 아이콘 페이드 애니메이션 초기화 (지연 초기화)
  void _initializeIconFadeAnimation() {
    _iconFadeController = AnimationController(
      duration: widget.fadeDuration,
      vsync: this,
    );

    _iconFadeAnimation = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _iconFadeController!,
      curve: Curves.easeInOut,
    ));
  }

  /// 성능 모니터링 시작
  void _startPerformanceMonitoring() {
    if (!kDebugMode) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureFrameRate();
    });
  }

  /// 프레임율 측정
  void _measureFrameRate() {
    if (!mounted || !kDebugMode) return;

    final now = DateTime.now();
    if (_lastFrameTime != null) {
      final frameDuration = now.difference(_lastFrameTime!);
      final fps = 1000 / frameDuration.inMilliseconds;

      _frameCount++;
      _averageFps = (_averageFps * (_frameCount - 1) + fps) / _frameCount;

      if (_frameCount % 60 == 0) {
        debugPrint(
            'LoadingOverlayWithIcon FPS: ${_averageFps.toStringAsFixed(1)}');
      }
    }
    _lastFrameTime = now;

    if (_isLoading.value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _measureFrameRate();
      });
    }
  }

  @override
  void dispose() {
    // 오버레이 정리
    _removeOverlayEntry();

    _overlayFadeController.dispose();
    _rotationController?.dispose();
    _scaleController?.dispose();
    _iconFadeController?.dispose();
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

      _overlayFadeController.forward();

      // 성능 모니터링 시작 (디버그 모드에서만)
      if (widget.showPerformanceDebugInfo && kDebugMode) {
        _frameCount = 0;
        _lastFrameTime = null;
        _startPerformanceMonitoring();
      }

      // 회전 애니메이션 시작 (활성화된 경우)
      if (widget.enableRotation && _rotationController != null) {
        _rotationController!.repeat();
      }

      // 스케일 애니메이션 시작 (활성화된 경우)
      if (widget.enableScale && _scaleController != null) {
        _scaleController!.repeat(reverse: true);
      }

      // 아이콘 페이드 애니메이션 시작 (활성화된 경우)
      if (widget.enableFade && _iconFadeController != null) {
        _iconFadeController!.repeat(reverse: true);
      }
    }
  }

  /// 로딩 오버레이 숨김
  void hide() {
    if (!mounted) return;

    if (_isLoading.value) {
      // 모든 애니메이션 정지
      _rotationController?.stop();
      _scaleController?.stop();
      _iconFadeController?.stop();

      _overlayFadeController.reverse().then((_) {
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
              animation: _overlayFadeAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _overlayFadeAnimation.value,
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
                          child: _buildPerformanceDebugInfo(),
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
    return _buildCombinedAnimations(iconWidget);
  }

  /// 모든 애니메이션을 효율적으로 조합
  Widget _buildCombinedAnimations(Widget child) {
    // 단일 AnimatedBuilder로 모든 애니메이션 처리 (성능 최적화)
    if (widget.enablePerformanceOptimization &&
        widget.enableRotation &&
        widget.enableScale &&
        widget.enableFade &&
        _rotationAnimation != null &&
        _scaleAnimation != null &&
        _iconFadeAnimation != null) {
      return AnimatedBuilder(
        animation: Listenable.merge([
          _rotationAnimation!,
          _scaleAnimation!,
          _iconFadeAnimation!,
        ]),
        builder: (context, _) {
          return Transform.rotate(
            angle: _rotationAnimation!.value * 2 * 3.14159,
            child: Transform.scale(
              scale: _scaleAnimation!.value,
              child: Opacity(
                opacity: _iconFadeAnimation!.value,
                child: child,
              ),
            ),
          );
        },
      );
    }

    // 개별 애니메이션 적용 (호환성 모드)
    Widget result = child;

    // 스케일 애니메이션 적용
    if (widget.enableScale && _scaleAnimation != null) {
      result = AnimatedBuilder(
        animation: _scaleAnimation!,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation!.value,
            child: child,
          );
        },
        child: result,
      );
    }

    // 회전 애니메이션 적용
    if (widget.enableRotation && _rotationAnimation != null) {
      result = RotationTransition(
        turns: _rotationAnimation!,
        child: result,
      );
    }

    // 아이콘 페이드 애니메이션 적용
    if (widget.enableFade && _iconFadeAnimation != null) {
      result = AnimatedBuilder(
        animation: _iconFadeAnimation!,
        builder: (context, child) {
          return Opacity(
            opacity: _iconFadeAnimation!.value,
            child: child,
          );
        },
        child: result,
      );
    }

    return result;
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
    return SmallPulseLoadingIndicator(
      iconColor: Theme.of(context).primaryColor,
    );
  }

  /// 성능 디버그 정보 위젯
  Widget _buildPerformanceDebugInfo() {
    if (!kDebugMode) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FPS: ${_averageFps.toStringAsFixed(1)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Frames: $_frameCount',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
            ),
          ),
          Text(
            'Optimized: ${widget.enablePerformanceOptimization}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
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

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/presentation/widgets/ui/pulse_loading_indicator.dart';
import 'loading_overlay_manager.dart';

/// 고급 기능이 포함된 LoadingOverlay 위젯
///
/// 메시지, 다양한 애니메이션, 테마를 지원합니다.
///
/// 사용 예시:
/// ```dart
/// AdvancedLoadingOverlay(
///   child: MyScreen(),
///   message: "로딩 중...",
///   animationType: LoadingAnimationType.scale,
///   theme: LoadingOverlayTheme.blur,
/// );
/// ```
class AdvancedLoadingOverlay extends ConsumerStatefulWidget {
  /// 오버레이가 덮을 자식 위젯
  final Widget child;

  /// 로딩 메시지
  final String? message;

  /// 커스텀 로딩 위젯
  final Widget? loadingWidget;

  /// 애니메이션 타입
  final LoadingAnimationType animationType;

  /// 테마
  final LoadingOverlayTheme theme;

  /// 배경 터치로 오버레이 해제 가능 여부
  final bool barrierDismissible;

  /// 접근성을 위한 로딩 메시지
  final String semanticsLabel;

  /// 애니메이션 지속 시간
  final Duration animationDuration;

  const AdvancedLoadingOverlay({
    super.key,
    required this.child,
    this.message,
    this.loadingWidget,
    this.animationType = LoadingAnimationType.fade,
    this.theme = LoadingOverlayTheme.dark,
    this.barrierDismissible = false,
    this.semanticsLabel = '로딩 중',
    this.animationDuration = const Duration(milliseconds: 300),
  });

  @override
  ConsumerState<AdvancedLoadingOverlay> createState() =>
      _AdvancedLoadingOverlayState();
}

class _AdvancedLoadingOverlayState extends ConsumerState<AdvancedLoadingOverlay>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    _setupAnimation();
  }

  void _setupAnimation() {
    switch (widget.animationType) {
      case LoadingAnimationType.fade:
        _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
        );
        break;
      case LoadingAnimationType.scale:
        _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
        );
        break;
      case LoadingAnimationType.slideUp:
      case LoadingAnimationType.slideDown:
        _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeOut),
        );
        break;
      case LoadingAnimationType.rotate:
        _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(parent: _controller, curve: Curves.linear),
        );
        break;
    }
  }

  @override
  void didUpdateWidget(AdvancedLoadingOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animationType != widget.animationType ||
        oldWidget.animationDuration != widget.animationDuration) {
      _controller.duration = widget.animationDuration;
      _setupAnimation();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _show() {
    if (!_controller.isAnimating &&
        _controller.status != AnimationStatus.completed) {
      _controller.forward();
    }
  }

  void _hide() {
    if (!_controller.isAnimating &&
        _controller.status != AnimationStatus.dismissed) {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final loadingState = ref.watch(loadingOverlayProvider);

    // 로딩 상태가 변경되면 애니메이션 실행
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (loadingState.isLoading) {
        _show();
      } else {
        _hide();
      }
    });

    return Stack(
      children: [
        // 기본 자식 위젯
        widget.child,

        // 로딩 오버레이
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            if (_animation.value <= 0.0) {
              return const SizedBox.shrink();
            }

            return Positioned.fill(
              child: _buildOverlay(context, loadingState),
            );
          },
        ),
      ],
    );
  }

  Widget _buildOverlay(BuildContext context, LoadingOverlayState state) {
    final themeData = LoadingOverlayThemeData.getThemeData(state.theme);

    Widget overlayContent = Material(
      color: Colors.transparent,
      child: Container(
        color: themeData.barrierColor,
        child: widget.barrierDismissible
            ? GestureDetector(
                onTap: () => ref.read(loadingOverlayProvider.notifier).hide(),
                behavior: HitTestBehavior.opaque,
                child: _buildLoadingContent(state, themeData),
              )
            : _buildLoadingContent(state, themeData),
      ),
    );

    // Blur 효과 적용
    if (state.theme == LoadingOverlayTheme.blur &&
        themeData.blurSigma != null) {
      overlayContent = BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: themeData.blurSigma!,
          sigmaY: themeData.blurSigma!,
        ),
        child: overlayContent,
      );
    }

    // 애니메이션 적용
    return _applyAnimation(overlayContent, state.animationType);
  }

  Widget _applyAnimation(Widget child, LoadingAnimationType animationType) {
    switch (animationType) {
      case LoadingAnimationType.fade:
        return Opacity(
          opacity: _animation.value,
          child: child,
        );
      case LoadingAnimationType.scale:
        return Transform.scale(
          scale: _animation.value,
          child: Opacity(
            opacity: _animation.value,
            child: child,
          ),
        );
      case LoadingAnimationType.slideUp:
        return Transform.translate(
          offset: Offset(0, (1 - _animation.value) * 100),
          child: Opacity(
            opacity: _animation.value,
            child: child,
          ),
        );
      case LoadingAnimationType.slideDown:
        return Transform.translate(
          offset: Offset(0, (_animation.value - 1) * 100),
          child: Opacity(
            opacity: _animation.value,
            child: child,
          ),
        );
      case LoadingAnimationType.rotate:
        return Transform.rotate(
          angle: _animation.value * 2 * 3.14159,
          child: Opacity(
            opacity: _animation.value,
            child: child,
          ),
        );
    }
  }

  Widget _buildLoadingContent(
      LoadingOverlayState state, LoadingOverlayThemeData themeData) {
    return Semantics(
      label: widget.semanticsLabel,
      child: Center(
        child: RepaintBoundary(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 로딩 위젯
              state.customWidget ??
                  widget.loadingWidget ??
                  MediumPulseLoadingIndicator(),

              // 메시지 표시
              if (state.message != null || widget.message != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  decoration: BoxDecoration(
                    color: themeData.textColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    state.message ?? widget.message!,
                    style: TextStyle(
                      color: themeData.textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 편리한 사용을 위한 헬퍼 위젯
class SimpleLoadingOverlay extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  final String? message;
  final LoadingOverlayTheme theme;

  const SimpleLoadingOverlay({
    super.key,
    required this.child,
    required this.isLoading,
    this.message,
    this.theme = LoadingOverlayTheme.dark,
  });

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: Consumer(
        builder: (context, ref, _) {
          // 로딩 상태를 프로바이더에 동기화
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final notifier = ref.read(loadingOverlayProvider.notifier);
            if (isLoading && !ref.read(loadingOverlayProvider).isLoading) {
              notifier.show(message: message, theme: theme);
            } else if (!isLoading &&
                ref.read(loadingOverlayProvider).isLoading) {
              notifier.hide();
            }
          });

          return AdvancedLoadingOverlay(
            message: message,
            theme: theme,
            child: child,
          );
        },
      ),
    );
  }
}

/// LoadingOverlay 프리셋 테마
class LoadingOverlayPresets {
  /// 기본 다크 테마
  static const dark = LoadingOverlayTheme.dark;

  /// 라이트 테마
  static const light = LoadingOverlayTheme.light;

  /// 투명 테마
  static const transparent = LoadingOverlayTheme.transparent;

  /// 블러 테마
  static const blur = LoadingOverlayTheme.blur;

  /// 애니메이션 프리셋
  static const fadeAnimation = LoadingAnimationType.fade;
  static const scaleAnimation = LoadingAnimationType.scale;
  static const slideUpAnimation = LoadingAnimationType.slideUp;
  static const slideDownAnimation = LoadingAnimationType.slideDown;
  static const rotateAnimation = LoadingAnimationType.rotate;
}

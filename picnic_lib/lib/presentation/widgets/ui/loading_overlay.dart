import 'package:flutter/material.dart';
import 'package:picnic_lib/presentation/widgets/ui/pulse_loading_indicator.dart';

/// 전체화면을 덮는 로딩 오버레이 위젯
///
/// 사용 예시:
/// ```dart
/// LoadingOverlay(
///   child: MyScreen(),
/// );
///
/// // 로딩 표시
/// LoadingOverlay.of(context).show();
///
/// // 로딩 숨김
/// LoadingOverlay.of(context).hide();
/// ```
class LoadingOverlay extends StatefulWidget {
  /// 오버레이가 덮을 자식 위젯
  final Widget child;

  /// 오버레이 배경 색상 (기본: Colors.black54)
  final Color barrierColor;

  /// 커스텀 로딩 위젯 (기본: CircularProgressIndicator)
  final Widget? loadingWidget;

  /// 배경 터치로 오버레이 해제 가능 여부 (기본: false)
  final bool barrierDismissible;

  /// 접근성을 위한 로딩 메시지
  final String semanticsLabel;

  const LoadingOverlay({
    super.key,
    required this.child,
    this.barrierColor = Colors.black54,
    this.loadingWidget,
    this.barrierDismissible = false,
    this.semanticsLabel = '로딩 중',
  });

  /// 가장 가까운 LoadingOverlay의 상태에 접근
  static LoadingOverlayState of(BuildContext context) {
    final state = context.findAncestorStateOfType<LoadingOverlayState>();
    if (state == null) {
      throw FlutterError(
          'LoadingOverlay.of() called with a context that does not contain a LoadingOverlay.\n'
          'Make sure your widget is wrapped with LoadingOverlay.');
    }
    return state;
  }

  /// context 확장 없이 안전하게 LoadingOverlay 상태에 접근
  static LoadingOverlayState? maybeOf(BuildContext context) {
    return context.findAncestorStateOfType<LoadingOverlayState>();
  }

  @override
  LoadingOverlayState createState() => LoadingOverlayState();
}

class LoadingOverlayState extends State<LoadingOverlay>
    with SingleTickerProviderStateMixin {
  /// 로딩 상태를 관리하는 ValueNotifier
  final ValueNotifier<bool> _isLoading = ValueNotifier<bool>(false);

  /// 페이드 애니메이션 컨트롤러
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    _isLoading.dispose();
    super.dispose();
  }

  /// 로딩 오버레이 표시
  void show() {
    if (!_isLoading.value) {
      _isLoading.value = true;
      _animationController.forward();
    }
  }

  /// 로딩 오버레이 숨김
  void hide() {
    if (_isLoading.value) {
      _animationController.reverse().then((_) {
        if (mounted) {
          _isLoading.value = false;
        }
      });
    }
  }

  /// 현재 로딩 상태 반환
  bool get isLoading => _isLoading.value;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 기본 자식 위젯
        widget.child,

        // 로딩 오버레이
        ValueListenableBuilder<bool>(
          valueListenable: _isLoading,
          builder: (context, isLoading, _) {
            if (!isLoading) {
              return const SizedBox.shrink();
            }

            return Positioned.fill(
              child: AnimatedBuilder(
                animation: _fadeAnimation,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: _buildOverlay(context),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  /// 오버레이 UI 구성
  Widget _buildOverlay(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        color: widget.barrierColor,
        child: widget.barrierDismissible
            ? GestureDetector(
                onTap: hide,
                behavior: HitTestBehavior.opaque,
                child: _buildLoadingContent(),
              )
            : _buildLoadingContent(),
      ),
    );
  }

  /// 로딩 콘텐츠 구성
  Widget _buildLoadingContent() {
    return Semantics(
      label: widget.semanticsLabel,
      child: Center(
        child: RepaintBoundary(
          child: widget.loadingWidget ?? const MediumPulseLoadingIndicator(),
        ),
      ),
    );
  }
}

/// BuildContext 확장을 통한 편리한 로딩 오버레이 사용
extension LoadingOverlayContext on BuildContext {
  /// 로딩 오버레이 표시
  void showLoading() {
    final overlay = LoadingOverlay.maybeOf(this);
    if (overlay != null) {
      overlay.show();
    } else {
      debugPrint('LoadingOverlay not found in widget tree');
    }
  }

  /// 로딩 오버레이 숨김
  void hideLoading() {
    final overlay = LoadingOverlay.maybeOf(this);
    if (overlay != null) {
      overlay.hide();
    } else {
      debugPrint('LoadingOverlay not found in widget tree');
    }
  }

  /// 현재 로딩 상태 확인
  bool get isLoadingOverlayVisible {
    final overlay = LoadingOverlay.maybeOf(this);
    return overlay?.isLoading ?? false;
  }
}

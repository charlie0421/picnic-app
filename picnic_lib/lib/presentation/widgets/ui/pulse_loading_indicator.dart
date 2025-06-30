import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// 공통 Pulse 로딩 인디케이터
/// 앱 아이콘을 사용하여 일관된 pulse 애니메이션을 제공합니다.
class PulseLoadingIndicator extends StatefulWidget {
  /// 로딩 인디케이터 크기 (기본: 40)
  final double size;
  
  /// 애니메이션 지속 시간 (기본: 800ms)
  final Duration duration;
  
  /// 최소 스케일 값 (기본: 0.98)
  final double minScale;
  
  /// 최대 스케일 값 (기본: 1.02)
  final double maxScale;
  
  const PulseLoadingIndicator({
    super.key,
    this.size = 40,
    this.duration = const Duration(milliseconds: 800),
    this.minScale = 0.98,
    this.maxScale = 1.02,
  });

  @override
  State<PulseLoadingIndicator> createState() => _PulseLoadingIndicatorState();
}

class _PulseLoadingIndicatorState extends State<PulseLoadingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _fadeController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // 스케일 애니메이션 컨트롤러
    _scaleController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    // 페이드 애니메이션 컨트롤러
    _fadeController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    
    // 스케일 애니메이션 (부드러운 pulse 효과)
    _scaleAnimation = Tween<double>(
      begin: widget.minScale,
      end: widget.maxScale,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));
    
    // 페이드 애니메이션 (투명도 변화)
    _fadeAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    // 애니메이션 시작
    _startAnimations();
  }

  void _startAnimations() {
    // 스케일과 페이드를 동기화하여 pulse 효과 생성
    _scaleController.repeat(reverse: true);
    _fadeController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: Listenable.merge([_scaleAnimation, _fadeAnimation]),
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: Container(
                width: widget.size.w,
                height: widget.size.w,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/app_icon_128.png',
                    width: widget.size.w,
                    height: widget.size.w,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 작은 크기의 pulse 로딩 인디케이터 (24px)
class SmallPulseLoadingIndicator extends StatelessWidget {
  
  const SmallPulseLoadingIndicator({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return PulseLoadingIndicator(
      size: 24,
      duration: const Duration(milliseconds: 1000),
      minScale: 0.96,
      maxScale: 1.04,
    );
  }
}

/// 중간 크기의 pulse 로딩 인디케이터 (40px) - 기본값
class MediumPulseLoadingIndicator extends StatelessWidget {
  
  const MediumPulseLoadingIndicator({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return PulseLoadingIndicator(
      size: 40,
      duration: const Duration(milliseconds: 1000),
      minScale: 0.96,
      maxScale: 1.04,
    );
  }
}

/// 큰 크기의 pulse 로딩 인디케이터 (60px)
class LargePulseLoadingIndicator extends StatelessWidget {
  
  const LargePulseLoadingIndicator({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return PulseLoadingIndicator(
      size: 60,
      duration: const Duration(milliseconds: 1000),
      minScale: 0.96,
      maxScale: 1.04,
    );
  }
} 
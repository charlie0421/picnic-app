import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

/// 리페인트 성능 메트릭
class RepaintMetrics {
  final int repaintCount;
  final Duration totalRepaintTime;
  final DateTime timestamp;
  final String widgetId;

  const RepaintMetrics({
    required this.repaintCount,
    required this.totalRepaintTime,
    required this.timestamp,
    required this.widgetId,
  });

  double get averageRepaintTime => 
      totalRepaintTime.inMicroseconds / repaintCount / 1000.0; // ms

  Map<String, dynamic> toJson() => {
    'repaintCount': repaintCount,
    'totalRepaintTime': totalRepaintTime.inMicroseconds,
    'averageRepaintTime': averageRepaintTime,
    'timestamp': timestamp.toIso8601String(),
    'widgetId': widgetId,
  };
}

/// 리페인트 분석기
class RepaintAnalyzer {
  static final RepaintAnalyzer _instance = RepaintAnalyzer._internal();
  factory RepaintAnalyzer() => _instance;
  RepaintAnalyzer._internal();

  final Map<String, RepaintMetrics> _metricsMap = {};
  final Map<String, Stopwatch> _activeStopwatches = {};
  final Map<String, int> _repaintCounts = {};
  
  bool _isAnalyzing = false;

  /// 분석 시작
  void startAnalyzing() {
    _isAnalyzing = true;
  }

  /// 분석 중지
  void stopAnalyzing() {
    _isAnalyzing = false;
    _clearMetrics();
  }

  /// 리페인트 시작 기록
  void recordRepaintStart(String widgetId) {
    if (!_isAnalyzing) return;
    
    _activeStopwatches[widgetId] = Stopwatch()..start();
    _repaintCounts[widgetId] = (_repaintCounts[widgetId] ?? 0) + 1;
  }

  /// 리페인트 종료 기록
  void recordRepaintEnd(String widgetId) {
    if (!_isAnalyzing) return;
    
    final stopwatch = _activeStopwatches.remove(widgetId);
    if (stopwatch != null) {
      stopwatch.stop();
      
      final existingMetrics = _metricsMap[widgetId];
      final newTotalTime = existingMetrics != null
          ? existingMetrics.totalRepaintTime + stopwatch.elapsed
          : stopwatch.elapsed;
      
      _metricsMap[widgetId] = RepaintMetrics(
        repaintCount: _repaintCounts[widgetId] ?? 1,
        totalRepaintTime: newTotalTime,
        timestamp: DateTime.now(),
        widgetId: widgetId,
      );
    }
  }

  /// 메트릭 가져오기
  RepaintMetrics? getMetrics(String widgetId) => _metricsMap[widgetId];

  /// 모든 메트릭 가져오기
  Map<String, RepaintMetrics> getAllMetrics() => Map.from(_metricsMap);

  /// 성능이 나쁜 위젯 찾기
  List<String> findPoorPerformanceWidgets({double threshold = 5.0}) {
    return _metricsMap.entries
        .where((entry) => entry.value.averageRepaintTime > threshold)
        .map((entry) => entry.key)
        .toList();
  }

  /// 메트릭 초기화
  void _clearMetrics() {
    _metricsMap.clear();
    _activeStopwatches.clear();
    _repaintCounts.clear();
  }

  /// 리소스 정리
  void dispose() {
    stopAnalyzing();
  }
}

/// 스마트 RepaintBoundary 위젯
class SmartRepaintBoundary extends StatefulWidget {
  const SmartRepaintBoundary({
    super.key,
    required this.child,
    this.debugName,
    this.enableMetrics = false,
    this.autoOptimize = true,
    this.repaintThreshold = 3,
    this.onMetricsUpdate,
  });

  final Widget child;
  final String? debugName;
  final bool enableMetrics;
  final bool autoOptimize;
  final int repaintThreshold;
  final ValueChanged<RepaintMetrics>? onMetricsUpdate;

  @override
  State<SmartRepaintBoundary> createState() => _SmartRepaintBoundaryState();
}

class _SmartRepaintBoundaryState extends State<SmartRepaintBoundary> {
  late final String _widgetId;
  final RepaintAnalyzer _analyzer = RepaintAnalyzer();
  int _repaintCount = 0;
  bool _shouldUseBoundary = true;

  @override
  void initState() {
    super.initState();
    _widgetId = widget.debugName ?? 'widget_${identityHashCode(this)}';
    
    if (widget.enableMetrics) {
      _analyzer.startAnalyzing();
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget child = _MonitoredWidget(
      widgetId: _widgetId,
      enableMetrics: widget.enableMetrics,
      onRepaint: _onRepaint,
      child: widget.child,
    );

    // 자동 최적화가 활성화되고 리페인트가 임계값을 초과하면 RepaintBoundary 적용
    if (widget.autoOptimize && _shouldUseBoundary && 
        _repaintCount >= widget.repaintThreshold) {
      child = RepaintBoundary(child: child);
    } else if (!widget.autoOptimize) {
      // 자동 최적화가 비활성화된 경우 항상 RepaintBoundary 적용
      child = RepaintBoundary(child: child);
    }

    return child;
  }

  void _onRepaint() {
    setState(() {
      _repaintCount++;
    });

    // 메트릭 업데이트 콜백
    if (widget.enableMetrics) {
      final metrics = _analyzer.getMetrics(_widgetId);
      if (metrics != null) {
        widget.onMetricsUpdate?.call(metrics);
      }
    }
  }

  @override
  void dispose() {
    if (widget.enableMetrics) {
      _analyzer.stopAnalyzing();
    }
    super.dispose();
  }
}

/// 리페인트 모니터링 위젯
class _MonitoredWidget extends SingleChildRenderObjectWidget {
  const _MonitoredWidget({
    required this.widgetId,
    required this.enableMetrics,
    required this.onRepaint,
    required Widget child,
  }) : super(child: child);

  final String widgetId;
  final bool enableMetrics;
  final VoidCallback onRepaint;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _MonitoredRenderObject(
      widgetId: widgetId,
      enableMetrics: enableMetrics,
      onRepaint: onRepaint,
    );
  }

  @override
  void updateRenderObject(BuildContext context, _MonitoredRenderObject renderObject) {
    renderObject
      ..widgetId = widgetId
      ..enableMetrics = enableMetrics
      ..onRepaint = onRepaint;
  }
}

/// 리페인트 모니터링 렌더 객체
class _MonitoredRenderObject extends RenderProxyBox {
  _MonitoredRenderObject({
    required String widgetId,
    required bool enableMetrics,
    required VoidCallback onRepaint,
  }) : _widgetId = widgetId,
       _enableMetrics = enableMetrics,
       _onRepaint = onRepaint;

  String _widgetId;
  bool _enableMetrics;
  VoidCallback _onRepaint;

  String get widgetId => _widgetId;
  set widgetId(String value) {
    if (_widgetId != value) {
      _widgetId = value;
      markNeedsPaint();
    }
  }

  bool get enableMetrics => _enableMetrics;
  set enableMetrics(bool value) {
    if (_enableMetrics != value) {
      _enableMetrics = value;
    }
  }

  VoidCallback get onRepaint => _onRepaint;
  set onRepaint(VoidCallback value) {
    _onRepaint = value;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_enableMetrics) {
      RepaintAnalyzer().recordRepaintStart(_widgetId);
    }

    _onRepaint();
    super.paint(context, offset);

    if (_enableMetrics) {
      RepaintAnalyzer().recordRepaintEnd(_widgetId);
    }
  }
}

/// 조건부 RepaintBoundary 위젯
class ConditionalRepaintBoundary extends StatelessWidget {
  const ConditionalRepaintBoundary({
    super.key,
    required this.child,
    this.condition = true,
    this.debugName,
  });

  final Widget child;
  final bool condition;
  final String? debugName;

  @override
  Widget build(BuildContext context) {
    if (condition) {
      return RepaintBoundary(
        child: child,
      );
    }
    return child;
  }
}

/// 애니메이션 최적화 RepaintBoundary
class AnimationRepaintBoundary extends StatefulWidget {
  const AnimationRepaintBoundary({
    super.key,
    required this.child,
    required this.animation,
    this.enableDuringAnimation = true,
    this.disableWhenIdle = false,
    this.debugName,
  });

  final Widget child;
  final Animation<double> animation;
  final bool enableDuringAnimation;
  final bool disableWhenIdle;
  final String? debugName;

  @override
  State<AnimationRepaintBoundary> createState() => _AnimationRepaintBoundaryState();
}

class _AnimationRepaintBoundaryState extends State<AnimationRepaintBoundary> {
  bool _shouldUseRepaintBoundary = false;

  @override
  void initState() {
    super.initState();
    widget.animation.addListener(_onAnimationChanged);
    _updateRepaintBoundaryState();
  }

  @override
  void didUpdateWidget(AnimationRepaintBoundary oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animation != widget.animation) {
      oldWidget.animation.removeListener(_onAnimationChanged);
      widget.animation.addListener(_onAnimationChanged);
      _updateRepaintBoundaryState();
    }
  }

  void _onAnimationChanged() {
    _updateRepaintBoundaryState();
  }

  void _updateRepaintBoundaryState() {
    final isAnimating = widget.animation.status == AnimationStatus.forward ||
                       widget.animation.status == AnimationStatus.reverse;
    
    bool newState;
    if (isAnimating) {
      newState = widget.enableDuringAnimation;
    } else {
      newState = !widget.disableWhenIdle;
    }

    if (newState != _shouldUseRepaintBoundary) {
      setState(() {
        _shouldUseRepaintBoundary = newState;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_shouldUseRepaintBoundary) {
      return RepaintBoundary(child: widget.child);
    }
    return widget.child;
  }

  @override
  void dispose() {
    widget.animation.removeListener(_onAnimationChanged);
    super.dispose();
  }
}

/// 리스트 아이템 RepaintBoundary
class ListItemRepaintBoundary extends StatelessWidget {
  const ListItemRepaintBoundary({
    super.key,
    required this.child,
    this.index,
    this.enableForComplexItems = true,
    this.complexityThreshold = 3,
  });

  final Widget child;
  final int? index;
  final bool enableForComplexItems;
  final int complexityThreshold;

  @override
  Widget build(BuildContext context) {
    if (!enableForComplexItems) {
      return RepaintBoundary(child: child);
    }

    // 위젯 복잡도 추정
    final complexity = _estimateComplexity(child);
    
    if (complexity >= complexityThreshold) {
      return RepaintBoundary(child: child);
    }

    return child;
  }

  int _estimateComplexity(Widget widget) {
    int complexity = 1;
    
    if (widget is StatefulWidget) complexity += 2;
    if (widget is AnimatedWidget) complexity += 3;
    if (widget is CustomPaint) complexity += 5;
    
    // 특정 위젯 타입에 따른 복잡도 증가
    if (widget is Image) complexity += 2;
    if (widget is Text) complexity += 1;
    if (widget is Container) complexity += 1;
    if (widget is Column || widget is Row) complexity += 1;
    
    return complexity;
  }
}

/// 이미지 RepaintBoundary
class ImageRepaintBoundary extends StatelessWidget {
  const ImageRepaintBoundary({
    super.key,
    required this.child,
    this.enableForNetworkImages = true,
    this.enableForAssetImages = false,
  });

  final Widget child;
  final bool enableForNetworkImages;
  final bool enableForAssetImages;

  @override
  Widget build(BuildContext context) {
    bool shouldUseBoundary = false;

    if (child is Image) {
      final image = child as Image;
      if (image.image is NetworkImage && enableForNetworkImages) {
        shouldUseBoundary = true;
      } else if (image.image is AssetImage && enableForAssetImages) {
        shouldUseBoundary = true;
      }
    }

    if (shouldUseBoundary) {
      return RepaintBoundary(child: child);
    }

    return child;
  }
}

/// RepaintBoundary 자동 배치기
class AutoRepaintBoundaryPlacer {
  static Widget wrapWithBoundaries(Widget widget, {
    bool enableForLists = true,
    bool enableForAnimations = true,
    bool enableForImages = true,
    bool enableForComplexWidgets = true,
  }) {
    return _RecursiveRepaintBoundaryWrapper(
      enableForLists: enableForLists,
      enableForAnimations: enableForAnimations,
      enableForImages: enableForImages,
      enableForComplexWidgets: enableForComplexWidgets,
      child: widget,
    );
  }
}

/// 재귀적 RepaintBoundary 래퍼
class _RecursiveRepaintBoundaryWrapper extends StatelessWidget {
  const _RecursiveRepaintBoundaryWrapper({
    required this.child,
    required this.enableForLists,
    required this.enableForAnimations,
    required this.enableForImages,
    required this.enableForComplexWidgets,
  });

  final Widget child;
  final bool enableForLists;
  final bool enableForAnimations;
  final bool enableForImages;
  final bool enableForComplexWidgets;

  @override
  Widget build(BuildContext context) {
    return _wrapWidget(child);
  }

  Widget _wrapWidget(Widget widget) {
    // 리스트 아이템에 대한 RepaintBoundary
    if (enableForLists && (widget is ListTile || _isListItem(widget))) {
      widget = ListItemRepaintBoundary(child: widget);
    }

    // 이미지에 대한 RepaintBoundary
    if (enableForImages && widget is Image) {
      widget = ImageRepaintBoundary(child: widget);
    }

    // 복잡한 위젯에 대한 RepaintBoundary
    if (enableForComplexWidgets && _isComplexWidget(widget)) {
      widget = RepaintBoundary(child: widget);
    }

    return widget;
  }

  bool _isListItem(Widget widget) {
    return widget is Card || 
           widget is ExpansionTile ||
           (widget is Container && _hasListItemCharacteristics(widget));
  }

  bool _hasListItemCharacteristics(Container container) {
    // Container가 리스트 아이템 특성을 가지는지 확인
    return container.margin != null || 
           container.padding != null ||
           container.decoration != null;
  }

  bool _isComplexWidget(Widget widget) {
    return widget is CustomPaint ||
           widget is AnimatedBuilder ||
           widget is Builder ||
           (widget is StatefulWidget && _hasComplexState(widget));
  }

  bool _hasComplexState(StatefulWidget widget) {
    // StatefulWidget이 복잡한 상태를 가지는지 추정
    return widget.toString().contains('Complex') ||
           widget.toString().contains('Heavy') ||
           widget.toString().contains('Expensive');
  }
}

/// RepaintBoundary 성능 분석 도구
class RepaintBoundaryAnalyzer {
  static void analyzeWidget(Widget widget) {
    _AnalyzerVisitor().visitWidget(widget);
  }

  static List<String> generateOptimizationSuggestions(Widget widget) {
    final visitor = _AnalyzerVisitor();
    visitor.visitWidget(widget);
    return visitor.suggestions;
  }
}

/// 위젯 분석 방문자
class _AnalyzerVisitor {
  final List<String> suggestions = [];
  int _depthLevel = 0;
  int _animatedWidgetCount = 0;
  int _imageCount = 0;
  int _customPaintCount = 0;

  void visitWidget(Widget widget) {
    _depthLevel++;
    
    _analyzeWidget(widget);
    
    // 자식 위젯들 분석 (간단한 예시)
    if (widget is Container && widget.child != null) {
      visitWidget(widget.child!);
    }
    
    _depthLevel--;
    
    if (_depthLevel == 0) {
      _generateSuggestions();
    }
  }

  void _analyzeWidget(Widget widget) {
    if (widget is AnimatedWidget || widget is AnimatedBuilder) {
      _animatedWidgetCount++;
    }
    
    if (widget is Image) {
      _imageCount++;
    }
    
    if (widget is CustomPaint) {
      _customPaintCount++;
    }
  }

  void _generateSuggestions() {
    if (_animatedWidgetCount > 0) {
      suggestions.add('애니메이션 위젯에 RepaintBoundary를 추가하여 성능을 향상시키세요.');
    }
    
    if (_imageCount > 3) {
      suggestions.add('다수의 이미지에 대해 RepaintBoundary를 사용하는 것을 고려하세요.');
    }
    
    if (_customPaintCount > 0) {
      suggestions.add('CustomPaint 위젯에는 반드시 RepaintBoundary를 사용하세요.');
    }
    
    if (_depthLevel > 10) {
      suggestions.add('위젯 트리가 깊습니다. 중간 레벨에 RepaintBoundary를 배치하세요.');
    }
  }
}

/// RepaintBoundary 디버깅 도구
class RepaintBoundaryDebugger {
  static Widget wrapWithDebugInfo(Widget child, {String? debugName}) {
    return _DebugRepaintBoundary(
      debugName: debugName ?? 'debug_${identityHashCode(child)}',
      child: child,
    );
  }
}

/// 디버그용 RepaintBoundary
class _DebugRepaintBoundary extends StatefulWidget {
  const _DebugRepaintBoundary({
    required this.debugName,
    required this.child,
  });

  final String debugName;
  final Widget child;

  @override
  State<_DebugRepaintBoundary> createState() => _DebugRepaintBoundaryState();
}

class _DebugRepaintBoundaryState extends State<_DebugRepaintBoundary> {
  int _repaintCount = 0;
  DateTime? _lastRepaint;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: _DebugMonitorWidget(
        debugName: widget.debugName,
        onRepaint: () {
          setState(() {
            _repaintCount++;
            _lastRepaint = DateTime.now();
          });
          
          debugPrint(
            'RepaintBoundary [${widget.debugName}] '
            'repainted $_repaintCount times. '
            'Last: ${_lastRepaint?.toIso8601String()}'
          );
        },
        child: widget.child,
      ),
    );
  }
}

/// 디버그 모니터 위젯
class _DebugMonitorWidget extends SingleChildRenderObjectWidget {
  const _DebugMonitorWidget({
    required this.debugName,
    required this.onRepaint,
    required Widget child,
  }) : super(child: child);

  final String debugName;
  final VoidCallback onRepaint;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _DebugMonitorRenderObject(onRepaint: onRepaint);
  }

  @override
  void updateRenderObject(BuildContext context, _DebugMonitorRenderObject renderObject) {
    renderObject.onRepaint = onRepaint;
  }
}

/// 디버그 모니터 렌더 객체
class _DebugMonitorRenderObject extends RenderProxyBox {
  _DebugMonitorRenderObject({required VoidCallback onRepaint}) 
      : _onRepaint = onRepaint;

  VoidCallback _onRepaint;

  VoidCallback get onRepaint => _onRepaint;
  set onRepaint(VoidCallback value) {
    _onRepaint = value;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    _onRepaint();
    super.paint(context, offset);
  }
}
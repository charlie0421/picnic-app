import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:picnic_lib/core/utils/logger.dart';

/// 위젯의 지연 로딩을 관리하는 클래스
///
/// 위젯의 가시성과 우선순위에 따라 로딩을 최적화하여
/// 앱 시작 시간과 메모리 사용량을 개선합니다.
class WidgetLazyLoader {
  static final WidgetLazyLoader _instance = WidgetLazyLoader._internal();
  factory WidgetLazyLoader() => _instance;
  WidgetLazyLoader._internal();

  final Map<String, LazyWidgetEntry> _lazyWidgets = {};
  final Map<String, Timer> _loadingTimers = {};
  final Set<String> _loadedWidgets = {};

  /// 지연 로딩할 위젯을 등록합니다
  void registerLazyWidget({
    required String id,
    required Widget Function() builder,
    LazyLoadPriority priority = LazyLoadPriority.normal,
    Duration? delay,
    bool preloadOnIdle = false,
  }) {
    _lazyWidgets[id] = LazyWidgetEntry(
      id: id,
      builder: builder,
      priority: priority,
      delay: delay,
      preloadOnIdle: preloadOnIdle,
    );

    logger.d('지연 로딩 위젯 등록: $id (우선순위: ${priority.name})');
  }

  /// 위젯을 즉시 로드합니다
  Widget loadWidget(String id) {
    final entry = _lazyWidgets[id];
    if (entry == null) {
      logger.w('등록되지 않은 지연 로딩 위젯: $id');
      return const SizedBox.shrink();
    }

    if (_loadedWidgets.contains(id)) {
      logger.d('이미 로드된 위젯: $id');
      return entry.cachedWidget ?? entry.builder();
    }

    try {
      final widget = entry.builder();
      entry.cachedWidget = widget;
      _loadedWidgets.add(id);

      logger.d('위젯 로드 완료: $id');
      return widget;
    } catch (e) {
      logger.e('위젯 로드 실패: $id', error: e);
      return ErrorWidget(e);
    }
  }

  /// 지연된 시간 후에 위젯을 로드합니다
  void scheduleWidgetLoad(String id, {Duration? customDelay}) {
    final entry = _lazyWidgets[id];
    if (entry == null || _loadedWidgets.contains(id)) {
      return;
    }

    final delay =
        customDelay ?? entry.delay ?? _getDefaultDelay(entry.priority);

    _loadingTimers[id]?.cancel();
    _loadingTimers[id] = Timer(delay, () {
      loadWidget(id);
      _loadingTimers.remove(id);
    });

    logger.d('위젯 로드 예약: $id (지연: ${delay.inMilliseconds}ms)');
  }

  /// 우선순위에 따른 기본 지연 시간을 반환합니다
  Duration _getDefaultDelay(LazyLoadPriority priority) {
    switch (priority) {
      case LazyLoadPriority.critical:
        return const Duration(milliseconds: 100);
      case LazyLoadPriority.high:
        return const Duration(milliseconds: 300);
      case LazyLoadPriority.normal:
        return const Duration(milliseconds: 500);
      case LazyLoadPriority.low:
        return const Duration(milliseconds: 1000);
      case LazyLoadPriority.background:
        return const Duration(milliseconds: 2000);
    }
  }

  /// 유휴 시간에 위젯들을 미리 로드합니다
  void preloadOnIdle() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final preloadEntries = _lazyWidgets.values
          .where((entry) =>
              entry.preloadOnIdle && !_loadedWidgets.contains(entry.id))
          .toList();

      // 우선순위 순으로 정렬
      preloadEntries
          .sort((a, b) => a.priority.index.compareTo(b.priority.index));

      for (final entry in preloadEntries) {
        scheduleWidgetLoad(entry.id);
      }

      logger.i('유휴 시간 미리 로드 시작: ${preloadEntries.length}개 위젯');
    });
  }

  /// 특정 위젯이 로드되었는지 확인합니다
  bool isWidgetLoaded(String id) {
    return _loadedWidgets.contains(id);
  }

  /// 모든 타이머를 취소하고 상태를 초기화합니다
  void dispose() {
    for (final timer in _loadingTimers.values) {
      timer.cancel();
    }
    _loadingTimers.clear();
    _lazyWidgets.clear();
    _loadedWidgets.clear();

    logger.d('WidgetLazyLoader 정리 완료');
  }

  /// 현재 상태를 반환합니다
  Map<String, dynamic> getStatus() {
    return {
      'registered_widgets': _lazyWidgets.length,
      'loaded_widgets': _loadedWidgets.length,
      'pending_timers': _loadingTimers.length,
      'loaded_widget_ids': _loadedWidgets.toList(),
    };
  }
}

/// 지연 로딩 위젯 정보를 담는 클래스
class LazyWidgetEntry {
  final String id;
  final Widget Function() builder;
  final LazyLoadPriority priority;
  final Duration? delay;
  final bool preloadOnIdle;
  Widget? cachedWidget;

  LazyWidgetEntry({
    required this.id,
    required this.builder,
    required this.priority,
    this.delay,
    required this.preloadOnIdle,
  });
}

/// 지연 로딩 우선순위
enum LazyLoadPriority {
  critical, // 즉시 로드 (100ms)
  high, // 높음 (300ms)
  normal, // 보통 (500ms)
  low, // 낮음 (1000ms)
  background, // 백그라운드 (2000ms)
}

/// 지연 로딩 위젯을 위한 래퍼 위젯
class LazyWidget extends StatefulWidget {
  final String id;
  final Widget Function() builder;
  final Widget? placeholder;
  final LazyLoadPriority priority;
  final Duration? delay;
  final bool preloadOnIdle;
  final bool loadOnVisible;

  const LazyWidget({
    super.key,
    required this.id,
    required this.builder,
    this.placeholder,
    this.priority = LazyLoadPriority.normal,
    this.delay,
    this.preloadOnIdle = false,
    this.loadOnVisible = true,
  });

  @override
  State<LazyWidget> createState() => _LazyWidgetState();
}

class _LazyWidgetState extends State<LazyWidget> {
  final WidgetLazyLoader _loader = WidgetLazyLoader();
  bool _isVisible = false;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();

    // 지연 로딩 위젯 등록
    _loader.registerLazyWidget(
      id: widget.id,
      builder: widget.builder,
      priority: widget.priority,
      delay: widget.delay,
      preloadOnIdle: widget.preloadOnIdle,
    );

    // 가시성에 따른 로딩이 비활성화된 경우 즉시 로드 예약
    if (!widget.loadOnVisible) {
      _loader.scheduleWidgetLoad(widget.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 이미 로드된 경우 위젯 반환
    if (_loader.isWidgetLoaded(widget.id)) {
      return _loader.loadWidget(widget.id);
    }

    // 가시성 기반 로딩이 활성화된 경우
    if (widget.loadOnVisible) {
      return VisibilityDetector(
        key: Key('lazy_${widget.id}'),
        onVisibilityChanged: _onVisibilityChanged,
        child: widget.placeholder ?? const SizedBox.shrink(),
      );
    }

    // 플레이스홀더 반환
    return widget.placeholder ?? const SizedBox.shrink();
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    final isVisible = info.visibleFraction > 0;

    if (isVisible && !_isVisible && !_isLoaded) {
      _isVisible = true;
      _loader.scheduleWidgetLoad(widget.id);

      // 로드 완료 후 리빌드
      Timer.periodic(const Duration(milliseconds: 100), (timer) {
        if (_loader.isWidgetLoaded(widget.id)) {
          timer.cancel();
          if (mounted) {
            setState(() {
              _isLoaded = true;
            });
          }
        }
      });
    }

    _isVisible = isVisible;
  }
}

/// 가시성 감지를 위한 위젯
class VisibilityDetector extends StatefulWidget {
  final Widget child;
  final ValueChanged<VisibilityInfo> onVisibilityChanged;

  const VisibilityDetector({
    super.key,
    required this.child,
    required this.onVisibilityChanged,
  });

  @override
  State<VisibilityDetector> createState() => _VisibilityDetectorState();
}

class _VisibilityDetectorState extends State<VisibilityDetector> {
  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _checkVisibility();
        });
        return false;
      },
      child: widget.child,
    );
  }

  void _checkVisibility() {
    final renderObject = context.findRenderObject();
    if (renderObject is RenderBox && renderObject.hasSize) {
      final viewport = RenderAbstractViewport.of(renderObject);
      viewport.getOffsetToReveal(renderObject, 0.0);
      final visibleFraction = _calculateVisibleFraction(renderObject, viewport);

      widget.onVisibilityChanged(VisibilityInfo(
        visibleFraction: visibleFraction,
        size: renderObject.size,
      ));
    }
  }

  double _calculateVisibleFraction(
      RenderBox renderBox, RenderAbstractViewport viewport) {
    // 간단한 가시성 계산 (실제로는 더 복잡한 로직이 필요할 수 있음)
    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final screenSize = MediaQuery.of(context).size;

    // 화면 내에 있는지 확인
    if (position.dy + size.height < 0 || position.dy > screenSize.height) {
      return 0.0;
    }

    return 1.0; // 간단히 완전히 보이는 것으로 처리
  }
}

/// 가시성 정보를 담는 클래스
class VisibilityInfo {
  final double visibleFraction;
  final Size size;

  const VisibilityInfo({
    required this.visibleFraction,
    required this.size,
  });
}

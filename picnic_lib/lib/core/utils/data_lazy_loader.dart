import 'dart:async';

import 'package:flutter/material.dart';
import 'package:picnic_lib/core/utils/logger.dart';

/// 데이터의 지연 로딩을 관리하는 클래스
///
/// API 호출, 캐시 로딩, 데이터베이스 쿼리 등을 우선순위에 따라
/// 지연 로딩하여 앱 시작 시간을 최적화합니다.
class DataLazyLoader {
  static final DataLazyLoader _instance = DataLazyLoader._internal();
  factory DataLazyLoader() => _instance;
  DataLazyLoader._internal();

  final Map<String, LazyDataEntry> _lazyData = {};
  final Map<String, Timer> _loadingTimers = {};
  final Map<String, dynamic> _loadedData = {};
  final Map<String, Completer<dynamic>> _loadingCompleters = {};
  final Set<String> _failedLoads = {};

  /// 지연 로딩할 데이터를 등록합니다
  void registerLazyData<T>({
    required String id,
    required Future<T> Function() loader,
    DataLoadPriority priority = DataLoadPriority.normal,
    Duration? delay,
    bool preloadOnIdle = false,
    bool cacheResult = true,
    Duration? cacheExpiry,
    int maxRetries = 3,
  }) {
    _lazyData[id] = LazyDataEntry<T>(
      id: id,
      loader: loader,
      priority: priority,
      delay: delay,
      preloadOnIdle: preloadOnIdle,
      cacheResult: cacheResult,
      cacheExpiry: cacheExpiry,
      maxRetries: maxRetries,
    );

    logger.d('지연 로딩 데이터 등록: $id (우선순위: ${priority.name})');
  }

  /// 데이터를 즉시 로드합니다
  Future<T?> loadData<T>(String id) async {
    final entry = _lazyData[id] as LazyDataEntry<T>?;
    if (entry == null) {
      logger.w('등록되지 않은 지연 로딩 데이터: $id');
      return null;
    }

    // 이미 로드된 데이터가 있고 캐시가 유효한 경우
    if (_loadedData.containsKey(id)) {
      final cachedEntry = _loadedData[id] as CachedDataEntry<T>;
      if (_isCacheValid(cachedEntry)) {
        logger.d('캐시된 데이터 반환: $id');
        return cachedEntry.data;
      } else {
        logger.d('캐시 만료, 데이터 재로드: $id');
        _loadedData.remove(id);
      }
    }

    // 이미 로딩 중인 경우 완료를 기다림
    if (_loadingCompleters.containsKey(id)) {
      logger.d('데이터 로딩 대기 중: $id');
      return await _loadingCompleters[id]!.future as T?;
    }

    final completer = Completer<T?>();
    _loadingCompleters[id] = completer;

    try {
      logger.d('데이터 로드 시작: $id');
      final data = await _loadDataWithRetry(entry);

      if (entry.cacheResult && data != null) {
        _loadedData[id] = CachedDataEntry<T>(
          data: data,
          loadedAt: DateTime.now(),
          expiry: entry.cacheExpiry,
        );
      }

      _failedLoads.remove(id);
      completer.complete(data);
      logger.d('데이터 로드 완료: $id');

      return data;
    } catch (e) {
      logger.e('데이터 로드 실패: $id', error: e);
      _failedLoads.add(id);
      completer.complete(null);
      return null;
    } finally {
      _loadingCompleters.remove(id);
    }
  }

  /// 재시도 로직을 포함한 데이터 로드
  Future<T?> _loadDataWithRetry<T>(LazyDataEntry<T> entry) async {
    int attempts = 0;
    Exception? lastException;

    while (attempts < entry.maxRetries) {
      try {
        attempts++;
        final data = await entry.loader();
        return data;
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        logger.w('데이터 로드 시도 $attempts/${entry.maxRetries} 실패: ${entry.id}',
            error: e);

        if (attempts < entry.maxRetries) {
          // 지수 백오프로 재시도 지연
          final delay = Duration(milliseconds: 1000 * attempts);
          await Future.delayed(delay);
        }
      }
    }

    throw lastException ?? Exception('데이터 로드 실패: ${entry.id}');
  }

  /// 지연된 시간 후에 데이터를 로드합니다
  void scheduleDataLoad(String id, {Duration? customDelay}) {
    final entry = _lazyData[id];
    if (entry == null || _loadedData.containsKey(id)) {
      return;
    }

    final delay =
        customDelay ?? entry.delay ?? _getDefaultDelay(entry.priority);

    _loadingTimers[id]?.cancel();
    _loadingTimers[id] = Timer(delay, () {
      loadData(id);
      _loadingTimers.remove(id);
    });

    logger.d('데이터 로드 예약: $id (지연: ${delay.inMilliseconds}ms)');
  }

  /// 우선순위에 따른 기본 지연 시간을 반환합니다
  Duration _getDefaultDelay(DataLoadPriority priority) {
    switch (priority) {
      case DataLoadPriority.critical:
        return const Duration(milliseconds: 0);
      case DataLoadPriority.high:
        return const Duration(milliseconds: 200);
      case DataLoadPriority.normal:
        return const Duration(milliseconds: 500);
      case DataLoadPriority.low:
        return const Duration(milliseconds: 1000);
      case DataLoadPriority.background:
        return const Duration(milliseconds: 3000);
    }
  }

  /// 유휴 시간에 데이터를 미리 로드합니다
  void preloadOnIdle() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final preloadEntries = _lazyData.values
          .where((entry) =>
              entry.preloadOnIdle && !_loadedData.containsKey(entry.id))
          .toList();

      // 우선순위 순으로 정렬
      preloadEntries
          .sort((a, b) => a.priority.index.compareTo(b.priority.index));

      for (final entry in preloadEntries) {
        scheduleDataLoad(entry.id);
      }

      logger.i('유휴 시간 데이터 미리 로드 시작: ${preloadEntries.length}개 항목');
    });
  }

  /// 캐시가 유효한지 확인합니다
  bool _isCacheValid<T>(CachedDataEntry<T> cachedEntry) {
    if (cachedEntry.expiry == null) {
      return true; // 만료 시간이 없으면 항상 유효
    }

    final now = DateTime.now();
    final expiryTime = cachedEntry.loadedAt.add(cachedEntry.expiry!);
    return now.isBefore(expiryTime);
  }

  /// 특정 데이터가 로드되었는지 확인합니다
  bool isDataLoaded(String id) {
    return _loadedData.containsKey(id) && !_failedLoads.contains(id);
  }

  /// 특정 데이터가 로딩 중인지 확인합니다
  bool isDataLoading(String id) {
    return _loadingCompleters.containsKey(id);
  }

  /// 캐시된 데이터를 무효화합니다
  void invalidateCache(String id) {
    _loadedData.remove(id);
    _failedLoads.remove(id);
    logger.d('캐시 무효화: $id');
  }

  /// 모든 캐시를 무효화합니다
  void invalidateAllCache() {
    _loadedData.clear();
    _failedLoads.clear();
    logger.d('모든 캐시 무효화');
  }

  /// 실패한 로드를 재시도합니다
  Future<T?> retryFailedLoad<T>(String id) async {
    if (!_failedLoads.contains(id)) {
      logger.w('실패하지 않은 데이터 재시도 요청: $id');
      return null;
    }

    _failedLoads.remove(id);
    return await loadData<T>(id);
  }

  /// 모든 타이머를 취소하고 상태를 초기화합니다
  void dispose() {
    for (final timer in _loadingTimers.values) {
      timer.cancel();
    }
    _loadingTimers.clear();

    for (final completer in _loadingCompleters.values) {
      if (!completer.isCompleted) {
        completer.complete(null);
      }
    }
    _loadingCompleters.clear();

    _lazyData.clear();
    _loadedData.clear();
    _failedLoads.clear();

    logger.d('DataLazyLoader 정리 완료');
  }

  /// 현재 상태를 반환합니다
  Map<String, dynamic> getStatus() {
    return {
      'registered_data': _lazyData.length,
      'loaded_data': _loadedData.length,
      'loading_data': _loadingCompleters.length,
      'failed_loads': _failedLoads.length,
      'pending_timers': _loadingTimers.length,
      'loaded_data_ids': _loadedData.keys.toList(),
      'failed_data_ids': _failedLoads.toList(),
    };
  }
}

/// 지연 로딩 데이터 정보를 담는 클래스
class LazyDataEntry<T> {
  final String id;
  final Future<T> Function() loader;
  final DataLoadPriority priority;
  final Duration? delay;
  final bool preloadOnIdle;
  final bool cacheResult;
  final Duration? cacheExpiry;
  final int maxRetries;

  LazyDataEntry({
    required this.id,
    required this.loader,
    required this.priority,
    this.delay,
    required this.preloadOnIdle,
    required this.cacheResult,
    this.cacheExpiry,
    required this.maxRetries,
  });
}

/// 캐시된 데이터 정보를 담는 클래스
class CachedDataEntry<T> {
  final T data;
  final DateTime loadedAt;
  final Duration? expiry;

  CachedDataEntry({
    required this.data,
    required this.loadedAt,
    this.expiry,
  });
}

/// 데이터 로드 우선순위
enum DataLoadPriority {
  critical, // 즉시 로드 (0ms)
  high, // 높음 (200ms)
  normal, // 보통 (500ms)
  low, // 낮음 (1000ms)
  background, // 백그라운드 (3000ms)
}

/// 지연 로딩 데이터를 위한 FutureBuilder 래퍼
class LazyDataBuilder<T> extends StatefulWidget {
  final String dataId;
  final Widget Function(BuildContext context, T data) builder;
  final Widget Function(BuildContext context)? loadingBuilder;
  final Widget Function(BuildContext context, Object? error)? errorBuilder;
  final bool autoLoad;

  const LazyDataBuilder({
    super.key,
    required this.dataId,
    required this.builder,
    this.loadingBuilder,
    this.errorBuilder,
    this.autoLoad = true,
  });

  @override
  State<LazyDataBuilder<T>> createState() => _LazyDataBuilderState<T>();
}

class _LazyDataBuilderState<T> extends State<LazyDataBuilder<T>> {
  final DataLazyLoader _loader = DataLazyLoader();
  Future<T?>? _dataFuture;

  @override
  void initState() {
    super.initState();

    if (widget.autoLoad) {
      _loadData();
    }
  }

  void _loadData() {
    _dataFuture = _loader.loadData<T>(widget.dataId);
  }

  @override
  Widget build(BuildContext context) {
    if (_dataFuture == null) {
      return widget.loadingBuilder?.call(context) ??
          const Center(child: CircularProgressIndicator());
    }

    return FutureBuilder<T?>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return widget.loadingBuilder?.call(context) ??
              const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return widget.errorBuilder?.call(context, snapshot.error) ??
              Center(child: Text('오류: ${snapshot.error}'));
        }

        final data = snapshot.data;
        if (data == null) {
          return widget.errorBuilder?.call(context, '데이터 없음') ??
              const Center(child: Text('데이터를 불러올 수 없습니다'));
        }

        return widget.builder(context, data);
      },
    );
  }

  /// 수동으로 데이터를 다시 로드합니다
  void reload() {
    setState(() {
      _loadData();
    });
  }
}

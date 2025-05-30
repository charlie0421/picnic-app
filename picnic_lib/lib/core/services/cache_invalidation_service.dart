import 'dart:async';
import 'dart:convert';
import 'package:picnic_lib/core/services/simple_cache_manager.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 캐시 무효화 이벤트 타입
enum InvalidationEventType {
  userAction, // 사용자 액션으로 인한 무효화
  dataUpdate, // 데이터 업데이트로 인한 무효화
  timeExpiry, // 시간 만료로 인한 무효화
  remoteSignal, // 원격 신호로 인한 무효화
  systemEvent, // 시스템 이벤트로 인한 무효화
  manual, // 수동 무효화
}

/// 캐시 무효화 이벤트
class CacheInvalidationEvent {
  final String id;
  final InvalidationEventType type;
  final String source;
  final List<String> tags;
  final List<String> patterns;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;
  final int priority; // 1-10, 높을수록 우선순위 높음

  CacheInvalidationEvent({
    required this.id,
    required this.type,
    required this.source,
    this.tags = const [],
    this.patterns = const [],
    this.metadata = const {},
    DateTime? timestamp,
    this.priority = 5,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'source': source,
      'tags': tags,
      'patterns': patterns,
      'metadata': metadata,
      'timestamp': timestamp.toIso8601String(),
      'priority': priority,
    };
  }

  factory CacheInvalidationEvent.fromJson(Map<String, dynamic> json) {
    return CacheInvalidationEvent(
      id: json['id'] as String,
      type: InvalidationEventType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => InvalidationEventType.manual,
      ),
      source: json['source'] as String,
      tags: List<String>.from(json['tags'] as List? ?? []),
      patterns: List<String>.from(json['patterns'] as List? ?? []),
      metadata: Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
      timestamp: DateTime.parse(json['timestamp'] as String),
      priority: json['priority'] as int? ?? 5,
    );
  }
}

/// 캐시 태그 정보
class CacheTag {
  final String name;
  final String description;
  final List<String> relatedPatterns;
  final Duration defaultTtl;
  final int priority;

  const CacheTag({
    required this.name,
    required this.description,
    this.relatedPatterns = const [],
    this.defaultTtl = const Duration(hours: 1),
    this.priority = 5,
  });
}

/// 캐시 워밍 작업
class CacheWarmingTask {
  final String id;
  final String url;
  final Map<String, String> headers;
  final Duration interval;
  final DateTime nextRun;
  final bool isActive;
  final int priority;

  CacheWarmingTask({
    required this.id,
    required this.url,
    this.headers = const {},
    this.interval = const Duration(hours: 1),
    DateTime? nextRun,
    this.isActive = true,
    this.priority = 5,
  }) : nextRun = nextRun ?? DateTime.now().add(interval);

  CacheWarmingTask copyWith({
    String? id,
    String? url,
    Map<String, String>? headers,
    Duration? interval,
    DateTime? nextRun,
    bool? isActive,
    int? priority,
  }) {
    return CacheWarmingTask(
      id: id ?? this.id,
      url: url ?? this.url,
      headers: headers ?? this.headers,
      interval: interval ?? this.interval,
      nextRun: nextRun ?? this.nextRun,
      isActive: isActive ?? this.isActive,
      priority: priority ?? this.priority,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'headers': headers,
      'interval': interval.inMilliseconds,
      'nextRun': nextRun.toIso8601String(),
      'isActive': isActive,
      'priority': priority,
    };
  }

  factory CacheWarmingTask.fromJson(Map<String, dynamic> json) {
    return CacheWarmingTask(
      id: json['id'] as String,
      url: json['url'] as String,
      headers: Map<String, String>.from(json['headers'] as Map? ?? {}),
      interval: Duration(milliseconds: json['interval'] as int),
      nextRun: DateTime.parse(json['nextRun'] as String),
      isActive: json['isActive'] as bool? ?? true,
      priority: json['priority'] as int? ?? 5,
    );
  }
}

/// 고급 캐시 무효화 서비스
class CacheInvalidationService {
  static const String _eventQueueKey = 'cache_invalidation_events';
  static const String _tagMappingKey = 'cache_tag_mapping';
  static const String _warmingTasksKey = 'cache_warming_tasks';
  static const String _remoteSignalsKey = 'cache_remote_signals';

  late SharedPreferences _prefs;
  final SimpleCacheManager _cacheManager;

  // 이벤트 스트림
  final StreamController<CacheInvalidationEvent> _eventController =
      StreamController<CacheInvalidationEvent>.broadcast();

  // 무효화 이벤트 큐
  final List<CacheInvalidationEvent> _eventQueue = [];

  // 태그 매핑 (URL -> Tags)
  final Map<String, Set<String>> _urlTagMapping = {};

  // 캐시 워밍 작업들
  final Map<String, CacheWarmingTask> _warmingTasks = {};

  // 타이머들
  Timer? _processingTimer;
  Timer? _warmingTimer;
  Timer? _remoteCheckTimer;

  static CacheInvalidationService? _instance;

  static CacheInvalidationService get instance =>
      _instance ??= CacheInvalidationService._();

  CacheInvalidationService._() : _cacheManager = SimpleCacheManager.instance;

  /// 이벤트 스트림
  Stream<CacheInvalidationEvent> get eventStream => _eventController.stream;

  /// 미리 정의된 캐시 태그들
  static const Map<String, CacheTag> predefinedTags = {
    'user_profile': CacheTag(
      name: 'user_profile',
      description: '사용자 프로필 관련 데이터',
      relatedPatterns: [r'/api/user_profiles/.*', r'/rest/v1/user_profiles.*'],
      defaultTtl: Duration(hours: 6),
      priority: 8,
    ),
    'user_posts': CacheTag(
      name: 'user_posts',
      description: '사용자 게시물 관련 데이터',
      relatedPatterns: [r'/api/posts/.*', r'/rest/v1/posts.*'],
      defaultTtl: Duration(hours: 2),
      priority: 7,
    ),
    'config': CacheTag(
      name: 'config',
      description: '앱 설정 및 구성 데이터',
      relatedPatterns: [r'/api/config.*', r'/rest/v1/config.*'],
      defaultTtl: Duration(hours: 24),
      priority: 9,
    ),
    'products': CacheTag(
      name: 'products',
      description: '상품 관련 데이터',
      relatedPatterns: [r'/api/products/.*', r'/rest/v1/products.*'],
      defaultTtl: Duration(hours: 2),
      priority: 6,
    ),
    'static_content': CacheTag(
      name: 'static_content',
      description: '정적 콘텐츠',
      relatedPatterns: [r'/assets/.*', r'/images/.*', r'/static/.*'],
      defaultTtl: Duration(days: 7),
      priority: 4,
    ),
    'popup_data': CacheTag(
      name: 'popup_data',
      description: '팝업 및 알림 데이터',
      relatedPatterns: [r'/api/popups/.*', r'/api/notifications/.*'],
      defaultTtl: Duration(minutes: 30),
      priority: 3,
    ),
  };

  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();

      // 저장된 데이터 로드
      await _loadEventQueue();
      await _loadTagMapping();
      await _loadWarmingTasks();

      // 타이머 시작
      _startProcessingTimer();
      _startWarmingTimer();
      _startRemoteCheckTimer();

      logger.i('CacheInvalidationService initialized successfully');
    } catch (e, s) {
      logger.e('Failed to initialize CacheInvalidationService',
          error: e, stackTrace: s);
      rethrow;
    }
  }

  /// 무효화 이벤트 추가
  Future<void> addInvalidationEvent(CacheInvalidationEvent event) async {
    try {
      _eventQueue.add(event);
      _eventController.add(event);

      // 높은 우선순위 이벤트는 즉시 처리
      if (event.priority >= 8) {
        await _processEvent(event);
      }

      await _saveEventQueue();

      logger.d('Added invalidation event: ${event.id} (${event.type.name})');
    } catch (e, s) {
      logger.e('Error adding invalidation event', error: e, stackTrace: s);
    }
  }

  /// 태그 기반 무효화
  Future<void> invalidateByTags(
    List<String> tags, {
    String source = 'manual',
    InvalidationEventType type = InvalidationEventType.manual,
    int priority = 5,
  }) async {
    final event = CacheInvalidationEvent(
      id: 'tag_${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      source: source,
      tags: tags,
      priority: priority,
    );

    await addInvalidationEvent(event);
  }

  /// URL에 태그 할당
  Future<void> assignTagsToUrl(String url, List<String> tags) async {
    try {
      _urlTagMapping[url] = tags.toSet();
      await _saveTagMapping();

      logger.d('Assigned tags $tags to URL: $url');
    } catch (e, s) {
      logger.e('Error assigning tags to URL', error: e, stackTrace: s);
    }
  }

  /// URL의 태그 조회
  Set<String> getTagsForUrl(String url) {
    // 직접 매핑된 태그 확인
    if (_urlTagMapping.containsKey(url)) {
      return _urlTagMapping[url]!;
    }

    // 패턴 기반 태그 매칭
    final tags = <String>{};
    for (final entry in predefinedTags.entries) {
      for (final pattern in entry.value.relatedPatterns) {
        if (RegExp(pattern).hasMatch(url)) {
          tags.add(entry.key);
        }
      }
    }

    return tags;
  }

  /// 캐시 워밍 작업 추가
  Future<void> addWarmingTask(CacheWarmingTask task) async {
    try {
      _warmingTasks[task.id] = task;
      await _saveWarmingTasks();

      logger.d('Added cache warming task: ${task.id} for ${task.url}');
    } catch (e, s) {
      logger.e('Error adding warming task', error: e, stackTrace: s);
    }
  }

  /// 캐시 워밍 작업 제거
  Future<void> removeWarmingTask(String taskId) async {
    try {
      _warmingTasks.remove(taskId);
      await _saveWarmingTasks();

      logger.d('Removed cache warming task: $taskId');
    } catch (e, s) {
      logger.e('Error removing warming task', error: e, stackTrace: s);
    }
  }

  /// 원격 무효화 신호 확인
  Future<void> checkRemoteInvalidationSignals() async {
    try {
      // 여기서는 Supabase의 실시간 기능이나 Firebase의 Remote Config를 사용할 수 있습니다
      // 예시로 SharedPreferences에서 원격 신호를 확인합니다

      final signals = _prefs.getStringList(_remoteSignalsKey) ?? [];

      for (final signalJson in signals) {
        try {
          final signal = jsonDecode(signalJson) as Map<String, dynamic>;
          final timestamp = DateTime.parse(signal['timestamp'] as String);

          // 5분 이내의 신호만 처리
          if (DateTime.now().difference(timestamp).inMinutes <= 5) {
            final event = CacheInvalidationEvent(
              id: 'remote_${signal['id']}',
              type: InvalidationEventType.remoteSignal,
              source: 'remote_server',
              tags: List<String>.from(signal['tags'] as List? ?? []),
              patterns: List<String>.from(signal['patterns'] as List? ?? []),
              priority: signal['priority'] as int? ?? 7,
            );

            await addInvalidationEvent(event);
          }
        } catch (e) {
          logger.w('Invalid remote signal format: $signalJson');
        }
      }

      // 처리된 신호들 제거
      await _prefs.remove(_remoteSignalsKey);
    } catch (e, s) {
      logger.e('Error checking remote invalidation signals',
          error: e, stackTrace: s);
    }
  }

  /// 스마트 무효화 (관련 데이터 자동 감지)
  Future<void> smartInvalidate(
    String modifiedUrl, {
    String source = 'auto',
    Map<String, dynamic> metadata = const {},
  }) async {
    try {
      final tags = getTagsForUrl(modifiedUrl);
      final relatedPatterns = <String>[];

      // 태그 기반 관련 패턴 수집
      for (final tag in tags) {
        final tagInfo = predefinedTags[tag];
        if (tagInfo != null) {
          relatedPatterns.addAll(tagInfo.relatedPatterns);
        }
      }

      // URL 기반 관련 패턴 추가
      if (modifiedUrl.contains('/user_profiles/')) {
        relatedPatterns.addAll([
          r'/api/user_profiles/.*',
          r'/api/posts/user/.*',
          r'/api/followers/.*',
        ]);
      } else if (modifiedUrl.contains('/posts/')) {
        relatedPatterns.addAll([
          r'/api/posts/.*',
          r'/api/comments/.*',
          r'/api/likes/.*',
        ]);
      } else if (modifiedUrl.contains('/products/')) {
        relatedPatterns.addAll([
          r'/api/products/.*',
          r'/api/categories/.*',
          r'/api/inventory/.*',
        ]);
      }

      final event = CacheInvalidationEvent(
        id: 'smart_${DateTime.now().millisecondsSinceEpoch}',
        type: InvalidationEventType.dataUpdate,
        source: source,
        tags: tags.toList(),
        patterns: relatedPatterns,
        metadata: {
          'originalUrl': modifiedUrl,
          ...metadata,
        },
        priority: 7,
      );

      await addInvalidationEvent(event);

      logger.d('Smart invalidation triggered for: $modifiedUrl');
    } catch (e, s) {
      logger.e('Error in smart invalidation', error: e, stackTrace: s);
    }
  }

  /// 이벤트 처리
  Future<void> _processEvent(CacheInvalidationEvent event) async {
    try {
      logger.d('Processing invalidation event: ${event.id}');

      // 태그 기반 무효화
      for (final tag in event.tags) {
        await _invalidateByTag(tag);
      }

      // 패턴 기반 무효화
      for (final pattern in event.patterns) {
        await _cacheManager.invalidateByPattern(pattern);
      }

      // 특별한 처리가 필요한 이벤트 타입들
      switch (event.type) {
        case InvalidationEventType.userAction:
          await _handleUserActionInvalidation(event);
          break;
        case InvalidationEventType.dataUpdate:
          await _handleDataUpdateInvalidation(event);
          break;
        case InvalidationEventType.systemEvent:
          await _handleSystemEventInvalidation(event);
          break;
        default:
          break;
      }

      logger.d('Completed processing event: ${event.id}');
    } catch (e, s) {
      logger.e('Error processing invalidation event: ${event.id}',
          error: e, stackTrace: s);
    }
  }

  /// 태그 기반 무효화 실행
  Future<void> _invalidateByTag(String tag) async {
    try {
      final tagInfo = predefinedTags[tag];
      if (tagInfo != null) {
        for (final pattern in tagInfo.relatedPatterns) {
          await _cacheManager.invalidateByPattern(pattern);
        }
      }

      // 직접 매핑된 URL들도 무효화
      final urlsToInvalidate = <String>[];
      for (final entry in _urlTagMapping.entries) {
        if (entry.value.contains(tag)) {
          urlsToInvalidate.add(entry.key);
        }
      }

      for (final url in urlsToInvalidate) {
        await _cacheManager.invalidateByPattern(RegExp.escape(url));
      }

      logger.d('Invalidated cache for tag: $tag');
    } catch (e, s) {
      logger.e('Error invalidating by tag: $tag', error: e, stackTrace: s);
    }
  }

  /// 사용자 액션 무효화 처리
  Future<void> _handleUserActionInvalidation(
      CacheInvalidationEvent event) async {
    // 사용자 관련 캐시만 무효화
    await _cacheManager.invalidateByPattern(r'/api/user_profiles/.*');
    await _cacheManager.invalidateByPattern(r'/api/posts/user/.*');
  }

  /// 데이터 업데이트 무효화 처리
  Future<void> _handleDataUpdateInvalidation(
      CacheInvalidationEvent event) async {
    final originalUrl = event.metadata['originalUrl'] as String?;
    if (originalUrl != null) {
      await _cacheManager.invalidateForModification(originalUrl);
    }
  }

  /// 시스템 이벤트 무효화 처리
  Future<void> _handleSystemEventInvalidation(
      CacheInvalidationEvent event) async {
    // 시스템 이벤트에 따라 전체 캐시 또는 특정 부분 무효화
    if (event.metadata['clearAll'] == true) {
      await _cacheManager.clear();
    }
  }

  /// 이벤트 처리 타이머 시작
  void _startProcessingTimer() {
    _processingTimer =
        Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (_eventQueue.isNotEmpty) {
        // 우선순위 순으로 정렬
        _eventQueue.sort((a, b) => b.priority.compareTo(a.priority));

        // 최대 5개 이벤트 처리
        final eventsToProcess = _eventQueue.take(5).toList();
        _eventQueue.removeRange(0, eventsToProcess.length);

        for (final event in eventsToProcess) {
          await _processEvent(event);
        }

        await _saveEventQueue();
      }
    });
  }

  /// 캐시 워밍 타이머 시작
  void _startWarmingTimer() {
    _warmingTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      await _executeWarmingTasks();
    });
  }

  /// 원격 신호 확인 타이머 시작
  void _startRemoteCheckTimer() {
    _remoteCheckTimer =
        Timer.periodic(const Duration(minutes: 2), (timer) async {
      await checkRemoteInvalidationSignals();
    });
  }

  /// 캐시 워밍 작업 실행
  Future<void> _executeWarmingTasks() async {
    try {
      final now = DateTime.now();
      final tasksToRun = _warmingTasks.values
          .where((task) => task.isActive && now.isAfter(task.nextRun))
          .toList();

      // 우선순위 순으로 정렬
      tasksToRun.sort((a, b) => b.priority.compareTo(a.priority));

      for (final task in tasksToRun.take(3)) {
        // 최대 3개 작업 동시 실행
        try {
          // 여기서 실제 HTTP 요청을 보내서 캐시를 워밍할 수 있습니다
          // 현재는 로그만 출력
          logger.d('Executing cache warming for: ${task.url}');

          // 다음 실행 시간 업데이트
          final updatedTask = task.copyWith(
            nextRun: now.add(task.interval),
          );
          _warmingTasks[task.id] = updatedTask;
        } catch (e) {
          logger.w('Failed to warm cache for: ${task.url}', error: e);
        }
      }

      if (tasksToRun.isNotEmpty) {
        await _saveWarmingTasks();
      }
    } catch (e, s) {
      logger.e('Error executing warming tasks', error: e, stackTrace: s);
    }
  }

  /// 이벤트 큐 저장
  Future<void> _saveEventQueue() async {
    try {
      final jsonList = _eventQueue.map((e) => jsonEncode(e.toJson())).toList();
      await _prefs.setStringList(_eventQueueKey, jsonList);
    } catch (e, s) {
      logger.e('Error saving event queue', error: e, stackTrace: s);
    }
  }

  /// 이벤트 큐 로드
  Future<void> _loadEventQueue() async {
    try {
      final jsonList = _prefs.getStringList(_eventQueueKey) ?? [];
      _eventQueue.clear();

      for (final jsonString in jsonList) {
        try {
          final json = jsonDecode(jsonString) as Map<String, dynamic>;
          final event = CacheInvalidationEvent.fromJson(json);
          _eventQueue.add(event);
        } catch (e) {
          logger.w('Invalid event in queue: $jsonString');
        }
      }

      logger.d('Loaded ${_eventQueue.length} events from queue');
    } catch (e, s) {
      logger.e('Error loading event queue', error: e, stackTrace: s);
    }
  }

  /// 태그 매핑 저장
  Future<void> _saveTagMapping() async {
    try {
      final mappingJson = _urlTagMapping.map(
        (url, tags) => MapEntry(url, tags.toList()),
      );
      await _prefs.setString(_tagMappingKey, jsonEncode(mappingJson));
    } catch (e, s) {
      logger.e('Error saving tag mapping', error: e, stackTrace: s);
    }
  }

  /// 태그 매핑 로드
  Future<void> _loadTagMapping() async {
    try {
      final jsonString = _prefs.getString(_tagMappingKey);
      if (jsonString != null) {
        final mappingJson = jsonDecode(jsonString) as Map<String, dynamic>;
        _urlTagMapping.clear();

        for (final entry in mappingJson.entries) {
          _urlTagMapping[entry.key] = Set<String>.from(entry.value as List);
        }
      }

      logger.d('Loaded ${_urlTagMapping.length} tag mappings');
    } catch (e, s) {
      logger.e('Error loading tag mapping', error: e, stackTrace: s);
    }
  }

  /// 워밍 작업 저장
  Future<void> _saveWarmingTasks() async {
    try {
      final tasksJson = _warmingTasks.map(
        (id, task) => MapEntry(id, task.toJson()),
      );
      await _prefs.setString(_warmingTasksKey, jsonEncode(tasksJson));
    } catch (e, s) {
      logger.e('Error saving warming tasks', error: e, stackTrace: s);
    }
  }

  /// 워밍 작업 로드
  Future<void> _loadWarmingTasks() async {
    try {
      final jsonString = _prefs.getString(_warmingTasksKey);
      if (jsonString != null) {
        final tasksJson = jsonDecode(jsonString) as Map<String, dynamic>;
        _warmingTasks.clear();

        for (final entry in tasksJson.entries) {
          try {
            final task = CacheWarmingTask.fromJson(
              entry.value as Map<String, dynamic>,
            );
            _warmingTasks[entry.key] = task;
          } catch (e) {
            logger.w('Invalid warming task: ${entry.key}');
          }
        }
      }

      logger.d('Loaded ${_warmingTasks.length} warming tasks');
    } catch (e, s) {
      logger.e('Error loading warming tasks', error: e, stackTrace: s);
    }
  }

  /// 통계 정보 조회
  Future<Map<String, dynamic>> getInvalidationStats() async {
    try {
      final cacheStats = await _cacheManager.getCacheStats();

      return {
        'eventQueueSize': _eventQueue.length,
        'tagMappingCount': _urlTagMapping.length,
        'warmingTaskCount': _warmingTasks.length,
        'activeWarmingTasks':
            _warmingTasks.values.where((t) => t.isActive).length,
        'cacheStats': cacheStats,
        'predefinedTagsCount': predefinedTags.length,
      };
    } catch (e) {
      return {
        'eventQueueSize': 0,
        'tagMappingCount': 0,
        'warmingTaskCount': 0,
        'activeWarmingTasks': 0,
        'cacheStats': {},
        'predefinedTagsCount': 0,
      };
    }
  }

  /// 서비스 정리
  Future<void> dispose() async {
    try {
      _processingTimer?.cancel();
      _warmingTimer?.cancel();
      _remoteCheckTimer?.cancel();
      await _eventController.close();

      logger.i('CacheInvalidationService disposed');
    } catch (e, s) {
      logger.e('Error disposing CacheInvalidationService',
          error: e, stackTrace: s);
    }
  }
}

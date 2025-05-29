# 캐싱 시스템 빠른 참조

## 주요 클래스 및 메서드

### SimpleCacheManager

```dart
// 초기화
await SimpleCacheManager.instance.init();

// 캐시 저장
await cacheManager.put(url, headers, responseBody, statusCode,
  cacheDuration: Duration(hours: 2),
  isAuthenticated: true);

// 캐시 조회
final cached = await cacheManager.get(url, headers, isAuthenticated: true);

// 캐시 정리
await cacheManager.clearExpired();
await cacheManager.clear();
await cacheManager.clearAuthenticatedCache();

// 패턴별 무효화
await cacheManager.invalidateByPattern(r'/rest/v1/user_profiles');

// 수정 후 무효화
await cacheManager.invalidateForModification(modifiedUrl);

// 통계 조회
final stats = await cacheManager.getCacheStats();
```

### CachingHttpClient

```dart
// 인스턴스 생성
final client = CachingHttpClient();

// GET 요청 (자동 캐싱)
final response = await client.get(url, headers: headers);

// POST 요청 (자동 무효화)
final response = await client.post(url, body: body);

// 캐시 헤더 확인
print('Cache Status: ${response.headers['x-cache']}');
print('Cache Date: ${response.headers['x-cache-date']}');

// 통계 조회
final stats = client.getCacheStats();
```

### CacheInvalidationService

```dart
// 초기화
await CacheInvalidationService.instance.init();

// 패턴별 무효화
await invalidationService.invalidateByPattern(r'/rest/v1/users');

// 태그별 무효화
await invalidationService.invalidateByTags(['user_profiles']);

// URL별 무효화
await invalidationService.invalidateByUrls(['https://api.example.com/data']);

// 이벤트 발생
final event = CacheInvalidationEvent(
  id: 'update_${DateTime.now().millisecondsSinceEpoch}',
  type: InvalidationEventType.dataUpdate,
  source: 'user_service',
  tags: ['user_profiles'],
);
await invalidationService.emitEvent(event);

// 데이터 수정 후 스마트 무효화
await invalidationService.handleDataUpdate(modifiedUrl);
```

### EnhancedNetworkService

```dart
// 초기화
await EnhancedNetworkService.instance.init();

// 네트워크 상태 확인
final isOnline = networkService.isOnline;
final quality = networkService.networkQuality;
final status = networkService.connectivityStatus;

// 상태 변경 구독
networkService.statusStream.listen((status) {
  print('Network changed: ${status.isOnline}');
});

// 오프라인 큐 상태
final queueSize = networkService.offlineQueueSize;
```

## 캐시 정책 설정

### 기본 정책 예제

```dart
// cache_policy.dart에 추가
CacheRule(
  pattern: r'/rest/v1/my_endpoint',
  ttl: Duration(hours: 2),
  priority: CachePriority.medium,
  strategy: CacheStrategy.staleWhileRevalidate,
  requiresAuth: true,
  maxSize: 100 * 1024, // 100KB
),
```

### 캐시 전략

- `cacheFirst`: 캐시 우선 → 네트워크
- `networkFirst`: 네트워크 우선 → 캐시
- `staleWhileRevalidate`: 캐시 반환 + 백그라운드 업데이트
- `cacheOnly`: 캐시만 사용
- `networkOnly`: 네트워크만 사용

### 우선순위

- `CachePriority.critical`: 가장 높음, 절대 삭제하지 않음
- `CachePriority.high`: 높음, 오래 보관
- `CachePriority.medium`: 보통
- `CachePriority.low`: 낮음, 먼저 삭제됨

## 자주 사용되는 패턴

### 조건부 캐싱

```dart
// 인증 상태에 따른 캐싱
final cached = await cacheManager.get(
  url, 
  headers, 
  isAuthenticated: AuthService.instance.isLoggedIn,
);
```

### 캐시 워밍

```dart
// 앱 시작시 중요한 데이터 미리 로딩
final warmingTask = CacheWarmingTask(
  id: 'startup_data',
  urls: [
    '/rest/v1/config',
    '/rest/v1/user/profile',
  ],
  priority: CacheWarmingPriority.high,
  schedule: CacheWarmingSchedule.onAppStart,
);
await CacheInvalidationService.instance.addWarmingTask(warmingTask);
```

### 오프라인 처리

```dart
try {
  final response = await client.get(url);
  return processResponse(response);
} catch (e) {
  if (!networkService.isOnline) {
    // 오프라인 상태에서 캐시된 데이터 사용
    final cached = await cacheManager.get(url, headers);
    if (cached != null) {
      return processResponse(Response(cached.data, cached.statusCode));
    }
    throw OfflineException('No cached data available');
  }
  rethrow;
}
```

### 로그아웃 시 캐시 정리

```dart
Future<void> logout() async {
  // 사용자 관련 데이터 정리
  await AuthService.instance.logout();
  
  // 인증 관련 캐시 모두 삭제
  await SimpleCacheManager.instance.clearAuthenticatedCache();
  
  // 특정 패턴 캐시 추가 삭제
  await CacheInvalidationService.instance.invalidateByTags([
    'user_profiles',
    'user_settings',
    'user_data',
  ]);
}
```

## 디버깅 및 모니터링

### 캐시 상태 검사

```dart
// 개발 모드에서 캐시 상태 로깅
void debugCacheInfo() async {
  final stats = await SimpleCacheManager.instance.getCacheStats();
  print('📊 Cache Stats:');
  print('  Total: ${stats['totalCount']} entries');
  print('  Memory: ${stats['memoryCount']} entries');
  print('  Size: ${(stats['totalSize'] / 1024).toStringAsFixed(1)} KB');
  
  final priorities = stats['priorityCounts'] as Map<String, int>;
  priorities.forEach((priority, count) {
    print('  $priority: $count entries');
  });
}
```

### 성능 측정

```dart
// 캐시 작업 성능 측정
Future<T> measureCacheOperation<T>(
  String operation,
  Future<T> Function() task,
) async {
  final stopwatch = Stopwatch()..start();
  try {
    final result = await task();
    return result;
  } finally {
    stopwatch.stop();
    print('⏱️ $operation: ${stopwatch.elapsedMilliseconds}ms');
  }
}

// 사용 예
final cached = await measureCacheOperation('cache_get', () {
  return cacheManager.get(url, headers);
});
```

### 캐시 히트율 모니터링

```dart
class CacheHitRateMonitor {
  static int _hits = 0;
  static int _misses = 0;
  
  static void recordHit() => _hits++;
  static void recordMiss() => _misses++;
  
  static double get hitRate {
    final total = _hits + _misses;
    return total > 0 ? (_hits / total) * 100 : 0.0;
  }
  
  static void printStats() {
    print('🎯 Cache Hit Rate: ${hitRate.toStringAsFixed(1)}%');
    print('   Hits: $_hits, Misses: $_misses');
  }
}
```

## 일반적인 오류 및 해결

### 캐시가 작동하지 않는 경우

```dart
// 1. URL이 캐시 가능한지 확인
final shouldCache = CachePolicy.shouldCacheUrl(url);
print('Should cache: $shouldCache');

// 2. 캐시 규칙 확인
final rule = CachePolicy.getRuleForUrl(url);
print('Cache rule: $rule');

// 3. 인증 요구사항 확인
final requiresAuth = CachePolicy.requiresAuthForUrl(url);
print('Requires auth: $requiresAuth');
```

### 메모리 부족 문제

```dart
// 1. 만료된 캐시 정리
await SimpleCacheManager.instance.clearExpired();

// 2. 메모리 캐시 크기 확인
final stats = await SimpleCacheManager.instance.getCacheStats();
print('Memory cache: ${stats['memoryCount']} entries');

// 3. 필요시 전체 캐시 정리
if (stats['memoryCount'] > 40) {
  await SimpleCacheManager.instance.clear();
}
```

### 오프라인 모드 문제

```dart
// 1. 네트워크 상태 확인
final networkService = EnhancedNetworkService.instance;
print('Online: ${networkService.isOnline}');
print('Quality: ${networkService.networkQuality}');

// 2. 오프라인 큐 크기 확인
print('Offline queue: ${networkService.offlineQueueSize}');

// 3. 네트워크 연결 복구 대기
await networkService.waitForConnection();
```

## 테스트 유틸리티

### 캐시 테스트 헬퍼

```dart
class CacheTestHelper {
  static Future<void> clearAllCaches() async {
    await SimpleCacheManager.instance.clear();
    await CacheInvalidationService.instance.clearAll();
  }
  
  static Future<void> setupTestCache() async {
    await SimpleCacheManager.instance.init();
    await CacheInvalidationService.instance.init();
  }
  
  static Future<void> addTestData(String url, String data) async {
    await SimpleCacheManager.instance.put(
      url, {}, data, 200,
      cacheDuration: Duration(hours: 1),
    );
  }
}
```

### Mock 네트워크 조건

```dart
// 네트워크 조건 시뮬레이션
final networkService = EnhancedNetworkService.instance;

// 오프라인 모드
networkService.simulateOffline();

// 느린 네트워크
networkService.simulateSlowNetwork();

// 정상 복구
networkService.simulateOnline();
```

---

## 주요 상수

```dart
// 캐시 크기 제한
static const int MAX_MEMORY_CACHE_SIZE = 50;
static const int MAX_PERSISTENT_CACHE_SIZE = 100;
static const int MAX_CACHE_ENTRY_SIZE = 50 * 1024; // 50KB

// 기본 TTL
static const Duration DEFAULT_CACHE_DURATION = Duration(hours: 1);

// 네트워크 타임아웃
static const Duration NETWORK_TIMEOUT = Duration(seconds: 30);
static const Duration SLOW_NETWORK_TIMEOUT = Duration(seconds: 45);
```

## 환경별 설정

```dart
// Development
if (kDebugMode) {
  Logger.level = LogLevel.debug; // 상세 로그
  // 짧은 캐시 TTL for testing
}

// Production
if (kReleaseMode) {
  Logger.level = LogLevel.error; // 에러만 로그
  // 긴 캐시 TTL for performance
}
``` 
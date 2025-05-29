# Picnic App 캐싱 시스템 가이드

## 목차
1. [개요](#개요)
2. [아키텍처](#아키텍처)
3. [설정 및 초기화](#설정-및-초기화)
4. [기본 사용법](#기본-사용법)
5. [캐시 정책 구성](#캐시-정책-구성)
6. [캐시 무효화 전략](#캐시-무효화-전략)
7. [오프라인 지원](#오프라인-지원)
8. [성능 최적화](#성능-최적화)
9. [테스트 가이드](#테스트-가이드)
10. [문제 해결](#문제-해결)
11. [확장 가이드](#확장-가이드)

## 개요

Picnic App의 캐싱 시스템은 네트워크 효율성을 최적화하고 오프라인 경험을 향상시키기 위해 설계된 포괄적인 솔루션입니다. 이 시스템은 다음과 같은 주요 기능을 제공합니다:

### 주요 기능
- **계층적 캐싱**: 메모리 + 영구 저장소 (SharedPreferences, Hive)
- **유연한 캐시 정책**: URL 패턴 기반 캐싱 규칙
- **지능적 무효화**: 이벤트 기반, 태그 기반, 스마트 무효화
- **오프라인 지원**: 네트워크 상태 감지 및 요청 큐잉
- **성능 모니터링**: 캐시 적중률 및 성능 메트릭
- **캐시 워밍**: 예측적 캐시 로딩

### 시스템 구성 요소
- `SimpleCacheManager`: 메인 캐시 관리자
- `CachePolicy`: 캐시 정책 정의
- `CachingHttpClient`: HTTP 클라이언트 캐싱 인터셉터
- `CacheInvalidationService`: 캐시 무효화 관리
- `EnhancedNetworkService`: 네트워크 상태 관리
- `CacheManagementService`: 고급 캐시 관리

## 아키텍처

```
┌─────────────────────────────────────────────────────────────┐
│                    Application Layer                        │
├─────────────────────────────────────────────────────────────┤
│                  CachingHttpClient                         │
│  ┌─────────────────┬─────────────────┬──────────────────┐   │
│  │  Cache Strategy │  Offline Queue  │  Network Status  │   │
│  └─────────────────┴─────────────────┴──────────────────┘   │
├─────────────────────────────────────────────────────────────┤
│                 Cache Management Layer                     │
│  ┌──────────────────┬────────────────┬───────────────────┐  │
│  │  SimpleCacheManager  CachePolicy │ InvalidationService  │  │
│  └──────────────────┴────────────────┴───────────────────┘  │
├─────────────────────────────────────────────────────────────┤
│                    Storage Layer                           │
│  ┌─────────────────┬─────────────────┬──────────────────┐   │
│  │  Memory Cache   │ SharedPreferences│      Hive       │   │
│  │   (Temporary)   │   (Small Data)  │  (Large Data)   │   │
│  └─────────────────┴─────────────────┴──────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### 캐시 계층

1. **메모리 캐시 (L1)**
   - 빠른 액세스를 위한 인메모리 저장
   - LRU 기반 우선순위 관리
   - 최대 50개 항목

2. **영구 캐시 (L2)**
   - SharedPreferences: 작은 데이터 (< 50KB)
   - Hive: 큰 데이터 (> 50KB, 미래 확장용)
   - 최대 100개 항목

## 설정 및 초기화

### 의존성 추가

```yaml
# pubspec.yaml
dependencies:
  shared_preferences: ^2.3.4
  connectivity_plus: ^6.1.1
  crypto: ^3.0.3
  hive_flutter: ^1.1.0 # 선택적 - 대용량 캐시용

dev_dependencies:
  mockito: ^5.4.4
  build_runner: ^2.4.12
```

### 초기화 코드

```dart
// main.dart 또는 app initialization
Future<void> initializeCaching() async {
  // 캐시 관리자 초기화
  await SimpleCacheManager.instance.init();
  
  // 네트워크 서비스 초기화
  await EnhancedNetworkService.instance.init();
  
  // 캐시 무효화 서비스 초기화
  await CacheInvalidationService.instance.init();
  
  // (선택적) Hive 기반 캐시 관리자
  // await CacheManager.instance.init();
}

// 앱 시작시 호출
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await initializeCaching();
  
  runApp(MyApp());
}
```

## 기본 사용법

### HTTP 요청에 캐싱 적용

```dart
import 'package:picnic_lib/core/services/caching_http_client.dart';

// 캐싱이 적용된 HTTP 클라이언트 사용
final client = CachingHttpClient();

// GET 요청 (자동 캐싱)
final response = await client.get(
  'https://api.example.com/users/profile',
  headers: {'Authorization': 'Bearer $token'},
);

// 캐시 상태 확인
final cacheHeaders = response.headers;
print('Cache Status: ${cacheHeaders['x-cache']}'); // hit/miss
print('Cache Date: ${cacheHeaders['x-cache-date']}');
print('Cache Expires: ${cacheHeaders['x-cache-expires']}');
```

### 수동 캐시 관리

```dart
import 'package:picnic_lib/core/services/simple_cache_manager.dart';

final cacheManager = SimpleCacheManager.instance;

// 캐시 조회
final cached = await cacheManager.get(
  'https://api.example.com/data',
  headers,
  isAuthenticated: true,
);

if (cached != null && cached.isValid) {
  print('Using cached data: ${cached.data}');
} else {
  // 네트워크 요청 후 캐시 저장
  final response = await makeNetworkRequest();
  
  await cacheManager.put(
    'https://api.example.com/data',
    headers,
    response.body,
    response.statusCode,
    cacheDuration: Duration(hours: 2),
    isAuthenticated: true,
  );
}
```

## 캐시 정책 구성

### 기본 캐시 정책

캐시 정책은 `cache_policy.dart`에서 URL 패턴 기반으로 정의됩니다:

```dart
// 사용자 프로필 - 높은 우선순위, 6시간 TTL
CacheRule(
  pattern: r'/rest/v1/user_profiles',
  ttl: Duration(hours: 6),
  priority: CachePriority.high,
  strategy: CacheStrategy.staleWhileRevalidate,
  requiresAuth: true,
),

// 설정 데이터 - 매우 높은 우선순위, 24시간 TTL
CacheRule(
  pattern: r'/rest/v1/config',
  ttl: Duration(hours: 24),
  priority: CachePriority.critical,
  strategy: CacheStrategy.cacheFirst,
),
```

### 캐시 전략

1. **cacheFirst**: 캐시 우선, 없으면 네트워크
   - 안정적인 데이터에 적합
   - 예: 설정, 정적 콘텐츠

2. **networkFirst**: 네트워크 우선, 실패하면 캐시
   - 자주 변경되는 데이터에 적합
   - 예: 실시간 데이터, 알림

3. **staleWhileRevalidate**: 캐시 반환 후 백그라운드 업데이트
   - 성능과 신선도의 균형
   - 예: 사용자 프로필, 상품 데이터

4. **cacheOnly**: 캐시만 사용
   - 오프라인 모드에 적합

5. **networkOnly**: 네트워크만 사용
   - 실시간 데이터에 적합

### 커스텀 캐시 정책 추가

```dart
// cache_policy.dart에 새 규칙 추가
CacheRule(
  pattern: r'/rest/v1/my_custom_endpoint',
  ttl: Duration(minutes: 30),
  priority: CachePriority.medium,
  strategy: CacheStrategy.networkFirst,
  requiresAuth: false,
  maxSize: 100 * 1024, // 100KB
),
```

## 캐시 무효화 전략

### 자동 무효화

1. **시간 기반**: TTL 만료시 자동 삭제
2. **수정 후 무효화**: POST/PUT/DELETE 후 관련 캐시 삭제
3. **로그아웃 시**: 인증 관련 캐시 전체 삭제

### 수동 무효화

```dart
import 'package:picnic_lib/core/services/cache_invalidation_service.dart';

final invalidationService = CacheInvalidationService.instance;

// 패턴별 무효화
await invalidationService.invalidateByPattern(r'/rest/v1/user_profiles');

// 태그별 무효화
await invalidationService.invalidateByTags(['user_profiles', 'user_settings']);

// 특정 URL 무효화
await invalidationService.invalidateByUrls(['https://api.example.com/specific']);

// 수정 후 스마트 무효화
await invalidationService.handleDataUpdate('https://api.example.com/users/123');
```

### 이벤트 기반 무효화

```dart
// 무효화 이벤트 발생
final event = CacheInvalidationEvent(
  id: 'user_update_${DateTime.now().millisecondsSinceEpoch}',
  type: InvalidationEventType.dataUpdate,
  source: 'user_service',
  tags: ['user_profiles'],
  priority: 8,
);

await invalidationService.emitEvent(event);

// 이벤트 스트림 구독
invalidationService.eventStream.listen((event) {
  print('Cache invalidation: ${event.type} from ${event.source}');
});
```

## 오프라인 지원

### 네트워크 상태 모니터링

```dart
import 'package:picnic_lib/core/services/enhanced_network_service.dart';

final networkService = EnhancedNetworkService.instance;

// 현재 네트워크 상태 확인
final isOnline = networkService.isOnline;
final quality = networkService.networkQuality;
final connectivity = networkService.connectivityStatus;

// 네트워크 상태 변경 구독
networkService.statusStream.listen((status) {
  print('Network status changed: $status');
  
  if (status.isOnline) {
    // 온라인으로 전환시 오프라인 큐 처리
    print('Back online, processing offline queue...');
  }
});
```

### 오프라인 요청 큐잉

```dart
// 오프라인 상태에서 요청이 자동으로 큐잉됨
final response = await client.post(
  'https://api.example.com/data',
  body: jsonEncode(data),
  headers: {'Content-Type': 'application/json'},
);

// 오프라인 큐 상태 확인
final queueStatus = networkService.offlineQueueStream;
queueStatus.listen((request) {
  print('Offline request queued: ${request.method} ${request.url}');
});
```

### 오프라인 데이터 처리

```dart
// 오프라인 상태에서 캐시된 데이터 사용
if (!networkService.isOnline) {
  final cachedData = await cacheManager.get(url, headers);
  
  if (cachedData != null) {
    // 캐시된 데이터 사용
    return Response(cachedData.data, cachedData.statusCode);
  } else {
    // 오프라인 상태에서 캐시도 없는 경우
    throw NetworkException('No cached data available offline');
  }
}
```

## 성능 최적화

### 캐시 성능 모니터링

```dart
// 캐시 통계 확인
final stats = await cacheManager.getCacheStats();
print('Total cache size: ${stats['totalSize']} bytes');
print('Total entries: ${stats['totalCount']}');
print('Memory cache: ${stats['memoryCount']} entries');
print('Hit rate: ${stats['hitRate']}%');

// 우선순위별 캐시 분포
final priorityCounts = stats['priorityCounts'] as Map<String, int>;
priorityCounts.forEach((priority, count) {
  print('$priority priority: $count entries');
});
```

### 캐시 워밍

```dart
import 'package:picnic_lib/core/services/cache_invalidation_service.dart';

final invalidationService = CacheInvalidationService.instance;

// 캐시 워밍 작업 추가
final warmingTask = CacheWarmingTask(
  id: 'user_data_warming',
  urls: [
    'https://api.example.com/user/profile',
    'https://api.example.com/user/settings',
  ],
  priority: CacheWarmingPriority.high,
  schedule: CacheWarmingSchedule.onAppStart,
);

await invalidationService.addWarmingTask(warmingTask);
```

### 메모리 사용량 최적화

```dart
// 캐시 정리
await cacheManager.clearExpired(); // 만료된 항목만
await cacheManager.clear(); // 전체 캐시

// 인증 관련 캐시만 정리 (로그아웃 시)
await cacheManager.clearAuthenticatedCache();

// 특정 패턴의 캐시 정리
await cacheManager.invalidateByPattern(r'/rest/v1/temp_data');
```

## 테스트 가이드

### 단위 테스트

```dart
// test/cache_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:picnic_lib/core/services/simple_cache_manager.dart';

void main() {
  group('SimpleCacheManager Tests', () {
    late SimpleCacheManager cacheManager;
    
    setUp(() async {
      cacheManager = SimpleCacheManager.instance;
      await cacheManager.init();
    });
    
    tearDown(() async {
      await cacheManager.clear();
    });
    
    test('should cache and retrieve data', () async {
      const url = 'https://api.example.com/test';
      const responseBody = '{"test": "data"}';
      
      // 캐시 저장
      await cacheManager.put(
        url,
        {},
        responseBody,
        200,
        cacheDuration: Duration(hours: 1),
      );
      
      // 캐시 조회
      final cached = await cacheManager.get(url, {});
      
      expect(cached, isNotNull);
      expect(cached!.data, equals(responseBody));
      expect(cached.statusCode, equals(200));
    });
    
    test('should handle cache expiration', () async {
      const url = 'https://api.example.com/test';
      
      // 만료 시간이 짧은 캐시 저장
      await cacheManager.put(
        url,
        {},
        'test',
        200,
        cacheDuration: Duration(milliseconds: 100),
      );
      
      // 만료 대기
      await Future.delayed(Duration(milliseconds: 200));
      
      // 만료된 캐시는 null 반환
      final cached = await cacheManager.get(url, {});
      expect(cached, isNull);
    });
  });
}
```

### 통합 테스트

```dart
// integration_test/cache_integration_test.dart
import 'package:integration_test/integration_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/services/caching_http_client.dart';
import 'package:picnic_lib/core/services/enhanced_network_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  group('Cache Integration Tests', () {
    late CachingHttpClient client;
    late EnhancedNetworkService networkService;
    
    setUpAll(() async {
      client = CachingHttpClient();
      networkService = EnhancedNetworkService.instance;
      await networkService.init();
    });
    
    testWidgets('should handle offline mode', (tester) async {
      const url = 'https://httpbin.org/json';
      
      // 온라인 상태에서 데이터 캐시
      final response1 = await client.get(url);
      expect(response1.statusCode, equals(200));
      
      // 오프라인 모드 시뮬레이션
      networkService.simulateOffline();
      
      // 캐시된 데이터 반환 확인
      final response2 = await client.get(url);
      expect(response2.statusCode, equals(200));
      expect(response2.headers['x-cache'], equals('hit'));
      
      // 온라인 복구
      networkService.simulateOnline();
    });
  });
}
```

### 네트워크 조건 테스트

```dart
test('should handle slow network', () async {
  networkService.simulateSlowNetwork();
  
  final stopwatch = Stopwatch()..start();
  final response = await client.get('https://httpbin.org/delay/1');
  stopwatch.stop();
  
  // 느린 네트워크에서 타임아웃 조정 확인
  expect(stopwatch.elapsedMilliseconds, greaterThan(1000));
  expect(response.statusCode, equals(200));
});
```

## 문제 해결

### 일반적인 문제

#### 1. 캐시가 작동하지 않음

**증상**: 동일한 요청이 항상 네트워크를 통해 실행됨

**해결 방법**:
```dart
// 캐시 정책 확인
final rule = CachePolicy.getRuleForUrl(url);
print('Cache rule: $rule');

// URL이 캐시 가능한지 확인
final shouldCache = CachePolicy.shouldCacheUrl(url);
print('Should cache: $shouldCache');

// 캐시 통계 확인
final stats = await cacheManager.getCacheStats();
print('Cache stats: $stats');
```

#### 2. 메모리 사용량 과다

**해결 방법**:
```dart
// 캐시 크기 제한 확인
await cacheManager.clearExpired();

// 메모리 캐시 크기 조정 (코드 수정)
static const int _maxMemoryCacheSize = 30; // 기본 50에서 줄임
```

#### 3. 오프라인 모드에서 오류

**해결 방법**:
```dart
// 네트워크 상태 확인
final networkService = EnhancedNetworkService.instance;
print('Is online: ${networkService.isOnline}');
print('Connectivity: ${networkService.connectivityStatus}');

// 오프라인 큐 상태 확인
final queueSize = networkService.offlineQueueSize;
print('Offline queue size: $queueSize');
```

### 디버깅 도구

#### 로그 활성화

```dart
// main.dart
import 'package:picnic_lib/core/utils/logger.dart';

void main() {
  // 디버그 모드에서 상세 로그 활성화
  Logger.level = LogLevel.debug;
  
  runApp(MyApp());
}
```

#### 캐시 상태 검사

```dart
// 개발자 도구용 헬퍼 함수
Future<void> debugCacheState() async {
  final cacheManager = SimpleCacheManager.instance;
  final stats = await cacheManager.getCacheStats();
  
  print('=== Cache Debug Info ===');
  print('Total entries: ${stats['totalCount']}');
  print('Memory entries: ${stats['memoryCount']}');
  print('Total size: ${stats['totalSize']} bytes');
  print('Priority distribution: ${stats['priorityCounts']}');
  
  // 개별 캐시 항목 검사 (개발 모드에서만)
  if (kDebugMode) {
    // 여기에 더 상세한 디버그 로직 추가
  }
}
```

### 성능 프로파일링

```dart
import 'dart:developer' as developer;

Future<T> profileCacheOperation<T>(
  String operation,
  Future<T> Function() task,
) async {
  final stopwatch = Stopwatch()..start();
  
  developer.Timeline.startSync(operation);
  try {
    final result = await task();
    return result;
  } finally {
    developer.Timeline.finishSync();
    stopwatch.stop();
    
    logger.d(
      'Cache operation "$operation" took ${stopwatch.elapsedMilliseconds}ms'
    );
  }
}

// 사용 예
final result = await profileCacheOperation('cache_get', () async {
  return await cacheManager.get(url, headers);
});
```

## 확장 가이드

### 새로운 캐시 전략 추가

1. **CacheStrategy 열거형에 새 전략 추가**:
```dart
// cache_policy.dart
enum CacheStrategy {
  cacheFirst,
  networkFirst,
  cacheOnly,
  networkOnly,
  staleWhileRevalidate,
  adaptiveStrategy, // 새 전략 추가
}
```

2. **CachingHttpClient에 전략 핸들러 구현**:
```dart
// caching_http_client.dart
Future<http.Response> _handleAdaptiveStrategy(
  String url,
  Future<http.Response> Function() networkCall,
  CacheEntry? cached,
) async {
  // 네트워크 품질에 따른 적응형 전략 구현
  final quality = _networkService.networkQuality;
  
  if (quality == NetworkQuality.excellent && cached == null) {
    return _handleNetworkFirst(url, networkCall, cached);
  } else if (quality == NetworkQuality.poor && cached != null) {
    return _handleCacheFirst(url, networkCall, cached);
  }
  
  return _handleStaleWhileRevalidate(url, networkCall, cached);
}
```

### 새로운 저장소 백엔드 추가

```dart
// cache_backends/secure_cache_backend.dart
abstract class CacheBackend {
  Future<void> init();
  Future<String?> get(String key);
  Future<void> put(String key, String value);
  Future<void> remove(String key);
  Future<void> clear();
}

class SecureCacheBackend implements CacheBackend {
  // Flutter Secure Storage 기반 구현
  // 민감한 데이터를 위한 암호화된 저장소
  
  @override
  Future<void> init() async {
    // 초기화 로직
  }
  
  // 구현...
}
```

### 캐시 미들웨어 시스템

```dart
// cache_middleware.dart
abstract class CacheMiddleware {
  Future<CacheEntry?> beforeGet(String url, Map<String, String> headers);
  Future<void> afterPut(String url, CacheEntry entry);
  Future<bool> shouldInvalidate(String url, InvalidationEvent event);
}

class CompressionMiddleware implements CacheMiddleware {
  @override
  Future<void> afterPut(String url, CacheEntry entry) async {
    // 대용량 데이터 압축
    if (entry.data.length > 10 * 1024) {
      // 압축 로직 구현
    }
  }
  
  // 다른 메서드 구현...
}

// 미들웨어 등록
cacheManager.addMiddleware(CompressionMiddleware());
cacheManager.addMiddleware(EncryptionMiddleware());
```

### 캐시 메트릭 수집

```dart
// cache_metrics.dart
class CacheMetrics {
  static final Map<String, int> _hitCounts = {};
  static final Map<String, int> _missCounts = {};
  static final Map<String, List<int>> _responseTimes = {};
  
  static void recordHit(String url, int responseTimeMs) {
    _hitCounts[url] = (_hitCounts[url] ?? 0) + 1;
    _recordResponseTime(url, responseTimeMs);
  }
  
  static void recordMiss(String url, int responseTimeMs) {
    _missCounts[url] = (_missCounts[url] ?? 0) + 1;
    _recordResponseTime(url, responseTimeMs);
  }
  
  static Map<String, dynamic> getMetrics() {
    return {
      'hitCounts': Map.from(_hitCounts),
      'missCounts': Map.from(_missCounts),
      'responseTimes': Map.from(_responseTimes),
      'hitRate': _calculateHitRate(),
    };
  }
  
  static double _calculateHitRate() {
    final totalHits = _hitCounts.values.fold(0, (a, b) => a + b);
    final totalMisses = _missCounts.values.fold(0, (a, b) => a + b);
    final total = totalHits + totalMisses;
    
    return total > 0 ? (totalHits / total) * 100 : 0.0;
  }
}
```

---

## 라이센스 및 기여

이 캐싱 시스템은 Picnic App의 일부로 개발되었습니다. 버그 리포트나 기능 제안은 팀 내부 채널을 통해 제출해 주세요.

### 변경 이력

- **v1.0.0**: 초기 구현 완료
  - SimpleCacheManager 구현
  - CachePolicy 시스템
  - 기본 오프라인 지원

- **v1.1.0**: 고급 기능 추가
  - CacheInvalidationService
  - EnhancedNetworkService
  - 캐시 워밍 지원

- **v1.2.0**: 성능 최적화
  - 메모리 캐시 최적화
  - 백그라운드 동기화
  - 고급 캐시 전략

---

**마지막 업데이트**: 2024년 12월
**문서 버전**: 1.2.0 
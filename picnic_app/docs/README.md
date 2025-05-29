# Picnic App 캐싱 시스템 문서

이 디렉토리는 Picnic App의 포괄적인 캐싱 시스템에 대한 문서를 포함합니다.

## 📚 문서 목록

### 1. [캐싱 시스템 가이드](./caching_system_guide.md)
캐싱 시스템의 전체적인 아키텍처, 설정 방법, 사용법에 대한 종합적인 가이드입니다.

**포함 내용:**
- 시스템 개요 및 아키텍처
- 설정 및 초기화 방법
- 기본 사용법 및 고급 기능
- 캐시 정책 구성
- 캐시 무효화 전략
- 오프라인 지원
- 성능 최적화
- 테스트 가이드
- 문제 해결
- 확장 가이드

### 2. [빠른 참조 가이드](./cache_quick_reference.md)
개발자를 위한 간결한 참조 문서로, 자주 사용되는 API와 코드 예제를 제공합니다.

**포함 내용:**
- 주요 클래스 및 메서드 참조
- 캐시 정책 설정 예제
- 자주 사용되는 패턴
- 디버깅 및 모니터링 도구
- 일반적인 오류 및 해결 방법
- 테스트 유틸리티

## 🏗️ 캐싱 시스템 구조

```
캐싱 시스템
├── Application Layer
│   └── CachingHttpClient (HTTP 요청 캐싱)
├── Cache Management Layer
│   ├── SimpleCacheManager (메인 캐시 관리)
│   ├── CachePolicy (캐시 정책)
│   └── CacheInvalidationService (캐시 무효화)
├── Network Layer
│   └── EnhancedNetworkService (네트워크 상태 관리)
└── Storage Layer
    ├── Memory Cache (L1)
    ├── SharedPreferences (L2 - 작은 데이터)
    └── Hive (L2 - 큰 데이터, 미래 확장)
```

## 🚀 빠른 시작

### 1. 초기화

```dart
// main.dart
Future<void> initializeCaching() async {
  await SimpleCacheManager.instance.init();
  await EnhancedNetworkService.instance.init();
  await CacheInvalidationService.instance.init();
}
```

### 2. 기본 사용법

```dart
// HTTP 요청에 캐싱 적용
final client = CachingHttpClient();
final response = await client.get('https://api.example.com/data');

// 캐시 상태 확인
print('Cache Status: ${response.headers['x-cache']}');
```

### 3. 수동 캐시 관리

```dart
final cacheManager = SimpleCacheManager.instance;

// 캐시 저장
await cacheManager.put(url, headers, responseBody, 200);

// 캐시 조회
final cached = await cacheManager.get(url, headers);
```

## 📋 주요 기능

### ✅ 계층적 캐싱
- 메모리 캐시 (L1): 빠른 액세스
- 영구 캐시 (L2): SharedPreferences & Hive

### ✅ 유연한 캐시 정책
- URL 패턴 기반 규칙
- 5가지 캐시 전략 (cacheFirst, networkFirst, staleWhileRevalidate 등)
- 우선순위 기반 관리

### ✅ 지능적 무효화
- 시간 기반 (TTL)
- 이벤트 기반
- 태그 기반
- 스마트 무효화 (관련 데이터 자동 감지)

### ✅ 오프라인 지원
- 네트워크 상태 실시간 모니터링
- 오프라인 요청 큐잉
- 자동 동기화

### ✅ 성능 최적화
- 캐시 워밍
- 성능 메트릭 수집
- 메모리 사용량 최적화

## 🔧 개발 도구

### 디버깅
```dart
// 캐시 상태 검사
final stats = await SimpleCacheManager.instance.getCacheStats();
print('Cache entries: ${stats['totalCount']}');

// 네트워크 상태 확인
final networkService = EnhancedNetworkService.instance;
print('Network status: ${networkService.isOnline}');
```

### 테스트
```dart
// 테스트 환경 설정
await CacheTestHelper.setupTestCache();

// 네트워크 조건 시뮬레이션
networkService.simulateOffline();
```

## 📊 성능 지표

캐싱 시스템은 다음과 같은 성능 지표를 제공합니다:

- **캐시 적중률**: 네트워크 요청 절약 정도
- **응답 시간**: 캐시된 데이터 반환 속도
- **메모리 사용량**: 캐시가 사용하는 메모리
- **저장소 사용량**: 영구 캐시 크기

## 🛠️ 설정 옵션

### 캐시 크기 제한
- 메모리 캐시: 최대 50개 항목
- 영구 캐시: 최대 100개 항목
- 항목별 최대 크기: 50KB

### TTL (Time To Live)
- 기본값: 1시간
- 설정 데이터: 24시간
- 사용자 프로필: 6시간
- 팝업 데이터: 30분

## 🔍 모니터링 및 분석

### 실시간 모니터링
- 캐시 적중률 추적
- 네트워크 상태 변화 감지
- 오프라인 큐 상태 모니터링

### 성능 분석
- 응답 시간 측정
- 메모리 사용량 추적
- 캐시 효율성 분석

## 🚨 문제 해결

일반적인 문제와 해결 방법:

1. **캐시가 작동하지 않음**: URL 패턴 및 정책 확인
2. **메모리 사용량 과다**: 캐시 크기 제한 조정
3. **오프라인 모드 오류**: 네트워크 상태 및 캐시 유효성 확인

자세한 문제 해결 방법은 [캐싱 시스템 가이드](./caching_system_guide.md#문제-해결)를 참조하세요.

## 📈 확장 가능성

캐싱 시스템은 다음과 같은 확장을 지원합니다:

- **새로운 캐시 전략 추가**
- **커스텀 저장소 백엔드**
- **캐시 미들웨어 시스템**
- **고급 메트릭 수집**

확장 방법은 [캐싱 시스템 가이드](./caching_system_guide.md#확장-가이드)를 참조하세요.

## 📄 라이센스

이 캐싱 시스템과 문서는 Picnic App 프로젝트의 일부입니다.

## 📞 지원

문제나 제안사항이 있으시면 팀 내부 채널을 통해 연락주세요.

---

**마지막 업데이트**: 2024년 12월
**문서 버전**: 1.2.0 
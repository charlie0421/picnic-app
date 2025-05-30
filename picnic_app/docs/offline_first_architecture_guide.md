# Offline-First Architecture Guide

## 개요

Picnic 앱은 사용자에게 끊김 없는 경험을 제공하기 위해 오프라인 우선(Offline-First) 아키텍처를 구현합니다. 이 문서는 오프라인 기능의 아키텍처, 구현 상세, 사용 가이드라인, 그리고 문제 해결 방법을 다룹니다.

## 목차

1. [아키텍처 개요](#아키텍처-개요)
2. [핵심 컴포넌트](#핵심-컴포넌트)
3. [데이터베이스 레이어](#데이터베이스-레이어)
4. [동기화 로직](#동기화-로직)
5. [재시도 메커니즘](#재시도-메커니즘)
6. [충돌 해결 전략](#충돌-해결-전략)
7. [네트워크 상태 관리](#네트워크-상태-관리)
8. [사용 가이드라인](#사용-가이드라인)
9. [테스트 및 디버깅](#테스트-및-디버깅)
10. [문제 해결](#문제-해결)

## 아키텍처 개요

### 설계 원칙

1. **로컬 우선**: 모든 데이터 액세스는 로컬 데이터베이스를 우선으로 합니다.
2. **투명한 동기화**: 네트워크 연결 복구 시 자동으로 데이터를 동기화합니다.
3. **사용자 경험**: 네트워크 상태와 무관하게 일관된 사용자 경험을 제공합니다.
4. **데이터 무결성**: 충돌 해결과 트랜잭션을 통해 데이터 일관성을 보장합니다.

### 아키텍처 다이어그램

```
┌─────────────────────────────────────────────────────┐
│                 UI Layer                            │
│  (Screens, Widgets, Providers)                     │
└──────────────────┬──────────────────────────────────┘
                   │
┌─────────────────────────────────────────────────────┐
│               Repository Layer                      │
│  - PopupRepository                                  │
│  - VoteRepository                                   │
│  - UserProfileRepository                            │
│  └─ OfflineFirstRepository (Base Class)            │
└──────────────────┬──────────────────────────────────┘
                   │
┌─────────────────────────────────────────────────────┐
│             Service Layer                           │
│  ┌───────────────┬─────────────────┬───────────────┐ │
│  │ OfflineSync   │ ConflictResolut │ EnhancedRetry │ │
│  │ Service       │ ionService      │ Service       │ │
│  └───────────────┼─────────────────┼───────────────┘ │
│  ┌───────────────┴─────────────────┴───────────────┐ │
│  │         OfflineDatabaseService                  │ │
│  └─────────────────────────────────────────────────┘ │
└──────────────────┬──────────────────────────────────┘
                   │
┌─────────────────────────────────────────────────────┐
│             Storage Layer                           │
│  ┌─────────────────┐    ┌─────────────────────────┐ │
│  │ Local Database  │    │    Remote Backend       │ │
│  │   (SQLite)      │    │     (Supabase)          │ │
│  └─────────────────┘    └─────────────────────────┘ │
└─────────────────────────────────────────────────────┘
```

## 핵심 컴포넌트

### 1. OfflineDatabaseService

**위치**: `picnic_lib/lib/core/services/offline_database_service.dart`

SQLite 기반의 로컬 데이터베이스 서비스로 오프라인 데이터 저장소의 핵심입니다.

**주요 기능**:
- SQLite 데이터베이스 관리
- 테이블 스키마 생성 및 버전 관리
- CRUD 작업 및 트랜잭션 지원
- 동기화 큐 관리
- 더티 플래그 추적

**지원 테이블**:
- `user_profiles`: 사용자 프로필 데이터
- `votes`: 투표 데이터
- `user_votes`: 사용자 투표 기록
- `galleries`: 갤러리 데이터
- `sync_queue`: 동기화 대기 큐
- `persistent_retries`: 지속적 재시도 큐
- `conflict_reviews`: 수동 해결 대기 충돌
- `conflict_history`: 충돌 해결 기록

### 2. OfflineSyncService

**위치**: `picnic_lib/lib/core/services/offline_sync_service.dart`

로컬과 원격 데이터 간의 양방향 동기화를 관리합니다.

**주요 기능**:
- 주기적 동기화 (5분 간격)
- 네트워크 복구 시 자동 동기화
- 로컬 변경사항 업로드
- 원격 변경사항 다운로드
- 충돌 감지 및 해결

### 3. ConflictResolutionService

**위치**: `picnic_lib/lib/core/services/conflict_resolution_service.dart`

데이터 동기화 중 발생하는 충돌을 감지하고 해결합니다.

**해결 전략**:
- `localWins`: 로컬 데이터 우선
- `remoteWins`: 원격 데이터 우선
- `lastWriteWins`: 마지막 수정 시간 기준
- `merge`: 자동 병합 (숫자, 문자열, 리스트)
- `manualReview`: 수동 해결 필요

### 4. EnhancedRetryService

**위치**: `picnic_lib/lib/core/services/enhanced_retry_service.dart`

실패한 네트워크 요청과 동기화 작업에 대한 강력한 재시도 로직을 제공합니다.

**재시도 전략**:
- **Exponential Backoff**: 지수적 지연 증가
- **Linear Backoff**: 선형 지연 증가
- **Fixed Delay**: 고정 지연
- **Random Jitter**: 랜덤 변동

**우선순위 시스템**:
- `Critical`: 즉시 처리
- `High`: 높은 우선순위
- `Normal`: 일반 우선순위
- `Low`: 낮은 우선순위

### 5. NetworkStateManager

**위치**: `picnic_lib/lib/core/services/network_state_manager.dart`

네트워크 상태를 실시간으로 모니터링하고 관리합니다.

**모니터링 기능**:
- 네트워크 연결 상태 감지
- 인터넷 접근성 확인
- 지연 시간 측정
- 네트워크 품질 평가
- 강제 오프라인 모드

## 데이터베이스 레이어

### 스키마 구조

#### 메인 데이터 테이블

```sql
-- 사용자 프로필
CREATE TABLE user_profiles (
  id TEXT PRIMARY KEY,
  nickname TEXT,
  avatar_url TEXT,
  bio TEXT,
  star_candy INTEGER DEFAULT 0,
  created_at TEXT,
  updated_at TEXT,
  last_sync TEXT,
  is_dirty INTEGER DEFAULT 0
);

-- 투표 데이터
CREATE TABLE votes (
  id INTEGER PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  start_date TEXT,
  end_date TEXT,
  status TEXT,
  category TEXT,
  artist_id INTEGER,
  image_url TEXT,
  vote_count INTEGER DEFAULT 0,
  created_at TEXT,
  updated_at TEXT,
  last_sync TEXT,
  is_dirty INTEGER DEFAULT 0
);
```

#### 시스템 테이블

```sql
-- 동기화 큐
CREATE TABLE sync_queue (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  table_name TEXT NOT NULL,
  record_id TEXT NOT NULL,
  operation TEXT NOT NULL, -- INSERT, UPDATE, DELETE
  data TEXT, -- JSON data
  created_at TEXT,
  retry_count INTEGER DEFAULT 0,
  last_retry TEXT
);

-- 충돌 리뷰
CREATE TABLE conflict_reviews (
  id TEXT PRIMARY KEY,
  table_name TEXT NOT NULL,
  record_id TEXT NOT NULL,
  field_name TEXT NOT NULL,
  local_value TEXT NOT NULL, -- JSON encoded
  remote_value TEXT NOT NULL, -- JSON encoded
  status TEXT DEFAULT 'pending',
  created_at TEXT NOT NULL
);
```

### 더티 플래그 시스템

모든 메인 데이터 테이블에는 `is_dirty` 플래그가 있어 로컬 변경사항을 추적합니다:

- `0`: 동기화됨 (clean)
- `1`: 로컬 변경사항 있음 (dirty)

```dart
// 데이터 변경 시 더티 플래그 설정
await _localDb.markAsDirty('user_profiles', userId);

// 동기화 완료 시 플래그 해제
await _localDb.markAsClean('user_profiles', userId);
```

### 인덱스 최적화

성능 향상을 위한 인덱스:

```sql
CREATE INDEX idx_votes_status ON votes(status);
CREATE INDEX idx_votes_category ON votes(category);
CREATE INDEX idx_user_votes_user_id ON user_votes(user_id);
CREATE INDEX idx_sync_queue_table ON sync_queue(table_name);
CREATE INDEX idx_conflict_reviews_status ON conflict_reviews(status);
```

## 동기화 로직

### 동기화 플로우

1. **트리거 조건**:
   - 네트워크 연결 복구
   - 주기적 타이머 (5분)
   - 수동 동기화 요청

2. **업로드 단계**:
   - 동기화 큐에서 대기 중인 작업 조회
   - EnhancedRetryService를 통한 재시도 스케줄링
   - 성공 시 큐에서 제거 및 더티 플래그 해제

3. **다운로드 단계**:
   - 각 테이블의 마지막 동기화 시간 확인
   - 원격에서 변경된 데이터 조회
   - 충돌 감지 및 해결
   - 로컬 데이터베이스 업데이트

### 동기화 구현 예제

```dart
// 특정 테이블 강제 동기화
await _syncService.forceSyncTable('user_profiles');

// 전체 동기화
await _syncService.forcSync();

// 동기화 상태 모니터링
_syncService.syncStatusStream.listen((status) {
  switch (status) {
    case SyncStatus.syncing:
      print('동기화 진행 중...');
      break;
    case SyncStatus.completed:
      print('동기화 완료');
      break;
    case SyncStatus.failed:
      print('동기화 실패');
      break;
  }
});
```

### 동기화 우선순위

테이블별 동기화 우선순위:

- **High**: `user_profiles`, `user_votes`
- **Normal**: `votes`, `galleries`
- **Low**: 기타 테이블

## 재시도 메커니즘

### 재시도 전략

#### 1. Exponential Backoff

지수적으로 지연 시간을 증가시켜 서버 과부하를 방지합니다.

```dart
await _retryService.scheduleRetry(
  operationId: 'sync_user_profile_123',
  operation: () => _syncUserProfile('123'),
  strategy: RetryStrategy.exponentialBackoff,
  maxAttempts: 5,
);
```

#### 2. Circuit Breaker Pattern

연속적인 실패 시 일정 시간 동안 요청을 중단합니다.

- **실패 임계값**: 10회 연속 실패
- **리셋 타임아웃**: 5분
- **상태**: Closed → Open → Half-Open

### 우선순위 큐

```dart
enum RetryPriority {
  critical,  // 즉시 처리
  high,      // 1초 이내
  normal,    // 5초 이내
  low,       // 30초 이내
}
```

### 지속적 재시도

앱 재시작에도 유지되는 재시도 작업:

```dart
await _retryService.scheduleRetry(
  operationId: 'critical_sync_operation',
  operation: () => _criticalSyncOperation(),
  persistentRetry: true, // 앱 재시작 후에도 유지
  priority: RetryPriority.critical,
);
```

## 충돌 해결 전략

### 충돌 감지

필드별 값 비교를 통해 충돌을 감지합니다:

```dart
final conflicts = _detectConflicts(localData, remoteData);
```

### 충돌 타입

- **TextConflict**: 문자열 필드 충돌
- **NumericConflict**: 숫자 필드 충돌
- **TimestampConflict**: 시간 필드 충돌
- **NullValueConflict**: null 값 충돌
- **DataTypeConflict**: 데이터 타입 충돌

### 해결 전략 구성

```dart
// 테이블별 기본 전략 설정
_conflictService.setTableStrategy(
  'user_profiles', 
  ConflictResolutionStrategy.lastWriteWins
);

// 필드별 특별 전략 설정
_conflictService.setFieldStrategy(
  'user_profiles', 
  'star_candy', 
  ConflictResolutionStrategy.merge
);

_conflictService.setFieldStrategy(
  'user_profiles', 
  'nickname', 
  ConflictResolutionStrategy.manualReview
);
```

### 자동 병합 로직

#### 숫자 병합 (합계)
```dart
if (localValue is num && remoteValue is num) {
  return localValue + remoteValue;
}
```

#### 문자열 병합 (연결)
```dart
if (localValue is String && remoteValue is String) {
  return '$localValue | $remoteValue';
}
```

#### 리스트 병합 (유니온)
```dart
if (localValue is List && remoteValue is List) {
  final merged = List.from(localValue);
  for (final item in remoteValue) {
    if (!merged.contains(item)) {
      merged.add(item);
    }
  }
  return merged;
}
```

### 수동 충돌 해결

사용자 개입이 필요한 충돌은 UI 대화상자를 통해 해결됩니다:

```dart
// 대기 중인 충돌 조회
final pendingConflicts = _conflictService.getPendingManualReviews();

// 충돌 해결 대화상자 표시
await ConflictResolutionDialog.show(
  context,
  pendingConflicts.first,
  onResolved: () => print('충돌 해결 완료'),
);
```

## 네트워크 상태 관리

### DetailedNetworkState

네트워크 상태에 대한 포괄적인 정보를 제공합니다:

```dart
class DetailedNetworkState {
  final bool isConnected;
  final bool hasInternetAccess;
  final bool isOfflineModeForced;
  final int? latencyMs;
  final NetworkQuality quality;
  final DateTime lastChecked;
}
```

### 네트워크 품질 분류

- **Excellent**: < 100ms (최상급 연결)
- **Good**: 100-300ms (안정적 연결)
- **Fair**: 300-1000ms (보통 연결)
- **Poor**: > 1000ms (느린 연결)
- **None**: 연결 없음

### 실시간 모니터링

```dart
// 네트워크 상태 스트림 구독
NetworkStateManager.instance.detailedNetworkStream.listen((state) {
  if (state.hasInternetAccess) {
    // 동기화 트리거
    _syncService.forcSync();
  }
});
```

### 강제 오프라인 모드

사용자가 수동으로 오프라인 모드를 활성화할 수 있습니다:

```dart
// 오프라인 모드 활성화
await NetworkStateManager.instance.setOfflineMode(true);

// 오프라인 모드 비활성화
await NetworkStateManager.instance.setOfflineMode(false);
```

## 사용 가이드라인

### Repository 패턴 구현

새로운 Repository를 만들 때는 `OfflineFirstRepository`를 상속받습니다:

```dart
class MyDataRepository extends OfflineFirstRepository<MyData> {
  MyDataRepository() : super(
    tableName: 'my_data_table',
    fromJson: MyData.fromJson,
    toJson: (data) => data.toJson(),
    supabaseTable: 'my_data',
  );

  // 특별한 비즈니스 로직 추가
  Future<List<MyData>> getActiveData() async {
    return getLocalData(where: 'status = ?', whereArgs: ['active']);
  }
}
```

### 데이터 변경 시 주의사항

1. **트랜잭션 사용**: 여러 테이블을 동시에 변경할 때는 트랜잭션을 사용합니다.

```dart
await _localDb.transaction((txn) async {
  await txn.insert('table1', data1);
  await txn.insert('table2', data2);
});
```

2. **더티 플래그 관리**: 데이터 변경 후 반드시 더티 플래그를 설정합니다.

```dart
await _localDb.markAsDirty('user_profiles', userId);
```

3. **동기화 큐 등록**: 원격 동기화가 필요한 변경사항은 큐에 등록합니다.

```dart
await _localDb.addToSyncQueue('user_profiles', userId, 'UPDATE', userData);
```

### 에러 처리

네트워크 오류에 대한 우아한 처리:

```dart
try {
  final data = await repository.getData();
  return data;
} catch (e) {
  if (e is NetworkException) {
    // 로컬 데이터로 폴백
    return await repository.getLocalData();
  }
  rethrow;
}
```

### UI에서의 오프라인 상태 표시

```dart
// 오프라인 모드 인디케이터 위젯 사용
class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const OfflineModeIndicator(), // 네트워크 상태 표시
          Expanded(child: MyContent()),
        ],
      ),
    );
  }
}
```

## 테스트 및 디버깅

### OfflineTestScreen

개발 및 테스트를 위한 전용 화면이 제공됩니다:

**위치**: `picnic_lib/lib/presentation/screens/offline_test_screen.dart`

**기능**:
- 시스템 상태 모니터링
- 데이터베이스 작업 테스트
- 재시도 메커니즘 테스트
- 충돌 해결 테스트
- 수동 충돌 해결 테스트
- 네트워크 모드 토글
- 데이터베이스 초기화

### 테스트 시나리오

#### 1. 오프라인 데이터 작업 테스트

```dart
// 오프라인 모드 활성화
await NetworkStateManager.instance.setOfflineMode(true);

// 데이터 생성/수정
await repository.createData(newData);
await repository.updateData(existingData);

// 온라인 모드 복구
await NetworkStateManager.instance.setOfflineMode(false);

// 동기화 확인
await Future.delayed(Duration(seconds: 10));
final syncedData = await repository.getRemoteData();
```

#### 2. 충돌 시나리오 테스트

```dart
// 로컬에서 데이터 수정
await repository.updateLocalData(userId, {'nickname': 'LocalName'});

// 원격에서 동일 데이터 수정 시뮬레이션
await supabase.from('user_profiles')
  .update({'nickname': 'RemoteName'})
  .eq('id', userId);

// 동기화 시 충돌 발생 확인
await _syncService.forcSync();
```

### 로깅 및 모니터링

```dart
// 로그 레벨 설정
Logger.level = Level.debug;

// 동기화 상태 로깅
_syncService.syncStatusStream.listen((status) {
  logger.i('Sync status changed: $status');
});

// 충돌 해결 로깅
_conflictService.getPendingManualReviews().forEach((conflict) {
  logger.w('Pending conflict: ${conflict.tableName}.${conflict.recordId}');
});
```

## 문제 해결

### 일반적인 문제와 해결방법

#### 1. 동기화가 작동하지 않는 경우

**증상**: 네트워크가 복구되었지만 동기화가 시작되지 않음

**확인 사항**:
- 네트워크 상태 확인: `NetworkStateManager.instance.detailedNetworkStream.value`
- 동기화 서비스 초기화 확인: `_syncService.initialize()` 호출 여부
- 동기화 큐 상태 확인: `await _localDb.getSyncQueue()`

**해결방법**:
```dart
// 수동 동기화 트리거
await _syncService.forcSync();

// 네트워크 서비스 재시작
await NetworkStateManager.instance.initialize();
```

#### 2. 충돌이 해결되지 않는 경우

**증상**: 충돌이 감지되었지만 자동 해결되지 않음

**확인 사항**:
- 충돌 해결 전략 확인
- 수동 해결 대기 목록 확인

**해결방법**:
```dart
// 대기 중인 충돌 확인
final pending = _conflictService.getPendingManualReviews();

// 수동 해결 또는 전략 변경
_conflictService.setFieldStrategy(
  tableName, 
  fieldName, 
  ConflictResolutionStrategy.remoteWins
);
```

#### 3. 데이터베이스 성능 문제

**증상**: 앱이 느려지거나 데이터베이스 작업이 오래 걸림

**확인 사항**:
- 데이터베이스 크기 확인
- 인덱스 상태 확인
- 동기화 큐 크기 확인

**해결방법**:
```dart
// 오래된 충돌 기록 정리
await _localDb.rawQuery(
  'DELETE FROM conflict_history WHERE resolved_at < ?',
  [DateTime.now().subtract(Duration(days: 30)).toIso8601String()]
);

// 동기화 큐 정리
await _localDb.rawQuery('DELETE FROM sync_queue WHERE retry_count > 10');
```

### 디버깅 도구

#### 1. 데이터베이스 상태 확인

```dart
// 테이블별 레코드 수 확인
final stats = await _getDbStats();
print('Database stats: $stats');

// 더티 레코드 확인
final dirtyRecords = await _localDb.getDirtyRecords('user_profiles');
print('Dirty records: ${dirtyRecords.length}');
```

#### 2. 동기화 상태 진단

```dart
// 동기화 큐 상태
final queueCount = await _syncService.getPendingSyncCount();
print('Pending sync items: $queueCount');

// 재시도 서비스 상태
final retryStatus = _retryService.getQueueStatus();
print('Retry queue status: $retryStatus');
```

#### 3. 네트워크 진단

```dart
// 네트워크 상태 상세 정보
final networkState = NetworkStateManager.instance.detailedNetworkStream.value;
print('Network state: ${networkState?.toString()}');

// 연결성 테스트
await NetworkStateManager.instance.checkInternetAccess();
```

### 성능 최적화 팁

#### 1. 배치 작업 사용

```dart
// 여러 레코드를 한 번에 처리
await _localDb.transaction((txn) async {
  for (final record in records) {
    await txn.insert('table_name', record);
  }
});
```

#### 2. 적절한 동기화 간격 설정

```dart
// 앱 설정에 따라 동기화 간격 조정
const syncInterval = Duration(minutes: 10); // 배터리 절약
const syncInterval = Duration(minutes: 2);  // 실시간성 중시
```

#### 3. 선택적 동기화

```dart
// 중요한 테이블만 우선 동기화
await _syncService.forceSyncTable('user_profiles');
await _syncService.forceSyncTable('user_votes');
```

## 결론

Picnic 앱의 오프라인 우선 아키텍처는 사용자에게 끊김 없는 경험을 제공하면서도 데이터 무결성을 보장합니다. 이 문서에서 설명한 가이드라인과 모범 사례를 따르면 안정적이고 효율적인 오프라인 기능을 구현하고 유지할 수 있습니다.

추가적인 질문이나 문제가 있는 경우, 개발팀에 문의하거나 OfflineTestScreen을 사용하여 시스템 상태를 진단할 수 있습니다. 
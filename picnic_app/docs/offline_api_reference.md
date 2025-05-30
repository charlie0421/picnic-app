# Offline-First API Reference

## 개요

이 문서는 Picnic 앱의 오프라인 우선 아키텍처에서 사용되는 주요 클래스와 메서드들의 API 레퍼런스를 제공합니다.

## 목차

1. [OfflineDatabaseService](#offlinedatabaseservice)
2. [OfflineSyncService](#offlinesyncservice)
3. [ConflictResolutionService](#conflictresolutionservice)
4. [EnhancedRetryService](#enhancedretryservice)
5. [NetworkStateManager](#networkstatemanager)
6. [OfflineFirstRepository](#offlinefirstrepository)
7. [ConflictResolutionDialog](#conflictresolutiondialog)
8. [OfflineModeIndicator](#offlinemodeindicator)

---

## OfflineDatabaseService

**파일**: `picnic_lib/lib/core/services/offline_database_service.dart`

SQLite 기반 로컬 데이터베이스 관리 서비스

### 인스턴스 접근

```dart
static OfflineDatabaseService get instance
```

싱글톤 인스턴스에 접근합니다.

### 초기화

#### init()

```dart
Future<void> init()
```

데이터베이스를 초기화합니다.

**예외**:
- 데이터베이스 초기화 실패 시 예외 발생

**사용 예제**:
```dart
await OfflineDatabaseService.instance.init();
```

### CRUD 작업

#### insert()

```dart
Future<int> insert(String table, Map<String, dynamic> values)
```

테이블에 새 레코드를 삽입합니다.

**매개변수**:
- `table`: 테이블 이름
- `values`: 삽입할 데이터

**반환값**: 삽입된 레코드의 ID

**사용 예제**:
```dart
final id = await _localDb.insert('user_profiles', {
  'id': 'user_123',
  'nickname': 'John',
  'created_at': DateTime.now().toIso8601String(),
});
```

#### update()

```dart
Future<int> update(
  String table, 
  Map<String, dynamic> values, 
  String where, 
  List<dynamic> whereArgs
)
```

기존 레코드를 업데이트합니다.

**매개변수**:
- `table`: 테이블 이름
- `values`: 업데이트할 데이터
- `where`: WHERE 조건
- `whereArgs`: WHERE 조건 매개변수

**반환값**: 업데이트된 레코드 수

**사용 예제**:
```dart
await _localDb.update(
  'user_profiles',
  {'nickname': 'Jane'},
  'id = ?',
  ['user_123']
);
```

#### query()

```dart
Future<List<Map<String, dynamic>>> query(
  String table, {
  List<String>? columns,
  String? where,
  List<dynamic>? whereArgs,
  String? orderBy,
  int? limit,
  int? offset,
})
```

테이블에서 데이터를 조회합니다.

**매개변수**:
- `table`: 테이블 이름
- `columns`: 조회할 컬럼 목록 (옵션)
- `where`: WHERE 조건 (옵션)
- `whereArgs`: WHERE 조건 매개변수 (옵션)
- `orderBy`: 정렬 조건 (옵션)
- `limit`: 결과 제한 수 (옵션)
- `offset`: 결과 시작 오프셋 (옵션)

**반환값**: 조회된 레코드 목록

**사용 예제**:
```dart
final users = await _localDb.query(
  'user_profiles',
  where: 'is_dirty = ?',
  whereArgs: [1],
  orderBy: 'created_at DESC',
  limit: 10,
);
```

#### delete()

```dart
Future<int> delete(String table, String where, List<dynamic> whereArgs)
```

레코드를 삭제합니다.

**매개변수**:
- `table`: 테이블 이름
- `where`: WHERE 조건
- `whereArgs`: WHERE 조건 매개변수

**반환값**: 삭제된 레코드 수

### 동기화 관리

#### addToSyncQueue()

```dart
Future<void> addToSyncQueue(
  String tableName, 
  String recordId, 
  String operation, 
  Map<String, dynamic>? data
)
```

동기화 큐에 작업을 추가합니다.

**매개변수**:
- `tableName`: 테이블 이름
- `recordId`: 레코드 ID
- `operation`: 작업 타입 ('INSERT', 'UPDATE', 'DELETE')
- `data`: 작업 데이터 (옵션)

#### markAsDirty()

```dart
Future<void> markAsDirty(String table, String recordId)
```

레코드를 더티 상태로 표시합니다.

**매개변수**:
- `table`: 테이블 이름
- `recordId`: 레코드 ID

#### markAsClean()

```dart
Future<void> markAsClean(String table, String recordId)
```

레코드를 클린 상태로 표시합니다.

**매개변수**:
- `table`: 테이블 이름
- `recordId`: 레코드 ID

#### getDirtyRecords()

```dart
Future<List<Map<String, dynamic>>> getDirtyRecords(String table)
```

더티 상태인 레코드들을 조회합니다.

**매개변수**:
- `table`: 테이블 이름

**반환값**: 더티 레코드 목록

---

## OfflineSyncService

**파일**: `picnic_lib/lib/core/services/offline_sync_service.dart`

로컬과 원격 데이터 간의 양방향 동기화 관리 서비스

### 인스턴스 접근

```dart
static OfflineSyncService get instance
```

### 초기화

#### initialize()

```dart
Future<void> initialize()
```

동기화 서비스를 초기화합니다.

### 동기화 작업

#### forcSync()

```dart
Future<void> forcSync()
```

전체 강제 동기화를 수행합니다.

**예외**:
- 오프라인 상태일 때 `Exception` 발생

**사용 예제**:
```dart
try {
  await _syncService.forcSync();
  print('동기화 완료');
} catch (e) {
  print('동기화 실패: $e');
}
```

#### forceSyncTable()

```dart
Future<void> forceSyncTable(String tableName)
```

특정 테이블의 강제 동기화를 수행합니다.

**매개변수**:
- `tableName`: 동기화할 테이블 이름

#### getPendingSyncCount()

```dart
Future<int> getPendingSyncCount()
```

동기화 대기 중인 항목 수를 조회합니다.

**반환값**: 대기 중인 동기화 항목 수

### 동기화 상태 모니터링

#### syncStatusStream

```dart
Stream<SyncStatus> get syncStatusStream
```

동기화 상태 변화를 감지하는 스트림입니다.

**사용 예제**:
```dart
_syncService.syncStatusStream.listen((status) {
  switch (status) {
    case SyncStatus.idle:
      print('동기화 대기 중');
      break;
    case SyncStatus.syncing:
      print('동기화 진행 중');
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

---

## ConflictResolutionService

**파일**: `picnic_lib/lib/core/services/conflict_resolution_service.dart`

데이터 동기화 중 발생하는 충돌을 감지하고 해결하는 서비스

### 인스턴스 접근

```dart
static ConflictResolutionService get instance
```

### 초기화

#### initialize()

```dart
Future<void> initialize()
```

충돌 해결 서비스를 초기화합니다.

### 충돌 해결

#### resolveConflict()

```dart
Future<ConflictResolutionResult> resolveConflict({
  required String tableName,
  required String recordId,
  required Map<String, dynamic> localData,
  required Map<String, dynamic> remoteData,
  ConflictResolutionStrategy? overrideStrategy,
})
```

데이터 충돌을 감지하고 해결합니다.

**매개변수**:
- `tableName`: 테이블 이름
- `recordId`: 레코드 ID
- `localData`: 로컬 데이터
- `remoteData`: 원격 데이터
- `overrideStrategy`: 전략 오버라이드 (옵션)

**반환값**: `ConflictResolutionResult` 객체

**사용 예제**:
```dart
final result = await _conflictService.resolveConflict(
  tableName: 'user_profiles',
  recordId: 'user_123',
  localData: localUserData,
  remoteData: remoteUserData,
);

if (result.success) {
  print('충돌 해결 완료: ${result.strategy}');
} else {
  print('충돌 해결 실패: ${result.error}');
}
```

#### resolveManualConflict()

```dart
Future<bool> resolveManualConflict({
  required String conflictId,
  required dynamic resolvedValue,
})
```

수동 충돌을 해결합니다.

**매개변수**:
- `conflictId`: 충돌 ID
- `resolvedValue`: 해결된 값

**반환값**: 해결 성공 여부

### 전략 설정

#### setTableStrategy()

```dart
void setTableStrategy(String tableName, ConflictResolutionStrategy strategy)
```

테이블의 기본 충돌 해결 전략을 설정합니다.

**매개변수**:
- `tableName`: 테이블 이름
- `strategy`: 해결 전략

**사용 예제**:
```dart
_conflictService.setTableStrategy(
  'user_profiles',
  ConflictResolutionStrategy.lastWriteWins
);
```

#### setFieldStrategy()

```dart
void setFieldStrategy(
  String tableName, 
  String fieldName, 
  ConflictResolutionStrategy strategy
)
```

특정 필드의 충돌 해결 전략을 설정합니다.

**매개변수**:
- `tableName`: 테이블 이름
- `fieldName`: 필드 이름
- `strategy`: 해결 전략

### 수동 충돌 관리

#### getPendingManualReviews()

```dart
List<ConflictRecord> getPendingManualReviews()
```

수동 해결 대기 중인 충돌 목록을 조회합니다.

**반환값**: `ConflictRecord` 목록

---

## EnhancedRetryService

**파일**: `picnic_lib/lib/core/services/enhanced_retry_service.dart`

실패한 작업에 대한 향상된 재시도 메커니즘 제공 서비스

### 인스턴스 접근

```dart
static EnhancedRetryService get instance
```

### 초기화

#### initialize()

```dart
Future<void> initialize()
```

재시도 서비스를 초기화합니다.

### 재시도 스케줄링

#### scheduleRetry()

```dart
Future<T> scheduleRetry<T>({
  required String operationId,
  required Future<T> Function() operation,
  RetryPriority priority = RetryPriority.normal,
  int maxAttempts = 3,
  RetryStrategy strategy = RetryStrategy.exponentialBackoff,
  Duration? initialDelay,
  List<Type> retryOnExceptions = const [],
  bool persistentRetry = false,
})
```

작업을 재시도 큐에 스케줄링합니다.

**매개변수**:
- `operationId`: 작업 식별자
- `operation`: 실행할 작업 함수
- `priority`: 우선순위 (기본: normal)
- `maxAttempts`: 최대 시도 횟수 (기본: 3)
- `strategy`: 재시도 전략 (기본: exponentialBackoff)
- `initialDelay`: 초기 지연 시간 (옵션)
- `retryOnExceptions`: 재시도할 예외 타입 목록
- `persistentRetry`: 지속적 재시도 여부 (기본: false)

**반환값**: 작업 실행 결과

**사용 예제**:
```dart
await _retryService.scheduleRetry(
  operationId: 'sync_user_profile_123',
  operation: () => _syncUserProfile('123'),
  priority: RetryPriority.high,
  maxAttempts: 5,
  strategy: RetryStrategy.exponentialBackoff,
  retryOnExceptions: [SocketException, TimeoutException],
  persistentRetry: true,
);
```

### 상태 조회

#### getQueueStatus()

```dart
Map<String, dynamic> getQueueStatus()
```

재시도 큐의 현재 상태를 조회합니다.

**반환값**: 큐 상태 정보가 담긴 Map

**반환 데이터**:
- `pending_operations`: 대기 중인 작업 수
- `active_retries`: 활성 재시도 수
- `circuit_breakers`: 서킷 브레이커 수

---

## NetworkStateManager

**파일**: `picnic_lib/lib/core/services/network_state_manager.dart`

네트워크 상태를 실시간으로 모니터링하고 관리하는 서비스

### 인스턴스 접근

```dart
static NetworkStateManager get instance
```

### 초기화

#### initialize()

```dart
Future<void> initialize()
```

네트워크 상태 관리자를 초기화합니다.

### 네트워크 상태 확인

#### checkInternetAccess()

```dart
Future<bool> checkInternetAccess()
```

실제 인터넷 접근 가능 여부를 확인합니다.

**반환값**: 인터넷 접근 가능 여부

#### measureLatency()

```dart
Future<int?> measureLatency()
```

네트워크 지연 시간을 측정합니다.

**반환값**: 지연 시간 (밀리초), 측정 실패 시 null

### 오프라인 모드 관리

#### setOfflineMode()

```dart
Future<void> setOfflineMode(bool forceOffline)
```

강제 오프라인 모드를 설정/해제합니다.

**매개변수**:
- `forceOffline`: 강제 오프라인 모드 여부

**사용 예제**:
```dart
// 오프라인 모드 활성화
await NetworkStateManager.instance.setOfflineMode(true);

// 오프라인 모드 비활성화
await NetworkStateManager.instance.setOfflineMode(false);
```

### 네트워크 상태 스트림

#### detailedNetworkStream

```dart
Stream<DetailedNetworkState?> get detailedNetworkStream
```

상세한 네트워크 상태 변화를 감지하는 스트림입니다.

**사용 예제**:
```dart
NetworkStateManager.instance.detailedNetworkStream.listen((state) {
  if (state != null) {
    print('연결 상태: ${state.isConnected}');
    print('인터넷 접근: ${state.hasInternetAccess}');
    print('지연 시간: ${state.latencyMs}ms');
    print('네트워크 품질: ${state.quality}');
  }
});
```

---

## OfflineFirstRepository

**파일**: `picnic_lib/lib/data/repositories/offline_first_repository.dart`

오프라인 우선 데이터 접근 패턴을 구현하는 기본 Repository 클래스

### 생성자

```dart
OfflineFirstRepository({
  required String tableName,
  required T Function(Map<String, dynamic>) fromJson,
  required Map<String, dynamic> Function(T) toJson,
  required String supabaseTable,
})
```

**매개변수**:
- `tableName`: 로컬 데이터베이스 테이블 이름
- `fromJson`: JSON에서 모델로 변환하는 함수
- `toJson`: 모델에서 JSON으로 변환하는 함수
- `supabaseTable`: Supabase 테이블 이름

### 데이터 조회

#### getLocalData()

```dart
Future<List<T>> getLocalData({
  String? where,
  List<dynamic>? whereArgs,
  String? orderBy,
  int? limit,
})
```

로컬 데이터베이스에서 데이터를 조회합니다.

**매개변수**:
- `where`: WHERE 조건 (옵션)
- `whereArgs`: WHERE 조건 매개변수 (옵션)
- `orderBy`: 정렬 조건 (옵션)
- `limit`: 결과 제한 수 (옵션)

**반환값**: 모델 객체 목록

#### getRemoteData()

```dart
Future<List<T>> getRemoteData({
  String? orderBy,
  int? limit,
})
```

원격 데이터베이스에서 데이터를 조회합니다.

**매개변수**:
- `orderBy`: 정렬 조건 (옵션)
- `limit`: 결과 제한 수 (옵션)

**반환값**: 모델 객체 목록

#### getData()

```dart
Future<List<T>> getData({
  bool localFirst = true,
  String? where,
  List<dynamic>? whereArgs,
  String? orderBy,
  int? limit,
})
```

오프라인 우선 패턴으로 데이터를 조회합니다.

**매개변수**:
- `localFirst`: 로컬 우선 여부 (기본: true)
- `where`: WHERE 조건 (옵션)
- `whereArgs`: WHERE 조건 매개변수 (옵션)
- `orderBy`: 정렬 조건 (옵션)
- `limit`: 결과 제한 수 (옵션)

**반환값**: 모델 객체 목록

### 데이터 수정

#### createData()

```dart
Future<void> createData(T data)
```

새 데이터를 생성합니다.

**매개변수**:
- `data`: 생성할 데이터 모델

#### updateData()

```dart
Future<void> updateData(String id, T data)
```

기존 데이터를 업데이트합니다.

**매개변수**:
- `id`: 레코드 ID
- `data`: 업데이트할 데이터 모델

#### deleteData()

```dart
Future<void> deleteData(String id)
```

데이터를 삭제합니다.

**매개변수**:
- `id`: 삭제할 레코드 ID

### 동기화

#### syncToRemote()

```dart
Future<void> syncToRemote()
```

로컬 변경사항을 원격 서버로 동기화합니다.

#### syncFromRemote()

```dart
Future<void> syncFromRemote()
```

원격 서버에서 로컬로 데이터를 동기화합니다.

---

## ConflictResolutionDialog

**파일**: `picnic_lib/lib/presentation/widgets/conflict_resolution_dialog.dart`

충돌 해결을 위한 UI 대화상자 위젯

### 정적 메서드

#### show()

```dart
static Future<void> show(
  BuildContext context,
  ConflictRecord conflictRecord, {
  VoidCallback? onResolved,
})
```

충돌 해결 대화상자를 표시합니다.

**매개변수**:
- `context`: BuildContext
- `conflictRecord`: 해결할 충돌 레코드
- `onResolved`: 해결 완료 콜백 (옵션)

**사용 예제**:
```dart
final pendingConflicts = _conflictService.getPendingManualReviews();
if (pendingConflicts.isNotEmpty) {
  await ConflictResolutionDialog.show(
    context,
    pendingConflicts.first,
    onResolved: () {
      print('충돌 해결 완료');
      _refreshData();
    },
  );
}
```

---

## OfflineModeIndicator

**파일**: `picnic_lib/lib/presentation/widgets/offline_mode_indicator.dart`

네트워크 상태를 시각적으로 표시하는 UI 위젯

### 생성자

```dart
const OfflineModeIndicator({
  Key? key,
  this.showWhenOnline = false,
})
```

**매개변수**:
- `showWhenOnline`: 온라인 상태일 때도 표시할지 여부 (기본: false)

### 사용 예제

```dart
class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const OfflineModeIndicator(showWhenOnline: true),
          Expanded(
            child: MyContent(),
          ),
        ],
      ),
    );
  }
}
```

---

## 열거형 (Enums)

### ConflictResolutionStrategy

```dart
enum ConflictResolutionStrategy {
  localWins,        // 로컬 데이터 우선
  remoteWins,       // 원격 데이터 우선
  lastWriteWins,    // 마지막 수정 시간 기준
  merge,            // 병합 (가능한 경우)
  manualReview,     // 수동 리뷰 필요
  noConflict,       // 충돌 없음
}
```

### RetryStrategy

```dart
enum RetryStrategy {
  exponentialBackoff,  // 지수적 백오프
  linearBackoff,       // 선형 백오프
  fixedDelay,         // 고정 지연
  randomJitter,       // 랜덤 지터
}
```

### RetryPriority

```dart
enum RetryPriority {
  critical,  // 즉시 처리
  high,      // 높은 우선순위
  normal,    // 일반 우선순위
  low,       // 낮은 우선순위
}
```

### SyncStatus

```dart
enum SyncStatus {
  idle,       // 대기 중
  syncing,    // 동기화 진행 중
  completed,  // 동기화 완료
  failed,     // 동기화 실패
}
```

### NetworkQuality

```dart
enum NetworkQuality {
  excellent,  // 최상급 (< 100ms)
  good,       // 양호 (100-300ms)
  fair,       // 보통 (300-1000ms)
  poor,       // 나쁨 (> 1000ms)
  none,       // 연결 없음
}
```

---

## 데이터 클래스

### DetailedNetworkState

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

### ConflictResolutionResult

```dart
class ConflictResolutionResult {
  final bool success;
  final Map<String, dynamic> resolvedData;
  final List<FieldConflict> conflictDetails;
  final ConflictResolutionStrategy strategy;
  final String? error;
}
```

### FieldConflict

```dart
class FieldConflict {
  final String fieldName;
  final dynamic localValue;
  final dynamic remoteValue;
  final ConflictType conflictType;
  final dynamic resolvedValue;
  final bool requiresManualReview;
}
```

### ConflictRecord

```dart
class ConflictRecord {
  final String id;
  final String tableName;
  final String recordId;
  final FieldConflict conflict;
  final Map<String, dynamic> localData;
  final Map<String, dynamic> remoteData;
  final DateTime createdAt;
  final ConflictStatus status;
}
```

---

## 사용 예제

### 기본 사용법

```dart
// 서비스 초기화
await OfflineDatabaseService.instance.init();
await OfflineSyncService.instance.initialize();
await ConflictResolutionService.instance.initialize();
await NetworkStateManager.instance.initialize();

// 데이터 생성
final userRepo = UserProfileRepository();
await userRepo.createData(newUserProfile);

// 오프라인 우선 데이터 조회
final users = await userRepo.getData();

// 동기화 상태 모니터링
OfflineSyncService.instance.syncStatusStream.listen((status) {
  print('Sync status: $status');
});

// 네트워크 상태 모니터링
NetworkStateManager.instance.detailedNetworkStream.listen((state) {
  if (state?.hasInternetAccess == true) {
    // 동기화 트리거
    OfflineSyncService.instance.forcSync();
  }
});
```

### 고급 사용법

```dart
// 충돌 해결 전략 설정
ConflictResolutionService.instance.setFieldStrategy(
  'user_profiles',
  'nickname',
  ConflictResolutionStrategy.manualReview,
);

// 재시도 작업 스케줄링
await EnhancedRetryService.instance.scheduleRetry(
  operationId: 'critical_sync',
  operation: () => syncCriticalData(),
  priority: RetryPriority.critical,
  persistentRetry: true,
);

// 수동 충돌 해결
final conflicts = ConflictResolutionService.instance.getPendingManualReviews();
if (conflicts.isNotEmpty && mounted) {
  await ConflictResolutionDialog.show(context, conflicts.first);
}
``` 
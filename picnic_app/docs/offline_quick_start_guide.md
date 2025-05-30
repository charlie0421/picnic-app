# Offline-First Quick Start Guide

## 개요

이 가이드는 개발자가 Picnic 앱에서 오프라인 우선 기능을 빠르게 구현할 수 있도록 돕는 실용적인 시작 가이드입니다.

## 5분 만에 시작하기

### 1. 기본 설정 확인

먼저 필요한 서비스들이 초기화되어 있는지 확인하세요:

```dart
// main.dart 또는 앱 시작 지점에서
await OfflineDatabaseService.instance.init();
await OfflineSyncService.instance.initialize();
await ConflictResolutionService.instance.initialize();
await NetworkStateManager.instance.initialize();
```

### 2. Repository 생성

새로운 데이터 타입을 위한 Repository를 만드세요:

```dart
// lib/data/repositories/my_data_repository.dart
import 'package:picnic_lib/data/repositories/offline_first_repository.dart';

class MyDataRepository extends OfflineFirstRepository<MyData> {
  MyDataRepository() : super(
    tableName: 'my_data',
    fromJson: MyData.fromJson,
    toJson: (data) => data.toJson(),
    supabaseTable: 'my_data',
  );
}
```

### 3. 데이터 모델 정의

JSON 직렬화가 가능한 데이터 모델을 만드세요:

```dart
// lib/data/models/my_data.dart
class MyData {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;

  MyData({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MyData.fromJson(Map<String, dynamic> json) {
    return MyData(
      id: json['id'],
      name: json['name'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
```

### 4. 데이터베이스 스키마 추가

`OfflineDatabaseService`에 새 테이블을 추가하세요:

```dart
// offline_database_service.dart의 _createTables 메서드에 추가
await db.execute('''
  CREATE TABLE my_data (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    created_at TEXT,
    updated_at TEXT,
    last_sync TEXT,
    is_dirty INTEGER DEFAULT 0
  )
''');

// 인덱스 추가
await db.execute('CREATE INDEX idx_my_data_name ON my_data(name)');
```

### 5. UI에서 사용

이제 화면에서 오프라인 우선 데이터를 사용할 수 있습니다:

```dart
class MyDataScreen extends StatefulWidget {
  @override
  _MyDataScreenState createState() => _MyDataScreenState();
}

class _MyDataScreenState extends State<MyDataScreen> {
  final MyDataRepository _repository = MyDataRepository();
  List<MyData> _data = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // 오프라인 우선으로 데이터 로드
      final data = await _repository.getData();
      setState(() {
        _data = data;
      });
    } catch (e) {
      print('데이터 로드 실패: $e');
    }
  }

  Future<void> _createData() async {
    final newData = MyData(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'New Item',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _repository.createData(newData);
    _loadData(); // 새로고침
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Data'),
        actions: [
          // 오프라인 상태 표시
          const OfflineModeIndicator(),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _data.length,
              itemBuilder: (context, index) {
                final item = _data[index];
                return ListTile(
                  title: Text(item.name),
                  subtitle: Text('Created: ${item.createdAt}'),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createData,
        child: Icon(Icons.add),
      ),
    );
  }
}
```

## 고급 기능 추가

### 동기화 상태 모니터링

```dart
class MyDataScreen extends StatefulWidget {
  @override
  _MyDataScreenState createState() => _MyDataScreenState();
}

class _MyDataScreenState extends State<MyDataScreen> {
  SyncStatus _syncStatus = SyncStatus.idle;

  @override
  void initState() {
    super.initState();
    // 동기화 상태 모니터링
    OfflineSyncService.instance.syncStatusStream.listen((status) {
      setState(() {
        _syncStatus = status;
      });
    });
  }

  Widget _buildSyncIndicator() {
    switch (_syncStatus) {
      case SyncStatus.syncing:
        return Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text('동기화 중...'),
          ],
        );
      case SyncStatus.completed:
        return Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 16),
            SizedBox(width: 8),
            Text('동기화 완료'),
          ],
        );
      case SyncStatus.failed:
        return Row(
          children: [
            Icon(Icons.error, color: Colors.red, size: 16),
            SizedBox(width: 8),
            Text('동기화 실패'),
          ],
        );
      default:
        return SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Data'),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(40),
          child: Container(
            height: 40,
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildSyncIndicator(),
                Spacer(),
                const OfflineModeIndicator(),
              ],
            ),
          ),
        ),
      ),
      // ... 나머지 UI
    );
  }
}
```

### 네트워크 상태 반응형 UI

```dart
class NetworkAwareScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<DetailedNetworkState?>(
        stream: NetworkStateManager.instance.detailedNetworkStream,
        builder: (context, snapshot) {
          final networkState = snapshot.data;
          
          if (networkState?.isOfflineModeForced == true) {
            return _buildOfflineContent();
          }
          
          if (networkState?.hasInternetAccess != true) {
            return _buildOfflineContent();
          }
          
          return _buildOnlineContent();
        },
      ),
    );
  }

  Widget _buildOfflineContent() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(16),
          color: Colors.orange[100],
          child: Row(
            children: [
              Icon(Icons.offline_bolt, color: Colors.orange),
              SizedBox(width: 8),
              Text('오프라인 모드 - 로컬 데이터를 표시 중'),
            ],
          ),
        ),
        Expanded(child: MyOfflineDataList()),
      ],
    );
  }

  Widget _buildOnlineContent() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(16),
          color: Colors.green[100],
          child: Row(
            children: [
              Icon(Icons.wifi, color: Colors.green),
              SizedBox(width: 8),
              Text('온라인 모드 - 실시간 데이터'),
            ],
          ),
        ),
        Expanded(child: MyOnlineDataList()),
      ],
    );
  }
}
```

### 충돌 해결 처리

```dart
class MyDataScreen extends StatefulWidget {
  @override
  _MyDataScreenState createState() => _MyDataScreenState();
}

class _MyDataScreenState extends State<MyDataScreen> {
  @override
  void initState() {
    super.initState();
    _checkForConflicts();
  }

  Future<void> _checkForConflicts() async {
    final conflicts = ConflictResolutionService.instance.getPendingManualReviews();
    
    if (conflicts.isNotEmpty && mounted) {
      // 충돌이 있으면 해결 대화상자 표시
      await ConflictResolutionDialog.show(
        context,
        conflicts.first,
        onResolved: () {
          print('충돌 해결 완료');
          _loadData(); // 데이터 새로고침
        },
      );
    }
  }

  Future<void> _handleConflicts() async {
    // 수동으로 충돌 확인 및 해결
    final conflicts = ConflictResolutionService.instance.getPendingManualReviews();
    
    if (conflicts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('해결할 충돌이 없습니다')),
      );
      return;
    }

    for (final conflict in conflicts) {
      await ConflictResolutionDialog.show(
        context,
        conflict,
        onResolved: () => _loadData(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Data'),
        actions: [
          IconButton(
            icon: Icon(Icons.sync_problem),
            onPressed: _handleConflicts,
            tooltip: '충돌 해결',
          ),
        ],
      ),
      // ... 나머지 UI
    );
  }
}
```

## 테스트 및 디버깅

### 개발 중 테스트

개발 중에는 `OfflineTestScreen`을 사용하여 오프라인 기능을 테스트하세요:

```dart
// 테스트 화면으로 이동
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => OfflineTestScreen()),
);
```

### 로깅 활성화

디버깅을 위해 로깅을 활성화하세요:

```dart
// main.dart
import 'package:logger/logger.dart';

void main() async {
  // 로그 레벨 설정
  Logger.level = Level.debug;
  
  runApp(MyApp());
}
```

### 오프라인 시나리오 테스트

```dart
// 1. 오프라인 모드 활성화
await NetworkStateManager.instance.setOfflineMode(true);

// 2. 데이터 생성/수정
await repository.createData(testData);

// 3. 온라인 모드 복구
await NetworkStateManager.instance.setOfflineMode(false);

// 4. 동기화 확인
await OfflineSyncService.instance.forcSync();
```

## 모범 사례

### 1. 에러 처리

```dart
Future<void> _performOfflineAction() async {
  try {
    await repository.createData(newData);
  } catch (e) {
    if (e is NetworkException) {
      // 네트워크 오류 - 로컬에 저장됨을 사용자에게 알림
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('오프라인 상태 - 온라인 복구 시 동기화됩니다'),
          backgroundColor: Colors.orange,
        ),
      );
    } else {
      // 다른 오류 처리
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('오류 발생: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
```

### 2. 사용자 피드백

```dart
Widget _buildDataItem(MyData item) {
  return ListTile(
    title: Text(item.name),
    subtitle: Text('Created: ${item.createdAt}'),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 로컬 변경사항 표시
        if (item.isDirty)
          Icon(
            Icons.sync_problem,
            color: Colors.orange,
            size: 16,
          ),
        // 동기화 상태 표시
        if (item.lastSync != null)
          Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 16,
          ),
      ],
    ),
  );
}
```

### 3. 성능 최적화

```dart
class OptimizedDataScreen extends StatefulWidget {
  @override
  _OptimizedDataScreenState createState() => _OptimizedDataScreenState();
}

class _OptimizedDataScreenState extends State<OptimizedDataScreen> {
  final MyDataRepository _repository = MyDataRepository();
  List<MyData> _data = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDataWithCaching();
  }

  Future<void> _loadDataWithCaching() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 로컬 데이터 먼저 로드 (빠른 UI 응답)
      final localData = await _repository.getLocalData();
      if (localData.isNotEmpty) {
        setState(() {
          _data = localData;
          _isLoading = false;
        });
      }

      // 백그라운드에서 원격 데이터 동기화
      if (NetworkStateManager.instance.detailedNetworkStream.value?.hasInternetAccess == true) {
        await _repository.syncFromRemote();
        final updatedData = await _repository.getLocalData();
        setState(() {
          _data = updatedData;
        });
      }
    } catch (e) {
      print('데이터 로드 실패: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _data.isEmpty) {
      return Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      itemCount: _data.length,
      itemBuilder: (context, index) => _buildDataItem(_data[index]),
    );
  }
}
```

## 문제 해결

### 자주 발생하는 문제

1. **동기화가 안 될 때**:
   - 네트워크 상태 확인: `NetworkStateManager.instance.detailedNetworkStream.value`
   - 수동 동기화 시도: `OfflineSyncService.instance.forcSync()`

2. **데이터가 중복될 때**:
   - 충돌 해결 전략 확인
   - `ConflictResolutionService.instance.getPendingManualReviews()` 호출

3. **앱이 느려질 때**:
   - 데이터베이스 크기 확인
   - 불필요한 동기화 큐 정리

### 디버깅 도구

```dart
// 시스템 상태 확인
void debugOfflineSystem() {
  print('Network State: ${NetworkStateManager.instance.detailedNetworkStream.value}');
  print('Sync Status: ${OfflineSyncService.instance.syncStatusStream.value}');
  print('Pending Conflicts: ${ConflictResolutionService.instance.getPendingManualReviews().length}');
}
```

## 다음 단계

이 가이드를 완료했다면:

1. [상세한 아키텍처 가이드](offline_first_architecture_guide.md) 읽기
2. [API 레퍼런스](offline_api_reference.md)에서 고급 기능 확인
3. 실제 프로젝트에 오프라인 기능 적용
4. `OfflineTestScreen`으로 다양한 시나리오 테스트

추가 도움이 필요하면 개발팀에 문의하거나 기존 구현체(`UserProfileRepository`, `VoteRepository` 등)를 참조하세요. 
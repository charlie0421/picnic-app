import 'dart:async';
import 'dart:convert';
import 'package:synchronized/synchronized.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:picnic_lib/core/utils/logger.dart';

/// 오프라인 우선 데이터베이스 서비스
/// SQLite를 사용하여 로컬 데이터 저장소를 관리하고
/// 네트워크 연결시 Supabase와 동기화를 처리합니다.
class OfflineDatabaseService {
  static const String _databaseName = 'picnic_offline.db';
  static const int _databaseVersion = 3;

  static OfflineDatabaseService? _instance;
  static OfflineDatabaseService get instance =>
      _instance ??= OfflineDatabaseService._();
  OfflineDatabaseService._();

  Database? _database;
  final Lock _lock = Lock();

  /// 데이터베이스 초기화
  Future<void> init() async {
    await _lock.synchronized(() async {
      if (_database != null) return;

      try {
        final databasePath = await getDatabasesPath();
        final path = join(databasePath, _databaseName);

        _database = await openDatabase(
          path,
          version: _databaseVersion,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
        );

        logger.i('Offline database initialized successfully');
      } catch (e, s) {
        logger.e('Failed to initialize offline database',
            error: e, stackTrace: s);
        rethrow;
      }
    });
  }

  /// 데이터베이스 스키마 생성
  Future<void> _onCreate(Database db, int version) async {
    await db.transaction((txn) async {
      // 사용자 프로필 테이블
      await txn.execute('''
        CREATE TABLE user_profiles (
          id TEXT PRIMARY KEY,
          nickname TEXT,
          avatar_url TEXT,
          bio TEXT,
          created_at TEXT,
          updated_at TEXT,
          last_sync TEXT,
          is_dirty INTEGER DEFAULT 0
        )
      ''');

      // 팝업 테이블
      await txn.execute('''
        CREATE TABLE popups (
          id INTEGER PRIMARY KEY,
          title TEXT NOT NULL,  -- JSON 문자열: {"ko": "제목", "en": "Title"}
          content TEXT NOT NULL,  -- JSON 문자열: {"ko": "내용", "en": "Content"}
          image TEXT,  -- JSON 문자열: {"url": "image_url"}
          created_at TEXT,
          updated_at TEXT,
          deleted_at TEXT,
          start_at TEXT,
          stop_at TEXT,
          last_sync TEXT,
          is_dirty INTEGER DEFAULT 0
        )
      ''');

      // 투표 데이터 테이블
      await txn.execute('''
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
        )
      ''');

      // 사용자 투표 기록 테이블
      await txn.execute('''
        CREATE TABLE user_votes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          user_id TEXT NOT NULL,
          vote_id INTEGER NOT NULL,
          artist_id INTEGER NOT NULL,
          voted_at TEXT,
          last_sync TEXT,
          is_dirty INTEGER DEFAULT 0,
          UNIQUE(user_id, vote_id)
        )
      ''');

      // 갤러리 데이터 테이블
      await txn.execute('''
        CREATE TABLE galleries (
          id INTEGER PRIMARY KEY,
          title TEXT NOT NULL,
          description TEXT,
          image_url TEXT,
          category TEXT,
          artist_id INTEGER,
          like_count INTEGER DEFAULT 0,
          view_count INTEGER DEFAULT 0,
          created_at TEXT,
          updated_at TEXT,
          last_sync TEXT,
          is_dirty INTEGER DEFAULT 0
        )
      ''');

      // 동기화 큐 테이블 (오프라인 변경사항 추적)
      await txn.execute('''
        CREATE TABLE sync_queue (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          table_name TEXT NOT NULL,
          record_id TEXT NOT NULL,
          operation TEXT NOT NULL, -- INSERT, UPDATE, DELETE
          data TEXT, -- JSON data
          created_at TEXT,
          retry_count INTEGER DEFAULT 0,
          last_retry TEXT
        )
      ''');

      // 지속적 재시도 테이블 (EnhancedRetryService용)
      await txn.execute('''
        CREATE TABLE persistent_retries (
          id TEXT PRIMARY KEY,
          operation_data TEXT NOT NULL, -- JSON data for RetryOperation
          created_at TEXT NOT NULL,
          status TEXT DEFAULT 'pending', -- pending, failed, completed
          failed_at TEXT,
          last_attempt_at TEXT,
          attempt_count INTEGER DEFAULT 0
        )
      ''');

      // 충돌 리뷰 테이블 (수동 해결 대기)
      await txn.execute('''
        CREATE TABLE conflict_reviews (
          id TEXT PRIMARY KEY,
          table_name TEXT NOT NULL,
          record_id TEXT NOT NULL,
          field_name TEXT NOT NULL,
          local_value TEXT NOT NULL, -- JSON encoded
          remote_value TEXT NOT NULL, -- JSON encoded
          local_data TEXT NOT NULL, -- JSON encoded full record
          remote_data TEXT NOT NULL, -- JSON encoded full record
          conflict_type TEXT NOT NULL,
          status TEXT DEFAULT 'pending', -- pending, resolved, dismissed
          resolved_value TEXT, -- JSON encoded
          created_at TEXT NOT NULL,
          resolved_at TEXT
        )
      ''');

      // 충돌 해결 기록 테이블
      await txn.execute('''
        CREATE TABLE conflict_history (
          id TEXT PRIMARY KEY,
          table_name TEXT NOT NULL,
          record_id TEXT NOT NULL,
          conflicts_count INTEGER NOT NULL,
          strategy_used TEXT NOT NULL,
          resolution_data TEXT NOT NULL, -- JSON encoded
          success INTEGER NOT NULL, -- 0 or 1
          error_message TEXT,
          resolved_at TEXT NOT NULL
        )
      ''');

      // 인덱스 생성
      await txn.execute(
          'CREATE INDEX idx_popups_start_stop ON popups(start_at, stop_at)');
      await txn
          .execute('CREATE INDEX idx_popups_deleted_at ON popups(deleted_at)');
      await txn.execute('CREATE INDEX idx_votes_status ON votes(status)');
      await txn.execute('CREATE INDEX idx_votes_category ON votes(category)');
      await txn.execute(
          'CREATE INDEX idx_user_votes_user_id ON user_votes(user_id)');
      await txn.execute(
          'CREATE INDEX idx_galleries_category ON galleries(category)');
      await txn.execute(
          'CREATE INDEX idx_sync_queue_table ON sync_queue(table_name)');
      await txn.execute(
          'CREATE INDEX idx_persistent_retries_status ON persistent_retries(status)');
      await txn.execute(
          'CREATE INDEX idx_conflict_reviews_status ON conflict_reviews(status)');
      await txn.execute(
          'CREATE INDEX idx_conflict_reviews_table ON conflict_reviews(table_name)');
      await txn.execute(
          'CREATE INDEX idx_conflict_history_table ON conflict_history(table_name)');
    });

    logger.i('Database schema created successfully');
  }

  /// 데이터베이스 업그레이드
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    logger.i('Upgrading database from version $oldVersion to $newVersion');

    if (oldVersion < 2) {
      // 버전 2: popups 테이블 추가
      await db.execute('''
        CREATE TABLE popups (
          id INTEGER PRIMARY KEY,
          title TEXT NOT NULL,  -- JSON 문자열: {"ko": "제목", "en": "Title"}
          content TEXT NOT NULL,  -- JSON 문자열: {"ko": "내용", "en": "Content"}
          image TEXT,  -- JSON 문자열: {"url": "image_url"}
          created_at TEXT,
          updated_at TEXT,
          deleted_at TEXT,
          start_at TEXT,
          stop_at TEXT,
          last_sync TEXT,
          is_dirty INTEGER DEFAULT 0
        )
      ''');

      // popups 테이블 인덱스 추가
      await db.execute(
          'CREATE INDEX idx_popups_start_stop ON popups(start_at, stop_at)');
      await db
          .execute('CREATE INDEX idx_popups_deleted_at ON popups(deleted_at)');

      logger.i('Added popups table and indexes');
    }

    if (oldVersion < 3) {
      // 버전 3: popups 테이블 JSON 스키마 수정을 위해 재생성
      await db.execute('DROP TABLE IF EXISTS popups');

      await db.execute('''
        CREATE TABLE popups (
          id INTEGER PRIMARY KEY,
          title TEXT NOT NULL,  -- JSON 문자열: {"ko": "제목", "en": "Title"}
          content TEXT NOT NULL,  -- JSON 문자열: {"ko": "내용", "en": "Content"}
          image TEXT,  -- JSON 문자열: {"url": "image_url"}
          created_at TEXT,
          updated_at TEXT,
          deleted_at TEXT,
          start_at TEXT,
          stop_at TEXT,
          last_sync TEXT,
          is_dirty INTEGER DEFAULT 0
        )
      ''');

      // popups 테이블 인덱스 재생성
      await db.execute(
          'CREATE INDEX idx_popups_start_stop ON popups(start_at, stop_at)');
      await db
          .execute('CREATE INDEX idx_popups_deleted_at ON popups(deleted_at)');

      logger.i('Recreated popups table with JSON schema for version 3');
    }
  }

  /// 데이터베이스 인스턴스 가져오기
  Future<Database> get database async {
    if (_database == null) {
      await init();
    }
    return _database!;
  }

  /// 트랜잭션 실행
  Future<T> transaction<T>(Future<T> Function(Transaction txn) action) async {
    final db = await database;
    return await db.transaction(action);
  }

  /// 원시 쿼리 실행
  Future<List<Map<String, dynamic>>> rawQuery(String sql,
      [List<dynamic>? arguments]) async {
    final db = await database;
    return await db.rawQuery(sql, arguments);
  }

  /// 데이터 삽입
  Future<int> insert(String table, Map<String, dynamic> values) async {
    final db = await database;
    return await db.insert(table, values,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// 데이터 업데이트
  Future<int> update(String table, Map<String, dynamic> values, String where,
      List<dynamic> whereArgs) async {
    final db = await database;
    return await db.update(table, values, where: where, whereArgs: whereArgs);
  }

  /// 데이터 삭제
  Future<int> delete(
      String table, String where, List<dynamic> whereArgs) async {
    final db = await database;
    return await db.delete(table, where: where, whereArgs: whereArgs);
  }

  /// 데이터 조회
  Future<List<Map<String, dynamic>>> query(
    String table, {
    List<String>? columns,
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    return await db.query(
      table,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  /// 동기화 큐에 작업 추가
  Future<void> addToSyncQueue(String tableName, String recordId,
      String operation, Map<String, dynamic>? data) async {
    await insert('sync_queue', {
      'table_name': tableName,
      'record_id': recordId,
      'operation': operation,
      'data': data != null ? jsonEncode(data) : null,
      'created_at': DateTime.now().toIso8601String(),
      'retry_count': 0,
    });

    logger.d('Added to sync queue: $tableName $operation $recordId');
  }

  /// 동기화 큐 조회
  Future<List<Map<String, dynamic>>> getSyncQueue({int? limit}) async {
    return await query(
      'sync_queue',
      orderBy: 'created_at ASC',
      limit: limit,
    );
  }

  /// 동기화 큐에서 항목 제거
  Future<void> removeFromSyncQueue(int syncId) async {
    await delete('sync_queue', 'id = ?', [syncId]);
    logger.d('Removed from sync queue: $syncId');
  }

  /// 동기화 재시도 횟수 증가
  Future<void> incrementSyncRetry(int syncId) async {
    await rawQuery(
      'UPDATE sync_queue SET retry_count = retry_count + 1, last_retry = ? WHERE id = ?',
      [DateTime.now().toIso8601String(), syncId],
    );
  }

  /// 더티 플래그 설정 (로컬 변경사항 표시)
  Future<void> markAsDirty(String table, String recordId) async {
    await rawQuery(
      'UPDATE $table SET is_dirty = 1, updated_at = ? WHERE id = ?',
      [DateTime.now().toIso8601String(), recordId],
    );
  }

  /// 더티 플래그 해제 (동기화 완료 표시)
  Future<void> markAsClean(String table, String recordId) async {
    await rawQuery(
      'UPDATE $table SET is_dirty = 0, last_sync = ? WHERE id = ?',
      [DateTime.now().toIso8601String(), recordId],
    );
  }

  /// 더티 레코드 조회
  Future<List<Map<String, dynamic>>> getDirtyRecords(String table) async {
    return await query(table, where: 'is_dirty = 1');
  }

  /// 데이터베이스 정리
  Future<void> cleanup() async {
    await _lock.synchronized(() async {
      await _database?.close();
      _database = null;
    });
    logger.i('Database cleaned up');
  }

  /// 데이터베이스 재설정 (개발용)
  Future<void> reset() async {
    await cleanup();

    final databasePath = await getDatabasesPath();
    final path = join(databasePath, _databaseName);
    await deleteDatabase(path);

    logger.w('Database reset completed');
  }
}

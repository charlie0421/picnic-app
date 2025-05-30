import 'dart:async';
import 'package:picnic_lib/core/services/offline_database_service.dart';
import 'package:picnic_lib/core/services/enhanced_network_service.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sqflite/sqflite.dart';

/// 오프라인 우선 Repository 기본 클래스
/// 로컬 데이터베이스를 우선으로 하고 네트워크 연결시 원격 서버와 동기화
abstract class OfflineFirstRepository<T> {
  final OfflineDatabaseService _localDb = OfflineDatabaseService.instance;
  final EnhancedNetworkService _networkService = EnhancedNetworkService();
  final SupabaseClient _supabase = supabase;

  /// 테이블 이름
  String get tableName;

  /// 원격 테이블 이름 (로컬과 다를 경우)
  String get remoteTableName => tableName;

  /// JSON에서 모델로 변환
  T fromJson(Map<String, dynamic> json);

  /// 모델에서 JSON으로 변환
  Map<String, dynamic> toJson(T model);

  /// 모델에서 ID 추출
  String getId(T model);

  /// 데이터 조회 (오프라인 우선)
  Future<List<T>> getAll({
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
    int? offset,
    bool forceRemote = false,
  }) async {
    try {
      // 네트워크 연결 상태 확인
      final isOnline = _networkService.isOnline;

      if (!forceRemote && (!isOnline || await _hasLocalData())) {
        // 로컬 데이터 우선 반환
        final localData = await _getLocalData(
          where: where,
          whereArgs: whereArgs,
          orderBy: orderBy,
          limit: limit,
          offset: offset,
        );

        if (localData.isNotEmpty || !isOnline) {
          logger.d('Returning local data for $tableName');
          return localData;
        }
      }

      // 원격 데이터 가져오기
      if (isOnline) {
        final remoteData = await _getRemoteData(
          where: where,
          whereArgs: whereArgs,
          orderBy: orderBy,
          limit: limit,
          offset: offset,
        );

        // 로컬 캐시 업데이트
        await _updateLocalCache(remoteData);
        logger.d('Fetched and cached remote data for $tableName');
        return remoteData;
      }

      // 오프라인이고 로컬 데이터가 없는 경우
      logger.w('No data available for $tableName (offline)');
      return [];
    } catch (e, s) {
      logger.e('Error getting data from $tableName', error: e, stackTrace: s);

      // 에러 발생시 로컬 데이터라도 반환
      try {
        final localData = await _getLocalData(
          where: where,
          whereArgs: whereArgs,
          orderBy: orderBy,
          limit: limit,
          offset: offset,
        );
        logger.i('Fallback to local data for $tableName');
        return localData;
      } catch (localError) {
        logger.e('Failed to get local fallback data', error: localError);
        return [];
      }
    }
  }

  /// 단일 데이터 조회
  Future<T?> getById(String id, {bool forceRemote = false}) async {
    try {
      final results = await getAll(
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
        forceRemote: forceRemote,
      );

      return results.isNotEmpty ? results.first : null;
    } catch (e, s) {
      logger.e('Error getting $tableName by id: $id', error: e, stackTrace: s);
      return null;
    }
  }

  /// 데이터 생성
  Future<T?> create(T model) async {
    try {
      final id = getId(model);
      final data = toJson(model);
      data['created_at'] = DateTime.now().toIso8601String();
      data['updated_at'] = data['created_at'];

      if (_networkService.isOnline) {
        // 온라인: 즉시 원격 서버에 저장
        final response = await _supabase
            .from(remoteTableName)
            .insert(data)
            .select()
            .single();

        final createdModel = fromJson(response);

        // 로컬 캐시 업데이트
        await _insertLocal(response);

        logger.d('Created $tableName record: $id');
        return createdModel;
      } else {
        // 오프라인: 로컬에 저장하고 동기화 큐에 추가
        await _insertLocal(data);
        await _localDb.addToSyncQueue(tableName, id, 'INSERT', data);

        logger.d('Created $tableName record offline: $id');
        return model;
      }
    } catch (e, s) {
      logger.e('Error creating $tableName record', error: e, stackTrace: s);

      // 실패시 로컬에 저장 시도
      try {
        final id = getId(model);
        final data = toJson(model);
        await _insertLocal(data);
        await _localDb.addToSyncQueue(tableName, id, 'INSERT', data);
        logger.i('Saved $tableName record locally due to error');
        return model;
      } catch (localError) {
        logger.e('Failed to save $tableName record locally', error: localError);
        return null;
      }
    }
  }

  /// 데이터 업데이트
  Future<T?> update(T model) async {
    try {
      final id = getId(model);
      final data = toJson(model);
      data['updated_at'] = DateTime.now().toIso8601String();

      if (_networkService.isOnline) {
        // 온라인: 즉시 원격 서버 업데이트
        final response = await _supabase
            .from(remoteTableName)
            .update(data)
            .eq('id', id)
            .select()
            .single();

        final updatedModel = fromJson(response);

        // 로컬 캐시 업데이트
        await _updateLocal(id, response);

        logger.d('Updated $tableName record: $id');
        return updatedModel;
      } else {
        // 오프라인: 로컬 업데이트하고 동기화 큐에 추가
        await _updateLocal(id, data);
        await _localDb.addToSyncQueue(tableName, id, 'UPDATE', data);
        await _localDb.markAsDirty(tableName, id);

        logger.d('Updated $tableName record offline: $id');
        return model;
      }
    } catch (e, s) {
      logger.e('Error updating $tableName record', error: e, stackTrace: s);

      // 실패시 로컬 업데이트 시도
      try {
        final id = getId(model);
        final data = toJson(model);
        await _updateLocal(id, data);
        await _localDb.addToSyncQueue(tableName, id, 'UPDATE', data);
        await _localDb.markAsDirty(tableName, id);
        logger.i('Updated $tableName record locally due to error');
        return model;
      } catch (localError) {
        logger.e('Failed to update $tableName record locally',
            error: localError);
        return null;
      }
    }
  }

  /// 데이터 삭제
  Future<bool> delete(String id) async {
    try {
      if (_networkService.isOnline) {
        // 온라인: 즉시 원격 서버에서 삭제
        await _supabase.from(remoteTableName).delete().eq('id', id);

        // 로컬에서도 삭제
        await _deleteLocal(id);

        logger.d('Deleted $tableName record: $id');
        return true;
      } else {
        // 오프라인: 로컬에서 삭제하고 동기화 큐에 추가
        await _deleteLocal(id);
        await _localDb.addToSyncQueue(tableName, id, 'DELETE', null);

        logger.d('Deleted $tableName record offline: $id');
        return true;
      }
    } catch (e, s) {
      logger.e('Error deleting $tableName record: $id',
          error: e, stackTrace: s);

      // 실패시 로컬 삭제 시도
      try {
        await _deleteLocal(id);
        await _localDb.addToSyncQueue(tableName, id, 'DELETE', null);
        logger.i('Deleted $tableName record locally due to error');
        return true;
      } catch (localError) {
        logger.e('Failed to delete $tableName record locally',
            error: localError);
        return false;
      }
    }
  }

  /// 로컬 데이터 존재 여부 확인
  Future<bool> _hasLocalData() async {
    final results = await _localDb.query(tableName, limit: 1);
    return results.isNotEmpty;
  }

  /// 로컬 데이터 조회
  Future<List<T>> _getLocalData({
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final results = await _localDb.query(
      tableName,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );

    return results.map((json) => fromJson(json)).toList();
  }

  /// 원격 데이터 조회
  Future<List<T>> _getRemoteData({
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    dynamic query = _supabase.from(remoteTableName).select();

    // where 조건 처리 (Supabase용으로 변환 필요)
    if (where != null && whereArgs != null) {
      // 간단한 예시: 실제로는 더 복잡한 쿼리 변환이 필요할 수 있음
      if (where == 'id = ?' && whereArgs.isNotEmpty) {
        query = query.eq('id', whereArgs.first);
      }
    }

    if (orderBy != null) {
      // orderBy 파싱 필요 (예: "created_at DESC" -> order('created_at', ascending: false))
      final parts = orderBy.split(' ');
      final column = parts[0];
      final ascending = parts.length < 2 || parts[1].toUpperCase() != 'DESC';
      query = query.order(column, ascending: ascending);
    }

    if (limit != null) {
      query = query.limit(limit);
    }

    if (offset != null) {
      query = query.range(offset, offset + (limit ?? 10) - 1);
    }

    final response = await query;
    return (response as List).map((json) => fromJson(json)).toList();
  }

  /// 로컬 캐시 업데이트
  Future<void> _updateLocalCache(List<T> data) async {
    await _localDb.transaction((txn) async {
      for (final item in data) {
        final json = toJson(item);
        json['last_sync'] = DateTime.now().toIso8601String();
        json['is_dirty'] = 0;

        await txn.insert(
          tableName,
          json,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  /// 로컬 데이터 삽입
  Future<void> _insertLocal(Map<String, dynamic> data) async {
    await _localDb.insert(tableName, data);
  }

  /// 로컬 데이터 업데이트
  Future<void> _updateLocal(String id, Map<String, dynamic> data) async {
    await _localDb.update(tableName, data, 'id = ?', [id]);
  }

  /// 로컬 데이터 삭제
  Future<void> _deleteLocal(String id) async {
    await _localDb.delete(tableName, 'id = ?', [id]);
  }

  /// 동기화되지 않은 로컬 변경사항 가져오기
  Future<List<Map<String, dynamic>>> getPendingSync() async {
    return await _localDb.getSyncQueue();
  }

  /// 강제 원격 동기화
  Future<void> forceSyncFromRemote() async {
    if (_networkService.isOnline) {
      final remoteData = await _getRemoteData();
      await _updateLocalCache(remoteData);
      logger.i('Force synced $tableName from remote');
    }
  }
}

import 'dart:async';

import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}

class MockPostgrestFilterBuilder<T> extends Mock
    implements PostgrestFilterBuilder<T> {}

class MockPostgrestTransformBuilder<T> extends Mock
    implements PostgrestTransformBuilder<T> {}

/// Future를 올바르게 구현하는 Fake Transform Builder
///
/// PostgrestTransformBuilder는 Future를 implement하므로
/// Mockito의 when/thenReturn과 호환되지 않습니다.
class FakePostgrestTransformBuilder<T> extends Fake
    implements PostgrestTransformBuilder<T> {
  final T? _value;
  final Object? _error;
  final bool _isError;

  FakePostgrestTransformBuilder(T value)
      : _value = value,
        _error = null,
        _isError = false;

  FakePostgrestTransformBuilder.error(Object error)
      : _value = null,
        _error = error,
        _isError = true;

  @override
  Future<R> then<R>(FutureOr<R> Function(T) onValue,
      {Function? onError}) {
    if (_isError) {
      return Future<T>.error(_error!).then(onValue, onError: onError);
    }
    return Future.value(_value as T).then(onValue, onError: onError);
  }

  @override
  Future<T> catchError(Function onError, {bool Function(Object)? test}) {
    if (_isError) {
      return Future<T>.error(_error!).catchError(onError, test: test);
    }
    return Future.value(_value as T);
  }

  @override
  Future<T> whenComplete(FutureOr<void> Function() action) {
    if (_isError) {
      return Future<T>.error(_error!).whenComplete(action);
    }
    return Future.value(_value as T).whenComplete(action);
  }

  @override
  Stream<T> asStream() {
    if (_isError) {
      return Stream.error(_error!);
    }
    return Stream.value(_value as T);
  }

  @override
  Future<T> timeout(Duration timeLimit,
      {FutureOr<T> Function()? onTimeout}) {
    if (_isError) {
      return Future<T>.error(_error!)
          .timeout(timeLimit, onTimeout: onTimeout);
    }
    return Future.value(_value as T)
        .timeout(timeLimit, onTimeout: onTimeout);
  }
}

/// 완전 Fake 기반 Supabase 클라이언트
///
/// Mockito의 when/thenReturn 없이 Supabase 쿼리 체인을 테스트합니다.
/// PostgrestTransformBuilder가 Future를 implement하는 문제를 우회합니다.
///
/// 사용 예:
/// ```dart
/// final client = FakeSupabaseClient();
/// client.setTable('config', (query) {
///   query.setSelectResult('value', (filter) {
///     filter.singleResult = {'value': 'test'};
///   });
/// });
///
/// final service = ConfigService(client);
/// final result = await service.getConfig('test_key'); // 'test'
/// ```
class FakeSupabaseClient extends Fake implements SupabaseClient {
  final Map<String, FakeSupabaseQueryBuilder> _tables = {};

  void setTable(
      String table, void Function(FakeSupabaseQueryBuilder) configure) {
    final queryBuilder = FakeSupabaseQueryBuilder();
    configure(queryBuilder);
    _tables[table] = queryBuilder;
  }

  @override
  SupabaseQueryBuilder from(String table) {
    return _tables[table] ??
        (throw StateError('No table setup for "$table"'));
  }
}

class FakeSupabaseQueryBuilder extends Fake implements SupabaseQueryBuilder {
  final Map<String, FakeFilterBuilder> _selectResults = {};

  void setSelectResult(
      String columns, void Function(FakeFilterBuilder) configure) {
    final filter = FakeFilterBuilder();
    configure(filter);
    _selectResults[columns] = filter;
  }

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> select(
      [String columns = '*']) {
    return _selectResults[columns] ??
        (throw StateError('No select setup for "$columns"'));
  }
}

class FakeFilterBuilder extends Fake
    implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {
  Map<String, dynamic>? singleResult;
  Object? singleError;

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> eq(
      String column, Object value) {
    return this;
  }

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> or(String filter,
      {String? referencedTable}) {
    return this;
  }

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> order(String column,
      {bool ascending = false,
      bool nullsFirst = false,
      String? referencedTable}) {
    return this;
  }

  @override
  PostgrestTransformBuilder<Map<String, dynamic>?> maybeSingle() {
    if (singleError != null) {
      return FakePostgrestTransformBuilder.error(singleError!);
    }
    return FakePostgrestTransformBuilder(singleResult);
  }
}

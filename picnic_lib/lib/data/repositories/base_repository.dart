import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/data/repositories/error_handler.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Repository 기본 인터페이스
/// 모든 Repository는 이 인터페이스를 구현해야 합니다.
abstract class BaseRepository {
  SupabaseClient get supabase => Supabase.instance.client;

  /// Check if user is authenticated
  bool isAuthenticated() {
    return supabase.auth.currentUser != null;
  }

  /// Get current user ID
  String? getCurrentUserId() {
    return supabase.auth.currentUser?.id;
  }

  /// Check network connectivity
  Future<bool> isNetworkAvailable() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      logger.w('Could not check network connectivity: $e');
      return true; // Assume network is available if check fails
    }
  }

  /// Enhanced query execution with better error handling
  Future<T> executeQuery<T>(
    Future<T> Function() query,
    String operation, {
    bool requiresAuth = false,
    int maxRetries = 2,
    Duration retryDelay = const Duration(seconds: 1),
  }) async {
    // Check authentication if required
    if (requiresAuth && !isAuthenticated()) {
      throw RepositoryException(
        'Authentication required for $operation',
        type: RepositoryErrorType.authentication,
        userMessage: 'Please log in to continue.',
      );
    }

    // Check network connectivity
    if (!await isNetworkAvailable()) {
      throw RepositoryException(
        'No network connection for $operation',
        type: RepositoryErrorType.network,
        userMessage: 'No internet connection. Please check your network and try again.',
      );
    }

    int attempt = 0;
    while (attempt <= maxRetries) {
      try {
        logger.d('Executing $operation (attempt ${attempt + 1}/${maxRetries + 1})');
        
        final result = await query();
        
        if (attempt > 0) {
          logger.i('$operation succeeded after ${attempt + 1} attempts');
        }
        
        return result;
      } catch (e, stackTrace) {
        final repositoryError = RepositoryErrorHandler.handleError(e, stackTrace);
        
        // Don't retry if it's not a retryable error
        if (!repositoryError.isRetryable || attempt >= maxRetries) {
          logger.e('$operation failed permanently', error: e, stackTrace: stackTrace);
          throw RepositoryException.fromError(repositoryError);
        }

        // Log retry attempt
        logger.w('$operation failed (attempt ${attempt + 1}), retrying in ${retryDelay.inSeconds}s: ${repositoryError.message}');
        
        attempt++;
        if (attempt <= maxRetries) {
          await Future.delayed(retryDelay * attempt); // Exponential backoff
        }
      }
    }

    // This should never be reached, but just in case
    throw RepositoryException(
      'Maximum retries exceeded for $operation',
      type: RepositoryErrorType.unknown,
    );
  }

  /// Helper method for parsing response safely
  Map<String, dynamic> parseResponse(dynamic response, String operation) {
    try {
      if (response == null) {
        throw RepositoryException(
          'Null response received for $operation',
          type: RepositoryErrorType.unknown,
          userMessage: 'No data received. Please try again.',
        );
      }

      if (response is Map<String, dynamic>) {
        return response;
      }

      if (response is String) {
        // Try to parse as JSON if it's a string
        try {
          final parsed = jsonDecode(response);
          if (parsed is Map<String, dynamic>) {
            return parsed;
          }
        } catch (e) {
          // Not valid JSON, treat as string response
        }
      }

      throw RepositoryException(
        'Invalid response format for $operation: ${response.runtimeType}',
        type: RepositoryErrorType.unknown,
        userMessage: 'Invalid data format received. Please try again.',
      );
    } catch (e) {
      if (e is RepositoryException) rethrow;
      
      throw RepositoryException(
        'Failed to parse response for $operation: $e',
        type: RepositoryErrorType.unknown,
        originalError: e,
      );
    }
  }

  /// Helper method for handling auth-related operations
  T requireAuth<T>(T Function() operation, [String? operationName]) {
    if (!isAuthenticated()) {
      throw RepositoryException(
        'Authentication required${operationName != null ? ' for $operationName' : ''}',
        type: RepositoryErrorType.authentication,
        userMessage: 'Please log in to continue.',
      );
    }
    return operation();
  }

  /// Helper method for validating input parameters
  void validateRequired(Map<String, dynamic?> params, String operation) {
    final missingParams = <String>[];
    
    params.forEach((key, value) {
      if (value == null || (value is String && value.isEmpty)) {
        missingParams.add(key);
      }
    });

    if (missingParams.isNotEmpty) {
      throw RepositoryException(
        'Missing required parameters for $operation: ${missingParams.join(', ')}',
        type: RepositoryErrorType.validation,
        userMessage: 'Please provide all required information.',
        details: {'missingParams': missingParams},
      );
    }
  }

  /// Helper method for handling pagination
  Map<String, String> buildPaginationParams({
    int? limit,
    int? offset,
    String? orderBy,
    bool ascending = true,
  }) {
    final params = <String, String>{};
    
    if (limit != null) {
      if (limit <= 0 || limit > 1000) {
        throw RepositoryException(
          'Invalid limit: $limit. Must be between 1 and 1000.',
          type: RepositoryErrorType.validation,
          userMessage: 'Invalid page size requested.',
        );
      }
      params['limit'] = limit.toString();
    }
    
    if (offset != null) {
      if (offset < 0) {
        throw RepositoryException(
          'Invalid offset: $offset. Must be >= 0.',
          type: RepositoryErrorType.validation,
          userMessage: 'Invalid page offset.',
        );
      }
      params['offset'] = offset.toString();
    }
    
    if (orderBy != null) {
      params['order'] = '$orderBy.${ascending ? 'asc' : 'desc'}';
    }
    
    return params;
  }

  /// Helper method for safe type casting
  T? safeCast<T>(dynamic value, String fieldName, [String? operation]) {
    if (value == null) return null;
    
    try {
      return value as T;
    } catch (e) {
      throw RepositoryException(
        'Type casting failed for field "$fieldName"${operation != null ? ' in $operation' : ''}: expected ${T.toString()}, got ${value.runtimeType}',
        type: RepositoryErrorType.validation,
        userMessage: 'Invalid data format received.',
        originalError: e,
      );
    }
  }

  /// Clean up resources (override in subclasses if needed)
  void dispose() {
    // Base implementation does nothing
    logger.d('Disposing ${runtimeType}');
  }
}

/// Repository별 에러 클래스
class RepositoryException implements Exception {
  final String operation;
  final String repository;
  final Exception originalError;
  final RepositoryErrorType type;
  final String? userMessage;
  final Map<String, dynamic>? details;

  RepositoryException({
    required this.operation,
    required this.repository,
    required this.originalError,
    required this.type,
    this.userMessage,
    this.details,
  });

  RepositoryException.fromError(RepositoryErrorHandler errorHandler)
      : operation = errorHandler.operation,
        repository = errorHandler.repository,
        originalError = errorHandler.originalError,
        type = errorHandler.type,
        userMessage = errorHandler.userMessage,
        details = errorHandler.details;

  @override
  String toString() {
    return 'RepositoryException in $repository during $operation: $originalError';
  }
}

/// CRUD 작업을 위한 기본 Repository 인터페이스
abstract class CrudRepository<T, ID> extends BaseRepository {
  /// 테이블 이름
  String get tableName;

  /// JSON에서 모델로 변환
  T fromJson(Map<String, dynamic> json);

  /// 모델에서 JSON으로 변환
  Map<String, dynamic> toJson(T model);

  /// 모델에서 ID 추출
  ID getId(T model);

  /// 단일 항목 조회
  Future<T?> findById(ID id);

  /// 모든 항목 조회
  Future<List<T>> findAll({
    String? orderBy,
    bool ascending = true,
    int? limit,
  });

  /// 조건부 조회
  Future<List<T>> findWhere(
    String column,
    dynamic value, {
    String? orderBy,
    bool ascending = true,
    int? limit,
  });

  /// 항목 생성
  Future<T> create(T model);

  /// 항목 업데이트
  Future<T> update(ID id, Map<String, dynamic> data);

  /// 항목 삭제
  Future<bool> delete(ID id);

  /// 페이지네이션 조회
  Future<List<T>> findWithPagination({
    int page = 0,
    int pageSize = 10,
    String? orderBy,
    bool ascending = true,
    String? searchColumn,
    String? searchValue,
  });
}

/// 기본 CRUD Repository 구현
abstract class BaseCrudRepository<T, ID> extends CrudRepository<T, ID> {
  @override
  Future<T?> findById(ID id) async {
    validateRequired({'id': id}, 'findById');
    
    return executeQuery(
      () async {
        final response = await supabase
            .from(tableName)
            .select('*')
            .eq('id', id)
            .maybeSingle();
            
        return response != null ? fromJson(response) : null;
      },
      'findById($id)',
    );
  }

  @override
  Future<List<T>> findAll({
    String? orderBy,
    bool ascending = true,
    int? limit,
  }) async {
    return executeQuery(
      () async {
        var query = supabase.from(tableName).select('*');
        
        if (orderBy != null) {
          query = query.order(orderBy, ascending: ascending);
        }
        
        if (limit != null) {
          query = query.limit(limit);
        }
        
        final response = await query;
        return (response as List).map((item) => fromJson(item)).toList();
      },
      'findAll',
    );
  }

  @override
  Future<List<T>> findWhere(
    String column,
    dynamic value, {
    String? orderBy,
    bool ascending = true,
    int? limit,
  }) async {
    try {
      var query = supabase.from(tableName).select().eq(column, value);
      
      if (orderBy != null) {
        query = query.order(orderBy, ascending: ascending);
      }
      
      if (limit != null) {
        query = query.limit(limit);
      }

      final response = await query;
      return handleListResponse(response, fromJson);
    } catch (e) {
      return handleError('findWhere', Exception(e), <T>[]);
    }
  }

  @override
  Future<T> create(T model) async {
    validateRequired({'model': model}, 'create');
    
    return executeQuery(
      () async {
        final data = toJson(model);
        final response = await supabase
            .from(tableName)
            .insert(data)
            .select()
            .single();
            
        return fromJson(response);
      },
      'create',
      requiresAuth: true,
    );
  }

  @override
  Future<T> update(ID id, Map<String, dynamic> data) async {
    validateRequired({'id': id, 'data': data}, 'update');
    
    return executeQuery(
      () async {
        final response = await supabase
            .from(tableName)
            .update(data)
            .eq('id', id)
            .select()
            .single();
            
        return fromJson(response);
      },
      'update($id)',
      requiresAuth: true,
    );
  }

  @override
  Future<bool> delete(ID id) async {
    validateRequired({'id': id}, 'delete');
    
    return executeQuery(
      () async {
        await supabase
            .from(tableName)
            .delete()
            .eq('id', id);
        return true;
      },
      'delete($id)',
      requiresAuth: true,
    );
  }

  @override
  Future<List<T>> findWithPagination({
    int page = 0,
    int pageSize = 10,
    String? orderBy,
    bool ascending = true,
    String? searchColumn,
    String? searchValue,
  }) async {
    try {
      final from = page * pageSize;
      final to = from + pageSize - 1;

      var query = supabase.from(tableName).select();
      
      if (searchColumn != null && searchValue != null) {
        query = query.ilike(searchColumn, '%$searchValue%');
      }
      
      if (orderBy != null) {
        query = query.order(orderBy, ascending: ascending);
      }
      
      query = query.range(from, to);
      
      final response = await query;
      return handleListResponse(response, fromJson);
    } catch (e) {
      return handleError('findWithPagination', Exception(e), <T>[]);
    }
  }
}
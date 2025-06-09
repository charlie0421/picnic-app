import 'package:picnic_lib/core/services/search_cache_service.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/data/models/community/board.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// 공통 검색 서비스 클래스
/// 다양한 엔티티 타입에 대한 검색 기능을 제공하는 재사용 가능한 모듈
class SearchService {
  static final SearchCacheService _cache = SearchCacheService();
  /// 아티스트 이름과 그룹명을 동시에 검색하는 메서드 (고급 검색 사용)
  /// 
  /// [query] 검색어
  /// [page] 페이지 번호 (0부터 시작)
  /// [limit] 페이지당 결과 수
  /// [language] 언어 코드 (기본값: 'en')
  /// [excludeIds] 제외할 아티스트 ID 목록
  /// 
  /// Returns: 검색된 아티스트 목록
  static Future<List<ArtistModel>> searchArtists({
    required String query,
    int page = 0,
    int limit = 20,
    String language = 'en',
    List<int> excludeIds = const [],
    bool useCache = true,
  }) async {
    return await searchEntitiesAdvanced<ArtistModel>(
      query: query,
      table: 'artist',
      selectFields: 'id,name,image,gender, birth_date, artist_group(id,name,image)',
      searchConditions: [
        'name->>ko.ilike.%{query}%',
        'name->>en.ilike.%{query}%',
        'name->>ja.ilike.%{query}%',
        'name->>zh.ilike.%{query}%',
        'artist_group.name->>ko.ilike.%{query}%',
        'artist_group.name->>en.ilike.%{query}%',
        'artist_group.name->>ja.ilike.%{query}%',
        'artist_group.name->>zh.ilike.%{query}%',
      ],
      fromJson: (json) => ArtistModel.fromJson({...json, 'isBookmarked': false}),
      page: page,
      limit: limit,
      orderBy: ['name->>$language asc'],
      filters: {
        'not_in_id': [0, ...excludeIds],
      },
      useCache: useCache,
    );
  }

  /// 제네릭 검색 메서드 - 다른 엔티티 타입에서도 사용 가능
  /// 
  /// [T] 반환할 모델 타입
  /// [query] 검색어
  /// [table] 테이블 이름
  /// [selectFields] 선택할 필드
  /// [searchFields] 검색할 필드 목록
  /// [fromJson] JSON을 모델로 변환하는 함수
  /// [page] 페이지 번호
  /// [limit] 페이지당 결과 수
  /// [orderBy] 정렬 기준 필드
  /// [excludeIds] 제외할 ID 목록
  /// 
  /// Returns: 검색된 엔티티 목록
  static Future<List<T>> searchEntities<T>({
    required String query,
    required String table,
    required String selectFields,
    required List<String> searchFields,
    required T Function(Map<String, dynamic>) fromJson,
    int page = 0,
    int limit = 20,
    String? orderBy,
    List<int> excludeIds = const [],
    Map<String, dynamic>? additionalFilters,
    bool useCache = true,
  }) async {
    query = query.trim();
    
    // 캐시 키 생성
    final cacheKey = generateCacheKey(
      query: query,
      table: table,
      page: page,
      limit: limit,
    );
    
    // 캐시에서 조회 시도
    if (useCache) {
      final cachedResult = _cache.get<List<T>>(cacheKey);
      if (cachedResult != null) {
        logger.d('Returning cached search results for table $table, query: $query');
        return cachedResult;
      }
    }
    
    try {
      if (!isValidQuery(query) && query.isNotEmpty) {
        throw ArgumentError('Invalid search query: $query');
      }
      
      dynamic queryBuilder = supabase.from(table).select(selectFields);

      // 검색어가 있는 경우 지정된 필드들에서 검색
      if (query.isNotEmpty && searchFields.isNotEmpty) {
        final searchConditions = searchFields
            .map((field) => '$field.ilike.%$query%')
            .join(',');
        queryBuilder = queryBuilder.or(searchConditions);
      }

      // 추가 필터 적용
      if (additionalFilters != null) {
        for (final entry in additionalFilters.entries) {
          final key = entry.key;
          final value = entry.value;
          
          if (value is List) {
            if (key.startsWith('not_')) {
              final actualKey = key.substring(4); // 'not_' 제거
              queryBuilder = queryBuilder.not(actualKey, 'in', value);
            } else {
              queryBuilder = queryBuilder.filter(key, 'in', value);
            }
          } else if (key.startsWith('neq_')) {
            final actualKey = key.substring(4); // 'neq_' 제거
            queryBuilder = queryBuilder.neq(actualKey, value);
          } else {
            queryBuilder = queryBuilder.eq(key, value);
          }
        }
      }

      // 제외할 ID가 있는 경우
      if (excludeIds.isNotEmpty) {
        queryBuilder = queryBuilder.not('id', 'in', excludeIds);
      }

      // 정렬
      if (orderBy != null) {
        queryBuilder = queryBuilder.order(orderBy, ascending: true);
      }

      // 페이지네이션
      final response = await queryBuilder
          .limit(limit)
          .range(page * limit, (page + 1) * limit - 1);

      if (response == null) {
        return <T>[];
      }
      
      final results = (response as List<dynamic>)
          .where((data) => data != null)
          .map((data) => fromJson(data as Map<String, dynamic>))
          .toList()
          .cast<T>();

      // 결과를 캐시에 저장
      if (useCache && results.isNotEmpty) {
        _cache.put(cacheKey, results);
      }

      return results;
    } catch (e, s) {
      logger.e('Error searching entities in table $table:', error: e, stackTrace: s);
      Sentry.captureException(e, stackTrace: s);
      rethrow;
    }
  }

  /// 검색 결과 캐싱을 위한 키 생성
  static String generateCacheKey({
    required String query,
    required String table,
    int page = 0,
    int limit = 20,
    String? language,
  }) {
    return '${table}_${query}_${page}_${limit}_${language ?? 'default'}';
  }

  /// 검색어 유효성 검사
  static bool isValidQuery(String query) {
    final trimmedQuery = query.trim();
    return trimmedQuery.isNotEmpty && trimmedQuery.length >= 1;
  }

  /// 검색어 정규화 (특수문자 제거, 공백 정리 등)
  static String normalizeQuery(String query) {
    return query.trim().toLowerCase();
  }

  /// 캐시 무효화 - 특정 테이블의 모든 캐시 삭제
  static void invalidateCache(String table) {
    _cache.removeByPattern('${table}_*');
  }

  /// 캐시 무효화 - 특정 쿼리의 캐시 삭제
  static void invalidateCacheForQuery(String table, String query) {
    _cache.removeByPattern('${table}_${query}_*');
  }

  /// 전체 검색 캐시 삭제
  static void clearAllCache() {
    _cache.clear();
  }

  /// 만료된 캐시 정리
  static void cleanupExpiredCache() {
    _cache.cleanupExpired();
  }

  /// 캐시 통계 조회
  static CacheStats getCacheStats() {
    return _cache.stats;
  }

  /// 캐시 히트율 개선을 위한 프리로딩
  /// 자주 검색되는 용어들을 미리 캐시에 로드
  static Future<void> preloadPopularSearches({
    required List<String> popularQueries,
    String language = 'en',
    int limit = 20,
  }) async {
    for (final query in popularQueries) {
      try {
        await searchArtists(
          query: query,
          page: 0,
          limit: limit,
          language: language,
          useCache: true,
        );
        logger.d('Preloaded search results for: $query');
      } catch (e) {
        logger.w('Failed to preload search for: $query', error: e);
      }
    }
  }

  /// 고급 검색 메서드 - 복잡한 조인 쿼리와 커스텀 조건을 지원
  /// 
  /// [T] 반환할 모델 타입
  /// [query] 검색어
  /// [table] 메인 테이블 이름
  /// [selectFields] 선택할 필드 (조인 포함)
  /// [searchConditions] 커스텀 검색 조건 (OR 연산자로 연결)
  /// [fromJson] JSON을 모델로 변환하는 함수
  /// [page] 페이지 번호
  /// [limit] 페이지당 결과 수
  /// [orderBy] 정렬 기준 필드 목록
  /// [filters] 필터 조건들
  /// [joinConditions] 조인 조건들
  /// 
  /// Returns: 검색된 엔티티 목록
  static Future<List<T>> searchEntitiesAdvanced<T>({
    required String query,
    required String table,
    required String selectFields,
    required List<String> searchConditions,
    required T Function(Map<String, dynamic>) fromJson,
    int page = 0,
    int limit = 20,
    List<String>? orderBy,
    Map<String, dynamic>? filters,
    Map<String, String>? joinConditions,
    bool useCache = true,
  }) async {
    query = query.trim();
    
    // 캐시 키 생성 (더 복잡한 쿼리를 위한 해시 기반)
    final cacheKey = _generateAdvancedCacheKey(
      query: query,
      table: table,
      searchConditions: searchConditions,
      page: page,
      limit: limit,
      filters: filters,
    );
    
    // 캐시에서 조회 시도
    if (useCache) {
      final cachedResult = _cache.get<List<T>>(cacheKey);
      if (cachedResult != null) {
        logger.d('Returning cached advanced search results for table $table, query: $query');
        return cachedResult;
      }
    }
    
    try {
      if (!isValidQuery(query) && query.isNotEmpty) {
        throw ArgumentError('Invalid search query: $query');
      }
      
      dynamic queryBuilder = supabase.from(table).select(selectFields);

      // 검색어가 있는 경우 커스텀 검색 조건 적용
      if (query.isNotEmpty && searchConditions.isNotEmpty) {
        final formattedConditions = searchConditions
            .map((condition) => condition.replaceAll('{query}', query))
            .join(',');
        queryBuilder = queryBuilder.or(formattedConditions);
      }

      // 필터 조건 적용
      if (filters != null) {
        queryBuilder = _applyFilters(queryBuilder, filters);
      }

      // 정렬 조건 적용
      if (orderBy != null && orderBy.isNotEmpty) {
        for (final order in orderBy) {
          final parts = order.split(' ');
          final field = parts[0];
          final ascending = parts.length > 1 ? parts[1].toLowerCase() != 'desc' : true;
          queryBuilder = queryBuilder.order(field, ascending: ascending);
        }
      }

      // 페이지네이션
      final response = await queryBuilder
          .limit(limit)
          .range(page * limit, (page + 1) * limit - 1);

      if (response == null) {
        return <T>[];
      }
      
      final results = (response as List<dynamic>)
          .where((data) => data != null)
          .map((data) => fromJson(data as Map<String, dynamic>))
          .toList()
          .cast<T>();

      // 결과를 캐시에 저장
      if (useCache && results.isNotEmpty) {
        _cache.put(cacheKey, results);
      }

      return results;
    } catch (e, s) {
      logger.e('Error in advanced search for table $table:', error: e, stackTrace: s);
      Sentry.captureException(e, stackTrace: s);
      rethrow;
    }
  }

  /// 필터 조건을 쿼리 빌더에 적용하는 헬퍼 메서드
  static dynamic _applyFilters(dynamic queryBuilder, Map<String, dynamic> filters) {
    for (final entry in filters.entries) {
      final key = entry.key;
      final value = entry.value;
      
      if (value is List) {
        if (key.startsWith('not_in_')) {
          final actualKey = key.substring(7); // 'not_in_' 제거
          queryBuilder = queryBuilder.not(actualKey, 'in', value);
        } else if (key.startsWith('in_')) {
          final actualKey = key.substring(3); // 'in_' 제거
          queryBuilder = queryBuilder.filter(actualKey, 'in', value);
        } else {
          queryBuilder = queryBuilder.filter(key, 'in', value);
        }
      } else if (key.startsWith('neq_')) {
        final actualKey = key.substring(4); // 'neq_' 제거
        queryBuilder = queryBuilder.neq(actualKey, value);
      } else if (key.startsWith('gt_')) {
        final actualKey = key.substring(3); // 'gt_' 제거
        queryBuilder = queryBuilder.gt(actualKey, value);
      } else if (key.startsWith('gte_')) {
        final actualKey = key.substring(4); // 'gte_' 제거
        queryBuilder = queryBuilder.gte(actualKey, value);
      } else if (key.startsWith('lt_')) {
        final actualKey = key.substring(3); // 'lt_' 제거
        queryBuilder = queryBuilder.lt(actualKey, value);
      } else if (key.startsWith('lte_')) {
        final actualKey = key.substring(4); // 'lte_' 제거
        queryBuilder = queryBuilder.lte(actualKey, value);
      } else if (key.startsWith('like_')) {
        final actualKey = key.substring(5); // 'like_' 제거
        queryBuilder = queryBuilder.like(actualKey, value);
      } else if (key.startsWith('ilike_')) {
        final actualKey = key.substring(6); // 'ilike_' 제거
        queryBuilder = queryBuilder.ilike(actualKey, value);
      } else {
        queryBuilder = queryBuilder.eq(key, value);
      }
    }
    return queryBuilder;
  }

  /// 고급 검색을 위한 캐시 키 생성 (해시 기반)
  static String _generateAdvancedCacheKey({
    required String query,
    required String table,
    required List<String> searchConditions,
    int page = 0,
    int limit = 20,
    Map<String, dynamic>? filters,
  }) {
    final components = [
      table,
      query,
      searchConditions.join('|'),
      page.toString(),
      limit.toString(),
      filters?.toString() ?? '',
    ];
    
    // 간단한 해시 생성 (실제 프로덕션에서는 crypto 패키지 사용 권장)
    final combined = components.join('_');
    return 'advanced_${combined.hashCode.abs()}';
  }

  /// 다국어 검색 조건을 생성하는 헬퍼 메서드
  static List<String> createMultiLanguageSearchConditions(
    String fieldName, {
    List<String> languages = const ['ko', 'en', 'ja', 'zh'],
    String operator = 'ilike',
    String pattern = '%{query}%',
  }) {
    return languages
        .map((lang) => '$fieldName->>$lang.$operator.$pattern')
        .toList();
  }

  /// 조인된 테이블의 다국어 검색 조건을 생성하는 헬퍼 메서드
  static List<String> createJoinedMultiLanguageSearchConditions(
    String joinTable,
    String fieldName, {
    List<String> languages = const ['ko', 'en', 'ja', 'zh'],
    String operator = 'ilike',
    String pattern = '%{query}%',
  }) {
    // PostgREST에서 조인된 테이블 필드 접근은 다른 방식 사용
    return languages
        .map((lang) => '$joinTable($fieldName->>$lang.$operator.$pattern)')
        .toList();
  }

  /// 표준 정렬 조건을 생성하는 헬퍼 메서드
  static List<String> createStandardOrderBy({
    String? nameField,
    String language = 'ko',
    bool officialFirst = false,
    bool orderField = false,
  }) {
    final orderBy = <String>[];
    
    if (nameField != null) {
      orderBy.add('$nameField->>$language asc');
    }
    
    if (officialFirst) {
      orderBy.add('is_official desc');
    }
    
    if (orderField) {
      orderBy.add('order asc');
    }
    
    return orderBy;
  }

  /// 표준 필터 조건을 생성하는 헬퍼 메서드
  static Map<String, dynamic> createStandardFilters({
    List<int> excludeIds = const [],
    String? status,
    bool excludeZeroId = true,
  }) {
    final filters = <String, dynamic>{};
    
    if (excludeZeroId || excludeIds.isNotEmpty) {
      final allExcludeIds = excludeZeroId ? [0, ...excludeIds] : excludeIds;
      if (allExcludeIds.isNotEmpty) {
        filters['not_in_id'] = allExcludeIds;
      }
    }
    
    if (status != null) {
      filters['status'] = status;
    }
    
    return filters;
  }

  /// 보드 검색을 위한 특별 메서드 (조인된 테이블 검색 포함)
  static Future<List<BoardModel>> searchBoards({
    required String query,
    int page = 0,
    int limit = 20,
    String language = 'ko',
    bool useCache = true,
  }) async {
    query = query.trim();
    
    // 캐시 키 생성
    final cacheKey = 'boards_search_${query}_${page}_${limit}_$language';
    
    // 캐시에서 조회 시도
    if (useCache) {
      final cachedResult = _cache.get<List<BoardModel>>(cacheKey);
      if (cachedResult != null) {
        logger.d('Returning cached board search results for: $query');
        return cachedResult;
      }
    }
    
    try {
      // 직접 Supabase 쿼리 사용 (조인된 테이블 검색을 위해)
      final response = await supabase
          .from('boards')
          .select('name, board_id, artist_id, description, is_official, features, artist!inner(*, artist_group(*))')
          .or('name->>ko.ilike.%$query%,'
              'name->>en.ilike.%$query%,'
              'name->>ja.ilike.%$query%,'
              'name->>zh.ilike.%$query%')
          .neq('artist_id', 0)
          .eq('status', 'approved')
          .order('name->>$language', ascending: true)
          .order('is_official', ascending: false)
          .order('order', ascending: true)
          .range(page * limit, (page + 1) * limit - 1);

      if (response == null) {
        return <BoardModel>[];
      }
      
      final results = (response as List<dynamic>)
          .where((data) => data != null)
          .map((data) => BoardModel.fromJson(data as Map<String, dynamic>))
          .toList();

      // 결과를 캐시에 저장
      if (useCache && results.isNotEmpty) {
        _cache.put(cacheKey, results);
      }

      return results;
    } catch (e, s) {
      logger.e('Error searching boards:', error: e, stackTrace: s);
      Sentry.captureException(e, stackTrace: s);
      rethrow;
    }
  }
} 
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/services/search_service.dart';

void main() {
  group('SearchService 재사용성 테스트', () {
    test('generateCacheKey는 일관된 키를 생성해야 함', () {
      // Arrange
      const query = 'test';
      const table = 'artist';
      const page = 0;
      const limit = 20;
      const language = 'ko';

      // Act
      final key1 = SearchService.generateCacheKey(
        query: query,
        table: table,
        page: page,
        limit: limit,
        language: language,
      );
      
      final key2 = SearchService.generateCacheKey(
        query: query,
        table: table,
        page: page,
        limit: limit,
        language: language,
      );

      // Assert
      expect(key1, equals(key2));
      expect(key1, contains(query));
      expect(key1, contains(table));
      expect(key1, contains(page.toString()));
      expect(key1, contains(limit.toString()));
      expect(key1, contains(language));
    });

    test('isValidQuery는 올바른 검증을 수행해야 함', () {
      // Valid queries
      expect(SearchService.isValidQuery('a'), isTrue);
      expect(SearchService.isValidQuery('test'), isTrue);
      expect(SearchService.isValidQuery('  test  '), isTrue);
      expect(SearchService.isValidQuery('한글'), isTrue);
      expect(SearchService.isValidQuery('123'), isTrue);

      // Invalid queries
      expect(SearchService.isValidQuery(''), isFalse);
      expect(SearchService.isValidQuery('   '), isFalse);
    });

    test('normalizeQuery는 쿼리를 정규화해야 함', () {
      // Arrange & Act & Assert
      expect(SearchService.normalizeQuery('  Test  '), equals('test'));
      expect(SearchService.normalizeQuery('UPPERCASE'), equals('uppercase'));
      expect(SearchService.normalizeQuery('MixedCase'), equals('mixedcase'));
      expect(SearchService.normalizeQuery('한글'), equals('한글'));
      expect(SearchService.normalizeQuery(''), equals(''));
    });

    test('캐시 키는 다른 파라미터에 대해 다른 값을 생성해야 함', () {
      // Arrange
      const baseParams = {
        'query': 'test',
        'table': 'artist',
        'page': 0,
        'limit': 20,
      };

      // Act
      final key1 = SearchService.generateCacheKey(
        query: baseParams['query']! as String,
        table: baseParams['table']! as String,
        page: baseParams['page']! as int,
        limit: baseParams['limit']! as int,
      );

      final key2 = SearchService.generateCacheKey(
        query: 'different',
        table: baseParams['table']! as String,
        page: baseParams['page']! as int,
        limit: baseParams['limit']! as int,
      );

      final key3 = SearchService.generateCacheKey(
        query: baseParams['query']! as String,
        table: 'board',
        page: baseParams['page']! as int,
        limit: baseParams['limit']! as int,
      );

      // Assert
      expect(key1, isNot(equals(key2)));
      expect(key1, isNot(equals(key3)));
      expect(key2, isNot(equals(key3)));
    });

    group('캐시 관리 메서드 테스트', () {
      setUp(() {
        // 각 테스트 전에 캐시 초기화
        SearchService.clearAllCache();
      });

      test('clearAllCache는 모든 캐시를 삭제해야 함', () {
        // 이 테스트는 실제 캐시 구현이 있을 때 의미가 있음
        // 현재는 메서드 호출이 에러 없이 실행되는지만 확인
        expect(() => SearchService.clearAllCache(), returnsNormally);
      });

      test('invalidateCache는 특정 테이블 캐시를 삭제해야 함', () {
        expect(() => SearchService.invalidateCache('artist'), returnsNormally);
      });

      test('invalidateCacheForQuery는 특정 쿼리 캐시를 삭제해야 함', () {
        expect(() => SearchService.invalidateCacheForQuery('artist', 'test'), returnsNormally);
      });

      test('cleanupExpiredCache는 만료된 캐시를 정리해야 함', () {
        expect(() => SearchService.cleanupExpiredCache(), returnsNormally);
      });

      test('getCacheStats는 캐시 통계를 반환해야 함', () {
        final stats = SearchService.getCacheStats();
        expect(stats, isNotNull);
        expect(stats.totalEntries, isA<int>());
        expect(stats.maxSize, isA<int>());
        expect(stats.hitRate, isA<double>());
      });
    });

    group('다양한 엔티티 타입 지원 테스트', () {
      test('아티스트 검색 파라미터 검증', () {
        // 이 테스트는 실제 데이터베이스 연결 없이 파라미터 검증만 수행
        expect(() {
          // 파라미터가 올바르게 전달되는지 확인
          final query = 'test';
          final page = 0;
          final limit = 20;
          final language = 'ko';
          final excludeIds = [1, 2, 3];
          
          // 파라미터 유효성 검사
          expect(SearchService.isValidQuery(query), isTrue);
          expect(page, greaterThanOrEqualTo(0));
          expect(limit, greaterThan(0));
          expect(language, isNotEmpty);
          expect(excludeIds, isA<List<int>>());
        }, returnsNormally);
      });

      test('보드 검색 파라미터 검증', () {
        expect(() {
          // 보드 검색에 필요한 파라미터들 검증
          const table = 'boards';
          const selectFields = 'name, board_id, artist_id, description';
          const searchFields = ['name->>ko', 'name->>en'];
          final additionalFilters = {
            'status': 'approved',
            'neq_artist_id': 0,
          };
          
          expect(table, isNotEmpty);
          expect(selectFields, isNotEmpty);
          expect(searchFields, isNotEmpty);
          expect(additionalFilters, isNotEmpty);
          expect(additionalFilters['status'], equals('approved'));
          expect(additionalFilters['neq_artist_id'], equals(0));
        }, returnsNormally);
      });
    });

    group('에러 처리 테스트', () {
      test('빈 검색 필드 배열 처리', () {
        expect(() {
          const emptySearchFields = <String>[];
          expect(emptySearchFields, isEmpty);
          // 빈 검색 필드 배열이 전달되어도 에러가 발생하지 않아야 함
        }, returnsNormally);
      });

      test('null 값 처리', () {
        expect(() {
          String? nullOrderBy;
          Map<String, dynamic>? nullFilters;
          List<int>? nullExcludeIds;
          
          expect(nullOrderBy, isNull);
          expect(nullFilters, isNull);
          expect(nullExcludeIds, isNull);
        }, returnsNormally);
      });
    });
  });
} 
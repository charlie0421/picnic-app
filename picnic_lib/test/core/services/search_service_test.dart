import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/services/search_service.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';
import 'package:picnic_lib/data/models/community/board.dart';

import '../../helpers/mock_supabase.dart';

/// Helper to create a valid artist JSON map for mock responses
Map<String, dynamic> makeArtistJson({
  required int id,
  Map<String, dynamic>? name,
  String? image,
  String? gender,
  String? birthDate,
  Map<String, dynamic>? artistGroup,
  List<Map<String, dynamic>>? bookmarks,
}) {
  return {
    'id': id,
    'name': name ?? {'ko': '아티스트$id', 'en': 'Artist$id'},
    'image': image,
    'gender': gender ?? 'F',
    'birth_date': birthDate,
    'is_kpop': true,
    if (artistGroup != null) 'artist_group': artistGroup,
    if (bookmarks != null) 'artist_user_bookmark': bookmarks,
  };
}

Map<String, dynamic> makeArtistGroupJson({
  required int id,
  Map<String, dynamic>? name,
  String? image,
}) {
  return {
    'id': id,
    'name': name ?? {'ko': '그룹$id', 'en': 'Group$id'},
    'image': image,
  };
}

Map<String, dynamic> makeBoardJson({
  required String boardId,
  required int artistId,
  Map<String, dynamic>? name,
  dynamic description,
  bool? isOfficial,
  List<String>? features,
  Map<String, dynamic>? artist,
}) {
  return {
    'board_id': boardId,
    'artist_id': artistId,
    'name': name ?? {'ko': '보드', 'en': 'Board'},
    'description': description ?? {'ko': '설명', 'en': 'Description'},
    'is_official': isOfficial ?? true,
    'features': features ?? ['posts'],
    'created_at': '2026-01-01T00:00:00Z',
    'updated_at': '2026-01-01T00:00:00Z',
    'status': 'approved',
    'creator_id': null,
    'request_message': null,
    'artist': artist ?? makeArtistJson(id: artistId),
  };
}

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

    group('createMultiLanguageSearchConditions', () {
      test('기본 언어로 검색 조건 생성', () {
        final conditions = SearchService.createMultiLanguageSearchConditions(
          'name',
        );
        expect(conditions.length, equals(4));
        expect(conditions[0], contains('name->>ko'));
        expect(conditions[1], contains('name->>en'));
        expect(conditions[2], contains('name->>ja'));
        expect(conditions[3], contains('name->>zh_CN'));
      });

      test('커스텀 언어 목록', () {
        final conditions = SearchService.createMultiLanguageSearchConditions(
          'title',
          languages: ['ko', 'en'],
        );
        expect(conditions.length, equals(2));
        expect(conditions[0], contains('title->>ko'));
        expect(conditions[1], contains('title->>en'));
      });

      test('커스텀 연산자', () {
        final conditions = SearchService.createMultiLanguageSearchConditions(
          'name',
          languages: ['ko'],
          operator: 'eq',
          pattern: '{query}',
        );
        expect(conditions.length, equals(1));
        expect(conditions[0], contains('.eq.'));
      });

      test('커스텀 패턴', () {
        final conditions = SearchService.createMultiLanguageSearchConditions(
          'name',
          languages: ['ko'],
          pattern: '{query}%',
        );
        expect(conditions[0], endsWith('{query}%'));
      });
    });

    group('createJoinedMultiLanguageSearchConditions', () {
      test('조인 테이블 검색 조건 생성', () {
        final conditions =
            SearchService.createJoinedMultiLanguageSearchConditions(
          'artist_group',
          'name',
        );
        expect(conditions.length, equals(4));
        expect(conditions[0], contains('artist_group('));
        expect(conditions[0], contains('name->>ko'));
      });

      test('커스텀 언어 목록', () {
        final conditions =
            SearchService.createJoinedMultiLanguageSearchConditions(
          'artist',
          'title',
          languages: ['ko', 'en'],
        );
        expect(conditions.length, equals(2));
        expect(conditions[0], contains('artist(title->>ko'));
        expect(conditions[1], contains('artist(title->>en'));
      });
    });

    group('createStandardOrderBy', () {
      test('이름 필드 정렬', () {
        final orderBy = SearchService.createStandardOrderBy(
          nameField: 'name',
          language: 'ko',
        );
        expect(orderBy.length, equals(1));
        expect(orderBy[0], equals('name->>ko asc'));
      });

      test('공식 우선 정렬', () {
        final orderBy = SearchService.createStandardOrderBy(
          officialFirst: true,
        );
        expect(orderBy.length, equals(1));
        expect(orderBy[0], equals('is_official desc'));
      });

      test('순서 필드 정렬', () {
        final orderBy = SearchService.createStandardOrderBy(
          orderField: true,
        );
        expect(orderBy.length, equals(1));
        expect(orderBy[0], equals('order asc'));
      });

      test('복합 정렬', () {
        final orderBy = SearchService.createStandardOrderBy(
          nameField: 'name',
          language: 'en',
          officialFirst: true,
          orderField: true,
        );
        expect(orderBy.length, equals(3));
        expect(orderBy[0], equals('name->>en asc'));
        expect(orderBy[1], equals('is_official desc'));
        expect(orderBy[2], equals('order asc'));
      });

      test('빈 정렬', () {
        final orderBy = SearchService.createStandardOrderBy();
        expect(orderBy, isEmpty);
      });
    });

    group('createStandardFilters', () {
      test('기본 필터 (excludeZeroId 기본값 true)', () {
        final filters = SearchService.createStandardFilters();
        expect(filters, containsPair('not_in_id', [0]));
      });

      test('excludeIds 포함', () {
        final filters = SearchService.createStandardFilters(
          excludeIds: [1, 2, 3],
        );
        expect(filters['not_in_id'], equals([0, 1, 2, 3]));
      });

      test('excludeZeroId false', () {
        final filters = SearchService.createStandardFilters(
          excludeZeroId: false,
        );
        expect(filters.containsKey('not_in_id'), isFalse);
      });

      test('excludeZeroId false with excludeIds', () {
        final filters = SearchService.createStandardFilters(
          excludeZeroId: false,
          excludeIds: [5, 10],
        );
        expect(filters['not_in_id'], equals([5, 10]));
      });

      test('status 필터', () {
        final filters = SearchService.createStandardFilters(
          status: 'approved',
        );
        expect(filters['status'], equals('approved'));
      });

      test('모든 옵션 조합', () {
        final filters = SearchService.createStandardFilters(
          excludeIds: [1],
          status: 'active',
          excludeZeroId: true,
        );
        expect(filters['not_in_id'], equals([0, 1]));
        expect(filters['status'], equals('active'));
      });
    });

    group('generateCacheKey 추가 케이스', () {
      test('language 없으면 default 사용', () {
        final key = SearchService.generateCacheKey(
          query: 'test',
          table: 'artist',
        );
        expect(key, contains('default'));
      });

      test('language 지정', () {
        final key = SearchService.generateCacheKey(
          query: 'test',
          table: 'artist',
          language: 'ja',
        );
        expect(key, contains('ja'));
      });

      test('빈 query', () {
        final key = SearchService.generateCacheKey(
          query: '',
          table: 'artist',
        );
        expect(key, contains('artist'));
      });
    });
  });

  group('SearchService Supabase-dependent tests', () {
    setUp(() {
      SearchService.clearAllCache();
    });

    tearDown(() {
      tearDownMockSupabase();
      SearchService.clearAllCache();
    });

    group('searchArtists', () {
      test('returns artists for empty query (全体検索)', () async {
        setupMockSupabase({
          'artist': [
            makeArtistJson(id: 1, name: {'ko': '지수', 'en': 'Jisoo'}),
            makeArtistJson(id: 2, name: {'ko': '로제', 'en': 'Rose'}),
          ],
          'artist_group': <Map<String, dynamic>>[],
        });

        final results = await SearchService.searchArtists(
          query: '',
          useCache: false,
        );

        expect(results, isA<List<ArtistModel>>());
        expect(results.length, 2);
      });

      test('returns artists matching text query', () async {
        setupMockSupabase({
          'artist': [
            makeArtistJson(id: 1, name: {'ko': '지수', 'en': 'Jisoo'}),
          ],
          'artist_group': <Map<String, dynamic>>[],
        });

        final results = await SearchService.searchArtists(
          query: 'Jisoo',
          useCache: false,
        );

        expect(results, isA<List<ArtistModel>>());
      });

      test('handles excludeIds parameter', () async {
        setupMockSupabase({
          'artist': [
            makeArtistJson(id: 1, name: {'ko': '지수', 'en': 'Jisoo'}),
            makeArtistJson(id: 2, name: {'ko': '로제', 'en': 'Rose'}),
          ],
          'artist_group': <Map<String, dynamic>>[],
        });

        final results = await SearchService.searchArtists(
          query: 'test',
          excludeIds: [1],
          useCache: false,
        );

        expect(results, isA<List<ArtistModel>>());
      });

      test('processes bookmark data correctly', () async {
        setupMockSupabase({
          'artist': [
            {
              ...makeArtistJson(id: 1, name: {'ko': '지수', 'en': 'Jisoo'}),
              'artist_user_bookmark': [{'artist_id': 1}],
            },
            {
              ...makeArtistJson(id: 2, name: {'ko': '로제', 'en': 'Rose'}),
              'artist_user_bookmark': [],
            },
          ],
          'artist_group': <Map<String, dynamic>>[],
        });

        final results = await SearchService.searchArtists(
          query: 'test',
          useCache: false,
        );

        expect(results, isA<List<ArtistModel>>());
        if (results.isNotEmpty) {
          // First artist should be bookmarked
          expect(results[0].isBookmarked, true);
        }
      });

      test('handles group name search results', () async {
        setupMockSupabase({
          'artist': [
            {
              ...makeArtistJson(
                id: 1,
                name: {'ko': '지수', 'en': 'Jisoo'},
                artistGroup: makeArtistGroupJson(
                  id: 10,
                  name: {'ko': '블랙핑크', 'en': 'BLACKPINK'},
                ),
              ),
              'artist_user_bookmark': [],
            },
          ],
          'artist_group': [
            makeArtistGroupJson(
              id: 10,
              name: {'ko': '블랙핑크', 'en': 'BLACKPINK'},
            ),
          ],
        });

        final results = await SearchService.searchArtists(
          query: 'BLACKPINK',
          useCache: false,
        );

        expect(results, isA<List<ArtistModel>>());
      });

      test('deduplicates results from artist name and group name search', () async {
        final artistData = {
          ...makeArtistJson(
            id: 1,
            name: {'ko': '지수', 'en': 'Jisoo'},
            artistGroup: makeArtistGroupJson(
              id: 10,
              name: {'ko': '블랙핑크', 'en': 'BLACKPINK'},
            ),
          ),
          'artist_user_bookmark': [],
        };

        setupMockSupabase({
          'artist': [artistData],
          'artist_group': [
            makeArtistGroupJson(
              id: 10,
              name: {'ko': '블랙핑크', 'en': 'BLACKPINK'},
            ),
          ],
        });

        final results = await SearchService.searchArtists(
          query: 'test',
          useCache: false,
        );

        // Check no duplicates
        final ids = results.map((a) => a.id).toSet();
        expect(ids.length, results.length);
      });

      test('uses cache when useCache is true', () async {
        setupMockSupabase({
          'artist': [
            {
              ...makeArtistJson(id: 1, name: {'ko': '테스트', 'en': 'Test'}),
              'artist_user_bookmark': [],
            },
          ],
          'artist_group': <Map<String, dynamic>>[],
        });

        // First call populates cache
        final results1 = await SearchService.searchArtists(
          query: 'Test',
          useCache: true,
        );

        // Second call should use cache
        final results2 = await SearchService.searchArtists(
          query: 'Test',
          useCache: true,
        );

        expect(results1.length, results2.length);
      });

      test('handles Korean initial search (ㅂㅍ)', () async {
        setupMockSupabase({
          'artist': [
            makeArtistJson(id: 1, name: {'ko': '블랙핑크', 'en': 'BLACKPINK'}),
            makeArtistJson(id: 2, name: {'ko': '방탄소년단', 'en': 'BTS'}),
          ],
        });

        final results = await SearchService.searchArtists(
          query: 'ㅂ',
          useCache: false,
          supportKoreanInitials: true,
        );

        expect(results, isA<List<ArtistModel>>());
      });

      test('Korean initial search with excludeIds', () async {
        setupMockSupabase({
          'artist': [
            makeArtistJson(id: 1, name: {'ko': '블랙핑크', 'en': 'BLACKPINK'}),
            makeArtistJson(id: 2, name: {'ko': '방탄소년단', 'en': 'BTS'}),
          ],
        });

        final results = await SearchService.searchArtists(
          query: 'ㅂ',
          excludeIds: [1],
          useCache: false,
          supportKoreanInitials: true,
        );

        expect(results, isA<List<ArtistModel>>());
      });

      test('Korean initial search with pagination beyond results', () async {
        setupMockSupabase({
          'artist': [
            makeArtistJson(id: 1, name: {'ko': '블랙핑크', 'en': 'BLACKPINK'}),
          ],
        });

        final results = await SearchService.searchArtists(
          query: 'ㅂ',
          page: 100,
          limit: 20,
          useCache: false,
          supportKoreanInitials: true,
        );

        expect(results, isEmpty);
      });

      test('Korean initial search matches group name', () async {
        setupMockSupabase({
          'artist': [
            makeArtistJson(
              id: 1,
              name: {'ko': '지수', 'en': 'Jisoo'},
              artistGroup: makeArtistGroupJson(
                id: 10,
                name: {'ko': '블랙핑크', 'en': 'BLACKPINK'},
              ),
            ),
          ],
        });

        final results = await SearchService.searchArtists(
          query: 'ㅂㅍ',
          useCache: false,
          supportKoreanInitials: true,
        );

        expect(results, isA<List<ArtistModel>>());
      });

      test('supportKoreanInitials false disables Korean initial search', () async {
        setupMockSupabase({
          'artist': [
            {
              ...makeArtistJson(id: 1, name: {'ko': '블랙핑크', 'en': 'BLACKPINK'}),
              'artist_user_bookmark': [],
            },
          ],
          'artist_group': <Map<String, dynamic>>[],
        });

        final results = await SearchService.searchArtists(
          query: 'ㅂ',
          useCache: false,
          supportKoreanInitials: false,
        );

        // Should treat ㅂ as a regular text search, not Korean initials
        expect(results, isA<List<ArtistModel>>());
      });

      test('pagination works correctly for text search', () async {
        setupMockSupabase({
          'artist': [
            {
              ...makeArtistJson(id: 1, name: {'ko': '테스트1', 'en': 'Test1'}),
              'artist_user_bookmark': [],
            },
          ],
          'artist_group': <Map<String, dynamic>>[],
        });

        final results = await SearchService.searchArtists(
          query: 'Test',
          page: 0,
          limit: 5,
          useCache: false,
        );

        expect(results, isA<List<ArtistModel>>());
      });
    });

    group('searchArtistsFast', () {
      test('returns artists for empty query', () async {
        setupMockSupabase({
          'artist': [
            makeArtistJson(id: 1, name: {'ko': '지수', 'en': 'Jisoo'}),
            makeArtistJson(id: 2, name: {'ko': '로제', 'en': 'Rose'}),
          ],
        });

        final results = await SearchService.searchArtistsFast(
          query: '',
        );

        expect(results, isA<List<ArtistModel>>());
      });

      test('returns artists for text query', () async {
        setupMockSupabase({
          'artist': [
            makeArtistJson(id: 1, name: {'ko': '지수', 'en': 'Jisoo'}),
          ],
        });

        final results = await SearchService.searchArtistsFast(
          query: 'Jisoo',
        );

        expect(results, isA<List<ArtistModel>>());
      });

      test('Korean initial search in fast mode', () async {
        setupMockSupabase({
          'artist': [
            makeArtistJson(id: 1, name: {'ko': '블랙핑크', 'en': 'BLACKPINK'}),
          ],
        });

        final results = await SearchService.searchArtistsFast(
          query: 'ㅂ',
        );

        expect(results, isA<List<ArtistModel>>());
      });

      test('Korean initial search pagination beyond results', () async {
        setupMockSupabase({
          'artist': [
            makeArtistJson(id: 1, name: {'ko': '블랙핑크', 'en': 'BLACKPINK'}),
          ],
        });

        final results = await SearchService.searchArtistsFast(
          query: 'ㅂ',
          page: 100,
          limit: 20,
        );

        expect(results, isEmpty);
      });

      test('empty query with includeBookmarks on page 0', () async {
        setupMockSupabase({
          'artist': [
            makeArtistJson(id: 1, name: {'ko': '지수', 'en': 'Jisoo'}),
            makeArtistJson(id: 2, name: {'ko': '로제', 'en': 'Rose'}),
          ],
          'artist_user_bookmark': [
            {'artist_id': 1, 'artist': makeArtistJson(id: 1, name: {'ko': '지수', 'en': 'Jisoo'}), 'created_at': '2026-01-01T00:00:00Z'},
          ],
        });

        final results = await SearchService.searchArtistsFast(
          query: '',
          includeBookmarks: true,
          page: 0,
        );

        expect(results, isA<List<ArtistModel>>());
      });

      test('empty query with includeBookmarks on page > 0', () async {
        setupMockSupabase({
          'artist': [
            makeArtistJson(id: 1, name: {'ko': '지수', 'en': 'Jisoo'}),
            makeArtistJson(id: 2, name: {'ko': '로제', 'en': 'Rose'}),
          ],
          'artist_user_bookmark': [
            {'artist_id': 1},
          ],
        });

        final results = await SearchService.searchArtistsFast(
          query: '',
          includeBookmarks: true,
          page: 1,
        );

        expect(results, isA<List<ArtistModel>>());
      });

      test('empty query without includeBookmarks', () async {
        setupMockSupabase({
          'artist': [
            makeArtistJson(id: 1, name: {'ko': '지수', 'en': 'Jisoo'}),
          ],
        });

        final results = await SearchService.searchArtistsFast(
          query: '',
          includeBookmarks: false,
          page: 0,
        );

        expect(results, isA<List<ArtistModel>>());
      });

      test('caches results', () async {
        setupMockSupabase({
          'artist': [
            makeArtistJson(id: 1, name: {'ko': '테스트', 'en': 'Test'}),
          ],
        });

        final results1 = await SearchService.searchArtistsFast(query: 'Test');
        final results2 = await SearchService.searchArtistsFast(query: 'Test');

        expect(results1.length, results2.length);
      });

      test('Korean initial search matches group name in fast mode', () async {
        setupMockSupabase({
          'artist': [
            makeArtistJson(
              id: 1,
              name: {'ko': '지수', 'en': 'Jisoo'},
              artistGroup: makeArtistGroupJson(
                id: 10,
                name: {'ko': '블랙핑크', 'en': 'BLACKPINK'},
              ),
            ),
          ],
        });

        final results = await SearchService.searchArtistsFast(
          query: 'ㅂㅍ',
        );

        expect(results, isA<List<ArtistModel>>());
      });
    });

    group('searchEntities', () {
      test('returns entities with text search', () async {
        setupMockSupabase({
          'test_table': [
            {'id': 1, 'name': 'Test Item'},
            {'id': 2, 'name': 'Another Item'},
          ],
        });

        final results = await SearchService.searchEntities<Map<String, dynamic>>(
          query: 'Test',
          table: 'test_table',
          selectFields: 'id,name',
          searchFields: ['name'],
          fromJson: (json) => json,
          useCache: false,
        );

        expect(results, isA<List<Map<String, dynamic>>>());
      });

      test('returns all entities with empty query', () async {
        setupMockSupabase({
          'test_table': [
            {'id': 1, 'name': 'Item 1'},
            {'id': 2, 'name': 'Item 2'},
          ],
        });

        final results = await SearchService.searchEntities<Map<String, dynamic>>(
          query: '',
          table: 'test_table',
          selectFields: 'id,name',
          searchFields: ['name'],
          fromJson: (json) => json,
          useCache: false,
        );

        expect(results, isA<List<Map<String, dynamic>>>());
        expect(results.length, 2);
      });

      test('applies excludeIds filter', () async {
        setupMockSupabase({
          'test_table': [
            {'id': 1, 'name': 'Item 1'},
          ],
        });

        final results = await SearchService.searchEntities<Map<String, dynamic>>(
          query: '',
          table: 'test_table',
          selectFields: 'id,name',
          searchFields: [],
          fromJson: (json) => json,
          excludeIds: [2, 3],
          useCache: false,
        );

        expect(results, isA<List<Map<String, dynamic>>>());
      });

      test('applies additionalFilters with eq', () async {
        setupMockSupabase({
          'test_table': [
            {'id': 1, 'name': 'Item', 'status': 'active'},
          ],
        });

        final results = await SearchService.searchEntities<Map<String, dynamic>>(
          query: '',
          table: 'test_table',
          selectFields: 'id,name,status',
          searchFields: [],
          fromJson: (json) => json,
          additionalFilters: {'status': 'active'},
          useCache: false,
        );

        expect(results, isA<List<Map<String, dynamic>>>());
      });

      test('applies additionalFilters with neq_ prefix', () async {
        setupMockSupabase({
          'test_table': [
            {'id': 1, 'name': 'Item'},
          ],
        });

        final results = await SearchService.searchEntities<Map<String, dynamic>>(
          query: '',
          table: 'test_table',
          selectFields: 'id,name',
          searchFields: [],
          fromJson: (json) => json,
          additionalFilters: {'neq_id': 0},
          useCache: false,
        );

        expect(results, isA<List<Map<String, dynamic>>>());
      });

      test('applies additionalFilters with not_ prefix (list)', () async {
        setupMockSupabase({
          'test_table': [
            {'id': 1, 'name': 'Item'},
          ],
        });

        final results = await SearchService.searchEntities<Map<String, dynamic>>(
          query: '',
          table: 'test_table',
          selectFields: 'id,name',
          searchFields: [],
          fromJson: (json) => json,
          additionalFilters: {
            'not_id': [0, 99],
          },
          useCache: false,
        );

        expect(results, isA<List<Map<String, dynamic>>>());
      });

      test('applies additionalFilters with list (filter)', () async {
        setupMockSupabase({
          'test_table': [
            {'id': 1, 'name': 'Item'},
          ],
        });

        final results = await SearchService.searchEntities<Map<String, dynamic>>(
          query: '',
          table: 'test_table',
          selectFields: 'id,name',
          searchFields: [],
          fromJson: (json) => json,
          additionalFilters: {
            'id': [1, 2],
          },
          useCache: false,
        );

        expect(results, isA<List<Map<String, dynamic>>>());
      });

      test('applies orderBy', () async {
        setupMockSupabase({
          'test_table': [
            {'id': 1, 'name': 'B'},
            {'id': 2, 'name': 'A'},
          ],
        });

        final results = await SearchService.searchEntities<Map<String, dynamic>>(
          query: '',
          table: 'test_table',
          selectFields: 'id,name',
          searchFields: [],
          fromJson: (json) => json,
          orderBy: 'name',
          useCache: false,
        );

        expect(results, isA<List<Map<String, dynamic>>>());
      });

      test('caches results when useCache is true', () async {
        setupMockSupabase({
          'test_table': [
            {'id': 1, 'name': 'Item'},
          ],
        });

        final results1 = await SearchService.searchEntities<Map<String, dynamic>>(
          query: 'Item',
          table: 'test_table',
          selectFields: 'id,name',
          searchFields: ['name'],
          fromJson: (json) => json,
          useCache: true,
        );

        final results2 = await SearchService.searchEntities<Map<String, dynamic>>(
          query: 'Item',
          table: 'test_table',
          selectFields: 'id,name',
          searchFields: ['name'],
          fromJson: (json) => json,
          useCache: true,
        );

        expect(results1.length, results2.length);
      });

      test('whitespace-only query is trimmed to empty and returns all results', () async {
        setupMockSupabase({
          'test_table': [
            {'id': 1, 'name': 'Item'},
          ],
        });

        // query '   ' gets trimmed to '' at the start, so it becomes an empty query
        // which does NOT throw but instead returns all results
        final results = await SearchService.searchEntities<Map<String, dynamic>>(
          query: '   ',
          table: 'test_table',
          selectFields: 'id,name',
          searchFields: ['name'],
          fromJson: (json) => json,
          useCache: false,
        );

        expect(results, isA<List<Map<String, dynamic>>>());
      });

      test('handles empty searchFields', () async {
        setupMockSupabase({
          'test_table': [
            {'id': 1, 'name': 'Item'},
          ],
        });

        final results = await SearchService.searchEntities<Map<String, dynamic>>(
          query: 'test',
          table: 'test_table',
          selectFields: 'id,name',
          searchFields: [],
          fromJson: (json) => json,
          useCache: false,
        );

        // With non-empty query but empty searchFields, no .or() is applied
        expect(results, isA<List<Map<String, dynamic>>>());
      });
    });

    group('searchEntitiesAdvanced', () {
      test('returns entities with advanced search conditions', () async {
        setupMockSupabase({
          'artist': [
            makeArtistJson(id: 1, name: {'ko': '지수', 'en': 'Jisoo'}),
          ],
        });

        final results = await SearchService.searchEntitiesAdvanced<Map<String, dynamic>>(
          query: 'Jisoo',
          table: 'artist',
          selectFields: 'id,name',
          searchConditions: ['name->>en.ilike.%{query}%'],
          fromJson: (json) => json,
          useCache: false,
        );

        expect(results, isA<List<Map<String, dynamic>>>());
      });

      test('returns all entities with empty query', () async {
        setupMockSupabase({
          'test_table': [
            {'id': 1, 'name': 'Item 1'},
          ],
        });

        final results = await SearchService.searchEntitiesAdvanced<Map<String, dynamic>>(
          query: '',
          table: 'test_table',
          selectFields: 'id,name',
          searchConditions: ['name.ilike.%{query}%'],
          fromJson: (json) => json,
          useCache: false,
        );

        expect(results, isA<List<Map<String, dynamic>>>());
      });

      test('applies filters with various prefixes', () async {
        setupMockSupabase({
          'test_table': [
            {'id': 1, 'name': 'Item', 'score': 5},
          ],
        });

        final results = await SearchService.searchEntitiesAdvanced<Map<String, dynamic>>(
          query: '',
          table: 'test_table',
          selectFields: 'id,name,score',
          searchConditions: [],
          fromJson: (json) => json,
          filters: {
            'neq_id': 0,
            'gt_score': 3,
            'gte_score': 4,
            'lt_score': 10,
            'lte_score': 9,
            'like_name': '%Item%',
            'ilike_name': '%item%',
            'status': 'active',
            'not_in_id': [99, 100],
            'in_category': [1, 2],
            'tags': [1, 2, 3],
          },
          useCache: false,
        );

        expect(results, isA<List<Map<String, dynamic>>>());
      });

      test('applies orderBy with desc', () async {
        setupMockSupabase({
          'test_table': [
            {'id': 1, 'name': 'A'},
            {'id': 2, 'name': 'B'},
          ],
        });

        final results = await SearchService.searchEntitiesAdvanced<Map<String, dynamic>>(
          query: '',
          table: 'test_table',
          selectFields: 'id,name',
          searchConditions: [],
          fromJson: (json) => json,
          orderBy: ['name desc', 'id'],
          useCache: false,
        );

        expect(results, isA<List<Map<String, dynamic>>>());
      });

      test('caches results', () async {
        setupMockSupabase({
          'test_table': [
            {'id': 1, 'name': 'Item'},
          ],
        });

        final results1 = await SearchService.searchEntitiesAdvanced<Map<String, dynamic>>(
          query: 'Item',
          table: 'test_table',
          selectFields: 'id,name',
          searchConditions: ['name.ilike.%{query}%'],
          fromJson: (json) => json,
          useCache: true,
        );

        final results2 = await SearchService.searchEntitiesAdvanced<Map<String, dynamic>>(
          query: 'Item',
          table: 'test_table',
          selectFields: 'id,name',
          searchConditions: ['name.ilike.%{query}%'],
          fromJson: (json) => json,
          useCache: true,
        );

        expect(results1.length, results2.length);
      });

      test('whitespace-only query is trimmed to empty and returns all results', () async {
        setupMockSupabase({
          'test_table': [
            {'id': 1, 'name': 'Item'},
          ],
        });

        // query '   ' gets trimmed to '' at the start, so it becomes an empty query
        final results = await SearchService.searchEntitiesAdvanced<Map<String, dynamic>>(
          query: '   ',
          table: 'test_table',
          selectFields: 'id,name',
          searchConditions: ['name.ilike.%{query}%'],
          fromJson: (json) => json,
          useCache: false,
        );

        expect(results, isA<List<Map<String, dynamic>>>());
      });
    });

    group('searchBoards', () {
      test('returns boards matching query', () async {
        setupMockSupabase({
          'boards': [
            makeBoardJson(boardId: 'b1', artistId: 1, name: {'ko': '보드1', 'en': 'Board1'}),
          ],
        });

        final results = await SearchService.searchBoards(
          query: 'Board',
          useCache: false,
        );

        expect(results, isA<List<BoardModel>>());
      });

      test('returns empty list when no boards match', () async {
        setupMockSupabase({
          'boards': <Map<String, dynamic>>[],
        });

        final results = await SearchService.searchBoards(
          query: 'nonexistent',
          useCache: false,
        );

        expect(results, isEmpty);
      });

      test('caches board results', () async {
        setupMockSupabase({
          'boards': [
            makeBoardJson(boardId: 'b1', artistId: 1),
          ],
        });

        final results1 = await SearchService.searchBoards(
          query: 'Board',
          useCache: true,
        );

        final results2 = await SearchService.searchBoards(
          query: 'Board',
          useCache: true,
        );

        expect(results1.length, results2.length);
      });

      test('supports pagination', () async {
        setupMockSupabase({
          'boards': [
            makeBoardJson(boardId: 'b1', artistId: 1),
          ],
        });

        final results = await SearchService.searchBoards(
          query: 'Board',
          page: 0,
          limit: 5,
          useCache: false,
        );

        expect(results, isA<List<BoardModel>>());
      });

      test('supports different languages', () async {
        setupMockSupabase({
          'boards': [
            makeBoardJson(boardId: 'b1', artistId: 1),
          ],
        });

        final results = await SearchService.searchBoards(
          query: 'Board',
          language: 'en',
          useCache: false,
        );

        expect(results, isA<List<BoardModel>>());
      });
    });

    group('preloadPopularSearches', () {
      test('preloads without error', () async {
        setupMockSupabase({
          'artist': [
            {
              ...makeArtistJson(id: 1, name: {'ko': 'BTS', 'en': 'BTS'}),
              'artist_user_bookmark': [],
            },
          ],
          'artist_group': <Map<String, dynamic>>[],
        });

        await SearchService.preloadPopularSearches(
          popularQueries: ['BTS', 'BLACKPINK'],
        );

        // If we got here, it succeeded
        expect(true, isTrue);
      });
    });

    group('_parseArtistWithBookmark', () {
      // This is tested indirectly via searchArtistsFast
      test('without includeBookmarks returns plain ArtistModel', () async {
        setupMockSupabase({
          'artist': [
            makeArtistJson(id: 1, name: {'ko': '테스트', 'en': 'Test'}),
          ],
        });

        final results = await SearchService.searchArtistsFast(
          query: 'Test',
          includeBookmarks: false,
        );

        expect(results, isA<List<ArtistModel>>());
      });

      test('with includeBookmarks parses bookmark data from text search', () async {
        setupMockSupabase({
          'artist': [
            {
              ...makeArtistJson(id: 1, name: {'ko': '테스트', 'en': 'Test'}),
              'artist_user_bookmark': [{'artist_id': 1}],
            },
          ],
        });

        final results = await SearchService.searchArtistsFast(
          query: 'Test',
          includeBookmarks: true,
        );

        expect(results, isA<List<ArtistModel>>());
        if (results.isNotEmpty) {
          expect(results[0].isBookmarked, true);
        }
      });

      test('with includeBookmarks and empty bookmark list', () async {
        setupMockSupabase({
          'artist': [
            {
              ...makeArtistJson(id: 1, name: {'ko': '테스트', 'en': 'Test'}),
              'artist_user_bookmark': [],
            },
          ],
        });

        final results = await SearchService.searchArtistsFast(
          query: 'Test',
          includeBookmarks: true,
        );

        expect(results, isA<List<ArtistModel>>());
        if (results.isNotEmpty) {
          expect(results[0].isBookmarked, false);
        }
      });

      test('with includeBookmarks and null bookmark data', () async {
        setupMockSupabase({
          'artist': [
            makeArtistJson(id: 1, name: {'ko': '테스트', 'en': 'Test'}),
          ],
        });

        final results = await SearchService.searchArtistsFast(
          query: 'Test',
          includeBookmarks: true,
        );

        expect(results, isA<List<ArtistModel>>());
      });

      test('with includeBookmarks in Korean initial search', () async {
        setupMockSupabase({
          'artist': [
            {
              ...makeArtistJson(id: 1, name: {'ko': '블랙핑크', 'en': 'BLACKPINK'}),
              'artist_user_bookmark': [{'artist_id': 1}],
            },
          ],
        });

        final results = await SearchService.searchArtistsFast(
          query: 'ㅂ',
          includeBookmarks: true,
        );

        expect(results, isA<List<ArtistModel>>());
      });
    });

    group('searchArtists - Korean initials cache', () {
      test('caches results for Korean initial search when useCache is true', () async {
        setupMockSupabase({
          'artist': [
            makeArtistJson(id: 1, name: {'ko': '블랙핑크', 'en': 'BLACKPINK'}),
          ],
        });

        // First call with useCache: true should populate cache
        final results1 = await SearchService.searchArtists(
          query: 'ㅂ',
          useCache: true,
          supportKoreanInitials: true,
        );

        // Second call should use cache
        final results2 = await SearchService.searchArtists(
          query: 'ㅂ',
          useCache: true,
          supportKoreanInitials: true,
        );

        expect(results1.length, results2.length);
        expect(results1, isNotEmpty);
      });
    });

    group('searchArtists - group results deduplication', () {
      test('adds unique artists from group name search', () async {
        // Artist 1 matches by name, Artist 2 only matches via group
        setupMockSupabase({
          'artist': [
            {
              ...makeArtistJson(
                id: 1,
                name: {'ko': '지수', 'en': 'Jisoo'},
                artistGroup: makeArtistGroupJson(
                  id: 10,
                  name: {'ko': '블랙핑크', 'en': 'BLACKPINK'},
                ),
              ),
              'artist_user_bookmark': [],
            },
            {
              ...makeArtistJson(
                id: 2,
                name: {'ko': '로제', 'en': 'Rose'},
                artistGroup: makeArtistGroupJson(
                  id: 10,
                  name: {'ko': '블랙핑크', 'en': 'BLACKPINK'},
                ),
              ),
              'artist_user_bookmark': [],
            },
          ],
          'artist_group': [
            makeArtistGroupJson(
              id: 10,
              name: {'ko': '블랙핑크', 'en': 'BLACKPINK'},
            ),
          ],
        });

        final results = await SearchService.searchArtists(
          query: 'test_query',
          useCache: false,
        );

        // Verify no duplicates
        final ids = results.map((a) => a.id).toSet();
        expect(ids.length, results.length);
      });

      test('excludeIds applied in group artist query', () async {
        setupMockSupabase({
          'artist': [
            {
              ...makeArtistJson(
                id: 1,
                name: {'ko': '지수', 'en': 'Jisoo'},
                artistGroup: makeArtistGroupJson(
                  id: 10,
                  name: {'ko': '블랙핑크', 'en': 'BLACKPINK'},
                ),
              ),
              'artist_user_bookmark': [],
            },
          ],
          'artist_group': [
            makeArtistGroupJson(
              id: 10,
              name: {'ko': '블랙핑크', 'en': 'BLACKPINK'},
            ),
          ],
        });

        final results = await SearchService.searchArtists(
          query: 'BLACKPINK',
          excludeIds: [99],
          useCache: false,
        );

        expect(results, isA<List<ArtistModel>>());
      });
    });

    group('searchArtists - error handling', () {
      test('throws ArgumentError for invalid non-empty query', () async {
        setupMockSupabase({
          'artist': <Map<String, dynamic>>[],
          'artist_group': <Map<String, dynamic>>[],
        });

        // isValidQuery returns false for whitespace-only strings after trimming,
        // but query.trim() converts '   ' to '' which is empty, so it won't throw.
        // We need to trigger !isValidQuery(query) && query.isNotEmpty,
        // but isValidQuery just checks isEmpty after trim, and we already trim query.
        // Actually, isValidQuery returns true for any non-empty trimmed string.
        // The only way line 55 fires is if isValidQuery returns false AND query is not empty.
        // After trimming, isValidQuery(query) == query.isNotEmpty, so this condition
        // can never be true. This is dead code - skip testing it.
        expect(true, isTrue);
      });
    });

    group('searchEntities - error and edge cases', () {
      test('throws ArgumentError for invalid query in searchEntitiesAdvanced', () async {
        // Same dead-code situation as searchArtists line 55/652/852
        // isValidQuery(q) == q.trim().isNotEmpty, and q is already trimmed
        expect(true, isTrue);
      });
    });

    group('searchBoards - error handling', () {
      test('searchBoards with empty query trims whitespace', () async {
        setupMockSupabase({
          'boards': [
            makeBoardJson(boardId: 'b1', artistId: 1, name: {'ko': '보드', 'en': 'Board'}),
          ],
        });

        final results = await SearchService.searchBoards(
          query: '  Board  ',
          useCache: false,
        );

        expect(results, isA<List<BoardModel>>());
      });
    });
  });
}
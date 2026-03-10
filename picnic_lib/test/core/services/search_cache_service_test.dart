import 'package:picnic_lib/core/services/search_cache_service.dart';
import 'package:test/test.dart';

void main() {
  // SearchCacheService는 싱글톤이므로 매 테스트 전 clear 필요
  late SearchCacheService service;

  setUp(() {
    service = SearchCacheService();
    service.clear();
  });

  group('SearchCacheService - put/get 기본 동작', () {
    test('put으로 저장한 데이터를 get으로 조회할 수 있어야 함', () {
      // Arrange
      const key = 'test_key';
      const data = 'test_data';

      // Act
      service.put(key, data);
      final result = service.get<String>(key);

      // Assert
      expect(result, equals(data));
    });

    test('존재하지 않는 키 조회 시 null을 반환해야 함', () {
      // Act
      final result = service.get<String>('non_existent_key');

      // Assert
      expect(result, isNull);
    });

    test('다양한 타입의 데이터를 저장하고 조회할 수 있어야 함', () {
      // Arrange & Act
      service.put('int_key', 42);
      service.put('list_key', [1, 2, 3]);
      service.put('map_key', {'a': 1, 'b': 2});

      // Assert
      expect(service.get<int>('int_key'), equals(42));
      expect(service.get<List<int>>('list_key'), equals([1, 2, 3]));
      expect(service.get<Map<String, int>>('map_key'), equals({'a': 1, 'b': 2}));
    });

    test('같은 키에 다시 저장하면 값이 덮어씌워져야 함', () {
      // Arrange
      service.put('key', 'original');

      // Act
      service.put('key', 'updated');

      // Assert
      expect(service.get<String>('key'), equals('updated'));
    });
  });

  group('SearchCacheService - TTL/만료 동작', () {
    test('만료된 캐시 항목은 null을 반환해야 함', () {
      // Arrange - 매우 짧은 만료 시간으로 저장
      service.put('expire_key', 'data', expiration: Duration.zero);

      // Act - 이미 만료됨
      final result = service.get<String>('expire_key');

      // Assert
      expect(result, isNull);
    });

    test('만료되지 않은 캐시 항목은 정상 반환되어야 함', () {
      // Arrange - 긴 만료 시간으로 저장
      service.put('valid_key', 'data', expiration: const Duration(hours: 1));

      // Act
      final result = service.get<String>('valid_key');

      // Assert
      expect(result, equals('data'));
    });

    test('containsKey는 만료된 항목에 대해 false를 반환해야 함', () {
      // Arrange
      service.put('expire_key', 'data', expiration: Duration.zero);

      // Act & Assert
      expect(service.containsKey('expire_key'), isFalse);
    });

    test('containsKey는 유효한 항목에 대해 true를 반환해야 함', () {
      // Arrange
      service.put('valid_key', 'data');

      // Act & Assert
      expect(service.containsKey('valid_key'), isTrue);
    });

    test('containsKey는 존재하지 않는 키에 대해 false를 반환해야 함', () {
      expect(service.containsKey('no_key'), isFalse);
    });
  });

  group('SearchCacheService - LRU 제거', () {
    test('최대 크기 초과 시 가장 오래된 항목이 제거되어야 함', () {
      // Arrange - 100개(최대) 채우기
      for (var i = 0; i < 100; i++) {
        service.put('key_$i', 'value_$i');
      }

      // Act - 101번째 항목 추가
      service.put('key_100', 'value_100');

      // Assert - 가장 오래된 항목(key_0)이 제거됨
      expect(service.get<String>('key_0'), isNull);
      expect(service.get<String>('key_100'), equals('value_100'));
      expect(service.size, equals(100));
    });

    test('get 호출 시 LRU 순서가 업데이트되어야 함', () {
      // Arrange - 100개 채우기
      for (var i = 0; i < 100; i++) {
        service.put('key_$i', 'value_$i');
      }

      // Act - key_0을 조회하여 최근 사용 항목으로 갱신
      service.get<String>('key_0');

      // 101번째 항목 추가 - 이제 key_1이 가장 오래된 항목
      service.put('key_100', 'value_100');

      // Assert - key_0은 살아있고, key_1이 제거됨
      expect(service.get<String>('key_0'), equals('value_0'));
      expect(service.get<String>('key_1'), isNull);
    });
  });

  group('SearchCacheService - remove/clear 동작', () {
    test('remove는 특정 키의 캐시를 삭제해야 함', () {
      // Arrange
      service.put('key1', 'value1');
      service.put('key2', 'value2');

      // Act
      service.remove('key1');

      // Assert
      expect(service.get<String>('key1'), isNull);
      expect(service.get<String>('key2'), equals('value2'));
    });

    test('removeByPattern은 패턴에 맞는 키들을 삭제해야 함', () {
      // Arrange
      service.put('artist_1', 'data1');
      service.put('artist_2', 'data2');
      service.put('board_1', 'data3');

      // Act
      service.removeByPattern('artist_*');

      // Assert
      expect(service.get<String>('artist_1'), isNull);
      expect(service.get<String>('artist_2'), isNull);
      expect(service.get<String>('board_1'), equals('data3'));
    });

    test('clear는 모든 캐시를 삭제해야 함', () {
      // Arrange
      service.put('key1', 'value1');
      service.put('key2', 'value2');

      // Act
      service.clear();

      // Assert
      expect(service.isEmpty, isTrue);
      expect(service.size, equals(0));
    });
  });

  group('SearchCacheService - cleanupExpired', () {
    test('cleanupExpired는 만료된 항목만 제거해야 함', () {
      // Arrange
      service.put('expired_key', 'data', expiration: Duration.zero);
      service.put('valid_key', 'data', expiration: const Duration(hours: 1));

      // Act
      service.cleanupExpired();

      // Assert - 만료된 항목은 제거, 유효한 항목은 유지
      expect(service.size, equals(1));
      expect(service.get<String>('valid_key'), equals('data'));
    });

    test('cleanupExpired 호출 시 만료된 항목이 없으면 아무것도 제거하지 않아야 함', () {
      // Arrange
      service.put('key1', 'data1');
      service.put('key2', 'data2');

      // Act
      service.cleanupExpired();

      // Assert
      expect(service.size, equals(2));
    });
  });

  group('SearchCacheService - stats 및 유틸리티', () {
    test('stats는 올바른 통계를 반환해야 함', () {
      // Arrange
      service.put('key1', 'data1');
      service.put('key2', 'data2');
      service.put('expired_key', 'data3', expiration: Duration.zero);

      // Act
      final stats = service.stats;

      // Assert
      expect(stats.totalEntries, equals(3));
      expect(stats.expiredEntries, equals(1));
      expect(stats.activeEntries, equals(2));
      expect(stats.maxSize, equals(100));
    });

    test('isEmpty/isNotEmpty가 올바르게 동작해야 함', () {
      // 초기 상태
      expect(service.isEmpty, isTrue);
      expect(service.isNotEmpty, isFalse);

      // 데이터 추가 후
      service.put('key', 'value');
      expect(service.isEmpty, isFalse);
      expect(service.isNotEmpty, isTrue);
    });

    test('size가 올바른 크기를 반환해야 함', () {
      expect(service.size, equals(0));

      service.put('key1', 'value1');
      expect(service.size, equals(1));

      service.put('key2', 'value2');
      expect(service.size, equals(2));

      service.remove('key1');
      expect(service.size, equals(1));
    });
  });

  group('CacheEntry', () {
    test('만료되지 않은 엔트리의 isExpired는 false여야 함', () {
      final entry = CacheEntry(
        data: 'test',
        timestamp: DateTime.now(),
        expiration: const Duration(hours: 1),
      );

      expect(entry.isExpired, isFalse);
    });

    test('만료된 엔트리의 isExpired는 true여야 함', () {
      final entry = CacheEntry(
        data: 'test',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        expiration: const Duration(hours: 1),
      );

      expect(entry.isExpired, isTrue);
    });

    test('remainingTime은 남은 시간을 반환해야 함', () {
      final entry = CacheEntry(
        data: 'test',
        timestamp: DateTime.now(),
        expiration: const Duration(hours: 1),
      );

      expect(entry.remainingTime.inMinutes, greaterThan(55));
    });

    test('만료된 엔트리의 remainingTime은 Duration.zero여야 함', () {
      final entry = CacheEntry(
        data: 'test',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        expiration: const Duration(hours: 1),
      );

      expect(entry.remainingTime, equals(Duration.zero));
    });
  });

  group('CacheStats', () {
    test('activeEntries는 총 항목에서 만료된 항목을 뺀 값이어야 함', () {
      const stats = CacheStats(
        totalEntries: 10,
        expiredEntries: 3,
        maxSize: 100,
        hitRate: 0.5,
      );

      expect(stats.activeEntries, equals(7));
    });

    test('usageRate는 총 항목 / 최대 크기여야 함', () {
      const stats = CacheStats(
        totalEntries: 50,
        expiredEntries: 0,
        maxSize: 100,
        hitRate: 0.0,
      );

      expect(stats.usageRate, equals(0.5));
    });

    test('toString은 올바른 형식의 문자열을 반환해야 함', () {
      const stats = CacheStats(
        totalEntries: 10,
        expiredEntries: 2,
        maxSize: 100,
        hitRate: 0.75,
      );

      final str = stats.toString();
      expect(str, contains('total: 10'));
      expect(str, contains('active: 8'));
      expect(str, contains('expired: 2'));
    });
  });
}

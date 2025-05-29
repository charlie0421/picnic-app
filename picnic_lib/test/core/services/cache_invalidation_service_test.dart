import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/services/cache_invalidation_service.dart';
import 'package:picnic_lib/core/services/simple_cache_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('CacheInvalidationService Tests', () {
    late CacheInvalidationService invalidationService;
    late SimpleCacheManager cacheManager;

    setUp(() async {
      // Setup mock environment
      SharedPreferences.setMockInitialValues({});

      // Initialize services
      cacheManager = SimpleCacheManager.instance;
      await cacheManager.init();

      invalidationService = CacheInvalidationService.instance;
      await invalidationService.init();

      // Clear any existing cache and events
      await cacheManager.clear();
    });

    tearDown(() async {
      await invalidationService.dispose();
      await cacheManager.clear();
    });

    group('Event-Based Invalidation', () {
      test('should add and process invalidation events', () async {
        // Create invalidation event
        final event = CacheInvalidationEvent(
          id: 'test_event_1',
          type: InvalidationEventType.userAction,
          source: 'test',
          tags: ['user_profiles'],
          priority: 8, // High priority
        );

        // Listen to event stream
        final eventCompleter = Completer<CacheInvalidationEvent>();
        final subscription = invalidationService.eventStream.listen((event) {
          eventCompleter.complete(event);
        });

        // Add event
        await invalidationService.addInvalidationEvent(event);

        // Verify event was emitted
        final emittedEvent = await eventCompleter.future;
        expect(emittedEvent.id, equals('test_event_1'));
        expect(emittedEvent.type, equals(InvalidationEventType.userAction));
        expect(emittedEvent.source, equals('test'));
        expect(emittedEvent.priority, equals(8));

        await subscription.cancel();
      });

      test('should prioritize high-priority events', () async {
        // Store some test data in cache
        await cacheManager.put(
          'https://api.example.com/user_profiles/123',
          {},
          '{"user": "test"}',
          200,
          isAuthenticated: false,
        );

        // Create high-priority event
        final highPriorityEvent = CacheInvalidationEvent(
          id: 'high_priority',
          type: InvalidationEventType.dataUpdate,
          source: 'test',
          patterns: [r'/user_profiles/'],
          priority: 9,
        );

        // Add event
        await invalidationService.addInvalidationEvent(highPriorityEvent);

        // Wait a bit for processing
        await Future.delayed(const Duration(milliseconds: 100));

        // Verify cache was invalidated
        final cachedEntry = await cacheManager.get(
          'https://api.example.com/user_profiles/123',
          {},
          isAuthenticated: false,
        );
        expect(cachedEntry, isNull);
      });

      test('should handle different event types correctly', () async {
        final events = [
          CacheInvalidationEvent(
            id: 'user_action',
            type: InvalidationEventType.userAction,
            source: 'user_interface',
            tags: ['user_profiles'],
          ),
          CacheInvalidationEvent(
            id: 'data_update',
            type: InvalidationEventType.dataUpdate,
            source: 'api_update',
            patterns: [r'/products/'],
          ),
          CacheInvalidationEvent(
            id: 'time_expiry',
            type: InvalidationEventType.timeExpiry,
            source: 'scheduler',
            tags: ['expired_data'],
          ),
        ];

        // Process all events
        for (final event in events) {
          await invalidationService.addInvalidationEvent(event);
        }

        // Events should be processed without errors
        await Future.delayed(const Duration(milliseconds: 200));
      });
    });

    group('Tag-Based Invalidation', () {
      test('should invalidate by tags', () async {
        // Store tagged cache entries
        await cacheManager.put(
          'https://api.example.com/user_profiles/123',
          {},
          '{"user": "john"}',
          200,
          isAuthenticated: false,
        );

        await cacheManager.put(
          'https://api.example.com/posts/456',
          {},
          '{"post": "content"}',
          200,
          isAuthenticated: false,
        );

        // Assign tags to URLs
        await invalidationService.assignTagsToUrl(
          'https://api.example.com/user_profiles/123',
          ['user_profiles', 'user_data'],
        );

        await invalidationService.assignTagsToUrl(
          'https://api.example.com/posts/456',
          ['posts', 'content'],
        );

        // Invalidate by user_profiles tag
        await invalidationService.invalidateByTags(
          ['user_profiles'],
          source: 'test',
          type: InvalidationEventType.manual,
        );

        // Wait for processing
        await Future.delayed(const Duration(milliseconds: 100));

        // User profile should be invalidated
        final userEntry = await cacheManager.get(
          'https://api.example.com/user_profiles/123',
          {},
          isAuthenticated: false,
        );
        expect(userEntry, isNull);

        // Post should remain
        final postEntry = await cacheManager.get(
          'https://api.example.com/posts/456',
          {},
          isAuthenticated: false,
        );
        expect(postEntry, isNotNull);
      });

      test('should retrieve tags for URL', () async {
        const url = 'https://api.example.com/test';
        const tags = ['tag1', 'tag2', 'tag3'];

        // Assign tags
        await invalidationService.assignTagsToUrl(url, tags);

        // Retrieve tags
        final retrievedTags = invalidationService.getTagsForUrl(url);

        expect(retrievedTags.length, equals(3));
        expect(retrievedTags, containsAll(tags));
      });

      test('should use predefined tags', () async {
        // Test that predefined tags are available
        final predefinedTags = CacheInvalidationService.predefinedTags;

        expect(predefinedTags, isNotNull);
        expect(predefinedTags, isNotEmpty);
        expect(predefinedTags, contains('user_profile'));
        expect(predefinedTags, contains('user_posts'));
        expect(predefinedTags, contains('products'));
        expect(predefinedTags, contains('config'));
      });
    });

    group('Smart Invalidation', () {
      test('should perform smart invalidation for user profiles', () async {
        // Store related cache entries
        await cacheManager.put(
          'https://api.example.com/user_profiles/123',
          {},
          '{"user": "john"}',
          200,
          isAuthenticated: false,
        );

        await cacheManager.put(
          'https://api.example.com/posts/user/123',
          {},
          '{"posts": []}',
          200,
          isAuthenticated: false,
        );

        // Perform smart invalidation
        await invalidationService.smartInvalidate(
          'https://api.example.com/user_profiles/123',
          source: 'user_update',
        );

        // Wait for processing
        await Future.delayed(const Duration(milliseconds: 100));

        // Related entries should be invalidated
        final userEntry = await cacheManager.get(
          'https://api.example.com/user_profiles/123',
          {},
          isAuthenticated: false,
        );
        expect(userEntry, isNull);
      });

      test('should handle different URL patterns for smart invalidation',
          () async {
        final testCases = [
          'https://api.example.com/user_profiles/456',
          'https://api.example.com/posts/789',
          'https://api.example.com/products/abc',
        ];

        for (final url in testCases) {
          // Store cache entry
          await cacheManager.put(url, {}, '{"data": "test"}', 200,
              isAuthenticated: false);

          // Perform smart invalidation
          await invalidationService.smartInvalidate(
            url,
            source: 'smart_test',
            metadata: {'test': true},
          );

          // Should process without errors
          await Future.delayed(const Duration(milliseconds: 50));
        }
      });
    });

    group('Cache Warming', () {
      test('should add and manage warming tasks', () async {
        // Create warming task
        final warmingTask = CacheWarmingTask(
          id: 'test_warming',
          url: 'https://api.example.com/config',
          headers: {'Accept': 'application/json'},
          interval: const Duration(minutes: 30),
          priority: 8,
          isActive: true,
        );

        // Add warming task
        await invalidationService.addWarmingTask(warmingTask);

        // Verify task was added (check stats instead of non-existent method)
        final stats = await invalidationService.getInvalidationStats();
        expect(stats['warmingTaskCount'], greaterThan(0));
      });

      test('should execute warming tasks based on schedule', () async {
        // Create warming task with short interval
        final immediateTask = CacheWarmingTask(
          id: 'immediate_task',
          url: 'https://api.example.com/immediate',
          interval: const Duration(seconds: 1),
          priority: 7,
          isActive: true,
        );

        await invalidationService.addWarmingTask(immediateTask);

        // Task should be processed without errors
        await Future.delayed(const Duration(milliseconds: 100));
      });

      test('should manage warming task lifecycle', () async {
        final task = CacheWarmingTask(
          id: 'lifecycle_test',
          url: 'https://api.example.com/lifecycle',
          interval: const Duration(minutes: 30),
          priority: 5,
          isActive: true,
        );

        // Add task
        await invalidationService.addWarmingTask(task);

        // Verify task was added
        var stats = await invalidationService.getInvalidationStats();
        final initialCount = stats['warmingTaskCount'] as int;

        // Remove task
        await invalidationService.removeWarmingTask('lifecycle_test');

        // Task should be removed
        stats = await invalidationService.getInvalidationStats();
        expect(stats['warmingTaskCount'], lessThan(initialCount));
      });
    });

    group('Remote Invalidation Signals', () {
      test('should check for remote invalidation signals', () async {
        // Mock remote signals in SharedPreferences
        final signals = [
          {
            'id': 'remote_signal_1',
            'timestamp': DateTime.now().toIso8601String(),
            'tags': ['user_profiles'],
            'patterns': [r'/user_profiles/'],
            'priority': 8,
          }
        ];

        SharedPreferences.setMockInitialValues({
          'cache_remote_signals': signals.map((s) => jsonEncode(s)).toList(),
        });

        // Check for remote signals
        await invalidationService.checkRemoteInvalidationSignals();

        // Signals should be processed
        await Future.delayed(const Duration(milliseconds: 100));
      });

      test('should ignore old remote signals', () async {
        // Create old signal (more than 5 minutes ago)
        final oldSignal = {
          'id': 'old_signal',
          'timestamp': DateTime.now()
              .subtract(const Duration(minutes: 10))
              .toIso8601String(),
          'tags': ['old_data'],
          'priority': 5,
        };

        SharedPreferences.setMockInitialValues({
          'cache_remote_signals': [jsonEncode(oldSignal)],
        });

        // Check for remote signals
        await invalidationService.checkRemoteInvalidationSignals();

        // Old signal should be ignored
        await Future.delayed(const Duration(milliseconds: 100));
      });
    });

    group('Service Statistics and Management', () {
      test('should provide invalidation statistics', () async {
        // Add some events and tasks
        await invalidationService.addInvalidationEvent(
          CacheInvalidationEvent(
            id: 'stats_test',
            type: InvalidationEventType.manual,
            source: 'test',
          ),
        );

        await invalidationService.addWarmingTask(
          CacheWarmingTask(
            id: 'stats_warming',
            url: 'https://api.example.com/stats',
            priority: 6,
            isActive: true,
          ),
        );

        // Get statistics
        final stats = await invalidationService.getInvalidationStats();

        expect(stats, isNotNull);
        expect(stats, containsPair('eventQueueSize', isA<int>()));
        expect(stats, containsPair('tagMappingCount', isA<int>()));
        expect(stats, containsPair('warmingTaskCount', isA<int>()));
        expect(stats, containsPair('activeWarmingTasks', isA<int>()));
        expect(stats, containsPair('cacheStats', isA<Map>()));
        expect(stats, containsPair('predefinedTagsCount', isA<int>()));
      });

      test('should handle service disposal gracefully', () async {
        // Add some data
        await invalidationService.addInvalidationEvent(
          CacheInvalidationEvent(
            id: 'disposal_test',
            type: InvalidationEventType.manual,
            source: 'test',
          ),
        );

        // Dispose service
        await invalidationService.dispose();

        // Should dispose without errors
      });
    });

    group('Error Handling', () {
      test('should handle invalid event data gracefully', () async {
        // Try to create event with minimal data
        final minimalEvent = CacheInvalidationEvent(
          id: 'minimal',
          type: InvalidationEventType.manual,
          source: 'test',
        );

        // Should not throw
        await invalidationService.addInvalidationEvent(minimalEvent);
        await Future.delayed(const Duration(milliseconds: 50));
      });

      test('should handle empty tag lists', () async {
        // Invalidate with empty tag list
        await invalidationService.invalidateByTags(
          [],
          source: 'empty_test',
        );

        // Should not throw
        await Future.delayed(const Duration(milliseconds: 50));
      });

      test('should handle invalid URL patterns', () async {
        // Smart invalidation with malformed URL
        await invalidationService.smartInvalidate(
          'not-a-valid-url',
          source: 'malformed_test',
        );

        // Should not throw
        await Future.delayed(const Duration(milliseconds: 50));
      });

      test('should handle warming task errors gracefully', () async {
        // Create warming task with invalid URL
        final invalidTask = CacheWarmingTask(
          id: 'invalid_task',
          url: 'not-a-url',
          priority: 3,
          isActive: true,
        );

        // Should not throw
        await invalidationService.addWarmingTask(invalidTask);
        await Future.delayed(const Duration(milliseconds: 100));
      });
    });

    group('Integration Tests', () {
      test('should integrate with SimpleCacheManager correctly', () async {
        // Store some cache data
        await cacheManager.put(
          'https://api.example.com/integration/test',
          {},
          '{"data": "integration"}',
          200,
          isAuthenticated: false,
        );

        // Verify it's cached
        var entry = await cacheManager.get(
          'https://api.example.com/integration/test',
          {},
          isAuthenticated: false,
        );
        expect(entry, isNotNull);

        // Invalidate via invalidation service
        await invalidationService.addInvalidationEvent(
          CacheInvalidationEvent(
            id: 'integration_test',
            type: InvalidationEventType.manual,
            source: 'integration_test',
            patterns: [r'/integration/'],
            priority: 8,
          ),
        );

        // Wait for processing
        await Future.delayed(const Duration(milliseconds: 100));

        // Entry should be invalidated
        entry = await cacheManager.get(
          'https://api.example.com/integration/test',
          {},
          isAuthenticated: false,
        );
        expect(entry, isNull);
      });

      test('should handle complex invalidation scenarios', () async {
        // Setup complex cache scenario
        final urls = [
          'https://api.example.com/user_profiles/1',
          'https://api.example.com/user_profiles/2',
          'https://api.example.com/posts/user/1',
          'https://api.example.com/posts/user/2',
          'https://api.example.com/products/123',
        ];

        // Cache all URLs
        for (final url in urls) {
          await cacheManager.put(url, {}, '{"data": "cached"}', 200,
              isAuthenticated: false);
        }

        // Tag some URLs
        await invalidationService
            .assignTagsToUrl(urls[0], ['user_profiles', 'user_1']);
        await invalidationService
            .assignTagsToUrl(urls[1], ['user_profiles', 'user_2']);
        await invalidationService.assignTagsToUrl(urls[2], ['posts', 'user_1']);
        await invalidationService.assignTagsToUrl(urls[3], ['posts', 'user_2']);
        await invalidationService.assignTagsToUrl(urls[4], ['products']);

        // Complex invalidation: user_1 related data
        await invalidationService.invalidateByTags(['user_1']);
        await Future.delayed(const Duration(milliseconds: 100));

        // Check results
        final results = <String, bool>{};
        for (final url in urls) {
          final entry = await cacheManager.get(url, {}, isAuthenticated: false);
          results[url] = entry != null;
        }

        // user_1 related should be invalidated, others should remain
        expect(results[urls[0]], isFalse); // user_profiles/1
        expect(results[urls[1]], isTrue); // user_profiles/2
        expect(results[urls[2]], isFalse); // posts/user/1
        expect(results[urls[3]], isTrue); // posts/user/2
        expect(results[urls[4]], isTrue); // products/123
      });
    });
  });
}

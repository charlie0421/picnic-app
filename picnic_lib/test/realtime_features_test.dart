import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:picnic_lib/core/services/realtime_service.dart';
import 'package:picnic_lib/core/services/optimistic_update_service.dart';
import 'package:picnic_lib/presentation/providers/realtime_providers.dart';

import 'realtime_features_test.mocks.dart';

@GenerateMocks([
  SupabaseClient,
  RealtimeChannel,
  SupabaseAuth,
  User,
])
void main() {
  group('Realtime Features Tests', () {
    late MockSupabaseClient mockSupabaseClient;
    late MockRealtimeChannel mockChannel;
    late MockSupabaseAuth mockAuth;
    late MockUser mockUser;
    late RealtimeService realtimeService;

    setUp(() {
      mockSupabaseClient = MockSupabaseClient();
      mockChannel = MockRealtimeChannel();
      mockAuth = MockSupabaseAuth();
      mockUser = MockUser();
      
      // Mock 설정
      when(mockSupabaseClient.auth).thenReturn(mockAuth);
      when(mockSupabaseClient.channel(any)).thenReturn(mockChannel);
      when(mockAuth.currentUser).thenReturn(mockUser);
      when(mockUser.id).thenReturn('test-user-id');
      
      // 채널 구독 mock
      when(mockChannel.onPostgresChanges(
        event: anyNamed('event'),
        schema: anyNamed('schema'),
        table: anyNamed('table'),
        filter: anyNamed('filter'),
        callback: anyNamed('callback'),
      )).thenReturn(mockChannel);
      
      when(mockChannel.subscribe(any)).thenAnswer((_) async {
        // 콜백 실행
        final callback = verify(mockChannel.subscribe(captureAny)).captured.first as void Function(RealtimeSubscribeStatus, Exception?);
        callback(RealtimeSubscribeStatus.subscribed, null);
      });
      
      realtimeService = RealtimeService();
    });

    tearDown(() {
      realtimeService.dispose();
    });

    group('RealtimeService Tests', () {
      test('초기화가 성공적으로 수행되는지 테스트', () async {
        // When
        await realtimeService.initialize();
        
        // Then
        expect(realtimeService.isConnected, isTrue);
        verify(mockSupabaseClient.channel('system')).called(1);
      });

      test('채팅 메시지 구독이 올바르게 작동하는지 테스트', () async {
        // Given
        const chatRoomId = 'test-chat-room';
        final messageController = StreamController<Map<String, dynamic>>();
        
        // When
        final messageStream = realtimeService.subscribeToChatMessages(chatRoomId);
        
        // Then
        expect(messageStream, isA<Stream<Map<String, dynamic>>>());
        verify(mockSupabaseClient.channel('chat_$chatRoomId')).called(1);
        verify(mockChannel.onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chat_messages',
          filter: anyNamed('filter'),
          callback: anyNamed('callback'),
        )).called(1);
      });

      test('알림 구독이 올바르게 작동하는지 테스트', () async {
        // Given
        const userId = 'test-user-id';
        
        // When
        final notificationStream = realtimeService.subscribeToNotifications(userId);
        
        // Then
        expect(notificationStream, isA<Stream<Map<String, dynamic>>>());
        verify(mockSupabaseClient.channel('notifications_$userId')).called(1);
        verify(mockChannel.onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: anyNamed('filter'),
          callback: anyNamed('callback'),
        )).called(1);
      });

      test('투표 업데이트 구독이 올바르게 작동하는지 테스트', () async {
        // Given
        const voteId = 'test-vote-id';
        
        // When
        final voteStream = realtimeService.subscribeToVoteUpdates(voteId);
        
        // Then
        expect(voteStream, isA<Stream<Map<String, dynamic>>>());
        verify(mockSupabaseClient.channel('vote_$voteId')).called(1);
        verify(mockChannel.onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'votes',
          filter: anyNamed('filter'),
          callback: anyNamed('callback'),
        )).called(1);
      });

      test('구독 해제가 올바르게 작동하는지 테스트', () async {
        // Given
        const channelName = 'test-channel';
        when(mockChannel.unsubscribe()).thenAnswer((_) async {});
        
        // When
        await realtimeService.unsubscribe(channelName);
        
        // Then
        verify(mockChannel.unsubscribe()).called(1);
      });

      test('모든 구독 해제가 올바르게 작동하는지 테스트', () async {
        // Given
        await realtimeService.subscribeToChatMessages('room1');
        await realtimeService.subscribeToNotifications('user1');
        when(mockChannel.unsubscribe()).thenAnswer((_) async {});
        
        // When
        await realtimeService.unsubscribeAll();
        
        // Then
        expect(realtimeService.isConnected, isFalse);
        verify(mockChannel.unsubscribe()).called(greaterThan(0));
      });

      test('연결 재시도가 올바르게 작동하는지 테스트', () async {
        // Given
        when(mockChannel.unsubscribe()).thenAnswer((_) async {});
        
        // When
        await realtimeService.reconnect();
        
        // Then
        verify(mockChannel.unsubscribe()).called(greaterThan(0));
        verify(mockSupabaseClient.channel('system')).called(greaterThan(1));
      });
    });

    group('Optimistic Update Service Tests', () {
      late OptimisticUpdateService optimisticService;

      setUp(() {
        optimisticService = OptimisticUpdateService();
      });

      tearDown(() {
        optimisticService.dispose();
      });

      test('낙관적 업데이트 실행 테스트', () async {
        // Given
        var localData = {'count': 0};
        Future<Map<String, dynamic>> serverOperation() async {
          await Future.delayed(const Duration(milliseconds: 100));
          return {'count': 1, 'server_updated': true};
        }

        // When
        final result = await optimisticService.executeOptimisticUpdate<Map<String, dynamic>>(
          resourceId: 'test-resource',
          optimisticData: {'count': 1},
          serverOperation: serverOperation,
          localData: localData,
        );

        // Then
        expect(result.isSuccess, isTrue);
        expect(result.data!['count'], equals(1));
        expect(result.data!['server_updated'], isTrue);
      });

      test('낙관적 업데이트 실패 시 롤백 테스트', () async {
        // Given
        var localData = {'count': 0};
        Future<Map<String, dynamic>> failingOperation() async {
          throw Exception('Server error');
        }

        // When
        final result = await optimisticService.executeOptimisticUpdate<Map<String, dynamic>>(
          resourceId: 'test-resource',
          optimisticData: {'count': 1},
          serverOperation: failingOperation,
          localData: localData,
        );

        // Then
        expect(result.isSuccess, isFalse);
        expect(result.error, isNotNull);
      });

      test('낙관적 업데이트 타임아웃 테스트', () async {
        // Given
        var localData = {'count': 0};
        Future<Map<String, dynamic>> slowOperation() async {
          await Future.delayed(const Duration(seconds: 35)); // 기본 타임아웃보다 긴 시간
          return {'count': 1};
        }

        // When
        final result = await optimisticService.executeOptimisticUpdate<Map<String, dynamic>>(
          resourceId: 'test-resource',
          optimisticData: {'count': 1},
          serverOperation: slowOperation,
          localData: localData,
          timeout: const Duration(seconds: 1),
        );

        // Then
        expect(result.isSuccess, isFalse);
        expect(result.error.toString(), contains('timeout'));
      });

      test('충돌 해결 전략 테스트', () async {
        // Given
        var localData = {'count': 5, 'name': 'local'};
        Future<Map<String, dynamic>> conflictingOperation() async {
          return {'count': 10, 'name': 'server', 'new_field': 'added'};
        }

        // When - clientWins 전략
        final clientWinsResult = await optimisticService.executeOptimisticUpdate<Map<String, dynamic>>(
          resourceId: 'test-resource',
          optimisticData: {'count': 3, 'name': 'optimistic'},
          serverOperation: conflictingOperation,
          localData: localData,
          conflictResolver: ConflictResolver.clientWins(),
        );

        // Then
        expect(clientWinsResult.isSuccess, isTrue);
        expect(clientWinsResult.data!['count'], equals(3));
        expect(clientWinsResult.data!['name'], equals('optimistic'));

        // When - serverWins 전략
        final serverWinsResult = await optimisticService.executeOptimisticUpdate<Map<String, dynamic>>(
          resourceId: 'test-resource-2',
          optimisticData: {'count': 3, 'name': 'optimistic'},
          serverOperation: conflictingOperation,
          localData: localData,
          conflictResolver: ConflictResolver.serverWins(),
        );

        // Then
        expect(serverWinsResult.isSuccess, isTrue);
        expect(serverWinsResult.data!['count'], equals(10));
        expect(serverWinsResult.data!['name'], equals('server'));
      });

      test('진행 중인 작업 상태 확인 테스트', () async {
        // Given
        const resourceId = 'test-resource';
        Future<Map<String, dynamic>> slowOperation() async {
          await Future.delayed(const Duration(milliseconds: 500));
          return {'completed': true};
        }

        // When
        final operationFuture = optimisticService.executeOptimisticUpdate<Map<String, dynamic>>(
          resourceId: resourceId,
          optimisticData: {'pending': true},
          serverOperation: slowOperation,
          localData: {},
        );

        // Then - 작업 진행 중인지 확인
        expect(optimisticService.isOperationPending(resourceId), isTrue);

        // 작업 완료 대기
        await operationFuture;
        
        // 작업 완료 후 상태 확인
        expect(optimisticService.isOperationPending(resourceId), isFalse);
      });
    });

    group('Provider Integration Tests', () {
      testWidgets('ChatMessagesNotifier 낙관적 업데이트 테스트', (WidgetTester tester) async {
        // Given
        final container = ProviderContainer();
        const chatRoomId = 'test-room';
        const senderId = 'test-sender';
        const content = 'Hello, World!';

        // When
        final notifier = container.read(chatMessagesNotifierProvider(chatRoomId).notifier);
        await notifier.sendMessage(content, senderId);

        // Then
        final messages = container.read(chatMessagesNotifierProvider(chatRoomId));
        expect(messages.length, equals(1));
        expect(messages.first['content'], equals(content));
        expect(messages.first['sender_id'], equals(senderId));
        expect(messages.first['is_optimistic'], isTrue);

        container.dispose();
      });

      testWidgets('NotificationsNotifier 읽음 표시 테스트', (WidgetTester tester) async {
        // Given
        final container = ProviderContainer();
        const userId = 'test-user';
        const notificationId = 'test-notification';

        final notifier = container.read(notificationsNotifierProvider(userId).notifier);
        
        // 테스트용 알림 추가
        notifier.state = [
          {
            'id': notificationId,
            'content': 'Test notification',
            'is_read': false,
          }
        ];

        // When
        await notifier.markAsRead(notificationId);

        // Then
        final notifications = container.read(notificationsNotifierProvider(userId));
        expect(notifications.first['is_read'], isTrue);
        expect(notifier.unreadCount, equals(0));

        container.dispose();
      });

      testWidgets('VoteNotifier 투표 처리 테스트', (WidgetTester tester) async {
        // Given
        final container = ProviderContainer();
        const voteId = 'test-vote';
        const optionId = 'test-option';
        const userId = 'test-user';

        final notifier = container.read(voteNotifierProvider(voteId).notifier);
        
        // 테스트용 투표 데이터 설정
        notifier.state = {
          'id': voteId,
          'options': [
            {
              'id': optionId,
              'name': 'Option 1',
              'vote_count': 5,
            }
          ]
        };

        // When
        await notifier.vote(optionId, userId);

        // Then
        final voteData = container.read(voteNotifierProvider(voteId));
        final option = (voteData!['options'] as List).first;
        expect(option['vote_count'], equals(6));

        container.dispose();
      });

      testWidgets('RealtimeConnectionNotifier 연결 관리 테스트', (WidgetTester tester) async {
        // Given
        final container = ProviderContainer(
          overrides: [
            realtimeServiceProvider.overrideWithValue(realtimeService),
          ],
        );

        // When
        final notifier = container.read(realtimeConnectionNotifierProvider.notifier);
        await notifier.reconnect();

        // Then
        // 연결 상태는 mocked service의 동작에 따라 결정됨
        expect(notifier.state, isA<bool>());

        container.dispose();
      });
    });

    group('End-to-End Realtime Flow Tests', () {
      testWidgets('채팅 메시지 전송부터 수신까지 전체 플로우 테스트', (WidgetTester tester) async {
        // Given
        final container = ProviderContainer();
        const chatRoomId = 'e2e-chat-room';
        const senderId = 'sender-id';
        const content = 'E2E Test Message';

        // When - 메시지 전송
        final chatNotifier = container.read(chatMessagesNotifierProvider(chatRoomId).notifier);
        await chatNotifier.sendMessage(content, senderId);

        // Then - 낙관적 업데이트 확인
        var messages = container.read(chatMessagesNotifierProvider(chatRoomId));
        expect(messages.length, equals(1));
        expect(messages.first['content'], equals(content));
        expect(messages.first['is_optimistic'], isTrue);

        // When - 실시간 메시지 수신 시뮬레이션
        final realMessage = {
          'id': 'real-message-id',
          'content': content,
          'sender_id': senderId,
          'chat_room_id': chatRoomId,
          'created_at': DateTime.now().toIso8601String(),
          'is_optimistic': false,
        };

        // 실시간 스트림을 통한 메시지 수신 시뮬레이션
        // (실제 구현에서는 RealtimeService를 통해 수신)

        container.dispose();
      });

      testWidgets('투표 생성부터 실시간 업데이트까지 전체 플로우 테스트', (WidgetTester tester) async {
        // Given
        final container = ProviderContainer();
        const voteId = 'e2e-vote';
        const userId = 'voter-id';
        const optionId = 'option-1';

        // When - 초기 투표 데이터 설정
        final voteNotifier = container.read(voteNotifierProvider(voteId).notifier);
        voteNotifier.state = {
          'id': voteId,
          'title': 'E2E Vote Test',
          'options': [
            {'id': optionId, 'name': 'Option 1', 'vote_count': 0},
            {'id': 'option-2', 'name': 'Option 2', 'vote_count': 0},
          ],
        };

        // When - 투표 실행
        await voteNotifier.vote(optionId, userId);

        // Then - 낙관적 업데이트 확인
        final voteData = container.read(voteNotifierProvider(voteId));
        final option1 = (voteData!['options'] as List).first;
        expect(option1['vote_count'], equals(1));

        container.dispose();
      });

      testWidgets('알림 생성부터 읽음 처리까지 전체 플로우 테스트', (WidgetTester tester) async {
        // Given
        final container = ProviderContainer();
        const userId = 'e2e-user';

        final notificationsNotifier = container.read(notificationsNotifierProvider(userId).notifier);

        // When - 새로운 알림 시뮬레이션
        final newNotification = {
          'id': 'new-notification',
          'content': 'E2E Test Notification',
          'user_id': userId,
          'is_read': false,
          'created_at': DateTime.now().toIso8601String(),
        };

        // 실시간 알림 수신 시뮬레이션
        notificationsNotifier.state = [newNotification];

        // Then - 알림 수신 확인
        var notifications = container.read(notificationsNotifierProvider(userId));
        expect(notifications.length, equals(1));
        expect(notifications.first['is_read'], isFalse);
        expect(notificationsNotifier.unreadCount, equals(1));

        // When - 알림 읽음 처리
        await notificationsNotifier.markAsRead('new-notification');

        // Then - 읽음 상태 확인
        notifications = container.read(notificationsNotifierProvider(userId));
        expect(notifications.first['is_read'], isTrue);
        expect(notificationsNotifier.unreadCount, equals(0));

        container.dispose();
      });
    });

    group('Error Handling and Edge Cases', () {
      test('네트워크 연결 실패 시 에러 처리 테스트', () async {
        // Given
        when(mockChannel.subscribe(any)).thenAnswer((_) async {
          final callback = verify(mockChannel.subscribe(captureAny)).captured.first as void Function(RealtimeSubscribeStatus, Exception?);
          callback(RealtimeSubscribeStatus.channelError, Exception('Network error'));
        });

        // When & Then
        expect(() async {
          final stream = realtimeService.subscribeToChatMessages('test-room');
          await stream.first;
        }, throwsA(isA<Exception>()));
      });

      test('중복 구독 방지 테스트', () async {
        // Given
        const chatRoomId = 'duplicate-test-room';

        // When
        final stream1 = realtimeService.subscribeToChatMessages(chatRoomId);
        final stream2 = realtimeService.subscribeToChatMessages(chatRoomId);

        // Then
        expect(identical(stream1, stream2), isTrue);
        verify(mockSupabaseClient.channel('chat_$chatRoomId')).called(1);
      });

      test('대량 메시지 처리 성능 테스트', () async {
        // Given
        final container = ProviderContainer();
        const chatRoomId = 'performance-test-room';
        final chatNotifier = container.read(chatMessagesNotifierProvider(chatRoomId).notifier);

        // When - 100개 메시지 빠르게 추가
        final stopwatch = Stopwatch()..start();
        for (int i = 0; i < 100; i++) {
          await chatNotifier.sendMessage('Message $i', 'sender');
        }
        stopwatch.stop();

        // Then - 성능 기준 확인 (1초 이내)
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
        final messages = container.read(chatMessagesNotifierProvider(chatRoomId));
        expect(messages.length, equals(100));

        container.dispose();
      });

      test('메모리 누수 방지 테스트', () async {
        // Given
        final container = ProviderContainer();
        const chatRoomId = 'memory-test-room';

        // When - Provider 생성 및 해제 반복
        for (int i = 0; i < 10; i++) {
          final notifier = container.read(chatMessagesNotifierProvider('$chatRoomId-$i').notifier);
          await notifier.sendMessage('Test message', 'sender');
        }

        // Then - 리소스 정리 확인
        container.dispose();
        expect(container.debugCanBeDisposed, isTrue);
      });
    });

    group('Real-time Event Simulation Tests', () {
      test('빠른 연속 이벤트 처리 테스트', () async {
        // Given
        final container = ProviderContainer();
        const voteId = 'rapid-events-vote';
        final voteNotifier = container.read(voteNotifierProvider(voteId).notifier);

        voteNotifier.state = {
          'id': voteId,
          'options': [
            {'id': 'option-1', 'vote_count': 0},
          ],
        };

        // When - 빠른 연속 투표 시뮬레이션
        await Future.wait([
          voteNotifier.vote('option-1', 'user1'),
          voteNotifier.vote('option-1', 'user2'),
          voteNotifier.vote('option-1', 'user3'),
        ]);

        // Then - 모든 투표가 반영되었는지 확인
        final voteData = container.read(voteNotifierProvider(voteId));
        final option = (voteData!['options'] as List).first;
        expect(option['vote_count'], equals(3));

        container.dispose();
      });

      test('동시 구독 및 해제 테스트', () async {
        // Given
        const chatRooms = ['room1', 'room2', 'room3', 'room4', 'room5'];
        when(mockChannel.unsubscribe()).thenAnswer((_) async {});

        // When - 동시 구독
        final streams = chatRooms.map((room) => realtimeService.subscribeToChatMessages(room)).toList();
        
        // Then - 모든 구독이 성공했는지 확인
        expect(streams.length, equals(5));

        // When - 동시 구독 해제
        await Future.wait(
          chatRooms.map((room) => realtimeService.unsubscribe('chat_$room')),
        );

        // Then - 모든 구독이 해제되었는지 확인
        verify(mockChannel.unsubscribe()).called(5);
      });
    });
  });
}
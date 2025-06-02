import 'dart:async';

import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:rxdart/rxdart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Supabase 실시간 기능을 관리하는 서비스
/// 채팅, 알림, 투표/댓글 등의 실시간 업데이트를 처리합니다.
class RealtimeService {
  static final RealtimeService _instance = RealtimeService._internal();
  factory RealtimeService() => _instance;
  RealtimeService._internal();

  final Map<String, RealtimeChannel> _channels = {};
  final Map<String, StreamController> _controllers = {};
  final BehaviorSubject<bool> _connectionStatusSubject = BehaviorSubject<bool>.seeded(false);

  /// 연결 상태 스트림
  Stream<bool> get connectionStatus => _connectionStatusSubject.stream;

  /// 현재 연결 상태
  bool get isConnected => _connectionStatusSubject.value;

  /// 실시간 서비스 초기화
  Future<void> initialize() async {
    try {
      logger.i('🔌 Realtime Service 초기화 시작');
      
      // Supabase 연결 상태 모니터링
      supabase.channel('system').onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        callback: (payload) {
          // 연결 테스트용 더미 콜백
        },
      ).subscribe((status, error) {
        if (status == RealtimeSubscribeStatus.subscribed) {
          _connectionStatusSubject.add(true);
          logger.i('✅ Supabase Realtime 연결 성공');
        } else if (status == RealtimeSubscribeStatus.channelError) {
          _connectionStatusSubject.add(false);
          logger.e('❌ Supabase Realtime 연결 실패', error: error);
        }
      });

      logger.i('✅ Realtime Service 초기화 완료');
    } catch (e, stackTrace) {
      logger.e('❌ Realtime Service 초기화 실패', error: e, stackTrace: stackTrace);
      _connectionStatusSubject.add(false);
      rethrow;
    }
  }

  /// 채팅 메시지 실시간 구독
  Stream<Map<String, dynamic>> subscribeToChatMessages(String chatRoomId) {
    final channelName = 'chat_$chatRoomId';
    
    if (_controllers.containsKey(channelName)) {
      return _controllers[channelName]!.stream.cast<Map<String, dynamic>>();
    }

    final controller = StreamController<Map<String, dynamic>>.broadcast();
    _controllers[channelName] = controller;

    try {
      final channel = supabase.channel(channelName);
      _channels[channelName] = channel;

      channel.onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'chat_messages',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'chat_room_id',
          value: chatRoomId,
        ),
        callback: (payload) {
          logger.d('📩 새로운 채팅 메시지: ${payload.newRecord}');
          controller.add(payload.newRecord);
        },
      );

      channel.subscribe((status, error) {
        if (status == RealtimeSubscribeStatus.subscribed) {
          logger.i('✅ 채팅방 구독 성공: $chatRoomId');
        } else if (status == RealtimeSubscribeStatus.channelError) {
          logger.e('❌ 채팅방 구독 실패: $chatRoomId', error: error);
          controller.addError(error ?? Exception('Chat subscription failed'));
        }
      });

    } catch (e, stackTrace) {
      logger.e('❌ 채팅 구독 설정 실패', error: e, stackTrace: stackTrace);
      controller.addError(e);
    }

    return controller.stream;
  }

  /// 알림 실시간 구독
  Stream<Map<String, dynamic>> subscribeToNotifications(String userId) {
    final channelName = 'notifications_$userId';
    
    if (_controllers.containsKey(channelName)) {
      return _controllers[channelName]!.stream.cast<Map<String, dynamic>>();
    }

    final controller = StreamController<Map<String, dynamic>>.broadcast();
    _controllers[channelName] = controller;

    try {
      final channel = supabase.channel(channelName);
      _channels[channelName] = channel;

      channel.onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'notifications',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: userId,
        ),
        callback: (payload) {
          logger.d('🔔 새로운 알림: ${payload.newRecord}');
          controller.add(payload.newRecord);
        },
      );

      // 알림 상태 업데이트도 구독
      channel.onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'notifications',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'user_id',
          value: userId,
        ),
        callback: (payload) {
          logger.d('🔔 알림 상태 업데이트: ${payload.newRecord}');
          controller.add(payload.newRecord);
        },
      );

      channel.subscribe((status, error) {
        if (status == RealtimeSubscribeStatus.subscribed) {
          logger.i('✅ 알림 구독 성공: $userId');
        } else if (status == RealtimeSubscribeStatus.channelError) {
          logger.e('❌ 알림 구독 실패: $userId', error: error);
          controller.addError(error ?? Exception('Notification subscription failed'));
        }
      });

    } catch (e, stackTrace) {
      logger.e('❌ 알림 구독 설정 실패', error: e, stackTrace: stackTrace);
      controller.addError(e);
    }

    return controller.stream;
  }

  /// 투표/댓글 실시간 구독
  Stream<Map<String, dynamic>> subscribeToVoteUpdates(String voteId) {
    final channelName = 'vote_$voteId';
    
    if (_controllers.containsKey(channelName)) {
      return _controllers[channelName]!.stream.cast<Map<String, dynamic>>();
    }

    final controller = StreamController<Map<String, dynamic>>.broadcast();
    _controllers[channelName] = controller;

    try {
      final channel = supabase.channel(channelName);
      _channels[channelName] = channel;

      // 투표 정보 업데이트 구독
      channel.onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'votes',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'id',
          value: voteId,
        ),
        callback: (payload) {
          logger.d('🗳️ 투표 정보 업데이트: ${payload.newRecord}');
          controller.add({
            'type': 'vote_update',
            'data': payload.newRecord,
          });
        },
      );

      // 새로운 댓글 구독
      channel.onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'vote_comments',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'vote_id',
          value: voteId,
        ),
        callback: (payload) {
          logger.d('💬 새로운 댓글: ${payload.newRecord}');
          controller.add({
            'type': 'comment_insert',
            'data': payload.newRecord,
          });
        },
      );

      // 댓글 업데이트 구독
      channel.onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'vote_comments',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'vote_id',
          value: voteId,
        ),
        callback: (payload) {
          logger.d('💬 댓글 업데이트: ${payload.newRecord}');
          controller.add({
            'type': 'comment_update',
            'data': payload.newRecord,
          });
        },
      );

      channel.subscribe((status, error) {
        if (status == RealtimeSubscribeStatus.subscribed) {
          logger.i('✅ 투표 구독 성공: $voteId');
        } else if (status == RealtimeSubscribeStatus.channelError) {
          logger.e('❌ 투표 구독 실패: $voteId', error: error);
          controller.addError(error ?? Exception('Vote subscription failed'));
        }
      });

    } catch (e, stackTrace) {
      logger.e('❌ 투표 구독 설정 실패', error: e, stackTrace: stackTrace);
      controller.addError(e);
    }

    return controller.stream;
  }

  /// 포스트 실시간 구독 (좋아요, 댓글 수 등)
  Stream<Map<String, dynamic>> subscribeToPostUpdates(String postId) {
    final channelName = 'post_$postId';
    
    if (_controllers.containsKey(channelName)) {
      return _controllers[channelName]!.stream.cast<Map<String, dynamic>>();
    }

    final controller = StreamController<Map<String, dynamic>>.broadcast();
    _controllers[channelName] = controller;

    try {
      final channel = supabase.channel(channelName);
      _channels[channelName] = channel;

      // 포스트 좋아요 변경 구독
      channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'post_likes',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'post_id',
          value: postId,
        ),
        callback: (payload) {
          logger.d('❤️ 포스트 좋아요 변경: ${payload.eventType}');
          controller.add({
            'type': 'like_${payload.eventType.name}',
            'data': payload.newRecord ?? payload.oldRecord,
          });
        },
      );

      // 포스트 댓글 변경 구독
      channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'post_comments',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'post_id',
          value: postId,
        ),
        callback: (payload) {
          logger.d('💬 포스트 댓글 변경: ${payload.eventType}');
          controller.add({
            'type': 'comment_${payload.eventType.name}',
            'data': payload.newRecord ?? payload.oldRecord,
          });
        },
      );

      channel.subscribe((status, error) {
        if (status == RealtimeSubscribeStatus.subscribed) {
          logger.i('✅ 포스트 구독 성공: $postId');
        } else if (status == RealtimeSubscribeStatus.channelError) {
          logger.e('❌ 포스트 구독 실패: $postId', error: error);
          controller.addError(error ?? Exception('Post subscription failed'));
        }
      });

    } catch (e, stackTrace) {
      logger.e('❌ 포스트 구독 설정 실패', error: e, stackTrace: stackTrace);
      controller.addError(e);
    }

    return controller.stream;
  }

  /// 특정 채널 구독 해제
  Future<void> unsubscribe(String channelName) async {
    try {
      final channel = _channels[channelName];
      if (channel != null) {
        await channel.unsubscribe();
        _channels.remove(channelName);
        logger.i('✅ 채널 구독 해제: $channelName');
      }

      final controller = _controllers[channelName];
      if (controller != null) {
        await controller.close();
        _controllers.remove(channelName);
      }
    } catch (e, stackTrace) {
      logger.e('❌ 채널 구독 해제 실패: $channelName', error: e, stackTrace: stackTrace);
    }
  }

  /// 모든 구독 해제
  Future<void> unsubscribeAll() async {
    logger.i('🔌 모든 실시간 구독 해제 시작');
    
    final channelNames = List<String>.from(_channels.keys);
    await Future.wait(
      channelNames.map((channelName) => unsubscribe(channelName)),
    );

    _connectionStatusSubject.add(false);
    logger.i('✅ 모든 실시간 구독 해제 완료');
  }

  /// 연결 재시도
  Future<void> reconnect() async {
    logger.i('🔄 Realtime 연결 재시도');
    
    // 기존 연결 정리
    await unsubscribeAll();
    
    // 잠시 대기 후 재연결
    await Future.delayed(const Duration(seconds: 1));
    
    // 재초기화
    await initialize();
  }

  /// 리소스 정리
  void dispose() {
    logger.i('🧹 Realtime Service 리소스 정리');
    
    // 모든 구독 해제 (동기적으로)
    for (final channel in _channels.values) {
      channel.unsubscribe();
    }
    _channels.clear();

    // 모든 컨트롤러 닫기
    for (final controller in _controllers.values) {
      controller.close();
    }
    _controllers.clear();

    // 연결 상태 스트림 닫기
    _connectionStatusSubject.close();
  }
}
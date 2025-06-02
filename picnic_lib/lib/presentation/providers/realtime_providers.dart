import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/core/services/realtime_service.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:rxdart/rxdart.dart';

/// RealtimeService 인스턴스 Provider
final realtimeServiceProvider = Provider<RealtimeService>((ref) {
  final service = RealtimeService();
  
  // Provider가 dispose될 때 서비스 정리
  ref.onDispose(() {
    service.dispose();
  });
  
  return service;
});

/// 실시간 연결 상태 Provider
final realtimeConnectionProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(realtimeServiceProvider);
  return service.connectionStatus;
});

/// 채팅 메시지 실시간 Provider
final chatMessagesProvider = StreamProvider.family<Map<String, dynamic>, String>((ref, chatRoomId) {
  final service = ref.watch(realtimeServiceProvider);
  
  // 채팅방 구독
  final stream = service.subscribeToChatMessages(chatRoomId);
  
  // Provider가 dispose될 때 구독 해제
  ref.onDispose(() {
    service.unsubscribe('chat_$chatRoomId');
  });
  
  return stream;
});

/// 알림 실시간 Provider
final notificationsProvider = StreamProvider.family<Map<String, dynamic>, String>((ref, userId) {
  final service = ref.watch(realtimeServiceProvider);
  
  // 알림 구독
  final stream = service.subscribeToNotifications(userId);
  
  // Provider가 dispose될 때 구독 해제
  ref.onDispose(() {
    service.unsubscribe('notifications_$userId');
  });
  
  return stream;
});

/// 투표 업데이트 실시간 Provider
final voteUpdatesProvider = StreamProvider.family<Map<String, dynamic>, String>((ref, voteId) {
  final service = ref.watch(realtimeServiceProvider);
  
  // 투표 구독
  final stream = service.subscribeToVoteUpdates(voteId);
  
  // Provider가 dispose될 때 구독 해제
  ref.onDispose(() {
    service.unsubscribe('vote_$voteId');
  });
  
  return stream;
});

/// 포스트 업데이트 실시간 Provider
final postUpdatesProvider = StreamProvider.family<Map<String, dynamic>, String>((ref, postId) {
  final service = ref.watch(realtimeServiceProvider);
  
  // 포스트 구독
  final stream = service.subscribeToPostUpdates(postId);
  
  // Provider가 dispose될 때 구독 해제
  ref.onDispose(() {
    service.unsubscribe('post_$postId');
  });
  
  return stream;
});

/// 실시간 채팅 메시지 상태 관리 Provider
class ChatMessagesNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  ChatMessagesNotifier(this.ref, this.chatRoomId) : super([]) {
    _initialize();
  }
  
  final Ref ref;
  final String chatRoomId;
  
  void _initialize() {
    // 초기 메시지 로드 (필요시)
    _loadInitialMessages();
    
    // 실시간 메시지 구독
    ref.listen(chatMessagesProvider(chatRoomId), (previous, next) {
      next.whenData((message) {
        _addMessage(message);
      });
    });
  }
  
  Future<void> _loadInitialMessages() async {
    try {
      // TODO: Supabase에서 초기 메시지 로드
      logger.d('채팅 초기 메시지 로드: $chatRoomId');
    } catch (e) {
      logger.e('채팅 초기 메시지 로드 실패', error: e);
    }
  }
  
  void _addMessage(Map<String, dynamic> message) {
    state = [...state, message];
  }
  
  /// 메시지 전송 (낙관적 업데이트)
  Future<void> sendMessage(String content, String senderId) async {
    final optimisticMessage = {
      'id': 'temp_${DateTime.now().millisecondsSinceEpoch}',
      'content': content,
      'sender_id': senderId,
      'chat_room_id': chatRoomId,
      'created_at': DateTime.now().toIso8601String(),
      'is_optimistic': true,
    };
    
    // 낙관적 업데이트
    _addMessage(optimisticMessage);
    
    try {
      // TODO: Supabase에 메시지 저장
      logger.d('메시지 전송: $content');
      
      // 성공 시 낙관적 메시지 제거 (실시간으로 받은 메시지로 대체됨)
      _removeOptimisticMessage(optimisticMessage['id'] as String);
    } catch (e) {
      logger.e('메시지 전송 실패', error: e);
      // 실패 시 낙관적 메시지 제거
      _removeOptimisticMessage(optimisticMessage['id'] as String);
      rethrow;
    }
  }
  
  void _removeOptimisticMessage(String tempId) {
    state = state.where((message) => message['id'] != tempId).toList();
  }
}

/// 채팅 메시지 상태 Provider
final chatMessagesNotifierProvider = StateNotifierProvider.family<ChatMessagesNotifier, List<Map<String, dynamic>>, String>((ref, chatRoomId) {
  return ChatMessagesNotifier(ref, chatRoomId);
});

/// 알림 상태 관리 Provider
class NotificationsNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  NotificationsNotifier(this.ref, this.userId) : super([]) {
    _initialize();
  }
  
  final Ref ref;
  final String userId;
  
  void _initialize() {
    // 초기 알림 로드
    _loadInitialNotifications();
    
    // 실시간 알림 구독
    ref.listen(notificationsProvider(userId), (previous, next) {
      next.whenData((notification) {
        _addOrUpdateNotification(notification);
      });
    });
  }
  
  Future<void> _loadInitialNotifications() async {
    try {
      // TODO: Supabase에서 초기 알림 로드
      logger.d('알림 초기 데이터 로드: $userId');
    } catch (e) {
      logger.e('알림 초기 데이터 로드 실패', error: e);
    }
  }
  
  void _addOrUpdateNotification(Map<String, dynamic> notification) {
    final existingIndex = state.indexWhere((n) => n['id'] == notification['id']);
    
    if (existingIndex >= 0) {
      // 기존 알림 업데이트
      final updatedList = [...state];
      updatedList[existingIndex] = notification;
      state = updatedList;
    } else {
      // 새 알림 추가 (최신 순으로)
      state = [notification, ...state];
    }
  }
  
  /// 알림 읽음 표시
  Future<void> markAsRead(String notificationId) async {
    try {
      // 낙관적 업데이트
      final updatedList = state.map((notification) {
        if (notification['id'] == notificationId) {
          return {...notification, 'is_read': true};
        }
        return notification;
      }).toList();
      state = updatedList;
      
      // TODO: Supabase에 읽음 상태 업데이트
      logger.d('알림 읽음 표시: $notificationId');
    } catch (e) {
      logger.e('알림 읽음 표시 실패', error: e);
      // 실패 시 상태 롤백
      _loadInitialNotifications();
    }
  }
  
  /// 모든 알림 읽음 표시
  Future<void> markAllAsRead() async {
    try {
      // 낙관적 업데이트
      final updatedList = state.map((notification) {
        return {...notification, 'is_read': true};
      }).toList();
      state = updatedList;
      
      // TODO: Supabase에 모든 알림 읽음 상태 업데이트
      logger.d('모든 알림 읽음 표시: $userId');
    } catch (e) {
      logger.e('모든 알림 읽음 표시 실패', error: e);
      // 실패 시 상태 롤백
      _loadInitialNotifications();
    }
  }
  
  /// 읽지 않은 알림 수
  int get unreadCount => state.where((n) => n['is_read'] != true).length;
}

/// 알림 상태 Provider
final notificationsNotifierProvider = StateNotifierProvider.family<NotificationsNotifier, List<Map<String, dynamic>>, String>((ref, userId) {
  return NotificationsNotifier(ref, userId);
});

/// 투표 상태 관리 Provider
class VoteNotifier extends StateNotifier<Map<String, dynamic>?> {
  VoteNotifier(this.ref, this.voteId) : super(null) {
    _initialize();
  }
  
  final Ref ref;
  final String voteId;
  
  void _initialize() {
    // 초기 투표 데이터 로드
    _loadInitialVoteData();
    
    // 실시간 투표 업데이트 구독
    ref.listen(voteUpdatesProvider(voteId), (previous, next) {
      next.whenData((update) {
        _handleVoteUpdate(update);
      });
    });
  }
  
  Future<void> _loadInitialVoteData() async {
    try {
      // TODO: Supabase에서 초기 투표 데이터 로드
      logger.d('투표 초기 데이터 로드: $voteId');
    } catch (e) {
      logger.e('투표 초기 데이터 로드 실패', error: e);
    }
  }
  
  void _handleVoteUpdate(Map<String, dynamic> update) {
    final type = update['type'] as String;
    final data = update['data'] as Map<String, dynamic>;
    
    switch (type) {
      case 'vote_update':
        _updateVoteData(data);
        break;
      case 'comment_insert':
        _addComment(data);
        break;
      case 'comment_update':
        _updateComment(data);
        break;
    }
  }
  
  void _updateVoteData(Map<String, dynamic> voteData) {
    if (state != null) {
      state = {...state!, ...voteData};
    } else {
      state = voteData;
    }
  }
  
  void _addComment(Map<String, dynamic> comment) {
    if (state != null) {
      final comments = List<Map<String, dynamic>>.from(state!['comments'] ?? []);
      comments.add(comment);
      state = {...state!, 'comments': comments};
    }
  }
  
  void _updateComment(Map<String, dynamic> updatedComment) {
    if (state != null) {
      final comments = List<Map<String, dynamic>>.from(state!['comments'] ?? []);
      final index = comments.indexWhere((c) => c['id'] == updatedComment['id']);
      if (index >= 0) {
        comments[index] = updatedComment;
        state = {...state!, 'comments': comments};
      }
    }
  }
  
  /// 투표하기 (낙관적 업데이트)
  Future<void> vote(String optionId, String userId) async {
    try {
      // 낙관적 업데이트
      if (state != null) {
        final options = List<Map<String, dynamic>>.from(state!['options'] ?? []);
        final optionIndex = options.indexWhere((o) => o['id'] == optionId);
        if (optionIndex >= 0) {
          options[optionIndex] = {
            ...options[optionIndex],
            'vote_count': (options[optionIndex]['vote_count'] ?? 0) + 1,
          };
          state = {...state!, 'options': options};
        }
      }
      
      // TODO: Supabase에 투표 저장
      logger.d('투표 처리: $optionId');
    } catch (e) {
      logger.e('투표 처리 실패', error: e);
      // 실패 시 상태 롤백
      _loadInitialVoteData();
      rethrow;
    }
  }
}

/// 투표 상태 Provider
final voteNotifierProvider = StateNotifierProvider.family<VoteNotifier, Map<String, dynamic>?, String>((ref, voteId) {
  return VoteNotifier(ref, voteId);
});

/// 실시간 연결 관리 Provider
class RealtimeConnectionNotifier extends StateNotifier<bool> {
  RealtimeConnectionNotifier(this.ref) : super(false) {
    _initialize();
  }
  
  final Ref ref;
  late final RealtimeService _service;
  
  void _initialize() {
    _service = ref.read(realtimeServiceProvider);
    
    // 연결 상태 구독
    ref.listen(realtimeConnectionProvider, (previous, next) {
      next.whenData((isConnected) {
        state = isConnected;
      });
    });
    
    // 서비스 초기화
    _initializeService();
  }
  
  Future<void> _initializeService() async {
    try {
      await _service.initialize();
    } catch (e) {
      logger.e('실시간 서비스 초기화 실패', error: e);
    }
  }
  
  /// 연결 재시도
  Future<void> reconnect() async {
    try {
      await _service.reconnect();
    } catch (e) {
      logger.e('실시간 연결 재시도 실패', error: e);
    }
  }
}

/// 실시간 연결 관리 Provider
final realtimeConnectionNotifierProvider = StateNotifierProvider<RealtimeConnectionNotifier, bool>((ref) {
  return RealtimeConnectionNotifier(ref);
});
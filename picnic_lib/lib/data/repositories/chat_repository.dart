import 'package:picnic_lib/data/repositories/base_repository.dart';
import 'package:picnic_lib/core/utils/logger.dart';

class ChatMessage {
  final String id;
  final String chatRoomId;
  final String userId;
  final String content;
  final String messageType;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isDeleted;

  ChatMessage({
    required this.id,
    required this.chatRoomId,
    required this.userId,
    required this.content,
    this.messageType = 'text',
    this.metadata,
    required this.createdAt,
    this.updatedAt,
    this.isDeleted = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      chatRoomId: json['chat_room_id'] as String,
      userId: json['user_id'] as String,
      content: json['content'] as String,
      messageType: json['message_type'] as String? ?? 'text',
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String) 
          : null,
      isDeleted: json['is_deleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chat_room_id': chatRoomId,
      'user_id': userId,
      'content': content,
      'message_type': messageType,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_deleted': isDeleted,
    };
  }

  ChatMessage copyWith({
    String? id,
    String? chatRoomId,
    String? userId,
    String? content,
    String? messageType,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      chatRoomId: chatRoomId ?? this.chatRoomId,
      userId: userId ?? this.userId,
      content: content ?? this.content,
      messageType: messageType ?? this.messageType,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}

class ChatRoom {
  final String id;
  final String name;
  final String type;
  final List<String> participants;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final ChatMessage? lastMessage;

  ChatRoom({
    required this.id,
    required this.name,
    required this.type,
    required this.participants,
    this.metadata,
    required this.createdAt,
    this.updatedAt,
    this.lastMessage,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      participants: List<String>.from(json['participants'] ?? []),
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'] as String) 
          : null,
      lastMessage: json['last_message'] != null 
          ? ChatMessage.fromJson(json['last_message']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'participants': participants,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'last_message': lastMessage?.toJson(),
    };
  }

  ChatRoom copyWith({
    String? id,
    String? name,
    String? type,
    List<String>? participants,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
    ChatMessage? lastMessage,
  }) {
    return ChatRoom(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      participants: participants ?? this.participants,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastMessage: lastMessage ?? this.lastMessage,
    );
  }
}

class ChatRepository extends BaseRepository {
  static const String _chatRoomsTable = 'chat_rooms';
  static const String _chatMessagesTable = 'chat_messages';
  static const String _chatParticipantsTable = 'chat_participants';

  // Chat room operations
  Future<List<ChatRoom>> getChatRooms({
    int? limit,
    int? offset,
  }) async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) {
        throw RepositoryException('User must be authenticated to get chat rooms');
      }

      var query = supabase.from(_chatRoomsTable).select('''
        *,
        participants:chat_participants(user_id),
        last_message:chat_messages(content, created_at, user_id)
      ''');

      // Join with participants to filter user's chat rooms
      query = query.inFilter('id', [
        // Subquery to get chat room IDs where user is a participant
      ]);

      if (limit != null) {
        query = query.limit(limit);
      }

      if (offset != null) {
        query = query.range(offset, offset + (limit ?? 20) - 1);
      }

      final response = await executeQuery(
        () => query.order('updated_at', ascending: false),
        'getChatRooms',
      );

      return response.map((data) => ChatRoom.fromJson(data)).toList();
    } catch (e) {
      logger.e('Error getting chat rooms: $e');
      throw RepositoryException('Failed to get chat rooms', originalError: e);
    }
  }

  Future<ChatRoom?> getChatRoomById(String chatRoomId) async {
    try {
      final response = await executeQuery(
        () => supabase.from(_chatRoomsTable).select('''
          *,
          participants:chat_participants(user_id),
          last_message:chat_messages(content, created_at, user_id)
        ''').eq('id', chatRoomId).maybeSingle(),
        'getChatRoomById',
      );

      return response != null ? ChatRoom.fromJson(response) : null;
    } catch (e) {
      logger.e('Error getting chat room by ID: $e');
      throw RepositoryException('Failed to get chat room', originalError: e);
    }
  }

  Future<ChatRoom> createChatRoom({
    required String name,
    required String type,
    required List<String> participants,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) {
        throw RepositoryException('User must be authenticated to create chat room');
      }

      // Include the creator in participants if not already included
      final allParticipants = Set<String>.from(participants);
      allParticipants.add(userId);

      final chatRoomData = {
        'name': name,
        'type': type,
        'metadata': metadata,
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

      final response = await executeQuery(
        () => supabase.from(_chatRoomsTable).insert(chatRoomData).select().single(),
        'createChatRoom',
      );

      final chatRoom = ChatRoom.fromJson(response);

      // Add participants
      await _addParticipants(chatRoom.id, allParticipants.toList());

      return chatRoom.copyWith(participants: allParticipants.toList());
    } catch (e) {
      logger.e('Error creating chat room: $e');
      throw RepositoryException('Failed to create chat room', originalError: e);
    }
  }

  Future<void> deleteChatRoom(String chatRoomId) async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) {
        throw RepositoryException('User must be authenticated to delete chat room');
      }

      // Delete all messages in the chat room
      await executeQuery(
        () => supabase.from(_chatMessagesTable).delete().eq('chat_room_id', chatRoomId),
        'deleteChatRoomMessages',
      );

      // Delete all participants
      await executeQuery(
        () => supabase.from(_chatParticipantsTable).delete().eq('chat_room_id', chatRoomId),
        'deleteChatRoomParticipants',
      );

      // Delete the chat room
      await executeQuery(
        () => supabase.from(_chatRoomsTable).delete().eq('id', chatRoomId),
        'deleteChatRoom',
      );
    } catch (e) {
      logger.e('Error deleting chat room: $e');
      throw RepositoryException('Failed to delete chat room', originalError: e);
    }
  }

  // Message operations
  Future<List<ChatMessage>> getMessages({
    required String chatRoomId,
    int? limit,
    int? offset,
    DateTime? before,
    DateTime? after,
  }) async {
    try {
      var query = supabase.from(_chatMessagesTable)
          .select('*')
          .eq('chat_room_id', chatRoomId)
          .eq('is_deleted', false);

      if (before != null) {
        query = query.lt('created_at', before.toIso8601String());
      }

      if (after != null) {
        query = query.gt('created_at', after.toIso8601String());
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      if (offset != null) {
        query = query.range(offset, offset + (limit ?? 50) - 1);
      }

      final response = await executeQuery(
        () => query.order('created_at', ascending: false),
        'getMessages',
      );

      return response.map((data) => ChatMessage.fromJson(data)).toList();
    } catch (e) {
      logger.e('Error getting messages: $e');
      throw RepositoryException('Failed to get messages', originalError: e);
    }
  }

  Future<ChatMessage> sendMessage({
    required String chatRoomId,
    required String content,
    String messageType = 'text',
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) {
        throw RepositoryException('User must be authenticated to send message');
      }

      // Verify user is a participant of the chat room
      final isParticipant = await _isUserParticipant(chatRoomId, userId);
      if (!isParticipant) {
        throw RepositoryException('User is not a participant of this chat room');
      }

      final messageData = {
        'chat_room_id': chatRoomId,
        'user_id': userId,
        'content': content,
        'message_type': messageType,
        'metadata': metadata,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      };

      final response = await executeQuery(
        () => supabase.from(_chatMessagesTable).insert(messageData).select().single(),
        'sendMessage',
      );

      // Update chat room's last message timestamp
      await executeQuery(
        () => supabase.from(_chatRoomsTable).update({
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }).eq('id', chatRoomId),
        'updateChatRoomTimestamp',
      );

      return ChatMessage.fromJson(response);
    } catch (e) {
      logger.e('Error sending message: $e');
      throw RepositoryException('Failed to send message', originalError: e);
    }
  }

  Future<ChatMessage> updateMessage({
    required String messageId,
    required String content,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) {
        throw RepositoryException('User must be authenticated to update message');
      }

      final updateData = {
        'content': content,
        'metadata': metadata,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

      final response = await executeQuery(
        () => supabase.from(_chatMessagesTable)
            .update(updateData)
            .eq('id', messageId)
            .eq('user_id', userId)
            .select()
            .single(),
        'updateMessage',
      );

      return ChatMessage.fromJson(response);
    } catch (e) {
      logger.e('Error updating message: $e');
      throw RepositoryException('Failed to update message', originalError: e);
    }
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) {
        throw RepositoryException('User must be authenticated to delete message');
      }

      await executeQuery(
        () => supabase.from(_chatMessagesTable)
            .update({
              'is_deleted': true,
              'content': '[Message deleted]',
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            })
            .eq('id', messageId)
            .eq('user_id', userId),
        'deleteMessage',
      );
    } catch (e) {
      logger.e('Error deleting message: $e');
      throw RepositoryException('Failed to delete message', originalError: e);
    }
  }

  // Participant operations
  Future<void> addParticipant(String chatRoomId, String userId) async {
    try {
      await _addParticipants(chatRoomId, [userId]);
    } catch (e) {
      logger.e('Error adding participant: $e');
      throw RepositoryException('Failed to add participant', originalError: e);
    }
  }

  Future<void> removeParticipant(String chatRoomId, String userId) async {
    try {
      final currentUserId = getCurrentUserId();
      if (currentUserId == null) {
        throw RepositoryException('User must be authenticated to remove participant');
      }

      await executeQuery(
        () => supabase.from(_chatParticipantsTable)
            .delete()
            .eq('chat_room_id', chatRoomId)
            .eq('user_id', userId),
        'removeParticipant',
      );
    } catch (e) {
      logger.e('Error removing participant: $e');
      throw RepositoryException('Failed to remove participant', originalError: e);
    }
  }

  Future<List<String>> getParticipants(String chatRoomId) async {
    try {
      final response = await executeQuery(
        () => supabase.from(_chatParticipantsTable)
            .select('user_id')
            .eq('chat_room_id', chatRoomId),
        'getParticipants',
      );

      return response.map((data) => data['user_id'] as String).toList();
    } catch (e) {
      logger.e('Error getting participants: $e');
      throw RepositoryException('Failed to get participants', originalError: e);
    }
  }

  // Helper methods
  Future<void> _addParticipants(String chatRoomId, List<String> userIds) async {
    final participantData = userIds.map((userId) => {
      'chat_room_id': chatRoomId,
      'user_id': userId,
      'joined_at': DateTime.now().toUtc().toIso8601String(),
    }).toList();

    await executeQuery(
      () => supabase.from(_chatParticipantsTable).upsert(participantData),
      '_addParticipants',
    );
  }

  Future<bool> _isUserParticipant(String chatRoomId, String userId) async {
    try {
      final response = await executeQuery(
        () => supabase.from(_chatParticipantsTable)
            .select('id')
            .eq('chat_room_id', chatRoomId)
            .eq('user_id', userId)
            .maybeSingle(),
        '_isUserParticipant',
      );

      return response != null;
    } catch (e) {
      logger.e('Error checking if user is participant: $e');
      return false;
    }
  }

  // Stream operations for real-time updates
  Stream<List<ChatMessage>> streamMessages(String chatRoomId) {
    return supabase.from(_chatMessagesTable)
        .stream(primaryKey: ['id'])
        .eq('chat_room_id', chatRoomId)
        .eq('is_deleted', false)
        .order('created_at')
        .map((data) => 
          data.map((item) => ChatMessage.fromJson(item)).toList()
        );
  }

  Stream<List<ChatRoom>> streamChatRooms() {
    return supabase.from(_chatRoomsTable)
        .stream(primaryKey: ['id'])
        .order('updated_at', ascending: false)
        .map((data) => 
          data.map((item) => ChatRoom.fromJson(item)).toList()
        );
  }

  // Typing indicator operations
  Future<void> sendTypingIndicator(String chatRoomId) async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) return;

      // Send typing indicator via realtime channel
      final channel = supabase.channel('chat_room_$chatRoomId');
      await channel.sendBroadcastMessage(
        event: 'typing',
        payload: {
          'user_id': userId,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      logger.e('Error sending typing indicator: $e');
    }
  }

  Stream<Map<String, dynamic>> streamTypingIndicators(String chatRoomId) {
    final channel = supabase.channel('chat_room_$chatRoomId');
    
    return channel.onBroadcast(
      event: 'typing',
      callback: (payload) => payload,
    ).asyncMap((payload) => payload);
  }
}
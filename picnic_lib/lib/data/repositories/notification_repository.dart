import 'package:picnic_lib/data/repositories/base_repository.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String body;
  final String type;
  final Map<String, dynamic>? data;
  final bool isRead;
  final String priority;
  final DateTime createdAt;
  final DateTime? readAt;
  final DateTime? expiresAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.data,
    this.isRead = false,
    this.priority = 'normal',
    required this.createdAt,
    this.readAt,
    this.expiresAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      type: json['type'] as String,
      data: json['data'] as Map<String, dynamic>?,
      isRead: json['is_read'] as bool? ?? false,
      priority: json['priority'] as String? ?? 'normal',
      createdAt: DateTime.parse(json['created_at'] as String),
      readAt: json['read_at'] != null 
          ? DateTime.parse(json['read_at'] as String) 
          : null,
      expiresAt: json['expires_at'] != null 
          ? DateTime.parse(json['expires_at'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'body': body,
      'type': type,
      'data': data,
      'is_read': isRead,
      'priority': priority,
      'created_at': createdAt.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    String? type,
    Map<String, dynamic>? data,
    bool? isRead,
    String? priority,
    DateTime? createdAt,
    DateTime? readAt,
    DateTime? expiresAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}

class NotificationPreferences {
  final String userId;
  final bool pushEnabled;
  final bool emailEnabled;
  final bool inAppEnabled;
  final Map<String, bool> typePreferences;
  final DateTime? quietHoursStart;
  final DateTime? quietHoursEnd;
  final DateTime updatedAt;

  NotificationPreferences({
    required this.userId,
    this.pushEnabled = true,
    this.emailEnabled = true,
    this.inAppEnabled = true,
    this.typePreferences = const {},
    this.quietHoursStart,
    this.quietHoursEnd,
    required this.updatedAt,
  });

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    return NotificationPreferences(
      userId: json['user_id'] as String,
      pushEnabled: json['push_enabled'] as bool? ?? true,
      emailEnabled: json['email_enabled'] as bool? ?? true,
      inAppEnabled: json['in_app_enabled'] as bool? ?? true,
      typePreferences: Map<String, bool>.from(json['type_preferences'] ?? {}),
      quietHoursStart: json['quiet_hours_start'] != null 
          ? DateTime.parse(json['quiet_hours_start'] as String) 
          : null,
      quietHoursEnd: json['quiet_hours_end'] != null 
          ? DateTime.parse(json['quiet_hours_end'] as String) 
          : null,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'push_enabled': pushEnabled,
      'email_enabled': emailEnabled,
      'in_app_enabled': inAppEnabled,
      'type_preferences': typePreferences,
      'quiet_hours_start': quietHoursStart?.toIso8601String(),
      'quiet_hours_end': quietHoursEnd?.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class DeviceToken {
  final String userId;
  final String token;
  final String platform;
  final String? deviceId;
  final DateTime createdAt;
  final DateTime lastUsed;
  final bool isActive;

  DeviceToken({
    required this.userId,
    required this.token,
    required this.platform,
    this.deviceId,
    required this.createdAt,
    required this.lastUsed,
    this.isActive = true,
  });

  factory DeviceToken.fromJson(Map<String, dynamic> json) {
    return DeviceToken(
      userId: json['user_id'] as String,
      token: json['token'] as String,
      platform: json['platform'] as String,
      deviceId: json['device_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      lastUsed: DateTime.parse(json['last_used'] as String),
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'token': token,
      'platform': platform,
      'device_id': deviceId,
      'created_at': createdAt.toIso8601String(),
      'last_used': lastUsed.toIso8601String(),
      'is_active': isActive,
    };
  }
}

class NotificationRepository extends BaseRepository {
  static const String _notificationsTable = 'notifications';
  static const String _notificationPreferencesTable = 'notification_preferences';
  static const String _deviceTokensTable = 'device_tokens';

  // Notification operations
  Future<List<NotificationModel>> getNotifications({
    int? limit,
    int? offset,
    String? type,
    bool? isRead,
    bool includeExpired = false,
  }) async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) {
        throw RepositoryException('User must be authenticated to get notifications');
      }

      var query = supabase.from(_notificationsTable)
          .select('*')
          .eq('user_id', userId);

      if (type != null) {
        query = query.eq('type', type);
      }

      if (isRead != null) {
        query = query.eq('is_read', isRead);
      }

      if (!includeExpired) {
        query = query.or('expires_at.is.null,expires_at.gt.${DateTime.now().toIso8601String()}');
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      if (offset != null) {
        query = query.range(offset, offset + (limit ?? 20) - 1);
      }

      final response = await executeQuery(
        () => query.order('created_at', ascending: false),
        'getNotifications',
      );

      return response.map((data) => NotificationModel.fromJson(data)).toList();
    } catch (e) {
      logger.e('Error getting notifications: $e');
      throw RepositoryException('Failed to get notifications', originalError: e);
    }
  }

  Future<NotificationModel?> getNotificationById(String notificationId) async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) {
        throw RepositoryException('User must be authenticated to get notification');
      }

      final response = await executeQuery(
        () => supabase.from(_notificationsTable)
            .select('*')
            .eq('id', notificationId)
            .eq('user_id', userId)
            .maybeSingle(),
        'getNotificationById',
      );

      return response != null ? NotificationModel.fromJson(response) : null;
    } catch (e) {
      logger.e('Error getting notification by ID: $e');
      throw RepositoryException('Failed to get notification', originalError: e);
    }
  }

  Future<NotificationModel> createNotification({
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
    String priority = 'normal',
    DateTime? expiresAt,
    String? targetUserId,
  }) async {
    try {
      final userId = targetUserId ?? getCurrentUserId();
      if (userId == null) {
        throw RepositoryException('Target user ID is required');
      }

      final notificationData = {
        'user_id': userId,
        'title': title,
        'body': body,
        'type': type,
        'data': data,
        'priority': priority,
        'expires_at': expiresAt?.toIso8601String(),
        'created_at': DateTime.now().toUtc().toIso8601String(),
      };

      final response = await executeQuery(
        () => supabase.from(_notificationsTable).insert(notificationData).select().single(),
        'createNotification',
      );

      return NotificationModel.fromJson(response);
    } catch (e) {
      logger.e('Error creating notification: $e');
      throw RepositoryException('Failed to create notification', originalError: e);
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) {
        throw RepositoryException('User must be authenticated to mark notification as read');
      }

      await executeQuery(
        () => supabase.from(_notificationsTable)
            .update({
              'is_read': true,
              'read_at': DateTime.now().toUtc().toIso8601String(),
            })
            .eq('id', notificationId)
            .eq('user_id', userId),
        'markAsRead',
      );
    } catch (e) {
      logger.e('Error marking notification as read: $e');
      throw RepositoryException('Failed to mark notification as read', originalError: e);
    }
  }

  Future<void> markAllAsRead({String? type}) async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) {
        throw RepositoryException('User must be authenticated to mark notifications as read');
      }

      var query = supabase.from(_notificationsTable)
          .update({
            'is_read': true,
            'read_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('user_id', userId)
          .eq('is_read', false);

      if (type != null) {
        query = query.eq('type', type);
      }

      await executeQuery(() => query, 'markAllAsRead');
    } catch (e) {
      logger.e('Error marking all notifications as read: $e');
      throw RepositoryException('Failed to mark all notifications as read', originalError: e);
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) {
        throw RepositoryException('User must be authenticated to delete notification');
      }

      await executeQuery(
        () => supabase.from(_notificationsTable)
            .delete()
            .eq('id', notificationId)
            .eq('user_id', userId),
        'deleteNotification',
      );
    } catch (e) {
      logger.e('Error deleting notification: $e');
      throw RepositoryException('Failed to delete notification', originalError: e);
    }
  }

  Future<int> getUnreadCount({String? type}) async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) return 0;

      var query = supabase.from(_notificationsTable)
          .select('*', const FetchOptions(count: CountOption.exact))
          .eq('user_id', userId)
          .eq('is_read', false);

      if (type != null) {
        query = query.eq('type', type);
      }

      // Filter out expired notifications
      query = query.or('expires_at.is.null,expires_at.gt.${DateTime.now().toIso8601String()}');

      final response = await executeQuery(() => query, 'getUnreadCount');
      return (response as List).length;
    } catch (e) {
      logger.e('Error getting unread count: $e');
      return 0;
    }
  }

  // Notification preferences operations
  Future<NotificationPreferences> getNotificationPreferences() async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) {
        throw RepositoryException('User must be authenticated to get preferences');
      }

      final response = await executeQuery(
        () => supabase.from(_notificationPreferencesTable)
            .select('*')
            .eq('user_id', userId)
            .maybeSingle(),
        'getNotificationPreferences',
      );

      if (response != null) {
        return NotificationPreferences.fromJson(response);
      }

      // Return default preferences if none exist
      return NotificationPreferences(
        userId: userId,
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      logger.e('Error getting notification preferences: $e');
      throw RepositoryException('Failed to get notification preferences', originalError: e);
    }
  }

  Future<NotificationPreferences> updateNotificationPreferences({
    bool? pushEnabled,
    bool? emailEnabled,
    bool? inAppEnabled,
    Map<String, bool>? typePreferences,
    DateTime? quietHoursStart,
    DateTime? quietHoursEnd,
  }) async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) {
        throw RepositoryException('User must be authenticated to update preferences');
      }

      final updateData = <String, dynamic>{
        'user_id': userId,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

      if (pushEnabled != null) updateData['push_enabled'] = pushEnabled;
      if (emailEnabled != null) updateData['email_enabled'] = emailEnabled;
      if (inAppEnabled != null) updateData['in_app_enabled'] = inAppEnabled;
      if (typePreferences != null) updateData['type_preferences'] = typePreferences;
      if (quietHoursStart != null) updateData['quiet_hours_start'] = quietHoursStart.toIso8601String();
      if (quietHoursEnd != null) updateData['quiet_hours_end'] = quietHoursEnd.toIso8601String();

      final response = await executeQuery(
        () => supabase.from(_notificationPreferencesTable)
            .upsert(updateData)
            .select()
            .single(),
        'updateNotificationPreferences',
      );

      return NotificationPreferences.fromJson(response);
    } catch (e) {
      logger.e('Error updating notification preferences: $e');
      throw RepositoryException('Failed to update notification preferences', originalError: e);
    }
  }

  // Device token operations
  Future<void> registerDeviceToken({
    required String token,
    required String platform,
    String? deviceId,
  }) async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) {
        throw RepositoryException('User must be authenticated to register device token');
      }

      final tokenData = {
        'user_id': userId,
        'token': token,
        'platform': platform,
        'device_id': deviceId,
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'last_used': DateTime.now().toUtc().toIso8601String(),
        'is_active': true,
      };

      await executeQuery(
        () => supabase.from(_deviceTokensTable).upsert(tokenData),
        'registerDeviceToken',
      );
    } catch (e) {
      logger.e('Error registering device token: $e');
      throw RepositoryException('Failed to register device token', originalError: e);
    }
  }

  Future<void> unregisterDeviceToken(String token) async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) {
        throw RepositoryException('User must be authenticated to unregister device token');
      }

      await executeQuery(
        () => supabase.from(_deviceTokensTable)
            .update({'is_active': false})
            .eq('user_id', userId)
            .eq('token', token),
        'unregisterDeviceToken',
      );
    } catch (e) {
      logger.e('Error unregistering device token: $e');
      throw RepositoryException('Failed to unregister device token', originalError: e);
    }
  }

  Future<List<DeviceToken>> getActiveDeviceTokens() async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) {
        throw RepositoryException('User must be authenticated to get device tokens');
      }

      final response = await executeQuery(
        () => supabase.from(_deviceTokensTable)
            .select('*')
            .eq('user_id', userId)
            .eq('is_active', true)
            .order('last_used', ascending: false),
        'getActiveDeviceTokens',
      );

      return response.map((data) => DeviceToken.fromJson(data)).toList();
    } catch (e) {
      logger.e('Error getting active device tokens: $e');
      throw RepositoryException('Failed to get active device tokens', originalError: e);
    }
  }

  Future<void> updateDeviceTokenLastUsed(String token) async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) return;

      await executeQuery(
        () => supabase.from(_deviceTokensTable)
            .update({'last_used': DateTime.now().toUtc().toIso8601String()})
            .eq('user_id', userId)
            .eq('token', token),
        'updateDeviceTokenLastUsed',
      );
    } catch (e) {
      logger.e('Error updating device token last used: $e');
    }
  }

  // Bulk operations
  Future<void> createBulkNotifications(List<Map<String, dynamic>> notifications) async {
    try {
      await executeQuery(
        () => supabase.from(_notificationsTable).insert(notifications),
        'createBulkNotifications',
      );
    } catch (e) {
      logger.e('Error creating bulk notifications: $e');
      throw RepositoryException('Failed to create bulk notifications', originalError: e);
    }
  }

  Future<void> cleanupExpiredNotifications() async {
    try {
      await executeQuery(
        () => supabase.from(_notificationsTable)
            .delete()
            .lt('expires_at', DateTime.now().toIso8601String()),
        'cleanupExpiredNotifications',
      );
    } catch (e) {
      logger.e('Error cleaning up expired notifications: $e');
      throw RepositoryException('Failed to cleanup expired notifications', originalError: e);
    }
  }

  // Stream operations for real-time updates
  Stream<List<NotificationModel>> streamNotifications({String? type}) {
    final userId = getCurrentUserId();
    if (userId == null) {
      return Stream.value([]);
    }

    var query = supabase.from(_notificationsTable)
        .stream(primaryKey: ['id'])
        .eq('user_id', userId);

    if (type != null) {
      query = query.eq('type', type);
    }

    return query
        .order('created_at', ascending: false)
        .map((data) => 
          data.map((item) => NotificationModel.fromJson(item)).toList()
        );
  }

  Stream<int> streamUnreadCount({String? type}) {
    final userId = getCurrentUserId();
    if (userId == null) {
      return Stream.value(0);
    }

    var query = supabase.from(_notificationsTable)
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .eq('is_read', false);

    if (type != null) {
      query = query.eq('type', type);
    }

    return query.map((data) => data.length);
  }
}
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Push notification service for customizable notifications
class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  static const String _prefixKey = 'push_notification_';
  
  bool _isInitialized = false;
  bool _isEnabled = true;
  String? _deviceToken;
  
  // Notification categories and their settings
  final Map<NotificationCategory, NotificationSettings> _categorySettings = {};
  
  // Channel settings for different types
  final Map<String, NotificationChannel> _channels = {};
  
  // Scheduled notifications
  final Map<String, ScheduledNotification> _scheduledNotifications = {};
  
  // Notification history
  final List<NotificationRecord> _notificationHistory = [];
  
  // Sound and vibration patterns
  final Map<String, SoundPattern> _soundPatterns = {};
  final Map<String, VibrationPattern> _vibrationPatterns = {};
  
  // Quiet hours and DND settings
  bool _useQuietHours = false;
  TimeOfDay? _quietHoursStart;
  TimeOfDay? _quietHoursEnd;
  bool _useDoNotDisturb = false;
  Set<NotificationPriority> _allowedInDND = {NotificationPriority.urgent};
  
  // Stream controllers
  StreamController<NotificationEvent>? _notificationEventController;
  StreamController<NotificationInteraction>? _interactionController;

  /// Initialize push notification service
  Future<void> initialize() async {
    try {
      await _loadSettings();
      await _setupDefaultChannels();
      await _setupDefaultPatterns();
      _setupEventStreams();
      await _requestPermissions();
      _isInitialized = true;
      debugPrint('PushNotificationService initialized');
    } catch (e) {
      debugPrint('Failed to initialize PushNotificationService: $e');
    }
  }

  /// Load notification settings
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    _isEnabled = prefs.getBool('${_prefixKey}enabled') ?? true;
    _useQuietHours = prefs.getBool('${_prefixKey}use_quiet_hours') ?? false;
    _useDoNotDisturb = prefs.getBool('${_prefixKey}use_dnd') ?? false;
    
    // Load quiet hours
    final quietStartHour = prefs.getInt('${_prefixKey}quiet_start_hour');
    final quietStartMinute = prefs.getInt('${_prefixKey}quiet_start_minute');
    if (quietStartHour != null && quietStartMinute != null) {
      _quietHoursStart = TimeOfDay(hour: quietStartHour, minute: quietStartMinute);
    }
    
    final quietEndHour = prefs.getInt('${_prefixKey}quiet_end_hour');
    final quietEndMinute = prefs.getInt('${_prefixKey}quiet_end_minute');
    if (quietEndHour != null && quietEndMinute != null) {
      _quietHoursEnd = TimeOfDay(hour: quietEndHour, minute: quietEndMinute);
    }
    
    // Load category settings
    await _loadCategorySettings();
    
    // Load channels
    await _loadChannels();
    
    // Load device token
    _deviceToken = prefs.getString('${_prefixKey}device_token');
  }

  /// Load category settings
  Future<void> _loadCategorySettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    for (final category in NotificationCategory.values) {
      final categoryKey = '${_prefixKey}category_${category.name}';
      final settingsJson = prefs.getString(categoryKey);
      
      if (settingsJson != null) {
        try {
          final settingsMap = jsonDecode(settingsJson) as Map<String, dynamic>;
          _categorySettings[category] = NotificationSettings.fromJson(settingsMap);
        } catch (e) {
          debugPrint('Failed to load settings for category $category: $e');
          _categorySettings[category] = NotificationSettings.defaultForCategory(category);
        }
      } else {
        _categorySettings[category] = NotificationSettings.defaultForCategory(category);
      }
    }
  }

  /// Load notification channels
  Future<void> _loadChannels() async {
    final prefs = await SharedPreferences.getInstance();
    final channelsJson = prefs.getString('${_prefixKey}channels');
    
    if (channelsJson != null) {
      try {
        final channelsMap = jsonDecode(channelsJson) as Map<String, dynamic>;
        
        for (final entry in channelsMap.entries) {
          _channels[entry.key] = NotificationChannel.fromJson(entry.value);
        }
      } catch (e) {
        debugPrint('Failed to load channels: $e');
      }
    }
  }

  /// Save notification settings
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setBool('${_prefixKey}enabled', _isEnabled);
    await prefs.setBool('${_prefixKey}use_quiet_hours', _useQuietHours);
    await prefs.setBool('${_prefixKey}use_dnd', _useDoNotDisturb);
    
    // Save quiet hours
    if (_quietHoursStart != null) {
      await prefs.setInt('${_prefixKey}quiet_start_hour', _quietHoursStart!.hour);
      await prefs.setInt('${_prefixKey}quiet_start_minute', _quietHoursStart!.minute);
    }
    
    if (_quietHoursEnd != null) {
      await prefs.setInt('${_prefixKey}quiet_end_hour', _quietHoursEnd!.hour);
      await prefs.setInt('${_prefixKey}quiet_end_minute', _quietHoursEnd!.minute);
    }
    
    // Save category settings
    await _saveCategorySettings();
    
    // Save channels
    await _saveChannels();
    
    // Save device token
    if (_deviceToken != null) {
      await prefs.setString('${_prefixKey}device_token', _deviceToken!);
    }
  }

  /// Save category settings
  Future<void> _saveCategorySettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    for (final entry in _categorySettings.entries) {
      final categoryKey = '${_prefixKey}category_${entry.key.name}';
      await prefs.setString(categoryKey, jsonEncode(entry.value.toJson()));
    }
  }

  /// Save notification channels
  Future<void> _saveChannels() async {
    final prefs = await SharedPreferences.getInstance();
    
    final channelsMap = <String, dynamic>{};
    for (final entry in _channels.entries) {
      channelsMap[entry.key] = entry.value.toJson();
    }
    
    await prefs.setString('${_prefixKey}channels', jsonEncode(channelsMap));
  }

  /// Setup default notification channels
  Future<void> _setupDefaultChannels() async {
    // General notifications
    _channels['general'] = NotificationChannel(
      id: 'general',
      name: 'General Notifications',
      description: 'General app notifications',
      importance: NotificationImportance.defaultImportance,
      showBadge: true,
      enableSound: true,
      enableVibration: true,
    );

    // Messages
    _channels['messages'] = NotificationChannel(
      id: 'messages',
      name: 'Messages',
      description: 'New message notifications',
      importance: NotificationImportance.high,
      showBadge: true,
      enableSound: true,
      enableVibration: true,
      soundPattern: 'message_tone',
    );

    // Social interactions
    _channels['social'] = NotificationChannel(
      id: 'social',
      name: 'Social',
      description: 'Likes, comments, and social interactions',
      importance: NotificationImportance.defaultImportance,
      showBadge: true,
      enableSound: true,
      enableVibration: false,
    );

    // System updates
    _channels['system'] = NotificationChannel(
      id: 'system',
      name: 'System',
      description: 'System updates and maintenance',
      importance: NotificationImportance.low,
      showBadge: false,
      enableSound: false,
      enableVibration: false,
    );

    // Promotions
    _channels['promotions'] = NotificationChannel(
      id: 'promotions',
      name: 'Promotions',
      description: 'Promotional offers and marketing',
      importance: NotificationImportance.low,
      showBadge: false,
      enableSound: false,
      enableVibration: false,
    );
  }

  /// Setup default sound and vibration patterns
  Future<void> _setupDefaultPatterns() async {
    // Sound patterns
    _soundPatterns['default'] = SoundPattern(
      id: 'default',
      name: 'Default',
      asset: 'sounds/notification_default.mp3',
      duration: Duration(milliseconds: 500),
    );

    _soundPatterns['message_tone'] = SoundPattern(
      id: 'message_tone',
      name: 'Message Tone',
      asset: 'sounds/message_tone.mp3',
      duration: Duration(milliseconds: 800),
    );

    _soundPatterns['gentle_chime'] = SoundPattern(
      id: 'gentle_chime',
      name: 'Gentle Chime',
      asset: 'sounds/gentle_chime.mp3',
      duration: Duration(milliseconds: 600),
    );

    // Vibration patterns
    _vibrationPatterns['default'] = VibrationPattern(
      id: 'default',
      name: 'Default',
      pattern: [100, 200, 100],
      intensities: [128, 255, 128],
    );

    _vibrationPatterns['short_pulse'] = VibrationPattern(
      id: 'short_pulse',
      name: 'Short Pulse',
      pattern: [50],
      intensities: [200],
    );

    _vibrationPatterns['double_tap'] = VibrationPattern(
      id: 'double_tap',
      name: 'Double Tap',
      pattern: [100, 100, 100],
      intensities: [255, 100, 255],
    );
  }

  /// Setup event streams
  void _setupEventStreams() {
    _notificationEventController = StreamController<NotificationEvent>.broadcast();
    _interactionController = StreamController<NotificationInteraction>.broadcast();
  }

  /// Request notification permissions
  Future<bool> _requestPermissions() async {
    try {
      // In a real implementation, this would request actual permissions
      // For simulation, we'll assume permissions are granted
      debugPrint('Notification permissions requested');
      return true;
    } catch (e) {
      debugPrint('Failed to request permissions: $e');
      return false;
    }
  }

  /// Enable notifications
  Future<void> enableNotifications() async {
    _isEnabled = true;
    await _saveSettings();
    debugPrint('Notifications enabled');
  }

  /// Disable notifications
  Future<void> disableNotifications() async {
    _isEnabled = false;
    await _saveSettings();
    debugPrint('Notifications disabled');
  }

  /// Update category settings
  Future<void> updateCategorySettings(
    NotificationCategory category,
    NotificationSettings settings,
  ) async {
    _categorySettings[category] = settings;
    await _saveCategorySettings();
    debugPrint('Updated settings for category: $category');
  }

  /// Create or update notification channel
  Future<void> createChannel(NotificationChannel channel) async {
    _channels[channel.id] = channel;
    await _saveChannels();
    debugPrint('Created/updated channel: ${channel.id}');
  }

  /// Send notification
  Future<void> sendNotification(NotificationRequest request) async {
    if (!_isInitialized || !_isEnabled) return;

    // Check if notifications are allowed for this category
    final categorySettings = _categorySettings[request.category];
    if (categorySettings?.isEnabled != true) return;

    // Check quiet hours
    if (_useQuietHours && _isInQuietHours()) {
      // Only allow urgent notifications during quiet hours
      if (request.priority != NotificationPriority.urgent) return;
    }

    // Check do not disturb
    if (_useDoNotDisturb && !_allowedInDND.contains(request.priority)) {
      return;
    }

    // Create notification
    final notification = PushNotification(
      id: request.id ?? _generateNotificationId(),
      title: request.title,
      body: request.body,
      category: request.category,
      priority: request.priority,
      channelId: request.channelId,
      data: request.data,
      imageUrl: request.imageUrl,
      actions: request.actions,
      timestamp: DateTime.now(),
      isRead: false,
    );

    // Show notification
    await _showNotification(notification);

    // Add to history
    _addToHistory(notification);

    // Emit event
    _notificationEventController?.add(NotificationEvent(
      type: NotificationEventType.received,
      notification: notification,
    ));
  }

  /// Show notification
  Future<void> _showNotification(PushNotification notification) async {
    try {
      final channel = _channels[notification.channelId];
      if (channel == null) return;

      // In a real implementation, this would show the actual notification
      // For simulation, we'll just log it
      debugPrint('Showing notification: ${notification.title}');

      // Play sound if enabled
      if (channel.enableSound && channel.soundPattern != null) {
        await _playSound(channel.soundPattern!);
      }

      // Vibrate if enabled
      if (channel.enableVibration && channel.vibrationPattern != null) {
        await _vibrate(channel.vibrationPattern!);
      }

    } catch (e) {
      debugPrint('Failed to show notification: $e');
    }
  }

  /// Play notification sound
  Future<void> _playSound(String soundPatternId) async {
    final pattern = _soundPatterns[soundPatternId];
    if (pattern != null) {
      // In a real implementation, this would play the actual sound
      debugPrint('Playing sound: ${pattern.name}');
    }
  }

  /// Vibrate device
  Future<void> _vibrate(String vibrationPatternId) async {
    final pattern = _vibrationPatterns[vibrationPatternId];
    if (pattern != null) {
      try {
        // Use HapticFeedback for simple vibration
        HapticFeedback.heavyImpact();
        debugPrint('Vibrating with pattern: ${pattern.name}');
      } catch (e) {
        debugPrint('Failed to vibrate: $e');
      }
    }
  }

  /// Schedule notification
  Future<void> scheduleNotification(ScheduledNotificationRequest request) async {
    final scheduledNotification = ScheduledNotification(
      id: request.id ?? _generateNotificationId(),
      notificationRequest: request.notificationRequest,
      scheduledTime: request.scheduledTime,
      repeatInterval: request.repeatInterval,
      isActive: true,
    );

    _scheduledNotifications[scheduledNotification.id] = scheduledNotification;
    
    // In a real implementation, this would schedule the actual notification
    debugPrint('Scheduled notification: ${scheduledNotification.id}');
  }

  /// Cancel scheduled notification
  Future<void> cancelScheduledNotification(String id) async {
    _scheduledNotifications.remove(id);
    debugPrint('Cancelled scheduled notification: $id');
  }

  /// Set quiet hours
  Future<void> setQuietHours({
    required bool enabled,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
  }) async {
    _useQuietHours = enabled;
    if (startTime != null) _quietHoursStart = startTime;
    if (endTime != null) _quietHoursEnd = endTime;
    await _saveSettings();
    debugPrint('Quiet hours updated: enabled=$enabled');
  }

  /// Set do not disturb
  Future<void> setDoNotDisturb({
    required bool enabled,
    Set<NotificationPriority>? allowedPriorities,
  }) async {
    _useDoNotDisturb = enabled;
    if (allowedPriorities != null) _allowedInDND = allowedPriorities;
    await _saveSettings();
    debugPrint('Do not disturb updated: enabled=$enabled');
  }

  /// Check if currently in quiet hours
  bool _isInQuietHours() {
    if (!_useQuietHours || _quietHoursStart == null || _quietHoursEnd == null) {
      return false;
    }

    final now = TimeOfDay.now();
    return _isTimeInRange(now, _quietHoursStart!, _quietHoursEnd!);
  }

  /// Check if time is in range
  bool _isTimeInRange(TimeOfDay current, TimeOfDay start, TimeOfDay end) {
    final currentMinutes = current.hour * 60 + current.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;

    if (startMinutes <= endMinutes) {
      return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
    } else {
      return currentMinutes >= startMinutes || currentMinutes <= endMinutes;
    }
  }

  /// Add notification to history
  void _addToHistory(PushNotification notification) {
    final record = NotificationRecord(
      notification: notification,
      deliveredAt: DateTime.now(),
      wasShown: true,
    );

    _notificationHistory.insert(0, record);

    // Limit history to 100 items
    if (_notificationHistory.length > 100) {
      _notificationHistory.removeRange(100, _notificationHistory.length);
    }
  }

  /// Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    final historyIndex = _notificationHistory.indexWhere(
      (record) => record.notification.id == notificationId,
    );

    if (historyIndex != -1) {
      _notificationHistory[historyIndex] = _notificationHistory[historyIndex].copyWith(
        notification: _notificationHistory[historyIndex].notification.copyWith(isRead: true),
      );
    }

    _interactionController?.add(NotificationInteraction(
      notificationId: notificationId,
      action: NotificationAction.read,
      timestamp: DateTime.now(),
    ));
  }

  /// Clear notification history
  Future<void> clearHistory() async {
    _notificationHistory.clear();
    debugPrint('Notification history cleared');
  }

  /// Generate unique notification ID
  String _generateNotificationId() {
    return 'notification_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Get notification statistics
  NotificationStatistics getStatistics() {
    final now = DateTime.now();
    final last24Hours = now.subtract(const Duration(hours: 24));
    final last7Days = now.subtract(const Duration(days: 7));

    final total = _notificationHistory.length;
    final unread = _notificationHistory.where((record) => !record.notification.isRead).length;
    final last24HoursCount = _notificationHistory
        .where((record) => record.deliveredAt.isAfter(last24Hours))
        .length;
    final last7DaysCount = _notificationHistory
        .where((record) => record.deliveredAt.isAfter(last7Days))
        .length;

    final categoryStats = <NotificationCategory, int>{};
    for (final record in _notificationHistory) {
      categoryStats[record.notification.category] = 
          (categoryStats[record.notification.category] ?? 0) + 1;
    }

    return NotificationStatistics(
      totalNotifications: total,
      unreadNotifications: unread,
      notificationsLast24Hours: last24HoursCount,
      notificationsLast7Days: last7DaysCount,
      categoryBreakdown: categoryStats,
      isEnabled: _isEnabled,
      useQuietHours: _useQuietHours,
      useDoNotDisturb: _useDoNotDisturb,
    );
  }

  /// Get push notification status
  PushNotificationStatus getStatus() {
    return PushNotificationStatus(
      isInitialized: _isInitialized,
      isEnabled: _isEnabled,
      deviceToken: _deviceToken,
      categorySettings: Map.from(_categorySettings),
      channels: Map.from(_channels),
      useQuietHours: _useQuietHours,
      quietHoursStart: _quietHoursStart,
      quietHoursEnd: _quietHoursEnd,
      useDoNotDisturb: _useDoNotDisturb,
      allowedInDND: Set.from(_allowedInDND),
      scheduledNotificationsCount: _scheduledNotifications.length,
      historyCount: _notificationHistory.length,
      unreadCount: _notificationHistory.where((r) => !r.notification.isRead).length,
    );
  }

  /// Dispose service
  void dispose() {
    _notificationEventController?.close();
    _interactionController?.close();
  }

  /// Getters for streams
  Stream<NotificationEvent>? get onNotificationEvent => _notificationEventController?.stream;
  Stream<NotificationInteraction>? get onNotificationInteraction => _interactionController?.stream;

  /// Getters
  bool get isInitialized => _isInitialized;
  bool get isEnabled => _isEnabled;
  String? get deviceToken => _deviceToken;
  List<NotificationRecord> get notificationHistory => List.unmodifiable(_notificationHistory);
  Map<NotificationCategory, NotificationSettings> get categorySettings => 
      Map.unmodifiable(_categorySettings);
  Map<String, NotificationChannel> get channels => Map.unmodifiable(_channels);
}

/// Notification categories
enum NotificationCategory {
  general,
  messages,
  social,
  system,
  promotions,
  emergency,
}

/// Notification priority levels
enum NotificationPriority {
  low,
  normal,
  high,
  urgent,
}

/// Notification importance levels
enum NotificationImportance {
  min,
  low,
  defaultImportance,
  high,
  max,
}

/// Notification event types
enum NotificationEventType {
  received,
  opened,
  dismissed,
  actionClicked,
}

/// Notification actions
enum NotificationAction {
  read,
  dismissed,
  clicked,
  actionClicked,
}

/// Notification settings for categories
class NotificationSettings {
  final bool isEnabled;
  final bool showPreview;
  final bool playSound;
  final bool vibrate;
  final String? soundPattern;
  final String? vibrationPattern;
  final NotificationPriority priority;

  const NotificationSettings({
    required this.isEnabled,
    required this.showPreview,
    required this.playSound,
    required this.vibrate,
    this.soundPattern,
    this.vibrationPattern,
    required this.priority,
  });

  factory NotificationSettings.defaultForCategory(NotificationCategory category) {
    switch (category) {
      case NotificationCategory.emergency:
        return const NotificationSettings(
          isEnabled: true,
          showPreview: true,
          playSound: true,
          vibrate: true,
          soundPattern: 'default',
          vibrationPattern: 'default',
          priority: NotificationPriority.urgent,
        );
      case NotificationCategory.messages:
        return const NotificationSettings(
          isEnabled: true,
          showPreview: true,
          playSound: true,
          vibrate: true,
          soundPattern: 'message_tone',
          vibrationPattern: 'double_tap',
          priority: NotificationPriority.high,
        );
      case NotificationCategory.social:
        return const NotificationSettings(
          isEnabled: true,
          showPreview: true,
          playSound: true,
          vibrate: false,
          soundPattern: 'gentle_chime',
          vibrationPattern: null,
          priority: NotificationPriority.normal,
        );
      case NotificationCategory.general:
        return const NotificationSettings(
          isEnabled: true,
          showPreview: true,
          playSound: true,
          vibrate: true,
          soundPattern: 'default',
          vibrationPattern: 'default',
          priority: NotificationPriority.normal,
        );
      case NotificationCategory.system:
      case NotificationCategory.promotions:
        return const NotificationSettings(
          isEnabled: true,
          showPreview: false,
          playSound: false,
          vibrate: false,
          soundPattern: null,
          vibrationPattern: null,
          priority: NotificationPriority.low,
        );
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'isEnabled': isEnabled,
      'showPreview': showPreview,
      'playSound': playSound,
      'vibrate': vibrate,
      'soundPattern': soundPattern,
      'vibrationPattern': vibrationPattern,
      'priority': priority.index,
    };
  }

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      isEnabled: json['isEnabled'] as bool,
      showPreview: json['showPreview'] as bool,
      playSound: json['playSound'] as bool,
      vibrate: json['vibrate'] as bool,
      soundPattern: json['soundPattern'] as String?,
      vibrationPattern: json['vibrationPattern'] as String?,
      priority: NotificationPriority.values[json['priority'] as int],
    );
  }

  NotificationSettings copyWith({
    bool? isEnabled,
    bool? showPreview,
    bool? playSound,
    bool? vibrate,
    String? soundPattern,
    String? vibrationPattern,
    NotificationPriority? priority,
  }) {
    return NotificationSettings(
      isEnabled: isEnabled ?? this.isEnabled,
      showPreview: showPreview ?? this.showPreview,
      playSound: playSound ?? this.playSound,
      vibrate: vibrate ?? this.vibrate,
      soundPattern: soundPattern ?? this.soundPattern,
      vibrationPattern: vibrationPattern ?? this.vibrationPattern,
      priority: priority ?? this.priority,
    );
  }
}

/// Notification channel configuration
class NotificationChannel {
  final String id;
  final String name;
  final String description;
  final NotificationImportance importance;
  final bool showBadge;
  final bool enableSound;
  final bool enableVibration;
  final String? soundPattern;
  final String? vibrationPattern;

  const NotificationChannel({
    required this.id,
    required this.name,
    required this.description,
    required this.importance,
    required this.showBadge,
    required this.enableSound,
    required this.enableVibration,
    this.soundPattern,
    this.vibrationPattern,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'importance': importance.index,
      'showBadge': showBadge,
      'enableSound': enableSound,
      'enableVibration': enableVibration,
      'soundPattern': soundPattern,
      'vibrationPattern': vibrationPattern,
    };
  }

  factory NotificationChannel.fromJson(Map<String, dynamic> json) {
    return NotificationChannel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      importance: NotificationImportance.values[json['importance'] as int],
      showBadge: json['showBadge'] as bool,
      enableSound: json['enableSound'] as bool,
      enableVibration: json['enableVibration'] as bool,
      soundPattern: json['soundPattern'] as String?,
      vibrationPattern: json['vibrationPattern'] as String?,
    );
  }
}

/// Scheduled notification configuration
class ScheduledNotification {
  final String id;
  final NotificationRequest notificationRequest;
  final DateTime scheduledTime;
  final Duration? repeatInterval;
  final bool isActive;

  const ScheduledNotification({
    required this.id,
    required this.notificationRequest,
    required this.scheduledTime,
    this.repeatInterval,
    required this.isActive,
  });
}

/// Notification record for history
class NotificationRecord {
  final PushNotification notification;
  final DateTime deliveredAt;
  final bool wasShown;
  final DateTime? readAt;

  const NotificationRecord({
    required this.notification,
    required this.deliveredAt,
    required this.wasShown,
    this.readAt,
  });

  NotificationRecord copyWith({
    PushNotification? notification,
    DateTime? deliveredAt,
    bool? wasShown,
    DateTime? readAt,
  }) {
    return NotificationRecord(
      notification: notification ?? this.notification,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      wasShown: wasShown ?? this.wasShown,
      readAt: readAt ?? this.readAt,
    );
  }
}

/// Sound pattern configuration
class SoundPattern {
  final String id;
  final String name;
  final String asset;
  final Duration duration;

  const SoundPattern({
    required this.id,
    required this.name,
    required this.asset,
    required this.duration,
  });
}

/// Vibration pattern configuration
class VibrationPattern {
  final String id;
  final String name;
  final List<int> pattern;
  final List<int> intensities;

  const VibrationPattern({
    required this.id,
    required this.name,
    required this.pattern,
    required this.intensities,
  });
}

/// Notification event
class NotificationEvent {
  final NotificationEventType type;
  final PushNotification notification;
  final String? actionId;
  final DateTime timestamp;

  NotificationEvent({
    required this.type,
    required this.notification,
    this.actionId,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// Notification interaction
class NotificationInteraction {
  final String notificationId;
  final NotificationAction action;
  final String? actionId;
  final DateTime timestamp;

  NotificationInteraction({
    required this.notificationId,
    required this.action,
    this.actionId,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// Push notification data
class PushNotification {
  final String id;
  final String title;
  final String body;
  final NotificationCategory category;
  final NotificationPriority priority;
  final String channelId;
  final Map<String, dynamic>? data;
  final String? imageUrl;
  final List<NotificationActionButton>? actions;
  final DateTime timestamp;
  final bool isRead;

  const PushNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.priority,
    required this.channelId,
    this.data,
    this.imageUrl,
    this.actions,
    required this.timestamp,
    required this.isRead,
  });

  PushNotification copyWith({
    String? id,
    String? title,
    String? body,
    NotificationCategory? category,
    NotificationPriority? priority,
    String? channelId,
    Map<String, dynamic>? data,
    String? imageUrl,
    List<NotificationActionButton>? actions,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return PushNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      channelId: channelId ?? this.channelId,
      data: data ?? this.data,
      imageUrl: imageUrl ?? this.imageUrl,
      actions: actions ?? this.actions,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }
}

/// Notification request
class NotificationRequest {
  final String? id;
  final String title;
  final String body;
  final NotificationCategory category;
  final NotificationPriority priority;
  final String channelId;
  final Map<String, dynamic>? data;
  final String? imageUrl;
  final List<NotificationActionButton>? actions;

  const NotificationRequest({
    this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.priority,
    required this.channelId,
    this.data,
    this.imageUrl,
    this.actions,
  });
}

/// Scheduled notification request
class ScheduledNotificationRequest {
  final String? id;
  final NotificationRequest notificationRequest;
  final DateTime scheduledTime;
  final Duration? repeatInterval;

  const ScheduledNotificationRequest({
    this.id,
    required this.notificationRequest,
    required this.scheduledTime,
    this.repeatInterval,
  });
}

/// Notification action button
class NotificationActionButton {
  final String id;
  final String title;
  final String? icon;
  final bool isDestructive;

  const NotificationActionButton({
    required this.id,
    required this.title,
    this.icon,
    this.isDestructive = false,
  });
}

/// Notification statistics
class NotificationStatistics {
  final int totalNotifications;
  final int unreadNotifications;
  final int notificationsLast24Hours;
  final int notificationsLast7Days;
  final Map<NotificationCategory, int> categoryBreakdown;
  final bool isEnabled;
  final bool useQuietHours;
  final bool useDoNotDisturb;

  const NotificationStatistics({
    required this.totalNotifications,
    required this.unreadNotifications,
    required this.notificationsLast24Hours,
    required this.notificationsLast7Days,
    required this.categoryBreakdown,
    required this.isEnabled,
    required this.useQuietHours,
    required this.useDoNotDisturb,
  });

  @override
  String toString() {
    return 'NotificationStatistics('
        'total: $totalNotifications, '
        'unread: $unreadNotifications, '
        'last24h: $notificationsLast24Hours, '
        'last7d: $notificationsLast7Days, '
        'enabled: $isEnabled'
        ')';
  }
}

/// Push notification status
class PushNotificationStatus {
  final bool isInitialized;
  final bool isEnabled;
  final String? deviceToken;
  final Map<NotificationCategory, NotificationSettings> categorySettings;
  final Map<String, NotificationChannel> channels;
  final bool useQuietHours;
  final TimeOfDay? quietHoursStart;
  final TimeOfDay? quietHoursEnd;
  final bool useDoNotDisturb;
  final Set<NotificationPriority> allowedInDND;
  final int scheduledNotificationsCount;
  final int historyCount;
  final int unreadCount;

  const PushNotificationStatus({
    required this.isInitialized,
    required this.isEnabled,
    this.deviceToken,
    required this.categorySettings,
    required this.channels,
    required this.useQuietHours,
    this.quietHoursStart,
    this.quietHoursEnd,
    required this.useDoNotDisturb,
    required this.allowedInDND,
    required this.scheduledNotificationsCount,
    required this.historyCount,
    required this.unreadCount,
  });

  @override
  String toString() {
    return 'PushNotificationStatus('
        'initialized: $isInitialized, '
        'enabled: $isEnabled, '
        'channels: ${channels.length}, '
        'scheduled: $scheduledNotificationsCount, '
        'history: $historyCount, '
        'unread: $unreadCount'
        ')';
  }
}
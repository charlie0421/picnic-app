import 'package:flutter/material.dart';
import 'package:picnic_lib/data/models/user_notification.dart';

enum NotificationSource { personal, broadcast }

/// A notification together with the table it came from.
///
/// Numeric IDs are only unique inside each source table, so [identity] must be
/// used for list keys, de-duplication, and read targeting.
class InboxNotification {
  const InboxNotification({required this.source, required this.notification});

  final NotificationSource source;
  final UserNotification notification;

  int get id => notification.id;
  String get identity => '${source.name}:$id';
  bool get isRead => notification.isRead;
  String? get createdAt => notification.createdAt;
  String get type => notification.type;
  Map<String, dynamic>? get data => notification.data;
  String? get actionUrl => notification.actionUrl;

  String getLocalizedTitle(BuildContext context) =>
      notification.getLocalizedTitle(context);

  String getLocalizedBody(BuildContext context) =>
      notification.getLocalizedBody(context);

  InboxNotification copyWith({UserNotification? notification}) =>
      InboxNotification(
        source: source,
        notification: notification ?? this.notification,
      );

  InboxNotification markedRead({String? readAt}) => copyWith(
    notification: notification.copyWith(
      isRead: true,
      readAt: readAt ?? DateTime.now().toIso8601String(),
    ),
  );

  @override
  bool operator ==(Object other) =>
      other is InboxNotification && other.identity == identity;

  @override
  int get hashCode => Object.hash(source, id);
}

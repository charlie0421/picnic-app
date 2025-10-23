import 'package:freezed_annotation/freezed_annotation.dart';

part '../../generated/models/user_notification.freezed.dart';
part '../../generated/models/user_notification.g.dart';

@freezed
class UserNotification with _$UserNotification {
  const UserNotification._();

  const factory UserNotification({
    @JsonKey(name: 'id') required int id,
    @JsonKey(name: 'user_id') String? userId,
    @JsonKey(name: 'title') required String title,
    @JsonKey(name: 'body') required String body,
    @JsonKey(name: 'data') Map<String, dynamic>? data,
    @JsonKey(name: 'action_url') String? actionUrl,
    @JsonKey(name: 'type') @Default('default') String type,
    @JsonKey(name: 'is_read') @Default(false) bool isRead,
    @JsonKey(name: 'created_at') String? createdAt,
    @JsonKey(name: 'read_at') String? readAt,
  }) = _UserNotification;

  factory UserNotification.fromJson(Map<String, dynamic> json) =>
      _$UserNotificationFromJson(json);
}

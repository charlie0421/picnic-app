import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:picnic_lib/core/utils/locale_utils.dart';

part '../../generated/models/user_notification.g.dart';

/// 다국어 필드를 정규화하는 JSON 변환기
/// 문자열이면 {"ko": "...", "en": "..."} 형태로 변환
/// JSON 문자열이면 파싱하여 Map으로 변환
class MultilangJsonConverter
    implements JsonConverter<Map<String, dynamic>, dynamic> {
  const MultilangJsonConverter();

  @override
  Map<String, dynamic> fromJson(dynamic json) {
    // 이미 Map인 경우 그대로 반환
    if (json is Map<String, dynamic>) {
      return json;
    }

    // 문자열인 경우
    if (json is String) {
      // JSON 문자열인지 확인 (시작이 '{' 또는 '[')
      final trimmed = json.trim();
      if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
        try {
          // JSON 문자열을 파싱
          final parsed = jsonDecode(json) as dynamic;
          if (parsed is Map<String, dynamic>) {
            return parsed;
          } else if (parsed is Map) {
            // Map<dynamic, dynamic> 같은 경우도 처리
            return Map<String, dynamic>.from(parsed);
          }
        } catch (e) {
          // JSON 파싱 실패 시 일반 문자열로 처리
          return {'ko': json, 'en': json};
        }
      }
      // 일반 문자열인 경우
      return {'ko': json, 'en': json};
    }

    // null이거나 다른 타입인 경우
    return {'ko': '', 'en': ''};
  }

  @override
  dynamic toJson(Map<String, dynamic> object) => object;
}

@JsonSerializable()
class UserNotification {
  @JsonKey(name: 'id')
  final int id;

  @JsonKey(name: 'user_id')
  final String? userId;

  @JsonKey(name: 'title')
  @MultilangJsonConverter()
  final Map<String, dynamic> title;

  @JsonKey(name: 'body')
  @MultilangJsonConverter()
  final Map<String, dynamic> body;

  @JsonKey(name: 'data')
  final Map<String, dynamic>? data;

  @JsonKey(name: 'action_url')
  final String? actionUrl;

  @JsonKey(name: 'type')
  final String type;

  @JsonKey(name: 'is_read')
  final bool isRead;

  @JsonKey(name: 'created_at')
  final String? createdAt;

  @JsonKey(name: 'read_at')
  final String? readAt;

  const UserNotification({
    required this.id,
    this.userId,
    required this.title,
    required this.body,
    this.data,
    this.actionUrl,
    this.type = 'default',
    this.isRead = false,
    this.createdAt,
    this.readAt,
  });

  factory UserNotification.fromJson(Map<String, dynamic> json) =>
      _$UserNotificationFromJson(json);

  Map<String, dynamic> toJson() => _$UserNotificationToJson(this);

  UserNotification copyWith({
    int? id,
    String? userId,
    Map<String, dynamic>? title,
    Map<String, dynamic>? body,
    Map<String, dynamic>? data,
    String? actionUrl,
    String? type,
    bool? isRead,
    String? createdAt,
    String? readAt,
  }) {
    return UserNotification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      data: data ?? this.data,
      actionUrl: actionUrl ?? this.actionUrl,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
    );
  }

  /// 현재 로케일에 맞는 제목 반환 (en fallback)
  String getLocalizedTitle(BuildContext context) {
    return getLocaleTextFromJson(title, context);
  }

  /// 현재 로케일에 맞는 본문 반환 (en fallback)
  String getLocalizedBody(BuildContext context) {
    return getLocaleTextFromJson(body, context);
  }

  /// 특정 언어 코드로 제목 반환 (en fallback)
  String getLocalizedTitleWithLocale(String languageCode) {
    return getLocaleTextFromJsonWithLocale(title, languageCode);
  }

  /// 특정 언어 코드로 본문 반환 (en fallback)
  String getLocalizedBodyWithLocale(String languageCode) {
    return getLocaleTextFromJsonWithLocale(body, languageCode);
  }
}

import 'package:hive/hive.dart';

part 'cache_entry.g.dart';

@HiveType(typeId: 0)
class CacheEntry extends HiveObject {
  @HiveField(0)
  String key;

  @HiveField(1)
  String data;

  @HiveField(2)
  DateTime createdAt;

  @HiveField(3)
  DateTime expiresAt;

  @HiveField(4)
  Map<String, String> headers;

  @HiveField(5)
  int statusCode;

  @HiveField(6)
  String? etag;

  CacheEntry({
    required this.key,
    required this.data,
    required this.createdAt,
    required this.expiresAt,
    required this.headers,
    required this.statusCode,
    this.etag,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  bool get isValid => !isExpired && statusCode >= 200 && statusCode < 400;

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'data': data,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'headers': headers,
      'statusCode': statusCode,
      'etag': etag,
    };
  }

  factory CacheEntry.fromJson(Map<String, dynamic> json) {
    return CacheEntry(
      key: json['key'] as String,
      data: json['data'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      headers: Map<String, String>.from(json['headers'] as Map),
      statusCode: json['statusCode'] as int,
      etag: json['etag'] as String?,
    );
  }
}

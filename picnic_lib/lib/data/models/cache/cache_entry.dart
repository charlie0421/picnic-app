import 'package:hive/hive.dart';

@HiveType(typeId: 0)
class CacheEntry extends HiveObject {
  @HiveField(0)
  @override
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

// 수동으로 생성한 Hive Adapter
class CacheEntryAdapter extends TypeAdapter<CacheEntry> {
  @override
  final int typeId = 0;

  @override
  CacheEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CacheEntry(
      key: fields[0] as String,
      data: fields[1] as String,
      createdAt: fields[2] as DateTime,
      expiresAt: fields[3] as DateTime,
      headers: Map<String, String>.from(fields[4] as Map),
      statusCode: fields[5] as int,
      etag: fields[6] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, CacheEntry obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.key)
      ..writeByte(1)
      ..write(obj.data)
      ..writeByte(2)
      ..write(obj.createdAt)
      ..writeByte(3)
      ..write(obj.expiresAt)
      ..writeByte(4)
      ..write(obj.headers)
      ..writeByte(5)
      ..write(obj.statusCode)
      ..writeByte(6)
      ..write(obj.etag);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CacheEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;

  @override
  int get hashCode => typeId.hashCode;
}

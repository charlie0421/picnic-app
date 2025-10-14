import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:picnic_lib/core/constants/purchase_constants.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReceiptQueueService {
  ReceiptQueueService._internal();
  static final ReceiptQueueService _instance = ReceiptQueueService._internal();
  factory ReceiptQueueService() => _instance;

  static const String _spKey = 'receipt_queue_v1';

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  Future<List<Map<String, dynamic>>> _loadQueue() async {
    final sp = await _prefs;
    final raw = sp.getString(_spKey);
    if (raw == null || raw.isEmpty) return <Map<String, dynamic>>[];
    try {
      final list = (json.decode(raw) as List<dynamic>)
          .cast<Map<String, dynamic>>();
      return list;
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  Future<void> _saveQueue(List<Map<String, dynamic>> items) async {
    final sp = await _prefs;
    await sp.setString(_spKey, json.encode(items));
  }

  String _generateClientTraceId() {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final rand = Random().nextInt(1 << 32).toRadixString(16);
    return 'android-$ts-$rand';
  }

  Future<String> enqueueAndroid({
    required String receipt,
    required String productId,
    required String userId,
    required String environment,
  }) async {
    final clientTraceId = _generateClientTraceId();
    final items = await _loadQueue();
    items.add({
      'client_trace_id': clientTraceId,
      'receipt': receipt,
      'productId': productId,
      'user_id': userId,
      'platform': 'android',
      'environment': environment,
      'attempt': 0,
      'createdAt': DateTime.now().toIso8601String(),
      'nextAt': 0,
    });
    await _saveQueue(items);
    logger.i('📥 큐 적재: $clientTraceId ($productId)');
    return clientTraceId;
  }

  Future<void> removeByClientTraceId(String clientTraceId) async {
    final items = await _loadQueue();
    items.removeWhere((e) => e['client_trace_id'] == clientTraceId);
    await _saveQueue(items);
    logger.i('🧹 큐 제거: $clientTraceId');
  }

  bool _shouldSendNow(Map<String, dynamic> item) {
    final nextAt = (item['nextAt'] ?? 0) as int;
    return DateTime.now().millisecondsSinceEpoch >= nextAt;
  }

  int _computeNextAt(int attempt) {
    final base = PurchaseConstants.baseRetryDelay;
    final seconds = base * (1 << (attempt.clamp(0, 6))); // 2,4,8,16,32,64,128
    final cap = 300; // 5분 상한
    final backoffSec = seconds > cap ? cap : seconds;
    return DateTime.now()
        .add(Duration(seconds: backoffSec))
        .millisecondsSinceEpoch;
  }

  Future<void> flushPending() async {
    final items = await _loadQueue();
    if (items.isEmpty) return;
    logger.i('🧾 영수증 큐 플러시 시작: ${items.length}건');

    final updated = <Map<String, dynamic>>[];
    for (final item in items) {
      try {
        if (!_shouldSendNow(item)) {
          updated.add(item);
          continue;
        }

        final body = {
          'receipt': item['receipt'],
          'platform': item['platform'],
          'productId': item['productId'],
          'user_id': item['user_id'],
          'environment': item['environment'],
          'format': 'google_play',
          'client_trace_id': item['client_trace_id'],
        };

        final response = await supabase.functions.invoke(
          'verify_receipt',
          body: body,
        );
        final ok =
            response.status == 200 &&
            response.data != null &&
            response.data['success'] == true;
        if (ok) {
          logger.i('✅ 큐 전송 성공: ${item['client_trace_id']}');
          continue; // drop
        }

        // 409 중복은 성공으로 간주하고 제거
        if (response.status == 409) {
          logger.w('♻️ 중복 감지(409), 큐 제거: ${item['client_trace_id']}');
          continue;
        }

        // 그 외 오류는 백오프 후 유지
        final attempt = (item['attempt'] ?? 0) + 1;
        item['attempt'] = attempt;
        item['nextAt'] = _computeNextAt(attempt);
        updated.add(item);
        logger.w(
          '⏳ 큐 전송 실패(${response.status}), 재시도 예약: ${item['client_trace_id']}',
        );
      } catch (e) {
        // 네트워크/타임아웃 등 예외 → 백오프
        final attempt = (item['attempt'] ?? 0) + 1;
        item['attempt'] = attempt;
        item['nextAt'] = _computeNextAt(attempt);
        updated.add(item);
        logger.w('🌐 큐 전송 예외, 재시도 예약: ${item['client_trace_id']} ($e)');
      }
    }

    await _saveQueue(updated);
    logger.i('🧾 영수증 큐 플러시 완료. 남은 건: ${updated.length}');
  }
}

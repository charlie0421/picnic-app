import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';

import 'package:picnic_lib/core/constants/purchase_constants.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  /// 409 응답이 "보상 지급까지 완료된 중복"인지 판별한다.
  ///
  /// verify_receipt는 영수증 행만 있고 보상 지급이 실패한 경로에서도
  /// 409(DUPLICATE_RECEIPT)를 반환한다. 그 경우 큐 항목이 유일한 재시도
  /// 수단이므로 지우면 안 된다.
  ///
  /// 판별은 구조화된 `grant_confirmed` 필드를 우선한다(하드닝된 서버).
  /// 필드가 없는 배포본(v161)에 한해 알려진 실패 문구 부재로 fallback하며,
  /// 판별할 수 없는 응답은 보수적으로 유지한다.
  @visibleForTesting
  static bool duplicateConfirmsGrant(dynamic details) {
    if (details is! Map) return false;
    final structured = details['grant_confirmed'];
    if (structured is bool) return structured;
    if (details['code'] != 'DUPLICATE_RECEIPT') return false;
    final message = details['message']?.toString() ?? '';
    return !message.contains('실패');
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
        // 성공 판정은 foreground 검증과 같은 기준을 공유해야 한다:
        // 레거시 서버는 {success: true, ...}, wallet.v1 서버는 정산 객체
        // 자체(contract_version == 'wallet.v1')를 200으로 반환한다.
        // 후자를 실패로 오판하면 이미 정산된 영수증을 영원히 재전송한다.
        final data = response.data;
        final ok =
            response.status == 200 &&
            data is Map &&
            (data['success'] == true ||
                data['contract_version'] == 'wallet.v1');
        if (ok) {
          logger.i('✅ 큐 전송 성공: ${item['client_trace_id']}');
          continue; // drop
        }

        // 그 외 오류는 백오프 후 유지
        final attempt = (item['attempt'] ?? 0) + 1;
        item['attempt'] = attempt;
        item['nextAt'] = _computeNextAt(attempt);
        updated.add(item);
        logger.w(
          '⏳ 큐 전송 실패(${response.status}), 재시도 예약: ${item['client_trace_id']}',
        );
      } on FunctionException catch (e) {
        // invoke는 2xx 외 상태코드에서 FunctionException을 던지고 JSON
        // body는 details에 담긴다. 서버는 "영수증은 있으나 보상 지급에
        // 실패한" 경우에도 재시도를 의도하며 같은 409를 반환하므로,
        // 보상 지급까지 끝난 중복이 확인될 때만 큐에서 제거한다.
        if (e.status == 409 && duplicateConfirmsGrant(e.details)) {
          logger.w('♻️ 이미 정산된 영수증(409), 큐 제거: ${item['client_trace_id']}');
          continue;
        }
        // Google이 취소로 확정한 구매는 영원히 적립 대상이 아니다 → 제거.
        // (pending(PURCHASE_PENDING)은 결제 완료 후 적립돼야 하므로 유지)
        if (e.status == 400 &&
            e.details is Map &&
            (e.details as Map)['code'] == 'PURCHASE_CANCELED') {
          logger.w('🚫 취소 확정 구매, 큐 제거: ${item['client_trace_id']}');
          continue;
        }
        // 422는 wallet.v1 워커의 명시적 비재시도 판정 - 재전송해도 결코
        // 성공하지 못하는 영수증이 큐를 영원히 돌지 않게 제거한다.
        if (e.status == 422) {
          logger.w('🚫 서버 영구 거부(422), 큐 제거: ${item['client_trace_id']}');
          continue;
        }
        final attempt = (item['attempt'] ?? 0) + 1;
        item['attempt'] = attempt;
        item['nextAt'] = _computeNextAt(attempt);
        updated.add(item);
        logger.w(
          '⏳ 큐 전송 실패(${e.status}), 재시도 예약: ${item['client_trace_id']}',
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

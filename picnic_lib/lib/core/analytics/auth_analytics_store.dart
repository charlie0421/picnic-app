import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:picnic_lib/core/analytics/analytics_send_markers.dart';
import 'package:picnic_lib/core/constatns/constants.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/data/storage/local_storage.dart';

/// `login` / `sign_up` 중복 발송을 막기 위한 영속 상태.
///
/// 왜 영속이 필요한가:
///   - 앱을 재시작하면 Supabase 가 세션을 복원하면서 auth 리스너가 다시
///     `signedIn` 을 흘린다. 메모리 플래그만으로는 매 실행마다 `login` 이
///     한 번씩 더 나간다.
///   - `sign_up` 은 사용자당 정확히 1회여야 한다. 가입 직후 30초 안에
///     로그아웃→재로그인하면 시각 기반 판정만으로는 두 번 잡힌다.
///
/// ## 저장 실패를 삼키지 않는다
///
/// 모든 쓰기는 성공 여부를 **`bool` 로 돌려준다.** 저장 실패를 삼키면
/// 호출부는 "중복 방어가 걸렸다"고 착각한다. 반대로 마커를 먼저 남기고
/// 발송하면 발송 실패가 곧 영구 누락이므로, 호출부
/// ([AuthAnalyticsReporter])는 **durable outbox enqueue 성공을 확인한 뒤에만**
/// 여기에 쓴다. 실제 sink 성공 전이어도 payload 자체가 재시작 후 남아 재시도된다.
///
/// ## 갱신은 직렬화된다
///
/// `sign_up` 사용자 목록은 read-modify-write 다. Reporter 가 두 개
/// 존재하거나(초기화 재실행) 서로 다른 사용자가 거의 동시에 로그인하면
/// 마지막 쓰기가 이겨 한쪽 마커가 사라진다 — 그 사용자의 `sign_up` 이 다음
/// 실행에서 한 번 더 나간다. [AnalyticsMarkerMutex] 가 키 단위로 이를 막는다.
class AuthAnalyticsStore {
  AuthAnalyticsStore({
    LocalStorage? storage,
    this.ioTimeout = const Duration(seconds: 2),
  }) : _storage = storage;

  final LocalStorage? _storage;
  final Duration ioTimeout;

  LocalStorage get _s => _storage ?? globalStorage;

  static const String loginSignatureKey = 'analytics_last_login_signature';
  static const String signUpUserIdsKey = 'analytics_signup_logged_user_ids';

  /// 기록해두는 사용자 수 상한. 한 기기에서 계정을 바꿔가며 쓰는 경우를
  /// 감당하면서도 키가 무한히 커지지 않게 한다.
  static const int maxTrackedSignUpUsers = 20;

  @visibleForTesting
  static void resetProcessCacheForTest() => AnalyticsMarkerMutex.resetForTest();

  Future<String?> readLoginSignature() async {
    try {
      return await _s.loadData(loginSignatureKey, null).timeout(ioTimeout);
    } catch (e, s) {
      logger.e('analytics 로그인 서명 로드 실패', error: e, stackTrace: s);
      return null;
    }
  }

  /// 저장 성공 여부를 돌려준다. 실패하면 다음 실행에서 `login` 이 한 번 더
  /// 나갈 수 있다 — 조용히 넘기지 않고 호출부가 로그로 드러낸다.
  Future<bool> writeLoginSignature(String signature) {
    return AnalyticsMarkerMutex.runExclusive(loginSignatureKey, () async {
      try {
        await _s.saveData(loginSignatureKey, signature).timeout(ioTimeout);
        return true;
      } catch (e, s) {
        logger.e('analytics 로그인 서명 저장 실패', error: e, stackTrace: s);
        return false;
      }
    });
  }

  /// 로그아웃 시 호출한다. 서명을 지워야 같은 사용자가 다시 로그인했을 때
  /// (`last_sign_in_at` 이 없어 서명이 userId 뿐인 예외 상황 포함) `login` 이
  /// 정상 발송된다.
  Future<bool> clearLoginSignature() {
    return AnalyticsMarkerMutex.runExclusive(loginSignatureKey, () async {
      try {
        await _s.removeData(loginSignatureKey).timeout(ioTimeout);
        return true;
      } catch (e, s) {
        logger.e('analytics 로그인 서명 삭제 실패', error: e, stackTrace: s);
        return false;
      }
    });
  }

  Future<bool> hasLoggedSignUp(String userId) async {
    final ids = await _readSignUpUserIds();
    return ids.contains(userId);
  }

  /// `sign_up` 을 durable outbox에 **성공적으로 넣은 뒤에만** 호출한다.
  Future<bool> markSignUpLogged(String userId) {
    return AnalyticsMarkerMutex.runExclusive(signUpUserIdsKey, () async {
      try {
        // 락 안에서 다시 읽는다. 밖에서 읽은 스냅샷을 쓰면 그 사이에 커밋된
        // 다른 사용자의 마커를 덮어쓴다.
        final ids = await _readSignUpUserIds();
        if (ids.contains(userId)) return true;
        ids.add(userId);
        final capped = ids.length > maxTrackedSignUpUsers
            ? ids.sublist(ids.length - maxTrackedSignUpUsers)
            : ids;
        await _s
            .saveData(signUpUserIdsKey, capped.join(','))
            .timeout(ioTimeout);
        return true;
      } catch (e, s) {
        logger.e('analytics sign_up 마커 저장 실패', error: e, stackTrace: s);
        return false;
      }
    });
  }

  Future<List<String>> _readSignUpUserIds() async {
    try {
      final raw = await _s.loadData(signUpUserIdsKey, null).timeout(ioTimeout);
      if (raw == null || raw.isEmpty) return <String>[];
      return raw.split(',').where((e) => e.isNotEmpty).toList();
    } catch (e, s) {
      logger.e('analytics sign_up 마커 로드 실패', error: e, stackTrace: s);
      return <String>[];
    }
  }
}

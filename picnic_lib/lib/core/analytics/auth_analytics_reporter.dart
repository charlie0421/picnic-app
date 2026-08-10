import 'dart:async';

import 'package:picnic_lib/core/analytics/analytics_outbox.dart';
import 'package:picnic_lib/core/analytics/auth_analytics_resolver.dart';
import 'package:picnic_lib/core/analytics/auth_analytics_store.dart';
import 'package:picnic_lib/core/analytics/ga4_language.dart';
import 'package:picnic_lib/core/analytics/ga4_parameters.dart';
import 'package:picnic_lib/core/analytics/ga4_taxonomy.dart';
import 'package:picnic_lib/core/analytics/picnic_analytics.dart';
import 'package:picnic_lib/core/utils/logger.dart';

/// auth 상태 변화 → `login` / `sign_up` 발송을 담당한다.
///
/// [AuthAnalyticsResolver] (순수 판정) 와 [AuthAnalyticsStore] (영속 중복 차단)
/// 를 묶어 호출부가 한 줄로 쓰게 만든다. 호출부: `AppInitializer` 의
/// `setupSupabaseAuthListener`.
///
/// ## 직렬화 (single-flight)
///
/// 호출부는 `Stream.listen` 의 **async 콜백**이다. Dart 의 스트림은 async
/// 리스너의 완료를 기다리지 않으므로, `signedIn` 이 짧은 간격으로 두 번 흘러오면
/// 두 호출이 동시에 [onSignedIn] 안에 들어온다. 그러면
/// `readLoginSignature()` → `writeLoginSignature()` 사이의 await 지점에서 둘 다
/// "아직 저장된 서명이 없다"를 읽고 각자 `login` 을 발송한다 (`sign_up` 마커도
/// 같은 read-then-write 경쟁을 탄다).
///
/// [_serialize] 가 모든 진입을 하나의 Future 체인에 묶어 이 창을 없앤다. 두 번째
/// 호출은 첫 번째가 서명을 **저장한 뒤에** 판정하므로 중복으로 걸러진다.
/// [onSignedOut] 도 같은 체인에 태워야 "로그아웃의 서명 삭제"가 진행 중인
/// 로그인 판정 한복판에 끼어들지 않는다.
class AuthAnalyticsReporter {
  AuthAnalyticsReporter({
    AuthAnalyticsStore? store,
    PicnicAnalytics? analytics,
    AnalyticsOutbox? outbox,
    this.sendTimeout = const Duration(seconds: 5),
  }) : _store = store ?? AuthAnalyticsStore(),
       _analytics = analytics,
       _outbox =
           outbox ?? (analytics == null ? AnalyticsOutbox.instance : null);

  final AuthAnalyticsStore _store;
  final PicnicAnalytics? _analytics;
  final AnalyticsOutbox? _outbox;
  final Duration sendTimeout;

  /// 직렬화 체인의 꼬리. 항상 완료(성공)로 수렴시켜 한 번의 실패가 이후 모든
  /// 발송을 막지 않게 한다.
  Future<void> _tail = Future<void>.value();

  PicnicAnalytics get _a => _analytics ?? PicnicAnalytics.instance;

  Future<void> _serialize(Future<void> Function() action) {
    final next = _tail.then((_) => action());
    // 체인에는 '삼킨' 버전을 남기고, 호출부에는 원본을 돌려준다.
    _tail = next.catchError((Object _) {});
    return next;
  }

  /// 로그인/회원가입 완료(통신 시점)에 호출한다.
  ///
  /// [provider] 는 Supabase user 의 `app_metadata['provider']`.
  /// [createdAt] / [lastSignInAt] 은 Supabase user 의 동명 필드 (ISO8601).
  /// [selectedLanguage] 는 로그인 직전 선택된 언어.
  ///
  /// 동시에 두 번 호출돼도 `login` / `sign_up` 은 정확히 1회만 발송된다.
  Future<void> onSignedIn({
    required String userId,
    required String? provider,
    required String? createdAt,
    required String? lastSignInAt,
    required String? selectedLanguage,
  }) {
    return _serialize(
      () => _onSignedIn(
        userId: userId,
        provider: provider,
        createdAt: createdAt,
        lastSignInAt: lastSignInAt,
        selectedLanguage: selectedLanguage,
      ),
    );
  }

  Future<void> _onSignedIn({
    required String userId,
    required String? provider,
    required String? createdAt,
    required String? lastSignInAt,
    required String? selectedLanguage,
  }) async {
    try {
      final decision = AuthAnalyticsResolver.decide(
        userId: userId,
        provider: provider,
        createdAt: createdAt,
        lastSignInAt: lastSignInAt,
        persistedLoginSignature: await _store.readLoginSignature(),
        signUpAlreadyLogged: await _store.hasLoggedSignUp(userId),
      );

      if (!decision.shouldLogLogin && !decision.shouldLogSignUp) {
        // 세션 복원으로 signedIn 이 재발화한 경우. 이벤트를 보내지 않는다.
        logger.i('login 이벤트 중복 발송 방지 (세션 복원): ${decision.loginSignature}');
        return;
      }

      // login/sign_up은 서로 독립된 durable outbox 항목이다. enqueue 성공 뒤
      // 판정 마커를 남겨도 payload가 재시작 후 살아 있으므로 sink 실패가 영구
      // 누락이 되지 않는다. 특히 sign_up 실패가 login 서명에 가려지지 않는다.
      if (decision.shouldLogSignUp) {
        final queued = await _queueOrSend(
          kind: AnalyticsOutboxEventKind.signUp,
          id: 'signup:$userId',
          userId: userId,
          method: decision.method,
          selectedLanguage: selectedLanguage,
        );
        if (queued) {
          if (!await _store.markSignUpLogged(userId)) {
            logger.e('sign_up outbox 저장은 성공했으나 enqueue 마커 저장 실패: $userId');
          }
        } else {
          logger.w('sign_up outbox enqueue/전송 실패 — 다음 signedIn에서 다시 시도');
        }
      }

      if (!decision.shouldLogLogin) return;
      final loginQueued = await _queueOrSend(
        kind: AnalyticsOutboxEventKind.login,
        id: decision.loginSignature,
        userId: userId,
        method: decision.method,
        selectedLanguage: selectedLanguage,
      );
      if (!loginQueued) {
        // 서명을 쓰지 않고 끝낸다. 다음 signedIn(세션 복원 포함)이 이 로그인을
        // 다시 시도한다 — 중복 1건이 누락 1건보다 낫다.
        logger.w('login 전송 실패 — 로그인 서명을 남기지 않는다. 다음 signedIn 에서 다시 시도한다.');
        return;
      }

      if (!await _store.writeLoginSignature(decision.loginSignature)) {
        logger.e('login 전송은 성공했으나 서명 저장 실패 — 다음 실행에서 한 번 더 나갈 수 있다.');
      }
    } catch (e, s) {
      logger.e('login/sign_up analytics 처리 실패', error: e, stackTrace: s);
    }
  }

  Future<bool> _queueOrSend({
    required AnalyticsOutboxEventKind kind,
    required String id,
    required String userId,
    required String? method,
    required String? selectedLanguage,
  }) async {
    final outbox = _outbox;
    if (outbox != null) {
      final eventName = kind == AnalyticsOutboxEventKind.login
          ? Ga4Event.login
          : Ga4Event.signUp;
      final queued = await outbox.enqueue(
        AnalyticsOutboxEntry.event(
          kind: kind,
          id: id,
          userId: userId,
          userProperties: <String, String?>{
            Ga4UserProperty.isLogin: Ga4Value.loggedIn,
            Ga4UserProperty.language: Ga4Language.normalize(selectedLanguage),
          },
          parameters: Ga4Parameters.build(
            strings: <String, String?>{
              Ga4Param.method: method,
              Ga4Param.selectedLanguage: Ga4Language.normalize(
                selectedLanguage,
              ),
            },
            eventNameForLog: eventName,
          ),
        ),
      );
      if (queued) unawaited(outbox.flush());
      return queued;
    }

    // Explicit PicnicAnalytics injection is a compatibility seam for existing
    // focused tests. It still has a timeout so one native call cannot pin every
    // later auth event on this reporter's serialization chain.
    try {
      return await (kind == AnalyticsOutboxEventKind.login
              ? _a.logLogin(method: method, selectedLanguage: selectedLanguage)
              : _a.logSignUp(
                  method: method,
                  selectedLanguage: selectedLanguage,
                ))
          .timeout(sendTimeout);
    } on TimeoutException catch (e, s) {
      logger.e(
        'auth analytics sink timeout: ${kind.name}:$id',
        error: e,
        stackTrace: s,
      );
      return false;
    }
  }

  /// 로그아웃 시 호출한다. 저장된 로그인 서명을 지워 다음 로그인이
  /// 중복으로 오인되지 않게 한다.
  ///
  /// [onSignedIn] 과 같은 체인에서 실행된다 — 진행 중인 로그인 판정의
  /// read-then-write 사이에 끼어들어 서명을 지우면, 이미 발송된 `login` 의
  /// 서명이 저장되지 않아 다음 실행에서 한 번 더 나간다.
  Future<void> onSignedOut() {
    return _serialize(() async {
      try {
        await _store.clearLoginSignature();
      } catch (e, s) {
        logger.e('로그아웃 analytics 상태 정리 실패', error: e, stackTrace: s);
      }
    });
  }
}

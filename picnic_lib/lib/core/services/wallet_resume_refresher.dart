import 'dart:async';

import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/data/models/wallet/wallet_summary.dart';
import 'package:picnic_lib/presentation/providers/wallet_provider.dart';
import 'package:riverpod/riverpod.dart';

/// 앱 복귀 잔액 갱신의 최소 간격.
///
/// 앱 전환을 반복해도 재조회 폭풍이 되지 않게 하는 유일한 제동이다. 광고 결과
/// 목록 스윕을 걷어낸 뒤 복귀 경로에 남는 서버 왕복은 이 잔액 한 줄뿐이므로,
/// 여기서 새는 만큼이 그대로 운영 호출량이 된다.
const kWalletResumeRefreshCooldown = Duration(seconds: 60);

/// 복귀 갱신도 파우치와 **같은** 잔액 읽기 상한을 쓴다.
///
/// postgrest 는 타임아웃 없는 `http.Client` 를 쓰기 때문에, 소켓만 살아 있고
/// 응답이 오지 않는 상황에서 이 Future 는 완결되지 않는다. 복귀마다 그런
/// 요청이 하나씩 쌓이면 단일 비행 잠금이 영원히 풀리지 않는다.
const kWalletResumeRefreshReadTimeout = kWalletSummaryReadTimeout;

enum WalletResumeRefreshOutcome {
  /// 서버 잔액을 읽어 화면에 반영했다.
  refreshed,

  /// 비로그인 상태. 남의 세션으로 잔액을 읽지 않는다.
  notSignedIn,

  /// 파우치를 아직 아무도 열지 않았다. 복귀가 첫 로드를 만들지는 않는다.
  notLoaded,

  /// 직전 성공으로부터 [kWalletResumeRefreshCooldown] 이 지나지 않았다.
  cooledDown,

  /// 응답이 도착했을 때 이미 다른 계정/세대였다. 값을 버린다.
  superseded,

  /// 읽기가 실패했다. 화면에 있던 잔액을 그대로 둔다.
  failed,
}

/// 앱 복귀 시 **현재 계정의** 잔액만 한 번 다시 읽어 파우치에 적용한다.
///
/// 광고 결과 목록 자동 복구를 걷어내면서 복귀 경로가 잃는 것은 "그 사이 서버가
/// 지급한 금액이 파우치에 반영되는 것" 하나다. 목록 순회와 과거 보상 재폴링
/// 대신 잔액 한 줄만 읽어 그 자리를 대신한다.
///
/// 계정 격리가 이 클래스의 존재 이유다. 잔액 읽기는 느릴 수 있고, 그 사이
/// 로그아웃이나 계정 전환이 일어날 수 있다. 응답을 적용하기 전에 세대와 현재
/// 사용자를 다시 확인하므로 A 계정의 늦은 응답이 B 계정 화면을 덮지 못한다.
class WalletResumeRefresher {
  WalletResumeRefresher({
    required String? Function() currentUserId,
    required bool Function() isWalletLoaded,
    required Future<WalletSummaryModel> Function() readSummary,
    required void Function(WalletSummaryModel summary) applySummary,
    DateTime Function() clock = DateTime.now,
    Duration cooldown = kWalletResumeRefreshCooldown,
    Duration readTimeout = kWalletResumeRefreshReadTimeout,
  }) : _currentUserId = currentUserId,
       _isWalletLoaded = isWalletLoaded,
       _readSummary = readSummary,
       _applySummary = applySummary,
       _clock = clock,
       _cooldown = cooldown,
       _readTimeout = readTimeout;

  final String? Function() _currentUserId;
  final bool Function() _isWalletLoaded;
  final Future<WalletSummaryModel> Function() _readSummary;
  final void Function(WalletSummaryModel summary) _applySummary;
  final DateTime Function() _clock;
  final Duration _cooldown;
  final Duration _readTimeout;

  String? _activeUserId;
  DateTime? _lastSuccessAt;
  int _generation = 0;
  Future<WalletResumeRefreshOutcome>? _inFlight;

  /// 로그아웃·계정 전환에서 호출한다. 진행 중인 읽기의 응답도 함께 버린다.
  void reset() {
    _generation++;
    _activeUserId = null;
    _lastSuccessAt = null;
    _inFlight = null;
  }

  Future<WalletResumeRefreshOutcome> refreshOnResume() {
    final userId = _currentUserId();
    if (userId == null) {
      reset();
      return Future<WalletResumeRefreshOutcome>.value(
        WalletResumeRefreshOutcome.notSignedIn,
      );
    }
    if (_activeUserId != userId) {
      // 계정이 바뀌었다. 이전 계정의 쿨다운과 진행 중 읽기를 물려받지 않는다.
      _generation++;
      _activeUserId = userId;
      _lastSuccessAt = null;
      _inFlight = null;
    }

    // 파우치를 한 번도 읽지 않은 사용자에게 복귀가 새 RPC 를 만들지는 않는다.
    // 최초 로드는 provider 의 build 가, 명시적 새로고침은 재시도 버튼이 맡는다.
    if (!_isWalletLoaded()) {
      return Future<WalletResumeRefreshOutcome>.value(
        WalletResumeRefreshOutcome.notLoaded,
      );
    }

    // 겹친 복귀는 하나로 합친다. 인증 이벤트 리플레이와 resume 이 같은 프레임에
    // 도착해도 서버 왕복은 한 번이다.
    final inFlight = _inFlight;
    if (inFlight != null) return inFlight;

    final lastSuccess = _lastSuccessAt;
    if (lastSuccess != null) {
      final elapsed = _clock().difference(lastSuccess);
      // 시계가 뒤로 간 경우(수동 변경·NTP 보정)는 쿨다운으로 보지 않는다.
      // 그렇지 않으면 되돌아간 시간만큼 갱신이 막힌다.
      if (!elapsed.isNegative && elapsed < _cooldown) {
        return Future<WalletResumeRefreshOutcome>.value(
          WalletResumeRefreshOutcome.cooledDown,
        );
      }
    }

    final generation = _generation;
    final completer = Completer<WalletResumeRefreshOutcome>();
    final flight = completer.future;
    // 비동기 본문에 들어가기 전에 단일 비행을 먼저 게시한다. 첫 suspension
    // 지점에 도착한 호출자도 정확히 이 Future 를 받는다.
    _inFlight = flight;
    unawaited(
      _read(userId, generation).then(
        (outcome) {
          if (identical(_inFlight, flight)) _inFlight = null;
          completer.complete(outcome);
        },
        onError: (Object error, StackTrace stackTrace) {
          if (identical(_inFlight, flight)) _inFlight = null;
          completer.completeError(error, stackTrace);
        },
      ),
    );
    return flight;
  }

  Future<WalletResumeRefreshOutcome> _read(
    String userId,
    int generation,
  ) async {
    try {
      final summary = await _readSummary().timeout(_readTimeout);
      if (!_isCurrent(userId, generation)) {
        return WalletResumeRefreshOutcome.superseded;
      }
      _applySummary(summary);
      _lastSuccessAt = _clock();
      return WalletResumeRefreshOutcome.refreshed;
    } catch (error, stackTrace) {
      // 잔액 읽기 실패로 화면 값을 지우지 않는다. 실패는 쿨다운도 남기지 않아
      // 다음 복귀가 곧바로 다시 시도한다.
      logger.w(
        '복귀 잔액 갱신 실패 — 마지막으로 확인된 잔액을 유지한다',
        error: error,
        stackTrace: stackTrace,
      );
      return WalletResumeRefreshOutcome.failed;
    }
  }

  bool _isCurrent(String userId, int generation) =>
      generation == _generation &&
      _activeUserId == userId &&
      _currentUserId() == userId;
}

/// 앱이 복귀 갱신을 부르는 단일 창구.
///
/// `walletSummaryProvider` 의 공개 인터페이스만 소비한다 - 파우치를 새로
/// 만들지 않고([Ref.exists]), 값이 이미 있는 경우에만 갱신하며, 적용은
/// `setSummary` 가 가진 snapshot 순서 규칙을 그대로 통과한다.
final walletResumeRefresherProvider = Provider<WalletResumeRefresher>((ref) {
  final gateway = ref.watch(walletAuthGatewayProvider);
  return WalletResumeRefresher(
    // 인증 연동이 없는 환경(테스트 하네스)에서는 비로그인으로 취급한다.
    currentUserId: () =>
        gateway.isEnabled ? gateway.currentSession?.user.id : null,
    isWalletLoaded: () =>
        ref.exists(walletSummaryProvider) &&
        ref.read(walletSummaryProvider).hasValue,
    readSummary: () => ref.read(walletRepositoryProvider).getSummary(),
    applySummary: (summary) =>
        ref.read(walletSummaryProvider.notifier).setSummary(summary),
  );
});

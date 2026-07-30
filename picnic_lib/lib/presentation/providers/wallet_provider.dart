import 'dart:async';

import 'package:picnic_lib/core/config/environment.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/data/models/wallet/currency_history.dart';
import 'package:picnic_lib/data/models/wallet/wallet_amount.dart';
import 'package:picnic_lib/data/models/wallet/wallet_summary.dart';
import 'package:picnic_lib/data/repositories/wallet_repository.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:riverpod/riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part '../../generated/providers/wallet_provider.g.dart';

/// 세션 복구 이벤트를 기다리는 상한.
///
/// 콜드스타트에서 지갑 RPC가 세션 복구를 앞질러 익명으로 나가는 것을 막기 위한
/// 대기지만, **비로그인 사용자에게는 그 이벤트가 영원히 오지 않는다.** 상한이
/// 없으면 파우치가 그대로 로딩에 갇힌다.
const kWalletSessionRestoreTimeout = Duration(seconds: 3);

/// 잔액 읽기 1회의 상한.
///
/// postgrest 는 타임아웃 없는 `http.Client` 를 그대로 쓴다. 안드로이드에서
/// 네트워크가 바뀌거나 doze 에서 깨어난 직후처럼 소켓은 살아 있는데 응답이
/// 오지 않는 상황이면 `rpc()` 의 Future 는 **완결되지 않는다**. 잔액 한 줄
/// 읽기에 몇 초 이상 걸릴 이유가 없고, 실패는 재시도 버튼으로 회복 가능하므로
/// 짧게 끊는 편이 스피너에 갇히는 것보다 낫다.
const kWalletSummaryReadTimeout = Duration(seconds: 6);

@Riverpod(keepAlive: true)
WalletRepository walletRepository(Ref ref) => WalletRepository(supabase);

/// 지갑 요약이 인증 상태를 들여다보는 유일한 창구.
///
/// `supabase` 전역을 [WalletSummary] 안에서 직접 만지지 않는 이유:
/// 1. 세션 복구가 늦거나 아예 오지 않는 경우를 테스트가 재현할 수 있어야 한다.
///    그게 이 provider 가 무한 로딩에 빠지는 경로 중 하나였다.
/// 2. 테스트 하네스는 supabase 전역을 초기화하지 않는다.
abstract interface class WalletAuthGateway {
  /// 인증 연동이 살아 있는지. false 면 세션 대기도, 무효화 구독도 걸지 않는다.
  ///
  /// false 인 동안 [currentSession] / [authStateChanges] 는 호출되지 않는다.
  bool get isEnabled;

  Session? get currentSession;

  Stream<AuthState> get authStateChanges;
}

/// 프로덕션 구현. supabase 전역이 초기화된 실제 앱 환경에서만 활성화된다.
final class SupabaseWalletAuthGateway implements WalletAuthGateway {
  const SupabaseWalletAuthGateway();

  @override
  bool get isEnabled =>
      Environment.isInitialized && Environment.currentEnvironment != 'test';

  @override
  Session? get currentSession => supabase.auth.currentSession;

  @override
  Stream<AuthState> get authStateChanges => supabase.auth.onAuthStateChange;
}

final walletAuthGatewayProvider = Provider<WalletAuthGateway>(
  (ref) => const SupabaseWalletAuthGateway(),
);

/// 파우치 최초 로드 실패에 대한 자동 재시도 정책.
///
/// riverpod 3 은 build 실패를 기본값으로 **10회, 200ms→6.4s 백오프**로 자동
/// 재시도한다 (`ProviderContainer.defaultRetry`). 그 재시도 중의 상태는
/// `AsyncLoading`(`isReloading`) 이라서 카드는 그 시간 내내 스켈레톤을 띄운다.
/// [kWalletSummaryReadTimeout] 를 곱하면 실패가 화면에 드러나기까지 1분이 넘고,
/// 사용자에게는 그것도 "무한 로딩"이다.
///
/// 잔액 읽기에는 눈에 보이는 재시도 버튼이 있으므로 자동 재시도는 순간적인
/// 네트워크 딸꾹질만 흡수하면 된다. 짧게 한 번.
Duration? walletSummaryRetry(int retryCount, Object error) =>
    retryCount == 0 ? const Duration(milliseconds: 400) : null;

@Riverpod(keepAlive: true, retry: walletSummaryRetry)
class WalletSummary extends _$WalletSummary {
  @override
  Future<WalletSummaryModel> build() async {
    final repository = ref.watch(walletRepositoryProvider);
    final gateway = ref.watch(walletAuthGatewayProvider);

    if (!gateway.isEnabled) return _read(repository);

    // 콜드스타트에서 세션 복구보다 먼저 실행되면 RPC가 익명으로 나가
    // WALLET_UNAUTHENTICATED로 실패한다 (iOS 홈 배너 재현, 2026-07-28).
    // 세션이 아직 없으면 복구 이벤트를 잠깐 기다린다. 진짜 비로그인이면
    // 그대로 진행해 서버 응답에 맡기고(repository 가 0 잔액으로 매핑한다),
    // 이후 로그인은 아래 구독이 처리한다.
    final session = await _resolveSession(gateway);

    // 로그인/로그아웃이 일어나면 항상 최신 세션 기준으로 다시 읽는다.
    // keepAlive라 이 구독이 없으면 콜드스타트 실패(또는 이전 계정의 잔액)가
    // 명시적 refresh 전까지 눌러앉는다.
    //
    // ⚠️ 조건은 "이벤트 종류"가 아니라 **사용자 신원의 변화**다. gotrue 의
    // `onAuthStateChange` 는 `BehaviorSubject` (gotrue 2.18.0
    // `gotrue_client.dart:65`) 이므로 **새 구독자에게 마지막 이벤트를 즉시
    // 리플레이한다.** 세션 도중 한 번이라도 로그인이 일어나 마지막 이벤트가
    // `signedIn` 이 되면, 이벤트 종류만 보는 구독은 자기가 붙는 순간 그
    // `signedIn` 을 되받아 `invalidateSelf()` → `build()` 재실행 → 재구독 →
    // 리플레이 … 로 스스로를 영원히 무효화한다. `build()` 가 끝나지 못하므로
    // 파우치는 영구 로딩이 되고, 앱을 강제 종료해야 풀린다(재시작 직후
    // 마지막 이벤트는 `initialSession` 이라 리플레이가 무해하다).
    // 같은 사용자로 다시 온 `signedIn` 은 다시 읽을 이유가 없으니 무시한다.
    final builtForUserId = session?.user.id;
    final authEvents = gateway.authStateChanges.listen((change) {
      if (change.event != AuthChangeEvent.signedIn &&
          change.event != AuthChangeEvent.signedOut) {
        return;
      }
      if (change.session?.user.id == builtForUserId) return;
      ref.invalidateSelf();
    });
    ref.onDispose(authEvents.cancel);

    return _read(repository);
  }

  /// 세션이 준비될 때까지 **유한 시간만** 기다린다.
  ///
  /// 복구 이벤트가 오지 않아도(비로그인, 스트림 조기 종료) 반드시 반환한다.
  /// 여기서 매달리면 그게 곧 무한 로딩이다.
  Future<Session?> _resolveSession(WalletAuthGateway gateway) async {
    final current = gateway.currentSession;
    if (current != null) return current;
    try {
      final restored = await gateway.authStateChanges
          .firstWhere((change) => change.session != null)
          .timeout(kWalletSessionRestoreTimeout);
      return restored.session;
    } on TimeoutException {
      return null;
    } on StateError {
      // 세션 없이 스트림이 닫혔다 (클라이언트 dispose). 서버 응답에 맡긴다.
      return null;
    }
  }

  /// 잔액 읽기 1회. **반드시 유한 시간에 끝난다.** ([kWalletSummaryReadTimeout])
  Future<WalletSummaryModel> _read(WalletRepository repository) =>
      repository.getSummary().timeout(kWalletSummaryReadTimeout);

  /// 서버에서 잔액을 다시 읽는다. 실패하면 **화면에 있던 값을 유지한다.**
  ///
  /// 카드의 재시도 버튼과 구매/광고 정산 뒤의 백그라운드 재조회가 같은 경로를
  /// 쓴다. 후자가 네트워크 사정으로 실패했다고 이미 맞게 보여주던 잔액을
  /// 스피너나 에러 문구로 바꾸면 사용자에게는 잔액이 사라진 것으로 보인다.
  /// 보여줄 값이 없을 때만(최초 로드 실패 후의 재시도) 로딩으로 간다.
  Future<void> refresh() async {
    final previous = state.value;
    if (previous == null) {
      state = const AsyncLoading<WalletSummaryModel>();
    }

    final next = await AsyncValue.guard(
      () => _read(ref.read(walletRepositoryProvider)),
    );
    if (!ref.mounted) return;

    if (next case AsyncError(:final error, :final stackTrace)) {
      // await 사이에 정산 스냅샷([setSummary])이 들어왔을 수 있으므로 await
      // 이전 값이 아니라 **지금** 값을 기준으로 되돌린다.
      final keep = state.value ?? previous;
      if (keep != null) {
        logger.w(
          '지갑 재조회 실패 — 마지막으로 확인된 잔액을 유지한다',
          error: error,
          stackTrace: stackTrace,
        );
        state = AsyncData(keep);
        return;
      }
    }
    state = next;
  }

  /// Applies the balance a settled operation came back with.
  ///
  /// Three call sites write here - a settled vote, a watched rewarded ad, and a
  /// verified purchase - and each carries the wallet as of *its own* server
  /// response. They are independent round trips, so they can land out of order:
  /// receipt verification takes as long as the network takes, and an ad watched
  /// while it is in flight settles first. Applying the purchase's snapshot
  /// afterwards would put the displayed balance back to before the ad until the
  /// next [refresh].
  ///
  /// [WalletSummaryModel.snapshotAt] is the server's own ordering of those
  /// responses, which is why the contract carries it; an older one is dropped.
  /// Equal stamps take the later write - two responses stamped the same instant
  /// describe the same balance.
  ///
  /// [refresh] deliberately does not come through here: an explicit re-read is
  /// the newest thing there is.
  void setSummary(WalletSummaryModel summary) {
    final current = state.value;
    if (current != null && summary.snapshotAt.isBefore(current.snapshotAt)) {
      logger.i('⏪ 이전 스냅샷 무시: ${summary.snapshotAt} < ${current.snapshotAt}');
      return;
    }
    state = AsyncData(summary);
  }
}

@riverpod
class CurrencyHistory extends _$CurrencyHistory {
  @override
  Future<CurrencyHistoryPageModel> build(WalletCurrency currency) {
    return ref.watch(walletRepositoryProvider).getHistory(currency: currency);
  }

  bool _loadingNext = false;

  Future<void> loadNext() async {
    // 스크롤 끝 알림이 연달아 들어와도 페이지 요청은 한 번만 (PICNIC-APP-4R8)
    if (_loadingNext) return;
    final current = state.value;
    if (current == null || current.nextCursor == null) return;

    _loadingNext = true;
    try {
      final next = await ref
          .read(walletRepositoryProvider)
          .getHistory(currency: currency, cursor: current.nextCursor);
      // async gap 중 provider 가 dispose 되었으면 state 접근 금지
      if (!ref.mounted) return;
      // 응답이 도착한 시점의 state 기준으로 병합 (await 이전 스냅샷 사용 금지)
      final latest = state.value ?? current;
      final seen = latest.items.map((item) => item.id).toSet();
      state = AsyncData(
        latest.copyWith(
          items: [
            ...latest.items,
            ...next.items.where((item) => seen.add(item.id)),
          ],
          nextCursor: next.nextCursor,
          totalCount: next.totalCount,
        ),
      );
    } catch (e, s) {
      // 이미 불러온 페이지는 유지하고 실패만 보고한다.
      logger.e(
        'Failed to load next currency history page',
        error: e,
        stackTrace: s,
      );
    } finally {
      _loadingNext = false;
    }
  }
}

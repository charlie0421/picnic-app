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

/// 서버 읽기 캐시가 바뀌어야 하는 실제 인증 신원.
///
/// Supabase auth stream은 마지막 이벤트를 새 구독자에게 replay하고 토큰 갱신도
/// 같은 사용자로 여러 번 발행한다. 이벤트 종류를 cache boundary로 쓰면 replay
/// 무효화 루프가 생기므로, 사용자 ID가 실제로 달라질 때만 상태를 바꾼다.
final authSessionIdentityProvider =
    NotifierProvider<AuthSessionIdentity, String?>(AuthSessionIdentity.new);

void _handleAuthStateStreamError(Object _, StackTrace _) {
  // Auth exceptions may carry session/token material. The stream remains open
  // after transient errors, so retain the last identity and log no payload.
  logger.w('인증 상태 스트림 오류 — 현재 인증 상태를 유지한다');
}

final class AuthSessionIdentity extends Notifier<String?> {
  @override
  String? build() {
    final gateway = ref.watch(walletAuthGatewayProvider);
    if (!gateway.isEnabled) return null;

    var identity = gateway.currentSession?.user.id;
    final authEvents = gateway.authStateChanges.listen((change) {
      final next = change.session?.user.id;
      if (next == identity) return;
      identity = next;
      state = next;
    }, onError: _handleAuthStateStreamError);
    ref.onDispose(authEvents.cancel);
    return identity;
  }
}

/// 읽기 하나를 시작한 순간의 인증 신원. **스트림과 무관하게** 확인된다.
///
/// 응답이 도착했을 때 "이건 아직 이 화면의 것인가"를 물어야 하는데, 이벤트가
/// 실어다 주는 신호(무효화, epoch)는 그 시점에 아직 도착하지 않았을 수 있다.
/// gotrue 의 `onAuthStateChange` 는 `BehaviorSubject` 이고 rxdart subject 의
/// 기본값은 `sync: false` 다. 즉 **`currentSession` 은 바뀌는 턴에 즉시 갈리고,
/// 이벤트는 큐에만 들어간다.** 응답이 그 이벤트보다 먼저 큐에 있었다면 응답의
/// continuation 은 "세션은 이미 남의 것인데 아무 리스너도 모르는" 순간에 실행된다.
/// 그 순간 움직여 있는 것은 [session] 하나뿐이다.
///
/// [session] 을 `identical` 로 비교하는 이유:
/// * 사용자 ID 로는 A → B → A 왕복이 보이지 않는다. 양쪽 다 같은 ID 다.
/// * 이벤트 종류로도 안 된다. 이벤트가 아직 오지 않았다.
/// * gotrue 는 토큰을 갱신할 때마다 **새 `Session`** 을 만들어 갈아끼우므로
///   왕복이든 토큰 갱신이든 인스턴스가 달라진다.
/// * 반대로 `BehaviorSubject` 가 되돌려주는 리플레이는 **같은 인스턴스**라
///   조용히 통과한다 - 그게 리플레이와 실제 세션 교체의 차이다.
///
/// JWT 를 파싱하지 않는다. 만료 시각이나 access token 문자열을 들여다보는 것보다
/// 인스턴스 동일성이 싸고, 무엇보다 자격증명을 다루지 않는다.
final class _ReadIdentity {
  const _ReadIdentity({
    required this.generation,
    required this.authEpoch,
    required this.session,
  });

  final int generation;
  final int authEpoch;
  final Session? session;
}

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
  /// 이 notifier 가 몇 번째 [build] 를 살고 있는지.
  ///
  /// keepAlive notifier 는 `invalidateSelf()` 뒤에도 같은 인스턴스로 살아남고
  /// `ref.mounted` 도 계속 true 다. 그래서 진행 중인 읽기가 "아직 내 응답인가"를
  /// 물을 수 있는 것은 이 세대 번호뿐이다.
  int _generation = 0;

  /// 이 notifier 가 지금까지 **관측한 계정 전환 횟수**.
  ///
  /// A → B → A 는 마지막에 다시 A 지만, 그 사이 전환이 있었다. 사용자 ID 만
  /// 비교하면 그 왕복이 보이지 않고, 세대([_generation])로도 안 잡힌다 -
  /// `invalidateSelf()` 는 재빌드를 **예약**할 뿐이라 응답이 판정되는 순간에는
  /// 아직 첫 빌드다. 전환 전에 시작된 읽기가 "아직 내 계정"이라고 착각할 수
  /// 있는 창이 그 사이다.
  ///
  /// 같은 계정의 토큰 갱신이나 리플레이는 전환이 아니므로 올리지 않는다.
  /// 올리면 그것이 곧 재조회 루프다.
  int _authEpoch = 0;

  @override
  Future<WalletSummaryModel> build() async {
    final repository = ref.watch(walletRepositoryProvider);
    final gateway = ref.watch(walletAuthGatewayProvider);
    _generation++;

    if (!gateway.isEnabled) return _read(repository);

    // 콜드스타트에서 세션 복구보다 먼저 실행되면 RPC가 익명으로 나가
    // WALLET_UNAUTHENTICATED로 실패한다 (iOS 홈 배너 재현, 2026-07-28).
    // 세션이 아직 없으면 복구 이벤트를 잠깐 기다린다. 기다려도 세션이 없으면
    // **서버에 묻지 않고** 빈 지갑으로 답한다(아래 참조) - 익명 읽기는 잔액을
    // 받아올 수 없다. 이후 로그인은 아래 구독이 처리한다.
    await _awaitSessionRestore(gateway);

    // 그 대기는 최대 [kWalletSessionRestoreTimeout] 이고, 그 사이 사용자가 화면을
    // 떠나 컨테이너가 폐기될 수 있다. 폐기된 뒤로는 ref 를 만질 수 없다 - 아래
    // `ref.onDispose` 가 곧 던지고, 그러면 그 직전에 등록한 auth 구독은 취소할
    // 곳이 없어 그대로 남는다.
    if (!ref.mounted) return WalletRepository.signedOut();

    // 이 빌드가 대표하는 계정은 **복구 이벤트가 실어 온 세션이 아니라 지금
    // 세션**이다. gotrue 는 상태를 먼저 바꾸고 이벤트를 다음 턴에 흘리므로,
    // 기다림이 끝난 이벤트와 이 줄 사이에 로그아웃이 들어오면 그 이벤트가
    // 들고 있는 세션은 이미 없는 세션이다. 그것을 신원으로 삼으면 (1) 아래
    // 읽기가 `anon` 으로 나가고 (2) 아래 구독이 사라진 계정을 기준으로 걸려
    // 같은 계정의 재로그인을 전환으로 보지 못한다.
    final builtForUserId = gateway.currentSession?.user.id;

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
    //
    // 이벤트 종류로 거르지 않는 이유가 하나 더 있다. gotrue 는 저장소에서 복구한
    // 세션을 `signedIn` 이 아니라 `initialSession` 으로 알린다. 아래 세션 없는
    // 단락과 합쳐지면, 복구가 [kWalletSessionRestoreTimeout] 보다 늦은 콜드스타트에서
    // 파우치를 깨울 수 있는 이벤트는 이것뿐이다.
    final authEvents = gateway.authStateChanges.listen((change) {
      if (change.session?.user.id == builtForUserId) return;
      _authEpoch++;
      ref.invalidateSelf();
    }, onError: _handleAuthStateStreamError);
    ref.onDispose(authEvents.cancel);

    // 세션이 없으면 서버에 물을 것이 없다. 지갑 RPC 의 `anon` EXECUTE 는 설계상
    // 회수돼 있어서 이 읽기가 받아올 수 있는 것은 잔액이 아니라 권한 오류뿐이고,
    // 그 오류는 repository 가 매핑하는 `WALLET_UNAUTHENTICATED` 도 아니라 그대로
    // 에러 카드가 된다. 비로그인 사용자마다 서버에 권한 거부 로그를 남기면서.
    // 로그인은 위 구독이 처리한다.
    if (builtForUserId == null) return WalletRepository.signedOut();

    // 읽는 동안 로그아웃·계정 전환·왕복이 일어날 수 있고, 그 사실은 위 구독보다
    // 먼저 도착한다([_ReadIdentity]). 그러면 이 응답은 성공이든 실패든 이 화면의
    // 것이 아니다.
    final captured = _identity(gateway);
    try {
      final summary = await _read(repository);
      if (!_stillOwns(captured, gateway)) return _supersededRead(captured);
      return summary;
    } catch (error, stackTrace) {
      if (!_stillOwns(captured, gateway)) return _supersededRead(captured);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  /// 이 build 의 응답은 더 이상 이 화면의 것이 아니다. 값도 오류도 내보내지 않는다.
  ///
  /// 완결되지 않는 future 를 돌려주는 이유: **무엇을 반환하든 그것이 곧 상태로
  /// 게시된다.** riverpod 은 이미 무효화된 build 의 결과도 그대로 적용하므로,
  /// 빈 지갑을 반환하면 계정 전환 중에 잔액이 0 으로 번쩍이고, 던지면 잠깐
  /// 에러 카드가 뜬다. 완결하지 않으면 그 사이 상태는 **이전 값을 유지한**
  /// `AsyncLoading` 이고, 여기서 예약하는 재빌드가 새 주인의 값으로 교체한다.
  ///
  /// 영구 로딩이 되지 않는 근거는 재빌드를 여기서 **직접** 예약한다는 것이다.
  /// 뒤늦게 도착할 auth 이벤트에 기대지 않는다. 그리고 이 예약은 우리가 만든
  /// 신원 변화가 아니라 외부에서 이미 일어난 변화에만 반응하므로 - 리플레이는
  /// 같은 인스턴스라 여기까지 오지 않는다 - 스스로를 되먹이는 루프가 아니다.
  ///
  /// 단, 이미 다음 세대가 시작됐다면(`captured.generation != _generation`)
  /// 예약하지 않고 그냥 손을 뗀다. 그 경우 상태는 새 build 의 것이고, 여기서
  /// 또 무효화하면 **맞게 끝난 결과를 이유 없이 다시 읽게** 만든다. 세션만
  /// 갈렸는데 세대는 그대로일 때가 재빌드가 실제로 필요한 경우다.
  Future<WalletSummaryModel> _supersededRead(_ReadIdentity captured) {
    if (ref.mounted && captured.generation == _generation) {
      ref.invalidateSelf();
    }
    return Completer<WalletSummaryModel>().future;
  }

  /// 세션이 준비될 때까지 **유한 시간만** 기다린다.
  ///
  /// 복구 이벤트가 오지 않아도(비로그인, 스트림 조기 종료, 갱신 실패) 반드시
  /// 정상 반환한다. 여기서 매달리면 그게 곧 무한 로딩이고, 여기서 던지면
  /// [build] 가 실패해 그 아래 durable 구독이 아예 걸리지 않는다.
  ///
  /// 세션을 돌려주지 않는 이유: 이 이벤트는 "기다림이 끝났다"는 신호일 뿐이고,
  /// 읽기가 무엇으로 나갈지는 [build] 가 지금 세션에서 다시 읽어 정한다.
  Future<void> _awaitSessionRestore(WalletAuthGateway gateway) async {
    if (gateway.currentSession != null) return;
    try {
      await gateway.authStateChanges
          .firstWhere((change) => change.session != null)
          .timeout(kWalletSessionRestoreTimeout);
    } on TimeoutException {
      // 비로그인 사용자에게는 이 이벤트가 영원히 오지 않는다. 상한에서 손을 뗀다.
    } catch (error, stackTrace) {
      // `StateError`: 세션 없이 스트림이 닫혔다 (클라이언트 dispose).
      // `AuthException` 등: gotrue 는 토큰 갱신 실패를 복구 이벤트가 오는 그
      // 스트림의 **에러**로 흘린다. 게다가 그 스트림은 `BehaviorSubject` 라
      // 마지막 emission 을 새 구독자에게 리플레이하므로, 이 에러를 그대로
      // 던지면 자동 재시도 빌드도 같은 에러로 다시 죽는다. 그러면 durable
      // 구독이 없는 채로 끝나서 뒤늦게 도착하는 `initialSession` 을 받아줄
      // 곳이 사라진다(orphan) - 파우치는 그 세션 내내 그대로 굳는다.
      // 어느 쪽이든 여기서는 "아직 세션이 없다"로만 취급한다.
      _handleAuthStateStreamError(error, stackTrace);
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
  ///
  /// 세션이 없으면 읽지 않는다([build] 와 같은 이유). 응답을 반영하기 전에는
  /// 그 읽기를 시작한 신원이 아직 그대로인지 [_stillOwns] 로 확인한다 - 잔액
  /// 읽기는 느릴 수 있고 그 사이 로그아웃·계정 전환·토큰 갱신이 일어난다.
  /// `ref.mounted` 는 keepAlive notifier 의 재빌드를 걸러내지 못하고, 세대와
  /// 사용자 ID 만으로는 A → B → A 처럼 제자리로 돌아온 왕복을 볼 수 없다
  /// (양쪽 다 같은 ID 이고, 그것을 알려줄 이벤트는 아직 도착하지 않았다).
  /// 성공이든 실패든, 지금 세션이 시작하지 않은 읽기는 이 화면이 무엇을
  /// 보여줄지 결정하지 못한다.
  Future<void> refresh() async {
    // 정산 뒤의 백그라운드 재조회는 future 를 버리고 호출된다. 그 사이 사용자가
    // 화면을 떠났으면 notifier 는 이미 dispose 됐고, 아래 `ref.read` 가 곧
    // 던진다 - 아무도 받지 않는 곳에서.
    if (!ref.mounted) return;

    final gateway = ref.read(walletAuthGatewayProvider);
    final owner = _currentOwner(gateway);
    if (gateway.isEnabled && owner == null) {
      state = AsyncData(WalletRepository.signedOut());
      return;
    }

    var reReadForNewSession = false;
    while (true) {
      final captured = _identity(gateway);
      final previous = state.value;
      if (previous == null) {
        state = const AsyncLoading<WalletSummaryModel>();
      }

      final next = await AsyncValue.guard(
        () => _read(ref.read(walletRepositoryProvider)),
      );

      if (!_stillOwns(captured, gateway)) {
        // 이 응답은 지금 세션이 시작한 것이 아니다. 기존 `AsyncData` 는 그대로
        // 두고, 오류였다면 그 오류로 fallback 을 정하거나 기록하지도 않는다.
        // 화면에 값이 있으면 그것으로 끝이다 - 버린 응답도 결국 그 사용자의
        // 것이었고, 마지막으로 확인된 잔액이 이미 옳은 답이다.
        if (previous != null) return;

        // 보여줄 것이 없으면 사정이 다르다. 위에서 켠 `AsyncLoading` 을 그대로
        // 두고 물러나면 그게 영구 스피너다.
        if (!ref.mounted || _generation != captured.generation) return;
        if (!reReadForNewSession && _currentOwner(gateway) == owner) {
          // 같은 사용자의 토큰 갱신: 데이터는 이 화면의 것이니 새 세션으로
          // **한 번만** 다시 읽는다.
          reReadForNewSession = true;
          continue;
        }

        // 재시도 예산까지 쓴 뒤에도 세션이 또 갈렸거나 소유자가 바뀌었다.
        // stale 결과를 내보내는 것은 여전히 금지이므로, 지금 세션 기준으로
        // 다시 빌드하게 넘긴다 - 로딩에 갇히지 않는 유일한 남은 길이다.
        // (`refresh` 실패마다 무효화하는 것이 아니라, 보여줄 값이 없는 채로
        // 예산이 소진된 이 경우에만이다.)
        ref.invalidateSelf();
        return;
      }

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
      return;
    }
  }

  /// 인증 연동이 없는 환경(테스트 하네스)은 항상 비로그인으로 읽힌다.
  String? _currentOwner(WalletAuthGateway gateway) =>
      gateway.isEnabled ? gateway.currentSession?.user.id : null;

  /// 인증 연동이 없는 환경에서는 세션도 없다. `supabase` 전역을 만지지 않는다.
  Session? _currentSession(WalletAuthGateway gateway) =>
      gateway.isEnabled ? gateway.currentSession : null;

  /// 지금 이 읽기를 시작한다면 그 결과의 주인이 될 신원.
  _ReadIdentity _identity(WalletAuthGateway gateway) => _ReadIdentity(
    generation: _generation,
    authEpoch: _authEpoch,
    session: _currentSession(gateway),
  );

  /// [captured] 로 시작한 읽기의 결과가 **아직 이 화면의 것인지**.
  ///
  /// `false` 면 성공이든 실패든 그 결과로 상태를 정하지 않는다.
  bool _stillOwns(_ReadIdentity captured, WalletAuthGateway gateway) =>
      ref.mounted &&
      captured.generation == _generation &&
      captured.authEpoch == _authEpoch &&
      identical(captured.session, _currentSession(gateway));

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

/// Identity changes on every observed owner transition, including A → B → A.
/// A same-owner token refresh keeps the existing history session.
class WalletHistorySession {
  WalletHistorySession(this.userId);
  final String? userId;
}

final walletHistorySessionProvider = Provider.autoDispose<WalletHistorySession>(
  (ref) {
    final gateway = ref.watch(walletAuthGatewayProvider);
    if (!gateway.isEnabled) return WalletHistorySession(null);
    var observedOwner = gateway.currentSession?.user.id;
    final session = WalletHistorySession(observedOwner);
    final subscription = gateway.authStateChanges.listen(
      (change) {
        final nextOwner = change.session?.user.id;
        if (nextOwner == observedOwner) return;
        observedOwner = nextOwner;
        ref.invalidateSelf();
      },
      onError: _handleAuthStateStreamError,
    );
    ref.onDispose(subscription.cancel);
    return session;
  },
);

/// History is requested explicitly. Keep failures visible for manual retry
/// instead of multiplying requests through Riverpod's default retry policy.
Duration? currencyHistoryRetry(int retryCount, Object error) => null;

const kCurrencyHistoryReadTimeout = Duration(seconds: 6);

@Riverpod(retry: currencyHistoryRetry)
class CurrencyHistory extends _$CurrencyHistory {
  int _generation = 0;
  WalletHistorySession? _session;

  @override
  Future<CurrencyHistoryPageModel> build(WalletCurrency currency) {
    final session = ref.watch(walletHistorySessionProvider);
    _session = session;
    _generation++;
    _loadingNext = false;
    if (session.userId == null) {
      throw StateError('Wallet history requires an authenticated user');
    }
    return ref
        .watch(walletRepositoryProvider)
        .getHistory(currency: currency)
        .timeout(kCurrencyHistoryReadTimeout);
  }

  bool _loadingNext = false;

  Future<bool> loadNext() async {
    // 스크롤 끝 알림이 연달아 들어와도 페이지 요청은 한 번만 (PICNIC-APP-4R8)
    if (_loadingNext) return true;
    final session = ref.read(walletHistorySessionProvider);
    if (session.userId == null || !identical(session, _session)) return true;
    final generation = _generation;
    final current = state.value;
    if (current == null || current.nextCursor == null) return true;

    _loadingNext = true;
    try {
      final next = await ref
          .read(walletRepositoryProvider)
          .getHistory(currency: currency, cursor: current.nextCursor)
          .timeout(kCurrencyHistoryReadTimeout);
      // async gap 중 provider 가 dispose 되었으면 state 접근 금지
      if (!ref.mounted ||
          generation != _generation ||
          !identical(session, ref.read(walletHistorySessionProvider))) {
        return true;
      }
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
      return true;
    } catch (e, s) {
      // 이미 불러온 페이지는 유지하고 실패만 보고한다.
      logger.e(
        'Failed to load next currency history page',
        error: e,
        stackTrace: s,
      );
      return false;
    } finally {
      if (generation == _generation) _loadingNext = false;
    }
  }
}

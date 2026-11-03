import 'dart:async';
import 'package:picnic_lib/core/errors/anti_abuse_exception.dart';
import 'package:picnic_lib/core/utils/rate_limited_handler.dart';
import 'package:picnic_lib/presentation/widgets/anti_abuse/rate_limited_dialog.dart';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:picnic_lib/core/analytics/picnic_analytics.dart';
import 'package:picnic_lib/core/config/environment.dart';
import 'package:picnic_lib/data/models/ad/ad_reward_status.dart';
import 'package:picnic_lib/data/repositories/ad_reward_repository.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/main_initializer.dart';
import 'package:picnic_lib/core/utils/startup_readiness.dart';
import 'package:picnic_lib/core/utils/ui.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/dialogs/require_login_dialog.dart';
import 'package:picnic_lib/presentation/dialogs/simple_dialog.dart';
import 'package:picnic_lib/presentation/providers/ad_reward_provider.dart';
import 'package:picnic_lib/presentation/providers/ad_reward_recovery_provider.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/ad_platform.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/free_charge_analytics.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:universal_io/io.dart';
import 'package:uuid/uuid.dart';

typedef AdmobClaimCreator =
    Future<AdmobClaimModel> Function({
      required String platform,
      required String placementId,
      required String clientRequestId,
    });

class AdmobClaimPreflightResult {
  const AdmobClaimPreflightResult({
    required this.signedToken,
    required this.reference,
  });

  final String signedToken;
  final AdRewardReference reference;
}

/// SDK가 광고를 표시하기 전에 AdMob SSV용 opaque 토큰을 발급받는다.
///
/// 발급 실패를 호출자에게 전파하므로, 호출자는 [RewardedAd.show]에 도달하지 않는다.
///
/// 발급된 클레임 참조는 Pangle 과 같은 계약으로 [persist] 에 넘긴다 — 보상은
/// Google 의 SSV 콜백이 서버에 닿은 뒤에야 GRANTED 가 되므로(클레임 생성 기준
/// p50 19~21초, p90 61~66초), 앱은 그 참조로 상태를 폴링해 적립 영수증을 띄우고
/// ack 해야 한다. 예전에는 참조를 버려서 정상 적립조차 화면에 반영되지 않았고,
/// 광고 닫힘 직후의 프로필 새로고침은 대개 적립보다 먼저 실행됐다.
class AdmobClaimPreflight {
  const AdmobClaimPreflight({required this.createClaim, required this.persist});

  final AdmobClaimCreator createClaim;
  final Future<void> Function(String ownerUserId, AdRewardReference reference)
  persist;

  Future<AdmobClaimPreflightResult> execute({
    required String ownerUserId,
    required String platform,
    required String placementId,
    required String clientRequestId,
  }) async {
    if (ownerUserId.isEmpty) {
      throw StateError('Authenticated user required for AdMob claim');
    }
    final claim = await createClaim(
      platform: platform,
      placementId: placementId,
      clientRequestId: clientRequestId,
    );
    if (claim.signedToken.isEmpty) {
      throw const FormatException('AdMob claim is missing a signed token');
    }
    await persist(ownerUserId, claim.reference);
    return AdmobClaimPreflightResult(
      signedToken: claim.signedToken,
      reference: claim.reference,
    );
  }
}

/// 로드된 광고를 실제로 채운 광고 소스 요약.
///
/// 진단용이다. Google 은 SSV 콜백에 `ad_network` 소스 ID 를 함께 보내는데,
/// 프로덕션 24시간 콜백 21,881건이 전부 AdMob 네트워크(5450213213286189855)
/// 였고 Meta·Pangle·Liftoff 미디에이션 소스는 0건이었다(2026-09-14). 미디에이션
/// 채움이 SSV 없이 끝나 PENDING 으로 남는지는 기기에서만 가릴 수 있으므로,
/// 로드 시점의 소스를 로그와 Sentry breadcrumb 으로 남긴다.
class AdmobAdSourceSummary {
  const AdmobAdSourceSummary({
    required this.adSourceName,
    required this.adSourceId,
    required this.adapterClassName,
    required this.mediationAdapterClassName,
    required this.responseId,
  });

  factory AdmobAdSourceSummary.fromResponseInfo(ResponseInfo? info) {
    final loaded = info?.loadedAdapterResponseInfo;
    return AdmobAdSourceSummary(
      adSourceName: loaded?.adSourceName,
      adSourceId: loaded?.adSourceId,
      adapterClassName: loaded?.adapterClassName,
      mediationAdapterClassName: info?.mediationAdapterClassName,
      responseId: info?.responseId,
    );
  }

  /// Google 의 SSV `ad_network` 파라미터가 AdMob 네트워크일 때 쓰는 소스 ID.
  static const String admobNetworkSourceId = '5450213213286189855';

  final String? adSourceName;
  final String? adSourceId;
  final String? adapterClassName;
  final String? mediationAdapterClassName;
  final String? responseId;

  /// 타사 미디에이션 네트워크가 채웠으면 true, AdMob 네트워크면 false,
  /// 판단할 정보가 없으면 null.
  bool? get isMediated {
    final adapter = adapterClassName ?? mediationAdapterClassName;
    if (adSourceId == admobNetworkSourceId) return false;
    if (adSourceId != null && adSourceId!.isNotEmpty) return true;
    if (adapter == null || adapter.isEmpty) return null;
    return !adapter.toLowerCase().contains('mediation.admob');
  }

  String describe() {
    if (adSourceName == null &&
        adSourceId == null &&
        adapterClassName == null &&
        mediationAdapterClassName == null) {
      return 'ad_source=unknown';
    }
    final source = adSourceName ?? '?';
    final id = adSourceId == null ? '' : '($adSourceId)';
    final adapter = adapterClassName ?? mediationAdapterClassName ?? '?';
    return 'ad_source=$source$id adapter=$adapter '
        'mediated=${isMediated ?? 'unknown'} response=${responseId ?? '-'}';
  }

  Map<String, dynamic> toBreadcrumbData() => {
    'ad_source_name': adSourceName,
    'ad_source_id': adSourceId,
    'adapter': adapterClassName ?? mediationAdapterClassName,
    'mediated': isMediated,
    'response_id': responseId,
  };
}

/// [AdmobShowFlow] 가 로드된 광고 한 건마다 표시 delegate 에 넘기는 핸들.
///
/// delegate 는 claim 발급·SSV 설정처럼 `await` 를 사이에 두고 표시를 준비한다.
/// 그 사이 타임아웃·dispose·새 attempt 가 일어날 수 있다. 그래서 delegate 는
/// 매 `await` 뒤에 [isActive] 를 확인하고, 표시를 포기할 때는 [abandon] 을 부른다.
class AdmobShowAttempt {
  AdmobShowAttempt._({
    required bool Function() isActive,
    required bool Function() abandon,
    required void Function() showSubmitted,
  }) : _isActive = isActive,
       _abandon = abandon,
       _showSubmitted = showSubmitted;

  final bool Function() _isActive;
  final bool Function() _abandon;
  final void Function() _showSubmitted;

  /// delegate 가 `ad.show()` 를 호출하기 직전에 부른다. 이때부터 광고가 실제로
  /// 떠 있을 수 있으므로 flow 의 정리 대상에서 뺀다 — onShowed 가 유실돼도
  /// 다음 요청·dispose 가 광고를 폐기해 SDK 보상 라우팅을 지우지 않게 한다.
  /// 정리는 광고 자신의 dismissed/failedToShow 가 맡는다.
  void showSubmitted() => _showSubmitted();

  /// 이 attempt 가 UI terminal 전이고 광고도 정리되지 않았으면 true.
  /// false 이면 delegate 는 `ad.show()` 를 호출하지 않는다.
  bool get isActive => _isActive();

  /// 광고를 표시하지 않고 정리한다. 이 호출이 attempt 를 끝냈으면 true 를
  /// 반환한다 — 그때만 호출자가 스피너를 풀고 안내를 띄운다. 이미 타임아웃
  /// 등으로 끝난 attempt 이면 false 이고, 호출자는 UI 를 건드리지 않는다.
  bool abandon() => _abandon();
}

/// 로드된 광고 한 건의 정리 상태. 정리는 정확히 한 번만 일어난다.
class _LoadedAd<T> {
  _LoadedAd(this.ad, this._dispose);

  final T ad;
  final void Function(T ad) _dispose;
  bool _released = false;

  bool get isReleased => _released;

  void release() {
    if (_released) return;
    _released = true;
    _dispose(ad);
  }
}

/// AdMob 로드→준비(claim·SSV)→표시 한 사이클의 상태 기계.
///
/// - 로드/표시 각 단계에 워치독을 걸어 SDK 콜백이나 claim 응답이 오지 않아도
///   반드시 UI terminal 중 정확히 하나로 끝난다 (조사 보고서 §1.3 의 "영구
///   정지" 차단). **UI terminal** = `onLoadTimeout` / `onLoadFailed` /
///   `onShowTimeout` / `onShowFailed` / `onShowStarted` 중 하나, 또는
///   [AdmobShowAttempt.abandon] 이 true 를 반환한 경우다. 표시 워치독은 로드
///   완료부터 onShowed 까지(claim·SSV 준비 포함) 걸린다.
/// - 세대 토큰(`_generation`)으로 늦게 도착한 SDK 콜백·claim 응답의 UI 액션을
///   무시한다. 광고 정리는 세대와 무관하게 **광고 한 건마다 정확히 한 번**
///   수행한다(`_LoadedAd`). 늦게 도착한 구세대 콜백은 자기 광고만 정리하므로
///   신세대 attempt 의 광고를 폐기하지 않는다.
/// - **표시를 요청한 광고(showSubmitted)와 화면에 뜬 광고(onShowed)는 flow 의
///   정리 대상에서 빠진다.** 다음 attempt 나 [dispose] 가 그 광고를 폐기하지
///   않고, 광고 자신의 dismissed/failedToShow 가 정리한다. SDK 는 dispose 때
///   광고의 이벤트 라우팅을 지우므로, 떠 있는 광고를 폐기하면 보상 콜백이
///   버려져 적립 확인 폴링이 시작되지 않는다.
/// - 한 attempt 는 로드 결과를 **한 번만** 받는다. SDK 는 같은 광고 객체로
///   onAdLoaded 를 다시 보낼 수 있다. 이미 받은 광고의 재전달은 무시하고(소유·
///   표시 중일 수 있다), 그 밖의 광고는 광고마다 한 번만 정리한다.
/// - `onDismissed` 는 onShowed 가 이 attempt 를 끝냈고, 그 뒤 새 attempt 나
///   dispose 가 없었을 때만 UI 액션을 전달한다.
/// - SDK 타입·BuildContext 에 의존하지 않아 fake 로 유닛 테스트가 가능하다
///   (PangleClaimPreflight 와 같은 패턴).
class AdmobShowFlow<T> {
  AdmobShowFlow({
    required this.startLoad,
    required this.attachCallbacksAndShow,
    required this.disposeAd,
    this.loadTimeout = const Duration(seconds: 15),
    this.showTimeout = const Duration(seconds: 10),
  });

  /// RewardedAd.load 호출. 결과는 콜백으로만 판정한다 — load 가 반환하는
  /// Future 는 로드 성공/실패와 무관하므로 신뢰하지 않는다.
  final void Function(
    void Function(T ad) onLoaded,
    void Function(Object error) onFailedToLoad,
  )
  startLoad;

  /// fullScreenContentCallback 배선 + 표시 준비(claim·SSV) + ad.show 를
  /// 수행한다. 인자로 받은 콜백을 SDK 콜백에 그대로 연결해야 한다. 비동기
  /// delegate 는 매 await 뒤에 [AdmobShowAttempt.isActive] 를 확인한다.
  /// 반환된 Future 의 오류는 동기 throw 와 같이 표시 실패 단일 경로로 합류한다.
  final FutureOr<void> Function(
    T ad, {
    required void Function() onShowed,
    required void Function() onDismissed,
    required void Function(Object error) onFailedToShow,
    required AdmobShowAttempt attempt,
  })
  attachCallbacksAndShow;

  final void Function(T ad) disposeAd;
  final Duration loadTimeout;
  final Duration showTimeout;

  /// UI terminal 가드. attempt 시작·terminal·dispose 마다 증가한다.
  int _generation = 0;

  /// attempt 소유권. attempt 시작과 dispose 때만 증가한다 — terminal 뒤에 오는
  /// 같은 attempt 의 정상 후속 이벤트(dismissed)를 구분한다.
  int _attempt = 0;
  Timer? _watchdog;

  /// 아직 화면에 뜨지 않은, flow 가 정리 책임을 지는 광고.
  _LoadedAd<T>? _pending;

  bool _isCurrent(int g) => g == _generation;

  void _cancelWatchdog() {
    _watchdog?.cancel();
    _watchdog = null;
  }

  /// 이 attempt 를 UI terminal 상태로 만든다. 이후 도착하는 같은 세대의 SDK
  /// 콜백은 UI 액션을 건너뛴다. 광고 정리는 [_LoadedAd] 가 따로 관리한다.
  void _finish(int g) {
    if (_isCurrent(g)) {
      _generation++;
      _cancelWatchdog();
    }
  }

  void _disposePending() {
    final pending = _pending;
    _pending = null;
    pending?.release();
  }

  void run({
    required void Function() onLoadTimeout,
    required void Function(Object error) onLoadFailed,
    required void Function() onShowStarted,
    required void Function() onShowTimeout,
    required void Function(Object error) onShowFailed,
    required void Function() onDismissed,
  }) {
    _attempt++;
    _generation++; // 새 attempt 시작 = 이전 attempt 전부 무효화
    _disposePending();
    final a = _attempt;
    final g = _generation;
    _cancelWatchdog();

    _watchdog = Timer(loadTimeout, () {
      if (!_isCurrent(g)) return;
      _finish(g);
      onLoadTimeout();
    });

    // 이 attempt 가 받아들인 광고, 그리고 받아들이지 않고 정리한 광고들.
    // 로드 결과는 성공·실패를 합쳐 한 번만 받는다 — 성공을 받은 뒤 늦게 온
    // 실패 콜백이나 load Future 오류는 claim·SSV 준비를 취소하지 않는다.
    T? accepted;
    final rejected = Set<T>.identity();

    void handleLoadFailed(Object error) {
      if (accepted != null) return; // 이미 성공을 받았다 — 늦은 실패는 무시
      if (!_isCurrent(g)) return; // 늦은 실패 콜백 — 이미 타임아웃 처리됨
      _finish(g);
      onLoadFailed(error);
    }

    void rejectOnce(T ad) {
      if (rejected.add(ad)) disposeAd(ad);
    }

    try {
      startLoad((ad) {
        final first = accepted;
        if (first != null) {
          // 같은 attempt 의 중복 로드 결과. 이미 받은 같은 광고는 준비·표시
          // 중이므로 건드리지 않는다. 다른 광고면 그 광고만 정리한다.
          if (!identical(first, ad)) rejectOnce(ad);
          return;
        }
        if (!_isCurrent(g)) {
          // 타임아웃/재시도/dispose 이후 늦게 도착한 onAdLoaded — 조용히 폐기.
          rejectOnce(ad);
          return;
        }
        accepted = ad;
        _cancelWatchdog();
        final loaded = _LoadedAd<T>(ad, disposeAd);
        _pending = loaded;
        var showedFired = false;
        _watchdog = Timer(showTimeout, () {
          if (!_isCurrent(g)) return;
          _finish(g);
          // 광고가 실제로 떠 있는데 콜백만 유실된 경우일 수 있으므로 여기서
          // ad 를 dispose 하지 않는다.
          onShowTimeout();
        });

        void releaseLoaded() {
          if (identical(_pending, loaded)) _pending = null;
          loaded.release();
        }

        void handleShowFailed(Object error) {
          releaseLoaded(); // 늦게 오더라도 자기 광고 정리는 항상 수행
          if (!_isCurrent(g)) return;
          _finish(g);
          onShowFailed(error);
        }

        final attempt = AdmobShowAttempt._(
          isActive: () => _isCurrent(g) && !loaded.isReleased,
          abandon: () {
            releaseLoaded();
            if (!_isCurrent(g)) return false;
            _finish(g);
            return true;
          },
          showSubmitted: () {
            if (identical(_pending, loaded)) _pending = null;
          },
        );

        try {
          final result = attachCallbacksAndShow(
            ad,
            onShowed: () {
              // 광고가 실제로 떴다 — 정리 책임을 광고 자신의 dismissed /
              // failedToShow 로 넘긴다. 표시 타임아웃 뒤에 늦게 떠도 사용자는
              // 그 광고를 보고 있으므로 세대와 무관하게 수행한다.
              if (identical(_pending, loaded)) _pending = null;
              if (!_isCurrent(g)) return;
              showedFired = true;
              _finish(g);
              onShowStarted();
            },
            onDismissed: () {
              // 자기 광고만 정리한다(BLOCKER-1). UI 액션은 onShowed 가 이
              // attempt 를 끝냈고 그 뒤 새 attempt·dispose 가 없을 때만 전달한다.
              final wasLive = !loaded.isReleased;
              releaseLoaded();
              if (!wasLive || !showedFired || a != _attempt) return;
              onDismissed();
            },
            onFailedToShow: handleShowFailed,
            attempt: attempt,
          );
          if (result is Future<void>) {
            unawaited(
              result.then<void>(
                (_) {},
                onError: (Object error, StackTrace _) =>
                    handleShowFailed(error),
              ),
            );
          }
        } catch (e) {
          // delegate 가 콜백 배선 중 동기 throw 하면 표시 실패 단일
          // 경로로 합류시킨다.
          handleShowFailed(e);
        }
      }, handleLoadFailed);
    } catch (e) {
      // delegate 가 동기 throw 하면(예: RewardedAd.load 설정 오류) 로드
      // 실패 단일 경로로 합류시킨다.
      handleLoadFailed(e);
    }
  }

  void dispose() {
    _attempt++;
    _generation++;
    _cancelWatchdog();
    _disposePending();
  }
}

/// 표시 직전 claim 발급과 보상 이후 적립 확인 폴링에 쓰는 의존성 묶음.
///
/// [AdmobPlatform.createRewardWiring] 이 첫 `await` **이전**에 만든다. 폴링은
/// 광고가 끝난 뒤 돌아오는데 그 사이 이 화면이 사라지면 `AdPlatform.ref` 의
/// read 가 던져 확정된 적립 확인이 조용히 사라지기 때문이다(Pangle 과 같은 이유).
class AdmobRewardWiring {
  const AdmobRewardWiring({required this.preflight, required this.poll});

  final AdmobClaimPreflight preflight;
  final Future<void> Function({
    required String ownerUserId,
    required AdRewardReference reference,
  })
  poll;
}

/// showAd 요청 한 건의 고정 컨텍스트.
///
/// showAd 진입 시점, 첫 await(로그인·정책 확인) 이전에 만들고 바꾸지 않는다.
/// 정책·준비·로드·claim·SSV·표시·보상 폴링은 인스턴스 필드가 아니라 이 값을
/// 쓴다. 그래야 그 사이 시작된 다른 요청이 owner·GA4·갱신 상태를 덮어써도
/// 이 요청의 결과가 다른 요청·계정으로 이어지지 않는다.
class _AdmobRequest {
  _AdmobRequest({
    required this.seq,
    required this.owner,
    required this.logGa4Impression,
    required this.refreshUserProfileOnce,
  });

  final int seq;

  /// 진입 시점 사용자 ID. claim·SSV·보상 폴링의 소유자다.
  final String? owner;
  final void Function() logGa4Impression;
  final void Function() refreshUserProfileOnce;
}

/// AdMob 광고 플랫폼 구현
/// 참고: AdMob SDK 초기화는 MainInitializer._initializeAdMob()에서 앱 시작 시 수행됨
class AdmobPlatform extends AdPlatform {
  String _adUnitId = '';

  /// 가장 최근 showAd 요청의 순번. 이보다 오래된 요청은 비활성이다.
  int _requestSeq = 0;

  /// 현재 요청의 흐름. 요청마다 새로 만들고, 새 요청이 시작되면 이전 흐름을
  /// dispose 한다(아직 표시 요청 전인 광고만 정리되고 워치독이 멈춘다).
  AdmobShowFlow<RewardedAd>? _flow;

  /// 현재 attempt 의 "프로필 1회 갱신" 클로저 — [beginProfileRefreshAttempt] 가
  /// attempt 마다 새로 만들어 심는다(MINOR-1: attempt 별 dedup).
  void Function() _currentProfileRefreshOnce = () {};

  @visibleForTesting
  void Function() beginProfileRefreshAttempt() {
    var refreshed = false;
    void refreshOnce() {
      if (refreshed) return;
      refreshed = true;
      commonUtils.refreshUserProfile();
    }

    _currentProfileRefreshOnce = refreshOnce;
    return refreshOnce;
  }

  @visibleForTesting
  void Function() captureProfileRefreshOnce() => _currentProfileRefreshOnce;

  AdmobPlatform(
    super.ref,
    super.context,
    super.id,
    AnimationController super.animationController,
  );

  @override
  Future<void> initialize() async {
    if (isDisposed) return;

    // 광고 ID만 초기화 (SDK 초기화는 앱 시작 시 완료됨)
    await _initAdUnitId();
  }

  Future<void> _initAdUnitId() async {
    if (Environment.admobIosRewardedVideoId == null ||
        Environment.admobAndroidRewardedVideoId == null) {
      logger.w('[$id] 광고 ID가 설정되지 않음');
      return;
    }

    try {
      _adUnitId = isIOS()
          ? Environment.admobIosRewardedVideoId!
          : Environment.admobAndroidRewardedVideoId!;

      logger.i('[$id] 광고 ID 초기화: $_adUnitId');
    } catch (e, s) {
      logger.e('[$id] 광고 ID 초기화 실패', error: e, stackTrace: s);
    }
  }

  // ---------------------------------------------------------------------------
  // 프로덕션 의존성 경계. 기본 구현이 실제 동작이고, 위젯 테스트만 재정의해
  // SDK 채널·Supabase·전역 다이얼로그 없이 showAd() 의 실제 배선을 돌린다.
  // ---------------------------------------------------------------------------

  /// 현재 인증 사용자 ID (SSV userId · claim 소유자).
  @visibleForTesting
  String? currentUserId() => supabase.auth.currentUser?.id;

  /// 동의(UMP)·SDK 준비를 기다린 뒤 [request] 를 실행한다. 준비가 안 되면
  /// [AdsUnavailable] 을 던진다.
  @visibleForTesting
  Future<void> runWhenAdsReady({
    required bool Function() isRequestActive,
    required Future<void> Function() request,
  }) {
    return MainInitializer.runAdRequestWhenReady<void>(
      isRequestActive: isRequestActive,
      request: request,
    );
  }

  /// SDK 로드 호출. 결과는 [callback] 으로만 전달된다.
  @visibleForTesting
  Future<void> loadRewardedAd({
    required String adUnitId,
    required RewardedAdLoadCallback callback,
  }) {
    return RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: callback,
    );
  }

  /// claim 발급·영속화와 적립 확인 폴링 의존성. 첫 await 이전에 호출된다.
  @visibleForTesting
  AdmobRewardWiring createRewardWiring() {
    final pendingStore = ref.read(pendingAdRewardStoreProvider);
    final adRewardRecovery = ref.read(adRewardRecoveryProvider.notifier);
    return AdmobRewardWiring(
      preflight: AdmobClaimPreflight(
        createClaim: AdRewardRepository(supabase).createAdmobClaim,
        persist: pendingStore.add,
      ),
      poll: adRewardRecovery.poll,
    );
  }

  @visibleForTesting
  void showErrorDialog(String content) {
    showSimpleDialog(content: content, type: DialogType.error);
  }

  @visibleForTesting
  Future<void> showRateLimited(AntiAbuseException restriction) {
    return showRateLimitedDialog(
      context,
      channel: restriction.channel,
      rawCode: restriction.rawCode,
    );
  }

  @visibleForTesting
  void showLoginRequired() => showRequireLoginDialog();

  // ---------------------------------------------------------------------------

  @override
  Future<void> showAd() async {
    // 첫 await(safelyExecute 의 로그인·정책 확인) 이전에 이 요청을 고정한다.
    // 새 요청이 시작되면 이전 요청의 흐름을 끝낸다 — 표시 요청 전인 광고만
    // 정리되고, 이미 표시를 요청한 광고는 자기 dismissed 가 정리한다.
    final request = _AdmobRequest(
      seq: ++_requestSeq,
      owner: currentUserId(),
      // MAJOR-2: 구좌 클릭 시점의 GA4 컨텍스트를 스냅샷한다.
      logGa4Impression: captureGa4ImpressionLogger(),
      refreshUserProfileOnce: beginProfileRefreshAttempt(),
    );
    _flow?.dispose();
    _flow = null;
    bool isActive() => _isActiveRequest(request);

    await safelyExecute(isRequestActive: isActive, () async {
      if (!context.mounted || isDisposed || !isActive()) return;

      final owner = request.owner;
      if (owner == null || owner.isEmpty) {
        logger.e('[$id] SSV userId가 없음 - 인증 세션 만료 가능성');
        stopAllAnimations();
        showLoginRequired();
        return;
      }
      if (!_requestOwnerIsCurrent(request)) return;

      if (_adUnitId.isEmpty) {
        await _initAdUnitId();
      }
      startButtonAnimation();
      logger.i('[$id] 광고 로드 시작: $_adUnitId');

      try {
        await runWhenAdsReady(
          isRequestActive: isActive,
          request: () async {
            if (!isActive()) return;
            if (!_requestOwnerIsCurrent(request)) return;
            _runFlow(request);
          },
        );
      } on AdsUnavailable catch (e) {
        if (!isActive()) {
          // 더 새로운 요청이 스피너·안내를 이어받았다.
          logger.i('[$id] 대체된 광고 요청 종료: $e');
          return;
        }
        // 준비 대기 종료·동의 미허용·화면 닫기는 SDK 로드 오류가 아니다.
        logger.i('[$id] 광고 요청 보류: $e');
        stopAllAnimations();
        if (context.mounted && !isDisposed) {
          showErrorDialog(AppLocalizations.of(context).label_ads_load_fail);
        }
      } catch (e, s) {
        if (!isActive()) {
          logger.w('[$id] 대체된 광고 요청의 준비 실패', error: e, stackTrace: s);
          return;
        }
        logAdLoadFailure('AdMob', e, _adUnitId, e.toString(), s);
        stopAllAnimations();
      }
    });
  }

  bool _isActiveRequest(_AdmobRequest request) =>
      request.seq == _requestSeq && !isDisposed && context.mounted;

  /// 요청 owner 가 아직 현재 사용자인지 확인한다(흐름 시작 전 경계용).
  /// 다르면 스피너를 풀고 안내한다(로그아웃이면 로그인 안내, 계정 전환이면
  /// 로드 실패 안내).
  bool _requestOwnerIsCurrent(_AdmobRequest request) {
    final current = currentUserId();
    if (current == request.owner) return true;
    stopAllAnimations();
    _notifyOwnerChanged(current);
    return false;
  }

  void _runFlow(_AdmobRequest request) {
    final flow = AdmobShowFlow<RewardedAd>(
      startLoad: _startLoad,
      attachCallbacksAndShow:
          (
            ad, {
            required onShowed,
            required onDismissed,
            required onFailedToShow,
            required attempt,
          }) => _attachCallbacksAndShow(
            ad,
            request: request,
            onShowed: onShowed,
            onDismissed: onDismissed,
            onFailedToShow: onFailedToShow,
            attempt: attempt,
          ),
      disposeAd: (ad) => ad.dispose(),
    );
    _flow = flow;
    flow.run(
      onLoadTimeout: () {
        logger.w('[$id] 광고 로드 타임아웃 (${flow.loadTimeout.inSeconds}s)');
        // '광고 로드 시간 초과' 는 isNonReportableAdError 키워드에 걸려
        // "모든 광고 소진" 안내 + Sentry 미보고로 처리된다.
        logAdLoadFailure(
          'AdMob',
          TimeoutException('admob load timeout', flow.loadTimeout),
          _adUnitId,
          '광고 로드 시간 초과',
          StackTrace.current,
        );
        stopAllAnimations();
      },
      onLoadFailed: handleLoadFailedForFlow,
      onShowStarted: () {
        logger.i('[$id] 광고가 전체 화면으로 표시됨');
        stopAllAnimations();
      },
      onShowTimeout: () {
        logger.e(
          '[$id] 광고 표시 타임아웃 (${flow.showTimeout.inSeconds}s) — '
          'FullScreenContentCallback 미수신',
        );
        logAdShowFailure(
          'AdMob',
          TimeoutException('admob show timeout', flow.showTimeout),
          _adUnitId,
          'AdMob show callback timeout', // no-fill 키워드에 안 걸리는 문구 → Sentry 보고됨
          StackTrace.current,
        );
        stopAllAnimations();
        if (context.mounted && !isDisposed) {
          showErrorDialog(AppLocalizations.of(context).label_ads_show_fail);
        }
      },
      onShowFailed: (error) {
        logAdShowFailure('AdMob', error, _adUnitId, error.toString(), null);
        stopAllAnimations();
        if (context.mounted && !isDisposed) {
          showErrorDialog(AppLocalizations.of(context).label_ads_show_fail);
        }
      },
      onDismissed: () {
        // 스피너는 onShowStarted 에서 이미 풀었다 — 다시 풀면 그 사이 다른
        // 구좌가 켠 전역 로딩 오버레이를 닫는다.
        logger.i('[$id] 광고가 닫힘');
        request.refreshUserProfileOnce();
      },
    );
  }

  /// `onLoadFailed` 배선 로직.
  ///
  /// MAJOR-3: `logAdLoadFailure` 의 message 인자는 반드시 **실제 에러
  /// 텍스트**([error.toString()])여야 한다 — 하드코딩 라벨을 넘기면
  /// isNonReportableAdError 의 '광고 로드 실패' 키워드에 걸려 모든 예외가
  /// "모든 광고 소진"으로 뭉개지고 Sentry 보고도 막힌다(PICNIC-2377).
  @visibleForTesting
  void handleLoadFailedForFlow(Object error) {
    if (error is LoadAdError) {
      logger.e(
        '[$id] AdMob 광고 로드 실패 상세:\n'
        '  code: ${error.code}\n'
        '  message: ${error.message}\n'
        '  domain: ${error.domain}\n'
        '  responseInfo: ${error.responseInfo}\n'
        '  adUnitId: $_adUnitId',
      );
    }
    logAdLoadFailure(
      'AdMob',
      error,
      _adUnitId,
      error.toString(),
      StackTrace.current,
    );
    stopAllAnimations();
  }

  void _startLoad(
    void Function(RewardedAd ad) onLoaded,
    void Function(Object error) onFailedToLoad,
  ) {
    unawaited(
      loadRewardedAd(
        adUnitId: _adUnitId,
        callback: RewardedAdLoadCallback(
          onAdLoaded: onLoaded,
          onAdFailedToLoad: onFailedToLoad,
        ),
      ).catchError((Object e) => onFailedToLoad(e)),
    );
  }

  /// 로드된 광고 한 건의 준비(claim 발급·영속화 → SSV 설정)와 표시.
  ///
  /// 순서는 현재 main 의 AdMob claim/SSV 계약을 따른다. claim 은 로드 성공
  /// 뒤에만 발급하고, 영속화가 끝나야 표시하며, 서명 토큰만 customData 로
  /// 보낸다. 매 await 뒤에 attempt 가 살아 있는지와 요청 owner 가 여전히 현재
  /// 사용자인지 확인해, 타임아웃·dispose·새 attempt·계정 전환·로그아웃 뒤의
  /// claim/SSV 완료가 오래된 광고를 띄우지 못하게 한다.
  Future<void> _attachCallbacksAndShow(
    RewardedAd ad, {
    required _AdmobRequest request,
    required void Function() onShowed,
    required void Function() onDismissed,
    required void Function(Object error) onFailedToShow,
    required AdmobShowAttempt attempt,
  }) async {
    final adSource = AdmobAdSourceSummary.fromResponseInfo(ad.responseInfo);
    logger.i('[$id] 광고 로드 완료 ${adSource.describe()}');
    _breadcrumb('loaded', adSource.toBreadcrumbData());
    // 이 요청의 고정 값만 쓴다 — 인스턴스 필드는 다른 요청이 덮어쓸 수 있다.
    final owner = request.owner;
    final logGa4Impression = request.logGa4Impression;
    final refreshUserProfileOnce = request.refreshUserProfileOnce;

    if (!_canStillShow(attempt) || !_ownerStillCurrent(owner, attempt)) return;
    final userId = owner!;

    final platform = Platform.isIOS ? 'ios' : 'android';
    final AdmobRewardWiring wiring;
    final AdmobClaimPreflightResult preflight;
    try {
      wiring = createRewardWiring();
      preflight = await wiring.preflight.execute(
        ownerUserId: userId,
        platform: platform,
        placementId: _adUnitId,
        clientRequestId: const Uuid().v4(),
      );
    } catch (e, s) {
      if (!attempt.abandon()) {
        // 이미 타임아웃·dispose·새 attempt 로 끝났다 — 안내는 그쪽이 했다.
        logger.w('[$id] 종료된 attempt 의 AdMob claim 실패 — UI 생략', error: e);
        return;
      }
      stopAllAnimations();
      final restriction = mapToAntiAbuseException(e);
      if (restriction is AntiAbuseException) {
        if (context.mounted && !isDisposed) {
          await showRateLimited(restriction);
        }
        return;
      }
      logger.e(
        '[$id] AdMob SSV claim 발급 실패 - 광고를 표시하지 않음',
        error: e,
        stackTrace: s,
      );
      if (context.mounted && !isDisposed) {
        showErrorDialog(AppLocalizations.of(context).label_ads_load_fail);
      }
      return;
    }
    final reference = preflight.reference;
    _breadcrumb('claim_issued', {'claim_id': reference.id});
    if (!_canStillShow(attempt) || !_ownerStillCurrent(owner, attempt)) return;

    logger.i(
      '[$id] AdMob SSV claim 설정: platform=$platform, adUnit=$_adUnitId, '
      'claim=${reference.id}',
    );
    // 실패는 flow 의 표시 실패 단일 경로로 합류한다(실제 오류 텍스트로 보고).
    await ad.setServerSideOptions(
      ServerSideVerificationOptions(
        userId: userId,
        customData: preflight.signedToken,
      ),
    );
    if (!_canStillShow(attempt) || !_ownerStillCurrent(owner, attempt)) return;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) {
        _breadcrumb('showed');
        onShowed();
      },
      onAdDismissedFullScreenContent: (_) {
        _breadcrumb('dismissed');
        onDismissed();
      },
      onAdFailedToShowFullScreenContent: (_, error) {
        logger.e(
          '[$id] AdMob 광고 표시 실패 상세:\n'
          '  code: ${error.code}\n'
          '  message: ${error.message}\n'
          '  domain: ${error.domain}',
        );
        _breadcrumb('show_failed', {
          'code': error.code,
          'domain': error.domain,
          'message': error.message,
        });
        onFailedToShow(error);
      },
      onAdImpression: (_) {
        logger.i('[$id] 광고 노출 기록됨');
        logGa4Impression(); // Task B-4
      },
    );
    final poll = wiring.poll;
    // 이제 광고가 떠 있을 수 있다. onShowed 가 유실돼도 새 요청·화면 dispose 가
    // 이 광고를 폐기하지 않게 flow 의 정리 대상에서 뺀다(SDK 보상 라우팅 보존).
    attempt.showSubmitted();
    await ad.show(
      onUserEarnedReward: (AdWithoutView _, RewardItem reward) {
        // 세대·owner 가드 밖이다 — 이미 시청한 보상은 요청 owner 와 이 claim
        // 으로 확인한다(그 사이 화면이 사라졌거나 계정이 바뀌었어도).
        logger.i(
          '[$id] 보상 콜백 수신: ${reward.amount} ${reward.type}, '
          'userId=$userId, claim=${reference.id} '
          '${adSource.describe()}',
        );
        _breadcrumb('earned', {
          'claim_id': reference.id,
          'amount': reward.amount,
          'type': reward.type,
          ...adSource.toBreadcrumbData(),
        });
        refreshUserProfileOnce();
        // SDK 의 보상 콜백은 "시청 완료" 일 뿐 지급이 아니다. 지급은 Google 의
        // SSV 콜백이 서버에 닿아야 확정되므로 여기서부터 상태 사다리를 돈다.
        unawaited(
          Future.sync(
            () => poll(ownerUserId: userId, reference: reference),
          ).catchError((Object error, StackTrace stackTrace) {
            logger.e(
              '[$id] AdMob reward polling failed: claim=${reference.id}',
              error: error,
              stackTrace: stackTrace,
            );
          }),
        );
      },
    );
  }

  /// 이 attempt 가 아직 광고를 띄워도 되는지 확인한다. 안 되면 광고를
  /// 정리하고, 이 호출이 attempt 를 끝냈을 때만 스피너를 푼다.
  bool _canStillShow(AdmobShowAttempt attempt) {
    if (attempt.isActive && context.mounted && !isDisposed) return true;
    logger.i('[$id] 종료된 attempt — 광고를 표시하지 않음');
    if (attempt.abandon()) stopAllAnimations();
    return false;
  }

  /// 요청 owner 가 여전히 현재 사용자인지 확인한다. 다르면 광고를 정리하고
  /// 안내한다(로그아웃이면 로그인 안내, 계정 전환이면 로드 실패 안내).
  bool _ownerStillCurrent(String? owner, AdmobShowAttempt attempt) {
    final current = currentUserId();
    if (owner != null && owner.isNotEmpty && current == owner) return true;
    if (attempt.abandon()) {
      stopAllAnimations();
      _notifyOwnerChanged(current);
    }
    return false;
  }

  void _notifyOwnerChanged(String? current) {
    if (current == null || current.isEmpty) {
      logger.e('[$id] 광고 요청 중 로그아웃 — 광고를 표시하지 않음');
      showLoginRequired();
      return;
    }
    logger.w('[$id] 광고 요청 중 계정 전환 — 이전 요청의 광고를 표시하지 않음');
    if (context.mounted && !isDisposed) {
      showErrorDialog(AppLocalizations.of(context).label_ads_load_fail);
    }
  }

  /// 광고 한 건의 생애주기를 Sentry breadcrumb 으로 남긴다.
  void _breadcrumb(String step, [Map<String, dynamic>? data]) {
    unawaited(
      Sentry.addBreadcrumb(
        Breadcrumb(
          category: 'ad.admob',
          message: step,
          level: SentryLevel.info,
          data: {'slot': id, 'ad_unit': _adUnitId, ...?data},
        ),
      ),
    );
  }

  /// 현재 [ga4AdContext] 스냅샷을 캡처해 반환한다(MAJOR-2).
  @visibleForTesting
  void Function() captureGa4ImpressionLogger() {
    final ga4Snapshot = ga4AdContext;
    return () => logGa4Impression(ga4Snapshot);
  }

  @visibleForTesting
  void logGa4Impression(FreeChargeAdGa4Context? ga4) {
    if (ga4 == null) return; // 구좌 컨텍스트 없이 임의값으로 보내지 않는다.
    unawaited(
      PicnicAnalytics.instance.logAdImpression(
        adPlatform: ga4.adPlatform,
        adSource: ga4.adSource,
        adFormat: ga4.adFormat,
        adUnitName: ga4.adUnitName,
        sectionName: ga4.sectionName,
        adCategory: ga4.adCategory,
        virtualCurrencyName: ga4.virtualCurrencyName,
        rewardAmount: ga4.rewardAmount,
      ),
    );
  }

  @override
  Future<void> handleError(error, StackTrace? stackTrace) async {
    logger.e('[$id] 광고 오류 발생', error: error, stackTrace: stackTrace);
    setLoading(false);
    stopAllAnimations();
    if (context.mounted && !isDisposed) {
      showSimpleDialog(
        content: AppLocalizations.of(context).label_ads_load_fail,
        type: DialogType.error,
      );
    }
  }

  @override
  void dispose() {
    _flow?.dispose();
    _flow = null;
    super.dispose();
  }
}

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:picnic_lib/core/errors/anti_abuse_exception.dart';
import 'package:picnic_lib/core/utils/common_utils.dart';
import 'package:picnic_lib/core/utils/startup_readiness.dart';
import 'package:picnic_lib/data/models/ad/ad_reward_status.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/ad_platform.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/free_charge_analytics.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/platforms/admob_platform.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yet_another_json_isolate/yet_another_json_isolate.dart';

import '../../../../../../helpers/ignore_image_errors.dart';
import '../../../../../../helpers/test_app.dart';

/// `AdmobPlatform.showAd()` 의 **실제 프로덕션 배선**을 돈다.
///
/// 예전 PR 테스트는 추출한 헬퍼만 검증해서, showAd 가 워치독·claim·SSV·표시를
/// 실제로 어떻게 엮는지는 아무도 지키지 않았다. 여기서는 SDK·Supabase·전역
/// 다이얼로그 경계만 `@visibleForTesting` seam 으로 바꾸고, 그 사이의
/// `AdmobShowFlow` · `AdmobClaimPreflight` · `_attachCallbacksAndShow` 는 프로덕션
/// 코드 그대로 돌린다. `RewardedAd` 는 SDK 채널 대신 [_FakeRewardedAd] 가
/// 콜백을 손으로 발화한다.
class _FakeRewardedAd extends Fake implements RewardedAd {
  _FakeRewardedAd(this.name, this.log);

  final String name;
  final List<String> log;

  @override
  ResponseInfo? responseInfo;

  @override
  FullScreenContentCallback<RewardedAd>? fullScreenContentCallback;

  ServerSideVerificationOptions? ssv;
  Completer<void>? ssvGate;
  void Function(AdWithoutView ad, RewardItem reward)? _earned;
  int showCalls = 0;
  int disposeCalls = 0;

  @override
  Future<void> setServerSideOptions(
    ServerSideVerificationOptions options,
  ) async {
    log.add('ssv:$name');
    ssv = options;
    final gate = ssvGate;
    if (gate != null) await gate.future;
    final error = ssvError;
    if (error != null) throw error;
  }

  Object? ssvError;

  @override
  Future<void> show({
    required void Function(AdWithoutView ad, RewardItem reward)
    onUserEarnedReward,
  }) async {
    log.add('show:$name');
    showCalls++;
    _earned = onUserEarnedReward;
  }

  /// SDK 의 `AdInstanceManager.disposeAd` 처럼 dispose 는 광고의 이벤트
  /// 라우팅(`_loadedAds` 매핑)을 지운다. 그 뒤 네이티브가 보내는 이벤트
  /// (표시·닫힘·노출·보상)는 `adFor(adId) == null` 이라 버려진다
  /// (ad_instance_manager.dart:65~69, :663~665). 횟수만 세는 fake 로는 "dispose
  /// 된 광고의 earned 가 버려진다"는 실제 결과를 볼 수 없다.
  bool get isRoutingRemoved => disposeCalls > 0;

  /// dispose 뒤에 도착해 SDK 가 버린 이벤트 이름.
  final List<String> droppedEvents = [];

  @override
  Future<void> dispose() async {
    disposeCalls++;
  }

  bool _route(String event) {
    if (!isRoutingRemoved) return true;
    droppedEvents.add(event);
    return false;
  }

  void sdkShowed() {
    if (_route('showed')) {
      fullScreenContentCallback!.onAdShowedFullScreenContent!(this);
    }
  }

  void sdkDismissed() {
    if (_route('dismissed')) {
      fullScreenContentCallback!.onAdDismissedFullScreenContent!(this);
    }
  }

  void sdkFailedToShow(AdError error) {
    if (_route('failed_to_show')) {
      fullScreenContentCallback!.onAdFailedToShowFullScreenContent!(
        this,
        error,
      );
    }
  }

  void sdkImpression() {
    if (_route('impression')) {
      fullScreenContentCallback!.onAdImpression!(this);
    }
  }

  void sdkEarn() {
    if (_route('earned')) _earned!(this, RewardItem(1, 'star_candy'));
  }
}

/// 호출한 isolate 안에서 JSON 을 encode/decode 하는 [YAJsonIsolate].
class _SyncJsonIsolate extends YAJsonIsolate {
  @override
  Future<void> initialize() async {}

  @override
  Future<void> dispose() async {}

  @override
  Future<String> encode(Object? json) async => jsonEncode(json);

  @override
  Future<dynamic> decode(String json) async => jsonDecode(json);
}

/// `check-ads-count` 서버. 실제 [SupabaseClient]·FunctionsClient 배선을 타고,
/// http 전송 계층만 요청마다 테스트가 끝내는 [Completer] 로 대신한다
/// (ad_platform_debug_admob_bypass_test.dart 의 MockClient 패턴). 응답 순서를
/// 요청 순서와 다르게 줄 수 있다.
class _PolicyServer {
  final List<http.Request> requests = [];
  final List<Completer<http.Response>> _pending = [];

  late final SupabaseClient client = SupabaseClient(
    'http://localhost:54321',
    'test-anon-key',
    httpClient: MockClient((request) {
      requests.add(request);
      final response = Completer<http.Response>();
      _pending.add(response);
      return response.future;
    }),
    // FunctionsClient 는 JSON 응답을 isolate 왕복으로 decode 한다. 위젯
    // 테스트의 가짜 시계에서는 그 왕복이 진행하지 않아 응답이 영영 도착하지
    // 않는다(jma_voting_dialog_dismiss_guard_test.dart 의 _SyncJsonIsolate 와
    // 같은 이유). JSON 실행 위치만 바꾸고, 요청·응답 내용은 그대로다.
    isolate: _SyncJsonIsolate(),
    authOptions: const AuthClientOptions(autoRefreshToken: false),
  );

  int get pendingCount => _pending.length;

  void respond(int index, Map<String, dynamic> body, {int status = 200}) {
    _pending[index].complete(
      http.Response(
        jsonEncode(body),
        status,
        headers: {'content-type': 'application/json'},
      ),
    );
  }
}

class _Failure {
  _Failure(this.error, this.message);
  final Object error;
  final String message;
}

class _RecordingCommonUtils extends CommonUtils {
  _RecordingCommonUtils(super.ref, super.context, this._onRefresh);

  final void Function() _onRefresh;

  @override
  void refreshUserProfile() => _onRefresh();
}

typedef _ClaimFn =
    Future<AdmobClaimModel> Function({
      required String platform,
      required String placementId,
      required String clientRequestId,
    });

class _TestAdmobPlatform extends AdmobPlatform {
  _TestAdmobPlatform(
    super.ref,
    super.context,
    super.id,
    super.animationController,
  );

  final List<String> log = [];
  String? userId = 'user-a';
  Object? readinessError;
  final List<RewardedAdLoadCallback> loads = [];
  final List<String> persisted = [];
  final List<String> polls = [];
  final List<String> dialogs = [];
  final List<String?> rateLimited = [];
  final List<_Failure> loadFailures = [];
  final List<_Failure> showFailures = [];
  final List<FreeChargeAdGa4Context?> impressions = [];
  int spinnerStops = 0;
  int loginRequired = 0;
  int profileRefreshes = 0;
  int claimCalls = 0;

  late _ClaimFn createClaim = _issueClaim;
  Future<void> Function(String owner, AdRewardReference reference) persist =
      (_, _) async {};

  Future<AdmobClaimModel> _issueClaim({
    required String platform,
    required String placementId,
    required String clientRequestId,
  }) async => claimFor('claim-$claimCalls');

  static AdmobClaimModel claimFor(String claimId) => AdmobClaimModel(
    reference: AdRewardReference(
      type: AdRewardReferenceType.admobClaim,
      id: claimId,
    ),
    platform: 'android',
    signedToken: 'signed-$claimId',
    expiresAt: DateTime.utc(2030),
  );

  late final CommonUtils _commonUtils = _RecordingCommonUtils(
    ref,
    context,
    () => profileRefreshes++,
  );

  @override
  CommonUtils get commonUtils => _commonUtils;

  @override
  Future<bool> checkLogin() async => true;

  /// 다음 N 번의 광고 정책 확인(check-ads-count 왕복)을 테스트가 끝낼 때까지
  /// 붙잡는다. safelyExecute 의 첫 await 경계를 재현한다.
  int policyHolds = 0;
  final List<Completer<bool>> policyWaits = [];

  /// true 이면 정책 확인을 가짜로 대신하지 않고 실제 [AdPlatform.checkAdsLimit]
  /// (check-ads-count 요청·응답 판정·안내 다이얼로그)를 그대로 탄다. I/O 는
  /// 테스트가 [testSupabaseClient] 의 http 계층에서만 대신한다.
  bool useRealPolicy = false;

  @override
  Future<bool> checkAdsLimit(
    String platform, {
    bool Function()? isRequestActive,
  }) async {
    if (useRealPolicy) {
      return super.checkAdsLimit(platform, isRequestActive: isRequestActive);
    }
    if (policyHolds > 0) {
      policyHolds--;
      final wait = Completer<bool>();
      policyWaits.add(wait);
      return wait.future;
    }
    return true;
  }

  @override
  void startLoading() {}

  @override
  void stopLoading() => spinnerStops++;

  /// 동의·SDK 준비를 기다리는 동안 일어나는 일(계정 전환·로그아웃)을 흉내 낸다.
  void Function()? whileWaitingForReadiness;

  /// true 이면 각 준비 대기를 요청별 [Completer] 로 붙잡는다. 테스트가 요청마다
  /// 따로, 역순으로 성공·실패·타임아웃시킬 수 있다.
  bool holdReadiness = false;
  final List<Completer<void>> readinessWaits = [];

  @override
  String? currentUserId() => userId;

  @override
  Future<void> runWhenAdsReady({
    required bool Function() isRequestActive,
    required Future<void> Function() request,
  }) async {
    // 실제 AdRequestReadinessGate 와 같은 순서: 대기 → 대기 뒤 활성 재확인 → 요청.
    // 대기 실패(동의 거부·타임아웃 등)는 실제 게이트처럼 이 Future 로 던진다.
    if (holdReadiness) {
      final wait = Completer<void>();
      readinessWaits.add(wait);
      await wait.future;
    }
    whileWaitingForReadiness?.call();
    final error = readinessError;
    if (error != null) throw error;
    if (!isRequestActive()) {
      throw const AdsUnavailable('Ad request is no longer active');
    }
    await request();
  }

  @override
  Future<void> loadRewardedAd({
    required String adUnitId,
    required RewardedAdLoadCallback callback,
  }) async {
    log.add('load');
    loads.add(callback);
  }

  @override
  AdmobRewardWiring createRewardWiring() {
    return AdmobRewardWiring(
      preflight: AdmobClaimPreflight(
        createClaim:
            ({
              required platform,
              required placementId,
              required clientRequestId,
            }) {
              claimCalls++;
              log.add('claim');
              return createClaim(
                platform: platform,
                placementId: placementId,
                clientRequestId: clientRequestId,
              );
            },
        persist: (owner, reference) async {
          await persist(owner, reference);
          log.add('persist:${reference.id}');
          persisted.add('$owner:${reference.id}');
        },
      ),
      poll: ({required ownerUserId, required reference}) async {
        polls.add('$ownerUserId:${reference.id}');
      },
    );
  }

  @override
  void showErrorDialog(String content) => dialogs.add(content);

  @override
  Future<void> showRateLimited(AntiAbuseException restriction) async {
    rateLimited.add(restriction.rawCode);
  }

  @override
  void showLoginRequired() => loginRequired++;

  @override
  void logAdLoadFailure(
    String platform,
    dynamic error,
    String adId,
    String message,
    StackTrace? stackTrace,
  ) {
    loadFailures.add(_Failure(error as Object, message));
  }

  @override
  void logAdShowFailure(
    String platform,
    dynamic error,
    String adId,
    String message,
    StackTrace? stackTrace,
  ) {
    showFailures.add(_Failure(error as Object, message));
  }

  @override
  void logGa4Impression(FreeChargeAdGa4Context? ga4) => impressions.add(ga4);
}

class _AnimationHost extends StatefulWidget {
  const _AnimationHost({required this.builder});

  final Widget Function(AnimationController controller) builder;

  @override
  State<_AnimationHost> createState() => _AnimationHostState();
}

class _AnimationHostState extends State<_AnimationHost>
    with TickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(_controller);
}

const _ga4A = FreeChargeAdGa4Context(
  adPlatform: 'AdMob',
  adSource: 'AdMob',
  adUnitName: 'unit',
  adCategory: 'global_pick_1',
  virtualCurrencyName: 'star_candy',
  rewardAmount: 1,
);

const _ga4B = FreeChargeAdGa4Context(
  adPlatform: 'AdMob',
  adSource: 'AdMob',
  adUnitName: 'unit',
  adCategory: 'global_pick_2',
  virtualCurrencyName: 'star_candy',
  rewardAmount: 1,
);

void main() {
  late RestoreCallback restore;

  setUp(() {
    restore = suppressImageErrors();
    initTestEnvironment();
  });

  tearDown(() => restore());

  late BuildContext hostContext;

  Future<_TestAdmobPlatform> buildPlatform(WidgetTester tester) async {
    late WidgetRef capturedRef;
    late AnimationController capturedController;
    await pumpWidgetAndIgnoreErrors(
      tester,
      buildTestApp(
        _AnimationHost(
          builder: (controller) => Consumer(
            builder: (context, ref, _) {
              capturedRef = ref;
              hostContext = context;
              capturedController = controller;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    await pumpAndIgnoreErrors(tester);
    return _TestAdmobPlatform(
      capturedRef,
      hostContext,
      'admob',
      capturedController,
    );
  }

  AppLocalizations l10n() => AppLocalizations.of(hostContext);

  /// showAd → 로드 완료까지 진행하고 로드된 광고를 돌려준다.
  Future<_FakeRewardedAd> startAndLoad(
    WidgetTester tester,
    _TestAdmobPlatform platform, {
    String name = 'ad-1',
  }) async {
    await platform.showAd();
    final ad = _FakeRewardedAd(name, platform.log);
    platform.loads.last.onAdLoaded(ad);
    await tester.pump();
    return ad;
  }

  testWidgets('정상 경로: claim 영속화 → 서명 토큰 SSV → 표시 순서이고 스피너는 한 번만 풀린다', (
    tester,
  ) async {
    final platform = await buildPlatform(tester);
    platform.ga4AdContext = _ga4A;

    final ad = await startAndLoad(tester, platform);

    expect(platform.log, [
      'load',
      'claim',
      'persist:claim-1',
      'ssv:ad-1',
      'show:ad-1',
    ]);
    expect(platform.persisted, ['user-a:claim-1']);
    expect(ad.ssv!.userId, 'user-a');
    // 서명 토큰만 보낸다 — 예전의 무서명 `platform=` customData 는 서버
    // claim 가드가 거부한다.
    expect(ad.ssv!.customData, 'signed-claim-1');
    expect(ad.ssv!.customData, isNot(contains('platform=')));
    expect(platform.spinnerStops, 0);

    // 다른 구좌 클릭이 컨텍스트를 덮어써도 노출은 이번 구좌로 귀속된다.
    platform.ga4AdContext = _ga4B;
    ad.sdkShowed();
    ad.sdkImpression();
    expect(platform.spinnerStops, 1);
    expect(platform.impressions, [same(_ga4A)]);

    ad.sdkEarn();
    await tester.pump();
    expect(platform.polls, ['user-a:claim-1']);
    expect(platform.profileRefreshes, 1);

    ad.sdkDismissed();
    expect(ad.disposeCalls, 1);
    expect(platform.profileRefreshes, 1); // earned 와 dismissed 는 attempt 당 1회
    expect(platform.spinnerStops, 1); // dismissed 는 스피너를 다시 풀지 않는다

    await tester.pump(const Duration(minutes: 1));
    expect(platform.dialogs, isEmpty);
    expect(platform.showFailures, isEmpty);
    platform.dispose();
  });

  testWidgets('로드 콜백이 전혀 없으면 15초 뒤 로드 타임아웃 1회, 늦은 광고는 폐기된다', (tester) async {
    final platform = await buildPlatform(tester);
    await platform.showAd();
    expect(platform.loads, hasLength(1));

    await tester.pump(const Duration(seconds: 14));
    expect(platform.loadFailures, isEmpty);
    await tester.pump(const Duration(seconds: 1));
    expect(platform.loadFailures, hasLength(1));
    final failure = platform.loadFailures.single;
    expect(failure.error, isA<TimeoutException>());
    expect(failure.message, '광고 로드 시간 초과');
    expect(
      AdPlatform.isNonReportableAdError(
        'AdMob',
        failure.error,
        failure.message,
      ),
      isTrue,
    );
    expect(platform.spinnerStops, 1);

    final late = _FakeRewardedAd('late', platform.log);
    platform.loads.single.onAdLoaded(late);
    await tester.pump(const Duration(minutes: 1));
    expect(late.disposeCalls, 1);
    expect(platform.claimCalls, 0);
    expect(late.showCalls, 0);
    expect(platform.loadFailures, hasLength(1));
    expect(platform.spinnerStops, 1);
    platform.dispose();
  });

  testWidgets('로드 실패 콜백은 실제 오류 텍스트로 1회 보고되고 워치독은 뒤따르지 않는다', (tester) async {
    final platform = await buildPlatform(tester);
    await platform.showAd();
    final error = LoadAdError(3, 'domain', 'No fill', null);
    platform.loads.single.onAdFailedToLoad(error);
    await tester.pump(const Duration(seconds: 30));

    expect(platform.loadFailures, hasLength(1));
    expect(platform.loadFailures.single.error, same(error));
    expect(platform.loadFailures.single.message, error.toString());
    expect(platform.spinnerStops, 1);
    platform.dispose();
  });

  testWidgets('표시 콜백이 없으면 10초 뒤 표시 타임아웃 1회 — 떠 있을 수 있는 광고는 폐기하지 않는다', (
    tester,
  ) async {
    final platform = await buildPlatform(tester);
    final ad = await startAndLoad(tester, platform);
    expect(ad.showCalls, 1);

    await tester.pump(const Duration(seconds: 10));
    expect(platform.showFailures, hasLength(1));
    final failure = platform.showFailures.single;
    expect(failure.error, isA<TimeoutException>());
    expect(
      AdPlatform.isNonReportableAdError(
        'AdMob',
        failure.error,
        failure.message,
      ),
      isFalse,
      reason: '표시 콜백 유실은 Sentry 로 보고돼야 한다',
    );
    expect(platform.dialogs, [l10n().label_ads_show_fail]);
    expect(platform.spinnerStops, 1);
    expect(ad.disposeCalls, 0);

    await tester.pump(const Duration(minutes: 1));
    expect(platform.showFailures, hasLength(1));

    // 예전 기대값(화면 dispose → disposeCalls 1)은 틀렸다. ad.show() 를 이미
    // 요청했으므로 onShowed 가 유실됐을 뿐 광고가 떠 있을 수 있다. 여기서
    // dispose 하면 SDK 가 이벤트 라우팅을 지워 earned 가 버려지고 적립 확인
    // 폴링이 시작되지 않는다. 표시 요청된 광고는 자기 dismissed 가 정리한다.
    platform.dispose();
    expect(ad.disposeCalls, 0);
    ad.sdkEarn();
    await tester.pump();
    expect(platform.polls, ['user-a:claim-1']);
    ad.sdkDismissed();
    expect(ad.disposeCalls, 1);
    expect(ad.droppedEvents, isEmpty);
  });

  group('R1: 표시 요청 뒤 onShowed 가 유실된 광고', () {
    testWidgets('표시 타임아웃 뒤 새 요청이 와도 earned 가 원 owner·claim 으로 폴링되고 '
        'dismissed 가 한 번 정리한다', (tester) async {
      final platform = await buildPlatform(tester);
      final adA = await startAndLoad(tester, platform, name: 'A');
      expect(adA.showCalls, 1); // show 요청 제출 — onShowed 는 오지 않는다
      await tester.pump(const Duration(seconds: 10));
      expect(platform.dialogs, [l10n().label_ads_show_fail]);

      final adB = await startAndLoad(tester, platform, name: 'B');
      expect(adA.disposeCalls, 0, reason: '떠 있을 수 있는 A 를 새 요청이 폐기하면 안 된다');

      adA.sdkEarn();
      await tester.pump();
      expect(platform.polls, ['user-a:claim-1']);
      adA.sdkDismissed();
      expect(adA.disposeCalls, 1);
      expect(adA.droppedEvents, isEmpty);

      // B 는 A 의 늦은 이벤트에 영향받지 않는다.
      expect(adB.disposeCalls, 0);
      expect(adB.showCalls, 1);
      expect(platform.dialogs, hasLength(1));
      adB.sdkShowed();
      adB.sdkDismissed();
      expect(adB.disposeCalls, 1);
      platform.dispose();
    });

    testWidgets('표시 타임아웃 뒤 화면이 dispose 돼도 earned 가 폴링되고 dismissed 가 정리한다', (
      tester,
    ) async {
      final platform = await buildPlatform(tester);
      final ad = await startAndLoad(tester, platform);
      await tester.pump(const Duration(seconds: 10));

      platform.dispose();
      expect(ad.disposeCalls, 0);

      ad.sdkEarn();
      await tester.pump();
      expect(platform.polls, ['user-a:claim-1']);
      ad.sdkDismissed();
      expect(ad.disposeCalls, 1);
      expect(ad.droppedEvents, isEmpty);
    });

    testWidgets('아직 show 를 요청하지 않은 준비 중 광고는 새 요청이 한 번 정리한다', (tester) async {
      final platform = await buildPlatform(tester);
      final claim = Completer<AdmobClaimModel>();
      platform.createClaim =
          ({
            required platform,
            required placementId,
            required clientRequestId,
          }) => claim.future;
      final adA = await startAndLoad(tester, platform, name: 'A');
      expect(adA.showCalls, 0);

      platform.createClaim =
          ({
            required platform,
            required placementId,
            required clientRequestId,
          }) async => _TestAdmobPlatform.claimFor('claim-b');
      await platform.showAd();
      expect(adA.disposeCalls, 1);

      claim.complete(_TestAdmobPlatform.claimFor('claim-a'));
      await tester.pump();
      expect(adA.showCalls, 0);
      expect(adA.disposeCalls, 1);
      platform.dispose();
    });
  });

  testWidgets('표시 실패 콜백은 실제 오류 텍스트로 1회 보고되고 광고를 정리한다', (tester) async {
    final platform = await buildPlatform(tester);
    final ad = await startAndLoad(tester, platform);
    final error = AdError(1, 'domain', 'Ad not ready');
    ad.sdkFailedToShow(error);
    await tester.pump(const Duration(seconds: 30));

    expect(platform.showFailures, hasLength(1));
    expect(platform.showFailures.single.message, error.toString());
    expect(platform.dialogs, [l10n().label_ads_show_fail]);
    expect(ad.disposeCalls, 1);
    expect(platform.spinnerStops, 1);
    platform.dispose();
    expect(ad.disposeCalls, 1);
  });

  testWidgets('정책 거절된 claim 은 영속화·표시 없이 제한 안내 1회로 끝난다', (tester) async {
    final platform = await buildPlatform(tester);
    platform.createClaim =
        ({
          required platform,
          required placementId,
          required clientRequestId,
        }) async => throw const FunctionException(
          status: 429,
          details: {
            'error': {'code': 'AD_DEVICE_ACCOUNT_LIMIT'},
          },
        );

    final ad = await startAndLoad(tester, platform);
    await tester.pump(const Duration(seconds: 30));

    expect(platform.rateLimited, ['AD_DEVICE_ACCOUNT_LIMIT']);
    expect(platform.persisted, isEmpty);
    expect(ad.ssv, isNull);
    expect(ad.showCalls, 0);
    expect(ad.disposeCalls, 1);
    expect(platform.dialogs, isEmpty);
    expect(platform.showFailures, isEmpty); // 표시 타임아웃이 뒤따르지 않는다
    expect(platform.spinnerStops, 1);
    platform.dispose();
  });

  testWidgets('claim 영속화 실패는 광고를 표시하지 않고 로드 실패 안내 1회로 끝난다', (tester) async {
    final platform = await buildPlatform(tester);
    platform.persist = (_, _) =>
        Future<void>.error(StateError('storage unavailable'));

    final ad = await startAndLoad(tester, platform);
    await tester.pump(const Duration(seconds: 30));

    expect(platform.persisted, isEmpty);
    expect(ad.ssv, isNull);
    expect(ad.showCalls, 0);
    expect(ad.disposeCalls, 1);
    expect(platform.dialogs, [l10n().label_ads_load_fail]);
    expect(platform.showFailures, isEmpty);
    expect(platform.spinnerStops, 1);
    platform.dispose();
  });

  testWidgets('표시 타임아웃 뒤에 끝난 claim 은 오래된 광고를 띄우지 않는다', (tester) async {
    final platform = await buildPlatform(tester);
    final claim = Completer<AdmobClaimModel>();
    platform.createClaim =
        ({required platform, required placementId, required clientRequestId}) =>
            claim.future;

    final ad = await startAndLoad(tester, platform);
    await tester.pump(const Duration(seconds: 10));
    expect(platform.dialogs, [l10n().label_ads_show_fail]);
    expect(platform.spinnerStops, 1);

    claim.complete(_TestAdmobPlatform.claimFor('late-claim'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 30));

    expect(ad.ssv, isNull);
    expect(ad.showCalls, 0);
    expect(ad.disposeCalls, 1);
    expect(platform.dialogs, hasLength(1));
    expect(platform.spinnerStops, 1);
    platform.dispose();
    expect(ad.disposeCalls, 1);
  });

  testWidgets('표시 타임아웃 뒤에 끝난 SSV 설정은 오래된 광고를 띄우지 않는다', (tester) async {
    final platform = await buildPlatform(tester);
    await platform.showAd();
    final ad = _FakeRewardedAd('ad-1', platform.log)
      ..ssvGate = Completer<void>();
    platform.loads.single.onAdLoaded(ad);
    await tester.pump();
    expect(ad.ssv, isNotNull);

    await tester.pump(const Duration(seconds: 10));
    expect(platform.dialogs, [l10n().label_ads_show_fail]);

    ad.ssvGate!.complete();
    await tester.pump();
    await tester.pump(const Duration(seconds: 30));

    expect(ad.showCalls, 0);
    expect(ad.disposeCalls, 1);
    expect(platform.dialogs, hasLength(1));
    expect(platform.spinnerStops, 1);
    platform.dispose();
  });

  testWidgets('화면 dispose 뒤에 끝난 claim 은 광고를 띄우지 않고 UI 도 건드리지 않는다', (
    tester,
  ) async {
    final platform = await buildPlatform(tester);
    final claim = Completer<AdmobClaimModel>();
    platform.createClaim =
        ({required platform, required placementId, required clientRequestId}) =>
            claim.future;

    final ad = await startAndLoad(tester, platform);
    platform.dispose();
    expect(ad.disposeCalls, 1);

    claim.complete(_TestAdmobPlatform.claimFor('late-claim'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 30));

    expect(ad.ssv, isNull);
    expect(ad.showCalls, 0);
    expect(ad.disposeCalls, 1);
    expect(platform.dialogs, isEmpty);
    expect(platform.showFailures, isEmpty);
  });

  testWidgets('시청 중 화면이 dispose 돼도 광고를 폐기하지 않아 적립 확인 폴링이 시작된다', (tester) async {
    final platform = await buildPlatform(tester);
    final ad = await startAndLoad(tester, platform);
    ad.sdkShowed();

    platform.dispose(); // 시청 중 페이지 teardown
    expect(ad.disposeCalls, 0);

    ad.sdkEarn();
    await tester.pump();
    expect(platform.polls, ['user-a:claim-1']);

    ad.sdkDismissed();
    expect(ad.disposeCalls, 1);
    expect(platform.spinnerStops, 1);
  });

  testWidgets('로드 중 세션이 만료되면 claim 없이 로그인 안내 1회로 끝난다', (tester) async {
    final platform = await buildPlatform(tester);
    await platform.showAd();
    platform.userId = null;
    final ad = _FakeRewardedAd('ad-1', platform.log);
    platform.loads.single.onAdLoaded(ad);
    await tester.pump(const Duration(seconds: 30));

    expect(platform.loginRequired, 1);
    expect(platform.claimCalls, 0);
    expect(ad.showCalls, 0);
    expect(ad.disposeCalls, 1);
    expect(platform.showFailures, isEmpty);
    expect(platform.spinnerStops, 1);
    platform.dispose();
  });

  testWidgets('광고 준비 불가(동의·SDK 초기화)는 로드 없이 안내 1회로 끝난다', (tester) async {
    final platform = await buildPlatform(tester);
    platform.readinessError = const AdsUnavailable(
      'UMP does not currently permit ad requests',
    );

    await platform.showAd();
    await tester.pump(const Duration(seconds: 30));

    expect(platform.loads, isEmpty);
    expect(platform.dialogs, [l10n().label_ads_load_fail]);
    expect(platform.loadFailures, isEmpty);
    expect(platform.spinnerStops, 1);
    platform.dispose();
  });

  testWidgets('새 attempt 로 대체된 이전 로드 완료는 claim 없이 폐기된다', (tester) async {
    final platform = await buildPlatform(tester);
    await platform.showAd(); // attempt A
    await platform.showAd(); // attempt B
    expect(platform.loads, hasLength(2));

    final adA = _FakeRewardedAd('A', platform.log);
    platform.loads.first.onAdLoaded(adA);
    await tester.pump();
    expect(adA.disposeCalls, 1);
    expect(platform.claimCalls, 0);

    final adB = _FakeRewardedAd('B', platform.log);
    platform.loads.last.onAdLoaded(adB);
    await tester.pump();
    expect(adB.showCalls, 1);
    expect(adA.showCalls, 0);
    adB.sdkShowed();
    adB.sdkDismissed();
    expect(adB.disposeCalls, 1);
    platform.dispose();
  });

  testWidgets('이전 광고의 늦은 dismissed 는 새 광고를 폐기하지 않는다', (tester) async {
    final platform = await buildPlatform(tester);
    final adA = await startAndLoad(tester, platform, name: 'A');
    adA.sdkShowed();

    final adB = await startAndLoad(tester, platform, name: 'B');
    expect(adA.disposeCalls, 0); // 시청 중이던 A 는 새 attempt 가 폐기하지 않는다
    expect(adB.showCalls, 1);

    adA.sdkDismissed();
    expect(adA.disposeCalls, 1);
    expect(adB.disposeCalls, 0);

    adB.sdkShowed();
    adB.sdkDismissed();
    expect(adB.disposeCalls, 1);
    expect(platform.spinnerStops, 2); // attempt 마다 정확히 한 번
    platform.dispose();
  });

  testWidgets('SSV 설정 실패는 실제 오류 텍스트로 표시 실패 1회이고 광고를 띄우지 않는다', (tester) async {
    final platform = await buildPlatform(tester);
    await platform.showAd();
    final error = StateError('SSV channel failure');
    final ad = _FakeRewardedAd('ad-1', platform.log)..ssvError = error;
    platform.loads.single.onAdLoaded(ad);
    await tester.pump();
    await tester.pump(const Duration(seconds: 30));

    expect(ad.showCalls, 0);
    expect(platform.showFailures, hasLength(1));
    expect(platform.showFailures.single.error, same(error));
    expect(
      platform.showFailures.single.message,
      'Bad state: SSV channel failure',
    );
    expect(platform.dialogs, [l10n().label_ads_show_fail]);
    expect(ad.disposeCalls, 1);
    expect(platform.spinnerStops, 1);
    platform.dispose();
  });

  // 계정 전환·로그아웃: 요청한 사용자(owner)의 광고·claim 이 다른 계정으로
  // 이어지거나, 로그아웃 뒤에 이전 계정 광고가 뜨면 안 된다.
  group('요청 owner 와 현재 사용자가 달라지면', () {
    testWidgets('준비 대기 중 계정 전환 — 새 계정으로 로드·claim 하지 않는다', (tester) async {
      final platform = await buildPlatform(tester);
      platform.whileWaitingForReadiness = () => platform.userId = 'user-b';

      await platform.showAd();
      await tester.pump(const Duration(seconds: 30));

      expect(platform.loads, isEmpty);
      expect(platform.claimCalls, 0);
      expect(platform.dialogs, [l10n().label_ads_load_fail]);
      expect(platform.loginRequired, 0);
      expect(platform.spinnerStops, 1);
      platform.dispose();
    });

    testWidgets('준비 대기 중 로그아웃 — 로드 없이 로그인 안내 1회', (tester) async {
      final platform = await buildPlatform(tester);
      platform.whileWaitingForReadiness = () => platform.userId = null;

      await platform.showAd();
      await tester.pump(const Duration(seconds: 30));

      expect(platform.loads, isEmpty);
      expect(platform.claimCalls, 0);
      expect(platform.loginRequired, 1);
      expect(platform.dialogs, isEmpty);
      expect(platform.spinnerStops, 1);
      platform.dispose();
    });

    testWidgets('로드 중 계정 전환 — 새 계정 claim 을 만들지 않고 광고를 정리한다', (tester) async {
      final platform = await buildPlatform(tester);
      await platform.showAd();
      platform.userId = 'user-b';
      final ad = _FakeRewardedAd('ad-1', platform.log);
      platform.loads.single.onAdLoaded(ad);
      await tester.pump(const Duration(seconds: 30));

      expect(platform.claimCalls, 0);
      expect(platform.persisted, isEmpty);
      expect(ad.showCalls, 0);
      expect(ad.disposeCalls, 1);
      expect(platform.dialogs, [l10n().label_ads_load_fail]);
      expect(platform.showFailures, isEmpty);
      expect(platform.spinnerStops, 1);
      platform.dispose();
    });

    testWidgets('claim 대기 중 계정 전환 — 이전 계정 광고를 띄우지 않는다', (tester) async {
      final platform = await buildPlatform(tester);
      final claim = Completer<AdmobClaimModel>();
      platform.createClaim =
          ({
            required platform,
            required placementId,
            required clientRequestId,
          }) => claim.future;
      final ad = await startAndLoad(tester, platform);

      platform.userId = 'user-b';
      claim.complete(_TestAdmobPlatform.claimFor('claim-a'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 30));

      expect(platform.persisted, ['user-a:claim-a']); // claim 은 요청 owner 소유
      expect(ad.ssv, isNull);
      expect(ad.showCalls, 0);
      expect(ad.disposeCalls, 1);
      expect(platform.dialogs, [l10n().label_ads_load_fail]);
      expect(platform.showFailures, isEmpty);
      expect(platform.spinnerStops, 1);
      platform.dispose();
    });

    testWidgets('claim 대기 중 로그아웃 — 광고 없이 로그인 안내 1회', (tester) async {
      final platform = await buildPlatform(tester);
      final claim = Completer<AdmobClaimModel>();
      platform.createClaim =
          ({
            required platform,
            required placementId,
            required clientRequestId,
          }) => claim.future;
      final ad = await startAndLoad(tester, platform);

      platform.userId = null;
      claim.complete(_TestAdmobPlatform.claimFor('claim-a'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 30));

      expect(ad.ssv, isNull);
      expect(ad.showCalls, 0);
      expect(ad.disposeCalls, 1);
      expect(platform.loginRequired, 1);
      expect(platform.dialogs, isEmpty);
      expect(platform.showFailures, isEmpty);
      expect(platform.spinnerStops, 1);
      platform.dispose();
    });

    testWidgets('SSV 대기 중 계정 전환 — 이전 계정 광고를 띄우지 않는다', (tester) async {
      final platform = await buildPlatform(tester);
      await platform.showAd();
      final ad = _FakeRewardedAd('ad-1', platform.log)
        ..ssvGate = Completer<void>();
      platform.loads.single.onAdLoaded(ad);
      await tester.pump();
      expect(ad.ssv!.userId, 'user-a');

      platform.userId = 'user-b';
      ad.ssvGate!.complete();
      await tester.pump();
      await tester.pump(const Duration(seconds: 30));

      expect(ad.showCalls, 0);
      expect(ad.disposeCalls, 1);
      expect(platform.dialogs, [l10n().label_ads_load_fail]);
      expect(platform.showFailures, isEmpty);
      expect(platform.spinnerStops, 1);
      platform.dispose();
    });

    testWidgets('SSV 대기 중 로그아웃 — 광고 없이 로그인 안내 1회', (tester) async {
      final platform = await buildPlatform(tester);
      await platform.showAd();
      final ad = _FakeRewardedAd('ad-1', platform.log)
        ..ssvGate = Completer<void>();
      platform.loads.single.onAdLoaded(ad);
      await tester.pump();

      platform.userId = null;
      ad.ssvGate!.complete();
      await tester.pump();
      await tester.pump(const Duration(seconds: 30));

      expect(ad.showCalls, 0);
      expect(ad.disposeCalls, 1);
      expect(platform.loginRequired, 1);
      expect(platform.dialogs, isEmpty);
      expect(platform.showFailures, isEmpty);
      expect(platform.spinnerStops, 1);
      platform.dispose();
    });

    testWidgets('시청 뒤 계정이 바뀌어도 적립 확인은 원래 owner·claim 으로 폴링한다', (tester) async {
      final platform = await buildPlatform(tester);
      final ad = await startAndLoad(tester, platform);
      ad.sdkShowed();

      platform.userId = 'user-b';
      ad.sdkEarn();
      await tester.pump();

      expect(platform.polls, ['user-a:claim-1']);
      ad.sdkDismissed();
      platform.dispose();
    });
  });

  // R2: 요청마다 진입 시점(첫 await 이전)에 고정한 토큰·owner·GA4·갱신
  // 컨텍스트가 있어야 한다. 더 새로운 요청이 시작되면 이전 요청의 정책·준비·
  // 로드·claim·SSV 결과와 catch 안내는 새 요청의 흐름·스피너를 건드리지 않는다.
  group('R2: 요청 토큰', () {
    testWidgets('A 로드 중 user-b 의 새 요청이 준비 대기하면 A 의 늦은 loaded 는 '
        'user-b 로 claim·SSV·show 하지 않는다', (tester) async {
      final platform = await buildPlatform(tester);
      await platform.showAd(); // A (user-a): 로드 대기
      expect(platform.loads, hasLength(1));

      platform.userId = 'user-b';
      platform.holdReadiness = true;
      final b = platform.showAd(); // B (user-b): 준비 대기
      await tester.pump();
      expect(platform.readinessWaits, hasLength(1));

      final adA = _FakeRewardedAd('A', platform.log);
      platform.loads.first.onAdLoaded(adA);
      await tester.pump();

      expect(platform.claimCalls, 0);
      expect(platform.persisted, isEmpty);
      expect(adA.ssv, isNull);
      expect(adA.showCalls, 0);
      expect(adA.disposeCalls, 1);
      // 대체된 A 는 B 가 소유한 스피너·안내를 건드리지 않는다.
      expect(platform.dialogs, isEmpty);
      expect(platform.loginRequired, 0);
      expect(platform.spinnerStops, 0);

      // A 의 로드 워치독도 B 의 준비 대기 중에 발화하지 않는다.
      await tester.pump(const Duration(seconds: 16));
      expect(platform.loadFailures, isEmpty);
      expect(platform.spinnerStops, 0);

      platform.readinessWaits.single.complete();
      await b;
      expect(platform.loads, hasLength(2));
      final adB = _FakeRewardedAd('B', platform.log);
      platform.loads.last.onAdLoaded(adB);
      await tester.pump();

      expect(platform.persisted, ['user-b:claim-1']);
      expect(adB.ssv!.userId, 'user-b');
      expect(adB.showCalls, 1);
      adB.sdkShowed();
      expect(platform.spinnerStops, 1);
      adB.sdkDismissed();
      platform.dispose();
    });

    testWidgets('A·B 준비 대기 중 B 가 먼저 성공하면 A 의 늦은 성공은 흐름을 시작하지 않는다', (
      tester,
    ) async {
      final platform = await buildPlatform(tester);
      platform.holdReadiness = true;
      platform.ga4AdContext = _ga4A;
      final a = platform.showAd();
      await tester.pump();
      platform.ga4AdContext = _ga4B;
      final b = platform.showAd();
      await tester.pump();
      expect(platform.readinessWaits, hasLength(2));

      platform.readinessWaits[1].complete();
      await b;
      expect(platform.loads, hasLength(1));

      platform.readinessWaits[0].complete();
      await a;
      await tester.pump();
      expect(platform.loads, hasLength(1), reason: 'A 는 B 흐름을 대체하면 안 된다');
      expect(platform.dialogs, isEmpty);
      expect(platform.spinnerStops, 0);

      final adB = _FakeRewardedAd('B', platform.log);
      platform.loads.single.onAdLoaded(adB);
      await tester.pump();
      expect(platform.claimCalls, 1);
      expect(adB.showCalls, 1);
      expect(adB.disposeCalls, 0);
      adB.sdkShowed();
      adB.sdkImpression();
      expect(platform.impressions, [same(_ga4B)]);
      expect(platform.spinnerStops, 1);
      adB.sdkDismissed();
      platform.dispose();
    });

    final lateFailures = <String, Object>{
      '동의 미허용': const AdsUnavailable(
        'UMP does not currently permit ad requests',
      ),
      '준비 타임아웃': AdsUnavailable(
        'Ad readiness check failed',
        cause: TimeoutException('readiness', const Duration(seconds: 5)),
      ),
      '예상 못 한 오류': StateError('readiness crashed'),
    };
    for (final entry in lateFailures.entries) {
      testWidgets('B 가 시작된 뒤 A 의 늦은 준비 실패(${entry.key})는 '
          'B 의 스피너·안내를 건드리지 않는다', (tester) async {
        final platform = await buildPlatform(tester);
        platform.holdReadiness = true;
        final a = platform.showAd();
        await tester.pump();
        final b = platform.showAd();
        await tester.pump();

        platform.readinessWaits[1].complete();
        await b;
        expect(platform.loads, hasLength(1));

        platform.readinessWaits[0].completeError(entry.value);
        await a;
        await tester.pump();

        expect(platform.dialogs, isEmpty);
        expect(platform.loadFailures, isEmpty);
        expect(platform.spinnerStops, 0);

        final adB = _FakeRewardedAd('B', platform.log);
        platform.loads.single.onAdLoaded(adB);
        await tester.pump();
        expect(adB.showCalls, 1);
        adB.sdkShowed();
        expect(platform.spinnerStops, 1);
        adB.sdkDismissed();
        platform.dispose();
      });
    }

    testWidgets('A 의 정책 확인(safelyExecute 첫 await) 대기 중 B 가 시작되면 '
        'A 는 늦게 통과해도 흐름을 시작하지 않는다', (tester) async {
      final platform = await buildPlatform(tester);
      platform.policyHolds = 1;
      final a = platform.showAd();
      await tester.pump();
      expect(platform.policyWaits, hasLength(1));

      await platform.showAd(); // B: 정책 즉시 통과 → 로드
      expect(platform.loads, hasLength(1));

      platform.policyWaits.single.complete(true);
      await a;
      await tester.pump();
      expect(platform.loads, hasLength(1), reason: 'A 는 B 흐름을 대체하면 안 된다');
      expect(platform.dialogs, isEmpty);
      expect(platform.spinnerStops, 0);

      final adB = _FakeRewardedAd('B', platform.log);
      platform.loads.single.onAdLoaded(adB);
      await tester.pump();
      expect(adB.showCalls, 1);
      expect(adB.disposeCalls, 0);
      adB.sdkShowed();
      adB.sdkDismissed();
      platform.dispose();
    });
  });

  // R3: SDK 는 같은 광고 객체로 onAdLoaded 를 다시 보낼 수 있다
  // (ad_instance_manager.dart:223~229). 요청마다 로드 결과는 한 번만 받고,
  // 이미 소유·표시 중인 같은 광고는 중복 콜백으로 폐기하지 않는다.
  group('R3: 같은 요청의 중복 loaded', () {
    testWidgets('claim 대기 중 같은 광고의 loaded 가 두 번 와도 claim·SSV·show 는 한 번이다', (
      tester,
    ) async {
      final platform = await buildPlatform(tester);
      final claim = Completer<AdmobClaimModel>();
      platform.createClaim =
          ({
            required platform,
            required placementId,
            required clientRequestId,
          }) => claim.future;
      final ad = await startAndLoad(tester, platform);
      platform.loads.single.onAdLoaded(ad); // 같은 객체 재전달
      await tester.pump();

      claim.complete(_TestAdmobPlatform.claimFor('claim-a'));
      await tester.pump();

      expect(platform.claimCalls, 1);
      expect(platform.log.where((e) => e == 'ssv:ad-1'), hasLength(1));
      expect(ad.showCalls, 1);
      expect(ad.disposeCalls, 0);

      ad.sdkShowed();
      ad.sdkEarn();
      await tester.pump();
      expect(platform.polls, ['user-a:claim-a']);
      ad.sdkDismissed();
      expect(ad.disposeCalls, 1);
      platform.dispose();
    });

    testWidgets('SSV 대기 중 같은 광고의 loaded 가 두 번 와도 claim·SSV·show 는 한 번이다', (
      tester,
    ) async {
      final platform = await buildPlatform(tester);
      await platform.showAd();
      final ad = _FakeRewardedAd('ad-1', platform.log)
        ..ssvGate = Completer<void>();
      platform.loads.single.onAdLoaded(ad);
      await tester.pump();
      expect(ad.ssv, isNotNull); // SSV 설정 대기 중

      platform.loads.single.onAdLoaded(ad); // 같은 객체 재전달
      await tester.pump();
      ad.ssvGate!.complete();
      await tester.pump();

      expect(platform.claimCalls, 1);
      expect(platform.log.where((e) => e == 'ssv:ad-1'), hasLength(1));
      expect(ad.showCalls, 1);
      expect(ad.disposeCalls, 0);

      ad.sdkShowed();
      ad.sdkEarn();
      await tester.pump();
      expect(platform.polls, ['user-a:claim-1']);
      ad.sdkDismissed();
      expect(ad.disposeCalls, 1);
      platform.dispose();
    });

    testWidgets('onShowed 뒤 같은 광고의 loaded 재전달은 시청 중 광고를 폐기하지 않는다', (
      tester,
    ) async {
      final platform = await buildPlatform(tester);
      final ad = await startAndLoad(tester, platform);
      ad.sdkShowed();

      platform.loads.single.onAdLoaded(ad); // 같은 객체 재전달
      await tester.pump();

      expect(ad.disposeCalls, 0);
      expect(platform.claimCalls, 1);
      expect(ad.showCalls, 1);
      ad.sdkEarn();
      await tester.pump();
      expect(platform.polls, ['user-a:claim-1']);
      ad.sdkDismissed();
      expect(ad.disposeCalls, 1);
      expect(ad.droppedEvents, isEmpty);
      platform.dispose();
    });

    testWidgets('같은 요청에 다른 광고가 추가로 loaded 되면 그 광고만 한 번 정리한다', (tester) async {
      final platform = await buildPlatform(tester);
      final claim = Completer<AdmobClaimModel>();
      platform.createClaim =
          ({
            required platform,
            required placementId,
            required clientRequestId,
          }) => claim.future;
      final ad = await startAndLoad(tester, platform);

      final extraWhilePreparing = _FakeRewardedAd('extra-1', platform.log);
      platform.loads.single.onAdLoaded(extraWhilePreparing);
      await tester.pump();
      expect(extraWhilePreparing.disposeCalls, 1);
      expect(platform.claimCalls, 1);

      claim.complete(_TestAdmobPlatform.claimFor('claim-a'));
      await tester.pump();
      expect(ad.showCalls, 1);
      ad.sdkShowed();

      final extraWhileShowing = _FakeRewardedAd('extra-2', platform.log);
      platform.loads.single.onAdLoaded(extraWhileShowing);
      await tester.pump();
      expect(extraWhileShowing.disposeCalls, 1);
      expect(extraWhileShowing.showCalls, 0);
      expect(ad.disposeCalls, 0);

      ad.sdkEarn();
      await tester.pump();
      expect(platform.polls, ['user-a:claim-a']);
      ad.sdkDismissed();
      expect(ad.disposeCalls, 1);
      expect(platform.claimCalls, 1);
      platform.dispose();
    });
  });

  // R2 (정책 경계): 실제 AdPlatform.safelyExecute → checkAdsLimit →
  // check-ads-count 요청·응답 판정·안내 다이얼로그를 그대로 탄다. http 응답만
  // 요청별로 늦춰, A 의 늦은 정책 결과가 이미 시작된 B 의 스피너·안내를
  // 건드리는지 본다. 다이얼로그는 전역 navigatorKey 로 실제 위젯 트리에 뜬다.
  group('R2: 실제 정책 경로', () {
    late _PolicyServer server;

    setUp(() {
      server = _PolicyServer();
      testSupabaseClient = server.client;
    });

    tearDown(() => testSupabaseClient = null);

    const allowed = {'allowed': true, 'disabled': false};
    const denied = {
      'allowed': false,
      'disabled': false,
      'limits': {
        'admob': {'hourly': 10, 'daily': 120},
      },
      'counts': {
        'admob': {'hourly': 10, 'daily': 37},
      },
      'nextAvailableTime': '2030-01-01T00:00:00.000Z',
    };
    const disabled = {'allowed': false, 'disabled': true};

    Future<void> settleDialogs(WidgetTester tester) async {
      await tester.pump();
      await pumpAndIgnoreErrors(tester);
      await pumpAndIgnoreErrors(tester);
    }

    /// A 의 정책 요청이 대기 중일 때 B 를 시작하고, B 가 먼저 통과해 로드까지
    /// 간 상태를 만든다. A 의 응답 인덱스는 0, B 는 1 이다.
    // 보류 중인 A 의 Future 를 그대로 넘기려고 record 로 감싼다 — async 함수가
    // Future 를 반환하면 평탄화돼 A 가 끝날 때까지 기다리게 된다.
    Future<({Future<void> requestA})> startAThenB(
      WidgetTester tester,
      _TestAdmobPlatform platform,
    ) async {
      final a = platform.showAd();
      await tester.pump();
      expect(server.pendingCount, 1);
      final b = platform.showAd();
      await tester.pump();
      expect(server.pendingCount, 2);
      server.respond(1, allowed);
      await tester.pump();
      await b;
      await tester.pump();
      expect(platform.loads, hasLength(1));
      return (requestA: a);
    }

    testWidgets('대조: 현재 요청의 정책 거절은 한도 안내 1회와 스피너 해제로 끝난다', (tester) async {
      final platform = await buildPlatform(tester);
      platform.useRealPolicy = true;
      final a = platform.showAd();
      await tester.pump();
      server.respond(0, denied);
      await tester.pump();
      await a;
      await settleDialogs(tester);

      expect(server.requests.single.url.queryParameters['platform'], 'admob');
      expect(find.text(l10n().label_ads_exceeded), findsOneWidget);
      expect(platform.loads, isEmpty);
      expect(platform.spinnerStops, 1);
      platform.dispose();
    });

    testWidgets('B 시작 뒤 A 의 늦은 정책 거절은 B 의 스피너·안내를 건드리지 않는다', (tester) async {
      final platform = await buildPlatform(tester);
      platform.useRealPolicy = true;
      final a = (await startAThenB(tester, platform)).requestA;

      server.respond(0, denied);
      await tester.pump();
      await a;
      await settleDialogs(tester);

      expect(find.text(l10n().label_ads_exceeded), findsNothing);
      expect(platform.spinnerStops, 0);
      expect(platform.loads, hasLength(1));
      platform.dispose();
    });

    testWidgets('B 시작 뒤 A 의 늦은 disabled 응답은 B 의 스피너·안내를 건드리지 않는다', (
      tester,
    ) async {
      final platform = await buildPlatform(tester);
      platform.useRealPolicy = true;
      final a = (await startAThenB(tester, platform)).requestA;

      server.respond(0, disabled);
      await tester.pump();
      // 테스트는 kDebugMode 이므로 admob 은 disabled 면 os 없이 정확히 한 번
      // 재요청한다(AdPlatform.resolveAdsCountData).
      expect(server.pendingCount, 3);
      expect(server.requests[2].url.queryParameters.containsKey('os'), isFalse);
      server.respond(2, disabled);
      await tester.pump();
      await a;
      await settleDialogs(tester);

      expect(find.text(l10n().label_ads_temporarily_unavailable), findsNothing);
      expect(platform.spinnerStops, 0);
      expect(platform.loads, hasLength(1));
      platform.dispose();
    });

    testWidgets('B 시작 뒤 A 의 늦은 정책 오류는 B 의 스피너·안내를 건드리지 않는다', (tester) async {
      final platform = await buildPlatform(tester);
      platform.useRealPolicy = true;
      final a = (await startAThenB(tester, platform)).requestA;

      server.respond(0, const {'error': 'boom'}, status: 500);
      await tester.pump();
      await a;
      await settleDialogs(tester);

      expect(find.text(l10n().label_ads_load_fail), findsNothing);
      expect(platform.dialogs, isEmpty);
      expect(platform.spinnerStops, 0);
      expect(platform.loads, hasLength(1));
      platform.dispose();
    });
  });
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:picnic_lib/core/errors/anti_abuse_exception.dart';
import 'package:picnic_lib/core/utils/common_utils.dart';
import 'package:picnic_lib/core/utils/startup_readiness.dart';
import 'package:picnic_lib/data/models/ad/ad_reward_status.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/ad_platform.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/free_charge_analytics.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/platforms/admob_platform.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  @override
  Future<void> dispose() async {
    disposeCalls++;
  }

  void sdkShowed() =>
      fullScreenContentCallback!.onAdShowedFullScreenContent!(this);
  void sdkDismissed() =>
      fullScreenContentCallback!.onAdDismissedFullScreenContent!(this);
  void sdkFailedToShow(AdError error) =>
      fullScreenContentCallback!.onAdFailedToShowFullScreenContent!(
        this,
        error,
      );
  void sdkImpression() => fullScreenContentCallback!.onAdImpression!(this);
  void sdkEarn() => _earned!(this, RewardItem(1, 'star_candy'));
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

  @override
  Future<bool> checkAdsLimit(String platform) async => true;

  @override
  void startLoading() {}

  @override
  void stopLoading() => spinnerStops++;

  /// 동의·SDK 준비를 기다리는 동안 일어나는 일(계정 전환·로그아웃)을 흉내 낸다.
  void Function()? whileWaitingForReadiness;

  @override
  String? currentUserId() => userId;

  @override
  Future<void> runWhenAdsReady({
    required bool Function() isRequestActive,
    required Future<void> Function() request,
  }) async {
    // 실제 AdRequestReadinessGate 와 같은 순서: 대기 → 대기 뒤 활성 재확인 → 요청.
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
    platform.dispose();
    expect(ad.disposeCalls, 1); // 뜨지 않은 광고는 dispose 가 정리한다
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
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:picnic_lib/core/utils/common_utils.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/free_charge_analytics.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/platforms/admob_platform.dart';

import '../../../../../../helpers/ignore_image_errors.dart';
import '../../../../../../helpers/test_app.dart';

/// MAJOR-3 재검증에서 지적된 배선 레벨 테스트 — `AdmobShowFlow` 는 이미
/// SDK-독립 순수 상태 기계로 검증돼 있지만(admob_show_flow_test.dart),
/// `AdmobPlatform.showAd()` 가 `logAdLoadFailure` 에 넘기는 message 인자가
/// 실제 error 텍스트인지는 그 어떤 테스트도 지키지 않았다. 이 파일은 실제
/// `RewardedAd`(플랫폼 채널 필요) 없이도 그 배선을 직접 exercise 하기 위해
/// `handleLoadFailedForFlow` / `beginProfileRefreshAttempt` /
/// `captureProfileRefreshOnce` / `captureGa4ImpressionLogger` 를
/// `@visibleForTesting` 로 노출해 둔 seam 을 사용한다.
class _RecordedLoadFailure {
  _RecordedLoadFailure(this.error, this.message);
  final dynamic error;
  final String message;
}

class _RecordingCommonUtils extends CommonUtils {
  _RecordingCommonUtils(super.ref, super.context, this._onRefresh);

  final void Function() _onRefresh;

  @override
  void refreshUserProfile() => _onRefresh();
}

class _RecordingAdmobPlatform extends AdmobPlatform {
  _RecordingAdmobPlatform(
      super.ref, super.context, super.id, super.animationController);

  final List<_RecordedLoadFailure> loadFailures = [];
  int refreshUserProfileCallCount = 0;
  final List<FreeChargeAdGa4Context?> ga4ImpressionCalls = [];

  late final CommonUtils _fakeCommonUtils = _RecordingCommonUtils(
    ref,
    context,
    () => refreshUserProfileCallCount++,
  );

  @override
  CommonUtils get commonUtils => _fakeCommonUtils;

  @override
  void logAdLoadFailure(
    String platform,
    dynamic error,
    String adId,
    String message,
    StackTrace? stackTrace,
  ) {
    loadFailures.add(_RecordedLoadFailure(error, message));
  }

  @override
  void logGa4Impression(FreeChargeAdGa4Context? ga4) {
    ga4ImpressionCalls.add(ga4);
  }
}

/// AdPlatform 생성에 필요한 실제 WidgetRef/BuildContext/AnimationController 를
/// 얻기 위한 최소 호스트 위젯 (ad_service_test.dart 와 같은 패턴).
class _AnimationHost extends StatefulWidget {
  final Widget Function(AnimationController controller) builder;

  const _AnimationHost({required this.builder});

  @override
  State<_AnimationHost> createState() => _AnimationHostState();
}

class _AnimationHostState extends State<_AnimationHost>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(_controller);
}

void main() {
  late RestoreCallback restore;

  setUp(() {
    restore = suppressImageErrors();
    initTestEnvironment();
  });

  tearDown(() {
    restore();
  });

  Future<_RecordingAdmobPlatform> buildPlatform(WidgetTester tester) async {
    late WidgetRef capturedRef;
    late BuildContext capturedContext;
    late AnimationController capturedController;

    await pumpWidgetAndIgnoreErrors(
      tester,
      buildTestApp(
        _AnimationHost(
          builder: (controller) => Consumer(
            builder: (context, ref, _) {
              capturedRef = ref;
              capturedContext = context;
              capturedController = controller;
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
    await pumpAndIgnoreErrors(tester);

    return _RecordingAdmobPlatform(
        capturedRef, capturedContext, 'admob', capturedController);
  }

  group('MAJOR-3: onLoadFailed 배선은 실제 error 텍스트를 넘긴다', () {
    testWidgets(
        'LoadAdError 는 error.toString() 을 message 로 넘긴다 (하드코딩 라벨 아님)',
        (tester) async {
      final platform = await buildPlatform(tester);
      final error = LoadAdError(1, 'domain', 'Request Error detail', null);

      platform.handleLoadFailedForFlow(error);

      expect(platform.loadFailures, hasLength(1));
      final recorded = platform.loadFailures.single;
      expect(recorded.error, same(error));
      // 회귀 지점: 이 값이 하드코딩된 'AdMob 광고 로드 실패' 로 되돌아가면
      // isNonReportableAdError 가 SDK 초기화 실패 같은 진짜 버그까지
      // "모든 광고 소진" 으로 뭉개고 Sentry 보고를 막는다.
      expect(recorded.message, error.toString());
      expect(recorded.message, isNot('AdMob 광고 로드 실패'));
    });

    testWidgets('LoadAdError 가 아닌 예외(SDK 설정 오류 등)도 실제 텍스트를 넘긴다',
        (tester) async {
      final platform = await buildPlatform(tester);
      final error = StateError('플랫폼 채널 설정 오류');

      platform.handleLoadFailedForFlow(error);

      expect(platform.loadFailures, hasLength(1));
      expect(platform.loadFailures.single.message, error.toString());
    });
  });

  group('MINOR-1: refreshUserProfile dedup 은 attempt 별로 독립적이다', () {
    testWidgets(
        'A 의 늦은 reward 가 B 의 dismissed 를 스킵시키지 않는다 (attempt 별 dedup)',
        (tester) async {
      final platform = await buildPlatform(tester);

      // attempt A: showAd() 가 하는 것과 동일하게 attempt 를 시작하고,
      // _attachCallbacksAndShow 가 하는 것과 동일하게 배선 시점에 캡처한다.
      platform.beginProfileRefreshAttempt();
      final rewardA = platform.captureProfileRefreshOnce();

      // attempt B: A 가 아직 dismissed/reward 되기 전에 B 의 showAd() 가
      // 시작되어 필드를 리셋한다.
      final dismissB = platform.beginProfileRefreshAttempt();
      final rewardB = platform.captureProfileRefreshOnce();

      // A 의 늦은 reward 콜백이 이제야 도착한다.
      rewardA();
      expect(platform.refreshUserProfileCallCount, 1);

      // 회귀 지점: 예전 코드(전역 플래그 공유)라면 A 의 늦은 reward 가 이미
      // 플래그를 true 로 만들어 B 의 dismissed 가 스킵됐다. attempt 별
      // dedup 이라면 B 는 독립적으로 1회 더 갱신되어야 한다.
      dismissB();
      expect(platform.refreshUserProfileCallCount, 2);

      // B 의 reward 도 같은 attempt 안에서는 여전히 dedup 된다(중복 방지).
      rewardB();
      expect(platform.refreshUserProfileCallCount, 2);
    });

    testWidgets('같은 attempt 안에서는 reward 와 dismissed 가 dedup 된다',
        (tester) async {
      final platform = await buildPlatform(tester);

      platform.beginProfileRefreshAttempt();
      final reward = platform.captureProfileRefreshOnce();
      final dismiss = platform.captureProfileRefreshOnce();

      reward();
      dismiss();

      expect(platform.refreshUserProfileCallCount, 1);
    });
  });

  group('GA4 컨텍스트 스냅샷 회귀 테스트 (MAJOR-2)', () {
    testWidgets(
        '배선 시점에 캡처한 ga4AdContext 를 쓴다 — 다음 attempt 의 덮어쓰기에 영향받지 않는다',
        (tester) async {
      final platform = await buildPlatform(tester);
      const contextA = FreeChargeAdGa4Context(
        adPlatform: 'AdMob',
        adSource: 'admob',
        adFormat: 'rewarded',
        adUnitName: 'unit-a',
        sectionName: 'global-pick-1',
        adCategory: 'global',
        virtualCurrencyName: 'star_candy',
        rewardAmount: 1,
      );
      const contextB = FreeChargeAdGa4Context(
        adPlatform: 'AdMob',
        adSource: 'admob',
        adFormat: 'rewarded',
        adUnitName: 'unit-b',
        sectionName: 'global-pick-2',
        adCategory: 'global',
        virtualCurrencyName: 'star_candy',
        rewardAmount: 2,
      );

      platform.ga4AdContext = contextA;
      final logImpressionA = platform.captureGa4ImpressionLogger();

      // 다음 attempt(B) 가 시작되어 구좌 컨텍스트를 덮어쓴다 — 예를 들어
      // onAdImpression 이 늦게 도착하기 전에 사용자가 다른 구좌에서 광고를
      // 다시 시작한 경우.
      platform.ga4AdContext = contextB;

      // A 의 늦은 onAdImpression 이 이제야 도착한다.
      logImpressionA();

      expect(platform.ga4ImpressionCalls, hasLength(1));
      // 회귀 지점: onAdImpression 배선이 ga4AdContext 를 그때그때 다시 읽으면
      // 이 값이 contextB 로 새어나가 A 의 노출이 B 구좌로 잘못 귀속된다.
      expect(platform.ga4ImpressionCalls.single, same(contextA));
      expect(platform.ga4ImpressionCalls.single, isNot(same(contextB)));
    });

    testWidgets('ga4AdContext 가 null 이면 임의값으로 보내지 않는다', (tester) async {
      final platform = await buildPlatform(tester);
      platform.ga4AdContext = null;

      final logImpression = platform.captureGa4ImpressionLogger();
      logImpression();

      expect(platform.ga4ImpressionCalls, [null]);
    });
  });
}

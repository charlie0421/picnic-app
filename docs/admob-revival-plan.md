# AdMob 무료충전소 되살리기 계획

> **For agentic workers:** REQUIRED SUB-SKILL: superpowers:subagent-driven-development(권장) 또는 superpowers:executing-plans 로 태스크 단위 실행. 단계는 체크박스(`- [ ]`) 로 추적한다.

- **작성일**: 2026-08-13
- **작성 위치**: worktree `/Users/charlie.hyun/orca/workspaces/picnic-app/admob-callback-stall`, 브랜치 `fix/admob-callback-stall`
- **목표**: 무료충전소 AdMob 구좌를 다시 켤 수 있는 상태로 만든다(사용자 결정 사항). "켤 수 있는 상태" = 콜백 유실 시에도 사용자가 갇히지 않고, 회귀 테스트가 있고, 스테이징 실검증을 통과하고, 서버 플래그로 즉시 끌 수 있는 상태.
- **아키텍처 요약**: `admob_platform.dart` 의 로드→표시 시퀀스를 세대(generation) 토큰 + 워치독 타이머를 가진 테스트 가능한 상태 기계(`AdmobShowFlow`)로 분리한다. Pangle 의 `PangleClaimPreflight`(함수 주입형 오케스트레이션 클래스) 와 같은 레포 기존 패턴이다.
- **근거 문서** (이 계획은 아래 두 문서의 사실 관계 위에서만 서 있다):
  - 조사 보고서: `docs/admob-callback-stall-investigation.md` (콜백 배선 전수 조사, §6.2 에 8개 테스트 시나리오)
  - 재현 보고서: `docs/admob-callback-stall-repro-report.html` (실기기 재현 시도 — 서버 `disabled: true` 게이트로 재현 불가 판명)

## 전역 제약 (모든 태스크에 적용)

- Dart/Flutter 전용 변경은 Shorebird OTA 대상, 네이티브(pubspec 의 네이티브 플러그인 추가·제거, gradle/Podfile) 변경은 Codemagic 신규 바이너리 대상 — `~/.config/ai-agent-policies/flutter-release.md` 정책을 따른다.
- `google_mobile_ads` 는 6.0.0 고정(`picnic_lib/pubspec.lock`). 이 계획은 패키지 업그레이드를 전제하지 않는다.
- 커밋 메시지는 Conventional Commits. 프로덕션 서버 플래그 조작은 반드시 사용자 명시 승인 후에만 실행한다.
- 파일 경로는 별도 표기가 없으면 `picnic_lib/lib/presentation/widgets/vote/store/free_charge_station/` 기준.

---

## A. 되살리기 전제조건

AdMob 을 다시 켜기(=프로덕션 `admob_disabled_os` 해제) 전에 아래가 전부 충족되어야 한다. P1~P4 는 차단 조건이고, P5~P6 은 켜는 시점에 함께 준비돼야 하는 운영 조건이다.

| # | 전제조건 | 판정 기준 |
|---|---|---|
| P1 | **로드·표시 워치독 + 늦은 콜백 무시 로직 머지** (태스크 B-1) | ① `admob_show_flow_test.dart` 전체 green. ② 수동 드릴: 실기기에서 비행기 모드로 버튼 탭 → 로드 타임아웃(15초) 안에 스피너·버튼 애니메이션이 해제되고 안내 다이얼로그가 뜬다. 화면 조작 가능 상태 복귀. |
| P2 | **No-Fill 오분류 수정이 main 에 머지** (커밋 `71fd248d3`·`c7f5d11a0`·`2048fa016`, 이 브랜치에서 이미 수정됨 — 조사 보고서 §2 후보 C) | `git log main` 에서 해당 커밋(또는 그 squash 머지) 확인. `ad_platform_logic_test.dart` 의 관련 케이스 green. |
| P3 | **GA4 택소노미 정식화** (태스크 B-2·B-3: `FreeChargeGa4.platformAdmob` 상수 추가, 리터럴 `'AdMob'` 제거) | 스테이징 실기기에서 AdMob 시청 1건에 대해 `ad_request` → `ad_impression` 이 GA4 DebugView 에 `ad_platform=AdMob` 으로 잡힌다. |
| P4 | **스테이징 실검증 통과** (E 단계 3) | 스테이징에서 `admob_disabled_os` 게이트를 통과한 상태로: 5종 콜백(load/showed/impression/reward/dismissed) 로그 전부 관측 + 코튼캔디 잔액 증가(SSV `callback-admob` 경유) + 워치독 드릴 2종 통과. |
| P5 | **서버 킬스위치 왕복 검증** | 스테이징에서 `admob_disabled_os` 를 설정→해제→재설정하며, 각 상태가 앱의 `checkAdsLimit` 응답(`disabled` 필드)에 배포 없이 반영됨을 확인. 이것이 프로덕션 롤백 수단이다. |
| P6 | **모니터링 기준선 합의** | 켜기 전 최근 7일의 Play Console Android vitals ANR 비율과 Sentry App Hanging 건수를 기록해 두고, 켠 뒤 비교할 임계(예: ANR 비율이 기준선 대비 유의미 상승 시 플래그 재설정)를 사용자와 합의. Sentry 는 커밋 `4729cc5d7` 의 광고 SDK culprit 필터가 노이즈를 걸러내고 있으므로 **Play Console 수치를 1차 지표로** 삼는다. |

**전제조건이 아닌 것** — PangleMediationAdapter notReady 해소는 되살리기의 차단 조건이 **아니다**. 프로덕션 캡처(확정 사실 #3)에서 AdMob 코어·Vungle·Meta 어댑터는 ready 였으므로, Pangle 어댑터가 notReady 인 상태로도 AdMob 워터폴은 동작한다(해당 라인만 채움 없음). 처리 방침은 §C.

---

## B. 코드 수정 계획

### 설계 개요

현 구조의 결함(조사 보고서 §1.3): `stopAllAnimations()` 가 SDK 콜백 5종 안에서만 호출되어, 콜백이 안 오면 UI 를 되돌릴 경로가 없다. 수정 원칙:

1. **모든 시청 시도(attempt)는 반드시 정확히 하나의 UI terminal 경로로 끝난다** — `onLoadTimeout` / `onLoadFailed` / `onShowTimeout` / `onShowFailed` / **`onShowStarted`** 중 하나. **표시 성공(`onShowStarted`)도 terminal 이다** — 스피너가 이미 그 시점에 풀리고, 시청 시간은 전적으로 사용자에게 달려 더 지킬 워치독이 없기 때문이다. *(cross-review 갱신: 최초 계획은 "성공=dismissed" 로 적었으나, 그러면 dismissed/failedToShow 콜백이 둘 다 유실될 때 이 attempt 는 terminal 없이 끝나 위 불변식이 깨진다. `onDismissed`/`onFailedToShow` 는 UI terminal *이후에도* 도착할 수 있는 **광고 리소스 lifecycle** 이벤트로 재정의했다 — 아래 4번 참고, 실제 구현은 `admob_platform.dart` 의 `AdmobShowFlow._finish`/`_releaseIfPending` 문서 주석 참고.)*
2. **로드 단계 15초, 표시 단계 10초 워치독.**
   - 로드 15초 근거: Pangle 은 단일 SDK 라 5초를 쓰지만(`pangle_platform.dart:42`), AdMob 은 미디에이션 워터폴이 네트워크를 순회하므로 더 오래 걸릴 수 있고, GMA SDK 는 클라이언트 타임아웃을 제공하지 않아 앱이 직접 걸어야 한다(조사 보고서 §4, `[공개자료]` 등급 — 6.0.0 changelog 대조는 못 했음). 15초는 "스피너를 보고 기다려 줄 수 있는 상한"으로서의 공학적 판단이며 **측정 근거는 없다**. 스테이징에서 실제 로드 소요를 로그로 수집해 보정한다(§E 단계 3, §F).
   - 표시 10초 근거: `ad.show()` → `onAdShowedFullScreenContent` 는 로컬 UI 전환이라 정상적으로는 1~2초 내다. 10초는 보수적 상한.
3. **타임아웃 시 사용자에게 보여줄 것**:
   - 로드 타임아웃 → `logAdLoadFailure('AdMob', TimeoutException, …, '광고 로드 시간 초과', …)` 를 태운다. 이 문구는 `isNonReportableAdError` 키워드(`ad_platform.dart:384`)에 걸려 **"모든 광고 소진" 다이얼로그 + Sentry 미보고**로 처리된다. Pangle 로드 타임아웃(`loaded=false` → no-fill 안내)과 동일한 UX 로 의도적으로 맞춘 것이다. (대안: 별도 오류 다이얼로그 — §F 미확정 참고)
   - 표시 타임아웃 → `label_ads_show_fail` 오류 다이얼로그(기존 `onAdFailedToShowFullScreenContent` 경로와 동일 문구) + Sentry 보고(진짜 이상 상황이므로).
4. **늦게 도착한 콜백 무시(중복 처리 방지)**: 시도마다 증가하는 세대 토큰 `_generation` 을 캡처해, `onLoadTimeout`/`onLoadFailed`/`onShowTimeout`/`onShowStarted` 는 UI terminal 처리 이후 도착하면 UI 액션을 건너뛴다. `onDismissed`/`onFailedToShow` 는 세대가 아니라 **`_pendingAd` 소유권**으로 따로 관리한다 — 콜백이 캡처한 ad 가 여전히 `_pendingAd` 일 때만(=아직 아무도 정리하지 않았을 때만) 정리한다(`_releaseIfPending`, cross-review BLOCKER-1). 이래야 늦게 도착한 구세대 콜백이 이미 시작된 신세대 attempt 의 광고를 잘못 폐기하지 않는다. **리소스 정리(`ad.dispose()`)는 항상 수행하되**, `onDismissed` 의 UI 액션(스피너 해제·`refreshUserProfile`)은 **이 attempt 가 실제로 `onShowed` 로 끝났을 때만** 전달한다 — `showTimeout`/`showFailed` 로 이미 실패 다이얼로그가 뜬 뒤 늦게 온 dismissed 는 리소스만 정리하고 조용히 끝난다. 보상 후속 처리(`refreshUserProfile`)는 `onUserEarnedReward` 콜백에서도 별도로(세대 가드 밖) 수행하며, attempt 당 1회로 dedup 한다(cross-review MINOR-1).
5. **표시 타임아웃 시 `ad.dispose()` 를 즉시 하지 않는다** — "광고는 실제로 떠 있는데 콜백만 유실"인 경우 시청 중인 광고를 죽일 수 있다. 늦은 dismissed/failedToShow 콜백 또는 플랫폼 `dispose()` 에서 정리한다.
6. **위젯 teardown 시 실제로 정리된다**: `AdService.dispose()` 는 각 `AdPlatform.dispose()` 를 호출한 뒤에야 목록을 비우고, `FreeChargeStation.didChangeDependencies()` 는 새 `AdService` 를 만들기 전에 이전 인스턴스를 dispose 한다(cross-review BLOCKER-3) — 그러지 않으면 화면 이탈 후에도 flow 의 워치독 타이머가 살아남아 dispose 된 `AnimationController` 를 건드리거나 네이티브 광고가 누수된다.

### Task B-1: `AdmobShowFlow` 상태 기계 도입 + `AdmobPlatform` 재배선

**Files:**
- Modify: `platforms/admob_platform.dart`
- Test: `picnic_lib/test/presentation/widgets/vote/store/free_charge_station/platforms/admob_show_flow_test.dart` (신규 — 테스트 내용은 §D)

**Interfaces:**
- Produces: `AdmobShowFlow<T>` — 생성자 `AdmobShowFlow({required startLoad, required attachCallbacksAndShow, required disposeAd, loadTimeout, showTimeout})`, 메서드 `run({onLoadTimeout, onLoadFailed, onShowStarted, onShowTimeout, onShowFailed, onDismissed})`, `dispose()`. §D 의 테스트가 이 시그니처를 그대로 사용한다.

- [ ] **Step 1: 실패하는 테스트 작성** — §D 시나리오 1·2 의 테스트를 먼저 작성한다(코드는 §D Task D-1 에 있음).

- [ ] **Step 2: 테스트 실패 확인**

```bash
cd picnic_lib && flutter test test/presentation/widgets/vote/store/free_charge_station/platforms/admob_show_flow_test.dart
```
기대: `AdmobShowFlow` 미정의로 컴파일 실패.

- [ ] **Step 3: `AdmobShowFlow` 구현** — `admob_platform.dart` 에 추가(파일 상단, `AdmobPlatform` 클래스 앞). `PangleClaimPreflight` 처럼 같은 파일 안의 public 클래스로 둔다.

```dart
/// AdMob 로드→표시 한 사이클의 상태 기계.
///
/// - 로드/표시 각 단계에 워치독을 걸어 SDK 콜백이 하나도 오지 않아도 반드시
///   terminal 콜백 중 정확히 하나로 끝난다 (조사 보고서 §1.3 의 "영구 정지" 차단).
/// - 세대 토큰으로 늦게 도착한 SDK 콜백의 UI 액션을 무시한다. 리소스 정리는
///   늦게 와도 수행한다.
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
  ) startLoad;

  /// fullScreenContentCallback 배선 + SSV 설정 + ad.show 를 한 번에 수행한다.
  /// 인자로 받은 콜백을 SDK 콜백에 그대로 연결해야 한다.
  final void Function(
    T ad, {
    required void Function() onShowed,
    required void Function() onDismissed,
    required void Function(Object error) onFailedToShow,
  }) attachCallbacksAndShow;

  final void Function(T ad) disposeAd;
  final Duration loadTimeout;
  final Duration showTimeout;

  int _generation = 0;
  Timer? _watchdog;
  T? _pendingAd;

  bool _isCurrent(int g) => g == _generation;

  void _cancelWatchdog() {
    _watchdog?.cancel();
    _watchdog = null;
  }

  /// 이 attempt 를 terminal 상태로 만든다. 이후 도착하는 같은 세대의 SDK
  /// 콜백은 UI 액션을 건너뛴다.
  void _finish(int g) {
    if (_isCurrent(g)) {
      _generation++;
      _cancelWatchdog();
    }
  }

  void _disposePending() {
    final ad = _pendingAd;
    _pendingAd = null;
    if (ad != null) disposeAd(ad);
  }

  void run({
    required void Function() onLoadTimeout,
    required void Function(Object error) onLoadFailed,
    required void Function() onShowStarted,
    required void Function() onShowTimeout,
    required void Function(Object error) onShowFailed,
    required void Function() onDismissed,
  }) {
    _generation++; // 새 attempt 시작 = 이전 attempt 전부 무효화
    _disposePending();
    final g = _generation;
    _cancelWatchdog();

    _watchdog = Timer(loadTimeout, () {
      if (!_isCurrent(g)) return;
      _finish(g);
      onLoadTimeout();
    });

    startLoad(
      (ad) {
        if (!_isCurrent(g)) {
          // 타임아웃/재시도 이후 늦게 도착한 onAdLoaded — 조용히 폐기.
          disposeAd(ad);
          return;
        }
        _cancelWatchdog();
        _pendingAd = ad;
        _watchdog = Timer(showTimeout, () {
          if (!_isCurrent(g)) return;
          _finish(g);
          // 광고가 실제로 떠 있는데 콜백만 유실된 경우일 수 있으므로 여기서
          // ad 를 dispose 하지 않는다. 늦은 dismissed/failedToShow 또는
          // 플랫폼 dispose 에서 정리한다.
          onShowTimeout();
        });
        attachCallbacksAndShow(
          ad,
          onShowed: () {
            if (!_isCurrent(g)) return;
            // 표시 성공. 시청 시간은 사용자에 달렸으므로 이후 시한은 두지
            // 않는다 — 스피너는 이 시점에 이미 해제된다.
            _cancelWatchdog();
            onShowStarted();
          },
          onDismissed: () {
            _disposePending(); // 늦게 오더라도 리소스 정리는 항상 수행
            if (!_isCurrent(g)) return;
            _finish(g);
            onDismissed();
          },
          onFailedToShow: (error) {
            _disposePending();
            if (!_isCurrent(g)) return;
            _finish(g);
            onShowFailed(error);
          },
        );
      },
      (error) {
        if (!_isCurrent(g)) return; // 늦은 실패 콜백 — 이미 타임아웃 처리됨
        _finish(g);
        onLoadFailed(error);
      },
    );
  }

  void dispose() {
    _generation++;
    _cancelWatchdog();
    _disposePending();
  }
}
```

- [ ] **Step 4: `AdmobPlatform` 을 `AdmobShowFlow` 로 재배선** — 기존 `_loadRewardedAd`/`_setupAdCallbacks`/`_showRewardedAd`/`_disposeCurrentAd`/`_currentAd` 를 아래로 대체한다.

```dart
class AdmobPlatform extends AdPlatform {
  String _adUnitId = '';
  late final AdmobShowFlow<RewardedAd> _flow = AdmobShowFlow<RewardedAd>(
    startLoad: _startLoad,
    attachCallbacksAndShow: _attachCallbacksAndShow,
    disposeAd: (ad) => ad.dispose(),
  );

  // initialize()/_initAdUnitId() 는 기존 그대로.

  @override
  Future<void> showAd() async {
    await safelyExecute(() async {
      if (!context.mounted || isDisposed) return;

      // SSV userId 는 표시 직전이 아니라 진입 시점에 확인한다 — 로드까지 다
      // 해 놓고 로그인 다이얼로그를 띄우는 낭비와, 표시 단계의 조기 이탈
      // 경로 하나를 없앤다. (표시 직전 재확인은 _attachCallbacksAndShow 에 유지)
      final userId = supabase.auth.currentUser?.id;
      if (userId == null || userId.isEmpty) {
        logger.e('[$id] SSV userId가 없음 - 인증 세션 만료 가능성');
        stopAllAnimations();
        showRequireLoginDialog();
        return;
      }

      if (_adUnitId.isEmpty) {
        await _initAdUnitId();
      }
      startButtonAnimation();
      logger.i('[$id] 광고 로드 시작: $_adUnitId');

      _flow.run(
        onLoadTimeout: () {
          logger.w('[$id] 광고 로드 타임아웃 (${_flow.loadTimeout.inSeconds}s)');
          // '광고 로드 시간 초과' 는 isNonReportableAdError 키워드에 걸려
          // "모든 광고 소진" 안내 + Sentry 미보고로 처리된다. Pangle 로드
          // 타임아웃과 동일한 UX 를 의도한 선택이다.
          logAdLoadFailure(
            'AdMob',
            TimeoutException('admob load timeout', _flow.loadTimeout),
            _adUnitId,
            '광고 로드 시간 초과',
            StackTrace.current,
          );
          stopAllAnimations();
        },
        onLoadFailed: (error) {
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
          // 분류 근거로 실제 에러 텍스트를 넘긴다(하드코딩 라벨 금지 —
          // ad_platform.dart isNonReportableAdError doc 참조).
          logAdLoadFailure(
              'AdMob', error, _adUnitId, error.toString(), StackTrace.current);
          stopAllAnimations();
        },
        onShowStarted: () {
          logger.i('[$id] 광고가 전체 화면으로 표시됨');
          stopAllAnimations();
        },
        onShowTimeout: () {
          logger.e('[$id] 광고 표시 타임아웃 (${_flow.showTimeout.inSeconds}s) — '
              'FullScreenContentCallback 미수신');
          logAdShowFailure(
            'AdMob',
            TimeoutException('admob show timeout', _flow.showTimeout),
            _adUnitId,
            'AdMob show callback timeout', // no-fill 키워드에 안 걸리는 문구 → Sentry 보고됨
            StackTrace.current,
          );
          stopAllAnimations();
          if (context.mounted && !isDisposed) {
            showSimpleDialog(
                content: AppLocalizations.of(context).label_ads_show_fail,
                type: DialogType.error);
          }
        },
        onShowFailed: (error) {
          logAdShowFailure('AdMob', error, _adUnitId, error.toString(), null);
          stopAllAnimations();
          if (context.mounted && !isDisposed) {
            showSimpleDialog(
                content: AppLocalizations.of(context).label_ads_show_fail,
                type: DialogType.error);
          }
        },
        onDismissed: () {
          logger.i('[$id] 광고가 닫힘');
          stopAllAnimations();
          commonUtils.refreshUserProfile();
        },
      );
    });
  }

  void _startLoad(
    void Function(RewardedAd ad) onLoaded,
    void Function(Object error) onFailedToLoad,
  ) {
    unawaited(
      RewardedAd.load(
        adUnitId: _adUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: onLoaded,
          onAdFailedToLoad: onFailedToLoad,
        ),
        // RewardedAd.load 가 동기/비동기 예외를 던지는 드문 경로(설정 오류 등)도
        // 같은 실패 콜백으로 합류시킨다 — 세대 가드·단일 다이얼로그가 함께 적용된다.
      ).catchError((Object e) => onFailedToLoad(e)),
    );
  }

  void _attachCallbacksAndShow(
    RewardedAd ad, {
    required void Function() onShowed,
    required void Function() onDismissed,
    required void Function(Object error) onFailedToShow,
  }) {
    logger.i('[$id] 광고 로드 완료');
    if (!context.mounted || isDisposed) {
      ad.dispose();
      return;
    }
    final userId = supabase.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      // showAd 진입 시점 검사를 통과했지만 로드 중 세션이 만료된 경우.
      onFailedToShow(StateError('SSV userId missing at show time'));
      return;
    }
    final platform = Platform.isIOS ? 'ios' : 'android';
    logger.i('[$id] SSV 설정: userId=$userId, platform=$platform, adUnit=$_adUnitId');
    ad.setServerSideOptions(
      ServerSideVerificationOptions(
        userId: userId,
        customData: 'platform=$platform',
      ),
    );
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) => onShowed(),
      onAdDismissedFullScreenContent: (_) => onDismissed(),
      onAdFailedToShowFullScreenContent: (_, error) {
        logger.e(
          '[$id] AdMob 광고 표시 실패 상세:\n'
          '  code: ${error.code}\n'
          '  message: ${error.message}\n'
          '  domain: ${error.domain}',
        );
        onFailedToShow(error);
      },
      onAdImpression: (_) {
        logger.i('[$id] 광고 노출 기록됨');
        _logGa4Impression(); // Task B-4
      },
    );
    ad.show(
      onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
        // 보상 적립은 SSV(callback-admob)가 서버에서 독립 수행한다. 클라이언트는
        // 프로필 갱신만 하며, 이는 세대 가드 밖 — 늦게 와도 무해하고 유익하다.
        logger.i('[$id] 보상 콜백 수신: ${reward.amount} ${reward.type}, userId=$userId');
        commonUtils.refreshUserProfile();
      },
    );
  }

  @override
  Future<void> handleError(error, StackTrace? stackTrace) async {
    // 기존 그대로 유지 (safelyExecute 의 catch 전용 — _flow 경유 실패는
    // 여기까지 오지 않는다. rethrow 를 하지 않으므로.)
    logger.e('[$id] 광고 오류 발생', error: error, stackTrace: stackTrace);
    setLoading(false);
    stopAllAnimations();
    if (context.mounted && !isDisposed) {
      showSimpleDialog(
          content: AppLocalizations.of(context).label_ads_load_fail,
          type: DialogType.error);
    }
  }

  @override
  void dispose() {
    _flow.dispose();
    super.dispose();
  }
}
```

필요 임포트 추가: `dart:async` (`Timer`, `TimeoutException`, `unawaited`).

주의사항:
- `showAd()` 는 `_flow.run()` 호출 즉시 반환한다(터미널 처리는 전부 콜백). `safelyExecute` 의 catch 는 이제 `checkAdsLimit` 예외 등 게이트 단계 예외만 잡는다.
- 기존 `onAdLoaded` 의 `isDisposed → ad.dispose()` 가드는 `_attachCallbacksAndShow` 의 `context.mounted/isDisposed` 검사로 이동·유지된다.
- `_currentAd` 필드는 `_flow._pendingAd` 로 대체되므로 삭제한다.

- [ ] **Step 5: 테스트 green 확인**

```bash
cd picnic_lib && flutter test test/presentation/widgets/vote/store/free_charge_station/platforms/admob_show_flow_test.dart
cd picnic_lib && flutter test test/presentation/widgets/vote/store/free_charge_station/
```
기대: 신규 파일 전체 PASS + 기존 free_charge_station 테스트 회귀 없음.

- [ ] **Step 6: 정적 분석 + 커밋**

```bash
cd picnic_lib && flutter analyze lib/presentation/widgets/vote/store/free_charge_station/platforms/admob_platform.dart
git add picnic_lib/lib/presentation/widgets/vote/store/free_charge_station/platforms/admob_platform.dart \
        picnic_lib/test/presentation/widgets/vote/store/free_charge_station/platforms/admob_show_flow_test.dart
git commit -m "fix(ads): AdMob 로드·표시 워치독 도입, 콜백 유실 시 영구 로딩 차단"
```

### Task B-2: GA4 택소노미 상수 추가

**Files:**
- Modify: `free_charge_analytics.dart` (`FreeChargeGa4` 클래스, `platformPangle`/`sourcePangle` 이 있는 54–55행 부근)

**Interfaces:**
- Produces: `FreeChargeGa4.platformAdmob`, `FreeChargeGa4.sourceAdmob` (둘 다 `static const String`, 값 `'AdMob'`) — Task B-3 이 사용.

- [ ] **Step 1: 실패하는 테스트 작성** — `free_charge_analytics_test.dart` 에 추가:

```dart
test('AdMob taxonomy constants', () {
  expect(FreeChargeGa4.platformAdmob, 'AdMob');
  expect(FreeChargeGa4.sourceAdmob, 'AdMob');
});
```

- [ ] **Step 2: 실패 확인** → **Step 3: 구현**

```dart
  static const String platformAdmob = 'AdMob';
  static const String sourceAdmob = 'AdMob';
```

- [ ] **Step 4: green 확인 후 커밋**

```bash
cd picnic_lib && flutter test test/presentation/widgets/vote/store/free_charge_station/free_charge_analytics_test.dart
git add -A picnic_lib/lib/presentation/widgets/vote/store/free_charge_station/free_charge_analytics.dart \
       picnic_lib/test/presentation/widgets/vote/store/free_charge_station/free_charge_analytics_test.dart
git commit -m "feat(analytics): FreeChargeGa4 에 AdMob 택소노미 상수 추가"
```

### Task B-3: UI 구좌 복원 정식화

**Files:**
- Modify: `free_charge_station.dart` (`_buildAdItems()`, 현재 워크트리에 `[조사용 임시 복원 — 커밋 금지]` 주석의 미커밋 diff 로 존재)

현재 워크트리의 미커밋 복원 diff(재현 보고서 §8)를 그대로 커밋하지 말고, 다음을 고쳐서 정식화한다:

- [ ] **Step 1**: `adPlatform: 'AdMob'` / `adSource: 'AdMob'` 리터럴을 `FreeChargeGa4.platformAdmob` / `FreeChargeGa4.sourceAdmob` 으로 교체.
- [ ] **Step 2**: `// [조사용 임시 복원 — 커밋 금지] …` 주석을 `// 글로벌 픽 #2: AdMob 리워드 비디오` 로 교체 (internal-shortform 이 #1 을 차지한 뒤의 자리이므로 — 6fecae2fe 이전과 같은 상대 배치).
- [ ] **Step 3**: `free_charge_station_logic_test.dart`/`free_charge_station_test.dart` 에 구좌 노출 케이스가 있으면 AdMob 구좌 포함 기대값으로 갱신, 없으면 "admob 사용 가능 시 글로벌 픽 #2 로 노출된다" 케이스 추가. 기존 테스트 패턴을 따른다.
- [ ] **Step 4**: green 확인 후 커밋

```bash
cd picnic_lib && flutter test test/presentation/widgets/vote/store/free_charge_station/
git add picnic_lib/lib/presentation/widgets/vote/store/free_charge_station/free_charge_station.dart
git commit -m "feat(ads): 무료충전소 AdMob 글로벌 구좌 복원 (6fecae2fe 되돌림, GA4 상수 적용)"
```

**참고**: 이 커밋이 배포된 시점부터 서버 플래그 해제 전까지, 사용자는 구좌를 볼 수 있고 탭하면 "일시적으로 이용 불가" 다이얼로그를 본다(재현 보고서 §3 에서 실측한 정상 동작). 창을 줄이려면 §E 에서 OTA 발행과 플래그 해제를 같은 작업 창에서 붙여 실행한다. 탭 전에 구좌 자체를 숨기는 사전 조회는 현 구조(`checkAdsLimit` 이 탭 시점에만 호출)에 없는 기능이라 이번 범위에서 제외한다(YAGNI — 필요해지면 별도 태스크).

### Task B-4: `ad_impression` GA4 발송 (Pangle 과 동등화)

**Files:**
- Modify: `platforms/admob_platform.dart` (Task B-1 의 `onAdImpression` 에서 호출하는 `_logGa4Impression()` 구현)

Pangle 은 SDK 노출 콜백에서 `logAdImpression` 을 보낸다(`pangle_platform.dart:228-252`). AdMob 은 SDK 가 `onAdImpression` 콜백을 직접 주므로 1회성 구독·타이머 없이 단순하다.

- [ ] **Step 1: 구현**

```dart
  void _logGa4Impression() {
    final ga4 = ga4AdContext;
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
```

임포트 추가: `package:picnic_lib/core/analytics/picnic_analytics.dart`.

- [ ] **Step 2**: `flutter analyze` 통과 확인 후 Task B-1 커밋에 포함하거나 별도 커밋:

```bash
git commit -m "feat(analytics): AdMob onAdImpression 에서 ad_impression 발송"
```

---

## C. PangleMediationAdapter 처리 방침

### 방침: **제거한다** (버전 정렬이 아니라)

근거:

1. **중복**: Pangle 은 아시아 픽 #1 구좌에서 직접 SDK(`pangle_native_channel` MethodChannel → Android `PangleNativeHandler`, iOS `PangleAdManager.swift` 의 `PAGSdk`)로 이미 서빙 중이다(확정 사실 #6). AdMob 워터폴 안의 Pangle 라인은 같은 수요를 이중 연동한 것이다.
2. **현재 수익 기여 0**: 프로덕션 1.3.0+130007 캡처에서 PangleMediationAdapter 는 notReady('does not implement the initialize() method', `main_initializer.dart:239-245` 어댑터 상태 로그) — 즉 지금도 이 라인은 워터폴에서 채움을 만들지 못한다. 제거해도 **현재 대비** 수익 회귀가 없다.
3. **유지 비용**: Android 는 어댑터 번들 SDK(`pag-sdk-ad`)를 exclude 하고 직접 SDK(`ads-sdk:6.5.0.6`)로 치환하는 트릭(`picnic_app/android/app/build.gradle:247-253`)으로 두 연동을 공존시키고 있다. notReady 의 원인이 이 치환(어댑터가 기대하는 모듈/버전과 불일치)일 가능성이 있으나 **미확정**이다(§F). "고쳐서 유지"를 택하면 어댑터↔SDK 버전 매트릭스를 Pangle·Google 양쪽 릴리스마다 계속 맞춰야 한다.

포기하는 것(정직하게): 어댑터를 **고쳤을 경우** AdMob 워터폴이 Pangle 수요를 끼워 넣어 얻었을 잠재적 eCPM 개선. 이는 현재 0 인 기여의 회복 가능성이지 현존 수익이 아니며, Pangle 수요 자체는 직접 구좌로 이미 수익화 중이다.

### 제거 영향 범위 (실행 시 체크리스트)

| 영역 | 변경 | 비고 |
|---|---|---|
| `picnic_lib/pubspec.yaml:25` | `gma_mediation_pangle: ^3.4.0` 삭제 (`gma_mediation_meta`·`gma_mediation_liftoffmonetize` 는 유지) | `flutter pub get` 으로 lock 재생성 |
| `picnic_app/android/app/build.gradle:251-253` | `configurations.all { exclude group: 'com.pangle.global', module: 'pag-sdk-ad' }` 블록과 247-250행 주석 삭제 — 어댑터가 사라지면 번들 SDK 도 사라져 exclude 가 무의미해진다 | `implementation 'com.pangle.global:ads-sdk:6.5.0.6'`(265행)은 **유지** — 직접 연동(`PangleNativeHandler`)이 사용 |
| `picnic_app/ios/Podfile:50-51` | **⚠️ 필수**: `pod 'Ads-Global'` 재추가. 현재 iOS 의 Pangle SDK 는 gma_mediation_pangle 어댑터가 끌어오고 있고(50행 주석), `PangleAdManager.swift:110` 의 `PAGSdk.start` 가 그 SDK 를 직접 쓴다. 어댑터만 빼면 **iOS 빌드가 깨진다.** 51행에 주석으로 남아 있는 이전 핀 `pod 'Ads-Global', '6.5.0.9'` 을 복원하되, 최신 호환 버전 확인 후 결정 | `pod install` 후 `PAGAdSDK`(또는 `Ads-Global`) 가 Podfile.lock 에 남아 있는지 확인이 판정 기준 |
| Android `bytedance` maven 저장소(`build.gradle:240-241`) | **유지** — 직접 SDK 가 계속 필요 | |
| AdMob 콘솔 | 미디에이션 그룹에서 Pangle 광고 소스 라인 제거/일시중지 | 코드 아님. 남겨두면 서빙엔 지장 없지만 죽은 라인이 워터폴 순회 지연을 만든다 |
| 워터폴 수익 | 현재 notReady 라 기여 0 → 회귀 없음 (위 근거 2) | 제거 후 AdMob eCPM/매치율을 콘솔에서 1주 관찰 |
| 배포 수단 | **네이티브 변경이므로 Codemagic 신규 바이너리 필수, OTA 불가** (flutter-release 정책) | |

### 시점

되살리기의 차단 조건이 아니므로(§A), **별도 PR 로 분리해 다음 정규 바이너리 릴리스(버전 상향이 필요한 다음 릴리스)에 편승**시킨다. 이번 되살리기(B 태스크들)는 Dart 전용이라 OTA 로 나갈 수 있는데, 어댑터 제거를 같은 PR 에 섞으면 전체가 바이너리 릴리스로 격상되어 롤아웃이 늦어진다.

---

## D. 테스트 계획

현황: AdMob 전용 테스트 0건 (조사 보고서 §6.1 — `AdmobPlatform` 을 다루는 테스트 파일이 레포에 없음). 조사 보고서 §6.2 의 8개 시나리오를 다음과 같이 확정한다. `AdmobShowFlow` 가 함수 주입형이므로 시나리오 대부분이 SDK 모킹 없이 순수 유닛 테스트로 내려온다. 타이머는 `fake_async`(이미 `picnic_lib/pubspec.yaml:128` dev dependency) 로 제어한다.

| 조사 §6.2 시나리오 | 판정 | 구현 위치 |
|---|---|---|
| 1. show 단계 콜백 전부 유실 | **채택** | `admob_show_flow_test.dart` — show 워치독 |
| 2. load 콜백 양쪽 다 유실 | **채택** | `admob_show_flow_test.dart` — load 워치독 |
| 3. no-fill 코드로 `onAdFailedToLoad` | **채택** | `admob_show_flow_test.dart`(단일 terminal 호출 검증) + `ad_platform_logic_test.dart`(LoadAdError 코드 1/2/3 분류) |
| 4. `RewardedAd.load` 동기 예외 | **채택 (변형)** | `admob_show_flow_test.dart` — `startLoad` 가 즉시 `onFailedToLoad` 를 부르는 fake 로 표현. "다이얼로그 3회" 재현 테스트는 main 구코드 전제라 작성하지 않고, 새 구조에서 terminal 1회만 검증 |
| 5. showed 후 dismissed/failedToShow 유실 | **채택** | `admob_show_flow_test.dart` — 스피너 해제 + pendingAd 미정리 상태의 명시적 고정 |
| 6. `context.mounted == false` 시 콜백 | **부분 채택** | BuildContext 는 순수 유닛으로 검증 불가. `AdmobShowFlow` 계층에서는 "UI 콜백 스킵돼도 dispose 는 수행"으로 치환해 검증(시나리오 8 과 통합). `AdmobPlatform` 계층의 mounted 가드는 스테이징 수동 드릴로 커버(§E) |
| 7. `isNonReportableAdError` 키워드 충돌 회귀 | **채택** | `ad_platform_logic_test.dart` 확장 — 이 함수는 `@visibleForTesting static`(`ad_platform.dart:353`) 이라 직접 호출 가능 |
| 8. 타임아웃 후 늦은 콜백 race | **채택** | `admob_show_flow_test.dart` — 세대 가드 |

### Task D-1: `admob_show_flow_test.dart` (신규)

**Files:**
- Create: `picnic_lib/test/presentation/widgets/vote/store/free_charge_station/platforms/admob_show_flow_test.dart`

**Interfaces:**
- Consumes: `AdmobShowFlow<T>` (Task B-1 정의 시그니처)

케이스 목록과 핵심 코드 (fake ad 는 `String` 으로 충분 — `AdmobShowFlow<T>` 는 T 를 불투명하게 다룬다):

```dart
import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/platforms/admob_platform.dart';

typedef LoadedCb = void Function(String ad);
typedef FailedCb = void Function(Object error);

void main() {
  // 각 테스트가 SDK 콜백을 손으로 발화할 수 있도록 캡처해 두는 하네스.
  late LoadedCb sdkOnLoaded;
  late FailedCb sdkOnFailedToLoad;
  void Function()? sdkOnShowed;
  void Function()? sdkOnDismissed;
  void Function(Object)? sdkOnFailedToShow;
  late List<String> disposed;
  late List<String> events;

  AdmobShowFlow<String> buildFlow() {
    disposed = [];
    events = [];
    sdkOnShowed = null;
    sdkOnDismissed = null;
    sdkOnFailedToShow = null;
    return AdmobShowFlow<String>(
      startLoad: (onLoaded, onFailed) {
        sdkOnLoaded = onLoaded;
        sdkOnFailedToLoad = onFailed;
      },
      attachCallbacksAndShow: (ad, {required onShowed, required onDismissed, required onFailedToShow}) {
        sdkOnShowed = onShowed;
        sdkOnDismissed = onDismissed;
        sdkOnFailedToShow = onFailedToShow;
      },
      disposeAd: disposed.add,
    );
  }

  void run(AdmobShowFlow<String> flow) {
    flow.run(
      onLoadTimeout: () => events.add('loadTimeout'),
      onLoadFailed: (e) => events.add('loadFailed'),
      onShowStarted: () => events.add('showStarted'),
      onShowTimeout: () => events.add('showTimeout'),
      onShowFailed: (e) => events.add('showFailed'),
      onDismissed: () => events.add('dismissed'),
    );
  }

  // 시나리오 2: onAdLoaded 도 onAdFailedToLoad 도 안 온다 → 15초 뒤
  // loadTimeout 이 정확히 1회. (현재 코드에는 이 방어가 없어 영구 로딩 — 조사 §1.3)
  test('load 콜백이 전혀 없으면 loadTimeout 으로 끝난다', () {
    fakeAsync((async) {
      final flow = buildFlow();
      run(flow);
      async.elapse(const Duration(seconds: 14));
      expect(events, isEmpty);
      async.elapse(const Duration(seconds: 1));
      expect(events, ['loadTimeout']);
      async.elapse(const Duration(minutes: 10));
      expect(events, ['loadTimeout']); // 더 이상 아무 일도 없다
    });
  });

  // 시나리오 1: 로드 성공 후 show 단계 콜백 전부 유실 → 10초 뒤 showTimeout.
  test('show 콜백이 전혀 없으면 showTimeout 으로 끝난다', () {
    fakeAsync((async) {
      final flow = buildFlow();
      run(flow);
      sdkOnLoaded('ad-1');
      async.elapse(const Duration(seconds: 10));
      expect(events, ['showTimeout']);
      // ⚠️ 광고가 떠 있을 수 있으므로 showTimeout 시점에 dispose 하지 않는다.
      expect(disposed, isEmpty);
    });
  });

  // 시나리오 8: showTimeout 뒤 늦게 도착한 dismissed — UI 이벤트는 무시하되
  // 리소스 정리는 수행한다.
  test('타임아웃 후 늦은 dismissed 는 dispose 만 수행한다', () {
    fakeAsync((async) {
      final flow = buildFlow();
      run(flow);
      sdkOnLoaded('ad-1');
      async.elapse(const Duration(seconds: 10));
      expect(events, ['showTimeout']);
      sdkOnDismissed!();
      expect(events, ['showTimeout']); // dismissed 이벤트는 추가되지 않는다
      expect(disposed, ['ad-1']);      // 하지만 광고는 정리된다
    });
  });

  // 시나리오 8 변형: loadTimeout 뒤 늦게 도착한 onAdLoaded → 광고 즉시 폐기,
  // show 로 진행하지 않는다.
  test('타임아웃 후 늦은 onAdLoaded 는 광고를 폐기한다', () {
    fakeAsync((async) {
      final flow = buildFlow();
      run(flow);
      async.elapse(const Duration(seconds: 15));
      expect(events, ['loadTimeout']);
      sdkOnLoaded('late-ad');
      expect(disposed, ['late-ad']);
      expect(sdkOnShowed, isNull); // attachCallbacksAndShow 미호출
    });
  });

  // 정상 경로: load → showed → dismissed. terminal 은 dismissed 하나뿐이고
  // 워치독은 아무 것도 발화하지 않는다.
  test('정상 시청 경로는 dismissed 한 번으로 끝난다', () {
    fakeAsync((async) {
      final flow = buildFlow();
      run(flow);
      sdkOnLoaded('ad-1');
      async.elapse(const Duration(seconds: 3));
      sdkOnShowed!();
      async.elapse(const Duration(minutes: 5)); // 긴 시청 — showed 후엔 시한 없음
      sdkOnDismissed!();
      expect(events, ['showStarted', 'dismissed']);
      expect(disposed, ['ad-1']);
    });
  });

  // 시나리오 3/4 (새 구조 형태): 실패 콜백이 오면 terminal 은 loadFailed
  // 정확히 1회 — 워치독과 중복 발화하지 않는다.
  test('onAdFailedToLoad 는 loadFailed 1회로 끝나고 워치독은 발화하지 않는다', () {
    fakeAsync((async) {
      final flow = buildFlow();
      run(flow);
      sdkOnFailedToLoad(StateError('no fill'));
      async.elapse(const Duration(minutes: 10));
      expect(events, ['loadFailed']);
    });
  });

  // 시나리오 5: showed 는 왔지만 dismissed/failedToShow 가 안 온다 → 스피너는
  // 풀렸고(showStarted), 워치독도 해제됐으므로 추가 이벤트는 없다. pendingAd 는
  // 다음 run() 또는 dispose() 에서 정리된다 — 이 잔류를 명시적으로 고정한다.
  test('showed 후 종결 콜백 유실 시 광고는 다음 attempt 시작 때 정리된다', () {
    fakeAsync((async) {
      final flow = buildFlow();
      run(flow);
      sdkOnLoaded('ad-1');
      sdkOnShowed!();
      async.elapse(const Duration(minutes: 10));
      expect(events, ['showStarted']);
      expect(disposed, isEmpty);
      run(flow); // 다음 시도 시작
      expect(disposed, ['ad-1']);
    });
  });

  // 재진입: 시도 중 새 run() 이 시작되면 이전 시도의 늦은 성공은 폐기된다.
  test('새 attempt 시작 후 이전 attempt 의 onAdLoaded 는 폐기된다', () {
    fakeAsync((async) {
      final flow = buildFlow();
      run(flow);
      final firstLoaded = sdkOnLoaded;
      run(flow); // 두 번째 시도 — 세대 증가
      firstLoaded('stale-ad');
      expect(disposed, ['stale-ad']);
      expect(events, isEmpty);
    });
  });

  // dispose(): 플랫폼 dispose 시 워치독 해제 + 보류 광고 정리.
  test('dispose 는 워치독을 멈추고 보류 광고를 정리한다', () {
    fakeAsync((async) {
      final flow = buildFlow();
      run(flow);
      sdkOnLoaded('ad-1');
      flow.dispose();
      expect(disposed, ['ad-1']);
      async.elapse(const Duration(minutes: 10));
      expect(events, isEmpty); // showTimeout 미발화
    });
  });
}
```

### Task D-2: `ad_platform_logic_test.dart` 확장 (시나리오 3·7)

**Files:**
- Modify: `picnic_lib/test/presentation/widgets/vote/store/free_charge_station/ad_platform_logic_test.dart`

`AdPlatform.isNonReportableAdError` 는 `@visibleForTesting static` 이므로 직접 호출한다. 추가 케이스:

```dart
group('isNonReportableAdError — AdMob', () {
  // 시나리오 3: no-fill 계열 LoadAdError 코드는 비보고 분류
  // (LoadAdError 는 SDK final 타입이라 인스턴스 생성이 어려우면 코드 경로 대신
  //  메시지 키워드 경로로 검증한다 — 케이스 작성 시 실제 생성 가능 여부를 먼저
  //  확인하고, 불가하면 아래 메시지 기반 케이스만 남긴다.)
  test('no fill 메시지는 비보고', () {
    expect(
      AdPlatform.isNonReportableAdError('AdMob', StateError('x'), 'No fill.'),
      isTrue,
    );
  });

  // 시나리오 7: 실제 예외 텍스트를 넘기면 진짜 버그는 보고 대상으로 남는다
  test('설정 오류 텍스트는 보고 대상', () {
    expect(
      AdPlatform.isNonReportableAdError(
        'AdMob', StateError('x'), 'Invalid ad unit ID'),
      isFalse,
    );
  });

  // 로드 타임아웃 문구가 비보고(=소진 안내) 로 분류되는 계약을 고정한다.
  // Task B-1 의 onLoadTimeout 이 이 계약에 의존한다.
  test('광고 로드 시간 초과 는 비보고', () {
    expect(
      AdPlatform.isNonReportableAdError(
        'AdMob', TimeoutException('t'), '광고 로드 시간 초과'),
      isTrue,
    );
  });
});
```

- [ ] 작성 → 실패 확인 → (구현 변경 불필요 — 현행 로직 고정용) → green 확인 → Task B-1 커밋에 포함.

### 실행 명령 (전체)

```bash
cd picnic_lib && flutter test test/presentation/widgets/vote/store/free_charge_station/ && flutter analyze lib/presentation/widgets/vote/store/free_charge_station/
```

---

## E. 검증·롤아웃 순서

각 단계는 이전 단계 완료가 전제다. 프로덕션 해제는 마지막이다.

### 단계 0 — 사전 확인 (코드 작성 전)

- [ ] `check-ads-count` 의 **배포 소스와 `admob_disabled_os` 설정 실체 확인**: 이 레포의 `picnic_app/supabase_dev/supabase/functions/check-ads-count/index.ts` 는 `disabled` 로직이 아예 없는 구버전 미러다(이번 계획 수립 중 확인). 실제 배포 소스는 picnic-supabase 레포에 있으므로, 거기서 플래그가 어떤 저장소(테이블/환경변수)에서 읽히는지, 스테이징·프로덕션 각각의 현재 값을 확인해 기록한다.
- **롤백**: 해당 없음(읽기 전용).

### 단계 1 — PR-1: 워치독 + 테스트 (Task B-1, B-4, D-1, D-2)

- [ ] 이 워크트리에서 구현·테스트 후 PR 생성, main 머지. Dart 전용.
- **롤백**: 머지 전이면 PR 닫기. 머지 후면 `git revert` — UI 구좌가 아직 없으므로(단계 2 전) 사용자 영향 없음.

### 단계 2 — PR-2: GA4 상수 + UI 구좌 복원 (Task B-2, B-3)

- [ ] PR-1 머지 후 진행(복원된 버튼이 워치독 없는 코드로 나가는 순서 역전 금지).
- **롤백**: `git revert` — 6fecae2fe 와 같은 UI 제거 상태로 복귀.

### 단계 3 — 스테이징 실검증 (P4·P5 판정)

- [ ] 스테이징 Supabase 의 `admob_disabled_os` 에서 검증 대상 OS 를 제거(또는 빈 값). 변경 전 원래 값을 기록해 둔다.
- [ ] 실기기에서 스테이징 환경으로 실행(재현 보고서와 같은 방식의 `flutter run` — 환경은 스테이징 dart-define). 이때 `picnic_app/config/*.json` 의 `ads.admob.*_rewarded_video_id` 가 스테이징에서 뭘 가리키는지(실광고 유닛인지 Google 테스트 유닛인지) 먼저 확인하고, 실광고 유닛이면 보상 실적립이 발생함을 인지하고 진행한다.
- [ ] **검증 체크리스트**:
  1. 정상 경로: 버튼 탭 → `checkAdsLimit {allowed: true}` → 5종 콜백 로그(로드 완료/표시됨/노출 기록됨/보상 수신/닫힘) 전부 관측 → 코튼캔디 잔액 증가(SSV `callback-admob` 경유) → UI 정상 복귀.
  2. 로드 타임아웃 드릴: 비행기 모드에서 탭 → (즉시 `onAdFailedToLoad` network error 로 끝나면 그것대로 정상 — 그 경우 방화벽/프록시로 광고 요청만 블랙홀시켜 타임아웃을 강제) → 15초에 "광고 소진" 안내 + UI 복귀 확인.
  3. 늦은 콜백 드릴(가능한 범위): 광고 표시 직후 홈 이동/복귀 등으로 콜백 순서를 흔들어 이중 다이얼로그·이중 적립이 없는지 관찰.
  4. GA4 DebugView 에서 `ad_request`/`ad_impression`(`ad_platform=AdMob`) 확인 (P3 판정).
  5. 로드 소요 시간 로그를 모아 15초 타임아웃 값이 적절한지 판단, 필요 시 상수 조정 커밋.
- [ ] 킬스위치 왕복(P5): 플래그 재설정 → 앱에서 "일시적으로 이용 불가" 확인 → 다시 해제 → 정상 서빙 확인.
- **롤백**: 스테이징 플래그를 기록해 둔 원래 값으로 복원.

### 단계 4 — 프로덕션 클라이언트 배포 (OTA)

- [ ] `flutter-release.md` 정책 §3 (OTA 프로세스) 를 처음부터 끝까지 따른다. 요점: main 머지 확인 → `shorebird releases list` 로 현재 프로덕션 전체 버전(예: 1.3.0+130007 — 2026-08-13 실기기 캡처 기준, 배포 시점에 재확인)의 release 존재 확인 → **사용자에게 대상 앱·버전·플랫폼 명시 승인** → iOS·Android 각각 patch → `shorebird patches list` 로 stable 채널·미롤백 확인.
- [ ] 이 시점에는 프로덕션 `admob_disabled_os` 가 아직 걸려 있으므로, 구좌는 보이되 탭하면 "일시적으로 이용 불가" 가 뜬다. 단계 5 를 같은 작업 창에서 바로 잇는다.
- **주의**: main 에 네이티브/에셋 변경(예: PR #156 스플래시류)이 섞여 OTA 부적격이면 정책 §2 에 따라 신규 바이너리로 전환한다 — 이 판단은 배포 시점의 main diff 로 한다.
- **롤백**: 문제 시 이전 상태 코드로 재패치(shorebird 는 태그·바이너리 불변).

### 단계 5 — 프로덕션 서버 플래그 해제 (최종 단계)

- [ ] **사용자 명시 승인 후**, 프로덕션(PROD 프로젝트)의 `admob_disabled_os` 에서 해제 범위를 조정한다. 한 번에 전부 열지 말고 **`android` 먼저 해제**(Sentry ANR 정황의 관측이 쉬운 쪽부터, 캡처 검증도 Android 기기로 수행됨) → 48시간 모니터링 → 이상 없으면 `ios` 해제.
- [ ] 모니터링(P6 기준선 대비): Play Console ANR 비율, Sentry App Hanging/신규 이슈, `transaction_admob` 적립 건수, CS 유입.
- **롤백(가장 빠른 수단)**: `admob_disabled_os = 'ios,android'` 재설정 — 배포 없이 서버에서 즉시 차단되고, 클라이언트는 재현 보고서 §3 에서 실측한 "일시적으로 이용 불가" 정상 종료 경로로 떨어진다.

### 단계 6 — 후속 (비차단)

- [ ] PR-3: PangleMediationAdapter 제거(§C) — 다음 정규 바이너리 릴리스에 편승.
- [ ] 타임아웃 상수를 스테이징·프로덕션 실측으로 보정.

---

## F. 위험과 미확정 사항

정직하게 남긴다. 아래는 이 계획이 **증명하지 못한 것**들이다.

1. **"콜백이 실제로 안 왔다"는 재현으로 증명되지 않았다.** 재현 시도는 서버 `disabled` 게이트에 막혀 `RewardedAd.load()` 에 도달조차 못 했다(재현 보고서 §4·§6). 워치독은 "콜백이 안 와도 사용자가 갇히지 않게" 하는 **방어**이지, 미수신의 근본 원인을 제거했다는 주장이 아니다. 스테이징 실검증(단계 3)이 통과해도 "정상 경로가 동작한다"까지만 증명되고, 원 신고 증상의 재현·해소는 증명되지 않는다.
2. **Dart 워치독은 네이티브 ANR 을 막지 못한다.** Sentry 정황(커밋 `4729cc5d7`, GAD_* culprit 14건·200명+)은 광고 SDK 의 **네이티브 main-thread 블로킹**이다. 워치독 타이머는 Dart 이벤트 루프에서 돌므로 플랫폼 메인 스레드가 SDK 내부에서 블로킹되면 UI 복구는 어차피 지연될 수 있다. AdMob 을 다시 켜면 이 ANR 노출면도 함께 돌아온다 — 그래서 P6 모니터링과 단계 5 의 OS 별 점진 해제가 있다. 또한 해당 Sentry 증거는 구좌 제거 커밋(4월) 이후(5월)의 것이라 신고 사건과의 인과는 미확정이다(조사 보고서 §5).
3. **PangleMediationAdapter notReady 의 원인을 확정하지 못했다.** 'does not implement the initialize() method' 가 Android 의 pag-sdk-ad exclude/치환 트릭 때문인지, 어댑터 3.5.1 자체 문제인지, iOS 쪽도 같은 상태인지 검증하지 못했다(조사 세션에서 WebSearch 차단으로 버전 매트릭스 대조 불가). §C 의 제거 방침은 이 원인 규명 없이도 성립하도록(현재 기여 0 + 중복 연동) 구성했지만, "고치면 얼마의 수익이 회복되는가"는 답하지 못한다.
4. **`check-ads-count` 의 배포 소스·플래그 저장 위치를 이 레포에서 확인할 수 없었다.** 레포 내 미러는 `disabled` 로직이 없는 구버전이다(단계 0 에서 picnic-supabase 레포로 확인 필수). `admob_disabled_os` 라는 키 이름 자체도 태스크 배경 설명에서 온 것으로, 실제 저장 형태(테이블 컬럼인지, 값 포맷이 `'ios,android'` 문자열인지)는 미검증이다.
5. **타임아웃 값(로드 15초·표시 10초)은 측정 근거가 없는 공학적 판단이다.** 너무 짧으면 정상 로드를 끊어 매치율을 깎고(특히 미디에이션 워터폴), 너무 길면 사용자를 오래 세운다. 단계 3 에서 실측으로 보정한다.
6. **로드 타임아웃을 "광고 소진" 안내로 분류한 것은 UX 트레이드오프다.** Pangle 과의 일관성을 택했지만, 타임아웃은 엄밀히는 소진이 아니다. 별도 문구("잠시 후 다시 시도")가 낫다고 판단되면 `onLoadTimeout` 에서 키워드에 안 걸리는 메시지 + 전용 다이얼로그로 바꾸면 된다(구조는 무관).
7. **시나리오 5(showed 후 dismissed/failedToShow 둘 다 유실)의 광고 객체 잔류는 다음 attempt 또는 명시적 `dispose()` 까지 살아남는다.** `onShowed` 는 이미 이 attempt 의 UI terminal 이라(스피너 해제) UI 상으로는 "끝난" 상태지만, 시청 중 광고를 죽이지 않기 위해 리소스 정리는 의도적으로 미룬다. 사용자가 무료충전소에 머무는 동안 RewardedAd 1개 분량의 메모리를 쥐고 있게 되지만, 위젯을 벗어나면 `AdPlatform.dispose()` 경유로 정리된다(cross-review BLOCKER-3, §B 항목 6). 테스트로 동작을 고정해 두었고, 실사용상 문제는 관측되지 않았다(관측 수단도 아직 없다).
8. **스테이징 AdMob 광고 유닛 구성 미확인.** 스테이징 환경 config 의 AdMob ID 가 실유닛인지 테스트 유닛인지에 따라 단계 3 의 검증 강도(실서빙 vs 테스트 광고)가 달라진다. 단계 3 첫 항목에서 확인한다.
9. **iOS 실기기 검증 공백.** 이번 재현·캡처는 Android(Galaxy S20+) 기준이다. iOS 는 스테이징 검증(단계 3)에서 별도 기기로 최소 정상 경로 1회 이상을 확인해야 하며, 못 하면 단계 5 에서 ios 해제를 보류한다.

---

## Self-Review 결과 (writing-plans 체크)

- 스펙 커버리지: 태스크 요구 A~F 전 섹션 존재. §6.2 의 8개 시나리오 전부 채택/부분채택/변형으로 처분 명시. ✅
- 플레이스홀더: "TBD/추후 구현" 없음. 모든 코드 스텝에 실제 코드 포함. ✅
- 타입 일관성: `AdmobShowFlow<T>` 시그니처가 B-1(정의)·D-1(사용) 간 일치. `FreeChargeGa4.platformAdmob` 이 B-2(정의)·B-3(사용) 간 일치. ✅

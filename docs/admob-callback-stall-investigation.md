# 무료충전소 AdMob 콜백 배선 전수 조사

- **조사일**: 2026-08-13
- **기준 커밋**: `main` HEAD (`aef0327b8`), 필요 시 `fix/admob-callback-stall`(`2048fa016`, worktree `/Users/charlie.hyun/orca/workspaces/picnic-app/admob-callback-stall`)와 대조
- **범위**: 읽기 전용 조사. 파일 수정 없음.
- **표기**: `[확인]` = 코드/커밋에서 직접 검증한 사실. `[추정]` = 코드로 뒷받침되지만 실기기 재현으로 확정하지 못한 가설. `[공개자료]` = 학습 지식 기반 일반 정보(이 세션에서 WebSearch 툴이 차단되어 실시간 검증 불가).

---

## 0. 결론 요약

`// AdMob 글로벌 구좌 제거됨`(`free_charge_station.dart:266`)로 이어진 "콜백이 안 들어와서 멈춘다"는 신고는 **코드 구조상 실제로 가능한 결함이었다** `[확인/추정 혼합]`. 핵심 근거:

1. `AdmobPlatform`은 로딩 스피너·버튼 애니메이션을 끄는 유일한 경로를 `FullScreenContentCallback`의 4개 콜백(`onAdShowedFullScreenContent` / `onAdDismissedFullScreenContent` / `onAdFailedToShowFullScreenContent`)과 `onAdFailedToLoad`에 전적으로 위임하고 있다. 이 중 **어느 것도 오지 않으면 UI를 되돌릴 코드 경로가 전혀 없다** — `[확인]` (§1, §2).
2. `RewardedAd.load()`에도, `ad.show()`에도 **타임아웃/워치독이 전혀 없다** — Pangle에는 로드 단계에 5초 `.timeout()`이 있는 것과 대조적이다 — `[확인]` (§5).
3. 커밋 `6fecae2fe`는 `admob_platform.dart`를 전혀 건드리지 않았다. UI 목록에서 버튼만 뺐을 뿐, 콜백 배선의 결함 자체는 **지금도 그대로 남아 있다**(죽은 코드로) — `[확인]` (§3).
4. 독립적인 프로덕션 증거로, 커밋 `4729cc5d7`(2026-05-13)이 Sentry의 App Hanging/ANR 누적 이슈 14건·200명+ 사용자에서 `GAD_*`(AdMob) 스택 프레임이 culprit으로 반복 등장했다고 기록한다 — `[확인, 단 시점 유의]` (§5).
5. 다만 이번 조사에서 발견한 **가장 실증적인 동종 결함**(No-Fill 오분류로 인한 "전부 소진" 오탐 + 다이얼로그 3연속)은 `fix/admob-callback-stall` 브랜치에서 이미 별도로 다뤄지고 있으며, 이는 "무한 로딩"이 아니라 "오류를 소진으로 잘못 표시"에 가깝다 — 신고 문구와 완전히 일치하지는 않는다 `[확인]` (§2 후보 C).

즉 "콜백 미수신 → 영구 정지"는 **코드가 실제로 허용하는 실패 모드**이지만, 이번 조사에서 그 정확한 트리거(어느 콜백이, 어떤 조건에서 안 왔는지)를 재현 로그로 확정하지는 못했다. AdMob 전용 유닛 테스트가 전무해 회귀 검증 자체가 불가능했던 점도 함께 확인했다(§6).

---

## 1. AdMob 콜백 배선 전체 지도

파일: `picnic_lib/lib/presentation/widgets/vote/store/free_charge_station/platforms/admob_platform.dart`

### 1.1 호출 체인

```
showAd()                                    [L48-56]
  └─ safelyExecute(...)                     (ad_platform.dart:262)
       ├─ checkLogin()                      실패 시 dialog, 리턴
       ├─ startLoading()                    setLoading(true) + OverlayLoadingProgress.start()
       ├─ checkAdsLimit('admob')            실패 시 stopAllAnimations() 후 리턴
       └─ action():
            ├─ startButtonAnimation()       [L53] 버튼 펄스 시작
            └─ _loadRewardedAd()            [L58-105]
                 └─ RewardedAd.load(...)    [L66-94] ★타임아웃 없음★
                      ├─ onAdLoaded ────────────────┐ [L70-78]
                      │                              ├─ _setupAdCallbacks(ad) [L107]
                      │                              └─ _showRewardedAd(ad)   [L149]
                      │                                   └─ ad.show(onUserEarnedReward: …) [L175-180]
                      │                                        └─ FullScreenContentCallback  [L110-140]
                      │                                             ├─ onAdShowedFullScreenContent    → stopAllAnimations() [L113]
                      │                                             ├─ onAdDismissedFullScreenContent → stopAllAnimations() + refreshUserProfile + dispose [L117-119]
                      │                                             ├─ onAdFailedToShowFullScreenContent → stopAllAnimations() + dialog [L129-135]
                      │                                             └─ onAdImpression → 로그만, 애니메이션 무관 [L137-139]
                      └─ onAdFailedToLoad ───────────→ stopAllAnimations() + (no-fill이면 dialog) [L79-92]
```

### 1.2 콜백별 배선 상세

| 콜백 | 위치 | 하는 일 | `stopAllAnimations()` 호출 여부 |
|---|---|---|---|
| `onAdLoaded` | `admob_platform.dart:70-78` | `_setupAdCallbacks(ad)` 후 즉시 `_showRewardedAd(ad)` 호출 | **아니오** — 애니메이션은 계속 도는 채로 show 단계로 넘어간다 |
| `onAdFailedToLoad` | `admob_platform.dart:79-92` | 에러 상세 로깅 → `logAdLoadFailure` → `stopAllAnimations()` | **예** (L90) |
| `onAdShowedFullScreenContent` | `admob_platform.dart:111-114` | 로그만 남기고 `stopAllAnimations()` | **예** (L113) |
| `onAdDismissedFullScreenContent` | `admob_platform.dart:115-120` | `stopAllAnimations()` → `refreshUserProfile()` → `_disposeCurrentAd()` | **예** (L117) |
| `onAdFailedToShowFullScreenContent` | `admob_platform.dart:121-136` | 에러 로깅 → `logAdShowFailure` → `stopAllAnimations()` → dispose → dialog | **예** (L129) |
| `onAdImpression` | `admob_platform.dart:137-139` | 로그만 | 아니오 (애니메이션과 무관한 계측용) |
| `onUserEarnedReward` | `admob_platform.dart:176-179` | 로그 + `refreshUserProfile()` | 아니오 (애니메이션과 무관, 보상은 SSV로 별도 처리) |

### 1.3 어떤 콜백이 안 오면 영구 정지인가 — `[확인]`

**`stopAllAnimations()`를 호출하는 코드 경로는 위 표의 5곳(및 `_loadRewardedAd`의 catch, `handleError`)뿐이다.** 이들은 전부 SDK 콜백 또는 예외 처리 안에서만 실행된다. 타이머·워치독·`Future.timeout` 등 콜백과 무관하게 UI를 되돌리는 별도 경로가 **코드베이스 전체에 존재하지 않는다**(§5에서 grep으로 재확인).

따라서:

- `onAdLoaded`가 왔지만 이후 `onAdShowedFullScreenContent`/`onAdDismissedFullScreenContent`/`onAdFailedToShowFullScreenContent` **중 아무것도 오지 않으면** → 로딩 스피너 + 버튼 애니메이션이 영구히 남는다. **가장 유력한 후보.**
- `onAdLoaded`도 `onAdFailedToLoad`도 **둘 다 오지 않으면** (native 쪽에서 요청이 유실되거나 SDK가 콜백 자체를 드롭) → 같은 결과. `RewardedAd.load()`가 반환하는 `Future<void>`는 이 두 콜백과 별개로 관리되므로(§5), 이 경우에도 `_loadRewardedAd`의 `try/await` 블록 자체는 조용히 끝나버릴 수 있다.

---

## 2. "멈춤"의 정확한 정의 후보

### 후보 A — 로딩 스피너 + 버튼 애니메이션 영구 잔류 (가장 유력) `[추정, 코드로 뒷받침]`

- **트리거**: `ad.show()`(`admob_platform.dart:175`) 호출 후 `FullScreenContentCallback`의 3개 콜백이 전부 유실.
- **증상**: `OverlayLoadingProgress`(전체 화면 로딩 오버레이, `ad_platform.dart:104` `startLoading()`에서 시작)와 버튼 펄스 애니메이션(`ad_platform.dart:115-119` `startButtonAnimation()`)이 화면에 그대로 남아 사용자가 아무 것도 누를 수 없는 상태가 된다.
- **되돌리는 유일한 방법**: 화면을 벗어났다 돌아오는 것도 소용없다 — `dispose()`(`admob_platform.dart:196-199`)는 `stopAllAnimations()`를 호출하지만, `AdmobPlatform` 인스턴스는 `AdService._platforms` 맵에 위젯 생명주기 동안 유지되므로(`ad_service.dart:32`) 위젯이 `dispose`되지 않는 한(즉 화면을 나가지 않는 한) 해제되지 않는다. 앱을 강제 종료하거나 화면을 나가야만 풀린다 — 사용자 체감상 "멈춘다"는 표현과 정확히 일치한다.
- **근거 파일**: `admob_platform.dart:107-141`(콜백 등록), `ad_platform.dart:94-132`(`setLoading`/`startLoading`/`stopAllAnimations` 정의).

### 후보 B — `adLoadingStateProvider` 잔류 `[확인 가능, 부수 증상]`

- `setLoading(true)`(`ad_platform.dart:95-98`, `admob` id로 `adLoadingStateProvider`에 기록)는 `stopLoading()`(`ad_platform.dart:108-112`, `stopAllAnimations()` 경유)에서만 `false`로 되돌아간다.
- 후보 A와 동일한 콜백 유실 조건에서 함께 발생한다 — 별개 버그가 아니라 후보 A의 부수 효과. `ad_loading_state.dart:13-19`는 단순 맵이라 자체적으로 만료되지 않는다.

### 후보 C — 오류를 "광고 소진"으로 오분류 + 다이얼로그 중복 (실제 확인된 동종 결함이지만 신고 문구와는 약간 다름) `[확인]`

- `main` 기준 `_loadRewardedAd`의 `catch` 블록(`admob_platform.dart:95-104`)은 `RewardedAd.load()` 호출 **자체**가 동기적으로 예외를 던질 때만 진입한다(설정 오류·SDK 미초기화 등 드문 경로 — 정상적인 no-fill/네트워크 실패는 `onAdFailedToLoad` 콜백으로 오지 이 catch로 오지 않는다).
- 이 catch는 `logAdLoadFailure('AdMob', e, _adUnitId, 'AdMob 광고 로드 실패', s)`를 호출하는데(L88), 하드코딩 라벨 `'AdMob 광고 로드 실패'`가 `ad_platform.dart:370`의 no-fill 키워드 `'광고 로드 실패'`를 **부분 문자열로 포함**한다. 그 결과 `isNonReportableAdError`(`ad_platform.dart:344-384`)가 실제 원인과 무관하게 항상 "소진" 다이얼로그로 분류하고 Sentry 보고도 막는다.
- 이어서 `showSimpleDialog(...)`(L99-101) 후 `rethrow`(L103) → `safelyExecute`의 catch(`ad_platform.dart:280-283`)가 `stopAllAnimations()` 재호출 + `handleError`(`admob_platform.dart:184-193`) 실행 → **동일 실패에 다이얼로그가 최대 3번** 뜬다.
- **이 결함은 이미 `fix/admob-callback-stall` 브랜치에서 실제로 수정됐다** — `git diff main fix/admob-callback-stall -- .../admob_platform.dart`: catch가 `e.toString()`을 넘기도록 바뀌고 dialog+rethrow가 제거됐다. 커밋 메시지(`c7f5d11a0`)는 이를 "감사 중 발견한 Pangle과 동일 결함"이라 명시한다.
- **신고 문구와의 괴리**: 이 경로는 `stopAllAnimations()`가 즉시 호출되므로(L97) 스피너가 "영구히" 남지는 않는다 — 다이얼로그가 여러 번 뜨는 혼란스러운 UX이지 무한 로딩은 아니다. 후보 A의 보완 설명은 될 수 있어도 대체 설명은 아니다.

### 후보 D — 다이얼로그 자체가 안 뜨는 경로 `[확인, 발생 가능하지만 저빈도]`

- `showSimpleDialog(...)` 호출부 대부분이 `if (context.mounted && !isDisposed)`로 감싸여 있다(예: `admob_platform.dart:98`, `131`). 사용자가 광고 대기 중 화면을 빠르게 이탈하면 `context.mounted`가 `false`가 되어 실패/성공 다이얼로그가 조용히 스킵된다 — 다만 이 경로에서도 `stopAllAnimations()` 자체는 실행되므로(가드 이전에 위치) 스피너는 풀린다. "멈춤"보다는 "무응답 실패"에 가깝다.

**결론**: 신고된 "콜백이 안 들어와서 멈춘다"는 문구에 코드 구조상 가장 정확히 대응하는 것은 **후보 A** — `ad.show()` 이후 `FullScreenContentCallback` 3종 중 아무것도 오지 않는 경우다.

---

## 3. 커밋 `6fecae2fe` diff 분석 `[확인]`

```
refactor: 무료 충전소 AdMob 글로벌 구좌 제거, 내부 숏폼을 글로벌 #1로 승격
Author: Charlie Hyun, 2026-04-10
1 file changed, 5 insertions(+), 63 deletions(-)
 free_charge_station.dart | 68 +++---------------------------------
```

- **변경 파일은 `free_charge_station.dart` 단 하나.** `admob_platform.dart`, `ad_platform.dart`, `ad_service.dart`는 **전혀 건드리지 않았다.**
- **제거된 것**: `_buildAdItems()`에서 `id: 'admob'` `ChargeStationItem` 생성 블록(`platformType: AdPlatformType.admob`, `onPressed: () => _adService.getPlatform('admob')?.showAd()`), 그리고 "내부 숏폼을 글로벌 #2로 재배치"하던 인덱스 재정렬 로직 63줄(글로벌 아이템 위치 탐색 → 삽입 → 다음 아이템 제거의 수작업 배열 조작).
- **남은/추가된 것**: 내부 숏폼(`internal-shortform`)이 처음부터 글로벌 픽 #1 자리를 직접 차지하도록 단순화(5줄). `import 'package:google_mobile_ads/google_mobile_ads.dart';` 임포트도 함께 제거됨(더 이상 이 파일에서 AdMob 타입을 안 쓰므로).
- **`// AdMob 글로벌 구좌 제거됨`** 주석은 이 커밋에서 추가됐다(`free_charge_station.dart:266`, 구 위치는 diff상 "Unity 플랫폼 제거됨" 주석 자리를 대체).
- **결과적으로 `AdmobPlatform`은 죽은 코드가 됐지만 삭제되지 않았다**: `ad_service.dart:32`의 `'admob': AdmobPlatform(...)` 등록, `ad_service.dart:85-89`의 `isPlatformAvailable('admob')` 판정 로직, `ad_types.dart:1`의 `AdPlatformType.admob` enum 값이 모두 그대로 남아 있다. `AdService.initializeAllPlatforms()`(`ad_service.dart:46-76`)는 지금도 `isPlatformAvailable('admob')`이 `true`면 `AdmobPlatform.initialize()`(광고 ID 세팅만, `_adUnitId` 캐시)를 계속 호출한다 — 단 `showAd()`를 부르는 UI 버튼이 없으므로 로드/표시 단계까지는 절대 진입하지 않는다.
- **커밋 메시지에 결함에 대한 설명 없음**: 커밋 메시지·diff 어디에도 "콜백" "멈춤" "버그" 관련 언급이 없다 — 순수 리팩터링 커밋으로만 기록돼 있다. 신고 배경(콜백 미수신)은 이 조사 태스크의 배경 설명에서만 확인되며, 저장소 커밋 이력 자체에는 해당 서술이 없다.

---

## 4. `google_mobile_ads` 패키지 버전과 알려진 콜백 이슈

- **버전(확인)**: `picnic_lib/pubspec.yaml:24` → `google_mobile_ads: ^6.0.0`, `picnic_lib/pubspec.lock:1200-1207` → 실제 고정 버전 `6.0.0` (sha256 `a4f59019f2c32769fb6c60ed8aa321e9c21a36297e2c4f23452b3e779a3e7a26`). `picnic_app/pubspec.lock`은 이를 `picnic_lib` 경유 transitive dependency로 동일 버전 사용.

- **`[공개자료]` — WebSearch 툴 접근이 이번 세션에서 차단되어 실시간 검색으로 재검증하지 못했다. 아래는 학습 데이터 기반 일반 지식이며, 6.0.0 changelog와 1:1 대조는 못했다는 점을 감안해서 읽어야 한다.**
  - `google_mobile_ads`(Flutter 공식 Google Mobile Ads SDK 플러그인)는 네이티브 GMA SDK(Android/iOS)를 플랫폼 채널로 감싸는 구조이며, **`RewardedAd.load()`가 반환하는 `Future<void>`는 로드 성공/실패 결과와 직접 연결돼 있지 않다** — 실제 결과는 `RewardedAdLoadCallback`의 `onAdLoaded`/`onAdFailedToLoad`로만 전달된다. 즉 `Future`가 완료돼도 광고가 로드됐다는 보장이 없고, 반대로 이 콜백들이 플랫폼 채널 메시지 유실·앱 백그라운드 전환·네이티브 측 예외로 인해 아예 호출되지 않는 사례가 GMA SDK 사용자들 사이에서 반복적으로 보고돼 왔다.
  - GMA(Google Mobile Ads) 네이티브 SDK 자체는 **광고 요청에 대한 클라이언트 측 타임아웃을 제공하지 않는다** — 이는 Google 공식 문서에서도 "요청이 언제 끝날지 SDK가 보장하지 않으므로 필요하면 앱이 자체 타임아웃을 구현하라"는 취지로 안내된 바 있다(일반 지식, 버전 6.0.0 한정 확인 아님).
  - 미디에이션(중개) 어댑터가 개입하는 경우 어댑터 SDK 내부에서 콜백이 드롭되는 사례도 보고 사례로 알려져 있다. 이 레포에서 AdMob 미디에이션을 실제로 구성했는지는 `bf2d13c38 feat: AdMob 미디에이션 및 UMP GDPR 동의 관리 구현` 커밋명으로 미루어 짐작되나, 이번 조사에서 미디에이션 어댑터 목록까지는 확인하지 않았다.
  - **결론**: "6.0.0에 특정된 알려진 버그"를 이번 세션에서 공식 이슈 트래커·changelog로 확정하지 못했다 — 이는 확인 실패이지 부재 확인이 아니다. 다만 "콜백이 안 올 수 있다"는 것은 이 패키지의 **설계상 알려진 특성**이며, Pangle 쪽에 이미 5초 로드 타임아웃 방어 코드가 존재한다는 사실(§5) 자체가 팀이 이 문제 부류를 이미 인지하고 있었다는 정황 증거다.

---

## 5. 타임아웃/워치독 부재 여부 `[확인]`

### Pangle의 방어 코드 (대조군)

`picnic_lib/lib/presentation/widgets/vote/store/free_charge_station/platforms/pangle_platform.dart:35-51`

```dart
class PangleClaimPreflight {
  const PangleClaimPreflight({
    ...
    this.loadTimeout = const Duration(seconds: 5),
    ...
  });
  ...
}
```

`pangle_platform.dart:75-79`에서 실제 적용:

```dart
final loaded = await load(
  placementId,
  claim.mediaExtra(ownerUserId),
).timeout(loadTimeout, onTimeout: () => false);
```

→ **로드 단계**에 명시적 5초 타임아웃이 있고, 타임아웃 시 `false`를 반환해 `_loadAndShowAd()`(`pangle_platform.dart:170-217`)의 실패 분기(`stopAllAnimations()` 포함, L214)로 정상 합류한다. 단, Pangle에도 **show 단계**(`PangleAds.showRewardedAd()`, `pangle_platform.dart:186`) 자체에는 타임아웃이 없다 — 참고로만 기록.

### AdMob에 대응물이 있는가 — 없다

`admob_platform.dart` 전체 및 `ad_platform.dart` 전체를 검색한 결과:

- `.timeout(` 호출이 **admob_platform.dart에 0건**.
- `Timer(` / `Timer.periodic(` 등 워치독 타이머가 **admob_platform.dart에 0건** (참고로 Pangle에는 `_impressionTimeout`이라는 별개 목적의 30초 타이머가 있다 — `pangle_platform.dart:103-104, 240-243` — 이것도 "노출 계측 리스너 정리용"이지 로딩 UI 워치독은 아니다).
- `RewardedAd.load(...)`(L66-94) 호출에 `.timeout()` wrapper 없음 — `await` 후 성공/실패는 전적으로 콜백에 위임.
- `ad.show(...)`(L175-180) 호출에도 타임아웃 없음 — `FullScreenContentCallback` 콜백에 전적으로 위임.

→ **AdMob 경로는 로드·표시 두 단계 모두에서 콜백 도착을 무기한 신뢰한다.** Pangle의 로드 단계 5초 타임아웃과 명확히 비대칭이며, 이 비대칭 자체가 §2 후보 A(영구 로딩)를 코드 구조적으로 가능하게 만드는 직접 원인이다.

### 정황 증거 — Sentry App Hanging/ANR

`4729cc5d7 fix(sentry): App Hanging / ANR 의 광고 SDK culprit filter (#29)` (2026-05-13, `6fecae2fe`보다 1개월 뒤):

> Sentry App Hanging / ANR 누적 이슈들 (PICNIC-APP-45E 99u, 45S 52u, 56S 7u, 49J 41u 등 14건 합 200+ users)의 culprit 대부분이 광고 SDK의 main-thread blocking — Pangle (PAG*), Tapjoy (TJ*), **AdMob (GAD_*)**, Branch (BranchLogger).

- 이 커밋은 애플리케이션 코드가 아니라 **네이티브 SDK 내부**의 main-thread 블로킹이 원인이라 진단하고, 해결책으로 Sentry 노이즈 필터만 추가했다(앱 로직 수정 아님) — `[확인]`.
- **시점 유의**: 이 커밋은 `6fecae2fe`(4월 10일) **이후**(5월 13일)이므로 6fecae2fe의 직접적 근거 자료였다고 단정할 수 없다. 다만 `MobileAds.instance.initialize()`가 UI 버튼 유무와 무관하게 앱 시작 시 항상 실행되므로(`main_initializer.dart:227-236`, `admob_platform.dart:14` 주석에서도 명시) `GAD_*` culprit의 ANR이 버튼 제거 이후에도 계속 관측될 수 있는 구조다 — `[추정]`. 즉 이 데이터는 "AdMob SDK가 실제로 메인스레드를 블로킹하는 사례가 프로덕션에 존재한다"는 것의 독립 증거는 되지만, "그것이 버튼 클릭 후 로딩 스피너 무한 정지의 그 사건과 동일 사건인지"까지는 이번 조사로 연결하지 못했다.

---

## 6. 반례·테스트 설계 — 이 결함을 고정할 단위 테스트 시나리오

### 6.1 현재 테스트 커버리지 — `[확인]`

- `admob_platform_test.dart`(또는 이에 준하는 `AdmobPlatform` 전용 테스트 파일)는 **레포 전체에 존재하지 않는다**(`find` 결과 0건).
- 기존 `ad_platform_test.dart` / `ad_platform_logic_test.dart`는 `'admob'`이라는 **문자열 id**를 예시로 쓸 뿐, `AdmobPlatform` 클래스나 `RewardedAd`/`FullScreenContentCallback` 콜백 배선을 실제로 호출·검증하지 않는다(주로 `isNonReportableAdError`, `isDisposed` 가드, `checkAdsLimit` 응답 파싱 등 `AdPlatform` 공통 로직 테스트).
- 즉 **후보 A(영구 로딩)든 후보 C(오분류)든, 지금 이 코드에 대한 회귀 가드가 전혀 없다** — 두 결함 모두 테스트 스위트를 통과한 채로 존재할 수 있고 실제로 그래 왔다.

### 6.2 제안 시나리오 (모두 현재 미존재, 신규 작성 필요)

`google_mobile_ads`는 콜백 객체가 `final` 필드로 전달되는 구조라 순수 유닛 테스트로 SDK를 완전히 모킹하기는 까다롭다. 아래는 **AdmobPlatform의 상태 관리 로직을 분리 가능한 형태로 리팩터링한다는 전제** 하의 시나리오다(현재는 `_loadRewardedAd`/`_setupAdCallbacks`가 private이라 직접 단위 테스트가 어렵다는 점 자체도 함께 지적한다).

1. **`onAdLoaded` 이후 `show` 단계 콜백이 전혀 안 오는 경우** — `stopAllAnimations()`가 호출되지 않고 `adLoadingStateProvider['admob']`이 `true`로 남는지 확인. (후보 A 직접 재현 — 현재 가장 중요한 공백)
2. **`onAdLoaded`도 `onAdFailedToLoad`도 안 오는 경우** — `RewardedAd.load()`의 `Future`가 완료된 뒤에도 로딩 상태가 무기한 유지되는지 확인. 타임아웃 도입 후에는 N초 뒤 `false`/오류로 귀결하는지 확인.
3. **`onAdFailedToLoad`가 no-fill 계열 코드(1/2/3)로 오는 경우** — "소진" 다이얼로그 1회만 뜨고 `stopAllAnimations()`가 정확히 1회 호출되는지 (현재 정상 동작 확인용 회귀 가드).
4. **`RewardedAd.load()` 자체가 동기 예외를 던지는 경우** — `main` 기준 다이얼로그가 몇 번 뜨는지 카운트(현재는 최대 3회 — 후보 C 고정 가드). `fix/admob-callback-stall` 반영 후에는 1회로 줄었는지 검증하는 비교 테스트로 전환.
5. **`onAdShowedFullScreenContent`는 왔지만 `onAdDismissedFullScreenContent`/`onAdFailedToShowFullScreenContent`가 둘 다 안 오는 경우** — 스피너는 꺼지지만(§L113) 버튼이 "닫힘/보상" 상태로 전이하지 못한 채 `_currentAd`가 dispose되지 않고 남는지 확인. `_disposeCurrentAd()`가 이 경로에서 호출되지 않으므로 메모리/상태 누수 후보로 별도 기록할 가치가 있다.
6. **`context.mounted == false` 시점에 콜백이 오는 경우** — 각 콜백의 `if (context.mounted && !isDisposed)` 가드가 다이얼로그만 막고 `stopAllAnimations()`는 여전히 실행되는지(현재 코드는 `stopAllAnimations()`가 가드 밖에 있는 콜백과 안에 있는 콜백이 섞여 있어 일관성 확인 필요 — 예: L113 `stopAllAnimations()`는 가드 없이 무조건 실행, L129-135는 dialog만 가드).
7. **`isNonReportableAdError` 키워드 충돌 회귀 가드** — `logAdLoadFailure`/`logAdShowFailure`에 넘기는 메시지가 하드코딩 라벨이 아니라 실제 예외 텍스트인지(§2 후보 C, 이미 `fix/admob-callback-stall`에 유사 테스트 존재 — `ad_platform_logic_test.dart` 재작성분 참고).
8. **워치독 타임아웃 도입 시 리소스 정리 검증** — 타임아웃으로 강제 종료했는데 그 뒤에 실제 콜백이 뒤늦게 도착하는 race condition에서 이미 disposed된 ad를 이중 dispose하거나 이미 닫힌 context에 접근하지 않는지.

### 6.3 근본 수정 방향 제안 (조사 범위 밖이지만 기록)

Pangle과 동일한 패턴 — `RewardedAd.load(...)`를 `.timeout(Duration(seconds: N), onTimeout: ...)`으로 감싸고, `ad.show(...)` 이후에도 별도 워치독 `Timer`를 두어 N초 내 `FullScreenContentCallback` 중 하나도 안 오면 강제로 `stopAllAnimations()` + 에러 다이얼로그로 귀결시키는 것이 §2 후보 A를 구조적으로 차단하는 가장 직접적인 방법이다. 이번 조사는 읽기 전용이라 구현하지 않았다.

---

## 부록 — 참고 파일·라인 인덱스

| 항목 | 파일:라인 |
|---|---|
| AdMob 콜백 전체 정의 | `picnic_lib/lib/presentation/widgets/vote/store/free_charge_station/platforms/admob_platform.dart:1-200` |
| 공통 로딩/애니메이션 로직 | `picnic_lib/lib/presentation/widgets/vote/store/free_charge_station/ad_platform.dart:94-132`, `262-284` |
| No-Fill 키워드 판정(충돌 지점) | `picnic_lib/lib/presentation/widgets/vote/store/free_charge_station/ad_platform.dart:344-384` (특히 L370) |
| UI에서 admob 버튼 제거 지점 | `picnic_lib/lib/presentation/widgets/vote/store/free_charge_station/free_charge_station.dart:266` |
| admob 플랫폼 등록(죽었지만 존재) | `picnic_lib/lib/presentation/widgets/vote/store/free_charge_station/ad_service.dart:32, 85-89` |
| Pangle 로드 타임아웃(대조군) | `picnic_lib/lib/presentation/widgets/vote/store/free_charge_station/platforms/pangle_platform.dart:35-51, 75-79` |
| AdMob SDK 전역 초기화(버튼과 무관) | `picnic_lib/lib/core/utils/main_initializer.dart:227-236` |
| google_mobile_ads 버전 고정 | `picnic_lib/pubspec.yaml:24`, `picnic_lib/pubspec.lock:1200-1207` |
| 제거 커밋 | `6fecae2fe0e7744c330e4859a9b86daba2e60b45` |
| ANR/App Hanging 정황 증거 | `4729cc5d7c7c346f7bb6a5977fd8dd0bee899e66` |
| 동종 결함(No-Fill 오분류) 이미 수정 중 | branch `fix/admob-callback-stall`, 커밋 `71fd248d3`, `c7f5d11a0`, `2048fa016` |

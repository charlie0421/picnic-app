# picnic-app Sentry 노이즈 정리 + 45E ANR 관측성 — 설계

- **날짜**: 2026-07-08
- **브랜치**: `fix/sentry-app-noise-and-anr-obs`
- **레포**: picnic-app (`picnic_lib` 중심)
- **출처**: 2026-07-08 앱 Sentry 트리아지 (상위 12개 이슈 병렬 조사 + 소스 교차검증). 리포트: `/Users/charlie.hyun/Repositories/picnic-all/picnic-app-sentry-triage-2026-07-08.html`

## 배경 / 문제

앱 Sentry 대시보드가 **예상된/외부/이미수정된 이벤트**로 뒤덮여 실제 신호를 가린다. 조사 결과 실제로 코드 조치가 필요한 건 아래 4건이며, 이 중 3건은 Sentry 노이즈 억제(오탐 리포팅 제거), 1건(45E)은 심볼화가 구조적으로 불가능해 **관측성 태깅**이 정답이다.

교차검증에서 드러난 사실:
- **4RJ**: 실제 이벤트는 `AuthApiException(message: 가입 시도가 너무 많습니다..., statusCode: 429, code: unknown)` — 429 rate-limit. 그런데 `app_initializer_helper.dart:202-203` 주석이 `user_banned` 필터를 "PICNIC-APP-4RJ"로 **오라벨**하고 있어, 실제 4RJ(429)는 어떤 필터에도 안 걸린다.
- **4GW**: 실제 이벤트는 `AuthApiException(message: Refresh token is not valid, statusCode: 400, code: validation_failed)`. 기존 필터(`:196-200`)는 `Invalid Refresh Token: Already Used` / `Refresh Token Not Found` 리터럴 2종만 잡아 이 변형이 샌다.
- **4ZX**: `attendance-check` 엣지함수가 중복 출석을 **HTTP 409** `{error:{code:ALREADY_CHECKED}}`로 응답. `_invokeAndParse`의 graceful 분기(`:237-243`)는 2xx 응답 body만 처리하므로, 409는 그 전에 `supabase.functions.invoke`가 `FunctionException`을 throw → `checkIn`의 catch(`:145`)가 **정상 중복탭을 에러로 Sentry 보고**한다. 사용자 영향 0, 순수 로그 노이즈.
- **45E**: all-system Android ANR. 프레임이 `dlc.vmcode`(Shorebird OTA 패치 Dart 코드)라 Sentry가 심볼화할 debug-id가 없고, base 릴리스 Dart 심볼 파이프라인(`--split-debug-info`/`sentry_dart_plugin`)도 미구성. **심볼화는 구조적으로 불가.** 게다가 현재 `shouldFilterSentryEvent`(`:235-239`)가 이 all-system ANR을 **전량 드롭**해 스스로 신호를 눈감고 있다.

## 목표 / 비목표

**목표**
1. 4RJ·4GW·4ZX의 오탐/노이즈 리포팅을 소스 레벨에서 제거한다.
2. 45E를 "심볼 없이도 화면·라우트로 특정 가능"하게 만들고, 볼륨을 다시 측정 가능하게 한다.
3. 모든 변경은 picnic-app 클라이언트 한정. 백엔드/UX/제품 흐름 변경 없음.
4. Sentry 필터 로직은 순수·결정론·테스트 가능 상태를 유지한다 (`picnic_app_sentry_filter_policy` 준수: 필터 변경 시 helper test 동반).

**비목표 (후속으로 분리)**
- 9E(Pangle 텔레메트리 500): `app_initializer.dart:113 captureNativeFailedRequests=false`로 **이미 해결**. 코드 변경 없음. Sentry에서 resolve만.
- Sentry 하우스키핑(5CX·4EN·4ED·435·4ZY·T2·9E resolve/mute): 수동 운영 작업.
- 4RJ 로그인 UX 친절 메시지, Supabase Auth rate-limit 임계값(CGNAT 정상유저 차단 여부) 데이터 조사.
- 45E 성능 근본수정: vote/pic 리스트 `fromJson` 파싱을 background isolate로 이관 (`compute()` 레포 전체 0건). pic-chart OOM은 PR#54로 이미 완화·라이브 → P0 관측성으로 잔존 볼륨 측정 후 판단.
- 45E hot-path 커스텀 브레드크럼(P0-d): 제품 provider 다수 접촉 → 성능 작업과 함께.
- base 릴리스 Dart 심볼화 복구(`--split-debug-info`): patched 사용자에겐 무효라 45E 직접 기여도 낮음.

## 설계

전부 2개 소스 파일 + 2개 테스트 파일에 집중된다:
`picnic_lib/lib/core/utils/app_initializer_helper.dart`,
`picnic_lib/lib/core/utils/app_initializer.dart`,
`picnic_lib/lib/presentation/providers/attendance_provider.dart`,
그리고 각 테스트. C1/C2는 navigator observer·navigation_provider 접점 포함.

### A. Sentry 필터 (`app_initializer_helper.dart`)

`shouldFilterSentryEvent`는 순수·정적·부작용 없음을 유지한다.

**A1 — 4RJ: 429 auth rate-limit 필터 + 오라벨 정정**
- 새 블록 추가:
  ```dart
  // Auth rate limit (PICNIC-APP-4RJ). GoTrue/anti-abuse 가 로그인·가입 시도
  // 폭주에 429 를 반환하는 정상 rate-limit. self-recovering("잠시 후 다시").
  // statusCode 매칭이라 로케일(메시지 번역)과 무관하게 견고.
  if (exceptionType == 'AuthApiException' &&
      exceptionValue.contains('statusCode: 429')) {
    return true;
  }
  ```
- `:202-203` 주석에서 잘못된 "(PICNIC-APP-4RJ)" 라벨 제거. 그 블록은 실제 `user_banned` 필터이므로 라벨만 바로잡는다(로직 불변).

**A2 — 4GW: refresh-token 필터 확장**
- `:196-200`의 리터럴 2종 매칭을 케이스-무관 단일 매칭으로 대체:
  ```dart
  // Supabase refresh token 회전/만료 노이즈 (PICNIC-APP-4GW / 56J).
  // 모든 변형(Already Used / Not Found / "Refresh token is not valid"
  // (validation_failed)) 을 포섭. 전부 self-recovering(재로그인/세션 재발급).
  if (exceptionType == 'AuthApiException' &&
      exceptionValue.toLowerCase().contains('refresh token')) {
    return true;
  }
  ```
  (기존 2종은 이 조건의 부분집합이라 회귀 없음.)

**과필터 방지**: `Invalid login credentials`(400) 같은 진짜 auth 에러는 위 어느 조건에도 안 걸려 그대로 Sentry로 간다 — 네거티브 테스트로 못박는다.

### B. 출석 409 처리 (`attendance_provider.dart`)

`_invokeAndParse`의 `supabase.functions.invoke('attendance-check')` 호출을 `try / on FunctionException`으로 감싼다:
```dart
try {
  final response = await supabase.functions.invoke('attendance-check', ...);
  // ... 기존 2xx 파싱 (raw==null 체크, jsonDecode, success/ALREADY_CHECKED, data 반환)
} on FunctionException catch (e) {
  if (e.status == 409 &&
      _extractErrorCode(e.details) == 'ALREADY_CHECKED' &&
      onAlreadyChecked != null) {
    onAlreadyChecked();      // todayChecked=true 세팅
    return const {};         // checkIn: data.isEmpty -> return null
  }
  rethrow;                    // 그 외 FunctionException 은 기존 checkIn/fetchStatus catch 로
}
```
- `_extractErrorCode(dynamic details)`: `details`가 `Map`이면 `details['error']?['code']`, `String`이면 `jsonDecode` 후 동일 추출, 실패/기타는 `null`. (supabase_flutter 버전별 `details` 타입 편차 방어)
- **불변식**: 401/403 세션갱신 재시도, anti-abuse(429→`mapToAntiAbuseException`), 진짜 5xx는 전부 `rethrow`로 기존 `checkIn`/`fetchStatus` catch가 그대로 처리. 오직 409+ALREADY_CHECKED만 가로챈다. `fetchStatus`는 `onAlreadyChecked`를 넘기지 않으므로 영향 없음(rethrow).

### C. 45E ANR 관측성

**C1 — SentryNavigatorObserver 등록**
- 현재 `AppAnalytics.buildNavigatorObservers()`(`firebase_analytics_utils.dart:11`)는 `appRouteObserver` + `FirebaseAnalyticsObserver`만 반환 → Sentry는 라우트 브레드크럼을 전혀 못 받는다.
- 리스트에 `SentryNavigatorObserver(setRouteNameAsTransaction: true)` 추가. 모든 이벤트(ANR 포함)에 마지막 라우트가 브레드크럼/트랜잭션으로 붙는다.

**C2 — current_screen scope 태그**
- picnic은 커스텀 portal/page 네비게이션을 쓰므로 순수 `Navigator` 라우트만으론 부족하다. `navigation_provider`가 이미 `currentScreen`을 상태로 추적(`:29,44,68,91,115`)하므로, 화면 변경 지점에서 `Sentry.configureScope((s) => s.setTag('current_screen', name))`를 호출한다. (`app_initializer.dart:178-187`의 `shorebird.patch_number` 태그 패턴 재사용.)
- 실패해도 앱 흐름을 막지 않도록 try/catch 또는 fire-and-forget.

**C3 — all-system ANR 드롭을 결정론적 샘플 유지로 완화**
- 현재 `shouldFilterSentryEvent`(`:235-239`)가 all-system ANR을 전량 드롭한다. 순수성을 유지하면서 ~10%만 남기기 위해:
  1. 판별 로직을 순수 헬퍼로 추출: `static bool isAllSystemAnr(String exceptionType, List<bool> stackFrameInApp)` = `exceptionType=='ApplicationNotResponding' && stackFrameInApp.isNotEmpty && !stackFrameInApp.any((x)=>x)`.
  2. 결정론적 샘플 헬퍼 추가: `static bool shouldSampleKeep(String seed, double rate)` — `seed`의 안정적 해시를 `[0,1)`로 매핑해 `< rate`면 true. (`Math.random` 미사용 → 순수·테스트 가능. `seed`=event id라 이벤트마다 균일 분포.)
  3. `shouldFilterSentryEvent`에서 all-system ANR **무조건 드롭 분기를 제거**한다(더 이상 여기서 드롭하지 않음).
  4. `app_initializer.dart`의 `beforeSend`에서 샘플 적용:
     ```dart
     final shouldFilter = AppInitializerHelper.shouldFilterSentryEvent(...);
     if (shouldFilter) return null;
     // all-system ANR (45E): 심볼 없는 OS 사후 ANR. 화면/라우트 태그로만
     // 유의미 → 볼륨 측정용으로 ~10% 결정론적 샘플만 유지, 나머지는 드롭.
     if (AppInitializerHelper.isAllSystemAnr(exceptionType, stackFrameInApp) &&
         !AppInitializerHelper.shouldSampleKeep(
             event.eventId.toString(), 0.10)) {
       return null;
     }
     return event;
     ```
- 이유: C1/C2로 route·screen 태그가 붙기 시작하면 45E가 "어느 화면 + 기기 + 브레드크럼"을 갖게 되어 심볼 없이도 분류 가능. 전량 드롭이면 PR#54 이후 잔존 볼륨을 측정조차 못 한다. 10%면 대시보드 홍수 없이 화면별 group-by에 충분(최근 ~13/day → ~1.3/day 샘플).

## 테스트 (TDD)

**`app_initializer_helper_test.dart`** (필터 정책상 동시 수정 필수)
- 4RJ: `AuthApiException` + `statusCode: 429` (한국어 메시지 포함) → `true`.
- 4GW: `Refresh token is not valid`, `Invalid Refresh Token: Already Used`, `Refresh Token Not Found` 3종 → `true`.
- 네거티브: `AuthApiException` + `Invalid login credentials`(400) → `false`. `AuthApiException` + `statusCode: 400`(비 refresh, 비 429) → `false`.
- `isAllSystemAnr`: all-system(inApp 전부 false) → `true`; in-app 프레임 하나라도 있으면 → `false`; 빈 프레임 → `false`.
- `shouldSampleKeep`: 결정론(같은 seed·rate → 같은 결과); `rate=0.0`→항상 false, `rate=1.0`→항상 true; 여러 seed에 대해 대략 rate 비율 유지(경계는 결정론 값으로 픽스처 고정).
- 기존 all-system ANR "필터됨(true)" 단언 테스트는 **새 계약(헬퍼가 더 이상 드롭 안 함)에 맞게 갱신** — `isAllSystemAnr` true + `shouldFilterSentryEvent` false로 분리 검증.

**`attendance_provider` 테스트** (기존 테스트 유무 확인; 없으면 `_invokeAndParse`/`checkIn` 경로 테스트 신설)
- 409 `{success:false,error:{code:ALREADY_CHECKED}}` (Map details, String(JSON) details 양쪽) → `onAlreadyChecked` 호출·`checkIn`이 `null` 반환·`todayChecked=true`·**Sentry 미보고**.
- 409 with `details` 다른 code → rethrow → 기존 에러 경로.
- 401/403 → 세션갱신 재시도 경로 불변(회귀 가드).

## 리스크 / 완화

- **A1 `statusCode: 429` 문자열 매칭**: AuthApiException 값 렌더 포맷 의존. 429 auth는 항상 rate-limit이라 과필터 위험 낮음. 포맷이 바뀌면 테스트가 잡도록 실제 이벤트 문자열을 픽스처로 사용.
- **C3 헬퍼 계약 변경**: 기존 테스트 갱신 필요(위에 명시). beforeSend 통합은 `app_initializer.dart`에서만.
- **C2 provider 접촉**: 관측성 훅만 추가, 로직 불변. 실패가 앱을 막지 않도록 방어.
- **검증**: `flutter test`로 helper·provider 테스트 통과 확인. 필터/핸들링은 런타임 부작용이 작아 단위 테스트로 충분하나, C1/C2는 앱 실행 시 Sentry 태그가 실제로 붙는지 스모크 확인 권장.

## 배포

- 단일 PR: `fix/sentry-app-noise-and-anr-obs`. 관련 변경(전부 Sentry 위생)을 한 커밋군으로 번들.
- 머지 후 Sentry에서 5CX·4EN·4ED·435·4ZY·T2·9E resolve/mute(수동). 45E는 C3 배포 후 화면별 볼륨 재측정.

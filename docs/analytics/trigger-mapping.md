# GA4 택소노미 트리거 지점 매핑 조사 보고서

**기준 문서**: `docs/analytics/ga4-event-taxonomy.md`  
**대상 저장소**: `/Users/charlie.hyun/orca/workspaces/picnic-app/텍소노미` (`picnic_lib`, `picnic_app`)  
**조사 일시**: 2026-08-07  
**조사 성격**: 읽기 전용 코드베이스 매핑 (코드 수정 없음)

---

## 1. 개요 및 요약

Picnic 모바일 앱 프로젝트 내 10개 GA4 이벤트에 대하여 실제 코드 위치, 접근 가능한 파라미터 데이터 경로, 분기 조건 및 중복 발송 리스크를 정밀 분석하였다.

---

## 2. GA4 이벤트별 매핑 상세

### 1. `login` (로그인 완료 시점)

- **권장 호출 지점**: `picnic_lib/lib/core/utils/app_initializer.dart:759`
  - `setupSupabaseAuthListener(WidgetRef ref)` 내 `if (data.event == AuthChangeEvent.signedIn)` 조건절
  - **이유**: Supabase 인증 상태 변경 리스너에서 로그인 성공 이벤트가 수신되는 단일 진입점이며, 사용자 세션 정보 및 앱 설정에 접근 가능함.
  - *(보조/선택 지점)*: `picnic_lib/lib/presentation/pages/signup/login_page.dart:372` (`_handleSuccessfulLogin([String? provider])`)
- **파라미터별 값 출처**:
  - `method`: `user.appMetadata['provider']` (예: `'apple'`, `'google'`, `'kakao'`) 또는 `FlutterSecureStorage`에 저장된 `last_provider` / `user.identities?.first.provider`.
  - `selected_language`: `ref.read(appSettingProvider).language` (설정값 미존재 시 `PlatformDispatcher.instance.locale.languageCode`).
- **성공/실패 분기**: Supabase auth 통신 성공 후 `signedIn` 이벤트 수신 시점에만 발송됨. 실패 시 예외가 던져져 발송되지 않음.
- **신규가입 구분 및 중복 발송 위험**:
  - `user.createdAt` (생성시각)과 `user.lastSignInAt` (최종로그인시각)을 비교하여, 시각 차이가 5초 이상인 경우에만 `login` 이벤트로 분류함.
  - 앱 재시작 시 자동 세션 복구로 인한 `signedIn` 발생 시 중복 발송을 막기 위해 1회 발송 플래그 또는 세션 체크가 필요함.

---

### 2. `sign_up` (회원가입 완료 시점)

- **권장 호출 지점**: `picnic_lib/lib/core/utils/app_initializer.dart:759`
  - `setupSupabaseAuthListener(WidgetRef ref)` 내 `if (data.event == AuthChangeEvent.signedIn)` 조건절
  - **이유**: 최초 신규 계정 가입 완료 직후 Supabase auth 세션이 생성되는 공통 수신부임.
- **파라미터별 값 출처**:
  - `method`: `user.appMetadata['provider']` (예: `'apple'`, `'google'`, `'kakao'`) 또는 `user.identities?.first.provider`.
  - `selected_language`: `ref.read(appSettingProvider).language`.
- **신규가입 구분 로직 (Supabase Auth)**:
  - Supabase `User` 객체의 `user.createdAt`과 `user.lastSignInAt`을 비교 분석함.
  - 신규 가입 시: `user.lastSignInAt == null` 이거나, `DateTime.parse(user.lastSignInAt!).difference(DateTime.parse(user.createdAt)).inSeconds.abs() < 5` (최초 가입 시 두 시각이 동일함).
  - 재로그인 시: `user.lastSignInAt`이 갱신되어 `user.createdAt`과 수초~수일의 차이가 생김.
- **성공/실패 분기**: 회원가입 인증 통신 성공 시에만 `signedIn` 이벤트가 발생하므로 실패 경로는 차단됨.
- **중복 발송 위험**: 계정당 최초 1회만 발송되도록 회원가입 직후 시점에 strict 조건으로 분기하여 중복 방지.

---

### 3. `click_attendance` (출석체크 팝업 '출석하기' 버튼 클릭)

- **권장 호출 지점**: **[현재 코드베이스 접근 불가 / 기능 제거됨]**
  - **이유**: `docs/operations/attendance-reward-decision.html` (출석 보상 폐지 결정 문서)에 명시된 바와 같이, `AttendanceIconButton`, `attendance_dialog.dart`, `attendance_check_tab.dart` 등 출석체크 관련 UI 및 기능 코드가 전량 삭제(청소)되었음.
  - **제안**: 향후 출석체크 UI가 재도입될 경우 해당 팝업의 '출석하기' 버튼 클릭 이벤트 핸들러에 구현해야 함.
- **파라미터별 값 출처**:
  - `virtual_currency_name`: `접근 불가` (기능 제거 상태, 재도입 시 `'별사탕'` 매핑 필요)
  - `reward_amount`: `접근 불가` (기능 제거 상태, 재도입 시 지급 수량 매핑 필요)
- **성공/실패 분기 및 중복 위험**: 현재 UI 미존재로 해당 없음.

---

### 4. `click_mission` (무료 충전소 '미션에서 별사탕 받기' 미션 버튼 클릭)

- **권장 호출 지점**: `picnic_lib/lib/presentation/widgets/vote/store/free_charge_station/free_charge_station.dart:151,166`
  - `_buildMissionItems(BuildContext context)` 내부 `onPressed` 콜백 (또는 `free_charge_content.dart:145` `_buildStationItem` 클릭부)
  - **이유**: 무료 충전소 페이지에서 Tapjoy(`:151`), Pincrux(`:166`) 오퍼월 미션 버튼을 사용자가 터치하는 시점임.
- **파라미터별 값 출처**:
  - `mission_category`: `item.title` (예: `AppLocalizations.of(context).label_global_recommendation + ' #1'` → `'글로벌 픽 #1'`, `'한국 픽 #1'`).
- **성공/실패 분기**: 버튼 클릭 시점에 발송 (오퍼월 열림 통신 전 사용자 의도 수집).
- **중복 발송 위험**: 빠르게 버튼을 연속 클릭할 경우 중복 로깅 가능성 존재. 클릭 시 로딩 애니메이션 및 버튼 비활성화 조치가 필요함.

---

### 5. `ad_request` (무료 충전소 '광고에서 코튼캔디 받기' 시청 버튼 클릭)

- **권장 호출 지점**: `picnic_lib/lib/presentation/widgets/vote/store/free_charge_station/free_charge_station.dart:191,208`
  - `_buildAdItems(BuildContext context)` 내부 `onPressed` 콜백 (내부 숏폼 `:191`, Pangle `:208`)
  - **이유**: 무료 충전소 광고 목록에서 사용자가 광고 시청 버튼을 클릭하여 광고 로드/시청을 요청하는 지점.
- **파라미터별 값 출처**:
  - `section_name`: `'광고에서 코튼캔디 받기'` (`FreeChargeGa4.sectionAds`) (또는 `AppLocalizations.of(context).label_ads_get_cotton_candy`).
  - `ad_category`: `item.title` (예: `'글로벌 픽 #1'`, `'아시아 픽 #1'`).
  - `virtual_currency_name`: `'코튼캔디'` (`Ga4CurrencyNames.cottonCandy`) — 광고 리워드 재화.
  - `reward_amount`: `int.tryParse(item.bonusText) ?? 1`.
- **성공/실패 분기**: 광고 요청 버튼 클릭 즉시 발송.
- **중복 발송 위험**: `adLoadingStateProvider` 상태에 의해 광고 로딩 중 버튼이 비활성화되므로 중복 위험 낮음.

---

### 6. `ad_impression` (광고 SDK가 실제 광고 노출)

- **권장 호출 지점**:
  - AdMob: `picnic_lib/lib/presentation/widgets/vote/store/free_charge_station/platforms/admob_platform.dart:137` (`onAdImpression` 콜백)
  - Shortform: `picnic_lib/lib/presentation/widgets/vote/store/free_charge_station/platforms/shortform_internal_platform.dart:123` (`_callView` 시점)
  - Pangle: `picnic_lib/lib/presentation/widgets/vote/store/free_charge_station/platforms/pangle_platform.dart` (노출 성공 콜백)
- **파라미터별 값 출처**:
  - `ad_platform`: `'AdMob'`, `'Pangle'`, `'internal-shortform'` (플랫폼 식별자).
  - `ad_source`: AdMob의 경우 `ad.responseInfo?.loadedAdapterResponseInfo?.adSourceName` 또는 `ad.responseInfo?.mediationAdapterClassName`에서 취득 가능.
  - `ad_format`: `'rewarded'`
  - `ad_unit_name`: AdMob: `_adUnitId` (`ad.adUnitId`), Pangle: slot ID, 자체 숏폼: **`null`** (ad unit 개념이 없어 `undefined` 로 대체 — 추정값을 넣지 않는다).
  - `section_name`: `'광고에서 코튼캔디 받기'` (`FreeChargeGa4.sectionAds`)
  - `ad_category`: `'글로벌 픽 #1'`, `'아시아 픽 #1'`
  - `virtual_currency_name`: `'코튼캔디'` (`Ga4CurrencyNames.cottonCandy`)
  - `reward_amount`: `1`
- **성공/실패 분기**: 광고 SDK가 실제 전체 화면 렌더링에 성공하여 임프레션 이벤트를 발생시킨 경우만 잡힘.
- **중복 발송 위험 (주의)**: Firebase와 AdMob SDK 연동 시, `ad_impression`은 GA4에 **자동 수집(Auto-collected)**되는 이벤트다. 커스텀 코드에서 `logEvent('ad_impression')`를 수동 발송하면 동일 노출 건이 2번 집계될 위험이 높으므로, AdMob 자동 연동 여부를 먼저 확인해야 함.

---

### 7. `earn_virtual_currency` (광고 완료 시청으로 코튼캔디 지급)

- **권장 호출 지점**:
  - AdMob: `picnic_lib/lib/presentation/widgets/vote/store/free_charge_station/platforms/admob_platform.dart:176` (`onUserEarnedReward: (ad, reward) { ... }`)
  - Shortform: `picnic_lib/lib/presentation/widgets/vote/store/free_charge_station/platforms/shortform_internal_platform.dart` (서버 보상 지급 완료 응답 `response.rewardAdded > 0` 수신부)
  - Pangle: `pangle_platform.dart` (보상 획득 콜백)
- **파라미터별 값 출처**:
  - `virtual_currency_name`: `'코튼캔디'` (`Ga4CurrencyNames.cottonCandy`). 레거시 응답 경로는 `'보너스 스타캔디'`.
  - `reward_amount`: `reward.amount.toInt()` 또는 서버 응답의 지급 수량 (`1`)
  - `earn_method`: `'광고 리워드'`
  - `section_name`: `'광고에서 코튼캔디 받기'` (`FreeChargeGa4.sectionAds`)
  - `ad_category`: `'글로벌 픽 #1'`, `'아시아 픽 #1'`
- **성공/실패 분기**: 광고를 끝까지 시청하여 리워드 검증(SSV / API)이 완료된 성공 경로만 선택됨. 중도 닫기 시 콜백 미호출.
- **중복 발송 위험**: SDK 및 서버 보상 콜백은 1회 시청당 1회만 트리거되므로 중복 위험 낮음.

---

### 8. `ad_cta_click` (광고 종료 후 '더보기' 버튼으로 이동)

- **실제 호출 지점**: `picnic_lib/lib/presentation/widgets/vote/store/free_charge_station/platforms/ad_shortform_fullscreen_page.dart:701` — `_openCta(String url)` 안에서 `launchUrl` 이 **성공(`true`) 했을 때만** `_logAdClick(url)` 호출.
  - **이유**: 숏폼 광고 화면 하단 CTA '더보기' 버튼을 눌러 외부 링크로 실제 이동한 지점. 이동에 실패하면 클릭으로 집계하지 않는다.
  - ⚠️ 이전 판에는 `shortform_internal_platform.dart` 의 `_callMore()` 가 호출 지점으로 함께 적혀 있었으나 **잘못된 기술**이었다. `_callMore()` 는 '더보기' 추가 적립용 서버 콜백이었고 UI 에서 호출된 적이 없으며, 추가 적립을 하지 않기로 확정(PICNIC-2377)되면서 제거됐다. `ad_cta_click` 계측은 그와 무관하게 `_openCta()` 에서 그대로 발송된다.
- **파라미터별 값 출처**:
  - `ad_platform`: `'internal-shortform'`
  - `ad_source`: `'internal'`
  - `ad_format`: `'rewarded'`
  - `ad_unit_name`: **`null`** → `'undefined'` (자체 숏폼에는 외부 SDK 의 ad unit 개념이 없다)
  - `section_name`: `'광고에서 코튼캔디 받기'` (`FreeChargeGa4.sectionAds`)
  - `ad_category`: `'글로벌 픽 #1'`
  - `destination_type`: `ctaUrl` URI 분석 (예: `'youtube'`, `'web'`, `'store'`).
- **UI 존재 여부 확인**:
  - 내부 숏폼 광고(`internal-shortform`): `AdShortformFullscreenPage` 하단에 CTA '더보기' 버튼이 **실제 UI로 존재함**. 잔여 5초부터 노출·활성되므로 재생 종료 전 클릭도 집계된다.
  - AdMob / Pangle 외부 SDK 광고: SDK 전용 플레이어 내부에서 클릭 조작이 처리되므로 Flutter UI 차원의 별도 '더보기' 버튼은 존재하지 않음.

---

### 9. `purchase` (결제 완료로 별사탕 구매)

- **권장 호출 지점**: `picnic_lib/lib/core/services/purchase_service.dart:836` (`_logPurchaseAnalytics`)
  - **기존 서비스 활용**: `picnic_lib/lib/presentation/widgets/vote/store/purchase/analytics_service.dart:6` (`logPurchaseEvent`)
  - **이유**: `PurchaseService`가 결제 검증 및 영수증 검증 통신을 정상 마친 뒤 애널리틱스를 호출하는 중앙 지점.
- **파라미터별 값 출처**:
  - **Event 수준**:
    - `transaction_id`: `purchaseDetails.purchaseID`
    - `currency`: `productDetails.currencyCode` (예: `'USD'`, `'KRW'`)
    - `value`: `productDetails.rawPrice`
  - **Item 수준 (`items` 배열)**:
    - `item_id`: `productDetails.id` (예: `'star100'`, `'star200'`)
    - `item_name`: `productDetails.title`
    - `virtual_currency_name`: `'별사탕'`
    - `base_amount`: `purchaseProduct.starCandy` (`purchase_product_provider.dart` 의 `PurchaseProductList` 매핑 데이터, 예: 100, 200, 600)
    - `bonus_amount`: `purchaseProduct.bonusStarCandy` (예: 0, 25, 85)
- **기존 `AnalyticsService` 분석**:
  - 이미 `AnalyticsService.logPurchaseEvent`가 존재하고 `purchase` 이벤트를 발송 중이나, `items` 내부 항목에 `virtual_currency_name`, `base_amount`, `bonus_amount` 파라미터가 빠져 있고 `price`/`quantity`만 들어있음. 본 택소노미 스펙에 맞춘 파라미터 확장이 필요함.
- **성공/실패 분기**: 결제 완료 및 서버 영수증 검증 통과 시점에만 호출됨. 결제 취소/오류 시 `logPurchaseCancelEvent`, `logPurchaseErrorEvent`로 분기 처리됨.
- **중복 발송 위험**: `PurchaseService`에서 처리된 트랜잭션의 중복 완결 처리를 차단하므로 중복 위험 없음.

---

### 10. `vote` (투표 팝업 '투표' 버튼 클릭)

- **권장 호출 지점**: `picnic_lib/lib/presentation/widgets/vote/voting/voting_dialog.dart:408` (`_handleVote` 진입부)
  - *(JMA 투표 다이얼로그)*: `jma_voting_dialog.dart` 의 제출 핸들러
  - **이유**: 투표 다이얼로그에서 사용자가 별사탕 수량을 입력하고 '투표' 버튼을 누르는 지점.
- **파라미터별 값 출처**:
  - `virtual_currency_name`: `'별사탕'`
  - `reward_amount`: `_getVoteAmount()` (투표에 사용한 별사탕 개수)
  - `vote_id`: `widget.voteModel.id.toString()`
  - `vote_name`: `widget.voteModel.title['ko']` (또는 현재 로캘 언어 String)
  - `vote_reward`: `widget.voteModel.reward?.firstOrNull?.title?['ko'] ?? ''`
  - `vote_start_date`: `widget.voteModel.startAt != null ? DateFormat('yyyy.MM.dd').format(widget.voteModel.startAt!) : ''`
  - `vote_end_date`: `widget.voteModel.stopAt != null ? DateFormat('yyyy.MM.dd').format(widget.voteModel.stopAt!) : ''`
  - `vote_artist_name`: `widget.voteItemModel.artist?.name['ko'] ?? ''`
  - `vote_artist_group`: `widget.voteItemModel.artistGroup?.name['ko'] ?? ''`
- **성공/실패 분기**: 수량 0개, 잔액 부족(`!hasBalance`), 탈퇴 회원 차단(`showWithdrawalBlockedDialog`) 검증을 통과한 유효한 투표 요청 시점에 발송.
- **중복 발송 위험**: `_isVoting` 상태 변수로 버튼 클릭 중복 입력을 이미 차단하고 있어 중복 위험 없음.

---

## 3. 추가 조사 항목 보고

### ① Google Mobile Ads 콜백 구현 및 메디에이션 정보 수집 가능 여부
- **구현 위치**: `picnic_lib/lib/presentation/widgets/vote/store/free_charge_station/platforms/admob_platform.dart`
  - `_setupAdCallbacks` (lines 107–140): `onAdShowedFullScreenContent`, `onAdDismissedFullScreenContent`, `onAdFailedToShowFullScreenContent`, `onAdImpression`
  - `_showRewardedAd` (lines 149–181): `ad.show(onUserEarnedReward: ...)`
- **`ad_unit_name` / `ad_source` 코드상 취득 여부**:
  - `ad_unit_name`: `ad.adUnitId` 또는 `AdmobPlatform._adUnitId`에서 **직접 수집 가능**.
  - `ad_source`: `ad.responseInfo?.loadedAdapterResponseInfo?.adSourceName` 또는 `ad.responseInfo?.mediationAdapterClassName` 객체를 통해 메디에이션 네트워크명을 **직접 수집 가능**.

### ② AdMob-Firebase 연동으로 `ad_impression` 자동 수집 여부
- `admob_platform.dart:137`에 `onAdImpression` 로그 콜백이 선언되어 있으나 커스텀 GA4 `logEvent`는 작성되어 있지 않음.
- 앱 실행 시 `main_initializer.dart`에서 Firebase와 MobileAds가 초기화되며 `FirebaseAnalyticsObserver`가 적용되어 있음.
- Firebase 콘솔과 AdMob 계정이 연동되어 있는 프로젝트라면 Google SDK가 `ad_impression` 이벤트를 **자동 수집(Auto-collected)**함.
- 따라서 커스텀 `ad_impression` 수동 발송을 추가하기 전에 Firebase-AdMob 자동 수집 활성화 여부를 반드시 확인해야 함 (중복 집계 위험).

### ③ '더보기' 버튼 (`ad_cta_click` 트리거) UI 존재 여부
- **내부 숏폼 광고 (`internal-shortform`)**: `AdShortformFullscreenPage` 화면 하단에 CTA ('더보기' / 이동) 버튼이 **실제 UI로 구현되어 있음**. 클릭 시 `_openCta(url)` 이 `launchUrl` 로 external browser 를 열고, 이동에 성공하면 `_logAdCtaClick(url)` 로 `ad_cta_click` 을 1회 발송한다. **추가 적립은 없다** — 더보기는 광고주 랜딩 이동과 클릭 계측만 담당한다(PICNIC-2377 결정).
- **외부 SDK 광고 (AdMob, Pangle 등)**: SDK 플레이어가 자율 관리하므로 Flutter UI 차원의 별도 '더보기' 버튼은 없음.

---

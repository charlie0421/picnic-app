# GA4 이벤트 택소노미 (Picnic App)

출처: [이벤트 택소노미 스프레드시트](https://docs.google.com/spreadsheets/d/1JfC-wGcmGYJIOxOyNGys1ypRsVGtvwDvkjliTX3B6p8/edit?gid=0#gid=0)
추출일: 2026-08-07 · 세팅 상태: 전 이벤트 `대기중` · Platform: MO(모바일 앱)

이 문서는 스프레드시트에서 추출한 **구현 기준표**다. 스프레드시트가 갱신되면 이 문서를 먼저 갱신하고 코드를 맞춘다.

## 1. 사용자 속성 (User Property)

로그인 완료 시점 또는 사용자 식별 가능 시점에 설정한다.

| 파라미터 | 의미 | 타입 | 예시값 | 구현 |
|---|---|---|---|---|
| `user_id` | 로그인한 사용자 ID | String | `7c9e6679-7425-40de-944b-e07fc1f90ae7` | Supabase `auth.users.id` (UUID) **원본** |
| `is_login` | 로그인 여부 | String | `Y`, `N` | 로그인/로그아웃 시 갱신 |
| `language` | 현재 선택 언어 | String | `ko`, `en`, `jp` | user property 이름은 `language` 로 통일 |

> 스프레드시트 내 이름 불일치: "파라미터 리스트" 시트는 `language`, "공통 파라미터" 시트는 `selected_language`.
> 개인정보(PII) 주의: 이메일·전화번호·이름 등 직접 식별 정보는 `user_id` 및 사용자 속성에 넣지 않는다.

### `user_id` 를 해시하지 않는 이유 (스프레드시트와의 의도적 차이)

스프레드시트는 `user_id` 를 "로그인한 ID의 해시값"으로 적고 있으나, 본 앱은
**Supabase `auth.users.id` (UUID) 를 해시 없이 그대로** 전달한다.

1. **UUID 는 PII 가 아니다.** v4 UUID 는 사용자 정보에서 파생되지 않은 무작위
   식별자다. 이메일·전화번호·이름 등 직접 식별 정보는 애초에 GA4 로 보내지 않는다.
2. **해시하면 BigQuery↔Supabase 조인이 끊긴다.** GA4 BigQuery export 의
   `user_id` 와 Supabase `user_profiles.id` 를 조인해야 퍼널·리텐션·과금 분석이
   가능하다. 해시하면 이 연결고리가 사라진다.
3. **기존 GA4 `user_id` 히스토리가 단절된다.** 이미 원본 UUID 로 수집 중이므로,
   지금 해시로 바꾸면 동일 사용자가 신규 사용자로 갈라져 코호트가 깨진다.

구현: `PicnicAnalytics.setUserProperties` (picnic_lib/lib/core/analytics/picnic_analytics.dart).

샘플 코드 (실제 구현):

```dart
await PicnicAnalytics.instance.setUserProperties(
  userId: supabase.auth.currentUser?.id, // 해시하지 않은 UUID 원본
  isLogin: true,
  language: 'ko',
);
```

## 2. 이벤트 목록

정보가 없는 경우 값은 `undefined` 로 대체한다(스프레드시트 규칙).

### 1. `login` — 로그인 완료 시점 (통신 시점)

| 파라미터 | 의미 | 타입 | 수준 | 예시값 |
|---|---|---|---|---|
| `method` | 로그인 방법 | String | Event | `apple`, `google`, `kakao` |
| `selected_language` | 로그인 직전 선택된 언어 | String | Event | `ko`, `en`, `jp` |

### 2. `sign_up` — 회원가입 완료 시점 (통신 시점)

| 파라미터 | 의미 | 타입 | 수준 | 예시값 |
|---|---|---|---|---|
| `method` | 회원가입 방법 | String | Event | `apple`, `google`, `kakao` |
| `selected_language` | 회원가입 직전 선택된 언어 | String | Event | `ko`, `en`, `jp` |

### 3. `click_attendance` — 출석체크 팝업에서 '출석하기' 버튼 클릭 시

> ⚠️ **구현 불가 — 제품에서 폐지된 기능.** 출석 보상은 폐지됐고 1.3.0 코드에 이미 반영돼 있다.
> `AttendanceIconButton` 은 어디서도 참조되지 않는 고아 위젯이고, 무료 충전소의 출석 탭도 제거되어
> `attendance_check_tab` 은 미사용 import 만 남아 있다 (`free_charge_station.dart:38`).
> 사용자가 도달할 수 있는 진입점이 없으므로 이 이벤트는 발생시킬 수 없다.
> 근거: `docs/operations/attendance-reward-decision.html`
> → **대행사 확인 필요 항목** (§4 참조)


| 파라미터 | 의미 | 타입 | 수준 | 예시값 |
|---|---|---|---|---|
| `virtual_currency_name` | 지급된 가상 재화 이름 | String | Event | `별사탕`, `보너스 별사탕` |
| `reward_amount` | 지급된 가상 재화 수량 | Number | Event | `60` |

### 4. `click_mission` — 무료 충전소 '미션에서 별사탕 받기' 영역에서 미션 버튼 클릭 시

| 파라미터 | 의미 | 타입 | 수준 | 예시값 |
|---|---|---|---|---|
| `mission_category` | 미션 카테고리 | String | Event | `글로벌 픽 #1`, `아시아 픽 #1` |

### 5. `ad_request` — 무료 충전소 '광고에서 별사탕 받기' 영역에서 시청 버튼 클릭 시

| 파라미터 | 의미 | 타입 | 수준 | 예시값 |
|---|---|---|---|---|
| `section_name` | 광고가 위치한 영역명 | String | Event | `광고에서 별사탕 받기` |
| `ad_category` | 광고가 속한 카테고리 또는 큐레이션 | String | Event | `글로벌 픽 #1` |
| `virtual_currency_name` | 시청 완료 시 지급 예정 재화 이름 | String | Event | `별사탕` |
| `reward_amount` | 시청 완료 시 지급 예정 재화 수량 | Number | Event | `1` |

### 6. `ad_impression` — 광고 SDK가 실제 광고를 노출했을 때

| 파라미터 | 의미 | 타입 | 수준 | 예시값 |
|---|---|---|---|---|
| `ad_platform` | 광고 플랫폼 | String | Event | `AdMob` |
| `ad_source` | 광고 제공 네트워크 | String | Event | `Google Ads` |
| `ad_format` | 광고 형식 | String | Event | `rewarded` |
| `ad_unit_name` | 광고 Unit 이름 | String | Event | `reward_global_pick_1` |
| `section_name` | 광고가 위치한 영역명 | String | Event | `광고에서 별사탕 받기` |
| `ad_category` | 광고 카테고리/큐레이션 | String | Event | `글로벌 픽 #1` |
| `virtual_currency_name` | 지급 예정 재화 이름 | String | Event | `별사탕` |
| `reward_amount` | 지급 예정 재화 수량 | Number | Event | `1` |

> 주의: `ad_impression` 은 Firebase↔AdMob 연동 시 SDK가 자동 수집하는 이름과 동일하다. 커스텀 로깅 시 중복 집계 가능성을 확인할 것.

### 7. `earn_virtual_currency` — 광고를 끝까지 시청하여 별사탕이 실제 지급됐을 때

| 파라미터 | 의미 | 타입 | 수준 | 예시값 |
|---|---|---|---|---|
| `virtual_currency_name` | 지급된 재화 이름 | String | Event | `별사탕`, `보너스 별사탕` |
| `reward_amount` | 지급된 재화 수량 | Number | Event | `1` |
| `earn_method` | 재화 획득 방법 | String | Event | `광고 리워드` |
| `section_name` | 광고가 위치한 영역명 | String | Event | `광고에서 별사탕 받기` |
| `ad_category` | 광고 카테고리/큐레이션 | String | Event | `글로벌 픽 #1` |

> GA4 표준 `earn_virtual_currency` 는 `virtual_currency_name` + `value` 를 쓰지만, 본 택소노미는 수량을 `reward_amount` 로 정의한다.

### 8. `ad_click` — 광고 종료 후 '더보기' 버튼을 눌러 이동했을 때

| 파라미터 | 의미 | 타입 | 수준 | 예시값 |
|---|---|---|---|---|
| `ad_platform` | 광고 플랫폼 | String | Event | `AdMob` |
| `ad_source` | 광고 제공 네트워크 | String | Event | `Google Ads` |
| `ad_format` | 광고 형식 | String | Event | `rewarded` |
| `ad_unit_name` | 광고 Unit 이름 | String | Event | `reward_global_pick_1` |
| `section_name` | 광고가 위치한 영역명 | String | Event | `광고에서 별사탕 받기` |
| `ad_category` | 광고 카테고리/큐레이션 | String | Event | `글로벌 픽 #1` |
| `destination_type` | 클릭 후 이동한 목적지 유형 | String | Event | `youtube` |

### 9. `purchase` — 사용자가 결제를 완료하여 별사탕을 구매했을 때 (통신 시점)

Event 수준:

| 파라미터 | 의미 | 타입 | 예시값 |
|---|---|---|---|
| `transaction_id` | 결제 건 고유 거래 ID | String | `202607061530001` |
| `currency` | 결제 통화 코드 | String | `USD` |
| `value` | 최종 결제 금액 | Number | `0.99`, `1.99`, `5.99` |

Item 수준 (`items` 배열):

| 파라미터 | 의미 | 타입 | 예시값 |
|---|---|---|---|
| `item_id` | 구매 상품 고유 ID | String | `star100`, `star200`, `star600` |
| `item_name` | 구매 상품명 | String | `STAR100`, `STAR200`, `STAR600` |
| `virtual_currency_name` | 구매한 가상 재화 이름 | String | `별사탕` |
| `base_amount` | 상품의 기본 지급 수량 | Number | `100`, `200`, `600` |
| `bonus_amount` | 프로모션 추가 지급 수량 | Number | `0`, `25`, `85` |

### 10. `vote` — 투표 팝업에서 '투표' 버튼 클릭 시

| 파라미터 | 의미 | 타입 | 수준 | 예시값 |
|---|---|---|---|---|
| `virtual_currency_name` | 사용된 재화 이름 | String | Event | `별사탕`, `보너스 별사탕` |
| `reward_amount` | 사용된 재화 수량 | Number | Event | `100` |
| `vote_id` | 투표 고유 ID | String | Event | `vote0023` |
| `vote_name` | 투표 이름 | String | Event | `올해의 썸머킹` |
| `vote_reward` | 투표 우승자 리워드 | String | Event | `중앙데일리 온라인+지면 기사 송출` |
| `vote_start_date` | 투표 시작일 | String | Event | `2026.06.26` |
| `vote_end_date` | 투표 마감일 | String | Event | `2026.07.10` |
| `vote_artist_name` | 투표한 아티스트 이름 | String | Event | `제이엘`, `셔누` |
| `vote_artist_group` | 투표한 아티스트 그룹 | String | Event | `아홉`, `몬스타엑스` |

## 3. 공통 파라미터 사전

| # | 파라미터 | 타입 | 수준 | 공통 |
|---:|---|---|---|:-:|
| 1 | `user_id` | String | User | O |
| 2 | `is_login` | String | User | O |
| 3 | `language` | String | User | O |
| 4 | `method` | String | Event | |
| 5 | `selected_language` | String | Event | |
| 6 | `virtual_currency_name` | String | Event | |
| 7 | `reward_amount` | Number | Event | |
| 8 | `mission_category` | String | Event | |
| 9 | `section_name` | String | Event | |
| 10 | `ad_category` | String | Event | |
| 11 | `ad_platform` | String | Event | |
| 12 | `ad_source` | String | Event | |
| 13 | `ad_format` | String | Event | |
| 14 | `ad_unit_name` | String | Event | |
| 15 | `earn_method` | String | Event | |
| 16 | `destination_type` | String | Event | |
| 17 | `transaction_id` | String | Event | |
| 18 | `currency` | String | Event | |
| 19 | `value` | Number | Event | |
| 20 | `item_id` | String | Item | |
| 21 | `item_name` | String | Item | |
| 22 | `base_amount` | Number | Item | |
| 23 | `bonus_amount` | Number | Item | |
| 24 | `vote_id` | String | Event | |
| 25 | `vote_name` | String | Event | |
| 26 | `vote_reward` | String | Event | |
| 27 | `vote_start_date` | String | Event | |
| 28 | `vote_end_date` | String | Event | |
| 29 | `vote_artist_name` | String | Event | |
| 30 | `vote_artist_group` | String | Event | |

## 4. 대행사 확인 필요 항목

구현 과정에서 발견한 스펙 ↔ 실제 제품/코드 불일치. 대행사에 회신해야 한다.

| # | 항목 | 내용 | 처리 |
|---:|---|---|---|
| 1 | `click_attendance` 구현 불가 | 출석 보상은 제품에서 **폐지**됐고 1.3.0 코드에 반영 완료. 진입 UI가 전부 제거되어 이벤트가 발생할 수 없음. 근거: `docs/operations/attendance-reward-decision.html` | 이벤트 제외 요청 |
| 2 | `user_id` 해싱 불필요 | 스펙은 "로그인 ID의 해시값"을 요구하나, 본 앱의 로그인 식별자는 Supabase auth **UUID** 로 PII가 아님. 해싱 시 BigQuery↔DB 조인이 끊기고 기존 GA4 `user_id` 히스토리가 단절됨 | raw UUID 유지 통지 |
| 3 | user property 이름 불일치 | "파라미터 리스트" 시트는 `language`, "공통 파라미터" 시트는 `selected_language` 로 같은 값을 다르게 표기 | user property 는 `language` 로 통일 |
| 4 | `ad_impression` 중복 집계 | AdMob↔Firebase 연동 시 GA4가 동일 이름 이벤트를 자동 수집함. 스펙대로 커스텀 발송하면 중복 가능 | 스펙대로 발송하되 GA4 콘솔에서 중복 확인 요청 |
| 5 | `earn_virtual_currency` 비표준 | GA4 표준은 `virtual_currency_name` + `value` 이나 본 택소노미는 수량을 `reward_amount` 로 정의 | 스펙대로 구현 |
| 6 | Number 파라미터의 `undefined` 대체 | 스펙은 "정보가 없으면 값을 `undefined` 로 대체"하나, Number 파라미터(`reward_amount`, `value`, `base_amount`, `bonus_amount`)에 문자열을 섞으면 GA4가 해당 키를 커스텀 측정기준/측정항목 중 하나로만 등록해 **반대 타입 값이 리포트에서 통째로 누락**됨 | String 파라미터만 `undefined` 대체. Number 는 값이 없으면 파라미터 생략 + 경고 로그 |
| 7 | `sign_up` 판별 근거 | Supabase 는 신규 가입 여부를 응답에 직접 주지 않음. `created_at` 과 `last_sign_in_at` 의 차이가 30초 이내면 신규 가입으로 판정하고, 사용자별 1회 발송 마커를 로컬에 영속 저장 | 판별 기준 확인 요청 |
| 8 | `currency` 의 `undefined` 대체 불가 (ISO 4217) | 스펙의 "String 값이 없으면 `undefined` 로 대체" 규칙을 `currency` 에 적용하면 GA4 가 ISO 4217 위반 통화로 판정해 해당 **`purchase` 의 매출(`value`)을 통째로 무시**함 | `currency` 는 값이 없으면 파라미터를 생략(null 전달 → Firebase 가 `filterOutNulls` 로 제거)하고, 짝이 되는 `value` 도 함께 생략 |

## 5. 트리거 지점 매핑

코드베이스 실측 조사 결과는 [`trigger-mapping.md`](trigger-mapping.md) 참조.

## 관련 문서

| 문서 | 내용 |
|---|---|
| [`trigger-mapping.md`](trigger-mapping.md) | 이벤트별 실측 트리거 지점과 파라미터 데이터 출처 |
| [`api-contract.html`](api-contract.html) | `PicnicAnalytics` 공개 API 계약과 설계 근거 |
| [`agency-reply.html`](agency-reply.html) | 대행사 회신 — 스펙↔제품 불일치 13건, 전송값 대조표, GA4 등록 목록 |
| [`implementation-report.html`](implementation-report.html) | 구현 경과와 리뷰에서 발견한 결함 기록 |

## 6. Durable analytics outbox

`purchase`, `earn_virtual_currency`, `login`, `sign_up` payload는 sink를 바로
호출하지 않고 `analytics_ga4_outbox_v1`에 먼저 영속 저장한다. 저장
envelope는 `version`, `pending`, `delivered`를 가지며 pending 항목은 이벤트
종류, 안정적 idempotency key, purchase tx/op alias 그룹, 완성된 payload,
생성 시각, non-purchase `delivery_confirmed` 상태를 담는다. sink가 `true`를
반환한 항목만 pending에서 제거하고 delivered 마커로 옮긴다.

- 재시도: enqueue 직후 background drain을 시작하고, Firebase 초기화
  직후에 이전 프로세스의 pending을 다시 drain한다. 확인된 실패가
  남으면 앱이 살아 있는 동안 30초 후 background drain을 재예약한다. 각 I/O는 2초,
  각 sink는 5초로 제한한다. sink가 `false`를 반환하거나 timeout/throw한
  항목은 pending을 남겨 재시도한다.
- 동시성: storage-key 전역 mutex로 read-modify-write를 직렬화하고,
  항목별 in-flight 예약을 첫 `await` 전에 잡는다. auth는 captured
  user_id 설정→이벤트→현재 사용자(B 또는 logout) 복원을 하나의
  delivery 순서 단위로 묶는다.
- 읽기 실패: outbox 본문을 읽지 못하면 빈 목록으로 축약하거나 덮어쓰지
  않고 해당 drain/enqueue를 실패시켜 error log와 다음 retry로 넘긴다.
  legacy marker/auth 보조 마커 읽기 실패는 fail-open으로 관측 가능하게
  enqueue하되, 안정적 idempotency key를 가진 outbox가 실제 중복을 다시 막는다.
- 용량/만료: pending 200건이 차면 미전송 기존 항목을 밀어내지
  않고 신규 enqueue를 거부하며 error로 남긴다. purchase pending은
  365일, 나머지는 30일 후 만료하고, delivered는 500건/180일을
  보존한다. 만료·용량 제거는 모두 logger에 드러난다.

### 이벤트별 중복/누락 정책

| 이벤트 | 정책 | 근거 |
|---|---|---|
| `purchase` | at-least-once | GA4가 같은 `transaction_id`를 중복 제거한다. sink 성공 후 제거 저장이 실패하면 재시작 후 재전송해 매출 영구 누락을 막는다. |
| `earn_virtual_currency` | 성공 확인 checkpoint + at-least-once | reference로 클라이언트 동시/재진입 중복을 막는다. GA4 서버 중복 제거가 없으므로 sink `true` 뒤 `delivery_confirmed`를 먼저 저장하고 cleanup한다. cleanup만 실패하면 재시작에서 보내지 않고 제거만 재시도한다. 성공과 checkpoint 저장 사이의 프로세스 종료에는 중복 가능성이 남지만, 확인되지 않은 이벤트를 버려 영구 누락시키지는 않는다. |
| `login`, `sign_up` | 성공 확인 checkpoint + 독립 at-least-once | 두 이벤트를 별도 outbox 항목으로 두어 `sign_up` 실패가 `login` 성공 서명에 가리지 않게 한다. `sign_up` 발송 판정도 `login` 중복(세션 복원) 판정과 독립이다 — 함께 억제하면 `sign_up` outbox 저장만 실패하고 `login` 저장은 성공한 최초 가입이 영구 누락된다. 세션 복원 재발화의 `sign_up` 중복 방지는 사용자별 발송 마커와 outbox 의 `signup:<userId>` id dedup 이 담당한다. 각각 sink `true` 뒤 checkpoint를 저장하므로 cleanup 실패는 재전송하지 않는다. 성공과 checkpoint 저장 사이의 좁은 구간에는 중복 가능성이 있으나, GA4 중복 제거가 없다는 이유로 미확인 이벤트를 삭제하지 않는 쪽을 택한다. |

## 7. 알려진 한계

출시 전 인지하고 있어야 하는, 현재 구현이 의도적으로 감수한 한계다. 각 항목은
"막을 수 있는 다른 방법이 더 큰 손실(영구 누락, UX 블로킹)을 내는" 트레이드오프의
결과이며, 바꾸려면 제품 결정이 필요하다.

| # | 한계 | 내용 | 영향/처리 |
|---:|---|---|---|
| 1 | 카탈로그 미적재 복구 구매의 매출 누락 | 정산 확정 시점에 스토어 상품 카탈로그가 메모리에 없으면 (`purchase_service.dart` 의 `_sendPurchaseAnalytics`) `currency`/`value` 를 알 수 없다. **`PurchasePriceMemo` 로 대부분 해소** (§8) — 결제 시점에 남긴 기록으로 금액을 복원한다. 기록마저 없는 경우(앱 데이터 삭제, 다른 설치에서 시작된 구매, 90일 초과)에만 금액이 빈다 | 잔여 케이스에서 **purchase 건수는 남지만 그 건의 매출액은 복원되지 않는다.** 숫자를 지어내지 않고 거래 사실부터 durable 하게 남기는 선택이다 |
| 2 | non-purchase 이벤트의 좁은 중복 창 | `earn_virtual_currency`/`login`/`sign_up` 은 sink 성공과 `delivery_confirmed` checkpoint 저장 사이에 프로세스가 종료되면 재시작 후 한 번 더 나갈 수 있다 (§6 정책 표 참조) | GA4 서버 중복 제거가 없는 이벤트에서 미확인 삭제(영구 누락) 대신 좁은 중복 가능성을 택함 |
| 3 | outbox 용량/만료 | pending 은 200건 상한(초과 시 신규 거부)·30일 만료(purchase 는 365일), delivered 마커는 500건·180일 보존. 초과·만료 제거는 모두 로그로 드러난다 | 장기 미전송 항목과 오래된 dedup 마커는 결국 소멸함. delivered 마커가 밀려나면 재발송 방지가 사용자별 발송 마커에만 의존 |
| 4 | captured auth context 의 좁은 귀속 경쟁 | auth 이벤트 발송 중 captured user 를 잠시 전역 GA4 user context 에 적용했다가 현재 사용자로 복원한다. 이 구간에 outbox 밖에서 동시 발화한 비-auth 이벤트(`ad_request`, `vote` 등 직접 sink 호출 이벤트)는 captured user 로 귀속될 수 있다 | delivery mutex 는 outbox 이벤트끼리만 직렬화함. 좁은 창이며 이벤트 유실은 없고 `user_id` 귀속만 흔들림 |
| 5 | SharedPreferences 최초 실패의 고착 | 로컬 저장소의 최초 초기화 `Future` 가 실패하면 그 실패 상태가 캐시되어 앱 재시작 전까지 모든 마커/outbox I/O 가 실패한다 | I/O timeout·enqueue 실패 로그로 관측 가능. 재시작 시 복구되며, durable payload 는 남는 시점 이후부터 보존됨 |
| 6 | `ad_impression` 자동수집 중복 | Firebase↔AdMob 연동 시 GA4 가 동일 이름 이벤트를 자동 수집해 커스텀 `ad_impression` 과 중복될 수 있다 (§4 #4 와 동일 사안) | 스펙대로 커스텀 발송 유지. GA4 콘솔에서 자동수집 여부 확인을 대행사에 요청한 상태 |

## 8. 결제 시점 가격 기록 (`PurchasePriceMemo`)

`purchase` 의 `currency`/`value` 는 스토어 카탈로그에서 온다. 발송 경로는
카탈로그 future 를 **기다리지 않고** 이미 메모리에 로드된 값만 동기적으로
읽는다 — 기다리다 지연되면 outbox 저장보다 store finish 가 먼저 일어나
매출 payload 가 통째로 사라지기 때문이다.

그래서 앱 재시작 직후 복구 스윕이 카탈로그 로드보다 먼저 돌면 금액을 알 수
없다. `purchase` 건수는 있는데 매출이 0 인 레코드는 나중에 보는 사람에게
**무료 지급으로 오해될 수 있어** 단순 누락보다 나쁘다.

### 왜 "캐시"가 아니라 "결제 시점 기록"인가

복구 시점에 카탈로그를 다시 읽는 방식이면 그 사이의 가격 인상·프로모션
종료·환율·지역 변경으로 **실제 결제 금액과 다른 값**이 들어갈 수 있다.
여기 남는 값은 사용자가 상점에서 보고 결제한 바로 그 가격이므로 폴백이
아니라 더 정확한 출처다.

구매를 시작하려면 상점 화면을 거쳐야 하고 그 시점엔 카탈로그가 반드시
메모리에 있으므로 기록은 항상 남는다.

| 항목 | 값 | 근거 |
|---|---|---|
| 결합 키 | `storeProductId` + `userId` + 기록 시각 | 상품 ID 만 쓰면 취소된 시도의 잔재·다른 사용자·다른 스토어 계정 값이 서로 덮어써 **틀린 매출**이 들어간다 |
| 지목 규칙 | 정산 대상 사용자 + 거래 시각 이전(+10분 skew) 중 **가장 가까운** 하나. 거래 시각을 모르면 후보가 정확히 하나일 때만 | 모호하면 금액을 생략한다 — 추측한 숫자를 매출로 올리지 않는다 |
| 소비 | 지목된 항목은 삭제 | 남기면 기록 없이 복구된 다른 거래(다른 기기에서 시작된 구매 등)가 잘못 집어간다 |
| 카탈로그와의 우선순위 | **기록이 우선** | 정산이 며칠 뒤면 카탈로그 값은 이미 드리프트했다. day-1 결제를 day-2 가격으로 보내면 안 된다 |
| 기록 시점 | 결제 직전 (`purchase_service.dart`, `makePurchase` 호출 전) | 카탈로그가 확실히 메모리에 있는 유일한 시점 |
| `await` 여부 | 하지 않음 | 결제 시트가 뜨기 전에 로컬 I/O 를 기다리게 하면 안 된다. 기록이 필요해지는 것은 다음 실행이고 그 사이 인증·결제로 충분한 시간이 있다 |
| 조회 시점 | 카탈로그가 메모리에 없을 때만 | 있으면 카탈로그가 우선 |
| `ioTimeout` | 1초 (마커 저장소는 2초) | 정산 확정 후 5초 예산 안에서 일어난다. 오래 물면 정작 중요한 outbox 저장이 잘려 매출 payload 를 잃는다. **금액은 있으면 좋은 값, 거래 기록은 반드시 남아야 하는 값** |
| 용량 / 만료 | 50건 / 90일 | 만료된 값은 스토어 가격이 바뀌었을 수 있어 쓰지 않는다 — 틀린 매출은 누락보다 나쁘다 |
| 검증 | timestamp epoch 범위·미래 시각, 금액 유한·비음수, 통화 ISO 4217 형식 | 범위 밖 `at` 은 `DateTime.fromMillisecondsSinceEpoch` 에서 `RangeError` 를 던져, 손상 항목 하나가 전체 기록을 영구히 막는 poison blob 이 된다. 항목 단위로 버린다 |
| 동시성 | `AnalyticsMarkerMutex` 로 storage-key 직렬화. **mutex 대기까지 타임아웃으로 묶는다** | 직렬화 없이는 서로 다른 상품의 동시 기록이 lost update 를 낸다. 반대로 앞선 작업이 물리면 뒤가 전부 대기하므로, analytics 가 호출자를 붙잡지 않도록 전체를 시간 제한한다 |
| 실패 처리 | 기록·조회 실패 모두 삼키고 로그만. 전역 `supabase` 접근도 별도로 감싼다 | 금액이 비는 기존 동작으로 돌아갈 뿐 거래 사실은 보존된다. 전역 접근이 던지면 상위 try/catch 가 삼켜 **발송 자체가 사라지므로** 따로 막는다 |

손상된 저장 내용과 I/O 실패는 구분한다. 파싱되지 않는 값은 이미 쓸 수 없어
빈 상태로 축약하고 덮어쓴다(축약하지 않으면 손상된 blob 하나가 이후 모든
기록을 영구히 막는다). 반면 **읽기 실패를 "비어 있음"으로 축약하지 않는다** —
그러면 뒤이은 저장이 멀쩡한 기록을 통째로 덮어쓴다.

### 테스트에서 반드시 주입할 것

`PurchasePriceMemo` 는 기본으로 `globalStorage` 를 쓴다.
`NonWebLocalStorage` 의 정적 `SharedPreferences` future 는 자신이 생성된
`testWidgets` 존에 묶이므로, 그 존이 끝난 뒤 다른 테스트에서 `await` 하면
**영원히 완료되지 않는다.** `ioTimeout` 도 pump 없이는 진행되지 않아 소용없다.

`PurchaseService` 를 세우는 위젯 테스트는 반드시 메모리 저장소를 주입하라.

```dart
PurchaseService(
  purchasePriceMemo: PurchasePriceMemo(storage: _MemoryAnalyticsStorage()),
  // ...
)
```

`AnalyticsOutbox`, `PurchaseAnalyticsDedup`, `AnalyticsSendMarkerStore` 도
같은 이유로 같은 조치가 필요하다. **저장소를 쓰는 새 소비자를 추가할 때마다
반복되는 함정**이니, 추가 시 기존 위젯 테스트를 함께 확인하라.

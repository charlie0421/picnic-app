# GA4 purchase 매출(currency/value) 계약 설계

## 1. 배경

GA4 이벤트 택소노미는 `1.3.0+130007` 바이너리로 이미 프로덕션에 배포돼 있다(PR
#153, 머지 커밋 `d99118ab3`, 8/13 공개·강업). `purchase` 이벤트는 영수증 서버
검증이 성공한 시점에 발송되며, 정상 경로에서는 정확히 동작한다.

배포 후 남은 미해결 과제 하나가 이 문서의 대상이다. `docs/analytics/ga4-event-taxonomy.md`
§7 #1("카탈로그 미적재 복구 구매의 매출 누락")은 정산 확정 시점에 스토어
상품 카탈로그가 메모리에 없으면(`purchase_service.dart` 의
`_sendPurchaseAnalytics`) `currency`/`value` 없이 purchase 를 확정한다고
이미 기록하고 있고, 그 영향을 "**purchase 건수는 남지만 그 건의 매출액은
복원되지 않는다**"고 적어 두었다.

같은 문서 §8 은 "로컬 결제 시점 기록" 방식을 실제로 구현했다가(`38284d3a5`,
`1d9e90d9f`) 적대적 리뷰 3회에서 매번 새 blocker 가 나와 되돌린 경위를 남기고,
권장 방향으로 "정산 응답에 통화·금액을 포함"을 지목한 뒤 `requireExactContractKeys`
때문에 클라이언트 선배포가 필요하다는 제약까지 적어 두었다. 이 문서는 그
권장 방향을 실제로 구현 가능한 수준까지 구체화한 설계다 — 새로운 방향을
제안하는 문서가 아니라, 이미 좁혀진 방향의 계약 형태·값 출처·배포 순서·
실패 정책을 확정하는 문서다.

## 2. 레포 구조와 실제 배포 소스

이 설계는 두 레포에 걸친다.

- **picnic-app** (`picnic_lib/`) — 클라이언트. `PurchaseSettlementResultModel`
  파서, `AnalyticsService`, `PurchaseService` 가 이 레포에 있다.
- **picnic-supabase** — 서버. `verify_receipt`, `wallet-provider-event`,
  `wallet-operation-worker` Edge Function 과 `_shared/wallet/purchase-provider-verifiers.ts`,
  그리고 `public.wallet_purchase_result` 를 만드는 SQL 정산 함수가 이 레포에
  있다. **실제 프로덕션 배포 소스는 이 레포 하나뿐이다.**

picnic-app 레포 안에는 `picnic_app/supabase_dev/supabase/functions/verify_receipt/`
경로에 오래된 사본이 남아 있다. 이 사본은 배포되지 않으며 현재 서버 동작과
불일치한다(예: 이 문서가 인용하는 `wallet-provider-event`/`wallet-operation-worker`
2단계 구조, Apple 환경 다운그레이드 처리, `providerCurrency` 파이프라인이
사본에는 없다). **이 설계와 향후 구현은 picnic-supabase 레포만을 근거로 하며,
picnic-app 내 사본은 참고도 수정도 하지 않는다.**

## 3. 목표와 범위 제외

### 목표

- 정산 확정 시점에 스토어 상품 카탈로그가 없어도(복구 구매) `purchase` 이벤트가
  `currency`/`value` 를 가질 수 있게 한다.
- currency/value 의 단일 권위 출처를 서버로 만든다.
- 계약 확장이 기존 앱 버전을 깨지 않게 하는 배포 순서와 그 순서를 강제하는
  구체적 메커니즘을 정의한다.

### 비목표 / 범위 제외

- **배포 실행** — 태그·Codemagic·Shorebird 명령, 실제 배포 일정은 이 문서의
  범위가 아니다. §9 는 순서 "정책"만 정의하며 실행 절차는 별도 운영 문서가
  다룬다.
- **DB 마이그레이션 작성** — SQL 마이그레이션 파일, 컬럼 추가 문법은 이
  문서의 범위가 아니다. §5, §12 는 계약 모양과 영향받는 함수만 규정한다.
- **PR 작성** — 이 문서는 구현 계획이지 PR 본문이 아니다.
- **로그인(login) 중복 방지 메커니즘 재설계** — §10 에서 별도로 다루지만,
  결론만 먼저 밝히면 기존 방어를 그대로 쓴다. 이 설계가 손대는 대상이
  아니다.
- **Google 지역별 가격 카탈로그 구축** — §6, §14 에서 다루듯 Google 구매의
  provider 출처 currency/value 는 이번 설계 범위에서 얻을 수 없다(§6.2 근거).
  지역별 카탈로그로 근사하는 방안은 후속 과제로 명시적으로 분리한다(§15).

## 4. 문제: 카탈로그 미적재 복구 구매의 매출 유실

클라이언트에서 `currency`/`value` 는 오늘 다음 한 곳에서만 나온다.

`picnic_lib/lib/core/services/purchase_service.dart` 의 `_sendPurchaseAnalytics`
(현재 981~1023행)는 `container.read(storeProductsProvider).value` 로 얻은
**메모리에 이미 로드된** 스토어 카탈로그에서 구매한 `productID` 를 찾아
`ProductDetails` 를 얻고, 그 `currencyCode`/`rawPrice` 를
`AnalyticsService.logPurchasePayload` 의 `currency`/`value` 인자로 넘긴다.
카탈로그에 해당 상품이 없으면(앱 재시작 직후 정산이 카탈로그 로드보다
먼저 끝나는 경우, 카탈로그 조회 실패, 큐/reconcile 로 인한 지연 정산 등)
`productDetails` 가 `null` 이 되고 두 값은 함께 생략된다. 정산 사실과 지급량은
durable 하게 outbox 에 남지만, 그 거래의 매출액은 GA4 어디에도 기록되지
않는다.

서버는 이미 그 거래의 실제 검증 결과를 갖고 있다. `verify_receipt` →
`wallet-provider-event`(durable 인박스 커밋) → `wallet-operation-worker`(provider
검증 + 정산) 경로에서, `wallet-operation-worker/index.ts` 는 검증 결과
(`VerifiedPurchase`)의 `providerCurrency`/`providerPaidAmountMinor` 를 이미
`prepare_purchase_attestation`/`attest_verified_purchase`/`grant_verified_purchase`
RPC 호출 인자로 전달하고 있다(현재 343~399행). 즉 **이 값을 실어 나르는
배관은 이미 있다** — PayPal/PortOne 검증기(`verifyPayPal`/`verifyPortOne`,
`purchase-provider-verifiers.ts` 498행~)는 실제 통화·금액을 채워 넣는다. 다만
Apple/Google 검증기(`verifyApple`/`verifyGoogle`)는 각각 360~361행,
494~495행에서 `providerPaidAmountMinor: null, providerCurrency: null` 을
하드코딩하고 있고, `wallet.v1` 응답 계약(`purchaseSettlementKeys`, 7개 키) 자체에
currency/value 에 해당하는 키가 아예 없다. 이 설계는 이 두 지점을 메운다.

## 5. 서버 권위 currency/value 계약

### 5.1 현재 계약 (7키)

`picnic_lib/lib/data/models/purchase/purchase_settlement_result.dart` 의
`purchaseSettlementKeys`:

```
contract_version, operation_id, replayed,
base_star_amount, base_bonus_amount, promotion, wallet
```

이 키 집합은 `wallet_amount.dart` 의 `requireExactContractKeys` 로 검증된다 —
**실제 키 집합이 기대 집합과 정확히 같아야** 통과한다(개수 동일 +
`containsAll`). 하나라도 더 있거나 없으면 `FormatException`.

### 5.2 확장 계약 (7키 + 선택 2키)

새 선택 키 두 개를 추가한다.

| 키 | 타입(wire) | 의미 | 필수 여부 |
|---|---|---|---|
| `currency` | String 또는 부재 | ISO 4217 3자 코드 (예: `"USD"`, `"KRW"`) | 선택 |
| `value` | 10진 소수 문자열 또는 부재 (예: `"1.99"`) | 이 거래에서 실제로 결제된 금액(메이저 단위) | 선택 |

- **`contract_version` 은 `wallet.v1` 로 유지한다, bump 하지 않는다.** 이
  계약은 이미 한 번 확장된 전례가 있다 — `promotion` 키 도입 당시에도
  버전 문자열은 그대로였고, 구 형태를 위한 `PurchaseSettlementResultModel.fromLegacyJson`
  이 방어적으로 남아 있을 뿐 실사용 경로(`receipt_verification_service.dart:593`)는
  canonical 파서 하나만 부른다. `promotion` 은 **필수** 키였기 때문에 그
  선례는 "엄격한 선배포 순서"를 요구했다. `currency`/`value` 는 **선택** 키로
  설계하므로 같은 자리에 있으면서도 요구 조건은 더 약하다 — 버전을 나누는
  비용을 들일 이유가 없다.
- `value` 는 `WalletAmountConverter`(BigInt 전용, `base_star_amount` 등에 사용)를
  재사용하지 않는다. 그건 정수 캔디 수량을 위한 것이고 `value` 는 소수
  통화 금액이다. 대신 서버가 이미 쓰는 것과 같은 규율 — **숫자는 문자열로
  전송**(`exactMinorUnits` 의 `^\d+(\.\d+)?$` 검증, `purchase-provider-verifiers.ts:64`)
  — 을 따르는 별도의 가벼운 파서를 쓴다. JSON 부동소수점으로 보내지 않는
  이유는 이 레포의 다른 모든 금액 필드와 동일하다: 전송 중 정밀도 손실을
  원천 차단한다.
- 서버는 값이 없을 때 **키를 생략해도 되고 명시적 `null` 을 보내도 된다** —
  클라이언트 파서가 두 경우를 동일하게 취급한다(§8). 계약 문서 수준에서
  이 모호함을 없애 두는 이유는 서버 구현이 어느 쪽을 택하든(응답 직렬화기가
  null 필드를 자동으로 드롭하는 경우가 흔하다) 계약 위반이 되지 않게 하기
  위해서다.

### 5.3 "서버 권위"의 정확한 의미

서버 권위는 "서버 값이 있으면 항상 이긴다"는 뜻이지 "클라이언트 관찰값을
전혀 쓰지 않는다"는 뜻이 아니다. 서버가 `null` 을 준 경우에만(즉 서버가
이 거래에 대해 값을 제공하지 못한 경우에만) 기존 클라이언트 카탈로그
관찰값이 최후 수단으로 남는다 — §7 에서 정확한 우선순위를 정의한다. 계약
자체(키 모양·타입·null 규칙)는 Apple/Google 양쪽에 동일하게 적용된다.
다른 것은 각 provider 가 이 계약을 얼마나 자주 채울 수 있는가이며, 그건
§6 의 문제다.

## 6. Google/Apple 검증값 출처와 nullable/실패 정책

### 6.1 Apple — 이미 검증된 JWS 안에 있다

`verifyApple`(`purchase-provider-verifiers.ts:332`)은 이미
`verifyAppleJws(envelope.proof)` 로 App Store Server API 의
`JWSTransactionDecodedPayload` 를 암호학적으로 검증해 디코드한다. Apple 공식
문서 기준으로 이 payload 는 `price`(밀리유닛 정수, 예: `1990` = 1.99)와
`currency`(ISO 4217 3자 코드) 필드를 가질 수 있고, "`currency` 는 `price` 가
있을 때만 존재한다"고 명시돼 있다. 지금 코드는 `transactionId`, `productId`,
`environment`, `appAccountToken`, `quantity`, `purchaseDate` 만 읽고 `price`/
`currency` 는 아예 읽지 않는다 — **새 네트워크 호출이 필요 없다.** 이미 손에
있는, 이미 서명 검증을 통과한 구조체에서 필드 두 개를 더 읽는 것뿐이다.

- **출처**: `verifyAppleJws` 가 반환한 payload 의 `price`/`currency`.
- **nullable 정책**: 두 필드는 공식적으로 optional 이다(오래된 트랜잭션,
  일부 프로모션/패밀리 공유 케이스 등에서 부재 가능 — Apple 라이브러리
  생태계에 "price 필드가 안 보인다"는 리포트가 존재한다). 부재/타입 불일치
  시 `null` 로 폴백하고 **예외를 던지지 않는다.** 이미 같은 함수 안에
  선례가 있다: `purchaseDate` 를
  `typeof purchaseDate === 'number' ? new Date(purchaseDate).toISOString() : null`
  로 방어적으로 다룬다(359행) — `price`/`currency` 도 동일한 패턴을 따른다.
- **실패 정책**: 가격 필드 추출은 서명 검증이 이미 끝난 뒤 순수 필드 읽기이므로
  이 자체로 새로운 거부 사유가 생기지 않는다. `APPLE_TRANSACTION_MISMATCH`,
  `APPLE_OWNER_MISMATCH`, `APPLE_ENVIRONMENT_MISMATCH` 등 기존 터미널 거부
  판정에는 관여하지 않는다 — 가격 필드가 없다고 구매 자체를 거부하면 안
  된다. 매출 계측은 지급을 막을 이유가 될 수 없다는 원칙은 이 코드베이스
  전체에서 이미 확립돼 있다(`_sendPurchaseAnalytics` 문서 주석: "애널리틱스
  로깅 실패 - 구매 결과에는 영향 없음").

### 6.2 Google — provider 자체에 가격 필드가 없다

`verifyGoogle`(`purchase-provider-verifiers.ts:470`)은 Google Play Developer API
`purchases.products.get` (`androidpublisher/v3/.../purchases/products/{productId}/tokens/{token}`)
을 호출한다. 이 API 가 반환하는 `ProductPurchase` 리소스의 필드는
`kind`, `purchaseTimeMillis`, `purchaseState`, `consumptionState`,
`developerPayload`, `orderId`, `purchaseType`, `acknowledgementState`,
`purchaseToken`, `productId`, `quantity`, `obfuscatedExternalAccountId`,
`obfuscatedExternalProfileId`, `regionCode`, `refundableQuantity` 이다
(Google 공식 API 레퍼런스, 2026-08-21 확인). **가격·통화·결제 금액 필드가
존재하지 않는다.** 이는 코드의 누락이 아니라 API 자체의 한계다 — Apple 과
근본적으로 다른 상황이므로 같은 해법을 쓸 수 없다.

유일하게 쓸 수 있는 신호는 `regionCode`(ISO 3166-1 alpha-2, 구매 승인 시점의
결제 지역)다. 이 값과 Picnic 자체 상품 카탈로그를 결합하면 지역별 예상
가격을 **근사**할 수 있다 — `wallet-operation-worker/index.ts` 의
`assertWebProductPrice`(251~298행)가 이미 `products.web_price_krw`/
`web_price_usd` 를 상품 ID 로 조회하는 동일한 패턴을 PortOne 경로에 쓰고
있다. 하지만 이 근사는 Apple 의 `price`/`currency` 와 성격이 다르다:
Apple 값은 **provider 가 증언한 실제 결제액**이고, Google regionCode 기반
카탈로그 값은 **Picnic 이 추정한 목록가**다 — 프로모션, 반올림, 세금
표시 방식 차이로 실제 결제액과 어긋날 수 있고, 카탈로그가 커버하지 않는
지역은 여전히 값을 못 만든다.

- **출처(이번 설계 범위)**: 없음. Google 은 이번 phase 에서 `providerCurrency`/
  `providerPaidAmountMinor` 를 계속 `null` 로 둔다 — 오늘과 동일한 동작이며
  회귀가 아니다.
- **후속 과제(이번 범위 밖, §15)**: `regionCode` + 지역별 가격 카탈로그
  확장으로 근사치를 만드는 방안은 별도 설계로 분리한다. 이유는 두 가지다.
  (1) 지역별 카탈로그 구축·유지는 그 자체로 별개 규모의 작업이고 데이터
  정확성 리스크(카탈로그 drift, 커버리지 공백)가 Apple 경로와 질적으로
  다르다. (2) `assertWebProductPrice` 를 그대로 재사용하면 안 된다 —
  **그 함수는 무결성 게이트다**(`refundRatioBasis === 'AMOUNT'` 인 PayPal/
  PortOne 에서 provider 가 보고한 결제액이 카탈로그와 다르면 정산 자체를
  거부한다). Google 은 `refundRatioBasis: 'QUANTITY'` 라 지급 정합성이
  가격과 무관하다 — 향후 Google 카탈로그 근사치를 추가하더라도 그건 순수
  매출 계측 보강이지 무결성 게이트가 아니어야 한다. 조회 실패·불일치가
  정산 거부로 이어지면 §6.1 과 같은 원칙(계측이 지급을 막지 않는다)을
  깨는 회귀가 된다.

### 6.3 실패 정책 요약

| 상황 | 정책 |
|---|---|
| Apple JWS 에 `price`/`currency` 없음 또는 타입 불일치 | `null` 로 폴백, 검증/지급 계속 진행 |
| Google 응답에 가격 필드 없음(항상 그렇다) | `null` 유지, 검증/지급 계속 진행 — 오늘과 동일 |
| currency/value 추출 코드 자체가 예외를 던짐(방어 코드 버그) | 해당 필드만 `null` 로 잡아먹고 로그, 정산 트랜잭션을 실패시키지 않음 |
| 두 값 중 하나만 있고 하나가 없음(예: `price` 있는데 `currency` 파싱 실패) | 둘 다 `null` 로 취급 — GA4 는 `currency` 없는 `value` 를 ISO 4217 위반으로 판정해 해당 purchase 의 매출 전체를 무시하므로(`ga4-event-taxonomy.md` §4-8), 짝이 안 맞는 값을 절반만 보내는 것보다 둘 다 생략하는 편이 안전하다 |

이 표의 마지막 행은 이미 taxonomy 문서 §4-8 에서 확립된 규칙을 currency/value
출처가 서버로 바뀌어도 그대로 적용한 것이다 — 규칙을 새로 만들지 않는다.

## 7. Analytics 우선순위

`_sendPurchaseAnalytics` 가 `AnalyticsService.logPurchasePayload` 를 호출할 때
`currency`/`value` 를 정하는 우선순위:

1. **서버 정산 응답의 `currency`/`value`(둘 다 non-null 일 때)** — 존재하면
   무조건 이 값을 쓴다. 클라이언트 카탈로그 값과 비교·병합하지 않는다.
2. **서버가 `null` 을 준 경우에만** — 기존 로직대로 `container.read(storeProductsProvider).value`
   에서 찾은 `ProductDetails.currencyCode`/`rawPrice` 를 쓴다(오늘의 동작,
   변경 없음). 이 경로는 서버 계약이 아직 이 필드를 안 보내는 구버전
   contract_version 이나, Google 처럼 provider 가 값을 못 주는 경우를 모두
   자연스럽게 커버한다 — 별도 분기가 필요 없다.
3. **둘 다 없음** — 기존과 동일하게 `currency`/`value` 를 함께 생략하고,
   거래·지급 사실은 그대로 durable 하게 outbox 에 남긴다.

이 우선순위가 §4 의 문제를 정확히 푸는 지점은 2번과 3번 사이다: 오늘은
카탈로그가 없으면 바로 3번(둘 다 생략)으로 떨어지지만, 서버가 값을 채워
보내는 순간부터는 카탈로그 부재와 무관하게 1번에서 끝난다 — **복구 구매의
매출 유실이 카탈로그 가용성에 더 이상 의존하지 않는다.**

변경 지점은 `purchase_service.dart` 의 `_sendPurchaseAnalytics` 딱 한 곳이다
(현재 1014~1015행의 `currency: productDetails?.currencyCode` /
`value: productDetails?.rawPrice` 를 위 우선순위로 교체). `AnalyticsService.logPurchasePayload`
자체는 이미 nullable `currency`/`value` 를 받는 인터페이스이므로 시그니처
변경이 없다.

## 8. 앱 forward-compatible 파서

### 8.1 왜 기존 `requireExactContractKeys` 를 고치지 않는가

`requireExactContractKeys`(`wallet_amount.dart:45`)는 purchase
settlement(`purchase_settlement_result.dart` 안에서 3곳 — `promotion` 객체
파싱 1곳, canonical/legacy 정산 파싱 각 1곳) 말고도
`vote_transaction.dart`(2곳), `ad_reward_status.dart`(5곳),
`promotion_campaign.dart`(3곳), `payment_breakdown.dart`(1곳),
`currency_history.dart`(2곳), `wallet_summary.dart`(1곳),
`pending_ad_reward_store.dart`(1곳) — 7개 파일 15곳에서 더 쓰인다. 이
함수의 "정확히 일치"라는 엄격함은 그 모델들이 계약 드리프트(오타, 필드
누락, 서버가 실수로 여분 필드를 보내는 것)를 즉시 잡아내는 안전장치다.
purchase settlement 하나를 위해 이 함수의 의미를 느슨하게 바꾸면 나머지
15곳 모두가 같이 느슨해진다 — 의도하지 않은 매우 넓은 blast radius다.
그래서 기존 함수는 손대지 않고, 옆에 새 함수를 추가한다.

### 8.2 새 헬퍼

`wallet_amount.dart` 에 `requireExactContractKeys` 와 나란히 추가한다(같은
파일에 두는 이유: 이 파일이 이미 "계약 키 검증 유틸리티"의 정본 위치이고,
purchase 외에 다른 모델이 나중에 같은 방식의 선택 키 확장을 필요로 할 때도
재사용할 수 있다 — 단, 그 모델들을 지금 이 설계에서 같이 바꾸지는 않는다).

```dart
Map<String, dynamic> requireContractKeys(
  Map<String, dynamic> json, {
  required Set<String> required,
  required Set<String> optional,
}) {
  final actual = json.keys.toSet();
  final allowed = {...required, ...optional};
  if (!actual.containsAll(required) || !allowed.containsAll(actual)) {
    throw FormatException(
      'Contract keys differ: required $required, optional $optional, got $actual',
    );
  }
  return {
    for (final key in allowed) key: json.containsKey(key) ? json[key] : null,
  };
}
```

동작 방식:

- **필수 키가 하나라도 없으면** 여전히 `FormatException` — 기존 안전성
  유지.
- **`required ∪ optional` 에 없는 키가 하나라도 있으면** 여전히
  `FormatException` — "아무 여분 키나 허용"이 아니라 "미리 이름 붙인
  선택 키만 허용". drift 감지 능력을 유지한 채로 허용 범위만 넓힌다.
- **선택 키가 아예 없거나 명시적으로 `null` 이면 결과 맵에서 동일하게
  `null`** — §5.2 에서 정한 "생략해도, null 을 보내도 된다"를 여기서
  정규화한다. 이 정규화 덕분에 `_$PurchaseSettlementResultModelFromJson`
  이 생성하는 코드는 항상 `currency`/`value` 키가 맵에 존재한다고 가정할
  수 있다.

### 8.3 모델 변경

`purchase_settlement_result.dart`:

- `purchaseSettlementKeys`(기존 7개, 이름 유지)를 `required` 로 쓴다.
- `purchaseSettlementOptionalKeys = {'currency', 'value'}` 를 새로 정의한다.
- `parseCanonicalPurchaseSettlement` 안의 `requireExactContractKeys(json, purchaseSettlementKeys)`
  호출을 `requireContractKeys(json, required: purchaseSettlementKeys, optional: purchaseSettlementOptionalKeys)`
  로 바꾼다. `parseLegacyPurchaseSettlement` 는 건드리지 않는다 — 그건
  `promotion` 부재 시절 형태를 위한 방어적 하위 호환 경로이고, currency/value
  는 그 시절에도 존재하지 않았으므로 영향받을 이유가 없다.
- 모델에 `String? currency`, `num? value` 필드를 추가한다(둘 다 nullable,
  `@JsonKey(name: 'currency')`/`'value'`).
- `value` 의 wire 인코딩(10진 문자열)을 파싱하는 작은 컨버터를 추가한다.
  `WalletAmountConverter` 를 재사용하지 않는 이유는 §5.2 에 이미 적었다 —
  BigInt 정수 전용이라 소수 금액에 맞지 않는다.

### 8.4 이 파서가 "먼저" 배포돼야 하는 이유

서버가 `wallet.v1` 응답에 `currency`/`value` 를 추가하는 순간, 이 새 헬퍼가
없는 구버전 앱은 여전히 `requireExactContractKeys(json, purchaseSettlementKeys)`
를 호출하고 있고, 그 함수는 "실제 키 개수 == 기대 키 개수"를 요구한다.
서버가 9개 키를 보내는데 클라이언트가 7개를 기대하면 즉시
`FormatException` — 이미 지급이 끝난 정산 응답 전체를 파싱하지 못해
사용자에게는 결제가 실패한 것처럼 보인다(정확히 taxonomy 문서 §8 이 경고한
실패 모드, 그리고 `verify_receipt/index.ts` 87~96행 주석이 인용하는 실제
사고 "v7 이 success 봉투를 추가해서 정산된 구매가 클라이언트에서 계약
위반으로 실패 처리된" 사고와 같은 종류). §9 가 이 순서를 정책으로
못박는다.

## 9. 배포 순서 정책 — 앱 선배포 → 서버 후배포

### 9.1 순서

1. §8 의 forward-compatible 파서를 담은 앱 릴리스를 먼저 배포한다.
2. 서버가 `currency`/`value` 를 채워 보내기 시작한다.

이 순서 자체는 §1 이 인용한 taxonomy 문서 §8 에서 이미 결정돼 있다(§8.4 도
같은 근거). 이 문서가 추가하는 것은 "순서를 지켰다고 끝이 아니다"라는
점과 그 잔여 위험을 없애는 구체적 메커니즘이다.

### 9.2 "선배포"만으로는 충분하지 않다

Shorebird OTA 든 스토어 신규 빌드든, 배포는 그 시점 이후 실행되는 앱에만
적용된다. 이미 설치돼 있고 한동안 열리지 않는 구버전 바이너리, 또는
업데이트를 미루는 사용자는 새 파서를 영영 받지 못할 수 있다. "앱을 먼저
배포했다"는 사실이 "모든 활성 클라이언트가 새 파서를 갖고 있다"를
보장하지 않는다 — 이 간극을 메우지 않으면 §8.4 의 실패 모드가 롱테일
사용자에게서 계속 재현된다.

### 9.3 권장 메커니즘 — 서버가 `app_build` 로 자체 게이팅한다

서버는 이미 이 신호를 받고 있다. `verify_receipt/index.ts` 74행이 요청
본문에서 `app_build` 를 읽어 `envelope.requestContext` 에 담고, 이는
`IntakeEnvelope.requestContext.app_build`(`purchase-provider-verifiers.ts:19`)로
검증기까지 전달되며, `wallet-provider-event/index.ts:39` 는 이 값이 정수가
아니면 요청 자체를 거부할 정도로 이미 필수 신호로 취급한다. **클라이언트
쪽에 새 필드를 추가할 필요가 없다** — 이미 매 검증 요청마다 실려 오는
값이다.

권장 설계: `wallet-operation-worker`(또는 응답을 조립하는 SQL 함수)가
응답에 `currency`/`value` 를 실을지 여부를 `requestContext.app_build` 와
설정된 최소 build 번호를 비교해 결정한다. 최소 build 미만이면 두 키를
생략(또는 `null`)하고, 그 이상이면 채운다. 이러면:

- 새 파서를 아직 못 받은 구버전 앱은 서버가 애초에 새 키를 안 보내므로
  §8.4 의 실패 모드에 노출될 수 없다 — "많은 사용자가 업데이트했기를
  바란다"가 아니라 **구조적으로 안전**하다.
- "선배포 → 후배포"라는 요구사항의 실행 방식이 "전체 사용자 업데이트를
  기다린 뒤 서버를 한 번에 바꾼다"가 아니라 "서버가 요청 단위로 안전하게
  전환한다"가 된다 — 롤아웃 속도가 사용자 업데이트 속도에 묶이지 않는다.
- 정확한 최소 `app_build` 값은 이 설계를 구현하는 실제 릴리스의 build
  number 로 정한다(이 문서 작성 시점엔 아직 없는 값이므로 여기서 확정하지
  않는다 — §3 비목표의 "배포 실행 제외"와 일관된다). 필요한 건 값이 아니라
  이 게이팅이 존재한다는 설계 결정이다.

이 메커니즘은 새 유틸리티를 발명하는 게 아니다 — `app_build` 가 이미
`purchase_reward_snapshots` 테이블에 거래별로 영속 기록되고 있다는 사실(요청
컨텍스트 스키마 확인) 위에, 응답 조립 시점의 조건 분기 하나를 추가하는
것뿐이다.

## 10. 로그인 중복 — 범위 밖, 기존 방어로 충분

이 설계는 `purchase` 이벤트의 currency/value 계약을 다루지, `login`/`sign_up`
중복 방지 메커니즘을 다루지 않는다. 이 절은 그 경계를 명시하기 위해서만
존재한다 — 구매 계약과 무관한 별개 이벤트임에도 남은 작업 목록에서
자주 같이 언급되기 때문에, 이 문서가 로그인 중복까지 재설계한다는
오해를 막는다.

- **기존 방어**: `AuthAnalyticsResolver.buildLoginSignature({userId,
  lastSignInAt})`(`picnic_lib/lib/core/analytics/auth_analytics_resolver.dart`)가
  `'$userId|$lastSignInAt'` 서명을 만들어 저장해 두고, 앱 재시작으로
  세션이 복원돼 `signedIn` 이 재발화해도 `lastSignInAt` 이 그대로면 서명이
  같아 `login` 재발송을 막는다. `sign_up` 판정은 별도로 `createdAt` 과
  `lastSignInAt` 의 차이가 30초 이내인지로 독립 판정한다(같은 파일).
- **이 설계에서 손대는 부분**: 없음.
- **남은 작업**: 이 방어가 실기기에서 실제로 동작하는지 확인하는 일만
  남아 있고, 그 확인 수단은 이미 정해져 있다 — 기존 자동화 테스트
  스위트와 DebugView 실측(`adb shell setprop
  debug.firebase.analytics.app`, iOS 는 `-FIRDebugEnabled` 실행 인자)이다.
  확인 체크리스트는 `docs/operations/handoff-20260821-ga4-taxonomy.html`
  §3-②에 이미 있다("앱 재시작 시 재발송 없음" 항목). 이 문서가 그 체크
  리스트를 대체하거나 새로 만들지 않는다.

## 11. 오류 처리

| 계층 | 상황 | 처리 |
|---|---|---|
| 서버 · Apple 검증 | JWS 에 `price`/`currency` 없음/타입 불일치 | 필드만 `null`, 검증·정산 계속(§6.1) |
| 서버 · Google 검증 | 애초에 provider 가 값을 안 줌 | 오늘과 동일하게 `null` 유지, 회귀 아님(§6.2) |
| 서버 · 응답 조립 | `app_build` 가 게이팅 기준 미만 | `currency`/`value` 생략, 기존 7키 계약으로 응답(§9.3) |
| 서버 · 응답 조립 | `currency` 만 있고 `value` 파싱 실패 등 비대칭 | 둘 다 `null` 로 낮춰서 응답(§6.3) — ISO 4217 위반으로 GA4 가 매출 전체를 버리는 사고를 원천 차단 |
| 클라이언트 · 파서 | 새 헬퍼 배포 전, 서버가 실수로 새 키를 먼저 보냄 | 여전히 `FormatException`(`requireExactContractKeys` 미변경) — §9 순서를 어기면 기존과 동일하게 시끄럽게 실패한다. 이건 의도된 동작이다: 조용히 매출을 잃는 것보다 낫다 |
| 클라이언트 · 파서 | 새 헬퍼 배포 후, 계약에 없는 제3의 키가 섞여 옴 | 여전히 `FormatException` — drift 감지 유지(§8.2) |
| 클라이언트 · analytics 우선순위 | 서버 값도 카탈로그 값도 없음 | `currency`/`value` 함께 생략, 거래·지급 payload 는 그대로 outbox 에 durable 저장(§7-3, 기존 동작) |
| 클라이언트 · analytics 전송 | `logPurchasePayload` 호출 자체가 실패/타임아웃 | 이 설계로 바뀌지 않는다 — 기존 outbox/dedup/재시도 정책(taxonomy 문서 §6) 그대로 적용 |

공통 원칙 하나로 위 표 전체를 요약할 수 있다: **currency/value 획득·전달
경로의 실패는 항상 "그 필드를 생략한다"로 흡수되고, 절대 "지급을
거부한다" 또는 "정산을 실패시킨다"로 번지지 않는다.** 이는 새로 만드는
원칙이 아니라 §4 문제 자체가 이미 증명하고 있는 이 코드베이스의 기존
설계 철학 — "숫자를 지어내지 않고 거래 사실부터 durable 하게 남긴다" —
을 currency/value 소스가 서버로 바뀐 뒤에도 유지하는 것이다.

## 12. 두 레포 파일 목록

### picnic-app (`picnic_lib/`)

| 파일 | 변경 내용 |
|---|---|
| `lib/data/models/wallet/wallet_amount.dart` | `requireContractKeys(required:, optional:)` 헬퍼 추가. `requireExactContractKeys` 는 수정하지 않음 |
| `lib/data/models/purchase/purchase_settlement_result.dart` | `purchaseSettlementOptionalKeys` 추가, `parseCanonicalPurchaseSettlement` 가 새 헬퍼 사용, 모델에 `currency`/`value` nullable 필드 추가, 소수 문자열 컨버터 추가 |
| `lib/core/services/purchase_service.dart` | `_sendPurchaseAnalytics` 의 currency/value 결정 로직을 §7 우선순위로 교체 |
| `lib/presentation/widgets/vote/store/purchase/analytics_service.dart` | 시그니처 변경 없음. 상단 문서 주석 중 "카탈로그가 없으면 생략" 서술을 새 우선순위에 맞게 갱신 |
| `test/data/models/purchase/purchase_settlement_result_test.dart` | §13 신규 케이스 |
| `test/core/services/purchase_service_logic_test.dart` | §13 신규 케이스 |
| `test/presentation/widgets/vote/store/purchase/purchase_revenue_analytics_test.dart` | §13 신규 케이스(기존 431행 "카탈로그가 비어도..." 테스트와 대칭되는 케이스 추가) |

이 설계로 변경하지 않는 파일(확인됨, 참고용):
`lib/presentation/widgets/vote/store/purchase/purchase_settlement_step.dart`
는 currency/value 참조가 전혀 없어 무관하다.
`lib/data/models/wallet/candy_reward_receipt.dart` 에는 `currency` 라는
이름의 필드가 실제로 있지만 **이름만 같을 뿐 다른 개념**이다 — 그건
`WalletCurrency`(스타캔디/보너스 스타캔디/코튼캔디를 구분하는 이 코드베이스
자체 열거형)이고, 이 설계가 §5 에서 정의하는 ISO 4217 통화 코드
`currency`(GA4 wire 계약의 새 키)와는 타입도 용도도 다르다. 헷갈리기 쉬운
이름이라 명시해 둔다 — 이 파일도 변경 대상이 아니다.
`AnalyticsService.logPurchaseEvent`(`ProductDetails` 오버로드)는 프로덕션
호출부가 없고(`purchase_analytics_dedup_test.dart` 에서만 테스트 목적으로
호출됨) 이 설계와 무관하므로 변경하지 않는다.

### picnic-supabase

| 파일 | 변경 내용 |
|---|---|
| `supabase/functions/_shared/wallet/purchase-provider-verifiers.ts` | `verifyApple`: `payload.price`/`payload.currency` 읽어 `providerPaidAmountMinor`/`providerCurrency` 채움(360~361행 대체). `verifyGoogle`: 이번 phase 는 변경 없음(494~495행 유지, §6.2) |
| `supabase/functions/wallet-operation-worker/index.ts` | `processInbox` 자체는 변경 없음(이미 `verified.providerCurrency`/`providerPaidAmountMinor` 를 RPC 인자로 전달 중, 343~399행). 응답 조립 지점에 §9.3 의 `app_build` 게이팅 추가 |
| `supabase/functions/verify_receipt/index.ts` | 로직 변경 없음(그대로 pass-through). 87~96행의 "정확히 7키" 주석을 새 계약 모양에 맞게 갱신 |
| `supabase/functions/tests/wallet/apple-verifier.test.ts` | §13 신규 케이스 |
| `supabase/functions/tests/wallet/apple-jws-fixture.ts` | `price`/`currency` 를 포함한 서명된 JWS 픽스처 추가(및 없는 버전과의 비교용 픽스처) |
| `supabase/functions/tests/wallet/operation-worker.test.ts` | §13 신규 케이스 |
| `supabase/functions/tests/wallet/purchase-settlement.test.ts` | §13 신규 케이스 |

DB 스키마(`public.wallet_purchase_result` 타입, 이를 반환하는 정산 함수들 —
`20260721103500_purchase_settlement_commands.sql` 등)는 `currency`/`value` 를
응답에 실으려면 결국 바뀌어야 하지만, 정확한 마이그레이션 작성은 §3
비목표에 따라 이 문서의 범위 밖이다. `provider_currency` 컬럼 자체는 이미
스키마에 존재한다(`purchase_reward_schema.sql`) — 이번에 새로 만드는 것은
그 값을 API 응답 계약에 노출하는 부분이다.

## 13. TDD 계획

RED 를 먼저 쓰고, 그 RED 가 위 설계대로 구현했을 때만 GREEN 이 되는지
확인하는 순서로 진행한다.

### picnic-app

1. **`purchase_settlement_result_test.dart`**
   - 7키 + `currency`/`value` 모두 있는 JSON → 파싱 성공, 필드에 그대로 반영.
   - 7키만 있고 `currency`/`value` 없는 JSON(오늘 프로덕션이 실제로 보내는
     모양) → 파싱 성공, 두 필드는 `null`(하위 호환 회귀 테스트).
   - `currency` 만 있고 `value` 없는 비대칭 JSON → 파싱 자체는 성공(파서는
     독립적으로 허용 — GA4 발송 시 함께 생략하는 판단은 analytics 계층
     책임, §6.3).
   - 계약에 없는 제3의 키(`foo`)가 섞인 JSON → 여전히 `FormatException`
     (drift 감지 유지 회귀).
   - 기존 7키 중 하나라도 빠짐 → 여전히 `FormatException`(기존 동작 불변
     회귀).
2. **`purchase_revenue_analytics_test.dart`**
   - **핵심 성공 기준**: 서버 응답에 `currency`/`value` 있음 + 카탈로그
     없음(`catalogue: () => []`, 기존 431행 테스트와 동일 셋업) → outbox 에
     들어가는 payload 의 `currency`/`value` 가 서버 값으로 채워짐. 이
     테스트가 §4 문제의 해결을 직접 증명한다.
   - 서버 값과 카탈로그 값을 **의도적으로 다르게** 설정 → 서버 값이 쓰이고
     카탈로그 값은 버려짐(§7 우선순위 1번 확정).
   - 서버가 `null`, 카탈로그는 로드됨 → 카탈로그 값 사용(§7 우선순위
     2번, 기존 동작 유지 회귀).
   - 서버도 `null`, 카탈로그도 없음 → 기존 431행 테스트 그대로 유지(회귀
     없음 확인).
3. **`purchase_service_logic_test.dart`** — `_sendPurchaseAnalytics` 가
   `PurchaseSettlementResultModel.currency`/`value` 를 실제로 읽어 우선순위
   로직에 넘기는지 단위 수준에서 확인.

### picnic-supabase

1. **`apple-verifier.test.ts`** (+ `apple-jws-fixture.ts` 확장)
   - `price`/`currency` 포함 서명된 JWS → `VerifiedPurchase.providerCurrency`/
     `providerPaidAmountMinor` 가 그 값으로 채워짐(현재 구현에서는 실패해야
     정상인 RED).
   - `price`/`currency` 없는(과거 형태) JWS → 검증은 여전히 성공, 두 필드만
     `null`(throw 하지 않는다는 정책의 회귀 테스트).
   - `price` 는 있는데 `currency` 형식이 깨진 경우 → 둘 다 `null` 로 폴백,
     예외 없음.
2. **`operation-worker.test.ts`**
   - Google 응답(가격 필드 없음, 오늘과 동일) → `providerCurrency`/
     `providerPaidAmountMinor` 는 `null` 유지, 정산은 정상 진행(거부되지
     않음) — §6.2 의 "이번 phase 는 변경 없음" 결정을 회귀로 고정.
   - `requestContext.app_build` 가 게이팅 기준 미만인 요청 → 응답에서
     `currency`/`value` 생략(§9.3 회귀 테스트).
   - 게이팅 기준 이상 + Apple 값 있음 → 응답에 `currency`/`value` 포함.
3. **`purchase-settlement.test.ts`**
   - `wallet_purchase_result` 로 나가는 `currency`/`value` 가
     `attest_verified_purchase`/`grant_verified_purchase` 에 전달한
     `p_provider_currency`/`p_provider_paid_amount_minor` 와 일치하는지.

## 14. 대안 비교와 권고

### 대안 1 — 로컬 결제 시점 기록 (이미 시도, 되돌림)

결제 직전 클라이언트가 통화·금액을 로컬에 남겨 두고 정산/복구 시점에
읽는 방식. 실제로 구현했다(`38284d3a5`, `1d9e90d9f`)가 적대적 리뷰 3회에서
매번 새 blocker 가 나와 되돌렸다: 거래 결합 불가(취소된 시도와 구분 불가),
시각 매칭의 한계(시계 오차 창 안의 이후 시도가 정답을 가로챔), 소비
시점 딜레마(저장 전 소비하면 실패 시 영구 손실, 안 하면 다른 거래가
가로챔), `Future.timeout` 이 하위 I/O 를 취소하지 못해 생기는 손상 가능성.

**기각.** 근거가 추측이 아니라 실측(3회 리뷰, 매번 다른 blocker)이다.
근본 원인은 이 방식이 outbox 가 이미 풀어낸 exactly-once 문제를 "필드
하나"를 위해 클라이언트에서 다시 구현하는 것이라는 데 있다 — 얻는 값에
비해 재구현 비용이 너무 크다.

### 대안 2 — 사후 정산·스토어 리포트 기반 매출 백필

정산 시점엔 currency/value 없이 `purchase` 를 그대로 보내고, 이후 배치로
Apple Sales and Trends / Google Play 재무 리포트 같은 공식 정산 리포트와
대조해 매출을 복원하는 방식. 스토어가 공식 발행하는 데이터를 근거로
삼는다는 점은 매력적이다.

**기각.** 세 가지 이유가 겹친다. (1) GA4 는 이미 수집된 이벤트의
파라미터를 사후에 고칠 수 없다 — 원본 `purchase` 를 나중에 "고치는" 게
아니라 별도의 새 이벤트(예: 매출 백필용 커스텀 이벤트)를 또 만들어야
하고, 그건 새 택소노미 항목이라 대행사 승인이 또 필요하다(현재도
`docs/analytics/agency-reply.html` 에 회신 대기 중인 항목이 3건 있다 —
협상 채널을 하나 더 여는 셈). (2) 스토어 재무 리포트는 거래 단위가 아니라
집계 단위인 경우가 많고 지연도 크다(T+수일) — 개별 `transaction_id` 와
1:1로 재결합하는 신뢰 가능한 매핑을 새로 만들어야 한다. (3) 이 코드베이스의
`purchase` 발송은 "영수증 검증 성공 직후 즉시"라는 불변식 위에 outbox
설계 전체가 서 있다(`ga4-event-taxonomy.md` §6 "Durable analytics outbox"의
재시도 정책 표) — 지연-후-백필은 그 불변식을 깨고 파이프라인을 사실상
두 개로 만든다.

### 대안 3 — 서버 정산 응답에 통화·금액 포함 (권고)

§5~§9 에서 구체화한 설계. 서버가 이미 검증 과정에서 알고 있는(또는 이미
배관이 있는) 값을 정산 응답에 실어 클라이언트가 그대로 쓰게 한다.

**권고 근거**:

- 결합·소비 시점·mutex·예산 문제가 구조적으로 사라진다(대안 1 이 실패한
  지점 전부) — 서버는 이미 그 거래의 유일한 검증 결과를 갖고 있으므로
  "어느 시도인지 지목"할 필요 자체가 없다.
- 새 이벤트·새 대행사 협의가 필요 없다(대안 2 가 요구하는 것) — 기존
  `purchase` 이벤트의 기존 파라미터를 더 자주 채우는 것뿐이다.
- Apple 쪽은 **추가 네트워크 호출 없이** 이미 검증된 데이터에서 필드
  두 개를 더 읽는 것뿐이라 구현 리스크가 낮다.
- Google 쪽은 이번 phase 에서 값을 얻지 못한다는 한계를 그대로 인정한다
  — 없는 것을 있는 척 설계하지 않는다. `assertWebProductPrice` 를 그대로
  재사용하고 싶은 유혹이 있지만 §6.2 에서 설명했듯 그 함수는 무결성
  게이트이지 계측 보강 도구가 아니어서 그대로 가져오면 안 된다.
- `app_build` 게이팅(§9.3)이 "선배포 → 후배포"라는 요구사항을 "사용자
  업데이트를 기다리는 느슨한 순서 지침"에서 "요청 단위로 안전한 전환"으로
  바꾼다 — 이미 서버가 받고 있는 신호 위에 조건 하나만 추가하면 된다.

## 15. 이 설계가 새로 남기는 한계

`ga4-event-taxonomy.md` §7 "알려진 한계" 표 형식을 따라, 이 설계를 구현한
뒤에도 남는 한계를 명시한다.

| # | 한계 | 내용 | 처리 |
|---:|---|---|---|
| 1 | Google 구매의 매출 유실은 그대로 남는다 | §6.2 에 따라 이번 phase 는 Google `currency`/`value` 를 계속 `null` 로 둔다 | 후속 과제(지역별 카탈로그 근사)로 명시적으로 분리. 무결성 게이트와 섞지 않는다는 제약(§6.2)이 있는 별개 설계가 필요 |
| 2 | Apple 값도 항상 보장되지는 않는다 | `price`/`currency` 는 공식적으로 optional 필드라 일부 트랜잭션에서 여전히 부재할 수 있다 | §6.3 실패 정책대로 `null` 처리, §4 문제가 "가끔"으로 줄어드는 것이지 "완전히 사라지는 것"은 아니다 |
| 3 | Google 근사치(후속 구현 시)는 provider 증언이 아니다 | 지역별 카탈로그로 채운 값은 Apple 처럼 provider 가 확인해 준 실제 결제액이 아니라 Picnic 이 추정한 목록가다 | 후속 설계에서 이 차이를 데이터 신뢰도 라벨로 구분할지 결정 필요 — 이번 문서에서 선결하지 않음 |
| 4 | `app_build` 롤아웃 게이팅 기준값 자체는 사람이 정한다 | 어떤 build 번호부터 "새 파서 탑재"로 볼지는 실제 배포 시점에 확정되는 운영 값이다 | §3 비목표에 따라 이 문서는 메커니즘만 규정하고 값은 배포 작업에서 정한다 |

## 16. 참고 문서

| 경로 | 내용 |
|---|---|
| `docs/analytics/ga4-event-taxonomy.md` | 택소노미 기준 문서. §2-9 `purchase` 파라미터 정의, §4-8 currency undefined 대체 불가 규칙, §7 #1 이 문서가 푸는 한계, §8 이미 좁혀진 권장 방향 |
| `docs/analytics/trigger-mapping.md` | §9 `purchase` 트리거 지점(계획 당시 문서, 현재 라인 번호와는 다름) |
| `docs/operations/handoff-20260821-ga4-taxonomy.html` | 8/21 시점 상태 핸드오프. §3-④ 가 이 문서가 구체화한 미해결 과제, §3-② DebugView 체크리스트(로그인 중복 검증 포함) |
| `docs/analytics/agency-reply.html` | 대행사 회신 대기 항목(대안 2 기각 근거로 인용) |

---

이 문서 작성 과정에서 스스로 점검한 것: (1) "서버 권위"와 "서버가 null
이면 클라이언트 값을 쓴다"가 모순처럼 보일 수 있어 §5.3 에서 관계를
명시했다. (2) Google 을 Apple 과 같은 수준으로 "provider 검증값"이라고
뭉뚱그리면 사실과 다르므로 §6.2 에서 API 자체의 한계로 명확히 구분했다.
(3) `assertWebProductPrice` 를 Google 에 그대로 재사용하자는 자연스러운
제안을 §6.2 에서 검토했으나 무결성 게이트와 계측 보강의 목적이 다르다는
이유로 명시적으로 배제했다. (4) "앱 선배포"가 실제로 무엇을 보장하고
무엇을 보장하지 않는지 §9.2 에서 분리하고, 부족한 부분을 §9.3 의 구체
메커니즘으로 메웠다. (5) 배포·마이그레이션·PR·로그인 중복 재설계·Google
카탈로그 구축은 각 절에서 반복해 범위 밖임을 명시해, 읽는 사람이 이
문서의 승인을 그 작업들의 승인으로 착각하지 않게 했다. (6) §12 파일
목록을 작성하며 "변경 없음"이라 적으려던 `candy_reward_receipt.dart` 를
실제로 확인해 보니 `currency` 라는 이름의 필드가 이미 존재했다 — 이
설계의 ISO 4217 `currency` 와는 다른 개념(`WalletCurrency` 열거형)임을
확인하고 혼동 가능성을 명시적으로 적었다. 문서 안의 "§N" 절 번호가 이
문서 자체와 인용하는 taxonomy 문서 양쪽에 겹쳐 존재해 모호했던 지점들도
전부 "taxonomy 문서 §N" 형태로 명시해 구분했다.

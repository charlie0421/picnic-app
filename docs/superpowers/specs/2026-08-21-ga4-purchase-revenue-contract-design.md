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

**클라이언트가 실제로 호출하는 엔드포인트 이름은 `verify_receipt` 가 아니라
`verify-receipt-v2` 다.** `supabase/config.toml` 95~97행 주석: "프로덕션 전환
전략(C: 엔드포인트 버저닝) — 기존 `verify_receipt` 는 레거시 v162 로 동결해
구버전 앱 전용으로 남기고, 현재 앱은 이 이름(`verify-receipt-v2`)을 호출한다.
두 이름의 호출량 비율이 세대 전환 진행률 지표가 되고, v162 호출이 임계
미만으로 떨어지면 강제 업데이트 → v162 은퇴." 단,
`supabase/functions/verify-receipt-v2/index.ts` 는 자체 로직이 없고
`import { handler } from "../verify_receipt/index.ts"; Deno.serve(handler);`
가 전부다 — **두 엔드포인트 이름은 오늘 정확히 같은 핸들러 코드를 실행한다.**
그래서 이 문서가 `verify_receipt/index.ts` 의 코드 경로를 인용/수정 대상으로
삼는 것은 여전히 정확하다(수정은 그 파일 하나에 하면 두 엔드포인트 모두에
반영된다) — 다만 "프로덕션이 실제로 서비스하는 엔드포인트"를 지칭할 때는
`verify-receipt-v2` 가 맞는 이름이고, `verify_receipt` 라는 이름은 구버전
앱이 은퇴 전까지 계속 호출하는 레거시 별칭이라는 점을 이후 절(특히 §9)에서
전제로 삼는다.

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
- **Google 지역별 "가격" 근사** — Google 구매의 provider 증언 결제액(`value`)은
  이번 설계 범위에서 얻을 수 없다(§6.2 근거) — 정밀 지역 가격 카탈로그로
  금액까지 근사하는 방안은 후속 과제로 분리한다(§15). 다만 **"통화" 만은
  범위 안이다** — §6.2 가 정의하는 검증된 `regionCode` + Play 상품 지역별
  통화 조회(및 클라이언트 storefront 폴백)는 이번 설계에 포함되며, 전건
  보장이 아닌 비권위 best-effort 라는 한계를 §15 에 명시한다.
- **구독(subscription) 상품 지원** — Antigravity 리뷰가 지적한
  `purchases.subscriptionsv2` 경로는 이 설계와 무관하다. `verifyGoogle`
  (`purchase-provider-verifiers.ts:470`)은 `purchases.products.get` **일회성
  상품** 엔드포인트만 호출하고, `refund_ratio_basis`/`quantity` 기반 정산
  모델 전체(§5.3, `normalized_purchase_provider`)가 구독 갱신·기간이 아니라
  수량 기반 소모품을 전제한다 — 코드 어디에도 구독 갱신·기간(period)·
  `subscriptionsv2` 관련 로직이 없다(grep 결과 0건). Picnic 에 실제 구독
  상품이 없는 한 이 설계가 다룰 이유가 없는 YAGNI 이며, 구독을 실제로
  도입하면 검증·환불·정산 모델 전체가 별도 설계가 필요한 다른 문제다.

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

### 5.3 왜 `providerPaidAmountMinor`/`providerCurrency` 를 재사용하면 안 되는가

§4 는 "이 값을 실어 나르는 배관은 이미 있다"며 `verifyApple`/`verifyGoogle` 가
채우는 `providerPaidAmountMinor`/`providerCurrency` 필드를 그대로 analytics
값으로 쓰자는 인상을 준다. **이 초안은 실제로 검증해 보니 틀렸다 — 재사용하면
Apple 구매가 전부 정산 단계에서 거부된다.** 근거:

- `wallet_private.normalized_purchase_provider`(`purchase-provider-verifiers.ts`
  와 짝을 이루는 SQL, `purchase_settlement_commands.sql:81-104`)는 `APPLE`/`GOOGLE`
  에 `refund_ratio_basis:='QUANTITY'` 를 하드코딩한다. `verifyApple`/`verifyGoogle`
  도 각각 `refundRatioBasis: "QUANTITY"` 를 리터럴로 반환한다(360행, 494행) —
  둘 다 `providerPaidAmountMinor`/`providerCurrency` 의 null 여부와 무관하게
  고정된 값이다.
- `grant_verified_purchase`(`purchase_settlement_commands.sql:436-449`)는 이
  `refund_ratio_basis` 를 받아 **하드 불변식**을 강제한다:
  ```sql
  if v_expected_refund_basis='QUANTITY' then
    if p_provider_original_quantity is null or p_provider_original_quantity<=0
       or p_provider_original_quantity<>p_quantity or p_provider_paid_amount_minor is not null
       or p_provider_currency is not null then
      raise exception using errcode='22023',message='PURCHASE_INVALID_QUANTITY_BASIS';
    end if;
  ```
  **QUANTITY 기준 구매는 `provider_paid_amount_minor`/`provider_currency` 가
  반드시 둘 다 `null` 이어야 하고, 하나라도 non-null 이면 정산 전체가
  `PURCHASE_INVALID_QUANTITY_BASIS` 로 예외를 던진다.** Apple JWS 는 §6.1 이
  설명하듯 대부분의 트랜잭션에 `price`/`currency` 를 담고 있으므로, `verifyApple`
  이 그 값을 곧바로 `providerPaidAmountMinor`/`providerCurrency` 에 채워 넣으면
  **배포 즉시 절대다수의 Apple 구매가 정산 거부로 실패한다** — analytics
  필드 하나 채우려다 지급 자체를 깨는, §6.1/§6.2 가 스스로 세운 "계측이
  지급을 막지 않는다" 원칙을 정면으로 위반하는 회귀다.
- 이 불변식은 우연이 아니라 의도된 설계다: `refund_ratio_basis='AMOUNT'`
  (PayPal/PortOne)는 반대로 `p_provider_paid_amount_minor`/`p_provider_currency`
  가 **없으면** 거부한다(`PURCHASE_INVALID_AMOUNT_BASIS`, 같은 파일 443~447행)
  — 두 필드는 "환불 비율을 금액 기준으로 계산할지, 수량 기준으로 계산할지"를
  결정하는 정산 무결성 필드이지, 비어 있어도 그만인 표시용 필드가 아니다.

**결론: analytics 용 통화/금액은 `providerPaidAmountMinor`/`providerCurrency`
와 완전히 별개의 필드로 실어 나른다.** `VerifiedPurchase`(`purchase-provider-verifiers.ts:24`)
에 새 필드를 추가한다.

```ts
export interface VerifiedPurchase {
  // ...기존 필드 전부 그대로...
  refundRatioBasis: RefundBasis;
  providerPaidAmountMinor: bigint | null;   // 환불 정산 전용 — 이 설계는 손대지 않는다
  providerCurrency: string | null;          // 환불 정산 전용 — 이 설계는 손대지 않는다
  analyticsPriceMilliunits: bigint | null;  // 신규 — GA4 계측 전용, 정산 불변식과 무관
  analyticsCurrency: string | null;         // 신규 — GA4 계측 전용
  analyticsCurrencySource: "APPLE_JWS" | "GOOGLE_REGION_CATALOG"
    | "GOOGLE_CLIENT_STOREFRONT" | null;    // 신규 — §6.2 출처 로깅용, GA4 로는 안 나감
}
```

이 분리는 provider 마다 다르게 적용된다:

- **Apple/Google(QUANTITY basis)**: `providerPaidAmountMinor`/`providerCurrency`
  는 오늘처럼 항상 `null` 로 남긴다(무결성 불변식 유지). `analyticsPriceMilliunits`/
  `analyticsCurrency` 만 채운다(Apple 는 §6.1, Google 은 §6.2).
- **PayPal/PortOne(AMOUNT basis)**: 이미 `providerPaidAmountMinor`/`providerCurrency`
  가 실결제 값으로 채워지고 있고(`purchase-provider-verifiers.ts:520,546`),
  AMOUNT basis 는 애초에 이 값이 non-null 이어야 통과하므로 재사용해도
  QUANTITY 불변식과 무관하다 — 새 analytics 필드를 따로 채울 필요 없이 기존
  `providerPaidAmountMinor`/`providerCurrency` 를 그대로 analytics 출처로
  써도 안전하다. 다만 이 값을 실제로 `wallet_purchase_result` 응답에 노출하는
  배관(§9 의 capability 게이팅)은 §12 파일 목록에서 범위를 Apple 로만
  한정한다 — PayPal/PortOne 노출은 이 문서가 언급만 하고 별도 후속으로
  분리한다(추가 검증 없이 "이미 안전하니 그냥 켜자"고 단정하지 않는다).

이 새 필드들이 SQL 까지 내려가려면 `purchase_reward_snapshots` 에 대응하는
신규 컬럼(예: `analytics_price_milliunits bigint`, `analytics_currency text`)이
필요하다 — 정확한 마이그레이션 작성은 §3 비목표에 따라 범위 밖이지만, §12 는
이 컬럼들이 `provider_paid_amount_minor`/`provider_currency` 와 이름부터
분리돼야 한다는 제약을 명시한다.

### 5.4 "서버 권위"의 정확한 의미

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

- **출처**: `verifyAppleJws` 가 반환한 payload 의 `price`/`currency`. **`VerifiedPurchase.providerPaidAmountMinor`/`providerCurrency`
  가 아니라 §5.3 에서 새로 정의한 `analyticsPriceMilliunits`/`analyticsCurrency`
  에 채운다** — 360~361행의 `providerPaidAmountMinor: null, providerCurrency: null`
  은 그대로 둔 채, 같은 반환 객체 리터럴에 두 필드를 **추가만** 한다.
- **nullable 정책**: 두 필드는 공식적으로 optional 이다(오래된 트랜잭션,
  일부 프로모션/패밀리 공유 케이스 등에서 부재 가능 — Apple 라이브러리
  생태계에 "price 필드가 안 보인다"는 리포트가 존재한다). 부재/타입 불일치
  시 `null` 로 폴백하고 **예외를 던지지 않는다.** 이미 같은 함수 안에
  선례가 있다: `purchaseDate` 를
  `typeof purchaseDate === 'number' ? new Date(purchaseDate).toISOString() : null`
  로 방어적으로 다룬다(359행) — `price`/`currency` 도 동일한 패턴을 따른다.
- **단위: `price` 는 밀리유닛이지 마이너유닛이 아니다.** Apple 공식 문서
  기준 `price` 는 항상 "메이저 단위의 1/1000"이다(예: `1990` = `$1.99`,
  통화의 ISO 4217 소수 자릿수와 무관하게 항상 1000 분의 1). 이 값을
  `providerPaidAmountMinor` 류의 "마이너유닛"(예: USD 센트 = 1/100) 필드에
  그대로 넣으면 자릿수가 어긋난다 — 그래서도 `analyticsPriceMilliunits` 는
  이름 그대로 밀리유닛 단위임을 명시하는 별도 필드여야 한다(§5.3). GA4
  wire 의 `value`(메이저 단위 10진 문자열, §5.2)로 변환할 때는 **항상
  `analyticsPriceMilliunits / 1000`** 이며, 다른 나눗수를 쓰지 않는다.
  부동소수점 나눗셈을 쓰면 `1990/1000` 같은 값에서 표현 오차가 생길 수
  있으므로(§5.2 가 이미 세운 "금액은 부동소수점으로 보내지 않는다" 원칙),
  BigInt 정수 나눗셈으로 정수부/소수부를 분리해 문자열을 조립한다:
  ```ts
  function formatMilliunitsAsMajorDecimal(milliunits: bigint): string {
    const whole = milliunits / 1000n;
    const frac = (milliunits % 1000n).toString().padStart(3, "0").replace(/0+$/, "");
    return frac.length > 0 ? `${whole}.${frac}` : `${whole}`;
  }
  // 1990n -> "1.99"   1000n -> "1"   1005n -> "1.005"   500n -> "0.5"
  ```
  (정확한 소스 위치는 §12 신규 파일 목록에서 정한다 — `purchase-provider-verifiers.ts`
  가 밀리유닛 정수를 그대로 전달하고, 이 변환은 응답 조립 지점(§9)에서
  한 번만 수행해 왕복 변환 실수를 피한다.)
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

- **출처(이번 설계 범위): `providerCurrency`/`providerPaidAmountMinor` 는 그대로
  `null`** — §5.3 이 정한 QUANTITY 불변식은 Google 에도 동일하게 적용되고,
  Google 은 애초에 provider 증언 금액이 없으므로 이 두 필드를 채울 방법
  자체가 없다(오늘과 동일한 동작, 회귀 아님). **다만 `analyticsCurrency` 만은
  비권위 폴백으로 채울 수 있다** — 아래가 그 최소 설계다. `value`(금액)는
  이번 phase 에서도 채우지 않는다: regionCode 로 알 수 있는 것은 통화이지
  실결제액이 아니고, 목록가를 실결제액으로 둔갑시키면 §6.1 이 세운 "provider
  가 증언한 실제 결제액"이라는 기준을 어기게 된다.

  **출처 A(1순위) — 검증된 `regionCode` + Google Play 상품 지역별 가격 카탈로그
  조회.** `regionCode` 는 `purchases.products.get` 응답 필드로, Google 이 이미
  서버 대 서버로 검증해 돌려준 값이다(클라이언트 자기신고가 아니다). Google
  Play 는 지역마다 정확히 하나의 통화를 쓰도록 강제하므로(가격은 프로모션·
  반올림으로 흔들려도 "이 지역은 이 통화"라는 매핑 자체는 안정적이다),
  Play Developer API 의 상품 조회(구 in-app products 카탈로그는
  `inappproducts.get` 의 `prices` 맵, 신 unified 카탈로그는
  `monetization.onetimeproducts.get` 의 `regionalPricingAndAvailabilityConfigs`)
  에서 그 `productId` 의 지역별 설정을 조회해 `regionCode` 에 대응하는
  `currencyCode` **하나만** 뽑아 쓴다 — 가격(units/nanos)은 버리고 통화 코드만
  쓴다. **Picnic 의 상품 콘솔이 구 카탈로그를 쓰는지 신 카탈로그를 쓰는지는
  코드만으로 확인되지 않는다 — 구현 착수 전에 실제 Play Console 설정으로
  확인해야 하는 미확인 전제다(이 문서가 코드로 검증하지 않은 유일한 외부
  API 사실이며, 아래 §6.2-부칙에서 그대로 명시한다).**
  `assertWebProductPrice` 는 재사용하지 않는다 — 그 함수는 여전히 무결성
  게이트이고, 이 조회는 순수 조회 실패 시 `analyticsCurrency=null` 로
  흡수될 뿐 정산을 막지 않는다(§6.1 의 "계측이 지급을 막지 않는다" 원칙
  그대로 적용).

  **출처 B(2순위, A 실패 시에만) — 클라이언트가 거래 요청 시점에 함께 보낸
  storefront currency.** Android 클라이언트는 `launchBillingFlow` 를 부르기
  **전에** 이미 `ProductDetails.oneTimePurchaseOfferDetails.priceCurrencyCode`
  를 들고 있다(가격을 화면에 표시하기 위해 반드시 먼저 조회해 둔 값). 이
  값을 verify_receipt/verify-receipt-v2 요청 본문에 필드 하나로 추가해
  실어 보낸다(예: `client_observed_currency`) — **대안 1 이 실패한 "결제
  시점에 로컬에 별도로 기록해 뒀다가 정산 시점에 다시 읽어오는" 패턴을
  반복하지 않는다.** 차이는 세 가지다.
  1. **거래 결합 문제가 없다.** 새 저장소나 타임스탬프 매칭이 아니라, 이미
     그 거래의 유일한 식별자(purchaseToken/proof)를 실어 보내는 **같은 HTTP
     요청의 필드 하나**다 — "어느 시도의 값인지" 지목할 필요 자체가 없다.
  2. **`Future.timeout` 이 취소 못 하는 하위 I/O가 없다.** 이미 메모리에 있는
     `ProductDetails` 필드를 읽어 JSON 에 넣는 동기 작업이라 새로운 비동기
     I/O 가 없다.
  3. **소비 시점 딜레마가 없다.** 별도로 저장했다가 나중에 소비하는 상태가
     아니라, 매 요청마다 그 자리에서 다시 읽어 보내는 값이라 "저장 전에
     소비되면 유실"이라는 경우의 수 자체가 없다.

  이 필드는 §9 의 parser capability 와 마찬가지로 **`intakeIdentityHash`
  (`wallet-provider-event/index.ts`)에는 절대 포함하지 않는다** — 그 파일 자체의
  주석이 이미 이 함정을 기록하고 있다: `requestContext.app_version`/`app_build`/
  `cohort_version` 을 해시에 넣었다가 "앱 업데이트 후 정당한 재전달이 페이로드
  충돌로 오판되는" 프로덕션 장애가 실제로 있었다(2026-07-30, 인박스
  `APPLE:SANDBOX:2000001213180810`). `client_observed_currency` 도 정확히 같은
  성격의 필드이므로 같은 함정을 반복하지 않는다 — identity hash 5개 필드
  (provider/environment/providerTransactionId/userId/productId) 밖에 둔다.

  **우선순위와 불일치 처리**: A 성공 → A 값 사용, `analyticsCurrencySource:
  "GOOGLE_REGION_CATALOG"`. A 실패(카탈로그에 그 지역 없음/API 오류) + B
  존재 → B 값 사용, `analyticsCurrencySource: "GOOGLE_CLIENT_STOREFRONT"`.
  **A 와 B 가 둘 다 있는데 서로 다른 통화를 가리키면, A 를 채택하고 불일치를
  구조화 로그로 남긴다**(`regionCode`, A 값, B 값, `productId` — 알람이 아니라
  관측용 로그. 카탈로그 drift 나 클라이언트 구버전을 나중에 발견하기 위한
  용도다). 어느 쪽도 없으면 `analyticsCurrency=null` — 오늘과 동일하게
  currency/value 를 함께 생략한다.

  **§6.2-부칙 — 이 폴백은 "모든 Google 구매의 currency 보장"이 아니다.**
  카탈로그가 그 지역을 안 다루거나, 구버전 클라이언트가 `client_observed_currency`
  를 아직 안 보내거나, 둘 다 실패하면 여전히 `null` 이다. 이 문서는 그
  간극을 메웠다고 주장하지 않는다 — **Google 구매 전건에 대한 currency
  보장은 이번 설계로 해결되지 않은 채로 남고, "부분/최선 노력 커버리지를
  받아들일지"는 대행사 확인이 필요한 별도 의사결정 게이트로 남긴다**(§15
  한계 표, §10 이 이미 세운 "대행사 확인 대기 항목"과 같은 성격 — 코드를
  먼저 배포하고 나중에 답을 받는 게 아니라, 이 간극 자체를 명시적으로
  들고 대행사에 확인을 구한다).
- **후속 과제(이번 범위 밖, §15)**: 위 폴백으로도 못 메우는 지역(카탈로그
  미커버)까지 억지로 채우려는 정밀 지역 가격 근사(예: 통화만이 아니라 실제
  근사 가격까지 추정)는 별도 설계로 분리한다 — 데이터 정확성 리스크
  (프로모션·반올림·세금 표시 차이)가 currency-only 폴백과 질적으로 다르고,
  §6.1 의 "provider 증언 실제 결제액"과 혼동되지 않도록 데이터 신뢰도
  라벨링이 별도로 필요하다.

### 6.3 실패 정책 요약

| 상황 | 정책 |
|---|---|
| Apple JWS 에 `price`/`currency` 없음 또는 타입 불일치 | `null` 로 폴백, 검증/지급 계속 진행 |
| Google 응답에 가격 필드 없음(항상 그렇다) | `null` 유지, 검증/지급 계속 진행 — 오늘과 동일 |
| currency/value 추출 코드 자체가 예외를 던짐(방어 코드 버그) | 해당 필드만 `null` 로 잡아먹고 로그, 정산 트랜잭션을 실패시키지 않음 |
| `currency` 는 없는데 `value`(또는 milliunits 가격)만 있음 | **둘 다 `null` 로 낮춰서 생략** — `value` 만 보내면 GA4 가 `currency` 를 ISO 4217 위반으로 판정해 해당 purchase 의 매출 전체를 무시한다(`ga4-event-taxonomy.md` §4-8, `agency-reply.html` B-2) |
| `currency` 는 있는데 `value` 만 없음(예: Google 폴백으로 통화만 구했고 금액은 없음) | **`currency` 는 그대로 보내고 `value` 만 생략** — `value` 는 Number 파라미터라 결측 시 그 파라미터만 생략하는 것이 규칙이고(`ga4-event-taxonomy.md` §4-8 행6, `agency-reply.html` B-3), `currency` 를 억지로 같이 지울 근거가 없다 |

이 표의 마지막 두 행은 **비대칭 규칙**이다 — 대칭("둘 중 하나라도 없으면
둘 다 버림")이 아니다. 근거를 다시 읽으면: `agency-reply.html` B-2 는
"`currency` 값이 없을 경우... **짝이 되는 `value` 도 함께 생략**"이라고
`currency` 결측 방향만 명시하고, B-3 은 Number 파라미터(`value` 포함) 결측
시 "파라미터를 생략"이라고만 하지 짝 파라미터를 같이 지우라는 말이 없다
— `ga4-event-taxonomy.md` §4-8(행8)도 같은 비대칭으로 적혀 있다. 이 설계의
이전 초안은 이 두 규칙을 하나의 대칭 규칙으로 뭉뚱그렸는데, 그 상태로는
Google 폴백(§6.2)이 통화만 구하고 금액은 못 구한 정상 케이스에서 `currency`
까지 버려 폴백 자체가 무의미해진다 — 표를 비대칭으로 정정한다. (참고:
`docs/analytics/agency-reply.html` 은 2026-08-21 시점에 **대행사에 아직
발송되지 않은 내부 초안**이다 — `docs/operations/handoff-20260821-ga4-taxonomy.html`
64행·148행이 "대행사 회신 발송: 미확인/미발송"이라고 명시한다. 즉 B-2/B-3
는 "대행사가 확인해 준 규칙"이 아니라 "Picnic 이 대행사에 보내려고 준비한,
아직 전달 전인 자체 결정"이다 — 근거로서의 무게는 그만큼 낮춰서 읽어야
하고, 실제 발송 후 대행사가 다른 의견을 낼 가능성은 열려 있다.)

## 7. Analytics 우선순위

`_sendPurchaseAnalytics` 가 `AnalyticsService.logPurchasePayload` 를 호출할 때
`currency`/`value` 를 정하는 우선순위:

1. **서버 정산 응답에 `currency` 가 있으면(값 있음) 무조건 서버 값을 쓴다
   — `value` 유무와 무관하게.** `currency` 가 있고 `value` 도 있으면 둘 다
   서버 값. `currency` 는 있는데 `value` 가 없으면(§6.2 Google 폴백처럼
   통화만 구해진 경우) **`currency` 만 보내고 `value` 는 생략** — 이때
   클라이언트 카탈로그의 `rawPrice` 를 끌어와 "서버 통화 + 클라이언트
   금액"으로 짜깁기하지 않는다. 카탈로그 가격은 카탈로그 자신의 통화
   기준으로 조회된 값이라, 서버가 확정한 통화와 다를 수 있는 값을 섞으면
   금액-통화 쌍 자체가 틀린 값이 된다 — §5.3 이 이미 "클라이언트 관찰값과
   비교·병합하지 않는다"고 정한 원칙을 `value` 단독 결측 케이스까지
   일관되게 적용한 것뿐이다.
2. **서버 `currency` 가 `null` 인 경우에만** — 기존 로직대로
   `container.read(storeProductsProvider).value` 에서 찾은
   `ProductDetails.currencyCode`/`rawPrice` 를 **currency/value 한 쌍으로
   함께** 쓴다(오늘의 동작, 변경 없음). 이 경로는 서버 계약이 아직 이
   필드를 안 보내는 구버전 `contract_version` 이나, Google 폴백조차
   실패한 경우를 모두 자연스럽게 커버한다 — 별도 분기가 필요 없다.
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

### 9.3 왜 `app_build` 게이팅은 실제로 안전하지 않은가

이전 초안은 서버가 `requestContext.app_build` 와 최소 build 번호를 비교해
게이팅하자고 제안했다. **코드로 확인한 결과 이 메커니즘은 두 가지 독립적인
이유로 신뢰할 수 없다 — 채택하지 않는다.**

1. **Shorebird OTA 는 build number 를 바꾸지 않는다.** §8 의 forward-compatible
   파서는 Dart 전용 변경(JSON 파싱 로직)이라 네이티브 코드·권한·엔진 호환성
   변경이 없고, `flutter-release.md` 의 배포 방식 기준대로라면 **Shorebird
   OTA 대상**이다. 그런데 같은 정책 문서가 명시하듯 "OTA 에서는 표시 버전과
   Build number 를 모두 유지한다" — OTA 로 새 파서를 받은 클라이언트도
   `app_build` 값은 patch 이전과 **동일**하다. 즉 "새 파서가 있다"와 "이
   app_build 값이다"는 애초에 1:1 대응이 아니다 — OTA 로 어제 패치받은
   기기와 아직 안 받은 기기가 서버에는 **같은 `app_build`** 로 보인다.
   게이팅 임계값을 어느 쪽으로 설정해도 둘 중 하나는 틀린다.
2. **설령 OTA 문제가 없어도, 지금 코드는 애초에 "이 요청"의 `app_build` 를
   응답 조립 지점까지 전달하지 않는다.** `verify_receipt/index.ts` 는 요청마다
   `app_build` 를 새로 읽어 `envelope.requestContext` 에 담지만(74행 부근),
   `wallet-operation-worker` 를 부를 때는 **`{ inbox_id: received.inbox_id }`
   딱 하나만 넘긴다**(83행) — 이 요청의 `requestContext` 자체를 넘기지 않는다.
   그래서 `wallet-operation-worker`(`processInbox`)가 실제로 손에 쥐는
   `requestContext` 는 `byteaJson(claim.encrypted_payload)` 로 **인박스에
   최초 커밋 시점에 영속 저장된, 그 당시의** `envelope.requestContext` 뿐이다
   (`verified.requestContext`, 343~395행 부근). 클라이언트가 그 사이 앱을
   업데이트하고 같은 영수증으로 재시도(멱등 재전달)해도, 이 응답 조립
   경로가 보는 `app_build` 는 **최초 커밋 시점의 구버전 값**이다 — "이번
   요청이 새 파서를 가졌는가"를 물을 방법이 지금 배관에는 없다. 이것이
   요구사항이 말하는 "최초 requestContext replay" 문제다: 게이팅 판단이
   현재 요청이 아니라 과거에 박제된 스냅샷을 재생(replay)해서 내려진다.

  (참고: `requestContext` 를 인박스 커밋 이후에도 재시도마다 최신값으로
  덮어쓰지 않는 것 자체는 **의도된 동작**이다 — `wallet-provider-event/index.ts`
  의 `intakeIdentityHash` 주석이 정확히 이 이유로 `app_build`/`app_version`/
  `cohort_version` 을 멱등 식별자 해시에서 **제외**한다: 앱 업데이트로 이
  값이 바뀌는 게 정상이라, 해시에 넣으면 "업데이트 후 정당한 재전달"이
  "페이로드 충돌"로 오판된다(2026-07-30 프로덕션 장애, 인박스
  `APPLE:SANDBOX:2000001213180810`). 즉 "저장된 `requestContext` 를 그대로
  믿으면 안 된다"는 교훈은 이 코드베이스에 이미 한 번 새겨져 있다 — 이
  설계는 그 교훈을 응답 조립(게이팅) 지점에도 일관되게 적용하는 것뿐이다.)

### 9.4 채택 메커니즘 — 현재 요청의 명시적 parser capability, 응답 직전 include/strip

`app_build` 대신, **"이 요청을 보낸 클라이언트가 지금 이 순간 확장 계약을
파싱할 수 있는가"를 그 요청 자체가 명시적으로 선언**하게 한다. 값을
추론(build number, 저장된 이력)하지 않고 선언받는다.

**1) 클라이언트 → 서버: 요청 필드 하나 추가.**
`verify_receipt`/`verify-receipt-v2` 요청 본문에 `parser_capabilities:
string[]` 를 추가한다(예: `["purchase_revenue_v1"]`). §8 의 새 파서가
탑재된 빌드/OTA 패치에서만 이 배열에 `"purchase_revenue_v1"` 을 채워
보낸다 — build number 가 아니라 **파서 코드 자체가 스스로 아는 사실**이므로
OTA 로 조용히 패치된 기기도 정확히 반영된다.

**2) 서버: 이 요청 전용 파라미터로만 전달한다 — durable 저장하지 않는다.**
`verify_receipt/index.ts` 핸들러가 이 요청의 `parser_capabilities` 를 읽어,
**단일 인박스 처리 호출(`{ inbox_id }`)에만** 얹어 보낸다:
`invoke(serviceKey, "wallet-operation-worker", { inbox_id: received.inbox_id,
parser_capabilities: parserCapabilities })`. 이 값은 `envelope`/`requestContext`
의 일부가 **아니다** — 인박스에 영속 저장되지 않고, `intakeIdentityHash` 에도
들어가지 않는다(§6.2 의 `client_observed_currency` 와 같은 이유 — §9.3 이
기록한 함정을 반복하지 않는다). 매 호출마다 사라지는 순수 요청 파라미터다.
크론 배치 경로(`{"limit":50}`, `inbox_id` 없이 최대 50건 일괄 처리 —
`purchase_settlement_commands.sql` 의 `cron.schedule('wallet-operation-worker',
'* * * * *', ...)`)는 이 필드를 **애초에 가질 수 없다** — 뒤에서 보듯
이건 문제가 되지 않는다.

**3) 서버: 응답 직전, 딱 한 곳에서 include/strip 한다.** `wallet-operation-worker`
는 `grant_verified_purchase`/`get_purchase_result_for_inbox` 가 돌려준 7키
결과에, `parser_capabilities` 가 `"purchase_revenue_v1"` 을 포함할 때만
`purchase_reward_snapshots`(`inbox_id` 로 조회)의 `analytics_currency`/
`analytics_price_milliunits`(§5.3)를 추가로 한 번 조회해 `currency`/
`value`(§6.1 의 milliunits→decimal 변환 적용)를 병합한다. **`wallet_purchase_result`
SQL 타입/`build_purchase_result` 자체는 건드리지 않는다** — 여전히 정확히
7키를 반환한다. capability 인지는 edge function(TypeScript) 레이어 하나에만
있고, SQL 레이어는 "누가 요청했는지"를 몰라도 된다. `verify_receipt` 의
마지막 `return response(worker);` 직전이 실제 strip 지점이다:

```ts
function shapeForCapabilities(worker: Record<string, unknown>, capabilities: unknown): Record<string, unknown> {
  const allowed = Array.isArray(capabilities) && capabilities.every(c => typeof c === "string")
    && capabilities.includes("purchase_revenue_v1");
  if (allowed) return worker; // currency/value 는 wallet-operation-worker 가 이미 채워 넣었다
  const { currency, value, ...rest } = worker; // 명시적 capability 없으면 무조건 7키
  return rest;
}
```

**누락/오형식은 무조건 fail-closed 다** — `parser_capabilities` 가 없거나,
배열이 아니거나, 문자열이 아닌 원소가 섞여 있거나, 알려진 값을 안
포함하면 전부 "capability 없음"으로 취급해 7키로 낮춘다. 새 키를 잘못
보내는 쪽보다 옛 계약으로 안전하게 떨어지는 쪽이 항상 낫다는 §11 의
공통 원칙 그대로다.

**4) 왜 이게 foreground 든 재전달(큐 replay)이든 항상 안전한가.** 이
아키텍처에서 클라이언트가 실제로 HTTP 응답을 받는 경로는 **`verify_receipt`/
`verify-receipt-v2` 의 공유 핸들러 하나뿐이다** — `wallet-operation-worker`
자체는 `config.toml` 에 `verify_jwt` 항목이 없고 클라이언트 JWT 로 직접
호출 가능한 엔드포인트가 아니다(service_role 또는 `X-Cron-Secret` 로만
호출된다). 그래서:

- **foreground(최초 호출)**: 이번 요청이 보낸 `parser_capabilities` 그대로
  반영된다 — 지금까지의 §7~§8 설계와 동일.
- **클라이언트 재시도(§5.1 의 "replayed" 케이스, 예: 최초 호출이 503 을
  받은 뒤 앱을 업데이트하고 같은 영수증으로 다시 호출)**: 이것도 `verify_receipt`
  를 **다시** 부르는 새 HTTP 요청이므로, 이번에 보낸(업데이트 후이므로 새
  파서를 가졌다면 새) `parser_capabilities` 가 신선하게 적용된다 — 최초
  커밋 시점에 어떤 값이었는지와 무관하다. 정산 자체는 멱등하게 재사용되지만
  **응답 모양은 이번 요청 기준으로 매번 새로 결정된다.**
- **크론 배치 재처리(`* * * * *`, 최대 50건)**: 이 경로가 만드는 HTTP 응답은
  pg_cron 의 `net.http_post` 가 받고 버릴 뿐, 어떤 클라이언트에게도 전달되지
  않는다 — "클라이언트가 이 응답을 볼 수 있는가"라는 질문 자체가 성립하지
  않는다. `parser_capabilities` 가 없으니 이 경로는 자동으로 §9.4-3의 fail-closed
  분기를 타지만, **그 판단이 어떤 클라이언트에게도 보이지 않으므로 안전성에
  영향이 없다.** 크론 배치는 정산(지급)만 진행하고, 그 거래의 실제 응답
  모양은 나중에 클라이언트가 `verify_receipt` 를 다시 불렀을 때(위 "재시도"
  케이스) 그 시점의 살아있는 capability 로 결정된다.

즉 old→new(구버전 클라이언트가 업데이트 후 재시도) 방향과 new→old(있을 수
없지만, 방어적으로) 방향 모두 **"과거에 무엇이었나"가 아니라 "지금 이
요청이 뭐라고 말하는가"만 본다** — §9.3 이 지적한 "최초 requestContext
replay" 문제가 구조적으로 재발할 수 없다.

**5) 롤백 — 기존 wallet runtime flag 를 재사용한다.** 이 코드베이스에는
이미 즉시 킬스위치 패턴이 있다: `public.set_wallet_runtime_flag`(service_role
전용, `20260721095500_wallet_core_release_gates.sql:128`)로 쓰고
`wallet_private.cotton_runtime_flag_enabled('flag.key')` 로 읽는 플래그가
`wallet.star_projection_check_enabled`/`wallet.cotton_expiry_enabled` 등에
이미 쓰이고 있다(`20260730170000_wallet_star_projection_gate_and_alert_dispatch.sql`).
같은 패턴으로 `wallet.purchase_revenue_fields_enabled` 플래그를 하나
추가한다 — `wallet-operation-worker` 의 include 판단은
`parser_capabilities 포함 && 플래그 활성` 일 때만 참이 된다. 클라이언트가
capability 를 올바르게 보내더라도, 배포 후 currency/value 계산에 문제가
발견되면 **재배포 없이 플래그 하나로 즉시 전면 차단**할 수 있다 — 이
설계가 실제로 갖는 유일한 "배포 실행" 성격의 레버이므로 §3 비목표의
배포 실행 제외 범위 밖에 둔다(플래그 존재는 설계 결정, 실제 on/off 시점은
운영 문제).

**6) 이 롤아웃은 cotton-candy-v1 컷오버와 다른, 더 작은 롤아웃이다.**
`verify-receipt-v2` 자체가 이미 큰 세대 전환(구앱 v162 ↔ cotton-candy 앱,
§2)을 겪었고 그 전환은 대부분 끝난 상태다 — 이 설계는 그 위에 얹히는
**훨씬 작고 독립적인** 2단계 롤아웃이다: (1) 서버 코드 + `analytics_*`
컬럼을 먼저 배포한다(플래그는 꺼둔 채, 또는 클라이언트가 아직 capability
를 안 보내는 상태라 자동으로 dark — §12 파일 목록의 "가산 전용" 성격과
같다), (2) §8 파서를 담은 클라이언트를 배포한다. 진행률은 `verify_receipt`
대 `verify-receipt-v2` 호출 비율을 세대 전환 지표로 쓰는 것과 같은 방식으로,
"`parser_capabilities` 를 포함한 요청의 비율"로 관측할 수 있다 — 새 지표
체계를 발명하지 않는다.

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
| 서버 · Google 폴백 조회 | 지역별 가격 카탈로그에 그 `regionCode` 없음/API 오류 | `analyticsCurrency` 를 클라이언트 storefront 폴백으로 낮추거나 `null`, 정산은 계속 진행(§6.2) — 조회 실패가 정산을 막지 않는다 |
| 서버 · 응답 조립 | `parser_capabilities` 누락/배열 아님/알려진 값 미포함(오형식 포함) | fail-closed — `currency`/`value` 생략, 기존 7키 계약으로 응답(§9.4) |
| 서버 · 응답 조립 | `wallet.purchase_revenue_fields_enabled` 런타임 플래그 꺼짐 | capability 와 무관하게 `currency`/`value` 생략(§9.4-5, 즉시 롤백 레버) |
| 서버 · 응답 조립 | `currency` 없는데 `value`(또는 milliunits 가격)만 있음 | 둘 다 `null` 로 낮춰서 응답(§6.3, B-2) — ISO 4217 위반으로 GA4 가 매출 전체를 버리는 사고를 원천 차단 |
| 서버 · 응답 조립 | `currency` 는 있는데 `value` 만 없음(Google 폴백이 통화만 구한 정상 케이스) | `currency` 만 응답에 포함, `value` 는 생략(§6.3, B-3) — 이전 초안처럼 `currency` 까지 같이 지우지 않는다 |
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
| `lib/presentation/widgets/vote/store/purchase/analytics_service.dart` | 시그니처 변경 없음. 상단 문서 주석 중 "카탈로그가 없으면 생략" 서술을 §7 의 비대칭 우선순위에 맞게 갱신 |
| `lib/core/services/receipt_format_helper.dart` | `buildIOSRequestBody`/`buildAndroidRequestBody`(185행, 204행)에 `parser_capabilities: ['purchase_revenue_v1']` 를 양쪽 다 추가. `buildAndroidRequestBody` 에는 `client_observed_currency`(§6.2 출처 B)를 `ProductDetails.oneTimePurchaseOfferDetails.priceCurrencyCode` 에서 채워 추가 |
| `lib/core/services/receipt_verification_service.dart` (및 `presentation/widgets/vote/store/purchase/` 사본) | **확인 필요, 이 문서에서 확정하지 않음**: 이 두 함수가 만드는 요청 본문에는 오늘 `app_build`/`app_version`/`cohort_version` 가 없는데도 서버(`wallet-provider-event/index.ts:39`)는 이 값이 정수가 아니면 요청을 거부한다 — 즉 이 세 필드는 `_requestBodyFor` 반환 이후, HTTP 전송 전 어딘가(다른 인터셉터/공통 레이어)에서 병합되고 있다. `parser_capabilities`/`client_observed_currency` 는 **그 병합 지점과 같은 곳**에 추가해야 한다 — `receipt_format_helper.dart` 단독 수정만으로는 실제 전송 경로를 놓칠 수 있으므로, 구현 착수 시 그 병합 지점을 먼저 찾아 확인한다 |
| `test/data/models/purchase/purchase_settlement_result_test.dart` | §13 신규 케이스 |
| `test/core/services/purchase_service_logic_test.dart` | §13 신규 케이스 |
| `test/presentation/widgets/vote/store/purchase/purchase_revenue_analytics_test.dart` | §13 신규 케이스(기존 431행 "카탈로그가 비어도..." 테스트와 대칭되는 케이스 추가, §7 비대칭 우선순위 케이스 추가) |

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
| `supabase/functions/_shared/wallet/purchase-provider-verifiers.ts` | `VerifiedPurchase`(24행)에 `analyticsPriceMilliunits`/`analyticsCurrency`/`analyticsCurrencySource` 추가(§5.3). `verifyApple`: `payload.price`/`payload.currency` 읽어 이 신규 필드만 채움 — **360~361행의 `providerPaidAmountMinor: null, providerCurrency: null` 은 그대로 둔다**(대체가 아니라 추가). `verifyGoogle`: `providerPaidAmountMinor`/`providerCurrency` 는 494~495행 그대로 유지(변경 없음, §6.2). `analyticsCurrency` 만 새 헬퍼(§6.2 출처 A: regionCode + Play 상품 지역별 가격 카탈로그 조회, 출처 B: `envelope` 에 실려온 `client_observed_currency`)로 채운다 — 이 조회 실패는 예외를 던지지 않고 `null` 로 흡수(§6.3) |
| `supabase/functions/_shared/wallet/purchase-provider-verifiers.ts` (동일 파일, `IntakeEnvelope`) | `IntakeEnvelope`(4행)에 `clientObservedCurrency?: string`(§6.2 출처 B) 추가. **`intakeIdentityHash` 입력 5개 필드에는 넣지 않는다**(§9.3 이 기록한 함정 반복 금지) |
| `supabase/functions/wallet-operation-worker/index.ts` | `processInbox` 의 RPC 인자(343~399행)는 변경 없음(`providerPaidAmountMinor`/`providerCurrency` 는 오늘처럼 QUANTITY 구매에 `null`). `handler`(729행)의 단일 인박스 분기(767~771행)가 요청 본문의 `parser_capabilities` 를 읽어 처리 결과에 병합하는 단계 추가: capability 포함 **and** `wallet.purchase_revenue_fields_enabled` 런타임 플래그 활성일 때만 `purchase_reward_snapshots`(inbox_id 로 조회)의 `analytics_currency`/`analytics_price_milliunits` 를 추가 조회해 §6.1 의 milliunits→decimal 변환 후 `currency`/`value` 로 병합(§9.4-3). 크론 배치 분기(`{"limit":50}`, `inbox_id` 없음)는 `parser_capabilities` 자체가 없으므로 항상 병합 생략 — 그 결과가 클라이언트에 노출되지 않으므로 무해(§9.4-4) |
| `supabase/functions/verify_receipt/index.ts` | **로직 변경 있음** — 이전 초안의 "pass-through, 변경 없음"은 틀렸다. (1) 요청 본문에서 `parser_capabilities` 를 읽어 검증(배열·문자열 원소인지만, 값 자체는 그대로 통과 — 알려지지 않은 값은 뒤에서 무시됨)하고 `wallet-operation-worker` 단일 인박스 호출에 `{ inbox_id, parser_capabilities }` 로 실어 보낸다(83행 대체, §9.4-2). (2) `return response(worker);` 직전에 `shapeForCapabilities(worker, parserCapabilities)` 로 fail-closed strip 적용(§9.4-3). 87~96행의 "정확히 7키" 주석은 "capability 없으면 정확히 7키, 있으면 최대 9키"로 갱신 |
| `supabase/functions/tests/wallet/apple-verifier.test.ts` | §13 신규 케이스 — **특히 "JWS 에 price/currency 있어도 `providerPaidAmountMinor`/`providerCurrency` 는 여전히 null" 회귀 테스트**(§5.3 불변식 보호) |
| `supabase/functions/tests/wallet/apple-jws-fixture.ts` | `price`/`currency` 를 포함한 서명된 JWS 픽스처 추가(및 없는 버전과의 비교용 픽스처) |
| `supabase/functions/tests/wallet/google-verifier.test.ts` | §13 신규 케이스(§6.2 출처 A/B 우선순위, 불일치 로깅, 조회 실패 시 정산 계속) — 기존 파일이 없다면 신설 |
| `supabase/functions/tests/wallet/operation-worker.test.ts` | §13 신규 케이스 — capability 포함/누락/오형식, 런타임 플래그 off, 크론 배치 경로가 capability 무관하게 동작하는지 |
| `supabase/functions/tests/wallet/verify-receipt-intake.test.ts` | §13 신규 케이스 — `parser_capabilities` 전달·strip 통합 테스트(기존 파일, `verify_receipt` 인테이크 테스트) |
| `supabase/functions/tests/wallet/purchase-settlement.test.ts` | §13 신규 케이스 |

DB 스키마 변경 대상(정확한 마이그레이션 작성은 §3 비목표에 따라 범위 밖,
영향받는 대상만 명시):

- `public.purchase_reward_snapshots` 에 `analytics_currency text`,
  `analytics_price_milliunits bigint` 신규 컬럼(§5.3) — **`provider_currency`/
  `provider_paid_amount_minor` 와는 별개 컬럼**, 기존 QUANTITY 불변식
  (`grant_verified_purchase`, §5.3)은 전혀 건드리지 않는다.
- `wallet.purchase_revenue_fields_enabled` 런타임 플래그 시드(§9.4-5) —
  `20260721095500_wallet_core_release_gates.sql`/`20260730170000_..._gate_and_alert_dispatch.sql`
  이 이미 쓰는 것과 같은 패턴(`set_wallet_runtime_flag`/`cotton_runtime_flag_enabled`).
  **`public.wallet_purchase_result` 타입 자체(7키)는 바꾸지 않는다** —
  §9.4-3 이 그 이유를 설명한다(capability 인지는 edge function 레이어에만
  있어야 SQL 레이어가 단순하게 유지된다).
- `provider_currency`/`provider_paid_amount_minor` 컬럼 자체는 이미
  스키마에 존재한다(`purchase_reward_schema.sql`) — **이번에 새로 만드는
  analytics 컬럼과 이름·용도가 겹치지 않게 하는 것이 §5.3 의 핵심 제약이다.**
- Google 지역별 가격 카탈로그 조회(§6.2 출처 A)가 부르는 Google Play
  Developer API 엔드포인트(`inappproducts.get` 또는
  `monetization.onetimeproducts.get`)가 오늘 `verifyGoogle` 이 쓰는
  서비스 계정 자격증명과 같은 OAuth 스코프로 이미 호출 가능한지는 **이
  문서가 코드로 확인하지 못한 유일한 외부 전제**다 — 스코프가 다르면
  구현 착수 전 Play Console/서비스 계정 설정에서 별도로 확인·추가해야
  한다.

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
   - `currency` 만 있고 `value` 없는 JSON → 파싱 성공, `currency` 필드에
     값 반영·`value` 는 `null`(§6.3/§7 비대칭 규칙이 파서가 아니라 analytics
     계층 책임임을 재확인하는 케이스).
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
   - **서버 `currency` 있음 + `value` 없음(Google 폴백 케이스) + 카탈로그도
     로드됨** → outbox payload 는 `currency` 만 서버 값, `value` 는 `null`
     로 남는다 — 카탈로그의 `rawPrice` 를 끌어와 채우지 **않는다**(§7-1 이
     금지하는 통화-금액 짜깁기 회귀 테스트, 이전 초안에서 빠져 있던 케이스).
3. **`purchase_service_logic_test.dart`** — `_sendPurchaseAnalytics` 가
   `PurchaseSettlementResultModel.currency`/`value` 를 실제로 읽어 우선순위
   로직에 넘기는지 단위 수준에서 확인.

### picnic-supabase

1. **`apple-verifier.test.ts`** (+ `apple-jws-fixture.ts` 확장)
   - `price`/`currency` 포함 서명된 JWS → `VerifiedPurchase.analyticsPriceMilliunits`/
     `analyticsCurrency` 가 그 값으로 채워짐(현재 구현에서는 실패해야 정상인 RED).
   - **같은 입력에 대해 `VerifiedPurchase.providerPaidAmountMinor`/
     `providerCurrency`/`refundRatioBasis` 는 여전히 `null`/`null`/`"QUANTITY"`
     — 절대 값이 채워지면 안 된다.** 이 테스트가 §5.3 의 핵심 불변식을
     지킨다: 이게 깨지면 `grant_verified_purchase` 가 `PURCHASE_INVALID_QUANTITY_BASIS`
     로 프로덕션 Apple 구매를 전부 거부한다(§5.3 SQL 인용 참고).
   - `price`/`currency` 없는(과거 형태) JWS → 검증은 여전히 성공, 신규
     analytics 필드만 `null`(throw 하지 않는다는 정책의 회귀 테스트).
   - `price` 는 있는데 `currency` 형식이 깨진 경우 → 둘 다 `null` 로 폴백,
     예외 없음.
   - 밀리유닛→10진 변환 단위 테스트(순수 함수, JWS 불필요): `1990n → "1.99"`,
     `1000n → "1"`, `1005n → "1.005"`, `0n → "0"` — 부동소수점 없이 BigInt
     연산으로만 계산되는지(§6.1 의 `formatMilliunitsAsMajorDecimal`).
2. **`google-verifier.test.ts`**(신설)
   - `regionCode` 가 지역별 가격 카탈로그에 있음 → `analyticsCurrency` =
     카탈로그 통화, `analyticsCurrencySource: "GOOGLE_REGION_CATALOG"`,
     `providerPaidAmountMinor`/`providerCurrency`/`refundRatioBasis` 는
     여전히 `null`/`null`/`"QUANTITY"`(위와 같은 불변식 재확인).
   - 카탈로그 조회 실패/그 지역 없음 + `clientObservedCurrency` 있음 →
     `analyticsCurrency` = 클라이언트 값, `source: "GOOGLE_CLIENT_STOREFRONT"`,
     정산은 계속 진행(거부되지 않음).
   - 카탈로그 값과 `clientObservedCurrency` 가 서로 다름 → 카탈로그 값 채택,
     불일치가 구조화 로그로 기록됨(§6.2).
   - 둘 다 없음 → `analyticsCurrency: null`, 정산은 계속 진행 — §6.2 의
     "이번 폴백도 전건 보장은 아니다"를 회귀로 고정.
3. **`operation-worker.test.ts`**
   - `parser_capabilities: ["purchase_revenue_v1"]` 포함 + 런타임 플래그
     활성 + 스냅샷에 analytics 값 있음 → 응답에 `currency`/`value` 포함.
   - `parser_capabilities` 누락/빈 배열/배열 아님(문자열 등)/알려지지 않은
     값만 있음 → fail-closed, 7키만 응답(§9.4-3 회귀).
   - `parser_capabilities` 포함하지만 `wallet.purchase_revenue_fields_enabled`
     플래그 비활성 → 7키만 응답(§9.4-5 킬스위치 회귀).
   - **재현(replay) 시나리오**: 인박스 최초 커밋 시 `requestContext.app_build`
     는 구버전이었지만, 같은 영수증으로 재시도하는 이번 호출은
     `parser_capabilities` 를 보냄 → 응답에 `currency`/`value` 포함(§9.4-4,
     "최초 requestContext 가 아니라 이번 요청 capability" 회귀 — 요구사항의
     핵심 안전성 증명).
   - 크론 배치 호출(`{"limit":50}`, `inbox_id` 없음)은 `parser_capabilities`
     유무와 무관하게 항상 동일하게 동작(정산만 진행, 응답 모양 신경 안 씀).
   - Google 응답(가격 필드 없음, 오늘과 동일) → `providerCurrency`/
     `providerPaidAmountMinor` 는 `null` 유지, 정산은 정상 진행(거부되지
     않음) — §6.2 의 QUANTITY 불변식 유지를 회귀로 고정.
4. **`verify-receipt-intake.test.ts`**
   - `parser_capabilities` 가 `wallet-operation-worker` 단일 인박스 호출에
     그대로 전달되는지(포워딩 테스트, §9.4-2).
   - `shapeForCapabilities` 가 `return response(worker)` 직전에 적용돼
     capability 없는 응답에는 `currency`/`value` 키 자체가 JSON 에 존재하지
     않는지(단순 `null` 이 아니라 키 부재 — `requireExactContractKeys` 를
     아직 쓰는 구버전 파서가 여분 키 때문에 죽지 않게 하는 §8.1 전제 재확인).
5. **`purchase-settlement.test.ts`**
   - `purchase_reward_snapshots` 의 `provider_currency`/`provider_paid_amount_minor`
     는 Apple/Google(QUANTITY) 구매에 대해 **항상 `null`** — `attest_verified_purchase`/
     `grant_verified_purchase` 호출 인자와 무관하게 이 불변식이 유지되는지
     (이전 초안이 뒤집었던 것을 다시 뒤집지 않도록 고정하는 회귀).
   - `analytics_currency`/`analytics_price_milliunits` 는 위와 완전히
     독립적으로 채워지는지(같은 트랜잭션에서 한쪽은 `null`, 다른 쪽은
     값이 있는 조합이 정상임을 확인).

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
하고, 그건 새 택소노미 항목이라 대행사 승인이 또 필요하다(`docs/analytics/agency-reply.html`
에 승인 대기 항목이 이미 3건 있는데, 그 문서 자체가 2026-08-21 현재 대행사에
**아직 발송조차 되지 않았다** — `handoff-20260821-ga4-taxonomy.html` 64·148행.
새 이벤트를 또 얹으면 발송도 안 된 채널에 협상거리를 하나 더 쌓는
셈이다). (2) 스토어 재무 리포트는 거래 단위가 아니라
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
- 명시적 parser capability 게이팅(§9.4)이 "선배포 → 후배포"라는 요구사항을
  "사용자 업데이트를 기다리는 느슨한 순서 지침"에서 "요청 단위로 안전한
  전환"으로 바꾼다 — `app_build` 로 추론하는 대신 클라이언트가 매 요청마다
  스스로 선언하게 해서, OTA 패치가 build number 를 바꾸지 않는다는 사실과
  무관하게 항상 정확하다(§9.3).

## 15. 이 설계가 새로 남기는 한계

`ga4-event-taxonomy.md` §7 "알려진 한계" 표 형식을 따라, 이 설계를 구현한
뒤에도 남는 한계를 명시한다.

| # | 한계 | 내용 | 처리 |
|---:|---|---|---|
| 1 | **Google 구매 전건의 `currency` 보장은 이 설계로 해결되지 않는다** | §6.2 폴백(출처 A/B)은 best-effort 다 — 지역별 카탈로그가 그 지역을 안 다루거나, 구버전 클라이언트가 storefront 값을 아직 안 보내거나, 조회가 실패하면 여전히 `null` 이다. `value`(금액)는 이 phase 에서 Google 에 대해 **항상** `null` 이다(출처 자체가 없음, §6.2) | **완료로 간주하지 않는다.** "부분/최선노력 커버리지를 받아들일지"는 대행사 확인이 필요한 별도 의사결정 게이트로 남긴다(§6.2-부칙) — B-10(아래 6번 행)과 같은 성격의, 코드 배포로 저절로 닫히지 않는 항목이다 |
| 2 | Apple 값도 항상 보장되지는 않는다 | `price`/`currency` 는 공식적으로 optional 필드라 일부 트랜잭션에서 여전히 부재할 수 있다 | §6.3 실패 정책대로 `null` 처리, §4 문제가 "가끔"으로 줄어드는 것이지 "완전히 사라지는 것"은 아니다 |
| 3 | Google 지역 카탈로그 통화(§6.2 출처 A)도 완전한 진실은 아니다 | 통화는 지역별로 고정이라 가격보다 신뢰도가 높지만, Picnic 상품 콘솔이 어느 Play Developer API 모델(`inappproducts` 구/`monetization.onetimeproducts` 신)을 쓰는지는 이 문서가 코드로 확인하지 못했다(§12) | 구현 착수 전 Play Console 설정 확인 필요 — 이 문서가 선결하지 않은 유일한 외부 API 전제 |
| 4 | `wallet.purchase_revenue_fields_enabled` 플래그의 실제 on/off 시점은 운영 판단이다 | 메커니즘(§9.4-5)은 이 문서가 규정하지만, 언제 켤지는 §3 비목표의 "배포 실행 제외"에 따라 별도 운영 결정이다 | 플래그 존재는 설계 확정, 시점은 배포 작업에서 정한다 |
| 5 | Google/PayPal/PortOne 의 `value` 단위 변환은 서로 다르다 | Apple 은 밀리유닛(÷1000, §6.1), PayPal/PortOne 은 `exactMinorUnits` 의 통화 exponent 기반 마이너유닛(÷10^exponent, 기본 2) — 이 설계는 Apple 변환만 명시했고 PayPal/PortOne 을 실제로 wire 에 노출하는 건 범위 밖으로 남겼다(§5.3) | PayPal/PortOne 을 노출하는 후속 설계는 이 두 변환 방식이 섞이지 않게 명시적으로 분기해야 한다 |
| 6 | `agency-reply.html` B-10(`ad_impression` 자동 수집 중복)은 이 설계와 무관하지만 여전히 미해결이다 | B-10 은 이 문서가 다루는 purchase 계약과 다른 이벤트(`ad_impression`)에 대한 별개 질문이고, 그 문서 자체가 아직 대행사에 발송되지 않았다(`handoff-20260821-ga4-taxonomy.html` 64·148행, "미확인/미발송") — 발송 후에도 GA4 콘솔의 자동 수집 설정을 실기기 DebugView 로 확인하기 전까지는 닫히지 않는다 | 이 문서는 B-10 을 해결하지 않으며, 해결한 것처럼 읽히지 않도록 명시적으로 열어 둔다 — §10 의 로그인 중복 DebugView 체크리스트와 같은 성격의, 실측 전 unresolved decision gate |

## 16. 참고 문서

| 경로 | 내용 |
|---|---|
| `docs/analytics/ga4-event-taxonomy.md` | 택소노미 기준 문서. §2-9 `purchase` 파라미터 정의, §4-8 currency undefined 대체 불가 규칙, §7 #1 이 문서가 푸는 한계, §8 이미 좁혀진 권장 방향 |
| `docs/analytics/trigger-mapping.md` | §9 `purchase` 트리거 지점(계획 당시 문서, 현재 라인 번호와는 다름) |
| `docs/operations/handoff-20260821-ga4-taxonomy.html` | 8/21 시점 상태 핸드오프. §3-④ 가 이 문서가 구체화한 미해결 과제, §3-② DebugView 체크리스트(로그인 중복 검증 포함) |
| `docs/analytics/agency-reply.html` | 대행사 회신 대기 항목(대안 2 기각 근거로 인용) |

---

이 문서 작성 과정에서 스스로 점검한 것: (1) "서버 권위"와 "서버가 null
이면 클라이언트 값을 쓴다"가 모순처럼 보일 수 있어 §5.4 에서 관계를
명시했다. (2) Google 을 Apple 과 같은 수준으로 "provider 검증값"이라고
뭉뚱그리면 사실과 다르므로 §6.2 에서 API 자체의 한계로 명확히 구분했다.
(3) `assertWebProductPrice` 를 Google 에 그대로 재사용하자는 자연스러운
제안을 §6.2 에서 검토했으나 무결성 게이트와 계측 보강의 목적이 다르다는
이유로 명시적으로 배제했다. (4) "앱 선배포"가 실제로 무엇을 보장하고
무엇을 보장하지 않는지 §9.2 에서 분리하고, 부족한 부분을 §9.4 의 구체
메커니즘으로 메웠다(최초 초안의 §9.3 `app_build` 메커니즘은 이번 개정에서
직접 반증되어 §9.3 은 "왜 안 되는가"로, §9.4 는 그 대체 메커니즘으로
재편했다 — 위 (8)번 참고). (5) 배포·마이그레이션·PR·로그인 중복 재설계·Google
지역 가격 근사(통화 제외)는 각 절에서 반복해 범위 밖임을 명시해, 읽는 사람이 이
문서의 승인을 그 작업들의 승인으로 착각하지 않게 했다. (6) §12 파일
목록을 작성하며 "변경 없음"이라 적으려던 `candy_reward_receipt.dart` 를
실제로 확인해 보니 `currency` 라는 이름의 필드가 이미 존재했다 — 이
설계의 ISO 4217 `currency` 와는 다른 개념(`WalletCurrency` 열거형)임을
확인하고 혼동 가능성을 명시적으로 적었다. 문서 안의 "§N" 절 번호가 이
문서 자체와 인용하는 taxonomy 문서 양쪽에 겹쳐 존재해 모호했던 지점들도
전부 "taxonomy 문서 §N" 형태로 명시해 구분했다.

**2026-08-21 교차 리뷰 반영 개정에서 추가로 점검한 것**: (7) 이전 초안의
핵심 결함을 실제 SQL 로 확인했다 — `verifyApple` 이 `providerPaidAmountMinor`/
`providerCurrency` 를 채우는 계획은 `grant_verified_purchase`
(`purchase_settlement_commands.sql:436-449`)의 `PURCHASE_INVALID_QUANTITY_BASIS`
불변식과 충돌해 배포 즉시 대다수 Apple 구매를 정산 거부로 깨뜨렸을
것이다 — 이 문서 자체를 시뮬레이션이 아니라 실제 마이그레이션 SQL 을
읽어서 검증했다(§5.3). (8) `app_build` 게이팅이 안전하다는 이전 초안의
전제도 두 겹으로 틀렸음을 확인했다: Shorebird OTA 는 build number 를
바꾸지 않고(`flutter-release.md`), `verify_receipt/index.ts` 는 애초에 이번
요청의 `app_build` 를 `wallet-operation-worker` 호출에 넘기지 않는다(`{
inbox_id }` 뿐) — 그래서 응답 조립은 구조적으로 "최초 커밋 시점의 저장된
값"만 볼 수 있었다(§9.3). (9) `verify-receipt-v2` 가 실제 프로덕션 엔드포인트
이름이고 `verify_receipt` 는 레거시 별칭이라는 사실을 `supabase/config.toml`
과 `verify-receipt-v2/index.ts` 로 확인했다 — 다만 둘이 지금 같은 핸들러를
공유한다는 사실도 함께 확인했으므로, 이 문서의 기존 파일 경로 인용은
바꾸지 않고 "실제로 서비스되는 이름"만 정정했다(§2). (10) `agency-reply.html`
의 B-2/B-3 를 원문 그대로 다시 읽어, 이전 초안의 "둘 중 하나만 있으면
둘 다 버린다"는 대칭 규칙이 실제로는 "`currency` 결측 시에만 `value` 도
같이 버린다"는 비대칭 규칙이었음을 발견해 정정했다(§6.3/§7) — 동시에 그
문서 자체가 아직 대행사에 발송되지 않은 내부 초안이라는 사실도
`handoff-20260821-ga4-taxonomy.html` 로 확인해 근거의 무게를 낮춰 적었다.
(11) Google `currency` 폴백(§6.2)은 실제로 구현 가능한 최소 설계까지
구체화했지만, **"Google 구매 전건의 currency 보장"이라는 문제 자체는
풀지 못했다** — best-effort 폴백과 100% 보장을 혼동하지 않도록 §15 1번
행에 명시적으로 미해결로 남겼고, 완료로 포장하지 않았다.

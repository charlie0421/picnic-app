# 코튼캔디 지갑 + 캔디 부스트 데이 설계

- 날짜: 2026-07-21
- 상태: 사용자 최종 승인 완료, 구현 계획 작성 완료·실행 방식 선택 대기
- 조정 브랜치: `feat/cotton-candy-policy`
- 범위: `picnic-app`, `picnic-supabase`, `picnic-admin`
- 기준 시간대: `Asia/Seoul`
- 원본 참고 자료: `/Users/charlie.hyun/Downloads/재화정책2.1.html`

## 1. 결정 요약

1. 새 광고 재화의 사용자 노출명은 **코튼캔디(Cotton Candy)** 다. 사용자 화면에서 `솜사탕`을 사용하지 않는다.
2. 코튼캔디는 기존 보너스 스타캔디와 분리한 **독립 만료 버킷 + 불변 원장**으로 관리한다.
3. 코튼캔디는 지급 시점 다음 KST 자정에 만료된다.
4. 일반 투표는 **코튼캔디 → 보너스 스타캔디 → 스타캔디** 순으로 서버가 차감량을 계산한다.
5. 코튼캔디 사용 범위는 일반 투표다. JMA와 궁합에는 사용하지 않는다. PIC 투표 비활성화는 별도 작업이다.
6. V1 코튼캔디 지급원은 내부 숏폼의 `view` 보상과 Pangle rewarded-view SSV다. Tapjoy, Pincrux, 비활성 legacy 채널, 내부 숏폼의 다른 action은 기존 정책을 유지한다.
7. 임시 프로모션 브랜드는 **캔디 부스트 데이(Candy Boost Day)** 다. 시스템 코드는 표시명과 분리해 향후 브랜딩 변경에 대응한다.
8. 캔디 부스트 데이는 KST 기준 월요일 00:00 이상, 수요일 00:00 미만인 구매에 적용한다.
9. 프로모션 추가 지급량은 `floor((상품 Star + 채널 기본 Bonus) × 추가 Bonus 배율)`이다. V1 배율은 1.0, 즉 기본 총 지급량의 100%를 보너스 스타캔디로 추가한다.
10. 구매 자격은 Apple/Google의 검증된 구매 시각 또는 PayPal/PortOne의 검증된 capture 시각으로 판정한다. 클라이언트 시각과 Edge 처리 시각은 사용하지 않는다.
11. 환불은 원 구매 snapshot의 기본 지급과 프로모션 지급을 역분개한다. 잔액이 부족하면 Star/Bonus별 부채를 만들고 이후 같은 통화 적립에서 먼저 상계한다. 코튼캔디로 Star/Bonus 부채를 상계하지 않는다.
12. V1 부분 환불은 기본 Star/Bonus만 누적 비율로 회수하고, 프로모션 Bonus는 첫 유효 환불에서 전액 회수한다.
13. Supabase가 재화 원장의 단일 진실이다. 앱과 관리자는 잔액·원장 테이블을 직접 수정하지 않는다.
14. 모든 금융 명령은 멱등하며 원장·버킷·projection·도메인 기록을 한 트랜잭션으로 커밋한다.
15. 출시는 additive schema와 읽기 계약부터 시작한다. 만료 집행과 reconciliation은 최초 실제 코튼캔디 지급보다 먼저 활성화한다.

## 2. 목표와 비목표

### 목표

- 광고 보상을 구매 보너스와 분리해 짧은 유효기간을 가진 코튼캔디로 운영한다.
- 앱, 데이터베이스, 관리자 화면에서 세 재화의 의미와 내역을 일관되게 표시한다.
- 재시도, 동시 호출, 자정 경계, 환불, 운영 설정 변경에도 중복 지급·음수 잔액·부분 커밋이 발생하지 않게 한다.
- 캔디 부스트 데이의 지급과 홈/스토어 노출을 같은 서버 정책으로 평가한다.
- 운영자가 SQL 없이 사용자 거래를 설명하고, 직접 잔액 수정 없이 감사 가능한 복구를 실행할 수 있게 한다.
- 기존 앱과 API 계약을 additive하게 확장하고 단계적으로 전환한다.

### 비목표

- PIC 투표 비활성화 구현. 별도 기능 플래그/작업으로 분리한다.
- JMA 및 궁합 재화 정책 변경.
- Tapjoy, Pincrux, 비활성 legacy 광고 채널의 지급 통화 변경.
- 기존 Star/Bonus 원장의 전면 재설계 또는 순수 event sourcing 전환.
- V1 관리자 화면에서 코튼캔디 수동 적립·차감 제공.
- 캠페인별 복잡한 상품 선택, 쿠폰 중첩, 다중 프로모션 stacking.
- 원장 삭제, 과거 정책 수정, 음수 지갑을 이용한 부채 표현.

## 3. 용어와 사용자 노출 규칙

| 개념 | 사용자 노출명 | 내부 식별자 예시 | 비고 |
|---|---|---|---|
| 일반 유료 재화 | 스타캔디 | `STAR_CANDY` | 기존 정책 유지 |
| 기존 보너스 재화 | 보너스 스타캔디 | `BONUS_STAR_CANDY` | 기존 만료 버킷 유지 |
| 신규 광고 재화 | 코튼캔디 | `COTTON_CANDY` | 다음 KST 자정 만료 |
| 구매 프로모션 | 캔디 부스트 데이 | `CANDY_BOOST_DAY` | 표시명은 version별 다국어 값 |

- 사용자 문자열, 접근성 라벨, 푸시/팝업, 도움말에서 `솜사탕`을 사용하지 않는다.
- `candy_history_type`은 **지급 사유**를 나타내는 기존 enum이다. 통화 enum이 아니므로 `COTTON_CANDY`를 여기에 추가하지 않는다.
- 통화와 사유를 별도 필드로 유지한다.
- 프로모션 운영 코드는 표시명과 분리한다. 향후 이름이 바뀌어도 구매 snapshot과 참조 무결성은 유지된다.

## 4. 선택한 접근법

### 선택: 만료 버킷 + 불변 원장 + projection

- `cotton_candy_grants`가 실제 사용 가능한 코튼캔디의 권위 상태다.
- `cotton_candy_ledger`가 `GRANT`, `CONSUME`, `EXPIRE` 이벤트를 append-only로 보존한다.
- `user_profiles.cotton_candy`는 빠른 조회를 위한 materialized projection이다. 사용자에게 보여 주는 spendable 값은 아니다.
- 앱과 관리자는 안정된 wallet/history RPC를 읽는다.

### 기각한 대안

1. **기존 Bonus history에 통화 컬럼만 추가**
   - 기존 합계·만료·투표 쿼리가 코튼캔디를 Bonus로 오인할 위험이 크다.
   - 기존 `parent_id` 모델의 의미·부호 혼재를 확대한다.
2. **순수 event sourcing**
   - 감사성은 좋지만 FIFO 만료 소비 때 전체 이벤트 재생 비용과 구현 범위가 과하다.
3. **profile 잔액만 권위로 사용**
   - 만료 근거, 지급 거래 1:1 멱등성, 환불·감사를 재현할 수 없다.

## 5. 제품 동작

### 5.1 코튼캔디 지급

- 내부 숏폼 `view` 보상과 Pangle rewarded-view만 코튼캔디로 전환한다.
- 내부 숏폼의 안정 멱등 키는 `internal_shortform:view:<impression_id>`다.
- Pangle의 안정 멱등 키는 `pangle:<environment>:reward:<trans_id>`다.
- 지급 수량과 보상 자격은 검증 완료한 서버가 결정한다. 앱이 보낸 amount를 신뢰하지 않는다.
- 지급 시각과 만료 시각은 같은 DB clock snapshot으로 계산한다.
- 동일 지급 이벤트 재호출은 최초 grant와 현재 wallet summary를 반환하며 추가 지급하지 않는다.
- 동일 멱등 키를 다른 사용자, 수량, source 또는 claim에 재사용하면 보안 충돌로 거부한다.
- provider별 source 값은 DB가 정규화한다. production/sandbox가 같은 거래 ID를 공유할 수 있으므로 환경을 canonical key에 포함한다.

### 5.2 만료

- `granted_at`의 다음 `Asia/Seoul` 자정이 `expires_at`이다. 정확히 자정에 지급된 grant도 그 다음 날 자정에 만료된다.
- `expires_at` 직전까지 사용할 수 있고 정각부터 사용할 수 없다.
- 배치 worker가 늦어도 모든 wallet summary와 소비 쿼리는 `expires_at > fixed_db_now`인 grant만 사용한다.
- 모든 wallet writer의 전역 lock 순서는 `per-user advisory → user_profiles row → currency bucket/grant`다. expiry batch는 due user ID 후보만 먼저 읽고 `pg_try_advisory_xact_lock`에 성공한 사용자별로 profile row를 `FOR UPDATE SKIP LOCKED`한 뒤 Cotton grant를 잡는다. grant를 먼저 lock하지 않는다.
- Cotton과 기존 Bonus expiry batch 모두 이 사용자 단위 순서를 사용하고 grant별 `EXPIRE`를 최대 한 번 기록한다.
- 일반 투표 안에서는 해당 사용자의 overdue grant를 lazy expiry 대상으로 다룬다.
- 만료 문제를 이유로 과거 `expires_at`을 연장하거나 grant/ledger를 삭제하지 않는다.

### 5.3 일반 투표 소비

- 지원 범위는 일반 투표다.
- 차감 순서는 코튼캔디, 보너스 스타캔디, 스타캔디다.
- 코튼캔디와 보너스 스타캔디는 만료 임박 순, 같은 만료 시각이면 ID 순으로 FIFO 소비한다.
- 클라이언트가 보낸 통화별 usage는 권위 값이 아니다. 서버가 총 요청 수량에서 실제 usage를 계산한다.
- 총 유효 잔액이 부족하면 어떤 재화·투표 기록도 변경하지 않는다.
- 같은 `request_id`와 같은 payload는 기존 `vote_pick`을 반환한다. 같은 ID에 다른 payload는 거부한다.

### 5.4 캔디 부스트 데이

- 주간 window는 KST 월요일 00:00 이상, 수요일 00:00 미만의 반개구간이다.
- 구매 자격은 검증된 공급자 발생 시각으로 평가한다.
- 기본 Star는 `products.star_candy`를 사용한다.
- 채널 기본 Bonus는 현재 채널 정책의 서버 상품 값을 사용한다. 모바일은 `star_candy_bonus`, 웹 채널은 `web_bonus_amount`를 기준으로 한다.
- V1 프로모션 추가분은 다음과 같다.

```text
base_reward_total = base_star_amount + channel_base_bonus_amount
promo_bonus_amount = floor(base_reward_total × 1.0)
```

- 기본 Bonus와 프로모션 Bonus를 원장에서 구분한다.
- 프로모션 지급 사유는 `CANDY_BOOST`로 기록한다.
- 프로모션 설정이 바뀌어도 과거 지급과 환불은 구매 당시 snapshot을 사용한다.
- 구매 자체는 검증됐으나 공급자 발생 시각만 검증할 수 없으면 기본 Star/Bonus를 지급하고 promotion resolution을 `PENDING_TIME`(API domain code `PROMO_REVIEW_REQUIRED`)으로 보류한다. 처리 시각으로 자격을 대체하지 않는다.
- 보류 중 환불이 먼저 확정되면 구매를 환불 상태로 잠그고 이후 프로모션 추가 지급을 차단한다.

### 5.5 스토어와 홈 이벤트 배너

- 스토어 상품 badge와 홈 이벤트 배너는 서버의 현재 시각으로 같은 campaign-version evaluator를 사용한다.
- 구매 자격 판정은 공급자 구매 시각, 현재 노출 판정은 서버 현재 시각이라는 차이만 있다.
- campaign version의 `show_in_store`, `show_home_banner`가 surface를 독립 제어한다.
- 기존 `banner` 행은 이미지, CTA, 딥링크 등 creative만 보관한다.
- 캔디 부스트 노출 일정의 권위는 campaign version이다. `banner.start_at/end_at`을 별도 권위 일정으로 사용하지 않는다.
- 홈 배너는 좌측 정렬 카피와 승인된 핑크 계열 프로모션 디자인을 사용한다.
- 기간 밖이거나 캠페인이 비활성이면 홈과 스토어 모두 노출하지 않는다.
- `display_name.ko`는 필수다. 다른 locale이 없으면 `ko`, 그마저 유효하지 않으면 campaign code 순으로 fallback하며 빈 배너를 렌더링하지 않는다.

### 5.6 환불과 부채

- 환불은 현재 campaign을 재평가하지 않고 원 구매 snapshot의 기본 Star, 기본 Bonus, 프로모션 Bonus를 역분개한다.
- 즉시 회수 가능한 같은 통화 잔액만 회수하고 잔액을 음수로 만들지 않는다.
- 부족분은 Star/Bonus별 `wallet_recovery_debts`로 남긴다.
- 이후 같은 통화의 모든 gross credit는 가장 오래된 open debt부터 상계하고 남은 금액만 wallet에 적립한다.
- 다른 통화끼리 상계하지 않는다. 코튼캔디 광고 지급도 Star/Bonus 부채를 상계하지 않는다.
- 자동 상계를 활성화하기 전에 모든 Star/Bonus 지급 경로가 공통 `credit_*_with_debt` 경계로 들어와야 한다.
- 부분 환불의 기본 Star/Bonus는 공급자가 검증한 누적 환불 금액 또는 수량을 정수 비율로 계산한다. 부동소수점을 사용하지 않고 누적 역분개 목표를 `floor(original_base_component × cumulative_refunded_numerator / original_denominator)`로 계산한다. 이번 역분개액은 `누적 목표 - 과거 역분개 합계`다.
- V1 프로모션 Bonus는 구매가 환불되지 않았다는 조건의 혜택으로 본다. **금액과 무관하게 첫 유효 환불에서 promo Bonus 전액을 회수**한다. resolution 전 환불이면 `CANCELLED_BY_REFUND`로 award 0건, award 후 환불이면 첫 refund allocation의 promo 누적 목표를 원 promo 전액으로 만든다. 따라서 worker 처리 순서와 부분 환불 비율이 최종 promo 잔액을 바꾸지 않는다.
- 원 구매 적립이 과거 부채를 일부 또는 전부 상계했더라도 환불은 원 구매의 **gross 지급액 전체**를 대상으로 한다. 과거 부채와 recovery event는 다시 열거나 되돌리지 않고, 현재 지갑에서 회수하지 못한 금액은 원 환불 allocation을 출처로 하는 새 `PURCHASE_REFUND` 부채로 남긴다.

## 6. UI와 브랜딩

### 6.1 지갑

- 지갑은 스타캔디, 보너스 스타캔디, 코튼캔디의 3분할 레이아웃을 사용한다.
- 텍스트는 좌측 정렬한다.
- 코튼캔디에는 오늘 만료량과 다음 만료 시각을 보조 정보로 표시한다.
- 조회값은 raw profile row가 아니라 서버 wallet summary를 사용한다.
- 스토어, 투표, 공통 내 재화 정보, 사용 정책 dialog가 같은 명칭과 순서를 사용한다.

### 6.2 아이콘

- 세 아이콘은 같은 크기, 광택, 외곽선, 그림자 언어를 가진 하나의 family로 제작한다.
- 스타캔디는 기본 별, 보너스 스타캔디는 강조된 별, 코튼캔디는 사용자가 제공한 코튼캔디 레퍼런스 사진의 실루엣을 참고한 분홍·하늘색 아이콘을 사용한다.
- 승인 시안의 투명 PNG를 최종 앱 asset으로 정리하되 `.superpowers/`의 preview 파일을 직접 제품 asset으로 참조하지 않는다.
- 접근성 라벨은 각 사용자 노출명과 일치해야 한다.

### 6.3 프로모션

- 사용자 노출명은 `캔디 부스트 데이`다.
- 프로모션 카드는 핑크 계열의 double-benefit 인상을 유지한다.
- 배너와 스토어 카피는 좌측 정렬한다.
- “기본 지급 + 추가 보너스”를 구분해 표시하고 `2배` 표현은 실제 계산값이 정확히 100% 추가일 때만 사용한다.

## 7. 시스템 책임 경계

### picnic-supabase

- schema, constraint, RLS, server-only write guard의 소유자다.
- 광고, 투표, 구매, 환불, 만료, 부채 상계 명령을 원자적 RPC로 제공한다.
- KST 만료, 프로모션 window, 통화 사용 순서를 판정한다.
- 멱등성, durable inbox, reconciliation, alert, audit를 관리한다.
- 앱/관리자 DTO를 반환하는 read RPC를 제공한다.

### picnic-app

- 세 재화 wallet과 이력, 만료 안내, 광고 상태, 스토어와 홈 프로모션을 표시한다.
- 광고 claim, 일반 투표, 영수증 검증 요청을 보낸다.
- 서버가 확정한 amount, expiry, status만 사용자에게 표시한다.
- Pangle native reward 이벤트는 status polling 시작 신호로만 사용한다.
- 잔액과 만료를 로컬에서 최종 계산하지 않는다.

### picnic-admin

- 캠페인 새 version 생성, 활성/비활성, surface 설정과 감사 이력을 제공한다.
- 세 재화, 구매, 환불, debt, alert, operation timeline을 조회한다.
- dry-run 가능한 제한 command RPC만 실행한다.
- 목표 잔액 입력, 원장 수정/삭제, 시스템 type 선택을 제공하지 않는다.

## 8. 데이터 모델

### 8.1 코튼캔디

#### `user_profiles`

- `cotton_candy integer NOT NULL DEFAULT 0 CHECK (cotton_candy >= 0)` 추가.
- 조회 성능용 projection이며 권위 데이터가 아니다. 아직 batch가 materialize하지 않은 overdue grant를 포함할 수 있다.
- projection 불변식은 `cotton_candy = 모든 grant의 remain_amount 합계`다. 사용자 spendable 잔액은 `expires_at > fixed_db_now` 조건으로 별도 계산한다.
- admin을 포함한 직접 갱신을 server-only guard로 차단한다.

#### `cotton_candy_grants`

주요 필드:

- `id bigint identity primary key`
- `user_id uuid` → `user_profiles(id) ON DELETE RESTRICT`
- `source_provider`, `source_environment`, `source_event_type`, `source_transaction_id`
- nullable `claim_id`, nullable `impression_id`
- `idempotency_key text UNIQUE`
- `original_amount integer CHECK > 0`
- `remain_amount integer CHECK (0 <= remain_amount AND remain_amount <= original_amount)`
- `granted_at timestamptz`
- `expires_at timestamptz CHECK (expires_at > granted_at)`
- `metadata jsonb`

필수 index:

- `(user_id, expires_at, id) WHERE remain_amount > 0`
- `(expires_at, id) WHERE remain_amount > 0`

`idempotency_key`의 unique 범위에 `user_id`를 넣지 않는다. 같은 공급자 거래가 다른 사용자에게 재지급되는 것을 막아야 한다.

- `(source_provider, source_environment, source_event_type, source_transaction_id)`도 unique로 강제한다. DB가 정규화한 source tuple에서 canonical idempotency key를 만들며, wrapper가 다른 operation key를 보내도 같은 source transaction은 추가 grant를 만들지 않는다.
- Pangle source는 `claim_id IS NOT NULL AND impression_id IS NULL`, 내부 숏폼 source는 그 반대가 되도록 provider/event별 XOR check를 둔다.
- `user_id`, source tuple, `idempotency_key`, amount, `granted_at`, `expires_at`은 모두 `NOT NULL`이고 metadata는 빈 object가 기본값이다. ledger의 사용자 일치 FK를 위해 `UNIQUE(id, user_id)`를 둔다.

#### `cotton_candy_ledger`

주요 필드:

- `id bigint identity primary key`
- `user_id`, `grant_id`
- 선택 참조: `vote_pick_id`, source transaction/reference
- `event_type IN ('GRANT', 'CONSUME', 'EXPIRE')`
- `amount_delta`: GRANT는 양수, CONSUME/EXPIRE는 음수
- `operation_key`
- `created_at`

제약:

- `UNIQUE(operation_key, grant_id, event_type)`
- `user_id`, `grant_id`, `operation_key`, `event_type`, `amount_delta`, `created_at`은 `NOT NULL`이다.
- `(grant_id, user_id)`가 grant의 같은 조합을 참조하는 composite FK여서 다른 사용자의 grant를 원장에 연결할 수 없다.
- `GRANT`의 `amount_delta > 0`, `CONSUME/EXPIRE`의 `amount_delta < 0`을 check로 강제한다.
- partial unique는 grant별 GRANT/EXPIRE를 각각 **최대 하나**로 강제한다. GRANT 정확히 하나는 grant 생성 RPC와 reconciliation이 보장한다.
- grant별 EXPIRE 최대 하나
- `UNIQUE(grant_id) WHERE event_type='GRANT'`
- `UNIQUE(grant_id) WHERE event_type='EXPIRE'`
- 소비가 여러 grant를 쓰면 공통 operation key로 grant별 CONSUME 행을 남긴다.
- `balance_after`는 다중 버킷 처리 순서 의존성을 만들므로 ledger에 저장하지 않는다.
- INSERT는 전용 command RPC에만 허용한다. UPDATE/DELETE는 service role을 포함해 immutable trigger와 권한으로 차단한다.

#### `ad_reward_claims`

- Pangle 광고 load 전에 서버가 발급하는 intent다.
- 주요 필드: `id`, `user_id`, `channel`, `environment`, `platform`, `placement_id`, `client_request_id`, `status`, `provider_transaction_id`, `expires_at`, `result_grant_id`, `payload_hash`, `acknowledged_at`.
- 상태: `PENDING`, `GRANTED`, `DENIED`, `EXPIRED`, `ABANDONED`.
- `UNIQUE(channel, environment, provider_transaction_id)`와 claim당 최대 한 grant를 강제한다.
- intent 발급 재시도는 `UNIQUE(user_id, channel, client_request_id)`로 기존 intent를 반환한다. 같은 client request ID에 다른 platform/placement payload를 사용하면 충돌로 거부한다.
- claim TTL은 서버 설정으로 정하고 클라이언트 입력을 받지 않는다.
- claim의 user/channel/environment/platform/placement/client request/status/payload hash/expiry는 `NOT NULL`이다. `GRANTED ↔ result_grant_id IS NOT NULL`을 check로 강제하고 `result_grant_id UNIQUE` 및 `(result_grant_id, user_id)` composite FK로 한 grant를 두 claim이나 다른 사용자에게 연결하지 못하게 한다.
- `PENDING`만 `GRANTED`, `DENIED`, `EXPIRED`, `ABANDONED`로 전이할 수 있고 모든 terminal 상태는 불변이다. 이미 `GRANTED`인 provider transaction의 replay는 정책·일일 한도를 다시 평가하지 않고 최초 결과를 반환한다.
- 내부 숏폼은 기존 `ad_impressions.id`가 intent 역할을 하므로 별도 claim을 만들지 않는다. V1 Cotton 대상인 `view`를 다른 action과 섞지 않도록 `ad_impressions`에 `view_reward_status`, `view_result_grant_id`, `view_reward_acknowledged_at`, `view_reward_payload_hash`를 추가하고 Pangle claim과 같은 terminal 전이·사용자 일치 FK를 적용한다. 미확인 목록 RPC는 두 테이블을 safe DTO로 합친다.

#### `vote_pick`

- `cotton_candy_usage integer NOT NULL DEFAULT 0 CHECK >= 0`
- `request_id uuid`
- `request_payload_hash text`
- `UNIQUE(user_id, request_id) WHERE request_id IS NOT NULL`
- 동일 request ID는 vote/item/amount의 canonical payload hash가 같을 때만 replay한다.
- 장기 불변식: `amount = cotton_candy_usage + star_candy_bonus_usage + star_candy_usage`.
- 기존 데이터 검증 전 합계 constraint는 `NOT VALID`로 추가한 뒤 별도 검증한다.

### 8.2 프로모션과 구매

#### `promotion_campaigns`

- 안정된 identity만 보관한다.
- 주요 필드: `id uuid`, `code UNIQUE`, `kind='PURCHASE_BONUS'`, 생성 정보.
- V1 code는 `CANDY_BOOST_DAY`다.

#### `promotion_campaign_versions`

- append-only 설정 version이다.
- 주요 필드:
  - `id uuid primary key`, `campaign_id`, `version`, `effective_from`
  - `is_active`
  - `timezone='Asia/Seoul'`
  - `weekly_start_isodow=1`, `weekly_start_time='00:00:00'`
  - `weekly_end_isodow=3`, `weekly_end_time='00:00:00'`
  - `extra_bonus_bps=10000`
  - `display_name` 다국어 JSON
  - `show_home_banner`, `show_in_store`, `home_banner_id`
  - `rollout_policy`: 대상 앱 version, 고정 cohort 방식·seed·threshold의 immutable JSON
  - 변경자, 변경 사유, 생성 시각
- `UNIQUE(campaign_id, version)`, `UNIQUE(campaign_id, effective_from)`을 둔다. version은 command 안에서 최신값 + 1로만 생성한다.
- V1은 미래 예약과 backdate를 모두 지원하지 않는다. 관리자 저장은 campaign/kind lock과 예상 latest version을 검증한 뒤 `effective_from=DB transaction_timestamp()`인 새 행만 추가한다. 예약 기능은 supersede 규칙을 별도 설계한 뒤 확장한다.
- 한 시점의 유효 version은 `effective_from <= at` 중 `(effective_from DESC, version DESC)` 첫 행이다. 그 행이 inactive면 **적용 없음**이며 과거 active version으로 fallback하지 않는다. 다음 version의 `effective_from`이 이전 version의 논리적 종료다.
- 과거 version을 update/delete하지 않는다.
- V1은 같은 `kind`에서 한 구매에 둘 이상의 캠페인이 적용되지 않도록 command가 겹치는 활성 정책을 거부한다.
- `extra_bonus_bps`는 `0..100000`, timezone은 `Asia/Seoul`, 주간 시작·종료 조합은 유효한 반개구간이어야 한다. `display_name.ko`는 비어 있지 않아야 한다.
- `show_home_banner=true`이면 `home_banner_id`와 유효한 `display_name.ko`가 반드시 있어야 한다. V1의 HOME surface는 기존 `banner.location='vote_home'`에 매핑한다. `home_banner_id`는 `banner`를 `ON DELETE RESTRICT`로 참조하고 이 location인지 command가 검증한다.
- 배너 row의 locale creative, CTA, deeplink만 사용하고 `banner.start_at/end_at`은 이 RPC에서 무시한다. creative가 없거나 읽을 수 없으면 해당 surface를 숨기고 운영 alert를 만든다.

#### `purchase_reward_snapshots`

- 모든 검증 구매의 **기본 지급 기준**을 immutable하게 보존한다.
- 주요 필드:
  - `id uuid primary key`, `receipt_id UNIQUE`
  - `provider`, `environment`, `provider_transaction_id`, `purchase_key UNIQUE`
  - `user_id`, `product_id`, `quantity`, `channel`
  - `request_platform`, `request_app_version`, `request_app_build`, `rollout_cohort_version`
  - immutable `eligibility_input_snapshot`과 그 `eligibility_payload_hash`
  - `provider_original_quantity`, nullable `provider_paid_amount_minor`, nullable `provider_currency`
  - `refund_ratio_basis`, `refund_denominator`
  - nullable `initial_provider_occurred_at`, `verified_at`, `source_payload_hash`
  - `unit_star_amount`, `unit_bonus_amount`, `base_star_amount`, `base_bonus_amount`
  - 상품·채널 정책 version과 immutable `base_policy_snapshot`
- `purchase_key`는 provider/environment namespace를 포함하고 `(provider, environment, provider_transaction_id)`도 unique다.
- 모든 수량·금액은 `bigint` 정수다. `base_*_amount`는 단가가 아니라 `unit_* × quantity`가 끝난 총액이며 overflow와 음수를 check한다.
- 검증 시 provider별 환불 기준을 `QUANTITY` 또는 `AMOUNT`로 하나 고정한다. QUANTITY면 denominator는 `provider_original_quantity`, AMOUNT면 양수 `provider_paid_amount_minor`이고 ISO currency가 필수다.
- refund event composite FK를 위해 `UNIQUE(id, refund_ratio_basis, refund_denominator)`를 둔다.
- 캠페인 대상이 아닌 구매도 snapshot과 아래 resolution을 남긴다. 기본 지급 후 프로모션 보류가 가능하도록 프로모션 상태·award는 snapshot에서 분리한다.
- eligibility snapshot은 서버가 구매 요청에서 검증·정규화한 platform/channel/app version/build와 고정 user-ID cohort input만 allowlist해 저장한다. `PENDING_TIME`의 늦은 resolve도 이 값을 사용하고 현재 앱 version을 조회하지 않는다.

#### `wallet_financial_operations`

- Star/Bonus credit와 debit이 공유하는 전역 멱등 anchor다.
- 주요 필드: `id`, `user_id`, `operation_key UNIQUE`, `operation_kind IN ('CREDIT','DEBIT')`, `source_type`, `source_reference`, `payload_hash`, `created_at`.
- 모든 공통 credit/debit command가 child row보다 먼저 이 행을 만든다. 같은 key·같은 payload는 원 child 결과를 replay하고, direction/kind/source/user/amount를 포함한 payload가 다르면 `OP_IDEMPOTENCY_CONFLICT`로 거부한다.

#### `wallet_credit_operations` / `wallet_credit_allocations`

- 구매뿐 아니라 **모든 Star/Bonus 양수 writer**가 사용하는 공통 gross/debt-offset/net 경계다.
- operation 주요 필드: `id`, `financial_operation_id UNIQUE`, `created_at`.
- parent `operation_kind`는 `CREDIT`이어야 한다.
- allocation 주요 필드: `id`, `credit_operation_id`, `allocation_no`, `currency_type`, `reason`, `gross_amount`, `debt_offset_amount`, `net_wallet_credit_amount`, nullable `star_candy_history_id`, nullable `star_candy_bonus_history_id`, `created_at`.
- `UNIQUE(credit_operation_id, allocation_no)`, `UNIQUE(id, currency_type)`이며 `gross_amount = debt_offset_amount + net_wallet_credit_amount`, 모든 금액은 0 이상, gross는 0보다 큼을 강제한다.
- `net_wallet_credit_amount=0`이면 history FK는 모두 NULL이다. `net>0 AND STAR`면 Star history만, `net>0 AND BONUS`면 parent bucket 역할의 Bonus history만 존재하도록 conditional XOR check를 둔다.
- 출석·미션·선물·legacy Bonus 광고·관리자 조정을 포함한 비구매 credit도 이 allocation을 만들며, debt `RECOVER` event가 이를 FK로 참조한다.
- 이 공통 allocation은 기존 Star/Bonus history를 대체하지 않는 additive provenance wrapper다. 실제 net wallet 적립은 기존 history/bucket 행을 계속 만들고 그 ID를 연결한다.

#### `wallet_debit_operations` / `wallet_debit_allocations`

- 구매 환불이 아닌 Star/Bonus 관리자 차감과 오지급 correction의 append-only 경계다.
- operation 주요 필드: `id`, `financial_operation_id UNIQUE`, `created_at`. parent `source_type`은 `ADMIN_ADJUST_DEBIT` 또는 `CORRECTION`이다.
- parent `operation_kind`는 `DEBIT`이어야 한다.
- allocation 주요 필드: `id`, `debit_operation_id`, `allocation_no`, `currency_type`, `requested_amount`, `wallet_recovered_amount`, `debt_created_amount`, nullable `star_candy_history_id`, `created_at`이며 `requested = recovered + debt_created`를 강제한다.
- Bonus 차감은 `wallet_debit_bucket_allocations(debit_allocation_id, bonus_bucket_id, amount, child_history_id, allocation_no)`로 만료 임박 bucket별 소비와 child history를 보존한다.
- 각 `child_history_id`는 unique이고 해당 history의 `parent_id=bonus_bucket_id`, 절대 amount=allocation amount여야 한다.
- recovered=0이면 history/bucket reference가 없어야 한다. recovered>0인 Star는 Star history가 정확히 하나이고 그 절대 delta가 recovered와 같아야 한다. recovered>0인 Bonus는 Star history 없이 bucket allocation과 child-history 절대 delta 합이 각각 `wallet_recovered_amount`와 같아야 한다.
- 일반 `ADMIN_ADJUST_DEBIT`은 사용 가능한 같은 통화 잔액이 요청액보다 적으면 mutation 없이 거부하고 debt를 만들지 않는다. 검증된 오지급 `CORRECTION`만 Super Admin 2인 승인 아래 부족분을 `CORRECTION` debt로 남길 수 있다.
- `debt_created_amount > 0`이면 parent source는 반드시 `CORRECTION`이고 연결된 correction debt가 정확히 하나여야 한다. `ADMIN_ADJUST_DEBIT`의 debt_created는 항상 0이다.
- Cotton 수동 debit/correction은 V1에서 제공하지 않는다.

#### `purchase_reward_allocations`

- 구매 도메인 구성요소를 공통 credit allocation에 연결하는 immutable link다.
- 주요 필드: `id`, `snapshot_id`, `component`, `currency_type`, `wallet_credit_allocation_id UNIQUE`.
- `component IN ('BASE_STAR', 'BASE_BONUS', 'PROMO_BONUS')`, `UNIQUE(snapshot_id, component)`.
- `BASE_STAR → STAR_CANDY`, `BASE_BONUS|PROMO_BONUS → BONUS_STAR_CANDY`를 check로 강제하고, `(wallet_credit_allocation_id, currency_type)` composite FK로 공통 allocation의 통화와 일치시킨다.
- `BASE_*` link는 기본 구매 transaction에서, `PROMO_BONUS` link는 award transaction에서 한 번만 생성한다. 환불·CS는 link가 가리키는 원 gross allocation과 history/bucket provenance를 사용한다.

#### `purchase_promotion_resolutions`

- snapshot별 프로모션 판정 상태를 하나 보관한다. `snapshot_id UNIQUE`다.
- 주요 필드: `id`, `snapshot_id`, `status`, nullable `verified_provider_occurred_at`, nullable `campaign_version_id`, nullable `rollout_policy_snapshot`, nullable `award_inbox_id`, `eligibility_payload_hash`, `resolved_at`, `reason_code`, `row_version`.
- 상태는 `PENDING_TIME`, `ELIGIBLE`, `INELIGIBLE`, `GRANTED`, `REJECTED`, `CANCELLED_BY_REFUND`다.
- resolution의 eligibility hash는 snapshot의 immutable eligibility input hash와 같아야 한다.
- 신규 행은 공급자 시각이 확인되면 `INELIGIBLE` 또는 `ELIGIBLE`, 확인되지 않으면 `PENDING_TIME`으로 생성한다. Boost write가 켜진 eligible 경로는 같은 transaction 안에서 `ELIGIBLE` 생성 → award insert → `GRANTED` 전이를 완료하고, pause면 `ELIGIBLE`에 머문다.
- 허용 전이는 `PENDING_TIME → ELIGIBLE|INELIGIBLE|REJECTED|CANCELLED_BY_REFUND`, `ELIGIBLE → GRANTED|CANCELLED_BY_REFUND`뿐이다. `INELIGIBLE`, `GRANTED`, `REJECTED`, `CANCELLED_BY_REFUND`는 terminal이다.
- resolve와 refund는 모두 snapshot에서 immutable user ID를 먼저 조회한 뒤 `per-user advisory → user profile → snapshot → resolution` 순으로 같은 row를 lock한다. refund event가 하나라도 먼저 확정되면 `CANCELLED_BY_REFUND`로 고정하고 award insert trigger가 이를 거부한다.
- entitlement는 provider 발생 시각에 유효했던 campaign version과 그 version의 `rollout_policy`로 결정해 snapshot한다. 현재 feature flag는 settlement 실행을 일시 정지할 뿐 과거 entitlement를 바꾸지 않으며, 대상 event는 inbox에 보존한다.
- base purchase settlement와 promo award settlement의 완료 경계는 분리한다. Boost write가 pause면 base purchase inbox는 `SUCCEEDED`, resolution은 `ELIGIBLE`, 별도 `PROMOTION_AWARD` inbox는 `PENDING`으로 commit한다. write가 켜져 있으면 같은 금융 transaction에서 award까지 처리하고 둘 다 성공시킬 수 있다.
- 모든 상태 전이는 `purchase_promotion_resolution_events(resolution_id, from_status, to_status, operation_key, payload_hash, created_at)`에도 append-only로 기록하며 `operation_key`로 중복 전이를 막는다. resolution row는 이 이벤트의 현재 상태 projection이다.

#### `purchase_promotion_awards`

- 확정된 추가 Bonus를 immutable하게 보관한다.
- 주요 필드: `id`, `resolution_id UNIQUE`, `campaign_version_id`, `promo_bonus_amount`, `extra_bonus_bps`, `policy_snapshot`, `purchase_reward_allocation_id UNIQUE`, `awarded_at`.
- `promo_bonus_amount = floor((base_star_amount + base_bonus_amount) × extra_bonus_bps / 10000)`를 `bigint` 정수 산술로 계산한다.
- `purchase_reward_allocation_id`는 `purchase_reward_allocations(id)`를 참조한다. award, `PROMO_BONUS` purchase link + wallet credit allocation, Bonus history/bucket, debt 상계, resolution의 `GRANTED` 전이는 한 transaction이다. award insert 시 resolution이 `ELIGIBLE`이고 환불 event가 없음을 lock한 상태에서 다시 검증한다.

### 8.3 환불 부채

#### `purchase_refund_events`

- 공급자가 검증한 전체/부분 환불을 immutable하게 보존한다.
- 주요 필드: `id`, `snapshot_id`, `provider`, `environment`, `provider_refund_id`, `ratio_basis`, `cumulative_refunded_numerator`, `original_denominator`, `provider_refunded_at`, `payload_hash`, `created_at`.
- `UNIQUE(provider, environment, provider_refund_id)`이며 같은 key의 다른 payload는 충돌로 거부한다.
- `ratio_basis IN ('QUANTITY', 'AMOUNT')`, `0 < cumulative_refunded_numerator <= original_denominator`를 강제한다. `(snapshot_id, ratio_basis, original_denominator)` composite FK로 원 snapshot의 고정 기준과 일치시키고, snapshot을 lock한 상태에서 이전 누적값보다 작아질 수 없다.

#### `purchase_refund_allocations`

- 각 원 지급 구성요소의 누적 목표와 이번 역분개를 immutable하게 보존한다.
- 주요 필드: `id`, `refund_event_id`, `original_reward_allocation_id`, `component`, `currency_type`, `cumulative_target_amount`, `incremental_reversal_amount`, `wallet_recovered_amount`, `debt_created_amount`, `operation_key`.
- `UNIQUE(refund_event_id, component)`이며 `incremental_reversal_amount = wallet_recovered_amount + debt_created_amount`를 강제한다.
- BASE 구성은 문서 5.6의 정수 누적 공식을 사용하고, `PROMO_BONUS`는 첫 유효 환불에서 원 지급 전액을 목표로 한다. 같은 통화 안의 적용 순서는 `PROMO_BONUS → BASE_BONUS`로 고정해 replay와 CS 설명을 결정적으로 만든다.
- Bonus 회수는 원 지급 bucket의 남은 금액을 먼저 사용하고, 부족하면 다른 유효 Bonus bucket을 만료 임박 순으로 사용한다. 그래도 부족한 금액만 해당 component의 debt로 만든다.
- 환불 lock 순서는 `per-user advisory → user profile → snapshot → promotion resolution → 이전 refund event/allocation → 해당 Star/Bonus bucket → open debt`다.

#### `wallet_recovery_debts`

- `id`, `user_id`, nullable `receipt_id`, nullable `source_refund_allocation_id`, nullable `source_debit_allocation_id`
- `currency_type IN ('STAR_CANDY', 'BONUS_STAR_CANDY')`
- `reason IN ('PURCHASE_REFUND', 'CHARGEBACK', 'CORRECTION')`
- `owed_amount`, `recovered_amount`, `waived_amount`
- generated `outstanding_amount = owed_amount - recovered_amount - waived_amount`
- `owed_amount > 0`, recovered/waived는 0 이상, `recovered_amount + waived_amount <= owed_amount`를 check로 강제한다.
- refund/chargeback debt는 refund allocation만, correction debt는 debit allocation만 참조하도록 source XOR와 reason check를 둔다. 각 source FK에는 partial unique를 둬 allocation당 debt를 최대 하나로 제한한다.
- open debt index: `(user_id, currency_type, created_at, id) WHERE outstanding_amount > 0`

#### `wallet_recovery_debt_events`

- `CREATE`, `RECOVER`, `WAIVE` 이벤트를 append-only로 기록한다. `CREATE`는 원 refund 또는 correction debit allocation, `RECOVER`는 `wallet_credit_allocations`, `WAIVE`는 승인된 관리자 command를 FK로 참조한다.
- 주요 필드는 `debt_id`, `event_type`, `amount`, `operation_key`, `allocation_no`, source reference, `created_at`이며 `UNIQUE(operation_key, allocation_no)`로 멱등성을 보장한다.
- debt별 `CREATE`는 partial unique로 최대 한 번이며 정확히 한 번은 debt 생성 RPC와 reconciliation이 보장한다.
- debt row는 event 합계의 projection이다. event 합계와 불일치하면 금융 transaction을 rollback한다. alert는 rollback 후 wrapper/worker의 별도 durable failure transaction이 기록한다.
- debt event의 UPDATE/DELETE는 service role을 포함해 immutable trigger로 차단한다. debt projection row의 recovered/waived 갱신은 전용 command 내부의 제한된 helper만 수행하고 직접 DML은 차단한다.

### 8.4 처리·운영 지원

#### `wallet_operation_inbox`

- 구매, 환불, 공급자 callback의 내구성 있는 재처리 상태를 관리한다.
- 최소 operation type은 `PURCHASE_BASE`, `PROMOTION_RESOLUTION`, `PROMOTION_AWARD`, `PURCHASE_REFUND`, `AD_PROVIDER_CALLBACK`으로 나눠 base 성공과 보류 promo를 독립 표현한다.
- `operation_type + idempotency_key` unique, `payload_hash`, `PENDING/PROCESSING/SUCCEEDED/DEAD`, `attempt_count`, `next_retry_at`, `lease_until`, `locked_by`, `lease_token`, 마지막 오류 코드, immutable 결과 참조를 저장한다. operation type/idempotency key/payload hash/status/attempt count는 `NOT NULL`이다.
- 원본 민감 영수증은 저장하지 않거나 암호화하며 일반 로그에 남기지 않는다.
- 처리 경계는 세 transaction으로 고정한다.
  1. **A — 수신:** 외부 event를 `PENDING`으로 insert/upsert하고 durable commit한다. 같은 key의 다른 payload는 여기서 격리한다.
  2. **B — 정산:** worker가 짧은 claim transaction으로 새 UUID `lease_token`을 발급받고 attempt version을 증가시킨다. 별도 금융 transaction이 `status='PROCESSING' AND lease_token=?` CAS에 성공할 때만 snapshot/원장/지갑/debt와 inbox `SUCCEEDED + result_ref`를 원자 commit한다. crash 시 만료된 lease를 다른 worker가 새 token으로 인계한다.
  3. **C — 실패 기록:** B가 rollback되면 별도 transaction이 같은 lease token CAS에 성공할 때만 retryable 오류를 `PENDING + next_retry_at`, 영구 오류를 `DEAD`와 alert로 기록한다. stale worker는 새 owner나 이미 `SUCCEEDED`인 행을 덮어쓸 수 없다.
- A가 성공한 뒤 B가 실패해도 재처리 근거가 사라지지 않으며, wallet 변경은 B의 금융 transaction 밖에서 일어나지 않는다.

#### `wallet_repair_operations`

- provider inbox와 분리한 관리자 dry-run/retry/repair 실행 이력이다.
- command 종류, 대상 resource, 요청자·역할·CS ticket, dry-run 결과 hash, 승인자, 상태, 결과 reference, 오류와 audit ID를 저장한다.
- 실패 settlement 재실행은 원 inbox key를 그대로 사용한다. 이미 잘못 commit된 결과는 새 correction key의 append-only 보정으로 처리하고, projection rebuild는 권위 원장에서 계산하는 전용 RPC만 사용한다.

#### `ops_alerts`

- fingerprint로 같은 문제를 deduplicate한다.
- `CRITICAL/WARNING`, `OPEN/ACKNOWLEDGED/RESOLVED`, 영향 resource, 최초/최근 시각, 발생 횟수를 저장한다.
- 운영자는 ACK만 할 수 있다. 불변식이 정상화되면 시스템이 자동 resolve한다.
- alert ACK도 아래 immutable audit에 기록한다.

#### `wallet_audit_events`

- 기존 범용 `audit_logs`의 text schema·retention 동작을 바꾸지 않고, 금융/캠페인 명령 전용 immutable 계약을 additive하게 만든다. admin safe view가 필요하면 두 source를 구분해 합친다.
- 필수 필드: `id`, `actor_user_id`, `actor_role`, `action_code`, `resource_type`, `resource_id`, `operation_id`, `request_id`, `reason`, nullable `cs_ticket`, `before_json`, `after_json`, nullable `campaign_version_id`, `created_at`.
- 금융 command, campaign/feature flag 변경, 관리자 조정·waiver·repair, alert ACK를 기록한다.
- 대상 mutation과 같은 transaction에서 insert하며 audit insert 실패 시 mutation도 rollback한다.
- 일반 관리자에게 허용된 safe read RPC 외 SELECT를 제한하고 INSERT는 command helper만 허용한다. UPDATE/DELETE는 service role도 immutable trigger로 차단한다.

#### 기존 테이블

- `receipts`, Star/Bonus history, `banner`를 참조로 연결한다.
- 필요한 사유 enum은 `CANDY_BOOST`, `REFUND_REVERSAL`, `DEBT_RECOVERY`, `ADMIN_ADJUST`, `CORRECTION` 등으로 확장한다.
- enum 추가 migration과 새 enum 사용 migration을 분리한다.
- 기존 Bonus projection의 `sync_or_enqueue_bonus()` 오류 삼키기 동작은 신규 구매·환불·debt 경계를 열기 전에 제거한다. strict projection trigger가 Bonus history insert와 같은 transaction에서 profile을 갱신하고 오류 시 전체 transaction을 rollback한다. 금융 RPC는 profile Bonus를 별도로 직접 갱신하지 않는다.
- strict 전환 전 운영 데이터를 정리하고 `user_profiles.star_candy_bonus >= 0`, 모든 Bonus row의 `remain_amount >= 0`, parent bucket의 `remain_amount <= amount`를 `NOT VALID → 검증 → VALIDATE` 순서로 강제한다.
- `star_candy_bonus_history` parent bucket은 권위 잔량이므로 전용 helper가 `remain_amount/updated_at/deleted_at`만 변경할 수 있다. 소비 child history는 append-only다. Cotton ledger·debt event·credit/refund allocation은 완전 immutable하다.
- 기존 Star/Bonus 직접 writer는 공통 debt-aware credit helper로 순차 이전한다. queue는 transaction 성공을 가장하는 수단이 아니라 drift 탐지·재구축 보조로만 사용한다.
- 신규 금융 테이블과 campaign version은 server-only DML이다. campaign 변경은 admin command RPC만, 앱·관리자 조회는 safe RPC/view만 허용한다.

## 9. 명령과 읽기 계약

### 9.1 원자적 명령

- `grant_ad_cotton(...)`: 서비스 역할 전용. 아래 자연키, grant, ledger, projection, claim/source 거래를 한 번에 처리한다.
- `perform_vote_transaction_v3(...)`: 일반 투표 검증, 사용자 lock, overdue 제외, 세 재화 배분, `vote_pick`, 원장, 집계를 한 번에 처리한다.
- `grant_verified_purchase(...)`: 공급자 검증 결과, 상품 서버값, base snapshot/allocation, 확정 가능한 promotion resolution/award, 기존 debt 상계를 한 번에 처리한다.
- `resolve_purchase_promotion(...)`: 보류 resolution을 provider 시각으로 판정하고, 환불이 없을 때만 award를 지급한다.
- `refund_verified_purchase(...)`: 원 snapshot/allocation, promotion resolution, 누적 환불 event/allocation, 즉시 회수, 신규 debt를 한 번에 처리한다.
- `expire_cotton_candy_batch(limit)`: 만료 bucket과 ledger, projection을 batch transaction으로 처리한다.
- `admin_create_promotion_version(...)`: expected version, 변경 사유, 새 version, audit를 한 번에 기록한다.
- `admin_adjust_star_bonus(direction, currency, amount, reason, cs_ticket, ...)`: CREDIT은 공통 credit, DEBIT은 잔액 충분 조건의 공통 debit을 실행한다.
- `apply_wallet_correction(...)`: 검증된 오지급만 새 correction key와 2인 승인으로 역분개하고 부족분은 correction debt로 남긴다.
- repair 명령은 세 종류로 분리한다. 실패한 inbox settlement는 같은 key로 replay하고, commit된 오결과는 새 correction key로 보정하며, projection은 목표 잔액을 받지 않고 권위 원장에서 재계산한다.

`grant_ad_cotton`의 논리 계약은 다음과 같다.

```text
grant_ad_cotton(
  operation_key,
  source_provider,
  source_environment,
  source_event_type,
  source_transaction_id,
  user_id,
  amount,
  claim_id?,
  impression_id?,
  reward_policy_version,
  payload_hash,
  metadata?
) -> {
  ok,
  status: GRANTED | ALREADY_GRANTED,
  operation_id,
  grant: { id, currency, amount, granted_at, expires_at },
  wallet: {
    star,
    bonus,
    cotton,
    cotton_expiring_amount,
    cotton_next_expires_at,
    snapshot_at
  }
}
```

- channel wrapper가 서명·사용자·보상 정책을 검증하고 서버 정책으로 amount를 계산한 뒤 호출한다. 앱 입력 amount나 임의 metadata는 전달하지 않는다.
- 동일 operation/source 자연키와 동일 payload는 immutable grant 결과를 반환한다. `wallet`은 재조회 시점의 현재 summary라 달라질 수 있다.
- 신규 응답의 Cotton 잔액·만료 예정량·다음 만료 시각은 grant와 같은 fixed DB snapshot에서 계산한다.
- 같은 key의 user/amount/source/payload mismatch는 `OP_IDEMPOTENCY_CONFLICT`다.

모든 `SECURITY DEFINER` 함수는 빈 `search_path`, 완전 수식 객체명, 최소 EXECUTE grant를 사용한다. `PUBLIC`, `anon`, `authenticated` 권한을 기본 회수한다.

모든 사용자 wallet mutation은 같은 per-user advisory key와 `advisory → user profile → domain row → currency bucket/debt` lock 순서를 사용한다. 여러 사용자를 다루는 운영 batch는 user ID 오름차순으로 처리한다.

### 9.2 앱 읽기

- `get_wallet_summary()`
  - Star, Bonus, Cotton 잔액
  - Cotton 만료 예정량과 다음 만료 시각
  - DB `snapshot_at`
- `get_active_promotion_campaigns(surface)`
  - 현재 surface에 유효한 표시명, 배율, window, creative/CTA
- `get_currency_history(currency, cursor, limit)`
  - 공개 가능한 사유, delta, origin, grant/purchase/refund reference, expiry
- `get_ad_reward_status(reference_type, reference_id)`
  - `PANGLE_CLAIM` 또는 `INTERNAL_IMPRESSION`의 상태, 최초 grant, 현재 wallet summary
- `list_unacknowledged_ad_rewards(cursor, limit)` / `acknowledge_ad_reward(reference_type, reference_id)`
  - 앱 종료 후 복구할 확정·대기 보상과 사용자 확인 상태
- 기존 응답 필드는 유지하고 v2 필드를 additive하게 추가한다.

앱용 promotion RPC는 전달받은 시각을 사용하지 않고 DB 현재 시각만 사용한다. 테스트 가능한 private evaluator와 관리자 preview RPC만 명시적 `at`을 받는다.

광고 상태 RPC는 인증된 사용자의 소유권을 DB에서 검증한다. 내부 숏폼 token이 만료돼도 `impression_id`의 기존 상태 조회는 허용하지만 어떤 지급 mutation도 허용하지 않는다. 앱은 미확정 reference를 로컬 durable storage에도 저장하고 terminal 상태를 확인·acknowledge할 때까지 재개 시 조회한다.

팝업 전달 보장은 exactly-once가 아니라 **at-least-once until acknowledged**다. 앱은 terminal `GRANTED` 팝업이 실제로 첫 frame에 렌더링된 뒤 acknowledge하고, ack된 reference는 다시 표시하지 않는다. 렌더링과 ack 사이의 프로세스 종료에서는 재표시될 수 있지만 확정 보상이 영구히 누락되지는 않는다. 정상 실행 중에는 reference별 in-memory/local dedupe로 한 번만 표시한다.

내부 숏폼 응답의 기존 `ok`, `reward_added`, `impression_id`, `new_bonus` 필드는 제거하지 않는다. Bonus mode에서는 기존 의미를 유지한다. Cotton mode에서는 wallet-aware 앱이 nested v2 `reward`를 사용하며 legacy `reward_added=0`, `new_bonus=null`로 두어 구버전 앱이 Cotton을 Bonus로 오표시하지 않게 한다. Cotton mode는 최소 지원 앱 version 강제 이후에만 활성화한다.

### 9.3 관리자 읽기

- `admin_get_user_cs_summary(user_id uuid)`
- `admin_list_user_currency_history(user_id uuid, currency wallet_currency, filters jsonb, cursor text?, limit int=20)`
- `admin_list_user_money_timeline(user_id uuid, filters jsonb, cursor text?, limit int=20)`
- `admin_list_promotion_campaigns(filters jsonb, cursor text?, limit int=20)`
- `admin_preview_promotion_campaign(campaign_id uuid, at timestamptz)`
- `admin_list_wallet_operations(filters jsonb, cursor text?, limit int=20)`
- `admin_list_ops_alerts(filters jsonb, cursor text?, limit int=20)`
- `admin_get_wallet_ops_summary(at timestamptz?)`
- `admin_list_wallet_invariant_violations(filters jsonb, cursor text?, limit int=20)`
- `admin_get_worker_health()`

CS summary는 세 잔액, Star/Bonus open debt, Cotton 만료 예정, 권위 합계와 drift, 최근 operation을 반환한다. currency history는 event/origin/delta/expiry와 원 구매·환불·grant 참조를, money timeline은 gross/wallet/debt delta, provider 시각, campaign version, operation/audit ID를 반환한다. Wallet Ops는 inbox/DLQ 지연, expiry·reconciliation heartbeat, debt aging/회수율, campaign 충돌, audit completeness를 포함한다.

목록 응답은 행 배열이 아니라 아래 고정 envelope다. 결과가 0건이어도 `total_count=0`을 반환한다.

```text
CursorPage<T> = {
  items: T[],
  total_count: bigint,
  next_cursor: text | null,
  snapshot_at: timestamptz
}
```

- cursor는 서버가 서명한 `{snapshot_at, created_at, id}` opaque token이며 client가 내부 값을 만들지 않는다. `(created_at DESC, id DESC)`로 고정하고 모든 page가 첫 page의 `snapshot_at` 이하 snapshot을 읽는다.
- `limit`은 1..100, 기본 20이다. offset pagination은 사용하지 않는다.
- filters의 허용 key는 RPC별로 `from`, `to`, `currency`, `event_types[]`, `statuses[]`, `provider`, `severity`, `campaign_id` 중 필요한 subset을 고정하고 unknown key·잘못된 enum·역전 시간범위를 거부한다.
- 공통 enum은 `wallet_currency=STAR_CANDY|BONUS_STAR_CANDY|COTTON_CANDY`, `operation_status=PENDING|PROCESSING|SUCCEEDED|DEAD`, `invariant_status=OK|DRIFT|UNKNOWN`, `alert_status=OPEN|ACKNOWLEDGED|RESOLVED`다.
- history item은 `id text`, `currency`, `event_type text`, `origin text`, `delta bigint`, `balance_effect bigint`, nullable `expires_at/purchase_id/refund_id/grant_id`, `operation_id uuid`, `created_at timestamptz`를 반환한다.
- timeline item은 operation 단위 `id text`, `kind text`, `allocations[]`, nullable `provider_occurred_at/campaign_version_id/audit_id`, `operation_id uuid`, `created_at timestamptz`를 반환한다. 각 allocation은 `component text`, `currency wallet_currency`, `gross_delta bigint`, `wallet_delta bigint`, `debt_delta bigint`를 가져 Star와 Bonus를 절대 합산하지 않는다.
- CS summary는 `balances`의 세 bigint, currency별 open debt bigint, Cotton expiring bigint와 nullable next expiry, `invariant_status`, 최근 operation item을 반환한다. Ops/alert/campaign DTO도 위 stable enum과 nullable 표기를 사용하고 SQL composite type에서 생성된 TypeScript 타입으로 admin build가 검증한다.
- raw 금융 테이블 SELECT를 UI에 허용하지 않는다.

### 9.4 관리자 명령과 RBAC

| 역할 | 허용 명령 | 필수 통제 |
|---|---|---|
| Operator | 조회, alert ACK, 자동 재시도 가능 상태의 동일-key retry **enqueue 요청**, dry-run | 사유와 operation ID; 금융 command 직접 EXECUTE 불가 |
| Finance Admin | Star/Bonus `ADMIN_ADJUST(CREDIT|DEBIT)`, debt waiver | CS ticket, 사유, 역할별 서버 금액 한도; 한도 초과는 별도 Super Admin 승인 필요 |
| Super Admin | campaign/feature flag 새 version, emergency disable, 승인된 correction/projection rebuild | dry-run hash, optimistic version, 별도 사유·ticket; 요청자와 승인자가 달라야 하는 2인 승인 구간 적용 |

- Cotton 수동 적립·차감은 V1에서 어떤 역할에도 제공하지 않는다.
- Operator retry는 inbox의 실행 가능 시각만 앞당기는 요청이다. 실제 settlement는 service worker가 기존 policy·idempotency·lease 검증 후 실행하며 audit에는 Operator를 requester, service worker를 executor로 각각 남긴다. `DEAD`, non-retryable, correction/waiver가 필요한 건은 Operator가 재실행할 수 없다.
- `ADMIN_ADJUST(CREDIT)`는 공통 credit allocation을 사용해 기존 debt를 먼저 상계한다. `ADMIN_ADJUST(DEBIT)`은 Star 잔액 또는 Bonus 만료 임박 bucket을 차감하며 부족하면 `ADMIN_ADJUST_INSUFFICIENT_FUNDS`로 전체 거부한다.
- `ADMIN_ADJUST`는 시스템 사유를 선택하지 못하며 append-only operation/allocation/history를 만든다. debt waiver도 row 삭제가 아니라 `WAIVE` event다.
- commit된 오지급의 음수 `CORRECTION`은 일반 admin debit과 다른 Super Admin 2인 승인 command다. 부족분 debt가 필요하면 `CORRECTION` reason으로만 생성한다.
- retry, reconcile, projection rebuild, emergency disable은 서로 다른 command/action code와 권한을 사용한다.
- 역할별 금액 한도와 2인 승인 기준은 서버 설정으로 version 관리하며 UI 입력값만 신뢰하지 않는다.

### 9.5 안정 오류 envelope

```json
{
  "ok": false,
  "domain_code": "VOTE_INSUFFICIENT_FUNDS",
  "retryable": false,
  "operation_id": "...",
  "support_ref": "..."
}
```

- SQL 메시지 문자열을 파싱하지 않는다.
- DB domain code와 PostgreSQL concurrency SQLSTATE를 Edge에서 안정 코드로 매핑한다.
- metrics label에 user ID, provider transaction ID, impression ID 같은 고카디널리티·개인 식별값을 넣지 않는다.

## 10. 트랜잭션 흐름

### 10.1 내부 숏폼

1. 서버가 `ad_impressions.id`, HMAC token, TTL을 발급한다.
2. callback이 JWT, token, 사용자, impression, 시청 조건, 캠페인 보상량을 검증한다.
3. wrapper RPC가 `ad_reward_events`, impression 지급 상태, Cotton grant/ledger/projection을 같은 transaction으로 처리한다.
4. 신규면 `GRANTED`, 재호출이면 `ALREADY_GRANTED`와 최초 grant를 반환한다.
5. 앱은 callback 전에 `impression_id`를 pending reference로 저장하고 서버의 지급량·만료 시각만 표시한다. 응답 유실 시 인증된 status RPC로 같은 impression을 조회한다.
6. token 만료 뒤 mutation이나 새 impression을 발급해 광고 없이 claim하는 기존 경로는 제거한다. 만료 뒤에도 소유권이 확인된 기존 impression의 상태 조회만 허용한다.
7. Cotton canary 대상은 wallet-aware 최소 앱 version과 서버 cohort의 교집합으로 제한한다. 그 밖의 사용자는 기존 Bonus mode를 유지한다.

### 10.2 Pangle

1. 앱이 광고 load 전에 인증 endpoint로 claim intent를 만든다.
2. `media_extra`는 전환 중 기존 parser와 공존하도록 `<userId>,<platform>,v2.<signed-opaque-token>` 형식을 사용한다.
3. v2 token이 있으면 앞의 raw CSV `userId/platform`은 파싱 호환용일 뿐 권위 값으로 사용하지 않는다. signed token이 가리키는 claim row의 user/platform/placement/environment만 사용한다.
4. Pangle SSV가 provider `sign`, environment, `trans_id`, signed token, claim 소유권을 검증한다. 인증·소유권 검증 직후 기존 `(environment, trans_id)` grant를 현재 일일 한도·정책보다 먼저 조회한다.
5. 기존 grant면 최초 canonical 결과를 반환한다. 신규면 claim이 아직 `PENDING`이고 TTL 안인지 검증한 뒤 `trans_id`를 bind하고 `grant_ad_cotton`을 실행한다.
6. TTL 이후 첫 SSV는 `EXPIRED`로 종료하고 지급하지 않는다. 단, TTL 전에 이미 `GRANTED`된 callback의 늦은 replay는 만료와 무관하게 최초 결과를 반환한다. terminal claim은 다른 상태로 바뀌지 않는다.
7. native reward callback의 `isValid=true`와 dismiss 이벤트는 **polling 시작 신호**일 뿐 지급 성공이 아니다. `isValid=false`도 앱에서 임의 지급하지 않으며 서버 terminal 상태를 조회한다.
8. 앱은 서버 `GRANTED`일 때만 성공 팝업을 표시한다. `PENDING`은 `확인 중`, `DENIED/EXPIRED/ABANDONED`는 미지급 안내로 끝내고 reference를 acknowledge한다.
9. 정상 중복 callback은 HTTP 200과 duplicate 결과를, transient 처리 실패는 provider 재시도가 가능한 5xx를, 서명·payload 위조는 4xx를 반환한다.

### 10.3 일반 투표

1. DB clock을 한 번 고정하고 caller, vote, amount, request ID를 검증한다.
2. 사용자 advisory/row lock을 잡고 같은 request replay를 확인한다.
3. 고정 lock 순서 `per-user advisory → user profile → overdue Cotton → active Cotton → Bonus`를 사용한다. 사용자 transaction은 lock을 기다리고 batch expiry만 사용자 단위 `try advisory + SKIP LOCKED`를 사용한다.
4. overdue Cotton의 `remain=0`과 `EXPIRE` ledger를 투표 transaction 안에서 materialize하되 사용 대상에서는 fixed DB time으로 즉시 제외한다.
5. 유효 Cotton과 Bonus bucket을 만료 임박 순으로 lock하고 Cotton, Bonus, Star 순으로 사용량을 계산한다.
6. 잔액 부족 또는 뒤 단계 실패면 expiry materialization까지 transaction 전체를 rollback한다. 그래도 timestamp 조건상 만료분은 사용할 수 없고 이후 batch가 처리한다.
7. `vote_pick`, payload hash, 세 통화 원장·버킷·projection·투표 집계를 한 번에 commit한다.

### 10.4 구매와 환불

1. 공급자 event를 8.4의 transaction A로 inbox에 먼저 durable commit한다.
2. worker는 lease를 얻고 provider transaction·환경·발생 시각을 검증한다. 상품 단가에 quantity를 적용한 base 총액을 DB에서 계산한다.
   - 기존 PayPal/PortOne RPC signature는 호환용 durable intake로만 남긴다. pending receipt/inbox를 반환한 뒤 Supabase worker가 provider API를 다시 조회하며, 검증 완료 전에는 금융 지급을 하지 않는다.
3. provider 시각을 확인했으면 그 시각의 campaign version과 rollout policy로 entitlement를 결정한다. 시각만 불명확하면 base snapshot/allocation과 `PENDING_TIME` resolution을 만든다.
4. Star/Bonus gross credit는 각 통화의 오래된 open debt를 먼저 상계하고 allocation에 gross/debt-offset/net을 모두 남긴다.
5. base 정상 경로는 receipt, base snapshot/allocation, history/bucket, profile projection, debt event와 purchase inbox success를 한 transaction으로 commit한다. Boost write가 켜져 있으면 확정 가능한 resolution/award도 같은 transaction에 포함한다.
6. Boost write가 pause거나 provider 시각이 보류면 base는 지연시키지 않는다. eligible award는 별도 `PROMOTION_AWARD` inbox에 남기고, 보류 resolve는 공통 사용자 lock 뒤 `snapshot → resolution`을 lock해 provider 시각·원 effective policy를 검증한다. 현재 runtime flag가 pause면 entitlement를 바꾸지 않고 promo inbox만 대기시킨다.
7. 환불도 먼저 inbox에 보존한 뒤 같은 lock 순서로 snapshot/resolution을 잡는다. base snapshot이 아직 없으면 mutation 없이 retry 대기한다. 보류 award보다 환불이 먼저면 `CANCELLED_BY_REFUND`; award가 먼저면 그 promo allocation까지 역분개 대상이다.
8. provider refund ID와 payload, 누적 비율을 검증하고 component별 누적 목표에서 이전 allocation 합을 뺀다. 회수 가능한 같은 통화를 차감하고 부족분은 새 refund debt로 만든다.
9. 원 구매가 과거 debt를 상계했어도 그 debt를 reopen하지 않는다. 원 gross 전액을 기준으로 현재 wallet 회수 + 신규 refund debt를 기록한다.
10. 이후 모든 같은 통화 credit는 공통 credit helper에서 오래된 open debt를 먼저 상계한다.

## 11. 오류 처리와 복구

### 사용자 상태

| 상태 | 대표 코드 | 앱 동작 |
|---|---|---|
| 완료 | `GRANTED`, `OP_REPLAYED`, `REFUND_APPLIED_WITH_DEBT` | 최초 확정 결과를 표시한다. 중복을 추가 지급으로 표현하지 않는다. |
| 확인 중 | `AD_REWARD_PENDING`, `PURCHASE_VERIFY_UNAVAILABLE`, `TX_CONFLICT_RETRYABLE` | 같은 operation/claim을 backoff 조회한다. 앱 재실행 후 이어서 확인한다. |
| 사용자 조치 | `VOTE_INSUFFICIENT_FUNDS`, `VOTE_INVALID_STATE`, `CLAIM_EXPIRED` | 잔액 새로고침, 새 투표, 새 광고 등 새 행동을 안내한다. |
| 운영 검토 | `OP_IDEMPOTENCY_CONFLICT`, `PURCHASE_POLICY_INVALID`, `WALLET_INVARIANT_VIOLATION` | support reference를 표시하고 자동 재처리하지 않는다. |

- 광고 `PENDING`은 backoff polling 대상, `GRANTED`는 성공, `DENIED/EXPIRED/ABANDONED`는 미지급 terminal이다. 모든 terminal 상태는 불변이다.
- transient DB conflict만 같은 idempotency key로 jitter backoff 최대 3회 재시도한다.
- 재시도 소진 또는 불변식 위반은 `DEAD`와 영속 alert로 격리한다.
- commit 여부가 불명확할 때 새 key로 다시 지급하지 않고 기존 key의 상태를 먼저 조회한다.
- 광고 지표는 channel/environment별 `claim_created`, `grant`, `duplicate`, `pending_age`, `denied`, `expired`, `recovered_after_resume`를 집계한다. 고카디널리티 ID는 label이 아니라 support reference로만 보관한다.
- rollback되는 PostgreSQL transaction 안에서 alert를 insert하지 않는다. inbox 명령은 transaction C가, vote/admin 같은 동기 명령은 인증된 Edge/admin wrapper가 rollback을 확인한 뒤 service-only `record_wallet_command_failure`를 별도 transaction으로 호출한다. recorder request는 정확히 `{actor_user_id,request_id,action_code,failure_stage,domain_code,retryable}`이며 `failure_stage`는 `TRANSPORT|RESPONSE_DECODE`만 허용한다. mutation RPC는 client가 직접 EXECUTE하지 않는다. 이 failure 기록까지 실패하면 외부 오류 metric이 on-call을 호출한다.

### 운영 복구 순서

1. 영향 사용자, 거래, 금액, 원본 event, snapshot, ledger, debt timeline을 표시한다.
2. 허용된 repair RPC를 dry-run한다.
3. 예상 row, wallet delta, debt delta의 before/after를 표시한다.
4. 운영자 사유와 CS ticket, 권한, optimistic version을 검증한다.
5. 실패 settlement는 원 key로 replay한다. commit된 오결과는 새 correction key, projection drift는 전용 rebuild operation key로 실행하고 audit를 같은 transaction에 기록한다.
6. 같은 불변식을 재검사하고 정상화됐을 때만 alert를 자동 resolve한다.

### 금지 작업

- `user_profiles`의 Star, Bonus, Cotton 직접 입력·수정
- Cotton ledger, Bonus 소비 child history, debt/credit/refund event·allocation의 update/delete 또는 금액·시각·참조 변경. 단, Cotton grant와 Bonus parent bucket의 잔량 필드는 전용 helper만 변경할 수 있다.
- 운영자가 목표 잔액을 지정하는 projection repair
- 현재 캠페인으로 과거 환불 재계산
- 시스템 지급 사유를 관리자 수동조정 type으로 선택
- 부채 row 직접 삭제
- 정합성 복구 없이 alert 강제 resolve
- audit 없이 금융 mutation commit

## 12. 보안과 무결성

- 앱·관리자는 Cotton grant/ledger와 purchase/refund/debt/inbox의 raw table SELECT를 하지 않는다. 공개 가능한 컬럼만 safe RPC/view로 제공한다.
- 모든 신규 금융 테이블에 RLS를 enable하고 default-deny policy를 사용한다. `REVOKE ALL ON TABLE ... FROM PUBLIC, anon, authenticated` 후 앱/관리자별 safe RPC의 `EXECUTE`만 명시적으로 다시 부여한다. service role도 raw mutation 대신 command 함수만 사용한다.
- 신규 금융 테이블은 별도 `NOLOGIN wallet_command_owner`가 소유한다. service role에도 해당 신규 table의 raw 권한을 `REVOKE ALL`하고, 이 owner가 소유한 검증된 `SECURITY DEFINER` command/read RPC의 EXECUTE만 부여한다. migration/복구 break-glass 역할은 별도이며 사용 시 감사와 2인 승인이 필요하다.
- admin도 직접 Cotton/profile balance를 수정할 수 없다.
- 외부 provider key의 unique 범위에 사용자 ID를 포함하지 않는다.
- provider payload, receipt, token, signature를 일반 로그에 기록하지 않는다.
- 원장·snapshot·debt FK에 `ON DELETE CASCADE`를 쓰지 않는다.
- 신규 `ON DELETE RESTRICT` FK를 배포하기 전에 기존 계정 탈퇴/삭제 RPC를 금융 식별자 보존 + 개인정보 익명화 흐름으로 이전하고 migration test를 통과시킨다.
- `SELECT 후 INSERT` 중복검사 대신 unique constraint를 충돌 지점으로 사용한다.
- `GREATEST(balance - amount, 0)`로 부족액을 숨기지 않는다. 조건부 update의 영향 행 수를 검증한다.
- ledger, wallet financial/credit/debit operation/allocation, purchase snapshot/allocation, promotion resolution event/award, campaign version, refund event/allocation, debt event, `wallet_audit_events`의 UPDATE/DELETE는 service role도 immutable trigger로 차단한다.

## 13. Reconciliation 불변식

- `user_profiles.cotton_candy = 만료 materialization 전후를 포함한 모든 grant remain_amount 합계`
- 앱/관리자 spendable Cotton = `fixed_now` 기준 `expires_at > fixed_now`인 grant remain 합계
- `original_amount = remain_amount + |CONSUME 합| + |EXPIRE 합|`
- grant별 GRANT는 정확히 하나, EXPIRE는 최대 하나
- `vote_pick.amount = Cotton + Bonus + Star usage`
- vote별 usage와 통화별 원장 delta 합계 일치
- 모든 balance와 grant remain은 0 이상
- completed purchase와 base snapshot은 1:1이고 snapshot의 BASE allocation은 각 지급 구성과 일치
- 모든 Star/Bonus 양수 credit에서 `gross = debt_offset + net_wallet_credit`이고 debt RECOVER 합은 해당 credit allocation의 debt_offset과 일치
- 모든 admin/correction debit에서 `requested = wallet_recovered + debt_created`; 일반 ADMIN_ADJUST debt는 0이고 CORRECTION debt만 source debit allocation과 1:1
- `GRANTED` promotion resolution, award, PROMO_BONUS allocation은 1:1이며 환불 선도착 resolution에는 award 0개
- refund event의 각 incremental reversal 합 = wallet recovered + 신규 debt, 누적 역분개는 원 allocation을 초과하지 않음
- `owed = recovered + waived + outstanding`
- debt recovery event 합계와 `recovered_amount` 일치
- 동일 idempotency key의 immutable operation result와 result reference는 항상 동일. 응답에 함께 붙는 현재 wallet summary는 조회 시점에 따라 달라질 수 있음
- 관리자 금융 mutation과 audit completeness 100%

## 14. 테스트 전략

### DB/RPC

- 실제 로컬 PostgreSQL/Supabase에서 schema, constraint, RLS, RPC를 검증한다.
- 월요일 00:00, 수요일 00:00, Cotton `expires_at` 직전/정각/직후 경계를 테스트한다.
- Cotton-only, Bonus-only, Star-only, 혼합, 정확한 전액, 1 부족 투표를 테스트한다.
- 동일 사용자의 동시 투표, vote와 expiry, refund와 credit 경쟁을 복수 DB connection으로 반복한다.
- vote와 Cotton/Bonus expiry batch가 전역 user-first lock 순서에서 deadlock 없이 완료되는지 검증한다.
- lazy expiry가 포함된 실패 vote에서 materialization은 rollback되지만 만료분은 사용할 수 없는지 검증한다.
- grant, ledger, projection, vote_pick, promotion award, debt event 직후 failure를 주입해 부분 commit 0을 검증한다.
- inbox 수신 commit 뒤 worker crash, lease 만료 인계, settlement rollback, 실패 상태 기록과 동일 key replay를 검증한다.
- lease 인계 뒤 stale worker의 B/C가 fencing token CAS에 실패하고 새 owner의 성공 상태를 덮어쓰지 못하는지 검증한다.
- strict Bonus projection trigger 실패와 audit insert 실패가 원 금융 mutation까지 rollback하는지 검증한다.
- 전액 debt 상계 credit는 net=0이고 history/bucket FK가 모두 NULL이며 부분·무상계 credit만 올바른 통화 FK를 만드는지 검증한다.
- failure injection은 운영 flag가 아니라 테스트 transaction의 임시 trigger를 사용한다.
- anon/authenticated/admin/service role별 raw SELECT/DML/EXECUTE와 immutable UPDATE/DELETE 차단을 검증한다.
- legacy 일반 투표 RPC/endpoint 직접 호출이 거부되고 일반 투표가 모두 v3 우선 차감으로 수렴하는지 검증한다.
- 기존 계정 탈퇴/익명화가 신규 `ON DELETE RESTRICT` FK 이후에도 감사 provenance를 보존하며 완료되는지 검증한다.

### Contract/App/Native

- 기존 내부 숏폼 top-level 응답 fixture와 v2 nested 응답을 모두 파싱한다.
- Pangle v1/v2 `media_extra`, 신규/중복 200, transient 5xx, invalid signature 4xx를 검증한다.
- v2 raw CSV user/platform 변조가 signed claim 소유권을 바꾸지 못하는지 검증한다.
- Pangle SSV 선도착, native 선도착, 미도착, TTL 직전/직후, terminal replay, 앱 종료·재개를 검증한다.
- 내부 callback 응답 유실과 token 만료 후 authenticated impression status 조회가 추가 지급 없이 복구되는지 검증한다.
- 앱 로컬 pending reference, server unacknowledged list, acknowledge가 정상 세션에서 성공 popup을 한 번만 만들고, 렌더링/ack 사이 강제 종료에서는 누락 없이 at-least-once로 복구하는지 검증한다.
- 3분할 wallet, 만료 카피, 아이콘, 홈/스토어 surface를 Flutter golden/위젯 테스트와 실기기로 확인한다.

### 구매/Admin

- 채널별 기본 Bonus와 프로모션 계산, campaign 경계와 version 경쟁을 테스트한다.
- 최신 inactive version이 과거 active로 fallback하지 않는지, backdate/미래 version/동일 effective time이 거부되는지 테스트한다.
- client 시각·Edge 처리 시각과 provider 시각이 서로 다른 구매가 provider 시각으로만 판정되는지 테스트한다.
- `PENDING_TIME` resolve와 refund 경쟁에서 단 하나의 terminal 결과만 남는지 테스트한다.
- 동일 부분 환불을 `refund → resolve`와 `award → refund` 순서로 각각 실행해 promo 전액 회수와 base 비례 회수가 동일한 최종값을 만드는지 테스트한다.
- Boost write pause 중 base purchase는 성공하고 `PROMOTION_AWARD` inbox만 pending이며 재개 후 원 entitlement로 한 번 지급되는지 테스트한다.
- canary 중 발생하고 전역 활성화 뒤 늦게 검증된 구매가 당시 rollout policy snapshot대로 판정되는지 테스트한다.
- 전체/부분 환불, 즉시 회수, 부분 debt, 전액 debt, future credit 상계를 테스트한다.
- 기존 debt를 상계해 net 0이었던 구매의 환불이 과거 debt를 reopen하지 않고 gross 기준 신규 refund debt를 만드는지 테스트한다.
- 다른 통화 상계 금지와 모든 credit source의 공통 debt 경계 사용을 테스트한다.
- 캠페인 version 수정 후에도 구매·환불·CS timeline이 원 version을 표시하는지 검증한다.
- home/store surface flag, `banner.start_at/end_at` 무시, creative 누락 시 hide + alert를 테스트한다.
- alert dedup, ACK audit, 불변식 정상화 후 자동 resolve를 테스트한다.
- admin hash navigation, 빈 목록 `total_count=0`, 동일 시각 cursor pagination, masking, audit rollback을 테스트한다.
- Star+Bonus 동시 구매/환불 timeline이 currency별 allocation을 분리해 반환하고 bigint delta를 합치지 않는지 테스트한다.
- Operator retry가 enqueue만 수행하고 stale/non-retryable/DEAD operation이나 금융 command 직접 실행은 거부되는지 테스트한다.
- Admin CREDIT, 충분/부족 Star·Bonus DEBIT, Bonus FIFO bucket 소비, 2인 승인 CORRECTION과 correction debt를 테스트한다.
- 동일 admin operation key를 CREDIT 뒤 DEBIT 또는 다른 amount/user로 재사용하면 전역 idempotency conflict가 발생하는지 테스트한다.
- 구매 → Boost → 환불 → debt → future recovery 전체가 CS timeline 한 흐름으로 재구성되는지 검증한다.
- `picnic-admin`은 Next build 설정과 별도로 TypeScript type-check를 반드시 통과해야 한다.

### Migration/Property/Performance

- fresh DB reset, 현재 baseline upgrade, 익명화한 운영 규모 snapshot upgrade를 모두 실행한다.
- 기존 Star/Bonus row와 합계 변화가 0인지 검증한다.
- 고정 seed 최소 100개 × seed당 200 operation의 grant/expire/vote/purchase/refund/retry sequence를 실행한다.
- 정상 fixture의 reconciliation mismatch는 0, 의도적으로 오염한 fixture 탐지율은 100%여야 한다.
- 동시성 시나리오는 각각 최소 100회 반복해 중복·음수 잔액 0을 확인한다.
- 대표 일반 투표 p95가 기존 `voting-v2` 대비 20% 이상 악화되면 NO-GO다.

## 15. 출시 순서와 게이트

### Phase -1 — 개발·Preview·Production 환경 격리

현재 저장소 점검에서 다음 위험을 확인했다.

- `picnic_app/config/dev.json`과 `local.json`의 Supabase URL·anon key·storage tuple이 `prod.json`과 동일하다.
- `picnic-admin/.env`와 `.env.local`의 Supabase endpoint가 production project를 가리킨다.
- `picnic-supabase/supabase/config.toml`과 ignored `supabase/.env`는 production project/DB를 기준으로 한다.

이 상태에서는 네트워크 통합 테스트, Preview 실행, remote Supabase CLI 명령을 시작하지 않는다. 아래 격리 gate가 먼저 통과해야 한다.

- production Supabase project ref `xtijtefcycoeqludlngc`를 모든 개발/Preview preflight의 denylist로 고정한다. production ref 변경 시 release-security 승인으로 denylist와 test fixture를 함께 갱신한다.
- Supabase 개발 명령은 host가 `127.0.0.1|localhost`, API port `54321`, DB port `54322`인 local stack만 허용한다. feature worktree에서는 `supabase db push --linked`, `supabase migration up --linked`, `supabase functions deploy`, production/unknown `--db-url`, `psql "$SUPABASE_DB_URL"`를 실행하지 않는다.
- `picnic-supabase` worktree에는 원본 `supabase/.env`, `.env*`, `supabase/.temp`, link metadata를 복사하지 않는다. local test에는 secret 없는 local config만 사용한다.
- 별도 staging Supabase project ref와 credentials가 제공되지 않으면 Preview/remote integration은 **NO-GO**다. staging ref는 production과 달라야 하며 App `ENVIRONMENT=dev`, Vercel Preview, Admin Playwright가 모두 같은 staging contract version을 사용한다.
- App의 `local`/`dev` build는 Supabase URL·anon key·storage tuple이 `prod`와 하나라도 동일하면 build/test 전에 실패한다. `local`은 local Supabase, `dev`는 staging만 허용하고 Pangle/결제는 sandbox/test mode만 사용한다.
- Admin의 local/Preview 환경에는 `NEXT_PUBLIC_*SERVICE_ROLE*` 변수를 허용하지 않는다. browser에는 staging anon key만, server-only Route Handler에는 staging `SUPABASE_SERVICE_ROLE_KEY`만 제공한다. Vercel Preview가 production Supabase URL/ref를 가리키면 build가 실패한다.
- production baseline은 별도 read-only DB role/URL과 승인 reference로만 수집한다. preflight는 `current_user`가 신규/기존 금융 table에 INSERT/UPDATE/DELETE 권한이 없음을 확인한 뒤 read-only SQL만 실행한다.
- production schema/function 배포는 feature branch나 개발자 shell에서 실행하지 않는다. `main`의 정확한 commit SHA, `GO: cotton-candy-v1`, rollback rehearsal, Product/Finance·Backend·CS/on-call 승인, protected production environment를 검증하는 수동 workflow만 수행한다.
- PR은 Vercel Preview와 staging만 사용한다. Vercel Production Branch는 `main`이며, UI/API merge 전 Preview 확인 질문에 사용자가 답하기 전에는 merge하지 않는다.

환경 gate의 실패는 우회 가능한 warning이 아니라 exit code 1인 배포 차단이다. staging 미구성은 개발 편의를 위해 production으로 fallback할 이유가 될 수 없다.

코드·schema 배포와 기능 활성화는 서로 다른 승인 단계다.

- **Dark launch 배포:** local/staging 검증, additive migration dry-run, clean `main`의 exact SHA, production deploy 승인, rollback rehearsal을 만족한 Supabase 코드만 수동 workflow로 배포한다. 이때 신규 write/source/surface/admin-command flag는 모두 false이고 live Cotton grant·Candy Boost·환불 역분개·관리자 금융 명령은 0이어야 한다.
- **기능 활성화:** dark launch 관찰, wallet-aware App/Admin 선배포, 전체 finance gate, Product/Finance·Backend·CS/on-call 승인까지 완료되어 release verifier가 `GO: cotton-candy-v1`을 반환한 뒤 audited runtime command로만 cohort flag를 단계적으로 연다. schema 재배포와 flag 활성화를 한 동작으로 묶지 않는다.
- 코드 PR은 full activation GO 전에 생성·검증·merge할 수 있지만, Supabase dark launch와 App/Admin Preview가 각각의 환경 gate를 통과해야 한다. UI/API PR은 Vercel Preview 확인 전 merge하지 않는다.

### Phase 0 — 기준선

- 기존 Star/Bonus 합계, drift, 광고/결제 오류율, p95, 만료 job 기준을 측정한다.

### Phase 1 — 엔진 dark launch

- additive schema, RPC, RLS, inbox, reconciliation, alert, admin read를 배포한다.
- strict Bonus projection과 공통 debt-aware credit helper를 먼저 배포하고 기존 지급원 회귀 테스트를 통과시킨다.
- 전체 wallet mutation writer inventory와 공통 per-user lock helper를 배포하고 shadow 계측을 시작한다.
- 관리자 전환은 `command RPC 배포 → 새 admin command UI 배포·검증 → legacy 직접 mutation 경로 비활성 → RLS/guard revoke 검증` 순서다. 마지막 검증 전에는 `admin_financial_commands_enabled`를 켜지 않는다.
- 모든 신규 write flag는 OFF 또는 기존 Bonus 모드다.

### Phase 2 — 만료 인프라 선배포

- worker heartbeat와 dry-run을 확인한다.
- 테스트 계정으로 KST 자정, lazy exclude, worker 재실행 멱등성을 검증한다.
- 이 단계는 최초 실제 코튼캔디 지급의 선행 조건이다.

### Phase 3 — 클라이언트 선배포

- Cotton 모델, wallet, history, spend, popup, polling을 지원하는 앱과 관리자 read UI를 배포한다.
- 실제 광고 지급은 계속 Bonus로 유지한다.
- Pangle v2 claim을 shadow로 실행해 intent 누락률, bind 성공률, SSV latency를 측정한다.
- 모든 **일반 투표** writer/Edge 경로를 `perform_vote_transaction_v3`로 라우팅하고 legacy 일반 투표 RPC의 client EXECUTE를 revoke한다. JMA·궁합·PIC처럼 의도적으로 별도인 경로는 inventory에 명시한다. 이 차단 검증은 최초 live Cotton 지급의 선행 조건이다.
- 나머지 debit/transfer/expiry writer도 공통 lock 순서로 이전해 `wallet_mutation_lock_coverage=100%`를 확인한다.

### Phase 4 — 내부 숏폼 canary

- wallet-aware 최소 앱 version을 만족하는 사내/테스트 계정에서 일반 vote spend와 내부 숏폼 Cotton을 함께 활성화한다.
- 안정 cohort로 확대하고 최소 한 번의 KST 자정 만료를 관찰한다.

### Phase 5 — Pangle canary와 전역 전환

- claim mode를 `shadow → optional → required`로 전환한다.
- allowlist, 안정 cohort, 전역 순으로 확대한다.
- Cotton 지원 앱을 최소 지원 version으로 강제한 뒤 legacy intent-less fallback을 마지막 세션 TTL 이후 종료한다.
- 앱 version별 Bonus/Cotton 장기 분기는 정책 우회가 가능하므로 허용하지 않는다.

### Phase 6 — 캔디 부스트와 surface

- shadow evaluator로 최근 provider event의 예상 대상·금액·version을 검증한다.
- 제한 cohort에서 구매 추가 지급을 활성화한다. entitlement는 event 발생 시각의 rollout policy로 snapshot하고 현재 flag는 정산 pause에만 사용한다.
- 모든 Star/Bonus positive writer가 공통 debt-aware helper로 이전되고 `debt_recovery_enabled=true`인 것을 DB gate로 확인한 뒤에만 `refund_reversal_enabled=true`를 허용한다. 역순 조합은 설정 command가 거부한다.
- 마지막으로 스토어와 홈 surface를 켠다.

### Feature flag

- `wallet.cotton_read_enabled`
- `wallet.cotton_spend_enabled`
- `wallet.cotton_expiry_enabled`
- `ads.internal_reward_mode = bonus | cotton | paused`
- `ads.pangle_reward_mode = bonus | cotton | paused`
- `ads.pangle_claim_mode = shadow | optional | required`
- `ads.cotton_popup_enabled`
- `candy_boost_write_enabled`
- `refund_reversal_enabled`
- `debt_recovery_enabled`
- `promotion_surfaces_enabled`
- `admin_financial_commands_enabled`

cohort는 allowlist 또는 안정적인 user-ID hash로 고정한다. 요청마다 무작위로 바꾸지 않는다.

- `wallet.cotton_expiry_enabled`는 최초 live Cotton grant 전의 출시 gate다. live grant가 하나라도 생긴 뒤에는 false로 되돌릴 수 없으며, 지급을 pause해도 기존 `expires_at`과 조회 시각 제외 규칙은 계속 적용한다.
- `candy_boost_write_enabled=false`여도 기본 구매 지급은 계속 처리한다. eligible 프로모션 award settlement만 inbox에 보류하며 provider-time entitlement를 지우거나 현재 policy로 다시 판정하지 않는다.
- `refund_reversal_enabled ⇒ debt_recovery_enabled ∧ credit_source_coverage=100%`를 DB 설정 제약과 release gate 양쪽에서 강제한다.

### Credit source 전환 게이트

최소 inventory 범위는 모바일/웹 구매, 출석, 미션·이벤트, 선물, 투표 공유, JMA·궁합/Goonghap, Tapjoy·Pincrux·legacy Bonus 광고, 관리자 조정, 그 밖의 모든 Star/Bonus 양수 writer다. 구현 계획에서 아래 열을 채운 machine-checkable coverage matrix를 만들고 미분류 writer가 0개일 때만 환불을 활성화한다.

| 필수 열 | 의미 |
|---|---|
| source/symbol | 기존 SQL 함수·trigger·Edge 함수의 정확한 위치 |
| currency/reason | Star/Bonus와 지급 사유 |
| common helper | 이전할 debt-aware command/helper |
| idempotency key | 안정 자연키와 payload mismatch 규칙 |
| test ID | debt 없음/부분 상계/전액 상계/replay 자동 테스트 |
| rollout state | shadow, migrated, legacy-disabled, verified |

### Wallet mutation lock 게이트

credit coverage와 별도로 Star/Bonus/Cotton을 바꾸는 **모든** writer를 inventory한다. 구매·출석 같은 양수 writer뿐 아니라 일반/JMA/궁합/PIC 사용, 선물 송신·수신, 환불·correction·관리자 debit, Cotton/Bonus expiry, batch/cron, legacy RPC가 포함된다.

- 각 writer는 exact source symbol, 영향 통화, lock 대상 사용자, `per-user advisory → user row → domain/bucket` 순서, multi-user 정렬 순서, 대체 RPC, direct-call 차단 test ID를 기록한다.
- 선물처럼 여러 사용자를 변경하면 user UUID 오름차순으로 모든 advisory/user row lock을 잡은 뒤 통화를 변경한다.
- `wallet_mutation_lock_coverage=100%`, unknown/legacy writer 0개가 되기 전에는 purchase refund, debt recovery, live Cotton을 활성화하지 않는다.

### GO 조건

- 금융 불변식 mismatch, 중복 지급, 음수 잔액, orphan, snapshot/audit 누락 0건
- 시간 경계, RLS, EXECUTE, 직접 DML 차단 100% 통과
- legacy 일반 투표 client 경로 0개, 일반 투표 v3 route coverage 100%
- 모든 failure point에서 부분 write 0
- 동일 replay가 신규 ledger/award/debt를 만들지 않음
- shadow 예상액과 실제 지급액 100% 일치
- Pangle intent bind, PENDING age, callback 오류율이 provider별 기준선 내
- credit source coverage matrix 100%, 미분류 positive writer 0개
- wallet mutation lock coverage 100%, 미분류 debit/transfer/expiry writer 0개
- Vercel Preview, 실기기, Pangle sandbox SSV, 운영 규모 migration 검증 완료
- kill switch와 alert → dry-run repair → 자동 resolve 리허설 완료
- 각 phase 시작 전에 표본 수, 관찰 시간, p95/PENDING-age, callback 오류율, DLQ 허용치와 Product/Finance·Backend·CS/on-call 승인자를 release manifest에 수치로 고정한다. manifest가 없거나 금융 오류 허용치가 0이 아니면 NO-GO다.
- 최근 provider event의 대상·금액·version, 현재/다음 홈·스토어 window, 예상 환불 debt, provider 시각 검증률, campaign 충돌 preview를 승인자가 확인한다.

### 즉시 중단 조건

- 금융 불변식 위반 1건
- 중복 지급/투표/환불 1건
- provider 시각이 아닌 시각으로 프로모션 판정
- 잘못된 campaign version snapshot
- future credit의 debt 우회
- audit 없는 관리자 금융 mutation
- 기간 밖 홈/스토어 노출
- 직접 잔액/원장 수정 가능
- 원인 불명의 reconciliation mismatch 또는 dead-letter

## 16. Rollback 원칙

- schema drop, DB snapshot 복원, 원장 삭제를 하지 않는다.
- 코드 rollback과 책임별 신규 write disable을 우선한다.
- 공급자 event 수신은 유지하고 settlement를 inbox에 보류한다.
- rollback 동안 관리자 금융 command도 동결하고 조회·alert ACK만 유지한다.
- 광고 문제가 있으면 채널 reward mode를 `paused`로 전환한다. 진행 중 claim을 즉시 Bonus로 바꾸지 않는다.
- 만료 문제가 있으면 신규 Cotton 지급을 중단하고 기존 만료일을 유지한 채 worker를 보정한다.
- Boost 문제가 있으면 추가 지급과 surface만 끄고 기본 구매는 유지한다.
- 오지급은 append-only correction과 필요 시 debt로 보정한다.
- 과다 회수는 append-only refund correction credit로 복구한다.
- 보류 provider/review/refund event를 유형별로 분류하고 correction 뒤 대표 CS timeline을 검증한다.
- drift·중복·부채 방정식·audit mismatch 0건과 관련 alert 자동 resolve를 확인한다.
- Product/Finance, Backend, CS/on-call 재개 승인을 남긴 뒤 inbox lease를 제한 cohort부터 풀고, 재처리 결과를 확인한 후 전역으로 확대한다.

## 17. 레포별 구현 경계

### picnic-supabase

- migration, RLS, grants/ledger/claim/campaign/snapshot/debt/inbox/alert schema
- 공통 Star/Bonus credit/debit/correction allocation과 전역 wallet lock helper
- server-only RPC와 Edge wrapper
- 기존 mobile/web 구매 경로의 공통 verified-purchase 경계 통합
- Pangle SSV/내부 숏폼 callback 원자화
- 일반 vote v3, expiry worker, reconciliation, alert
- admin/app read DTO
- 실제 PostgreSQL 테스트와 migration test

### picnic-app

- 모델 및 wallet/history provider의 Cotton 필드
- 3분할 UI, 승인 아이콘 asset, 명칭/도움말/접근성 문자열
- 일반 투표 요청/응답 v3
- 내부 숏폼 canonical reward 처리
- Pangle claim preflight, native media_extra, status polling과 앱 재개 복구
- 스토어 promo와 일정 기반 홈 이벤트 배너
- unit/widget/golden/native integration test

### picnic-admin

- 3재화 summary/history/CS timeline
- 프로모션 version 생성, 활성/비활성, surface, window preview
- Wallet Ops, operation/DLQ, alert/repair UI
- 직접 balance/ledger mutation 폐쇄
- Star/Bonus 수동조정을 제한 command RPC로 이동; Cotton 수동조정은 V1 미제공
- DB 기반 immutable audit 조회
- type-check, Jest, Playwright acceptance

각 레포는 정책에 맞는 별도 sibling worktree와 규격 브랜치에서 구현한다. 스키마가 먼저 확정되고 배포된 뒤 생성 타입을 갱신한다. 현재 `picnic-supabase`의 사용자 `.gitignore` 변경과 `picnic-admin/types/supabase.ts`의 사용자 변경을 덮어쓰지 않는다.

## 18. 성공 기준

- 앱에서 세 재화가 승인된 이름·아이콘·순서로 일관되게 표시된다.
- 코튼캔디 광고 지급, 일반 투표 우선 차감, KST 자정 만료가 서버 권위로 동작한다.
- 동일 광고/투표/구매/환불 재시도가 재화를 두 번 변경하지 않는다.
- 캔디 부스트 구매와 홈/스토어 노출이 같은 campaign version evaluator와 올바른 기준 시각을 사용한다.
- 환불 대상은 즉시 회수와 신규 debt의 합과 일치하고 이후 같은 통화 credit에서 debt가 먼저 상계된다.
- admin과 CS가 구매 → Boost → 환불 → debt → 상계를 SQL 없이 재구성할 수 있다.
- 직접 잔액/원장 수정이 DB 권한으로 차단된다.
- 정상 데이터의 reconciliation mismatch가 0이고 의도적 오염 fixture를 모두 탐지한다.
- 단계적 출시의 모든 GO 조건을 통과하기 전에는 전역 지급을 활성화하지 않는다.

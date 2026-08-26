# 캔디 부스트 어드민 일정 설계

## 결정

권장안은 **불변 campaign version에 전체 행사 반개구간과 KST 반복 요일 집합을 함께 저장하고, HOME과 결제 화면 배지를 독립 boolean으로 저장하는 additive V2 계약**이다. 지급 판정은 오직 Supabase DB 시계와 검증된 구매 발생 시각으로 수행하고, 앱과 어드민은 V2가 준비될 때까지 기존 V1 read RPC를 계속 사용한다. 모든 변경은 새 version INSERT이며 이전 version, 구매 지급 snapshot, 감사 이벤트를 수정하거나 삭제하지 않는다.

## 조사 결과와 해결 대상

현재 `promotion_campaign_versions`는 `start_iso_day/start_local_time/end_iso_day/end_local_time`로 주간 한 구간만 표현한다. `wallet_private.evaluate_campaign_promotion`은 `date_trunc('week', …)`로 그 한 구간을 매주 계산하므로 전체 행사 시작·종료도 복수 요일 반복도 표현하지 못한다.

`picnic-admin-wallet-ops/app/wallet-ops/components/PromotionCampaigns.tsx`는 새 version을 월요일 00:00부터 일요일 23:59:59까지 하드코딩하고 `home ? ['HOME'] : ['STORE']`를 보내 HOME/STORE를 배타적으로 만든다. 같은 화면은 `rolloutPolicy: {}`를 보내지만 기존 DB 제약은 `seed`와 `threshold_bps`를 요구하므로 정상 생성도 실패한다. 또한 어드민은 `extraBonusBps`를 직접 입력·표시해 운영 UI 요구인 bps 비노출을 위반한다.

앱의 `ActivePromotionCampaignModel`은 `extra_bonus_bps`, 주간 시작/끝, `show_in_store`, `show_home_banner`를 강제 exact-key 계약으로 받으며, badge는 bps가 정확히 10000일 때만 “2배”라고 말한다. 현 `get_active_promotion_campaigns(surface)`는 surface별 호출인데 각 item 안에 두 surface boolean을 모두 반환하므로, 독립 선택을 유지하면서도 surface에 맞지 않는 item을 누출하지 않는 V2 응답이 필요하다.

## 접근 비교

| 접근 | 장점 | 단점 | 판단 |
| --- | --- | --- | --- |
| V1 주간 구간을 확장해 날짜를 덧붙임 | migration이 작다 | 복수 요일·전체 기간·독립 노출을 억지로 표현하고 legacy 의미가 불명확하다 | 기각 |
| JSON 일정 정책만 version에 추가 | schema 변경이 적고 미래 규칙을 쉽게 넣는다 | DB 제약·인덱스·어드민 검증이 약해지고 잘못된 JSON이 금융 판정에 들어간다 | 기각 |
| 정규 V2 version + 반복 요일 테이블 + V2 RPC | 제약과 감사성이 강하고 현재 계약을 additive하게 유지한다 | migration/RPC/UI가 늘어난다 | 채택 |

## 데이터 모델

기존 V1 테이블/함수는 변경하지 않고 아래 V2 객체를 추가한다. `promotion_campaigns` identity는 계속 재사용하고 하나의 campaign에는 V1 또는 V2 version 계열 중 실제 평가 대상인 가장 늦은 `effective_from`만 존재하도록 생성 RPC가 직렬화한다.

`promotion_campaign_schedule_versions`:

| 필드 | 규칙 |
| --- | --- |
| `id uuid`, `campaign_id uuid`, `version bigint` | `(campaign_id, version)` unique; 새 행만 INSERT |
| `effective_from timestamptz` | version이 운영 정책으로 효력을 얻는 시각; 같은 campaign 내 unique |
| `enabled boolean` | 비활성 version은 어떤 surface/지급에도 적용하지 않는다 |
| `event_starts_at`, `event_ends_at timestamptz` | `event_starts_at < event_ends_at`; `[start,end)` 전체 행사 구간 |
| `timezone text` | V2는 반드시 `Asia/Seoul` |
| `multiplier_tenths smallint` | 11..30; 사용자 값 1.1x..3.0x를 정수 tenths로 저장 |
| `show_home_banner`, `show_payment_badge` | 독립 boolean; 둘 다 false 허용(지급 전용) |
| `home_banner_id uuid nullable` | HOME=true일 때만 필수, HOME=false면 null |
| `display_name jsonb` | object이며 `ko`의 비공백 문자열 필수 |
| `changed_by`, `change_reason`, `cs_ticket`, `created_at` | 감사 필수; 사유/티켓은 비공백 |

`promotion_campaign_schedule_weekdays`는 `(campaign_version_id, iso_dow)` primary key이며 `iso_dow`는 1(월)~7(일)이다. 최소 한 행을 생성 RPC에서 보장한다. 반복은 선택된 KST 날짜의 요일 전체를 뜻하며 시간대별 별도 구간은 V2 범위 밖이다.

append-only trigger는 UPDATE/DELETE/TRUNCATE를 거부한다. HOME creative ownership도 기존의 단일 campaign ownership 규칙을 재사용한다. `rollout_policy`는 V2에 만들지 않는다: 승인 요구는 전 사용자 적용이며 빈 객체 결함을 재발시키지 않는다. 이후 점진 rollout이 필요하면 명시적 `cohort_seed`와 `cohort_threshold_bps`를 nullable 쌍으로 별도 version에 추가하고 둘 다 존재할 때만 유효하도록 한다.

## 시간, 요일, DST

행사와 지급 판정은 `now()` 대신 기존 `wallet_private.fixed_db_now()` snapshot 하나를 사용한다. 구매는 provider가 검증한 발생 시각 `p_verified_occurred_at`을 사용하고, 노출은 그 DB snapshot을 사용한다. 어느 경우든 같은 evaluator에 `p_at`을 넣는다.

판정은 다음 순서다.

1. `event_starts_at <= p_at AND p_at < event_ends_at`가 아니면 inactive.
2. `local_ts = p_at AT TIME ZONE 'Asia/Seoul'`, `local_date = local_ts::date`.
3. `extract(isodow from local_date)`가 weekday 행에 없으면 inactive.
4. 그 밖에는 해당 version의 `enabled` 및 version effective 시각을 확인한다.

KST는 UTC+09:00이며 DST를 사용하지 않는다. 그럼에도 저장소는 `timestamptz`, 계산은 IANA zone `Asia/Seoul`로 고정해 host/session timezone에 의존하지 않는다. 행사 종료 정각과 선택 요일의 KST 00:00은 포함하지 않으며, 일광절약제를 쓰는 timezone으로의 변경은 V2에서 허용하지 않는다. provider 시간이 없거나 신뢰할 수 없으면 기본 구매만 처리하고 `PROMOTION_TIME_UNVERIFIABLE`로 promotion 지급을 보류/관측한다; 처리 시각으로 대체하지 않는다.

## 배수·금액

어드민은 `1.1x`~`3.0x` dropdown(0.1 단위)만 보며 bps 필드/컬럼/오류를 노출하지 않는다. 서버는 문자열을 부동소수점으로 변환하지 않고 `multiplier_tenths` 정수로 검증한다.

`base_reward_total`은 해당 구매의 서버 확정 기본 Star + 채널 기본 Bonus의 정수 합계다. `gross_total = floor(base_reward_total * multiplier_tenths / 10)`이며 `extra_bonus = gross_total - base_reward_total`이다. `base_reward_total`은 양수이고 `multiplier_tenths >= 11`이므로 extra도 최소 1이 된다. SQL은 numeric/정수 곱셈 후 floor를 명시하고 Dart/TypeScript도 정수 tenths만 표시 변환해 이진 부동소수점 반올림을 금지한다. 지급 snapshot에는 campaign/version ID, multiplier_tenths, base components, gross_total, extra_bonus, evaluator timestamp를 기록하며 환불은 현재 설정을 재평가하지 않고 snapshot을 역분개한다.

## API와 호환성

새 read RPC는 `get_active_promotion_campaigns_v2(p_surface text)`이며 `HOME` 또는 `PAYMENT_BADGE`만 받는다. 응답은 기존 envelope 모양(`items`, `total_count`, `next_cursor`, `snapshot_at`, `campaign_owned_home_banner_ids`)을 유지하되 item에는 `campaign_id`, `campaign_version_id`, `code`, `display_name`, `multiplier_tenths`, `event_starts_at`, `event_ends_at`, `repeat_iso_dows`, `home_creative`만 포함한다. 요청 surface와 무관한 item은 반환하지 않으며, HOME item은 readable creative가 없으면 제외한다.

기존 `get_active_promotion_campaigns(text)`와 Dart V1 exact-key decoder는 제거하거나 응답 필드를 바꾸지 않는다. 앱은 V2 repository/model/provider를 추가하고 런타임 flag로 V2를 우선 호출하되 실패·미지원이면 V1을 읽기 전용 fallback으로 사용한다. payment badge는 V2의 multiplier를 `1.5배`, `2배`, `2.1배`처럼 렌더링하며 HOME과 badge fetch/cache key를 분리한다.

새 admin command `admin_create_promotion_schedule_version`은 request idempotency, optimistic `expected_latest_version`, role permission, reason/CS ticket, exact-key JSON validation을 지킨다. 입력은 event start/end, enabled, weekday 배열, multiplier_tenths, 두 surface boolean, optional banner이며 bps/rollout-policy/weekly start-end 필드는 허용하지 않는다. admin list/preview V2 RPC는 계산된 다음 활성 KST 날짜와 판정 이유를 반환한다.

## 어드민 UI와 오류 처리

새 version modal은 KST로 표시되는 전체 행사 시작/종료 datetime, 요일 다중 선택, 배수 dropdown, HOME 배너 토글+선택, 결제 화면 배지 토글, 활성 토글을 둔다. HOME과 결제 배지는 서로 영향을 주지 않으며 HOME off일 때 선택한 banner ID를 제출하지 않는다. 제출 전에는 종료가 시작보다 뒤인지, 요일이 하나 이상인지, HOME이면 banner가 있는지, multiplier가 11..30인지 검증한다.

서버 오류는 field 오류(`PROMOTION_INVALID_EVENT_RANGE`, `PROMOTION_WEEKDAY_REQUIRED`, `PROMOTION_MULTIPLIER_INVALID`, `PROMOTION_HOME_BANNER_REQUIRED`), 충돌(`PROMOTION_VERSION_CONFLICT`, 재로드 후 재입력), 권한/감사(`ADMIN_ROLE_REQUIRED`, `ADMIN_REASON_TICKET_REQUIRED`), 안전 정지(`PROMOTION_SURFACES_DISABLED`)로 매핑한다. 원문 SQL 오류나 내부 bps 값은 표시하지 않는다. create 성공은 audit ID와 새 version 번호를 보여주고 실패/네트워크 재시도는 같은 request ID만 재사용한다.

## 마이그레이션과 롤아웃

1. additive V2 tables, immutable triggers, constraints, indexes, admin permission/RPC를 배포하고 SQL tests를 통과시킨다.
2. V2 read RPC와 앱/admin DTO를 추가하되 `promotion_schedule_v2_enabled=false`로 둔다.
3. 기존 V1 campaign을 V2 version으로 backfill하지 않는다. 운영자가 새 V2 version을 명시 생성하고 preview에서 KST 경계·각 요일·두 surface를 검토한다.
4. staging에서 V2 read와 purchase settlement snapshot을 검증한 뒤 flag를 소수 내부 계정에서 시작한다. cohort 요구가 없으므로 일반 출시에서는 100%다.
5. flag를 켜고 metrics(선택된 version, inactive 사유, V1 fallback, 지급/환불 snapshot)를 관측한다.

되돌리기는 runtime flag를 끄고 V1 read와 V1 지급 경로로 복귀하는 것이다. 이미 생성한 V2 version·지급 snapshot·감사 행은 삭제/수정하지 않는다. 활성 V2 설정의 잘못은 새 `enabled=false` version 또는 올바른 후속 version으로 정정하며, payout 오류는 원 구매 snapshot 기반의 감사된 correction/환불 절차로만 처리한다.

## TDD 검증

- SQL: start 포함/end 제외, KST 자정, 월말/연말, 선택한 복수 요일, 선택되지 않은 요일, enabled false, version effective 경계, banner nullable 제약, append-only, 동일 request replay/다른 payload conflict를 test한다.
- SQL: multiplier 11/30 수용, 10/31 거부, `base=1, tenths=11`의 extra=1, `base=15, tenths=15`의 gross=22/extra=7, snapshot 환불이 후속 version 변경의 영향을 받지 않음을 test한다.
- RPC 계약: V1 exact-key fixture는 변경 없이 통과하고 V2 HOME은 badge-only version을, V2 PAYMENT_BADGE는 home-only version을 반환하지 않음을 검증한다.
- Admin: 빈 rollout policy를 보내지 않고, HOME+badge 동시 선택/각각 off/기간·요일·배수 field 오류/optimistic conflict를 component 및 command tests로 검증한다.
- Flutter: V2 parser의 strict keys, V1 fallback, HOME creative 미완성 제외, badge의 1.1x·2x·3x localization과 HOME/결제 cache 독립성을 widget/provider tests로 검증한다.
- 운영: migration 전후 read-only schema/RPC privilege check, flag off/on smoke, 대표 KST 시각의 admin preview와 실제 settlement evaluator 결과를 대조한다.

## 범위 경계와 사용자 검토

V2는 하루 안에서 여러 시간 구간, 국가별 timezone, 상품별 배수, promotion stacking, 퍼센트/코호트 rollout UI를 제공하지 않는다. 사용자 검토가 필요한 결정은 (1) 비검증 provider 발생 시각을 기본 지급만 하고 보류할지 완전 거절할지, (2) 행사 중간에 비활성 후 재활성할 때 새 version의 `effective_from`를 즉시로 허용할지 예약만 허용할지, (3) V1 기존 캠페인을 언제 별도 V2 version으로 운영 전환할지다.

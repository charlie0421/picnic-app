# PR 73 Merge Readiness Design

## Goal

PR 73을 프로덕션 배포 경로에 영향을 주지 않는 상태로 정리하고, 코튼캔디 보상·구매 영수증·일반 투표 Wallet v3 기능을 재현 가능한 migration 및 테스트와 함께 머지할 수 있게 한다.

## Scope

현 PR에서 다음 항목만 머지 필수 범위로 취급한다.

- 코튼캔디 광고 보상 적립과 공통 보상 영수증
- 스타캔디·보너스 스타캔디 구매 영수증
- 일반 투표 Wallet v3 연동과 PIC 투표의 기존 재시도·인증 복구
- staging 빌드의 명시적 격리
- 위 기능이 의존하는 Wallet schema, RPC, RLS, grants, Edge Function
- Task Master 제거

Shorebird 시작 정책, AWS 배포 스크립트, YouTube/DeepL/network 변경 등 독립적으로 배포·검토할 수 있는 변경은 별도 후속 PR로 분리한다.

## Considered Approaches

### 1. 현 PR을 그대로 보정

가장 빠르지만 309개 파일의 결합된 변경을 유지하므로 회귀 원인과 롤백 범위가 지나치게 넓다.

### 2. 코튼캔디 변경만 새 PR로 재구성

가장 깨끗하지만 이미 완료한 staging 검증과 충돌 해결을 다시 수행해야 하며 누락 위험이 있다.

### 3. 안전 차단 수정 후 주제별 분리

현 브랜치에서 프로덕션 배포 차단, Wallet migration 완결성, 투표 실패 처리를 우선 수정한다. 이후 코튼캔디에 필요 없는 변경을 원래 목적별 후속 브랜치로 옮기거나 현 PR에서 제거한다.

이 접근을 채택한다. 기존 검증 자산을 보존하면서도 머지 단위를 코튼캔디 기능과 필수 인프라로 제한할 수 있기 때문이다.

## Deployment Architecture

Codemagic production workflow는 `ENVIRONMENT=prod`, production Supabase 설정, production 결제 및 광고 설정을 기본값으로 유지한다. staging은 별도 workflow 또는 명시적 staging 태그 패턴으로만 실행하며 `ENVIRONMENT=dev`, staging Supabase project ref, sandbox payment/Pangle 값을 사용한다.

두 workflow는 같은 태그를 동시에 소비하지 않는다. production 빌드는 staging 환경변수의 존재 여부에 의존하지 않고, staging 빌드는 production endpoint 또는 production project ref가 검출되면 빌드를 중단한다.

## Database Architecture

빈 staging database에 repository migration을 순서대로 적용하면 Wallet 기능이 완성되어야 한다. migration에는 다음이 포함된다.

- Wallet 원장 및 사용자별 잔액 저장 구조
- 광고 보상 상태와 acknowledgement 구조
- 구매 정산 및 promotion 구조
- `get_wallet_summary`
- `get_currency_history`
- `get_ad_reward_status`
- `list_unacknowledged_ad_rewards`
- `acknowledge_ad_reward`
- `settle_shortform_view_reward`
- 일반 투표 Wallet v3 transaction 함수
- 필요한 grants, RLS, 함수별 사용자 검증

특권 함수는 비노출 schema에 두고 `search_path`를 고정한다. 클라이언트 호출 함수는 `auth.uid()`를 검증하고 필요한 함수에만 `authenticated` 실행 권한을 부여한다.

## Vote Failure Handling

일반 투표 실패 UI와 로딩 상태 복원은 Wallet refresh보다 먼저 보장한다. 실패 후 Wallet refresh는 timeout과 자체 오류 처리를 가진 best-effort 동작으로 수행하며, refresh 실패가 원래 투표 오류를 가리거나 다이얼로그 종료를 막지 않는다.

인증 재시도에서는 최초 요청과 동일한 idempotency request ID를 사용한다. PIC 투표의 기존 429 backoff와 인증 복구는 변경하지 않는다.

## Testing

- Codemagic workflow 정적 테스트로 production과 staging의 tag, environment, backend, payment/Pangle 설정을 검증한다.
- 빈 local Supabase database에 전체 migration을 적용하고 필요한 table/function/grant를 조회한다.
- 인증 사용자와 비인증 사용자의 Wallet RPC 권한 및 소유권 격리를 검증한다.
- Wallet refresh가 지연되거나 실패해도 투표 오류 UI와 로딩 복원이 완료되는 widget/unit test를 추가한다.
- 코튼캔디 광고 적립, 공통 영수증, 구매 복합 영수증, Wallet v3 투표 테스트를 재실행한다.

## Merge Gates

- 독립 코드 리뷰에서 Critical 및 Important 이슈가 없어야 한다.
- 관련 Flutter tests와 analyzer가 통과해야 한다.
- migration clean-database 검증이 통과해야 한다.
- GitHub PR이 mergeable이고 필수 checks가 완료되어야 한다.
- 저장소 정책에 따라 UI/API 변경의 Preview 확인 승인을 받은 뒤에만 `main`으로 머지한다.

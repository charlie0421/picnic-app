# 운영 문서 (런북 · 핸드오프 · 감사 보고)

프로덕션 운영 중 참조하는 문서 모음. 지금까지 `picnic-app-cotton-candy-policy`
워크트리 루트에 **git 추적 없이** 놓여 있어, 워크트리를 정리하면 소실되는
상태였다. 여기로 옮겨 이력에 남긴다.

문서는 작성 시점의 스냅샷이다. 파일이 사실이라고 말하는 것과 현재 코드·DB가
다르면 **코드와 DB가 이긴다** — 특히 버전 번호, 패치 번호, 플래그 상태.

## 런북 (사고·문의 대응)

| 문서 | 언제 보나 |
|---|---|
| [cs-missing-purchase-runbook.html](cs-missing-purchase-runbook.html) | 사용자가 "결제했는데 캔디가 안 들어왔다"고 할 때. 응대 문구 + 복구·수동 지급 절차 |
| [handoff-cotton-candy-production.html](handoff-cotton-candy-production.html) | 프로덕션 전환 전체 상태와 절차. OTA 패치·마이그레이션 러너·1b 컷오버 명령이 여기 있다 |

## 계획 · 결정 기록

| 문서 | 내용 |
|---|---|
| [production-deployment-plan.html](production-deployment-plan.html) | cotton-candy 프로덕션 배포 계획 (엔드포인트 버저닝 + lazy 시딩 + 지표 기반 강업) |
| [purchase-flow-improvement-plan.html](purchase-flow-improvement-plan.html) | IAP 결제 흐름 개선 계획 (검증본) |
| [attendance-reward-decision.html](attendance-reward-decision.html) | 출석 보상 폐지 결정과 1b 차단 해제 검증 |

## 감사 · 검증 보고

| 문서 | 내용 |
|---|---|
| [phase1-migration-audit-report.html](phase1-migration-audit-report.html) | Phase 1 wallet 마이그레이션 감사 (적용 차단 보고) |
| [production-release-rehearsal.html](production-release-rehearsal.html) | 프로덕션 릴리스 게이트 리허설 (2026-07-27) |
| [pr73-review-report.html](pr73-review-report.html) | PR #73 코튼캔디 완료 보고 및 배포 전 점검 |

## 작업 핸드오프

| 문서 | 내용 |
|---|---|
| [handoff-pr73-claude.html](handoff-pr73-claude.html) | PR #73 핸드오프 |
| [handoff-store-purchase-speed-and-cancel-fix.html](handoff-store-purchase-speed-and-cancel-fix.html) | 구매 속도 개선 + 취소/에러 로딩락 수정 핸드오프 (PR #137 계열) |
| [handoff-rls-rollout.html](handoff-rls-rollout.html) | RLS 도입 (착수 전). RLS 미적용 105개 테이블 — 로그인 사용자의 타인 데이터 열람을 닫는 작업. 엣지 함수 7개가 `authenticated` 로 도는 함정 포함 |

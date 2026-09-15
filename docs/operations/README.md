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
| [handoff-rls-rollout.html](handoff-rls-rollout.html) | RLS 도입 (0단계 완료 · 1~6단계 착수 전). anon 쓰기 32개는 2026-08-21 회수 완료, 남은 것은 **읽기** — 로그인 사용자의 타인 데이터 열람. 엣지 함수 7개가 `authenticated` 로 도는 함정 포함 |
| [handoff-20260819-wallet-incidents.html](handoff-20260819-wallet-incidents.html) | 지갑 장애 4건(코튼 게이트·8/15 선행·Tapjoy 7일·투표 보너스 18일) 대응 기록. 소급 4,865건, 알람 신설, 반복하기 쉬운 함정 6가지 |
| [handoff-20260820-emergency-patch.html](handoff-20260820-emergency-patch.html) | 긴급패치 배포 대기열. 130007 이후 미배포 8건(투표 이중 차감 방어 #159·#160, Sentry 5G9 수정 #165 포함)과 OTA 선행 vs 130008 신규 빌드 경로 판단 |
| [handoff-20260825-ad-abuse-detection.html](handoff-20260825-ad-abuse-detection.html) | 광고 어뷰징 탐지 cron(detect-ad-anomaly) 만성 500 + 설계 공백 4종(ACL 증발·소비자 불일치·0명 임계값·알림 부재). anti-abuse 도메인 이관 |
| [handoff-20260906-ga4-taxonomy-final.html](handoff-20260906-ga4-taxonomy-final.html) | **GA4 택소노미 — 진입점.** 전 작업 종료(2026-09-06) 시점의 프로덕션 상태, 남은 2건(Android 강업 · attestation seal), 함정, 복붙용 검증 쿼리. GA4 관련 작업을 맡으면 **이 문서부터** 읽는다 |
| [handoff-20260902-purchase-revenue-server.html](handoff-20260902-purchase-revenue-server.html) | GA4 매출 서버 계약(picnic-supabase #109·#116·#117·#118)의 상세 기록. §0 에 "계약이 프로덕션에서 한 번도 동작하지 않았다"는 GA4×DB 대조와 근본 원인(워커 타입 게이트) |
| [handoff-20260821-ga4-taxonomy.html](handoff-20260821-ga4-taxonomy.html) | GA4 택소노미 **2026-08-21~24 시점 기록**(구현·교차리뷰·대행사 회신). 본문의 "미착수/미검증" 표기는 당시 상태이고 전부 종결됐다 — 맨 위 종결 요약 블록을 먼저 볼 것 |

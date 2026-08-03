# 관리자 기능 최종 수정 보고서

## 반영 내용

- `public.is_super_admin()` helper가 `is_super_admin OR is_admin`으로 정의하는 관리자 범위를 설계와 계획 문서에 명시했다. helper와 실제 권한 코드는 변경하지 않았다.
- GDPR reset 전 상태 로깅을 제거했다. reset 결과 반환과 busy 해제 후에만 결과 상태를 `unawaited` best-effort로 기록하며, 로그 예외는 기존 보호 경계에서 삼킨다.
- 로그 Future가 완료되지 않아도 reset 결과와 busy 해제가 완료되는 회귀 테스트를 추가했다.
- 새 환경 재현을 위해 `20260803085209_cast_payment_breakdown_revenue_to_text.sql` 끝에 `get_payment_breakdown(timestamptz, timestamptz, text)`의 `PUBLIC, anon` 실행 권한 revoke 및 `authenticated` grant를 추가했다.
- 이미 적용된 운영 마이그레이션을 보완할 후속 `20260803091257_enforce_payment_breakdown_acl.sql`를 `supabase migration new enforce_payment_breakdown_acl`로 생성하고 같은 ACL을 추가했다.
- 정적 migration 계약 테스트가 두 마이그레이션의 ACL을 검증한다.

## 검증

- RED 확인: 미완료 로그 Future가 controller 결과를 timeout시키고, 두 마이그레이션 ACL 계약 테스트가 실패함을 확인했다.
- GREEN 확인: `flutter test test/presentation/controllers/admin_gdpr_reset_controller_test.dart test/data/repositories/payment_breakdown_migration_contract_test.dart` — 8건 통과.
- 회귀: controller, admin menu, consent service, repository, migration contract, charge history 대상 `flutter test` — 62건 통과.
- 정적 분석: `flutter analyze --no-pub lib/presentation/controllers/admin_gdpr_reset_controller.dart test/presentation/controllers/admin_gdpr_reset_controller_test.dart test/data/repositories/payment_breakdown_migration_contract_test.dart` — 문제 없음.
- `git diff --check` 통과.

## 미수행 항목 및 주의사항

- 운영 배포는 수행하지 않았다.
- `supabase migration list --local`은 로컬 PostgreSQL(`127.0.0.1:54322`)이 실행 중이지 않아 연결할 수 없었다. SQL 적용 검증은 배포 담당자가 실행 중인 Supabase 환경에서 수행해야 한다.

# PICNIC-2232 Comment Fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Jira PICNIC-2232의 후속 댓글 5건을 기존 Flutter UI와 로컬라이제이션 패턴에 맞게 반영한다.

**Architecture:** 기존 이미지 에셋과 위젯 구조를 재사용해 화면별 표시만 수정한다. 결제·지갑·투표 이력 데이터 흐름은 건드리지 않고, 각 화면의 위젯 테스트로 요구사항을 고정한다.

**Tech Stack:** Flutter, Dart, Riverpod, flutter_test, ARB/gen-l10n

## Global Constraints

- 신규 이미지 에셋을 추가하지 않는다.
- 결제, 지갑 API, 만료 계산, 투표 이력 조회 로직을 변경하지 않는다.
- 일반 사용자 캔디 정보 배너만 숨기고 관리자 표시는 유지한다.
- 현재 비규격 브랜치에서는 커밋·푸시·PR을 생성하지 않는다.

---

### Task 1: 상점 및 투표 이력 스타캔디 아이콘 통일

**Files:**
- Modify: `picnic_lib/lib/presentation/widgets/vote/store/purchase/purchase_star_candy_state.dart`
- Modify: `picnic_lib/lib/presentation/widgets/vote/vote_history_list_item.dart`
- Test: `picnic_lib/test/presentation/widgets/vote/store/purchase/purchase_star_candy_state_test.dart`
- Test: `picnic_lib/test/presentation/widgets/vote/vote_history_list_item_test.dart`

**Interfaces:**
- Consumes: `assets/icons/store/currency_star_candy.png`
- Produces: 일반 스타캔디를 표시하는 두 화면에서 동일한 표준 통화 아이콘

- [ ] **Step 1: 구매 목록과 일반 투표 이력이 `currency_star_candy.png`를 렌더링한다고 검증하는 테스트를 추가한다.**
- [ ] **Step 2: 두 테스트를 실행해 기존 `star_*.png` 사용 때문에 실패하는지 확인한다.**
- [ ] **Step 3: 일반 스타캔디 이미지 경로만 표준 통화 아이콘으로 교체한다. 파트너 투표 아이콘 분기는 유지한다.**
- [ ] **Step 4: 두 테스트를 다시 실행해 통과를 확인한다.**

### Task 2: 무료충전소 보상 종류별 문구

**Files:**
- Modify: `picnic_lib/lib/presentation/widgets/vote/store/free_charge_station/free_charge_content.dart`
- Modify: `picnic_lib/lib/l10n/app_*.arb`
- Regenerate: `picnic_lib/lib/l10n/app_localizations*.dart`
- Test: `picnic_lib/test/presentation/widgets/vote/store/free_charge_station/free_charge_content_test.dart`

**Interfaces:**
- Consumes: `ChargeStationItem.isMission`, `ChargeStationItem.bonusText`
- Produces: 미션은 보너스 스타캔디, 광고는 코튼캔디로 구분되는 섹션 제목과 보상 문구

- [ ] **Step 1: 한국어 환경에서 미션/광고 섹션과 보상 행의 새 문구를 검증하는 위젯 테스트를 추가한다.**
- [ ] **Step 2: 테스트를 실행해 기존 “별사탕/보너스” 문구 때문에 실패하는지 확인한다.**
- [ ] **Step 3: 의미가 명확한 로컬라이제이션 키를 ARB에 추가하고 지원 로케일 값을 작성한다.**
- [ ] **Step 4: `flutter gen-l10n`으로 생성 파일을 갱신한다.**
- [ ] **Step 5: `isMission` 분기에 따라 보상 문구를 선택하도록 최소 구현한다.**
- [ ] **Step 6: 위젯 테스트와 로컬라이제이션 생성 검증을 실행한다.**

### Task 3: 보너스 스타캔디 소멸 시점 헤더 보강

**Files:**
- Modify: `picnic_lib/lib/presentation/widgets/vote/store/common/usage_policy_dialog.dart`
- Modify: `picnic_lib/lib/l10n/app_*.arb`
- Regenerate: `picnic_lib/lib/l10n/app_localizations*.dart`
- Test: `picnic_lib/test/presentation/widgets/vote/store/common/usage_policy_dialog_test.dart`
- Test: `picnic_lib/test/presentation/widgets/vote/store/common/usage_policy_dialog_layout_test.dart`
- Verify: `picnic_lib/test/presentation/widgets/vote/store/common/usage_policy_dialog_golden_test.dart`

**Interfaces:**
- Consumes: `assets/icons/store/currency_bonus_star_candy.png`
- Produces: 아이콘과 “보너스 스타캔디 소멸 시점 안내”가 결합된 기존 보너스 구역 헤더

- [ ] **Step 1: 새 제목과 보너스 통화 아이콘을 찾는 위젯 테스트를 추가한다.**
- [ ] **Step 2: 테스트를 실행해 제목·아이콘 부재로 실패하는지 확인한다.**
- [ ] **Step 3: 기존 보너스 구역 안에서 헤더만 행 형태로 변경하고 새 로컬라이제이션 키를 연결한다.**
- [ ] **Step 4: 위젯·레이아웃 테스트를 실행하고 오버플로가 없는지 확인한다.**
- [ ] **Step 5: 골든 테스트를 실행해 의도된 시각 변경 범위를 확인하고 필요한 골든만 갱신한다.**

### Task 4: 마이페이지 일반 사용자 캔디 배너 제거

**Files:**
- Modify: `picnic_lib/lib/presentation/pages/my_page/my_page.dart`
- Test: `picnic_lib/test/presentation/pages/my_page/my_page_test.dart`
- Test: `picnic_lib/test/presentation/pages/my_page/my_page_render_test.dart`

**Interfaces:**
- Consumes: `UserProfilesModel.isAdmin`
- Produces: 로그인 여부와 무관하게 일반 사용자에게 숨고 관리자에게만 보이는 `StarCandyInfoText`

- [ ] **Step 1: 일반 사용자에게 배너가 없고 관리자에게는 존재하는 테스트를 추가한다.**
- [ ] **Step 2: 테스트를 실행해 일반 사용자 케이스가 실패하는지 확인한다.**
- [ ] **Step 3: 기존 로그인 조건에 관리자 조건을 추가해 배너 노출만 제한한다.**
- [ ] **Step 4: 마이페이지 테스트를 다시 실행해 두 역할이 모두 통과하는지 확인한다.**

### Task 5: 통합 검증

**Files:**
- Verify all modified Dart, ARB, generated localization, and golden files

**Interfaces:**
- Consumes: Tasks 1–4 결과
- Produces: 댓글 5건 전체가 회귀 없이 동작하는 검증 결과

- [ ] **Step 1: `dart format`을 변경된 Dart 파일에 실행한다.**
- [ ] **Step 2: Tasks 1–4의 관련 테스트를 한 명령으로 실행한다.**
- [ ] **Step 3: `flutter analyze`를 실행해 새 오류가 없는지 확인한다.**
- [ ] **Step 4: `git diff --check`와 변경 파일 목록을 확인한다.**
- [ ] **Step 5: 요구사항별 코드·테스트 대응 관계를 최종 리뷰한다.**

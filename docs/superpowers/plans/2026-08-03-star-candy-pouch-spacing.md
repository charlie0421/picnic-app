# Star Candy Pouch Spacing Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 구매 탭, 무료 충전소, 마이페이지의 공통 별사탕 파우치 외부 간격을 승인된 값으로 통일한다.

**Architecture:** `StorePointInfo`는 내부 UI만 소유하고 기본 외부 상단 마진을 갖지 않는다. 각 소비 화면은 파우치 전후에 명시적인 `SizedBox`를 배치해 화면 문맥에 맞는 간격을 소유한다. 위젯 테스트는 공통 기본값과 세 화면의 실제 렌더 좌표 차이를 검증한다.

**Tech Stack:** Flutter, Dart, flutter_test, Riverpod

## Global Constraints

- 파우치 높이, 테두리, 라운드, 내부 패딩, 재화 표시 및 새로고침 동작은 변경하지 않는다.
- 구매 탭은 파우치 전후 16을 적용한다.
- 무료 충전소는 파우치 전후 16을 적용한다.
- 마이페이지는 프로필 뒤 16, 언어 설정 앞 24를 적용한다.
- 마이페이지 로그인/로그아웃 상태의 배치 규칙은 동일하다.

---

### Task 1: 공통 파우치와 세 소비 화면의 외부 간격 명시

**Files:**
- Modify: `picnic_lib/lib/presentation/widgets/vote/store/common/store_point_info.dart`
- Modify: `picnic_lib/lib/presentation/widgets/vote/store/purchase/purchase_star_candy_state.dart`
- Modify: `picnic_lib/lib/presentation/widgets/vote/store/free_charge_station/free_charge_content.dart`
- Modify: `picnic_lib/lib/presentation/pages/my_page/my_page.dart`
- Test: `picnic_lib/test/presentation/widgets/vote/store/common/store_point_info_test.dart`
- Test: `picnic_lib/test/presentation/widgets/vote/store/purchase/purchase_star_candy_state_test.dart`
- Test: `picnic_lib/test/presentation/widgets/vote/store/free_charge_station/free_charge_content_test.dart`
- Test: `picnic_lib/test/presentation/pages/my_page/my_page_render_test.dart`

**Interfaces:**
- Consumes: `StorePointInfo({required String title, double topMargin, ...})`
- Produces: `StorePointInfo.topMargin` 기본값 `0`; 세 화면이 소유하는 명시적 전후 `SizedBox`

- [ ] **Step 1: 공통 컴포넌트 기본값 회귀 테스트 작성**

`store_point_info_test.dart`에서 기본값 기대치를 변경한다.

```dart
expect(widget.topMargin, 0);
```

- [ ] **Step 2: 세 화면 간격 위젯 테스트 작성**

각 기존 화면 테스트에 파우치와 인접 위젯의 렌더 좌표 검증을 추가한다.

```dart
final pouchRect = tester.getRect(find.byType(StorePointInfo));
final previousRect = tester.getRect(previousFinder);
final nextRect = tester.getRect(nextFinder);
expect(pouchRect.top - previousRect.bottom, 16);
expect(nextRect.top - pouchRect.bottom, expectedBottomGap);
```

구매/무료 충전소의 `expectedBottomGap`은 `16`, 마이페이지는 `24`다. 인접 finder는 실제 승인 간격의 경계를 이루는 섹션 위젯을 선택한다.

- [ ] **Step 3: 실패 테스트 확인**

Run:

```bash
cd picnic_lib
flutter test test/presentation/widgets/vote/store/common/store_point_info_test.dart test/presentation/widgets/vote/store/purchase/purchase_star_candy_state_test.dart test/presentation/widgets/vote/store/free_charge_station/free_charge_content_test.dart test/presentation/pages/my_page/my_page_render_test.dart
```

Expected: 기존 기본 마진 20과 화면별 하단 12/8/0 때문에 새 assertion이 FAIL한다.

- [ ] **Step 4: 최소 구현 적용**

공통 기본값:

```dart
this.topMargin = 0,
```

구매 탭:

```dart
const SizedBox(height: 16),
StorePointInfo(...),
const SizedBox(height: 16),
```

무료 충전소에서는 로그인 블록 안에 파우치 전후 16을 둔다. 로그아웃 상태에는 파우치용 간격을 남기지 않는다.

```dart
if (isLogged) ...[
  const SizedBox(height: 16),
  StorePointInfo(...),
  const SizedBox(height: 16),
],
```

마이페이지:

```dart
data != null ? _buildProfile() : _buildNonLogin(),
const SizedBox(height: 16),
StorePointInfo(...),
const SizedBox(height: 24),
```

- [ ] **Step 5: 대상 테스트와 정적 분석 실행**

Run:

```bash
cd picnic_lib
dart format lib/presentation/widgets/vote/store/common/store_point_info.dart lib/presentation/widgets/vote/store/purchase/purchase_star_candy_state.dart lib/presentation/widgets/vote/store/free_charge_station/free_charge_content.dart lib/presentation/pages/my_page/my_page.dart test/presentation/widgets/vote/store/common/store_point_info_test.dart test/presentation/widgets/vote/store/purchase/purchase_star_candy_state_test.dart test/presentation/widgets/vote/store/free_charge_station/free_charge_content_test.dart test/presentation/pages/my_page/my_page_render_test.dart
flutter test test/presentation/widgets/vote/store/common/store_point_info_test.dart test/presentation/widgets/vote/store/purchase/purchase_star_candy_state_test.dart test/presentation/widgets/vote/store/free_charge_station/free_charge_content_test.dart test/presentation/pages/my_page/my_page_render_test.dart
flutter analyze lib/presentation/widgets/vote/store/common/store_point_info.dart lib/presentation/widgets/vote/store/purchase/purchase_star_candy_state.dart lib/presentation/widgets/vote/store/free_charge_station/free_charge_content.dart lib/presentation/pages/my_page/my_page.dart
```

Expected: 모든 대상 테스트 PASS, analyzer `No issues found`.

- [ ] **Step 6: 변경 검토 및 커밋**

```bash
git diff --check
git diff --stat
git add picnic_lib/lib/presentation/widgets/vote/store/common/store_point_info.dart picnic_lib/lib/presentation/widgets/vote/store/purchase/purchase_star_candy_state.dart picnic_lib/lib/presentation/widgets/vote/store/free_charge_station/free_charge_content.dart picnic_lib/lib/presentation/pages/my_page/my_page.dart picnic_lib/test/presentation/widgets/vote/store/common/store_point_info_test.dart picnic_lib/test/presentation/widgets/vote/store/purchase/purchase_star_candy_state_test.dart picnic_lib/test/presentation/widgets/vote/store/free_charge_station/free_charge_content_test.dart picnic_lib/test/presentation/pages/my_page/my_page_render_test.dart
git commit -m "fix(store): normalize candy pouch spacing"
```


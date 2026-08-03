# Admin Currency History Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 마이페이지는 기존 공통 캔디 파우치를 모든 로그인 상태에서 사용하고, 캔디 내역은 관리자만 메뉴와 내용을 볼 수 있게 한다.

**Architecture:** `MyPage`의 개별 `StarCandyInfoText` 분기를 구매 탭·무료충전소가 공유하는 `StorePointInfo`로 교체한다. 메뉴 노출과 `CurrencyHistoryPage` 자체에 각각 관리자 검사를 두어 일반 사용자의 우회 진입에서도 이력 provider가 호출되지 않게 한다.

**Tech Stack:** Flutter, Riverpod, flutter_test

## Global Constraints

- 로그인한 일반 사용자와 관리자는 동일한 `StorePointInfo` 캔디 파우치를 본다.
- 로그아웃 사용자는 동일 모듈의 기존 로그인 유도 UI와 동작을 본다.
- 캔디 내역 메뉴와 페이지 내용은 관리자에게만 허용한다.
- 결제·지갑 데이터·이력 조회 API는 변경하지 않는다.

---

### Task 1: 마이페이지 공통 파우치 및 관리자 메뉴

**Files:**
- Modify: `picnic_lib/lib/presentation/pages/my_page/my_page.dart`
- Test: `picnic_lib/test/presentation/pages/my_page/my_page_render_test.dart`

**Interfaces:**
- Consumes: `StorePointInfo({required String title, ...})`, `AppLocalizations.label_star_candy_pouch`, `UserProfilesModel.isAdmin`
- Produces: 모든 상태에서 동일한 파우치 모듈을 렌더링하고 관리자에게만 캔디 내역 메뉴를 렌더링하는 `MyPage`

- [ ] **Step 1: 실패하는 렌더링 테스트 작성**

  `my_page_render_test.dart`에서 `StorePointInfo`를 import하고 다음 기대값을 추가한다.

  ```dart
  expect(find.byType(StorePointInfo), findsOneWidget);
  expect(find.text('캔디 내역'), findsNothing); // 일반 사용자 및 로그아웃
  expect(find.text('로그인이 필요합니다.'), findsOneWidget); // 로그아웃
  expect(find.text('캔디 내역'), findsOneWidget); // 관리자
  ```

- [ ] **Step 2: 테스트가 실패하는지 확인**

  Run: `flutter test test/presentation/pages/my_page/my_page_render_test.dart`

  Expected: 일반 사용자·로그아웃 상태에서 `StorePointInfo`가 없고, 일반 사용자에게 캔디 내역이 노출되어 실패한다.

- [ ] **Step 3: 공통 모듈로 최소 구현**

  `my_page.dart`에서 `StarCandyInfoText` import와 관리자 전용 배너 분기를 제거하고 다음 위젯을 배치한다.

  ```dart
  StorePointInfo(
    title: AppLocalizations.of(context).label_star_candy_pouch,
    width: double.infinity,
  ),
  ```

  캔디 내역 `PicnicListItem`은 다음 조건 안으로 이동한다.

  ```dart
  if (data?.isAdmin ?? false)
    PicnicListItem(
      leading: AppLocalizations.of(context).wallet_history_title,
      assetPath: 'assets/icons/arrow_right_style=line.svg',
      onTap: () => ref
          .read(navigationInfoProvider.notifier)
          .setCurrentMyPage(const CurrencyHistoryPage()),
    ),
  ```

- [ ] **Step 4: 렌더링 테스트 통과 확인**

  Run: `flutter test test/presentation/pages/my_page/my_page_render_test.dart`

  Expected: PASS

### Task 2: 캔디 내역 직접 접근 차단

**Files:**
- Modify: `picnic_lib/lib/presentation/pages/my_page/currency_history_page.dart`
- Test: `picnic_lib/test/presentation/pages/my_page/currency_history_page_test.dart`

**Interfaces:**
- Consumes: `userInfoProvider`의 `AsyncValue<UserProfilesModel?>`
- Produces: 관리자일 때만 탭과 `currencyHistoryProvider`를 생성하는 `CurrencyHistoryPage`

- [ ] **Step 1: 비관리자 직접 접근 실패 테스트 작성**

  기존 관리자 이력 테스트에는 `userProfile: MockData.userProfile(isAdmin: true)`를 전달한다. 일반 사용자로 페이지를 렌더링하는 테스트를 추가하고 통화 탭이 없으며 repository 호출이 비어 있음을 검증한다.

  ```dart
  expect(find.text('스타캔디'), findsNothing);
  expect(repository.calls, isEmpty);
  ```

- [ ] **Step 2: 테스트가 실패하는지 확인**

  Run: `flutter test test/presentation/pages/my_page/currency_history_page_test.dart`

  Expected: 일반 사용자에게 이력 탭이 노출되고 repository가 호출되어 실패한다.

- [ ] **Step 3: 페이지 수준 관리자 가드 구현**

  `CurrencyHistoryPage.build`에서 사용자를 구독하고 관리자가 아니면 내용을 만들지 않는다.

  ```dart
  final isAdmin =
      ref.watch(userInfoProvider.select((state) => state.value?.isAdmin)) ??
      false;
  if (!isAdmin) return const SizedBox.shrink();
  ```

- [ ] **Step 4: 페이지 접근 테스트 통과 확인**

  Run: `flutter test test/presentation/pages/my_page/currency_history_page_test.dart`

  Expected: PASS

### Task 3: 회귀 검증 및 커밋

**Files:**
- Verify: `picnic_lib/lib/presentation/pages/my_page/my_page.dart`
- Verify: `picnic_lib/lib/presentation/pages/my_page/currency_history_page.dart`
- Verify: `picnic_lib/test/presentation/pages/my_page/my_page_render_test.dart`
- Verify: `picnic_lib/test/presentation/pages/my_page/currency_history_page_test.dart`

**Interfaces:**
- Consumes: Task 1과 Task 2의 구현 및 테스트
- Produces: 정적 분석과 관련 테스트를 통과한 커밋

- [ ] **Step 1: 변경 파일 포맷 적용**

  Run: `dart format lib/presentation/pages/my_page/my_page.dart lib/presentation/pages/my_page/currency_history_page.dart test/presentation/pages/my_page/my_page_render_test.dart test/presentation/pages/my_page/currency_history_page_test.dart`

- [ ] **Step 2: 대상 정적 분석 실행**

  Run: `flutter analyze lib/presentation/pages/my_page/my_page.dart lib/presentation/pages/my_page/currency_history_page.dart test/presentation/pages/my_page/my_page_render_test.dart test/presentation/pages/my_page/currency_history_page_test.dart`

  Expected: No issues found

- [ ] **Step 3: 관련 테스트 함께 실행**

  Run: `flutter test test/presentation/pages/my_page/my_page_render_test.dart test/presentation/pages/my_page/currency_history_page_test.dart`

  Expected: PASS

- [ ] **Step 4: 변경 커밋**

  ```bash
  git add docs/superpowers/specs/2026-07-31-picnic-2232-comment-fixes-design.md \
    docs/superpowers/plans/2026-08-03-admin-currency-history.md \
    picnic_lib/lib/presentation/pages/my_page/my_page.dart \
    picnic_lib/lib/presentation/pages/my_page/currency_history_page.dart \
    picnic_lib/test/presentation/pages/my_page/my_page_render_test.dart \
    picnic_lib/test/presentation/pages/my_page/currency_history_page_test.dart
  git commit -m "fix(mypage): restrict candy history to admins"
  ```

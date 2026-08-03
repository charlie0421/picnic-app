# MyPage Admin Menu Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** MyPage에 흩어진 관리자 전용 항목을 하나의 `관리자` 메뉴와 별도 관리자 페이지로 묶는다.

**Architecture:** MyPage는 관리자 여부에 따라 단일 진입점만 렌더링하고, 실제 관리자 기능은 새 `AdminMenuPage`가 소유한다. 새 페이지는 `userInfoProvider`를 직접 확인해 일반 사용자의 직접 접근도 차단하며, 기존 관리자 기능의 동작은 그대로 이동한다.

**Tech Stack:** Flutter, Riverpod, flutter_test, Google Mobile Ads, 기존 `navigationInfoProvider`

## Global Constraints

- MyPage의 관리자 전용 진입점 라벨은 정확히 `관리자`이다.
- 관리자 페이지에는 `캔디 내역`, `충전 내역`, `Ad Inspector`, `Reset & Reload GDPR` 네 항목만 노출한다.
- `캔디 내역`은 기존 `CurrencyHistoryPage`로 이동한다.
- `충전 내역`은 현재 동작과 동일하게 no-op을 유지한다.
- `Ad Inspector`와 `Reset & Reload GDPR`은 기존 MyPage 구현의 동작과 사용자 메시지를 그대로 유지한다.
- 알림함은 관리자 메뉴로 이동하지 않고 로그인 사용자 공통 메뉴로 유지한다.
- 일반 사용자와 로그아웃 사용자는 MyPage에서 `관리자` 진입점을 볼 수 없다.
- 일반 사용자가 관리자 페이지에 직접 접근하면 상단 제목은 `관리자`, 본문 중앙에는 정확히 `접근 권한이 없습니다.`를 표시한다.
- 앱 버전과 OTA 기준 릴리스는 `1.3.0+130001`이다.

---

### Task 1: 관리자 메뉴 페이지와 MyPage 진입점

**Files:**
- Create: `picnic_lib/lib/presentation/pages/my_page/admin_menu_page.dart`
- Modify: `picnic_lib/lib/presentation/pages/my_page/my_page.dart`
- Create: `picnic_lib/test/presentation/pages/my_page/admin_menu_page_test.dart`
- Modify: `picnic_lib/test/presentation/pages/my_page/my_page_render_test.dart`

**Interfaces:**
- Consumes: `userInfoProvider`, `navigationInfoProvider.notifier.setCurrentMyPage(Widget)`, `navigationInfoProvider.notifier.setMyPageTitle(pageTitle: String)`, `CurrencyHistoryPage`, `PicnicListItem`
- Produces: `const AdminMenuPage()` (`ConsumerStatefulWidget`) and a single MyPage navigation entry labeled `관리자`

- [ ] **Step 1: Write failing MyPage visibility and navigation tests**

Update `my_page_render_test.dart` so the admin case scrolls to `관리자`, asserts exactly one entry, asserts `캔디 내역`, `충전 내역`, `Ad Inspector`, and `Reset & Reload GDPR` are absent from MyPage, taps `관리자`, pumps, and verifies `AdminMenuPage` is selected/rendered. Extend the regular and logged-out cases to scroll through the menu and assert `관리자` is absent.

```dart
expect(find.text('관리자'), findsOneWidget);
expect(find.text('캔디 내역'), findsNothing);
expect(find.text('충전 내역'), findsNothing);
expect(find.text('Ad Inspector'), findsNothing);
expect(find.text('Reset & Reload GDPR'), findsNothing);
await tester.tap(find.text('관리자'));
await pumpAndIgnoreErrors(tester);
expect(find.byType(AdminMenuPage), findsOneWidget);
```

- [ ] **Step 2: Write failing administrator-page tests**

Create `admin_menu_page_test.dart` using `buildTestAppPage` and existing mock helpers. Verify an admin sees exactly the four required entries, tapping `캔디 내역` navigates to `CurrencyHistoryPage`, and a non-admin direct render sees only `접근 권한이 없습니다.` instead of any administrator entry.

```dart
expect(find.text('캔디 내역'), findsOneWidget);
expect(find.text('충전 내역'), findsOneWidget);
expect(find.text('Ad Inspector'), findsOneWidget);
expect(find.text('Reset & Reload GDPR'), findsOneWidget);
await tester.tap(find.text('캔디 내역'));
await pumpAndIgnoreErrors(tester);
expect(find.byType(CurrencyHistoryPage), findsOneWidget);

expect(find.text('접근 권한이 없습니다.'), findsOneWidget);
expect(find.text('캔디 내역'), findsNothing);
```

- [ ] **Step 3: Run the focused tests and confirm the red state**

Run:

```bash
flutter test test/presentation/pages/my_page/my_page_render_test.dart test/presentation/pages/my_page/admin_menu_page_test.dart
```

Expected: FAIL because `AdminMenuPage` and the grouped `관리자` entry do not exist yet.

- [ ] **Step 4: Implement `AdminMenuPage`**

Create a `ConsumerStatefulWidget` that sets the navigation title to `관리자` after the first frame and whenever dependencies/route state require it. Watch `userInfoProvider`; while loading use the existing loading overlay, on error use the project error UI, for non-admin data return a scaffold with centered `Text('접근 권한이 없습니다.')`, and for an admin return a list of exactly four `PicnicListItem` widgets. Move the existing Mobile Ads and GDPR callback bodies from MyPage without changing their behavior or strings.

```dart
class AdminMenuPage extends ConsumerStatefulWidget {
  const AdminMenuPage({super.key});

  @override
  ConsumerState<AdminMenuPage> createState() => _AdminMenuPageState();
}

void _openCurrencyHistory() {
  ref
      .read(navigationInfoProvider.notifier)
      .setCurrentMyPage(const CurrencyHistoryPage());
}
```

- [ ] **Step 5: Replace inline administrator entries in MyPage**

Remove the direct `CurrencyHistoryPage`, charge-history, Ad Inspector, and GDPR list items and their now-unused imports. Add a single admin-only `PicnicListItem` after the normal `설정` entry that navigates to `const AdminMenuPage()`. Keep the notification item unchanged under the logged-in condition.

```dart
if (data?.isAdmin ?? false)
  PicnicListItem(
    leading: '관리자',
    assetPath: 'assets/icons/arrow_right_style=line.svg',
    onTap: () => ref
        .read(navigationInfoProvider.notifier)
        .setCurrentMyPage(const AdminMenuPage()),
  ),
```

- [ ] **Step 6: Format and run focused verification**

Run:

```bash
dart format lib/presentation/pages/my_page/admin_menu_page.dart lib/presentation/pages/my_page/my_page.dart test/presentation/pages/my_page/admin_menu_page_test.dart test/presentation/pages/my_page/my_page_render_test.dart
flutter test test/presentation/pages/my_page/my_page_render_test.dart test/presentation/pages/my_page/admin_menu_page_test.dart
flutter analyze lib/presentation/pages/my_page/admin_menu_page.dart lib/presentation/pages/my_page/my_page.dart test/presentation/pages/my_page/admin_menu_page_test.dart test/presentation/pages/my_page/my_page_render_test.dart
```

Expected: formatter succeeds, all focused tests pass, analyzer reports no issues in the changed files.

- [ ] **Step 7: Commit the implementation**

```bash
git add picnic_lib/lib/presentation/pages/my_page/admin_menu_page.dart picnic_lib/lib/presentation/pages/my_page/my_page.dart picnic_lib/test/presentation/pages/my_page/admin_menu_page_test.dart picnic_lib/test/presentation/pages/my_page/my_page_render_test.dart
git commit -m "feat(mypage): group administrator tools"
```

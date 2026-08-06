# Purchase Reward Breakdown Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 구매 상품 행에서 기본 별사탕과 보너스 별사탕 수량을 각 아이콘과 함께 명확히 표시한다.

**Architecture:** `RewardBreakdown` 공통 위젯이 두 재화의 아이콘·수량·구분자를 렌더링한다. `StoreListTile.subtitle`을 일반 `Widget`으로 확장해 네이티브/웹 구매 페이지가 같은 보상 표시 위젯을 사용할 수 있게 한다. 데이터는 기존 서버 상품의 `star_candy`와 `bonus_star_candy` 필드를 그대로 사용한다.

**Tech Stack:** Flutter, Dart, flutter_test, flutter_screenutil, 기존 `picnic_lib` 화폐 이미지 자산

## Global Constraints

- 기준 별사탕 자산은 `assets/icons/store/currency_star_candy.png`를 사용한다.
- 보너스 별사탕 자산은 `assets/icons/store/currency_bonus_star_candy.png`를 사용한다.
- 보너스 수량이 0이면 보너스 항목과 `+` 구분자를 숨긴다.
- 상품 행 높이와 구매 처리 흐름은 변경하지 않는다.
- 보상 총합만 표시하지 않는다.

---

### Task 1: 공통 보상 표시 위젯

**Files:**
- Create: `picnic_lib/lib/presentation/widgets/vote/store/common/reward_breakdown.dart`
- Test: `picnic_lib/test/presentation/widgets/vote/store/common/reward_breakdown_test.dart`

**Interfaces:**
- Consumes: `baseAmount`, `bonusAmount`, optional icon size.
- Produces: `RewardBreakdown({required int baseAmount, required int bonusAmount, double iconSize = 18})` widget.

- [ ] **Step 1: Write the failing widget tests**

```dart
testWidgets('renders base and bonus amounts with icons', (tester) async {
  await tester.pumpWidget(testApp(const RewardBreakdown(baseAmount: 200, bonusAmount: 25)));
  expect(find.text('200'), findsOneWidget);
  expect(find.text('25'), findsOneWidget);
  expect(find.text('+'), findsOneWidget);
  expect(find.byType(Image), findsNWidgets(2));
});

testWidgets('hides bonus section when amount is zero', (tester) async {
  await tester.pumpWidget(testApp(const RewardBreakdown(baseAmount: 100, bonusAmount: 0)));
  expect(find.text('100'), findsOneWidget);
  expect(find.text('+'), findsNothing);
  expect(find.byType(Image), findsOneWidget);
});
```

- [ ] **Step 2: Run the focused test and verify it fails**

Run: `cd picnic_lib && flutter test test/presentation/widgets/vote/store/common/reward_breakdown_test.dart`

Expected: FAIL because `RewardBreakdown` does not exist.

- [ ] **Step 3: Implement the minimal widget**

Use `RichText` with `WidgetSpan` for the two existing package assets and `TextSpan` for numbers and `+`. Return only the base item when `bonusAmount == 0`.

- [ ] **Step 4: Run the focused test and verify it passes**

Run: `cd picnic_lib && flutter test test/presentation/widgets/vote/store/common/reward_breakdown_test.dart`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add picnic_lib/lib/presentation/widgets/vote/store/common/reward_breakdown.dart picnic_lib/test/presentation/widgets/vote/store/common/reward_breakdown_test.dart
git commit -m "feat(store): add reward breakdown widget"
```

### Task 2: 구매 상품 행에 보상 위젯 연결

**Files:**
- Modify: `picnic_lib/lib/presentation/widgets/vote/store/purchase/store_list_tile.dart`
- Modify: `picnic_lib/lib/presentation/widgets/vote/store/purchase/purchase_star_candy_state.dart`
- Modify: `picnic_lib/lib/presentation/widgets/vote/store/purchase/purchase_star_candy_web_state.dart`
- Test: existing store purchase widget tests covering product rows

**Interfaces:**
- Consumes: `RewardBreakdown` from Task 1 and existing server product maps.
- Produces: native and web purchase rows with icon-based reward breakdowns.

- [ ] **Step 1: Change the subtitle slot from `Text?` to `Widget?`**

Keep the existing layout and spacing; all existing `Text` callers remain source-compatible.

- [ ] **Step 2: Replace purchase descriptions with `RewardBreakdown`**

Read `serverProduct['star_candy']` and `serverProduct['bonus_star_candy']` as integers, with a defensive zero fallback, and pass them to the widget. Keep the product ID as the title and price button unchanged.

- [ ] **Step 3: Add/adjust row assertions**

Assert that a product with `star_candy: 200, bonus_star_candy: 25` renders both amounts and the plus separator, while a zero-bonus product renders only the base amount.

- [ ] **Step 4: Run focused purchase tests**

Run: `cd picnic_lib && flutter test test/presentation/widgets/vote/store/purchase`

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add picnic_lib/lib/presentation/widgets/vote/store/purchase/store_list_tile.dart picnic_lib/lib/presentation/widgets/vote/store/purchase/purchase_star_candy_state.dart picnic_lib/lib/presentation/widgets/vote/store/purchase/purchase_star_candy_web_state.dart picnic_lib/test/presentation/widgets/vote/store/purchase
git commit -m "feat(store): show purchase rewards with currency icons"
```

### Task 3: 디바이스 캡처 및 최종 검증

**Files:**
- Create: `/tmp/picnic-purchase-reward-breakdown.png` (verification artifact only)

- [ ] **Step 1: Run formatting and static checks**

Run: `dart format picnic_lib/lib/presentation/widgets/vote/store/common/reward_breakdown.dart picnic_lib/lib/presentation/widgets/vote/store/purchase/store_list_tile.dart picnic_lib/lib/presentation/widgets/vote/store/purchase/purchase_star_candy_state.dart picnic_lib/lib/presentation/widgets/vote/store/purchase/purchase_star_candy_web_state.dart`

- [ ] **Step 2: Run focused tests and analyze**

Run: `cd picnic_lib && flutter test test/presentation/widgets/vote/store/common/reward_breakdown_test.dart test/presentation/widgets/vote/store/purchase && flutter analyze lib/presentation/widgets/vote/store/common/reward_breakdown.dart lib/presentation/widgets/vote/store/purchase`

- [ ] **Step 3: Launch the purchase screen on the available iOS simulator**

Use the existing local Flutter simulator workflow and capture the purchase list showing one product with `200 + 25` and one product without bonus.

- [ ] **Step 4: Inspect the screenshot**

Confirm both icons align with the numbers, the plus separator is legible, product row height is unchanged, and the price buttons remain aligned.

- [ ] **Step 5: Commit any test-only fixture updates and report the screenshot path**

Do not commit generated screenshots unless they are an existing golden fixture; report `/tmp/picnic-purchase-reward-breakdown.png` to the user.

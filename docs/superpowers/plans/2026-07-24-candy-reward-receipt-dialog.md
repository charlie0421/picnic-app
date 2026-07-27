# Candy Reward Receipt Dialog Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 광고와 구매의 서버 확정 적립 결과를 B 타입 공통 캔디 영수증 팝업으로 표시한다.

**Architecture:** UI와 도메인 응답 사이에 불변 `CandyRewardReceipt` 모델과 광고·구매 어댑터를 둔다. `CandyRewardReceiptDialog`는 정규화된 양수 지급 항목만 렌더링하고, 기존 광고 durable queue 및 구매 검증 흐름은 다이얼로그 표시 시점만 교체한다.

**Tech Stack:** Flutter 3.41.4, Dart 3.11.1, Riverpod, Freezed 기존 wallet DTO, Flutter gen-l10n, intl, flutter_test

## Global Constraints

- 사용자 노출명은 `스타캔디`, `보너스 스타캔디`, `코튼캔디`이며 `솜사탕`을 추가하지 않는다.
- 지급액과 적립 후 잔액은 서버가 확정한 DTO에서만 가져온다.
- 광고는 코튼캔디 한 행, 구매는 지급액이 양수인 스타캔디·보너스 스타캔디 행만 표시한다.
- 한국어 문자열을 Dart 코드에 하드코딩하지 않는다.
- 승인된 `currency_star_candy.png`, `currency_bonus_star_candy.png`, `currency_cotton_candy.png`를 재사용한다.
- 광고 acknowledge는 팝업 첫 프레임 이후 한 번만 실행한다.
- 결제 이벤트만으로 성공 팝업을 열지 않고 서버 구매 검증 완료 이후에만 연다.
- 기존 실패·대기 안내와 결제 중복 방지 상태 머신은 변경하지 않는다.

---

### Task 1: 정규화된 적립 영수증 모델과 어댑터

**Files:**
- Create: `picnic_lib/lib/data/models/wallet/candy_reward_receipt.dart`
- Test: `picnic_lib/test/data/models/wallet/candy_reward_receipt_test.dart`

**Interfaces:**
- Consumes: `AdRewardStatusModel`, `PurchaseSettlementResultModel`, `WalletCurrency`, `WalletSummaryModel`
- Produces:
  - `CandyRewardReceiptItem`
  - `CandyRewardReceipt`
  - `CandyRewardReceipt? receiptFromAdReward(AdRewardStatusModel status)`
  - `CandyRewardReceipt? receiptFromPurchase(PurchaseSettlementResultModel result)`

- [ ] **Step 1: 양수 항목 필터와 서버 snapshot 변환 실패 테스트 작성**

```dart
test('purchase receipt combines positive base and granted promo bonus', () {
  final receipt = receiptFromPurchase(purchaseResult(
    baseStar: BigInt.from(100),
    baseBonus: BigInt.from(20),
    promoBonus: BigInt.from(30),
  ));

  expect(receipt!.referenceKey, 'PURCHASE:operation-1');
  expect(receipt.items, hasLength(2));
  expect(receipt.items[0].currency, WalletCurrency.starCandy);
  expect(receipt.items[0].grantedAmount, BigInt.from(100));
  expect(receipt.items[0].balanceAfter, BigInt.from(500));
  expect(receipt.items[1].currency, WalletCurrency.bonusStarCandy);
  expect(receipt.items[1].grantedAmount, BigInt.from(50));
  expect(receipt.items[1].balanceAfter, BigInt.from(80));
});

test('purchase receipt omits zero-value currencies', () {
  final receipt = receiptFromPurchase(purchaseResult(
    baseStar: BigInt.from(100),
    baseBonus: BigInt.zero,
    promoBonus: BigInt.zero,
  ));
  expect(receipt!.items.map((item) => item.currency), [
    WalletCurrency.starCandy,
  ]);
});

test('ad receipt accepts only a granted positive grant', () {
  expect(receiptFromAdReward(grantedAd(amount: BigInt.one)), isNotNull);
  expect(receiptFromAdReward(deniedAd()), isNull);
});
```

- [ ] **Step 2: 모델 테스트를 실행해 컴파일 실패 확인**

Run:

```bash
cd picnic_lib
flutter test test/data/models/wallet/candy_reward_receipt_test.dart
```

Expected: FAIL because `candy_reward_receipt.dart` and its symbols do not exist.

- [ ] **Step 3: 불변 모델과 통화별 잔액 선택 구현**

```dart
@immutable
class CandyRewardReceiptItem {
  CandyRewardReceiptItem({
    required this.currency,
    required this.grantedAmount,
    required this.balanceAfter,
    this.expiresAt,
  }) : assert(grantedAmount > BigInt.zero);

  final WalletCurrency currency;
  final BigInt grantedAmount;
  final BigInt? balanceAfter;
  final DateTime? expiresAt;
}

@immutable
class CandyRewardReceipt {
  CandyRewardReceipt({
    required this.referenceKey,
    required this.items,
    this.supportingMessageKey,
  }) : assert(items.length > 0);

  final String referenceKey;
  final List<CandyRewardReceiptItem> items;
  final String? supportingMessageKey;
}

BigInt _balanceFor(WalletSummaryModel wallet, WalletCurrency currency) =>
    switch (currency) {
      WalletCurrency.starCandy => wallet.star,
      WalletCurrency.bonusStarCandy => wallet.bonus,
      WalletCurrency.cottonCandy => wallet.cotton,
    };
```

- [ ] **Step 4: 광고와 구매 어댑터 구현**

```dart
CandyRewardReceipt? receiptFromAdReward(AdRewardStatusModel status) {
  final grant = status.grant;
  if (status.state != AdRewardState.granted ||
      grant == null ||
      grant.amount <= BigInt.zero) {
    return null;
  }
  return CandyRewardReceipt(
    referenceKey:
        'AD:${status.reference.type.wireValue}:${status.reference.id}:${grant.id}',
    items: [
      CandyRewardReceiptItem(
        currency: grant.currency,
        grantedAmount: grant.amount,
        balanceAfter: _balanceFor(status.wallet, grant.currency),
        expiresAt: grant.currency == WalletCurrency.cottonCandy
            ? grant.expiresAt
            : null,
      ),
    ],
  );
}

CandyRewardReceipt? receiptFromPurchase(PurchaseSettlementResultModel result) {
  final promo = result.promotion;
  final promoBonus = promo?.state == PurchasePromotionState.granted
      ? promo!.promoBonusAmount
      : BigInt.zero;
  final candidates = [
    (WalletCurrency.starCandy, result.baseStarAmount),
    (
      WalletCurrency.bonusStarCandy,
      result.baseBonusAmount + promoBonus,
    ),
  ];
  final items = candidates
      .where((entry) => entry.$2 > BigInt.zero)
      .map((entry) => CandyRewardReceiptItem(
            currency: entry.$1,
            grantedAmount: entry.$2,
            balanceAfter: _balanceFor(result.wallet, entry.$1),
          ))
      .toList(growable: false);
  if (items.isEmpty) return null;
  return CandyRewardReceipt(
    referenceKey: 'PURCHASE:${result.operationId}',
    items: items,
  );
}
```

- [ ] **Step 5: 모델 테스트 통과 확인**

Run:

```bash
cd picnic_lib
flutter test test/data/models/wallet/candy_reward_receipt_test.dart
```

Expected: PASS.

- [ ] **Step 6: 모델과 테스트 커밋**

```bash
git add picnic_lib/lib/data/models/wallet/candy_reward_receipt.dart picnic_lib/test/data/models/wallet/candy_reward_receipt_test.dart
git commit -m "feat(wallet): normalize candy reward receipts"
```

---

### Task 2: 국제화된 B 타입 공통 영수증 UI

**Files:**
- Create: `picnic_lib/lib/presentation/dialogs/candy_reward_receipt_dialog.dart`
- Modify: `picnic_lib/lib/l10n/app_en.arb`
- Modify: `picnic_lib/lib/l10n/app_ko.arb`
- Regenerate: `picnic_lib/lib/l10n/app_localizations.dart`
- Regenerate: `picnic_lib/lib/l10n/app_localizations_en.dart`
- Regenerate: `picnic_lib/lib/l10n/app_localizations_ko.dart`
- Regenerate: other `picnic_lib/lib/l10n/app_localizations_*.dart` files selected by the existing l10n configuration
- Test: `picnic_lib/test/presentation/dialogs/candy_reward_receipt_dialog_test.dart`

**Interfaces:**
- Consumes: `CandyRewardReceipt`, `CandyRewardReceiptItem`, existing wallet currency icon assets
- Produces:
  - `CandyRewardReceiptDialog({required CandyRewardReceipt receipt, String? supportingMessage})`
  - `Future<void> showCandyRewardReceiptDialog(BuildContext context, CandyRewardReceipt receipt, {String? supportingMessage})`

- [ ] **Step 1: 한국어·영어, 0원 제거 결과, 큰 글꼴 위젯 테스트 작성**

```dart
testWidgets('renders Korean multi-currency receipt with approved assets', (
  tester,
) async {
  await tester.pumpWidget(localizedApp(
    locale: const Locale('ko'),
    child: CandyRewardReceiptDialog(receipt: purchaseReceipt),
  ));

  expect(find.text('캔디가 적립됐어요!'), findsOneWidget);
  expect(find.text('스타캔디'), findsOneWidget);
  expect(find.text('보너스 스타캔디'), findsOneWidget);
  expect(find.text('+1,000'), findsOneWidget);
  expect(find.byKey(const Key('reward-icon-STAR_CANDY')), findsOneWidget);
  expect(find.byKey(const Key('reward-icon-BONUS_STAR_CANDY')), findsOneWidget);
});

testWidgets('uses English localization and survives 2x text scale', (
  tester,
) async {
  tester.view.physicalSize = const Size(640, 960);
  tester.view.devicePixelRatio = 1;
  await tester.pumpWidget(localizedApp(
    locale: const Locale('en'),
    textScaler: const TextScaler.linear(2),
    child: CandyRewardReceiptDialog(receipt: cottonReceipt),
  ));

  expect(find.text('Candy added!'), findsOneWidget);
  expect(find.text('Cotton Candy'), findsOneWidget);
  expect(tester.takeException(), isNull);
});
```

- [ ] **Step 2: 위젯 테스트를 실행해 미구현 실패 확인**

Run:

```bash
cd picnic_lib
flutter test test/presentation/dialogs/candy_reward_receipt_dialog_test.dart
```

Expected: FAIL because the dialog and localization getters do not exist.

- [ ] **Step 3: ARB 메시지와 placeholder metadata 추가**

`app_en.arb`:

```json
"candy_reward_receipt_title": "Candy added!",
"candy_reward_receipt_confirm": "Confirm",
"candy_reward_receipt_amount": "+{amount}",
"@candy_reward_receipt_amount": {
  "placeholders": {"amount": {"type": "String"}}
},
"candy_reward_receipt_balance": "Current balance {amount}",
"@candy_reward_receipt_balance": {
  "placeholders": {"amount": {"type": "String"}}
},
"candy_reward_receipt_balance_unavailable": "Balance will refresh shortly",
"candy_reward_receipt_expiry": "Expires {date}",
"@candy_reward_receipt_expiry": {
  "placeholders": {"date": {"type": "String"}}
},
"candy_reward_receipt_semantics": "{currency}, added {granted}, current balance {balance}",
"@candy_reward_receipt_semantics": {
  "placeholders": {
    "currency": {"type": "String"},
    "granted": {"type": "String"},
    "balance": {"type": "String"}
  }
}
```

`app_ko.arb`:

```json
"candy_reward_receipt_title": "캔디가 적립됐어요!",
"candy_reward_receipt_confirm": "확인",
"candy_reward_receipt_amount": "+{amount}",
"@candy_reward_receipt_amount": {
  "placeholders": {"amount": {"type": "String"}}
},
"candy_reward_receipt_balance": "현재 보유 {amount}",
"@candy_reward_receipt_balance": {
  "placeholders": {"amount": {"type": "String"}}
},
"candy_reward_receipt_balance_unavailable": "잔액은 잠시 후 갱신돼요",
"candy_reward_receipt_expiry": "{date} 만료",
"@candy_reward_receipt_expiry": {
  "placeholders": {"date": {"type": "String"}}
},
"candy_reward_receipt_semantics": "{currency}, {granted} 적립, 현재 보유 {balance}",
"@candy_reward_receipt_semantics": {
  "placeholders": {
    "currency": {"type": "String"},
    "granted": {"type": "String"},
    "balance": {"type": "String"}
  }
}
```

- [ ] **Step 4: localization 코드 생성**

Run:

```bash
cd picnic_lib
flutter gen-l10n
```

Expected: exit 0 and all configured generated locale classes compile.

- [ ] **Step 5: 통화별 표현과 locale-aware 포맷 helper 구현**

```dart
String _currencyLabel(AppLocalizations l10n, WalletCurrency currency) =>
    switch (currency) {
      WalletCurrency.starCandy => l10n.wallet_star_candy,
      WalletCurrency.bonusStarCandy => l10n.wallet_bonus_star_candy,
      WalletCurrency.cottonCandy => l10n.wallet_cotton_candy,
    };

String _currencyAsset(WalletCurrency currency) => switch (currency) {
  WalletCurrency.starCandy =>
    'assets/icons/store/currency_star_candy.png',
  WalletCurrency.bonusStarCandy =>
    'assets/icons/store/currency_bonus_star_candy.png',
  WalletCurrency.cottonCandy =>
    'assets/icons/store/currency_cotton_candy.png',
};

String _formatAmount(BuildContext context, BigInt amount) =>
    NumberFormat.decimalPattern(
      Localizations.localeOf(context).toLanguageTag(),
    ).format(amount);

String _formatExpiry(BuildContext context, DateTime value) =>
    DateFormat.yMd(
      Localizations.localeOf(context).toLanguageTag(),
    ).add_Hm().format(value.toLocal());
```

- [ ] **Step 6: B 타입 다이얼로그 구현**

```dart
class CandyRewardReceiptDialog extends StatelessWidget {
  const CandyRewardReceiptDialog({
    super.key,
    required this.receipt,
    this.supportingMessage,
  });

  final CandyRewardReceipt receipt;
  final String? supportingMessage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360, maxHeight: 560),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.candy_reward_receipt_title),
              const SizedBox(height: 18),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: receipt.items
                        .map((item) => CandyRewardReceiptRow(item: item))
                        .toList(growable: false),
                  ),
                ),
              ),
              if (supportingMessage != null) Text(supportingMessage!),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.candy_reward_receipt_confirm),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

`CandyRewardReceiptRow`는 아이콘, 재화명, `+지급량`, 현재 잔액과 선택적
만료 일시를 한 semantics node로 묶는다. 아이콘은 `excludeFromSemantics:
true`로 중복 낭독을 막는다.

- [ ] **Step 7: 국제화와 반응형 위젯 테스트 통과 확인**

Run:

```bash
cd picnic_lib
flutter test test/presentation/dialogs/candy_reward_receipt_dialog_test.dart
flutter analyze lib/presentation/dialogs/candy_reward_receipt_dialog.dart
```

Expected: all tests PASS and analyzer reports `No issues found!`.

- [ ] **Step 8: 공통 UI와 국제화 커밋**

```bash
git add picnic_lib/lib/presentation/dialogs/candy_reward_receipt_dialog.dart picnic_lib/lib/l10n picnic_lib/test/presentation/dialogs/candy_reward_receipt_dialog_test.dart
git commit -m "feat(wallet): add localized reward receipt dialog"
```

---

### Task 3: 광고 보상 팝업을 공통 영수증으로 전환

**Files:**
- Modify: `picnic_lib/lib/presentation/widgets/ad_reward_dialog_host.dart`
- Modify: `picnic_lib/test/presentation/widgets/ad_reward_dialog_host_test.dart`

**Interfaces:**
- Consumes: `receiptFromAdReward`, `CandyRewardReceiptDialog`
- Preserves: `AdRewardDialogHost` queue ownership checks and `acknowledgeAfterRender`
- Produces: granted 광고에는 공통 영수증, denied/expired에는 기존 실패 안내

- [ ] **Step 1: granted 광고의 B 타입 UI와 첫 프레임 ACK 테스트 추가**

```dart
testWidgets('granted reward renders receipt and acknowledges once', (
  tester,
) async {
  repository.statusCompleter.complete(granted());
  await recovery;
  await tester.pumpWidget(app(container));
  await tester.pump();
  await tester.pump();

  expect(find.text('Candy added!'), findsOneWidget);
  expect(find.text('Cotton Candy'), findsOneWidget);
  expect(find.text('+1'), findsOneWidget);
  expect(repository.acknowledged, [reference]);
});
```

- [ ] **Step 2: 광고 host 테스트가 기존 AlertDialog 구현에서 실패하는지 확인**

Run:

```bash
cd picnic_lib
flutter test test/presentation/widgets/ad_reward_dialog_host_test.dart
```

Expected: new B-type assertions FAIL while existing ownership/ACK tests remain PASS.

- [ ] **Step 3: granted body를 공통 영수증으로 위임**

```dart
@override
Widget build(BuildContext context) {
  final receipt = receiptFromAdReward(widget.status);
  if (receipt != null) {
    return CandyRewardReceiptDialog(receipt: receipt);
  }
  return AlertDialog(
    title: Text(AppLocalizations.of(context).ad_reward_not_granted),
    content: Text(widget.status.state.name.toUpperCase()),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(AppLocalizations.of(context).confirm),
      ),
    ],
  );
}
```

`AdRewardDialogBody.initState`와 `onFirstFrame` 호출은 그대로 두어 렌더링 후
acknowledge 의미를 보존한다.

- [ ] **Step 4: 광고 복구·소유권·중복 ACK 전체 테스트 실행**

Run:

```bash
cd picnic_lib
flutter test test/presentation/widgets/ad_reward_dialog_host_test.dart
flutter test test/presentation/providers/ad_reward_recovery_provider_test.dart
```

Expected: all tests PASS.

- [ ] **Step 5: 광고 전환 커밋**

```bash
git add picnic_lib/lib/presentation/widgets/ad_reward_dialog_host.dart picnic_lib/test/presentation/widgets/ad_reward_dialog_host_test.dart
git commit -m "feat(ads): present cotton reward receipts"
```

---

### Task 4: 구매 성공 팝업을 다중 재화 영수증으로 전환

**Files:**
- Modify: `picnic_lib/lib/presentation/widgets/vote/store/purchase/handlers/purchase_dialog_handler.dart`
- Modify: `picnic_lib/test/presentation/widgets/vote/store/purchase/handlers/purchase_dialog_handler_test.dart`
- Modify: `picnic_lib/test/presentation/widgets/vote/store/purchase/purchase_campaign_attempt_test.dart`

**Interfaces:**
- Consumes: `receiptFromPurchase`, `showCandyRewardReceiptDialog`
- Preserves:
  - `PurchaseSettlementPresentation.present`
  - `showSuccessDialog` and `showLatePurchaseSuccessDialog` signatures
  - purchase attempt captured campaign and verified settlement ordering
- Produces: 서버 확정 지급액이 양수인 재화만 포함한 공통 영수증

- [ ] **Step 1: 구매 어댑터 전달과 일반·프로모션 표시 테스트 추가**

```dart
test('normal purchase receipt contains only positive star reward', () {
  final receipt = receiptFromPurchase(result(
    baseStarAmount: BigInt.from(100),
    baseBonusAmount: BigInt.zero,
  ));
  expect(receipt!.items.map((item) => item.currency), [
    WalletCurrency.starCandy,
  ]);
});

test('promotion receipt combines base and promo bonus from server', () {
  final receipt = receiptFromPurchase(result(
    baseStarAmount: BigInt.from(100),
    baseBonusAmount: BigInt.from(20),
    promotionState: PurchasePromotionState.granted,
    promoBonusAmount: BigInt.from(30),
  ));
  expect(
    receipt!.items.singleWhere(
      (item) => item.currency == WalletCurrency.bonusStarCandy,
    ).grantedAmount,
    BigInt.from(50),
  );
});
```

- [ ] **Step 2: 구매 관련 테스트를 실행해 기존 문자열 다이얼로그와 불일치 확인**

Run:

```bash
cd picnic_lib
flutter test test/presentation/widgets/vote/store/purchase/handlers/purchase_dialog_handler_test.dart
flutter test test/presentation/widgets/vote/store/purchase/purchase_campaign_attempt_test.dart
```

Expected: receipt presentation assertions FAIL.

- [ ] **Step 3: 성공 다이얼로그를 공통 영수증으로 교체**

```dart
Future<void> showSuccessDialog({
  required PurchaseSettlementResultModel result,
  required ActivePromotionCampaignModel? displayedCampaign,
}) async {
  final context = navigatorKey.currentContext;
  if (context == null) return;
  final receipt = receiptFromPurchase(result);
  if (receipt == null) return;
  final checking =
      result.promotion?.state == PurchasePromotionState.pendingTime ||
      result.promotion?.state == PurchasePromotionState.eligible;
  await showCandyRewardReceiptDialog(
    context,
    receipt,
    supportingMessage: checking
        ? AppLocalizations.of(context).candy_boost_promotion_checking
        : null,
  );
}
```

`showLatePurchaseSuccessDialog`도 같은 receipt를 사용하되 기존
`candy_boost_late_purchase_explanation`을 `supportingMessage`로 전달한다.
서버 결과의 `baseStarAmount`, `baseBonusAmount`, `promotion`과 `wallet`
외의 상품 설명 또는 화면 캠페인 예상값은 금액 계산에 사용하지 않는다.

- [ ] **Step 4: 성공 팝업 Future를 await하는 계약과 한 번 표시 검증**

`purchase_campaign_attempt_test.dart`에서 동일 immutable result가
`showSuccess` 또는 `showLateSuccess` 중 정확히 하나에 전달되고 호출 Future가
완료될 때까지 `present`가 완료되지 않는 기존 테스트를 유지한다. 정상과 late
각각 한 번 호출되는 케이스를 명시한다.

- [ ] **Step 5: 구매 관련 테스트 통과 확인**

Run:

```bash
cd picnic_lib
flutter test test/presentation/widgets/vote/store/purchase/handlers/purchase_dialog_handler_test.dart
flutter test test/presentation/widgets/vote/store/purchase/purchase_campaign_attempt_test.dart
flutter test test/presentation/widgets/vote/store/purchase/purchase_star_candy_state_test.dart
```

Expected: all tests PASS; 서버 검증 이전 결제 이벤트는 성공 팝업을 열지 않는다.

- [ ] **Step 6: 구매 전환 커밋**

```bash
git add picnic_lib/lib/presentation/widgets/vote/store/purchase/handlers/purchase_dialog_handler.dart picnic_lib/test/presentation/widgets/vote/store/purchase/handlers/purchase_dialog_handler_test.dart picnic_lib/test/presentation/widgets/vote/store/purchase/purchase_campaign_attempt_test.dart
git commit -m "feat(store): present multi-candy purchase receipts"
```

---

### Task 5: 통합 회귀와 시뮬레이터 검증

**Files:**
- Modify only if a test exposes a defect in files already listed above.

**Interfaces:**
- Verifies: common receipt model, localized UI, ad queue ACK, purchase settlement presentation
- Produces: staging-ready app changes without production Supabase mutation

- [ ] **Step 1: formatter와 localization 생성 상태 검증**

Run:

```bash
cd picnic_lib
dart format --output=none --set-exit-if-changed \
  lib/data/models/wallet/candy_reward_receipt.dart \
  lib/presentation/dialogs/candy_reward_receipt_dialog.dart \
  lib/presentation/widgets/ad_reward_dialog_host.dart \
  lib/presentation/widgets/vote/store/purchase/handlers/purchase_dialog_handler.dart \
  test/data/models/wallet/candy_reward_receipt_test.dart \
  test/presentation/dialogs/candy_reward_receipt_dialog_test.dart \
  test/presentation/widgets/ad_reward_dialog_host_test.dart \
  test/presentation/widgets/vote/store/purchase/handlers/purchase_dialog_handler_test.dart
flutter gen-l10n
git diff --exit-code -- lib/l10n
```

Expected: format check exits 0; regenerating localization produces no additional diff.

- [ ] **Step 2: 관련 전체 테스트 실행**

Run:

```bash
cd picnic_lib
flutter test \
  test/data/models/wallet/candy_reward_receipt_test.dart \
  test/presentation/dialogs/candy_reward_receipt_dialog_test.dart \
  test/presentation/widgets/ad_reward_dialog_host_test.dart \
  test/presentation/providers/ad_reward_recovery_provider_test.dart \
  test/presentation/widgets/vote/store/purchase/handlers/purchase_dialog_handler_test.dart \
  test/presentation/widgets/vote/store/purchase/purchase_campaign_attempt_test.dart \
  test/presentation/widgets/vote/store/purchase/purchase_star_candy_state_test.dart
```

Expected: all tests PASS.

- [ ] **Step 3: 변경 파일 정적 분석**

Run:

```bash
cd picnic_lib
flutter analyze \
  lib/data/models/wallet/candy_reward_receipt.dart \
  lib/presentation/dialogs/candy_reward_receipt_dialog.dart \
  lib/presentation/widgets/ad_reward_dialog_host.dart \
  lib/presentation/widgets/vote/store/purchase/handlers/purchase_dialog_handler.dart
```

Expected: `No issues found!`.

- [ ] **Step 4: 스테이징 시뮬레이터 광고 적립 검증**

1. 스테이징 환경으로 앱을 실행한다.
2. 내부 광고 한 건을 끝까지 시청한다.
3. B 타입 팝업에 코튼캔디 한 행, `+1`, 서버 잔액과 만료 안내가 표시되는지 확인한다.
4. 확인 후 지갑 패널 잔액이 팝업과 같은지 확인한다.
5. 앱을 background/resume하고 동일 grant 팝업이 다시 나타나지 않는지 확인한다.

Expected: 한 번의 적립, 한 번의 팝업, 팝업과 지갑의 동일 잔액.

- [ ] **Step 5: 스테이징 sandbox 구매 검증**

1. 보너스가 없는 상품을 구매해 스타캔디 한 행만 표시되는지 확인한다.
2. 활성 프로모션 상품을 구매해 스타캔디와 보너스 스타캔디 두 행이 표시되는지 확인한다.
3. 두 행의 지급량과 적립 후 잔액을 settlement 로그 및 지갑 패널과 대조한다.
4. 결제 callback이 재전달돼도 성공 팝업이 다시 뜨지 않는지 확인한다.

Expected: 양수 지급 항목만 표시되고 서버 settlement와 UI 값이 일치한다.

- [ ] **Step 6: 최종 검증 결과 커밋**

검증 중 코드 변경이 있었다면 해당 파일과 테스트만 추가한다.

```bash
git status --short
git diff --check
git commit -m "test(wallet): verify reward receipt flows"
git push
```

Expected: 기존 사용자 변경 파일과 `.superpowers/`, `.playwright-cli/`,
`output/` 산출물은 커밋하지 않는다.

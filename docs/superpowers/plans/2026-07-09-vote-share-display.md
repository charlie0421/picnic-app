# 투표 상세 점유율(%) 표시 + 2위 갭 말풍선 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 진행 중인 투표 상세 리스트에서 원시 득표수를 점유율(%)로 바꾸고, 2위 행에 "1위와 N표 차이!" 말풍선을 진입 시 1회만 띄운다.

**Architecture:** 순수 로직은 전부 `VoteDetailHelper` 의 static 메서드로 넣어 위젯 없이 테스트한다. 말풍선은 재사용 가능한 `VoteGapTooltip` 위젯으로 분리하되, **수명(언제 뜨고 언제 영원히 죽는가)은 `_VoteDetailPageState` 가 소유**한다. 행 위젯(`VoteItemWidget`, `VoteItemHighlightWidget`)의 시그니처는 건드리지 않고, 페이지가 반환값을 `Stack` 으로 감싸기만 한다.

**Tech Stack:** Flutter, Riverpod, `animated_digit` ^3.2.3, `flutter_screenutil`, gen-l10n (ARB), `flutter_test`

**설계 문서:** `docs/superpowers/specs/2026-07-09-vote-share-display-design.html`

## Global Constraints

- 작업 디렉터리는 워크트리 `~/Repositories/picnic-app-vote-share`, 브랜치 `feat/vote-share-display`.
- Flutter 명령은 전부 `picnic_lib/` 에서 실행한다 (`l10n.yaml` 과 `pubspec.yaml` 이 거기 있다).
- **종료된 투표(`isEnded == true`)의 표시는 절대 바꾸지 않는다.** 상세 리스트·캡처 이미지·목록 카드 포디움 모두 기존 `NumberFormat('#,###')` 득표수를 유지한다.
- 다음 파일은 **건드리지 않는다**: `vote_item_widget.dart`, `vote_item_highlight_widget.dart`, `vote_gain_indicator.dart`, `vote_detail_achieve_page.dart`, `vote_info_card_vertical.dart`.
- `VoteGainIndicator`(`+N` 팝)와 순위 변동 배경 플래시는 **유지**한다. 지우면 `vote_gain_indicator_test.dart` / `vote_detail_page_test.dart` / `vote_detail_page_render_test.dart` 세 파일이 top-level import 때문에 컴파일 자체가 깨진다.
- l10n 키 이름은 정확히 `text_vote_gap_behind_leader`, placeholder 이름은 정확히 `gap`, 타입은 `String`.
- 점유율 표기 규칙: 유효숫자 2자리 보장, 소수 자릿수 2~4 클램프. `votes <= 0` 또는 `total <= 0` → `—` (U+2014 EM DASH). `0 < pct < 0.0001` → `<0.0001%`.
- 말풍선 문구의 `{gap}` 은 **원시 표 차이**(`1위 득표수 − 2위 득표수`)를 `NumberFormat('#,###')` 로 미리 포맷한 문자열이다. 점유율이 아니다.
- 테스트에서 `VoteDetailPage` 를 마운트한 채 `pumpAndSettle` 을 쓰면 안 된다. 페이지의 1초 주기 `Timer` 때문에 영원히 settle 되지 않는다.

## File Structure

| 파일 | 책임 |
|---|---|
| `picnic_lib/lib/presentation/pages/vote/vote_detail_helper.dart` | 순수 로직. 점유율 포맷, 자릿수 결정, 합계, 말풍선 대상 선정. 위젯 의존성 없음 |
| `picnic_lib/lib/presentation/pages/vote/vote_gap_tooltip.dart` | **신규.** 1회 재생 후 자기 자신을 트리에서 제거하는 말풍선 위젯 + 꼬리 페인터 |
| `picnic_lib/lib/presentation/pages/vote/vote_detail_page.dart` | 배선. 합계 계산, 말풍선 수명 소유, 라벨 분기 |
| `picnic_lib/lib/l10n/app_*.arb` (14개) | 말풍선 문구 |
| `picnic_lib/test/presentation/pages/vote/vote_detail_helper_test.dart` | 순수 로직 테스트 (기존 파일에 group 2개 추가) |
| `picnic_lib/test/presentation/pages/vote/vote_gap_tooltip_test.dart` | **신규.** 말풍선 1회 재생 + 자기 제거 + 타이머 정리 |

> 스펙에는 위젯 이름이 `_GapTooltip` 으로 적혀 있으나, `vote_detail_page.dart` 에서 참조해야 하므로 **public `VoteGapTooltip`** 으로 만든다. 핸드오프의 rankitten 원본은 같은 파일 안에 있어서 private 이었다.

---

### Task 1: 점유율 포맷 + 합계 (`VoteDetailHelper`)

**Files:**
- Modify: `picnic_lib/lib/presentation/pages/vote/vote_detail_helper.dart`
- Test: `picnic_lib/test/presentation/pages/vote/vote_detail_helper_test.dart`

**Interfaces:**
- Consumes: `VoteItemModel` (from `picnic_lib/data/models/vote/vote.dart`), 필드 `int id`, `int? voteTotal`
- Produces:
  - `static int VoteDetailHelper.sharePercentDecimals(double pct)` — 렌더링에 쓸 소수 자릿수 (2~4)
  - `static String VoteDetailHelper.formatSharePercent(int? votes, int total)` — `'35.20%'` / `'<0.0001%'` / `'—'`
  - `static int VoteDetailHelper.sumVoteTotals(List<VoteItemModel?> items)`

- [ ] **Step 1: 실패하는 테스트를 쓴다**

`test/presentation/pages/vote/vote_detail_helper_test.dart` 의 **맨 끝**, 마지막 `}` (main 의 닫는 중괄호) **직전**에 아래 두 group 을 붙여넣는다. 파일 상단의 `_item` 팩토리를 그대로 쓴다.

```dart
  // ── formatSharePercent / sharePercentDecimals ────────────────────────

  group('sharePercentDecimals', () {
    test('clamps to 2 for values >= 1', () {
      expect(VoteDetailHelper.sharePercentDecimals(35.1972), 2);
      expect(VoteDetailHelper.sharePercentDecimals(100.0), 2);
      expect(VoteDetailHelper.sharePercentDecimals(1.0), 2);
    });

    test('keeps 2 decimals down to 0.1', () {
      expect(VoteDetailHelper.sharePercentDecimals(0.1790), 2);
    });

    test('widens to 3 decimals below 0.1', () {
      expect(VoteDetailHelper.sharePercentDecimals(0.0763), 3);
    });

    test('widens to 4 decimals below 0.01', () {
      expect(VoteDetailHelper.sharePercentDecimals(0.0032), 4);
    });

    test('clamps to 4 for very small values', () {
      expect(VoteDetailHelper.sharePercentDecimals(0.00001), 4);
    });
  });

  group('formatSharePercent', () {
    test('formats the leader with two decimals', () {
      expect(VoteDetailHelper.formatSharePercent(711479, 2021408), '35.20%');
    });

    test('keeps two significant digits as the value shrinks', () {
      expect(VoteDetailHelper.formatSharePercent(1790, 1000000), '0.18%');
      expect(VoteDetailHelper.formatSharePercent(763, 1000000), '0.076%');
      expect(VoteDetailHelper.formatSharePercent(32, 1000000), '0.0032%');
    });

    test('rounds rather than truncates', () {
      // 35.199% -> 35.20%, not 35.19%
      expect(VoteDetailHelper.formatSharePercent(35199, 100000), '35.20%');
    });

    test('shows a floor marker below 0.0001%', () {
      expect(VoteDetailHelper.formatSharePercent(1, 2891788), '<0.0001%');
    });

    test('shows an em dash for zero votes', () {
      expect(VoteDetailHelper.formatSharePercent(0, 1000), '—');
    });

    test('shows an em dash for null votes', () {
      expect(VoteDetailHelper.formatSharePercent(null, 1000), '—');
    });

    test('shows an em dash when the total is zero', () {
      expect(VoteDetailHelper.formatSharePercent(0, 0), '—');
      expect(VoteDetailHelper.formatSharePercent(10, 0), '—');
    });

    test('renders a single-item vote as 100.00%', () {
      expect(VoteDetailHelper.formatSharePercent(500, 500), '100.00%');
    });
  });

  group('sumVoteTotals', () {
    test('returns 0 for an empty list', () {
      expect(VoteDetailHelper.sumVoteTotals([]), 0);
    });

    test('treats null items and null voteTotal as 0', () {
      final items = [_item(id: 1, voteTotal: 10), null, _item(id: 2, voteTotal: null)];
      expect(VoteDetailHelper.sumVoteTotals(items), 10);
    });

    test('sums every item', () {
      final items = [
        _item(id: 1, voteTotal: 100),
        _item(id: 2, voteTotal: 250),
        _item(id: 3, voteTotal: 1),
      ];
      expect(VoteDetailHelper.sumVoteTotals(items), 351);
    });
  });
```

- [ ] **Step 2: 실패하는지 확인한다**

```bash
cd ~/Repositories/picnic-app-vote-share/picnic_lib
flutter test test/presentation/pages/vote/vote_detail_helper_test.dart
```

Expected: 컴파일 실패. `The method 'sharePercentDecimals' isn't defined for the type 'VoteDetailHelper'.` (그리고 `formatSharePercent`, `sumVoteTotals` 도 동일)

- [ ] **Step 3: 최소 구현을 넣는다**

`lib/presentation/pages/vote/vote_detail_helper.dart` 의 **첫 줄**에 import 를 추가한다:

```dart
import 'dart:math' as math;
```

그리고 `class VoteDetailHelper` 안, `computeRanks` 메서드 **바로 앞**에 아래를 넣는다:

```dart
  /// Fraction digits used to render [pct] as a percentage string.
  ///
  /// Two significant digits, clamped to 2..4. picnic votes are extremely
  /// top-heavy — the top three candidates hold 90%+ and everyone below rank 4
  /// falls off a cliff — so a fixed two-decimal format collapses most of the
  /// list to "0.00%".
  static int sharePercentDecimals(double pct) {
    if (pct <= 0) return 2;
    final magnitude = (math.log(pct) / math.ln10).floor();
    return (2 - magnitude - 1).clamp(2, 4);
  }

  /// Format [votes] as a share of [total].
  ///
  /// Returns an em dash when there is nothing to show, and a floor marker
  /// rather than a string of zeros for vanishingly small shares.
  static String formatSharePercent(int? votes, int total) {
    final v = votes ?? 0;
    if (v <= 0 || total <= 0) return '—';

    final pct = v / total * 100;
    if (pct < 0.0001) return '<0.0001%';

    return '${pct.toStringAsFixed(sharePercentDecimals(pct))}%';
  }

  /// Sum of every item's voteTotal. Null items and null totals count as 0.
  static int sumVoteTotals(List<VoteItemModel?> items) {
    var sum = 0;
    for (final item in items) {
      sum += item?.voteTotal ?? 0;
    }
    return sum;
  }
```

- [ ] **Step 4: 통과하는지 확인한다**

```bash
cd ~/Repositories/picnic-app-vote-share/picnic_lib
flutter test test/presentation/pages/vote/vote_detail_helper_test.dart
```

Expected: `All tests passed!` — 기존 computeRanks/getFilteredIndices 등 group 도 전부 통과해야 한다.

- [ ] **Step 5: 커밋**

```bash
cd ~/Repositories/picnic-app-vote-share
git add picnic_lib/lib/presentation/pages/vote/vote_detail_helper.dart \
        picnic_lib/test/presentation/pages/vote/vote_detail_helper_test.dart
git commit -m "feat(vote): 점유율 포맷 헬퍼 추가 (동적 정밀도)"
```

---

### Task 2: 말풍선 대상 선정 (`pickGapTooltipTarget`)

**Files:**
- Modify: `picnic_lib/lib/presentation/pages/vote/vote_detail_helper.dart`
- Test: `picnic_lib/test/presentation/pages/vote/vote_detail_helper_test.dart`

**Interfaces:**
- Consumes: `VoteDetailHelper.computeRanks(List<VoteItemModel?>) -> Map<int, int>` (기존, item id → rank). **competition ranking** 이라 동점자는 같은 rank 를 공유하고 다음 순위는 건너뛴다 (1,2,2,4).
- Produces:
  - `class GapTooltipTarget { final int itemId; final int gapVotes; const GapTooltipTarget({required this.itemId, required this.gapVotes}); }`
  - `static GapTooltipTarget? VoteDetailHelper.pickGapTooltipTarget(List<VoteItemModel?> items, Map<int, int> ranks)`

- [ ] **Step 1: 실패하는 테스트를 쓴다**

`test/presentation/pages/vote/vote_detail_helper_test.dart` 의 맨 끝, main 의 닫는 `}` 직전에 붙인다.

```dart
  // ── pickGapTooltipTarget ─────────────────────────────────────────────

  group('pickGapTooltipTarget', () {
    GapTooltipTarget? pick(List<VoteItemModel?> items) =>
        VoteDetailHelper.pickGapTooltipTarget(
          items,
          VoteDetailHelper.computeRanks(items),
        );

    test('returns null for an empty list', () {
      expect(pick([]), isNull);
    });

    test('returns null when there is only a leader', () {
      expect(pick([_item(id: 1, voteTotal: 100)]), isNull);
    });

    test('picks the sole runner-up and the raw vote gap', () {
      final target = pick([
        _item(id: 1, voteTotal: 95304),
        _item(id: 2, voteTotal: 87666),
        _item(id: 3, voteTotal: 86729),
      ]);
      expect(target, isNotNull);
      expect(target!.itemId, 2);
      expect(target.gapVotes, 7638);
    });

    test('returns null when two items tie for rank 2', () {
      // competition ranking -> both get rank 2, tooltip would be drawn twice
      expect(
        pick([
          _item(id: 1, voteTotal: 100),
          _item(id: 2, voteTotal: 50),
          _item(id: 3, voteTotal: 50),
        ]),
        isNull,
      );
    });

    test('returns null when the leaders tie, because rank 2 does not exist', () {
      // ranks are 1, 1, 3 -- nobody holds rank 2
      expect(
        pick([
          _item(id: 1, voteTotal: 100),
          _item(id: 2, voteTotal: 100),
          _item(id: 3, voteTotal: 10),
        ]),
        isNull,
      );
    });

    test('returns null when the gap is zero', () {
      // a zero gap can only happen via a tie, which computeRanks collapses,
      // but guard the arithmetic anyway
      final items = [_item(id: 1, voteTotal: 10), _item(id: 2, voteTotal: 10)];
      expect(
        VoteDetailHelper.pickGapTooltipTarget(items, {1: 1, 2: 2}),
        isNull,
      );
    });

    test('treats a null voteTotal on the runner-up as zero', () {
      final target = pick([
        _item(id: 1, voteTotal: 40),
        _item(id: 2, voteTotal: null),
      ]);
      expect(target!.itemId, 2);
      expect(target.gapVotes, 40);
    });

    test('ignores null items', () {
      final target = pick([
        _item(id: 1, voteTotal: 30),
        null,
        _item(id: 2, voteTotal: 10),
      ]);
      expect(target!.itemId, 2);
      expect(target.gapVotes, 20);
    });
  });
```

- [ ] **Step 2: 실패하는지 확인한다**

```bash
cd ~/Repositories/picnic-app-vote-share/picnic_lib
flutter test test/presentation/pages/vote/vote_detail_helper_test.dart
```

Expected: 컴파일 실패. `Undefined class 'GapTooltipTarget'.` 및 `The method 'pickGapTooltipTarget' isn't defined`

- [ ] **Step 3: 최소 구현을 넣는다**

`lib/presentation/pages/vote/vote_detail_helper.dart` 의 `class VoteDetailHelper` 안, `computeRanks` **바로 뒤**에 넣는다:

```dart
  /// Pick the single item that should carry the "N votes behind #1" tooltip.
  ///
  /// Returns null unless exactly one item holds rank 2 and its gap to the
  /// leader is positive. [computeRanks] uses competition ranking, so a tie at
  /// rank 2 yields several rank-2 items (the tooltip would be drawn on each)
  /// and a tie at rank 1 yields no rank-2 item at all.
  static GapTooltipTarget? pickGapTooltipTarget(
    List<VoteItemModel?> items,
    Map<int, int> ranks,
  ) {
    int? leaderVotes;
    VoteItemModel? runnerUp;
    var rank2Count = 0;

    for (final item in items) {
      if (item == null) continue;
      final rank = ranks[item.id];
      if (rank == 1) {
        leaderVotes ??= item.voteTotal ?? 0;
      } else if (rank == 2) {
        rank2Count++;
        runnerUp = item;
      }
    }

    if (leaderVotes == null || runnerUp == null || rank2Count != 1) return null;

    final gap = leaderVotes - (runnerUp.voteTotal ?? 0);
    if (gap <= 0) return null;

    return GapTooltipTarget(itemId: runnerUp.id, gapVotes: gap);
  }
```

그리고 파일 맨 끝, 기존 `class RankChangeResult { ... }` **뒤**에 추가한다:

```dart
/// Result of [VoteDetailHelper.pickGapTooltipTarget].
class GapTooltipTarget {
  final int itemId;
  final int gapVotes;

  const GapTooltipTarget({required this.itemId, required this.gapVotes});
}
```

- [ ] **Step 4: 통과하는지 확인한다**

```bash
cd ~/Repositories/picnic-app-vote-share/picnic_lib
flutter test test/presentation/pages/vote/vote_detail_helper_test.dart
```

Expected: `All tests passed!`

- [ ] **Step 5: 커밋**

```bash
cd ~/Repositories/picnic-app-vote-share
git add picnic_lib/lib/presentation/pages/vote/vote_detail_helper.dart \
        picnic_lib/test/presentation/pages/vote/vote_detail_helper_test.dart
git commit -m "feat(vote): 2위 갭 말풍선 대상 선정 로직 (동점 가드 포함)"
```

---

### Task 3: 말풍선 위젯 (`VoteGapTooltip`)

**Files:**
- Create: `picnic_lib/lib/presentation/pages/vote/vote_gap_tooltip.dart`
- Test: `picnic_lib/test/presentation/pages/vote/vote_gap_tooltip_test.dart`

**Interfaces:**
- Consumes: `AppColors.grey900`, `AppColors.grey00`, `AppTypo.caption10SB`, `getTextStyle(AppTypo, Color)` — 전부 `package:picnic_lib/ui/style.dart`
- Produces: `class VoteGapTooltip extends StatefulWidget` — 생성자 `const VoteGapTooltip({super.key, required String text, VoidCallback? onDismissed})`. 총 재생 시간 260ms(인) + 1000ms(유지) + 260ms(아웃) = 1520ms. 재생이 끝나면 `onDismissed` 를 **정확히 한 번** 호출하고 `SizedBox.shrink()` 를 반환한다.

- [ ] **Step 1: 실패하는 테스트를 쓴다**

`test/presentation/pages/vote/vote_gap_tooltip_test.dart` 를 새로 만든다.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/pages/vote/vote_gap_tooltip.dart';

import '../../../helpers/test_environment.dart';

void main() {
  setUp(() {
    initTestColors();
  });

  group('VoteGapTooltip', () {
    testWidgets('shows the text after fading in', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: VoteGapTooltip(text: '1위와 16,800표 차이!')),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('1위와 16,800표 차이!'), findsOneWidget);
    });

    testWidgets('plays once, then removes itself from the tree', (tester) async {
      var dismissed = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VoteGapTooltip(text: 'gap', onDismissed: () => dismissed++),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 300)); // fade in done
      expect(find.text('gap'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 1100)); // hold elapsed
      await tester.pump(const Duration(milliseconds: 300)); // fade out done
      await tester.pump(); // rebuild as SizedBox.shrink

      expect(find.text('gap'), findsNothing);
      expect(dismissed, 1);
    });

    testWidgets('does not intercept taps', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: VoteGapTooltip(text: 'gap')),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(IgnorePointer), findsOneWidget);
    });

    testWidgets('cancels its timer when disposed early', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: VoteGapTooltip(text: 'gap')),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Unmount before the hold timer fires. If the timer were left pending,
      // flutter_test fails the test with "A Timer is still pending".
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SizedBox())),
      );
      await tester.pump(const Duration(seconds: 2));

      expect(tester.takeException(), isNull);
    });
  });
}
```

- [ ] **Step 2: 실패하는지 확인한다**

```bash
cd ~/Repositories/picnic-app-vote-share/picnic_lib
flutter test test/presentation/pages/vote/vote_gap_tooltip_test.dart
```

Expected: 컴파일 실패. `Error: Couldn't resolve the package 'picnic_lib' ... vote_gap_tooltip.dart` 또는 `Target of URI doesn't exist`

- [ ] **Step 3: 최소 구현을 넣는다**

`lib/presentation/pages/vote/vote_gap_tooltip.dart` 를 새로 만든다.

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:picnic_lib/ui/style.dart';

/// A one-shot tooltip: fades and slides in, holds for a beat, fades out, then
/// removes itself from the widget tree.
///
/// Removing itself matters. A bare [FadeTransition] would leave the
/// [IgnorePointer] sitting on top of the row at opacity 0 forever.
///
/// The widget owns its *animation*; the caller owns its *lifetime*. Nothing
/// here prevents a second instance from being built — the caller must ensure
/// it mounts this only once.
class VoteGapTooltip extends StatefulWidget {
  const VoteGapTooltip({super.key, required this.text, this.onDismissed});

  final String text;

  /// Called exactly once, when the fade-out completes.
  final VoidCallback? onDismissed;

  @override
  State<VoteGapTooltip> createState() => _VoteGapTooltipState();
}

class _VoteGapTooltipState extends State<VoteGapTooltip>
    with SingleTickerProviderStateMixin {
  static const _fade = Duration(milliseconds: 260);
  static const _hold = Duration(seconds: 1);

  late final AnimationController _controller;
  late final CurvedAnimation _curve;
  late final Animation<Offset> _slide;
  Timer? _dismiss;
  bool _gone = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _fade)..forward();
    // Build the curve once. Creating it in build() would stack a listener on
    // the controller every rebuild.
    _curve = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(_curve);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.dismissed && mounted && !_gone) {
        setState(() => _gone = true);
        widget.onDismissed?.call();
      }
    });

    _dismiss = Timer(_hold, () {
      if (mounted) _controller.reverse();
    });
  }

  @override
  void dispose() {
    _dismiss?.cancel();
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_gone) return const SizedBox.shrink();

    return IgnorePointer(
      child: FadeTransition(
        opacity: _curve,
        child: SlideTransition(
          position: _slide,
          child: ConstrainedBox(
            // A Positioned child is unbounded; a long locale or a large gap
            // would otherwise run off the screen edge.
            constraints: const BoxConstraints(maxWidth: 240),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.grey900,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    widget.text,
                    style: getTextStyle(AppTypo.caption10SB, AppColors.grey00),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: CustomPaint(
                    size: const Size(12, 6),
                    painter: _TailPainter(color: AppColors.grey900),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TailPainter extends CustomPainter {
  const _TailPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_TailPainter oldDelegate) => oldDelegate.color != color;
}
```

- [ ] **Step 4: 통과하는지 확인한다**

```bash
cd ~/Repositories/picnic-app-vote-share/picnic_lib
flutter test test/presentation/pages/vote/vote_gap_tooltip_test.dart
```

Expected: `All tests passed!` (4 tests)

만약 `dismissed` 가 0 이면 hold 타이머가 아직 안 터진 것이다. Step 1 의 `pump(1100ms)` 값을 확인한다 (1000ms 정각은 경계라 불안정하다).

- [ ] **Step 5: 커밋**

```bash
cd ~/Repositories/picnic-app-vote-share
git add picnic_lib/lib/presentation/pages/vote/vote_gap_tooltip.dart \
        picnic_lib/test/presentation/pages/vote/vote_gap_tooltip_test.dart
git commit -m "feat(vote): 1회 재생 후 트리에서 사라지는 갭 말풍선 위젯"
```

---

### Task 4: l10n 키 추가 (14개 로케일)

**Files:**
- Modify: `picnic_lib/lib/l10n/app_bn.arb`, `app_bn_BD.arb`, `app_en.arb`, `app_es.arb`, `app_fil.arb`, `app_id.arb`, `app_ja.arb`, `app_ko.arb`, `app_my.arb`, `app_th.arb`, `app_vi.arb`, `app_zh.arb`, `app_zh_CN.arb`, `app_zh_TW.arb`
- Modify (생성됨, 커밋 대상): `picnic_lib/lib/l10n/app_localizations.dart`, `app_localizations_*.dart`

**Interfaces:**
- Produces: `String AppLocalizations.text_vote_gap_behind_leader(String gap)`

> `app_en.arb` 가 템플릿이다. 14개 파일 모두 기존 `text_vote_rank` 에 `@`-메타데이터 블록을 갖고 있으므로, 새 키도 전부 같은 형태로 넣는다.
>
> **주의:** `app_my.arb` 의 기존 `text_vote_rank` 값은 `"__phph_0__ အဆင့်"` 로 placeholder 가 깨져 있다. 우리 변경과 무관한 기존 버그이니 **고치지 말고 그대로 둔다** (별건으로 처리).

- [ ] **Step 1: 삽입 스크립트를 작성해 실행한다**

각 ARB 의 `"text_vote_rank":` 줄 **바로 앞**에 새 키를 끼워 넣는다. 중간 삽입이라 JSON trailing-comma 문제가 없다.

```bash
cd ~/Repositories/picnic-app-vote-share/picnic_lib/lib/l10n
python3 - <<'PY'
import io, json, os

MESSAGES = {
    'app_ko.arb':    '1위와 {gap}표 차이!',
    'app_en.arb':    '{gap} votes behind #1',
    'app_ja.arb':    '1位と{gap}票差！',
    'app_zh.arb':    '落后第 1 名 {gap} 票！',
    'app_zh_CN.arb': '落后第 1 名 {gap} 票！',
    'app_zh_TW.arb': '落後第 1 名 {gap} 票！',
    'app_es.arb':    '{gap} votos detrás del n.º 1',
    'app_th.arb':    'ตามหลังอันดับ 1 อยู่ {gap} โหวต!',
    'app_vi.arb':    'Kém hạng 1 {gap} phiếu!',
    'app_id.arb':    '{gap} suara di belakang #1',
    'app_bn.arb':    '১ম স্থান থেকে {gap} ভোট পিছিয়ে!',
    'app_bn_BD.arb': '১ম স্থান থেকে {gap} ভোট পিছিয়ে!',
    'app_fil.arb':   '{gap} na boto ang agwat sa #1!',
    'app_my.arb':    'ပထမနေရာထက် မဲ {gap} မဲ နောက်ကျနေသည်!',
}

ANCHOR = '  "text_vote_rank":'

for fname, msg in MESSAGES.items():
    with io.open(fname, encoding='utf-8') as f:
        lines = f.readlines()

    if any('"text_vote_gap_behind_leader"' in l for l in lines):
        print('skip (already present):', fname)
        continue

    idx = next(i for i, l in enumerate(lines) if l.startswith(ANCHOR))

    block = (
        '  "text_vote_gap_behind_leader": %s,\n'
        '  "@text_vote_gap_behind_leader": {\n'
        '    "placeholders": {\n'
        '      "gap": {\n'
        '        "type": "String"\n'
        '      }\n'
        '    }\n'
        '  },\n'
    ) % json.dumps(msg, ensure_ascii=False)

    lines.insert(idx, block)
    with io.open(fname, 'w', encoding='utf-8') as f:
        f.writelines(lines)
    print('inserted:', fname)

# Fail loudly if any file is no longer valid JSON.
for fname in MESSAGES:
    with io.open(fname, encoding='utf-8') as f:
        data = json.load(f)
    assert 'text_vote_gap_behind_leader' in data, fname
    assert '{gap}' in data['text_vote_gap_behind_leader'], fname
print('all 14 ARB files valid')
PY
```

Expected 마지막 줄: `all 14 ARB files valid`

- [ ] **Step 2: 코드 생성**

```bash
cd ~/Repositories/picnic-app-vote-share/picnic_lib
flutter gen-l10n
```

Expected: 에러 없음. `lib/l10n/app_localizations*.dart` 가 갱신된다.

- [ ] **Step 3: 생성 결과를 확인한다**

```bash
cd ~/Repositories/picnic-app-vote-share/picnic_lib
grep -n "text_vote_gap_behind_leader" lib/l10n/app_localizations.dart
grep -n "text_vote_gap_behind_leader" lib/l10n/app_localizations_ko.dart
cat untranslated-messages.json
```

Expected:
- `app_localizations.dart` 에 `String text_vote_gap_behind_leader(String gap);` 추상 선언
- `app_localizations_ko.dart` 에 `return '1위와 $gap표 차이!';`
- `untranslated-messages.json` 은 `{}` — 비어 있어야 한다. 비어 있지 않으면 어떤 로케일에 키가 빠진 것이다.

- [ ] **Step 4: 커밋**

```bash
cd ~/Repositories/picnic-app-vote-share
git add picnic_lib/lib/l10n/
git commit -m "i18n(vote): text_vote_gap_behind_leader 키 추가 (14개 로케일)"
```

---

### Task 5: 진행 중 투표 리스트 행을 점유율로 (`vote_detail_page.dart`)

**Files:**
- Modify: `picnic_lib/lib/presentation/pages/vote/vote_detail_page.dart` (`_buildVoteCountContainer` 부근, 현재 1166–1218행)

**Interfaces:**
- Consumes: `VoteDetailHelper.formatSharePercent`, `VoteDetailHelper.sharePercentDecimals`, `VoteDetailHelper.sumVoteTotals` (Task 1)
- Produces: `_VoteDetailPageState._totalVotes` (`int`) — Task 6 이 읽지는 않지만 같은 `data` 콜백에서 갱신된다

- [ ] **Step 1: 합계 필드를 추가한다**

`vote_detail_page.dart` 의 `_VoteDetailPageState` 필드 선언부에서 아래 줄을 찾는다:

```dart
  final Set<int> _highlightedItemIds = {};
```

그 **바로 뒤**에 추가한다:

```dart

  /// Sum of every item's voteTotal, over the *unfiltered* list.
  /// Recomputed once per data frame in [_buildVoteItemList].
  int _totalVotes = 0;
```

- [ ] **Step 2: 합계를 매 데이터 프레임마다 계산한다**

`_buildVoteItemList` 의 `data:` 콜백 시작부에서 아래를 찾는다:

```dart
      data: (data) {
        _updateRanks(data);
        final filteredIndices = _getFilteredIndices([data, _searchQuery]);
```

아래로 바꾼다:

```dart
      data: (data) {
        _updateRanks(data);
        _totalVotes = VoteDetailHelper.sumVoteTotals(data);
        final filteredIndices = _getFilteredIndices([data, _searchQuery]);
```

- [ ] **Step 3: 라벨을 분기한다**

`_buildVoteCountContainer` 전체(현재 1166–1218행)를 아래로 교체한다.

```dart
  Widget _buildVoteCountContainer(VoteItemModel item, int voteCountDiff) {
    final hasChanged = voteCountDiff != 0;

    return SizedBox(
      width: double.infinity,
      height: 20,
      child: Stack(
        clipBehavior: Clip.none, // 진행바 위로 배지를 띄워 레이아웃 흔들림 방지
        children: [
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 1000),
              width: double.infinity,
              height: 20,
              decoration: BoxDecoration(
                gradient: commonGradient,
                borderRadius: BorderRadius.circular(10.r),
              ),
              padding: EdgeInsets.only(right: 16.w, bottom: 3),
              alignment: Alignment.centerRight,
              key: ValueKey(hasChanged ? item.voteTotal : 'static'),
              child: _buildVoteCountLabel(item, hasChanged),
            ),
          ),
          Positioned(
            right: 16.w,
            bottom: 28,
            child: VoteGainIndicator(diff: voteCountDiff),
          ),
        ],
      ),
    );
  }

  /// Ended votes keep the raw count. Live votes show share of total, because
  /// the raw numbers are what we are trying to stop surfacing.
  Widget _buildVoteCountLabel(VoteItemModel item, bool hasChanged) {
    final style = getTextStyle(AppTypo.caption10SB, AppColors.grey00);

    if (isEnded) {
      return hasChanged
          ? AnimatedDigitWidget(
              value: item.voteTotal,
              enableSeparator: true,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              textStyle: style,
            )
          : Text(NumberFormat('#,###').format(item.voteTotal), style: style);
    }

    final votes = item.voteTotal ?? 0;
    final label = VoteDetailHelper.formatSharePercent(votes, _totalVotes);

    // '—' and '<0.0001%' have no digits to roll.
    final rollable = hasChanged && !label.startsWith('<') && label != '—';
    if (!rollable) return Text(label, style: style);

    final pct = votes / _totalVotes * 100;
    final decimals = VoteDetailHelper.sharePercentDecimals(pct);

    // AnimatedDigitWidget truncates the fraction (fractionList.take), while
    // toStringAsFixed rounds. Pre-round so the rolling and the static text
    // never disagree by one in the last digit.
    final rounded = double.parse(pct.toStringAsFixed(decimals));

    return AnimatedDigitWidget(
      // A change in decimals shifts the decimal point; rebuild instead of
      // rolling across it.
      key: ValueKey(decimals),
      value: rounded,
      fractionDigits: decimals,
      enableSeparator: false,
      suffix: '%',
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      textStyle: style,
    );
  }
```

- [ ] **Step 4: 분석 + 기존 테스트가 안 깨졌는지 확인한다**

```bash
cd ~/Repositories/picnic-app-vote-share/picnic_lib
flutter analyze lib/presentation/pages/vote/vote_detail_page.dart
flutter test test/presentation/pages/vote/
```

Expected:
- `flutter analyze`: `No issues found!`
- `flutter test`: 전부 통과. `vote_gain_indicator_test.dart`, `vote_detail_page_test.dart`, `vote_detail_page_render_test.dart` 도 통과해야 한다 — `VoteGainIndicator` 는 그대로 두었으므로 깨질 이유가 없다.

`AnimatedDigitWidget` 이 `fractionDigits` / `suffix` 를 모른다고 하면 `animated_digit` 버전을 확인한다 (`pubspec.yaml` 의 `^3.2.3`, 잠긴 버전은 3.3.1+2 이고 둘 다 지원한다).

- [ ] **Step 5: 커밋**

```bash
cd ~/Repositories/picnic-app-vote-share
git add picnic_lib/lib/presentation/pages/vote/vote_detail_page.dart
git commit -m "feat(vote): 진행 중 투표 리스트 행을 득표수 대신 점유율로 표시"
```

---

### Task 6: 말풍선 배선 (수명은 페이지가 소유)

**Files:**
- Modify: `picnic_lib/lib/presentation/pages/vote/vote_detail_page.dart`

**Interfaces:**
- Consumes:
  - `VoteDetailHelper.pickGapTooltipTarget(List<VoteItemModel?>, Map<int, int>) -> GapTooltipTarget?` (Task 2)
  - `GapTooltipTarget.itemId` (`int`), `GapTooltipTarget.gapVotes` (`int`) (Task 2)
  - `VoteGapTooltip({required String text, VoidCallback? onDismissed})` (Task 3)
  - `AppLocalizations.text_vote_gap_behind_leader(String gap)` (Task 4)
- Produces: 없음 (마지막 배선 작업)

> **왜 페이지가 수명을 소유하나.** 핸드오프의 "진입 시 1회" 는 키 없는 `for` 루프의 위치 기반 State 매칭에 의존한다. picnic 의 리스트는 `ListView.builder` + `ValueKey('vote_item_${item.id}')` 라서 State 가 아이템을 따라다닌다. 그대로 두면 (a) 2위 주인이 바뀔 때 (1초 폴링이라 흔하다), (b) 스크롤 아웃 후 다시 들어올 때 말풍선이 재생된다. 그래서 대상 id 와 gap 값을 페이지가 한 번 고정하고, 끝나면 영구 래치한다.

- [ ] **Step 1: import 3개를 추가한다**

`vote_detail_page.dart` 상단 import 블록에 추가한다 (기존 `vote_item_widget.dart` import 근처):

```dart
import 'package:picnic_lib/presentation/pages/vote/vote_gap_tooltip.dart';
```

`dart:async`, `package:intl/intl.dart`, `vote_detail_helper.dart`, `app_localizations.dart` 는 이미 import 되어 있다. 확인만 한다.

- [ ] **Step 2: 상태 필드를 추가한다**

Task 5 에서 넣은 `int _totalVotes = 0;` **바로 뒤**에 추가한다:

```dart

  // ── Gap tooltip lifetime (owned by the page, not the row) ────────────
  //
  // The rows are keyed by item id, so a row's State follows its item. Letting
  // the tooltip widget own its own "play once" would replay it whenever the
  // runner-up changes or the row is scrolled out and back in.
  int? _gapTooltipItemId;
  int _gapTooltipGap = 0;
  bool _gapTooltipDone = false;
  Timer? _gapTooltipLatch;
```

- [ ] **Step 3: 무장/종료 메서드를 추가한다**

`_triggerHighlight` 메서드 **바로 뒤**에 추가한다:

```dart
  /// Choose the one row that gets the gap tooltip, once, on the first real
  /// data frame. Freezes the gap so the 1s poll cannot make the number twitch.
  void _maybeArmGapTooltip(List<VoteItemModel?> data) {
    if (_gapTooltipDone || _gapTooltipItemId != null) return;
    if (isEnded || isUpcoming || _isSaving || data.isEmpty) return;
    if (_searchQuery.isNotEmpty) return;

    final target = VoteDetailHelper.pickGapTooltipTarget(data, _currentRanks);
    if (target == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _gapTooltipDone || _gapTooltipItemId != null) return;
      setState(() {
        _gapTooltipItemId = target.itemId;
        _gapTooltipGap = target.gapVotes;
      });
      // Safety net: the row can be scrolled out and disposed mid-play, in
      // which case VoteGapTooltip.onDismissed never fires.
      _gapTooltipLatch = Timer(const Duration(seconds: 2), _finishGapTooltip);
    });
  }

  /// Latch the tooltip off, permanently. Idempotent — both the widget callback
  /// and the safety-net timer may call this.
  void _finishGapTooltip() {
    _gapTooltipLatch?.cancel();
    _gapTooltipLatch = null;
    if (_gapTooltipDone) return;
    _gapTooltipDone = true;

    // The callback can arrive from an animation status listener mid-frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _gapTooltipItemId = null);
    });
  }
```

- [ ] **Step 4: 데이터 프레임에서 무장한다**

Task 5 Step 2 에서 고친 곳을 다시 연다:

```dart
      data: (data) {
        _updateRanks(data);
        _totalVotes = VoteDetailHelper.sumVoteTotals(data);
        final filteredIndices = _getFilteredIndices([data, _searchQuery]);
```

아래로 바꾼다:

```dart
      data: (data) {
        _updateRanks(data);
        _totalVotes = VoteDetailHelper.sumVoteTotals(data);
        _maybeArmGapTooltip(data);
        final filteredIndices = _getFilteredIndices([data, _searchQuery]);
```

- [ ] **Step 5: 타이머를 정리한다**

`dispose()` 에서 아래 줄을 찾는다:

```dart
    _updateTimer?.cancel();
    super.dispose();
```

아래로 바꾼다:

```dart
    _updateTimer?.cancel();
    _gapTooltipLatch?.cancel();
    super.dispose();
```

- [ ] **Step 6: 행을 감싼다**

`_buildVoteItemWithHighlight` 전체(현재 853–893행)를 아래로 교체한다. 행 위젯의 생성자 인자는 하나도 바뀌지 않는다 — `Stack` 으로 감싸기만 한다.

```dart
  Widget _buildVoteItemWithHighlight({
    required VoteItemModel item,
    required int index,
    required int actualRank,
    required int voteCountDiff,
    required bool rankChanged,
    required bool rankUp,
    required String searchQuery,
  }) {
    // 검색어가 있을 때는 커스텀 위젯을 만들어서 하이라이트 적용
    final row = searchQuery.isNotEmpty
        ? _buildCustomVoteItemWithHighlight(
            item: item,
            index: index,
            actualRank: actualRank,
            voteCountDiff: voteCountDiff,
            rankChanged: rankChanged,
            rankUp: rankUp,
            searchQuery: searchQuery,
          )
        : VoteItemWidget(
            item: item,
            index: index,
            actualRank: actualRank,
            voteCountDiff: voteCountDiff,
            rankChanged: rankChanged,
            rankUp: rankUp,
            isEnded: isEnded,
            isSaving: _isSaving,
            onTap: () {
              logger.d('🔥 onTap: onTap');
              _handleVoteItemTap(context, item, index);
            },
            artistImage: _buildArtistImage(item, index, actualRank, rankChanged),
            voteCountContainer: _buildVoteCountContainer(item, voteCountDiff),
            rankText: _buildRankText(actualRank, item),
          );

    if (item.id != _gapTooltipItemId || searchQuery.isNotEmpty) return row;

    return Stack(
      clipBehavior: Clip.none, // 행 위로 살짝 넘겨 2위를 가리킨다
      children: [
        row,
        Positioned(
          top: -30,
          right: 10,
          child: VoteGapTooltip(
            text: AppLocalizations.of(context).text_vote_gap_behind_leader(
              NumberFormat('#,###').format(_gapTooltipGap),
            ),
            onDismissed: _finishGapTooltip,
          ),
        ),
      ],
    );
  }
```

- [ ] **Step 7: 분석 + 전체 vote 테스트**

```bash
cd ~/Repositories/picnic-app-vote-share/picnic_lib
flutter analyze lib/presentation/pages/vote/
flutter test test/presentation/pages/vote/
```

Expected:
- `flutter analyze`: `No issues found!`
- `flutter test`: 전부 통과.

`vote_detail_page_render_test.dart` 가 "A Timer is still pending" 으로 실패하면 Step 5 의 `dispose` 수정이 빠진 것이다.

- [ ] **Step 8: 커밋**

```bash
cd ~/Repositories/picnic-app-vote-share
git add picnic_lib/lib/presentation/pages/vote/vote_detail_page.dart
git commit -m "feat(vote): 2위 갭 말풍선 배선 (수명은 페이지가 소유, 재노출 차단)"
```

---

### Task 7: 전체 검증

**Files:** 없음 (검증만)

**Interfaces:**
- Consumes: Task 1–6 전부

- [ ] **Step 1: picnic_lib 전체 테스트**

```bash
cd ~/Repositories/picnic-app-vote-share/picnic_lib
flutter test
```

Expected: `All tests passed!` — 실패가 있으면 이 계획 밖의 회귀다. 고치기 전에 `git stash` 없이 `main` 에서도 같은 테스트가 실패하는지 먼저 확인한다.

- [ ] **Step 2: 전체 analyze**

```bash
cd ~/Repositories/picnic-app-vote-share/picnic_lib
flutter analyze
```

Expected: 새 경고 0개. 기존 경고가 있다면 `main` 대비 개수가 늘지 않았는지 확인한다.

- [ ] **Step 3: 손대지 않기로 한 파일이 정말 안 바뀌었는지 확인한다**

```bash
cd ~/Repositories/picnic-app-vote-share
git diff --stat main...HEAD -- \
  picnic_lib/lib/presentation/pages/vote/vote_item_widget.dart \
  picnic_lib/lib/presentation/pages/vote/vote_item_highlight_widget.dart \
  picnic_lib/lib/presentation/pages/vote/vote_gain_indicator.dart \
  picnic_lib/lib/presentation/pages/vote/vote_detail_achieve_page.dart \
  picnic_lib/lib/presentation/widgets/vote/list/vote_info_card_vertical.dart
```

Expected: **출력 없음.** 한 줄이라도 나오면 범위를 벗어난 것이다.

- [ ] **Step 4: 실기기/시뮬레이터 확인**

```bash
cd ~/Repositories/picnic-app-vote-share/picnic_app
flutter run --dart-define=DISABLE_VM_CHECK=true
```

앱에서 확인할 것:

1. **진행 중인 투표** 상세 → 1~3위 행이 `35.20%` 같은 두 자리 소수 %로 보인다. 20위권은 `0.0032%`, 0표는 `—`.
2. **2위 행 위에 말풍선**이 잠깐 떴다 사라진다. 문구는 `1위와 7,638표 차이!` 처럼 **표 단위**다 (%가 아니다).
3. 말풍선이 사라진 뒤 **다시 뜨지 않는다.** 스크롤로 2위 행을 화면 밖으로 뺐다가 다시 들어와도, 1초 폴링으로 순위가 뒤집혀도 안 뜬다.
4. `+N` 팝과 순위 변동 파랑/빨강 플래시는 **여전히 동작**한다.
5. **종료된 투표** 상세 → 행이 **득표수**로 보인다 (`482,900`). 말풍선 없음.
6. 종료된 투표에서 **저장/공유** → 캡처 이미지의 Top-3 가 득표수로 보인다. 말풍선 없음.
7. **투표 목록** 카드의 종료된 투표 포디움 → 득표수가 그대로 보인다.
8. **예정된 투표** → 전원 `—`.
9. 검색창에 아티스트명을 넣으면 하이라이트가 동작하고, 말풍선은 뜨지 않는다.
10. **위클리 핔차트** (후보 1500명) 를 열어 스크롤이 버벅이지 않는지 본다. 합계 계산이 1초마다 돌지만 int 덧셈 1500회라 체감이 없어야 한다.

> **알려진 리스크 (수용됨).** 말풍선은 화면 진입 즉시 재생된다. 리스트는 `shrinkWrap: true` 라 화면 밖 행도 즉시 빌드되므로, **메인 이미지가 큰 투표에서는 사용자가 스크롤하기 전에 말풍선이 다 재생되고 사라진다.** 2번 항목이 재현되지 않으면 이것이 원인이다. 문제가 되면 `visibility_detector`(이미 의존성)로 2위 행이 10% 노출될 때 `_maybeArmGapTooltip` 을 부르도록 바꾼다 — 래치 구조는 그대로 쓴다.

- [ ] **Step 5: PR 을 연다**

```bash
cd ~/Repositories/picnic-app-vote-share
git push -u origin feat/vote-share-display
gh pr create --title "feat(vote): 투표 상세 점유율(%) 표시 + 2위 갭 말풍선" --body "$(cat <<'EOF'
## 요약

진행 중인 투표 상세 리스트에서 원시 득표수를 감추고 전체 대비 점유율(%)로 바꿉니다.
2위 행에 "1위와 N표 차이!" 말풍선을 진입 시 1회만 띄웁니다.

rankitten PR #196 이식. 설계 문서: `docs/superpowers/specs/2026-07-09-vote-share-display-design.html`

## 범위

- **변경**: `vote_detail_page.dart` 의 진행 중 투표 리스트 행
- **유지**: 종료된 투표(상세·캡처 이미지·목록 카드 포디움)는 전부 기존 득표수
- **유지**: achieve 투표 상세는 단일 아티스트 + 절대 득표수 마일스톤이라 share 개념이 없음
- **유지**: `+N` gain 팝, 순위 변동 배경 플래시

## 설계 노트

picnic 리스트는 `ListView.builder` + item id 키라서 rankitten 의 위치 기반 "1회 재생" 트릭이
성립하지 않습니다 (2위 주인이 바뀌거나 스크롤 아웃/인 하면 재노출). 말풍선의 수명을
페이지가 소유하도록 뒤집고, 2위 동점일 때는 아예 띄우지 않습니다.

점유율은 동적 정밀도입니다. picnic 투표는 상위 3명이 90%+ 를 가져가서, 고정 2자리로는
위클리 핔차트 1487명 중 ~1470명이 `0.00%` 로 뭉개집니다.

## 검토 요청

`bn` / `fil` / `my` 번역은 초안입니다. 네이티브 검수 부탁드립니다.
(ARB 키 누락/오역을 잡는 CI 게이트가 없습니다.)

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

---

## Self-Review

**스펙 커버리지**

| 스펙 섹션 | 구현 태스크 |
|---|---|
| 범위 (①만 변경, ②③④ 유지) | Task 5 (isEnded 분기), Task 7 Step 3 (미변경 검증) |
| 표시 규칙 (isEnded 분기) | Task 5 Step 3 |
| `formatSharePercent` + 자릿수 규칙 | Task 1 |
| 절삭 vs 반올림 함정 | Task 5 Step 3 (`double.parse(pct.toStringAsFixed(decimals))`) |
| 자릿수 변화 함정 | Task 5 Step 3 (`key: ValueKey(decimals)`) |
| `sumVoteTotals` + `_totalVotes` | Task 1, Task 5 Step 1–2 |
| `pickGapTooltipTarget` (동점 가드) | Task 2 |
| 페이지 소유 수명 + 래치 | Task 6 Step 2–5 |
| 안전망 타이머 | Task 6 Step 3, dispose 는 Step 5 |
| 행 시그니처 미변경 | Task 6 Step 6 |
| `VoteGapTooltip` (1회 재생 후 트리 제거) | Task 3 |
| l10n 14개 로케일 | Task 4 |
| 테스트 3종 | Task 1, 2 (helper), Task 3 (위젯) |
| 진입 즉시 재생 리스크 | Task 7 Step 4 노트 |

**타입 일관성 확인**

- `sharePercentDecimals(double) -> int` — Task 1 정의, Task 5 사용. 일치.
- `formatSharePercent(int?, int) -> String` — Task 1 정의, Task 5 사용. 일치.
- `sumVoteTotals(List<VoteItemModel?>) -> int` — Task 1 정의, Task 5 Step 2 사용. 일치.
- `pickGapTooltipTarget(List<VoteItemModel?>, Map<int,int>) -> GapTooltipTarget?` — Task 2 정의, Task 6 Step 3 사용. 일치.
- `GapTooltipTarget.itemId` / `.gapVotes` — Task 2 정의, Task 6 Step 3 사용. 일치.
- `VoteGapTooltip({required String text, VoidCallback? onDismissed})` — Task 3 정의, Task 6 Step 6 사용. 일치.
- `text_vote_gap_behind_leader(String gap)` — Task 4 생성, Task 6 Step 6 사용. `gap` 은 `NumberFormat` 으로 포맷된 `String`. 일치.

**스펙과의 의도적 차이 1건**

스펙은 위젯 이름을 `_GapTooltip` 으로 적었으나, 별도 파일에서 `vote_detail_page.dart` 가 참조해야 하므로 public `VoteGapTooltip` 으로 만든다. rankitten 원본은 같은 파일 안에 있어 private 이었다.

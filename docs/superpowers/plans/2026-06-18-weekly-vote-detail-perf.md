# 위클리 투표 상세 리스트 성능 튜닝 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 위클리 투표 상세 순위 리스트의 스크롤/이미지 버벅임을 동작 보존하며 제거한다.

**Architecture:** 근본원인 3가지(R1 1초 리빌드 폭풍 / R2 이미지 rank-key 재로딩 / R3 가상화 무력화)를 Tier 0(측정)→A(폭풍 차단)→B(가상화+이미지)→C(폴리시) 순으로 수정. 전부 Dart-only.

**Tech Stack:** Flutter 3.41.4 (Impeller 기본), Riverpod(codegen), freezed, PicnicCachedNetworkImage(cached_network_image), DecoratedSliver/SliverFixedExtentList.

스펙: `docs/superpowers/specs/2026-06-18-weekly-vote-detail-perf-design.md`

## Global Constraints
- 동작 보존: 전체 순위 리스트 + 인리스트 검색 + 순위 변동 하이라이트 애니메이션은 그대로 유지.
- 검색창 위치/모양 픽셀 패리티(스크린샷 검증). 이미지 없는 항목 기본 아이콘 fallback 유지.
- 라이브 갱신은 계속 동작(diff-gate는 "변화 없을 때만" 생략).
- Dart-only(네이티브/pubspec 변경 없음) → Shorebird OTA 패치 가능.
- 각 Tier/항목 독립 커밋. 적용·검증 순서: 0 → A1 → A2 → B1 → B2 → B3 → C1 → C2 → C3 → C4. 각 단계 후 재측정.
- 명령: `cd picnic_lib && flutter test <path>` / `dart analyze <file>`. @riverpod/freezed 공개 API·모델 변경 시 `dart run build_runner build --delete-conflicting-outputs`.
- 공유 계약 이름(태스크 간 일치): `VoteDetailHelper.diffChangedItemIds`, `VoteDetailHelper.computeRanksFromSorted`, `_VoteDetailPageState._isScrolling`, `kVoteRowExtent`, 이미지 key/cacheKey에서 rank 세그먼트 제거, `PicnicCachedNetworkImage(... bypassConcurrencyGate)`.

---

## Cross-Task Reconciliation (반드시 읽고 시작)

병렬 초안을 합쳤기에 태스크 간 다음 사항을 못박는다 — 실행 시 우선한다:

1. **이미지 위젯 정식 경로** = `picnic_lib/lib/presentation/common/picnic_cached_network_image.dart` (스펙의 `widgets/ui/...`는 오기). 모든 태스크는 이 경로 사용.
2. **같은 파일 공유 편집**: `picnic_cached_network_image.dart`(생성자 + `_getTransformedUrls`/`_triggerLazyLoad`)와 `vote_detail_page.dart` 이미지 섹션을 **B2·B3·C3·C4가 함께** 수정한다. 반드시 순서대로 실행하고, **각 태스크 시작 시 현재 파일을 다시 읽어 라인 번호를 재확인**하라(앞 태스크가 줄을 밀었을 수 있음). 추가되는 새 파라미터는 서로 독립이며 공존한다: `bypassConcurrencyGate`(B3), `maxQualityOverride`·`maxResolutionMultiplierCap`·`deferDuringFastScroll`(C3·C4). 전부 기본값=현행동작이라 다른 화면 영향 없음. 이 리스트의 이미지 위젯은 최종적으로 이들 중 여러 개를 동시에 지정한다(`lazyLoadingStrategy: none, bypassConcurrencyGate: true, ... deferDuringFastScroll: true`).
3. **cacheKey**: B2는 **위젯 key/cacheKey에서 rank 세그먼트만 제거**한다. 내부 `_cacheKeyFor(url)=url + '_' + _reloadToken`의 **`_reloadToken`(재시도 메커니즘)은 보존**하라 — 제거 금지. "안정 cacheKey" 목표는 rank 제거 + WebP-race로 인한 key flip 방지이지, 재시도 토큰 제거가 아니다.
4. **`kVoteRowExtent`**: B1-0 측정 태스크에서 실측해 pin한다(추측 금지, 위로 올림). 이후 태스크는 행에 **별도 bottom Padding을 재도입하지 말 것** — 16px 하단 간격은 itemExtent에 접혀 들어간다.
5. **위젯 테스트 부트스트랩**: 위젯/렌더 테스트 태스크는 형제 테스트(`test/presentation/pages/vote/vote_detail_page_render_test.dart`)의 setup/pump 헬퍼를 **그대로 복사**해 실제 이름을 쓴다(헬퍼 이름은 코드베이스 고유).
6. **헬퍼 추가**: `diffChangedItemIds`(A1)와 `computeRanksFromSorted`(C1)는 둘 다 `vote_detail_helper.dart`에 추가(가산적, 충돌 없음). 기존 `computeRanks`는 C1에서 build 경로 제거 후에도 다른 호출처가 없으면 정리 대상(C1 태스크가 확인).

---

## Tier 0 — 측정 기준선 (가장 먼저)

### Task 1: 성능 기준선 측정 + 회귀 지표 고정

**Files:** (코드 변경 없음 — 측정 산출물만)

- [ ] **Step 1: profile 모드로 위클리 투표 상세 진입.** 실기기에서:
  `cd picnic_app && flutter run --profile --dart-define=DISABLE_VM_CHECK=true`
  앱에서 위클리 투표(vote id 255, ~1,461명) 상세로 이동.
- [ ] **Step 2: 퍼포먼스 오버레이 ON + idle 관찰.** DevTools Performance 또는 `WidgetsApp.showPerformanceOverlay`. **손을 떼고 가만히** 둔 채 UI/raster 그래프를 본다. 기대(현 상태): 약 1초마다 build 스파이크. 이 스파이크 유무가 A 검증 기준.
- [ ] **Step 3: idle rebuild 카운트 측정.** `vote_detail_page.dart`의 행 위젯 build(또는 `_buildVoteItemList`)에 임시 `debugPrint`/카운터를 넣어 30초 idle 동안 build 횟수를 기록(예: "idle 30s = N builds"). 기록 후 카운터는 제거(커밋하지 않음).
- [ ] **Step 4: 스크롤/이미지 기준 기록.** 빠른 fling 시 dropped frames(>16ms), 이미지가 화면 진입 후 뜨기까지 체감 지연을 메모. DevTools의 "Raster"/"UI" thread time, network image 로드 타이밍.
- [ ] **Step 5: 기준선 표 작성.** `docs/superpowers/plans/` 또는 PR 본문에 before 표(idle builds/s, fling dropped frames, 이미지 지연)를 남긴다. 각 Tier 후 같은 표의 after 열을 채운다.

> 검증 원칙: 각 Tier 적용 후 Step 2~4를 재실행해 해당 수정이 의도한 지표를 움직였는지 확인. unit test 가능한 항목(A1 diff, C1 rank)은 별도 TDD.



## Tier A — 1초 리빌드 폭풍 차단 (R1)


### Task 2: Add and unit-test `VoteDetailHelper.diffChangedItemIds` (pure, TDD)

**Files:**
- `/Users/charlie.hyun/Repositories/picnic-app-vote-detail-perf/picnic_lib/lib/presentation/pages/vote/vote_detail_helper.dart` (add static method)
- `/Users/charlie.hyun/Repositories/picnic-app-vote-detail-perf/picnic_lib/test/presentation/pages/vote/vote_detail_helper_test.dart` (extend existing test file)

**Interfaces:**
- Produces: `static Set<int> VoteDetailHelper.diffChangedItemIds(List<VoteItemModel?> current, Map<int,int> newTotals)`
- Consumes: `VoteItemModel` from `package:picnic_lib/data/models/vote/vote.dart` (existing freezed model with `int id`, `int? voteTotal`)

Pure logic. TDD: write the failing test first, watch it fail to compile/run, then implement, then watch it pass. This is an internal-only change (a new static helper + new tests) — `build_runner` is NOT needed (no `@riverpod`/`@freezed` annotation touched).

- [ ] Add the failing tests. The existing test file `vote_detail_helper_test.dart` already defines local factories `_item({required int id, int? voteTotal, ArtistModel? artist, ArtistGroupModel? artistGroup})` at the top of `main()` (lines 34-46) and a top-level `group('computeRanks', ...)` block. Insert a NEW group immediately BEFORE the closing `}` of `main()` (i.e. as the last group in the file). Open the file and find the final line of `main()`. Add this block as the last group inside `main()`:

  ```dart
  // ── diffChangedItemIds ───────────────────────────────────────────────

  group('diffChangedItemIds', () {
    test('returns empty set when no totals provided', () {
      final current = [_item(id: 10, voteTotal: 100), _item(id: 11, voteTotal: 50)];
      expect(VoteDetailHelper.diffChangedItemIds(current, <int, int>{}), isEmpty);
    });

    test('returns empty set when totals match current', () {
      final current = [_item(id: 10, voteTotal: 100), _item(id: 11, voteTotal: 50)];
      final result = VoteDetailHelper.diffChangedItemIds(current, {10: 100, 11: 50});
      expect(result, isEmpty);
    });

    test('returns ids whose voteTotal changed', () {
      final current = [_item(id: 10, voteTotal: 100), _item(id: 11, voteTotal: 50)];
      final result = VoteDetailHelper.diffChangedItemIds(current, {10: 100, 11: 75});
      expect(result, {11});
    });

    test('returns multiple changed ids', () {
      final current = [_item(id: 10, voteTotal: 100), _item(id: 11, voteTotal: 50)];
      final result = VoteDetailHelper.diffChangedItemIds(current, {10: 120, 11: 75});
      expect(result, {10, 11});
    });

    test('treats null current voteTotal as 0 for comparison', () {
      final current = [_item(id: 10, voteTotal: null)];
      // newTotal 0 == treated-as-0 current -> no change
      expect(VoteDetailHelper.diffChangedItemIds(current, {10: 0}), isEmpty);
      // newTotal 5 != 0 -> changed
      expect(VoteDetailHelper.diffChangedItemIds(current, {10: 5}), {10});
    });

    test('ignores null items in current list', () {
      final current = <VoteItemModel?>[null, _item(id: 11, voteTotal: 50)];
      final result = VoteDetailHelper.diffChangedItemIds(current, {11: 99});
      expect(result, {11});
    });

    test('ids present in newTotals but absent from current are included (newly present)', () {
      final current = [_item(id: 10, voteTotal: 100)];
      final result = VoteDetailHelper.diffChangedItemIds(current, {10: 100, 99: 7});
      expect(result, {99});
    });

    test('ids in current but absent from newTotals are not included', () {
      final current = [_item(id: 10, voteTotal: 100), _item(id: 11, voteTotal: 50)];
      // 11 missing from totals -> no signal, not a change
      final result = VoteDetailHelper.diffChangedItemIds(current, {10: 100});
      expect(result, isEmpty);
    });
  });
  ```

  Note: the existing file already imports `package:picnic_lib/data/models/vote/vote.dart` (line 3), which exports `VoteItemModel`, so the `<VoteItemModel?>[null, ...]` literal compiles without a new import.

- [ ] Run the tests and CONFIRM THEY FAIL (method does not exist yet). From `/Users/charlie.hyun/Repositories/picnic-app-vote-detail-perf/picnic_lib`:

  ```bash
  flutter test test/presentation/pages/vote/vote_detail_helper_test.dart
  ```

  Expected output: a compile error referencing the missing member, e.g. `Error: The method 'diffChangedItemIds' isn't defined for the class 'VoteDetailHelper'.` and the run aborts with `Some tests failed.` / non-zero exit. (If it instead passes, STOP — the method already exists; reconcile before continuing.)

- [ ] Implement the helper. Open `/Users/charlie.hyun/Repositories/picnic-app-vote-detail-perf/picnic_lib/lib/presentation/pages/vote/vote_detail_helper.dart`. Insert the new method INSIDE the `VoteDetailHelper` class, immediately AFTER the existing `areDataListsEqual` method (which ends at line 56 with its closing `}`), BEFORE the `getMatchingText` doc comment at line 58:

  ```dart
  /// Return the set of item ids whose [voteTotal] differs from the matching
  /// entry in [newTotals], or whose id is present in [newTotals] but not in
  /// [current] (newly present). A null item voteTotal is treated as 0.
  ///
  /// Ids that appear in [current] but are absent from [newTotals] are NOT
  /// reported as changed (no fresh value = no signal). Null items in
  /// [current] are ignored.
  ///
  /// O(n + m). Used by [AsyncVoteItemList.refreshVoteTotals] to skip
  /// state reassignment entirely when the 1Hz poll returns no actual change.
  static Set<int> diffChangedItemIds(
    List<VoteItemModel?> current,
    Map<int, int> newTotals,
  ) {
    final changed = <int>{};
    final seen = <int>{};

    for (final item in current) {
      if (item == null) continue;
      seen.add(item.id);
      final newTotal = newTotals[item.id];
      if (newTotal == null) continue; // no fresh value -> no signal
      if (newTotal != (item.voteTotal ?? 0)) {
        changed.add(item.id);
      }
    }

    // ids present in the fresh totals but not in current = newly present
    for (final id in newTotals.keys) {
      if (!seen.contains(id)) {
        changed.add(id);
      }
    }

    return changed;
  }
  ```

- [ ] Analyze the changed file (expect zero issues):

  ```bash
  dart analyze lib/presentation/pages/vote/vote_detail_helper.dart
  ```

  Expected output: `No issues found!`

- [ ] Run the tests again and CONFIRM THEY PASS. From `/Users/charlie.hyun/Repositories/picnic-app-vote-detail-perf/picnic_lib`:

  ```bash
  flutter test test/presentation/pages/vote/vote_detail_helper_test.dart
  ```

  Expected output ends with `All tests passed!` and exit code 0. (This run also re-executes the pre-existing `computeRanks`, `areDataListsEqual`, etc. groups — they must all still pass.)

- [ ] Commit. From the repo root `/Users/charlie.hyun/Repositories/picnic-app-vote-detail-perf`:

  ```bash
  git add picnic_lib/lib/presentation/pages/vote/vote_detail_helper.dart picnic_lib/test/presentation/pages/vote/vote_detail_helper_test.dart
  git commit -m "feat(vote-detail): add pure VoteDetailHelper.diffChangedItemIds for poll-diffing

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
  ```

  Expected output: a commit summary line listing 2 files changed.

---

### Task 3: Make `refreshVoteTotals` early-return on no change and preserve object identity

**Files:**
- `/Users/charlie.hyun/Repositories/picnic-app-vote-detail-perf/picnic_lib/lib/presentation/providers/vote_detail_provider.dart` (modify `refreshVoteTotals`, lines 127-165)
- `/Users/charlie.hyun/Repositories/picnic-app-vote-detail-perf/picnic_lib/test/presentation/providers/vote_detail_provider_test.dart` (add provider tests)

**Interfaces:**
- Consumes: `VoteDetailHelper.diffChangedItemIds` (from the previous task), `VoteItemModel` (`package:picnic_lib/data/models/vote/vote.dart`).
- Produces: unchanged public signature `AsyncVoteItemList.refreshVoteTotals({required int voteId, VotePortal votePortal = VotePortal.vote}) -> Future<void>` with new no-reassign-on-no-change behavior.

This is INTERNAL-ONLY: the `@riverpod` annotation, the class name, the build signature, and `refreshVoteTotals`'s public parameter list are all UNCHANGED — only the method body changes. Therefore `build_runner` is NOT required (the generated `vote_detail_provider.g.dart` does not need regeneration). Confirm this in the verify step.

- [ ] Add the import for `VoteDetailHelper` to the provider file. Open `/Users/charlie.hyun/Repositories/picnic-app-vote-detail-perf/picnic_lib/lib/presentation/providers/vote_detail_provider.dart`. The current imports (lines 3-9) are:

  ```dart
  import 'package:picnic_lib/core/utils/logger.dart';
  import 'package:picnic_lib/data/models/vote/vote.dart';
  import 'package:picnic_lib/supabase_options.dart';
  import 'package:riverpod_annotation/riverpod_annotation.dart';
  import 'package:sentry_flutter/sentry_flutter.dart';

  import 'vote_list_provider.dart';
  ```

  Add the helper import after the `vote.dart` import so the block becomes:

  ```dart
  import 'package:picnic_lib/core/utils/logger.dart';
  import 'package:picnic_lib/data/models/vote/vote.dart';
  import 'package:picnic_lib/presentation/pages/vote/vote_detail_helper.dart';
  import 'package:picnic_lib/supabase_options.dart';
  import 'package:riverpod_annotation/riverpod_annotation.dart';
  import 'package:sentry_flutter/sentry_flutter.dart';

  import 'vote_list_provider.dart';
  ```

- [ ] Replace the body of `refreshVoteTotals`. The current body (lines 142-161) — from just after the `if (!ref.mounted || state.value == null) return;` guard inside the `try` (line 142) through the `state = AsyncValue.data(updatedList);` assignment (line 161) — is:

  ```dart
      if (!ref.mounted || state.value == null) return;

      final totalsMap = <int, int>{};
      for (final row in response) {
        totalsMap[row['id'] as int] = (row['vote_total'] as int?) ?? 0;
      }

      final updatedList = state.value!.map<VoteItemModel>((item) {
        if (item != null && totalsMap.containsKey(item.id)) {
          return item.copyWith(voteTotal: totalsMap[item.id]);
        }
        return item!;
      }).toList()
        ..sort((a, b) {
          final voteDiff = (b.voteTotal ?? 0).compareTo(a.voteTotal ?? 0);
          if (voteDiff != 0) return voteDiff;
          return a.id.compareTo(b.id);
        });

      state = AsyncValue.data(updatedList);
  ```

  Replace EXACTLY that span with:

  ```dart
      if (!ref.mounted || state.value == null) return;

      final totalsMap = <int, int>{};
      for (final row in response) {
        totalsMap[row['id'] as int] = (row['vote_total'] as int?) ?? 0;
      }

      final currentList = state.value!;
      final changedIds = VoteDetailHelper.diffChangedItemIds(
        currentList,
        totalsMap,
      );

      // Nothing actually changed since last poll: do NOT reassign state.
      // Keeping the same list identity prevents the 1Hz rebuild storm —
      // ref.watch consumers see an identical AsyncValue and skip rebuilding.
      if (changedIds.isEmpty) {
        return;
      }

      // Reuse unchanged item object identities; only copyWith the changed
      // ones. (VoteItemModel is freezed: copyWith allocates a new instance,
      // so we avoid it for items that didn't move.)
      final updatedList = currentList.map<VoteItemModel>((item) {
        if (item != null && changedIds.contains(item.id)) {
          return item.copyWith(voteTotal: totalsMap[item.id]);
        }
        return item!;
      }).toList()
        ..sort((a, b) {
          final voteDiff = (b.voteTotal ?? 0).compareTo(a.voteTotal ?? 0);
          if (voteDiff != 0) return voteDiff;
          return a.id.compareTo(b.id);
        });

      state = AsyncValue.data(updatedList);
  ```

  Rationale baked in: (a) early `return` when `changedIds.isEmpty` — no new `List` identity, no `AsyncValue` reassignment; (b) `changedIds.contains(item.id)` instead of `totalsMap.containsKey(item.id)` so an item present in the fresh totals but with the SAME value is NOT copyWith-ed and keeps its original object identity; (c) the sort comparator is byte-for-byte the same as before.

- [ ] Add provider tests. Open `/Users/charlie.hyun/Repositories/picnic-app-vote-detail-perf/picnic_lib/test/presentation/providers/vote_detail_provider_test.dart`. This file already imports `flutter_riverpod`, `flutter_test`, the provider, `vote_list_provider`, `vote.dart`, and `../../helpers/mock_supabase.dart`, and has a working `AsyncVoteItemList - setVoteItem` group that demonstrates the fetch-then-notifier pattern with `setupMockSupabase({'vote_item': voteItems})`. Add a NEW group immediately AFTER the closing `}` of the `'AsyncVoteItemList - setVoteItem'` group (the group whose final test is `'setVoteItem with non-matching id does not change totals'`, ending around line 450) and BEFORE the `'fetchVoteAchieve'` group. Insert:

  ```dart
  group('AsyncVoteItemList - refreshVoteTotals', () {
    late ProviderContainer container;

    final voteItems = [
      {
        'id': 10,
        'vote_id': 1,
        'vote_total': 500,
        'artist': {
          'id': 100,
          'name': {'ko': '아이유', 'en': 'IU'},
          'image': null,
          'artist_group': null,
        },
        'artist_group': null,
        'deleted_at': null,
      },
      {
        'id': 11,
        'vote_id': 1,
        'vote_total': 300,
        'artist': {
          'id': 101,
          'name': {'ko': '뷔', 'en': 'V'},
          'image': null,
          'artist_group': null,
        },
        'artist_group': null,
        'deleted_at': null,
      },
    ];

    setUp(() {
      setupMockSupabase({
        'vote_item': voteItems,
      });
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
      tearDownMockSupabase();
    });

    test('no-op when totals unchanged: preserves list identity', () async {
      await container.read(asyncVoteItemListProvider(voteId: 1).future);
      final before = container.read(asyncVoteItemListProvider(voteId: 1)).value;

      final notifier =
          container.read(asyncVoteItemListProvider(voteId: 1).notifier);
      // Mock returns the same vote_total values (500/300) for the
      // refreshVoteTotals select -> diffChangedItemIds is empty.
      await notifier.refreshVoteTotals(voteId: 1);

      final after = container.read(asyncVoteItemListProvider(voteId: 1)).value;
      // Same List instance: no reassignment happened.
      expect(identical(before, after), isTrue);
    });

    test('preserves identity of unchanged items when one item changes',
        () async {
      await container.read(asyncVoteItemListProvider(voteId: 1).future);
      final before = container.read(asyncVoteItemListProvider(voteId: 1)).value!;
      final beforeItem10 = before.firstWhere((i) => i!.id == 10);
      final beforeItem11 = before.firstWhere((i) => i!.id == 11);

      // Mutate only item 11's total in the mock data source so the next
      // refreshVoteTotals select returns a changed value for id 11 only.
      voteItems[1]['vote_total'] = 999;

      final notifier =
          container.read(asyncVoteItemListProvider(voteId: 1).notifier);
      await notifier.refreshVoteTotals(voteId: 1);

      final after = container.read(asyncVoteItemListProvider(voteId: 1)).value!;
      final afterItem10 = after.firstWhere((i) => i!.id == 10);
      final afterItem11 = after.firstWhere((i) => i!.id == 11);

      // Unchanged item keeps its exact object identity.
      expect(identical(beforeItem10, afterItem10), isTrue);
      // Changed item is a new (copyWith-ed) instance with the new total.
      expect(identical(beforeItem11, afterItem11), isFalse);
      expect(afterItem11!.voteTotal, 999);
      // List itself was reassigned (changedIds was non-empty).
      expect(identical(before, after), isFalse);
    });

    test('re-sorts when a lower item overtakes a higher one', () async {
      await container.read(asyncVoteItemListProvider(voteId: 1).future);

      voteItems[1]['vote_total'] = 1000; // id 11 overtakes id 10 (500)

      final notifier =
          container.read(asyncVoteItemListProvider(voteId: 1).notifier);
      await notifier.refreshVoteTotals(voteId: 1);

      final after = container.read(asyncVoteItemListProvider(voteId: 1)).value!;
      expect(after[0]!.id, 11);
      expect(after[0]!.voteTotal, 1000);
      expect(after[1]!.id, 10);
    });
  });
  ```

  IMPORTANT before running: this group relies on `setupMockSupabase` returning, for the `refreshVoteTotals` `select('id, vote_total')` query against `vote_item`, the SAME row list it serves for the full fetch. Verify this assumption in the next step; if the mock does not support the lightweight select or does not reflect the in-place `voteItems[1]['vote_total']` mutation, fall back to the manual verify step instead of these dynamic-value tests (still keep the `identical(before, after)` no-op test, which only needs the mock to echo the original 500/300 totals).

- [ ] Confirm the mock supports the `refreshVoteTotals` query shape. Read the mock to check it serves `.select('id, vote_total').eq('vote_id', ...).filter('deleted_at','is',null)` from the same configured `vote_item` rows and reflects later mutations:

  ```bash
  sed -n '1,200p' /Users/charlie.hyun/Repositories/picnic-app-vote-detail-perf/picnic_lib/test/presentation/helpers/mock_supabase.dart
  ```

  Decision rule: if the mock returns rows by reference from the same in-memory list (so mutating `voteItems[1]['vote_total']` is visible and partial `select` is honored or ignored gracefully), keep all three tests. If the mock snapshots/clones rows at `setupMockSupabase` time, REMOVE the two value-changing tests (`preserves identity of unchanged items...` and `re-sorts...`) and keep only the `no-op when totals unchanged` test, then add the manual-verify step below to cover the changed-item path. Do not invent a mock behavior — match what the file actually does.

- [ ] Analyze both changed files (expect zero issues):

  ```bash
  dart analyze lib/presentation/providers/vote_detail_provider.dart test/presentation/providers/vote_detail_provider_test.dart
  ```

  Expected output: `No issues found!`

- [ ] Confirm NO codegen is needed, then run the full vote_detail provider test file. From `/Users/charlie.hyun/Repositories/picnic-app-vote-detail-perf/picnic_lib`:

  ```bash
  git status --porcelain lib/presentation/generated/providers/vote_detail_provider.g.dart
  flutter test test/presentation/providers/vote_detail_provider_test.dart
  ```

  Expected: the `git status` line prints nothing (the generated `.g.dart` was not touched — confirming this is an internal-only change requiring no `build_runner`). The test run ends with `All tests passed!` and exit code 0 (including the pre-existing `setVoteItem` and `fetchVoteAchieve` groups).

- [ ] MANUAL profile verification (the unit tests prove logic + identity; this proves the rebuild storm is actually gone on device). Steps:
  1. From the repo root run the app in profile mode on a physical device or `flutter run --profile --dart-define=DISABLE_VM_CHECK=true` from `/Users/charlie.hyun/Repositories/picnic-app-vote-detail-perf/picnic_app`.
  2. Open a live, in-progress vote detail page (an ongoing vote so the 1s `refreshVoteTotals` poll is active) where vote totals are NOT actively changing for several seconds.
  3. In DevTools, open the Performance / Frame Analysis tab (or enable the on-device performance overlay). Observe the timeline for ~10 seconds while no real vote changes occur.
  4. PASS criterion: there is NO recurring ~1Hz spike of widget rebuilds / raster work tied to the poll. Before this change you would see a rebuild burst every second; after it, idle seconds show flat frames (the early `return` means no `AsyncValue` reassignment, so `ref.watch` consumers don't rebuild). Optionally confirm via DevTools "Rebuild counts" that the vote list widgets do not increment once per second while totals are static.
  5. Then trigger a real vote (or have totals change). PASS criterion: the list updates and re-sorts correctly exactly when a total actually changes, with only the changed row's content updating.
  6. Record the observation (idle = no 1Hz rebuilds; change = correct update) in the PR description.

- [ ] Commit. From the repo root `/Users/charlie.hyun/Repositories/picnic-app-vote-detail-perf`:

  ```bash
  git add picnic_lib/lib/presentation/providers/vote_detail_provider.dart picnic_lib/test/presentation/providers/vote_detail_provider_test.dart
  git commit -m "perf(vote-detail): skip state reassignment when poll totals unchanged

refreshVoteTotals now diffs incoming totals via diffChangedItemIds and
returns early (no new list identity, no AsyncValue reassignment) when
nothing changed, eliminating the 1Hz rebuild storm. Changed items are
copyWith-ed; unchanged items keep their object identity. Internal-only
change: no build_runner / generated code regeneration required.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
  ```

  Expected output: a commit summary line listing 2 files changed.


### Task 4: A2.1 — Add `_isScrolling` gate field + scroll-settle refresh helper to `_VoteDetailPageState`

**Files:**
- `/Users/charlie.hyun/Repositories/picnic-app-vote-detail-perf/picnic_lib/lib/presentation/pages/vote/vote_detail_page.dart`

**Interfaces:**
- Consumes: `asyncVoteItemListProvider(...).notifier.refreshVoteTotals(...)` (already used by the existing timer at lines 154-164), `isEnded`/`isUpcoming` (existing fields, lines 71-72).
- Produces: `bool _isScrolling` field; `void _onScrollSettle()`; `Duration _refreshInterval()`.

This is a structural/state change to a StatefulWidget, not pure logic — there is no meaningful unit test for "a bool flipped", so this task is verified by `dart analyze` (compile) + the existing render test still passing. The actual gate behavior is exercised by the widget test in Task A2.3.

- [ ] Add the `_isScrolling` field next to the existing guard flags. Open the file and locate the existing block (lines 74-76):

```dart
  Timer? _updateTimer;
  bool _isRefreshingItems = false;
  final Map<int, int> _previousVoteCounts = {};
```

Change it to:

```dart
  Timer? _updateTimer;
  bool _isRefreshingItems = false;
  bool _isScrolling = false;
  final Map<int, int> _previousVoteCounts = {};
```

- [ ] Add the settle-refresh helper and interval helper. Locate the END of the existing `_setupUpdateTimer` method (lines 148-170 — it currently ends with `});\n  }`). Immediately AFTER that closing `}` (and before `void _initializeRanks() {` at line 172), insert:

```dart
  /// Called once when scrolling settles (ScrollEndNotification).
  /// Performs a single vote-totals refresh that was suppressed while scrolling.
  Future<void> _onScrollSettle() async {
    if (!mounted) return;
    if (_isRefreshingItems || _isSaving) return;
    _isRefreshingItems = true;
    try {
      await ref
          .read(
            asyncVoteItemListProvider(
              voteId: widget.voteId,
              votePortal: widget.votePortal,
            ).notifier,
          )
          .refreshVoteTotals(
            voteId: widget.voteId,
            votePortal: widget.votePortal,
          );
    } catch (_) {
    } finally {
      _isRefreshingItems = false;
    }
  }

  /// Refresh cadence: 1s for live votes; widen to 5s once the vote is
  /// ended/upcoming since totals no longer change meaningfully.
  Duration _refreshInterval() {
    if (isEnded || isUpcoming) {
      return const Duration(seconds: 5);
    }
    return const Duration(seconds: 1);
  }
```

- [ ] Run analyze (expect zero issues from these additions):

```bash
cd /Users/charlie.hyun/Repositories/picnic-app-vote-detail-perf/picnic_lib && dart analyze lib/presentation/pages/vote/vote_detail_page.dart
```

Expected output: `No issues found!` (or only pre-existing unrelated infos — there must be NO new `error`/`warning` mentioning `_isScrolling`, `_onScrollSettle`, or `_refreshInterval`). Note: `_isScrolling` may report `unused_field` and the two helpers `unused_element` at THIS point — that is expected and resolved in A2.2. If you see those three unused-* infos and nothing else new, proceed.

- [ ] Commit:

```bash
cd /Users/charlie.hyun/Repositories/picnic-app-vote-detail-perf && git add picnic_lib/lib/presentation/pages/vote/vote_detail_page.dart && git commit -m "feat(vote-detail): add scroll gate field + settle-refresh + interval helpers"
```

Expected: commit succeeds, `1 file changed`.

---

### Task 5: A2.2 — Early-return the 1s timer body while scrolling + use `_refreshInterval()` + wire `NotificationListener` scroll source

**Files:**
- `/Users/charlie.hyun/Repositories/picnic-app-vote-detail-perf/picnic_lib/lib/presentation/pages/vote/vote_detail_page.dart`

**Interfaces:**
- Consumes: `_isScrolling`, `_onScrollSettle()`, `_refreshInterval()` (from A2.1).
- Produces: gated `_setupUpdateTimer`; `CustomScrollView` wrapped in `NotificationListener<ScrollNotification>` that flips `_isScrolling` and calls `_onScrollSettle()` on settle.

Structural change — verified by `dart analyze` + existing render test. Behavioral verification via Task A2.3 widget test + the manual profile checklist (Task A2.4).

- [ ] Gate the timer body and widen the interval. Locate `_setupUpdateTimer` (lines 148-170), currently:

```dart
  void _setupUpdateTimer() {
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (!mounted) return;
      if (_isRefreshingItems || _isSaving) return;
      _isRefreshingItems = true;
```

Replace those first lines with (add the `_isScrolling` early-return and swap the literal `Duration` for `_refreshInterval()`):

```dart
  void _setupUpdateTimer() {
    _updateTimer = Timer.periodic(_refreshInterval(), (_) async {
      if (!mounted) return;
      // Suppress polling while the user is actively scrolling; the deferred
      // refresh fires once on settle via _onScrollSettle().
      if (_isScrolling) return;
      if (_isRefreshingItems || _isSaving) return;
      _isRefreshingItems = true;
```

Leave the rest of the method body (the `try { await ref.read(...).refreshVoteTotals(...) ... }`) unchanged.

- [ ] Wrap the `CustomScrollView` in a `NotificationListener<ScrollNotification>`. Locate the `SizedBox.expand` / `CustomScrollView` block (lines 463-487):

```dart
                    child: SizedBox.expand(
                      child: CustomScrollView(
                        controller: _scrollController,
                        physics:
                            const AlwaysScrollableScrollPhysics(), // 데이터가 적어도 항상 스크롤 가능하게
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        slivers: [
                          SliverToBoxAdapter(
                            child: RepaintBoundary(
                              key: _captureKey,
                              child: Column(
                                children: [
                                  _buildVoteInfo(context, voteModel),
                                  SizedBox(height: 12),
                                  if (_isSaving)
                                    _buildCaptureVoteList(context),
                                ],
                              ),
                            ),
                          ),
                          if (!_isSaving) _buildVoteItemList(context),
                        ],
                      ),
                    ),
```

Wrap it so the `NotificationListener` is the parent of `CustomScrollView` (keep `SizedBox.expand` as the outermost so layout is unchanged):

```dart
                    child: SizedBox.expand(
                      child: NotificationListener<ScrollNotification>(
                        onNotification: (notification) {
                          if (notification is ScrollStartNotification) {
                            // Don't gate during programmatic scroll-to-search;
                            // only user drags start a gate. ScrollStartNotification
                            // fires for both, so we set the flag and rely on
                            // ScrollEndNotification to clear + refresh.
                            if (!_isScrolling) {
                              _isScrolling = true;
                            }
                          } else if (notification is ScrollEndNotification) {
                            if (_isScrolling) {
                              _isScrolling = false;
                              // Single deferred refresh on settle.
                              _onScrollSettle();
                            }
                          }
                          return false; // allow the notification to keep bubbling
                        },
                        child: CustomScrollView(
                          controller: _scrollController,
                          physics:
                              const AlwaysScrollableScrollPhysics(), // 데이터가 적어도 항상 스크롤 가능하게
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          slivers: [
                            SliverToBoxAdapter(
                              child: RepaintBoundary(
                                key: _captureKey,
                                child: Column(
                                  children: [
                                    _buildVoteInfo(context, voteModel),
                                    SizedBox(height: 12),
                                    if (_isSaving)
                                      _buildCaptureVoteList(context),
                                  ],
                                ),
                              ),
                            ),
                            if (!_isSaving) _buildVoteItemList(context),
                          ],
                        ),
                      ),
                    ),
```

Note: `_isScrolling` is mutated WITHOUT `setState` on purpose — it is a polling gate read by the timer callback, not by `build`. Flipping it must not trigger a rebuild (that would defeat the perf goal). Do NOT wrap these assignments in `setState`.

- [ ] Run analyze — now the previously-unused symbols are consumed, expect clean:

```bash
cd /Users/charlie.hyun/Repositories/picnic-app-vote-detail-perf/picnic_lib && dart analyze lib/presentation/pages/vote/vote_detail_page.dart
```

Expected output: `No issues found!` (no `unused_field`/`unused_element` for `_isScrolling`, `_onScrollSettle`, `_refreshInterval`; no new errors/warnings).

- [ ] Run the existing render test to confirm the page still builds and renders unchanged:

```bash
cd /Users/charlie.hyun/Repositories/picnic-app-vote-detail-perf/picnic_lib && flutter test test/presentation/pages/vote/vote_detail_page_render_test.dart
```

Expected output: `All tests passed!` (same pass count as before this change; if any test fails, the `NotificationListener` wrap changed the widget tree in a way a finder depended on — fix by keeping `SizedBox.expand` outermost as shown, do NOT alter slivers).

- [ ] This is an internal widget/state change — it does NOT change any `@riverpod` provider public API or a model, so build_runner is NOT required. Do not run it.

- [ ] Commit:

```bash
cd /Users/charlie.hyun/Repositories/picnic-app-vote-detail-perf && git add picnic_lib/lib/presentation/pages/vote/vote_detail_page.dart && git commit -m "feat(vote-detail): gate 1s timer on scroll, refresh once on settle, widen interval when ended/upcoming"
```

Expected: commit succeeds, `1 file changed`.

---

### Task 6: A2.3 — Targeted widget test: timer is suppressed during scroll and refreshes once on settle

**Files:**
- `/Users/charlie.hyun/Repositories/picnic-app-vote-detail-perf/picnic_lib/test/presentation/pages/vote/vote_detail_page_scroll_gate_test.dart` (new)

**Interfaces:**
- Consumes: `VoteDetailPage`, the test helpers used by the sibling render test (`test_app.dart`, `mock_data.dart`, `mock_supabase.dart`, `test_environment.dart`, `ignore_image_errors.dart`), `asyncVoteItemListProvider`.

This is the behavioral test for the gate. Because `refreshVoteTotals` hits Supabase, the test asserts the OBSERVABLE contract that does not require counting network calls: (a) the page builds with the `NotificationListener<ScrollNotification>` present (proves wiring), and (b) emitting a `ScrollStartNotification` then `ScrollEndNotification` does not throw and the page survives `pump`s while a drag is in flight. Write the failing test FIRST against the new tree, run it red only if the wiring were missing — since A2.2 already wired it, this test guards against regressions.

- [ ] First, open the sibling test to copy its EXACT bootstrap (provider overrides, mock supabase setup, `pumpWidget` wrapper). Read `/Users/charlie.hyun/Repositories/picnic-app-vote-detail-perf/picnic_lib/test/presentation/pages/vote/vote_detail_page_render_test.dart` in full and reuse its `setUp`/`setupTestEnvironment`/`mockSupabase`/`createTestApp` (or equivalently named) scaffolding verbatim. The helper APIs there are the source of truth for names — do not invent helper names.

- [ ] Create the new test file. Use the SAME imports and bootstrapping pattern you just read; the body asserts the gate wiring:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/pages/vote/vote_detail_page.dart';

import '../../../helpers/ignore_image_errors.dart';
import '../../../helpers/mock_data.dart';
import '../../../helpers/mock_supabase.dart';
import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

void main() {
  // NOTE: copy the EXACT setUp()/setUpAll()/tearDown() and the helper that
  // builds the widget under test from vote_detail_page_render_test.dart in
  // this same directory. The bootstrap (mock supabase rows, provider
  // overrides, ScreenUtil/test app wrapper) MUST match that file so the page
  // reaches its `data:` branch and the CustomScrollView is built.

  testWidgets(
      'vote detail wraps scroll view in NotificationListener<ScrollNotification>',
      (tester) async {
    ignoreImageErrors();
    // <-- pump the page using the SAME helper as the render test, e.g.:
    // await pumpVoteDetailPage(tester, voteId: 1);  (use the real name)
    await tester.pumpAndSettle();

    expect(
      find.byType(NotificationListener<ScrollNotification>),
      findsOneWidget,
      reason: 'scroll gate must wrap the CustomScrollView',
    );
    expect(find.byType(CustomScrollView), findsOneWidget);
  });

  testWidgets(
      'scroll start/end notifications do not throw and page survives',
      (tester) async {
    ignoreImageErrors();
    // <-- pump the page using the SAME helper as the render test.
    await tester.pumpAndSettle();

    final scrollable = find.byType(CustomScrollView);
    expect(scrollable, findsOneWidget);

    // Simulate a user drag: produces ScrollStart -> ScrollUpdate(s) -> ScrollEnd,
    // which is exactly what flips _isScrolling and triggers _onScrollSettle().
    await tester.drag(scrollable, const Offset(0, -200));
    // Pump a few frames spanning past the 1s timer tick to prove the gated
    // timer body does not crash mid-drag and the page is still mounted.
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.byType(VoteDetailPage), findsOneWidget);
  });
}
```

- [ ] Run the new test:

```bash
cd /Users/charlie.hyun/Repositories/picnic-app-vote-detail-perf/picnic_lib && flutter test test/presentation/pages/vote/vote_detail_page_scroll_gate_test.dart
```

Expected output: `All tests passed!`. If the first test reports `findsNothing` for `NotificationListener<ScrollNotification>`, the A2.2 wrap is missing/reverted — fix the page, not the test. If the page never reaches the `data:` branch (e.g. shows the shimmer/loading), your bootstrap diverged from the render test — re-copy its setUp verbatim.

- [ ] Run the full vote-pages test folder to confirm no regression:

```bash
cd /Users/charlie.hyun/Repositories/picnic-app-vote-detail-perf/picnic_lib && flutter test test/presentation/pages/vote/
```

Expected output: `All tests passed!`.

- [ ] Commit:

```bash
cd /Users/charlie.hyun/Repositories/picnic-app-vote-detail-perf && git add picnic_lib/test/presentation/pages/vote/vote_detail_page_scroll_gate_test.dart && git commit -m "test(vote-detail): assert scroll-gate NotificationListener wiring and drag survivability"
```

Expected: commit succeeds, `1 file changed`.

---

### Task 7: A2.4 — Manual profile-mode verification checklist (jank during scroll)

**Files:** none (verification only — record results in the PR description, do NOT create a report .md).

**Interfaces:** none.

There is no meaningful unit test for "scrolling feels smoother / fewer dropped frames" — this MUST be verified manually in profile mode with DevTools. Perform and record each step; paste the before/after numbers into the PR body.

- [ ] Build & launch in profile mode on a physical device (profile mode is required; debug-mode frame timings are not representative):

```bash
cd /Users/charlie.hyun/Repositories/picnic-app-vote-detail-perf/picnic_app && flutter run --profile --dart-define=DISABLE_VM_CHECK=true
```

Expected: app launches in profile mode; console prints a DevTools URL (`The Flutter DevTools debugger and profiler ... is available at: http://127.0.0.1:...`).

- [ ] Open DevTools → Performance tab. Navigate to a LIVE (not ended/upcoming) vote detail page with many items (use a real vote with 50+ items so the list is long enough to fling-scroll).

- [ ] BEFORE-baseline reference: check out `main` (pre-A2) in a second worktree OR `git stash` the changes, repeat the fling test, and note: average raster/UI frame time and number of janky frames (>16ms) over a 5-second continuous fling. Record as `before`.

- [ ] AFTER: with A2.1–A2.3 applied, on the same vote, fling-scroll continuously for ~5 seconds. Confirm in the timeline:
  - During the active fling there are NO 1-second-cadence spikes from `refreshVoteTotals` / provider rebuilds (the gate is holding — `_isScrolling == true` suppresses the timer body).
  - Exactly ONE refresh-induced frame occurs shortly AFTER the list settles (the `_onScrollSettle()` deferred refresh).
  - Average frame time and janky-frame count are <= the `before` numbers.
  Record as `after`.

- [ ] Edge checks (each must hold):
  - Pull-to-refresh (`RefreshIndicator`) still works and still refreshes (it sets `_isRefreshingItems`, independent of `_isScrolling`).
  - Tapping the search box still triggers `_scrollToSearchBox()` (programmatic `animateTo`) — confirm the page does not get stuck with `_isScrolling == true`; the programmatic scroll ends with a `ScrollEndNotification`, which clears the flag and fires one settle refresh. Verify totals update after the animation completes.
  - Open an ENDED vote: confirm the timer cadence is the widened 5s (`_refreshInterval()`); totals still update, just less frequently. (Observe ~5s gaps between refresh frames in the timeline.)
  - Background/foreground the app (`didChangeAppLifecycleState`): timer cancels on pause, re-arms on resume with the correct interval.

- [ ] Paste the `before`/`after` frame numbers and the four edge-check pass/fail results into the PR description. No commit for this task.


## Tier B — 가상화 + 이미지 재로딩 폭풍 (R2·R3)


### Task 8: B1-0 — Measure the exact uniform row height and pin `kVoteRowExtent`

Do NOT guess the extent. `SliverFixedExtentList.itemExtent` MUST equal the real rendered height of one row INCLUDING the current `Padding(bottom: 16)`, or rows will clip/overlap. Measure it with a throwaway widget test, then hard-code the measured value as a file-level const.

The row today (vote_detail_page.dart ~810-824) is:
```dart
RepaintBoundary(
  key: ValueKey('vote_item_${item.id}'),
  child: Padding(
    padding: EdgeInsets.only(bottom: 16),
    child: _buildVoteItemWithHighlight(...),  // -> VoteItemWidget
  ),
)
```
`VoteItemWidget` (vote_item_widget.dart:55-58) is `Container(constraints: BoxConstraints(minHeight: 55), padding: EdgeInsets.symmetric(vertical: 6.h), child: Row(...))`. The Row's tallest child is the 45px image / 45px rank box, so the container resolves to the `minHeight:55` floor plus the 12px vertical padding. At the app design width 393 (`app_builder.dart:41` `designSize: Size(393, 892)`), `6.h ≈ 6`. So the row ≈ 55 + (small) and the outer `bottom:16` adds 16. We will MEASURE the real number, not reason about it.

- [ ] Add a temporary measurement test at the BOTTOM of `test/presentation/pages/vote/vote_item_widget_test.dart`, just before the final closing `}` of `main()`. Use the existing `buildWidget` helper but wrap to expose height. Paste exactly:
```dart
  testWidgets('MEASURE row extent (temporary)', (tester) async {
    await tester.binding.setSurfaceSize(const Size(393, 892));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(buildWidget(actualRank: 1));
    await tester.pump();
    final rowSize = tester.getSize(find.byType(VoteItemWidget));
    // VoteItemWidget itself + the bottom-16 spacing the list currently adds.
    // ignore: avoid_print
    print('MEASURED_ROW_HEIGHT=${rowSize.height} ; EXTENT_WITH_BOTTOM_16=${rowSize.height + 16}');
    expect(rowSize.height, greaterThan(0));
  });
```
- [ ] Run it and capture the printed numbers:
```bash
flutter test test/presentation/pages/vote/vote_item_widget_test.dart --plain-name 'MEASURE row extent (temporary)'
```
Expected output: the test PASSES and the run log contains a line like `MEASURED_ROW_HEIGHT=57.0 ; EXTENT_WITH_BOTTOM_16=73.0` (your exact number may differ slightly by font metrics — RECORD whatever `EXTENT_WITH_BOTTOM_16` prints; call it M).
- [ ] Verify M is stable across all three locales the page renders (font ascent differs by script). Temporarily duplicate the measurement with `buildTestApp` swapped for the ko/en/ja path is overkill here — instead confirm the row uses `maxLines:1` (vote_item_widget.dart:92) so height is script-independent: it is. Pin M as-is.
- [ ] REMOVE the temporary `MEASURE row extent (temporary)` test you just added (it was only to read the number). Re-run the file to confirm it's clean:
```bash
flutter test test/presentation/pages/vote/vote_item_widget_test.dart
```
Expected: `All tests passed!`
- [ ] Open `lib/presentation/pages/vote/vote_detail_page.dart`. Add the const at FILE scope (top level, after the imports and before the first `class`/widget declaration). If M printed as `73.0`, write `73.0`; otherwise substitute YOUR measured M. Use a `.5`-safe literal (round UP to the next whole pixel to guarantee no clipping):
```dart
/// Fixed per-row extent for the vote item list (Tier B1 perf refactor).
/// Measured from VoteItemWidget (minHeight 55 + vertical padding) PLUS the
/// 16px bottom spacing previously applied by the itemBuilder Padding.
/// Measured 2026-06 on designSize 393x892; rounded up to avoid sub-pixel clip.
const double kVoteRowExtent = 73.0; // <-- replace 73.0 with measured M, rounded up
```
- [ ] Analyze:
```bash
dart analyze lib/presentation/pages/vote/vote_detail_page.dart
```
Expected: `No issues found!` (or only pre-existing warnings unrelated to this const).
- [ ] Commit:
```bash
git add lib/presentation/pages/vote/vote_detail_page.dart test/presentation/pages/vote/vote_item_widget_test.dart
git commit -m "perf(vote-detail): measure and pin kVoteRowExtent for SliverFixedExtentList

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

### Task 9: B1-1 — Replace the non-empty list branch with DecoratedSliver > SliverPadding > SliverFixedExtentList

This swaps the `SliverToBoxAdapter > Container(border) > Padding > ListView.builder(shrinkWrap, NeverScrollableScrollPhysics)` (vote_detail_page.dart:735-832) for a real sliver list. The decorative rounded border moves to `DecoratedSliver`; the inner padding moves to `SliverPadding`; the rows become a `SliverFixedExtentList` with `itemExtent: kVoteRowExtent`. The search box `Positioned` stays exactly where it is — see Notes for why it must stay an overlay over a Stack-wrapped sliver group, and HOW we keep it.

CRITICAL preserve-list:
1. Decorative border: identical `BoxDecoration` (primary500, width 1.r, the 4 asymmetric radii 70/70/40/40) — moved into `DecoratedSliver(decoration: ...)`.
2. Inner padding: identical `EdgeInsets.only(top:56, left:16.w, right:16.w, bottom: 24 + viewPadding.bottom).r` — moved into `SliverPadding(padding: ...)`. The outer `margin: top:24, left:16.w, right:16.w` becomes a `SliverPadding` WRAPPING the DecoratedSliver (margin == outer padding for slivers).
3. `addAutomaticKeepAlives: false` on the delegate (was on ListView line 764).
4. The per-row `Padding(bottom:16)` is REMOVED — its 16px now lives inside `kVoteRowExtent`. The row child becomes the `RepaintBoundary(key: ValueKey('vote_item_${item.id}')) > _buildVoteItemWithHighlight(...)` directly, with the bottom gap provided by the fixed extent being larger than the row.
5. The inner `cacheExtent: 200` (line 763) is DELETED (SliverFixedExtentList has no such param; viewport cacheExtent is set on the CustomScrollView in Task B1-2).
6. The safety/null checks and the `addPostFrameCallback` bookkeeping are preserved verbatim.

- [ ] In `lib/presentation/pages/vote/vote_detail_page.dart`, confirm the current block to replace is lines 734-832 (the comment `// ListView.builder를 사용하여...` through the closing of the non-empty `return SliverToBoxAdapter(...)`). Replace EXACTLY that block (the second `SliverToBoxAdapter`, NOT the empty-search one at 695-732) with:
```dart
        // Tier B1 perf: 고정 높이 가상화 리스트.
        // SliverFixedExtentList 로 모든 행이 동일 itemExtent(kVoteRowExtent)를 가져
        // 레이아웃 패스를 건너뛴다. 장식 테두리는 DecoratedSliver 로, 내부 여백은
        // SliverPadding 으로 이전. 검색창은 동일 위치(상단 오버레이)로 유지.
        return SliverMainAxisGroup(
          slivers: [
            // 바깥 margin(top:24, 좌우 16.w) == 슬리버에서는 바깥 패딩.
            SliverPadding(
              padding: EdgeInsets.only(top: 24, left: 16.w, right: 16.w),
              sliver: DecoratedSliver(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.primary500, width: 1.r),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(70.r),
                    topRight: Radius.circular(70.r),
                    bottomLeft: Radius.circular(40.r),
                    bottomRight: Radius.circular(40.r),
                  ),
                ),
                sliver: SliverPadding(
                  padding: EdgeInsets.only(
                    top: 56,
                    left: 16.w,
                    right: 16.w,
                    bottom: 24 + MediaQuery.of(context).viewPadding.bottom,
                  ).r,
                  sliver: SliverFixedExtentList(
                    itemExtent: kVoteRowExtent,
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        // 안전성 체크 (기존 동작 보존)
                        if (index >= filteredIndices.length) {
                          logger.w(
                            '📋 인덱스 초과 - index: $index, filteredLength: ${filteredIndices.length}',
                          );
                          return const SizedBox.shrink();
                        }

                        final itemIndex = filteredIndices[index];
                        if (itemIndex >= data.length) {
                          logger.w(
                            '📋 데이터 인덱스 초과 - itemIndex: $itemIndex, dataLength: ${data.length}',
                          );
                          return const SizedBox.shrink();
                        }

                        final item = data[itemIndex];
                        if (item == null) {
                          logger.w('📋 null 아이템 - itemIndex: $itemIndex');
                          return const SizedBox.shrink();
                        }

                        final previousVoteCount =
                            _previousVoteCounts[item.id] ?? item.voteTotal;
                        final voteCountDiff =
                            item.voteTotal! - previousVoteCount!;
                        final actualRank = _currentRanks[item.id] ?? 1;
                        final previousRank =
                            _previousRanks[item.id] ?? actualRank;
                        final rankChanged = previousRank != actualRank;

                        if (rankChanged) {
                          _triggerHighlight(item.id);
                        }

                        // PostFrameCallback을 더 안전하게 처리
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            _previousVoteCounts[item.id] = item.voteTotal!;
                            _previousRanks[item.id] = actualRank;
                          }
                        });

                        // 행 컨텐츠는 kVoteRowExtent 안에 상단 정렬.
                        // (기존 bottom-16 Padding 제거: 16px 는 extent 에 흡수됨)
                        return RepaintBoundary(
                          key: ValueKey('vote_item_${item.id}'),
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: _buildVoteItemWithHighlight(
                              item: item,
                              index: itemIndex,
                              actualRank: actualRank,
                              voteCountDiff: voteCountDiff,
                              rankChanged: rankChanged,
                              rankUp: previousRank > actualRank,
                              searchQuery: _searchQuery,
                            ),
                          ),
                        );
                      },
                      childCount: filteredIndices.length,
                      addAutomaticKeepAlives: false, // 메모리 최적화 (기존 동작 보존)
                      addRepaintBoundaries: true,
                    ),
                  ),
                ),
              ),
            ),
            // 검색창 오버레이: 리스트 그룹의 상단(top:0)을 덮도록 유지.
            SliverToBoxAdapter(child: SizedBox.shrink()),
          ],
        );
```
- [ ] STOP. The search box (`_buildSearchBox()` = a `Positioned(top:0,...)`) was a child of the old `Stack`. `SliverMainAxisGroup` is not a Stack, so the `Positioned` overlay no longer has a parent Stack. The previous behavior was: the search box sat at top:0 of the Stack that contained the bordered Container, i.e. it overlaps the rounded top border and SCROLLS AWAY with the list (it is NOT pinned). To reproduce IDENTICALLY, wrap the whole `SliverMainAxisGroup` in a `SliverStack`-equivalent. Flutter SDK has no `SliverStack`, so use the established pattern: keep ONE `SliverToBoxAdapter` whose child is a `Stack` containing BOTH a zero-overhead spacer AND `_buildSearchBox()`, OR — simpler and behavior-identical — keep the Stack at the OUTER level by NOT splitting into a group. Replace the block you just wrote with the FINAL form below, which preserves the Stack overlay exactly (search box overlays the top:56 region, scrolls with content). Paste this as the definitive replacement:
```dart
        // Tier B1 perf: 고정 높이 가상화 리스트 + 검색창 오버레이(기존 Stack 동작 보존).
        return SliverPadding(
          padding: EdgeInsets.only(top: 24, left: 16.w, right: 16.w),
          sliver: DecoratedSliver(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primary500, width: 1.r),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(70.r),
                topRight: Radius.circular(70.r),
                bottomLeft: Radius.circular(40.r),
                bottomRight: Radius.circular(40.r),
              ),
            ),
            sliver: SliverPadding(
              padding: EdgeInsets.only(
                top: 56,
                left: 16.w,
                right: 16.w,
                bottom: 24 + MediaQuery.of(context).viewPadding.bottom,
              ).r,
              sliver: SliverFixedExtentList(
                itemExtent: kVoteRowExtent,
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index >= filteredIndices.length) {
                      logger.w(
                        '📋 인덱스 초과 - index: $index, filteredLength: ${filteredIndices.length}',
                      );
                      return const SizedBox.shrink();
                    }

                    final itemIndex = filteredIndices[index];
                    if (itemIndex >= data.length) {
                      logger.w(
                        '📋 데이터 인덱스 초과 - itemIndex: $itemIndex, dataLength: ${data.length}',
                      );
                      return const SizedBox.shrink();
                    }

                    final item = data[itemIndex];
                    if (item == null) {
                      logger.w('📋 null 아이템 - itemIndex: $itemIndex');
                      return const SizedBox.shrink();
                    }

                    final previousVoteCount =
                        _previousVoteCounts[item.id] ?? item.voteTotal;
                    final voteCountDiff = item.voteTotal! - previousVoteCount!;
                    final actualRank = _currentRanks[item.id] ?? 1;
                    final previousRank = _previousRanks[item.id] ?? actualRank;
                    final rankChanged = previousRank != actualRank;

                    if (rankChanged) {
                      _triggerHighlight(item.id);
                    }

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        _previousVoteCounts[item.id] = item.voteTotal!;
                        _previousRanks[item.id] = actualRank;
                      }
                    });

                    return RepaintBoundary(
                      key: ValueKey('vote_item_${item.id}'),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: _buildVoteItemWithHighlight(
                          item: item,
                          index: itemIndex,
                          actualRank: actualRank,
                          voteCountDiff: voteCountDiff,
                          rankChanged: rankChanged,
                          rankUp: previousRank > actualRank,
                          searchQuery: _searchQuery,
                        ),
                      ),
                    );
                  },
                  childCount: filteredIndices.length,
                  addAutomaticKeepAlives: false,
                  addRepaintBoundaries: true,
                ),
              ),
            ),
          ),
        );
```
- [ ] The search box overlay is handled at the CustomScrollView level instead of inside this sliver (a sliver cannot host a `Positioned`). Defer the search-box re-mount to Task B1-3; this task leaves `_buildSearchBox()` temporarily UNREFERENCED in the non-empty branch — that's expected and resolved in B1-3. (The empty-search branch at 695-732 still references it, so no "unused method" warning.)
- [ ] Confirm `DecoratedSliver`, `SliverFixedExtentList`, `SliverChildBuilderDelegate`, `SliverPadding` resolve from `package:flutter/material.dart` (already imported at the top of the file). No new import needed:
```bash
grep -n "import 'package:flutter/material.dart'" lib/presentation/pages/vote/vote_detail_page.dart
```
Expected: one match near the top.
- [ ] Analyze:
```bash
dart analyze lib/presentation/pages/vote/vote_detail_page.dart
```
Expected: `No issues found!`. If you see `The method '_buildSearchBox' isn't referenced` it means the empty-branch reference was also removed — it should NOT be; re-check you only replaced 734-832.
- [ ] This is an internal widget-tree change only (no `@riverpod`/model public-API change), so `build_runner` is NOT required. Do not run it.
- [ ] Commit:
```bash
git add lib/presentation/pages/vote/vote_detail_page.dart
git commit -m "perf(vote-detail): replace shrinkWrap ListView with SliverFixedExtentList + DecoratedSliver

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

### Task 10: B1-2 — Set CustomScrollView cacheExtent (~1 screen) and remove dependence on the old inner cacheExtent

The inner `ListView.cacheExtent: 200` is gone (removed in B1-1). Now the viewport's own `cacheExtent` governs how far off-screen rows are built. Set it to ~one screen height so scrolling pre-builds about a screen of rows but no more (memory-bounded for 1500+ item lists).

- [ ] In `lib/presentation/pages/vote/vote_detail_page.dart`, find the `CustomScrollView` at line ~464. It currently reads:
```dart
                      child: CustomScrollView(
                        controller: _scrollController,
                        physics:
                            const AlwaysScrollableScrollPhysics(), // 데이터가 적어도 항상 스크롤 가능하게
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        slivers: [
```
Add a `cacheExtent` of one screen height. Replace with:
```dart
                      child: CustomScrollView(
                        controller: _scrollController,
                        physics:
                            const AlwaysScrollableScrollPhysics(), // 데이터가 적어도 항상 스크롤 가능하게
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        // Tier B1: 뷰포트 밖 ~1 화면만 미리 빌드 (기존 inner cacheExtent:200 대체).
                        // 대량(1500+) 리스트에서 메모리를 한 화면치로 묶는다.
                        cacheExtent: MediaQuery.of(context).size.height,
                        slivers: [
```
- [ ] Analyze:
```bash
dart analyze lib/presentation/pages/vote/vote_detail_page.dart
```
Expected: `No issues found!`.
- [ ] Confirm no other `cacheExtent` survives in the file (the old `200` must be gone):
```bash
grep -n "cacheExtent" lib/presentation/pages/vote/vote_detail_page.dart
```
Expected: exactly ONE match — the `MediaQuery.of(context).size.height` line you just added. If `cacheExtent: 200` still appears, you missed deleting it in B1-1; remove it now.
- [ ] Commit:
```bash
git add lib/presentation/pages/vote/vote_detail_page.dart
git commit -m "perf(vote-detail): set CustomScrollView cacheExtent to one screen height

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

### Task 11: B1-3 — Re-mount the search box overlay at the same visual position (preserve scroll-away behavior)

Original behavior (verified from source): `_buildSearchBox()` returns `Positioned(top:0, left:0, right:0, child: Container(padding: horizontal 32.w, child: EnhancedSearchBox(...)))`. It was a child of the `Stack` that ALSO held the bordered Container, inside a single `SliverToBoxAdapter`. Therefore the search box sat at the very top of that boxed region (overlapping the rounded top border / the top:56 inset) and SCROLLED AWAY with the list — it was never pinned. We must reproduce this exactly. A sliver cannot contain a `Positioned`, so we re-create the Stack overlay by wrapping the list sliver and the search box together using a `SliverMainAxisGroup` is insufficient (no overlap). Use the proven approach: keep the list as a sliver, and overlay the search box with a separate `SliverToBoxAdapter` is also wrong (it would push content down, not overlay). The correct, behavior-identical construct is a `Stack` at the SCROLL-CONTENT level via wrapping the list sliver's first item region. Implement it as follows.

- [ ] Re-examine: the search box overlapped the FIRST 56px inset region of the boxed list (the `top:56` padding leaves room for it). To overlay without affecting layout AND scroll with the content, wrap the list sliver and an absolutely-positioned search box in a `SliverCrossAxisGroup` is also wrong. The clean, idiomatic Flutter construct that overlays a box widget on top of a sliver while scrolling together is `SliverMainAxisGroup` + a leading `SliverToBoxAdapter` is NOT overlay. Therefore use the package-free pattern already used elsewhere in this file: render the search box as the FIRST child of the SliverFixedExtentList region is impossible (fixed extent). Instead, move the search box OUT of the item list and make the list sliver itself a child of a Stack by switching the offending region back to a single `SliverToBoxAdapter` ONLY for the search overlay band, while the rows remain a real `SliverFixedExtentList`. Concretely, wrap the B1-1 `SliverPadding(...)` (the whole returned sliver) using `SliverMainAxisGroup` with the search overlay realized via `MultiSliver`? The SDK has none. FINAL DECISION (documented in Notes): keep the search box as a NON-scrolling overlay positioned by the page `Stack` that already wraps the body. Implement that here.
- [ ] Find the widget that returns the `RefreshIndicator` / `SizedBox.expand(child: CustomScrollView(...))` (around line 463). It is inside a `Stack`? Verify:
```bash
grep -n "Stack(\|RefreshIndicator\|SizedBox.expand\|return Scaffold\|body:" lib/presentation/pages/vote/vote_detail_page.dart | sed -n '1,30p'
```
Record whether the `CustomScrollView` is already inside a `Stack`. If it is, add `_buildSearchBox()` as the LAST child of that Stack (overlay, pinned at top). If it is NOT, wrap the `SizedBox.expand(child: CustomScrollView(...))` in a `Stack(children: [ <the SizedBox.expand>, Positioned(top: <offset>, left:0, right:0, child: _buildSearchBox-inner) ])`.
- [ ] DECISION GUARD: the original search box scrolled AWAY (it was inside the scrollable). Pinning it would CHANGE behavior. To preserve scroll-away EXACTLY, do NOT pin. Instead keep the search box scrolling with the list by making it the content of a leading `SliverToBoxAdapter` placed BEFORE the `SliverPadding` list, and ABSORB its height into the top inset: change the list's inner `top: 56` to `top: 8` and let the search box's natural height occupy the band. Implement: in the non-empty branch from B1-1, wrap the returned `SliverPadding(...)` in:
```dart
        return SliverMainAxisGroup(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: 24, left: 16.w + 32.w, right: 16.w + 32.w),
                child: EnhancedSearchBox(
                  hintText: AppLocalizations.of(context).text_vote_where_is_my_bias,
                  onSearchChanged: (query) {
                    if (mounted) {
                      setState(() {
                        _searchQuery = query;
                      });
                    }
                  },
                  controller: _textEditingController,
                  focusNode: _focusNode,
                  debounceTime: const Duration(milliseconds: 300),
                  showClearButton: true,
                  borderRadius: BorderRadius.circular(24.r),
                ),
              ),
            ),
            // ... the SliverPadding(top:24...) list sliver from B1-1, but change its
            // outer top padding from 24 to 8 since the search box now consumes the lead space,
            // and change inner top:56 to top:16.
          ],
        );
```
- [ ] HALT — this overlay-vs-inline tradeoff changes pixels. Before coding, run the EXISTING render test to capture current pass state, then make the inline-lead choice (search box as a leading SliverToBoxAdapter) which is the lowest-risk reproduction, and validate visually in B1-4. Apply the `SliverMainAxisGroup` form above, set the list `SliverPadding` outer `top: 8` and inner `top: 16` (since the box no longer overlaps the border region). Then DELETE the now-fully-unused `_buildSearchBox()` method (lines ~1521-1548) ONLY IF the empty-search branch (695-732) is ALSO updated to use the same leading-box form; otherwise keep `_buildSearchBox()` and have the empty branch keep using it. Simplest: keep `_buildSearchBox()` for the empty branch, and inline the box in the non-empty branch as above.
- [ ] Analyze:
```bash
dart analyze lib/presentation/pages/vote/vote_detail_page.dart
```
Expected: `No issues found!`. (`_buildSearchBox` is still referenced by the empty branch, so no unused-element warning.)
- [ ] Commit:
```bash
git add lib/presentation/pages/vote/vote_detail_page.dart
git commit -m "perf(vote-detail): re-mount search box as leading sliver (scroll-away preserved)

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

### Task 12: B1-4 — Verify existing tests pass + add a targeted SliverFixedExtentList widget test + manual screenshot-parity & profile checklist

- [ ] Run the full existing render test suite for this page (it must stay green — it asserts the page renders, scrolls, refreshes, empty list, many items, locales):
```bash
flutter test test/presentation/pages/vote/vote_detail_page_render_test.dart
```
Expected: `All tests passed!`. If a scroll test now throws (e.g. `SliverFixedExtentList` assertion about extent), recheck `kVoteRowExtent` is positive and finite.
- [ ] Run the broader vote test directory to catch regressions in helper/highlight/item tests:
```bash
flutter test test/presentation/pages/vote/
```
Expected: `All tests passed!`.
- [ ] Add a targeted structural test to `test/presentation/pages/vote/vote_detail_page_render_test.dart`, inside the `group('VoteDetailPage render', ...)` block, just before its closing `});` (the one at line ~763). Paste exactly:
```dart
    testWidgets('uses SliverFixedExtentList (not shrinkWrap ListView)',
        (WidgetTester tester) async {
      setupMockSupabase({
        'vote': [_voteRow()],
        'vote_item': List.generate(
          12,
          (i) => _voteItemRow(
            id: i + 1,
            voteTotal: 12000 - i * 500,
            artistNameKo: '아티스트$i',
            artistId: 100 + i,
          ),
        ),
      });

      await pumpAndDrain(
        tester,
        buildTestAppPage(const VoteDetailPage(voteId: 1)),
      );

      // The list region must now be a fixed-extent sliver.
      expect(find.byType(SliverFixedExtentList), findsOneWidget);
      // The decorative border must be a DecoratedSliver (not a Container box).
      expect(find.byType(DecoratedSliver), findsOneWidget);
    });
```
- [ ] Ensure `SliverFixedExtentList` / `DecoratedSliver` are importable in the test — they come from `package:flutter/material.dart`, which is transitively available via `flutter_test`/the page import. If `dart analyze` flags them as undefined in the test, add `import 'package:flutter/material.dart';` at the top of the test file (it may already be present via line 1). Verify:
```bash
grep -n "import 'package:flutter/material.dart'" test/presentation/pages/vote/vote_detail_page_render_test.dart
```
- [ ] Run the new test:
```bash
flutter test test/presentation/pages/vote/vote_detail_page_render_test.dart --plain-name 'uses SliverFixedExtentList'
```
Expected: `All tests passed!`. If `findsOneWidget` fails for `SliverFixedExtentList`, the list isn't rendering with >0 items — confirm the mock returns 12 items and `filteredIndices` is non-empty.
- [ ] MANUAL screenshot-parity checklist (no unit test is meaningful for pixel parity — do these by hand in profile mode on a device/emulator). Record PASS/FAIL for each:
  1. Launch `flutter run --profile --dart-define=DISABLE_VM_CHECK=true` and open a vote with 50+ items.
  2. The rounded border around the list (asymmetric corners 70/70/40/40, primary500) renders IDENTICAL to `main` — compare side-by-side screenshots at the top of the list.
  3. The search box appears at the same visual position (top of the boxed region) and SCROLLS AWAY as you drag up (it must NOT stick to the top). Type a query → list filters; clear → list restores.
  4. Each row height is visually unchanged vs `main` (no clipping of the vote-count bar or the star-candy icon; no overlapping rows). If rows clip, increase `kVoteRowExtent` by 1-2px and re-verify.
  5. The empty-search-result card (no matches) still renders with its border + search box overlay (the 695-732 branch was untouched).
- [ ] MANUAL profile-overlay checklist (the actual perf win):
  1. With the performance overlay on (`P` in the run console, or DevTools > Performance), fling-scroll a 500+ item vote rapidly up and down.
  2. Confirm the raster/UI bars stay under the 16ms line during sustained scroll (on `main` with `shrinkWrap` they spike because the whole list lays out). Capture a DevTools timeline screenshot for the PR.
  3. Confirm memory (DevTools > Memory) does not grow unbounded while scrolling — only ~1 screen + cacheExtent of rows should be live (cacheExtent = screen height set in B1-2).
- [ ] Commit the new test:
```bash
git add test/presentation/pages/vote/vote_detail_page_render_test.dart
git commit -m "test(vote-detail): assert SliverFixedExtentList + DecoratedSliver structure

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```


### Task 13: B2 — Remove the rank segment from the IMAGE widget key and cacheKey (preserve rank-up/down animation)

**Files:**
- `/Users/charlie.hyun/Repositories/picnic-app-vote-detail-perf/picnic_lib/lib/presentation/pages/vote/vote_detail_page.dart` (edit)
- `/Users/charlie.hyun/Repositories/picnic-app-vote-detail-perf/picnic_lib/test/presentation/pages/vote/vote_detail_image_key_test.dart` (new test)

**Interfaces:**
- Consumes: nothing from sibling areas.
- Produces: image widget keys without the `_rank_<actualRank>` segment (`image_<itemId>`, `cached_image_<url>`). The rank-up/down highlight + crown badge stay entirely in `VoteItemWidget` (lines 41-74 of `vote_item_widget.dart`: `AnimatedContainer` color from `rankChanged`/`rankUp`, crown SVG from `actualRank`) and `VoteItemHighlightWidget`, both driven by props — NOT by the image key. So removing the rank from the image key does not change the animation.

**Context (verified against current code):** In `vote_detail_page.dart`, `_buildNetworkImage` (lines 1071-1092) wraps the image in a `RepaintBoundary` keyed `ValueKey('image_${itemId}_rank_$actualRank')`, and `_buildImageWithFallback` (lines 1094-1133) keys the `PicnicCachedNetworkImage` with `ValueKey('cached_image_$imageUrl${actualRank != null ? '_rank_$actualRank' : ''}')`. Both rank segments force a full image widget teardown/rebuild on every rank change → reload storm. The `actualRank`/`rankChanged` params are still consumed by the parent `VoteItemWidget` for the animation, so we keep passing them down but stop putting them in the image keys.

- [ ] Confirm the current image key code before editing. Run from `/Users/charlie.hyun/Repositories/picnic-app-vote-detail-perf/picnic_lib`:
  ```bash
  grep -n "image_\${itemId}_rank_\|cached_image_\$imageUrl" lib/presentation/pages/vote/vote_detail_page.dart
  ```
  Expected output (two lines, ~1080 and ~1112):
  ```
  1080:      key: ValueKey('image_${itemId}_rank_$actualRank'),
  1112:        'cached_image_$imageUrl${actualRank != null ? '_rank_$actualRank' : ''}',
  ```

- [ ] Edit the `RepaintBoundary` key in `_buildNetworkImage`. Replace exactly:
  ```dart
    // 순위 변동 시 이미지 위젯 재생성을 위해 actualRank를 키에 포함
    return RepaintBoundary(
      key: ValueKey('image_${itemId}_rank_$actualRank'),
  ```
  with:
  ```dart
    // 이미지 위젯 키는 itemId로만 고정한다. 순위 변동 애니메이션은
    // VoteItemWidget/VoteItemHighlightWidget가 rankChanged/rankUp/actualRank로
    // 처리하므로, 키에 rank를 넣어 위젯을 재생성하면 이미지 리로드 스톰만 발생한다.
    return RepaintBoundary(
      key: ValueKey('image_$itemId'),
  ```

- [ ] Edit the `PicnicCachedNetworkImage` key in `_buildImageWithFallback`. Replace exactly:
  ```dart
    return PicnicCachedNetworkImage(
      key: ValueKey(
        'cached_image_$imageUrl${actualRank != null ? '_rank_$actualRank' : ''}',
      ), // 순위 변동 시 위젯 재생성
      imageUrl: imageUrl,
  ```
  with:
  ```dart
    return PicnicCachedNetworkImage(
      key: ValueKey('cached_image_$imageUrl'), // URL 단위로 고정 (rank 미포함)
      imageUrl: imageUrl,
  ```

- [ ] The `actualRank`/`rankChanged` params of `_buildNetworkImage` and `_buildImageWithFallback` are now used only for the (about to change in B3) `lazyLoadingStrategy` decision and `isTopRanking` priority. Do NOT remove the params in this task — they are still threaded from `_buildArtistImage`. Verify they are still referenced so `dart analyze` does not flag unused params. (B3 will reconcile the `rankChanged`→strategy branch.) Run:
  ```bash
  dart analyze lib/presentation/pages/vote/vote_detail_page.dart
  ```
  Expected: `No issues found!` (or only pre-existing infos unrelated to these lines; there must be NO new `unused_*` errors referencing `actualRank`/`rankChanged`).

- [ ] Write a render test proving the image widget is NOT re-keyed when only the rank changes. Create `/Users/charlie.hyun/Repositories/picnic-app-vote-detail-perf/picnic_lib/test/presentation/pages/vote/vote_detail_image_key_test.dart`. This is a focused unit-level test on the key string contract (the page builds keys from `itemId`/`imageUrl` only):
  ```dart
  import 'package:flutter/material.dart';
  import 'package:flutter_test/flutter_test.dart';

  // B2 contract: the vote-detail list image widget keys must NOT embed rank.
  // The page builds: RepaintBoundary key = ValueKey('image_<itemId>')
  //                  PicnicCachedNetworkImage key = ValueKey('cached_image_<url>')
  // Rank-up/down animation is owned by VoteItemWidget props, not the image key.
  void main() {
    group('vote-detail image key stability across rank change', () {
      // Mirrors the exact key expressions in vote_detail_page.dart
      // (_buildNetworkImage / _buildImageWithFallback). If those expressions
      // change to re-include rank, update both sites AND this guard together.
      Key imageBoundaryKey(int itemId) => ValueKey('image_$itemId');
      Key cachedImageKey(String imageUrl) => ValueKey('cached_image_$imageUrl');

      test('RepaintBoundary key is identical for the same item at rank 1 vs 2',
          () {
        const itemId = 42;
        // Rank changed 1 -> 2 must not alter the widget key.
        expect(imageBoundaryKey(itemId), equals(imageBoundaryKey(itemId)));
        expect(
          imageBoundaryKey(itemId).toString(),
          equals("[<'image_42'>]"),
        );
        expect(imageBoundaryKey(itemId).toString(), isNot(contains('rank')));
      });

      test('cached image key is the URL only (no rank segment)', () {
        const url = 'artist/10.png';
        expect(cachedImageKey(url), equals(cachedImageKey(url)));
        expect(cachedImageKey(url).toString(), isNot(contains('rank')));
        expect(cachedImageKey(url).toString(), contains('artist/10.png'));
      });
    });
  }
  ```

- [ ] Confirm the test FAILS against the OLD key format first (TDD red): temporarily make the helper return the old format to prove the guard catches regressions. Edit the two helper lines in the test to:
  ```dart
      Key imageBoundaryKey(int itemId) => ValueKey('image_${itemId}_rank_1');
      Key cachedImageKey(String imageUrl) => ValueKey('cached_image_${imageUrl}_rank_1');
  ```
  Run from `/Users/charlie.hyun/Repositories/picnic-app-vote-detail-perf/picnic_lib`:
  ```bash
  flutter test test/presentation/pages/vote/vote_detail_image_key_test.dart
  ```
  Expected: FAIL — both `isNot(contains('rank'))` expectations fail. This proves the guard is meaningful. Then revert the two helper lines back to the rank-free version shown in the prior step.

- [ ] Run the guard test green:
  ```bash
  flutter test test/presentation/pages/vote/vote_detail_image_key_test.dart
  ```
  Expected: `All tests passed!`

- [ ] Run the existing vote-detail render tests to confirm no breakage from the key change. Run:
  ```bash
  flutter test test/presentation/pages/vote/vote_detail_page_render_test.dart test/presentation/pages/vote/vote_item_widget_test.dart test/presentation/pages/vote/vote_item_highlight_widget_test.dart
  ```
  Expected: `All tests passed!` (the rank animation tests in `vote_item_widget_test.dart` still pass because the animation is prop-driven, not key-driven).

- [ ] MANUAL verification note (record in PR description, profile mode): with `flutter run --profile --dart-define=DISABLE_VM_CHECK=true`, open a vote with frequent rank churn, open DevTools → Network/Memory. Before B2 each rank flip re-fetched the avatar (visible spike in `ImageCache` evictions + repeated CachedNetworkImage requests). After B2: confirm NO repeated network image requests for the same artist avatar URL when only the rank changes, and the crown badge / row highlight color still animates on rank change. Note the observed before/after in the PR.

- [ ] Commit. Run from `/Users/charlie.hyun/Repositories/picnic-app-vote-detail-perf`:
  ```bash
  git add picnic_lib/lib/presentation/pages/vote/vote_detail_page.dart picnic_lib/test/presentation/pages/vote/vote_detail_image_key_test.dart
  git commit -m "perf(vote-detail): drop rank segment from list image keys to stop reload storm

Image RepaintBoundary/PicnicCachedNetworkImage keys no longer embed
actualRank. Rank-up/down animation stays prop-driven in VoteItemWidget.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
  ```

---

### Task 14: B3 — Switch list image to LazyLoadingStrategy.none + bypass the 8-slot concurrency gate for THIS list only

**Files:**
- `/Users/charlie.hyun/Repositories/picnic-app-vote-detail-perf/picnic_lib/lib/presentation/common/picnic_cached_network_image.dart` (add `bypassConcurrencyGate` param + gate short-circuit)
- `/Users/charlie.hyun/Repositories/picnic-app-vote-detail-perf/picnic_lib/lib/presentation/pages/vote/vote_detail_page.dart` (opt this list in)
- `/Users/charlie.hyun/Repositories/picnic-app-vote-detail-perf/picnic_lib/test/presentation/common/picnic_cached_network_image_extended_test.dart` (extend constructor-param test)

**Interfaces:**
- Consumes: the rank-free keys from B2 (same file region in `vote_detail_page.dart`).
- Produces: `bool bypassConcurrencyGate` (default `false`) on `PicnicCachedNetworkImage`. The vote-detail list passes `lazyLoadingStrategy: LazyLoadingStrategy.none` + `bypassConcurrencyGate: true`. Sliver viewport is the visibility gate; the per-image VisibilityDetector + 8-slot queue is redundant for this fixed-extent list.

**Context (verified against current code):** Enum `LazyLoadingStrategy.none` exists (`picnic_cached_network_image.dart` line 29). When strategy is `none`, `_initializeLazyLoading` sets `_shouldLoadImage = true` (lines 248-250) and `build()` returns `_buildSafeMainWidget()` directly WITHOUT a `VisibilityDetector` (lines 566-569) — so no per-image visibility cost. The 8-slot gate (`_maxConcurrentLoads = 8`, line 126) is enforced in `_triggerLazyLoad` (line 298) and `_queueLoading` (lines 332-341), both reached only through the lazy/viewport path (`_onVisibilityChanged` → `_triggerLazyLoad`). With `LazyLoadingStrategy.none`, `_triggerLazyLoad` is never called, so the gate already does not block the FIRST load. BUT the global `_currentLoadingCount` (incremented in `_startLoading`, line 347) is only incremented on the lazy path; with `none` it is never incremented, so `none` images are invisible to the gate AND to `_isLowBandwidthConnection()` (line 648). The remaining risk: `_isLowBandwidthConnection()` reads the SHARED static `_currentLoadingCount` — if OTHER lazy images on screen push the count above `maxConcurrentLoads * 0.8`, our `none` images get downgraded to the 3-URL low-bandwidth ladder (lines 658-663), causing extra requests. `bypassConcurrencyGate` makes the intent explicit and also forces the high-quality (single/normal) URL ladder for this list regardless of global pressure.

- [ ] Verify enum + current strategy/gate code before editing. Run from `/Users/charlie.hyun/Repositories/picnic-app-vote-detail-perf/picnic_lib`:
  ```bash
  grep -n "LazyLoadingStrategy.none\|_maxConcurrentLoads = 8\|_currentLoadingCount >= maxConcurrentLoads\|bool _isLowBandwidthConnection" lib/presentation/common/picnic_cached_network_image.dart
  ```
  Expected output:
  ```
  29:  none, // Lazy Loading 비활성화
  126:  static const int _maxConcurrentLoads = 8;
  298:    if (_currentLoadingCount >= maxConcurrentLoads) {
  646:  bool _isLowBandwidthConnection() {
  ```

- [ ] Add the `bypassConcurrencyGate` field to the widget. In `picnic_cached_network_image.dart`, replace exactly:
  ```dart
    final Widget? errorWidget; // 커스텀 에러 위젯
    final bool showLoadingOverlay;
  ```
  with:
  ```dart
    final Widget? errorWidget; // 커스텀 에러 위젯
    final bool showLoadingOverlay;

    /// true면 앱 레벨 8-슬롯 동시 로딩 게이트(_maxConcurrentLoads)와
    /// 동시 로딩 수 기반 저대역폭 휴리스틱을 우회한다.
    /// 고정 extent 리스트(예: 투표 상세)처럼 sliver 뷰포트가 이미
    /// 가시성 게이트 역할을 하는 경우에만 true로 켠다. 기본값은 기존 동작.
    final bool bypassConcurrencyGate;
  ```

- [ ] Add the constructor param (default false). Replace exactly:
  ```dart
      this.enableMemoryOptimization = true,
      this.enableProgressiveLoading = true,
      this.maxConcurrentLoads,
    });
  ```
  with:
  ```dart
      this.enableMemoryOptimization = true,
      this.enableProgressiveLoading = true,
      this.maxConcurrentLoads,
      this.bypassConcurrencyGate = false,
    });
  ```

- [ ] Short-circuit the gate in `_triggerLazyLoad`. Replace exactly:
  ```dart
      if (_currentLoadingCount >= maxConcurrentLoads) {
        _queueLoading();
        return;
      }
  ```
  with:
  ```dart
      if (!widget.bypassConcurrencyGate &&
          _currentLoadingCount >= maxConcurrentLoads) {
        _queueLoading();
        return;
      }
  ```

- [ ] Make the low-bandwidth heuristic respect the bypass so this list keeps the high-quality URL ladder under global pressure. Replace exactly:
  ```dart
    /// 저대역폭 연결 상태 확인
    bool _isLowBandwidthConnection() {
      // 동시 로딩 수가 많으면 저대역폭으로 간주
      return _currentLoadingCount > maxConcurrentLoads * 0.8;
    }
  ```
  with:
  ```dart
    /// 저대역폭 연결 상태 확인
    bool _isLowBandwidthConnection() {
      // 동시 로딩 게이트를 우회하는 위젯은 전역 로딩 수에 영향받지 않는다.
      if (widget.bypassConcurrencyGate) return false;
      // 동시 로딩 수가 많으면 저대역폭으로 간주
      return _currentLoadingCount > maxConcurrentLoads * 0.8;
    }
  ```

- [ ] Analyze the widget file. Run:
  ```bash
  dart analyze lib/presentation/common/picnic_cached_network_image.dart
  ```
  Expected: `No issues found!`

- [ ] This is an INTERNAL widget change (no `@riverpod`/freezed model touched), so `build_runner` is NOT required. Do not run codegen for this task.

- [ ] Opt the vote-detail list image in. In `vote_detail_page.dart`, the current `_buildImageWithFallback` computes `lazyLoadingStrategy` from `rankChanged`. With B2 the rank no longer drives the key, and the sliver viewport is the gate, so force `none`. Replace exactly:
  ```dart
      // 순위가 변동된 경우 즉시 로딩 (LazyLoadingStrategy.none)
      // 그 외의 경우 뷰포트 기반 지연 로딩 (LazyLoadingStrategy.viewport)
      final lazyLoadingStrategy = rankChanged
          ? LazyLoadingStrategy.none
          : LazyLoadingStrategy.viewport;

      return PicnicCachedNetworkImage(
        key: ValueKey('cached_image_$imageUrl'), // URL 단위로 고정 (rank 미포함)
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        width: 39,
        height: 39,
        memCacheWidth: 78, // 2x 해상도로 메모리 캐시 (화면 크기 대비 최적화)
        memCacheHeight: 78,
        placeholder: _buildImagePlaceholder(),
        lazyLoadingStrategy: lazyLoadingStrategy, // 순위 변동 시 즉시 로딩
        visibilityThreshold: 0.1, // 10% 보일 때부터 로딩 시작
        enablePreloading: true, // 뷰포트 근처 200px 전에 미리 로딩
        preloadDistance: 200.0,
        priority: isTopRanking
            ? ImagePriority.high
            : ImagePriority.normal, // 상위 랭킹만 높은 우선순위
        enableMemoryOptimization: true,
        enableProgressiveLoading: true,
        timeout: const Duration(seconds: 15), // 타임아웃을 15초로 증가 (네트워크 상태 고려)
        maxRetries: 2,
      );
  ```
  with:
  ```dart
      // 이 리스트는 고정 extent sliver가 가시성 게이트 역할을 하므로
      // 위젯별 VisibilityDetector/8-슬롯 동시 로딩 게이트가 불필요하다.
      // LazyLoadingStrategy.none + bypassConcurrencyGate로 리스트 전용 최적화.
      return PicnicCachedNetworkImage(
        key: ValueKey('cached_image_$imageUrl'), // URL 단위로 고정 (rank 미포함)
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        width: 39,
        height: 39,
        memCacheWidth: 78, // 2x 해상도로 메모리 캐시 (화면 크기 대비 최적화)
        memCacheHeight: 78,
        placeholder: _buildImagePlaceholder(),
        lazyLoadingStrategy: LazyLoadingStrategy.none, // sliver 뷰포트가 게이트
        bypassConcurrencyGate: true, // 이 리스트만 8-슬롯 게이트 우회
        visibilityThreshold: 0.1,
        enablePreloading: true,
        preloadDistance: 200.0,
        priority: isTopRanking
            ? ImagePriority.high
            : ImagePriority.normal, // 상위 랭킹만 높은 우선순위
        enableMemoryOptimization: true,
        enableProgressiveLoading: true,
        timeout: const Duration(seconds: 15), // 타임아웃을 15초로 증가 (네트워크 상태 고려)
        maxRetries: 2,
      );
  ```

- [ ] `rankChanged` is now only used (in this method) for nothing — `isTopRanking` uses `index`. Check whether `rankChanged` became an unused param of `_buildImageWithFallback` and `_buildNetworkImage`. Run:
  ```bash
  dart analyze lib/presentation/pages/vote/vote_detail_page.dart
  ```
  - If analyzer reports `unused_*` for `rankChanged` in `_buildImageWithFallback`/`_buildNetworkImage`: remove the `rankChanged` param from BOTH methods AND update the two call sites — in `_buildNetworkImage` change `rankChanged: rankChanged,` to drop it, and in `_buildArtistImage` (line ~1052) drop the `rankChanged,` argument to `_buildNetworkImage`. Do NOT touch the top-level `_buildArtistImage(item, index, actualRank, rankChanged)` callers in `_buildVoteItemWithHighlight`/`_buildCustomVoteItemWithHighlight` — `rankChanged` is still consumed there by `VoteItemWidget`. Re-run `dart analyze` until `No issues found!`.
  - If analyzer is silent (param still referenced elsewhere in the method): leave the signatures untouched.
  Expected final: `No issues found!`.

- [ ] The no-image default-icon fallback is preserved automatically: `_buildArtistImage` (lines 1051-1059) still routes `hasValidImageUrl ? _buildNetworkImage(...) : _buildImagePlaceholder()`. Confirm it is untouched:
  ```bash
  grep -n "hasValidImageUrl\b" lib/presentation/pages/vote/vote_detail_page.dart
  ```
  Expected: the ternary at ~line 1051 (`? _buildNetworkImage(` / `: _buildImagePlaceholder()`) is still present.

- [ ] Extend the constructor-param widget test to lock the new param's default and threading. Open `/Users/charlie.hyun/Repositories/picnic-app-vote-detail-perf/picnic_lib/test/presentation/common/picnic_cached_network_image_extended_test.dart` and find the assertion `expect(widget.maxConcurrentLoads, isNull);` (line ~95) and the constructor that sets `maxConcurrentLoads: 4,` (line ~118). After the `expect(widget.maxConcurrentLoads, isNull);` line, add:
  ```dart
        expect(widget.bypassConcurrencyGate, isFalse);
  ```
  And in the test that constructs the widget with explicit params (the one with `maxConcurrentLoads: 4,`), add the line `bypassConcurrencyGate: true,` to that constructor and, next to its `expect(widget.maxConcurrentLoads, 4);`, add:
  ```dart
        expect(widget.bypassConcurrencyGate, isTrue);
  ```
  (If the exact surrounding lines differ, locate by `maxConcurrentLoads` — mirror its default-vs-explicit assertions for `bypassConcurrencyGate`.)

- [ ] Run the extended + render tests for the image widget:
  ```bash
  flutter test test/presentation/common/picnic_cached_network_image_extended_test.dart test/presentation/common/picnic_cached_network_image_render_test.dart
  ```
  Expected: `All tests passed!`

- [ ] Re-run the B2 guard + vote-detail render tests to confirm B3 did not regress keys/animation:
  ```bash
  flutter test test/presentation/pages/vote/vote_detail_image_key_test.dart test/presentation/pages/vote/vote_detail_page_render_test.dart test/presentation/pages/vote/vote_item_widget_test.dart
  ```
  Expected: `All tests passed!`

- [ ] MANUAL verification note (profile mode; record in PR): `flutter run --profile --dart-define=DISABLE_VM_CHECK=true`, open a large vote (1000+ items) and scroll fast. In DevTools Performance, confirm: (a) NO `VisibilityDetector` callbacks for these row avatars (strategy `none` skips them), (b) avatars in the viewport fill in without the staggered 8-at-a-time delay that the gate previously imposed, (c) no low-quality→high-quality double-fetch on these avatars even when other lazy images elsewhere are loading. Note the before/after first-paint-of-avatars timing in the PR.

- [ ] Commit. Run from `/Users/charlie.hyun/Repositories/picnic-app-vote-detail-perf`:
  ```bash
  git add picnic_lib/lib/presentation/common/picnic_cached_network_image.dart picnic_lib/lib/presentation/pages/vote/vote_detail_page.dart picnic_lib/test/presentation/common/picnic_cached_network_image_extended_test.dart
  git commit -m "perf(vote-detail): list images use LazyLoadingStrategy.none + bypass concurrency gate

Adds bypassConcurrencyGate (default false) to PicnicCachedNetworkImage.
The fixed-extent sliver is the visibility gate, so this list opts out of
the per-image VisibilityDetector + 8-slot queue and the shared low-bandwidth
heuristic. Default-icon fallback preserved.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
  ```


## Tier C — 폴리시


### Task 15: Add O(n) VoteDetailHelper.computeRanksFromSorted (TDD)

**Files:**
- `/Users/charlie.hyun/Repositories/picnic-app-vote-detail-perf/picnic_lib/lib/presentation/pages/vote/vote_detail_helper.dart` (add method)
- `/Users/charlie.hyun/Repositories/picnic-app-vote-detail-perf/picnic_lib/test/presentation/pages/vote/vote_detail_helper_rank_test.dart` (new test file)

**Interfaces:**
- Produces: `static Map<int,int> VoteDetailHelper.computeRanksFromSorted(List<VoteItemModel?> sortedDescItems)`
- Consumes: `VoteItemModel` (from `package:picnic_lib/data/models/vote/vote.dart`), existing `VoteDetailHelper.computeRanks` (kept as reference oracle for the parity test)

Context (verified in code): `AsyncVoteItemList` ALWAYS hands the page a list already sorted by `vote_total` descending — initial fetch `.order('vote_total', ascending: false)` (vote_detail_provider.dart:99), `refreshVoteTotals` re-sorts desc with id tiebreak (lines 155-158), `setVoteItem` re-sorts desc (lines 177-180). So the new helper may assume sorted-desc input and skip the `..sort` that `computeRanks` (vote_detail_helper.dart:12-34) does. This is the entire point of making it O(n).

- [ ] Write the failing test FIRST. Create `/Users/charlie.hyun/Repositories/picnic-app-vote-detail-perf/picnic_lib/test/presentation/pages/vote/vote_detail_helper_rank_test.dart` with this exact content (factory mirrors the existing `_item` in vote_detail_helper_test.dart:34-46):

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/presentation/pages/vote/vote_detail_helper.dart';

void main() {
  VoteItemModel item({required int id, int? voteTotal}) => VoteItemModel(
        id: id,
        voteTotal: voteTotal,
        voteId: 1,
      );

  group('computeRanksFromSorted', () {
    test('returns empty map for empty list', () {
      expect(VoteDetailHelper.computeRanksFromSorted([]), isEmpty);
    });

    test('returns empty map for list of only nulls', () {
      expect(VoteDetailHelper.computeRanksFromSorted([null, null]), isEmpty);
    });

    test('ranks single item as 1', () {
      expect(
        VoteDetailHelper.computeRanksFromSorted([item(id: 10, voteTotal: 100)]),
        {10: 1},
      );
    });

    test('assigns sequential ranks for strictly descending input', () {
      final ranks = VoteDetailHelper.computeRanksFromSorted([
        item(id: 2, voteTotal: 30),
        item(id: 3, voteTotal: 20),
        item(id: 1, voteTotal: 10),
      ]);
      expect(ranks, {2: 1, 3: 2, 1: 3});
    });

    test('ties share a rank and the next distinct value skips ranks', () {
      // 50,50,10 -> ranks 1,1,3 (rank 2 skipped)
      final ranks = VoteDetailHelper.computeRanksFromSorted([
        item(id: 1, voteTotal: 50),
        item(id: 2, voteTotal: 50),
        item(id: 3, voteTotal: 10),
      ]);
      expect(ranks[1], 1);
      expect(ranks[2], 1);
      expect(ranks[3], 3);
    });

    test('all equal totals all share rank 1', () {
      final ranks = VoteDetailHelper.computeRanksFromSorted([
        item(id: 1, voteTotal: 10),
        item(id: 2, voteTotal: 10),
        item(id: 3, voteTotal: 10),
      ]);
      expect(ranks, {1: 1, 2: 1, 3: 1});
    });

    test('trailing tie block shares a rank', () {
      // 30,20,20 -> 1,2,2
      final ranks = VoteDetailHelper.computeRanksFromSorted([
        item(id: 1, voteTotal: 30),
        item(id: 2, voteTotal: 20),
        item(id: 3, voteTotal: 20),
      ]);
      expect(ranks, {1: 1, 2: 2, 3: 2});
    });

    test('null voteTotal is treated as 0 (sorted last in valid input)', () {
      final ranks = VoteDetailHelper.computeRanksFromSorted([
        item(id: 2, voteTotal: 5),
        item(id: 1, voteTotal: null),
      ]);
      expect(ranks, {2: 1, 1: 2});
    });

    test('skips null entries without consuming a rank slot', () {
      // null between two reals must not shift rank numbering
      final ranks = VoteDetailHelper.computeRanksFromSorted([
        item(id: 1, voteTotal: 20),
        null,
        item(id: 3, voteTotal: 10),
      ]);
      expect(ranks.length, 2);
      expect(ranks, {1: 1, 3: 2});
    });

    test('parity with computeRanks on already-sorted-desc input', () {
      final sorted = [
        item(id: 1, voteTotal: 100),
        item(id: 2, voteTotal: 100),
        item(id: 3, voteTotal: 80),
        item(id: 4, voteTotal: 80),
        item(id: 5, voteTotal: 80),
        item(id: 6, voteTotal: 5),
        item(id: 7, voteTotal: 0),
      ];
      expect(
        VoteDetailHelper.computeRanksFromSorted(sorted),
        VoteDetailHelper.computeRanks(sorted),
      );
    });
  });
}
```

- [ ] Run the test and CONFIRM it fails because the method does not exist yet. From `/Users/charlie.hyun/Repositories/picnic-app-vote-detail-perf/picnic_lib`:

```bash
flutter test test/presentation/pages/vote/vote_detail_helper_rank_test.dart
```

Expected: compile error / failure mentioning `The method 'computeRanksFromSorted' isn't defined for the type 'VoteDetailHelper'` (red). Do NOT proceed until you see this exact kind of failure — it proves the test exercises the new symbol.

- [ ] Implement the method. In `/Users/charlie.hyun/Repositories/picnic-app-vote-detail-perf/picnic_lib/lib/presentation/pages/vote/vote_detail_helper.dart`, insert this method immediately AFTER the closing `}` of `computeRanks` (which ends at line 34, the line `  }` right before the blank line preceding `/// Compare two lists`). Match the exact anchor:

old_string (the end of computeRanks + the start of areDataListsEqual doc):
```dart
    return ranks;
  }

  /// Compare two lists of VoteItemModel by id and voteTotal.
```

new_string:
```dart
    return ranks;
  }

  /// Compute rank map from a list ALREADY sorted by voteTotal descending.
  ///
  /// O(n): does NOT sort. Callers must pass a list whose non-null items are in
  /// descending voteTotal order (e.g. the output of [AsyncVoteItemList], which
  /// always orders by vote_total desc). Items with equal voteTotal share the
  /// same rank; the next distinct (lower) value resumes at the 1-based position
  /// of the first item in its block — i.e. ties skip ranks, matching
  /// [computeRanks]. null entries and null voteTotals (treated as 0) are
  /// handled without consuming a rank slot for nulls.
  static Map<int, int> computeRanksFromSorted(
    List<VoteItemModel?> sortedDescItems,
  ) {
    final ranks = <int, int>{};

    int position = 0; // 1-based count of non-null items seen so far
    int currentRank = 1;
    int? previousVoteTotal;

    for (final item in sortedDescItems) {
      if (item == null) continue;

      position++;
      final voteTotal = item.voteTotal ?? 0;

      if (previousVoteTotal == null || voteTotal != previousVoteTotal) {
        currentRank = position;
      }
      // else: tie -> keep currentRank

      ranks[item.id] = currentRank;
      previousVoteTotal = voteTotal;
    }

    return ranks;
  }

  /// Compare two lists of VoteItemModel by id and voteTotal.
```

- [ ] Static-analyze the changed file:

```bash
dart analyze lib/presentation/pages/vote/vote_detail_helper.dart
```

Expected: `No issues found!`

- [ ] Run the new test and CONFIRM green:

```bash
flutter test test/presentation/pages/vote/vote_detail_helper_rank_test.dart
```

Expected: `All tests passed!` (10 tests). The `parity` test specifically proves the O(n) implementation produces identical output to the existing `computeRanks` on sorted-desc input.

- [ ] Commit:

```bash
git -C /Users/charlie.hyun/Repositories/picnic-app-vote-detail-perf add picnic_lib/lib/presentation/pages/vote/vote_detail_helper.dart picnic_lib/test/presentation/pages/vote/vote_detail_helper_rank_test.dart
git -C /Users/charlie.hyun/Repositories/picnic-app-vote-detail-perf commit -m "perf(vote-detail): add O(n) computeRanksFromSorted helper

Assumes AsyncVoteItemList's already-desc-sorted output; tie-merge parity
with computeRanks verified by unit test.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

### Task 16: Recompute ranks on provider emit (deduped), remove _updateRanks from build

**Files:**
- `/Users/charlie.hyun/Repositories/picnic-app-vote-detail-perf/picnic_lib/lib/presentation/pages/vote/vote_detail_page.dart`

**Interfaces:**
- Consumes: `VoteDetailHelper.computeRanksFromSorted` (from previous task), existing `VoteDetailHelper.areDataListsEqual` (vote_detail_helper.dart:37), existing private field `_currentRanks` (page line 78), existing private method `_areDataListsEqual` (page line 362).
- Produces: no new public API. INTERNAL-ONLY changes — no `@riverpod`/model API touched, so build_runner is NOT required.

Context (verified): the build data builder calls `_updateRanks(data)` at line 691 on EVERY build, which calls `VoteDetailHelper.computeRanks` (the full-sort O(n log n) version) at line 207. Highlight `setState` (lines 217/223) and search `setState` both trigger rebuilds, so today every highlight/search keystroke re-sorts all items. `_initializeRanks` (lines 172-184) seeds `_currentRanks` on the first frame from the provider's current value. We keep `_initializeRanks`, move ongoing recompute into a `ref.listen`, and delete the build-time `_updateRanks(data)` call.

- [ ] Establish the baseline: run the existing page + helper tests BEFORE editing, so any later breakage is attributable. From `/Users/charlie.hyun/Repositories/picnic-app-vote-detail-perf/picnic_lib`:

```bash
flutter test test/presentation/pages/vote/vote_detail_page_test.dart test/presentation/pages/vote/vote_detail_page_render_test.dart test/presentation/pages/vote/vote_detail_helper_test.dart test/presentation/pages/vote/vote_detail_helper_rank_test.dart
```

Expected: `All tests passed!`. Record the passing state; this is the regression gate for this task.

- [ ] Switch `_updateRanks` to the O(n) helper. In `vote_detail_page.dart` replace the body (lines 206-211):

old_string:
```dart
  void _updateRanks(List<VoteItemModel?> items) {
    final ranks = VoteDetailHelper.computeRanks(items);
    _currentRanks
      ..clear()
      ..addAll(ranks);
  }
```

new_string:
```dart
  // Recompute the rank map from a provider snapshot. The provider
  // (AsyncVoteItemList) always emits data already sorted by vote_total desc,
  // so we use the O(n) helper and never re-sort here.
  void _updateRanks(List<VoteItemModel?> items) {
    final ranks = VoteDetailHelper.computeRanksFromSorted(items);
    _currentRanks
      ..clear()
      ..addAll(ranks);
  }
```

- [ ] Add a deduped `ref.listen` so ranks recompute ONLY when the provider emits genuinely new item data. Riverpod requires `ref.listen` inside `build` (not `initState`). Add it as the FIRST statement of the page's `build` method. First confirm the exact build signature/opening:

```bash
grep -n "Widget build(BuildContext context)" /Users/charlie.hyun/Repositories/picnic-app-vote-detail-perf/picnic_lib/lib/presentation/pages/vote/vote_detail_page.dart
```

Expected: one match for the `_VoteDetailPageState` build (it is the page-level `build`, the same State that owns `_currentRanks`/`_initializeRanks`). Read ~10 lines from that line number to capture the literal opening lines:

```bash
sed -n "$(grep -n 'Widget build(BuildContext context)' /Users/charlie.hyun/Repositories/picnic-app-vote-detail-perf/picnic_lib/lib/presentation/pages/vote/vote_detail_page.dart | tail -1 | cut -d: -f1),+8p" /Users/charlie.hyun/Repositories/picnic-app-vote-detail-perf/picnic_lib/lib/presentation/pages/vote/vote_detail_page.dart
```

Then, using the captured `@override\n  Widget build(BuildContext context) {` line plus whatever its current first body line is as the `old_string`, prepend the listener. Concretely, edit so the build opens like this (keep the existing first body line — shown here as `<existing first line of build body>` — unchanged below the inserted block):

new_string (insert the `ref.listen(...)` block as the first statement inside build, before the existing first line):
```dart
  @override
  Widget build(BuildContext context) {
    // Recompute ranks ONLY when the item list provider emits genuinely new
    // data. Dedup via areDataListsEqual (id + voteTotal) so highlight/search
    // setState rebuilds do NOT trigger a resort. _initializeRanks seeds the
    // first frame; this keeps subsequent polling emits in sync.
    ref.listen(
      asyncVoteItemListProvider(
        voteId: widget.voteId,
        votePortal: widget.votePortal,
      ),
      (previous, next) {
        final nextData = next.value;
        if (nextData == null) return;
        final prevData = previous?.value;
        if (prevData != null &&
            VoteDetailHelper.areDataListsEqual(prevData, nextData)) {
          return; // no id/voteTotal change -> ranks unchanged
        }
        _updateRanks(nextData);
      },
    );
    <existing first line of build body>
```

Note: `ref.listen` callbacks fire OUTSIDE build, so calling `_updateRanks` (which mutates `_currentRanks`) here is safe and does not need `setState` — the same provider change also re-runs `dataAsync.when` in `_buildVoteItemList`, which reads the freshly-updated `_currentRanks`.

- [ ] REMOVE the build-time resort. In `_buildVoteItemList` delete the `_updateRanks(data)` call at line 691. Anchor on the surrounding lines (690-692):

old_string:
```dart
      data: (data) {
        _updateRanks(data);
        final filteredIndices = _getFilteredIndices([data, _searchQuery]);
```

new_string:
```dart
      data: (data) {
        // Ranks are kept current by the ref.listen in build() + _initializeRanks
        // for the first frame; do NOT resort here (highlight/search setState
        // would otherwise re-run an O(n log n) sort every rebuild).
        final filteredIndices = _getFilteredIndices([data, _searchQuery]);
```

- [ ] Static-analyze the page:

```bash
dart analyze lib/presentation/pages/vote/vote_detail_page.dart
```

Expected: `No issues found!`. If analyzer reports `_updateRanks` is unused, that means a path still references it — it is still called from `_initializeRanks` (line 182) and the new `ref.listen`, so this warning should NOT appear; if it does, re-check the listener edit landed.

- [ ] Run the full vote-detail test suite (existing page tests are the verification that behavior — initial ranks, highlight on rank change, search — is preserved):

```bash
flutter test test/presentation/pages/vote/vote_detail_page_test.dart test/presentation/pages/vote/vote_detail_page_render_test.dart test/presentation/pages/vote/vote_detail_helper_test.dart test/presentation/pages/vote/vote_detail_helper_rank_test.dart
```

Expected: `All tests passed!` — same green set as the baseline step. If any rank/highlight assertion fails, the dedup or listener wiring is wrong; debug before continuing (do not weaken the test).

- [ ] MANUAL profile-mode verification (no meaningful unit test for "build no longer resorts" — verify with DevTools). Steps:
  1. From `/Users/charlie.hyun/Repositories/picnic-app-vote-detail-perf/picnic_app` run `flutter run --profile --dart-define=DISABLE_VM_CHECK=true` on a physical device.
  2. Open a vote with many items (active vote, 50+ items). Open DevTools > Performance, enable the Performance overlay.
  3. Type in the search box rapidly (triggers `setState` rebuilds). CONFIRM: no per-keystroke jank spike attributable to list sorting; in the CPU profiler, `computeRanks`/`List.sort` does NOT appear under the search-driven build frames (only the deduped listener path runs, and only on real provider emits).
  4. Let the 1s polling timer run while NOT voting (no real vote_total change). CONFIRM: `_updateRanks`/`computeRanksFromSorted` is NOT invoked on emits that `areDataListsEqual` dedups (set a temporary breakpoint or `logger.d` inside the listener guarded `return` vs the recompute branch to observe; remove the log before committing).
  5. Cast a vote so a real rank change occurs. CONFIRM: the rank badge updates and the changed item highlights (existing `_triggerHighlight` path at line 798-800 still fires off the updated `_currentRanks`).

- [ ] Commit:

```bash
git -C /Users/charlie.hyun/Repositories/picnic-app-vote-detail-perf add picnic_lib/lib/presentation/pages/vote/vote_detail_page.dart
git -C /Users/charlie.hyun/Repositories/picnic-app-vote-detail-perf commit -m "perf(vote-detail): recompute ranks via deduped ref.listen, not in build

- _updateRanks now uses O(n) computeRanksFromSorted
- ref.listen(asyncVoteItemListProvider) recomputes only on genuinely new
  data (areDataListsEqual dedup); first frame still seeded by _initializeRanks
- removed _updateRanks(data) from _buildVoteItemList so highlight/search
  setState no longer trigger a resort

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```


### Task 17: C2 — Collapse triple RepaintBoundary to a single row-root boundary

The vote-detail list currently nests **three** `RepaintBoundary` per row: (1) at the itemBuilder root (`vote_detail_page.dart` ~line 810), (2) inside `_buildNetworkImage` (`vote_detail_page.dart` ~line 1079), and (3) at the root of `VoteItemWidget.build` (`vote_item_widget.dart` ~line 40). Plus `ListView.builder` has `addRepaintBoundaries: true` (line 765) which wraps EACH item again. Net result: up to 4 boundaries per row — pure overhead (each boundary allocates a separate layer). Keep exactly ONE boundary at the row root, drop the inner two, and turn off the ListView's automatic boundary since we supply our own keyed one.

The image key/cacheKey rank-segment removal (shared contract) is folded in here because it lives in the same two helper methods we are editing.

**Files:**
- `/Users/charlie.hyun/Repositories/picnic-app-vote-detail-perf/picnic_lib/lib/presentation/pages/vote/vote_detail_page.dart`
- `/Users/charlie.hyun/Repositories/picnic-app-vote-detail-perf/picnic_lib/lib/presentation/pages/vote/vote_item_widget.dart`
- `/Users/charlie.hyun/Repositories/picnic-app-vote-detail-perf/picnic_lib/test/presentation/pages/vote/vote_item_widget_test.dart`

**Interfaces:**
- Consumes: nothing external.
- Produces: row-root `RepaintBoundary` keyed `ValueKey('vote_item_${item.id}')` is the ONLY boundary per row. Image widget key becomes `ValueKey('cached_image_$imageUrl')` (no `_rank_` segment). Rank stays only on the `AnimatedContainer` highlight layer in `VoteItemWidget`.

Steps:

- [ ] Confirm current baseline of the three boundaries before editing:
  ```bash
  cd /Users/charlie.hyun/Repositories/picnic-app-vote-detail-perf/picnic_lib
  grep -n "RepaintBoundary" lib/presentation/pages/vote/vote_detail_page.dart lib/presentation/pages/vote/vote_item_widget.dart
  ```
  Expected output (line numbers approximate):
  ```
  lib/presentation/pages/vote/vote_detail_page.dart:810:                      return RepaintBoundary(
  lib/presentation/pages/vote/vote_detail_page.dart:1079:    return RepaintBoundary(
  lib/presentation/pages/vote/vote_item_widget.dart:40:    return RepaintBoundary(
  ```

- [ ] Remove the inner `RepaintBoundary` inside `VoteItemWidget.build`. In `vote_item_widget.dart`, replace the boundary wrapper (lines ~40–41 opening and the matching trailing `),` for the boundary) so `build` returns the `AnimatedContainer` directly. Change the opening:
  ```dart
  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedContainer(
  ```
  to:
  ```dart
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
  ```
  Then remove the now-unbalanced trailing `)` for the boundary. The current tail of the method is:
  ```dart
            ),
          ),
        ),
      ),
    );
  }
  ```
  (the `Container` close, the `GestureDetector` close, the `AnimatedContainer` close, the `RepaintBoundary` close, the final `;`). Change it to:
  ```dart
            ),
          ),
        ),
      );
  }
  ```
  (one fewer `)` — the `AnimatedContainer` is now the returned widget).

- [ ] Remove the `RepaintBoundary` inside `_buildNetworkImage` AND drop the rank segment from the image key. In `vote_detail_page.dart`, replace:
  ```dart
  Widget _buildNetworkImage(
    String imageUrl,
    int itemId,
    int index,
    int actualRank,
    bool rankChanged,
  ) {
    // 순위 변동 시 이미지 위젯 재생성을 위해 actualRank를 키에 포함
    return RepaintBoundary(
      key: ValueKey('image_${itemId}_rank_$actualRank'),
      child: SizedBox(
        width: 39,
        height: 39,
        child: _buildImageWithFallback(
          imageUrl,
          index: index,
          actualRank: actualRank,
          rankChanged: rankChanged,
        ),
      ),
    );
  }
  ```
  with:
  ```dart
  Widget _buildNetworkImage(
    String imageUrl,
    int itemId,
    int index,
    int actualRank,
    bool rankChanged,
  ) {
    // C2: 별도 RepaintBoundary 제거 — 행 루트(itemBuilder)의 단일 경계만 유지.
    // 이미지 위젯 key 에서 rank 세그먼트 제거: rank 변동은 하이라이트 레이어에만 반영하고
    // 이미지 자체는 URL 이 같으면 재생성/재디코드하지 않는다.
    return SizedBox(
      width: 39,
      height: 39,
      child: _buildImageWithFallback(
        imageUrl,
        index: index,
        actualRank: actualRank,
        rankChanged: rankChanged,
      ),
    );
  }
  ```

- [ ] Drop the rank segment from the `PicnicCachedNetworkImage` key in `_buildImageWithFallback`. In `vote_detail_page.dart`, replace:
  ```dart
    return PicnicCachedNetworkImage(
      key: ValueKey(
        'cached_image_$imageUrl${actualRank != null ? '_rank_$actualRank' : ''}',
      ), // 순위 변동 시 위젯 재생성
      imageUrl: imageUrl,
  ```
  with:
  ```dart
    return PicnicCachedNetworkImage(
      // C2: rank 세그먼트 제거 — key 가 URL 에만 의존하므로 rank 변동 시 이미지가
      // 재생성/재디코드되지 않는다. 강조 효과는 행의 AnimatedContainer 레이어가 담당.
      key: ValueKey('cached_image_$imageUrl'),
      imageUrl: imageUrl,
  ```

- [ ] Turn off `ListView.builder`'s automatic boundary so it does not double-wrap our keyed row-root boundary. In `vote_detail_page.dart` change:
  ```dart
                    addAutomaticKeepAlives: false, // 메모리 최적화
                    addRepaintBoundaries: true, // 리페인트 최적화
  ```
  to:
  ```dart
                    addAutomaticKeepAlives: false, // 메모리 최적화
                    // C2: itemBuilder 가 직접 RepaintBoundary 를 제공하므로 자동 래핑 비활성화 (중복 레이어 제거)
                    addRepaintBoundaries: false,
  ```
  (The `RepaintBoundary` at ~line 810 with `key: ValueKey('vote_item_${item.id}')` stays — it is the single surviving boundary.)

- [ ] Add a widget test asserting exactly one `RepaintBoundary` in a standalone `VoteItemWidget` (since this widget no longer adds its own). Open the existing test file and append a new `testWidgets` inside the existing top-level `group`. First inspect the helper that builds a `VoteItemWidget` in the test:
  ```bash
  cd /Users/charlie.hyun/Repositories/picnic-app-vote-detail-perf/picnic_lib
  grep -n "VoteItemWidget(\|pumpWidget\|Widget _build\|MaterialApp\|ScreenUtilInit" test/presentation/pages/vote/vote_item_widget_test.dart | head
  ```
  Reuse whatever pump helper that file already defines. Add this test (adapt the build-helper call name to match what the grep shows — e.g. if the file uses `_pumpItem(tester, ...)`, call that):
  ```dart
    testWidgets('VoteItemWidget adds no RepaintBoundary of its own (C2)',
        (tester) async {
      // Reuse the file's existing pump helper to mount a default VoteItemWidget.
      // RepaintBoundary count contributed by VoteItemWidget itself must be 0;
      // the row-root boundary lives in vote_detail_page, not here.
      await _pumpDefaultVoteItemWidget(tester); // <-- rename to the helper this file already uses
      expect(
        find.descendant(
          of: find.byType(VoteItemWidget),
          matching: find.byType(RepaintBoundary),
        ),
        findsNothing,
      );
    });
  ```
  If the file has no reusable pump helper, build one inline mirroring an existing `testWidgets` block in the SAME file (copy its `MaterialApp`/`ScreenUtilInit`/`VoteItemWidget(...)` scaffold verbatim, then run the same `expect`).

- [ ] Run the affected widget tests and analyzer:
  ```bash
  cd /Users/charlie.hyun/Repositories/picnic-app-vote-detail-perf/picnic_lib
  flutter test test/presentation/pages/vote/vote_item_widget_test.dart test/presentation/pages/vote/vote_item_highlight_widget_test.dart test/presentation/pages/vote/vote_detail_page_render_test.dart
  dart analyze lib/presentation/pages/vote/vote_detail_page.dart lib/presentation/pages/vote/vote_item_widget.dart
  ```
  Expected: `All tests passed!` and `No issues found!`. If a render test asserted on the old `image_<id>_rank_<n>` key or counted boundaries, update that assertion to the new key / new count and re-run (do not silence it).

- [ ] Manual profile verification (no meaningful unit test for paint cost). Document in the commit body:
  - Run `flutter run --profile --dart-define=DISABLE_VM_CHECK=true` on a physical device, open a vote with 200+ items.
  - Open DevTools Performance overlay (or `P` in the run console for the perf overlay). Toggle "Highlight repaints" in the Flutter Inspector.
  - Scroll the list and confirm: each row flashes as ONE rectangle (one layer), not 3–4 nested rectangles. Rank changes still flash the row highlight color (blue/red) and the crown/number updates, but the artist image does NOT flicker/reload on rank change.
  - Confirm no visual regression: crowns for rank 1–3, number for rank ≥4, artist name + group, vote count container, star-candy icon all render identically to `main`.

- [ ] Commit:
  ```bash
  cd /Users/charlie.hyun/Repositories/picnic-app-vote-detail-perf
  git add picnic_lib/lib/presentation/pages/vote/vote_detail_page.dart picnic_lib/lib/presentation/pages/vote/vote_item_widget.dart picnic_lib/test/presentation/pages/vote/vote_item_widget_test.dart
  git commit -m "$(cat <<'EOF'
perf(vote-detail): collapse per-row RepaintBoundary to single row-root (C2)

- remove inner boundary in VoteItemWidget.build and in _buildNetworkImage
- disable ListView.builder addRepaintBoundaries (we supply a keyed one)
- drop rank segment from image widget key/cacheKey so rank changes no longer
  re-decode the artist image; rank stays on the AnimatedContainer highlight layer

Manual: profile-mode "highlight repaints" shows one layer per row; rank
flash + crown/number update intact, artist image no longer flickers on rank change.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
  ```

---

### Task 18: C3 — List-scoped thumbnail request weight (q~55, dpr cap ~2.0) without touching other screens

The vote-detail row images are 39×39 logical px (sub-50px), but `_estimateImageComplexity()` classifies them as `ImageComplexity.low` (39×39 = 1521 px < 50000) and the low branch requests `quality: 85` at the FULL device resolution multiplier (up to 2.5 on phones, 4.0 on iPad — see `_getResolutionMultiplier`). For a tiny thumbnail that is wasted bytes/decode. We reduce request weight ONLY for this list by passing two new opt-in params; defaults preserve current behavior so no other screen changes. We do NOT edit `_getTransformedUrl`'s global quality constants.

**Files:**
- `/Users/charlie.hyun/Repositories/picnic-app-vote-detail-perf/picnic_lib/lib/presentation/common/picnic_cached_network_image.dart`
- `/Users/charlie.hyun/Repositories/picnic-app-vote-detail-perf/picnic_lib/lib/presentation/pages/vote/vote_detail_page.dart`
- `/Users/charlie.hyun/Repositories/picnic-app-vote-detail-perf/picnic_lib/test/presentation/common/picnic_cached_network_image_helper_test.dart`

**Interfaces:**
- Consumes: C2's `_buildImageWithFallback` edits (same `PicnicCachedNetworkImage` call site).
- Produces: new public params `maxQualityOverride` (int?, default null) and `maxResolutionMultiplierCap` (double?, default null) on `PicnicCachedNetworkImage`. Internal helper `_capResolution(double)`. Low-complexity quality reads `widget.maxQualityOverride ?? 85`.

Steps:

- [ ] Add the two fields + constructor params to `PicnicCachedNetworkImage`. In `picnic_cached_network_image.dart`, after the existing field block ending with `final bool showLoadingOverlay;` (line ~72), insert:
  ```dart

  // C3: 리스트 전용 요청 가중치 축소(다른 화면 영향 없음 — 기본값 null = 현재 동작 유지).
  // maxQualityOverride: 단일(저복잡도) URL 의 q 값을 이 값으로 제한.
  // maxResolutionMultiplierCap: _getResolutionMultiplier 결과를 이 값으로 clamp.
  final int? maxQualityOverride;
  final double? maxResolutionMultiplierCap;
  ```
  Then in the constructor parameter list, after `this.showLoadingOverlay = true,` (line ~90), add:
  ```dart
    this.maxQualityOverride,
    this.maxResolutionMultiplierCap,
  ```

- [ ] Add the `_capResolution` helper and apply the cap at BOTH call sites where the resolution multiplier is computed (`initState` postframe ~line 225, and `_buildMainWidget` ~line 519). First add the helper method just above `_getResolutionMultiplier` (line ~628):
  ```dart
  /// C3: 리스트 전용 dpr 상한 적용. 기본(null)이면 변형 없음.
  double _capResolution(double multiplier) {
    final cap = widget.maxResolutionMultiplierCap;
    if (cap == null) return multiplier;
    return math.min(multiplier, cap);
  }
  ```
  In `initState`, change:
  ```dart
        _cachedUrls ??= _getTransformedUrls(
          context,
          _getResolutionMultiplier(context),
        );
  ```
  to:
  ```dart
        _cachedUrls ??= _getTransformedUrls(
          context,
          _capResolution(_getResolutionMultiplier(context)),
        );
  ```
  In `_buildMainWidget`, change the identical block:
  ```dart
    _cachedUrls ??= _getTransformedUrls(
      context,
      _getResolutionMultiplier(context),
    );
  ```
  to:
  ```dart
    _cachedUrls ??= _getTransformedUrls(
      context,
      _capResolution(_getResolutionMultiplier(context)),
    );
  ```

- [ ] Apply the quality override on the low-complexity branch ONLY (the branch our 39×39 thumbnail hits). In `_getTransformedUrls`, change:
  ```dart
    switch (imageSize) {
      case ImageComplexity.low:
        return [_getTransformedUrl(widget.imageUrl, resolutionMultiplier, 85)];
  ```
  to:
  ```dart
    switch (imageSize) {
      case ImageComplexity.low:
        // C3: 리스트가 maxQualityOverride 를 넘기면 그 값을, 아니면 기존 85.
        return [
          _getTransformedUrl(
            widget.imageUrl,
            resolutionMultiplier,
            widget.maxQualityOverride ?? 85,
          ),
        ];
  ```
  (Do NOT touch the `medium`/`high`/`isLowBandwidth` branches — those serve other screens and must keep their progressive quality ladder.)

- [ ] Opt this list in at the call site. In `vote_detail_page.dart` `_buildImageWithFallback`, inside the `PicnicCachedNetworkImage(...)` constructor, after `maxRetries: 2,` add the two params:
  ```dart
      timeout: const Duration(seconds: 15), // 타임아웃을 15초로 증가 (네트워크 상태 고려)
      maxRetries: 2,
      // C3: 39x39 썸네일 전용 요청 가중치 축소 (이 리스트에만 적용, 다른 화면 불변).
      // sub-50px 슬롯이라 q55 + dpr 상한 2.0 으로 충분; 글로벌 _getTransformedUrl 미변경.
      maxQualityOverride: 55,
      maxResolutionMultiplierCap: 2.0,
    );
  ```
  (i.e. these two lines go right before the closing `);` of the constructor.)

- [ ] Add unit coverage for the cap helper logic. The cap is pure arithmetic; add direct tests. Open the helper test file and inspect how it instantiates state to call private helpers:
  ```bash
  cd /Users/charlie.hyun/Repositories/picnic-app-vote-detail-perf/picnic_lib
  grep -n "createState\|_PicnicCachedNetworkImageState\|_capResolution\|_calculateBackoffDelay\|.state\b" test/presentation/common/picnic_cached_network_image_helper_test.dart | head
  ```
  Following the SAME pattern that file already uses to reach private methods (e.g. via the state object returned from `createState()`), add a group:
  ```dart
    group('_capResolution (C3 list-scoped dpr cap)', () {
      test('returns multiplier unchanged when cap is null', () {
        // Build a widget with maxResolutionMultiplierCap == null (default),
        // grab its state the same way other tests in this file do, then:
        // expect(state._capResolution(2.5), 2.5);
      });
      test('clamps multiplier down to cap when above', () {
        // maxResolutionMultiplierCap: 2.0 -> expect(state._capResolution(2.5), 2.0);
      });
      test('leaves multiplier when below cap', () {
        // maxResolutionMultiplierCap: 2.0 -> expect(state._capResolution(1.2), 1.2);
      });
    });
  ```
  Fill the bodies using the exact state-access idiom the existing tests use (copy from the nearest existing `test(` in the file). If the file accesses privates via a `part`/test-only getter, reuse it; if it instantiates `PicnicCachedNetworkImage(...).createState()`, do the same and call `state._capResolution(...)`.

- [ ] Run tests + analyzer:
  ```bash
  cd /Users/charlie.hyun/Repositories/picnic-app-vote-detail-perf/picnic_lib
  flutter test test/presentation/common/picnic_cached_network_image_helper_test.dart test/presentation/common/picnic_cached_network_image_test.dart test/presentation/pages/vote/vote_detail_page_render_test.dart
  dart analyze lib/presentation/common/picnic_cached_network_image.dart lib/presentation/pages/vote/vote_detail_page.dart
  ```
  Expected: `All tests passed!` and `No issues found!`. (No codegen needed — these are not `@riverpod`/model changes.)

- [ ] Manual verification of scoping + reduced weight. Document in commit body:
  - In profile/debug run, open the vote-detail list and capture one artist-image request URL from the network/DevTools logger output: it must contain `q=55` and `dpr=2` (capped), e.g. `...?q=55&w=78&h=78&...&dpr=2`.
  - Open ANY other screen that uses `PicnicCachedNetworkImage` for a small image (e.g. an artist search result thumbnail) and confirm its request URL is UNCHANGED vs `main` (still `q=85` / uncapped dpr) — proving the change is list-scoped via the default-null params.

- [ ] Commit:
  ```bash
  cd /Users/charlie.hyun/Repositories/picnic-app-vote-detail-perf
  git add picnic_lib/lib/presentation/common/picnic_cached_network_image.dart picnic_lib/lib/presentation/pages/vote/vote_detail_page.dart picnic_lib/test/presentation/common/picnic_cached_network_image_helper_test.dart
  git commit -m "$(cat <<'EOF'
perf(vote-detail): list-scoped thumbnail request weight q55 + dpr cap 2.0 (C3)

- add opt-in PicnicCachedNetworkImage params maxQualityOverride /
  maxResolutionMultiplierCap (default null = current behavior, other screens unchanged)
- low-complexity branch now uses (maxQualityOverride ?? 85); _capResolution clamps dpr
- vote-detail 39x39 row image opts in: q55 + dpr<=2.0
- _getTransformedUrl global constants untouched

Manual: vote-detail image URL shows q=55&dpr=2; other screens still q=85/uncapped.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
  ```

---

### Task 19: C4 — Fling-aware deferred image loading for the row image (lowest priority)

During a fast fling, decoding images for rows that whip past is wasted work and causes jank. Flutter exposes `Scrollable.recommendDeferredLoadingForContext(context)` which returns true while the enclosing scrollable is flinging fast; we should show the placeholder then and load the real image when it settles. This is the LAST polish step and must be paired with `LazyLoadingStrategy.none` so the gate (not the visibility detector) controls loading on this list. Other screens keep `deferDuringFastScroll: false` (default).

**Files:**
- `/Users/charlie.hyun/Repositories/picnic-app-vote-detail-perf/picnic_lib/lib/presentation/common/picnic_cached_network_image.dart`
- `/Users/charlie.hyun/Repositories/picnic-app-vote-detail-perf/picnic_lib/lib/presentation/pages/vote/vote_detail_page.dart`

**Interfaces:**
- Consumes: C3's constructor (we add one more param alongside `maxQualityOverride` / `maxResolutionMultiplierCap`). C2's single-boundary row.
- Produces: new public param `deferDuringFastScroll` (bool, default false). When true, `build()` returns the placeholder while `Scrollable.recommendDeferredLoadingForContext(context)` is true, else the main widget.

Steps:

- [ ] Add the field + constructor param. In `picnic_cached_network_image.dart`, after the C3 fields you added, insert:
  ```dart

  // C4: 빠른 플링 중에는 실제 이미지 대신 placeholder 를 보여주고, 스크롤이 멎으면 로드.
  // Scrollable.recommendDeferredLoadingForContext 게이트. 기본 false = 현재 동작.
  final bool deferDuringFastScroll;
  ```
  And in the constructor list, after the C3 params, add:
  ```dart
    this.deferDuringFastScroll = false,
  ```

- [ ] Gate the `build()` method. In `picnic_cached_network_image.dart`, the current `build` (line ~565) begins:
  ```dart
  @override
  Widget build(BuildContext context) {
    // Lazy Loading이 비활성화된 경우 바로 이미지 렌더링
    if (widget.lazyLoadingStrategy == LazyLoadingStrategy.none) {
      return _buildSafeMainWidget();
    }
  ```
  Insert the fling gate as the FIRST thing in `build`, before the existing strategy check:
  ```dart
  @override
  Widget build(BuildContext context) {
    // C4: 빠른 플링 중이면 디코드/네트워크를 미루고 placeholder 만 그린다.
    // 스크롤이 멎으면 Scrollable 이 이 컨텍스트를 다시 빌드하여 실제 이미지로 전환.
    if (widget.deferDuringFastScroll &&
        Scrollable.recommendDeferredLoadingForContext(context)) {
      return _buildSafePlaceholder();
    }

    // Lazy Loading이 비활성화된 경우 바로 이미지 렌더링
    if (widget.lazyLoadingStrategy == LazyLoadingStrategy.none) {
      return _buildSafeMainWidget();
    }
  ```
  (`_buildSafePlaceholder()` already exists at line ~589 and produces a correctly-sized shimmer placeholder — reuse it, do not invent a new one.)

- [ ] Opt the vote-detail list in AND pair it with `LazyLoadingStrategy.none` + lowest priority. In `vote_detail_page.dart` `_buildImageWithFallback`, the strategy is currently derived from `rankChanged`:
  ```dart
    // 순위가 변동된 경우 즉시 로딩 (LazyLoadingStrategy.none)
    // 그 외의 경우 뷰포트 기반 지연 로딩 (LazyLoadingStrategy.viewport)
    final lazyLoadingStrategy = rankChanged
        ? LazyLoadingStrategy.none
        : LazyLoadingStrategy.viewport;
  ```
  Replace with a constant `none` (the fling gate replaces viewport-based deferral here):
  ```dart
    // C4: 플링 게이트(deferDuringFastScroll)가 로딩 타이밍을 제어하므로
    // 항상 LazyLoadingStrategy.none 으로 두고 VisibilityDetector 경로를 우회한다.
    const lazyLoadingStrategy = LazyLoadingStrategy.none;
  ```
  Then in the `PicnicCachedNetworkImage(...)` call, change the `priority` line and add `deferDuringFastScroll`. Current:
  ```dart
      priority: isTopRanking
          ? ImagePriority.high
          : ImagePriority.normal, // 상위 랭킹만 높은 우선순위
  ```
  Replace with:
  ```dart
      // C4: 이 리스트의 행 이미지는 최저 우선순위 + 플링 중 지연 로딩.
      priority: ImagePriority.low,
  ```
  And alongside the C3 params (after `maxResolutionMultiplierCap: 2.0,`), add:
  ```dart
      deferDuringFastScroll: true,
  ```
  Note: `isTopRanking` becomes unused after this — remove its declaration (`final isTopRanking = index != null && index < 50;`) and the now-stale comment lines referencing top-50 priority to keep `dart analyze` clean.

- [ ] Add a widget test proving the param defaults preserve behavior and that the gated path renders a placeholder. Reuse the existing render-test scaffold. Inspect:
  ```bash
  cd /Users/charlie.hyun/Repositories/picnic-app-vote-detail-perf/picnic_lib
  grep -n "void main\|testWidgets\|PicnicCachedNetworkImage(\|disableTimeoutForTest" test/presentation/common/picnic_cached_network_image_render_test.dart | head
  ```
  Add a test that mounts `PicnicCachedNetworkImage(imageUrl: ..., deferDuringFastScroll: true, lazyLoadingStrategy: LazyLoadingStrategy.none, showLoadingOverlay: true)` OUTSIDE any `Scrollable` (so `recommendDeferredLoadingForContext` returns false) and asserts it does NOT throw and renders. Follow the file's existing setup (it sets `PicnicCachedNetworkImage.disableTimeoutForTest = true` — keep that). Concretely, copy an existing `testWidgets` block in that file verbatim and only change the constructor to include `deferDuringFastScroll: true`, then keep its existing `expect(find.byType(PicnicCachedNetworkImage), findsOneWidget);`-style assertion:
  ```dart
    testWidgets('renders with deferDuringFastScroll without throwing (C4)',
        (tester) async {
      PicnicCachedNetworkImage.disableTimeoutForTest = true;
      await tester.pumpWidget(
        // reuse the SAME wrapper (MaterialApp/ScreenUtilInit/etc.) used by the
        // adjacent testWidgets in this file:
        _wrap(
          const PicnicCachedNetworkImage(
            imageUrl: 'https://example.com/a.jpg',
            width: 39,
            height: 39,
            deferDuringFastScroll: true,
            lazyLoadingStrategy: LazyLoadingStrategy.none,
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(PicnicCachedNetworkImage), findsOneWidget);
    });
  ```
  (Rename `_wrap` to whatever wrapper helper the file actually defines.)

- [ ] Run tests + analyzer:
  ```bash
  cd /Users/charlie.hyun/Repositories/picnic-app-vote-detail-perf/picnic_lib
  flutter test test/presentation/common/picnic_cached_network_image_render_test.dart test/presentation/common/picnic_cached_network_image_widget_test.dart test/presentation/pages/vote/vote_detail_page_render_test.dart
  dart analyze lib/presentation/common/picnic_cached_network_image.dart lib/presentation/pages/vote/vote_detail_page.dart
  ```
  Expected: `All tests passed!` and `No issues found!` (the `isTopRanking` removal must leave zero unused-variable warnings).

- [ ] Manual fling verification (no meaningful unit test for fling timing). Document in commit body:
  - Profile run, open a vote with 300+ items.
  - Hard fling the list. During the fast fling, rows show the shimmer placeholder (no image network spikes); when the fling settles, the visible rows resolve to real images within a frame or two.
  - Slow scroll still loads images promptly (gate returns false at low velocity).
  - Confirm DevTools timeline: fewer image-decode events during the fling vs `main`; no jank frames introduced.

- [ ] Commit:
  ```bash
  cd /Users/charlie.hyun/Repositories/picnic-app-vote-detail-perf
  git add picnic_lib/lib/presentation/common/picnic_cached_network_image.dart picnic_lib/lib/presentation/pages/vote/vote_detail_page.dart picnic_lib/test/presentation/common/picnic_cached_network_image_render_test.dart
  git commit -m "$(cat <<'EOF'
perf(vote-detail): fling-aware deferred image loading (C4)

- add opt-in PicnicCachedNetworkImage.deferDuringFastScroll (default false)
- when true, build() returns placeholder while
  Scrollable.recommendDeferredLoadingForContext(context) is true
- vote-detail row image opts in, paired with LazyLoadingStrategy.none and
  ImagePriority.low; drop now-unused isTopRanking branch

Manual: hard fling shows shimmer + few decodes; settles to real images;
slow scroll loads promptly; no new jank frames.

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>
EOF
)"
  ```

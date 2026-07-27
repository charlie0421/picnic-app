# 투표 신청 데이터 로딩 구조적 성능 검증 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 실제 DB 시간 측정 없이 enrichment 배치 크기와 쿼리 상한을 회귀 테스트로 고정하고 이름 membership lookup을 Set 기반으로 변경한다.

**Architecture:** 기존 pure helper에 단일 batch-size 상수, Set 이름 수집기, 구조적 쿼리 수 계산기를 추가한다. 서비스는 이 helper의 배치 분할과 Set 수집을 직접 사용하되 기존 순차 배치 및 배치 내부 Future.wait 동작을 유지한다.

**Tech Stack:** Flutter, Dart, flutter_test, Supabase Flutter, Task Master

## Global Constraints

- 실제 DB, migration, Edge Function, RLS에 접근하거나 변경하지 않는다.
- Stopwatch 절대 시간으로 CI 성공·실패를 결정하지 않는다.
- 배치 크기는 정확히 50을 유지한다.
- 배치는 순차 처리하고 배치 내부 2/3개 쿼리 병렬 실행 동작은 유지한다.
- legacy N+1 경로와 검색 서비스는 수정하지 않는다.

---

### Task 1: 구조적 성능 helper

**Files:**
- Modify: `picnic_lib/lib/presentation/widgets/vote/vote_item_request/vote_item_request_service_helper.dart`
- Test: `picnic_lib/test/presentation/widgets/vote/vote_item_request/vote_item_request_service_helper_test.dart`

**Interfaces:**
- Produces: `static const int enrichmentBatchSize = 50`
- Produces: `collectArtistNameSet(List<Map<String, dynamic>>) -> Set<String>`
- Produces: `estimateEnrichmentQueryCount({required int artistCount, required bool hasUser}) -> int`

- [ ] **Step 1: 배치·쿼리 상한 실패 테스트 작성**

```dart
group('enrichment query bounds', () {
  test('keeps the enrichment batch size at 50', () {
    expect(VoteItemRequestServiceHelper.enrichmentBatchSize, 50);
  });

  test('returns deterministic signed-in query bounds', () {
    expect(_queryCount(0, true), 0);
    expect(_queryCount(1, true), 3);
    expect(_queryCount(50, true), 3);
    expect(_queryCount(51, true), 6);
    expect(_queryCount(100, true), 6);
    expect(_queryCount(120, true), 9);
  });

  test('returns deterministic anonymous query bounds', () {
    expect(_queryCount(0, false), 0);
    expect(_queryCount(50, false), 2);
    expect(_queryCount(51, false), 4);
    expect(_queryCount(100, false), 4);
  });
});
```

테스트의 `_queryCount`는 `estimateEnrichmentQueryCount`를 호출하는 로컬 함수다.

- [ ] **Step 2: RED 확인**

Run: `cd picnic_lib && flutter test test/presentation/widgets/vote/vote_item_request/vote_item_request_service_helper_test.dart --plain-name 'enrichment query bounds'`

Expected: 새 상수와 함수가 없어 compile FAIL.

- [ ] **Step 3: 최소 구현**

```dart
static const int enrichmentBatchSize = 50;

static int estimateEnrichmentQueryCount({
  required int artistCount,
  required bool hasUser,
}) {
  if (artistCount < 0) {
    throw ArgumentError.value(artistCount, 'artistCount', 'must not be negative');
  }
  if (artistCount == 0) return 0;
  final batchCount = (artistCount + enrichmentBatchSize - 1) ~/
      enrichmentBatchSize;
  return batchCount * (hasUser ? 3 : 2);
}
```

- [ ] **Step 4: Set 수집 실패 테스트와 구현**

```dart
test('collectArtistNameSet removes duplicates and empty names', () {
  final names = VoteItemRequestServiceHelper.collectArtistNameSet([
    {'ko': 'BTS', 'en': 'BTS'},
    {'ko': '', 'en': 'aespa'},
    {'ko': 'BTS', 'en': ''},
  ]);
  expect(names, {'BTS', 'aespa'});
  expect(names, isA<Set<String>>());
});
```

```dart
static Set<String> collectArtistNameSet(
  List<Map<String, dynamic>> artistNameMaps,
) {
  return collectArtistNames(artistNameMaps).toSet();
}
```

- [ ] **Step 5: 배치 경계·데이터 보존 테스트 보강**

0·1·50·51·100·120개 정수 목록에 `splitIntoBatches`를 적용해 batch 크기가 50 이하이고 `expand` 결과가 원본과 동일한지 검사한다.

- [ ] **Step 6: GREEN 확인과 커밋**

Run: `cd picnic_lib && flutter test test/presentation/widgets/vote/vote_item_request/vote_item_request_service_helper_test.dart`

Expected: 모든 helper 테스트 PASS.

```bash
git add picnic_lib/lib/presentation/widgets/vote/vote_item_request/vote_item_request_service_helper.dart picnic_lib/test/presentation/widgets/vote/vote_item_request/vote_item_request_service_helper_test.dart
git commit -m "test: define vote request loading bounds"
```

---

### Task 2: 운영 서비스에 검증된 배치·Set 연결

**Files:**
- Modify: `picnic_lib/lib/presentation/widgets/vote/vote_item_request/vote_item_request_service.dart`
- Test: `picnic_lib/test/presentation/widgets/vote/vote_item_request/vote_item_request_service_helper_test.dart`
- Regression: `picnic_lib/test/presentation/widgets/vote/vote_item_request/vote_item_request_service_test.dart`
- Regression: `picnic_lib/test/presentation/widgets/vote/vote_item_request/vote_item_request_service_extended_test.dart`

**Interfaces:**
- Consumes: Task 1의 `enrichmentBatchSize`, `splitIntoBatches`, `collectArtistNameSet`
- Preserves: `loadApplicationDataForResults(List<ArtistModel>, String?)` 공개 시그니처와 반환값

- [ ] **Step 1: 기준 테스트 실행**

Run:

```bash
cd picnic_lib
flutter test \
  test/presentation/widgets/vote/vote_item_request/vote_item_request_service_helper_test.dart \
  test/presentation/widgets/vote/vote_item_request/vote_item_request_service_test.dart \
  test/presentation/widgets/vote/vote_item_request/vote_item_request_service_extended_test.dart
```

Expected: PASS. 이 기존 테스트가 동작 보존 기준이다.

- [ ] **Step 2: 배치 분할을 helper로 교체**

```dart
final batches = VoteItemRequestServiceHelper.splitIntoBatches(
  artists,
  VoteItemRequestServiceHelper.enrichmentBatchSize,
);
for (final batch in batches) {
  final batchData = await _loadApplicationDataBatch(batch, userId);
  applicationData.addAll(batchData);
}
return applicationData;
```

기존 수동 분할과 50 이하 별도 분기를 제거한다. 빈 목록은 빈 batch 목록으로 즉시 빈 결과를 반환한다.

- [ ] **Step 3: 이름 목록을 Set으로 교체**

```dart
final artistNames = VoteItemRequestServiceHelper.collectArtistNameSet(
  artists.map((artist) => artist.name).toList(),
);
```

이후의 `artistNames.contains`는 Set lookup을 사용한다. 쿼리, timeout, 순차 batch, `Future.wait` 구조는 변경하지 않는다.

- [ ] **Step 4: 동작 보존 검증**

Task 2 Step 1의 세 테스트 파일을 다시 실행한다.

Expected: 모든 테스트 PASS.

- [ ] **Step 5: 정적 분석과 커밋**

Run:

```bash
cd picnic_lib
dart analyze \
  lib/presentation/widgets/vote/vote_item_request/vote_item_request_service.dart \
  lib/presentation/widgets/vote/vote_item_request/vote_item_request_service_helper.dart \
  test/presentation/widgets/vote/vote_item_request/vote_item_request_service_helper_test.dart
```

Expected: 새 issue 없음.

```bash
git add picnic_lib/lib/presentation/widgets/vote/vote_item_request/vote_item_request_service.dart
git commit -m "perf: bound vote request enrichment work"
```

---

### Task 3: 최종 검증과 Task Master 기록

**Files:**
- Modify through CLI: `.taskmaster/tasks/tasks.json`

**Interfaces:**
- Consumes: Tasks 1·2 결과
- Produces: Task 39.9 완료 상태

- [ ] **Step 1: 전체 집중 테스트**

Run: `cd picnic_lib && flutter test test/presentation/widgets/vote/vote_item_request/`

Expected: 모든 투표 신청 테스트 PASS.

- [ ] **Step 2: diff 검증**

Run: `git diff --check && git status --short`

Expected: whitespace 오류 없음. 변경 범위가 계획 파일과 Task Master 상태뿐임.

- [ ] **Step 3: Task Master 상태 갱신**

```bash
task-master set-status --id=39.9 --status=done
```

39.6·39.7과 상위 39는 미완료 상태를 유지한다.

- [ ] **Step 4: 상태 커밋**

```bash
git add .taskmaster/tasks/tasks.json
git commit -m "chore: record loading performance verification"
```

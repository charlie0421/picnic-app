# 투표 신청 로컬 안정화 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 실제 Supabase DB를 변경하지 않고 투표 신청의 예외 보존, 테이블 누락 메시지, 검색 로딩 종료, 대기 상태 UI를 안정화한다.

**Architecture:** 저장소 계층에 작은 예외 변환 함수를 두고 기존 도메인 예외는 보존한다. 다이얼로그는 서비스 주입 지점을 추가해 실패 경로를 widget test에서 제어하고, 모든 비동기 검색은 `finally`에서 로딩 상태를 해제한다. 상태 버튼은 번역 문자열 비교를 한 함수에 모아 기존 공개 모델을 유지한다.

**Tech Stack:** Flutter, Dart, Riverpod, Supabase Flutter, flutter_test, mock/fake Supabase clients

## Global Constraints

- 실제 Supabase DB, migration, Edge Function, RLS를 변경하거나 호출하지 않는다.
- `picnic_app`과 `picnic_lib` 밖의 프로젝트는 수정하지 않는다.
- DB 내부 오류 문자열과 테이블명을 사용자 UI에 노출하지 않는다.
- Task 39.6(RLS 검증)은 완료 처리하지 않는다.
- 모든 동작 변경은 실패 테스트를 먼저 작성한다.

---

### Task 1: 저장소 도메인 예외와 테이블 누락 오류 보존

**Files:**
- Modify: `picnic_lib/lib/data/repositories/vote_item_request_repository.dart`
- Test: `picnic_lib/test/data/repositories/vote_item_request_repository_test.dart`

**Interfaces:**
- Consumes: `VoteRequestException`, `DuplicateVoteRequestException`, `PostgrestException`
- Produces: `_mapRepositoryError(String operation, Object error) -> Never`

- [ ] **Step 1: 실패 테스트 작성**

`createVoteItemRequestUser`가 중복 예외를 보존하고, `42P01`이 고정 메시지로 변환되는지 추가한다.

```dart
expect(
  () => repository.createVoteItemRequestUser(
    voteId: 1,
    artistId: 100,
    userId: 'user-123',
  ),
  throwsA(isA<DuplicateVoteRequestException>()),
);

final missingTable = PostgrestException(
  message: 'relation "vote_item_requests" does not exist',
  code: '42P01',
);
expect(
  () => VoteItemRequestRepository(
    supabase: FakeErrorSupabaseClient(fromError: missingTable),
  ).getCurrentUserApplicationsWithDetails('user-123'),
  throwsA(
    isA<VoteRequestException>().having(
      (error) => error.message,
      'message',
      '현재 투표 신청 기능을 사용할 수 없습니다.',
    ),
  ),
);
```

- [ ] **Step 2: RED 확인**

Run: `cd picnic_lib && flutter test test/data/repositories/vote_item_request_repository_test.dart`

Expected: 중복 예외가 일반 예외로 감싸지거나 42P01 원문이 포함되어 FAIL.

- [ ] **Step 3: 최소 예외 매핑 구현**

```dart
Never _mapRepositoryError(String operation, Object error) {
  if (error is VoteRequestException) {
    throw error;
  }
  if (error is PostgrestException && error.code == '42P01') {
    throw const VoteRequestException('현재 투표 신청 기능을 사용할 수 없습니다.');
  }
  throw VoteRequestException('$operation 실패');
}
```

`createVoteItemRequestUser`, `getUserVoteItemRequests`와 table-backed 메서드의 catch에서 원문 보간 대신 이 함수를 호출한다. 로그가 필요하면 내부 logger에만 기록한다.

- [ ] **Step 4: 누락 오류 경로와 값 기반 테스트 보강**

`getApplicationCountByTitle`, `updateVoteItemRequestStatus`, `getArtistRequestStatistics`, `getVoteRequestStatusSummary`, `getUserRequestHistory`의 실패가 `VoteRequestException`으로 변환되는지 확인한다. 기존 타입만 검사하는 성공 테스트는 정확한 count, `null`, `true/false`, 상태값을 검사하도록 강화한다.

- [ ] **Step 5: GREEN 확인**

Run: `cd picnic_lib && flutter test test/data/repositories/vote_item_request_repository_test.dart`

Expected: 모든 repository 테스트 PASS.

- [ ] **Step 6: 커밋**

```bash
git add picnic_lib/lib/data/repositories/vote_item_request_repository.dart picnic_lib/test/data/repositories/vote_item_request_repository_test.dart
git commit -m "fix: preserve vote request repository errors"
```

---

### Task 2: 대기 상태 시각 요소 정규화

**Files:**
- Modify: `picnic_lib/lib/presentation/widgets/vote/vote_item_request/search_result_action_button.dart`
- Test: `picnic_lib/test/presentation/widgets/vote/vote_item_request/search_result_action_button_test.dart`

**Interfaces:**
- Consumes: localized `status` string
- Produces: `_isPendingStatus(BuildContext context, String status) -> bool`

- [ ] **Step 1: 실패 widget test 작성**

`vote_item_request_status_pending` 값으로 렌더링했을 때 schedule 아이콘, orange text, orange border가 동시에 적용되는지 검사한다.

```dart
expect(find.byIcon(Icons.schedule_rounded), findsOneWidget);
final text = tester.widget<Text>(find.text(pendingLabel));
expect(text.style?.color, Colors.orange);
final container = tester.widget<Container>(find.byType(Container).last);
final decoration = container.decoration! as BoxDecoration;
expect(decoration.border, isNotNull);
```

- [ ] **Step 2: RED 확인**

Run: `cd picnic_lib && flutter test test/presentation/widgets/vote/vote_item_request/search_result_action_button_test.dart`

Expected: schedule icon 또는 orange text assertion FAIL.

- [ ] **Step 3: 단일 pending 판정 구현**

```dart
bool _isPendingStatus(BuildContext context, String status) {
  final l10n = AppLocalizations.of(context);
  return status == l10n.vote_item_request_status_pending ||
      status == l10n.vote_item_request_waiting;
}
```

build 시작부에서 `final isPending = _isPendingStatus(context, status);`를 계산하고 배경, 테두리, 아이콘, 글자색 모두 같은 값을 사용한다.

- [ ] **Step 4: GREEN 및 회귀 확인**

Run: `cd picnic_lib && flutter test test/presentation/widgets/vote/vote_item_request/search_result_action_button_test.dart test/presentation/widgets/vote/vote_item_request/vote_item_request_status_color_test.dart`

Expected: 모든 상태 UI 테스트 PASS.

- [ ] **Step 5: 커밋**

```bash
git add picnic_lib/lib/presentation/widgets/vote/vote_item_request/search_result_action_button.dart picnic_lib/test/presentation/widgets/vote/vote_item_request/search_result_action_button_test.dart
git commit -m "fix: normalize pending vote request styling"
```

---

### Task 3: 다이얼로그 조회·검색 실패 상태 안정화

**Files:**
- Modify: `picnic_lib/lib/presentation/widgets/vote/vote_item_request/vote_item_request_dialog.dart`
- Test: `picnic_lib/test/presentation/widgets/vote/vote_item_request/vote_item_request_dialog_render_test.dart`

**Interfaces:**
- Consumes: `VoteItemRequestService`
- Produces: optional constructor parameter `VoteItemRequestService? service`, visible generic error state, guaranteed loading cleanup

- [ ] **Step 1: 테스트용 서비스 주입 지점 추가를 요구하는 실패 테스트 작성**

테스트 fake는 초기 조회 또는 검색에서 예외를 던진다.

```dart
class FailingVoteItemRequestService extends Fake
    implements VoteItemRequestService {
  final bool failInitial;
  FailingVoteItemRequestService({this.failInitial = false});

  @override
  Future<Map<String, dynamic>> loadAllApplicationsByArtist() async {
    if (failInitial) throw Exception('internal table detail');
    return {
      'artistApplicationSummaries': <Map<String, dynamic>>[],
      'totalApplications': 0,
    };
  }
}
```

`VoteItemRequestDialog(vote: vote, service: fake)`를 렌더링해 내부 오류 문구는 보이지 않고 일반 오류가 보이며 progress indicator가 사라지는지 확인한다.

- [ ] **Step 2: RED 확인**

Run: `cd picnic_lib && flutter test test/presentation/widgets/vote/vote_item_request/vote_item_request_dialog_render_test.dart`

Expected: `service` 매개변수가 없어 compile FAIL.

- [ ] **Step 3: 서비스 주입과 초기 조회 cleanup 구현**

```dart
class VoteItemRequestDialog extends ConsumerStatefulWidget {
  final VoteModel vote;
  final VoteItemRequestService? service;

  const VoteItemRequestDialog({
    super.key,
    required this.vote,
    this.service,
  });
}
```

`initState`는 `widget.service ?? VoteItemRequestService(...)`를 사용한다. 초기 조회는 성공 데이터 갱신과 별도로 `finally`에서 `_isLoadingApplications = false`를 보장하고 catch에서는 내부 예외를 로그에만 남긴 뒤 일반 오류 메시지를 설정한다.

- [ ] **Step 4: 검색 실패 테스트 작성**

검색 fake가 예외를 던지도록 하고 검색창 입력 후 `pumpAndSettle`한다.

```dart
await tester.enterText(find.byType(TextField), 'artist');
await tester.pumpAndSettle();
expect(find.byType(CircularProgressIndicator), findsNothing);
expect(find.textContaining('internal table detail'), findsNothing);
```

- [ ] **Step 5: 검색 cleanup 최소 구현**

```dart
try {
  await _loadArtistsPage(
    query,
    page: 0,
    isInitial: true,
    searchToken: searchToken,
  );
} catch (error, stackTrace) {
  logger.e('검색 실패', error: error, stackTrace: stackTrace);
  if (mounted && searchToken == _lastSearchToken) {
    setState(() {
      _errorMessage = AppLocalizations.of(context).common_text_search_error;
    });
  }
} finally {
  if (mounted && searchToken == _lastSearchToken) {
    setState(() => _isSearching = false);
  }
}
```

성공 경로에서 `_loadArtistsPage`가 `_isSearching`을 직접 해제하는 코드는 제거해 상태 책임을 `_onSearchChanged`에 모은다.

- [ ] **Step 6: GREEN 및 집중 회귀 확인**

Run:

```bash
cd picnic_lib
flutter test \
  test/data/repositories/vote_item_request_repository_test.dart \
  test/presentation/widgets/vote/vote_item_request/search_result_action_button_test.dart \
  test/presentation/widgets/vote/vote_item_request/vote_item_request_dialog_test.dart \
  test/presentation/widgets/vote/vote_item_request/vote_item_request_dialog_render_test.dart \
  test/presentation/widgets/vote/vote_item_request/current_applications_section_test.dart
```

Expected: 모든 집중 테스트 PASS, uncaught async exception 없음.

- [ ] **Step 7: 정적 검사와 커밋**

Run: `cd picnic_lib && dart analyze lib/data/repositories/vote_item_request_repository.dart lib/presentation/widgets/vote/vote_item_request/vote_item_request_dialog.dart lib/presentation/widgets/vote/vote_item_request/search_result_action_button.dart`

Expected: 새 error 없음.

```bash
git add picnic_lib/lib/presentation/widgets/vote/vote_item_request/vote_item_request_dialog.dart picnic_lib/test/presentation/widgets/vote/vote_item_request/vote_item_request_dialog_render_test.dart
git commit -m "fix: handle vote request dialog load failures"
```

---

### Task 4: 최종 검증과 Task Master 기록

**Files:**
- Modify through CLI: `.taskmaster/tasks/tasks.json`
- Modify through CLI: `.taskmaster/state.json`

**Interfaces:**
- Consumes: Tasks 1–3의 테스트 결과
- Produces: 완료된 로컬 subtasks와 미완료 39.6 상태 기록

- [ ] **Step 1: diff와 비밀정보 검사**

Run: `git diff --check && git status --short`

Expected: whitespace error 없음. 변경 파일이 계획 범위와 Task Master 상태 파일뿐임.

- [ ] **Step 2: 관련 테스트 전체 실행**

Run: `cd picnic_lib && flutter test test/data/repositories/vote_item_request_repository_test.dart test/presentation/widgets/vote/vote_item_request/`

Expected: 모든 테스트 PASS.

- [ ] **Step 3: Task Master 하위 작업 갱신**

로컬에서 실제로 검증된 항목만 완료 처리한다.

```bash
task-master set-status --id=39.3 --status=done
task-master set-status --id=39.10 --status=done
task-master set-status --id=39.15 --status=done
```

`39.6`은 원격 schema/RLS 근거가 없어 `pending`을 유지한다. 따라서 상위 `39`도 `in-progress`를 유지한다.

- [ ] **Step 4: Task Master 상태 커밋**

```bash
git add .taskmaster/tasks/tasks.json .taskmaster/state.json
git commit -m "chore: record vote request hardening progress"
```

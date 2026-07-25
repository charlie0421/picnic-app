# 투표 신청 키보드 이벤트 검증 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 투표 신청 검색창의 정상 Backspace 동작을 회귀 테스트로 고정하고, Flutter 키 상태 assertion의 증거 수집·복구 절차를 한글 HTML로 문서화한다.

**Architecture:** 운영 위젯 코드는 변경하지 않는다. 실제 `VoteItemRequestDialog`와 가짜 서비스를 사용하는 widget test로 정상 down/up 키 시퀀스를 검증한다. 환경적 키 상태 불일치는 실행 절차와 증거 수집 기준으로 관리한다.

**Tech Stack:** Flutter 3.41.4, Dart 3.11.1, flutter_test, Task Master

## Global Constraints

- `picnic_lib` 운영 코드를 변경하지 않는다.
- Raw keyboard interception이나 Flutter pressed-key 상태 조작을 추가하지 않는다.
- 실제 DB, migration, Edge Function, RLS에 접근하거나 변경하지 않는다.
- unmatched KeyUp 이벤트로 framework assertion을 인위적으로 만들지 않는다.
- 대응 문서는 한글 HTML로 작성한다.

---

### Task 1: 정상 Backspace 회귀 테스트

**Files:**
- Modify: `picnic_lib/test/presentation/widgets/vote/vote_item_request/vote_item_request_dialog_render_test.dart`

**Interfaces:**
- Consumes: `VoteItemRequestDialog`, `FailingVoteItemRequestService`, Flutter test keyboard API
- Produces: 정상 paired Backspace와 focus 유지에 대한 회귀 테스트

- [ ] **Step 1: 실제 다이얼로그 키보드 테스트 작성**

```dart
testWidgets('검색창은 정상 Backspace 입력을 처리하고 focus를 유지한다', (
  WidgetTester tester,
) async {
  await tester.pumpWidget(
    buildTestAppPage(
      Material(
        child: VoteItemRequestDialog(
          vote: testVote,
          service: FailingVoteItemRequestService(),
        ),
      ),
      loggedIn: true,
    ),
  );
  await tester.pumpAndSettle();

  await tester.tap(find.byType(TextField));
  await tester.pump();
  final editable = tester.widget<EditableText>(find.byType(EditableText));
  expect(editable.focusNode.hasFocus, isTrue);

  await tester.enterText(find.byType(TextField), 'ab');
  await tester.pump();
  await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
  await tester.pump();

  expect(editable.controller.text, 'a');
  expect(editable.focusNode.hasFocus, isTrue);
  expect(tester.takeException(), isNull);
});
```

- [ ] **Step 2: 테스트 실행과 결과 판정**

Run: `cd picnic_lib && flutter test test/presentation/widgets/vote/vote_item_request/vote_item_request_dialog_render_test.dart --plain-name '검색창은 정상 Backspace 입력을 처리하고 focus를 유지한다'`

Expected: PASS. 실패하면 assertion과 stack을 보존하고 운영 코드 수정 없이 root-cause 조사로 돌아간다.

- [ ] **Step 3: 관련 회귀 테스트 실행**

Run:

```bash
cd picnic_lib
flutter test \
  test/presentation/widgets/vote/vote_item_request/search_and_results_section_test.dart \
  test/presentation/widgets/vote/vote_item_request/vote_item_request_dialog_render_test.dart \
  test/presentation/widgets/enhanced_search_box_test.dart
```

Expected: 모든 테스트 PASS, HardwareKeyboard assertion 없음.

- [ ] **Step 4: 커밋**

```bash
git add picnic_lib/test/presentation/widgets/vote/vote_item_request/vote_item_request_dialog_render_test.dart
git commit -m "test: cover vote request backspace input"
```

---

### Task 2: 키보드 assertion 대응 문서

**Files:**
- Create: `docs/troubleshooting/vote-request-keyboard-events.html`

**Interfaces:**
- Consumes: Task 39 조사 결과와 Flutter assertion 의미
- Produces: 개발자가 재현·복구·에스컬레이션에 사용하는 한글 HTML 문서

- [ ] **Step 1: 대응 문서 작성**

문서에 다음 항목을 모두 포함한다.

```text
증상: KeyUpEvent/HardwareKeyboard physical key assertion
즉시 복구: focus 해제 → Hot Restart → 앱 완전 종료/재시작 → flutter clean/pub get
수집 증거: 전체 stack, OS/기기, Flutter revision, build mode, hot reload/restart, window focus, 키 순서
금지 조치: pressed-key 내부 상태 조작, KeyUp 무시, Backspace 대체
에스컬레이션: 완전 재시작 후에도 정상 down/up에서 재현되면 최소 프로젝트와 함께 Flutter upstream 보고
```

- [ ] **Step 2: 문서 자체 검증**

Run:

```bash
rg -n "KeyUpEvent|HardwareKeyboard|flutter doctor -v|Hot Restart|완전 종료|금지|upstream" docs/troubleshooting/vote-request-keyboard-events.html
git diff --check -- docs/troubleshooting/vote-request-keyboard-events.html
```

Expected: 모든 필수 항목이 검색되고 whitespace 오류 없음.

- [ ] **Step 3: 커밋**

```bash
git add docs/troubleshooting/vote-request-keyboard-events.html
git commit -m "docs: add keyboard assertion troubleshooting"
```

---

### Task 3: 검증과 Task Master 갱신

**Files:**
- Modify through CLI: `.taskmaster/tasks/tasks.json`

**Interfaces:**
- Consumes: Task 1·2 결과
- Produces: 완료된 39.4·39.5 상태

- [ ] **Step 1: 전체 범위 검증**

Run:

```bash
cd picnic_lib
flutter test \
  test/presentation/widgets/vote/vote_item_request/search_and_results_section_test.dart \
  test/presentation/widgets/vote/vote_item_request/vote_item_request_dialog_render_test.dart \
  test/presentation/widgets/enhanced_search_box_test.dart
dart analyze test/presentation/widgets/vote/vote_item_request/vote_item_request_dialog_render_test.dart
```

Expected: 테스트와 분석 PASS.

- [ ] **Step 2: Task Master 상태 변경**

```bash
task-master set-status --id=39.4 --status=done
task-master set-status --id=39.5 --status=done
```

상위 39와 39.6은 미완료 상태를 유지한다.

- [ ] **Step 3: 상태 커밋**

```bash
git add .taskmaster/tasks/tasks.json
git commit -m "chore: record keyboard verification progress"
```

# 투표 항목 신청 운영 보안 최소 수정 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 앱의 전체 신청 행 조회를 식별자 없는 집계 조회로 교체해 사용자별 RLS를 적용할 준비를 마치고, DB 소유 저장소에 안전한 권한 축소와 비밀키 회전 절차를 인계한다.

**Architecture:** `picnic_lib`는 기존 `vote_item_request_status_summary` 집계 뷰에서 투표·아티스트·상태별 개수만 읽고, 사용자 상태는 RLS가 적용되는 자기 행 조회로 분리한다. `picnic-app`에는 DB migration을 추가하지 않으며, DB 정책·권한·webhook 변경은 별도 소유 저장소 `picnic-supabase`의 후속 작업으로 명시한다.

**Tech Stack:** Flutter 3.41, Dart 3.11, `flutter_test`, Supabase/PostgREST, PostgreSQL RLS

## Global Constraints

- 대상은 `picnic_app`과 `picnic_lib`이며 폐기된 `ttja`는 수정하지 않는다.
- 비활성 커뮤니티 기능은 건드리지 않는다.
- 이 저장소에는 Supabase migration을 추가하지 않는다. `CLAUDE.md`에 따라 DB schema는 `/Users/charlie.hyun/Repositories/picnic-supabase`가 소유한다.
- 운영 DB 쓰기, `supabase db push`, 함수 배포, secret 변경, 키 회전은 수행하지 않는다.
- JWT, service role key, project ref, 사용자 데이터는 코드·문서·테스트 출력에 넣지 않는다.
- 공개 집계에는 `user_id`, 신청 UUID, IP hash, 생성 시각 등 개인별 행 정보가 포함되지 않는다.
- 현재 사용자 신청 여부와 상태는 `auth.uid()` 기반 자기 행 RLS를 전제로 한다. 호출자가 전달한 `userId`는 보안 경계가 아니다.
- 프로덕션 코드 변경 전에 실패 테스트를 먼저 실행한다.

---

### Task 1: 집계 응답 변환기를 테스트로 고정

**Files:**
- Create: `picnic_lib/lib/data/models/vote/vote_item_request_count_summary.dart`
- Create: `picnic_lib/test/data/models/vote/vote_item_request_count_summary_test.dart`

**Interfaces:**
- Consumes: `vote_item_request_status_summary`의 `vote_id`, `artist_id`, `artist_name`, `request_status`, `request_count`
- Produces: `VoteItemRequestCountSummary.fromRows(List<dynamic>)`, `totalCount`, `countsByArtistId`, `countsByArtistName`, `statusCountsByArtistId`

- [ ] **Step 1: 실패하는 변환기 테스트 작성**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/vote/vote_item_request_count_summary.dart';

void main() {
  test('상태별 집계 행을 아티스트별 합계로 합친다', () {
    final summary = VoteItemRequestCountSummary.fromRows([
      {'artist_id': 10, 'artist_name': '가수 A', 'request_status': 'pending', 'request_count': 2},
      {'artist_id': 10, 'artist_name': '가수 A', 'request_status': 'approved', 'request_count': 3},
      {'artist_id': 20, 'artist_name': '가수 B', 'request_status': 'pending', 'request_count': 1},
    ]);

    expect(summary.totalCount, 6);
    expect(summary.countsByArtistId, {10: 5, 20: 1});
    expect(summary.countsByArtistName, {'가수 A': 5, '가수 B': 1});
    expect(summary.statusCountsByArtistId[10], {'pending': 2, 'approved': 3});
  });

  test('잘못된 행과 음수 개수는 집계에서 제외한다', () {
    final summary = VoteItemRequestCountSummary.fromRows([
      {'artist_id': null, 'artist_name': '누락', 'request_status': 'pending', 'request_count': 2},
      {'artist_id': 10, 'artist_name': '가수 A', 'request_status': 'pending', 'request_count': -1},
      {'artist_id': 10, 'artist_name': '가수 A', 'request_status': 'pending', 'request_count': 2},
    ]);

    expect(summary.totalCount, 2);
    expect(summary.countsByArtistId, {10: 2});
  });
}
```

- [ ] **Step 2: 테스트가 클래스 부재로 실패하는지 확인**

Run: `cd picnic_lib && flutter test test/data/models/vote/vote_item_request_count_summary_test.dart`

Expected: `vote_item_request_count_summary.dart` 또는 `VoteItemRequestCountSummary`를 찾지 못해 FAIL.

- [ ] **Step 3: 최소 변환기 구현**

```dart
import 'dart:collection';

class VoteItemRequestCountSummary {
  VoteItemRequestCountSummary._({
    required this.totalCount,
    required Map<int, int> countsByArtistId,
    required Map<String, int> countsByArtistName,
    required Map<int, Map<String, int>> statusCountsByArtistId,
  })  : countsByArtistId = UnmodifiableMapView(countsByArtistId),
        countsByArtistName = UnmodifiableMapView(countsByArtistName),
        statusCountsByArtistId = UnmodifiableMapView(
          statusCountsByArtistId.map(
            (key, value) => MapEntry(key, UnmodifiableMapView(value)),
          ),
        );

  final int totalCount;
  final Map<int, int> countsByArtistId;
  final Map<String, int> countsByArtistName;
  final Map<int, Map<String, int>> statusCountsByArtistId;

  factory VoteItemRequestCountSummary.fromRows(List<dynamic> rows) {
    var totalCount = 0;
    final countsByArtistId = <int, int>{};
    final countsByArtistName = <String, int>{};
    final statusCountsByArtistId = <int, Map<String, int>>{};

    for (final raw in rows) {
      if (raw is! Map) continue;
      final artistId = raw['artist_id'];
      final artistName = raw['artist_name'];
      final status = raw['request_status'];
      final count = raw['request_count'];
      if (artistId is! int ||
          artistName is! String || artistName.trim().isEmpty ||
          status is! String || status.trim().isEmpty ||
          count is! int || count < 0) {
        continue;
      }
      totalCount += count;
      countsByArtistId[artistId] = (countsByArtistId[artistId] ?? 0) + count;
      countsByArtistName[artistName] =
          (countsByArtistName[artistName] ?? 0) + count;
      final statuses = statusCountsByArtistId.putIfAbsent(
        artistId,
        () => <String, int>{},
      );
      statuses[status] = (statuses[status] ?? 0) + count;
    }

    return VoteItemRequestCountSummary._(
      totalCount: totalCount,
      countsByArtistId: countsByArtistId,
      countsByArtistName: countsByArtistName,
      statusCountsByArtistId: statusCountsByArtistId,
    );
  }
}
```

- [ ] **Step 4: 변환기 테스트 통과 확인**

Run: `cd picnic_lib && flutter test test/data/models/vote/vote_item_request_count_summary_test.dart`

Expected: `All tests passed!`

- [ ] **Step 5: 변경 커밋**

```bash
git add picnic_lib/lib/data/models/vote/vote_item_request_count_summary.dart picnic_lib/test/data/models/vote/vote_item_request_count_summary_test.dart
git commit -m "feat: model anonymous vote request counts"
```

### Task 2: Repository의 전체 행 카운트를 집계 뷰로 교체

**Files:**
- Modify: `picnic_lib/lib/data/repositories/vote_item_request_repository.dart`
- Modify: `picnic_lib/test/data/repositories/vote_item_request_repository_test.dart`

**Interfaces:**
- Consumes: `VoteItemRequestCountSummary.fromRows`, Supabase relation `vote_item_request_status_summary`
- Produces: `Future<VoteItemRequestCountSummary> getVoteItemRequestCountSummary(int voteId)`
- Preserves: `Future<int> getVoteItemRequestCount(int voteId)`가 새 summary의 `totalCount`를 반환

- [ ] **Step 1: Repository 실패 테스트 추가**

Mock Supabase에 아래 집계 행을 설정하고 `getVoteItemRequestCountSummary(7)`이 아티스트별 합계와 전체 합계를 반환하는지 검증한다.

```dart
'vote_item_request_status_summary': [
  {'vote_id': 7, 'artist_id': 10, 'artist_name': '가수 A', 'request_status': 'pending', 'request_count': 2},
  {'vote_id': 7, 'artist_id': 10, 'artist_name': '가수 A', 'request_status': 'approved', 'request_count': 1},
],
```

기존 `getVoteItemRequestCount` 테스트는 기본 테이블이 아닌 위 relation을 사용한다고 기대하도록 수정한다.

- [ ] **Step 2: Repository 테스트 실패 확인**

Run: `cd picnic_lib && flutter test test/data/repositories/vote_item_request_repository_test.dart`

Expected: 새 메서드 부재 또는 기존 `vote_item_request_users` 조회 때문에 FAIL.

- [ ] **Step 3: 최소 Repository 구현**

```dart
Future<VoteItemRequestCountSummary> getVoteItemRequestCountSummary(
  int voteId,
) async {
  try {
    final response = await _supabase
        .from('vote_item_request_status_summary')
        .select('vote_id, artist_id, artist_name, request_status, request_count')
        .eq('vote_id', voteId);
    return VoteItemRequestCountSummary.fromRows(response as List);
  } catch (e) {
    _mapRepositoryError('투표 아이템 요청 집계 조회', e);
  }
}
```

`getVoteItemRequestCount`는 이 메서드의 `totalCount`만 반환한다.

- [ ] **Step 4: Repository 테스트 통과 확인**

Run: `cd picnic_lib && flutter test test/data/repositories/vote_item_request_repository_test.dart`

Expected: 모든 테스트 PASS.

- [ ] **Step 5: 변경 커밋**

```bash
git add picnic_lib/lib/data/repositories/vote_item_request_repository.dart picnic_lib/test/data/repositories/vote_item_request_repository_test.dart
git commit -m "security: read vote request counts from aggregate view"
```

### Task 3: 신청 다이얼로그의 전체 사용자 행 조회 제거

**Files:**
- Modify: `picnic_lib/lib/presentation/widgets/vote/vote_item_request/vote_item_request_service.dart`
- Modify: `picnic_lib/test/presentation/widgets/vote/vote_item_request/vote_item_request_service_test.dart`
- Modify: `picnic_lib/test/presentation/widgets/vote/vote_item_request/vote_item_request_service_extended_test.dart`

**Interfaces:**
- Consumes: `VoteItemRequestRepository.getVoteItemRequestCountSummary`
- Produces: 검색 결과 신청 수와 아티스트별 상태 요약을 개인별 신청 행 없이 구성
- Preserves: 현재 사용자의 `artist_id`, `status` 조회와 기존 화면 반환 Map 키

- [ ] **Step 1: 전체 신청 행을 요구하지 않는 실패 테스트 작성**

테스트 harness의 `vote_item_request_users`에는 현재 사용자 한 행만 두고, `vote_item_request_status_summary`에는 여러 사용자의 합계에 해당하는 집계 행을 둔다. `loadApplicationData`와 `loadAllApplicationsByArtist` 결과가 집계 뷰의 개수를 사용하고 타 사용자 UUID 없이 정상 구성되는지 검증한다.

- [ ] **Step 2: 기존 구현이 전체 행 relation에 의존해 실패하는지 확인**

Run: `cd picnic_lib && flutter test test/presentation/widgets/vote/vote_item_request/vote_item_request_service_test.dart test/presentation/widgets/vote/vote_item_request/vote_item_request_service_extended_test.dart`

Expected: 공개 신청 수 또는 전체 그룹 요약이 기대한 집계 수와 달라 FAIL.

- [ ] **Step 3: 배치 신청 수 조회 교체**

`_loadApplicationDataBatch`의 첫 번째 `vote_item_request_users` 전체 행 조회를 `getVoteItemRequestCountSummary` 한 번으로 교체한다. 이름 기반 Map은 summary의 `countsByArtistName`, 정확한 매칭은 `countsByArtistId`를 우선 사용한다. 현재 사용자 상태를 읽는 두 번째 자기 행 조회는 유지한다.

- [ ] **Step 4: 전체 신청 그룹 조회 교체**

`loadAllApplicationsByArtist`가 `getVoteItemRequestsByVoteId`로 개인별 행을 가져오지 않고 summary의 `countsByArtistId`와 `statusCountsByArtistId`로 기존 화면용 요약 Map을 구성하도록 변경한다. 화면이 사용하지 않는 신청 UUID와 사용자 UUID는 반환하지 않는다.

- [ ] **Step 5: 관련 서비스 테스트 통과 확인**

Run: `cd picnic_lib && flutter test test/presentation/widgets/vote/vote_item_request/vote_item_request_service_test.dart test/presentation/widgets/vote/vote_item_request/vote_item_request_service_extended_test.dart`

Expected: 모든 테스트 PASS.

- [ ] **Step 6: 전체 신청 행 조회가 UI 경로에서 제거됐는지 정적 확인**

Run: `rg -n "getVoteItemRequestsByVoteId|from\('vote_item_request_users'\)" picnic_lib/lib/presentation/widgets/vote/vote_item_request/vote_item_request_service.dart`

Expected: `getVoteItemRequestsByVoteId`는 0건. 기본 테이블 조회는 현재 사용자의 상태를 읽는 한 경로만 남고 반드시 `.eq('user_id', userId)`를 포함한다.

- [ ] **Step 7: 변경 커밋**

```bash
git add picnic_lib/lib/presentation/widgets/vote/vote_item_request/vote_item_request_service.dart picnic_lib/test/presentation/widgets/vote/vote_item_request/vote_item_request_service_test.dart picnic_lib/test/presentation/widgets/vote/vote_item_request/vote_item_request_service_extended_test.dart
git commit -m "security: remove cross-user vote request reads"
```

### Task 4: DB 소유 저장소 인계 문서와 운영 런북 작성

**Files:**
- Create: `docs/security/vote-request-production-hardening-handoff.html`

**Interfaces:**
- Consumes: 운영 schema-only 감사 결과와 앱의 새 집계 계약
- Produces: 비밀값 없는 한글 인계 문서, `picnic-supabase` migration/test 경로, 배포·검증·롤백 gate

- [ ] **Step 1: 한글 HTML 인계 문서 작성**

문서에는 다음을 정확히 기록한다.

1. 앱이 필요로 하는 공개 relation은 `vote_item_request_status_summary`의 다섯 컬럼뿐이다.
2. `vote_item_request_users` SELECT는 authenticated의 `auth.uid() = user_id`만 허용하고 anon은 금지한다.
3. anon/authenticated의 INSERT, TRUNCATE, TRIGGER를 회수한다.
4. 일반 사용자 UPDATE/DELETE는 현재 UI 계약에 필요 없으며 회수한다. 관리자/service role 정책만 유지한다.
5. `vote_item_requests`, `user_vote_item_request_history`는 `security_invoker = true`와 본인 RLS를 적용한다.
6. 공개 집계 뷰는 사용자 식별 컬럼 없이 SELECT만 허용한다.
7. migration 경로는 `/Users/charlie.hyun/Repositories/picnic-supabase/supabase/migrations/<timestamp>_harden_vote_item_request_access.sql`, 테스트 경로는 `supabase/tests/vote_item_request/01_access_security.test.sql`이다.
8. DB webhook에 service role JWT literal을 두지 않고 versioned shared secret/Vault와 Edge Function 환경 secret으로 분리한다.
9. 키 회전 전후 검증, 15–30분 관찰, 비밀값을 되돌리지 않는 forward-fix 롤백 원칙을 기록한다.

- [ ] **Step 2: 문서 비밀값·완성도 검사**

Run:

```bash
python3 -c "from html.parser import HTMLParser; p=HTMLParser(); p.feed(open('docs/security/vote-request-production-hardening-handoff.html', encoding='utf-8').read()); p.close(); print('HTML parse: PASS')"
rg -n "eyJ|service_role.{0,20}[A-Za-z0-9_-]{20,}" docs/security/vote-request-production-hardening-handoff.html
```

Expected: HTML parse PASS, `rg` 결과 0건.

- [ ] **Step 3: 문서 커밋**

```bash
git add docs/security/vote-request-production-hardening-handoff.html
git commit -m "docs: hand off vote request database hardening"
```

### Task 5: 앱 회귀 검증과 Task Master 기록

**Files:**
- Modify via CLI only: `.taskmaster/tasks/tasks.json` and generated Task Master files

**Interfaces:**
- Consumes: Tasks 1–4 결과
- Produces: 앱 측 준비 완료 증거와 DB 소유 저장소 작업이 남았다는 정확한 상태 기록

- [ ] **Step 1: vote request 집중 테스트 실행**

Run:

```bash
cd picnic_lib
flutter test \
  test/data/models/vote/vote_item_request_count_summary_test.dart \
  test/data/repositories/vote_item_request_repository_test.dart \
  test/presentation/widgets/vote/vote_item_request/vote_item_request_service_test.dart \
  test/presentation/widgets/vote/vote_item_request/vote_item_request_service_extended_test.dart
```

Expected: 모든 테스트 PASS.

- [ ] **Step 2: 정적 분석 실행**

Run: `cd picnic_lib && flutter analyze lib/data/models/vote/vote_item_request_count_summary.dart lib/data/repositories/vote_item_request_repository.dart lib/presentation/widgets/vote/vote_item_request/vote_item_request_service.dart`

Expected: `No issues found!`

- [ ] **Step 3: 저장소 위생 검사**

Run:

```bash
git diff --check
git status --short
rg -n "eyJ[a-zA-Z0-9_-]{10,}" docs picnic_app picnic_lib --glob '!**/build/**' --glob '!**/.dart_tool/**'
```

Expected: whitespace 오류 없음. 계획된 파일 외 변경 없음. 새 JWT 패턴 없음.

- [ ] **Step 4: Task Master에 단계 경계 기록**

```bash
task-master update-subtask --id=39.6 --prompt="운영 schema-only 감사에서 전체 행 SELECT, 과도한 권한, webhook JWT literal을 확인했다. picnic-app 측 cross-user 조회를 익명 집계 뷰로 교체하고 회귀 테스트를 통과했다. 실제 RLS/권한 수정과 A/B/admin DB 검증은 schema owner picnic-supabase 작업으로 남아 있어 39.6은 완료 처리하지 않는다."
task-master update-subtask --id=39.7 --prompt="운영 테이블/뷰/제약/인덱스 계약을 확인했고 앱은 vote_item_request_status_summary 집계 계약으로 전환했다. DB migration은 CLAUDE.md에 따라 picnic-supabase 저장소에서 수행해야 한다."
```

- [ ] **Step 5: 검증 기록 커밋**

```bash
git add .taskmaster
git commit -m "chore: record vote request security handoff"
```

## 별도 저장소 후속 Gate

이 계획 실행만으로 운영 취약점은 제거되지 않는다. `/Users/charlie.hyun/Repositories/picnic-supabase` 변경 권한과 운영 배포 승인을 받은 후 다음을 별도 계획으로 수행한다.

1. `supabase migration new harden_vote_item_request_access`
2. `supabase/tests/vote_item_request/01_access_security.test.sql`에 anon/A/B/admin 권한 행렬 추가
3. 로컬 `supabase db reset`, lint, DB 테스트 실행
4. webhook의 JWT literal 제거와 shared secret/Vault 전환
5. 승인된 변경창에서 배포·canary·키 회전·15–30분 관찰

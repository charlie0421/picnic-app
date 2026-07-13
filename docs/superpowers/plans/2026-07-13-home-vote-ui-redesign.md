# Picnic 홈/투표 UI 개편 v2.2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** picnic-app 홈/투표 화면을 PRD v2.2대로 개편한다 — 하단탭(홈/투표/미디어/상점)·상단 헤더 정리, 홈 요약 허브 신설, 투표 페이지를 종류탭+상태필터 구조로 재구성, 백엔드 `vote_type` 도입.

**Architecture:** 백엔드에 `vote_type` 테이블 + `vote.vote_type_id`를 추가하고(별도 picnic-supabase 마이그레이션), 앱은 기존 `@riverpod` async provider / `@freezed` 모델 패턴으로 데이터 계층을 확장한다. 네비게이션은 data-driven `NavigationConfigs`를 수정하고, 헤더 "흰색 스트립" 제거는 페이지가 `settingNavigation(showTopMenu:false)`를 호출하는 방식으로 처리한다. 홈은 새 `HomePage`, 투표 탭은 재구성된 `VoteListPage`.

**Tech Stack:** Flutter, Riverpod(riverpod_generator, `@riverpod`), Freezed, Supabase(supabase_flutter), flutter_screenutil, infinite_scroll_pagination, gen-l10n(ARB).

## Global Constraints

- 대상 레포/작업트리: `~/Repositories/picnic-app-home-vote-ui` (브랜치 `feat/home-vote-ui-redesign`). 백엔드 마이그레이션만 별도 레포 `~/Repositories/picnic-supabase`.
- 코드 생성물은 소스 옆이 아니라 `picnic_lib/lib/generated/providers/...`(모델은 `.../models/...`)로 나온다 — `part '../../generated/providers/...'` 상대경로 규칙 준수.
- 코드 생성 1회 실행: `cd picnic_lib && dart run build_runner build --delete-conflicting-outputs` (레포 스크립트는 watch 모드이므로 CI/단발 실행엔 build 사용).
- 테스트는 `picnic_lib`에서 실행: `cd picnic_lib && flutter test <path>`. Supabase는 `setupMockSupabase({...})`(`test/helpers/mock_supabase.dart`)로 목킹, provider는 `ProviderContainer()` + `container.read(xProvider.future)`.
- l10n: 새 키는 `picnic_lib/lib/l10n/app_en.arb`(템플릿) + `app_ko.arb`에만 추가하고 `flutter gen-l10n`(picnic_lib에서) 재생성 후 생성물 커밋. **다른 로케일 ARB에 비라틴 문자열을 직접 작성하지 말 것**(영어 fallback 허용).
- 투표 종류 탭 라벨은 ARB가 아니라 DB `vote_type.title`(localized JSON)에서 온다.
- 상태 필터 기본값은 **항상 진행중(active)**, 페이지 로컬 state, **재진입 시 저장 안 함**(PageStorage/persist 금지).
- 홈 대표 투표 = active 중 `stop_at ASC` 첫 1건(곧 종료). 카드엔 rank-1만.
- 공용 `VoteInfoCard`는 수정 금지(홈은 별도 카드). 궁합/PIC/커뮤니티 포탈 코드·딥링크는 삭제 금지(상단 진입점만 제거).
- 커밋 메시지: Conventional Commits, 끝에 `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`.

---

## File Structure

**picnic-supabase (별도 레포)**
- Create: `supabase/migrations/<ts>_add_vote_type.sql` — vote_type 테이블 + vote.vote_type_id + 시드 + 백필.

**picnic-app / picnic_lib (신규)**
- `lib/data/models/vote/vote_type.dart` — `VoteType` freezed 모델.
- `lib/presentation/providers/vote_type_list_provider.dart` — `asyncVoteTypeListProvider`.
- `lib/presentation/providers/featured_vote_provider.dart` — `asyncFeaturedVoteProvider` (홈 대표 투표).
- `lib/presentation/providers/latest_media_provider.dart` — `asyncLatestMediaProvider` (홈 미디어 6).
- `lib/presentation/pages/vote/home_page.dart` — 신규 `HomePage`(홈 탭).
- `lib/presentation/widgets/vote/reward_list_section.dart` — 리워드 가로 리스트 재사용 위젯.
- `lib/presentation/widgets/vote/home_featured_vote_card.dart` — 홈 전용 rank-1 카드.
- `lib/presentation/widgets/vote/latest_media_section.dart` — 홈 미디어 가로 캐러셀.

**picnic-app / picnic_lib (수정)**
- `lib/data/models/vote/vote.dart` — `vote_type_id` 필드.
- `lib/presentation/providers/vote_list_provider.dart` — `voteTypeId` 파라미터/필터/select.
- `lib/presentation/widgets/vote/list/vote_list.dart` — `voteTypeId` 스레딩.
- `lib/presentation/pages/vote/vote_list_page.dart` — 종류탭 + 상태 드롭다운 재구성.
- `lib/data/models/navigator/navigation_configs.dart` — vote 포탈 탭 재정의(홈 추가/커뮤니티 제거).
- `lib/l10n/app_en.arb`, `lib/l10n/app_ko.arb` — 신규 키.

**picnic-app / picnic_app (수정)**
- `lib/presentation/screens/portal.dart` — Vote/GoongHap 버튼 + 출석체크 제거.
- `lib/bottom_navigation_menu.dart` — votePages 동기화(vestigial 정합).

---

## Task 1: 백엔드 `vote_type` 마이그레이션 (picnic-supabase)

**Files:**
- Create: `~/Repositories/picnic-supabase/supabase/migrations/<timestamp>_add_vote_type.sql`

**Interfaces:**
- Produces: 테이블 `public.vote_type(id bigint PK, code text unique, title jsonb, "order" int, deleted_at timestamptz)`; 컬럼 `public.vote.vote_type_id bigint FK`; 시드 4행(picnic/musical/joongang/cgv); 기존 vote 백필.

- [ ] **Step 1: 마이그레이션 파일 생성**

파일명 타임스탬프는 기존 마이그레이션 규칙을 따른다(디렉터리에서 최신 파일명 형식 확인 후 그 다음 순번). 내용:

```sql
-- vote_type: 투표 종류(주최사 기반) 탭의 데이터 소스
create table if not exists public.vote_type (
  id          bigint generated always as identity primary key,
  code        text not null unique,
  title       jsonb not null default '{}'::jsonb,
  "order"     integer not null default 0,
  deleted_at  timestamptz
);

alter table public.vote
  add column if not exists vote_type_id bigint references public.vote_type(id);

create index if not exists vote_vote_type_id_idx on public.vote(vote_type_id);

-- 시드 (title 은 ko/en 최소 제공)
insert into public.vote_type (code, title, "order") values
  ('picnic',   '{"ko":"피크닉","en":"Picnic"}',        0),
  ('musical',  '{"ko":"뮤지컬","en":"Musical"}',        1),
  ('joongang', '{"ko":"중앙일보","en":"JoongAng"}',      2),
  ('cgv',      '{"ko":"CGV","en":"CGV"}',               3)
on conflict (code) do nothing;

-- 기존 vote 백필: musical area -> musical, 그 외 -> picnic
update public.vote v
set vote_type_id = (select id from public.vote_type where code = 'musical')
where v.vote_type_id is null
  and v.areas @> array['musical'];

update public.vote v
set vote_type_id = (select id from public.vote_type where code = 'picnic')
where v.vote_type_id is null;

-- 읽기 권한 (기존 vote/reward 와 동일한 최소 grant; 쓰기 미부여)
grant select on public.vote_type to anon, authenticated;
alter table public.vote_type enable row level security;
create policy vote_type_select_all on public.vote_type
  for select using (true);
```

- [ ] **Step 2: SQL 문법/컬럼 존재 검증 (읽기 전용 확인)**

`vote` 테이블에 `areas`(text[]) 컬럼이 실제 존재하는지 먼저 확인(백필 근거). picnic-supabase MCP 또는 psql로:
Run: `select column_name, data_type from information_schema.columns where table_schema='public' and table_name='vote' and column_name in ('areas','vote_type_id');`
Expected: `areas` 존재(백필 전), `vote_type_id` 없음(마이그레이션 전).

> `areas`가 `text[]`가 아니라면(예: jsonb) 백필의 `@>` 조건을 해당 타입에 맞게 수정할 것. 매핑 근거가 없으면 musical 백필 UPDATE를 생략하고 전부 picnic으로 백필한다.

- [ ] **Step 3: 마이그레이션 적용 (사용자 확인 후)**

공유 인스턴스(`xtijtefcycoeqludlngc`)에 적용. **사용자 지시가 있을 때만** MCP `apply_migration` 또는 `supabase db push`. 적용은 별도 PR/명령으로 처리하고, 앱 개발 검증 전에 선적용되어야 한다.
Run(검증): `select code, "order" from public.vote_type order by "order";`
Expected: picnic/musical/joongang/cgv 4행.

- [ ] **Step 4: Commit (picnic-supabase 레포)**

```bash
cd ~/Repositories/picnic-supabase
git add supabase/migrations/
git commit -m "feat(db): add vote_type table and vote.vote_type_id for vote-type tabs

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 2: `VoteType` 모델 + `asyncVoteTypeListProvider`

**Files:**
- Create: `picnic_lib/lib/data/models/vote/vote_type.dart`
- Create: `picnic_lib/lib/presentation/providers/vote_type_list_provider.dart`
- Test: `picnic_lib/test/presentation/providers/vote_type_list_provider_test.dart`

**Interfaces:**
- Produces: `VoteType({int id, String code, Map<String,dynamic> title, int order})`, `VoteType.fromJson`; `asyncVoteTypeListProvider` → `Future<List<VoteType>>`(order 오름차순, deleted_at null).
- Consumes: 없음(Task 1의 vote_type 테이블).

- [ ] **Step 1: 모델 작성** — `vote_type.dart`

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part '../../../generated/providers/models/vote/vote_type.freezed.dart';
part '../../../generated/providers/models/vote/vote_type.g.dart';

@freezed
abstract class VoteType with _$VoteType {
  const factory VoteType({
    @JsonKey(name: 'id') required int id,
    @JsonKey(name: 'code') required String code,
    @JsonKey(name: 'title') required Map<String, dynamic> title,
    @JsonKey(name: 'order') required int order,
  }) = _VoteType;

  factory VoteType.fromJson(Map<String, dynamic> json) =>
      _$VoteTypeFromJson(json);
}
```

- [ ] **Step 2: provider 작성** — `vote_type_list_provider.dart`

```dart
import 'package:picnic_lib/data/models/vote/vote_type.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '../../generated/providers/vote_type_list_provider.g.dart';

@riverpod
class AsyncVoteTypeList extends _$AsyncVoteTypeList {
  @override
  Future<List<VoteType>> build() async {
    final response = await supabase
        .from('vote_type')
        .select('id, code, title, order')
        .filter('deleted_at', 'is', null)
        .order('order', ascending: true);

    return response.map((e) => VoteType.fromJson(e)).toList();
  }
}
```

- [ ] **Step 3: 코드 생성**

Run: `cd picnic_lib && dart run build_runner build --delete-conflicting-outputs`
Expected: `lib/generated/providers/models/vote/vote_type.freezed.dart`, `vote_type.g.dart`, `lib/generated/providers/vote_type_list_provider.g.dart` 생성. 에러 0.

- [ ] **Step 4: 테스트 작성** — `vote_type_list_provider_test.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/vote/vote_type.dart';
import 'package:picnic_lib/presentation/providers/vote_type_list_provider.dart';

import '../../helpers/mock_supabase.dart';

void main() {
  group('AsyncVoteTypeList', () {
    setUp(() {
      setupMockSupabase({
        'vote_type': [
          {'id': 1, 'code': 'picnic', 'title': {'ko': '피크닉', 'en': 'Picnic'}, 'order': 0},
          {'id': 2, 'code': 'musical', 'title': {'ko': '뮤지컬', 'en': 'Musical'}, 'order': 1},
        ],
      });
    });
    tearDown(() => tearDownMockSupabase());

    test('returns ordered list of VoteType', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final result = await container.read(asyncVoteTypeListProvider.future);

      expect(result, isA<List<VoteType>>());
      expect(result.length, 2);
      expect(result.first.code, 'picnic');
      expect(result.first.title['ko'], '피크닉');
      expect(result[1].order, 1);
    });
  });
}
```

- [ ] **Step 5: 테스트 실행**

Run: `cd picnic_lib && flutter test test/presentation/providers/vote_type_list_provider_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 6: Commit**

```bash
git add picnic_lib/lib/data/models/vote/vote_type.dart picnic_lib/lib/presentation/providers/vote_type_list_provider.dart picnic_lib/lib/generated/providers/models/vote/vote_type.freezed.dart picnic_lib/lib/generated/providers/models/vote/vote_type.g.dart picnic_lib/lib/generated/providers/vote_type_list_provider.g.dart picnic_lib/test/presentation/providers/vote_type_list_provider_test.dart
git commit -m "feat(vote): add VoteType model and vote type list provider"
```

---

## Task 3: `VoteModel.voteTypeId` + `AsyncVoteList` 종류 필터

**Files:**
- Modify: `picnic_lib/lib/data/models/vote/vote.dart` (VoteModel factory)
- Modify: `picnic_lib/lib/presentation/providers/vote_list_provider.dart` (build 시그니처 + _fetchPage)
- Test: `picnic_lib/test/presentation/providers/vote_list_provider_votetype_test.dart`

**Interfaces:**
- Consumes: Task 1 `vote.vote_type_id`.
- Produces: `VoteModel.voteTypeId` (`int?`); `AsyncVoteList.build(..., {int? voteTypeId})` — `voteTypeId!=null`일 때 `.eq('vote_type_id', voteTypeId)`.

- [ ] **Step 1: VoteModel에 필드 추가** — `vote.dart`

`@JsonKey(name: 'area') String? area,` 다음 줄에 아래를 추가(둘 다 optional non-required 유지):

```dart
          @JsonKey(name: 'area') String? area,
          @JsonKey(name: 'vote_type_id') int? voteTypeId,
```

- [ ] **Step 2: provider build 시그니처에 voteTypeId 추가** — `vote_list_provider.dart`

`build(...)`의 named params에 추가:

```dart
    VotePortal votePortal = VotePortal.vote,
    required VoteStatus status,
    required VoteCategory category,
    int? voteTypeId,
```

그리고 `_fetchPage(...)` 호출에 `voteTypeId: voteTypeId,` 전달, `_fetchPage`의 named params에도 `int? voteTypeId,` 추가.

- [ ] **Step 3: select에 vote_type_id 추가 + 필터 + 정규화** — `vote_list_provider.dart`

select 문자열의 `vote_category,` 다음 줄에 `vote_type_id,` 추가:

```dart
            vote_category,
            vote_type_id,
            is_partnership,
```

area 필터(`if (area != 'all') { query = query.contains('areas', [area]); }`) **다음**에 종류 필터 추가:

```dart
      if (voteTypeId != null) {
        query = query.eq('vote_type_id', voteTypeId);
      }
```

정규화 루프의 `map.putIfAbsent('partner', () => null);` 다음에 추가:

```dart
        map.putIfAbsent('vote_type_id', () => null);
```

- [ ] **Step 4: 코드 생성**

Run: `cd picnic_lib && dart run build_runner build --delete-conflicting-outputs`
Expected: `vote.freezed.dart`/`vote.g.dart` 갱신, 에러 0.

- [ ] **Step 5: 테스트 작성** — `vote_list_provider_votetype_test.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';

import '../../helpers/mock_supabase.dart';

Map<String, dynamic> _voteRow(int id, int typeId) => {
      'id': id,
      'title': {'ko': '테스트$id'},
      'main_image': null, 'wait_image': null, 'result_image': null,
      'vote_content': null, 'created_at': '2026-07-01T00:00:00Z',
      'start_at': '2020-01-01T00:00:00Z', 'stop_at': '2999-01-01T00:00:00Z',
      'visible_at': '2020-01-01T00:00:00Z', 'vote_category': null,
      'vote_type_id': typeId, 'is_partnership': null, 'partner': null,
      'reward': <dynamic>[],
      'vote_item': [
        {'id': id * 10, 'vote_id': id, 'vote_total': 5, 'artist': null, 'artist_group': null}
      ],
    };

void main() {
  group('AsyncVoteList vote_type filter', () {
    setUp(() {
      setupMockSupabase({'vote': [_voteRow(1, 2)]});
    });
    tearDown(() => tearDownMockSupabase());

    test('parses vote_type_id into VoteModel', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final result = await container.read(asyncVoteListProvider(
        1, 20, 'id', 'DESC', 'all',
        status: VoteStatus.active,
        category: VoteCategory.all,
        voteTypeId: 2,
      ).future);

      expect(result, isA<List<VoteModel>>());
      expect(result.first.voteTypeId, 2);
    });
  });
}
```

> 참고: `mock_supabase`가 `.eq('vote_type_id', …)` 필터를 서버처럼 재현하지 못할 수 있다. 이 테스트의 목적은 (a) 새 시그니처 컴파일, (b) `vote_type_id` 파싱 확인이다. 필터 SQL 정확성은 마이그레이션 적용 후 수동 검증(Task 16)으로 확인한다.

- [ ] **Step 6: 테스트 실행**

Run: `cd picnic_lib && flutter test test/presentation/providers/vote_list_provider_votetype_test.dart`
Expected: PASS.

- [ ] **Step 7: 기존 vote_list_provider 관련 테스트 회귀 확인**

Run: `cd picnic_lib && flutter test test/presentation/providers/vote_list_provider_test.dart` (존재 시)
Expected: PASS (시그니처 변경은 optional param이라 기존 호출 무영향).

- [ ] **Step 8: Commit**

```bash
git add picnic_lib/lib/data/models/vote/vote.dart picnic_lib/lib/presentation/providers/vote_list_provider.dart picnic_lib/lib/generated/providers/models/vote/vote.freezed.dart picnic_lib/lib/generated/providers/models/vote/vote.g.dart picnic_lib/test/presentation/providers/vote_list_provider_votetype_test.dart
git commit -m "feat(vote): thread vote_type_id through VoteModel and vote list provider"
```

---

## Task 4: `asyncFeaturedVoteProvider` (홈 대표 투표)

**Files:**
- Create: `picnic_lib/lib/presentation/providers/featured_vote_provider.dart`
- Test: `picnic_lib/test/presentation/providers/featured_vote_provider_test.dart`

**Interfaces:**
- Produces: `asyncFeaturedVoteProvider` → `Future<VoteModel?>` — active(`visible_at<now<... `, `start_at<now<stop_at`) 중 `stop_at ASC` 첫 1건, vote_item은 top-1. 없으면 null.
- Consumes: `VoteModel`(Task 3).

- [ ] **Step 1: provider 작성** — `featured_vote_provider.dart`

```dart
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '../../generated/providers/featured_vote_provider.g.dart';

@riverpod
class AsyncFeaturedVote extends _$AsyncFeaturedVote {
  @override
  Future<VoteModel?> build() async {
    try {
      final response = await supabase
          .from('vote')
          .select('''
            id, title, main_image, wait_image, result_image, vote_content,
            created_at, start_at, stop_at, visible_at, vote_category,
            vote_type_id, is_partnership, partner, area, reward(*),
            vote_item!inner(
              id, vote_id, vote_total,
              artist(id, name, image),
              artist_group(id, name, image)
            )
          ''')
          .lt('visible_at', 'now()')
          .lt('start_at', 'now()')
          .gt('stop_at', 'now()')
          .filter('deleted_at', 'is', null)
          .order('vote_total', referencedTable: 'vote_item', ascending: false)
          .limit(1, referencedTable: 'vote_item')
          .order('stop_at', ascending: true)
          .limit(1);

      if (response.isEmpty) return null;

      final map = Map<String, dynamic>.from(response.first);
      map['is_upcoming'] = false;
      map['is_ended'] = false;
      if (map['vote_item'] is List) {
        map['vote_item'] = (map['vote_item'] as List)
            .whereType<Map<String, dynamic>>()
            .map((e) => Map<String, dynamic>.from(e))
            .where((e) => e['deleted_at'] == null)
            .take(1)
            .toList();
      } else {
        map['vote_item'] = <Map<String, dynamic>>[];
      }
      map.putIfAbsent('reward', () => <dynamic>[]);
      map.putIfAbsent('vote_content', () => null);
      map.putIfAbsent('main_image', () => null);
      map.putIfAbsent('wait_image', () => null);
      map.putIfAbsent('result_image', () => null);
      map.putIfAbsent('is_partnership', () => null);
      map.putIfAbsent('partner', () => null);
      map.putIfAbsent('vote_type_id', () => null);

      return VoteModel.fromJson(map);
    } catch (e, s) {
      logger.e('featured vote load error', error: e, stackTrace: s);
      rethrow;
    }
  }
}
```

- [ ] **Step 2: 코드 생성**

Run: `cd picnic_lib && dart run build_runner build --delete-conflicting-outputs`
Expected: `lib/generated/providers/featured_vote_provider.g.dart` 생성, 에러 0.

- [ ] **Step 3: 테스트 작성** — `featured_vote_provider_test.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/presentation/providers/featured_vote_provider.dart';

import '../../helpers/mock_supabase.dart';

void main() {
  group('AsyncFeaturedVote', () {
    test('returns the vote when present', () async {
      setupMockSupabase({
        'vote': [
          {
            'id': 7, 'title': {'ko': '대표투표'},
            'main_image': null, 'wait_image': null, 'result_image': null,
            'vote_content': null, 'created_at': '2026-07-01T00:00:00Z',
            'start_at': '2020-01-01T00:00:00Z', 'stop_at': '2999-01-01T00:00:00Z',
            'visible_at': '2020-01-01T00:00:00Z', 'vote_category': null,
            'vote_type_id': 1, 'is_partnership': null, 'partner': null,
            'reward': <dynamic>[],
            'vote_item': [
              {'id': 70, 'vote_id': 7, 'vote_total': 9, 'artist': null, 'artist_group': null}
            ],
          }
        ],
      });
      addTearDown(tearDownMockSupabase);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final result = await container.read(asyncFeaturedVoteProvider.future);
      expect(result, isNotNull);
      expect(result!.id, 7);
      expect(result.voteItem!.length, 1);
    });

    test('returns null when no active vote', () async {
      setupMockSupabase({'vote': []});
      addTearDown(tearDownMockSupabase);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final result = await container.read(asyncFeaturedVoteProvider.future);
      expect(result, isNull);
    });
  });
}
```

- [ ] **Step 4: 테스트 실행**

Run: `cd picnic_lib && flutter test test/presentation/providers/featured_vote_provider_test.dart`
Expected: PASS (2 tests). (mock이 `.limit`/정렬을 재현 못하면 첫 케이스는 리스트 첫 행을 반환하는지로 충분.)

- [ ] **Step 5: Commit**

```bash
git add picnic_lib/lib/presentation/providers/featured_vote_provider.dart picnic_lib/lib/generated/providers/featured_vote_provider.g.dart picnic_lib/test/presentation/providers/featured_vote_provider_test.dart
git commit -m "feat(home): add featured (soonest-ending active) vote provider"
```

---

## Task 5: `asyncLatestMediaProvider` (홈 미디어 6)

**Files:**
- Create: `picnic_lib/lib/presentation/providers/latest_media_provider.dart`
- Test: `picnic_lib/test/presentation/providers/latest_media_provider_test.dart`

**Interfaces:**
- Produces: `asyncLatestMediaProvider` → `Future<List<VideoInfo>>` — `media` 테이블 `id DESC` 최신 6.
- Consumes: `VideoInfo`(기존 모델).

- [ ] **Step 1: provider 작성** — `latest_media_provider.dart`

썸네일/채널 파생은 `vote_media_list_page.dart`의 `_fetch`와 동일한 규칙을 사용한다(YouTube 썸네일 URL 패턴).

```dart
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/data/models/vote/video_info.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '../../generated/providers/latest_media_provider.g.dart';

@riverpod
class AsyncLatestMedia extends _$AsyncLatestMedia {
  static const int _limit = 6;

  @override
  Future<List<VideoInfo>> build() async {
    try {
      final response = await supabase
          .from('media')
          .select()
          .filter('deleted_at', 'is', null)
          .order('id', ascending: false)
          .limit(_limit);

      return response.map((data) {
        final videoId = data['video_id']?.toString() ?? '';
        return VideoInfo(
          id: data['id'] as int,
          videoId: videoId,
          videoUrl: data['video_url']?.toString() ?? '',
          title: Map<String, String>.from(data['title'] as Map),
          thumbnailUrl: 'https://img.youtube.com/vi/$videoId/maxresdefault.jpg',
          createdAt: data['created_at'] != null
              ? DateTime.parse(data['created_at'].toString())
              : null,
          channelTitle: '',
          channelId: '',
          channelThumbnail: '',
        );
      }).toList();
    } catch (e, s) {
      logger.e('latest media load error', error: e, stackTrace: s);
      rethrow;
    }
  }
}
```

- [ ] **Step 2: 코드 생성**

Run: `cd picnic_lib && dart run build_runner build --delete-conflicting-outputs`
Expected: `lib/generated/providers/latest_media_provider.g.dart` 생성, 에러 0.

- [ ] **Step 3: 테스트 작성** — `latest_media_provider_test.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/vote/video_info.dart';
import 'package:picnic_lib/presentation/providers/latest_media_provider.dart';

import '../../helpers/mock_supabase.dart';

void main() {
  group('AsyncLatestMedia', () {
    setUp(() {
      setupMockSupabase({
        'media': [
          {'id': 2, 'video_id': 'abc', 'video_url': 'u', 'title': {'ko': 'v2'}, 'created_at': '2026-07-02T00:00:00Z'},
          {'id': 1, 'video_id': 'def', 'video_url': 'u', 'title': {'ko': 'v1'}, 'created_at': '2026-07-01T00:00:00Z'},
        ],
      });
    });
    tearDown(() => tearDownMockSupabase());

    test('maps media rows to VideoInfo with derived thumbnail', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final result = await container.read(asyncLatestMediaProvider.future);
      expect(result, isA<List<VideoInfo>>());
      expect(result.length, 2);
      expect(result.first.thumbnailUrl, contains('img.youtube.com/vi/'));
    });
  });
}
```

- [ ] **Step 4: 테스트 실행**

Run: `cd picnic_lib && flutter test test/presentation/providers/latest_media_provider_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add picnic_lib/lib/presentation/providers/latest_media_provider.dart picnic_lib/lib/generated/providers/latest_media_provider.g.dart picnic_lib/test/presentation/providers/latest_media_provider_test.dart
git commit -m "feat(home): add latest-6 media provider"
```

---

## Task 6: `VoteList`에 `voteTypeId` 스레딩

**Files:**
- Modify: `picnic_lib/lib/presentation/widgets/vote/list/vote_list.dart`

**Interfaces:**
- Consumes: `AsyncVoteList`의 `voteTypeId`(Task 3).
- Produces: `VoteList(status, category, area, {portal, int? voteTypeId})` — provider 호출 2곳에 `voteTypeId` 전달.

- [ ] **Step 1: 생성자에 필드 추가** — `vote_list.dart`

`final VotePortal portal;` 다음에 `final int? voteTypeId;` 추가하고, 생성자 named params에 `this.voteTypeId,` 추가:

```dart
  final VotePortal portal;
  final int? voteTypeId;

  const VoteList(
    this.status,
    this.category,
    this.area, {
    super.key,
    this.portal = VotePortal.vote,
    this.voteTypeId,
  });
```

- [ ] **Step 2: 두 provider 호출에 voteTypeId 전달** — `vote_list.dart`

`asyncVoteListProvider(...)` 두 호출 모두 `votePortal: widget.portal,` 다음에 `voteTypeId: widget.voteTypeId,` 추가.

- [ ] **Step 3: 분석**

Run: `cd picnic_lib && flutter analyze lib/presentation/widgets/vote/list/vote_list.dart`
Expected: No issues (또는 기존과 동일 수준).

- [ ] **Step 4: Commit**

```bash
git add picnic_lib/lib/presentation/widgets/vote/list/vote_list.dart
git commit -m "feat(vote): pass voteTypeId from VoteList to provider"
```

---

## Task 7: 투표 페이지 재구성 — 종류 탭 + 상태 드롭다운

**Files:**
- Modify: `picnic_lib/lib/presentation/pages/vote/vote_list_page.dart` (전체 `VoteListContent` 재작성 + `_updateNavigation` showTopMenu:false)
- Test: `picnic_lib/test/presentation/pages/vote/vote_list_page_votetype_test.dart`

**Interfaces:**
- Consumes: `asyncVoteTypeListProvider`(Task 2), `VoteList.voteTypeId`(Task 6), 기존 `label_tabbar_vote_active/end/upcoming`, `label_vote_screen_title`.
- Produces: 종류 탭(스와이프+가로스크롤) + 상태 드롭다운(기본 active, 미저장) UI.

- [ ] **Step 1: `_updateNavigation`에서 흰색 스트립 제거**

`vote_list_page.dart`의 `_VoteListPageState._updateNavigation`(및 `VoteListContent`가 별도 설정 시 동일)에서 `showTopMenu: true,` → `showTopMenu: false,` 로 변경. (타이틀은 페이지 본문에서 렌더.)

- [ ] **Step 2: `VoteListContent` 재작성** — 상태 드롭다운 + 종류 탭

`_VoteListContentState`를 아래로 교체. 핵심: 상태는 로컬 `VoteStatus _status = VoteStatus.active`(미저장), 종류 탭은 `asyncVoteTypeListProvider`로 `TabController` 동적 생성, `TabBarView` 스와이프 허용.

```dart
class _VoteListContentState extends ConsumerState<VoteListContent> {
  VoteStatus _status = VoteStatus.active; // 기본값 진행중, 미저장

  @override
  Widget build(BuildContext context) {
    final typesAsync = ref.watch(asyncVoteTypeListProvider);

    return typesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => buildErrorView(context, error: e.toString(), stackTrace: s),
      data: (types) {
        if (types.isEmpty) {
          return VoteNoItem(status: _status, context: context);
        }
        return _VoteTypeTabs(
          types: types,
          status: _status,
          isAdmin: widget.isAdmin,
          onStatusChanged: (s) => setState(() => _status = s),
        );
      },
    );
  }
}
```

새 위젯 `_VoteTypeTabs`(같은 파일 하단)로 `TabController`를 `types.length` 기반으로 만든다:

```dart
class _VoteTypeTabs extends ConsumerStatefulWidget {
  final List<VoteType> types;
  final VoteStatus status;
  final bool isAdmin;
  final ValueChanged<VoteStatus> onStatusChanged;
  const _VoteTypeTabs({
    required this.types,
    required this.status,
    required this.isAdmin,
    required this.onStatusChanged,
  });
  @override
  ConsumerState<_VoteTypeTabs> createState() => _VoteTypeTabsState();
}

class _VoteTypeTabsState extends ConsumerState<_VoteTypeTabs>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: widget.types.length, vsync: this);
  }

  @override
  void didUpdateWidget(covariant _VoteTypeTabs old) {
    super.didUpdateWidget(old);
    if (old.types.length != widget.types.length) {
      _tabController.dispose();
      _tabController = TabController(length: widget.types.length, vsync: this);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 페이지 타이틀 (흰색 스트립 제거로 본문에서 렌더)
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8),
          alignment: Alignment.centerLeft,
          child: Text(
            AppLocalizations.of(context).label_vote_screen_title,
            style: getTextStyle(AppTypo.title18B, AppColors.grey900),
          ),
        ),
        // 종류 탭 (가로 스크롤)
        SizedBox(
          height: 48,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorWeight: 3,
            tabs: widget.types
                .map((t) => Tab(text: getLocaleTextFromJson(t.title)))
                .toList(),
          ),
        ),
        // 상태 필터 드롭다운
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8),
          child: Align(
            alignment: Alignment.centerRight,
            child: DropdownButton<VoteStatus>(
              value: widget.status,
              onChanged: (v) {
                if (v != null) widget.onStatusChanged(v);
              },
              items: [
                DropdownMenuItem(
                  value: VoteStatus.active,
                  child: Text(AppLocalizations.of(context).label_tabbar_vote_active),
                ),
                DropdownMenuItem(
                  value: VoteStatus.end,
                  child: Text(AppLocalizations.of(context).label_tabbar_vote_end),
                ),
                DropdownMenuItem(
                  value: VoteStatus.upcoming,
                  child: Text(AppLocalizations.of(context).label_tabbar_vote_upcoming),
                ),
                if (widget.isAdmin)
                  const DropdownMenuItem(
                    value: VoteStatus.debug,
                    child: Text('(Admin)'),
                  ),
              ],
            ),
          ),
        ),
        // 리스트 (종류별 스와이프)
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: widget.types
                .map((t) => VoteList(
                      widget.status,
                      VoteCategory.all,
                      'all',
                      portal: VotePortal.vote,
                      voteTypeId: t.id,
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}
```

필요한 import 추가: `vote_type.dart`, `vote_type_list_provider.dart`, `l10n.dart`(`getLocaleTextFromJson`), `ui/style.dart`, `flutter_screenutil`, `error.dart`(buildErrorView), `vote_no_item.dart`. 기존 `PageStorage`/`_tabIndexKey`/디버그 로그/`logger` 관련 코드는 삭제(상태 미저장 정책).

- [ ] **Step 3: `_VoteListPageState`의 area 의존 Key 정리**

`build`에서 `area` 기반 `ValueKey('vote_list_${area}_$_isAdmin')`는 유지하되 `area`는 이제 리스트 필터에 영향 없음. `_isAdmin`만으로 재생성하도록 `ValueKey('vote_list_$_isAdmin')`로 단순화. `appSettingProvider`/`area` 참조 제거(미사용 import 정리).

- [ ] **Step 4: 분석**

Run: `cd picnic_lib && flutter analyze lib/presentation/pages/vote/vote_list_page.dart`
Expected: No issues.

- [ ] **Step 5: 위젯 테스트 작성** — `vote_list_page_votetype_test.dart`

종류 탭이 렌더되고 상태 드롭다운 기본값이 진행중인지 확인.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/pages/vote/vote_list_page.dart';

import '../../../helpers/mock_supabase.dart';
import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

void main() {
  setUp(() {
    initTestColors();
    setupMockSupabase({
      'vote_type': [
        {'id': 1, 'code': 'picnic', 'title': {'ko': '피크닉', 'en': 'Picnic'}, 'order': 0},
        {'id': 2, 'code': 'musical', 'title': {'ko': '뮤지컬', 'en': 'Musical'}, 'order': 1},
      ],
      'vote': [],
    });
  });
  tearDown(() => tearDownMockSupabase());

  testWidgets('renders vote type tabs and defaults status to active', (tester) async {
    await tester.pumpWidget(buildTestApp(const VoteListContent(isAdmin: false)));
    await tester.pumpAndSettle();

    // 종류 탭 라벨 노출
    expect(find.text('피크닉'), findsWidgets);
    expect(find.text('뮤지컬'), findsWidgets);
    // 상태 드롭다운 기본값 = 진행중
    final active = AppLocalizations.of(tester.element(find.byType(VoteListContent)))
        .label_tabbar_vote_active;
    expect(find.text(active), findsWidgets);
  });
}
```

- [ ] **Step 6: 테스트 실행**

Run: `cd picnic_lib && flutter test test/presentation/pages/vote/vote_list_page_votetype_test.dart`
Expected: PASS. (실패 시 mock 데이터/로케일 wrapper 확인.)

- [ ] **Step 7: Commit**

```bash
git add picnic_lib/lib/presentation/pages/vote/vote_list_page.dart picnic_lib/test/presentation/pages/vote/vote_list_page_votetype_test.dart
git commit -m "feat(vote): rebuild vote page with vote-type tabs and status dropdown"
```

---

## Task 8: `RewardListSection` 위젯 추출

**Files:**
- Create: `picnic_lib/lib/presentation/widgets/vote/reward_list_section.dart`

**Interfaces:**
- Produces: `RewardListSection()` — `vote_home_page.dart` `_buildRewardList`(L302-432)와 동일한 가로 리워드 리스트를 독립 위젯으로.

- [ ] **Step 1: 위젯 작성** — `reward_list_section.dart`

`vote_home_page.dart`의 `_buildRewardList` 본문을 그대로 `ConsumerWidget.build`로 옮긴다(참조: 리워드 리스트는 `asyncRewardListProvider` watch → `Column[제목, 가로 ListView.builder(height 100, item 120x100), showRewardDialog 탭]`). import: `reward_list_provider.dart`, `reward.dart`, `common/picnic_cached_network_image.dart`, `dialogs/reward_dialog.dart`, `widgets/error.dart`, `l10n.dart`, `l10n/app_localizations.dart`, `ui/style.dart`, `flutter_screenutil`, `shimmer`.

```dart
class RewardListSection extends ConsumerWidget {
  const RewardListSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncRewardListState = ref.watch(asyncRewardListProvider);
    // ↓ vote_home_page.dart:302-432 _buildRewardList 의 Column(...) 반환부를 그대로 이식
    //   (제목 label_vote_reward_list + 가로 ListView.builder + loading Shimmer + error)
    return Column( /* 동일 구현 */ );
  }
}
```

> 실행 시 `vote_home_page.dart` L302-432를 열어 `Column(...)` 전체를 복사·이식한다. `_rewardListKey`(UniqueKey)는 위젯 내부 `final Key _key = UniqueKey();` 또는 생략(홈 새로고침 시 `ref.invalidate`로 갱신).

- [ ] **Step 2: 분석**

Run: `cd picnic_lib && flutter analyze lib/presentation/widgets/vote/reward_list_section.dart`
Expected: No issues.

- [ ] **Step 3: Commit**

```bash
git add picnic_lib/lib/presentation/widgets/vote/reward_list_section.dart
git commit -m "refactor(home): extract RewardListSection for reuse on home"
```

---

## Task 9: `HomeFeaturedVoteCard` (홈 전용 rank-1 카드)

**Files:**
- Create: `picnic_lib/lib/presentation/widgets/vote/home_featured_vote_card.dart`

**Interfaces:**
- Consumes: `VoteModel`(Task 3), `CountdownTimer`(endTime/status/onRefresh), `ShareSection`(onSave/onShare), `VoteStatus`.
- Produces: `HomeFeaturedVoteCard({required VoteModel vote})` — 제목 + rank-1 항목 + 남은시간 + 저장/공유. 낮은 높이.

- [ ] **Step 1: 카드 작성** — `home_featured_vote_card.dart`

구조: `RepaintBoundary(key: _globalKey)`로 감싼 카드 본문 = [제목 Text, rank-1 아티스트 이미지+이름+표수, `CountdownTimer(endTime: vote.stopAt!, status: VoteStatus.active)`], 그 아래 `ShareSection(onSave: _handleSave, onShare: _handleShare)`. 저장/공유 핸들러는 **기존 `vote_info_card.dart`의 `_handleSaveImage`(L132-144)·`_handleShareToTwitter`(L146-168)와 동일한 `ShareUtils` 호출 패턴**을 사용한다(실행 시 해당 파일을 열어 `ShareUtils.saveImage`/`ShareUtils.shareToSocial` 시그니처를 그대로 mirror; RepaintBoundary GlobalKey 캡처 방식 동일).

```dart
class HomeFeaturedVoteCard extends ConsumerStatefulWidget {
  final VoteModel vote;
  const HomeFeaturedVoteCard({super.key, required this.vote});
  @override
  ConsumerState<HomeFeaturedVoteCard> createState() => _HomeFeaturedVoteCardState();
}

class _HomeFeaturedVoteCardState extends ConsumerState<HomeFeaturedVoteCard> {
  final GlobalKey _globalKey = GlobalKey();
  final GlobalKey _shareKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final vote = widget.vote;
    final topItem = (vote.voteItem?.isNotEmpty ?? false) ? vote.voteItem!.first : null;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.grey00,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RepaintBoundary(
            key: _globalKey,
            child: Column(
              children: [
                Text(
                  getLocaleTextFromJson(vote.title),
                  style: getTextStyle(AppTypo.title18B, AppColors.grey900),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                if (vote.stopAt != null)
                  CountdownTimer(endTime: vote.stopAt!, status: VoteStatus.active),
                const SizedBox(height: 12),
                // rank-1 항목: 낮은 높이 이미지 + 이름 + 표수
                if (topItem != null) _buildTopItem(topItem),
              ],
            ),
          ),
          ShareSection(onSave: _handleSave, onShare: _handleShare),
        ],
      ),
    );
  }

  Widget _buildTopItem(VoteItemModel item) {
    final name = item.artist?.name != null
        ? getLocaleTextFromJson(item.artist!.name)
        : (item.artistGroup?.name != null
            ? getLocaleTextFromJson(item.artistGroup!.name)
            : '');
    final imageUrl = item.artist?.image ?? item.artistGroup?.image ?? '';
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8.r),
          child: PicnicCachedNetworkImage(
            imageUrl: imageUrl, width: 64, height: 64, fit: BoxFit.cover,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Text(name,
              style: getTextStyle(AppTypo.body16B, AppColors.grey900),
              maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        Text('${item.voteTotal ?? 0}',
            style: getTextStyle(AppTypo.body16B, AppColors.primary500)),
      ],
    );
  }

  void _handleSave() {/* mirror vote_info_card.dart:132-144 (ShareUtils.saveImage) */}
  void _handleShare() {/* mirror vote_info_card.dart:146-168 (ShareUtils.shareToSocial) */}
}
```

> 실행 시 `getLocaleTextFromJson`(l10n.dart), `PicnicCachedNetworkImage`, `ShareUtils` import를 채우고, `ArtistModel.name`/`image` 실제 필드명을 `artist.dart`에서 확인해 맞춘다.

- [ ] **Step 2: 분석**

Run: `cd picnic_lib && flutter analyze lib/presentation/widgets/vote/home_featured_vote_card.dart`
Expected: No issues.

- [ ] **Step 3: 위젯 스모크 테스트** — `test/presentation/widgets/vote/home_featured_vote_card_test.dart`

`buildTestApp`로 mock VoteModel(항목 1개) 넣고 제목/표수 렌더 확인. `initTestColors()` 선행.

- [ ] **Step 4: 테스트 실행**

Run: `cd picnic_lib && flutter test test/presentation/widgets/vote/home_featured_vote_card_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add picnic_lib/lib/presentation/widgets/vote/home_featured_vote_card.dart picnic_lib/test/presentation/widgets/vote/home_featured_vote_card_test.dart
git commit -m "feat(home): add home-only rank-1 featured vote card"
```

---

## Task 10: `LatestMediaSection` (홈 미디어 가로 캐러셀)

**Files:**
- Create: `picnic_lib/lib/presentation/widgets/vote/latest_media_section.dart`

**Interfaces:**
- Consumes: `asyncLatestMediaProvider`(Task 5), `VideoInfo`, `nav_media` 라벨.
- Produces: `LatestMediaSection()` — 리워드 리스트와 동일 규격(height 100, item 120x100) 가로 캐러셀. 탭 시 유튜브 오픈.

- [ ] **Step 1: 위젯 작성** — `latest_media_section.dart`

`RewardListSection`과 동일한 레이아웃 규격을 따르되 데이터는 `asyncLatestMediaProvider`, 썸네일은 `VideoInfo.thumbnailUrl`, 제목은 `getLocaleTextFromJson(item.title)`. 탭 시 `vote_media_list_page.dart`의 `_launchVideoUrl` 패턴(youtube URL 실행)을 사용(`url_launcher`). 섹션 제목은 `AppLocalizations.of(context).nav_media`(기존 키 재사용).

```dart
class LatestMediaSection extends ConsumerWidget {
  const LatestMediaSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mediaAsync = ref.watch(asyncLatestMediaProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 16.w),
          child: Text(AppLocalizations.of(context).nav_media,
              style: getTextStyle(AppTypo.title18B, AppColors.grey900)),
        ),
        const SizedBox(height: 16),
        mediaAsync.when(
          loading: () => const SizedBox(height: 100),
          error: (e, s) => const SizedBox.shrink(),
          data: (items) => SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.only(left: 16.w),
              itemCount: items.length,
              itemBuilder: (context, i) {
                final item = items[i];
                return GestureDetector(
                  onTap: () => _launch(item),
                  child: Container(
                    width: 120, height: 100,
                    margin: const EdgeInsets.only(right: 16),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: PicnicCachedNetworkImage(
                        imageUrl: item.thumbnailUrl, width: 120, height: 100, fit: BoxFit.cover,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _launch(VideoInfo item) async {
    // mirror vote_media_list_page.dart _launchVideoUrl (vnd.youtube:// or item.videoUrl)
  }
}
```

- [ ] **Step 2: 분석**

Run: `cd picnic_lib && flutter analyze lib/presentation/widgets/vote/latest_media_section.dart`
Expected: No issues.

- [ ] **Step 3: Commit**

```bash
git add picnic_lib/lib/presentation/widgets/vote/latest_media_section.dart
git commit -m "feat(home): add latest-6 media horizontal carousel section"
```

---

## Task 11: `HomePage` 조립 + l10n 키

**Files:**
- Create: `picnic_lib/lib/presentation/pages/vote/home_page.dart`
- Modify: `picnic_lib/lib/l10n/app_en.arb`, `picnic_lib/lib/l10n/app_ko.arb`
- Test: `picnic_lib/test/presentation/pages/vote/home_page_test.dart`

**Interfaces:**
- Consumes: `CommonBanner`, `asyncFeaturedVoteProvider`(Task 4), `HomeFeaturedVoteCard`(Task 9), `RewardListSection`(Task 8), `LatestMediaSection`(Task 10).
- Produces: `HomePage()` — 홈 탭(index 0) 위젯. `settingNavigation(showTopMenu:false)`로 흰색 스트립 제거.

- [ ] **Step 1: l10n 키 추가** — `app_en.arb`(템플릿) + `app_ko.arb`

`app_en.arb`에 추가: `"label_home_current_vote": "Current Vote",`
`app_ko.arb`에 추가: `"label_home_current_vote": "현재 진행중인 투표",`
(미디어 섹션 제목은 기존 `nav_media` 재사용, 리워드는 `label_vote_reward_list` 재사용.)

- [ ] **Step 2: l10n 재생성**

Run: `cd picnic_lib && flutter gen-l10n`
Expected: `lib/l10n/app_localizations*.dart`에 `label_home_current_vote` getter 추가.

- [ ] **Step 3: HomePage 작성** — `home_page.dart`

`VoteHomePage`의 nav 등록/새로고침 패턴을 따르되 `showTopMenu:false`, 본문은 배너→대표투표→리워드→미디어6. `RouteAwareStateMixin` 사용.

```dart
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});
  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
    with RouteAwareStateMixin<HomePage> {
  Key _bannerKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateNavigation());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateNavigation();
  }

  @override
  void onRoutePopNext() {
    super.onRoutePopNext();
    _updateNavigation();
  }

  void _updateNavigation() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(navigationInfoProvider.notifier).settingNavigation(
            showPortal: true,
            showTopMenu: false, // 흰색 스트립(별사탕/area/타이틀) 제거
            showBottomNavigation: true,
            pageTitle: '',
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final featured = ref.watch(asyncFeaturedVoteProvider);
    return RefreshIndicator(
      color: AppColors.primary500,
      backgroundColor: Colors.white,
      onRefresh: () async {
        ref.invalidate(asyncBannerListProvider(location: 'vote_home'));
        ref.invalidate(asyncRewardListProvider);
        ref.invalidate(asyncFeaturedVoteProvider);
        ref.invalidate(asyncLatestMediaProvider);
        setState(() => _bannerKey = UniqueKey());
      },
      child: ListView(
        children: [
          CommonBanner('vote_home', 786 / 400, key: _bannerKey),
          const SizedBox(height: 24),
          Padding(
            padding: EdgeInsets.only(left: 16.w, bottom: 8),
            child: Text(AppLocalizations.of(context).label_home_current_vote,
                style: getTextStyle(AppTypo.title18B, AppColors.grey900)),
          ),
          featured.when(
            loading: () => const VoteCardSkeleton(status: VoteCardStatus.ongoing),
            error: (e, s) => const SizedBox.shrink(),
            data: (vote) => vote == null
                ? const SizedBox.shrink()
                : HomeFeaturedVoteCard(vote: vote),
          ),
          const SizedBox(height: 36),
          const RewardListSection(),
          const SizedBox(height: 36),
          const LatestMediaSection(),
          const SizedBox(height: 36),
        ],
      ),
    );
  }
}
```

import: `common_banner.dart`, `featured_vote_provider.dart`, `home_featured_vote_card.dart`, `reward_list_section.dart`, `latest_media_section.dart`, `banner_list_provider.dart`, `reward_list_provider.dart`, `latest_media_provider.dart`, `navigation_provider.dart`, `route_aware_mixin.dart`, `vote_card_skeleton.dart`, `l10n/app_localizations.dart`, `ui/style.dart`, `flutter_screenutil`, `enums.dart`.

- [ ] **Step 4: 분석**

Run: `cd picnic_lib && flutter analyze lib/presentation/pages/vote/home_page.dart`
Expected: No issues.

- [ ] **Step 5: 위젯 테스트** — `home_page_test.dart`

`buildTestApp(const HomePage())` + `setupMockSupabase({'banner':[], 'reward':[], 'vote':[], 'media':[]})` → 크래시 없이 렌더(빈 상태). `initTestColors()` 선행.

- [ ] **Step 6: 테스트 실행**

Run: `cd picnic_lib && flutter test test/presentation/pages/vote/home_page_test.dart`
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add picnic_lib/lib/presentation/pages/vote/home_page.dart picnic_lib/lib/l10n/app_en.arb picnic_lib/lib/l10n/app_ko.arb picnic_lib/lib/l10n/app_localizations*.dart picnic_lib/test/presentation/pages/vote/home_page_test.dart
git commit -m "feat(home): assemble HomePage (banner, featured vote, rewards, latest media)"
```

---

## Task 12: 하단 탭바 재구성 (홈 추가 / 커뮤니티 제거)

**Files:**
- Modify: `picnic_lib/lib/data/models/navigator/navigation_configs.dart`
- Modify: `picnic_app/lib/bottom_navigation_menu.dart`

**Interfaces:**
- Consumes: `HomePage`(Task 11), `VoteListPage`(Task 7).
- Produces: vote 포탈 탭 = 홈(0,HomePage)/투표(1,VoteListPage)/미디어(2)/상점(3).

- [ ] **Step 1: `navigation_configs.dart` vote 포탈 pages 교체**

L21-50의 `pages: const [...]`를 아래로 교체. import: `home_page.dart`, `vote_list_page.dart` 추가; `community_home_page.dart` import는 이 파일에서 vote 포탈 용도로는 제거하되 PortalType.community 정의(L92-124)에서 여전히 사용하므로 **import 자체는 유지**.

```dart
      pages: const [
        BottomNavigationItem(
          title: 'nav_home',
          assetPath: 'assets/icons/bottom/home.svg',
          index: 0,
          pageWidget: HomePage(),
          needLogin: false,
        ),
        BottomNavigationItem(
          title: 'nav_vote',
          assetPath: 'assets/icons/bottom/vote.svg',
          index: 1,
          pageWidget: VoteListPage(),
          needLogin: false,
        ),
        BottomNavigationItem(
          title: 'nav_media',
          assetPath: 'assets/icons/bottom/media.svg',
          index: 2,
          pageWidget: VoteMediaListPage(),
          needLogin: false,
        ),
        BottomNavigationItem(
          title: 'nav_store',
          assetPath: 'assets/icons/bottom/store.svg',
          index: 3,
          pageWidget: StorePage(),
          needLogin: false,
        ),
      ],
```

- [ ] **Step 2: `bottom_navigation_menu.dart` votePages 동기화**

L47-76 `votePages`를 위와 동일한 4개(홈/투표/미디어/상점)로 교체(vestigial이지만 `pages.length`=4 유지 + 정합). import 정리: `home_page.dart`, `vote_list_page.dart` 추가, `pic_chart_page.dart`가 다른 곳에서 안 쓰이면 제거.

- [ ] **Step 3: 저장된 탭 인덱스 기본 진입 홈(0) 확인**

`navigation.dart:91`의 초기/저장 인덱스 로직 확인: 저장값이 범위를 벗어나면 0으로 폴백해야 한다. 현재 `getPageWidget(vote, savedIndex)`가 null이면 안전 폴백하는지 점검. 구 저장값(예전 0=vote)이 그대로 0(이제 홈)으로 매핑되어 문제 없음. 별도 코드 변경 불필요면 스킵, 필요 시 로드 시 `index.clamp(0, pages.length-1)` 적용.

- [ ] **Step 4: 분석**

Run: `cd picnic_lib && flutter analyze lib/data/models/navigator/navigation_configs.dart` 및 `cd picnic_app && flutter analyze lib/bottom_navigation_menu.dart`
Expected: No issues (미사용 import 경고 0).

- [ ] **Step 5: Commit**

```bash
git add picnic_lib/lib/data/models/navigator/navigation_configs.dart picnic_app/lib/bottom_navigation_menu.dart
git commit -m "feat(nav): replace community tab with home tab in vote portal"
```

---

## Task 13: 상단 헤더 정리 (Vote/GoongHap 버튼 + 출석체크 제거)

**Files:**
- Modify: `picnic_app/lib/presentation/screens/portal.dart`

**Interfaces:**
- Produces: 상단 AppBar에서 Vote/GoongHap 포탈 버튼·출석체크 제거. 프로필(leading)·알림(TopRightNotifications)·민트 AppBar 유지. 관리자용 PIC/novel 스위처 블록은 유지.

- [ ] **Step 1: AppBar title에서 Vote/GoongHap PortalMenuItem 제거**

L107-108 두 줄 삭제:

```dart
                    const PortalMenuItem(portalType: PortalType.vote),
                    const PortalMenuItem(portalType: PortalType.goongHap),
```

(L109-122 admin PIC/novel 블록은 그대로 유지.)

- [ ] **Step 2: actions에서 출석체크 제거**

L127-136 actions Row를 알림만 남기도록 수정:

```dart
            actions: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  TopRightNotifications(),
                ],
              ),
            ],
```

`AttendanceIconButton` import(L12)가 이 파일에서 더 안 쓰이면 제거.

- [ ] **Step 3: 분석**

Run: `cd picnic_app && flutter analyze lib/presentation/screens/portal.dart`
Expected: No issues (미사용 import 0).

- [ ] **Step 4: Commit**

```bash
git add picnic_app/lib/presentation/screens/portal.dart
git commit -m "feat(header): remove vote/goonghap portal buttons and attendance from top bar"
```

---

## Task 14: 통합 분석 + 회귀 + 수동 스모크

**Files:** (없음 — 검증 단계)

- [ ] **Step 1: 전체 정적 분석**

Run: `cd picnic_lib && flutter analyze` 그리고 `cd picnic_app && flutter analyze`
Expected: 신규/수정 파일에서 error 0. (레포 기존 경고 baseline은 무시하되 새로 생긴 error/warning은 해결.)

- [ ] **Step 2: 변경 관련 테스트 일괄 실행**

Run:
```bash
cd picnic_lib && flutter test \
  test/presentation/providers/vote_type_list_provider_test.dart \
  test/presentation/providers/vote_list_provider_votetype_test.dart \
  test/presentation/providers/featured_vote_provider_test.dart \
  test/presentation/providers/latest_media_provider_test.dart \
  test/presentation/pages/vote/vote_list_page_votetype_test.dart \
  test/presentation/widgets/vote/home_featured_vote_card_test.dart \
  test/presentation/pages/vote/home_page_test.dart
```
Expected: 전부 PASS.

- [ ] **Step 3: 마이그레이션 선적용 상태에서 수동 실행 (실기기/에뮬)**

전제: Task 1 마이그레이션이 공유 인스턴스에 적용됨.
Run: `cd picnic_app && flutter run --dart-define=DISABLE_VM_CHECK=true`
확인 체크리스트:
- 하단탭이 홈/투표/미디어/상점 4개로 표시(커뮤니티 없음).
- 상단: 프로필·알림만. Vote/GoongHap 버튼·출석체크·별사탕·ALL/K-POP 드롭다운 없음(흰색 스트립 사라짐).
- 홈: 배너 → "현재 진행중인 투표"(rank-1, 남은시간/저장/공유) → 리워드 가로 → 미디어 최신6 가로.
- 투표 탭: 종류 탭(가로 스크롤·스와이프 전환) + 상태 드롭다운(기본 진행중). 다른 탭 갔다 재진입 시 다시 진행중.
- 미디어/상점 탭 정상.

- [ ] **Step 4: (선택) 홈/투표 화면 스크린샷 확보 후 이상 없으면 마무리**

---

## Self-Review Notes (작성자 확인)

- 커뮤니티 탭 제거는 `navigation_configs.dart`의 vote 포탈에서만. `PortalType.community` 포탈/화면은 보존(Global Constraint 준수).
- `VoteInfoCard` 미변경. 홈은 `HomeFeaturedVoteCard`.
- 상태 필터 미저장: `VoteListContent`에서 `PageStorage`/`_tabIndexKey` 제거, 로컬 `_status` 기본 active.
- `area` 필터는 투표 페이지에서 `'all'` 전달로 무력화, 파티션은 `voteTypeId`.
- 크로스 레포: Task 1(picnic-supabase)은 앱 수동 검증(Task 14 Step 3) 전에 적용 필수.
- 오픈 이슈(홈 카드 최종 비율, 종류 탭 UX 세부)는 기능 구현 후 비주얼 후속으로 남김.

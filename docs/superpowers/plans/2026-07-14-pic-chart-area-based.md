# PIC CHART area 기반 전환 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** PIC CHART 탭을 `vote_category` 카테고리 sentinel에서 다른 탭과 동일한 `areas @> ['pic-chart']` (array-contains) 필터로 전환한다.

**Architecture:** `vote.areas`(text[])가 탭 필터의 소스. image 투표를 `areas=['pic-chart']`로 마이그레이션하고, 앱·웹의 pic-chart 전용 카테고리 sentinel 코드를 제거해 일반 area 탭 경로로 통일. admin에 pic-chart/spotlight area 옵션을 추가해 향후 큐레이션을 가능케 한다.

**Tech Stack:** Supabase Postgres(트리거 `sync_vote_area_arrays`가 `area`=`areas[1]` 파생), Flutter/Riverpod(picnic_lib), Next.js/supabase-js(picnic-web), Refine/AntD(picnic-admin).

## Global Constraints

- 탭 필터 규약: `areas @> ['<area>']` (supabase-js `.contains('areas',[area])`). `area`(단일 text)는 트리거가 자동 파생 — **직접 쓰지 말 것**.
- 마이그레이션은 `areas`만 UPDATE(트리거가 `area` 동기화). 멱등(`NOT (areas @> ARRAY['pic-chart'])`).
- 프로덕션 DB 쓰기는 `guard_admin_only_write` 대상 — MCP(postgres 역할)로 실행(승인 후).
- 각 배포 단계 non-breaking. 순서: DB → web → app → admin(순서 무관).
- weekly(vote_category=weekly, areas=['kpop'])는 **손대지 않음** → PICNIC 유지.
- 프로젝트별 브랜치 = `feat/pic-chart-area-based`(kebab, Conventional Commits). 메인 폴더 아닌 worktree에서 작업.

---

### Task 0: 워크스페이스 / git 정리

**배경:** picnic-app 메인 체크아웃에 미커밋 변경 6개가 있다 — (a) goBack 상단메뉴 버그 fix 3파일(`navigation_provider.dart`, `navigation_provider_test.dart`, `navigation_test.dart`), (b) 앞서 넣은 weekly 카테고리 재분류 3파일(`vote_home_helper.dart`, `vote_list.dart`, `vote_home_helper_test.dart`). (b)는 본 작업의 area 방식이 대체하므로 폐기한다. (a)는 독립 버그 fix라 보존한다.

**Files:** (git 조작만; 코드 변경 없음). 메인 체크아웃의 미커밋 = goBack 3파일(보존) + weekly 3파일(폐기) + spec/plan 2 docs(untracked, 보존).

- [ ] **Step 1: goBack fix를 patch로 캡처(worktree 간 안전)**

```bash
cd ~/Repositories/picnic-app
git diff -- \
  picnic_lib/lib/presentation/providers/navigation_provider.dart \
  picnic_lib/test/presentation/providers/navigation_provider_test.dart \
  picnic_lib/test/data/models/navigation_test.dart \
  > /tmp/goback-fix.patch
test -s /tmp/goback-fix.patch && echo "patch OK"   # 비어있지 않아야 함
```

- [ ] **Step 2: 메인 tracked 변경 폐기(weekly+goBack 되돌림; docs는 untracked라 유지)**

```bash
cd ~/Repositories/picnic-app
git checkout -- picnic_lib/
git status -s    # docs/superpowers 의 신규 .md 2개(untracked)만 남아야 함
```

- [ ] **Step 3: goBack fix 전용 worktree + patch 적용 + 커밋**

```bash
git -C ~/Repositories/picnic-app worktree add ../picnic-app-vote-home-topmenu -b fix/vote-home-top-menu
cd ~/Repositories/picnic-app-vote-home-topmenu
git apply /tmp/goback-fix.patch
git add -A && git commit -m "fix(vote): keep home tab clear of stale top-menu strip after returning from detail

goBack() forced showTopMenu:true at stack root, but all vote-portal roots
opt out. IndexedStack keep-alive means the root page can't re-apply its own
settingNavigation, so goBack must restore it. Restore false at root."
```

- [ ] **Step 4: 3개 레포 worktree 생성 + 의존성**

```bash
git -C ~/Repositories/picnic-app worktree add ../picnic-app-pic-chart -b feat/pic-chart-area-based
git -C ~/Repositories/picnic-web worktree add ../picnic-web-pic-chart -b feat/pic-chart-area-based
git -C ~/Repositories/picnic-admin worktree add ../picnic-admin-pic-chart -b feat/pic-chart-area-based
cp ~/Repositories/picnic-web/.env.local ~/Repositories/picnic-web-pic-chart/.env.local 2>/dev/null || true
cp ~/Repositories/picnic-admin/.env.local ~/Repositories/picnic-admin-pic-chart/.env.local 2>/dev/null || true
( cd ~/Repositories/picnic-web-pic-chart && npm install )
( cd ~/Repositories/picnic-admin-pic-chart && npm install )
```

- [ ] **Step 5: spec/plan 문서를 feature 브랜치로 이동 커밋 + 메인 정리**

```bash
mkdir -p ~/Repositories/picnic-app-pic-chart/docs/superpowers/{specs,plans}
cp ~/Repositories/picnic-app/docs/superpowers/specs/2026-07-14-pic-chart-area-based-design.md \
   ~/Repositories/picnic-app-pic-chart/docs/superpowers/specs/
cp ~/Repositories/picnic-app/docs/superpowers/plans/2026-07-14-pic-chart-area-based.md \
   ~/Repositories/picnic-app-pic-chart/docs/superpowers/plans/
cd ~/Repositories/picnic-app-pic-chart
git add docs/superpowers && git commit -m "docs(vote): PIC CHART area-based spec + plan"
# 메인 체크아웃의 untracked 원본 제거(worktree로 이관 완료)
rm ~/Repositories/picnic-app/docs/superpowers/specs/2026-07-14-pic-chart-area-based-design.md \
   ~/Repositories/picnic-app/docs/superpowers/plans/2026-07-14-pic-chart-area-based.md
git -C ~/Repositories/picnic-app status -s   # 빈 출력(pristine)
```

---

### Task 1: DB 마이그레이션 (image → area='pic-chart')

**Files:** DB only (MCP execute_sql). DDL 아님(순수 DML).

- [ ] **Step 1: 사전 상태 스냅샷(검증 기준)**

MCP execute_sql (project `xtijtefcycoeqludlngc`):
```sql
SELECT
  count(*) FILTER (WHERE areas @> ARRAY['pic-chart']) AS pic_chart_now,
  count(*) FILTER (WHERE areas @> ARRAY['kpop'] AND vote_category ILIKE '%image%') AS kpop_image_now,
  count(*) FILTER (WHERE vote_category ILIKE '%image%') AS image_total
FROM vote WHERE deleted_at IS NULL;
```
Expected: `pic_chart_now=0`, `kpop_image_now=67`, `image_total=67`.

- [ ] **Step 2: 마이그레이션 실행 (승인 후)**

```sql
UPDATE vote
SET    areas = ARRAY['pic-chart']
WHERE  vote_category ILIKE '%image%'
  AND  deleted_at IS NULL
  AND  NOT (areas @> ARRAY['pic-chart']);
```

- [ ] **Step 3: 사후 검증**

```sql
SELECT
  count(*) FILTER (WHERE areas @> ARRAY['pic-chart']) AS pic_chart,
  count(*) FILTER (WHERE areas @> ARRAY['kpop'] AND vote_category ILIKE '%image%') AS kpop_image,
  count(*) FILTER (WHERE areas @> ARRAY['kpop'] AND vote_category ILIKE '%weekly%') AS kpop_weekly,
  count(*) FILTER (WHERE area <> areas[1]) AS area_desync
FROM vote WHERE deleted_at IS NULL;
```
Expected: `pic_chart=67`, `kpop_image=0`, `kpop_weekly=36`(PICNIC 유지), `area_desync=0`(트리거 동기화 확인).

- [ ] **롤백(필요 시):** `UPDATE vote SET areas=ARRAY['kpop'] WHERE vote_category ILIKE '%image%' AND areas @> ARRAY['pic-chart'];`

---

### Task 2: picnic-app — pic-chart sentinel 제거 (area 기반 통일)

작업 위치: `~/Repositories/picnic-app-pic-chart`.

**Files:**
- Modify: `picnic_lib/lib/presentation/widgets/vote/list/vote_list.dart` (isPicChart sentinel + 카테고리 필터 제거)
- Modify: `picnic_lib/lib/presentation/pages/vote/vote_home_helper.dart` (미사용 메서드 제거)
- Test: `picnic_lib/test/presentation/pages/vote/vote_home_helper_test.dart` (제거 메서드 테스트 삭제)

**Interfaces:**
- Consumes: `asyncVoteListProvider(page,size,sort,order,area,{status,category,votePortal})` — area 필터는 provider 내부 `query.contains('areas',[area])`(변경 없음).
- Produces: pic-chart 탭이 `area='pic-chart'`를 그대로 provider에 넘겨 area 필터를 탄다. 카테고리 후처리는 레거시 `VotePortal.pic`만 유지.

- [ ] **Step 1: vote_list.dart — 초기 로드 필터 블록 교체**

`_fetchVotes` 내 현재:
```dart
      // PIC-CHART 선택 시 area는 'all'로 처리
      final isPicChart = widget.area == 'pic-chart';
      final queryArea = isPicChart ? 'all' : widget.area;

      final newItems = await ref.read(
        asyncVoteListProvider(
          _pageKey, _pageSize, sortKey, 'DESC', queryArea,
          status: widget.status, category: widget.category, votePortal: widget.portal,
        ).future,
      );

      // 카테고리 필터: PIC CHART(및 레거시 PIC 포탈)는 image(픽) 투표만, ...
      List<VoteModel> filteredItems = newItems;
      if (widget.portal == VotePortal.pic || isPicChart) {
        filteredItems = newItems
            .where((v) => VoteHomeHelper.isPicChartCategory(v.voteCategory))
            .toList();
      } else if (widget.area != 'all') {
        filteredItems = newItems
            .where((v) => !VoteHomeHelper.isPicChartCategory(v.voteCategory))
            .toList();
      }
```
로 교체:
```dart
      final newItems = await ref.read(
        asyncVoteListProvider(
          _pageKey, _pageSize, sortKey, 'DESC', widget.area,
          status: widget.status, category: widget.category, votePortal: widget.portal,
        ).future,
      );

      // vote 포탈 탭은 areas 배열(area)로만 분류 — 카테고리 후처리 없음.
      // 레거시 PIC 포탈(딥링크 전용)만 이미지/위클리 후처리를 유지한다.
      List<VoteModel> filteredItems = widget.portal == VotePortal.pic
          ? newItems.where((v) {
              final cat = (v.voteCategory ?? '').toLowerCase();
              return cat.contains('image') || cat.contains('weekly');
            }).toList()
          : newItems;
```

- [ ] **Step 2: vote_list.dart — 빈 페이지 스킵(retry) 블록 교체**

현재:
```dart
            // ALL이면 필터링 없이 모든 항목
            if (widget.area == 'all' && widget.portal != VotePortal.pic && !isPicChart) {
              filteredItems = nextItems;
            } else {
              final keepPic = widget.portal == VotePortal.pic || isPicChart;
              filteredItems = nextItems
                  .where((v) =>
                      keepPic == VoteHomeHelper.isPicChartCategory(v.voteCategory))
                  .toList();
            }
```
로 교체:
```dart
            filteredItems = widget.portal == VotePortal.pic
                ? nextItems.where((v) {
                    final cat = (v.voteCategory ?? '').toLowerCase();
                    return cat.contains('image') || cat.contains('weekly');
                  }).toList()
                : nextItems;
```

- [ ] **Step 3: vote_list.dart — 미사용 import 제거**

`import 'package:picnic_lib/presentation/pages/vote/vote_home_helper.dart';` 제거(더 이상 `VoteHomeHelper` 참조 없음 — 확인: `grep -n VoteHomeHelper picnic_lib/lib/presentation/widgets/vote/list/vote_list.dart` 결과 0).

- [ ] **Step 4: vote_home_helper.dart — 미사용 메서드 제거**

`resolveQueryArea`, `isPicChart`, `filterByArea`, `isPicChartCategory`, `processFetchResults`(filterByArea 의존) 를 제거. (전제: lib 내 사용처 0 — 확인 `grep -rn "resolveQueryArea\|isPicChart\|filterByArea\|isPicChartCategory\|processFetchResults" picnic_lib/lib | grep -v generated`.) `deduplicateVotes`/`sortByStopAtAsc`/`takePageSlice`/status·cache·nav 헬퍼는 유지.

- [ ] **Step 5: 테스트 정리 — 제거 메서드 테스트 삭제**

`vote_home_helper_test.dart`에서 `group('isPicChartCategory'…)`, `group('filterByArea'…)`, `group('processFetchResults'…)`, 및 `resolveQueryArea`/`isPicChart` 테스트 그룹 삭제.

- [ ] **Step 6: analyze + 테스트**

```bash
cd ~/Repositories/picnic-app-pic-chart/picnic_lib
flutter analyze lib/presentation/widgets/vote/list/vote_list.dart lib/presentation/pages/vote/vote_home_helper.dart
flutter test test/presentation/pages/vote/vote_home_helper_test.dart \
  test/presentation/widgets/vote/list/vote_list_test.dart \
  test/presentation/widgets/vote/list/vote_list_coverage_test.dart \
  test/presentation/pages/vote/vote_list_page_tabs_test.dart
```
Expected: analyze 0 issues, 전부 pass.

- [ ] **Step 7: Commit**

```bash
cd ~/Repositories/picnic-app-pic-chart
git add -A && git commit -m "refactor(vote): PIC CHART을 area 기반으로 (카테고리 sentinel 제거)"
```

---

### Task 3: picnic-web — pic-chart sentinel 제거

작업 위치: `~/Repositories/picnic-web-pic-chart`.

**Files:**
- Modify: `lib/data-fetching/server/vote-service-query.ts` (~185)
- Modify: `lib/data-fetching/client/vote-service.client.ts` (~133)
- Test: `lib/data-fetching/**` 관련 테스트 있으면 갱신(확인: `grep -rl "PIC_CHART\|vote_category.*image" __tests__ **/*.test.ts 2>/dev/null`)

**Interfaces:**
- Produces: `area==='pic-chart'`일 때도 `query.contains('areas',['pic-chart'])`로 필터(다른 area와 동일 경로).

- [ ] **Step 1: server 쿼리 분기 제거**

`vote-service-query.ts`에서:
```ts
  if (area && area !== VOTE_AREAS.ALL) {
    if (area === VOTE_AREAS.PIC_CHART) {
      // PIC-CHART: vote_category가 'image' 또는 'weekly'인 것
      query = query.in("vote_category", ['image', 'weekly']);
    } else {
      // K-POP, K-MUSICAL: areas 배열에 해당 값이 포함되어 있는지 확인
      query = query.contains("areas", [area]);
    }
  }
```
로 교체:
```ts
  if (area && area !== VOTE_AREAS.ALL) {
    // 모든 area 탭(pic-chart 포함) — areas 배열에 값 포함 여부로 필터
    query = query.contains("areas", [area]);
  }
```

- [ ] **Step 2: client 쿼리 분기 제거**

`vote-service.client.ts`의 동일 블록을 Step 1과 같은 형태로 교체.

- [ ] **Step 3: 빌드/타입/테스트**

```bash
cd ~/Repositories/picnic-web-pic-chart
npx tsc --noEmit
npm test -- vote-service 2>/dev/null || echo "(관련 테스트 없음 — skip)"
npm run build
```
Expected: 타입 에러 0, 빌드 성공.

- [ ] **Step 4: Commit**

```bash
git add -A && git commit -m "refactor(vote): PIC CHART을 area(areas) 기반 필터로 통일"
```

---

### Task 4: picnic-admin — pic-chart/spotlight area 옵션 추가

작업 위치: `~/Repositories/picnic-admin-pic-chart`.

**Files:**
- Modify: `app/vote/components/VoteForm.tsx` (~464 areas Select options)
- Modify: `app/vote/components/VoteList.tsx` (`FILTER_AREA`, `getAreaName`, `getAreaColor`, 필터 드롭다운 options)

**Interfaces:**
- Produces: admin이 vote 생성/편집 시 `areas`에 `pic-chart`·`spotlight`를 선택 가능; 리스트 필터/표시에서 인식.

- [ ] **Step 1: VoteForm areas 옵션 추가**

```tsx
          options={[
            { label: 'K-POP', value: 'kpop' },
            { label: 'PIC CHART', value: 'pic-chart' },
            { label: '뮤지컬', value: 'musical' },
            { label: 'SPOTLIGHT', value: 'spotlight' },
          ]}
```

- [ ] **Step 2: FILTER_AREA 상수 확장**

```tsx
const FILTER_AREA = {
  ALL: 'all',
  KPOP: 'kpop',
  PIC_CHART: 'pic-chart',
  MUSICAL: 'musical',
  SPOTLIGHT: 'spotlight',
} as const;
```

- [ ] **Step 3: getAreaName / getAreaColor case 추가**

```tsx
// getAreaName switch
    case 'pic-chart':
      return 'PIC CHART';
    case 'spotlight':
      return 'SPOTLIGHT';
// getAreaColor switch
    case 'pic-chart':
      return '#FF5722';
    case 'spotlight':
      return '#FF9800';
```

- [ ] **Step 4: 리스트 필터 드롭다운 options 추가**

```tsx
              options={[
                { label: '전체', value: FILTER_AREA.ALL },
                { label: 'K-POP', value: FILTER_AREA.KPOP },
                { label: 'PIC CHART', value: FILTER_AREA.PIC_CHART },
                { label: '뮤지컬', value: FILTER_AREA.MUSICAL },
                { label: 'SPOTLIGHT', value: FILTER_AREA.SPOTLIGHT },
              ]}
```

- [ ] **Step 5: 타입/빌드**

```bash
cd ~/Repositories/picnic-admin-pic-chart
npx tsc --noEmit
npm run build 2>/dev/null || npx next build
```
Expected: 타입 에러 0.

- [ ] **Step 6: Commit**

```bash
git add -A && git commit -m "feat(vote): admin에 pic-chart/spotlight area 옵션 추가"
```

---

### Task 5: 통합 검증 + PR

- [ ] **Step 1: DB↔코드 정합 최종 확인** — 마이그레이션 후 각 탭 진행중 카운트가 PICNIC(kpop non-image), PIC CHART(pic-chart), MUSICAL(musical)로 맞는지 §Task1 Step3 재확인.
- [ ] **Step 2: 3개 레포 PR 생성** (각 worktree에서 `gh pr create`). PR 본문에 배포 순서(DB 선반영 완료 → web → app → admin) 명시.
- [ ] **Step 3: 머지 후 worktree 정리** — `git worktree remove ../picnic-<repo>-pic-chart` (머지 성공 확인 후에만).

# PIC CHART을 area 기반 탭으로 전환 (sentinel 제거)

- 날짜: 2026-07-14
- 범위: **DB 마이그레이션 + picnic-app + picnic-web + picnic-admin** (공유 Supabase `xtijtefcycoeqludlngc`)
- 관련: `2026-07-13-home-vote-ui-redesign-design.md`(홈/투표 개편으로 4탭 도입)

## 1. 배경 / 문제

투표 4탭 = **PICNIC / PIC CHART / MUSICAL / SPOTLIGHT**. 이 중 PICNIC·MUSICAL·SPOTLIGHT는 `vote.areas` 배열을 `@> ['<area>']`(array-contains)로 필터하는데, **PIC CHART만 예외로 `vote_category IN ('image','weekly')` 카테고리 sentinel**로 구현돼 있다. 이 예외가 앱·웹 양쪽에 중복 존재하고, admin은 `areas`로만 큐레이션하므로 PIC CHART은 admin 통제를 벗어나 있다.

**목표:** PIC CHART을 다른 탭과 동일하게 `areas @> ['pic-chart']`로 통일. 카테고리 sentinel 전면 제거 → **admin이 `areas` 필드로 4탭 전부 큐레이션**.

## 2. 스키마 사실 (확인 완료)

- `vote.areas text[]`(nullable) = **탭 필터의 소스 오브 트루스**. 앱 `vote_list_provider.dart:100 query.contains('areas',[area])`, 웹 `vote-service-query.ts:190`/`vote-service.client.ts` 동일.
- `vote.area text NOT NULL` = 트리거 **`sync_vote_area_arrays`(BEFORE INS/UPD)**가 `areas[1]`로 자동 파생. → **마이그레이션은 `areas`만 세팅하면 `area` 자동 동기화.**
- 쓰기 가드 트리거 **`guard_admin_only_write`**: `current_user IN ('authenticated','anon') AND NOT is_request_admin()`일 때만 차단 → **MCP/postgres 역할은 통과**(프로덕션 쓰기라 승인 후 실행).
- 현재 데이터(deleted 제외): `areas=['kpop']` 178(그중 `vote_category` image 67·weekly 36), `['musical']` 23, `['kpop','musical']` 1(비-image). **`pic-chart`/`spotlight`는 areas에 0건.**

## 3. 설계

### 3.1 DB 마이그레이션 (DML)
```sql
-- image 투표를 PIC CHART 로. areas 만 세팅(트리거가 area='pic-chart' 파생).
-- image 는 kpop 에서 제외되어 PICNIC 에서 사라지고 PIC CHART 로 이동.
UPDATE vote
SET    areas = ARRAY['pic-chart']
WHERE  vote_category ILIKE '%image%'
  AND  deleted_at IS NULL
  AND  NOT (areas @> ARRAY['pic-chart']);   -- 멱등
```
- weekly(36)는 **손대지 않음** → `areas=['kpop']` 유지 → PICNIC.
- spotlight: **데이터 변경 없음**(태깅은 별도 보류 결정).
- 검증: `areas @> ['pic-chart']` 카운트 = 67, PICNIC(`areas @> ['kpop']`)에 image 0.
- 롤백: `UPDATE vote SET areas=ARRAY['kpop'] WHERE vote_category ILIKE '%image%' AND areas @> ARRAY['pic-chart'];`

### 3.2 picnic-app (picnic_lib)
- `widgets/vote/list/vote_list.dart`: **`isPicChart` sentinel 제거**(`queryArea = isPicChart ? 'all'` 및 카테고리 image/weekly 필터 전부). 모든 탭이 자기 area를 provider에 그대로 전달 → provider가 `areas @> [area]` 필터. 빈-페이지 스킵 블록의 카테고리 필터도 제거.
- `providers/vote_list_provider.dart`: 이미 `contains('areas',[area])`라 area 필터 자체는 변경 불필요. pic-chart도 이제 일반 area로 통과.
- `pages/vote/vote_home_helper.dart`: `resolveQueryArea`·`isPicChart`·`filterByArea`·`isPicChartCategory` **제거**(더 이상 쓰이지 않음). 관련 테스트 삭제/정리. → **2026-07-14 먼저 넣은 weekly 카테고리 재분류 변경은 이 area 방식이 흡수**(카테고리 필터 자체가 사라지므로 원복 겸 대체).
- `common/area_selector.dart`: 이미 `pic-chart` 옵션 있음(변경 불필요).

### 3.3 picnic-web
- `lib/data-fetching/server/vote-service-query.ts` (~185): `if (area === PIC_CHART) query.in('vote_category',['image','weekly'])` **분기 제거** → 항상 `query.contains('areas',[area])`.
- `lib/data-fetching/client/vote-service.client.ts` (~133): 동일 제거.
- 효과: 웹 PIC CHART도 area 기반. **기존 image+weekly sentinel이 사라져 앱/웹 weekly 취급 불일치도 자동 해소**(weekly→PICNIC 일관).

### 3.4 picnic-admin
- `app/vote/components/VoteForm.tsx` (~471): `areas` Select options에 `{label:'PIC CHART', value:'pic-chart'}` 추가(+ `{label:'SPOTLIGHT', value:'spotlight'}` — 미래 대비, 데이터는 아직 없음). → **앞으로 admin이 vote를 pic-chart/spotlight로 태깅 가능**(지속가능성 핵심).
- `app/vote/components/VoteList.tsx`: `FILTER_AREA`에 `PIC_CHART`(+`SPOTLIGHT`), `getAreaName`/`getAreaColor` case 추가, 필터 드롭다운 options(~604)에 항목 추가.

## 4. 배포 순서 (각 단계 non-breaking)
1. **DB 마이그레이션 먼저**: 코드가 아직 sentinel(카테고리)이어도 PIC CHART은 여전히 image 노출(sentinel은 areas 무시), PICNIC은 image가 kpop에서 빠져 어차피 안 보이던 것과 동일 → 안 깨짐.
2. picnic-web 배포(area 기반).
3. picnic-app 배포(area 기반).
4. picnic-admin 배포(태깅 옵션).
순서 무관하게 각 단계가 non-breaking. admin은 언제 배포해도 무방.

## 5. 테스트
- **DB**: 마이그레이션 전/후 카운트 검증 쿼리(PIC CHART 67, PICNIC image 0, weekly는 PICNIC 유지).
- **app**: `vote_home_helper_test.dart`에서 제거 메서드 테스트 삭제; `vote_list` 관련 테스트가 area 기반으로 통과하는지. sentinel 제거 후 pic-chart 탭이 `areas@>['pic-chart']`로 쿼리하는지 provider 레벨 확인.
- **web**: `vote-service` 테스트가 있으면 pic-chart가 `contains('areas',['pic-chart'])`로 바뀌었는지 갱신.
- **admin**: `VoteList`/`VoteForm` 테스트에 pic-chart area 옵션/표시 추가.

## 6. 리스크 / 미결
- **프로덕션 데이터 쓰기**: 마이그레이션은 승인 후 실행. 멱등·롤백 쿼리 확보.
- **3-repo 조율**: 앱·웹·admin 각각 배포 필요. 단 §4대로 각 단계 non-breaking.
- **웹 SPOTLIGHT 탭 유무 미확인**: 웹 VOTE_AREAS엔 KPOP/MUSICAL/PIC_CHART만 보임 — 웹은 spotlight 탭이 없을 수 있음(있으면 동일 패턴). 구현 시 확인.
- **admin write 가드**: 마이그레이션은 MCP(postgres)로 통과 예상. 실패 시 service_role로.

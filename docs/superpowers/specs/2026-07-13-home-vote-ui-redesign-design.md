# Picnic 앱 홈/투표 UI 개편 v2.2 — 설계 문서

- **작성일**: 2026-07-13
- **브랜치**: `feat/home-vote-ui-redesign` (worktree: `~/Repositories/picnic-app-home-vote-ui`)
- **원본 PRD**: `picnic-home-vote-ui-prd-v2.2.html` (CTO 전달용 v2.2.1)
- **대상**: picnic-app (Flutter, `picnic_lib` 중심) + picnic-supabase (마이그레이션)

## 1. 목표 / 비목표

### 목표
- 홈 진입 구조 단순화(미사용 상단 기능 제거).
- 홈(요약형 허브)과 투표 페이지(탐색형 리스트)의 목적 분리.
- 향후 투표 종류 증가(10~20개)를 고려한 확장형·데이터 기반 종류 탭 구조.

### 비목표 (이번 범위에서 건드리지 않음)
- 투표 상세 페이지 세부 레이아웃.
- 저장/공유 기능 내부 로직.
- 홈 진행중 투표 카드의 최종 비주얼 비율/텍스트 배치(추후 확정, 기능만 구현).
- 궁합/PIC/커뮤니티 포탈 화면 자체(코드·딥링크 보존, 상단 진입점만 제거).

## 2. 확정된 의사결정 (사용자 승인 2026-07-13)

| 항목 | 결정 |
|---|---|
| 투표 종류 탭 데이터 소스 | **백엔드 `vote_type` 테이블 신설** (data-driven, 확장형) |
| 상단 Vote/Goong-Hap 버튼 · 커뮤니티 탭 제거 | **상단 진입점만 제거.** 궁합/PIC/커뮤니티 포탈 코드·딥링크는 보존 |
| 홈 "현재 진행중인 투표" 대표 선정 | **곧 종료되는 진행중**(active 중 `stop_at ASC` 첫 1건) |
| 작업 분할 | **단일 워크트리에서 한 번에** (앱 1 PR + 백엔드 마이그레이션 별도 레포) |
| "흰색 영역 전체 삭제" 해석 | 민트 AppBar 아래 `TopMenu` 보조 스트립(별사탕 + area 드롭다운 + 페이지 타이틀) 제거. 스크린 본문은 유지 |

## 3. 크로스 레포 영향

`vote_type`은 백엔드 스키마라 두 레포에 걸친다. 세 프로젝트가 같은 Supabase 인스턴스(`xtijtefcycoeqludlngc`)를 공유한다.

- **picnic-supabase**: `vote_type` 테이블 + `vote.vote_type_id` 컬럼 마이그레이션, 시드, 기존 vote 백필. (별도 마이그레이션 PR / 사용자 지시 시 MCP apply)
- **picnic-app**: 앱 UI 및 provider (이 워크트리, 1 PR).

> 앱 코드는 마이그레이션이 먼저 적용되어야 동작한다. 개발/검증을 위해 공유 인스턴스에 마이그레이션 적용 필요.

## 4. 현재 구조 (매핑 결과 요약)

### 4.1 하단 네비게이션 — data-driven
- `picnic_lib/lib/data/models/navigator/navigation_configs.dart` `_screenInfoMap` (L16–139)가 단일 소스.
- `PortalType.vote` 탭(L18–51): `nav_vote`(0)/`nav_community`(1)/`nav_media`(2)/`nav_store`(3).
- 렌더: `CommonBottomNavigationBar`(`.../navigator/bottom/common_bottom_navigation_bar.dart`), 각 탭 `MenuItem`(`.../menu_item.dart`, SVG 아이콘만, title 텍스트 미표시).
- 선택: `MenuItem` → `setBottomNavigationIndex(index)` → `getPageWidget(portalType, index)` 위젯을 `voteNavigationStack`에 push → `PicnicAnimatedSwitcher`의 `IndexedStack`으로 표시. (GoRouter/PageView 아님.)
- 선택 인덱스 persist: `globalStorage.saveData('voteBottomNavigationIndex', ...)` (`navigation_provider.dart` L364).
- `home.svg` 아이콘 이미 존재(`assets/icons/bottom/home.svg`, PIC 포탈이 사용 중).
- ⚠️ 중복 배선: `picnic_app/lib/bottom_navigation_menu.dart`에도 동일 목록 존재 → 동기화 필요.

### 4.2 상단 헤더 — `portal.dart` `Portal` (L22–169)
- 민트 그라디언트: `commonGradient`(`picnic_lib/lib/ui/common_gradient.dart`), AppBar 배경 = `voteMainColor` = `AppColors.secondary500`(`0xFF83FBC8`).
- **제거 대상**: Vote/Goong-Hap `PortalMenuItem`(L107–108, 포탈 전환), `AttendanceIconButton`(L131), `TopMenu` 스트립의 별사탕 `CommonMyPoint`(`top_menu.dart` L190) + area 드롭다운 `AreaSelector`(`top_menu.dart` L94).
- **유지 대상**: 프로필 avatar(AppBar leading, L55–95) → drawer(`MyPageScreen`), 알림 `TopRightNotifications`(L133), 민트 AppBar.

### 4.3 투표 페이지 — `vote_list_page.dart`
- 상태 탭: `_VoteListContentState.build`(L160–196), `TabBar` + `TabBarView`(physics `NeverScrollableScrollPhysics` → **현재 스와이프 불가**). 라벨 진행중/종료됨/예정됨. 인덱스 `PageStorage` persist.
- 카테고리 드롭다운: `AreaSelector`(`area_selector.dart`), `appSettingProvider.area`에 바인딩, `globalStorage`에 persist.
- 카드: `VoteInfoCard`(`.../vote/list/vote_info_card.dart` L30), 1~3위 podium. 서버가 vote_item top-3로 제한(`vote_list_provider.dart` L151–156).
- 데이터: `AsyncVoteList`(`vote_list_provider.dart`), `build(page, limit, sort, order, area, {votePortal, status, category})`. status → 날짜 필터, category → `.eq('vote_category', …)`, area → `.contains('areas', [area])`.
- 데이터 모델: `vote.dart`에 `area`, `vote_category`, `is_partnership`/`partner` 존재. **`vote_type` 없음.**

### 4.4 홈 카드 · 리워드 · 배너
- `VoteInfoCard` 공용(홈/PIC/투표리스트 3곳 공유) — 홈 전용 분리 없음. → 개편은 홈 전용 variant 신설.
- 카운트다운: `CountdownTimer`(`.../list/countdown_timer.dart`), `endTime.difference(now)` 1초 주기.
- 저장/공유: `ShareSection`(`.../common/share_section.dart`), `onSave`/`onShare` 콜백. 핸들러는 카드 내부(`_handleSaveImage`/`_handleShareToTwitter`).
- 리워드: `_buildRewardList`(`vote_home_page.dart` L302–432), `ListView.builder` 가로 스크롤(height 100, item 120×100), `asyncRewardListProvider`(`reward` 테이블).
- 배너: `CommonBanner('vote_home', ...)`(`vote_home_page.dart` L183), `asyncBannerListProvider(location:'vote_home')`.

### 4.5 미디어
- 탭 페이지: `VoteMediaListPage`(`.../pages/vote/vote_media_list_page.dart`), `media` 테이블 `.order('id', desc)` 페이지네이션. 세로 full-width `VideoListItem` 카드.
- 모델: `VideoInfo`(`.../data/models/vote/video_info.dart`) — `id`, `videoId`, `title`(localized JSON), `createdAt`, `channelTitle` 등. thumbnail은 videoId에서 파생(`https://img.youtube.com/vi/$id/maxresdefault.jpg`).
- 가로 미디어 캐러셀 없음 → 리워드 리스트 패턴 복제.

## 5. 변경 설계

### 5.1 하단 탭바 + 헤더
1. `navigation_configs.dart` `PortalType.vote` pages 재정의:
   - `nav_community` 항목 제거.
   - `nav_home`(index 0, `home.svg`, `pageWidget: HomePage()`) 신설.
   - 나머지 index 재부여: 홈0 / 투표1 / 미디어2 / 상점3.
   - `CommunityHomePage` import 제거(미사용).
2. `bottom_navigation_menu.dart` 동일 동기화.
3. persist 보정: `voteBottomNavigationIndex` 로드시 기본값 0(홈). 저장된 구 인덱스(0=vote 등)와 시프트 충돌 방지 — 저장값 무시하고 진입 시 홈(0)으로 시작하거나, 마이그레이션 로직으로 클램프. **결정: 진입 시 홈(0) 고정 시작** (구 저장값 폐기).
4. `portal.dart`: Vote/Goong-Hap `PortalMenuItem`, `AttendanceIconButton` 제거. 프로필/알림/민트 AppBar 유지.
5. `top_menu.dart`: 별사탕 `CommonMyPoint` + area 드롭다운 `AreaSelector` + 페이지 타이틀을 포함한 보조 스트립을 홈/투표 화면에서 제거(= "흰색 영역 삭제"). `showTopMenu` 게이팅 활용해 다른 포탈 영향 없이 vote 포탈 대상 화면만 제거.
6. 포탈 전환(`setPortal`)·궁합/PIC/커뮤니티 화면 코드는 **보존**.

### 5.2 백엔드 `vote_type` (picnic-supabase)
```sql
create table public.vote_type (
  id          bigint generated always as identity primary key,
  code        text not null unique,          -- 'picnic' | 'musical' | 'joongang' | 'cgv' ...
  title       jsonb not null default '{}',   -- {"ko":"뮤지컬","en":"Musical", ...}
  "order"     integer not null default 0,
  deleted_at  timestamptz
);

alter table public.vote add column vote_type_id bigint references public.vote_type(id);
create index vote_vote_type_id_idx on public.vote(vote_type_id);
```
- 시드: `picnic`(order 0), `musical`(1), `joongang`(2), `cgv`(3). title은 ko/en 최소 제공(비라틴 문자열은 정본에서 복사, i18n 정책 준수).
- 기존 vote 백필: `area='musical'` → musical, 그 외 → picnic. (pic-chart는 PIC 포탈, 대상 외.)
- RLS/grant: `reward`/`vote`와 동등한 최소 읽기 권한만. 쓰기 미부여. (systemic RLS 노출 이슈 고려 — blanket grant 금지.)

### 5.3 투표 페이지 재구성
- **투표 종류 탭** (신규):
  - `VoteType` 모델(`code`, `title`, `order`) + `asyncVoteTypeListProvider`(`vote_type` order순, deleted_at null).
  - UI: **`TabBar(isScrollable: true)` + `TabBarView`** 사용(기존 상태탭 위젯 재활용), 단 `TabBarView` physics를 스와이프 허용으로 변경(현 `NeverScrollableScrollPhysics` 제거). 탭이 많으면 가로 스크롤. 데이터 기반 렌더(고정 개수 전제 X, `vote_type` 목록 길이에 따라 `TabController.length` 동적).
  - 선택 상태는 페이지 로컬(탭 인덱스 → vote_type_id).
- **상태 필터 드롭다운** (기존 area 드롭다운 대체 위치):
  - 값: 진행중/종료됨/예정됨. 기본값 **항상 진행중**.
  - 페이지 로컬 state. **재진입 시 미저장**(기존 `PageStorage`/persist 제거).
  - 위치: 종류 탭 아래, 리스트 위.
- **리스트**:
  - `AsyncVoteList.build`에 `voteTypeId` 파라미터 추가 → `.eq('vote_type_id', voteTypeId)`(값 있을 때).
  - 기존 status 날짜 필터 재사용. `area` 컬럼/서버 필터는 스키마상 보존하되, 투표 페이지 UI에서 area를 더 이상 전달하지 않음(파티션은 `vote_type_id` + status로 일원화). `appSettingProvider.area` persist는 이 화면 흐름에서 미사용.
  - 카드 `VoteInfoCard`(1~3위) 유지.

### 5.4 홈 화면 (`HomePage` 신규)
- 위젯 트리(세로 스크롤): 배너 → 진행중 투표 카드 → 리워드 목록 → 미디어 최신 6.
- **배너**: `CommonBanner('vote_home', ...)` 재사용.
- **현재 진행중 투표 카드**:
  - `asyncFeaturedVoteProvider`(신규): active(`start_at<now<stop_at`) 중 `stop_at ASC` 첫 1건 + vote_item top-1.
  - `HomeFeaturedVoteCard`(신규 컴포넌트): 1위(rank-1)만·낮은 높이. 제목 / `CountdownTimer`(재사용) / `ShareSection`(저장·공유 재사용). 공용 `VoteInfoCard` 미변경.
- **리워드**: 기존 `_buildRewardList` 패턴 재사용(홈으로 이관).
- **미디어 6**: `asyncLatestMediaProvider`(신규) — `media` `.order('id', desc).limit(6)` → `VideoInfo`. 리워드와 동일 가로 스크롤 카드. 탭 시 유튜브 오픈(`VideoListItem` 방식).

### 5.5 신규/수정 파일
**신규**
- `HomePage`(홈 탭 스크린/페이지)
- `HomeFeaturedVoteCard`(홈 전용 카드)
- `VoteType` 모델 + `.freezed`/`.g`
- `asyncVoteTypeListProvider`
- `asyncFeaturedVoteProvider`
- `asyncLatestMediaProvider`
- picnic-supabase 마이그레이션 SQL

**수정**
- `navigation_configs.dart`, `bottom_navigation_menu.dart`, `navigation_provider.dart`(index 기본값/보정)
- `portal.dart`, `top_menu.dart`
- `vote_list_page.dart`, `vote_list.dart`, `vote_list_provider.dart`
- `vote.dart`(`vote_type_id` 필드) + 재생성
- l10n(홈 섹션 타이틀, 상태필터 라벨 신규 키)

## 6. 검증 계획
- `flutter analyze` + 변경 파일 대상 `flutter test`.
- 코드 생성: `./run_build_runner.sh`(freezed/riverpod/json).
- 수동: 하단탭 4개(홈/투표/미디어/상점), 홈 4섹션 렌더, 투표 종류 탭 스와이프 + 상태 드롭다운 기본값 진행중 + 재진입 리셋, 미디어 6개 노출/탭.
- 마이그레이션은 공유 Supabase 적용 후 실제 데이터로 확인.

## 7. 오픈 이슈 (PRD상 미확정 — 그대로 둠)
- 홈 진행중 카드 최종 비율/텍스트 배치.
- 미디어 최종 레이아웃(본 구현은 가로 스크롤로 확정).
- 종류 탭이 매우 많을 때 탭 폭/스크롤 UX 세부 정책.

## 8. 리스크
- persist 인덱스 시프트로 재실행 시 잘못된 탭 진입 → 홈(0) 고정 시작으로 방어.
- `top_menu`/`portal` 은 vote 외 포탈에도 공유 → 게이팅으로 vote 대상만 변경, 회귀 주의.
- `vote_type` 백필 누락 시 탭이 빈 리스트 → 기본 picnic 백필로 최소 담보.
- 크로스 레포 순서: 마이그레이션 미적용 상태로 앱만 배포되면 쿼리 실패 → 마이그레이션 선적용 필수.

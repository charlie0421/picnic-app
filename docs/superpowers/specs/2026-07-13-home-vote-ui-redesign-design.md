# Picnic 앱 홈/투표 UI 개편 v2.2 — 설계 문서

- **작성일**: 2026-07-13
- **브랜치**: `feat/home-vote-ui-redesign` (worktree: `~/Repositories/picnic-app-home-vote-ui`)
- **원본 PRD**: `picnic-home-vote-ui-prd-v2.2.html` (CTO 전달용 v2.2.1)
- **대상**: picnic-app (Flutter, `picnic_lib` 중심). **백엔드 스키마 변경 없음.**

## 1. 목표 / 비목표

### 목표
- 홈 진입 구조 단순화(미사용 상단 기능 제거).
- 홈(요약형 허브)과 투표 페이지(탐색형 리스트)의 목적 분리.
- 투표 종류 탭 도입(가로 스크롤·스와이프). **기존 `area` 필드 재활용** — 백엔드 신설 없이 최소 변경.

### 비목표 (이번 범위에서 건드리지 않음)
- 투표 상세 페이지 세부 레이아웃.
- 저장/공유 기능 내부 로직.
- 홈 진행중 투표 카드의 최종 비주얼 비율/텍스트 배치(추후 확정, 기능만 구현).
- 궁합/PIC/커뮤니티 포탈 화면 자체(코드·딥링크 보존, 상단 진입점만 제거).

## 2. 확정된 의사결정 (사용자 승인 2026-07-13)

| 항목 | 결정 |
|---|---|
| 투표 종류 탭 데이터 소스 | **기존 `area` 필드 재활용** (백엔드 신설·스키마 변경 없음). 탭 목록은 앱 const config |
| 탭 ↔ area 매핑 | PICNIC→`kpop` / PIC CHART→`pic-chart` / MUSICAL→`musical` / SPOTLIGHT→`spotlight`. 기존 재태깅 없음 |
| 탭 라벨 | **전부 영어 하드코딩** (PICNIC / PIC CHART / MUSICAL / SPOTLIGHT). i18n 키 미사용 |
| 상단 Vote/Goong-Hap 버튼 · 커뮤니티 탭 제거 | **상단 진입점만 제거.** 궁합/PIC/커뮤니티 포탈 코드·딥링크는 보존 |
| 홈 "현재 진행중인 투표" 대표 선정 | **곧 종료되는 진행중**(active 중 `stop_at ASC` 첫 1건) |
| 작업 분할 | **단일 워크트리에서 한 번에** (앱 1 PR) |
| "흰색 영역 전체 삭제" 해석 | 민트 AppBar 아래 `TopMenu` 보조 스트립(별사탕 + area 드롭다운 + 페이지 타이틀) 제거. 스크린 본문은 유지 |

### 2.1 DB 실측 근거 (탭↔area 매핑)
`vote.areas`에 실제 존재하는 값은 `kpop`(179건), `musical`(24건) 둘뿐. `pic-chart`/`spotlight`는 데이터 없음.
vote_category 분포: kpop → image 67 · birthday 50 · weekly 36 · debut 20 …, musical → birthday 23 …
→ PICNIC=`kpop`(기존 전부 커버), MUSICAL=`musical`, **PIC CHART/SPOTLIGHT는 신규 area라 admin이 `votes.areas`에 값 추가하기 전까지 빈 목록**(정상 동작). 스키마 변경·기존 재태깅 불필요.

## 3. 영향 범위 (단일 레포)
- **picnic-app 만** 변경. 백엔드 마이그레이션 없음.
- 신규 area 값(`pic-chart`/`spotlight`)은 스키마가 아니라 데이터 — admin이 vote 생성/편집 시 `areas` 배열에 값을 넣으면 즉시 해당 탭에 노출. (앱 배포와 독립적.)

## 4. 현재 구조 (매핑 결과 요약)

### 4.1 하단 네비게이션 — data-driven
- `NavigationConfigs._screenInfoMap`(`navigation_configs.dart` L16–139)가 **실제 렌더 소스**. `CommonBottomNavigationBar`가 `getScreenInfo`로 읽음.
- vote 포탈 탭(L18–51): `nav_vote`(0)/`nav_community`(1)/`nav_media`(2)/`nav_store`(3).
- `picnic_app/lib/bottom_navigation_menu.dart`의 `voteScreenInfo/votePages`는 vestigial(`common_my_point_info.dart`가 `pages.length`만 사용). 정합 위해 함께 수정.
- `home.svg` 아이콘 이미 존재.

### 4.2 상단 헤더 — `portal.dart` `Portal` (L22–169)
- 민트 AppBar(`voteMainColor`=`0xFF83FBC8`).
- **제거**: Vote/Goong-Hap `PortalMenuItem`(L107–108), `AttendanceIconButton`(L131).
- **유지**: 프로필 leading(L55–95), 알림 `TopRightNotifications`(L133).
- 별사탕 `CommonMyPoint` + area 드롭다운 `AreaSelector` + 페이지 타이틀은 `TopMenu`(별도 위젯) 스트립에 있고, 페이지가 `settingNavigation(showTopMenu:false)`를 부르면 통째로 사라짐.

### 4.3 헤더 제어 메커니즘
- `settingNavigation({showPortal, showBottomNavigation, showTopMenu, showMyPoint, topRightMenu, pageTitle})` (navigation_provider.dart).
- 각 페이지가 `_updateNavigation()`(initState/didChangeDependencies/onRoutePopNext)에서 호출.
- `showTopMenu:false` → `portal.dart`의 `if (showTopMenu) const TopMenu()`가 스킵 → 흰색 스트립(별사탕+area드롭다운+타이틀) 제거. **홈/투표 화면에서만 false.**

### 4.4 투표 페이지 — `vote_list_page.dart`
- 상태 탭: `TabBar`+`TabBarView`(physics `NeverScrollableScrollPhysics` → 스와이프 불가). 진행중/종료됨/예정됨. 인덱스 `PageStorage` persist.
- 카테고리 드롭다운: `AreaSelector`(제거 대상).
- 데이터: `AsyncVoteList.build(page, limit, sort, order, area, {votePortal, status, category})`. **`area != 'all'`이면 이미 `.contains('areas',[area])` 서버 필터 적용** → 종류 탭이 이 area 파라미터를 그대로 활용.
- `VoteList(status, category, area, {portal})`가 area를 provider로 스레딩.
- 카드 `VoteInfoCard`(1~3위) 유지.

### 4.5 홈 카드 · 리워드 · 배너 · 미디어
- `VoteInfoCard` 공용(수정 금지) → 홈은 별도 카드.
- 카운트다운 `CountdownTimer(endTime, status, onRefresh?)`, 저장/공유 `ShareSection(onSave, onShare)`.
- 리워드 `_buildRewardList`(`vote_home_page.dart` L302–432), `asyncRewardListProvider`.
- 배너 `CommonBanner('vote_home', 786/400)`.
- 미디어 `media` 테이블 `id DESC`, 모델 `VideoInfo`, thumbnail은 videoId 파생. 가로 캐러셀 없음 → 리워드 패턴 복제.

## 5. 변경 설계

### 5.1 하단 탭바 + 헤더
1. `navigation_configs.dart` vote 포탈 pages 재정의: community 제거, 홈(0,`HomePage`)/투표(1,`VoteListPage`)/미디어(2)/상점(3). `home.svg`.
2. `bottom_navigation_menu.dart` 동기화(vestigial 정합).
3. `portal.dart`: Vote/Goong-Hap `PortalMenuItem` + `AttendanceIconButton` 제거. 프로필/알림/민트 유지.
4. 홈·투표 페이지가 `settingNavigation(showTopMenu:false)` 호출 → 흰색 스트립 제거.
5. 포탈 전환·궁합/PIC/커뮤니티 화면 코드 보존.

### 5.2 투표 종류 탭 (area 재활용, 백엔드 무변경)
- 탭 목록은 앱 const config:
  ```dart
  const _voteTabs = [
    ('PICNIC', 'kpop'),
    ('PIC CHART', 'pic-chart'),
    ('MUSICAL', 'musical'),
    ('SPOTLIGHT', 'spotlight'),
  ];
  ```
- 신규 종류 추가 = config 1줄 + votes.areas 태깅(DB 테이블 불필요).
- 라벨은 영어 리터럴. **provider/모델 변경 없음** — 기존 `area` 필터 재사용.

### 5.3 투표 페이지 재구성 (`vote_list_page.dart`)
- 상단 **투표 종류 탭**: `_voteTabs` 기반 `TabBar(isScrollable:true)` + `TabBarView`(스와이프 허용, `NeverScrollableScrollPhysics` 제거). `TabController.length = _voteTabs.length`.
- 탭 아래 **상태 필터 드롭다운**: 진행중/종료됨/예정됨, **기본값 진행중**, **페이지 로컬 state**(재진입 미저장 — `PageStorage`/persist 제거).
- 리스트: 각 탭 = `VoteList(status, VoteCategory.all, tab.area, portal: VotePortal.vote)`. area가 서버 필터로 걸림.
- 페이지 타이틀은 본문에서 렌더(`showTopMenu:false`이므로).
- admin 디버그: 상태 드롭다운에 `(Admin)` 항목으로 편입(선택).

### 5.4 홈 화면 (`HomePage` 신규)
- 순서: 배너 → 현재 진행중인 투표 카드 → 리워드 목록 → 미디어 최신 6. `showTopMenu:false`.
- **현재 진행중 투표 카드**: 별도 provider 없이 기존 `asyncVoteListProvider(1, 1, 'id', 'DESC', 'all', status: active, category: all)` 재사용 → 첫 1건(active 브랜치가 `stop_at ASC` 정렬). `HomeFeaturedVoteCard`(신규): rank-1만·낮은 높이, 제목/`CountdownTimer`/`ShareSection` 재사용. 공용 `VoteInfoCard` 미변경.
- **리워드**: `RewardListSection`으로 추출해 재사용.
- **미디어 6**: `asyncLatestMediaProvider`(신규) — `media` `.order('id',desc).limit(6)` → `VideoInfo`. 리워드와 동일 가로 캐러셀. 탭 시 유튜브 오픈.

### 5.5 신규/수정 파일
**신규**
- `HomePage`(홈 탭), `HomeFeaturedVoteCard`, `RewardListSection`, `LatestMediaSection`
- `asyncLatestMediaProvider`(+ 생성물)

**수정**
- `navigation_configs.dart`, `bottom_navigation_menu.dart`
- `portal.dart`
- `vote_list_page.dart` (종류 탭 config + 상태 드롭다운, `showTopMenu:false`)
- l10n: `label_home_current_vote` 키 1개(홈 섹션 타이틀) — ko/en

> **vote_type 테이블·모델·provider, VoteModel 변경, VoteList voteTypeId 스레딩은 모두 불필요**(area 재활용).

## 6. 검증 계획
- `flutter analyze` + 변경 파일 대상 `flutter test`(picnic_lib).
- 코드 생성(신규 provider): `cd picnic_lib && dart run build_runner build --delete-conflicting-outputs`.
- l10n: `flutter gen-l10n`(picnic_lib).
- 수동: 하단탭 4개, 홈 4섹션, 종류 탭 스와이프 + 상태 드롭다운 기본 진행중 + 재진입 리셋, 미디어 6개. **PIC CHART/SPOTLIGHT 탭은 데이터 태깅 전까지 빈 목록(정상).** 마이그레이션 불필요라 즉시 실행 가능.

## 7. 오픈 이슈 (PRD상 미확정 — 그대로 둠)
- 홈 진행중 카드 최종 비율/텍스트 배치.
- 미디어 최종 레이아웃(본 구현은 가로 스크롤로 확정).
- 종류 탭이 매우 많을 때 탭 폭/스크롤 UX 세부 정책.

## 8. 리스크
- persist 인덱스 시프트로 재실행 시 잘못된 탭 진입 → 진입 시 홈(0) 고정/클램프로 방어.
- `top_menu`/`portal`은 vote 외 포탈에도 공유 → `showTopMenu` 게이팅으로 vote 대상 화면만 변경, 회귀 주의.
- 신규 area(pic-chart/spotlight) 데이터 태깅 전까지 해당 탭 빈 목록 — 빈 상태 UI(`VoteNoItem`) 필요.
- 기존 `AreaSelector`/`appSettingProvider.area` 흐름 제거 시 다른 화면(pic list 등) 회귀 없는지 확인.

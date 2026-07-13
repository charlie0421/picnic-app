# Picnic 홈/투표 UI 개편 v2.2 Implementation Plan (rev2 — area 재활용)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** picnic-app 홈/투표 화면을 PRD v2.2대로 개편 — 하단탭(홈/투표/미디어/상점)·상단 헤더 정리, 홈 요약 허브 신설, 투표 페이지를 종류탭+상태필터 구조로 재구성. 투표 종류는 **기존 `area` 필드 재활용**(백엔드 변경 없음).

**Architecture:** 투표 종류 탭은 앱 const config(라벨+area코드)로, 기존 `AsyncVoteList`의 `area` 서버 필터(`.contains('areas',[area])`)를 그대로 사용한다 — provider/모델 변경 없음. 홈은 새 `HomePage`(배너/대표투표/리워드/미디어6), 대표투표는 기존 `asyncVoteListProvider`(active, limit 1) 재사용. 네비게이션은 data-driven `NavigationConfigs` 수정, 헤더 흰색 스트립 제거는 페이지가 `settingNavigation(showTopMenu:false)` 호출로 처리.

**Tech Stack:** Flutter, Riverpod(riverpod_generator `@riverpod`), Freezed, Supabase(supabase_flutter), flutter_screenutil, gen-l10n(ARB).

## Global Constraints

- 작업트리: `~/Repositories/picnic-app-home-vote-ui` (브랜치 `feat/home-vote-ui-redesign`). **단일 레포, 백엔드 스키마 변경 없음.**
- 투표 종류 탭 = 앱 const config `[('PICNIC','kpop'),('PIC CHART','pic-chart'),('MUSICAL','musical'),('SPOTLIGHT','spotlight')]`. 라벨 영어 리터럴. **provider/모델/vote_type 테이블 신설 금지**(area 재활용).
- 신규 area(pic-chart/spotlight)는 데이터 태깅 사항 — 코드 대상 아님. 태깅 전 해당 탭 빈 목록(정상) → `VoteNoItem` 빈 상태.
- 코드 생성물은 `picnic_lib/lib/generated/providers/...` — `part '../../generated/providers/...'` 상대경로 규칙. 1회 생성: `cd picnic_lib && dart run build_runner build --delete-conflicting-outputs`.
- 테스트는 `picnic_lib`에서: `cd picnic_lib && flutter test <path>`. Supabase는 `setupMockSupabase({...})`(`test/helpers/mock_supabase.dart`), provider는 `ProviderContainer()` + `container.read(xProvider.future)`, 위젯은 `buildTestApp(...)` + `initTestColors()`.
- l10n: 새 키는 `app_en.arb`(템플릿)+`app_ko.arb`에만, `flutter gen-l10n`(picnic_lib) 재생성 후 생성물 커밋. 비라틴 문자열을 다른 로케일에 직접 작성 금지.
- 상태 필터 기본값 **항상 진행중(active)**, 페이지 로컬 state, **재진입 시 저장 안 함**(PageStorage/persist 제거).
- 홈 대표 투표 = active 중 `stop_at ASC` 첫 1건(카드엔 rank-1). 공용 `VoteInfoCard` 수정 금지(홈은 별도 카드). 궁합/PIC/커뮤니티 포탈 코드·딥링크 삭제 금지(상단 진입점만 제거).
- 커밋: Conventional Commits, 끝에 `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`.

---

## File Structure

**신규**
- `picnic_lib/lib/presentation/providers/latest_media_provider.dart` — `asyncLatestMediaProvider`(홈 미디어 6).
- `picnic_lib/lib/presentation/pages/vote/home_page.dart` — 신규 `HomePage`(홈 탭).
- `picnic_lib/lib/presentation/widgets/vote/reward_list_section.dart` — 리워드 가로 리스트 재사용 위젯.
- `picnic_lib/lib/presentation/widgets/vote/home_featured_vote_card.dart` — 홈 전용 rank-1 카드.
- `picnic_lib/lib/presentation/widgets/vote/latest_media_section.dart` — 홈 미디어 가로 캐러셀.

**수정**
- `picnic_lib/lib/presentation/pages/vote/vote_list_page.dart` — 종류 탭 config + 상태 드롭다운, `showTopMenu:false`.
- `picnic_lib/lib/data/models/navigator/navigation_configs.dart` — vote 포탈 탭 재정의(홈 추가/커뮤니티 제거).
- `picnic_app/lib/bottom_navigation_menu.dart` — votePages 동기화(vestigial 정합).
- `picnic_app/lib/presentation/screens/portal.dart` — Vote/GoongHap 버튼 + 출석체크 제거.
- `picnic_lib/lib/l10n/app_en.arb`, `app_ko.arb` — `label_home_current_vote`.

---

## Task 1: `asyncLatestMediaProvider` (홈 미디어 6)

**Files:**
- Create: `picnic_lib/lib/presentation/providers/latest_media_provider.dart`
- Test: `picnic_lib/test/presentation/providers/latest_media_provider_test.dart`

**Interfaces:**
- Produces: `asyncLatestMediaProvider` → `Future<List<VideoInfo>>` — `media` 테이블 `id DESC` 최신 6.
- Consumes: `VideoInfo`(기존 모델).

- [ ] **Step 1: provider 작성** — `latest_media_provider.dart`

썸네일 파생은 `vote_media_list_page.dart` `_fetch`와 동일 규칙(YouTube URL).

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

## Task 2: `RewardListSection` 위젯 추출

**Files:**
- Create: `picnic_lib/lib/presentation/widgets/vote/reward_list_section.dart`

**Interfaces:**
- Produces: `RewardListSection()` — `vote_home_page.dart` `_buildRewardList`(L302-432)와 동일한 가로 리워드 리스트를 독립 위젯으로.

- [ ] **Step 1: 위젯 작성** — `reward_list_section.dart`

`vote_home_page.dart` L302-432 `_buildRewardList`의 `Column(...)` 반환부(제목 `label_vote_reward_list` + 가로 `ListView.builder` height 100 / item 120×100 + `showRewardDialog` 탭 + loading Shimmer + error)를 그대로 `ConsumerWidget.build`로 이식.

```dart
class RewardListSection extends ConsumerWidget {
  const RewardListSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncRewardListState = ref.watch(asyncRewardListProvider);
    return Column(
      children: [
        // ↓ vote_home_page.dart:302-432 의 Column children 를 그대로 이식
        //   (제목 + asyncRewardListState.when(data/loading/error))
      ],
    );
  }
}
```

import: `reward_list_provider.dart`, `reward.dart`, `common/picnic_cached_network_image.dart`, `dialogs/reward_dialog.dart`, `widgets/error.dart`, `l10n.dart`(`getLocaleTextFromJson`), `l10n/app_localizations.dart`, `ui/style.dart`, `flutter_screenutil`, `shimmer`, `flutter_riverpod`. `_rewardListKey`는 생략(홈 새로고침은 `ref.invalidate`로).

- [ ] **Step 2: 분석**

Run: `cd picnic_lib && flutter analyze lib/presentation/widgets/vote/reward_list_section.dart`
Expected: No issues.

- [ ] **Step 3: Commit**

```bash
git add picnic_lib/lib/presentation/widgets/vote/reward_list_section.dart
git commit -m "refactor(home): extract RewardListSection for reuse on home"
```

---

## Task 3: `HomeFeaturedVoteCard` (홈 전용 rank-1 카드)

**Files:**
- Create: `picnic_lib/lib/presentation/widgets/vote/home_featured_vote_card.dart`
- Test: `picnic_lib/test/presentation/widgets/vote/home_featured_vote_card_test.dart`

**Interfaces:**
- Consumes: `VoteModel`, `VoteItemModel`, `CountdownTimer(endTime, status, onRefresh?)`, `ShareSection(onSave, onShare)`, `VoteStatus`.
- Produces: `HomeFeaturedVoteCard({required VoteModel vote})` — 제목 + rank-1 항목 + 남은시간 + 저장/공유. 낮은 높이.

- [ ] **Step 1: 카드 작성** — `home_featured_vote_card.dart`

구조: `RepaintBoundary(key: _globalKey)` 안에 [제목, `CountdownTimer(endTime: vote.stopAt!, status: VoteStatus.active)`, rank-1 항목(이미지+이름+표수)], 그 아래 `ShareSection(onSave: _handleSave, onShare: _handleShare)`. 저장/공유 핸들러는 **기존 `vote_info_card.dart`의 `_handleSaveImage`(L132-144)·`_handleShareToTwitter`(L146-168)와 동일한 `ShareUtils` 호출 패턴을 mirror**(실행 시 해당 파일을 열어 `ShareUtils.saveImage`/`ShareUtils.shareToSocial` 시그니처·RepaintBoundary GlobalKey 캡처 방식을 그대로 복제).

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

  void _handleSave() {/* mirror vote_info_card.dart:132-144 (ShareUtils.saveImage(_globalKey,...)) */}
  void _handleShare() {/* mirror vote_info_card.dart:146-168 (ShareUtils.shareToSocial(_shareKey,...)) */}
}
```

> 실행 시 `getLocaleTextFromJson`(l10n.dart), `PicnicCachedNetworkImage`, `ShareUtils`, `ui/style.dart`, `flutter_screenutil` import를 채우고, `ArtistModel.name`/`image`, `ArtistGroupModel.name`/`image` 실제 필드 타입을 `artist.dart`/`artist_group.dart`에서 확인해 맞춘다(`name`이 `Map<String,dynamic>`이면 `getLocaleTextFromJson`, `String`이면 직접).

- [ ] **Step 2: 분석**

Run: `cd picnic_lib && flutter analyze lib/presentation/widgets/vote/home_featured_vote_card.dart`
Expected: No issues.

- [ ] **Step 3: 위젯 스모크 테스트** — `home_featured_vote_card_test.dart`

`buildTestApp`로 항목 1개짜리 mock `VoteModel`을 넣어 제목·표수 렌더 확인. `initTestColors()` 선행. (mock VoteModel은 `test/helpers/factories/` 또는 인라인 `VoteModel(...)` 생성.)

- [ ] **Step 4: 테스트 실행**

Run: `cd picnic_lib && flutter test test/presentation/widgets/vote/home_featured_vote_card_test.dart`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add picnic_lib/lib/presentation/widgets/vote/home_featured_vote_card.dart picnic_lib/test/presentation/widgets/vote/home_featured_vote_card_test.dart
git commit -m "feat(home): add home-only rank-1 featured vote card"
```

---

## Task 4: `LatestMediaSection` (홈 미디어 가로 캐러셀)

**Files:**
- Create: `picnic_lib/lib/presentation/widgets/vote/latest_media_section.dart`

**Interfaces:**
- Consumes: `asyncLatestMediaProvider`(Task 1), `VideoInfo`, `nav_media` 라벨.
- Produces: `LatestMediaSection()` — 리워드와 동일 규격(height 100, item 120×100) 가로 캐러셀. 탭 시 유튜브 오픈.

- [ ] **Step 1: 위젯 작성** — `latest_media_section.dart`

썸네일=`VideoInfo.thumbnailUrl`, 제목=`getLocaleTextFromJson(item.title)`. 탭 시 `vote_media_list_page.dart`의 `_launchVideoUrl` 패턴(youtube URL 실행, `url_launcher`)을 mirror. 섹션 제목은 `AppLocalizations.of(context).nav_media`(기존 키).

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
    // mirror vote_media_list_page.dart _launchVideoUrl (vnd.youtube://watch?v=… 또는 item.videoUrl, url_launcher)
  }
}
```

import: `latest_media_provider.dart`, `video_info.dart`, `common/picnic_cached_network_image.dart`, `l10n.dart`, `l10n/app_localizations.dart`, `ui/style.dart`, `flutter_screenutil`, `url_launcher`, `flutter_riverpod`.

- [ ] **Step 2: 분석**

Run: `cd picnic_lib && flutter analyze lib/presentation/widgets/vote/latest_media_section.dart`
Expected: No issues.

- [ ] **Step 3: Commit**

```bash
git add picnic_lib/lib/presentation/widgets/vote/latest_media_section.dart
git commit -m "feat(home): add latest-6 media horizontal carousel section"
```

---

## Task 5: `HomePage` 조립 + l10n 키

**Files:**
- Create: `picnic_lib/lib/presentation/pages/vote/home_page.dart`
- Modify: `picnic_lib/lib/l10n/app_en.arb`, `app_ko.arb`
- Test: `picnic_lib/test/presentation/pages/vote/home_page_test.dart`

**Interfaces:**
- Consumes: `CommonBanner`, `asyncVoteListProvider`(대표투표 재사용), `HomeFeaturedVoteCard`(Task 3), `RewardListSection`(Task 2), `LatestMediaSection`(Task 4).
- Produces: `HomePage()` — 홈 탭(index 0). `settingNavigation(showTopMenu:false)`로 흰색 스트립 제거.

- [ ] **Step 1: l10n 키 추가**

`app_en.arb`: `"label_home_current_vote": "Current Vote",`
`app_ko.arb`: `"label_home_current_vote": "현재 진행중인 투표",`

- [ ] **Step 2: l10n 재생성**

Run: `cd picnic_lib && flutter gen-l10n`
Expected: `app_localizations*.dart`에 `label_home_current_vote` getter 추가.

- [ ] **Step 3: HomePage 작성** — `home_page.dart`

대표 투표는 `asyncVoteListProvider(1, 1, 'id', 'DESC', 'all', status: VoteStatus.active, category: VoteCategory.all)`(active 브랜치가 `stop_at ASC` 정렬 → 첫 1건 = 곧 종료).

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
    final featured = ref.watch(asyncVoteListProvider(
      1, 1, 'id', 'DESC', 'all',
      status: VoteStatus.active,
      category: VoteCategory.all,
    ));
    return RefreshIndicator(
      color: AppColors.primary500,
      backgroundColor: Colors.white,
      onRefresh: () async {
        ref.invalidate(asyncBannerListProvider(location: 'vote_home'));
        ref.invalidate(asyncRewardListProvider);
        ref.invalidate(asyncLatestMediaProvider);
        ref.invalidate(asyncVoteListProvider(
          1, 1, 'id', 'DESC', 'all',
          status: VoteStatus.active, category: VoteCategory.all,
        ));
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
            data: (votes) => votes.isEmpty
                ? const SizedBox.shrink()
                : HomeFeaturedVoteCard(vote: votes.first),
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

import: `common_banner.dart`, `vote_list_provider.dart`, `home_featured_vote_card.dart`, `reward_list_section.dart`, `latest_media_section.dart`, `banner_list_provider.dart`, `reward_list_provider.dart`, `latest_media_provider.dart`, `navigation_provider.dart`, `route_aware_mixin.dart`, `vote_card_skeleton.dart`, `l10n/app_localizations.dart`, `ui/style.dart`, `flutter_screenutil`, `enums.dart`, `flutter_riverpod`.

- [ ] **Step 4: 분석**

Run: `cd picnic_lib && flutter analyze lib/presentation/pages/vote/home_page.dart`
Expected: No issues.

- [ ] **Step 5: 위젯 테스트** — `home_page_test.dart`

`buildTestApp(const HomePage())` + `setupMockSupabase({'banner':[], 'reward':[], 'vote':[], 'media':[]})` → 빈 상태 크래시 없이 렌더. `initTestColors()` 선행.

- [ ] **Step 6: 테스트 실행**

Run: `cd picnic_lib && flutter test test/presentation/pages/vote/home_page_test.dart`
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add picnic_lib/lib/presentation/pages/vote/home_page.dart picnic_lib/lib/l10n/app_en.arb picnic_lib/lib/l10n/app_ko.arb picnic_lib/lib/l10n/app_localizations*.dart picnic_lib/test/presentation/pages/vote/home_page_test.dart
git commit -m "feat(home): assemble HomePage (banner, featured vote, rewards, latest media)"
```

---

## Task 6: 투표 페이지 재구성 — 종류 탭(area) + 상태 드롭다운

**Files:**
- Modify: `picnic_lib/lib/presentation/pages/vote/vote_list_page.dart`
- Test: `picnic_lib/test/presentation/pages/vote/vote_list_page_tabs_test.dart`

**Interfaces:**
- Consumes: 기존 `VoteList(status, category, area, {portal})`, 기존 `label_tabbar_vote_active/end/upcoming`, `label_vote_screen_title`.
- Produces: 종류 탭(const config, area 필터) + 상태 드롭다운(기본 active, 미저장) UI. `showTopMenu:false`.

- [ ] **Step 1: `_updateNavigation`에서 흰색 스트립 제거**

`_VoteListPageState._updateNavigation`의 `showTopMenu: true,` → `showTopMenu: false,`.

- [ ] **Step 2: `_VoteListPageState` 단순화**

기존 `_tabController`/area watch/`_initializeTabController`/`ValueKey('vote_list_${area}_...')` 제거. build는 admin 여부만 계산해 `VoteListContent(key: ValueKey('vote_list_$_isAdmin'), isAdmin: _isAdmin)` 반환. `appSettingProvider`/`area` import 제거.

- [ ] **Step 3: 종류 탭 config + `_VoteListContentState` 재작성**

파일 하단(또는 상단)에 const config 정의:

```dart
class _VoteTab {
  final String label;
  final String area;
  const _VoteTab(this.label, this.area);
}

const List<_VoteTab> _voteTabs = [
  _VoteTab('PICNIC', 'kpop'),
  _VoteTab('PIC CHART', 'pic-chart'),
  _VoteTab('MUSICAL', 'musical'),
  _VoteTab('SPOTLIGHT', 'spotlight'),
];
```

`_VoteListContentState` 교체:

```dart
class _VoteListContentState extends ConsumerState<VoteListContent>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  VoteStatus _status = VoteStatus.active; // 기본 진행중, 미저장

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _voteTabs.length, vsync: this);
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
        // 페이지 타이틀 (흰색 스트립 제거로 본문에서)
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8),
          alignment: Alignment.centerLeft,
          child: Text(
            AppLocalizations.of(context).label_vote_screen_title,
            style: getTextStyle(AppTypo.title18B, AppColors.grey900),
          ),
        ),
        // 종류 탭 (가로 스크롤 + 스와이프)
        SizedBox(
          height: 48,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorWeight: 3,
            tabs: _voteTabs.map((t) => Tab(text: t.label)).toList(),
          ),
        ),
        // 상태 필터 드롭다운
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8),
          child: Align(
            alignment: Alignment.centerRight,
            child: DropdownButton<VoteStatus>(
              value: _status,
              onChanged: (v) {
                if (v != null) setState(() => _status = v);
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
            children: _voteTabs
                .map((t) => VoteList(
                      _status,
                      VoteCategory.all,
                      t.area,
                      key: ValueKey('votelist_${t.area}_${_status.name}'),
                      portal: VotePortal.vote,
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}
```

import 정리: `flutter_screenutil`, `ui/style.dart` 추가; `logger`/`PageStorage`/`app_setting_provider`/`RouteAwareStateMixin`(Content쪽) 등 미사용 제거. `ValueKey`로 status 변경 시 `VoteList`가 새로 생성돼 재조회됨.

- [ ] **Step 4: 분석**

Run: `cd picnic_lib && flutter analyze lib/presentation/pages/vote/vote_list_page.dart`
Expected: No issues.

- [ ] **Step 5: 위젯 테스트** — `vote_list_page_tabs_test.dart`

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
    setupMockSupabase({'vote': []});
  });
  tearDown(() => tearDownMockSupabase());

  testWidgets('renders 4 vote-type tabs and defaults status to active', (tester) async {
    await tester.pumpWidget(buildTestApp(const VoteListContent(isAdmin: false)));
    await tester.pumpAndSettle();

    expect(find.text('PICNIC'), findsOneWidget);
    expect(find.text('PIC CHART'), findsOneWidget);
    expect(find.text('MUSICAL'), findsOneWidget);
    expect(find.text('SPOTLIGHT'), findsOneWidget);

    final active = AppLocalizations.of(tester.element(find.byType(VoteListContent)))
        .label_tabbar_vote_active;
    expect(find.text(active), findsWidgets); // 드롭다운 기본값
  });
}
```

- [ ] **Step 6: 테스트 실행**

Run: `cd picnic_lib && flutter test test/presentation/pages/vote/vote_list_page_tabs_test.dart`
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add picnic_lib/lib/presentation/pages/vote/vote_list_page.dart picnic_lib/test/presentation/pages/vote/vote_list_page_tabs_test.dart
git commit -m "feat(vote): rebuild vote page with vote-type (area) tabs and status dropdown"
```

---

## Task 7: 하단 탭바 재구성 (홈 추가 / 커뮤니티 제거)

**Files:**
- Modify: `picnic_lib/lib/data/models/navigator/navigation_configs.dart`
- Modify: `picnic_app/lib/bottom_navigation_menu.dart`

**Interfaces:**
- Consumes: `HomePage`(Task 5), `VoteListPage`(Task 6).
- Produces: vote 포탈 탭 = 홈(0,HomePage)/투표(1,VoteListPage)/미디어(2)/상점(3).

- [ ] **Step 1: `navigation_configs.dart` vote pages 교체**

L21-50 `pages: const [...]`를 아래로 교체. import `home_page.dart`, `vote_list_page.dart` 추가. `community_home_page.dart` import는 `PortalType.community` 정의에서 계속 쓰이므로 **유지**.

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

L47-76 `votePages`를 위와 동일 4개(홈/투표/미디어/상점)로 교체. import `home_page.dart`, `vote_list_page.dart` 추가, `pic_chart_page.dart`가 미사용이면 제거.

- [ ] **Step 3: 진입 인덱스 홈(0) 방어**

`navigation.dart`의 저장 인덱스 로드 지점에서 `getPageWidget(vote, index)`가 null이면/범위 밖이면 0으로 폴백하는지 확인. 필요 시 로드 시 `index.clamp(0, pages.length-1)` 적용(구 저장값이 새 4탭 범위 내이므로 대체로 무해).

- [ ] **Step 4: 분석**

Run: `cd picnic_lib && flutter analyze lib/data/models/navigator/navigation_configs.dart` 및 `cd picnic_app && flutter analyze lib/bottom_navigation_menu.dart`
Expected: No issues (미사용 import 0).

- [ ] **Step 5: Commit**

```bash
git add picnic_lib/lib/data/models/navigator/navigation_configs.dart picnic_app/lib/bottom_navigation_menu.dart
git commit -m "feat(nav): replace community tab with home tab in vote portal"
```

---

## Task 8: 상단 헤더 정리 (Vote/GoongHap 버튼 + 출석체크 제거)

**Files:**
- Modify: `picnic_app/lib/presentation/screens/portal.dart`

**Interfaces:**
- Produces: 상단 AppBar에서 Vote/GoongHap 포탈 버튼·출석체크 제거. 프로필(leading)·알림(TopRightNotifications)·민트 AppBar 유지. 관리자용 PIC/novel 스위처(L109-122)는 유지.

- [ ] **Step 1: title에서 Vote/GoongHap PortalMenuItem 제거**

L107-108 두 줄 삭제:

```dart
                    const PortalMenuItem(portalType: PortalType.vote),
                    const PortalMenuItem(portalType: PortalType.goongHap),
```

- [ ] **Step 2: actions에서 출석체크 제거**

L127-136 actions를 알림만 남기도록:

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
Expected: No issues.

- [ ] **Step 4: Commit**

```bash
git add picnic_app/lib/presentation/screens/portal.dart
git commit -m "feat(header): remove vote/goonghap portal buttons and attendance from top bar"
```

---

## Task 9: 통합 분석 + 회귀 + 수동 스모크

**Files:** (없음 — 검증)

- [ ] **Step 1: 전체 정적 분석**

Run: `cd picnic_lib && flutter analyze` 그리고 `cd picnic_app && flutter analyze`
Expected: 신규/수정 파일에서 error 0.

- [ ] **Step 2: 변경 관련 테스트 일괄 실행**

Run:
```bash
cd picnic_lib && flutter test \
  test/presentation/providers/latest_media_provider_test.dart \
  test/presentation/widgets/vote/home_featured_vote_card_test.dart \
  test/presentation/pages/vote/home_page_test.dart \
  test/presentation/pages/vote/vote_list_page_tabs_test.dart
```
Expected: 전부 PASS.

- [ ] **Step 3: 수동 실행 (실기기/에뮬)** — 마이그레이션 불필요, 즉시 가능

Run: `cd picnic_app && flutter run --dart-define=DISABLE_VM_CHECK=true`
체크리스트:
- 하단탭 홈/투표/미디어/상점 4개(커뮤니티 없음).
- 상단: 프로필·알림만. Vote/GoongHap·출석체크·별사탕·ALL/K-POP 드롭다운 없음(흰색 스트립 사라짐).
- 홈: 배너 → "현재 진행중인 투표"(rank-1, 남은시간/저장/공유) → 리워드 가로 → 미디어 최신6 가로.
- 투표 탭: 종류 탭 PICNIC/PIC CHART/MUSICAL/SPOTLIGHT(가로 스크롤·스와이프) + 상태 드롭다운(기본 진행중). 재진입 시 다시 진행중. **PIC CHART/SPOTLIGHT는 데이터 태깅 전이라 빈 목록(정상).**
- PICNIC 탭에 기존 kpop 투표, MUSICAL 탭에 musical 투표 노출 확인.
- 미디어/상점 탭 정상.

- [ ] **Step 4: 회귀 확인 — 다른 화면**

`AreaSelector`/`appSettingProvider.area` 흐름 변경이 pic list 등 다른 화면을 깨지 않았는지 확인. 필요 시 관련 테스트 실행.

---

## Self-Review Notes

- Spec 대비: 종류 탭(area 재활용)·상태 드롭다운(Task 6), 홈 조립(Task 1~5), 탭바(Task 7), 헤더(Task 8) 전부 커버.
- vote_type 관련 태스크(테이블/모델/provider/스레딩)는 area 재활용으로 **삭제**. VoteModel/vote_list_provider 무변경.
- 대표 투표는 기존 `asyncVoteListProvider`(active, limit 1) 재사용 — 신규 provider 없음.
- `VoteInfoCard` 미변경, 홈은 `HomeFeaturedVoteCard`.
- 상태 미저장: `_status` 로컬, PageStorage 제거. area 필터는 탭이 넘기는 `t.area`로.
- 신규 area(pic-chart/spotlight)는 데이터 태깅 사항 — 코드 아님. 빈 탭은 `VoteNoItem`.
- Placeholder(`mirror ...`)는 기존 프로덕션 코드(file:line 명시)를 복제하라는 지시 — 실행 시 해당 파일 확인.

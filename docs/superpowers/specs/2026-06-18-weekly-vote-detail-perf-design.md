# 위클리 투표 상세 리스트 성능 튜닝 — 설계 스펙

- 날짜: 2026-06-18
- 대상: `picnic_lib` — 투표 상세 페이지 순위 리스트 (`presentation/pages/vote/vote_detail_page.dart`)
- 브랜치/워크트리: `refactor/vote-detail-perf` / `~/Repositories/picnic-app-vote-detail-perf`
- 상태: 설계 승인됨(범위 = Tier 0+A+B+C). 구현 전 스펙 리뷰 단계.
- 출고: Dart-only → Shorebird OTA 패치 가능 (네이티브 변경 없음)

## 1. 문제

증상(사용자 보고): "위클리 투표(상세 순위 리스트)에서 아티스트 이미지가 느리게 뜨고, 스크롤이 느리고, 전반적으로 버벅인다." 위클리 투표(vote id 255)는 항목이 ~1,461개.

다관점(5-lens) 코드 조사로 확인한 **근본 원인 3가지**:

### R1 — 1초 리빌드 폭풍 (가장 큰 누락)
- 상세 페이지에 실시간 채널이 아니라 `Timer.periodic(1s)` 가 있음 (`vote_detail_page.dart:148-170`).
- 매초 `refreshVoteTotals` (`vote_detail_provider.dart:127-165`)가:
  - `totalsMap`에 있는 **모든 항목을 무조건 `copyWith`** (`:149-151`) → 1,461개 새 객체/초 (안 바뀐 것도).
  - 다시 `..sort` (`:155-159`) 후 `state = AsyncValue.data(updatedList)` (`:161`) → **리스트 identity가 매초 변경**.
- `_buildVoteItemList`가 `ref.watch(asyncVoteItemListProvider)` (`:682-687`) → state identity 변경 → `.when(data:)`가 **매초 재실행 → 전체 subtree rebuild** (idle에도, fling 중에도).
- fling이 초 경계와 겹치면 (1,461 copyWith + sort + refilter + rebuild)와 충돌 = 스크롤 버벅의 큰 축.

### R2 — 이미지 재로딩 폭풍 (라이브 투표의 "느린 이미지" 핵심)
- 이미지 위젯 key에 순위가 포함됨: `_buildNetworkImage` `ValueKey('image_${itemId}_rank_$actualRank')` (`:1079-1080`), `_buildImageWithFallback` `'cached_image_${imageUrl}_rank_$actualRank'` (`:1111`).
- 순위가 바뀌면 key가 바뀌어 **이미지 State가 dispose+재생성 → 동일 사진을 다시 resolve/재로드**. 라이브 투표는 순위가 계속 흔들리므로 **지속적 재로딩 폭풍**.
- 이미지 자체는 이미 서버 리사이즈 썸네일(cdn.picnic.fan — CloudFront + 커스텀 리사이저, Imgix 아님. 실측상 w/h/q만 동작, dpr·fm은 무시됨, `picnic_cached_network_image.dart:668/696-752`)이라 "원본이 커서"가 아님.
  - (2026-08-07 추가 발견, 별도 후속 과제) 서버 리사이즈는 물리 px 로 정확하지만, `memCacheWidth/Height`(→ Flutter `ResizeImage`)는 논리 px 에 배율만 곱해 DPR 을 반영하지 않는다 — 두 경로의 단위 불일치로 고DPR 기기에서 디코드 해상도가 화면 요구보다 낮아 흐려질 수 있다. 수정하려면 호출부(44곳 중 10곳 이상이 memCacheWidth 를 명시적으로 넘김) 전반의 메모리 사용량이 최대 DPR² 배 늘 수 있어 실기기 검증 없이 단독 수정하지 않았다. 근거: `picnic_cached_network_image.dart` `_computeCacheDimension` 주석.
- 추가로 `PicnicCachedNetworkImage`의 무거운 부속: per-row `VisibilityDetector` (`:573`), **전역 8-슬롯 동시로드 세마포어**(`_maxConcurrentLoads=8` `:126`, `_currentLoadingCount` `:298`)가 오히려 직렬화, 저대역폭 휴리스틱(`:646`)이 스크롤 중 cacheKey를 뒤집어 캐시 미스.

### R3 — 가상화 무력화 (목록 전체 eager build)
- `SliverToBoxAdapter > 테두리 Container > ListView.builder(shrinkWrap:true, NeverScrollableScrollPhysics)` (`:735-826`, shrinkWrap `:759`).
- shrinkWrap이 전체 높이 측정을 위해 모든 행을 빌드 → ~1,461행 + 이미지 위젯이 한꺼번에 생성. (`cacheExtent:200` `:763`는 무의미)
- (참고) #54에서 목록 카드 페이지의 over-fetch는 이미 수정. 이건 상세 페이지로 별개 표면.

> 라이브 투표 + 구형 기기에서 R1·R2·R3가 동시에 작용해 체감 버벅을 만든다.

## 2. 목표 / 비목표

**목표**
- 위클리 투표 상세 리스트에서 부드러운 스크롤(프레임 ~16ms), 보이는 근처 이미지만 점진 로드, idle 시 불필요한 rebuild 0.
- 동작 보존: 전체 순위 리스트 + 인리스트 검색 + 순위 변동 하이라이트 애니메이션은 **그대로**.
- Dart-only(Shorebird 패치 가능).

**비목표 (확정 제외)**
- 페이지네이션/상위 N + 더보기 (전체 순위 UX 훼손).
- Impeller/SkSL 워밍업 (Flutter 3.41.4에서 Impeller가 이미 기본; 네이티브라 패치 불가).
- 정렬/순위 계산의 isolate 이관 (n=1461 정렬은 sub-ms; 직렬화 비용이 더 큼).
- 행 위젯 비주얼 재디자인(레이아웃 픽셀 변경 없음).

## 3. 설계 (Tier별)

### Tier 0 — 측정 먼저 (필수)
구현 전/후 동일 지표로 효과를 입증한다. 추측 금지.
- profile 모드 + 퍼포먼스 오버레이로 "손 뗀 상태에서 매초 build 스파이크"를 먼저 재현.
- `VoteItemWidget.build`에 임시 카운터(또는 DevTools rebuild 통계)로 idle 시 build 횟수 측정.
- 위클리 투표(id 255)로 스크롤 시 UI 스레드/래스터 스레드 프레임타임, 이미지 로드 타이밍 관찰.
- 각 Tier 적용 후 같은 지표 재측정 → 어떤 수정이 무엇을 움직였는지 기록.

### Tier A — 1초 폭풍 차단 (R1)
- **A1. `refreshVoteTotals` diff-gate** (`vote_detail_provider.dart:144-161`)
  - 새 totals를 현재 state와 비교해 **실제로 바뀐 항목이 없으면 state 재할당하지 않고 `return`** (identity 불변 → `ref.watch` 미발화 → rebuild 0).
  - 바뀐 항목만 `copyWith`, 안 바뀐 항목은 **기존 객체 identity 재사용**.
  - 정렬 결과 순서가 동일하면 새 리스트도 동일 식별로 취급.
- **A2. 스크롤 중 타이머 일시정지** (`:148-170`)
  - `ScrollController`/`ScrollNotification`으로 `_isScrolling` 플래그 → 타이머 본문이 기존 `_isRefreshingItems`/`_isSaving` 가드와 동일하게 early-return. 스크롤이 멈추면 1회 refresh.
  - (선택) 종료/예정 투표(`isEnded`/`isUpcoming`, `:424-425`)는 갱신 간격을 2~3s로 완화.

### Tier B — 가상화 + 이미지 재로딩 (R2·R3)
- **B1. 네이티브 가상화 + 고정 extent** (`:735-826` 교체)
  - `SliverToBoxAdapter>Container>ListView(shrinkWrap)` → `DecoratedSliver(테두리) > SliverPadding > **SliverFixedExtentList**`.
  - 행 높이가 균일(`vote_item_widget.dart:56-58` minHeight 55, 이름 RichText maxLines:1 `:91-92`, 카운트 20px 고정 + 하단 16 패딩)이므로 **고정 itemExtent** 사용 → 자식 레이아웃 측정 생략(가변 delegate보다 결정적 승리). 행을 `SizedBox(height: <측정값>)`로 확정.
  - 기존 델리게이트 옵션 보존: `addAutomaticKeepAlives:false`, `addRepaintBoundaries`는 B-C2와 함께 정리.
  - **검색창 픽셀 패리티**: 현재 검색창은 컨테이너 상단 테두리에 겹친 Stack 오버레이(`_buildSearchBox`). 새 구조에서 동일 위치로 재현(테두리 그룹 내 상단 sliver 또는 오버레이). **UI 전후 동일**해야 하며 스크린샷으로 검증.
  - CustomScrollView(`:464`) `cacheExtent`를 ~1화면(약 700~1000px)으로, 제거되는 내부 ListView의 `cacheExtent:200` 삭제.
- **B2. 이미지 key에서 순위 제거** (`:1079-1080`, `:1111`)
  - 이미지 위젯 key/ cacheKey에서 `_rank_$actualRank` 제거 → 사진 내용은 순위와 무관하므로 순위 변동 시 재로드 대신 캐시된 프레임 재사용.
  - 순위 변동 **하이라이트 애니메이션은 별도 레이어에서 rank로 keying 유지** (동작 보존).
  - cacheKey를 **안정적인 최종 URL**로 고정 (WebP-race로 인한 jpg→webp cacheKey flip/재fetch 방지).
- **B3. 이 리스트 한정 이미지 기계장치 경량화** (`:1106-1118`)
  - `lazyLoadingStrategy:none` 으로 전환 — sliver 뷰포트가 이미 가시성 게이트라 per-row `VisibilityDetector`(`picnic_cached_network_image.dart:573`)는 불필요+per-frame 비용.
  - 전역 8-슬롯 세마포어/저대역폭 휴리스틱 우회(이 리스트의 작은 썸네일엔 직렬화가 해로움). 필요 시 thin `CachedNetworkImage`로 대체하되 **없을 때 기본 아이콘 fallback 보존**.

### Tier C — 폴리시
- **C1. `computeRanks`를 build 밖으로 + 정렬 생략** (`:691`, `vote_detail_helper.dart:12-34`)
  - `ref.listen(asyncVoteItemListProvider, ...)`로 **데이터가 실제 바뀔 때만 1회** 재계산(하이라이트/검색 setState에선 재계산 안 함). 기존 `_initializeRanks`로 초기값.
  - 데이터가 이미 (voteTotal, id) 내림차순 정렬돼 오므로 rank = index+1 + 동점 병합 **O(n) 1-pass** (2차 sort 제거). 기존 `VoteDetailHelper.areDataListsEqual`(`:37`)로 dedup.
- **C2. 행당 RepaintBoundary 3중 → 1개** (`:810`, `vote_item_widget.dart:40`, `:1079`)
  - 행 루트 1개만 유지, 내부 2개 제거 → 합성 레이어 수 감소.
- **C3. 썸네일 화질/dpr 캡** (`picnic_cached_network_image.dart:668`, `:628-643`)
  - 39px 슬롯에 q=85는 과함 → q≈55, sub-50px 슬롯의 dpr 상한 ≈2.0 (3x/iPad over-fetch 방지). 쿼리 파라미터만 변경(Dart-only).
- **C4. fling-aware 이미지 디퍼 (마지막)** (`:1106`)
  - `Scrollable.recommendDeferredLoadingForContext(context)`로 빠른 fling 중 플레이스홀더, 멈추면 로드.
  - **A·B 적용 후에도 raster가 지배적일 때만** 도입 (측정-회의론 권고). lazyLoadingStrategy:none과 함께.

## 4. 동작 보존 요구사항 (반드시 유지)
- 전체 순위 리스트(전 항목) + 인리스트 검색 결과/동작 동일.
- 순위 변동 하이라이트(rank-up/down, 800ms) 애니메이션 동일.
- 라이브 갱신: 득표/순위 변화는 여전히 반영(diff-gate는 "변화 없을 때만" 생략).
- 검색창 위치/모양 픽셀 패리티(스크린샷 검증).
- 이미지 없는 항목의 기본 아이콘 fallback 유지.

## 5. 측정 & 검증
- 위클리 투표(id 255, ~1,461개)에서:
  - idle 시 build 스파이크가 사라졌는지(A), 보이는 행만 build 되는지(B1).
  - 순위 변동 시 이미지가 재로드되지 않는지(B2) — 네트워크/디코드 관찰.
  - 스크롤 프레임타임 ~16ms, 이미지 점진 로드.
- UI 전후 스크린샷 패리티(검색창 포함).
- 기존 `vote_detail_page` 관련 테스트 통과 + 가능 시 단위 테스트 추가(diff-gate 로직, rank=index 계산).
- 회귀: 라이브 갱신/하이라이트/검색이 그대로 동작하는지 수동 확인.

## 6. 리스크 & 완화
- **고정 extent 불일치** → 행 높이가 케이스별로 다르면 클리핑. 완화: 정확한 높이 측정 + maxLines:1 보장, 다양한 데이터로 확인.
- **diff-gate가 변화를 누락** → 라이브 갱신 멈춤. 완화: 보수적 비교(총계/순서), 변화 시 반드시 반영, 테스트.
- **이미지 기계장치 우회로 fallback/특수동작 상실** → 기본 아이콘/에러 처리 보존, 시각 회귀 확인.
- **검색창 재배치로 픽셀 차이** → 스크린샷 패리티 게이트.
- 변경 범위가 넓음 → Tier 순서대로 적용·측정, 각 Tier를 독립 커밋으로 분리(리뷰·롤백 용이).

## 7. 적용 순서 (측정 기반)
1. Tier 0 측정(기준선) → 2. A(폭풍 차단) → 3. B1(가상화+고정extent) → 4. B2(이미지 rank-key) → 5. B3(이미지 경량화) → 6. C1(rank 계산) → 7. C2(RepaintBoundary) → 8. C3(화질) → 9. C4(디퍼, 필요 시). 각 단계 후 재측정.

## 8. 롤아웃
- 전부 Dart-only → Shorebird OTA 패치로 출고 가능(릴리스 1.2.30+123001 대상). 정식 릴리스에도 자연 포함.
- 변경이 크므로 측정 결과(전/후 프레임·rebuild 수)를 PR에 첨부.

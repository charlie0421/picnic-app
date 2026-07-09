# 투표 상세 — 득표수 대신 점유율(%) 표시 + 2위 갭 말풍선

- 날짜: 2026-07-09
- 브랜치: `feat/vote-share-display`
- 워크트리: `~/Repositories/picnic-app-vote-share`
- 출처: rankitten PR #196 (`docs/handoff-2026-07-09-vote-list-display.html`)

## 목표

진행 중인 투표 상세 화면에서 후보의 **원시 득표수를 감추고 전체 대비 점유율(%)** 로 바꾼다.
2위 행에 한해 **"1위와 N표 차이!"** 말풍선을 진입 시 1회 띄웠다 자동으로 사라지게 한다.

## 범위

rankitten 핸드오프의 체크리스트를 picnic 구조에 맞춰 다시 잘랐다. picnic 에서 득표수를
사람에게 보여주는 곳은 네 군데이고 코드가 공유되지 않은 복사본이다. 그중 **하나만** 바꾼다.

| # | 위치 | 파일 | 결정 |
|---|---|---|---|
| ① | 투표 상세 리스트 행 | `vote_detail_page.dart` `_buildVoteCountContainer` | **변경** (진행 중 투표만) |
| ② | 공유/저장 캡처 이미지 Top-3 | 같은 파일 `_buildCaptureVoteList` | 현행 유지 — 종료 투표에서만 뜨므로 ①의 ended 분기를 타 자동으로 득표수 유지 |
| ③ | achieve 투표 상세 | `vote_detail_achieve_page.dart:801` | 현행 유지 |
| ④ | 목록 카드 Top-3 포디움 | `vote_info_card_vertical.dart:47` | 현행 유지 |

### ③을 제외한 이유

`vote_detail_achieve_page.dart:455` 는 `_buildAchieveItem(data[0]!)` 로 **아티스트 한 명만**
렌더한다. "전체 대비 share" 가 성립하지 않는다(항상 100%). 게다가 옆의 `_buildLevelItem`
사다리는 마일스톤을 **절대 득표수**(`isAchieved = voteTotal >= currentLevel`)로 칠하므로
행을 %로 가리면 "목표까지 몇 표 남았는지" 를 알 수 없게 된다.

### ④를 제외한 이유

포디움은 `if (status == VoteStatus.end)` 가드가 있어 **종료된 투표에서만** 득표수를 보인다.
진행 중엔 이미 숫자가 없다. "종료된 투표는 기존대로 득표수" 원칙과 충돌하므로 손대지 않는다.
결과적으로 종료 투표는 상세·포디움·캡처 이미지 세 곳 모두 득표수로 일관된다.

## 표시 규칙

분기는 `isEnded` 하나뿐이다. upcoming 은 별도 분기가 아니라 `total == 0` 에서 자연히 떨어진다.

```dart
isEnded ? NumberFormat('#,###').format(item.voteTotal)   // 현행 그대로
        : VoteDetailHelper.formatSharePercent(item.voteTotal, _totalVotes)
```

| 투표 상태 | 행 수치 |
|---|---|
| 진행 중 (`!isEnded`) | share % (동적 정밀도) |
| 예정 (`isUpcoming`) | 전원 0표 → `total == 0` → `—` (특수 분기 없음) |
| 종료 (`isEnded`) | 득표수 — 현행 `NumberFormat('#,###')` |

유지하는 것 (rankitten 은 지웠으나 picnic 은 유지):

- `VoteGainIndicator` 의 `+N` 팝. 원시 증분(표)을 노출하지만, 말풍선도 표 단위이므로 모순은 아니다.
- 순위 변동 배경 플래시 (파랑=상승, 빨강=하락). rankitten 이 지운 ▲▼ 델타는 picnic 에 애초에 없다.
- `AnimatedDigitWidget` 롤링. % 값에도 적용한다.

## 컴포넌트 1 — `VoteDetailHelper.formatSharePercent(int? votes, int total)`

유효숫자 2자리를 보장하되 소수 자릿수를 2~4로 클램프한다.

```
pct = votes / total * 100
decimals = (2 - floor(log10(pct)) - 1).clamp(2, 4)
```

| 입력 pct | 출력 |
|---|---|
| 35.1972 | `35.20%` |
| 0.1790 | `0.18%` |
| 0.0763 | `0.076%` |
| 0.0032 | `0.0032%` |
| `0 < pct < 0.0001` | `<0.0001%` |
| `votes == 0` 또는 `total <= 0` | `—` |

`votes` 가 null 이면 0으로 취급한다 (`VoteItemModel.voteTotal` 은 `int?`).

### 구현 함정 두 가지

1. **절삭 vs 반올림.** `AnimatedDigitWidget._formatNum` 은 `fractionList.take(fractionDigits)`
   로 소수를 **절삭**한다. 정적 `Text` 는 `toStringAsFixed` 로 반올림한다. 그대로 두면
   `35.199` 가 롤링 중엔 `35.19%`, 멈추면 `35.20%` 로 튄다.
   → 위젯에 넘기기 전에 `double.parse(pct.toStringAsFixed(decimals))` 로 미리 라운딩한다.

2. **자릿수 변화.** `decimals` 가 바뀌면(`0.18%` → `0.076%`) 소수점 위치가 밀려 롤링이 어그러진다.
   → `AnimatedDigitWidget` 에 `key: ValueKey(decimals)` 를 주어 깨끗이 재생성한다.

`enableSeparator: false`, `suffix: '%'`, `fractionDigits: decimals` 를 쓴다.

### 합계 계산

`VoteDetailHelper.sumVoteTotals(List<VoteItemModel?>)` 를 추가한다.
합계는 **검색 필터가 걸리지 않은 전체 리스트** 기준이다. `_VoteDetailPageState` 에 `int _totalVotes = 0;`
필드를 두고, `_buildVoteItemList` 의 `data` 콜백에서 `ListView.builder` 진입 전에 1회 계산해 담는다
(`_updateRanks(data)` 바로 옆). 1초 폴링마다 재계산되지만 int 덧셈 1500회는 무시할 수준이다.
`_buildVoteCountContainer` 는 이 필드를 읽는다 — 캡처 경로는 `isEnded` 분기를 타므로 `_totalVotes`
를 쓰지 않는다.

## 컴포넌트 2 — 갭 말풍선

### rankitten 트릭이 picnic 에서 깨지는 이유

핸드오프의 "1회 노출" 은 **위치 기반 State 매칭**(키 없는 `for` 루프)에 의존한다. picnic 은
`ListView.builder` + `ValueKey('vote_item_${item.id}')` 라서 State 가 *아이템*을 따라다닌다.
그대로 이식하면 세 가지로 깨진다.

1. **2위 주인이 바뀌면 재노출.** 새 2위 아이템은 새 State → `initState` 재실행.
   picnic 은 1초 폴링(rankitten 은 2초)이라 흔하다.
2. **스크롤 아웃 → 인 하면 재노출.** `ListView.builder` 가상화로 unmount/remount.
3. **2위 동점이면 말풍선이 2개.** `VoteDetailHelper.computeRanks` 는 competition ranking
   (1,2,2,4) 이라 동점자가 모두 rank 2 를 받는다. 핸드오프의 `rank != 2` 가드로는 못 막는다.

### 해결 — 말풍선 수명을 페이지가 소유

```dart
// _VoteDetailPageState
int? _gapTooltipItemId;        // 말풍선을 붙일 단 하나의 아이템 id
int  _gapTooltipGap = 0;       // 진입 시점 값으로 freeze — 폴링에 숫자가 흔들리지 않게
bool _gapTooltipDone = false;  // 한 번 끝나면 영구 래치
Timer? _gapTooltipLatch;
```

`VoteDetailHelper.pickGapTooltipTarget(items, ranks)` 가 대상을 **정확히 하나** 고르거나
`null` 을 반환한다.

```
rank2 = items where ranks[id] == 2
if (rank2.length != 1) return null          // 동점 2위 다수 → 미노출
gap = leaderVotes - rank2.single.voteTotal
if (gap <= 0) return null                    // 동점 → "0표 차이" 방지
return (itemId: rank2.single.id, gapVotes: gap)
```

페이지 쪽 추가 가드: `_gapTooltipDone`, `isEnded`, `isUpcoming`, `_isSaving`,
`_searchQuery.isNotEmpty` 중 하나라도 참이면 미노출.

첫 실데이터 프레임에서 1회만 계산하고, `addPostFrameCallback` 안에서 `setState` 한다
(build 중 setState 금지).

> 핸드오프의 `showGapTooltip: candidates.isNotEmpty` (플레이스홀더 가드) 는 picnic 에서
> 불필요하다. 조사 결과 picnic 에는 가짜 `VoteItemModel` 을 리스트에 넣는 경로가 없다.
> 스켈레톤은 순수 `Container`/`Shimmer` 이고, 페치 실패 시 provider 는 빈 리스트를 반환한다.
> 따라서 `data.isNotEmpty` 로 충분하다.

### 행 위젯 시그니처는 건드리지 않는다

`VoteItemWidget` / `VoteItemHighlightWidget` 에 파라미터를 추가하지 않는다. 페이지의
`_buildVoteItemWithHighlight` 가 반환값을 감싸기만 한다.

```dart
final row = searchQuery.isNotEmpty ? highlightWidget : voteItemWidget;
if (item.id != _gapTooltipItemId) return row;
return Stack(clipBehavior: Clip.none, children: [
  row,
  Positioned(
    top: -30, right: 10,
    child: _GapTooltip(
      text: l10n.text_vote_gap_behind_leader(NumberFormat('#,###').format(_gapTooltipGap)),
      onDismissed: _finishGapTooltip,
    ),
  ),
]);
```

이 덕분에 기존 위젯 테스트가 하나도 깨지지 않는다.

### `_GapTooltip` (신규 파일 `vote_gap_tooltip.dart`)

핸드오프 코드를 그대로 쓰되 색/타이포만 picnic 테마(`AppColors`, `getTextStyle`)로 바꾼다.

- 260ms 페이드+슬라이드 인 → 1s 유지 → 페이드아웃
- `AnimationStatus.dismissed` 리스너에서 `_gone = true` → `build` 가 `SizedBox.shrink()` 반환
  (트리에서 제거해 `IgnorePointer` 오버레이 잔존 방지)
- `CurvedAnimation` 은 `initState` 에서 1회 생성하고 `dispose` 에서 해제 (build 에서 만들면
  리빌드마다 컨트롤러에 리스너가 쌓인다)
- `ConstrainedBox(maxWidth: 240)` 으로 긴 로케일/큰 gap 의 화면 밖 넘침 방지
- `IgnorePointer` 로 행의 탭을 가로채지 않음
- `_TailPainter` 로 아래쪽 꼬리 삼각형
- **추가**: `onDismissed` 콜백. 페이드아웃 완료 시 페이지에 알린다.

### 안전망 타이머

위젯이 스크롤 아웃으로 dispose 되면 `onDismissed` 가 오지 않는다. 페이지에 2초짜리
`_gapTooltipLatch` 타이머를 함께 건다 (위젯 총 재생 시간 260+1000+260 = 1520ms).
둘 중 먼저 도달하는 쪽이 `_gapTooltipDone = true` 로 래치하고, 다른 쪽은 무시된다.
`dispose` 에서 타이머를 취소한다.

### 알려진 리스크 — 진입 즉시 재생

핸드오프대로 **화면 진입 시** 재생한다. picnic 상세 화면은 리스트 위에 메인 이미지 + 타이틀 +
기간 + 카운트다운 + 리워드 + 신청 버튼이 쌓여 있다. 게다가 `ListView.builder` 가
`shrinkWrap: true` 라 화면 밖 행도 즉시 빌드된다. 따라서 **메인 이미지가 큰 투표에서는
사용자가 스크롤하기 전에 말풍선이 다 재생되고 사라진다.**

수용한 리스크다. 실기기 확인 후 문제가 되면 `visibility_detector`(이미 `picnic_lib` 의존성)로
2위 행이 10% 노출될 때 발동하도록 바꾼다. 래치 구조는 그대로 재사용된다.

## l10n

키: `text_vote_gap_behind_leader` (picnic 은 snake_case 관례 — `text_vote_rank`,
`message_vote_is_ended`). placeholder `gap` 은 `String` 이며, 호출부에서
`NumberFormat('#,###')` 로 **미리 포맷한 문자열**을 넘긴다. picnic ARB 에는 intl `format`
메타데이터를 쓰는 키가 하나도 없어 숫자 포맷은 전부 호출부 책임이다.

템플릿은 `app_en.arb`. **키 누락을 막는 CI 게이트가 없다** — 빠뜨리면 조용히 영어로 폴백한다.
14개 로케일 전부에 넣는다.

| locale | 문구 |
|---|---|
| ko | `1위와 {gap}표 차이!` |
| en | `{gap} votes behind #1` |
| ja | `1位と{gap}票差！` |
| zh, zh_CN | `落后第 1 名 {gap} 票！` |
| zh_TW | `落後第 1 名 {gap} 票！` |
| es | `{gap} votos detrás del n.º 1` |
| th | `ตามหลังอันดับ 1 อยู่ {gap} โหวต!` |
| vi | `Kém hạng 1 {gap} phiếu!` |
| id | `{gap} suara di belakang #1` |
| bn, bn_BD | `১ম স্থান থেকে {gap} ভোট পিছিয়ে!` |
| fil | `{gap} na boto ang agwat sa #1!` |
| my | `ပထမနေရာထက် မဲ {gap} မဲ နောက်ကျနေသည်!` |

핸드오프 표에 있던 `pt` 는 picnic 로케일에 없다.
`bn` / `fil` / `my` 세 줄은 핸드오프에 없어 새로 작성한 초안이다. 머지 전 네이티브 검수를 권한다
(틀려도 빌드는 통과하므로 자동으로 잡히지 않는다).

## 테스트

`VoteGainIndicator` 를 지우지 않기로 해서 **기존 테스트 파손이 없다.** (지웠다면
`vote_gain_indicator_test.dart`, `vote_detail_page_test.dart`, `vote_detail_page_render_test.dart`
세 파일이 top-level import 때문에 컴파일 자체가 깨졌을 것이다.) 위젯 시그니처를 유지하므로
`vote_item_widget_test.dart` / `vote_item_highlight_widget_test.dart` 도 무사하다.

신규 테스트:

1. `VoteDetailHelper.formatSharePercent` — 경계값. `35.1972 → 35.20%`, `0.0763 → 0.076%`,
   `0.0032 → 0.0032%`, `votes=0 → —`, `total=0 → —`, `1/2891788 → <0.0001%`.
2. `VoteDetailHelper.pickGapTooltipTarget` — 2위 동점 → null, gap 0 → null, 1위 동점으로
   rank 2 부재 → null, 정상 케이스 1건.
3. `_GapTooltip` 위젯 테스트 — 순수 `MaterialApp`(ScreenUtil/Riverpod 없이) + `pumpAndSettle(1600ms)`
   후 `findsNothing`, `onDismissed` 1회 호출.

**`VoteDetailPage` 를 마운트한 채 `pumpAndSettle` 을 쓰면 안 된다.** 페이지의 1초 주기 타이머
때문에 영원히 settle 되지 않는다. 페이지 레벨 테스트가 필요하면 기존 render 테스트처럼
`tester.pump(Duration(seconds: 1))` + 예외 드레인 패턴을 쓴다.

## 변경 파일

| 파일 | 변경 |
|---|---|
| `picnic_lib/lib/presentation/pages/vote/vote_detail_helper.dart` | `formatSharePercent`, `pickGapTooltipTarget`, `sumVoteTotals` 추가 |
| `picnic_lib/lib/presentation/pages/vote/vote_detail_page.dart` | `_buildVoteCountContainer` ended/active 분기, 말풍선 오너십 상태, `Stack` 래핑 |
| `picnic_lib/lib/presentation/pages/vote/vote_gap_tooltip.dart` | 신규 — `_GapTooltip` + `_TailPainter` |
| `picnic_lib/lib/l10n/app_*.arb` × 14 | `text_vote_gap_behind_leader` |
| `picnic_lib/test/presentation/pages/vote/vote_detail_helper_test.dart` | group 2개 추가 |
| `picnic_lib/test/presentation/pages/vote/vote_gap_tooltip_test.dart` | 신규 |

건드리지 않는 파일: `vote_item_widget.dart`, `vote_item_highlight_widget.dart`,
`vote_gain_indicator.dart`, `vote_detail_achieve_page.dart`, `vote_info_card_vertical.dart`.

## 참고 — 실측 데이터 (2026-07-09 프로덕션)

동적 정밀도가 필요한 근거. picnic 투표는 극단적으로 top-heavy 하다.

| 순위 | 07월 생일(남), 91명 | 27주차 위클리 핔차트, 1487명 |
|---|---|---|
| 1위 | 35.20% | 33.89% |
| 3위 | 27.87% | 30.84% |
| 5위 | 0.18% | 0.39% |
| 20위 | 0.0032% (65표) | 0표 |
| 50위+ | 0표 | 0표 |

`toStringAsFixed(2)` 고정이면 위클리 1487명 중 ~1470명이 `0.00%` 로 뭉개진다.

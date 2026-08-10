import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:picnic_lib/core/analytics/analytics.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/data/models/wallet/wallet_amount.dart';

/// GA4 `vote` 이벤트(스펙 §2-10) 파라미터 조립.
///
/// 투표 다이얼로그가 3개(일반 / pic / JMA)라 조립 규칙이 흩어지면 같은 이벤트가
/// 경로마다 다른 값으로 나간다. 규칙은 여기에만 둔다.
///
/// **호출 조건**: 서버 제출이 성공한 뒤에만 부른다. 수량 0·잔액 부족·탈퇴 차단·
/// 서버 실패 경로에서는 부르지 않는다.
class VoteAnalytics {
  const VoteAnalytics._();

  /// 스펙 예시값 `2026.06.26` 포맷.
  static final DateFormat _dateFormat = DateFormat('yyyy.MM.dd');

  /// 투표 기간을 고정할 기준 시간대 (KST, UTC+9).
  ///
  /// **왜 기기 로컬 시간이 아닌가.** 앱 UI(`formatVotePeriod`)는 사용자에게
  /// 보여주는 값이라 `toLocal()` 로 기기 시간대에 맞춘다. 하지만
  /// `vote_start_date` 는 사용자 속성이 아니라 **투표 자체의 속성**이고 GA4
  /// 디멘션 값이다. 로컬로 포맷하면 같은 투표가 한국 기기에서는
  /// `2026.06.26`, 미국 기기에서는 `2026.06.25` 로 나가 하나의 투표가 두 개의
  /// 디멘션 값으로 갈라진다 — 투표별 세그먼트가 불가능해진다.
  ///
  /// **왜 UTC 가 아니라 KST 인가.** 투표 시작·마감은 한국 기준으로 운영되고
  /// 택소노미 스프레드시트의 예시 날짜도 한국 캠페인 날짜다. UTC 로 찍으면
  /// 한국 자정 직후에 시작하는 투표가 하루 전 날짜로 기록되어 운영 캘린더와
  /// 어긋난다.
  ///
  /// 서버(Supabase)의 timestamptz 는 UTC 로 파싱되므로 [DateTime.toUtc] 는
  /// 항등이고, 여기에 +9h 를 더하면 KST 달력 날짜가 된다.
  static const Duration _kstOffset = Duration(hours: 9);

  @visibleForTesting
  static String? formatVoteDate(DateTime? value) {
    if (value == null) return null;
    return _dateFormat.format(value.toUtc().add(_kstOffset));
  }

  /// 다국어 JSON 에서 **로케일과 무관하게 고정된** 표시값을 고른다.
  ///
  /// `getLocaleTextFromJson` 을 쓰지 않는 이유는 [_kstOffset] 과 같다: 기기
  /// 언어에 따라 `vote_name` 이 `올해의 썸머킹` / `Summer King of the Year` 로
  /// 갈라지면 하나의 투표를 집계할 수 없다. 대행사 리포트가 한국어 기준이므로
  /// `ko` 를 1순위, `en` 을 2순위로 둔다.
  ///
  /// **'비어 있지 않은 첫 값' 폴백을 두지 않는다.** [Map] 순회 순서는 이 JSON 이
  /// 어떻게 역직렬화됐는지에 달려 있어, 같은 투표가 실행마다 다른 언어의 값으로
  /// 나갈 수 있고 어떤 언어가 뽑힐지 예측할 수도 없다. 그러면 하나의 투표가
  /// GA4 에서 여러 디멘션 값으로 갈라져 오히려 집계가 불가능해진다 — 값이
  /// 없는 것(= `undefined` 한 값으로 수렴)보다 나쁘다.
  ///
  /// `vote_id` 가 이미 투표의 유일 식별자이므로 `vote_name` 이 `undefined` 여도
  /// 투표별 집계는 그대로 가능하다.
  @visibleForTesting
  static String? stableText(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) return null;
    for (final key in const ['ko', 'en']) {
      final value = json[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  /// 스펙 예시값 `vote0023` 형식의 투표 ID.
  ///
  /// DB 의 `vote.id` 는 정수다. 스펙이 요구하는 문자열 형태로 맞춰 두면 대행사
  /// 리포트에서 다른 숫자 파라미터와 섞이지 않고, 4자리 미만은 0 으로 채워
  /// 정렬이 사전순=번호순이 된다. 9999 를 넘으면 자릿수가 늘어날 뿐 값은 계속
  /// 유일하다.
  @visibleForTesting
  static String voteIdOf(int id) => 'vote${id.toString().padLeft(4, '0')}';

  /// 실제 소모된 재화만 담아 반환한다 (0 이하는 제외).
  ///
  /// 0 을 남겨 두면 결합 라벨에 쓰지도 않은 재화가 들어가고, 재화별 수량
  /// 파라미터에도 0 이 실려 "쓰지 않았다"와 구분되지 않는다.
  @visibleForTesting
  static Map<WalletCurrency, BigInt> usedOnly(
    Map<WalletCurrency, BigInt> usage,
  ) => <WalletCurrency, BigInt>{
    for (final entry in usage.entries)
      if (entry.value > BigInt.zero) entry.key: entry.value,
  };

  /// 투표 제출이 **서버에서 성공한 뒤** 호출한다.
  ///
  /// [usage] 는 이 투표로 실제 소모된 재화별 수량이다. 일반 포털은 서버 정산
  /// (`VoteUsageModel`)이 돌려준 값을, pic·JMA 포털은 서버로 보낸 사용량 분해
  /// (`star_candy_usage` / `star_candy_bonus_usage`)를 그대로 넣는다 — 어느
  /// 쪽도 새로 계산하지 않는다.
  ///
  /// 어떤 경우에도 던지지 않는다. 이 호출은 투표 성공 처리(지갑 반영·완료
  /// 다이얼로그) 한복판에서 일어나므로, 여기서 예외가 새면 서버에서 이미 성공한
  /// 투표가 호출부의 catch 로 떨어져 실패로 안내되고 롤백까지 돈다.
  /// [PicnicAnalytics] 내부에도 같은 가드가 있지만 여기서 조립하는 값
  /// (모델 접근·포맷)이 던질 수 있어 한 겹 더 둔다.
  static Future<void> logVote({
    required VoteModel voteModel,
    required VoteItemModel voteItemModel,
    required Map<WalletCurrency, BigInt> usage,
  }) async {
    try {
      await _logVote(
        voteModel: voteModel,
        voteItemModel: voteItemModel,
        usage: usage,
      );
    } catch (e, s) {
      logger.e('GA4 vote 이벤트 조립 실패 - 투표 결과에는 영향 없음', error: e, stackTrace: s);
    }
  }

  static Future<void> _logVote({
    required VoteModel voteModel,
    required VoteItemModel voteItemModel,
    required Map<WalletCurrency, BigInt> usage,
  }) {
    final used = usedOnly(usage);
    final total = used.values.fold(BigInt.zero, (sum, v) => sum + v);

    return PicnicAnalytics.instance.logVote(
      // 재화가 2~3종 섞이면 결합 라벨, 하나면 그 재화 이름. 어느 쪽이든
      // 이벤트는 투표 1건당 1개로 유지된다.
      virtualCurrencyName: used.isEmpty
          ? null
          : Ga4CurrencyNames.combined(used.keys.toSet()),
      rewardAmount: used.isEmpty ? null : total.toInt(),
      voteId: voteIdOf(voteModel.id),
      voteName: stableText(voteModel.title),
      // 우승자 리워드가 등록되지 않은 투표가 있다. 그때는 null 로 넘겨 T2
      // 레이어가 'undefined' 로 대체하게 한다(String 파라미터 규칙).
      voteReward: stableText(voteModel.reward?.firstOrNull?.title),
      voteStartDate: formatVoteDate(voteModel.startAt),
      voteEndDate: formatVoteDate(voteModel.stopAt),
      voteArtistName: stableText(voteItemModel.artist?.name),
      // 아티스트에 직접 붙은 그룹이 없으면 아티스트가 들고 있는 그룹으로
      // 폴백한다 (솔로 아티스트는 양쪽 다 비어 'undefined' 가 된다).
      voteArtistGroup: stableText(
        voteItemModel.artistGroup?.name ?? voteItemModel.artist?.artistGroup?.name,
      ),
      starCandyUsage: used[WalletCurrency.starCandy]?.toInt(),
      starCandyBonusUsage: used[WalletCurrency.bonusStarCandy]?.toInt(),
      cottonCandyUsage: used[WalletCurrency.cottonCandy]?.toInt(),
    );
  }
}

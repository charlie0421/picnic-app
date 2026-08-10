import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/analytics/analytics.dart';
import 'package:picnic_lib/data/models/reward.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';
import 'package:picnic_lib/data/models/vote/artist_group.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/data/models/wallet/wallet_amount.dart';
import 'package:picnic_lib/presentation/widgets/vote/voting/vote_analytics.dart';

VoteModel _vote({
  int id = 23,
  Map<String, dynamic>? title,
  DateTime? startAt,
  DateTime? stopAt,
  List<RewardModel>? reward,
}) => VoteModel(
  id: id,
  title: title ?? {'ko': '올해의 썸머킹', 'en': 'Summer King of the Year'},
  voteCategory: null,
  mainImage: null,
  waitImage: null,
  resultImage: null,
  voteContent: null,
  voteItem: null,
  createdAt: null,
  visibleAt: null,
  stopAt: stopAt,
  startAt: startAt,
  isEnded: false,
  isUpcoming: false,
  isPartnership: false,
  partner: null,
  reward: reward,
);

VoteItemModel _item({
  Map<String, dynamic>? artistName,
  Map<String, dynamic>? groupName,
  Map<String, dynamic>? artistOwnGroupName,
}) => VoteItemModel(
  id: 1,
  voteTotal: 0,
  voteId: 23,
  artist: artistName == null
      ? null
      : ArtistModel(
          id: 1,
          name: artistName,
          artistGroup: artistOwnGroupName == null
              ? null
              : ArtistGroupModel(id: 9, name: artistOwnGroupName, image: null),
        ),
  artistGroup: groupName == null
      ? null
      : ArtistGroupModel(id: 2, name: groupName, image: null),
);

void main() {
  late RecordingGa4Sink sink;

  setUp(() {
    sink = RecordingGa4Sink();
    PicnicAnalytics.overrideInstance(PicnicAnalytics(sink: sink));
  });

  tearDown(PicnicAnalytics.resetInstance);

  Map<String, Object> lastVoteParams() {
    final event = sink.events.single;
    expect(event.name, Ga4Event.vote);
    return event.parameters;
  }

  group('vote_start_date / vote_end_date', () {
    test('스펙의 yyyy.MM.dd 포맷으로 나간다', () {
      expect(
        VoteAnalytics.formatVoteDate(DateTime.utc(2026, 6, 25, 15)),
        '2026.06.26', // UTC 15:00 == KST 익일 00:00
      );
    });

    test('KST 로 고정한다 — 기기 시간대가 값을 바꾸면 투표 하나가 두 디멘션으로 갈라진다', () {
      // 같은 순간을 어느 시간대의 DateTime 으로 주든 결과가 같아야 한다.
      final utc = DateTime.utc(2026, 7, 9, 14, 59);
      expect(VoteAnalytics.formatVoteDate(utc), '2026.07.09');
      expect(VoteAnalytics.formatVoteDate(utc.toLocal()), '2026.07.09');

      // KST 자정을 막 넘긴 순간은 UTC 기준으로는 전날이지만 KST 날짜로 찍힌다.
      expect(
        VoteAnalytics.formatVoteDate(DateTime.utc(2026, 7, 9, 15, 0)),
        '2026.07.10',
      );
    });

    test('날짜가 없으면 null 로 넘겨 undefined 대체 규칙을 타게 한다', () async {
      await VoteAnalytics.logVote(
        voteModel: _vote(),
        voteItemModel: _item(),
        usage: {WalletCurrency.starCandy: BigInt.from(100)},
      );

      final params = lastVoteParams();
      expect(params[Ga4Param.voteStartDate], Ga4Value.undefined);
      expect(params[Ga4Param.voteEndDate], Ga4Value.undefined);
    });
  });

  group('vote_id', () {
    test('스펙 예시값 형식(vote0023)으로 포맷한다', () {
      expect(VoteAnalytics.voteIdOf(23), 'vote0023');
      expect(VoteAnalytics.voteIdOf(1), 'vote0001');
      expect(VoteAnalytics.voteIdOf(12345), 'vote12345');
    });
  });

  group('로케일 무관 표시값', () {
    test('ko 를 1순위로 고정한다', () {
      expect(VoteAnalytics.stableText({'ko': '제이엘', 'en': 'JL'}), '제이엘');
    });

    test('ko 가 비어 있으면 en 으로 폴백한다', () {
      expect(VoteAnalytics.stableText({'ko': '  ', 'en': 'JL'}), 'JL');
      expect(VoteAnalytics.stableText({'en': 'JL'}), 'JL');
    });

    test('ko/en 이 모두 없으면 null 이다 — 임의의 첫 값을 쓰지 않는다', () {
      // '비어 있지 않은 첫 값' 폴백은 Map 순회 순서에 의존해 같은 투표가
      // 실행마다 다른 언어 값으로 나갈 수 있다. 하나의 투표가 여러 디멘션
      // 값으로 갈라지는 쪽이 undefined 한 값으로 수렴하는 것보다 나쁘다.
      expect(VoteAnalytics.stableText({'ja': 'ジェイエル'}), isNull);
      expect(VoteAnalytics.stableText({'ko': '', 'en': ''}), isNull);
      expect(VoteAnalytics.stableText({'ko': '', 'en': '', 'th': 'เจแอล'}),
          isNull);
      expect(VoteAnalytics.stableText(null), isNull);
      expect(VoteAnalytics.stableText(<String, dynamic>{}), isNull);
    });

    test('키 삽입 순서가 달라도 같은 값을 돌려준다', () {
      // 폴백이 남아 있다면 이 두 Map 은 서로 다른 값을 낸다.
      expect(
        VoteAnalytics.stableText(<String, dynamic>{'ja': 'A', 'th': 'B'}),
        VoteAnalytics.stableText(<String, dynamic>{'th': 'B', 'ja': 'A'}),
      );
    });
  });

  group('재화 표현', () {
    test('단일 재화면 그 이름과 총량만 나간다', () async {
      await VoteAnalytics.logVote(
        voteModel: _vote(),
        voteItemModel: _item(),
        usage: {
          WalletCurrency.starCandy: BigInt.from(100),
          WalletCurrency.bonusStarCandy: BigInt.zero,
          WalletCurrency.cottonCandy: BigInt.zero,
        },
      );

      final params = lastVoteParams();
      expect(params[Ga4Param.virtualCurrencyName], Ga4CurrencyNames.starCandy);
      expect(params[Ga4Param.rewardAmount], 100);
      expect(params[Ga4Param.starCandyUsage], 100);
      // 쓰지 않은 재화는 파라미터 자체가 없어야 한다 — 0 을 보내면
      // "쓰지 않았다"와 "쓸 수 있었는데 0" 이 구분되지 않는다.
      expect(params.containsKey(Ga4Param.starCandyBonusUsage), isFalse);
      expect(params.containsKey(Ga4Param.cottonCandyUsage), isFalse);
    });

    test('혼합 사용은 결합 라벨 + 총량 + 재화별 수량으로 복원 가능해야 한다', () async {
      await VoteAnalytics.logVote(
        voteModel: _vote(),
        voteItemModel: _item(),
        usage: {
          WalletCurrency.bonusStarCandy: BigInt.from(40),
          WalletCurrency.starCandy: BigInt.from(60),
        },
      );

      final params = lastVoteParams();
      expect(params[Ga4Param.virtualCurrencyName], '스타캔디+보너스 스타캔디');
      expect(params[Ga4Param.rewardAmount], 100);
      expect(params[Ga4Param.starCandyUsage], 60);
      expect(params[Ga4Param.starCandyBonusUsage], 40);
      expect(params.containsKey(Ga4Param.cottonCandyUsage), isFalse);
    });

    test('결합 라벨은 삽입 순서와 무관하게 정규화된다', () async {
      // 정규화하지 않으면 같은 조합이 '스타캔디+코튼캔디' 와 '코튼캔디+스타캔디'
      // 두 디멘션 값으로 갈라진다.
      Future<String> labelFor(Map<WalletCurrency, BigInt> usage) async {
        sink.clear();
        await VoteAnalytics.logVote(
          voteModel: _vote(),
          voteItemModel: _item(),
          usage: usage,
        );
        return lastVoteParams()[Ga4Param.virtualCurrencyName]! as String;
      }

      final forward = await labelFor({
        WalletCurrency.starCandy: BigInt.one,
        WalletCurrency.cottonCandy: BigInt.one,
      });
      final reversed = await labelFor({
        WalletCurrency.cottonCandy: BigInt.one,
        WalletCurrency.starCandy: BigInt.one,
      });

      expect(forward, reversed);
      expect(forward, '스타캔디+코튼캔디');
    });

    test('3종 동시 사용도 한 건의 vote 이벤트로만 나간다', () async {
      await VoteAnalytics.logVote(
        voteModel: _vote(),
        voteItemModel: _item(),
        usage: {
          WalletCurrency.starCandy: BigInt.from(10),
          WalletCurrency.bonusStarCandy: BigInt.from(20),
          WalletCurrency.cottonCandy: BigInt.from(30),
        },
      );

      // 재화별로 이벤트를 쪼개면 투표 카운트 지표가 부풀어 깨진다.
      expect(sink.events, hasLength(1));
      final params = lastVoteParams();
      expect(params[Ga4Param.virtualCurrencyName], '스타캔디+보너스 스타캔디+코튼캔디');
      expect(params[Ga4Param.rewardAmount], 60);
    });
  });

  group('투표 메타데이터', () {
    test('스펙 §2-10 파라미터를 모두 채운다', () async {
      await VoteAnalytics.logVote(
        voteModel: _vote(
          startAt: DateTime.utc(2026, 6, 25, 15),
          stopAt: DateTime.utc(2026, 7, 9, 15),
          reward: [
            const RewardModel(id: 1, title: {'ko': '중앙데일리 온라인+지면 기사 송출'}),
          ],
        ),
        voteItemModel: _item(
          artistName: {'ko': '제이엘'},
          groupName: {'ko': '아홉'},
        ),
        usage: {WalletCurrency.starCandy: BigInt.from(100)},
      );

      final params = lastVoteParams();
      expect(params[Ga4Param.voteId], 'vote0023');
      expect(params[Ga4Param.voteName], '올해의 썸머킹');
      expect(params[Ga4Param.voteReward], '중앙데일리 온라인+지면 기사 송출');
      expect(params[Ga4Param.voteStartDate], '2026.06.26');
      expect(params[Ga4Param.voteEndDate], '2026.07.10');
      expect(params[Ga4Param.voteArtistName], '제이엘');
      expect(params[Ga4Param.voteArtistGroup], '아홉');
    });

    test('리워드·아티스트 정보가 없으면 undefined 로 대체된다', () async {
      await VoteAnalytics.logVote(
        voteModel: _vote(reward: const []),
        voteItemModel: _item(),
        usage: {WalletCurrency.starCandy: BigInt.from(1)},
      );

      final params = lastVoteParams();
      expect(params[Ga4Param.voteReward], Ga4Value.undefined);
      expect(params[Ga4Param.voteArtistName], Ga4Value.undefined);
      expect(params[Ga4Param.voteArtistGroup], Ga4Value.undefined);
    });

    test('아이템에 그룹이 없으면 아티스트가 들고 있는 그룹으로 폴백한다', () async {
      await VoteAnalytics.logVote(
        voteModel: _vote(),
        voteItemModel: _item(
          artistName: {'ko': '셔누'},
          artistOwnGroupName: {'ko': '몬스타엑스'},
        ),
        usage: {WalletCurrency.starCandy: BigInt.from(1)},
      );

      expect(lastVoteParams()[Ga4Param.voteArtistGroup], '몬스타엑스');
    });
  });
}

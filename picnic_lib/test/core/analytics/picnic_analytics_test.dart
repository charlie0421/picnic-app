import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/analytics/ga4_purchase_item.dart';
import 'package:picnic_lib/core/analytics/ga4_sink.dart';
import 'package:picnic_lib/core/analytics/ga4_taxonomy.dart';
import 'package:picnic_lib/core/analytics/picnic_analytics.dart';

void main() {
  late RecordingGa4Sink sink;
  late PicnicAnalytics analytics;

  setUp(() {
    sink = RecordingGa4Sink();
    analytics = PicnicAnalytics(sink: sink);
  });

  group('사용자 속성 (스펙 §1)', () {
    test('user_id 는 해시 없이 원본 UUID 를 그대로 넘긴다', () async {
      const uuid = '3f2b1a4c-8d9e-4f10-b2c3-9a8d7e6f5c4b';

      await analytics.setUserProperties(
        userId: uuid,
        isLogin: true,
        language: 'ko',
      );

      expect(sink.userIds, <String?>[uuid]);
    });

    test('is_login 과 language 를 설정한다', () async {
      await analytics.setUserProperties(
        userId: 'u1',
        isLogin: true,
        language: 'jp',
      );

      expect(sink.userProperties[Ga4UserProperty.isLogin], Ga4Value.loggedIn);
      expect(sink.userProperties[Ga4UserProperty.language], 'jp');
    });

    test('비로그인은 is_login=N 이다', () async {
      await analytics.setUserProperties(
        userId: null,
        isLogin: false,
        language: 'en',
      );

      expect(sink.userProperties[Ga4UserProperty.isLogin], Ga4Value.loggedOut);
      expect(sink.userIds, <String?>[null]);
    });

    test('레거시 속성 user_role/locale/is_tester/app_env 를 유지한다', () async {
      await analytics.setUserProperties(
        userId: 'u1',
        isLogin: true,
        language: 'ko',
        userRole: 'admin',
        locale: 'ko',
        isTester: true,
        appEnv: 'production',
      );

      expect(sink.userProperties[Ga4UserProperty.userRole], 'admin');
      expect(sink.userProperties[Ga4UserProperty.locale], 'ko');
      expect(sink.userProperties[Ga4UserProperty.isTester], 'true');
      expect(sink.userProperties[Ga4UserProperty.appEnv], 'production');
    });

    test('clearUserProperties 는 is_login 을 N 으로 갱신하고 user_id 를 지운다', () async {
      await analytics.clearUserProperties();

      expect(sink.userIds, <String?>[null]);
      expect(sink.userProperties[Ga4UserProperty.isLogin], Ga4Value.loggedOut);
      expect(sink.userProperties[Ga4UserProperty.userRole], isNull);
      expect(sink.userProperties[Ga4UserProperty.appEnv], isNull);
      // language 는 로그아웃과 무관하므로 건드리지 않는다.
      expect(sink.userProperties.containsKey(Ga4UserProperty.language),
          isFalse);
    });
  });

  group('login / sign_up (스펙 §2-1, §2-2)', () {
    test('login 이름과 파라미터가 스펙과 일치한다', () async {
      await analytics.logLogin(method: 'kakao', selectedLanguage: 'ko');

      expect(sink.last.name, Ga4Event.login);
      expect(sink.last.parameters, <String, Object>{
        Ga4Param.method: 'kakao',
        Ga4Param.selectedLanguage: 'ko',
      });
    });

    test('sign_up 이름과 파라미터가 스펙과 일치한다', () async {
      await analytics.logSignUp(method: 'apple', selectedLanguage: 'en');

      expect(sink.last.name, Ga4Event.signUp);
      expect(sink.last.parameters, <String, Object>{
        Ga4Param.method: 'apple',
        Ga4Param.selectedLanguage: 'en',
      });
    });

    test('값이 없으면 undefined 로 대체하되 파라미터는 남는다', () async {
      await analytics.logLogin(method: null, selectedLanguage: null);

      expect(sink.last.parameters, <String, Object>{
        Ga4Param.method: Ga4Value.undefined,
        Ga4Param.selectedLanguage: Ga4Value.undefined,
      });
    });
  });

  group('click_attendance (스펙 §2-3)', () {
    test('한글 재화명과 숫자 수량을 스펙대로 보낸다', () async {
      await analytics.logClickAttendance(
        virtualCurrencyName: '보너스 별사탕',
        rewardAmount: 60,
      );

      expect(sink.last.name, Ga4Event.clickAttendance);
      expect(sink.last.parameters, <String, Object>{
        Ga4Param.virtualCurrencyName: '보너스 별사탕',
        Ga4Param.rewardAmount: 60,
      });
    });

    test('reward_amount 가 null 이면 파라미터를 생략한다', () async {
      await analytics.logClickAttendance(
        virtualCurrencyName: '별사탕',
        rewardAmount: null,
      );

      expect(sink.last.parameters.containsKey(Ga4Param.rewardAmount), isFalse);
      expect(sink.last.parameters[Ga4Param.virtualCurrencyName], '별사탕');
    });
  });

  group('click_mission (스펙 §2-4)', () {
    test('mission_category 만 보낸다', () async {
      await analytics.logClickMission(missionCategory: '글로벌 픽 #1');

      expect(sink.last.name, Ga4Event.clickMission);
      expect(sink.last.parameters, <String, Object>{
        Ga4Param.missionCategory: '글로벌 픽 #1',
      });
    });
  });

  group('ad_request (스펙 §2-5)', () {
    test('4개 파라미터가 스펙 이름/타입대로 나간다', () async {
      await analytics.logAdRequest(
        sectionName: '광고에서 별사탕 받기',
        adCategory: '글로벌 픽 #1',
        virtualCurrencyName: '별사탕',
        rewardAmount: 1,
      );

      expect(sink.last.name, Ga4Event.adRequest);
      expect(sink.last.parameters, <String, Object>{
        Ga4Param.sectionName: '광고에서 별사탕 받기',
        Ga4Param.adCategory: '글로벌 픽 #1',
        Ga4Param.virtualCurrencyName: '별사탕',
        Ga4Param.rewardAmount: 1,
      });
    });
  });

  group('ad_impression (스펙 §2-6)', () {
    test('8개 파라미터가 스펙 이름대로 나간다', () async {
      await analytics.logAdImpression(
        adPlatform: 'AdMob',
        adSource: 'Google Ads',
        adFormat: 'rewarded',
        adUnitName: 'reward_global_pick_1',
        sectionName: '광고에서 별사탕 받기',
        adCategory: '글로벌 픽 #1',
        virtualCurrencyName: '별사탕',
        rewardAmount: 1,
      );

      expect(sink.last.name, Ga4Event.adImpression);
      expect(sink.last.parameters, <String, Object>{
        Ga4Param.adPlatform: 'AdMob',
        Ga4Param.adSource: 'Google Ads',
        Ga4Param.adFormat: 'rewarded',
        Ga4Param.adUnitName: 'reward_global_pick_1',
        Ga4Param.sectionName: '광고에서 별사탕 받기',
        Ga4Param.adCategory: '글로벌 픽 #1',
        Ga4Param.virtualCurrencyName: '별사탕',
        Ga4Param.rewardAmount: 1,
      });
    });
  });

  group('earn_virtual_currency (스펙 §2-7)', () {
    test('수량은 value 가 아니라 reward_amount 로 나간다', () async {
      await analytics.logEarnVirtualCurrency(
        virtualCurrencyName: '별사탕',
        rewardAmount: 1,
        earnMethod: '광고 리워드',
        sectionName: '광고에서 별사탕 받기',
        adCategory: '글로벌 픽 #1',
      );

      expect(sink.last.name, Ga4Event.earnVirtualCurrency);
      expect(sink.last.parameters.containsKey(Ga4Param.value), isFalse);
      expect(sink.last.parameters, <String, Object>{
        Ga4Param.virtualCurrencyName: '별사탕',
        Ga4Param.earnMethod: '광고 리워드',
        Ga4Param.sectionName: '광고에서 별사탕 받기',
        Ga4Param.adCategory: '글로벌 픽 #1',
        Ga4Param.rewardAmount: 1,
      });
    });
  });

  group('ad_cta_click (스펙 §2-8)', () {
    test('destination_type 을 포함한 7개 파라미터가 나간다', () async {
      await analytics.logAdCtaClick(
        adPlatform: 'AdMob',
        adSource: 'Google Ads',
        adFormat: 'rewarded',
        adUnitName: 'reward_global_pick_1',
        sectionName: '광고에서 별사탕 받기',
        adCategory: '글로벌 픽 #1',
        destinationType: 'youtube',
      );

      expect(sink.last.name, Ga4Event.adCtaClick);
      expect(sink.last.parameters[Ga4Param.destinationType], 'youtube');
      expect(sink.last.parameters.length, 7);
    });
  });

  group('purchase (스펙 §2-9)', () {
    test('Event 수준 값과 Item 배열을 분리해서 보낸다', () async {
      await analytics.logPurchase(
        transactionId: '202607061530001',
        currency: 'USD',
        value: 0.99,
        items: const <Ga4PurchaseItem>[
          Ga4PurchaseItem(
            itemId: 'star100',
            itemName: 'STAR100',
            virtualCurrencyName: '별사탕',
            baseAmount: 100,
            bonusAmount: 25,
          ),
        ],
      );

      expect(sink.events, isEmpty, reason: 'purchase 는 logEvent 가 아니라 logPurchase');
      expect(sink.purchases, hasLength(1));

      final purchase = sink.purchases.single;
      expect(purchase.transactionId, '202607061530001');
      expect(purchase.currency, 'USD');
      expect(purchase.value, 0.99);

      final item = purchase.items.single;
      expect(item.resolvedItemId, 'star100');
      expect(item.resolvedItemName, 'STAR100');
      expect(item.toCustomParameters(), <String, Object>{
        Ga4Param.virtualCurrencyName: '별사탕',
        Ga4Param.baseAmount: 100,
        Ga4Param.bonusAmount: 25,
      });
    });

    test('보너스가 0 이어도 파라미터가 생략되지 않는다', () async {
      const item = Ga4PurchaseItem(
        itemId: 'star600',
        itemName: 'STAR600',
        virtualCurrencyName: '별사탕',
        baseAmount: 600,
        bonusAmount: 0,
      );

      expect(item.toCustomParameters()[Ga4Param.bonusAmount], 0);
    });

    test('transaction_id 없음은 undefined 대체, currency 없음은 생략한다', () async {
      // currency 는 ISO 4217 코드만 유효한 GA4 표준 필드다. 문자열
      // 'undefined' 를 넣으면 매출 값이 통째로 무시되므로, Number 파라미터와
      // 같은 이유로 대체하지 않고 생략한다(outbox 경로와 동일 계약).
      await analytics.logPurchase(
        transactionId: null,
        currency: null,
        value: null,
        items: const <Ga4PurchaseItem>[],
      );

      final purchase = sink.purchases.single;
      expect(purchase.transactionId, Ga4Value.undefined);
      expect(purchase.currency, isNull);
      expect(purchase.value, isNull);
    });

    test('Item 의 비표준 파라미터도 값 없으면 규칙대로 처리된다', () {
      const item = Ga4PurchaseItem(
        itemId: null,
        itemName: null,
        virtualCurrencyName: null,
        baseAmount: null,
        bonusAmount: null,
      );

      expect(item.resolvedItemId, Ga4Value.undefined);
      expect(item.resolvedItemName, Ga4Value.undefined);
      expect(item.toCustomParameters(), <String, Object>{
        Ga4Param.virtualCurrencyName: Ga4Value.undefined,
      });
    });
  });

  group('vote (스펙 §2-10)', () {
    test('9개 파라미터가 스펙 이름/타입대로 나간다', () async {
      await analytics.logVote(
        virtualCurrencyName: '별사탕',
        rewardAmount: 100,
        voteId: 'vote0023',
        voteName: '올해의 썸머킹',
        voteReward: '중앙데일리 온라인+지면 기사 송출',
        voteStartDate: '2026.06.26',
        voteEndDate: '2026.07.10',
        voteArtistName: '제이엘',
        voteArtistGroup: '아홉',
      );

      expect(sink.last.name, Ga4Event.vote);
      expect(sink.last.parameters, <String, Object>{
        Ga4Param.virtualCurrencyName: '별사탕',
        Ga4Param.voteId: 'vote0023',
        Ga4Param.voteName: '올해의 썸머킹',
        Ga4Param.voteReward: '중앙데일리 온라인+지면 기사 송출',
        Ga4Param.voteStartDate: '2026.06.26',
        Ga4Param.voteEndDate: '2026.07.10',
        Ga4Param.voteArtistName: '제이엘',
        Ga4Param.voteArtistGroup: '아홉',
        Ga4Param.rewardAmount: 100,
      });
    });

    test('긴 vote_reward 는 100자로 잘린다', () async {
      await analytics.logVote(
        virtualCurrencyName: '별사탕',
        rewardAmount: 1,
        voteId: 'v',
        voteName: 'n',
        voteReward: '리' * 200,
        voteStartDate: null,
        voteEndDate: null,
        voteArtistName: null,
        voteArtistGroup: null,
      );

      expect((sink.last.parameters[Ga4Param.voteReward] as String).length, 100);
      expect(sink.last.parameters[Ga4Param.voteStartDate], Ga4Value.undefined);
    });
  });

  group('안전성', () {
    test('싱크가 던져도 예외가 호출부로 새지 않지만 성공을 보고하지도 않는다', () async {
      final throwing = PicnicAnalytics(sink: _ThrowingSink());

      // 예외를 잡는 것과 "보냈다"고 보고하는 것은 다르다. 후자면 호출부가
      // 중복 방어 마커를 남기고 그 이벤트는 영구히 차단된다.
      expect(
        await throwing.logLogin(method: 'google', selectedLanguage: 'ko'),
        isFalse,
      );
      expect(
        await throwing.logPurchase(
          transactionId: 't',
          currency: 'USD',
          value: 1,
          items: const <Ga4PurchaseItem>[],
        ),
        isFalse,
      );
      expect(
        await throwing.setUserProperties(
          userId: 'u',
          isLogin: true,
          language: 'ko',
        ),
        isFalse,
      );
      expect(await throwing.clearUserProperties(), isFalse);
    });

    test('전송에 성공하면 true 를 돌려준다', () async {
      expect(
        await analytics.logLogin(method: 'google', selectedLanguage: 'ko'),
        isTrue,
      );
    });

    test('싱크가 전송 실패를 보고하면 false 가 그대로 올라온다', () async {
      final failing = PicnicAnalytics(sink: RecordingGa4Sink(deliver: false));

      expect(
        await failing.logLogin(method: 'google', selectedLanguage: 'ko'),
        isFalse,
      );
      expect(
        await failing.logPurchase(
          transactionId: 't',
          currency: 'USD',
          value: 1,
          items: const <Ga4PurchaseItem>[],
        ),
        isFalse,
      );
    });

    test('Firebase 미초기화 환경에서도 기본 인스턴스가 죽지 않는다', () async {
      PicnicAnalytics.resetInstance();
      await PicnicAnalytics.instance
          .logClickMission(missionCategory: '글로벌 픽 #1');
      await PicnicAnalytics.instance.clearUserProperties();
    });

    test('overrideInstance 로 싱크를 교체할 수 있다', () async {
      final recording = RecordingGa4Sink();
      PicnicAnalytics.overrideInstance(PicnicAnalytics(sink: recording));
      addTearDown(PicnicAnalytics.resetInstance);

      await PicnicAnalytics.instance.logClickMission(missionCategory: '아시아 픽 #1');

      expect(recording.last.name, Ga4Event.clickMission);
    });
  });
}

class _ThrowingSink implements Ga4Sink {
  @override
  Future<bool> logEvent(String name, Map<String, Object> parameters) async {
    throw StateError('boom');
  }

  @override
  Future<bool> logPurchase({
    required String? transactionId,
    required String? currency,
    required num? value,
    required List<Ga4PurchaseItem> items,
  }) async {
    throw StateError('boom');
  }

  @override
  Future<bool> setUserId(String? id) async => throw StateError('boom');

  @override
  Future<bool> setUserProperty(String name, String? value) async =>
      throw StateError('boom');
}

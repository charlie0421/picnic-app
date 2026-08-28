import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/analytics/ga4_taxonomy.dart';

/// Firebase 가 앱 스트림에서 **예약해 둔 이벤트 이름**.
///
/// 이 이름으로 `logEvent` 를 호출하면 SDK 가 `Invalid argument (name): Event
/// name is reserved` 를 던진다. 앱에서는 그 예외를 `PicnicAnalytics._guard` 가
/// 잡아 로그만 남기므로, **GA4 에서는 조용히 0건으로만 보인다.** 원안 이벤트명
/// `ad_click` 이 프로덕션 28일간 0건이었던 것이 그 사례다.
///
/// 출처: Firebase Analytics `FirebaseAnalytics.Event` 예약 목록.
const Set<String> _reservedEventNames = <String>{
  'ad_activeview',
  'ad_click',
  'ad_exposure',
  'ad_query',
  'ad_reward',
  'adunit_exposure',
  'app_background',
  'app_clear_data',
  'app_exception',
  'app_remove',
  'app_store_refund',
  'app_store_subscription_cancel',
  'app_store_subscription_convert',
  'app_store_subscription_renew',
  'app_update',
  'app_upgrade',
  'dynamic_link_app_open',
  'dynamic_link_app_update',
  'dynamic_link_first_open',
  'error',
  'firebase_campaign',
  'firebase_in_app_message_action',
  'firebase_in_app_message_dismiss',
  'firebase_in_app_message_impression',
  'first_open',
  'first_visit',
  'in_app_purchase',
  'notification_dismiss',
  'notification_foreground',
  'notification_open',
  'notification_receive',
  'os_update',
  'session_start',
  'session_start_with_rollout',
  'user_engagement',
};

/// 예약 접두사. 이 접두사로 시작하는 이름도 SDK 가 거부한다.
const List<String> _reservedPrefixes = <String>['firebase_', 'google_', 'ga_'];

void main() {
  group('이벤트 이름 예약어 검증', () {
    test('스펙에 정의된 이벤트 중 예약어는 없다', () {
      final offenders = Ga4Event.all
          .where(_reservedEventNames.contains)
          .toList(growable: false);

      expect(
        offenders,
        isEmpty,
        reason:
            '예약 이벤트명은 SDK 가 전송을 거부해 GA4 에서 0건이 된다. '
            '대행사와 협의해 다른 이름으로 바꿔야 한다: $offenders',
      );
    });

    test('예약 접두사로 시작하는 이벤트는 없다', () {
      for (final name in Ga4Event.all) {
        for (final prefix in _reservedPrefixes) {
          expect(
            name.startsWith(prefix),
            isFalse,
            reason: '`$name` 이 예약 접두사 `$prefix` 로 시작한다.',
          );
        }
      }
    });

    test('ad_cta_click 은 원안 ad_click 을 대체한 이름이다', () {
      // 되돌리면 다시 0건이 된다. 회귀를 이 한 줄로 막는다.
      expect(Ga4Event.adCtaClick, 'ad_cta_click');
      expect(_reservedEventNames, contains('ad_click'));
    });

    test('이벤트 이름은 서로 중복되지 않는다', () {
      expect(Ga4Event.all.toSet().length, Ga4Event.all.length);
    });
  });
}

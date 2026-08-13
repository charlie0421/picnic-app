import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:picnic_lib/presentation/widgets/vote/store/free_charge_station/ad_platform.dart';

/// [AdPlatform.isNonReportableAdError] 를 **구현 그대로** 호출한다.
///
/// (예전 이 파일은 키워드 목록을 통째로 복제해 검사했다. 그래서 구현에
/// 'sdk is not connected', 'server error with status code:-', '작업을 완료할 수
/// 없습니다' 가 추가된 뒤에도 테스트는 옛 목록을 계속 통과시켰다 — 아무것도
/// 지키지 못하는 테스트였다. 메서드를 static 으로 바꿔 직접 호출한다.)
bool classify(String platform, dynamic error, String message) =>
    AdPlatform.isNonReportableAdError(platform, error, message);

void main() {
  group('no-fill 로 분류되어 Sentry 보고를 생략하는 메시지', () {
    const nonReportable = <String, String>{
      '영문 no fill': 'Ad no fill available',
      'NOFILL 대문자': 'NOFILL error',
      'no ad available': 'There is no ad available now',
      'no ad to show': 'No ad to show at this time',
      'inventory unavailable': 'inventory unavailable',
      'no ads available': 'No ads available right now',
      'not_ready 스네이크': 'Status: not_ready',
      'not ready 공백': 'Ad is not ready',
      'network error': 'network error occurred',
      '한글 광고 없음': '광고 없음',
      '한글 광고 로드 시간 초과': '광고 로드 시간 초과',
      // 구현에는 있으나 옛 복제 테스트에는 빠져 있던 키워드들
      'Tapjoy SDK 미연결': 'SDK is not connected',
      'iOS NSURLError 계열': 'Server Error With Status Code:-1001',
      'iOS 한글 메시지': '작업을 완료할 수 없습니다. timeout',
    };

    nonReportable.forEach((label, message) {
      test('$label → 비보고', () {
        expect(classify('SomePlatform', 'error', message), isTrue);
      });
    });
  });

  group('AdMob LoadAdError 코드', () {
    for (final code in [1, 2, 3]) {
      test('code $code 는 비보고', () {
        final error = LoadAdError(code, 'domain', 'message', null);
        expect(classify('AdMob', error, 'unmapped failure'), isTrue);
      });
    }

    test('code 0 은 보고 대상', () {
      final error = LoadAdError(0, 'domain', 'message', null);
      expect(classify('AdMob', error, 'unmapped failure'), isFalse);
    });

    test('플랫폼이 AdMob 이 아니면 코드 규칙을 적용하지 않는다', () {
      final error = LoadAdError(3, 'domain', 'message', null);
      expect(classify('Pangle', error, 'unmapped failure'), isFalse);
    });
  });

  group('Sentry 로 보고해야 하는 실제 오류', () {
    const reportable = <String, String>{
      'SDK 초기화 실패': 'PlatformException(init_failed, Pangle SDK init error)',
      '플레이스먼트 설정 오류': 'PlatformException(20001, invalid slot id)',
      '널 참조': "NoSuchMethodError: The getter 'x' was called on null",
      '광고 ID 미설정': '광고 ID가 설정되지 않음',
    };

    reportable.forEach((label, message) {
      test('$label → 보고', () {
        expect(classify('Pangle', 'error', message), isFalse);
      });
    });
  });

  group('회귀 가드 — 일반 라벨을 분류 근거로 넘기지 말 것', () {
    // 이 두 문자열은 '광고 로드 실패' 키워드에 걸려 **무조건** 비보고가 된다.
    // pangle_platform 의 catch 블록이 예전에 이 라벨을 넘기는 바람에, 어떤
    // 예외든 사용자에게 "모든 광고 소진"으로 보이고 Sentry 보고까지 막혔다.
    // 지금은 e.toString() 을 넘긴다. 아래 단언은 "왜 라벨을 넘기면 안 되는지"
    // 를 고정한다 — 라벨을 되돌리면 이 의미가 그대로 되살아난다.
    test('일반 라벨 "광고 로드 실패" 는 무조건 비보고로 삼켜진다', () {
      expect(classify('Pangle', Exception('init failed'), '광고 로드 실패'), isTrue);
    });

    test('"Pangle 광고 로드 실패" 도 같은 키워드에 걸린다', () {
      expect(
        classify('Pangle', Exception('init failed'), 'Pangle 광고 로드 실패'),
        isTrue,
      );
    });

    test('같은 예외라도 실제 텍스트로 넘기면 보고 대상이 된다', () {
      final error = Exception('Pangle SDK init failed: missing app id');
      expect(classify('Pangle', error, error.toString()), isFalse);
    });
  });

  group('대소문자 무시', () {
    test('키워드는 소문자 비교된다', () {
      expect(classify('Other', 'error', 'NO FILL'), isTrue);
      expect(classify('Other', 'error', 'Not Ready'), isTrue);
    });
  });

  group('isNonReportableAdError — AdMob', () {
    // 시나리오 3: no-fill 계열 LoadAdError 코드는 비보고 분류
    // (LoadAdError 는 SDK final 타입이라 인스턴스 생성이 어려우면 코드 경로 대신
    //  메시지 키워드 경로로 검증한다 — 케이스 작성 시 실제 생성 가능 여부를 먼저
    //  확인하고, 불가하면 아래 메시지 기반 케이스만 남긴다.)
    test('no fill 메시지는 비보고', () {
      expect(
        AdPlatform.isNonReportableAdError('AdMob', StateError('x'), 'No fill.'),
        isTrue,
      );
    });

    // 시나리오 7: 실제 예외 텍스트를 넘기면 진짜 버그는 보고 대상으로 남는다
    test('설정 오류 텍스트는 보고 대상', () {
      expect(
        AdPlatform.isNonReportableAdError(
            'AdMob', StateError('x'), 'Invalid ad unit ID'),
        isFalse,
      );
    });

    // 로드 타임아웃 문구가 비보고(=소진 안내) 로 분류되는 계약을 고정한다.
    // Task B-1 의 onLoadTimeout 이 이 계약에 의존한다.
    test('광고 로드 시간 초과 는 비보고', () {
      expect(
        AdPlatform.isNonReportableAdError(
            'AdMob', TimeoutException('t'), '광고 로드 시간 초과'),
        isTrue,
      );
    });
  });
}

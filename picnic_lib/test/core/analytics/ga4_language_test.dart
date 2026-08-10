import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/analytics/ga4_language.dart';
import 'package:picnic_lib/core/analytics/ga4_sink.dart';
import 'package:picnic_lib/core/analytics/ga4_taxonomy.dart';
import 'package:picnic_lib/core/analytics/picnic_analytics.dart';
import 'package:picnic_lib/core/constatns/constants.dart';

void main() {
  group('Ga4Language.normalize', () {
    test('앱 코드 ja 는 스펙 표기 jp 로 나간다', () {
      // 스펙(§1, §2-1, §2-2)의 예시값은 ko / en / jp 인데 앱 내부 코드는 ja 다.
      // 정규화가 없으면 일본어 사용자 세그먼트가 리포트에서 통째로 빈다.
      expect(Ga4Language.normalize('ja'), 'jp');
    });

    test('대소문자가 달라도 매핑된다', () {
      expect(Ga4Language.normalize('JA'), 'jp');
      expect(Ga4Language.normalize(' Ja '), 'jp');
    });

    test('이미 jp 인 값은 그대로 둔다', () {
      expect(Ga4Language.normalize('jp'), 'jp');
    });

    test('ko / en 은 그대로 통과한다', () {
      expect(Ga4Language.normalize('ko'), 'ko');
      expect(Ga4Language.normalize('en'), 'en');
    });

    test('스펙에 규정이 없는 코드는 원문 그대로 통과한다', () {
      // 특히 지역 코드의 대소문자를 건드리면 (zh_CN → zh_cn) 이미 수집 중인
      // GA4 히스토리와 갈라진다.
      for (final code in const [
        'es',
        'zh_CN',
        'zh_TW',
        'id',
        'bn_BD',
        'fil',
        'th',
        'vi',
        'my',
      ]) {
        expect(Ga4Language.normalize(code), code, reason: code);
      }
    });

    test('null 과 공백은 null 이다', () {
      expect(Ga4Language.normalize(null), isNull);
      expect(Ga4Language.normalize(''), isNull);
      expect(Ga4Language.normalize('   '), isNull);
    });

    test('앱이 지원하는 12개 언어 전부에 대해 값을 잃지 않는다', () {
      // languageMap 이 앱의 실제 언어 코드 목록이다. 정규화가 어떤 코드도
      // 비어 있는 값으로 떨어뜨리지 않아야 한다.
      expect(languageMap.keys, isNotEmpty);
      for (final code in languageMap.keys) {
        final normalized = Ga4Language.normalize(code);
        expect(normalized, isNotNull, reason: code);
        expect(normalized, isNotEmpty, reason: code);
      }
    });
  });

  group('PicnicAnalytics 경계에서 적용된다', () {
    late RecordingGa4Sink sink;
    late PicnicAnalytics analytics;

    setUp(() {
      sink = RecordingGa4Sink();
      analytics = PicnicAnalytics(sink: sink);
    });

    test('user property language 는 jp 로 나간다', () async {
      await analytics.setUserProperties(
        userId: 'u1',
        isLogin: true,
        language: 'ja',
      );

      expect(sink.userProperties[Ga4UserProperty.language], 'jp');
    });

    test('레거시 locale 속성은 정규화하지 않고 원본 ja 를 유지한다', () async {
      await analytics.setUserProperties(
        userId: 'u1',
        isLogin: true,
        language: 'ja',
        locale: 'ja',
      );

      expect(sink.userProperties[Ga4UserProperty.locale], 'ja');
    });

    test('login 의 selected_language 는 jp 로 나간다', () async {
      await analytics.logLogin(method: 'kakao', selectedLanguage: 'ja');

      expect(sink.last.parameters[Ga4Param.selectedLanguage], 'jp');
    });

    test('sign_up 의 selected_language 는 jp 로 나간다', () async {
      await analytics.logSignUp(method: 'apple', selectedLanguage: 'ja');

      expect(sink.last.parameters[Ga4Param.selectedLanguage], 'jp');
    });

    test('공백만 있는 언어는 undefined 로 대체된다', () async {
      await analytics.logLogin(method: 'google', selectedLanguage: '  ');

      expect(
        sink.last.parameters[Ga4Param.selectedLanguage],
        Ga4Value.undefined,
      );
    });
  });
}

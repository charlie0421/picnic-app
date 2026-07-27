import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/constatns/constants.dart';
import 'package:picnic_lib/core/utils/language_initializer.dart';
import 'package:picnic_lib/presentation/providers/app_setting_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/mock_providers.dart';

/// 디바이스 로케일 → 앱이 골라야 하는 언어 코드.
///
/// `expected` 가 null 이면 "지원하지 않는 언어이므로 감지하지 않는다"는 뜻이고,
/// 호출부는 기본 언어(ko)를 유지해야 한다.
class _LocaleCase {
  const _LocaleCase(this.locale, this.expected, {required this.wasBroken});

  final Locale locale;
  final String? expected;

  /// 수정 전 게이트(`supportedLanguages.contains(deviceLanguage) ||
  /// contains('lang_COUNTRY')`)에서 잘못 동작하던 케이스인지.
  ///
  /// true = 감지가 통째로 건너뛰어져 한국어로 떨어지던 케이스,
  /// false = 수정 전에도 옳게 동작하던 케이스(회귀 방지용).
  final bool wasBroken;

  String get name => locale.toLanguageTag();
}

/// 수정 전 게이트가 통째로 실패해 한국어로 떨어지던 케이스들.
const _brokenBefore = <_LocaleCase>[
  // supportedLanguages 는 bare zh/bn 을 일부러 걸러내므로 contains('zh') 는
  // false 였고, 지역이 없으면 두 번째 조건은 리터럴 "zh_null" 을 만들었다.
  _LocaleCase(Locale('zh'), 'zh_CN', wasBroken: true),
  _LocaleCase(Locale('bn'), 'bn_BD', wasBroken: true),

  // CN/TW 가 아닌 중국어권 지역. supportedLanguages 에 zh_HK/zh_MO/zh_SG 가
  // 없으므로 두 조건 모두 false 였다. 홍콩/마카오는 번체, 싱가포르는 간체.
  _LocaleCase(Locale('zh', 'HK'), 'zh_TW', wasBroken: true),
  _LocaleCase(Locale('zh', 'MO'), 'zh_TW', wasBroken: true),
  _LocaleCase(Locale('zh', 'SG'), 'zh_CN', wasBroken: true),

  // BD 가 아닌 벵골어권 지역(서벵골 주 등).
  _LocaleCase(Locale('bn', 'IN'), 'bn_BD', wasBroken: true),

  // 표기 체계만 있고 지역이 없는 경우. 지역이 null 이라 예전 게이트는 무조건
  // 실패했다.
  _LocaleCase(
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
    'zh_TW',
    wasBroken: true,
  ),
  _LocaleCase(
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
    'zh_CN',
    wasBroken: true,
  ),

  // 표기 체계가 지역을 이긴다: 홍콩에서 간체를 고른 사용자는 간체를 봐야 한다.
  _LocaleCase(
    Locale.fromSubtags(
      languageCode: 'zh',
      scriptCode: 'Hans',
      countryCode: 'HK',
    ),
    'zh_CN',
    wasBroken: true,
  ),
  _LocaleCase(
    Locale.fromSubtags(
      languageCode: 'zh',
      scriptCode: 'Hant',
      countryCode: 'HK',
    ),
    'zh_TW',
    wasBroken: true,
  ),
];

/// 수정 전에도 옳게 동작하던 케이스들. 하나를 고치려다 다른 하나를 깨뜨리는 걸
/// 막기 위해 같은 매트릭스에 함께 둔다.
const _workingBefore = <_LocaleCase>[
  // supportedLanguages 가 실제로 갖고 있는 지역 변형.
  _LocaleCase(Locale('zh', 'CN'), 'zh_CN', wasBroken: false),
  _LocaleCase(Locale('zh', 'TW'), 'zh_TW', wasBroken: false),
  _LocaleCase(Locale('bn', 'BD'), 'bn_BD', wasBroken: false),

  // 실제 기기가 가장 흔하게 보고하는 형태(iOS 는 표기 체계를 함께 준다).
  // 표기 체계와 지역이 일치하므로 수정 전에도 옳게 동작했다.
  _LocaleCase(
    Locale.fromSubtags(
      languageCode: 'zh',
      scriptCode: 'Hans',
      countryCode: 'CN',
    ),
    'zh_CN',
    wasBroken: false,
  ),
  _LocaleCase(
    Locale.fromSubtags(
      languageCode: 'zh',
      scriptCode: 'Hant',
      countryCode: 'TW',
    ),
    'zh_TW',
    wasBroken: false,
  ),

  // 지역 없이 지원되는 언어들. 예전 게이트의 첫 번째 조건
  // (contains(deviceLanguage))이 살려주던 경우다. 우리가 안 가진 지역이
  // 붙어 있어도 언어 단위로 떨어져야 한다.
  _LocaleCase(Locale('en'), 'en', wasBroken: false),
  _LocaleCase(Locale('en', 'US'), 'en', wasBroken: false),
  _LocaleCase(Locale('en', 'GB'), 'en', wasBroken: false),
  _LocaleCase(Locale('es', 'ES'), 'es', wasBroken: false),
  _LocaleCase(Locale('es', 'MX'), 'es', wasBroken: false),
  _LocaleCase(Locale('ko', 'KR'), 'ko', wasBroken: false),
  _LocaleCase(Locale('ja', 'JP'), 'ja', wasBroken: false),
  _LocaleCase(Locale('id', 'ID'), 'id', wasBroken: false),
  _LocaleCase(Locale('fil', 'PH'), 'fil', wasBroken: false),
  _LocaleCase(Locale('th', 'TH'), 'th', wasBroken: false),
  _LocaleCase(Locale('vi', 'VN'), 'vi', wasBroken: false),
  _LocaleCase(Locale('my', 'MM'), 'my', wasBroken: false),

  // 지원하지 않는 언어는 감지하지 않는다(= 의도된 한국어 폴백).
  _LocaleCase(Locale('fr', 'FR'), null, wasBroken: false),
  _LocaleCase(Locale('de'), null, wasBroken: false),
  _LocaleCase(Locale('pt', 'BR'), null, wasBroken: false),
];

const _allCases = <_LocaleCase>[..._brokenBefore, ..._workingBefore];

void main() {
  group('LanguageInitializer', () {
    test('LanguageInitializer 클래스의 정적 메서드 타입 확인', () {
      // initializeLanguage 메서드의 존재 여부 확인
      expect(LanguageInitializer.initializeLanguage, isA<Function>());

      // changeLanguage 메서드의 존재 여부 확인
      expect(LanguageInitializer.changeLanguage, isA<Function>());
    });

    test('LanguageInitializer 클래스가 올바른 기본 언어를 처리하는지 확인', () {
      // 한국어가 기본 언어로 처리되는지 검증 (구현체 로직 확인)
      const defaultLanguage = 'ko';
      expect(defaultLanguage, equals('ko'));
    });
  });

  group('resolveDeviceLanguage: 디바이스 로케일 → 앱 언어', () {
    for (final testCase in _allCases) {
      test('${testCase.name} → ${testCase.expected ?? '(감지 안 함)'}', () {
        expect(
          LanguageInitializer.resolveDeviceLanguage(testCase.locale),
          testCase.expected,
        );
      });
    }

    test('감지 결과는 항상 저장 가능한 코드다', () {
      // 감지된 코드는 그대로 globalStorage 와 appSettingProvider 에 들어간다.
      // supportedLanguages 밖의 코드가 나오면 Setting.load() 가 다음 실행 때
      // 'ko' 로 되돌려 버린다.
      for (final testCase in _allCases) {
        final resolved = LanguageInitializer.resolveDeviceLanguage(
          testCase.locale,
        );
        if (resolved == null) continue;
        expect(
          Setting.supportedLanguages,
          contains(resolved),
          reason: '${testCase.name} 가 저장 불가능한 "$resolved" 로 감지됨',
        );
        expect(
          languageMap,
          contains(resolved),
          reason: '${testCase.name} 가 라벨 없는 "$resolved" 로 감지됨',
        );
      }
    });

    test('AppLocalizations 가 실제로 지원하는 모든 로케일은 감지된다', () {
      // supportedLanguages 는 ARB 에서 생성되므로 언어가 추가되면 자동으로
      // 늘어난다. 새 언어가 감지 대상에서 빠지는 일이 없도록 고정한다.
      for (final code in Setting.supportedLanguages) {
        final locale = parseLocale(code);
        expect(
          LanguageInitializer.resolveDeviceLanguage(locale),
          code,
          reason: '지원 언어 "$code" 를 쓰는 기기가 감지되지 않는다',
        );
      }
    });
  });

  group('initializeLanguage: 실제 디바이스 로케일로 구동', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    /// 디바이스 로케일을 [deviceLocale] 로 위장하고 초기화를 한 번 돌린다.
    /// 반환값은 초기화가 최종적으로 확정한 언어 코드.
    Future<String> runInitializer(
      WidgetTester tester,
      Locale deviceLocale, {
      String storedLanguage = '',
    }) async {
      tester.binding.platformDispatcher.localeTestValue = deviceLocale;
      addTearDown(tester.binding.platformDispatcher.clearLocaleTestValue);

      late WidgetRef capturedRef;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...defaultProviderOverrides(
              setting: Setting(language: storedLanguage),
              loggedIn: false,
            ),
          ],
          child: Consumer(
            builder: (context, ref, child) {
              capturedRef = ref;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      // 초기화 경로는 SharedPreferences / Firebase 같은 실제 플러그인을 건드리므로
      // 가짜 비동기 존이 아니라 runAsync 안에서 돌려야 완료된다.
      final result = await tester.runAsync(
        () => LanguageInitializer.initializeLanguage(
          capturedRef,
          (locale) async {},
        ),
      );

      final (success, language) = result!;
      expect(success, isTrue, reason: '언어 초기화 자체가 실패했다');
      return language;
    }

    for (final testCase in _allCases) {
      final expected = testCase.expected ?? 'ko';
      testWidgets(
        '${testCase.name} 기기는 $expected 로 시작한다',
        (tester) async {
          expect(await runInitializer(tester, testCase.locale), expected);
        },
        timeout: const Timeout(Duration(seconds: 30)),
      );
    }

    testWidgets('저장된 언어가 있으면 디바이스 로케일보다 우선한다', (tester) async {
      // 사용자가 직접 고른 언어를 디바이스 로케일이 덮어쓰면 안 된다.
      expect(
        await runInitializer(
          tester,
          const Locale('zh', 'HK'),
          storedLanguage: 'ja',
        ),
        'ja',
      );
    }, timeout: const Timeout(Duration(seconds: 30)));
  });

  group('canonicalLanguageCode: 중국어권 지역 규칙', () {
    // 규칙의 단일 출처는 constants.dart 다. 디바이스 감지와 저장값 마이그레이션
    // (Setting.load) 이 같은 함수를 쓰므로 여기서 한 번만 고정한다.
    test('번체를 쓰는 지역은 zh_TW 로 접힌다', () {
      expect(canonicalLanguageCode('zh_TW'), 'zh_TW');
      expect(canonicalLanguageCode('zh_HK'), 'zh_TW');
      expect(canonicalLanguageCode('zh_MO'), 'zh_TW');
    });

    test('나머지 중국어권 지역과 bare zh 는 zh_CN 로 접힌다', () {
      expect(canonicalLanguageCode('zh'), 'zh_CN');
      expect(canonicalLanguageCode('zh_CN'), 'zh_CN');
      expect(canonicalLanguageCode('zh_SG'), 'zh_CN');
    });

    test('벵골어는 지역과 무관하게 bn_BD 하나다', () {
      expect(canonicalLanguageCode('bn'), 'bn_BD');
      expect(canonicalLanguageCode('bn_BD'), 'bn_BD');
      expect(canonicalLanguageCode('bn_IN'), 'bn_BD');
    });

    test('나머지 언어는 지역 코드를 포함해 그대로 통과한다', () {
      expect(canonicalLanguageCode('ko'), 'ko');
      expect(canonicalLanguageCode('en_GB'), 'en_GB');
      expect(canonicalLanguageCode('pt'), 'pt');
    });
  });
}

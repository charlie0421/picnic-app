import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/ui/mypage_theme.dart';
import 'package:picnic_lib/ui/novel_theme.dart';
import 'package:picnic_lib/ui/pic_theme.dart';
import 'package:picnic_lib/ui/style.dart';

import '../helpers/test_app.dart';
import '../helpers/test_environment.dart';

/// Pretendard 는 picnic_lib 의 **패키지 폰트**다. 앱들은 자체 폰트 선언이
/// 없으므로 빌드된 FontManifest.json 에는 `packages/picnic_lib/Pretendard`
/// 만 등록된다. `TextStyle` 이 `package: 'picnic_lib'` 없이 맨
/// `'Pretendard'` 를 요청하면 어떤 폰트와도 매칭되지 않아 프로덕션이
/// Roboto(Android) / SF Pro(iOS) 로 폴백한다 — 디자인 시스템 타이포그래피
/// 전체가 조용히 무효가 된다.
///
/// `package:` 파라미터는 fontFamily 를 `packages/<pkg>/<family>` 로
/// 치환하는 문법 설탕이므로, 여기서는 치환된 최종 문자열을 고정한다.
void main() {
  const resolved = 'packages/picnic_lib/Pretendard';

  setUpAll(initTestColors);

  test('getTextStyle 은 패키지 접두사가 붙은 Pretendard 를 요청한다', () {
    for (final typo in AppTypo.values) {
      expect(
        getTextStyle(typo).fontFamily,
        resolved,
        reason: '$typo 가 맨 Pretendard 를 요청하면 프로덕션에서 '
            '시스템 폰트로 폴백한다',
      );
    }
  });

  testWidgets('테마의 모든 TextTheme 스타일도 패키지 접두사를 쓴다', (tester) async {
    // picThemeLight 등은 초기화 시점에 ScreenUtil(.w)을 읽는 최상위
    // ThemeData 라 위젯 하네스로 ScreenUtil 을 먼저 살린다.
    await tester.pumpWidget(buildTestApp(const SizedBox.shrink()));
    final themes = {
      'picThemeLight': picThemeLight,
      'novelThemeLight': novelThemeLight,
      'mypageThemeLight': mypageThemeLight,
    };
    themes.forEach((name, theme) {
      final tt = theme.textTheme;
      final styles = <String, TextStyle?>{
        'displayLarge': tt.displayLarge,
        'displayMedium': tt.displayMedium,
        'displaySmall': tt.displaySmall,
        'headlineMedium': tt.headlineMedium,
        'headlineSmall': tt.headlineSmall,
        'titleLarge': tt.titleLarge,
        'titleMedium': tt.titleMedium,
        'titleSmall': tt.titleSmall,
        'bodyLarge': tt.bodyLarge,
        'bodyMedium': tt.bodyMedium,
        'bodySmall': tt.bodySmall,
        'labelLarge': tt.labelLarge,
        'labelSmall': tt.labelSmall,
      };
      styles.forEach((slot, style) {
        if (style?.fontFamily == null) return;
        expect(
          style!.fontFamily,
          resolved,
          reason: '$name.$slot 이 패키지 접두사 없는 폰트를 요청한다',
        );
      });
    });
  });

  test('picnic_lib 에 접두사 없는 Pretendard 요청이 다시 생기지 않는다', () {
    // 위 두 테스트는 알려진 진입점만 본다. 새 파일이 맨 'Pretendard' 를
    // 요청하면 놓치므로, 소스 수준에서 한 번 더 고정한다.
    // (getTextStyle/테마를 거치지 않는 TextStyle 직접 생성이 대상)
    final offenders = <String>[];
    final dir = Directory('lib');
    for (final f in dir.listSync(recursive: true)) {
      if (f is! File || !f.path.endsWith('.dart')) continue;
      final src = f.readAsStringSync();
      var index = 0;
      while (true) {
        index = src.indexOf("fontFamily: 'Pretendard'", index);
        if (index == -1) break;
        // 같은 인자 목록 안에 package: 'picnic_lib' 가 따라오는지 본다.
        final window = src.substring(index, (index + 120).clamp(0, src.length));
        if (!window.contains("package: 'picnic_lib'")) {
          offenders.add(f.path);
        }
        index += 1;
      }
    }
    expect(
      offenders,
      isEmpty,
      reason: '접두사 없는 Pretendard 요청은 프로덕션에서 시스템 폰트로 '
          '폴백한다. package: \'picnic_lib\' 를 함께 지정할 것',
    );
  });
}

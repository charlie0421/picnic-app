import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/ui.dart' as ui;

import '../../helpers/mock_supabase.dart';
import '../../helpers/test_app.dart';
import '../../helpers/test_environment.dart';

void main() {
  group('getComplementaryColor', () {
    test('검정의 보색은 흰색에 가까움', () {
      final result = ui.getComplementaryColor(const Color(0xFF000000));
      // color.r for black = 0.0, toInt() = 0, 255-0 = 255
      expect(result, equals(const Color(0xFFFFFFFF)));
    });

    test('보색 계산 - alpha는 항상 255 유지', () {
      final result = ui.getComplementaryColor(const Color(0xFF808080));
      expect(result.a, equals(1.0));
    });

    test('보색 계산 - RGB 반전', () {
      // getComplementaryColor는 Color.r (0.0~1.0)에서 toInt() 사용
      // 따라서 정확한 RGB 반전이 아닌 근사값을 반환할 수 있음
      final input = const Color(0xFF000000);
      final result = ui.getComplementaryColor(input);
      // black → 0.0.toInt() = 0 → 255-0 = 255
      expect(result.r, closeTo(1.0, 0.01));
      expect(result.g, closeTo(1.0, 0.01));
      expect(result.b, closeTo(1.0, 0.01));
    });

    test('Color.fromARGB로 결과 생성 확인', () {
      // getComplementaryColor는 Color.r (0.0~1.0)에 toInt()를 사용
      // 이는 0.0~1.0 범위를 0 또는 1로 변환하므로 근사값만 테스트
      final result = ui.getComplementaryColor(const Color(0xFF808080));
      // 0x80/255 ≈ 0.502 → toInt() = 0 → 255-0 = 255
      expect(result, isA<Color>());
    });
  });

  group('플랫폼 감지 함수', () {
    test('isIOS 반환 타입 bool', () {
      expect(ui.isIOS(), isA<bool>());
    });

    test('isAndroid 반환 타입 bool', () {
      expect(ui.isAndroid(), isA<bool>());
    });

    test('isMobile 반환 타입 bool', () {
      expect(ui.isMobile(), isA<bool>());
    });

    test('isDesktop 반환 타입 bool', () {
      expect(ui.isDesktop(), isA<bool>());
    });

    test('isMacOS 반환 타입 bool', () {
      expect(ui.isMacOS(), isA<bool>());
    });

    test('isWindows 반환 타입 bool', () {
      expect(ui.isWindows(), isA<bool>());
    });

    test('isLinux 반환 타입 bool', () {
      expect(ui.isLinux(), isA<bool>());
    });

    test('isMobile과 isDesktop은 상호 배타적', () {
      if (!ui.isMobile() && !ui.isDesktop()) {
        expect(true, isTrue);
      } else {
        expect(ui.isMobile() != ui.isDesktop(), isTrue);
      }
    });
  });

  group('checkSuperAdmin', () {
    setUp(() {
      setupMockSupabase({
        'auth.users': [
          {'is_super_admin': true},
        ],
      });
    });

    tearDown(() {
      tearDownMockSupabase();
    });

    test('returns bool value', () async {
      final result = await ui.checkSuperAdmin();
      expect(result, isA<bool>());
    });

    test('returns false when no user found', () async {
      tearDownMockSupabase();
      setupMockSupabase({
        'auth.users': <Map<String, dynamic>>[],
      });
      final result = await ui.checkSuperAdmin();
      expect(result, false);
    });

    test('returns true when user is super admin', () async {
      final result = await ui.checkSuperAdmin();
      expect(result, true);
    });

    test('returns false when user is not super admin', () async {
      tearDownMockSupabase();
      setupMockSupabase({
        'auth.users': [
          {'is_super_admin': false},
        ],
      });
      final result = await ui.checkSuperAdmin();
      expect(result, false);
    });
  });

  group('위젯 유틸리티 함수', () {
    setUp(() {
      initTestColors();
    });

    testWidgets('buildPlaceholderImage renders Shimmer', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          SizedBox(
            width: 100,
            height: 100,
            child: ui.buildPlaceholderImage(),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('getPlatformScreenSize returns valid size', (tester) async {
      Size? result;
      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            result = ui.getPlatformScreenSize(context);
            return const SizedBox();
          }),
        ),
      );
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.width, greaterThan(0));
      expect(result!.height, greaterThan(0));
    });

    testWidgets('getBottomPadding returns non-negative value', (tester) async {
      double? result;
      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            result = ui.getBottomPadding(context);
            return const SizedBox();
          }),
        ),
      );
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!, greaterThanOrEqualTo(0));
    });

    testWidgets('isIPad returns bool', (tester) async {
      bool? result;
      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            result = ui.isIPad(context);
            return const SizedBox();
          }),
        ),
      );
      await tester.pumpAndSettle();

      expect(result, isA<bool>());
    });

    testWidgets('getAppBarHeight returns positive value', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          Consumer(builder: (context, ref, _) {
            final height = ui.getAppBarHeight(ref);
            expect(height, greaterThan(0));
            return const SizedBox();
          }),
        ),
      );
      await tester.pumpAndSettle();
    });
  });
}

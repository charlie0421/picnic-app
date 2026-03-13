import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/snackbar_util.dart';
import 'package:picnic_lib/ui/style.dart';

import '../../helpers/test_app.dart';
import '../../helpers/test_environment.dart';

void main() {
  group('SnackbarUtil 위젯 테스트', () {
    setUp(() {
      initTestColors();
    });

    testWidgets('show 메서드로 스낵바 표시', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            return ElevatedButton(
              onPressed: () {
                SnackbarUtil().show('테스트 메시지', context: context);
              },
              child: const Text('Show'),
            );
          }),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Show'));
      await tester.pump();

      expect(find.text('테스트 메시지'), findsOneWidget);
    });

    testWidgets('success 타입 스낵바', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            return ElevatedButton(
              onPressed: () {
                SnackbarUtil().success('성공!', context: context);
              },
              child: const Text('Success'),
            );
          }),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Success'));
      await tester.pump();

      expect(find.text('성공!'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('error 타입 스낵바', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            return ElevatedButton(
              onPressed: () {
                SnackbarUtil().error('오류 발생', context: context);
              },
              child: const Text('Error'),
            );
          }),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Error'));
      await tester.pump();

      expect(find.text('오류 발생'), findsOneWidget);
      expect(find.byIcon(Icons.error), findsOneWidget);
    });

    testWidgets('info 타입 스낵바', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            return ElevatedButton(
              onPressed: () {
                SnackbarUtil().info('알림', context: context);
              },
              child: const Text('Info'),
            );
          }),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Info'));
      await tester.pump();

      expect(find.text('알림'), findsOneWidget);
      expect(find.byIcon(Icons.info), findsOneWidget);
    });

    testWidgets('warning 타입 스낵바', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            return ElevatedButton(
              onPressed: () {
                SnackbarUtil().warning('경고!', context: context);
              },
              child: const Text('Warn'),
            );
          }),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Warn'));
      await tester.pump();

      expect(find.text('경고!'), findsOneWidget);
      expect(find.byIcon(Icons.warning), findsOneWidget);
    });

    testWidgets('actionLabel과 onAction 포함', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            return ElevatedButton(
              onPressed: () {
                SnackbarUtil().show(
                  '메시지',
                  context: context,
                  actionLabel: '확인',
                  onAction: () {},
                );
              },
              child: const Text('Show'),
            );
          }),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Show'));
      await tester.pump();

      expect(find.text('메시지'), findsOneWidget);
      expect(find.text('확인'), findsOneWidget);
    });

    testWidgets('messenger null일 때 예외 없이 처리', (tester) async {
      // scaffoldMessengerKey 없이, context도 없이 호출
      expect(
        () => SnackbarUtil().show('test'),
        returnsNormally,
      );
    });
  });

  group('SnackbarUtil 색상 매핑 테스트', () {
    setUp(() {
      initTestColors();
    });

    testWidgets('success 타입은 primary500 배경색 사용', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            return ElevatedButton(
              onPressed: () {
                SnackbarUtil().show('msg', type: SnackType.success, context: context);
              },
              child: const Text('Tap'),
            );
          }),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tap'));
      await tester.pump();

      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.backgroundColor, equals(AppColors.primary500));
    });

    testWidgets('error 타입은 statusError 배경색 사용', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            return ElevatedButton(
              onPressed: () {
                SnackbarUtil().show('msg', type: SnackType.error, context: context);
              },
              child: const Text('Tap'),
            );
          }),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tap'));
      await tester.pump();

      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.backgroundColor, equals(AppColors.statusError));
    });

    testWidgets('info 타입은 point500 배경색 사용', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            return ElevatedButton(
              onPressed: () {
                SnackbarUtil().show('msg', type: SnackType.info, context: context);
              },
              child: const Text('Tap'),
            );
          }),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tap'));
      await tester.pump();

      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.backgroundColor, equals(AppColors.point500));
    });

    testWidgets('warning 타입은 secondary500 배경색 사용', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            return ElevatedButton(
              onPressed: () {
                SnackbarUtil().show('msg', type: SnackType.warning, context: context);
              },
              child: const Text('Tap'),
            );
          }),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tap'));
      await tester.pump();

      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.backgroundColor, equals(AppColors.secondary500));
    });
  });

  group('SnackbarUtil 아이콘 및 액션 분기 테스트', () {
    setUp(() {
      initTestColors();
    });

    testWidgets('icon 파라미터 없으면 아이콘 위젯 미노출', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            return ElevatedButton(
              onPressed: () {
                SnackbarUtil().show('no icon', context: context);
              },
              child: const Text('Tap'),
            );
          }),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tap'));
      await tester.pump();

      expect(find.text('no icon'), findsOneWidget);
      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('show에 직접 icon 전달 시 해당 아이콘 노출', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            return ElevatedButton(
              onPressed: () {
                SnackbarUtil().show('with icon', context: context, icon: Icons.star);
              },
              child: const Text('Tap'),
            );
          }),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tap'));
      await tester.pump();

      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('actionLabel만 있고 onAction 없으면 액션 버튼 미노출', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            return ElevatedButton(
              onPressed: () {
                SnackbarUtil().show(
                  'msg',
                  context: context,
                  actionLabel: '버튼',
                );
              },
              child: const Text('Tap'),
            );
          }),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tap'));
      await tester.pump();

      expect(find.text('msg'), findsOneWidget);
      expect(find.text('버튼'), findsNothing);
    });

    testWidgets('onAction만 있고 actionLabel 없으면 액션 버튼 미노출', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            return ElevatedButton(
              onPressed: () {
                SnackbarUtil().show(
                  'msg',
                  context: context,
                  onAction: () {},
                );
              },
              child: const Text('Tap'),
            );
          }),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tap'));
      await tester.pump();

      expect(find.text('msg'), findsOneWidget);
      // SnackBarAction should not be present
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.action, isNull);
    });

    testWidgets('액션 버튼이 SnackBar에 포함됨', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            return ElevatedButton(
              onPressed: () {
                SnackbarUtil().show(
                  'msg',
                  context: context,
                  actionLabel: '실행',
                  onAction: () {},
                );
              },
              child: const Text('Tap'),
            );
          }),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tap'));
      await tester.pump();

      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.action, isNotNull);
      expect(snackBar.action!.label, equals('실행'));
    });
  });

  group('SnackbarUtil 스낵바 속성 테스트', () {
    setUp(() {
      initTestColors();
    });

    testWidgets('SnackBar는 floating 동작 사용', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            return ElevatedButton(
              onPressed: () {
                SnackbarUtil().show('msg', context: context);
              },
              child: const Text('Tap'),
            );
          }),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tap'));
      await tester.pump();

      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.behavior, equals(SnackBarBehavior.floating));
    });

    testWidgets('기본 타입은 info', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            return ElevatedButton(
              onPressed: () {
                SnackbarUtil().show('default type', context: context);
              },
              child: const Text('Tap'),
            );
          }),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tap'));
      await tester.pump();

      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      // Default type is info, which maps to point500
      expect(snackBar.backgroundColor, equals(AppColors.point500));
    });

    testWidgets('새 스낵바 표시 시 이전 스낵바 제거 (clearSnackBars)', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            return Column(
              children: [
                ElevatedButton(
                  onPressed: () {
                    SnackbarUtil().show('첫 번째', context: context);
                  },
                  child: const Text('First'),
                ),
                ElevatedButton(
                  onPressed: () {
                    SnackbarUtil().show('두 번째', context: context);
                  },
                  child: const Text('Second'),
                ),
              ],
            );
          }),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('First'));
      await tester.pump();
      expect(find.text('첫 번째'), findsOneWidget);

      await tester.tap(find.text('Second'));
      await tester.pump();
      // 두 번째 스낵바가 표시되어야 함
      expect(find.text('두 번째'), findsOneWidget);
    });

    testWidgets('convenience 메서드에 actionLabel/onAction 전달', (tester) async {
      await tester.pumpWidget(
        buildTestApp(
          Builder(builder: (context) {
            return ElevatedButton(
              onPressed: () {
                SnackbarUtil().success(
                  '성공 메시지',
                  context: context,
                  actionLabel: '되돌리기',
                  onAction: () {},
                );
              },
              child: const Text('Tap'),
            );
          }),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Tap'));
      await tester.pump();

      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.action, isNotNull);
      expect(snackBar.action!.label, equals('되돌리기'));
      // success convenience method should also include check_circle icon
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('scaffoldMessengerKey를 통한 스낵바 표시', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          scaffoldMessengerKey: SnackbarUtil.scaffoldMessengerKey,
          home: const Scaffold(body: SizedBox.shrink()),
        ),
      );
      await tester.pumpAndSettle();

      // context 없이 scaffoldMessengerKey를 통해 표시
      SnackbarUtil().show('via key');
      await tester.pump();

      expect(find.text('via key'), findsOneWidget);
    });
  });

  group('SnackType', () {
    test('4개 유형 존재', () {
      expect(SnackType.values.length, equals(4));
    });

    test('모든 유형 name 확인', () {
      expect(SnackType.success.name, equals('success'));
      expect(SnackType.error.name, equals('error'));
      expect(SnackType.info.name, equals('info'));
      expect(SnackType.warning.name, equals('warning'));
    });

    test('index 확인', () {
      expect(SnackType.success.index, equals(0));
      expect(SnackType.error.index, equals(1));
      expect(SnackType.info.index, equals(2));
      expect(SnackType.warning.index, equals(3));
    });
  });

  group('SnackbarUtil', () {
    test('싱글톤 패턴', () {
      final a = SnackbarUtil();
      final b = SnackbarUtil();
      expect(identical(a, b), isTrue);
    });

    test('scaffoldMessengerKey 초기 상태', () {
      expect(SnackbarUtil.scaffoldMessengerKey.currentState, isNull);
    });

    test('scaffoldMessengerKey는 GlobalKey<ScaffoldMessengerState> 타입', () {
      expect(
        SnackbarUtil.scaffoldMessengerKey,
        isA<GlobalKey<ScaffoldMessengerState>>(),
      );
    });

    test('여러 번 생성해도 동일 인스턴스', () {
      final instances = List.generate(5, (_) => SnackbarUtil());
      for (final instance in instances) {
        expect(identical(instance, instances.first), isTrue);
      }
    });
  });
}

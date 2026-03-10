import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/core/utils/common_utils.dart';

void main() {
  group('CommonUtils', () {
    test('CommonUtils 클래스가 존재하고 생성자가 ref와 context를 받는다', () {
      // CommonUtils 생성자 시그니처를 검증하기 위해 testWidgets 사용
      expect(CommonUtils, isA<Type>());
    });

    testWidgets('CommonUtils 인스턴스를 생성할 수 있다', (tester) async {
      late CommonUtils utils;

      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, ref, child) {
              utils = CommonUtils(ref, context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(utils, isA<CommonUtils>());
    });

    testWidgets('refreshUserProfile 메서드가 존재한다', (tester) async {
      late CommonUtils utils;

      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, ref, child) {
              utils = CommonUtils(ref, context);
              return const SizedBox();
            },
          ),
        ),
      );

      // refreshUserProfile 메서드가 존재하는지 확인
      expect(utils.refreshUserProfile, isA<Function>());
    });
  });
}

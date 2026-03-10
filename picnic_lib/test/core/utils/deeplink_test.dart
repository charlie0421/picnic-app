import 'package:test/test.dart';
import 'package:picnic_lib/core/utils/deeplink.dart';

void main() {
  group('Deeplink 함수', () {
    test('createBranchLink 함수가 존재하고 올바른 시그니처를 가진다', () {
      // createBranchLink는 String?과 String?을 받아 Future<String>을 반환하는 함수
      expect(createBranchLink, isA<Function>());
    });

    test('getLongUrl 함수가 존재하고 올바른 시그니처를 가진다', () {
      // getLongUrl은 String을 받아 Future<String>을 반환하는 함수
      expect(getLongUrl, isA<Function>());
    });

    test('createBranchLink의 반환 타입은 Future<String>이다', () {
      // 함수 타입 확인 (실제 호출 없이 시그니처만 검증)
      expect(
        createBranchLink,
        isA<Future<String> Function(String?, String?)>(),
      );
    });

    test('getLongUrl의 반환 타입은 Future<String>이다', () {
      // 함수 타입 확인 (실제 호출 없이 시그니처만 검증)
      expect(
        getLongUrl,
        isA<Future<String> Function(String)>(),
      );
    });
  });
}

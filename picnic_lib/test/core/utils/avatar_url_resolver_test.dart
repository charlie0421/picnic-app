import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/avatar_url_resolver.dart';

void main() {
  group('resolveAvatarImageUrl', () {
    test('null이면 빈 문자열 반환', () {
      expect(resolveAvatarImageUrl(null), equals(''));
    });

    test('빈 문자열이면 빈 문자열 반환', () {
      expect(resolveAvatarImageUrl(''), equals(''));
    });

    test('공백만 있으면 빈 문자열 반환', () {
      expect(resolveAvatarImageUrl('   '), equals(''));
    });

    test('scheme-less URL에 https: 추가', () {
      expect(
        resolveAvatarImageUrl('//example.com/avatar.png'),
        equals('https://example.com/avatar.png'),
      );
    });

    test('https URL은 그대로 반환', () {
      expect(
        resolveAvatarImageUrl('https://example.com/avatar.png'),
        equals('https://example.com/avatar.png'),
      );
    });

    test('http URL은 그대로 반환', () {
      expect(
        resolveAvatarImageUrl('http://example.com/avatar.png'),
        equals('http://example.com/avatar.png'),
      );
    });

    test('앞뒤 공백 제거', () {
      expect(
        resolveAvatarImageUrl('  https://example.com/avatar.png  '),
        equals('https://example.com/avatar.png'),
      );
    });

    test('Supabase storage URL 처리', () {
      const url =
          'https://xtijtefcycoeqludlngc.supabase.co/storage/v1/object/public/avatars/user123.jpg';
      expect(resolveAvatarImageUrl(url), equals(url));
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/user_profiles.dart';

void main() {
  group('UserProfilesModel', () {
    test('필수 필드로 생성', () {
      const profile = UserProfilesModel(
        isAdmin: false,
        starCandy: 100,
        starCandyBonus: 10,
        jmaCandy: 50,
      );
      expect(profile.isAdmin, isFalse);
      expect(profile.starCandy, equals(100));
      expect(profile.starCandyBonus, equals(10));
      expect(profile.jmaCandy, equals(50));
      expect(profile.id, isNull);
      expect(profile.nickname, isNull);
      expect(profile.avatarUrl, isNull);
      expect(profile.countryCode, isNull);
      expect(profile.deletedAt, isNull);
      expect(profile.birthDate, isNull);
      expect(profile.gender, isNull);
      expect(profile.birthTime, isNull);
    });

    test('모든 필드 포함 생성', () {
      final profile = UserProfilesModel(
        id: 'user-123',
        nickname: 'picnic_user',
        avatarUrl: 'https://example.com/avatar.jpg',
        countryCode: 'KR',
        isAdmin: true,
        starCandy: 500,
        starCandyBonus: 50,
        jmaCandy: 200,
        birthDate: DateTime(2000, 5, 15),
        gender: 'female',
        birthTime: '14:30',
      );
      expect(profile.id, equals('user-123'));
      expect(profile.nickname, equals('picnic_user'));
      expect(profile.avatarUrl, isNotNull);
      expect(profile.countryCode, equals('KR'));
      expect(profile.isAdmin, isTrue);
      expect(profile.birthDate, equals(DateTime(2000, 5, 15)));
      expect(profile.gender, equals('female'));
      expect(profile.birthTime, equals('14:30'));
    });

    test('삭제된 유저', () {
      final profile = UserProfilesModel(
        isAdmin: false,
        starCandy: 0,
        starCandyBonus: 0,
        jmaCandy: 0,
        deletedAt: DateTime(2025, 1, 1),
      );
      expect(profile.deletedAt, isNotNull);
    });
  });

  group('UserAgreement', () {
    test('생성', () {
      final agreement = UserAgreement(
        terms: DateTime(2025, 1, 1),
        privacy: DateTime(2025, 1, 1),
      );
      expect(agreement.terms, equals(DateTime(2025, 1, 1)));
      expect(agreement.privacy, equals(DateTime(2025, 1, 1)));
    });

    test('다른 동의 시간', () {
      final agreement = UserAgreement(
        terms: DateTime(2024, 6, 1),
        privacy: DateTime(2025, 1, 15),
      );
      expect(agreement.terms.isBefore(agreement.privacy), isTrue);
    });
  });
}

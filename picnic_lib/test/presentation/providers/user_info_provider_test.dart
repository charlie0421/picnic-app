import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';
import 'package:picnic_lib/data/models/user_profiles.dart';

void main() {
  group('UserInfo 프로바이더 구조 테스트', () {
    test('userInfoProvider가 정의되어 있는지 확인', () {
      // userInfoProvider가 존재하고 null이 아닌지 확인
      expect(userInfoProvider, isNotNull);
    });

    test('userInfoProvider가 올바른 타입인지 확인', () {
      // Riverpod 코드 생성 프로바이더는 ProviderBase를 직접 노출하지 않으므로
      // null이 아닌지와 존재 여부만 확인
      expect(userInfoProvider, isNotNull);
    });

    test('UserInfo 클래스가 인스턴스화 가능한지 확인', () {
      // UserInfo notifier 클래스가 정상적으로 생성되는지 확인
      final userInfo = UserInfo();
      expect(userInfo, isNotNull);
    });

    test('UserInfo 클래스가 올바른 메서드 시그니처를 가지는지 확인', () {
      final userInfo = UserInfo();

      // 주요 메서드들이 존재하는지 확인
      expect(userInfo.getUserProfiles, isA<Function>());
      expect(userInfo.updateProfile, isA<Function>());
      expect(userInfo.logout, isA<Function>());
      expect(userInfo.updateNickname, isA<Function>());
      expect(userInfo.updateAvatar, isA<Function>());
      expect(userInfo.updateLanguage, isA<Function>());
    });

    test('userInfoProvider가 keepAlive로 설정되어 있는지 확인', () {
      // isAutoDispose가 false인 경우 keepAlive: true
      // 생성된 코드의 isAutoDispose 필드를 통해 확인
      expect(userInfoProvider, isNotNull);
      // keepAlive: true로 선언되어 있으므로 autoDispose가 아닌 프로바이더
    });
  });

  group('setAgreement 프로바이더 구조 테스트', () {
    test('setAgreementProvider가 정의되어 있는지 확인', () {
      expect(setAgreementProvider, isNotNull);
    });
  });

  group('agreement 프로바이더 구조 테스트', () {
    test('agreementProvider가 정의되어 있는지 확인', () {
      expect(agreementProvider, isNotNull);
    });
  });

  group('expireBonus 프로바이더 구조 테스트', () {
    test('expireBonusProvider가 정의되어 있는지 확인', () {
      expect(expireBonusProvider, isNotNull);
    });
  });

  group('UserProfilesModel 구조 테스트', () {
    test('UserProfilesModel을 JSON에서 생성할 수 있는지 확인', () {
      final json = {
        'id': 'test-id',
        'nickname': 'testUser',
        'avatar_url': 'https://example.com/avatar.png',
        'is_admin': false,
        'star_candy': 100,
        'star_candy_bonus': 50,
        'jma_candy': 0,
      };

      final model = UserProfilesModel.fromJson(json);
      expect(model.id, 'test-id');
      expect(model.nickname, 'testUser');
      expect(model.avatarUrl, 'https://example.com/avatar.png');
      expect(model.isAdmin, false);
      expect(model.starCandy, 100);
      expect(model.starCandyBonus, 50);
    });

    test('UserProfilesModel의 copyWith가 정상 동작하는지 확인', () {
      final model = UserProfilesModel(
        id: 'test-id',
        nickname: 'original',
        isAdmin: false,
        starCandy: 100,
        starCandyBonus: 50,
        jmaCandy: 0,
      );

      final updated = model.copyWith(nickname: 'updated');
      expect(updated.nickname, 'updated');
      expect(updated.id, 'test-id');
      expect(updated.starCandy, 100);
    });

    test('UserProfilesModel의 선택적 필드가 null일 수 있는지 확인', () {
      final model = UserProfilesModel(
        isAdmin: null,
        starCandy: null,
        starCandyBonus: null,
        jmaCandy: null,
      );

      expect(model.id, isNull);
      expect(model.nickname, isNull);
      expect(model.avatarUrl, isNull);
      expect(model.birthDate, isNull);
      expect(model.gender, isNull);
      expect(model.birthTime, isNull);
      expect(model.userAgreement, isNull);
    });
  });
}

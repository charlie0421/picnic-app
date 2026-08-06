import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/user_profiles.dart';

/// 관리자 화면 접근 predicate 는 DB 쪽 판정(`is_super_admin()` 함수 =
/// is_super_admin OR is_admin)과 일치해야 한다. UI 가 is_admin 만 읽으면
/// is_super_admin=true/is_admin=false 계정이 DB 는 통과하는데 UI 에서
/// 거부된다 (Sol 머지 게이트 리뷰, PR #135).
void main() {
  UserProfilesModel profile({bool? isAdmin, bool? isSuperAdmin}) =>
      UserProfilesModel(
        isAdmin: isAdmin,
        isSuperAdmin: isSuperAdmin,
        starCandy: 0,
        starCandyBonus: 0,
        jmaCandy: 0,
      );

  group('UserProfilesModel.hasAdminAccess', () {
    test('is_admin 또는 is_super_admin 어느 쪽이든 true 면 접근 가능', () {
      expect(profile(isAdmin: true).hasAdminAccess, isTrue);
      expect(
        profile(isAdmin: false, isSuperAdmin: true).hasAdminAccess,
        isTrue,
        reason: 'super-admin 전용 계정이 UI 에서 거부되면 안 된다',
      );
      expect(profile(isAdmin: true, isSuperAdmin: true).hasAdminAccess, isTrue);
    });

    test('둘 다 아니면(널 포함) 접근 불가', () {
      expect(profile().hasAdminAccess, isFalse);
      expect(
        profile(isAdmin: false, isSuperAdmin: false).hasAdminAccess,
        isFalse,
      );
    });

    test('is_super_admin 컬럼이 JSON 에서 파싱된다', () {
      final parsed = UserProfilesModel.fromJson(const {
        'is_admin': false,
        'is_super_admin': true,
        'star_candy': 0,
        'star_candy_bonus': 0,
        'jma_candy': 0,
      });
      expect(parsed.isSuperAdmin, isTrue);
      expect(parsed.hasAdminAccess, isTrue);
    });
  });
}

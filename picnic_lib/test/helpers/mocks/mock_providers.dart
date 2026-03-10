import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/data/models/user_profiles.dart';
import 'package:picnic_lib/presentation/providers/app_initialization_provider.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';

import '../factories/user_factory.dart';
import 'mock_repositories.dart';
import 'mock_services.dart';

/// 테스트에서 자주 사용하는 Riverpod 프로바이더 오버라이드 헬퍼
class MockProviders {
  /// 기본 프로바이더 오버라이드 목록
  ///
  /// 로그인된 기본 사용자와 초기화 완료 상태를 포함합니다.
  static List<Override> defaultOverrides({
    UserProfilesModel? user,
  }) {
    final defaultUser = user ?? UserFactory.create();
    return [
      userInfoProvider.overrideWith(
        () => _MockUserInfo(defaultUser),
      ),
      appInitializationProvider.overrideWith(
        () => _MockAppInitialization(),
      ),
    ];
  }

  /// 로그아웃 상태의 프로바이더 오버라이드 목록
  static List<Override> loggedOutOverrides() {
    return [
      userInfoProvider.overrideWith(
        () => _MockUserInfo(null),
      ),
      appInitializationProvider.overrideWith(
        () => _MockAppInitialization(),
      ),
    ];
  }

  /// 관리자 사용자 프로바이더 오버라이드 목록
  static List<Override> adminOverrides() {
    return defaultOverrides(user: UserFactory.createAdmin());
  }
}

/// UserInfo 프로바이더 Mock 구현
class _MockUserInfo extends UserInfo {
  final UserProfilesModel? _user;

  _MockUserInfo(this._user);

  @override
  Future<UserProfilesModel?> build() async => _user;
}

/// AppInitialization 프로바이더 Mock 구현
class _MockAppInitialization extends AppInitialization {
  @override
  AppInitializationState build() {
    return const AppInitializationState(
      hasNetwork: true,
      isBanned: false,
      isInitialized: true,
      isUpdateRequired: false,
    );
  }
}

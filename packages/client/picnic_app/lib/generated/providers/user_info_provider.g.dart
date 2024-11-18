// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../providers/user_info_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$setAgreementHash() => r'f5ea7908e415543bec42922eeb5b3ded5c41a1ff';

/// See also [setAgreement].
@ProviderFor(setAgreement)
final setAgreementProvider = AutoDisposeFutureProvider<bool>.internal(
  setAgreement,
  name: r'setAgreementProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$setAgreementHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SetAgreementRef = AutoDisposeFutureProviderRef<bool>;
String _$agreementHash() => r'26a35964df24d6a274cd694cdababfc29ca7954d';

/// See also [agreement].
@ProviderFor(agreement)
final agreementProvider = AutoDisposeFutureProvider<bool>.internal(
  agreement,
  name: r'agreementProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$agreementHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AgreementRef = AutoDisposeFutureProviderRef<bool>;
String _$expireBonusHash() => r'82bc57f8cd8c126e2c6ea34bcc534accc2e67c56';

/// See also [expireBonus].
@ProviderFor(expireBonus)
final expireBonusProvider =
    AutoDisposeFutureProvider<List<Map<String, dynamic>?>?>.internal(
  expireBonus,
  name: r'expireBonusProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$expireBonusHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ExpireBonusRef
    = AutoDisposeFutureProviderRef<List<Map<String, dynamic>?>?>;
String _$userInfoHash() => r'564ff98729d15c97281f781f5b5691bf1fbab30d';

/// See also [UserInfo].
@ProviderFor(UserInfo)
final userInfoProvider =
    AsyncNotifierProvider<UserInfo, UserProfilesModel?>.internal(
  UserInfo.new,
  name: r'userInfoProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$userInfoHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$UserInfo = AsyncNotifier<UserProfilesModel?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package

// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../presentation/providers/user_info_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$setAgreementHash() => r'5f5acc3d185f4fbdb0cc5792f40ee9162dbb0c5d';

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
String _$agreementHash() => r'8627f3bfab6c71d04b324d8f46d18149b4ad58f5';

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
String _$expireBonusHash() => r'e12174725f2a41af9098a049f2c5779245b9394d';

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
String _$userInfoHash() => r'2a63f067de264cbef8e1b0f3cacdf400b7293d78';

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

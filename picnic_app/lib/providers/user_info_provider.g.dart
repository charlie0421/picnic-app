// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_info_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$setAgreementHash() => r'9237251080c74c8c023203ad0e53880532b69695';

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

typedef SetAgreementRef = AutoDisposeFutureProviderRef<bool>;
String _$agreementHash() => r'21aab497013794ba4b374292ca2446925716c060';

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

typedef AgreementRef = AutoDisposeFutureProviderRef<bool>;
String _$expireBonusHash() => r'537d57703fc1091cb63d2399b34fa58322593b8a';

/// See also [expireBonus].
@ProviderFor(expireBonus)
final expireBonusProvider = AutoDisposeFutureProvider<int>.internal(
  expireBonus,
  name: r'expireBonusProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$expireBonusHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef ExpireBonusRef = AutoDisposeFutureProviderRef<int>;
String _$userInfoHash() => r'ab4a73b074dd02cec029c02e4f47892f31577d99';

/// See also [UserInfo].
@ProviderFor(UserInfo)
final userInfoProvider =
    AutoDisposeAsyncNotifierProvider<UserInfo, UserProfilesModel?>.internal(
  UserInfo.new,
  name: r'userInfoProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$userInfoHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$UserInfo = AutoDisposeAsyncNotifier<UserProfilesModel?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member

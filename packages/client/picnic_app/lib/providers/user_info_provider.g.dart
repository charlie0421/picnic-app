// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_info_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$setAgreementHash() => r'1830ce60a0568fbde5a3b160fbed0df53086dd82';

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
String _$agreementHash() => r'19af065f4378c3658f01d542e6202e2dd42d30a1';

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

typedef ExpireBonusRef
    = AutoDisposeFutureProviderRef<List<Map<String, dynamic>?>?>;
String _$userInfoHash() => r'6571327ab1a815889dd8a1f5a33988665249f9c9';

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

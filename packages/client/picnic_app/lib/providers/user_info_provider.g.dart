// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_info_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$setAgreementHash() => r'7479150514aae43a4de8b87220e5e79e8c34bd74';

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
String _$agreementHash() => r'fbae75d56e2875a22303b960a5317c95e4c9c23a';

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
String _$expireBonusHash() => r'fe02b786c2c9e7906eb893ed5b6bc8ca9015838b';

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
String _$userInfoHash() => r'51420edd84da63efb45f39f7e7bbc48bc390ce70';

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

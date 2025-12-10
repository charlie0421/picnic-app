// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../presentation/providers/user_info_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(UserInfo)
const userInfoProvider = UserInfoProvider._();

final class UserInfoProvider
    extends $AsyncNotifierProvider<UserInfo, UserProfilesModel?> {
  const UserInfoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userInfoProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userInfoHash();

  @$internal
  @override
  UserInfo create() => UserInfo();
}

String _$userInfoHash() => r'3f2a1fc5302d76a50f70b87228e9137a9e38f1e5';

abstract class _$UserInfo extends $AsyncNotifier<UserProfilesModel?> {
  FutureOr<UserProfilesModel?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref as $Ref<AsyncValue<UserProfilesModel?>, UserProfilesModel?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<UserProfilesModel?>, UserProfilesModel?>,
              AsyncValue<UserProfilesModel?>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(setAgreement)
const setAgreementProvider = SetAgreementProvider._();

final class SetAgreementProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  const SetAgreementProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'setAgreementProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$setAgreementHash();

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    return setAgreement(ref);
  }
}

String _$setAgreementHash() => r'5f5acc3d185f4fbdb0cc5792f40ee9162dbb0c5d';

@ProviderFor(agreement)
const agreementProvider = AgreementProvider._();

final class AgreementProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  const AgreementProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'agreementProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$agreementHash();

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    return agreement(ref);
  }
}

String _$agreementHash() => r'8627f3bfab6c71d04b324d8f46d18149b4ad58f5';

@ProviderFor(expireBonus)
const expireBonusProvider = ExpireBonusProvider._();

final class ExpireBonusProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Map<String, dynamic>?>?>,
          List<Map<String, dynamic>?>?,
          FutureOr<List<Map<String, dynamic>?>?>
        >
    with
        $FutureModifier<List<Map<String, dynamic>?>?>,
        $FutureProvider<List<Map<String, dynamic>?>?> {
  const ExpireBonusProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'expireBonusProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$expireBonusHash();

  @$internal
  @override
  $FutureProviderElement<List<Map<String, dynamic>?>?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Map<String, dynamic>?>?> create(Ref ref) {
    return expireBonus(ref);
  }
}

String _$expireBonusHash() => r'52799c85fc5a4058db994474371362bedd5a58f4';

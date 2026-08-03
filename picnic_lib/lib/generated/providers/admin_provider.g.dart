// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../presentation/providers/admin_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(adminRepository)
const adminRepositoryProvider = AdminRepositoryProvider._();

final class AdminRepositoryProvider
    extends
        $FunctionalProvider<AdminRepository, AdminRepository, AdminRepository>
    with $Provider<AdminRepository> {
  const AdminRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adminRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adminRepositoryHash();

  @$internal
  @override
  $ProviderElement<AdminRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AdminRepository create(Ref ref) {
    return adminRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AdminRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AdminRepository>(value),
    );
  }
}

String _$adminRepositoryHash() => r'766978cd1bbe8c0717c1e3b1fd41c8708e069b3a';

@ProviderFor(platformPaymentBreakdown)
const platformPaymentBreakdownProvider = PlatformPaymentBreakdownProvider._();

final class PlatformPaymentBreakdownProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PaymentBreakdownItem>>,
          List<PaymentBreakdownItem>,
          FutureOr<List<PaymentBreakdownItem>>
        >
    with
        $FutureModifier<List<PaymentBreakdownItem>>,
        $FutureProvider<List<PaymentBreakdownItem>> {
  const PlatformPaymentBreakdownProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'platformPaymentBreakdownProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$platformPaymentBreakdownHash();

  @$internal
  @override
  $FutureProviderElement<List<PaymentBreakdownItem>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<PaymentBreakdownItem>> create(Ref ref) {
    return platformPaymentBreakdown(ref);
  }
}

String _$platformPaymentBreakdownHash() =>
    r'ebd54fdf3feab5461baf1df06f10dc57c92adb40';

@ProviderFor(productPaymentBreakdown)
const productPaymentBreakdownProvider = ProductPaymentBreakdownProvider._();

final class ProductPaymentBreakdownProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PaymentBreakdownItem>>,
          List<PaymentBreakdownItem>,
          FutureOr<List<PaymentBreakdownItem>>
        >
    with
        $FutureModifier<List<PaymentBreakdownItem>>,
        $FutureProvider<List<PaymentBreakdownItem>> {
  const ProductPaymentBreakdownProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'productPaymentBreakdownProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$productPaymentBreakdownHash();

  @$internal
  @override
  $FutureProviderElement<List<PaymentBreakdownItem>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<PaymentBreakdownItem>> create(Ref ref) {
    return productPaymentBreakdown(ref);
  }
}

String _$productPaymentBreakdownHash() =>
    r'5641e21e947474d7df04fae3e9736c3383435c60';

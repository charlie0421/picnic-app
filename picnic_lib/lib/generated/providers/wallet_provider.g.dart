// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../presentation/providers/wallet_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(walletRepository)
const walletRepositoryProvider = WalletRepositoryProvider._();

final class WalletRepositoryProvider
    extends
        $FunctionalProvider<
          WalletRepository,
          WalletRepository,
          WalletRepository
        >
    with $Provider<WalletRepository> {
  const WalletRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'walletRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$walletRepositoryHash();

  @$internal
  @override
  $ProviderElement<WalletRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  WalletRepository create(Ref ref) {
    return walletRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WalletRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WalletRepository>(value),
    );
  }
}

String _$walletRepositoryHash() => r'ab0ea4192e9cedb4ada5d2b5348748d2250c272c';

@ProviderFor(WalletSummary)
const walletSummaryProvider = WalletSummaryProvider._();

final class WalletSummaryProvider
    extends $AsyncNotifierProvider<WalletSummary, WalletSummaryModel> {
  const WalletSummaryProvider._()
    : super(
        from: null,
        argument: null,
        retry: walletSummaryRetry,
        name: r'walletSummaryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$walletSummaryHash();

  @$internal
  @override
  WalletSummary create() => WalletSummary();
}

String _$walletSummaryHash() => r'f1ab34c474f649d0523ca582b4c487b810d53a21';

abstract class _$WalletSummary extends $AsyncNotifier<WalletSummaryModel> {
  FutureOr<WalletSummaryModel> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref =
        this.ref as $Ref<AsyncValue<WalletSummaryModel>, WalletSummaryModel>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<WalletSummaryModel>, WalletSummaryModel>,
              AsyncValue<WalletSummaryModel>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(CurrencyHistory)
const currencyHistoryProvider = CurrencyHistoryFamily._();

final class CurrencyHistoryProvider
    extends $AsyncNotifierProvider<CurrencyHistory, CurrencyHistoryPageModel> {
  const CurrencyHistoryProvider._({
    required CurrencyHistoryFamily super.from,
    required WalletCurrency super.argument,
  }) : super(
         retry: null,
         name: r'currencyHistoryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$currencyHistoryHash();

  @override
  String toString() {
    return r'currencyHistoryProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  CurrencyHistory create() => CurrencyHistory();

  @override
  bool operator ==(Object other) {
    return other is CurrencyHistoryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$currencyHistoryHash() => r'4d9a77529e8e369c5a75959254cf3b1d3ff43c44';

final class CurrencyHistoryFamily extends $Family
    with
        $ClassFamilyOverride<
          CurrencyHistory,
          AsyncValue<CurrencyHistoryPageModel>,
          CurrencyHistoryPageModel,
          FutureOr<CurrencyHistoryPageModel>,
          WalletCurrency
        > {
  const CurrencyHistoryFamily._()
    : super(
        retry: null,
        name: r'currencyHistoryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CurrencyHistoryProvider call(WalletCurrency currency) =>
      CurrencyHistoryProvider._(argument: currency, from: this);

  @override
  String toString() => r'currencyHistoryProvider';
}

abstract class _$CurrencyHistory
    extends $AsyncNotifier<CurrencyHistoryPageModel> {
  late final _$args = ref.$arg as WalletCurrency;
  WalletCurrency get currency => _$args;

  FutureOr<CurrencyHistoryPageModel> build(WalletCurrency currency);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args);
    final ref =
        this.ref
            as $Ref<
              AsyncValue<CurrencyHistoryPageModel>,
              CurrencyHistoryPageModel
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<CurrencyHistoryPageModel>,
                CurrencyHistoryPageModel
              >,
              AsyncValue<CurrencyHistoryPageModel>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

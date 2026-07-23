// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../presentation/providers/vote_transaction_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(voteTransactionRepository)
const voteTransactionRepositoryProvider = VoteTransactionRepositoryProvider._();

final class VoteTransactionRepositoryProvider
    extends
        $FunctionalProvider<
          VoteTransactionRepository,
          VoteTransactionRepository,
          VoteTransactionRepository
        >
    with $Provider<VoteTransactionRepository> {
  const VoteTransactionRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'voteTransactionRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$voteTransactionRepositoryHash();

  @$internal
  @override
  $ProviderElement<VoteTransactionRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  VoteTransactionRepository create(Ref ref) {
    return voteTransactionRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VoteTransactionRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VoteTransactionRepository>(value),
    );
  }
}

String _$voteTransactionRepositoryHash() =>
    r'9b5e403d28bc68d0957ca757fb2aded5956a6f90';

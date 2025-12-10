// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../presentation/providers/vote_item_request_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// VoteItemRequestRepository 인스턴스를 제공하는 provider

@ProviderFor(voteItemRequestRepository)
const voteItemRequestRepositoryProvider = VoteItemRequestRepositoryProvider._();

/// VoteItemRequestRepository 인스턴스를 제공하는 provider

final class VoteItemRequestRepositoryProvider
    extends
        $FunctionalProvider<
          VoteItemRequestRepository,
          VoteItemRequestRepository,
          VoteItemRequestRepository
        >
    with $Provider<VoteItemRequestRepository> {
  /// VoteItemRequestRepository 인스턴스를 제공하는 provider
  const VoteItemRequestRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'voteItemRequestRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$voteItemRequestRepositoryHash();

  @$internal
  @override
  $ProviderElement<VoteItemRequestRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  VoteItemRequestRepository create(Ref ref) {
    return voteItemRequestRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VoteItemRequestRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VoteItemRequestRepository>(value),
    );
  }
}

String _$voteItemRequestRepositoryHash() =>
    r'9b01bf85056d37e503a98edc367d8fd0d69c26e0';

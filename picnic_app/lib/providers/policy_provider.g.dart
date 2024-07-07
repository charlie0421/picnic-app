// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'policy_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$asyncPolicyHash() => r'4ebc20ed8352cdaf95e0be477d1f147da3aab8f7';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

abstract class _$AsyncPolicy
    extends BuildlessAutoDisposeAsyncNotifier<PolicyItemModel> {
  late final PolicyType type;
  late final PolicyLanguage language;

  FutureOr<PolicyItemModel> build({
    required PolicyType type,
    required PolicyLanguage language,
  });
}

/// See also [AsyncPolicy].
@ProviderFor(AsyncPolicy)
const asyncPolicyProvider = AsyncPolicyFamily();

/// See also [AsyncPolicy].
class AsyncPolicyFamily extends Family<AsyncValue<PolicyItemModel>> {
  /// See also [AsyncPolicy].
  const AsyncPolicyFamily();

  /// See also [AsyncPolicy].
  AsyncPolicyProvider call({
    required PolicyType type,
    required PolicyLanguage language,
  }) {
    return AsyncPolicyProvider(
      type: type,
      language: language,
    );
  }

  @override
  AsyncPolicyProvider getProviderOverride(
    covariant AsyncPolicyProvider provider,
  ) {
    return call(
      type: provider.type,
      language: provider.language,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'asyncPolicyProvider';
}

/// See also [AsyncPolicy].
class AsyncPolicyProvider
    extends AutoDisposeAsyncNotifierProviderImpl<AsyncPolicy, PolicyItemModel> {
  /// See also [AsyncPolicy].
  AsyncPolicyProvider({
    required PolicyType type,
    required PolicyLanguage language,
  }) : this._internal(
          () => AsyncPolicy()
            ..type = type
            ..language = language,
          from: asyncPolicyProvider,
          name: r'asyncPolicyProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$asyncPolicyHash,
          dependencies: AsyncPolicyFamily._dependencies,
          allTransitiveDependencies:
              AsyncPolicyFamily._allTransitiveDependencies,
          type: type,
          language: language,
        );

  AsyncPolicyProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.type,
    required this.language,
  }) : super.internal();

  final PolicyType type;
  final PolicyLanguage language;

  @override
  FutureOr<PolicyItemModel> runNotifierBuild(
    covariant AsyncPolicy notifier,
  ) {
    return notifier.build(
      type: type,
      language: language,
    );
  }

  @override
  Override overrideWith(AsyncPolicy Function() create) {
    return ProviderOverride(
      origin: this,
      override: AsyncPolicyProvider._internal(
        () => create()
          ..type = type
          ..language = language,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        type: type,
        language: language,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<AsyncPolicy, PolicyItemModel>
      createElement() {
    return _AsyncPolicyProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AsyncPolicyProvider &&
        other.type == type &&
        other.language == language;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, type.hashCode);
    hash = _SystemHash.combine(hash, language.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin AsyncPolicyRef on AutoDisposeAsyncNotifierProviderRef<PolicyItemModel> {
  /// The parameter `type` of this provider.
  PolicyType get type;

  /// The parameter `language` of this provider.
  PolicyLanguage get language;
}

class _AsyncPolicyProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<AsyncPolicy,
        PolicyItemModel> with AsyncPolicyRef {
  _AsyncPolicyProviderElement(super.provider);

  @override
  PolicyType get type => (origin as AsyncPolicyProvider).type;
  @override
  PolicyLanguage get language => (origin as AsyncPolicyProvider).language;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member

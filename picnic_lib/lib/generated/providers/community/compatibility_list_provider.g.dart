// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../presentation/providers/community/compatibility_list_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(CompatibilityList)
const compatibilityListProvider = CompatibilityListFamily._();

final class CompatibilityListProvider
    extends $NotifierProvider<CompatibilityList, CompatibilityHistoryModel> {
  const CompatibilityListProvider._({
    required CompatibilityListFamily super.from,
    required int? super.argument,
  }) : super(
         retry: null,
         name: r'compatibilityListProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$compatibilityListHash();

  @override
  String toString() {
    return r'compatibilityListProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  CompatibilityList create() => CompatibilityList();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CompatibilityHistoryModel value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CompatibilityHistoryModel>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CompatibilityListProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$compatibilityListHash() => r'bea62c5009a169ad6ba464a7a36b070fb8571b9f';

final class CompatibilityListFamily extends $Family
    with
        $ClassFamilyOverride<
          CompatibilityList,
          CompatibilityHistoryModel,
          CompatibilityHistoryModel,
          CompatibilityHistoryModel,
          int?
        > {
  const CompatibilityListFamily._()
    : super(
        retry: null,
        name: r'compatibilityListProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CompatibilityListProvider call({int? artistId}) =>
      CompatibilityListProvider._(argument: artistId, from: this);

  @override
  String toString() => r'compatibilityListProvider';
}

abstract class _$CompatibilityList
    extends $Notifier<CompatibilityHistoryModel> {
  late final _$args = ref.$arg as int?;
  int? get artistId => _$args;

  CompatibilityHistoryModel build({int? artistId});
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(artistId: _$args);
    final ref =
        this.ref as $Ref<CompatibilityHistoryModel, CompatibilityHistoryModel>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CompatibilityHistoryModel, CompatibilityHistoryModel>,
              CompatibilityHistoryModel,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

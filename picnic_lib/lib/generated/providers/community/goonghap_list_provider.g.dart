// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../../presentation/providers/community/goonghap_list_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(GoonghapList)
const goonghapListProvider = GoonghapListFamily._();

final class GoonghapListProvider
    extends $NotifierProvider<GoonghapList, GoonghapHistoryModel> {
  const GoonghapListProvider._({
    required GoonghapListFamily super.from,
    required int? super.argument,
  }) : super(
         retry: null,
         name: r'goonghapListProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$goonghapListHash();

  @override
  String toString() {
    return r'goonghapListProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  GoonghapList create() => GoonghapList();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GoonghapHistoryModel value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GoonghapHistoryModel>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is GoonghapListProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$goonghapListHash() => r'fe2093489483a682ef102a6e093f03a862b4de60';

final class GoonghapListFamily extends $Family
    with
        $ClassFamilyOverride<
          GoonghapList,
          GoonghapHistoryModel,
          GoonghapHistoryModel,
          GoonghapHistoryModel,
          int?
        > {
  const GoonghapListFamily._()
    : super(
        retry: null,
        name: r'goonghapListProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  GoonghapListProvider call({int? artistId}) =>
      GoonghapListProvider._(argument: artistId, from: this);

  @override
  String toString() => r'goonghapListProvider';
}

abstract class _$GoonghapList extends $Notifier<GoonghapHistoryModel> {
  late final _$args = ref.$arg as int?;
  int? get artistId => _$args;

  GoonghapHistoryModel build({int? artistId});
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(artistId: _$args);
    final ref = this.ref as $Ref<GoonghapHistoryModel, GoonghapHistoryModel>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<GoonghapHistoryModel, GoonghapHistoryModel>,
              GoonghapHistoryModel,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

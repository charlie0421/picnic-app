// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../presentation/providers/check_update_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(checkUpdate)
const checkUpdateProvider = CheckUpdateProvider._();

final class CheckUpdateProvider
    extends
        $FunctionalProvider<
          AsyncValue<UpdateInfo?>,
          UpdateInfo?,
          FutureOr<UpdateInfo?>
        >
    with $FutureModifier<UpdateInfo?>, $FutureProvider<UpdateInfo?> {
  const CheckUpdateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'checkUpdateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$checkUpdateHash();

  @$internal
  @override
  $FutureProviderElement<UpdateInfo?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<UpdateInfo?> create(Ref ref) {
    return checkUpdate(ref);
  }
}

String _$checkUpdateHash() => r'c7db080a83fce84b20629f6de61c6465d37480dc';

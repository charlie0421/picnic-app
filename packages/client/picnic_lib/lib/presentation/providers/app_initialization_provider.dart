import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:picnic_lib/presentation/providers/update_checker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '../../generated/providers/app_initialization_provider.freezed.dart';
part '../../generated/providers/app_initialization_provider.g.dart';

@freezed
class AppInitializationState with _$AppInitializationState {
  const factory AppInitializationState({
    @Default(true) bool hasNetwork,
    @Default(false) bool isBanned,
    @Default(false) bool isInitialized,
    @Default(false) bool isUpdateRequired,
    UpdateInfo? updateInfo,
  }) = _AppInitializationState;
}

@riverpod
class AppInitialization extends _$AppInitialization {
  @override
  AppInitializationState build() {
    return const AppInitializationState();
  }

  void updateState({
    bool? hasNetwork,
    bool? isBanned,
    bool? isInitialized,
    bool? isUpdateRequired,
    UpdateInfo? updateInfo,
  }) {
    state = state.copyWith(
      hasNetwork: hasNetwork ?? state.hasNetwork,
      isBanned: isBanned ?? state.isBanned,
      isInitialized: isInitialized ?? state.isInitialized,
      isUpdateRequired: isUpdateRequired ?? state.isUpdateRequired,
      updateInfo: updateInfo ?? state.updateInfo,
    );
  }
}

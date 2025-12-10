import 'package:picnic_lib/presentation/providers/check_update_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '../../generated/providers/app_initialization_provider.g.dart';

class AppInitializationState {
  final bool hasNetwork;
  final bool isBanned;
  final bool isInitialized;
  final bool isUpdateRequired;
  final UpdateInfo? updateInfo;

  const AppInitializationState({
    this.hasNetwork = true,
    this.isBanned = false,
    this.isInitialized = false,
    this.isUpdateRequired = false,
    this.updateInfo,
  });

  AppInitializationState copyWith({
    bool? hasNetwork,
    bool? isBanned,
    bool? isInitialized,
    bool? isUpdateRequired,
    UpdateInfo? updateInfo,
  }) {
    return AppInitializationState(
      hasNetwork: hasNetwork ?? this.hasNetwork,
      isBanned: isBanned ?? this.isBanned,
      isInitialized: isInitialized ?? this.isInitialized,
      isUpdateRequired: isUpdateRequired ?? this.isUpdateRequired,
      updateInfo: updateInfo ?? this.updateInfo,
    );
  }
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

import 'dart:async';
import 'dart:isolate';

import 'package:shorebird_code_push/shorebird_code_push.dart' as shorebird;

abstract interface class ShorebirdUpdateClient {
  bool get isAvailable;

  Future<shorebird.UpdateStatus> checkForUpdate();

  Future<void> update();

  Future<int?> readCurrentPatchNumber();

  Future<int?> readNextPatchNumber();
}

class ShorebirdUpdateClientImpl implements ShorebirdUpdateClient {
  @override
  bool get isAvailable => true;

  @override
  Future<shorebird.UpdateStatus> checkForUpdate() {
    return Isolate.run(() async {
      final updater = shorebird.ShorebirdUpdater();
      if (!updater.isAvailable) return shorebird.UpdateStatus.unavailable;
      return updater.checkForUpdate();
    });
  }

  @override
  Future<void> update() {
    return Isolate.run(() async {
      final updater = shorebird.ShorebirdUpdater();
      if (updater.isAvailable) await updater.update();
    });
  }

  @override
  Future<int?> readCurrentPatchNumber() {
    return Isolate.run(() async {
      final updater = shorebird.ShorebirdUpdater();
      if (!updater.isAvailable) return null;
      return (await updater.readCurrentPatch())?.number;
    });
  }

  @override
  Future<int?> readNextPatchNumber() {
    return Isolate.run(() async {
      final updater = shorebird.ShorebirdUpdater();
      if (!updater.isAvailable) return null;
      return (await updater.readNextPatch())?.number;
    });
  }
}

enum ShorebirdRunState { unavailable, upToDate, restartRequired, error }

class ShorebirdRunResult {
  const ShorebirdRunResult._(
    this.state, {
    this.currentPatchNumber,
    this.nextPatchNumber,
    this.error,
  });

  const ShorebirdRunResult.unavailable()
    : this._(ShorebirdRunState.unavailable);

  const ShorebirdRunResult.upToDate({int? currentPatchNumber})
    : this._(
        ShorebirdRunState.upToDate,
        currentPatchNumber: currentPatchNumber,
      );

  const ShorebirdRunResult.restartRequired({
    int? currentPatchNumber,
    int? nextPatchNumber,
  }) : this._(
         ShorebirdRunState.restartRequired,
         currentPatchNumber: currentPatchNumber,
         nextPatchNumber: nextPatchNumber,
       );

  const ShorebirdRunResult.error(Object error)
    : this._(ShorebirdRunState.error, error: error);

  final ShorebirdRunState state;
  final int? currentPatchNumber;
  final int? nextPatchNumber;
  final Object? error;

  @override
  bool operator ==(Object other) =>
      other is ShorebirdRunResult &&
      state == other.state &&
      currentPatchNumber == other.currentPatchNumber &&
      nextPatchNumber == other.nextPatchNumber;

  @override
  int get hashCode => Object.hash(state, currentPatchNumber, nextPatchNumber);
}

class ShorebirdUpdateCoordinator {
  ShorebirdUpdateCoordinator({
    ShorebirdUpdateClient Function()? clientFactory,
    this.checkTimeout = const Duration(seconds: 10),
    this.downloadTimeout = const Duration(seconds: 30),
  }) : _clientFactory = clientFactory ?? ShorebirdUpdateClientImpl.new;

  final ShorebirdUpdateClient Function() _clientFactory;
  final Duration checkTimeout;
  final Duration downloadTimeout;

  ShorebirdUpdateClient? _client;
  Future<ShorebirdRunResult>? _activeRun;
  bool _nativeOperationInProgress = false;

  Future<ShorebirdRunResult> run() {
    final activeRun = _activeRun;
    if (activeRun != null) return activeRun;
    if (_nativeOperationInProgress) {
      return Future.value(
        ShorebirdRunResult.error(
          StateError('A timed-out Shorebird operation is still running'),
        ),
      );
    }

    final run = _runOnce();
    _activeRun = run;
    run.whenComplete(() {
      if (identical(_activeRun, run)) {
        _activeRun = null;
      }
    });
    return run;
  }

  Future<ShorebirdRunResult> _runOnce() async {
    try {
      final client = _client ??= _clientFactory();
      if (!client.isAvailable) {
        return const ShorebirdRunResult.unavailable();
      }

      final status = await _runNative(client.checkForUpdate, checkTimeout);
      final currentPatchNumber = await _runNative(
        client.readCurrentPatchNumber,
        checkTimeout,
      );

      if (status == shorebird.UpdateStatus.restartRequired) {
        return ShorebirdRunResult.restartRequired(
          currentPatchNumber: currentPatchNumber,
          nextPatchNumber: await _runNative(
            client.readNextPatchNumber,
            checkTimeout,
          ),
        );
      }

      if (status == shorebird.UpdateStatus.outdated) {
        await _runNative(client.update, downloadTimeout);
        return ShorebirdRunResult.restartRequired(
          currentPatchNumber: currentPatchNumber,
          nextPatchNumber: await _runNative(
            client.readNextPatchNumber,
            checkTimeout,
          ),
        );
      }

      return ShorebirdRunResult.upToDate(
        currentPatchNumber: currentPatchNumber,
      );
    } catch (error) {
      return ShorebirdRunResult.error(error);
    }
  }

  Future<T> _runNative<T>(Future<T> Function() operation, Duration timeout) {
    _nativeOperationInProgress = true;
    late final Future<T> future;
    try {
      future = operation();
    } catch (_) {
      _nativeOperationInProgress = false;
      rethrow;
    }
    future.then<void>(
      (_) => _nativeOperationInProgress = false,
      onError: (Object error, StackTrace stackTrace) {
        _nativeOperationInProgress = false;
      },
    );
    return future.timeout(timeout);
  }
}

final shorebirdUpdateCoordinator = ShorebirdUpdateCoordinator();

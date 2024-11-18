import 'dart:async';

import 'package:picnic_app/models/community/compatibility.dart';
import 'package:picnic_app/models/vote/artist.dart';
import 'package:picnic_app/pages/community/compatibility_result_page.dart';
import 'package:picnic_app/providers/community/compatibility_repository_provider.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/util/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '../../generated/providers/community/compatibility_provider.g.dart';

@Riverpod(keepAlive: true)
class Compatibility extends _$Compatibility {
  Timer? _pollingTimer;
  bool _isPolling = false;
  DateTime? _waitStartTime;
  CompatibilityModel? _completedResult;
  Timer? _displayTimer;

  @override
  CompatibilityModel? build() {
    ref.onDispose(() {
      _pollingTimer?.cancel();
      _displayTimer?.cancel();
      _isPolling = false;
      _waitStartTime = null;
      _completedResult = null;
    });
    return null;
  }

  Future<void> createCompatibility({
    required String userId,
    required ArtistModel artist,
    required DateTime birthDate,
    required String gender,
    String? birthTime,
  }) async {
    try {
      final repository = ref.read(compatibilityRepositoryProvider);

      // 대기 시작 시간 기록
      _waitStartTime = DateTime.now();

      // 새로운 compatibility 생성 및 state 업데이트
      final compatibility = await repository.createCompatibility(
        userId: userId,
        artist: artist,
        birthDate: birthDate,
        birthTime: birthTime,
        gender: gender,
      );

      // state 업데이트
      _updateState(compatibility.copyWith(status: CompatibilityStatus.pending));

      // 결과 페이지로 이동
      ref.read(navigationInfoProvider.notifier).setCurrentPage(
            CompatibilityResultScreen(compatibilityId: compatibility.id),
          );

      // 30초 후에 결과를 표시하는 타이머 설정
      _displayTimer = Timer(const Duration(seconds: 30), () {
        if (_completedResult != null) {
          _updateState(_completedResult!);
          _completedResult = null;
        }
      });

      // 폴링 시작
      _startPolling(compatibility.id);

      logger.i('Compatibility analysis started');
    } catch (e) {
      logger.e('Failed to create compatibility', error: e);
      if (state != null) {
        _updateState(state!.copyWith(
          status: CompatibilityStatus.error,
          errorMessage: e.toString(),
        ));
      }
      rethrow;
    }
  }

  void _updateState(CompatibilityModel newState) {
    logger.d('Updating compatibility state: ${newState.status}');

    final hasWaitedEnough = _waitStartTime != null &&
        DateTime.now().difference(_waitStartTime!).inSeconds >= 30;

    if (!hasWaitedEnough) {
      // 30초가 지나지 않았다면 pending 상태 유지
      if (newState.status == CompatibilityStatus.completed) {
        _completedResult = newState;
        state = newState.copyWith(status: CompatibilityStatus.pending);
      } else {
        state = newState.copyWith(status: CompatibilityStatus.pending);
      }
    } else {
      // 30초가 지났다면 실제 상태로 업데이트
      state = newState;
      if (newState.status == CompatibilityStatus.completed) {
        _pollingTimer?.cancel();
        _isPolling = false;
      }
    }
  }

  Future<void> _startPolling(String compatibilityId) async {
    if (_isPolling) return;
    _isPolling = true;

    logger.d('Starting polling for compatibility ID: $compatibilityId');

    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (!_isPolling || state == null) {
        timer.cancel();
        return;
      }

      try {
        final repository = ref.read(compatibilityRepositoryProvider);
        final updated = await repository.getCompatibility(compatibilityId);

        if (updated != null) {
          _updateState(updated);
          logger.d('Polling update - Status: ${updated.status}');

          // 완료되었거나 에러가 발생하고 30초가 지났다면 폴링 중단
          if ((updated.isCompleted || updated.hasError) &&
              _waitStartTime != null &&
              DateTime.now().difference(_waitStartTime!).inSeconds >= 30) {
            timer.cancel();
            _isPolling = false;
            logger.d('Polling ended - Final status: ${updated.status}');
          }
        }
      } catch (e, s) {
        logger.e('Error during polling', error: e, stackTrace: s);
        _updateState(state!.copyWith(
          status: CompatibilityStatus.error,
          errorMessage: 'Polling error: $e',
        ));
        timer.cancel();
        _isPolling = false;
      }
    });
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _displayTimer?.cancel();
    _isPolling = false;
  }

  Future<void> refreshCompatibility() async {
    if (state == null) return;

    try {
      final repository = ref.read(compatibilityRepositoryProvider);
      final updated = await repository.getCompatibility(state!.id);
      if (updated != null) {
        _updateState(updated);
      }
    } catch (e) {
      logger.e('Error refreshing compatibility', error: e);
    }
  }
}

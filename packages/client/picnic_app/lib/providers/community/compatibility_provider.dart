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
  Timer? _displayTimer;
  Timer? _retryTimer;
  CompatibilityModel? _cachedResult;
  static const _waitDuration = Duration(seconds: 30);
  static const _maxRetries = 3;
  static const _retryDelay = Duration(seconds: 2);

  @override
  CompatibilityModel? build() {
    ref.onDispose(() {
      _displayTimer?.cancel();
      _retryTimer?.cancel();
      _cachedResult = null;
    });
    return null;
  }

  Future<CompatibilityModel> createCompatibility({
    required String userId,
    required ArtistModel artist,
    required DateTime birthDate,
    required String gender,
    String? birthTime,
  }) async {
    try {
      final repository = ref.read(compatibilityRepositoryProvider);

      // 새로운 compatibility 생성 (재시도 로직 포함)
      final compatibility =
          await _retryOnError(() => repository.createCompatibility(
                userId: userId,
                artist: artist,
                birthDate: birthDate,
                birthTime: birthTime,
                gender: gender,
              ));

      // 초기 상태를 pending으로 설정
      state = compatibility;

      // 결과 확인 및 30초 타이머 시작
      _startWaitTimer(compatibility);

      return compatibility;
    } catch (e) {
      logger.e('Failed to create compatibility after retries', error: e);
      rethrow;
    }
  }

  void _startWaitTimer(CompatibilityModel initial) {
    _displayTimer?.cancel();
    _retryTimer?.cancel();
    _cachedResult = null;

    // 5초 후에 결과를 미리 확인
    Future.delayed(const Duration(seconds: 5), () async {
      try {
        final repository = ref.read(compatibilityRepositoryProvider);
        final result = await _retryOnError(
          () => repository.getCompatibility(initial.id),
        );

        if (result != null &&
            (result.isCompleted ||
                result.status == CompatibilityStatus.error)) {
          _cachedResult = result;
        }
      } catch (e) {
        logger.e('Failed to fetch early result after retries', error: e);
      }
    });

    // 30초 타이머 시작
    _displayTimer = Timer(_waitDuration, () async {
      try {
        if (_cachedResult != null) {
          // 캐시된 결과가 있으면 사용
          state = _cachedResult;
        } else {
          // 캐시된 결과가 없으면 다시 한번 확인 (재시도 로직 포함)
          final repository = ref.read(compatibilityRepositoryProvider);
          final result = await _retryOnError(
            () => repository.getCompatibility(initial.id),
          );

          if (result != null) {
            state = result;
          } else {
            // 모든 재시도 실패 후에도 결과가 없으면 에러 상태로 변경
            _startErrorRetryTimer(initial);
          }
        }
      } catch (e) {
        logger.e('Failed to fetch final result after retries', error: e);
        _startErrorRetryTimer(initial);
      }
    });
  }

  // 에러 발생 시 자동 재시도 타이머 시작
  void _startErrorRetryTimer(CompatibilityModel initial) {
    _retryTimer?.cancel();

    state = initial.copyWith(
      status: CompatibilityStatus.error,
      errorMessage: '결과를 확인하는 중입니다. 잠시만 기다려주세요...',
    );

    // 2초 후에 다시 시도
    _retryTimer = Timer(_retryDelay, () => refresh());
  }

  // 에러 발생 시 재시도하는 유틸리티 함수
  Future<T> _retryOnError<T>(Future<T> Function() operation) async {
    int retryCount = 0;

    while (true) {
      try {
        return await operation();
      } catch (e) {
        retryCount++;
        if (retryCount >= _maxRetries) {
          rethrow;
        }

        logger.w('Operation failed, retrying (${retryCount}/${_maxRetries})',
            error: e);
        // 재시도 전에 잠시 대기
        await Future.delayed(_retryDelay);
      }
    }
  }

  // 수동으로 결과를 새로고침하는 메서드
  Future<void> refresh() async {
    if (state == null) return;

    try {
      final repository = ref.read(compatibilityRepositoryProvider);
      final result = await _retryOnError(
        () => repository.getCompatibility(state!.id),
      );

      if (result != null) {
        state = result;
      }
    } catch (e) {
      logger.e('Failed to refresh compatibility after retries', error: e);
    }
  }
}

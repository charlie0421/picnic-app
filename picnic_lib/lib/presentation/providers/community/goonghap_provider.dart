import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/data/models/community/goonghap.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '../../../generated/providers/community/goonghap_provider.g.dart';

class GoonghapLoadingNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

final goonghapLoadingProvider =
    NotifierProvider<GoonghapLoadingNotifier, bool>(
  GoonghapLoadingNotifier.new,
);

@Riverpod(keepAlive: true)
class Goonghap extends _$Goonghap {
  static const String _table = 'goonghap_results';
  // ignore: unused_field
  static const _i18nTable = 'goonghap_results_i18n';
  static const _retryDelay = Duration(seconds: 2);
  static const _maxRetries = 3;
  static const _defaultTimeout = Duration(seconds: 30);

  Timer? _retryTimer;

  @override
  AsyncValue<GoonghapModel?> build() {
    ref.onDispose(() {
      _retryTimer?.cancel();
    });
    return const AsyncValue.data(null);
  }

  final Set<String> _processingIds = {};

  Future<void> setGoonghap(GoonghapModel goonghap) async {
    // 이미 동일한 데이터로 처리 중인 경우 중복 실행 방지
    if (state.isLoading ||
        (state.hasValue && state.value?.id == goonghap.id)) {
      return;
    }

    state = AsyncValue.data(goonghap);
    ref.read(goonghapLoadingProvider.notifier).set(false);

    if (goonghap.isPending) {
      // 이미 처리 중인 ID인지 확인
      if (_processingIds.contains(goonghap.id)) {
        return;
      }
      _processingIds.add(goonghap.id);

      ref.read(goonghapLoadingProvider.notifier).set(true);
      await _processInBackground(goonghap);
      _processingIds.remove(goonghap.id);
    }
  }

  Future<void> _processInBackground(GoonghapModel initial) async {
    var retryCount = 0;
    String? lastErrorMessage;

    while (retryCount < _maxRetries) {
      try {
        final response = await supabase.functions.invoke('goonghap',
            body: {'goonghap_id': initial.id}).timeout(_defaultTimeout);

        logger.i('Edge function response: ${response.data}');

        if (response.status == 200) {
          // Wait for 30 seconds regardless of the response
          await Future.delayed(const Duration(seconds: 30));

          // Then refresh the data
          await loadGoonghap(initial.id, forceRefresh: true);
          return;
        }

        lastErrorMessage = 'Edge function error: ${response.data}';
        throw Exception(lastErrorMessage);
      } catch (e, s) {
        logger.e('Edge function error (attempt ${retryCount + 1}/$_maxRetries)',
            error: e, stackTrace: s);
        lastErrorMessage = e.toString();
        retryCount++;

        if (retryCount >= _maxRetries) {
          // 최대 재시도 횟수 도달 - 에러 상태로 설정하고 종료
          ref.read(goonghapLoadingProvider.notifier).set(false);

          final errorMsg = 'Failed after $_maxRetries attempts: $lastErrorMessage';

          try {
            await supabase.from(_table).update({
              'status': 'error',
              'error_message': errorMsg,
            }).eq('id', initial.id);
          } catch (dbError) {
            logger.e('Failed to update error status in DB', error: dbError);
          }

          state = AsyncValue.data(initial.copyWith(
            status: GoonghapStatus.error,
            errorMessage: errorMsg,
          ));
          return; // 무한 루프 방지 - 반드시 여기서 종료
        }

        // 다음 재시도 전 대기
        await Future.delayed(_retryDelay * retryCount);
        // rethrow 제거 - while 루프가 계속 실행되도록 함
      }
    }
  }

  Future<void> loadGoonghap(String id, {bool forceRefresh = false}) async {
    if (state.isLoading) return;

    if (!forceRefresh && state.hasValue && state.value?.id == id) {
      return;
    }

    state = const AsyncValue.loading();

    try {
      final mainResponse = await supabase.from(_table).select('''
          id,
          user_id,
          artist_id,
          user_birth_date,
          user_birth_time,
          gender,
          status,
          error_message,
          score,
          created_at,
          completed_at,
          is_paid,
          is_ads,
          artist:artist(*)
        ''').eq('id', id).maybeSingle().timeout(_defaultTimeout);

      if (mainResponse == null) {
        state = const AsyncValue.data(null);
        ref.read(goonghapLoadingProvider.notifier).set(false);
        return;
      }

      List<Map<String, dynamic>> i18nData = [];
      if (mainResponse['status'] == 'completed') {
        i18nData = await _getI18nDataEfficiently(id);
        if (i18nData.isEmpty) {
          mainResponse['status'] = 'error';
          mainResponse['error_message'] = 'No results found';
        }
      }

      final goonghap = GoonghapModel.fromJson({
        ...mainResponse,
        'i18n': i18nData,
      });

      state = AsyncValue.data(goonghap);

      // Only turn off loading if the status is not pending
      if (goonghap.status != GoonghapStatus.pending) {
        ref.read(goonghapLoadingProvider.notifier).set(false);
      }
    } catch (e, stack) {
      logger.e('Failed to load goonghap', error: e, stackTrace: stack);
      state = AsyncValue.error(e, stack);
      ref.read(goonghapLoadingProvider.notifier).set(false);
    }
  }

  Future<GoonghapModel?> createGoonghap({
    required ArtistModel artist,
    required DateTime birthDate,
    required String gender,
    String? birthTime,
  }) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');
      if (artist.birthDate == null) {
        throw Exception('Artist birth date is required for goonghap');
      }

      state = const AsyncValue.loading();
      ref.read(goonghapLoadingProvider.notifier).set(true);

      final goonghapData = {
        'user_id': userId,
        'artist_id': artist.id,
        'idol_birth_date': artist.birthDate!.toIso8601String(),
        'user_birth_date': birthDate.toIso8601String(),
        'user_birth_time': birthTime,
        'gender': gender,
        'status': 'pending',
        'is_paid': false,
      };

      final response = await supabase
          .from(_table)
          .insert(goonghapData)
          .select()
          .single();

      final newGoonghap = GoonghapModel.fromJson({
        ...response,
        'artist': artist.toJson(),
        'i18n': [],
      });

      state = AsyncValue.data(newGoonghap);
      _processInBackground(newGoonghap);

      return newGoonghap;
    } catch (e, stack) {
      logger.e('Failed to create goonghap', error: e, stackTrace: stack);
      state = AsyncValue.error(e, stack);
      ref.read(goonghapLoadingProvider.notifier).set(false);
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> _getI18nDataEfficiently(
      String goonghapId) async {
    try {
      // 보안을 위해 RPC 함수 사용 (is_paid=false일 때 details, tips 숨김)
      final response = await supabase
          .rpc('get_goonghap_i18n', params: {'p_goonghap_id': goonghapId})
          .timeout(_defaultTimeout);

      if (response == null) return [];
      return List<Map<String, dynamic>>.from(response as List);
    } catch (e, s) {
      logger.e('Error fetching i18n data', error: e, stackTrace: s);
      return [];
    }
  }

  Future<void> refresh() async {
    if (state.value == null) return;

    try {
      await loadGoonghap(state.value!.id, forceRefresh: true);
    } catch (e, s) {
      logger.e('Failed to refresh goonghap', error: e, stackTrace: s);
    }
  }

  /// 궁합 결과 구매 (별사탕 차감)
  ///
  /// Returns:
  /// - `OpenGoonghapResult.success`: 구매 성공
  /// - `OpenGoonghapResult.alreadyPaid`: 이미 구매됨
  /// - `OpenGoonghapResult.insufficientBalance`: 잔액 부족
  /// - `OpenGoonghapResult.error`: 오류 발생
  Future<OpenGoonghapResult> openGoonghap({
    required String goonghapId,
    required String userId,
    int starCandyRequired = 100,
  }) async {
    try {
      // 현재 상태에서 이미 구매된 경우 early return
      if (state.hasValue && state.value?.id == goonghapId && state.value?.isPaid == true) {
        return OpenGoonghapResult.alreadyPaid;
      }

      final response = await supabase.functions.invoke(
        'open-goonghap',
        body: {'userId': userId, 'goonghapId': goonghapId},
      ).timeout(_defaultTimeout);

      if (response.status != 200) {
        final errorData = response.data as Map<String, dynamic>?;
        final errorCode = errorData?['code'] as String?;

        // 잔액 부족 에러 처리
        if (errorCode == 'PAYMENT_FAILED') {
          final errorMessage = errorData?['message'] as String? ?? '';
          if (errorMessage.contains('부족') || errorMessage.contains('insufficient')) {
            return OpenGoonghapResult.insufficientBalance;
          }
        }

        logger.e('Open goonghap failed: ${response.data}');
        return OpenGoonghapResult.error;
      }

      final data = response.data as Map<String, dynamic>?;
      final alreadyPaid = data?['alreadyPaid'] == true;

      // 데이터 새로고침
      await loadGoonghap(goonghapId, forceRefresh: true);

      return alreadyPaid ? OpenGoonghapResult.alreadyPaid : OpenGoonghapResult.success;
    } catch (e, s) {
      logger.e('Error opening goonghap', error: e, stackTrace: s);
      return OpenGoonghapResult.error;
    }
  }
}

/// 궁합 구매 결과
enum OpenGoonghapResult {
  /// 구매 성공
  success,
  /// 이미 구매됨 (중복 구매 방지)
  alreadyPaid,
  /// 잔액 부족
  insufficientBalance,
  /// 오류 발생
  error,
}

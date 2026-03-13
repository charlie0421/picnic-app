import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/data/models/community/goonghap.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';
import 'package:picnic_lib/presentation/providers/community/goonghap_provider_helper.dart';
export 'package:picnic_lib/presentation/providers/community/goonghap_provider_helper.dart' show OpenGoonghapResult;
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
    if (GoonghapProviderHelper.shouldSkipSetGoonghap(
      isLoading: state.isLoading,
      hasValue: state.hasValue,
      currentId: state.value?.id,
      incomingId: goonghap.id,
    )) {
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

    while (!GoonghapProviderHelper.isRetryExhausted(retryCount)) {
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

        if (GoonghapProviderHelper.isRetryExhausted(retryCount)) {
          // 최대 재시도 횟수 도달 - 에러 상태로 설정하고 종료
          ref.read(goonghapLoadingProvider.notifier).set(false);

          final errorMsg = GoonghapProviderHelper.buildRetryExhaustedErrorMessage(
            maxRetries: _maxRetries,
            lastErrorMessage: lastErrorMessage,
          );

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
        await Future.delayed(GoonghapProviderHelper.calculateRetryDelay(
          retryCount: retryCount,
          baseDelay: _retryDelay,
        ));
        // rethrow 제거 - while 루프가 계속 실행되도록 함
      }
    }
  }

  Future<void> loadGoonghap(String id, {bool forceRefresh = false}) async {
    if (GoonghapProviderHelper.shouldSkipLoadGoonghap(
      isLoading: state.isLoading,
      hasValue: state.hasValue,
      currentId: state.value?.id,
      requestedId: id,
      forceRefresh: forceRefresh,
    )) {
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
      }

      final mergedData = GoonghapProviderHelper.mergeResponseWithI18n(
        mainResponse: mainResponse,
        i18nData: i18nData,
      );

      final goonghap = GoonghapModel.fromJson(mergedData);

      state = AsyncValue.data(goonghap);

      // Only turn off loading if the status is not pending
      if (GoonghapProviderHelper.shouldTurnOffLoading(goonghap.status)) {
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
      final validationError = GoonghapProviderHelper.validateCreateGoonghapInput(
        userId: userId,
        artistBirthDate: artist.birthDate,
      );
      if (validationError == CreateGoonghapValidationError.notAuthenticated) {
        throw Exception('User not authenticated');
      }
      if (validationError == CreateGoonghapValidationError.missingArtistBirthDate) {
        throw Exception('Artist birth date is required for goonghap');
      }

      state = const AsyncValue.loading();
      ref.read(goonghapLoadingProvider.notifier).set(true);

      final goonghapData = GoonghapProviderHelper.buildCreateGoonghapData(
        userId: userId!,
        artist: artist,
        birthDate: birthDate,
        gender: gender,
        birthTime: birthTime,
      );

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
      if (GoonghapProviderHelper.isAlreadyPaidInState(
        hasValue: state.hasValue,
        currentId: state.value?.id,
        isPaid: state.value?.isPaid,
        goonghapId: goonghapId,
      )) {
        return OpenGoonghapResult.alreadyPaid;
      }

      final response = await supabase.functions.invoke(
        'open-goonghap',
        body: {'userId': userId, 'goonghapId': goonghapId},
      ).timeout(_defaultTimeout);

      if (response.status != 200) {
        final errorData = response.data as Map<String, dynamic>?;
        final result = GoonghapProviderHelper.parseOpenGoonghapError(errorData);
        if (result == OpenGoonghapResult.error) {
          logger.e('Open goonghap failed: ${response.data}');
        }
        return result;
      }

      final data = response.data as Map<String, dynamic>?;
      final result = GoonghapProviderHelper.determineOpenGoonghapResult(data);

      // 데이터 새로고침
      await loadGoonghap(goonghapId, forceRefresh: true);

      return result;
    } catch (e, s) {
      logger.e('Error opening goonghap', error: e, stackTrace: s);
      return OpenGoonghapResult.error;
    }
  }
}

// OpenGoonghapResult is defined in goonghap_provider_helper.dart
// and re-exported via the import above.

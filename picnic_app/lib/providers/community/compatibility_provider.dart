import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_app/models/community/compatibility.dart';
import 'package:picnic_app/models/vote/artist.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:picnic_app/util/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '../../generated/providers/community/compatibility_provider.g.dart';

final compatibilityLoadingProvider = StateProvider<bool>((ref) => false);

@Riverpod(keepAlive: true)
class Compatibility extends _$Compatibility {
  static const String _table = 'compatibility_results';
  static const _i18nTable = 'compatibility_results_i18n';
  static const _retryDelay = Duration(seconds: 2);
  static const _maxRetries = 3;
  static const _defaultTimeout = Duration(seconds: 30);

  Timer? _retryTimer;

  @override
  AsyncValue<CompatibilityModel?> build() {
    ref.onDispose(() {
      _retryTimer?.cancel();
    });
    return const AsyncValue.data(null);
  }

  Future<void> setCompatibility(CompatibilityModel compatibility) async {
    state = AsyncValue.data(compatibility);

    // Reset loading state
    ref.read(compatibilityLoadingProvider.notifier).state = false;

    // If pending, start loading and processing
    if (compatibility.isPending) {
      ref.read(compatibilityLoadingProvider.notifier).state = true;
      _processInBackground(compatibility);
    }
  }

  Future<void> _processInBackground(CompatibilityModel initial) async {
    var retryCount = 0;

    while (retryCount < _maxRetries) {
      try {
        final response = await supabase.functions.invoke('compatibility',
            body: {'compatibility_id': initial.id}).timeout(_defaultTimeout);

        logger.i('Edge function response: ${response.data}');

        if (response.status == 200) {
          // Wait for 30 seconds regardless of the response
          await Future.delayed(const Duration(seconds: 30));

          // Then refresh the data
          await loadCompatibility(initial.id, forceRefresh: true);
          return;
        }

        throw Exception('Edge function error: ${response.data}');
      } catch (e) {
        logger.e('Edge function error (attempt ${retryCount + 1}/$_maxRetries)',
            error: e);
        retryCount++;

        if (retryCount == _maxRetries) {
          ref.read(compatibilityLoadingProvider.notifier).state = false;

          await supabase.from(_table).update({
            'status': 'error',
            'error_message': 'Failed after $_maxRetries attempts',
          }).eq('id', initial.id);

          state = AsyncValue.data(initial.copyWith(
            status: CompatibilityStatus.error,
            errorMessage: 'Failed after $_maxRetries attempts',
          ));
          return;
        }

        await Future.delayed(_retryDelay * retryCount);
      }
    }
  }

  Future<void> loadCompatibility(String id, {bool forceRefresh = false}) async {
    if (state.isLoading) return;

    // if (!forceRefresh && state.hasValue && state.value?.id == id) {
    //   return;
    // }

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
          compatibility_score,
          created_at,
          completed_at,
          is_paid,
          artist:artist(*)
        ''').eq('id', id).maybeSingle().timeout(_defaultTimeout);

      if (mainResponse == null) {
        state = const AsyncValue.data(null);
        ref.read(compatibilityLoadingProvider.notifier).state = false;
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

      final compatibility = CompatibilityModel.fromJson({
        ...mainResponse,
        'i18n': i18nData,
      });

      state = AsyncValue.data(compatibility);

      // Only turn off loading if the status is not pending
      if (compatibility.status != CompatibilityStatus.pending) {
        ref.read(compatibilityLoadingProvider.notifier).state = false;
      }
    } catch (e, stack) {
      logger.e('Failed to load compatibility', error: e, stackTrace: stack);
      state = AsyncValue.error(e, stack);
      ref.read(compatibilityLoadingProvider.notifier).state = false;
    }
  }

  Future<CompatibilityModel?> createCompatibility({
    required ArtistModel artist,
    required DateTime birthDate,
    required String gender,
    String? birthTime,
  }) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      state = const AsyncValue.loading();
      ref.read(compatibilityLoadingProvider.notifier).state = true;

      final compatibilityData = {
        'user_id': userId,
        'artist_id': artist.id,
        'idol_birth_date': artist.birthDate?.toIso8601String(),
        'user_birth_date': birthDate.toIso8601String(),
        'user_birth_time': birthTime,
        'gender': gender,
        'status': 'pending',
        'is_paid': false,
      };

      final response = await supabase
          .from(_table)
          .insert(compatibilityData)
          .select()
          .single();

      final newCompatibility = CompatibilityModel.fromJson({
        ...response,
        'artist': artist.toJson(),
        'i18n': [],
      });

      state = AsyncValue.data(newCompatibility);
      _processInBackground(newCompatibility);

      return newCompatibility;
    } catch (e, stack) {
      logger.e('Failed to create compatibility', error: e, stackTrace: stack);
      state = AsyncValue.error(e, stack);
      ref.read(compatibilityLoadingProvider.notifier).state = false;
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> _getI18nDataEfficiently(
      String compatibilityId) async {
    try {
      final response = await supabase
          .from(_i18nTable)
          .select()
          .eq('compatibility_id', compatibilityId)
          .timeout(_defaultTimeout);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      logger.e('Error fetching i18n data', error: e);
      return [];
    }
  }

  Future<void> refresh() async {
    if (state.value == null) return;

    try {
      await loadCompatibility(state.value!.id, forceRefresh: true);
    } catch (e) {
      logger.e('Failed to refresh compatibility', error: e);
    }
  }
}

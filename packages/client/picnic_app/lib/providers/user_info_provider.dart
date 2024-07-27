import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:picnic_app/auth_service.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/models/user_profiles.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:supabase_extensions/supabase_extensions.dart';

part 'user_info_provider.g.dart';

@riverpod
class UserInfo extends _$UserInfo {
  @override
  Future<UserProfilesModel?> build() async {
    logger.i('supabase.isLogged: ${supabase.isLogged}');
    if (!supabase.isLogged) {
      return null;
    }

    return getUserProfiles();
  }

  Future<UserProfilesModel?> getUserProfiles() async {
    logger.i('supabase.isLogged: ${supabase.isLogged}');
    if (!supabase.isLogged) {
      return null;
    }

    try {
      final response = await supabase
          .from('user_profiles')
          .select('*, user_agreement(*)')
          .single();
      logger.i('response.data: $response');
      state = AsyncValue.data(UserProfilesModel.fromJson(response));

      if (kDebugMode || response['is_admin'] == true) {
        ScreenProtector.preventScreenshotOff();
      } else {
        ScreenProtector.preventScreenshotOn();
      }

      return UserProfilesModel.fromJson(response);
    } catch (e, s) {
      logger.e(e);
      logger.e(s);

      rethrow;
    } finally {}
  }

  Future<UserProfilesModel?> login() async {
    return getUserProfiles();
  }

  Future<void> logout() async {
    final authService = AuthService();
    authService.signOut();

    ref.read(navigationInfoProvider.notifier).setBottomNavigationIndex(0);

    state = const AsyncValue.data(null);
  }

  Future<bool> updateNickname(String nickname) async {
    try {
      final response = await supabase.functions.invoke(
        'update-nickname',
        body: {'nickname': nickname},
      );

      if (response.status != 200) {
        final error = jsonDecode(response.data)['error'];
        logger.e('Error updating nickname: $error');
        return false;
      }

      final updatedProfile =
          UserProfilesModel.fromJson(jsonDecode(response.data)['data']);
      state = AsyncValue.data(updatedProfile);
      logger.i('Nickname updated successfully: ${updatedProfile.nickname}');
      return true;
    } catch (e, s) {
      logger.e('Error calling update-nickname function: $e');
      logger.e(s);
      return false;
    }
  }

  Future<void> updateAvatar(String url) async {
    await supabase.from('user_profiles').update({
      'avatar_url': url,
    });
    state = AsyncValue.data(state.value!.copyWith(avatar_url: url));
  }
}

@riverpod
Future<bool> setAgreement(AgreementRef ref) async {
  try {
    final response = await supabase.from('user_agreement').upsert({
      'id': supabase.auth.currentUser?.id,
      'terms': 'now',
      'privacy': 'now',
    }).select();

    return true;
  } catch (e, s) {
    logger.e(e, stackTrace: s);
    return false;
  }
}

@riverpod
Future<bool> agreement(AgreementRef ref) async {
  try {
    final response = await supabase.from('user_agreement').insert({
      'id': supabase.auth.currentUser?.id,
      'terms': DateTime.now().toUtc(),
      'privacy': DateTime.now().toUtc(),
    }).select();

    return true;
  } catch (e, s) {
    logger.e(e, stackTrace: s);
    return false;
  }
}

@riverpod
Future<int> expireBonus(ExpireBonusRef ref) async {
  try {
    // 현재 월의 시작일과 다음 월의 시작일을 계산합니다.
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final startOfNextMonth = DateTime(now.year, now.month + 1, 1);

    final response = await supabase
        .from('star_candy_bonus_history')
        .select('remain_amount')
        .gte('created_at', startOfMonth.toIso8601String())
        .lt('created_at', startOfNextMonth.toIso8601String());
    final List<dynamic> data = response;
    int sum = data.fold(
        0,
        (sum, item) =>
            sum + (int.tryParse(item['remain_amount'].toString()) ?? 0));

    return sum;
  } catch (e, s) {
    logger.e(e, stackTrace: s);
    return 0;
  }
}

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:picnic_app/models/user_profiles.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:picnic_app/util/auth_service.dart';
import 'package:picnic_app/util/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_extensions/supabase_extensions.dart';

part 'user_info_provider.g.dart';

@riverpod
class UserInfo extends _$UserInfo {
  StreamSubscription? _configSubscription;

  @override
  Future<UserProfilesModel?> build() async {
    if (!supabase.isLogged) {
      logger.i('User is not logged in');
      return null;
    }

    final profile = await getUserProfiles();

    ref.onDispose(() {
      logger.i('Disposing UserInfo provider');
      _configSubscription?.cancel();
    });

    return profile;
  }

  Future<UserProfilesModel?> getUserProfiles() async {
    if (!supabase.isLogged) {
      logger.i('User is not logged in');
      return null;
    }

    try {
      final response = await supabase
          .from('user_profiles')
          .select('*, user_agreement(*)')
          .eq('id', supabase.auth.currentUser!.id)
          .maybeSingle();

      logger.i('User profiles response: $response');
      if (response != null) {
        final userProfile = UserProfilesModel.fromJson(response);
        state = AsyncValue.data(userProfile);

        if (!kIsWeb) {
          if (kDebugMode || userProfile.isAdmin == true) {
            logger.i('Disabling screenshot prevention');
            ScreenProtector.preventScreenshotOff();
          } else {
            logger.i('Enabling screenshot prevention');
            ScreenProtector.preventScreenshotOn();
          }
        }

        return userProfile;
      } else {
        logger.w('User profile not found');
        return null;
      }
    } catch (e, s) {
      logger.e('Error getting user profiles', error: e, stackTrace: s);
      Sentry.captureException(e, stackTrace: s);

      state = AsyncValue.error(e, s);
      return null;
    }
  }

  Future<void> logout() async {
    logger.i('Logging out user');
    final authService = AuthService();
    authService.signOut();

    ref.read(navigationInfoProvider.notifier).setBottomNavigationIndex(0);

    state = const AsyncValue.data(null);
    logger.i('User logged out');
  }

  Future<bool> updateNickname(String nickname) async {
    logger.i('Updating nickname to: $nickname');
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
      logger.e('Error calling update-nickname function',
          error: e, stackTrace: s);
      return false;
    }
  }

  Future<void> updateAvatar(String url) async {
    logger.i('Updating avatar URL to: $url');
    await supabase.from('user_profiles').update({
      'avatar_url': url,
    });
    state = AsyncValue.data(state.value!.copyWith(avatarUrl: url));
    logger.i('Avatar URL updated successfully');
  }
}

@riverpod
Future<bool> setAgreement(AgreementRef ref) async {
  logger.i('Setting user agreement');
  try {
    await supabase.from('user_agreement').upsert({
      'id': supabase.auth.currentUser?.id,
      'terms': 'now',
      'privacy': 'now',
    }).select();

    logger.i('User agreement set successfully');
    return true;
  } catch (e, s) {
    logger.e('Error setting user agreement', error: e, stackTrace: s);
    Sentry.captureException(e, stackTrace: s);

    return false;
  }
}

@riverpod
Future<bool> agreement(AgreementRef ref) async {
  logger.i('Creating user agreement');
  try {
    await supabase.from('user_agreement').insert({
      'id': supabase.auth.currentUser?.id,
      'terms': DateTime.now().toUtc(),
      'privacy': DateTime.now().toUtc(),
    }).select();

    logger.i('User agreement created successfully');
    return true;
  } catch (e, s) {
    logger.e('Error creating user agreement', error: e, stackTrace: s);
    Sentry.captureException(e, stackTrace: s);

    return false;
  }
}

@riverpod
Future<List<Map<String, dynamic>?>?> expireBonus(ExpireBonusRef ref) async {
  logger.i('Calculating expire bonus');
  try {
    final response = await supabase.rpc('get_expiring_bonus_prediction');
    if (response != null && response is List) {
      logger.i('Expire bonus calculated: $response');
      return List<Map<String, dynamic>>.from(response);
    } else {
      throw Exception('Unexpected response format');
    }

    // final now = DateTime.now();
    // final startOfMonth = DateTime(now.year, now.month, 1);
    // final startOfNextMonth = DateTime(now.year, now.month + 1, 1);
    //
    // final response = await supabase
    //     .from('star_candy_bonus_history')
    //     .select('remain_amount')
    //     .gte('created_at', startOfMonth.toUtc())
    //     .lt('created_at', startOfNextMonth.toIso8601String());
    // final List<dynamic> data = response;
    // int sum = data.fold(
    //     0,
    //     (sum, item) =>
    //         sum + (int.tryParse(item['remain_amount'].toString()) ?? 0));
    //
    // logger.i('Expire bonus calculated: $sum');
    // return sum;
  } catch (e, s) {
    logger.e('Error calculating expire bonus', error: e, stackTrace: s);
    Sentry.captureException(e, stackTrace: s);

    return null;
  }
}

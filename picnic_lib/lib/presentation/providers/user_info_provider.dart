import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/data/models/user_profiles.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/core/services/auth/auth_service.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_extensions/supabase_extensions.dart';

part '../../generated/providers/user_info_provider.g.dart';

@Riverpod(keepAlive: true)
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
          .select(
              'id,avatar_url,star_candy,nickname,email,star_candy_bonus,is_admin,birth_date,gender,birth_time,user_agreement(id,terms,privacy)')
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

  Future<void> updateProfile({
    String? gender,
    DateTime? birthDate,
    String? birthTime,
  }) async {
    logger.i('Updating profile - gender: $gender, birthDate: $birthDate');
    try {
      if (!supabase.isLogged) {
        logger.w('Cannot update profile: user not logged in');
        return;
      }

      final updates = {
        if (gender != null) 'gender': gender,
        if (birthDate != null) 'birth_date': birthDate.toIso8601String(),
        if (birthTime != null) 'birth_time': birthTime,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

      await supabase.from('user_profiles').upsert({
        'id': supabase.auth.currentUser!.id,
        ...updates,
      });

      // Refresh the profile
      await getUserProfiles();

      logger.i('Profile updated successfully');
    } catch (e, s) {
      logger.e('Error updating profile', error: e, stackTrace: s);
      Sentry.captureException(e, stackTrace: s);
      rethrow;
    }
  }

  Future<void> logout() async {
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
    }).eq('id', supabase.auth.currentUser!.id);
    state = AsyncValue.data(state.value!.copyWith(avatarUrl: url));
    logger.i('Avatar URL updated successfully');
  }
}

@riverpod
Future<bool> setAgreement(Ref ref) async {
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
Future<bool> agreement(Ref ref) async {
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
Future<List<Map<String, dynamic>?>?> expireBonus(Ref ref) async {
  logger.i('Calculating expire bonus');
  try {
    final response = await supabase.rpc('get_expiring_bonus_prediction');
    if (response != null && response is List) {
      logger.i('Expire bonus calculated: $response');
      return List<Map<String, dynamic>>.from(response);
    } else {
      throw Exception('Unexpected response format');
    }
  } catch (e, s) {
    logger.e('Error calculating expire bonus', error: e, stackTrace: s);
    Sentry.captureException(e, stackTrace: s);

    return null;
  }
}

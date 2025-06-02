import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/core/services/auth/auth_service.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/data/models/user_profiles.dart';
import 'package:picnic_lib/data/repositories/repository_providers.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

part '../../generated/providers/user_info_provider.g.dart';

@Riverpod(keepAlive: true)
class UserInfo extends _$UserInfo {
  StreamSubscription? _configSubscription;

  @override
  Future<UserProfilesModel?> build() async {
    final userProfileRepository = ref.watch(userProfileRepositoryProvider);
    
    if (!userProfileRepository.isAuthenticated()) {
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
    final userProfileRepository = ref.read(userProfileRepositoryProvider);
    
    if (!userProfileRepository.isAuthenticated()) {
      logger.i('User is not logged in');
      return null;
    }

    try {
      final userProfile = await userProfileRepository.getCurrentUserProfile();
      
      if (userProfile != null) {
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
      final userProfileRepository = ref.read(userProfileRepositoryProvider);
      
      if (!userProfileRepository.isAuthenticated()) {
        logger.w('Cannot update profile: user not logged in');
        return;
      }

      await userProfileRepository.updateProfile(
        gender: gender,
        birthDate: birthDate,
        birthTime: birthTime,
      );

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
      final userProfileRepository = ref.read(userProfileRepositoryProvider);
      final success = await userProfileRepository.updateNickname(nickname);

      if (success) {
        // Refresh the profile
        await getUserProfiles();
        logger.i('Nickname updated successfully: $nickname');
        return true;
      } else {
        logger.e('Failed to update nickname');
        return false;
      }
    } catch (e, s) {
      logger.e('Error updating nickname', error: e, stackTrace: s);
      return false;
    }
  }

  Future<void> updateAvatar(String url) async {
    logger.i('Updating avatar URL to: $url');
    try {
      final userProfileRepository = ref.read(userProfileRepositoryProvider);
      await userProfileRepository.updateAvatar(url);
      
      if (state.value != null) {
        state = AsyncValue.data(state.value!.copyWith(avatarUrl: url));
      }
      logger.i('Avatar URL updated successfully');
    } catch (e, s) {
      logger.e('Error updating avatar', error: e, stackTrace: s);
      rethrow;
    }
  }

  Future<void> addStarCandy(int amount) async {
    try {
      final userProfileRepository = ref.read(userProfileRepositoryProvider);
      await userProfileRepository.addStarCandy(amount);
      
      // Refresh the profile
      await getUserProfiles();
      logger.i('Star candy added: $amount');
    } catch (e, s) {
      logger.e('Error adding star candy', error: e, stackTrace: s);
      rethrow;
    }
  }

  Future<void> spendStarCandy(int amount) async {
    try {
      final userProfileRepository = ref.read(userProfileRepositoryProvider);
      await userProfileRepository.spendStarCandy(amount);
      
      // Refresh the profile
      await getUserProfiles();
      logger.i('Star candy spent: $amount');
    } catch (e, s) {
      logger.e('Error spending star candy', error: e, stackTrace: s);
      rethrow;
    }
  }
}

@riverpod
Future<bool> setAgreement(Ref ref) async {
  logger.i('Setting user agreement');
  try {
    final userProfileRepository = ref.read(userProfileRepositoryProvider);
    await userProfileRepository.setUserAgreement();

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
    final userProfileRepository = ref.read(userProfileRepositoryProvider);
    await userProfileRepository.createUserAgreement();

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
    final userProfileRepository = ref.read(userProfileRepositoryProvider);
    final bonusPrediction = await userProfileRepository.getExpiringBonusPrediction();
    
    if (bonusPrediction != null) {
      logger.i('Expire bonus calculated: $bonusPrediction');
      return bonusPrediction;
    } else {
      logger.w('No bonus prediction data available');
      return null;
    }
  } catch (e, s) {
    logger.e('Error calculating expire bonus', error: e, stackTrace: s);
    Sentry.captureException(e, stackTrace: s);

    return null;
  }
}

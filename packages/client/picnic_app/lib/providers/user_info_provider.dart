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

      if (response['is_admin'] == true) {
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
    await supabase.auth.signOut();
    ref.read(navigationInfoProvider.notifier).setBottomNavigationIndex(0);

    state = const AsyncValue.data(null);
  }

  Future<void> updateNickname(
    String nickname,
  ) async {
    try {
      final response = await supabase
          .from('user_profiles')
          .update({
            'nickname': nickname,
          })
          .eq('id', state.value!.id ?? 0)
          .select()
          .single();
      logger.i('response.data: $response');
      logger.i(UserProfilesModel.fromJson(response));
      state = AsyncValue.data(UserProfilesModel.fromJson(response));
    } catch (e, s) {
      logger.e(e);
      logger.e(s);
    }
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
      'terms': DateTime.now(),
      'privacy': DateTime.now(),
    }).select();

    return true;
  } catch (e, s) {
    logger.e(e, stackTrace: s);
    return false;
  }
}

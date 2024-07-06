import 'package:picnic_app/constants.dart';
import 'package:picnic_app/models/user_profiles.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_extensions/supabase_extensions.dart';

part 'user_info_provider.g.dart';

@Riverpod(keepAlive: true)
class UserInfo extends _$UserInfo {
  @override
  Future<UserProfilesModel?> build() async {
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
      final response = await supabase.from('user_profiles').select().single();
      logger.i('response.data: $response');
      state = AsyncValue.data(UserProfilesModel.fromJson(response));

      return UserProfilesModel.fromJson(response);
    } catch (e, s) {
      logger.e(e);
      logger.e(s);

      return null;
    } finally {}
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

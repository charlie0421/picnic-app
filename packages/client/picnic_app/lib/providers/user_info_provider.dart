import 'package:picnic_app/constants.dart';
import 'package:picnic_app/models/user_profiles.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_auth_ui/supabase_auth_ui.dart';
import 'package:supabase_extensions/supabase_extensions.dart';

part 'user_info_provider.g.dart';

@Riverpod(keepAlive: true)
class UserInfo extends _$UserInfo {
  @override
  Future<UserProfilesModel?> build() async {
    if (!Supabase.instance.client.isLogged) {
      return null;
    }

    return getUserProfiles();
  }

  bool get isLogged => Supabase.instance.client.isLogged;

  Future<UserProfilesModel?> getUserProfiles() async {
    logger.i(
        'Supabase.instance.client.isLogged: ${Supabase.instance.client.isLogged}');
    if (!Supabase.instance.client.isLogged) {
      return null;
    }
    try {
      final response = await Supabase.instance.client
          .from('user_profiles')
          .select()
          .single();
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
    await Supabase.instance.client.auth.signOut();
    state = AsyncValue.data(null);
  }
}

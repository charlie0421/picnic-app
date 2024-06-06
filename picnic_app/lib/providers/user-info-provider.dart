import 'package:picnic_app/models/user-profiles.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_auth_ui/supabase_auth_ui.dart';
import 'package:supabase_extensions/supabase_extensions.dart';

part 'user-info-provider.g.dart';

@Riverpod(keepAlive: true)
class UserInfo extends _$UserInfo {
  @override
  Future<UserProfilesModel?> build() async {
    if (!Supabase.instance.client.isLogged) {
      return null;
    }

    final response =
        await Supabase.instance.client.from('user_profiles').select().single();
    if (response != null && response is Map<String, dynamic>) {
      return UserProfilesModel.fromJson(response as Map<String, dynamic>);
    }
    return null;
  }

  void setStarCandy(int starCandy) {
    state = state.whenData((data) => data?.copyWith(star_candy: starCandy));
  }
}

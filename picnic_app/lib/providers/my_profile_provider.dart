import 'package:picnic_app/main.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../models/my_profile.dart';

part 'my_profile_provider.g.dart';

@riverpod
class AsyncMyProfile extends _$AsyncMyProfile {
  @override
  Future<MyProfileModel?> build() async {
    return fetch();
  }

  Future<MyProfileModel?> fetch() async {
    final response = await supabase.from('my_profile').select().single();
    return MyProfileModel.fromJson(response);
  }

  Future<void> logout() async {
    supabase.auth.signOut();
  }
}

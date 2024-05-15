import 'package:prame_app/auth_dio.dart';
import 'package:prame_app/constants.dart';
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
    var dio = await authDio(baseUrl: Constants.authApiUrl);
    final accessToken = await globalStorage.loadData('ACCESS_TOKEN', '');

    if (accessToken!.isEmpty) {
      return null;
    }

    const String apiUrl = '/profiles/me';
    final response = await dio.get(apiUrl);
    if (response.statusCode == 200) {
      state = AsyncValue.data(MyProfileModel.fromJson(response.data));
      return MyProfileModel.fromJson(response.data);
    } else {
      state = AsyncError('Failed to load profile', StackTrace.current);
      logger.e('Failed to load profile');
      throw Exception('Failed to load profile');
    }
  }

  Future<void> logout() async {
    await globalStorage.removeData("ACCESS_TOKEN");
    await globalStorage.removeData("REFRESH_TOKEN");
  }
}

import 'package:intl/intl.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/models/community/post.dart';
import 'package:picnic_app/models/user_profiles.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'post_provider.g.dart';

@riverpod
Future<List<PostModel>?> postsByArtist(
    ref, int artistId, int limit, int page) async {
  try {
    final response = await supabase
        .from('posts')
        .select('*, boards!inner(*), user_profiles(*)')
        .eq('boards.artist_id', artistId)
        .order('created_at', ascending: false)
        .range((page - 1) * limit, page * limit - 1);

    return response.map((data) {
      final post = PostModel.fromJson(data);
      final userProfile = UserProfilesModel.fromJson(data['user_profiles']);
      return post.copyWith(user_profiles: userProfile);
    }).toList();
  } catch (e, s) {
    logger.e('Error fetching posts:', error: e, stackTrace: s);
    return Future.error(e);
  }
}

@riverpod
Future<List<PostModel>?> postsByBoard(
    ref, String boardId, int limit, int page) async {
  try {
    final response = await supabase
        .from('posts')
        .select('*, boards!inner(*), user_profiles(*)')
        .eq('boards.board_id', boardId)
        .order('created_at', ascending: false)
        .range((page - 1) * limit, page * limit - 1);

    return response.map((data) {
      final post = PostModel.fromJson(data);
      final userProfile = UserProfilesModel.fromJson(data['user_profiles']);
      return post.copyWith(user_profiles: userProfile);
    }).toList();
  } catch (e, s) {
    logger.e('Error fetching posts:', error: e, stackTrace: s);
    return Future.error(e);
  }
}

@riverpod
Future<List<PostModel>?> postsByQuery(
    ref, int artistId, String query, int page, int limit) async {
  try {
    if (query.isEmpty) {
      return [];
    }

    final response = await supabase
        .from('posts')
        .select('*, boards(*), user_profiles(*)')
        .or('title.ilike.%$query%,content.ilike.%$query%')
        .range(page * limit, (page + 1) * limit - 1)
        .order('title->>${Intl.getCurrentLocale()}', ascending: true);

    return response.map((data) {
      final post = PostModel.fromJson(data);
      final userProfile = UserProfilesModel.fromJson(data['user_profiles']);
      return post.copyWith(user_profiles: userProfile);
    }).toList();
  } catch (e, s) {
    logger.e('Error fetching posts:', error: e, stackTrace: s);
    return Future.error(e);
  }
}

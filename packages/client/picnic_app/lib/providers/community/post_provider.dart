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
        .select('*, boards!inner(*), user_id')
        .eq('boards.artist_id', artistId)
        .order('created_at', ascending: false)
        .range((page - 1) * limit, page * limit - 1);

    final postData = response.map(PostModel.fromJson).toList();

    logger.i('postData: $postData');

    final userIds = postData.map((post) => post.user_id).toSet().toList();
    final userProfiles =
        await supabase.from('user_profiles').select().inFilter('id', userIds);

    return postData.map((post) {
      final userProfile =
          userProfiles.firstWhere((profile) => profile['id'] == post.user_id);
      return post.copyWith(
          user_profiles: UserProfilesModel.fromJson(userProfile));
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
        .select('*, boards!inner(*), user_id')
        .eq('boards.board_id', boardId)
        .order('created_at', ascending: false)
        .range((page - 1) * limit, page * limit - 1);

    final postData = response.map(PostModel.fromJson).toList();
    final userIds = postData.map((post) => post.user_id).toSet().toList();
    final userProfiles =
        await supabase.from('user_profiles').select().inFilter('id', userIds);

    return postData.map((post) {
      final userProfile =
          userProfiles.firstWhere((profile) => profile['id'] == post.user_id);
      return post.copyWith(
          user_profiles: UserProfilesModel.fromJson(userProfile));
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

    List<PostModel> postData = [];

    final response = await supabase
        .from('posts')
        .select('*, boards(*)')
        // .neq('boards.artist_id', 0)
        // .eq('boards.artist_id', artistId)
        .or('title.ilike.%$query%')
        .range(page * limit, (page + 1) * limit - 1)
        .order('title->>${Intl.getCurrentLocale()}', ascending: true);
    postData = response.map(PostModel.fromJson).toList();

    logger.i('postData: $postData');

    final userIds = postData.map((post) => post.user_id).toSet().toList();

    logger.d('userIds: $userIds');

    final userData =
        await supabase.from('user_profiles').select().inFilter('id', userIds);

    logger.d('userData: $userData');

    if (postData.isEmpty) {
      return [];
    }

    return postData.map((post) {
      logger.d('post: $post');
      return post.copyWith(user_profiles:
          UserProfilesModel.fromJson(userData.firstWhere((userProfiles) {
        logger.d('id: ${userProfiles['id']}');
        logger.d('post.user_id: ${post.user_id}');

        return userProfiles['id'] == post.user_id;
      })));
    }).toList();
  } catch (e, s) {
    logger.e('Error fetching boards:', error: e, stackTrace: s);
    return Future.error(e);
  }
}

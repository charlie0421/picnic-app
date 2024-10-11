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
        .select(
            '*, boards!inner(*), user_profiles(*), post_reports!left(post_id), post_scraps!left(post_id)')
        .eq('boards.artist_id', artistId)
        .isFilter('post_reports', null)
        .isFilter('deleted_at', null)
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
        .select(
            '*, boards!inner(*), user_profiles(*), post_reports!left(post_id), post_scraps!left(post_id)')
        .eq('boards.board_id', boardId)
        .isFilter('deleted_at', null)
        .isFilter('post_reports', null)
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
        .select(
            '*, boards!inner(*), user_profiles(*), post_reports!left(post_id), post_scraps!left(post_id)')
        .isFilter('deleted_at', null)
        .isFilter('post_reports', null)
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

@riverpod
Future<void> reportPost(ref, PostModel post, String reason, String text) async {
  try {
    final response = await supabase.from('post_reports').upsert({
      'post_id': post.post_id,
      'user_id': supabase.auth.currentUser!.id,
      'reason': reason + (text.isNotEmpty ? ' - $text' : ''),
    });

    logger.d('response: $response');
  } catch (e, s) {
    logger.e('Error reporting comment:', error: e, stackTrace: s);
    return Future.error(e);
  }
}

@riverpod
Future<void> deletePost(ref, String postId) async {
  try {
    final response = await supabase.from('posts').update({
      'deleted_at': DateTime.now().toIso8601String(),
    }).eq('post_id', postId);

    logger.d('response: $response');
  } catch (e, s) {
    logger.e('Error deleting post:', error: e, stackTrace: s);
    return Future.error(e);
  }
}

@riverpod
Future<void> scrapPost(ref, String postId) async {
  try {
    final response = await supabase.from('post_scraps').upsert({
      'post_id': postId,
      'user_id': supabase.auth.currentUser!.id,
    });

    logger.d('response: $response');
  } catch (e, s) {
    logger.e('Error scrapping post:', error: e, stackTrace: s);
    return Future.error(e);
  }
}

@riverpod
Future<void> unscrapPost(ref, String postId) async {
  try {
    final response = await supabase
        .from('post_scraps')
        .delete()
        .eq('post_id', postId)
        .eq('user_id', supabase.auth.currentUser!.id);

    logger.d('response: $response');
  } catch (e, s) {
    logger.e('Error unscrapping post:', error: e, stackTrace: s);
    return Future.error(e);
  }
}

import 'package:intl/intl.dart';
import 'package:picnic_app/models/community/board.dart';
import 'package:picnic_app/models/community/post.dart';
import 'package:picnic_app/models/community/post_scrap.dart';
import 'package:picnic_app/models/user_profiles.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:picnic_app/util/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'post_provider.g.dart';

@riverpod
Future<List<PostModel>?> postsByArtist(
    ref, int artistId, int limit, int page) async {
  try {
    final response = await supabase
        .from('posts')
        .select('''
            post_id, title,created_at,view_count,reply_count, user_id,board_id,
            boards!inner(board_id,name, artist_id, description),
            user_profiles!posts_user_id_fkey(id,nickname,avatar_url,created_at,updated_at,deleted_at),
            post_reports!left(post_id),
            post_scraps!left(post_id)
            ''')
        .eq('boards.artist_id', artistId)
        .isFilter('post_reports', null)
        .isFilter('deleted_at', null)
        .order('created_at', ascending: false)
        .range((page - 1) * limit, page * limit - 1);

    return response.map((data) => PostModel.fromJson(data)).toList();
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
        .select('''
            post_id, title,created_at,view_count,reply_count, user_id,board_id,
            boards!inner(board_id,name, artist_id, description),
            user_profiles!posts_user_id_fkey(id,nickname,avatar_url,created_at,updated_at,deleted_at),
            post_reports!left(post_id),
            post_scraps!left(post_id)
        ''')
        .eq('board_id', boardId)
        .isFilter('deleted_at', null)
        .isFilter('post_reports', null)
        .order('created_at', ascending: false)
        .range((page - 1) * limit, page * limit - 1);

    return response.map((data) => PostModel.fromJson(data)).toList();
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
        .select('''
            post_id, title,created_at,view_count,reply_count, user_id,board_id,
            boards!inner(board_id,name, artist_id, description),
            user_profiles!posts_user_id_fkey(id,nickname,avatar_url,created_at,updated_at,deleted_at),
            post_reports!left(post_id),
            post_scraps!left(post_id)
         ''')
        .isFilter('deleted_at', null)
        .isFilter('post_reports', null)
        .or('title.ilike.%$query%')
        .range((page - 1) * limit, page * limit - 1)
        .order('title->>${Intl.getCurrentLocale()}', ascending: true);

    return response.map((data) => PostModel.fromJson(data)).toList();
  } catch (e, s) {
    logger.e('Error fetching posts:', error: e, stackTrace: s);
    return Future.error(e);
  }
}

@riverpod
Future<PostModel?> postById(ref, String postId,
    {bool isIncrementViewCount = true}) async {
  try {
    logger.d(
        'Fetching post: $postId, isIncrementViewCount: $isIncrementViewCount');
    // 조회수 증가 함수 호출
    if (isIncrementViewCount) {
      await supabase
          .rpc('increment_view_count', params: {'post_id_param': postId});
    }

    final response = await supabase
        .from('posts')
        .select(
            '*, board:boards!inner(*), user_profiles!posts_user_id_fkey(nickname,avatar_url,created_at,updated_at,deleted_at), post_reports!left(post_id), post_scraps!left(post_id)')
        .eq('post_id', postId)
        .isFilter('deleted_at', null)
        .isFilter('post_reports', null)
        .maybeSingle();

    // Check if post_scraps exists and set isScraped accordingly
    bool isScraped =
        response!['post_scraps'] != null && response['post_scraps'].isNotEmpty;

    // Create a new map with the updated isScraped value
    Map<String, dynamic> updatedResponse = {
      ...response,
      'is_scraped': isScraped,
    };

    logger.i('postById: $updatedResponse');

    return PostModel.fromJson(updatedResponse);
  } catch (e, s) {
    logger.e('Error fetching post:', error: e, stackTrace: s);
    return Future.error(e);
  }
}

@riverpod
Future<List<PostModel>> postsByUser(
    ref, String userId, int limit, int page) async {
  try {
    final response = await supabase
        .from('posts')
        .select(
            '*, boards!inner(*), user_profiles!posts_user_id_fkey(*), post_reports!left(post_id), post_scraps!left(post_id)')
        .eq('user_id', userId)
        .isFilter('deleted_at', null)
        .isFilter('post_reports', null)
        .order('created_at', ascending: false)
        .range((page - 1) * limit, page * limit - 1);

    return response.map((data) {
      final post = PostModel.fromJson(data);
      final userProfile = UserProfilesModel.fromJson(data['user_profiles']);
      final board =
          data['boards'] != null ? BoardModel.fromJson(data['boards']) : null;
      return post.copyWith(userProfiles: userProfile, board: board);
    }).toList();
  } catch (e, s) {
    logger.e('Error fetching posts:', error: e, stackTrace: s);
    return Future.error(e);
  }
}

@riverpod
Future<List<PostScrapModel>> postsScrapedByUser(
    ref, String userId, int limit, int page) async {
  try {
    final response = await supabase
        .from('post_scraps')
        .select(
            '*, post:posts!inner(*, board:boards!inner(*)), user_profiles(*)')
        .eq('user_id', userId)
        .range((page - 1) * limit, page * limit - 1);

    return response.map((data) => PostScrapModel.fromJson(data)).toList();
  } catch (e, s) {
    logger.e('Error fetching posts:', error: e, stackTrace: s);
    return Future.error(e);
  }
}

@riverpod
Future<void> reportPost(ref, PostModel post, String reason, String text) async {
  try {
    final response = await supabase.from('post_reports').upsert({
      'post_id': post.postId,
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
Future<void> unscrapPost(ref, String postId, String userId) async {
  logger.d('Unscrapping post: $postId');
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

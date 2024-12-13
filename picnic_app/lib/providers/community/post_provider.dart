import 'package:picnic_app/models/community/board.dart';
import 'package:picnic_app/models/community/post.dart';
import 'package:picnic_app/models/community/post_scrap.dart';
import 'package:picnic_app/models/user_profiles.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:picnic_app/util/i18n.dart';
import 'package:picnic_app/util/logger.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '../../generated/providers/community/post_provider.g.dart';

@riverpod
Future<List<PostModel>?> postsByArtist(
    ref, int artistId, int limit, int page) async {
  try {
    // 1. 차단한 사용자 목록 조회
    final blockedResponse = await supabase
        .from('user_blocks')
        .select('blocked_user_id')
        .eq('user_id', supabase.auth.currentUser!.id)
        .isFilter('deleted_at', null);

    final blockedUserIds =
        blockedResponse.map((row) => row['blocked_user_id'] as String).toList();

    // 2. 게시글 조회 시 차단된 사용자의 게시글 제외
    var query = supabase
        .from('posts')
        .select('''
            post_id, title,created_at,view_count,reply_count, user_id,board_id, is_anonymous,
            boards!inner(board_id,name, artist_id, description),
            user_profiles!posts_user_id_fkey(id,nickname,avatar_url,created_at,updated_at,deleted_at),
            post_reports!left(post_id),
            post_scraps!left(post_id)
            ''')
        .eq('boards.artist_id', artistId)
        .isFilter('post_reports', null)
        .isFilter('deleted_at', null);

    // 차단된 사용자가 있는 경우에만 필터 적용
    if (blockedUserIds.isNotEmpty) {
      query = query.or(
          '''and(user_id.not.in.(${blockedUserIds.map((id) => id).join(',')}))''');
    }

    final response = await query
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
    // 1. 차단한 사용자 목록 조회
    final blockedResponse = await supabase
        .from('user_blocks')
        .select('blocked_user_id')
        .eq('user_id', supabase.auth.currentUser!.id)
        .isFilter('deleted_at', null);

    final blockedUserIds =
        blockedResponse.map((row) => row['blocked_user_id'] as String).toList();

    // 2. 게시글 조회 시 차단된 사용자의 게시글 제외
    var query = supabase
        .from('posts')
        .select('''
            post_id, title,created_at,view_count,reply_count, user_id,board_id, is_anonymous,
            boards!inner(board_id,name, artist_id, description),
            user_profiles!posts_user_id_fkey(id,nickname,avatar_url,created_at,updated_at,deleted_at),
            post_reports!left(post_id),
            post_scraps!left(post_id)
        ''')
        .eq('board_id', boardId)
        .isFilter('deleted_at', null)
        .isFilter('post_reports', null);

    // 차단된 사용자가 있는 경우에만 필터 적용
    if (blockedUserIds.isNotEmpty) {
      query = query.or(
          '''and(user_id.not.in.(${blockedUserIds.map((id) => id).join(',')}))''');
    }

    final response = await query
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

    // 1. 차단한 사용자 목록 조회
    final blockedResponse = await supabase
        .from('user_blocks')
        .select('blocked_user_id')
        .eq('user_id', supabase.auth.currentUser!.id)
        .isFilter('deleted_at', null);

    final blockedUserIds =
        blockedResponse.map((row) => row['blocked_user_id'] as String).toList();

    // 2. 게시글 조회 시 차단된 사용자의 게시글 제외
    var searchQuery = supabase
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
        .or('title.ilike.%$query%');

    // 차단된 사용자가 있는 경우에만 필터 적용
    if (blockedUserIds.isNotEmpty) {
      searchQuery = searchQuery.or(
          '''and(user_id.not.in.(${blockedUserIds.map((id) => id).join(',')}))''');
    }

    final response = await searchQuery
        .range((page - 1) * limit, page * limit - 1)
        .order('title->>${getLocaleLanguage()}', ascending: true);

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

    // 1. 차단한 사용자 목록 조회
    final blockedResponse = await supabase
        .from('user_blocks')
        .select('blocked_user_id')
        .eq('user_id', supabase.auth.currentUser!.id)
        .isFilter('deleted_at', null);

    final blockedUserIds =
        blockedResponse.map((row) => row['blocked_user_id'] as String).toList();

    // 조회수 증가 함수 호출
    if (isIncrementViewCount) {
      await supabase
          .rpc('increment_view_count', params: {'post_id_param': postId});
    }

    var query = supabase
        .from('posts')
        .select(
            '*, board:boards!inner(*), user_profiles!posts_user_id_fkey(nickname,avatar_url,created_at,updated_at,deleted_at), post_reports!left(post_id), post_scraps!left(post_id)')
        .eq('post_id', postId)
        .isFilter('deleted_at', null)
        .isFilter('post_reports', null);

    // 차단된 사용자가 있는 경우에만 필터 적용
    if (blockedUserIds.isNotEmpty) {
      query = query.or(
          '''and(user_id.not.in.(${blockedUserIds.map((id) => id).join(',')}))''');
    }

    final response = await query.maybeSingle();

    if (response == null) return null;

    // Check if post_scraps exists and set isScraped accordingly
    bool isScraped =
        response['post_scraps'] != null && response['post_scraps'].isNotEmpty;

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
    // 1. 차단한 사용자 목록 조회
    final blockedResponse = await supabase
        .from('user_blocks')
        .select('blocked_user_id')
        .eq('user_id', supabase.auth.currentUser!.id)
        .isFilter('deleted_at', null);

    final blockedUserIds =
        blockedResponse.map((row) => row['blocked_user_id'] as String).toList();

    var query = supabase
        .from('posts')
        .select(
            '*, boards!inner(*), user_profiles!posts_user_id_fkey(*), post_reports!left(post_id), post_scraps!left(post_id)')
        .eq('user_id', userId)
        .isFilter('deleted_at', null)
        .isFilter('post_reports', null);

    // 차단된 사용자가 있는 경우에만 필터 적용
    if (blockedUserIds.isNotEmpty) {
      query = query.or(
          '''and(user_id.not.in.(${blockedUserIds.map((id) => id).join(',')}))''');
    }

    final response = await query
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
    // 1. 차단한 사용자 목록 조회
    final blockedResponse = await supabase
        .from('user_blocks')
        .select('blocked_user_id')
        .eq('user_id', supabase.auth.currentUser!.id)
        .isFilter('deleted_at', null);

    final blockedUserIds =
        blockedResponse.map((row) => row['blocked_user_id'] as String).toList();

    var query = supabase
        .from('post_scraps')
        .select(
            '*, post:posts!inner(*, board:boards!inner(*)), user_profiles(*)')
        .eq('user_id', userId);

    // 차단된 사용자가 있는 경우에만 필터 적용
    if (blockedUserIds.isNotEmpty) {
      // 수정된 부분: not.in 연산자를 직접 사용
      query = query.not(
        'post.user_id',
        'in',
        '(${blockedUserIds.join(',')})',
      );
    }

    final response = await query.range((page - 1) * limit, page * limit - 1);

    return response.map((data) => PostScrapModel.fromJson(data)).toList();
  } catch (e, s) {
    logger.e('Error fetching posts:', error: e, stackTrace: s);
    return Future.error(e);
  }
}

@riverpod
Future<void> reportPost(
  ref,
  PostModel post,
  String reason,
  String text, {
  bool blockUser = false,
}) async {
  try {
    final userId = supabase.auth.currentUser!.id;
    final fullReason = reason + (text.isNotEmpty ? ' - $text' : '');

    // 1. 게시글 신고
    await supabase.from('post_reports').upsert({
      'post_id': post.postId,
      'user_id': userId,
      'reason': fullReason,
    });

    // 2. 사용자 차단 (옵션)
    if (blockUser) {
      await supabase.from('user_blocks').upsert({
        'user_id': userId,
        'blocked_user_id': post.userId,
        'created_at': DateTime.now().toIso8601String(),
      });
    }

    logger.d('Post reported successfully. Block user: $blockUser');
  } catch (e, s) {
    logger.e('Error reporting post:', error: e, stackTrace: s);
    return Future.error(e);
  }
}

@riverpod
Future<void> deletePost(ref, String postId) async {
  try {
    await supabase.from('posts').update({
      'deleted_at': DateTime.now().toIso8601String(),
    }).eq('post_id', postId);
  } catch (e, s) {
    logger.e('Error deleting post:', error: e, stackTrace: s);
    return Future.error(e);
  }
}

@riverpod
Future<void> scrapPost(ref, String postId) async {
  try {
    await supabase.from('post_scraps').upsert({
      'post_id': postId,
      'user_id': supabase.auth.currentUser!.id,
    });
  } catch (e, s) {
    logger.e('Error scrapping post:', error: e, stackTrace: s);
    return Future.error(e);
  }
}

@riverpod
Future<void> unscrapPost(ref, String postId, String userId) async {
  try {
    await supabase
        .from('post_scraps')
        .delete()
        .eq('post_id', postId)
        .eq('user_id', supabase.auth.currentUser!.id);
  } catch (e, s) {
    logger.e('Error unscrapping post:', error: e, stackTrace: s);
    return Future.error(e);
  }
}

// 차단된 사용자 목록 조회 유틸리티 함수
Future<List<String>> getBlockedUserIds() async {
  try {
    final response = await supabase
        .from('user_blocks')
        .select('blocked_user_id')
        .eq('user_id', supabase.auth.currentUser!.id)
        .isFilter('deleted_at', null);

    return response
        .map<String>((row) => row['blocked_user_id'] as String)
        .toList();
  } catch (e, s) {
    logger.e('Error fetching blocked users:', error: e, stackTrace: s);
    return [];
  }
}

// 차단 해제 유틸리티 함수
Future<void> unblockUser(String blockedUserId) async {
  try {
    await supabase
        .from('user_blocks')
        .update({'deleted_at': DateTime.now().toIso8601String()})
        .eq('user_id', supabase.auth.currentUser!.id)
        .eq('blocked_user_id', blockedUserId);
  } catch (e, s) {
    logger.e('Error unblocking user:', error: e, stackTrace: s);
    rethrow;
  }
}

// 사용자 차단 여부 확인 함수
Future<bool> isUserBlocked(String userId) async {
  try {
    final response = await supabase
        .from('user_blocks')
        .select()
        .eq('user_id', supabase.auth.currentUser!.id)
        .eq('blocked_user_id', userId)
        .isFilter('deleted_at', null)
        .maybeSingle();

    return response != null;
  } catch (e, s) {
    logger.e('Error checking blocked user:', error: e, stackTrace: s);
    return false;
  }
}

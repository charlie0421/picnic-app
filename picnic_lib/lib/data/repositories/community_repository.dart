import 'package:picnic_lib/data/models/community/post.dart';
import 'package:picnic_lib/data/models/community/board.dart';
import 'package:picnic_lib/data/models/community/comment.dart';
import 'package:picnic_lib/data/models/user_profiles.dart';
import 'package:picnic_lib/data/repositories/base_repository.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CommunityRepository extends BaseRepository {
  static const String _postsTable = 'posts';
  static const String _boardsTable = 'boards';
  static const String _commentsTable = 'comments';
  static const String _userProfilesTable = 'user_profiles';

  // Board operations
  Future<List<BoardModel>> getBoards({
    int? limit,
    int? offset,
    String? category,
  }) async {
    try {
      var query = supabase.from(_boardsTable).select('*');

      if (category != null) {
        query = query.eq('category', category);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      if (offset != null) {
        query = query.range(offset, offset + (limit ?? 20) - 1);
      }

      final response = await executeQuery(
        () => query.order('created_at', ascending: false),
        'getBoards',
      );

      return response.map((data) => BoardModel.fromJson(data)).toList();
    } catch (e) {
      logger.e('Error getting boards: $e');
      throw RepositoryException('Failed to get boards', originalError: e);
    }
  }

  Future<BoardModel?> getBoardById(String boardId) async {
    try {
      final response = await executeQuery(
        () => supabase.from(_boardsTable).select('*').eq('id', boardId).maybeSingle(),
        'getBoardById',
      );

      return response != null ? BoardModel.fromJson(response) : null;
    } catch (e) {
      logger.e('Error getting board by ID: $e');
      throw RepositoryException('Failed to get board', originalError: e);
    }
  }

  // Post operations
  Future<List<PostModel>> getPosts({
    String? boardId,
    int? limit,
    int? offset,
    bool includeUserProfiles = true,
  }) async {
    try {
      var query = supabase.from(_postsTable).select('''
        *,
        boards!inner(*)
      ''');

      if (boardId != null) {
        query = query.eq('board_id', boardId);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      if (offset != null) {
        query = query.range(offset, offset + (limit ?? 20) - 1);
      }

      final response = await executeQuery(
        () => query.order('created_at', ascending: false),
        'getPosts',
      );

      List<PostModel> posts = response.map((data) => PostModel.fromJson(data)).toList();

      if (includeUserProfiles && posts.isNotEmpty) {
        posts = await _enrichPostsWithUserProfiles(posts);
      }

      return posts;
    } catch (e) {
      logger.e('Error getting posts: $e');
      throw RepositoryException('Failed to get posts', originalError: e);
    }
  }

  Future<PostModel?> getPostById(String postId, {bool includeUserProfile = true}) async {
    try {
      final response = await executeQuery(
        () => supabase.from(_postsTable).select('''
          *,
          boards(*)
        ''').eq('id', postId).maybeSingle(),
        'getPostById',
      );

      if (response == null) return null;

      PostModel post = PostModel.fromJson(response);

      if (includeUserProfile) {
        final posts = await _enrichPostsWithUserProfiles([post]);
        post = posts.first;
      }

      return post;
    } catch (e) {
      logger.e('Error getting post by ID: $e');
      throw RepositoryException('Failed to get post', originalError: e);
    }
  }

  Future<PostModel> createPost({
    required String boardId,
    required String title,
    required String content,
    List<String>? imageUrls,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) {
        throw RepositoryException('User must be authenticated to create post');
      }

      final postData = {
        'board_id': boardId,
        'user_id': userId,
        'title': title,
        'content': content,
        'image_urls': imageUrls,
        'metadata': metadata,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      };

      final response = await executeQuery(
        () => supabase.from(_postsTable).insert(postData).select().single(),
        'createPost',
      );

      return PostModel.fromJson(response);
    } catch (e) {
      logger.e('Error creating post: $e');
      throw RepositoryException('Failed to create post', originalError: e);
    }
  }

  Future<PostModel> updatePost({
    required String postId,
    String? title,
    String? content,
    List<String>? imageUrls,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) {
        throw RepositoryException('User must be authenticated to update post');
      }

      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

      if (title != null) updateData['title'] = title;
      if (content != null) updateData['content'] = content;
      if (imageUrls != null) updateData['image_urls'] = imageUrls;
      if (metadata != null) updateData['metadata'] = metadata;

      final response = await executeQuery(
        () => supabase.from(_postsTable)
            .update(updateData)
            .eq('id', postId)
            .eq('user_id', userId)
            .select()
            .single(),
        'updatePost',
      );

      return PostModel.fromJson(response);
    } catch (e) {
      logger.e('Error updating post: $e');
      throw RepositoryException('Failed to update post', originalError: e);
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) {
        throw RepositoryException('User must be authenticated to delete post');
      }

      await executeQuery(
        () => supabase.from(_postsTable)
            .delete()
            .eq('id', postId)
            .eq('user_id', userId),
        'deletePost',
      );
    } catch (e) {
      logger.e('Error deleting post: $e');
      throw RepositoryException('Failed to delete post', originalError: e);
    }
  }

  // Comment operations
  Future<List<CommentModel>> getComments({
    required String postId,
    int? limit,
    int? offset,
  }) async {
    try {
      var query = supabase.from(_commentsTable).select('*').eq('post_id', postId);

      if (limit != null) {
        query = query.limit(limit);
      }

      if (offset != null) {
        query = query.range(offset, offset + (limit ?? 20) - 1);
      }

      final response = await executeQuery(
        () => query.order('created_at', ascending: true),
        'getComments',
      );

      return response.map((data) => CommentModel.fromJson(data)).toList();
    } catch (e) {
      logger.e('Error getting comments: $e');
      throw RepositoryException('Failed to get comments', originalError: e);
    }
  }

  Future<CommentModel> createComment({
    required String postId,
    required String content,
    String? parentCommentId,
  }) async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) {
        throw RepositoryException('User must be authenticated to create comment');
      }

      final commentData = {
        'post_id': postId,
        'user_id': userId,
        'content': content,
        'parent_comment_id': parentCommentId,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      };

      final response = await executeQuery(
        () => supabase.from(_commentsTable).insert(commentData).select().single(),
        'createComment',
      );

      return CommentModel.fromJson(response);
    } catch (e) {
      logger.e('Error creating comment: $e');
      throw RepositoryException('Failed to create comment', originalError: e);
    }
  }

  Future<void> deleteComment(String commentId) async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) {
        throw RepositoryException('User must be authenticated to delete comment');
      }

      await executeQuery(
        () => supabase.from(_commentsTable)
            .delete()
            .eq('id', commentId)
            .eq('user_id', userId),
        'deleteComment',
      );
    } catch (e) {
      logger.e('Error deleting comment: $e');
      throw RepositoryException('Failed to delete comment', originalError: e);
    }
  }

  // Like operations
  Future<void> likePost(String postId) async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) {
        throw RepositoryException('User must be authenticated to like post');
      }

      await executeQuery(
        () => supabase.from('post_likes').upsert({
          'post_id': postId,
          'user_id': userId,
          'created_at': DateTime.now().toUtc().toIso8601String(),
        }),
        'likePost',
      );
    } catch (e) {
      logger.e('Error liking post: $e');
      throw RepositoryException('Failed to like post', originalError: e);
    }
  }

  Future<void> unlikePost(String postId) async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) {
        throw RepositoryException('User must be authenticated to unlike post');
      }

      await executeQuery(
        () => supabase.from('post_likes')
            .delete()
            .eq('post_id', postId)
            .eq('user_id', userId),
        'unlikePost',
      );
    } catch (e) {
      logger.e('Error unliking post: $e');
      throw RepositoryException('Failed to unlike post', originalError: e);
    }
  }

  Future<int> getPostLikeCount(String postId) async {
    try {
      final response = await executeQuery(
        () => supabase.from('post_likes')
            .select('*', const FetchOptions(count: CountOption.exact))
            .eq('post_id', postId),
        'getPostLikeCount',
      );

      return (response as List).length;
    } catch (e) {
      logger.e('Error getting post like count: $e');
      return 0;
    }
  }

  Future<bool> isPostLikedByUser(String postId) async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) return false;

      final response = await executeQuery(
        () => supabase.from('post_likes')
            .select('id')
            .eq('post_id', postId)
            .eq('user_id', userId)
            .maybeSingle(),
        'isPostLikedByUser',
      );

      return response != null;
    } catch (e) {
      logger.e('Error checking if post is liked: $e');
      return false;
    }
  }

  // Helper methods
  Future<List<PostModel>> _enrichPostsWithUserProfiles(List<PostModel> posts) async {
    if (posts.isEmpty) return posts;

    try {
      final userIds = posts.map((post) => post.userId).toSet().toList();
      
      final response = await executeQuery(
        () => supabase.from(_userProfilesTable).select('*').inFilter('id', userIds),
        '_enrichPostsWithUserProfiles',
      );

      final userProfiles = Map.fromEntries(
        response.map((data) => MapEntry(data['id'], UserProfilesModel.fromJson(data)))
      );

      return posts.map((post) {
        final userProfile = userProfiles[post.userId];
        return userProfile != null ? post.copyWith(userProfiles: userProfile) : post;
      }).toList();
    } catch (e) {
      logger.e('Error enriching posts with user profiles: $e');
      return posts; // Return original posts if enrichment fails
    }
  }

  // Stream operations for real-time updates
  Stream<List<PostModel>> streamPosts({String? boardId}) {
    var query = supabase.from(_postsTable).stream(primaryKey: ['id']);
    
    if (boardId != null) {
      query = query.eq('board_id', boardId);
    }

    return query.map((data) => 
      data.map((item) => PostModel.fromJson(item)).toList()
    );
  }

  Stream<List<CommentModel>> streamComments(String postId) {
    return supabase.from(_commentsTable)
        .stream(primaryKey: ['id'])
        .eq('post_id', postId)
        .map((data) => 
          data.map((item) => CommentModel.fromJson(item)).toList()
        );
  }
}
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/models/common/comment.dart';
import 'package:picnic_app/models/user_profiles.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'comments_provider.g.dart';

@riverpod
Future<List<CommentModel>?> comments(
    ref, String postId, int page, int limit) async {
  try {
    final response = await supabase
        .schema('community')
        .from('comments')
        .select()
        .eq('post_id', postId)
        // .range(page * limit, (page + 1) * limit - 1)
        .order('created_at', ascending: false);

    final commentData = response.map(CommentModel.fromJson).toList();

    logger.i('commentData: $commentData');

    final userIds =
        commentData.map((comment) => comment.userId).toSet().toList();

    logger.i('userIds: $userIds');
    final userProfiles =
        await supabase.from('user_profiles').select().inFilter('id', userIds);

    return commentData.map((comment) {
      final userProfile =
          userProfiles.firstWhere((profile) => profile['id'] == comment.userId);
      return comment.copyWith(user: UserProfilesModel.fromJson(userProfile));
    }).toList();
  } catch (e, s) {
    logger.e('Error fetching comments:', error: e, stackTrace: s);
    return Future.error(e);
  }
}

@riverpod
Future<void> postComment(ref, String postId, String content) async {
  try {
    final response =
        await supabase.schema('community').from('comments').insert({
      'post_id': postId,
      'user_id': supabase.auth.currentUser!.id,
      'content': content,
    });

    logger.d('response: $response');
  } catch (e, s) {
    logger.e('Error posting comment:', error: e, stackTrace: s);
    return Future.error(e);
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_app/models/community/post.dart';
import 'package:picnic_app/models/user_profiles.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:picnic_app/util/logger.dart';

final postListProvider = FutureProvider.family((ref, String boardId) async {
  try {
    logger.d('Fetching posts for boardId: $boardId');
    final postsResponse = await supabase
        .from('posts')
        .select('''
          *,
          boards!inner(*)
        ''')
        .eq('board_id', boardId)
        .order('created_at', ascending: false)
        .limit(3);

    final posts =
        postsResponse.map((data) => PostModel.fromJson(data)).toList();

    logger.d('posts: $posts');

    // Fetch user profiles separately
    final userIds = posts.map((post) => post.userId).toSet().toList();
    final userProfilesResponse =
        await supabase.from('user_profiles').select().inFilter('id', userIds);

    final userProfiles = Map.fromEntries(userProfilesResponse
        .map((data) => MapEntry(data['id'], UserProfilesModel.fromJson(data))));

    logger.d('userProfiles: $userProfiles');

    for (var i = 0; i < posts.length; i++) {
      posts[i] =
          posts[i].copyWith(userProfiles: userProfiles[posts[i].userId]!);
    }
    return posts;
  } catch (e, s) {
    logger.e('Error fetching posts:', error: e, stackTrace: s);
    return Future.error(e);
  }
});

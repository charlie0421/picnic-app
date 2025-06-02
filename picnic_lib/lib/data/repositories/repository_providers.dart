import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/data/repositories/artist_repository.dart';
import 'package:picnic_lib/data/repositories/chat_repository.dart';
import 'package:picnic_lib/data/repositories/community_repository.dart';
import 'package:picnic_lib/data/repositories/config_repository.dart';
import 'package:picnic_lib/data/repositories/notification_repository.dart';
import 'package:picnic_lib/data/repositories/pic_repository.dart';
import 'package:picnic_lib/data/repositories/user_profile_repository.dart';
import 'package:picnic_lib/data/repositories/vote_repository.dart';

// Repository providers
final artistRepositoryProvider = Provider<ArtistRepository>((ref) {
  return ArtistRepository();
});

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository();
});

final communityRepositoryProvider = Provider<CommunityRepository>((ref) {
  return CommunityRepository();
});

final configRepositoryProvider = Provider<ConfigRepository>((ref) {
  return ConfigRepository();
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository();
});

final picRepositoryProvider = Provider<PicRepository>((ref) {
  return PicRepository();
});

final userProfileRepositoryProvider = Provider<UserProfileRepository>((ref) {
  return UserProfileRepository();
});

final voteRepositoryProvider = Provider<VoteRepository>((ref) {
  return VoteRepository();
});

// Aggregate provider for all repositories
final repositoriesProvider = Provider<Map<String, dynamic>>((ref) {
  return {
    'artist': ref.watch(artistRepositoryProvider),
    'chat': ref.watch(chatRepositoryProvider),
    'community': ref.watch(communityRepositoryProvider),
    'config': ref.watch(configRepositoryProvider),
    'notification': ref.watch(notificationRepositoryProvider),
    'pic': ref.watch(picRepositoryProvider),
    'userProfile': ref.watch(userProfileRepositoryProvider),
    'vote': ref.watch(voteRepositoryProvider),
  };
});
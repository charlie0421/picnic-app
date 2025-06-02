import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';
import 'package:picnic_lib/data/repositories/repository_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '../../generated/providers/artist_provider.g.dart';

@riverpod
Future<ArtistModel> getArtist(ref, int artistId) async {
  try {
    final artistRepository = ref.watch(artistRepositoryProvider);
    final artist = await artistRepository.findById(artistId);

    logger.i('Artist fetched: ${artist?.name}');

    if (artist == null) {
      throw Exception('Artist not found');
    }

    return artist;
  } catch (e) {
    logger.e('Failed to fetch artist: $e');
    throw Exception('Failed to fetch artist');
  }
}

@riverpod
Future<List<ArtistModel>> searchArtists(ref, String query) async {
  try {
    final artistRepository = ref.watch(artistRepositoryProvider);
    final artists = await artistRepository.searchByName(query);

    logger.i('Found ${artists.length} artists for query: $query');
    return artists;
  } catch (e) {
    logger.e('Failed to search artists: $e');
    throw Exception('Failed to search artists');
  }
}

@riverpod
Future<List<ArtistModel>> getArtistsByGroup(ref, int groupId) async {
  try {
    final artistRepository = ref.watch(artistRepositoryProvider);
    final artists = await artistRepository.findByGroup(groupId);

    logger.i('Found ${artists.length} artists for group: $groupId');
    return artists;
  } catch (e) {
    logger.e('Failed to fetch artists by group: $e');
    throw Exception('Failed to fetch artists by group');
  }
}

@riverpod
Future<List<ArtistModel>> getArtistsByGender(ref, String gender) async {
  try {
    final artistRepository = ref.watch(artistRepositoryProvider);
    final artists = await artistRepository.findByGender(gender);

    logger.i('Found ${artists.length} artists for gender: $gender');
    return artists;
  } catch (e) {
    logger.e('Failed to fetch artists by gender: $e');
    throw Exception('Failed to fetch artists by gender');
  }
}

@riverpod
Future<List<ArtistModel>> getPopularArtists(ref, {int limit = 20}) async {
  try {
    final artistRepository = ref.watch(artistRepositoryProvider);
    final artists = await artistRepository.getPopular(limit: limit);

    logger.i('Found ${artists.length} popular artists');
    return artists;
  } catch (e) {
    logger.e('Failed to fetch popular artists: $e');
    throw Exception('Failed to fetch popular artists');
  }
}

@riverpod
Future<List<ArtistModel>> getRecommendedArtists(ref, {int limit = 10}) async {
  try {
    final artistRepository = ref.watch(artistRepositoryProvider);
    final artists = await artistRepository.getRecommended(limit: limit);

    logger.i('Found ${artists.length} recommended artists');
    return artists;
  } catch (e) {
    logger.e('Failed to fetch recommended artists: $e');
    throw Exception('Failed to fetch recommended artists');
  }
}

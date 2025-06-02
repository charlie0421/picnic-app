import 'package:picnic_lib/domain/entities/artist_entity.dart';

/// Domain interface for artist repository operations
abstract class IArtistRepository {
  /// Get artist by ID
  Future<ArtistEntity?> getArtistById(int artistId);

  /// Get all artists with optional filtering
  Future<List<ArtistEntity>> getArtists({
    int? limit,
    int? offset,
    Gender? gender,
    int? groupId,
    bool? isActive,
    ArtistTier? tier,
  });

  /// Search artists by name
  Future<List<ArtistEntity>> searchArtists(String query, {
    int? limit,
    Gender? gender,
    bool? isActive,
  });

  /// Get artists by group
  Future<List<ArtistEntity>> getArtistsByGroup(int groupId);

  /// Get artists by gender
  Future<List<ArtistEntity>> getArtistsByGender(Gender gender);

  /// Get popular artists (high vote count)
  Future<List<ArtistEntity>> getPopularArtists({
    int limit = 20,
    Duration? timeRange,
  });

  /// Get trending artists (recent high activity)
  Future<List<ArtistEntity>> getTrendingArtists({
    int limit = 20,
  });

  /// Get rookie artists (new with growing popularity)
  Future<List<ArtistEntity>> getRookieArtists({
    int limit = 20,
  });

  /// Get recommended artists for user
  Future<List<ArtistEntity>> getRecommendedArtists({
    required String userId,
    int limit = 10,
  });

  /// Get featured artists
  Future<List<ArtistEntity>> getFeaturedArtists({
    int limit = 10,
  });

  /// Add vote to artist
  Future<ArtistEntity> addVoteToArtist(int artistId);

  /// Get artists by tier
  Future<List<ArtistEntity>> getArtistsByTier(ArtistTier tier);

  /// Get artists eligible for events
  Future<List<ArtistEntity>> getEventEligibleArtists();

  /// Update artist information
  Future<ArtistEntity> updateArtist({
    required int artistId,
    String? name,
    String? image,
    DateTime? birthDate,
    ArtistGroup? artistGroup,
  });

  /// Add artist to user's bookmarks
  Future<void> addBookmark({
    required String userId,
    required int artistId,
  });

  /// Remove artist from user's bookmarks
  Future<void> removeBookmark({
    required String userId,
    required int artistId,
  });

  /// Get user's bookmarked artists
  Future<List<ArtistEntity>> getBookmarkedArtists(String userId);

  /// Check if artist is bookmarked by user
  Future<bool> isArtistBookmarked({
    required String userId,
    required int artistId,
  });

  /// Get artist statistics
  Future<ArtistStats> getArtistStats(int artistId);

  /// Update artist statistics
  Future<void> updateArtistStats({
    required int artistId,
    required ArtistStats stats,
  });

  /// Deactivate artist
  Future<ArtistEntity> deactivateArtist(int artistId);

  /// Activate artist
  Future<ArtistEntity> activateArtist(int artistId);

  /// Get artists for admin management
  Future<List<ArtistEntity>> getArtistsForAdmin({
    int? limit,
    int? offset,
    bool? includeInactive,
    String? searchQuery,
  });

  /// Stream artist changes for real-time updates
  Stream<ArtistEntity?> streamArtist(int artistId);

  /// Stream popular artists for real-time updates
  Stream<List<ArtistEntity>> streamPopularArtists();

  /// Stream trending artists for real-time updates
  Stream<List<ArtistEntity>> streamTrendingArtists();
}
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:picnic_lib/domain/entities/artist_entity.dart';
import 'package:picnic_lib/domain/interfaces/artist_repository_interface.dart';
import 'package:picnic_lib/domain/value_objects/content.dart';
import 'package:picnic_lib/core/services/offline_database_service.dart';
import 'package:picnic_lib/core/services/simple_cache_manager.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/application/use_cases/artist/vote_for_artist_use_case.dart';

class ArtistRepositoryImpl implements IArtistRepository {
  final SupabaseClient _supabaseClient;
  final OfflineDatabaseService _offlineDatabase;
  final SimpleCacheManager _cacheManager;

  static const String _tableName = 'artists';
  static const String _groupTableName = 'artist_groups';
  static const String _voteTableName = 'artist_votes';
  static const String _cacheKeyPrefix = 'artist_';

  ArtistRepositoryImpl({
    required SupabaseClient supabaseClient,
    required OfflineDatabaseService offlineDatabase,
    required SimpleCacheManager cacheManager,
  })  : _supabaseClient = supabaseClient,
        _offlineDatabase = offlineDatabase,
        _cacheManager = cacheManager;

  @override
  Future<ArtistEntity?> getArtistById(int artistId) async {
    try {
      // Try cache first
      final cacheKey = '$_cacheKeyPrefix$artistId';
      final cachedData = await _cacheManager.get(cacheKey);
      if (cachedData != null) {
        return _mapToEntity(cachedData);
      }

      // Try local database
      final localData = await _offlineDatabase.query(
        _tableName,
        where: 'id = ?',
        whereArgs: [artistId],
      );

      if (localData.isNotEmpty) {
        final artistData = localData.first;
        await _cacheManager.set(cacheKey, artistData, ttl: Duration(hours: 2));
        return _mapToEntity(artistData);
      }

      // Fetch from remote with group information
      final response = await _supabaseClient
          .from(_tableName)
          .select('''
            *,
            artist_group:artist_groups(*)
          ''')
          .eq('id', artistId)
          .maybeSingle();

      if (response == null) return null;

      // Cache and store locally
      await _cacheManager.set(cacheKey, response, ttl: Duration(hours: 2));
      await _offlineDatabase.insertOrUpdate(_tableName, response);

      return _mapToEntity(response);
    } catch (e) {
      logger.e('Failed to get artist by ID: $artistId', error: e);
      return null;
    }
  }

  @override
  Future<List<ArtistEntity>> getArtistsByIds(List<int> artistIds) async {
    try {
      if (artistIds.isEmpty) return [];

      final response = await _supabaseClient
          .from(_tableName)
          .select('''
            *,
            artist_group:artist_groups(*)
          ''')
          .in_('id', artistIds)
          .eq('deleted_at', null);

      return response.map<ArtistEntity>((data) => _mapToEntity(data)).toList();
    } catch (e) {
      logger.e('Failed to get artists by IDs', error: e);
      return [];
    }
  }

  @override
  Future<List<ArtistEntity>> searchArtists({
    required String query,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _supabaseClient
          .from(_tableName)
          .select('''
            *,
            artist_group:artist_groups(*)
          ''')
          .or('name.ilike.%$query%,artist_group.name.ilike.%$query%')
          .eq('deleted_at', null)
          .order('total_votes', ascending: false)
          .range(offset, offset + limit - 1);

      return response.map<ArtistEntity>((data) => _mapToEntity(data)).toList();
    } catch (e) {
      logger.e('Failed to search artists: $query', error: e);
      return [];
    }
  }

  @override
  Future<List<ArtistEntity>> getPopularArtists({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _supabaseClient
          .from(_tableName)
          .select('''
            *,
            artist_group:artist_groups(*)
          ''')
          .eq('deleted_at', null)
          .gte('total_votes', 1000) // Popular threshold
          .order('total_votes', ascending: false)
          .range(offset, offset + limit - 1);

      return response.map<ArtistEntity>((data) => _mapToEntity(data)).toList();
    } catch (e) {
      logger.e('Failed to get popular artists', error: e);
      return [];
    }
  }

  @override
  Future<List<ArtistEntity>> getTrendingArtists({
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      // Get artists with high recent voting activity
      final response = await _supabaseClient
          .from(_tableName)
          .select('''
            *,
            artist_group:artist_groups(*)
          ''')
          .eq('deleted_at', null)
          .gte('current_ranking', 1)
          .lte('current_ranking', 100)
          .order('current_ranking', ascending: true)
          .range(offset, offset + limit - 1);

      return response.map<ArtistEntity>((data) => _mapToEntity(data)).toList();
    } catch (e) {
      logger.e('Failed to get trending artists', error: e);
      return [];
    }
  }

  @override
  Future<List<ArtistEntity>> getArtistsByGroup(int groupId) async {
    try {
      final response = await _supabaseClient
          .from(_tableName)
          .select('''
            *,
            artist_group:artist_groups(*)
          ''')
          .eq('artist_group_id', groupId)
          .eq('deleted_at', null)
          .order('created_at', ascending: true);

      return response.map<ArtistEntity>((data) => _mapToEntity(data)).toList();
    } catch (e) {
      logger.e('Failed to get artists by group: $groupId', error: e);
      return [];
    }
  }

  @override
  Future<VoteRecord> addVote({
    required String userId,
    required int artistId,
    required int voteCount,
    int starCandyUsed = 0,
  }) async {
    try {
      // Record the vote
      final voteData = {
        'user_id': userId,
        'artist_id': artistId,
        'vote_count': voteCount,
        'star_candy_used': starCandyUsed,
        'created_at': DateTime.now().toIso8601String(),
      };

      final voteResponse = await _supabaseClient
          .from(_voteTableName)
          .insert(voteData)
          .select()
          .single();

      // Update artist's total vote count
      await _supabaseClient.rpc('increment_artist_votes', params: {
        'artist_id': artistId,
        'vote_increment': voteCount,
      });

      // Clear cache for this artist
      final cacheKey = '$_cacheKeyPrefix$artistId';
      await _cacheManager.delete(cacheKey);

      return VoteRecord(
        id: voteResponse['id'] as int,
        userId: userId,
        artistId: artistId,
        voteCount: voteCount,
        starCandyUsed: starCandyUsed,
        timestamp: DateTime.parse(voteResponse['created_at'] as String),
      );
    } catch (e) {
      logger.e('Failed to add vote for artist: $artistId', error: e);
      throw Exception('Failed to add vote: $e');
    }
  }

  @override
  Future<int> getUserDailyVoteCount(String userId) async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(Duration(days: 1));

      final response = await _supabaseClient
          .from(_voteTableName)
          .select('vote_count')
          .eq('user_id', userId)
          .gte('created_at', startOfDay.toIso8601String())
          .lt('created_at', endOfDay.toIso8601String());

      int totalVotes = 0;
      for (final vote in response) {
        totalVotes += vote['vote_count'] as int;
      }

      return totalVotes;
    } catch (e) {
      logger.e('Failed to get user daily vote count: $userId', error: e);
      return 0;
    }
  }

  @override
  Future<List<VoteRecord>> getUserVoteHistory({
    required String userId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _supabaseClient
          .from(_voteTableName)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return response.map<VoteRecord>((data) => VoteRecord(
        id: data['id'] as int,
        userId: data['user_id'] as String,
        artistId: data['artist_id'] as int,
        voteCount: data['vote_count'] as int,
        starCandyUsed: data['star_candy_used'] as int? ?? 0,
        timestamp: DateTime.parse(data['created_at'] as String),
      )).toList();
    } catch (e) {
      logger.e('Failed to get user vote history: $userId', error: e);
      return [];
    }
  }

  @override
  Future<List<VoteRecord>> getArtistVoteHistory({
    required int artistId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _supabaseClient
          .from(_voteTableName)
          .select()
          .eq('artist_id', artistId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return response.map<VoteRecord>((data) => VoteRecord(
        id: data['id'] as int,
        userId: data['user_id'] as String,
        artistId: data['artist_id'] as int,
        voteCount: data['vote_count'] as int,
        starCandyUsed: data['star_candy_used'] as int? ?? 0,
        timestamp: DateTime.parse(data['created_at'] as String),
      )).toList();
    } catch (e) {
      logger.e('Failed to get artist vote history: $artistId', error: e);
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>> getArtistStats(int artistId) async {
    try {
      final response = await _supabaseClient.rpc('get_artist_stats', params: {
        'artist_id': artistId,
      });

      return response as Map<String, dynamic>;
    } catch (e) {
      logger.e('Failed to get artist stats: $artistId', error: e);
      return {};
    }
  }

  @override
  Future<List<ArtistEntity>> getTopRankedArtists({
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final response = await _supabaseClient
          .from(_tableName)
          .select('''
            *,
            artist_group:artist_groups(*)
          ''')
          .eq('deleted_at', null)
          .gte('current_ranking', 1)
          .order('current_ranking', ascending: true)
          .range(offset, offset + limit - 1);

      return response.map<ArtistEntity>((data) => _mapToEntity(data)).toList();
    } catch (e) {
      logger.e('Failed to get top ranked artists', error: e);
      return [];
    }
  }

  ArtistEntity _mapToEntity(Map<String, dynamic> data) {
    // Parse artist group if exists
    ArtistGroupEntity? artistGroup;
    if (data['artist_group'] != null) {
      final groupData = data['artist_group'] as Map<String, dynamic>;
      artistGroup = ArtistGroupEntity(
        id: groupData['id'] as int,
        name: Content.unsafe(
          _extractLocalizedName(groupData['name']),
          ContentType.title,
        ),
        image: groupData['image'] as String?,
        createdAt: DateTime.parse(groupData['created_at'] as String),
        updatedAt: groupData['updated_at'] != null
            ? DateTime.parse(groupData['updated_at'] as String)
            : null,
        deletedAt: groupData['deleted_at'] != null
            ? DateTime.parse(groupData['deleted_at'] as String)
            : null,
      );
    }

    return ArtistEntity(
      id: data['id'] as int,
      name: Content.unsafe(
        _extractLocalizedName(data['name']),
        ContentType.title,
      ),
      image: data['image'] as String?,
      birthDate: data['birth_date'] != null
          ? DateTime.parse(data['birth_date'] as String)
          : null,
      gender: data['gender'] as String?,
      artistGroup: artistGroup,
      createdAt: DateTime.parse(data['created_at'] as String),
      updatedAt: data['updated_at'] != null
          ? DateTime.parse(data['updated_at'] as String)
          : null,
      deletedAt: data['deleted_at'] != null
          ? DateTime.parse(data['deleted_at'] as String)
          : null,
      isBookmarked: data['is_bookmarked'] as bool? ?? false,
      totalVotes: data['total_votes'] as int? ?? 0,
      currentRanking: data['current_ranking'] as int? ?? 0,
    );
  }

  String _extractLocalizedName(dynamic nameData) {
    if (nameData is String) return nameData;
    if (nameData is Map<String, dynamic>) {
      // Try to get localized name, fallback to first available
      return nameData['ko'] ??
             nameData['en'] ??
             nameData.values.first?.toString() ??
             'Unknown';
    }
    return 'Unknown';
  }
}
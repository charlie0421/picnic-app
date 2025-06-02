import 'package:picnic_lib/data/models/vote/artist.dart';
import 'package:picnic_lib/data/repositories/base_repository.dart';

/// 아티스트 데이터 접근을 위한 Repository
class ArtistRepository extends BaseCrudRepository<ArtistModel, int> {
  @override
  String get tableName => 'artist';

  @override
  ArtistModel fromJson(Map<String, dynamic> json) => ArtistModel.fromJson(json);

  @override
  Map<String, dynamic> toJson(ArtistModel model) => model.toJson();

  @override
  int getId(ArtistModel model) => model.id;

  /// 특정 아티스트 조회 (아티스트 그룹 정보 포함)
  Future<ArtistModel?> findByIdWithGroup(int artistId) async {
    try {
      final response = await supabase
          .from(tableName)
          .select('*, artist_group(*)')
          .eq('id', artistId)
          .maybeSingle();

      return handleResponse(response, fromJson);
    } catch (e) {
      return handleError('findByIdWithGroup', Exception(e), null);
    }
  }

  /// 아티스트 그룹별 아티스트 목록 조회
  Future<List<ArtistModel>> findByGroupId(int groupId) async {
    try {
      final response = await supabase
          .from(tableName)
          .select('*, artist_group(*)')
          .eq('artist_group_id', groupId)
          .order('name');

      return handleListResponse(response, fromJson);
    } catch (e) {
      return handleError('findByGroupId', Exception(e), <ArtistModel>[]);
    }
  }

  /// 성별로 아티스트 검색
  Future<List<ArtistModel>> findByGender(String gender) async {
    try {
      final response = await supabase
          .from(tableName)
          .select('*, artist_group(*)')
          .eq('gender', gender)
          .order('name');

      return handleListResponse(response, fromJson);
    } catch (e) {
      return handleError('findByGender', Exception(e), <ArtistModel>[]);
    }
  }

  /// 아티스트 이름으로 검색
  Future<List<ArtistModel>> searchByName(String query, {int limit = 20}) async {
    try {
      final response = await supabase
          .from(tableName)
          .select('*, artist_group(*)')
          .ilike('name', '%$query%')
          .order('name')
          .limit(limit);

      return handleListResponse(response, fromJson);
    } catch (e) {
      return handleError('searchByName', Exception(e), <ArtistModel>[]);
    }
  }

  /// 사용자가 북마크한 아티스트 목록 조회
  Future<List<ArtistModel>> findBookmarkedArtists() async {
    try {
      requireAuth();
      
      final response = await supabase
          .from('artist_user_bookmark')
          .select('''
            artist_id, 
            artist(
              id, 
              name, 
              image, 
              gender, 
              birth_date, 
              artist_group(id, name, image)
            )
          ''')
          .eq('user_id', currentUserId!);

      final bookmarkedArtists = (response as List<dynamic>).map((data) {
        final artist = ArtistModel.fromJson(data['artist'] as Map<String, dynamic>);
        return artist.copyWith(isBookmarked: true);
      }).toList();

      return bookmarkedArtists;
    } catch (e) {
      return handleError('findBookmarkedArtists', Exception(e), <ArtistModel>[]);
    }
  }

  /// 아티스트 북마크 추가
  Future<bool> addBookmark(int artistId) async {
    try {
      requireAuth();
      
      await supabase.from('artist_user_bookmark').upsert({
        'artist_id': artistId,
        'user_id': currentUserId!,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      });

      return true;
    } catch (e) {
      return handleError('addBookmark', Exception(e), false);
    }
  }

  /// 아티스트 북마크 제거
  Future<bool> removeBookmark(int artistId) async {
    try {
      requireAuth();
      
      await supabase
          .from('artist_user_bookmark')
          .delete()
          .eq('artist_id', artistId)
          .eq('user_id', currentUserId!);

      return true;
    } catch (e) {
      return handleError('removeBookmark', Exception(e), false);
    }
  }

  /// 특정 아티스트의 북마크 상태 확인
  Future<bool> isBookmarked(int artistId) async {
    try {
      if (!isAuthenticated) return false;
      
      final response = await supabase
          .from('artist_user_bookmark')
          .select('id')
          .eq('artist_id', artistId)
          .eq('user_id', currentUserId!)
          .maybeSingle();

      return response != null;
    } catch (e) {
      return handleError('isBookmarked', Exception(e), false);
    }
  }

  /// 인기 아티스트 목록 조회 (북마크 수 기준)
  Future<List<ArtistModel>> findPopularArtists({int limit = 10}) async {
    try {
      final response = await supabase.rpc('get_popular_artists', params: {
        'limit_count': limit,
      });

      return handleListResponse(response, fromJson);
    } catch (e) {
      return handleError('findPopularArtists', Exception(e), <ArtistModel>[]);
    }
  }

  /// 추천 아티스트 목록 조회 (사용자 선호도 기반)
  Future<List<ArtistModel>> findRecommendedArtists({int limit = 10}) async {
    try {
      if (!isAuthenticated) return findPopularArtists(limit: limit);
      
      final response = await supabase.rpc('get_recommended_artists', params: {
        'user_id': currentUserId!,
        'limit_count': limit,
      });

      return handleListResponse(response, fromJson);
    } catch (e) {
      // 추천 실패시 인기 아티스트로 대체
      return findPopularArtists(limit: limit);
    }
  }
}
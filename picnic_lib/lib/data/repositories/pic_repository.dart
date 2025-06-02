import 'package:picnic_lib/data/models/pic/celeb.dart';
import 'package:picnic_lib/data/models/pic/library.dart';
import 'package:picnic_lib/data/repositories/base_repository.dart';
import 'package:picnic_lib/core/utils/logger.dart';

class PicRepository extends BaseRepository {
  static const String _celebTable = 'celeb';
  static const String _libraryTable = 'library';
  static const String _libraryImageTable = 'library_image';
  static const String _celebBookmarkTable = 'celeb_bookmark_user';

  // Celeb operations
  Future<List<CelebModel>> getCelebs({
    int? limit,
    int? offset,
    String? category,
    bool? isBookmarked,
  }) async {
    try {
      var query = supabase.from(_celebTable).select('*');

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
        () => query.order('id', ascending: true),
        'getCelebs',
      );

      List<CelebModel> celebs = response.map((data) => CelebModel.fromJson(data)).toList();

      // If user is authenticated and we need to check bookmark status
      if (isAuthenticated() && (isBookmarked == null || isBookmarked == true)) {
        celebs = await _enrichCelebsWithBookmarkStatus(celebs);
      }

      return celebs;
    } catch (e) {
      logger.e('Error getting celebs: $e');
      throw RepositoryException('Failed to get celebs', originalError: e);
    }
  }

  Future<CelebModel?> getCelebById(int celebId) async {
    try {
      final response = await executeQuery(
        () => supabase.from(_celebTable).select('*').eq('id', celebId).maybeSingle(),
        'getCelebById',
      );

      if (response == null) return null;

      CelebModel celeb = CelebModel.fromJson(response);

      // Check bookmark status if user is authenticated
      if (isAuthenticated()) {
        final isBookmarked = await _isCelebBookmarked(celebId);
        celeb = celeb.copyWith(isBookmarked: isBookmarked);
      }

      return celeb;
    } catch (e) {
      logger.e('Error getting celeb by ID: $e');
      throw RepositoryException('Failed to get celeb', originalError: e);
    }
  }

  Future<List<CelebModel>> searchCelebs(String query) async {
    try {
      final response = await executeQuery(
        () => supabase.from(_celebTable)
            .select('*')
            .ilike('name', '%$query%')
            .order('name'),
        'searchCelebs',
      );

      List<CelebModel> celebs = response.map((data) => CelebModel.fromJson(data)).toList();

      if (isAuthenticated()) {
        celebs = await _enrichCelebsWithBookmarkStatus(celebs);
      }

      return celebs;
    } catch (e) {
      logger.e('Error searching celebs: $e');
      throw RepositoryException('Failed to search celebs', originalError: e);
    }
  }

  // Bookmark operations
  Future<void> addCelebBookmark(int celebId) async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) {
        throw RepositoryException('User must be authenticated to bookmark celeb');
      }

      await executeQuery(
        () => supabase.from(_celebBookmarkTable).upsert({
          'celeb_id': celebId,
          'user_id': userId,
          'created_at': DateTime.now().toUtc().toIso8601String(),
        }),
        'addCelebBookmark',
      );
    } catch (e) {
      logger.e('Error adding celeb bookmark: $e');
      throw RepositoryException('Failed to bookmark celeb', originalError: e);
    }
  }

  Future<void> removeCelebBookmark(int celebId) async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) {
        throw RepositoryException('User must be authenticated to remove bookmark');
      }

      await executeQuery(
        () => supabase.from(_celebBookmarkTable)
            .delete()
            .eq('celeb_id', celebId)
            .eq('user_id', userId),
        'removeCelebBookmark',
      );
    } catch (e) {
      logger.e('Error removing celeb bookmark: $e');
      throw RepositoryException('Failed to remove bookmark', originalError: e);
    }
  }

  Future<List<CelebModel>> getBookmarkedCelebs() async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) {
        throw RepositoryException('User must be authenticated to get bookmarked celebs');
      }

      final response = await executeQuery(
        () => supabase.from(_celebBookmarkTable)
            .select('celeb_id, $_celebTable(*)')
            .eq('user_id', userId)
            .order('created_at', ascending: false),
        'getBookmarkedCelebs',
      );

      return response.map((data) {
        final celebData = data[_celebTable] as Map<String, dynamic>;
        return CelebModel.fromJson(celebData).copyWith(isBookmarked: true);
      }).toList();
    } catch (e) {
      logger.e('Error getting bookmarked celebs: $e');
      throw RepositoryException('Failed to get bookmarked celebs', originalError: e);
    }
  }

  // Library operations
  Future<List<LibraryModel>> getLibraries({
    int? limit,
    int? offset,
  }) async {
    try {
      var query = supabase.from(_libraryTable).select('*');

      if (limit != null) {
        query = query.limit(limit);
      }

      if (offset != null) {
        query = query.range(offset, offset + (limit ?? 20) - 1);
      }

      final response = await executeQuery(
        () => query.order('created_at', ascending: false),
        'getLibraries',
      );

      return response.map((data) => LibraryModel.fromJson(data)).toList();
    } catch (e) {
      logger.e('Error getting libraries: $e');
      throw RepositoryException('Failed to get libraries', originalError: e);
    }
  }

  Future<LibraryModel?> getLibraryById(int libraryId) async {
    try {
      final response = await executeQuery(
        () => supabase.from(_libraryTable).select('*').eq('id', libraryId).maybeSingle(),
        'getLibraryById',
      );

      return response != null ? LibraryModel.fromJson(response) : null;
    } catch (e) {
      logger.e('Error getting library by ID: $e');
      throw RepositoryException('Failed to get library', originalError: e);
    }
  }

  Future<LibraryModel> createLibrary({
    required String name,
    String? description,
    String? coverImageUrl,
  }) async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) {
        throw RepositoryException('User must be authenticated to create library');
      }

      final libraryData = {
        'name': name,
        'description': description,
        'cover_image_url': coverImageUrl,
        'user_id': userId,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      };

      final response = await executeQuery(
        () => supabase.from(_libraryTable).insert(libraryData).select().single(),
        'createLibrary',
      );

      return LibraryModel.fromJson(response);
    } catch (e) {
      logger.e('Error creating library: $e');
      throw RepositoryException('Failed to create library', originalError: e);
    }
  }

  Future<LibraryModel> updateLibrary({
    required int libraryId,
    String? name,
    String? description,
    String? coverImageUrl,
  }) async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) {
        throw RepositoryException('User must be authenticated to update library');
      }

      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      };

      if (name != null) updateData['name'] = name;
      if (description != null) updateData['description'] = description;
      if (coverImageUrl != null) updateData['cover_image_url'] = coverImageUrl;

      final response = await executeQuery(
        () => supabase.from(_libraryTable)
            .update(updateData)
            .eq('id', libraryId)
            .eq('user_id', userId)
            .select()
            .single(),
        'updateLibrary',
      );

      return LibraryModel.fromJson(response);
    } catch (e) {
      logger.e('Error updating library: $e');
      throw RepositoryException('Failed to update library', originalError: e);
    }
  }

  Future<void> deleteLibrary(int libraryId) async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) {
        throw RepositoryException('User must be authenticated to delete library');
      }

      await executeQuery(
        () => supabase.from(_libraryTable)
            .delete()
            .eq('id', libraryId)
            .eq('user_id', userId),
        'deleteLibrary',
      );
    } catch (e) {
      logger.e('Error deleting library: $e');
      throw RepositoryException('Failed to delete library', originalError: e);
    }
  }

  // Library image operations
  Future<void> addImageToLibrary(int libraryId, int imageId) async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) {
        throw RepositoryException('User must be authenticated to add image to library');
      }

      // Verify that the user owns the library
      final library = await getLibraryById(libraryId);
      if (library == null) {
        throw RepositoryException('Library not found');
      }

      await executeQuery(
        () => supabase.from(_libraryImageTable).upsert({
          'library_id': libraryId,
          'image_id': imageId,
          'added_at': DateTime.now().toUtc().toIso8601String(),
        }),
        'addImageToLibrary',
      );
    } catch (e) {
      logger.e('Error adding image to library: $e');
      throw RepositoryException('Failed to add image to library', originalError: e);
    }
  }

  Future<void> removeImageFromLibrary(int libraryId, int imageId) async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) {
        throw RepositoryException('User must be authenticated to remove image from library');
      }

      await executeQuery(
        () => supabase.from(_libraryImageTable)
            .delete()
            .eq('library_id', libraryId)
            .eq('image_id', imageId),
        'removeImageFromLibrary',
      );
    } catch (e) {
      logger.e('Error removing image from library: $e');
      throw RepositoryException('Failed to remove image from library', originalError: e);
    }
  }

  Future<List<Map<String, dynamic>>> getLibraryImages(int libraryId) async {
    try {
      final response = await executeQuery(
        () => supabase.from(_libraryImageTable)
            .select('*, images(*)')
            .eq('library_id', libraryId)
            .order('added_at', ascending: false),
        'getLibraryImages',
      );

      return response;
    } catch (e) {
      logger.e('Error getting library images: $e');
      throw RepositoryException('Failed to get library images', originalError: e);
    }
  }

  // Helper methods
  Future<List<CelebModel>> _enrichCelebsWithBookmarkStatus(List<CelebModel> celebs) async {
    if (celebs.isEmpty || !isAuthenticated()) return celebs;

    try {
      final userId = getCurrentUserId()!;
      final celebIds = celebs.map((celeb) => celeb.id).toList();

      final response = await executeQuery(
        () => supabase.from(_celebBookmarkTable)
            .select('celeb_id')
            .eq('user_id', userId)
            .inFilter('celeb_id', celebIds),
        '_enrichCelebsWithBookmarkStatus',
      );

      final bookmarkedCelebIds = response.map((data) => data['celeb_id'] as int).toSet();

      return celebs.map((celeb) {
        return celeb.copyWith(isBookmarked: bookmarkedCelebIds.contains(celeb.id));
      }).toList();
    } catch (e) {
      logger.e('Error enriching celebs with bookmark status: $e');
      return celebs; // Return original celebs if enrichment fails
    }
  }

  Future<bool> _isCelebBookmarked(int celebId) async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) return false;

      final response = await executeQuery(
        () => supabase.from(_celebBookmarkTable)
            .select('id')
            .eq('celeb_id', celebId)
            .eq('user_id', userId)
            .maybeSingle(),
        '_isCelebBookmarked',
      );

      return response != null;
    } catch (e) {
      logger.e('Error checking if celeb is bookmarked: $e');
      return false;
    }
  }

  // Stream operations for real-time updates
  Stream<List<CelebModel>> streamCelebs() {
    return supabase.from(_celebTable)
        .stream(primaryKey: ['id'])
        .map((data) => 
          data.map((item) => CelebModel.fromJson(item)).toList()
        );
  }

  Stream<List<LibraryModel>> streamLibraries() {
    return supabase.from(_libraryTable)
        .stream(primaryKey: ['id'])
        .map((data) => 
          data.map((item) => LibraryModel.fromJson(item)).toList()
        );
  }
}
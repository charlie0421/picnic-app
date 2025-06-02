import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:picnic_lib/domain/entities/user_entity.dart';
import 'package:picnic_lib/domain/interfaces/user_repository_interface.dart';
import 'package:picnic_lib/domain/value_objects/email.dart';
import 'package:picnic_lib/domain/value_objects/star_candy.dart';
import 'package:picnic_lib/core/services/offline_database_service.dart';
import 'package:picnic_lib/core/services/simple_cache_manager.dart';
import 'package:picnic_lib/core/utils/logger.dart';

class UserRepositoryImpl implements IUserRepository {
  final SupabaseClient _supabaseClient;
  final OfflineDatabaseService _offlineDatabase;
  final SimpleCacheManager _cacheManager;

  static const String _tableName = 'user_profiles';
  static const String _cacheKeyPrefix = 'user_';

  UserRepositoryImpl({
    required SupabaseClient supabaseClient,
    required OfflineDatabaseService offlineDatabase,
    required SimpleCacheManager cacheManager,
  })  : _supabaseClient = supabaseClient,
        _offlineDatabase = offlineDatabase,
        _cacheManager = cacheManager;

  @override
  Future<UserEntity?> getUserById(String userId) async {
    try {
      // Try cache first
      final cacheKey = '$_cacheKeyPrefix$userId';
      final cachedData = await _cacheManager.get(cacheKey);
      if (cachedData != null) {
        return _mapToEntity(cachedData);
      }

      // Try local database
      final localData = await _offlineDatabase.query(
        _tableName,
        where: 'id = ?',
        whereArgs: [userId],
      );

      if (localData.isNotEmpty) {
        final userData = localData.first;
        await _cacheManager.set(cacheKey, userData, ttl: Duration(hours: 1));
        return _mapToEntity(userData);
      }

      // Fetch from remote
      final response = await _supabaseClient
          .from(_tableName)
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) return null;

      // Cache and store locally
      await _cacheManager.set(cacheKey, response, ttl: Duration(hours: 1));
      await _offlineDatabase.insertOrUpdate(_tableName, response);

      return _mapToEntity(response);
    } catch (e) {
      logger.e('Failed to get user by ID: $userId', error: e);
      return null;
    }
  }

  @override
  Future<UserEntity?> getUserByEmail(String email) async {
    try {
      // Try local database first
      final localData = await _offlineDatabase.query(
        _tableName,
        where: 'email = ?',
        whereArgs: [email.toLowerCase()],
      );

      if (localData.isNotEmpty) {
        return _mapToEntity(localData.first);
      }

      // Fetch from remote
      final response = await _supabaseClient
          .from(_tableName)
          .select()
          .eq('email', email.toLowerCase())
          .maybeSingle();

      if (response == null) return null;

      // Store locally and cache
      await _offlineDatabase.insertOrUpdate(_tableName, response);
      final cacheKey = '$_cacheKeyPrefix${response['id']}';
      await _cacheManager.set(cacheKey, response, ttl: Duration(hours: 1));

      return _mapToEntity(response);
    } catch (e) {
      logger.e('Failed to get user by email: $email', error: e);
      return null;
    }
  }

  @override
  Future<bool> nicknameExists(String nickname) async {
    try {
      final response = await _supabaseClient
          .from(_tableName)
          .select('id')
          .eq('nickname', nickname)
          .maybeSingle();

      return response != null;
    } catch (e) {
      logger.e('Failed to check nickname existence: $nickname', error: e);
      return false;
    }
  }

  @override
  Future<UserEntity> createUser({
    required String id,
    required String nickname,
    required Email email,
    String? avatarUrl,
    DateTime? birthDate,
    String? gender,
    String? birthTime,
  }) async {
    try {
      final userData = {
        'id': id,
        'nickname': nickname,
        'email': email.value,
        'avatar_url': avatarUrl,
        'birth_date': birthDate?.toIso8601String(),
        'gender': gender,
        'birth_time': birthTime,
        'star_candy': 0,
        'star_candy_bonus': 0,
        'is_admin': false,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Insert to remote
      final response = await _supabaseClient
          .from(_tableName)
          .insert(userData)
          .select()
          .single();

      // Store locally and cache
      await _offlineDatabase.insertOrUpdate(_tableName, response);
      final cacheKey = '$_cacheKeyPrefix$id';
      await _cacheManager.set(cacheKey, response, ttl: Duration(hours: 1));

      return _mapToEntity(response);
    } catch (e) {
      logger.e('Failed to create user', error: e);
      throw Exception('Failed to create user: $e');
    }
  }

  @override
  Future<UserEntity> updateUserProfile({
    required String userId,
    String? nickname,
    String? avatarUrl,
    DateTime? birthDate,
    String? gender,
    String? birthTime,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (nickname != null) updateData['nickname'] = nickname;
      if (avatarUrl != null) updateData['avatar_url'] = avatarUrl;
      if (birthDate != null) updateData['birth_date'] = birthDate.toIso8601String();
      if (gender != null) updateData['gender'] = gender;
      if (birthTime != null) updateData['birth_time'] = birthTime;

      // Update remote
      final response = await _supabaseClient
          .from(_tableName)
          .update(updateData)
          .eq('id', userId)
          .select()
          .single();

      // Update local and cache
      await _offlineDatabase.insertOrUpdate(_tableName, response);
      final cacheKey = '$_cacheKeyPrefix$userId';
      await _cacheManager.set(cacheKey, response, ttl: Duration(hours: 1));

      return _mapToEntity(response);
    } catch (e) {
      logger.e('Failed to update user profile: $userId', error: e);
      throw Exception('Failed to update user profile: $e');
    }
  }

  @override
  Future<UserEntity> addStarCandy({
    required String userId,
    required StarCandy amount,
    required String reason,
  }) async {
    try {
      // Get current user
      final currentUser = await getUserById(userId);
      if (currentUser == null) {
        throw Exception('User not found');
      }

      final newAmount = currentUser.starCandy.amount + amount.amount;
      
      // Update remote
      final response = await _supabaseClient
          .from(_tableName)
          .update({
            'star_candy': newAmount,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId)
          .select()
          .single();

      // Record transaction
      await _recordStarCandyTransaction(
        userId: userId,
        amount: amount.amount,
        type: 'add',
        reason: reason,
        balanceBefore: currentUser.starCandy.amount,
        balanceAfter: newAmount,
      );

      // Update local and cache
      await _offlineDatabase.insertOrUpdate(_tableName, response);
      final cacheKey = '$_cacheKeyPrefix$userId';
      await _cacheManager.set(cacheKey, response, ttl: Duration(hours: 1));

      return _mapToEntity(response);
    } catch (e) {
      logger.e('Failed to add star candy: $userId', error: e);
      throw Exception('Failed to add star candy: $e');
    }
  }

  @override
  Future<UserEntity> spendStarCandy({
    required String userId,
    required StarCandy amount,
    required String reason,
  }) async {
    try {
      // Get current user
      final currentUser = await getUserById(userId);
      if (currentUser == null) {
        throw Exception('User not found');
      }

      if (!currentUser.canAfford(amount)) {
        throw Exception('Insufficient star candy');
      }

      final newAmount = currentUser.starCandy.amount - amount.amount;
      
      // Update remote
      final response = await _supabaseClient
          .from(_tableName)
          .update({
            'star_candy': newAmount,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId)
          .select()
          .single();

      // Record transaction
      await _recordStarCandyTransaction(
        userId: userId,
        amount: -amount.amount,
        type: 'spend',
        reason: reason,
        balanceBefore: currentUser.starCandy.amount,
        balanceAfter: newAmount,
      );

      // Update local and cache
      await _offlineDatabase.insertOrUpdate(_tableName, response);
      final cacheKey = '$_cacheKeyPrefix$userId';
      await _cacheManager.set(cacheKey, response, ttl: Duration(hours: 1));

      return _mapToEntity(response);
    } catch (e) {
      logger.e('Failed to spend star candy: $userId', error: e);
      throw Exception('Failed to spend star candy: $e');
    }
  }

  @override
  Future<UserEntity> addBonusStarCandy({
    required String userId,
    required StarCandy amount,
    required String reason,
  }) async {
    try {
      // Get current user
      final currentUser = await getUserById(userId);
      if (currentUser == null) {
        throw Exception('User not found');
      }

      final newBonusAmount = currentUser.starCandyBonus.amount + amount.amount;
      
      // Update remote
      final response = await _supabaseClient
          .from(_tableName)
          .update({
            'star_candy_bonus': newBonusAmount,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId)
          .select()
          .single();

      // Record transaction
      await _recordStarCandyTransaction(
        userId: userId,
        amount: amount.amount,
        type: 'bonus',
        reason: reason,
        balanceBefore: currentUser.starCandyBonus.amount,
        balanceAfter: newBonusAmount,
      );

      // Update local and cache
      await _offlineDatabase.insertOrUpdate(_tableName, response);
      final cacheKey = '$_cacheKeyPrefix$userId';
      await _cacheManager.set(cacheKey, response, ttl: Duration(hours: 1));

      return _mapToEntity(response);
    } catch (e) {
      logger.e('Failed to add bonus star candy: $userId', error: e);
      throw Exception('Failed to add bonus star candy: $e');
    }
  }

  @override
  Future<List<UserEntity>> searchUsers({
    required String query,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _supabaseClient
          .from(_tableName)
          .select()
          .ilike('nickname', '%$query%')
          .eq('deleted_at', null)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return response.map<UserEntity>((data) => _mapToEntity(data)).toList();
    } catch (e) {
      logger.e('Failed to search users: $query', error: e);
      return [];
    }
  }

  Future<void> _recordStarCandyTransaction({
    required String userId,
    required int amount,
    required String type,
    required String reason,
    required int balanceBefore,
    required int balanceAfter,
  }) async {
    try {
      await _supabaseClient.from('star_candy_transactions').insert({
        'user_id': userId,
        'amount': amount,
        'type': type,
        'reason': reason,
        'balance_before': balanceBefore,
        'balance_after': balanceAfter,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      logger.w('Failed to record star candy transaction', error: e);
      // Don't throw here as it's not critical for the main operation
    }
  }

  UserEntity _mapToEntity(Map<String, dynamic> data) {
    return UserEntity(
      id: data['id'] as String,
      nickname: data['nickname'] as String,
      email: Email.unsafe(data['email'] as String),
      avatarUrl: data['avatar_url'] as String?,
      starCandy: StarCandy(data['star_candy'] as int? ?? 0),
      starCandyBonus: StarCandy(data['star_candy_bonus'] as int? ?? 0),
      isAdmin: data['is_admin'] as bool? ?? false,
      birthDate: data['birth_date'] != null 
          ? DateTime.parse(data['birth_date'] as String)
          : null,
      gender: data['gender'] as String?,
      birthTime: data['birth_time'] as String?,
      createdAt: DateTime.parse(data['created_at'] as String),
      updatedAt: data['updated_at'] != null 
          ? DateTime.parse(data['updated_at'] as String)
          : null,
      deletedAt: data['deleted_at'] != null 
          ? DateTime.parse(data['deleted_at'] as String)
          : null,
      userAgreement: data['terms_agreed_at'] != null || data['privacy_agreed_at'] != null
          ? UserAgreement(
              userId: data['id'] as String,
              termsAgreedAt: data['terms_agreed_at'] != null 
                  ? DateTime.parse(data['terms_agreed_at'] as String)
                  : null,
              privacyAgreedAt: data['privacy_agreed_at'] != null 
                  ? DateTime.parse(data['privacy_agreed_at'] as String)
                  : null,
            )
          : null,
    );
  }
}
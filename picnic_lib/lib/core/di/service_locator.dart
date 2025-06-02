import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Domain
import 'package:picnic_lib/domain/interfaces/user_repository_interface.dart';
import 'package:picnic_lib/domain/interfaces/artist_repository_interface.dart';

// Application
import 'package:picnic_lib/application/use_cases/user/get_user_profile_use_case.dart';
import 'package:picnic_lib/application/use_cases/user/update_user_profile_use_case.dart';
import 'package:picnic_lib/application/use_cases/user/manage_star_candy_use_case.dart';
import 'package:picnic_lib/application/use_cases/artist/get_artist_use_case.dart';
import 'package:picnic_lib/application/use_cases/artist/vote_for_artist_use_case.dart';

// Data
import 'package:picnic_lib/data/repositories/user_repository_impl.dart';
import 'package:picnic_lib/data/repositories/artist_repository_impl.dart';

// Services
import 'package:picnic_lib/core/services/auth/auth_service.dart';
import 'package:picnic_lib/core/services/cache_management_service.dart';
import 'package:picnic_lib/core/services/enhanced_network_service.dart';
import 'package:picnic_lib/core/services/offline_database_service.dart';
import 'package:picnic_lib/core/services/offline_sync_service.dart';
import 'package:picnic_lib/core/services/simple_cache_manager.dart';

/// Service Locator using GetIt for dependency injection
/// 
/// This class manages the registration and retrieval of dependencies
/// throughout the application using the Service Locator pattern.
class ServiceLocator {
  static final GetIt _getIt = GetIt.instance;
  
  /// Get instance of a registered type
  static T get<T extends Object>() => _getIt.get<T>();
  
  /// Check if a type is registered
  static bool isRegistered<T extends Object>() => _getIt.isRegistered<T>();
  
  /// Initialize all dependencies
  static Future<void> init() async {
    await _registerCore();
    await _registerServices();
    await _registerRepositories();
    await _registerUseCases();
  }
  
  /// Register core dependencies (external packages)
  static Future<void> _registerCore() async {
    // SharedPreferences
    final sharedPreferences = await SharedPreferences.getInstance();
    _getIt.registerSingleton<SharedPreferences>(sharedPreferences);
    
    // Flutter Secure Storage
    const secureStorage = FlutterSecureStorage(
      aOptions: AndroidOptions(
        encryptedSharedPreferences: true,
      ),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
      ),
    );
    _getIt.registerSingleton<FlutterSecureStorage>(secureStorage);
    
    // Supabase Client
    final supabaseClient = Supabase.instance.client;
    _getIt.registerSingleton<SupabaseClient>(supabaseClient);
  }
  
  /// Register services layer
  static Future<void> _registerServices() async {
    // Network Service
    _getIt.registerSingleton<EnhancedNetworkService>(
      EnhancedNetworkService(),
    );
    
    // Cache Manager
    _getIt.registerSingleton<SimpleCacheManager>(
      SimpleCacheManager.instance,
    );
    
    // Cache Management Service
    _getIt.registerSingleton<CacheManagementService>(
      CacheManagementService(),
    );
    
    // Offline Database Service
    _getIt.registerSingleton<OfflineDatabaseService>(
      OfflineDatabaseService(),
    );
    
    // Initialize database
    await _getIt<OfflineDatabaseService>().initialize();
    
    // Offline Sync Service
    _getIt.registerSingleton<OfflineSyncService>(
      OfflineSyncService(
        database: _getIt<OfflineDatabaseService>(),
        supabaseClient: _getIt<SupabaseClient>(),
      ),
    );
    
    // Auth Service
    _getIt.registerSingleton<AuthService>(
      AuthService(
        supabaseClient: _getIt<SupabaseClient>(),
        secureStorage: _getIt<FlutterSecureStorage>(),
        sharedPreferences: _getIt<SharedPreferences>(),
      ),
    );
  }
  
  /// Register repositories layer
  static Future<void> _registerRepositories() async {
    // User Repository
    _getIt.registerSingleton<IUserRepository>(
      UserRepositoryImpl(
        supabaseClient: _getIt<SupabaseClient>(),
        offlineDatabase: _getIt<OfflineDatabaseService>(),
        cacheManager: _getIt<SimpleCacheManager>(),
      ),
    );
    
    // Artist Repository
    _getIt.registerSingleton<IArtistRepository>(
      ArtistRepositoryImpl(
        supabaseClient: _getIt<SupabaseClient>(),
        offlineDatabase: _getIt<OfflineDatabaseService>(),
        cacheManager: _getIt<SimpleCacheManager>(),
      ),
    );
  }
  
  /// Register use cases layer
  static Future<void> _registerUseCases() async {
    // User Use Cases
    _getIt.registerFactory<GetUserProfileUseCase>(
      () => GetUserProfileUseCase(_getIt<IUserRepository>()),
    );
    
    _getIt.registerFactory<UpdateUserProfileUseCase>(
      () => UpdateUserProfileUseCase(_getIt<IUserRepository>()),
    );
    
    _getIt.registerFactory<ManageStarCandyUseCase>(
      () => ManageStarCandyUseCase(_getIt<IUserRepository>()),
    );
    
    // Artist Use Cases
    _getIt.registerFactory<GetArtistUseCase>(
      () => GetArtistUseCase(_getIt<IArtistRepository>()),
    );
    
    _getIt.registerFactory<VoteForArtistUseCase>(
      () => VoteForArtistUseCase(
        _getIt<IArtistRepository>(),
        _getIt<IUserRepository>(),
      ),
    );
  }
  
  /// Clean up all dependencies
  static Future<void> dispose() async {
    // Clean up services
    await _getIt<CacheManagementService>().dispose();
    await _getIt<OfflineDatabaseService>().cleanup();
    
    // Reset GetIt
    await _getIt.reset();
  }
  
  /// Reset dependencies (for testing)
  static Future<void> reset() async {
    await _getIt.reset();
  }
}

/// Extension for easy access to dependencies in widgets and providers
extension ServiceLocatorExtension on Object {
  /// Get dependency from service locator
  T locate<T extends Object>() => ServiceLocator.get<T>();
}

/// Mixin for classes that need access to dependencies
mixin ServiceLocatorMixin {
  /// Get dependency from service locator
  T locate<T extends Object>() => ServiceLocator.get<T>();
}
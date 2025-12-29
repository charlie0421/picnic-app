import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/core/errors/vote_request_exceptions.dart';
import 'package:picnic_lib/data/repositories/vote_item_request_repository.dart';
import 'package:picnic_lib/presentation/providers/vote_item_request_provider.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/constants/purchase_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 중복 방지 전담 서비스 컴포넌트
///
/// 사용자의 중복 신청 및 중복 구매를 방지하기 위한 서비스입니다.
/// 메모리 캐싱과 로컬 저장소를 통해 효율적인 중복 감지를 지원합니다.
class DuplicatePreventionService {
  final WidgetRef _ref;

  // 투표 메모리 캐시: userId_voteId -> hasRequested
  final Map<String, bool> _voteCache = {};

  // 캐시 만료 시간 (5분)
  static const Duration _cacheExpiration = Duration(minutes: 5);

  // 캐시 타임스탬프: userId_voteId -> timestamp
  final Map<String, DateTime> _voteCacheTimestamps = {};

  // 진행 중인 요청들을 추적하여 중복 요청 방지
  final Map<String, Completer<bool>> _pendingRequests = {};

  // 🛡️ 구매 중복 방지 관련
  final Map<String, DateTime> _purchaseAttempts =
      {}; // productId_userId -> timestamp
  final Map<String, DateTime> _authenticationStarts =
      {}; // productId_userId -> timestamp
  final Map<String, DateTime> _backgroundPurchases =
      {}; // productId_userId -> timestamp
  final Set<String> _processingPurchases = {}; // 현재 처리 중인 구매들

  // 🛡️ UI 상호작용 패턴 감지 - 대폭 완화
  final Map<String, List<DateTime>> _userInteractionHistory =
      {}; // userId -> interaction timestamps
  static const Duration _rapidInteractionWindow =
      Duration(milliseconds: 500); // 2초 → 0.5초로 단축 (매우 빠른 클릭만 차단)
// 5회 → 10회로 증가 (매우 관대하게)

  DuplicatePreventionService(this._ref);

  VoteItemRequestRepository get _repository =>
      _ref.read(voteItemRequestRepositoryProvider);

  /// 사용자가 특정 투표에 이미 신청했는지 확인 (캐싱 지원)
  ///
  /// [voteId] 투표 ID
  /// [userId] 사용자 ID
  ///
  /// Returns: 이미 신청했으면 true, 아니면 false
  Future<bool> hasUserRequestedVote(int voteId, String userId) async {
    final cacheKey = '${userId}_$voteId';

    try {
      // 1. 진행 중인 요청이 있는지 확인
      if (_pendingRequests.containsKey(cacheKey)) {
        return await _pendingRequests[cacheKey]!.future;
      }

      // 2. 캐시 확인
      if (_isCacheValid(cacheKey)) {
        logger.d('캐시에서 중복 신청 정보 반환: $cacheKey');
        return _voteCache[cacheKey]!;
      }

      // 3. 새로운 요청 시작
      final completer = Completer<bool>();
      _pendingRequests[cacheKey] = completer;

      try {
        // 4. 데이터베이스 조회
        final hasRequested = await _repository.hasUserRequestedArtist(
          voteId,
          0, // 특정 아티스트가 아닌 전체 투표 확인
          userId,
        );

        // 5. 캐시 업데이트
        _updateCache(cacheKey, hasRequested);

        // 6. 결과 반환
        completer.complete(hasRequested);
        return hasRequested;
      } catch (e) {
        completer.completeError(e);
        rethrow;
      } finally {
        _pendingRequests.remove(cacheKey);
      }
    } catch (e) {
      logger.e('중복 신청 확인 중 오류 발생', error: e);
      throw VoteRequestException('중복 신청 확인에 실패했습니다: ${e.toString()}');
    }
  }

  /// 사용자가 이미 해당 아티스트에 대해 신청했는지 확인
  Future<bool> hasUserRequestedArtist({
    required int voteId,
    required int artistId,
    required String userId,
  }) async {
    try {
      return await _repository.hasUserRequestedArtist(
        voteId,
        artistId,
        userId,
      );
    } catch (e) {
      logger.e('중복 신청 확인 중 오류 발생', error: e);
      return false;
    }
  }

  // 🛡️ ===== 구매 중복 방지 메서드들 =====

  /// 구매 중복 방지 검사 - 연타 방지만
  ///
  /// [productId] 구매하려는 제품 ID
  /// [userId] 사용자 ID
  ///
  /// Returns: 구매 허용 여부와 차단 사유
  Future<PurchaseValidationResult> validatePurchaseAttempt(
    String productId,
    String userId,
  ) async {
    final key = '${productId}_$userId';
    final now = DateTime.now();

    try {
      logger.i('🔧 연타 방지 검사: $key');

      // 🔧 연타 방지만 - 300ms 내 중복 클릭 차단
      final lastAttempt = _purchaseAttempts[key];
      if (lastAttempt != null) {
        final timeSinceLastAttempt = now.difference(lastAttempt);
        if (timeSinceLastAttempt < PurchaseConstants.cooldownPeriod) {
          logger.w('🚫 연타 감지: $key (${timeSinceLastAttempt.inMilliseconds}ms)');
          return PurchaseValidationResult(
            allowed: false,
            reason: '너무 빠른 연속 클릭입니다.',
            type: PurchaseDenyType.cooldown,
          );
        }
      }

      // 연타 방지 검사 통과
      logger.i('✅ 연타 방지 검사 통과: $key');
      return PurchaseValidationResult(
        allowed: true,
        reason: null,
        type: null,
      );
    } catch (e) {
      logger.e('🚫 연타 방지 검사 중 오류: $e');
      // 오류 시에도 구매 허용
      return PurchaseValidationResult(
        allowed: true,
        reason: null,
        type: null,
      );
    }
  }

  /// 구매 시도 시작 등록
  void registerPurchaseAttempt(String productId, String userId) {
    final key = '${productId}_$userId';
    final now = DateTime.now();

    _purchaseAttempts[key] = now;
    _processingPurchases.add(key);

    logger.i('🛡️ 구매 시도 등록: $key');
    _savePurchaseAttemptToStorage(key, now);
  }

  /// Touch ID/Face ID 인증 시작 등록
  void registerAuthenticationStart(String productId, String userId) {
    final key = '${productId}_$userId';
    final now = DateTime.now();

    _authenticationStarts[key] = now;
    logger.i('🛡️ 인증 프로세스 시작 등록: $key');
    _saveAuthenticationStartToStorage(key, now);
  }

  /// 백그라운드 구매 감지 등록
  void registerBackgroundPurchase(String productId, String userId) {
    final key = '${productId}_$userId';
    final now = DateTime.now();

    _backgroundPurchases[key] = now;
    logger.w('🛡️ 백그라운드 구매 감지: $key');
    _saveBackgroundPurchaseToStorage(key, now);
  }

  /// 구매 완료 처리
  void completePurchase(String productId, String userId,
      {required bool success}) {
    final key = '${productId}_$userId';

    _processingPurchases.remove(key);

    if (success) {
      // 성공 시 모든 상태 정리
      _authenticationStarts.remove(key);
      _backgroundPurchases.remove(key);
      logger.i('✅ 구매 성공 완료 처리: $key');
    } else {
      // 실패 시 일부 상태만 정리 (재시도 가능하게)
      logger.w('❌ 구매 실패 완료 처리: $key');
    }

    _clearPurchaseDataFromStorage(key);
  }

  /// 타임아웃 발생 시 백그라운드 구매로 전환
  void handlePurchaseTimeout(String productId, String userId) {
    final key = '${productId}_$userId';

    _processingPurchases.remove(key);
    _authenticationStarts.remove(key);

    // 백그라운드 구매로 등록하여 일정 시간 동안 새 구매 차단
    registerBackgroundPurchase(productId, userId);

    logger.w('⏰ 구매 타임아웃 → 백그라운드 추적으로 전환: $key');
  }


  /// 구매 시도를 로컬 저장소에 저장
  Future<void> _savePurchaseAttemptToStorage(
      String key, DateTime timestamp) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('${PurchaseConstants.lastPurchaseAttemptKey}$key',
          timestamp.millisecondsSinceEpoch);
    } catch (e) {
      logger.e('구매 시도 저장 실패: $e');
    }
  }

  /// 인증 시작을 로컬 저장소에 저장
  Future<void> _saveAuthenticationStartToStorage(
      String key, DateTime timestamp) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('${PurchaseConstants.authenticationStartKey}$key',
          timestamp.millisecondsSinceEpoch);
    } catch (e) {
      logger.e('인증 시작 저장 실패: $e');
    }
  }

  /// 백그라운드 구매를 로컬 저장소에 저장
  Future<void> _saveBackgroundPurchaseToStorage(
      String key, DateTime timestamp) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('${PurchaseConstants.backgroundPurchaseKey}$key',
          timestamp.millisecondsSinceEpoch);
    } catch (e) {
      logger.e('백그라운드 구매 저장 실패: $e');
    }
  }

  /// 로컬 저장소에서 구매 데이터 정리
  Future<void> _clearPurchaseDataFromStorage(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('${PurchaseConstants.lastPurchaseAttemptKey}$key');
      await prefs.remove('${PurchaseConstants.authenticationStartKey}$key');
      await prefs.remove('${PurchaseConstants.backgroundPurchaseKey}$key');
    } catch (e) {
      logger.e('구매 데이터 정리 실패: $e');
    }
  }

  /// 🍎 iOS: 모든 구매 관련 상태 완전 초기화
  Future<void> clearAllPurchaseStates() async {
    logger.i('🧹 iOS: 모든 구매 관련 상태 초기화 시작');

    // 메모리 상태 초기화
    _purchaseAttempts.clear();
    _authenticationStarts.clear();
    _backgroundPurchases.clear();
    _processingPurchases.clear();
    _userInteractionHistory.clear();

    // SharedPreferences 정리
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      for (final key in keys) {
        if (key.contains('purchase_') ||
            key.contains('authentication_') ||
            key.contains('background_')) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      logger.e('SharedPreferences 정리 실패: $e');
    }

    logger.i('🧹 iOS: 모든 구매 관련 상태 초기화 완료');
  }

  /// 만료된 데이터 정리 (주기적으로 호출)
  void cleanupExpiredData() {
    final now = DateTime.now();

    // 만료된 인증 데이터 정리
    _authenticationStarts.removeWhere((key, timestamp) {
      final expired = now.difference(timestamp) >
          PurchaseConstants.authenticationGracePeriod;
      if (expired) logger.d('🧹 만료된 인증 데이터 정리: $key');
      return expired;
    });

    // 만료된 백그라운드 구매 데이터 정리
    _backgroundPurchases.removeWhere((key, timestamp) {
      final expired = now.difference(timestamp) >
          PurchaseConstants.backgroundPurchaseWindow;
      if (expired) logger.d('🧹 만료된 백그라운드 구매 데이터 정리: $key');
      return expired;
    });

    // 만료된 구매 시도 데이터 정리
    _purchaseAttempts.removeWhere((key, timestamp) {
      final expired =
          now.difference(timestamp) > PurchaseConstants.purchaseBlockingPeriod;
      if (expired) logger.d('🧹 만료된 구매 시도 데이터 정리: $key');
      return expired;
    });

    // 🛡️ 만료된 사용자 상호작용 이력 정리
    _userInteractionHistory.removeWhere((userId, interactions) {
      interactions.removeWhere(
          (timestamp) => now.difference(timestamp) > _rapidInteractionWindow);
      final isEmpty = interactions.isEmpty;
      if (isEmpty) logger.d('🧹 만료된 사용자 상호작용 이력 정리: $userId');
      return isEmpty;
    });

    logger.d('🧹 만료된 구매 데이터 정리 완료');
  }

  // 🛡️ ===== 기존 투표 관련 메서드들 =====

  /// 캐시가 유효한지 확인
  bool _isCacheValid(String cacheKey) {
    if (!_voteCache.containsKey(cacheKey) ||
        !_voteCacheTimestamps.containsKey(cacheKey)) {
      return false;
    }

    final timestamp = _voteCacheTimestamps[cacheKey]!;
    final now = DateTime.now();

    return now.difference(timestamp) < _cacheExpiration;
  }

  /// 캐시 업데이트
  void _updateCache(String cacheKey, bool hasRequested) {
    _voteCache[cacheKey] = hasRequested;
    _voteCacheTimestamps[cacheKey] = DateTime.now();

    logger.d('캐시 업데이트: $cacheKey = $hasRequested');
  }

  /// 캐시 무효화 (신청 후 호출)
  void invalidateCache(int voteId, String userId) {
    final cacheKey = '${userId}_$voteId';
    _voteCache.remove(cacheKey);
    _voteCacheTimestamps.remove(cacheKey);

    logger.d('캐시 무효화: $cacheKey');
  }

  /// 전체 캐시 클리어
  void clearCache() {
    _voteCache.clear();
    _voteCacheTimestamps.clear();
    logger.d('전체 캐시 클리어');
  }
}

// 🛡️ ===== 구매 검증 결과 클래스들 =====

/// 구매 검증 결과
class PurchaseValidationResult {
  final bool allowed;
  final String? reason;
  final PurchaseDenyType? type;

  PurchaseValidationResult({
    required this.allowed,
    this.reason,
    this.type,
  });
}

/// 구매 차단 유형
enum PurchaseDenyType {
  concurrent, // 동시 구매
  authenticationInProgress, // 인증 진행 중
  backgroundPurchase, // 백그라운드 구매
  cooldown, // 쿨다운
  recentPurchase, // 최근 구매
  systemError, // 시스템 오류
  rapidInteraction, // 급속한 상호작용
}

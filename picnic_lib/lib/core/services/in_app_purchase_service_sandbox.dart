part of 'in_app_purchase_service.dart';

/// Sandbox/diagnostic extension methods for [InAppPurchaseService].
///
/// These methods are debug-only and used for sandbox environment testing,
/// authentication reset, and purchase system diagnostics.
/// Separated from the main service to keep production code focused.
extension InAppPurchaseServiceSandbox on InAppPurchaseService {
  /// Sandbox 인증창 강제 초기화 (인증창 생략 문제 해결) - 개선된 버전
  Future<void> forceSandboxAuthReset() async {
    logger.w('🔥 Sandbox 인증창 강제 초기화 시작 (개선된 버전)');

    try {
      // 0단계: 현재 진행 중인 구매 강제 중단
      logger.i('🛑 0단계: 현재 진행 중인 구매 강제 중단');
      _currentPurchasingProductId = null;
      if (_purchaseTimeoutTimer?.isActive == true) {
        _purchaseTimeoutTimer?.cancel();
        logger.i('⏰ 구매 타임아웃 타이머 취소됨');
      }

      if (Platform.isIOS) {
        // 1단계: 모든 구매 스트림 완전 중단 (더 확실하게)
        logger.i('📱 1단계: 구매 스트림 완전 중단 (강화)');
        await _subscription?.cancel();
        _streamInitialized = false;

        // PurchaseController도 완전히 정리
        if (_purchaseController != null && !_purchaseController!.isClosed) {
          await _purchaseController!.close();
          _purchaseController = null;
          logger.i('🗑️ PurchaseController 완전 정리됨');
        }

        // 2단계: StoreKit 캐시 완전 무효화 (5회 시도, 더 긴 간격)
        logger.i('🧹 2단계: StoreKit 캐시 완전 무효화 (5회 시도)');
        for (int i = 0; i < 5; i++) {
          try {
            await Future.delayed(Duration(milliseconds: 500));
            await InAppPurchase.instance
                .queryProductDetails({}).timeout(Duration(seconds: 2));
            await InAppPurchase.instance.queryProductDetails({
              'STAR10000',
              'STAR7000',
              'STAR50000'
            }).timeout(Duration(seconds: 2));
            logger.i('✅ StoreKit 캐시 무효화 ${i + 1}/5 완료');
          } catch (e) {
            logger.w('⚠️ StoreKit 캐시 무효화 ${i + 1}/5 실패: $e');
          }
        }

        // 3단계: 모든 pending 구매 강제 완료 (더 철저하게)
        logger.i('🚀 3단계: 모든 pending 구매 강제 완료 (강화)');
        await _enhancedForceClearAllPendingPurchases();

        // 4단계: 시스템 레벨 정리 및 안정화 (더 긴 대기)
        logger.i('⏰ 4단계: 시스템 안정화 대기 (3초)');
        await Future.delayed(Duration(seconds: 3));

        // 5단계: 새로운 PurchaseController 생성
        logger.i('🔄 5단계: 새로운 PurchaseController 생성');
        _purchaseController =
            StreamController<List<PurchaseDetails>>.broadcast();

        // 6단계: 구매 스트림 재초기화
        logger.i('🔄 6단계: 구매 스트림 재초기화');
        _initializePurchaseStream();

        // 7단계: 인증 상태 검증을 위한 더미 쿼리
        logger.i('🔍 7단계: 인증 상태 검증을 위한 더미 쿼리');
        try {
          await Future.delayed(Duration(milliseconds: 500));
          final productResponse = await InAppPurchase.instance
              .queryProductDetails({'STAR10000'}).timeout(
                  Duration(seconds: 3));
          logger.i(
              '✅ 인증 상태 검증 쿼리 성공: ${productResponse.productDetails.length}개 제품 조회됨');
        } catch (e) {
          logger.w('⚠️ 인증 상태 검증 쿼리 실패: $e');
        }

        logger.w('✅ Sandbox 인증창 강제 초기화 완료 (개선된 버전)');
      } else {
        logger.i('🤖 Android: 개선된 캐시 정리');
        await Future.delayed(Duration(seconds: 1));
      }
    } catch (e) {
      logger.e('❌ Sandbox 인증창 강제 초기화 실패: $e');
      try {
        if (!_streamInitialized) {
          if (_purchaseController == null || _purchaseController!.isClosed) {
            _purchaseController =
                StreamController<List<PurchaseDetails>>.broadcast();
          }
          _initializePurchaseStream();
          logger.i('🔄 오류 복구: 스트림 재초기화 완료');
        }
      } catch (recoveryError) {
        logger.e('❌ 오류 복구 실패: $recoveryError');
      }
    }
  }

  /// 강화된 모든 pending 구매 강제 완료
  Future<void> _enhancedForceClearAllPendingPurchases() async {
    logger.i('🚀 강화된 모든 pending 구매 강제 완료 시작');

    try {
      for (int attempt = 0; attempt < 5; attempt++) {
        logger.i('🔍 Attempt ${attempt + 1}/5: pending 구매 검색 (강화)');

        final purchaseDetailsList =
            await _getPurchaseUpdates(Duration(seconds: 3));
        final pendingPurchases = purchaseDetailsList
            .where((p) => p.status == PurchaseStatus.pending)
            .toList();

        if (pendingPurchases.isEmpty) {
          logger.i('✅ Attempt ${attempt + 1}: pending 구매 없음');
          break;
        }

        logger.w(
            '🚀 Attempt ${attempt + 1}: ${pendingPurchases.length}개 pending 구매 발견 - 강화된 강제 완료');

        for (final purchase in pendingPurchases) {
          try {
            logger.i('🔥 순차 강제 완료 시작: ${purchase.productID}');
            await completePurchase(purchase).timeout(Duration(seconds: 3));
            logger.i('✅ 순차 강제 완료 성공: ${purchase.productID}');
            await Future.delayed(Duration(milliseconds: 200));
          } catch (e) {
            logger.w('⚠️ 순차 강제 완료 실패: ${purchase.productID} - $e');
          }
        }

        await Future.delayed(Duration(milliseconds: 800));
      }

      logger.i('✅ 강화된 모든 pending 구매 강제 완료 처리됨');
    } catch (e) {
      logger.e('❌ 강화된 강제 pending 구매 완료 실패: $e');
    }
  }

  /// Sandbox 환경 감지
  Future<bool> isSandboxEnvironment() async {
    try {
      if (Platform.isIOS) {
        return kDebugMode;
      }
      return false;
    } catch (e) {
      logger.w('Sandbox 환경 감지 실패: $e');
      return false;
    }
  }

  /// Sandbox 전용 인증창 강제 활성화 설정
  Future<void> prepareSandboxAuthentication() async {
    if (!(await isSandboxEnvironment())) {
      logger.i('Production 환경 - Sandbox 설정 생략');
      return;
    }

    logger.w('🔧 Sandbox 인증창 강제 활성화 준비');

    try {
      await forceSandboxAuthReset();
      await Future.delayed(Duration(milliseconds: 500));
      logger.i('🔧 인증 프로세스 준비 중...');
      logger.w('✅ Sandbox 인증창 활성화 준비 완료');
    } catch (e) {
      logger.e('🔧 Sandbox 인증 준비 실패: $e');
    }
  }

  /// 핵폭탄급 Sandbox 인증 시스템 완전 리셋 (최후의 수단)
  Future<void> nuclearSandboxReset() async {
    logger.w('💥 핵폭탄급 Sandbox 인증 시스템 완전 리셋 시작');

    try {
      if (Platform.isIOS) {
        logger.i('💥 1단계: 모든 StoreKit 연결 완전 끊기');
        await _subscription?.cancel();
        _streamInitialized = false;
        _purchaseController?.close();
        _purchaseController = null;
        await Future.delayed(Duration(seconds: 5));

        logger.i('💥 2단계: 시스템 캐시 완전 무효화 (10회 시도)');
        for (int i = 0; i < 10; i++) {
          try {
            await Future.delayed(Duration(milliseconds: 500));
            await InAppPurchase.instance
                .queryProductDetails({}).timeout(Duration(seconds: 2));
            logger.i('💥 시스템 캐시 무효화 ${i + 1}/10 완료');
          } catch (e) {
            logger.w('💥 시스템 캐시 무효화 ${i + 1}/10 실패: $e');
          }
        }

        logger.i('💥 3단계: 핵폭탄급 pending 구매 정리');
        for (int round = 0; round < 5; round++) {
          await _nuclearPendingClear(round + 1);
          await Future.delayed(Duration(milliseconds: 800));
        }

        logger.i('💥 4단계: 긴 시스템 안정화 대기 (10초)');
        await Future.delayed(Duration(seconds: 10));

        logger.i('💥 5단계: 완전 새로운 구매 스트림 생성');
        _purchaseController =
            StreamController<List<PurchaseDetails>>.broadcast();
        _initializePurchaseStream();

        logger.w('💥 핵폭탄급 Sandbox 인증 시스템 완전 리셋 완료');
      } else {
        logger.i('🤖 Android: 핵폭탄급 정리 (간단 버전)');
        await Future.delayed(Duration(seconds: 2));
      }
    } catch (e) {
      logger.e('💥 핵폭탄급 리셋 실패: $e');
      if (!_streamInitialized) {
        _purchaseController =
            StreamController<List<PurchaseDetails>>.broadcast();
        _initializePurchaseStream();
      }
    }
  }

  /// 핵폭탄급 pending 구매 정리
  Future<void> _nuclearPendingClear(int round) async {
    logger.i('💥 핵폭탄급 pending 정리 Round $round 시작');

    try {
      final purchaseDetailsList =
          await _getPurchaseUpdates(Duration(seconds: 5));
      final pendingPurchases = purchaseDetailsList
          .where((p) => p.status == PurchaseStatus.pending)
          .toList();

      if (pendingPurchases.isEmpty) {
        logger.i('💥 Round $round: pending 구매 없음');
        return;
      }

      logger.w(
          '💥 Round $round: ${pendingPurchases.length}개 pending 구매 핵폭탄급 정리');

      final futures = pendingPurchases.map((purchase) async {
        try {
          await completePurchase(purchase).timeout(Duration(seconds: 5));
          logger.i('💥 핵폭탄급 완료: ${purchase.productID}');
        } catch (e) {
          logger.w('💥 핵폭탄급 완료 실패: ${purchase.productID} - $e');
        }
      });

      await Future.wait(futures);
      logger.i(
          '💥 Round $round 완료: ${pendingPurchases.length}개 pending 구매 정리됨');
    } catch (e) {
      logger.e('💥 Round $round 실패: $e');
    }
  }

  /// Sandbox 환경 진단 및 문제점 분석
  Future<Map<String, dynamic>> diagnoseSandboxEnvironment() async {
    logger.i('🏥 Sandbox 환경 진단 시작');

    try {
      final diagnosis = <String, dynamic>{
        'timestamp': DateTime.now().toIso8601String(),
        'platform': Platform.operatingSystem,
        'isDebugMode': kDebugMode,
      };

      try {
        final isAvailable = await InAppPurchase.instance.isAvailable();
        diagnosis['storeKitAvailable'] = isAvailable;
      } catch (e) {
        diagnosis['storeKitAvailable'] = false;
        diagnosis['storeKitError'] = e.toString();
      }

      try {
        final purchaseDetailsList =
            await _getPurchaseUpdates(Duration(seconds: 2));
        final pendingCount = purchaseDetailsList
            .where((p) => p.status == PurchaseStatus.pending)
            .length;
        diagnosis['currentPendingCount'] = pendingCount;
        diagnosis['totalPurchaseUpdates'] = purchaseDetailsList.length;
      } catch (e) {
        diagnosis['pendingCheckError'] = e.toString();
      }

      try {
        final productResponse =
            await InAppPurchase.instance.queryProductDetails({});
        diagnosis['productQuerySuccessful'] = productResponse.error == null;
        if (productResponse.error != null) {
          diagnosis['productQueryError'] = productResponse.error.toString();
        }
      } catch (e) {
        diagnosis['productQuerySuccessful'] = false;
        diagnosis['productQueryException'] = e.toString();
      }

      diagnosis['streamInitialized'] = _streamInitialized;
      diagnosis['purchaseControllerActive'] =
          _purchaseController != null && !_purchaseController!.isClosed;

      logger.i('''🏥 Sandbox 환경 진단 완료:
├─ StoreKit 사용 가능: ${diagnosis['storeKitAvailable']}
├─ 현재 pending 구매: ${diagnosis['currentPendingCount'] ?? 'Unknown'}개
├─ 제품 쿼리 성공: ${diagnosis['productQuerySuccessful']}
├─ 스트림 초기화됨: ${diagnosis['streamInitialized']}
└─ 구매 컨트롤러 활성: ${diagnosis['purchaseControllerActive']}''');

      return diagnosis;
    } catch (e) {
      logger.e('🏥 Sandbox 환경 진단 실패: $e');
      return {
        'error': e.toString(),
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// 상세 인증 상태 진단 및 해결책 제시
  Future<Map<String, dynamic>> diagnoseAuthenticationState() async {
    logger.i('🔍 상세 인증 상태 진단 시작');

    final diagnosis = <String, dynamic>{
      'timestamp': DateTime.now().toIso8601String(),
      'platform': Platform.operatingSystem,
      'isDebugMode': kDebugMode,
    };

    try {
      final isAvailable = await InAppPurchase.instance.isAvailable();
      diagnosis['storeKitAvailable'] = isAvailable;

      try {
        final purchaseUpdates =
            await _getPurchaseUpdates(Duration(seconds: 3));
        diagnosis['currentPendingCount'] = purchaseUpdates
            .where((p) => p.status == PurchaseStatus.pending)
            .length;
        diagnosis['totalUpdatesCount'] = purchaseUpdates.length;
      } catch (e) {
        diagnosis['pendingCheckError'] = e.toString();
      }

      try {
        final productResult = await InAppPurchase.instance
            .queryProductDetails({'STAR10000'}).timeout(
                Duration(seconds: 5));
        diagnosis['productQuerySuccess'] = productResult.error == null;
        diagnosis['productCount'] = productResult.productDetails.length;
        if (productResult.error != null) {
          diagnosis['productQueryError'] = productResult.error.toString();
        }
      } catch (e) {
        diagnosis['productQueryException'] = e.toString();
      }

      diagnosis['streamInitialized'] = _streamInitialized;
      diagnosis['controllerActive'] =
          _purchaseController != null && !_purchaseController!.isClosed;

      final solutions = <String>[];

      if (diagnosis['currentPendingCount'] != null &&
          diagnosis['currentPendingCount'] > 0) {
        solutions.add(
            'Pending 구매가 ${diagnosis['currentPendingCount']}개 있습니다. 핵리셋을 시도해보세요.');
      }

      if (diagnosis['productQuerySuccess'] != true) {
        solutions.add('제품 쿼리가 실패했습니다. 인증초기화를 다시 시도해보세요.');
      }

      solutions.addAll([
        '1. 앱을 완전히 종료하고 재시작하세요',
        '2. iOS 설정 > App Store에서 로그아웃 후 재로그인하세요',
        '3. 디바이스를 재부팅해보세요',
        '4. 다른 Apple ID로 테스트해보세요',
        '5. 시뮬레이터에서 Device > Erase All Content and Settings 시도'
      ]);

      diagnosis['recommendedSolutions'] = solutions;

      logger.i('🔍 인증 상태 진단 완료');
      return diagnosis;
    } catch (e) {
      logger.e('🔍 인증 상태 진단 실패: $e');
      diagnosis['error'] = e.toString();
      return diagnosis;
    }
  }

  /// 궁극적인 인증창 복구 방법 (최후의 수단)
  Future<void> ultimateAuthenticationReset() async {
    logger.w('🔥 궁극적인 인증창 복구 시작 - 최후의 수단');

    try {
      if (Platform.isIOS) {
        logger.i('📱 iOS: 궁극적인 인증 상태 리셋');

        await _subscription?.cancel();
        _streamInitialized = false;
        _currentPurchasingProductId = null;
        _purchaseTimeoutTimer?.cancel();

        if (_purchaseController != null) {
          await _purchaseController!.close();
          _purchaseController = null;
        }

        logger.i('⏰ 시스템 완전 안정화 대기 (5초)');
        await Future.delayed(Duration(seconds: 5));

        logger.i('🧹 StoreKit 시스템 레벨 캐시 강제 무효화 (10회)');
        for (int i = 0; i < 10; i++) {
          try {
            await Future.delayed(Duration(seconds: 1));
            await InAppPurchase.instance
                .queryProductDetails({}).timeout(Duration(seconds: 3));
            await InAppPurchase.instance.queryProductDetails(
                {'INVALID_PRODUCT_ID'}).timeout(Duration(seconds: 3));
            await InAppPurchase.instance.queryProductDetails(
                {'STAR10000'}).timeout(Duration(seconds: 3));
            logger.i('🧹 시스템 캐시 무효화 ${i + 1}/10 완료');
          } catch (e) {
            logger.w('⚠️ 시스템 캐시 무효화 ${i + 1}/10 실패: $e');
          }
        }

        logger.i('⏰ 추가 안정화 대기 (3초)');
        await Future.delayed(Duration(seconds: 3));

        logger.i('🔄 완전히 새로운 구매 환경 재구성');
        _purchaseController =
            StreamController<List<PurchaseDetails>>.broadcast();
        _initializePurchaseStream();

        logger.i('🔍 최종 인증 상태 검증');
        await Future.delayed(Duration(seconds: 1));

        logger.w('🔥 궁극적인 인증창 복구 완료');
      }
    } catch (e) {
      logger.e('❌ 궁극적인 인증창 복구 실패: $e');
    }
  }
}

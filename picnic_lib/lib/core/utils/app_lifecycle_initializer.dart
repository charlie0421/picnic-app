import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/presentation/providers/app_initialization_provider.dart';

/// 앱 생명주기 관리 및 초기화를 위한 유틸리티 클래스
///
/// 두 앱(picnic_app, ttja_app)에서 공통으로 사용되는 초기화 및 생명주기 관련 로직을 통합합니다.
/// AppLifecycleInitializer는 StatefulWidget의 initState, dispose 등의 메서드에서
/// 호출되는 로직을 추상화하여 코드 중복을 제거합니다.
///
/// 기능:
/// - 앱 초기화 및 리스너 설정 (setupAppInitializers)
/// - 리스너 정리 및 메모리 누수 방지 (disposeAppListeners)
/// - 라우트 설정 (setupAppRoutes)
/// - 초기화 상태 관리 (markAppInitialized)
/// - 딥링크 처리 (handleBranchUri)
class AppLifecycleInitializer {
  /// 앱 URI 스키마 (Constants 클래스에 없으므로 여기에 정의)
  static const String appUriScheme = 'picnic';

  /// 앱 초기화 로직 설정
  ///
  /// [ref] Riverpod WidgetRef - Provider 접근에 사용
  /// [context] BuildContext - Widget 컨텍스트
  static void setupAppInitializers(WidgetRef ref, BuildContext context) {
    logger.i('App 초기화 로직 설정 시작');
    try {
      // 앱 초기화 관련 Provider 설정
      ref.read(appInitializationProvider.notifier).updateState(
            isInitialized: false,
            hasNetwork: true,
            isBanned: false,
            updateInfo: null,
          );
      logger.i('App 초기화 Provider 설정 완료');
    } catch (e, stackTrace) {
      logger.e('App 초기화 로직 설정 중 오류 발생', error: e, stackTrace: stackTrace);
    }
  }

  /// 앱 리스너 정리 (dispose 시 호출)
  ///
  /// [authSubscription] Supabase 인증 이벤트 구독 객체
  /// [appLinksSubscription] 앱 딥링크 이벤트 구독 객체
  static void disposeAppListeners(StreamSubscription? authSubscription,
      StreamSubscription? appLinksSubscription) {
    logger.i('App 리스너 정리');
    try {
      // 인증 이벤트 구독 해제
      authSubscription?.cancel();

      // 앱 링크 이벤트 구독 해제
      appLinksSubscription?.cancel();

      logger.i('App 리스너 정리 완료');
    } catch (e) {
      logger.e('App 리스너 정리 중 오류 발생', error: e);
    }
  }

  /// 앱의 라우트 정보 설정
  ///
  /// [ref] Riverpod WidgetRef - Provider 접근에 사용
  /// [routes] 앱에서 사용되는 모든 라우트 맵
  static void setupAppRoutes(WidgetRef ref, Map<String, WidgetBuilder> routes) {
    logger.i('App 라우팅 설정: ${routes.length}개 경로 등록');
    try {
      // 앱 라우팅 관련 설정
      // 필요한 경우 Provider를 통해 라우팅 상태 관리
    } catch (e) {
      logger.e('App 라우팅 설정 중 오류 발생', error: e);
    }
  }

  /// 앱 초기화 완료 표시
  ///
  /// [ref] Riverpod WidgetRef - Provider 접근에 사용
  static void markAppInitialized(WidgetRef ref) {
    logger.i('App 초기화 완료 표시');
    try {
      // 앱 초기화 상태 업데이트
      ref.read(appInitializationProvider.notifier).updateState(
            isInitialized: true,
          );
      logger.i('App 초기화 완료 표시 업데이트됨');
    } catch (e) {
      logger.e('App 초기화 완료 표시 중 오류 발생', error: e);
    }
  }

  /// Branch SDK 딥링크로 전달된 URI를 처리
  ///
  /// [uri] 처리할 URI 객체
  /// [ref] Riverpod WidgetRef - Provider 접근에 사용
  static void handleBranchUri(Uri? uri, WidgetRef ref) {
    if (uri == null) return;

    logger.i('Branch URI 처리: $uri');

    // URI 스키마 검사
    if (uri.scheme == appUriScheme) {
      // 딥링크 처리 로직은 각 앱에서 구현
      logger.i('딥링크 처리 필요: ${uri.toString()}');
    } else {
      logger.i('지원되지 않는 URI 스키마: ${uri.scheme}');
    }
  }
}

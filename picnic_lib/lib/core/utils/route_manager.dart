import 'package:flutter/material.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/presentation/pages/oauth_callback_page.dart';
import 'package:picnic_lib/presentation/screens/pic/pic_camera_screen.dart';
import 'package:picnic_lib/presentation/screens/privacy.dart';
import 'package:picnic_lib/presentation/screens/purchase.dart';
import 'package:picnic_lib/presentation/screens/signup/signup_screen.dart';
import 'package:picnic_lib/presentation/screens/terms.dart';

/// 두 앱의 공통 라우트와 라우팅 로직을 관리하는 유틸리티 클래스
///
/// picnic_app과 ttja_app의 라우트 정의 및 관리 코드 중복을 줄이고
/// 일관된 라우팅 메커니즘을 제공합니다.
class RouteManager {
  /// 공통 라우트 정의 및 반환
  ///
  /// 두 앱에서 공통으로 사용되는 라우트 맵을 생성합니다.
  static Map<String, WidgetBuilder> getCommonRoutes() {
    return {
      // 로그인 및 인증 관련 화면
      SignUpScreen.routeName: (context) => const SignUpScreen(),

      // 카메라 화면
      '/pic-camera': (context) => const PicCameraScreen(),

      // 약관 및 개인정보 화면
      TermsScreen.routeName: (context) => const TermsScreen(),
      PrivacyScreen.routeName: (context) => const PrivacyScreen(),

      // 결제 화면
      PurchaseScreen.routeName: (context) => const PurchaseScreen(),

      // OAuth 콜백 페이지
      OAuthCallbackPage.routeName: (context) {
        // URL에서 쿼리 파라미터 추출
        final uri = ModalRoute.of(context)?.settings.arguments as Uri?;
        return OAuthCallbackPage(
          callbackUri: uri ?? Uri.parse('picnic://auth/callback'),
        );
      },
    };
  }

  /// 앱별 라우트와 공통 라우트 병합
  ///
  /// [appSpecificRoutes] 앱별 고유 라우트 맵
  ///
  /// 공통 라우트와 앱별 고유 라우트를 병합한 전체 라우트 맵을 반환합니다.
  /// 동일한 경로에 대해 앱별 라우트가 우선합니다.
  static Map<String, WidgetBuilder> mergeRoutes(
      Map<String, WidgetBuilder> appSpecificRoutes) {
    final commonRoutes = getCommonRoutes();
    final mergedRoutes = Map<String, WidgetBuilder>.from(commonRoutes);

    // 앱별 라우트 추가 (동일 경로가 있으면 앱별 라우트가 우선)
    mergedRoutes.addAll(appSpecificRoutes);

    logger.i(
        '라우트 병합 완료: 공통=${commonRoutes.length}개, 앱별=${appSpecificRoutes.length}개, 최종=${mergedRoutes.length}개');
    return mergedRoutes;
  }

  /// 지정된 라우트로 네비게이션 수행
  ///
  /// [context] 빌드 컨텍스트
  /// [routeName] 이동할 라우트 이름
  /// [arguments] 라우트에 전달할 인자 (옵션)
  ///
  /// 지정된 라우트로 이동하고 성공 여부를 반환합니다.
  static bool navigateTo(BuildContext context, String routeName,
      {Object? arguments}) {
    try {
      Navigator.of(context).pushNamed(routeName, arguments: arguments);
      return true;
    } catch (e) {
      logger.e('라우트 이동 중 오류: $routeName', error: e);
      return false;
    }
  }

  /// 현재 화면을 대체하는 네비게이션 수행
  ///
  /// [context] 빌드 컨텍스트
  /// [routeName] 이동할 라우트 이름
  /// [arguments] 라우트에 전달할 인자 (옵션)
  ///
  /// 현재 화면을 지정된 라우트로 대체하고 성공 여부를 반환합니다.
  static bool replaceWith(BuildContext context, String routeName,
      {Object? arguments}) {
    try {
      Navigator.of(context)
          .pushReplacementNamed(routeName, arguments: arguments);
      return true;
    } catch (e) {
      logger.e('라우트 대체 중 오류: $routeName', error: e);
      return false;
    }
  }

  /// 딥링크 URI 분석 및 해당 라우트 반환
  ///
  /// [uri] 분석할 URI
  ///
  /// URI를 분석하여 해당하는 라우트 정보를 반환합니다.
  /// 지원되지 않는 URI인 경우 null을 반환합니다.
  static String? resolveDeepLink(Uri uri) {
    // 딥링크 스키마: picnic://
    if (uri.scheme != 'picnic') {
      return null;
    }

    // 앱 내 페이지 매핑 처리
    switch (uri.host) {
      case 'profile':
        return '/profile/${uri.pathSegments.isNotEmpty ? uri.pathSegments.first : ""}';
      case 'post':
        return '/post/${uri.pathSegments.isNotEmpty ? uri.pathSegments.first : ""}';
      case 'terms':
        return TermsScreen.routeName;
      case 'privacy':
        return PrivacyScreen.routeName;
      default:
        return null;
    }
  }
}

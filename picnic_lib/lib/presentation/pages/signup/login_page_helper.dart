import 'package:flutter/foundation.dart';

/// Post-login navigation action determined by user profile state.
enum PostLoginAction {
  /// User profile not found - navigate to agreement/signup flow.
  navigateToAgreement,

  /// User account was deleted - show withdrawal error dialog.
  showDeletedAccountDialog,

  /// User has no agreement record - navigate to agreement flow.
  navigateToAgreementNoRecord,

  /// User is fully registered - navigate to main/my page.
  navigateToMyPage,
}

/// Extracted pure logic from [LoginPage] to enable unit testing.
///
/// All methods are static and pure - they have no Flutter/widget dependencies
/// and can be tested without a widget test harness.
class LoginPageHelper {
  const LoginPageHelper._();

  /// Returns the candidate and fallback asset paths for a swiper login image.
  ///
  /// [languageCode] - current locale language code (e.g. 'ko', 'en').
  /// [index] - zero-based swiper page index.
  ///
  /// Returns a record with (candidate, fallback) paths.
  static ({String candidate, String fallback}) swiperImageAssetPaths({
    required String languageCode,
    required int index,
  }) {
    final oneBasedIndex = index + 1;
    return (
      candidate: 'assets/login/${languageCode}_$oneBasedIndex.png',
      fallback: 'assets/login/en_$oneBasedIndex.png',
    );
  }

  /// Determines what navigation action to take after a successful login,
  /// based on the user profile state.
  ///
  /// [profileExists] - whether a user profile was returned from the backend.
  /// [isDeleted] - whether the profile has a non-null deletedAt.
  /// [hasAgreement] - whether the profile has a non-null userAgreement.
  static PostLoginAction determinePostLoginAction({
    required bool profileExists,
    required bool isDeleted,
    required bool hasAgreement,
  }) {
    if (!profileExists) {
      return PostLoginAction.navigateToAgreement;
    }
    if (isDeleted) {
      return PostLoginAction.showDeletedAccountDialog;
    }
    if (!hasAgreement) {
      return PostLoginAction.navigateToAgreementNoRecord;
    }
    return PostLoginAction.navigateToMyPage;
  }

  /// Builds the OAuth redirect URL for web-based login.
  ///
  /// [webDomain] - the base web domain (e.g. 'https://example.com').
  /// [callbackPath] - the callback path (defaults to '/auth/callback').
  static String oauthRedirectUrl({
    required String webDomain,
    String callbackPath = '/auth/callback',
  }) {
    return '$webDomain$callbackPath';
  }

  /// Resolves a language code to its display name using the provided map.
  ///
  /// Returns `null` if [languageCode] is not found in [languageMap].
  @visibleForTesting
  static String? resolveLanguageDisplayName({
    required String languageCode,
    required Map<String, String> languageMap,
  }) {
    return languageMap[languageCode];
  }

  /// Determines whether the Apple login option should be shown.
  ///
  /// Apple login is only available on iOS native.
  static bool shouldShowAppleLogin({
    required bool isIOS,
    required bool isWeb,
  }) {
    return isIOS;
  }

  /// Validates that a login provider string is one of the supported providers.
  @visibleForTesting
  static bool isValidProvider(String? provider) {
    if (provider == null) return false;
    const validProviders = {'apple', 'google', 'kakao'};
    return validProviders.contains(provider);
  }

  /// Returns the list of supported login provider identifiers.
  @visibleForTesting
  static List<String> supportedProviders({required bool isIOS}) {
    return [
      if (isIOS) 'apple',
      'google',
      'kakao',
    ];
  }
}

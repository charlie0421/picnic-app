import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/pages/signup/login_page_helper.dart';

void main() {
  group('LoginPageHelper.swiperImageAssetPaths', () {
    test('returns correct candidate and fallback for index 0 with ko', () {
      final result = LoginPageHelper.swiperImageAssetPaths(
        languageCode: 'ko',
        index: 0,
      );
      expect(result.candidate, 'assets/login/ko_1.png');
      expect(result.fallback, 'assets/login/en_1.png');
    });

    test('returns correct candidate and fallback for index 1 with ko', () {
      final result = LoginPageHelper.swiperImageAssetPaths(
        languageCode: 'ko',
        index: 1,
      );
      expect(result.candidate, 'assets/login/ko_2.png');
      expect(result.fallback, 'assets/login/en_2.png');
    });

    test('returns correct paths for English locale', () {
      final result = LoginPageHelper.swiperImageAssetPaths(
        languageCode: 'en',
        index: 0,
      );
      expect(result.candidate, 'assets/login/en_1.png');
      expect(result.fallback, 'assets/login/en_1.png');
    });

    test('returns correct paths for Japanese locale', () {
      final result = LoginPageHelper.swiperImageAssetPaths(
        languageCode: 'ja',
        index: 1,
      );
      expect(result.candidate, 'assets/login/ja_2.png');
      expect(result.fallback, 'assets/login/en_2.png');
    });

    test('handles zh_CN locale correctly', () {
      final result = LoginPageHelper.swiperImageAssetPaths(
        languageCode: 'zh_CN',
        index: 0,
      );
      expect(result.candidate, 'assets/login/zh_CN_1.png');
      expect(result.fallback, 'assets/login/en_1.png');
    });

    test('fallback always uses en prefix', () {
      for (final lang in ['ko', 'ja', 'es', 'id', 'th', 'vi']) {
        final result = LoginPageHelper.swiperImageAssetPaths(
          languageCode: lang,
          index: 0,
        );
        expect(result.fallback, startsWith('assets/login/en_'));
      }
    });
  });

  group('LoginPageHelper.determinePostLoginAction', () {
    test('returns navigateToAgreement when profile does not exist', () {
      final action = LoginPageHelper.determinePostLoginAction(
        profileExists: false,
        isDeleted: false,
        hasAgreement: false,
      );
      expect(action, PostLoginAction.navigateToAgreement);
    });

    test('returns navigateToAgreement when profile does not exist regardless of other flags', () {
      final action = LoginPageHelper.determinePostLoginAction(
        profileExists: false,
        isDeleted: true,
        hasAgreement: true,
      );
      expect(action, PostLoginAction.navigateToAgreement);
    });

    test('returns showDeletedAccountDialog when profile is deleted', () {
      final action = LoginPageHelper.determinePostLoginAction(
        profileExists: true,
        isDeleted: true,
        hasAgreement: false,
      );
      expect(action, PostLoginAction.showDeletedAccountDialog);
    });

    test('returns showDeletedAccountDialog when deleted even with agreement', () {
      final action = LoginPageHelper.determinePostLoginAction(
        profileExists: true,
        isDeleted: true,
        hasAgreement: true,
      );
      expect(action, PostLoginAction.showDeletedAccountDialog);
    });

    test('returns navigateToAgreementNoRecord when no agreement', () {
      final action = LoginPageHelper.determinePostLoginAction(
        profileExists: true,
        isDeleted: false,
        hasAgreement: false,
      );
      expect(action, PostLoginAction.navigateToAgreementNoRecord);
    });

    test('returns navigateToMyPage when profile exists with agreement', () {
      final action = LoginPageHelper.determinePostLoginAction(
        profileExists: true,
        isDeleted: false,
        hasAgreement: true,
      );
      expect(action, PostLoginAction.navigateToMyPage);
    });
  });

  group('LoginPageHelper.oauthRedirectUrl', () {
    test('builds correct redirect URL with default callback path', () {
      final url = LoginPageHelper.oauthRedirectUrl(
        webDomain: 'https://picnic.com',
      );
      expect(url, 'https://picnic.com/auth/callback');
    });

    test('builds correct redirect URL with custom callback path', () {
      final url = LoginPageHelper.oauthRedirectUrl(
        webDomain: 'https://picnic.com',
        callbackPath: '/custom/callback',
      );
      expect(url, 'https://picnic.com/custom/callback');
    });

    test('handles domain without trailing slash', () {
      final url = LoginPageHelper.oauthRedirectUrl(
        webDomain: 'https://example.com',
      );
      expect(url, 'https://example.com/auth/callback');
      // Verify no double slashes in the path portion (after scheme)
      final pathPortion = url.replaceFirst(RegExp(r'^https?://'), '');
      expect(pathPortion, isNot(contains('//')));
    });

    test('handles localhost domain', () {
      final url = LoginPageHelper.oauthRedirectUrl(
        webDomain: 'http://localhost:3000',
      );
      expect(url, 'http://localhost:3000/auth/callback');
    });
  });

  group('LoginPageHelper.resolveLanguageDisplayName', () {
    final testLanguageMap = {
      'ko': '한국어',
      'en': 'English',
      'ja': '日本語',
      'es': 'Español',
    };

    test('returns correct display name for known language', () {
      expect(
        LoginPageHelper.resolveLanguageDisplayName(
          languageCode: 'ko',
          languageMap: testLanguageMap,
        ),
        '한국어',
      );
    });

    test('returns English for en code', () {
      expect(
        LoginPageHelper.resolveLanguageDisplayName(
          languageCode: 'en',
          languageMap: testLanguageMap,
        ),
        'English',
      );
    });

    test('returns null for unknown language code', () {
      expect(
        LoginPageHelper.resolveLanguageDisplayName(
          languageCode: 'fr',
          languageMap: testLanguageMap,
        ),
        isNull,
      );
    });

    test('returns null for empty language code', () {
      expect(
        LoginPageHelper.resolveLanguageDisplayName(
          languageCode: '',
          languageMap: testLanguageMap,
        ),
        isNull,
      );
    });

    test('returns null when map is empty', () {
      expect(
        LoginPageHelper.resolveLanguageDisplayName(
          languageCode: 'ko',
          languageMap: {},
        ),
        isNull,
      );
    });
  });

  group('LoginPageHelper.shouldShowAppleLogin', () {
    test('returns true when isIOS is true', () {
      expect(
        LoginPageHelper.shouldShowAppleLogin(isIOS: true, isWeb: false),
        isTrue,
      );
    });

    test('returns false when isIOS is false and not web', () {
      expect(
        LoginPageHelper.shouldShowAppleLogin(isIOS: false, isWeb: false),
        isFalse,
      );
    });

    test('returns false when on web but not iOS', () {
      expect(
        LoginPageHelper.shouldShowAppleLogin(isIOS: false, isWeb: true),
        isFalse,
      );
    });

    test('returns true when on iOS regardless of web', () {
      expect(
        LoginPageHelper.shouldShowAppleLogin(isIOS: true, isWeb: true),
        isTrue,
      );
    });
  });

  group('LoginPageHelper.isValidProvider', () {
    test('returns true for apple', () {
      expect(LoginPageHelper.isValidProvider('apple'), isTrue);
    });

    test('returns true for google', () {
      expect(LoginPageHelper.isValidProvider('google'), isTrue);
    });

    test('returns true for kakao', () {
      expect(LoginPageHelper.isValidProvider('kakao'), isTrue);
    });

    test('returns false for null', () {
      expect(LoginPageHelper.isValidProvider(null), isFalse);
    });

    test('returns false for empty string', () {
      expect(LoginPageHelper.isValidProvider(''), isFalse);
    });

    test('returns false for unknown provider', () {
      expect(LoginPageHelper.isValidProvider('facebook'), isFalse);
    });

    test('is case sensitive', () {
      expect(LoginPageHelper.isValidProvider('Apple'), isFalse);
      expect(LoginPageHelper.isValidProvider('GOOGLE'), isFalse);
    });
  });

  group('LoginPageHelper.supportedProviders', () {
    test('includes apple when isIOS is true', () {
      final providers = LoginPageHelper.supportedProviders(isIOS: true);
      expect(providers, contains('apple'));
      expect(providers, contains('google'));
      expect(providers, contains('kakao'));
      expect(providers.length, 3);
    });

    test('excludes apple when isIOS is false', () {
      final providers = LoginPageHelper.supportedProviders(isIOS: false);
      expect(providers, isNot(contains('apple')));
      expect(providers, contains('google'));
      expect(providers, contains('kakao'));
      expect(providers.length, 2);
    });

    test('google and kakao are always present', () {
      for (final isIOS in [true, false]) {
        final providers = LoginPageHelper.supportedProviders(isIOS: isIOS);
        expect(providers, contains('google'));
        expect(providers, contains('kakao'));
      }
    });

    test('order is apple first when present, then google, then kakao', () {
      final providers = LoginPageHelper.supportedProviders(isIOS: true);
      expect(providers.indexOf('apple'), lessThan(providers.indexOf('google')));
      expect(providers.indexOf('google'), lessThan(providers.indexOf('kakao')));
    });
  });

  group('PostLoginAction enum', () {
    test('has exactly 4 values', () {
      expect(PostLoginAction.values.length, 4);
    });

    test('contains all expected values', () {
      expect(PostLoginAction.values, contains(PostLoginAction.navigateToAgreement));
      expect(PostLoginAction.values, contains(PostLoginAction.showDeletedAccountDialog));
      expect(PostLoginAction.values, contains(PostLoginAction.navigateToAgreementNoRecord));
      expect(PostLoginAction.values, contains(PostLoginAction.navigateToMyPage));
    });
  });
}

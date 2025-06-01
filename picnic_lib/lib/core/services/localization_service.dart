import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// Localization service for managing app translations and locale
class LocalizationService {
  static final LocalizationService _instance = LocalizationService._internal();
  factory LocalizationService() => _instance;
  LocalizationService._internal();

  static const String _localeKey = 'app_locale';
  static const List<Locale> _supportedLocales = [
    Locale('ko', 'KR'), // Korean
    Locale('en', 'US'), // English
    Locale('ja', 'JP'), // Japanese
    Locale('zh', 'CN'), // Chinese Simplified
    Locale('zh', 'TW'), // Chinese Traditional
  ];

  Locale _currentLocale = const Locale('ko', 'KR');
  final Map<String, Map<String, String>> _translations = {};
  bool _isInitialized = false;

  /// Get current locale
  Locale get currentLocale => _currentLocale;

  /// Get supported locales
  List<Locale> get supportedLocales => _supportedLocales;

  /// Check if locale is supported
  bool isLocaleSupported(Locale locale) {
    return _supportedLocales.any((supportedLocale) =>
        supportedLocale.languageCode == locale.languageCode &&
        supportedLocale.countryCode == locale.countryCode);
  }

  /// Initialize localization service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await _loadSavedLocale();
      await _loadTranslations();
      _isInitialized = true;
      debugPrint('LocalizationService initialized with locale: $_currentLocale');
    } catch (e) {
      debugPrint('Failed to initialize LocalizationService: $e');
      rethrow;
    }
  }

  /// Load saved locale from preferences
  Future<void> _loadSavedLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLocaleCode = prefs.getString(_localeKey);
      
      if (savedLocaleCode != null) {
        final parts = savedLocaleCode.split('_');
        if (parts.length == 2) {
          final locale = Locale(parts[0], parts[1]);
          if (isLocaleSupported(locale)) {
            _currentLocale = locale;
            return;
          }
        }
      }
      
      // Fallback to system locale if supported
      final systemLocale = PlatformDispatcher.instance.locale;
      if (isLocaleSupported(systemLocale)) {
        _currentLocale = systemLocale;
      }
    } catch (e) {
      debugPrint('Failed to load saved locale: $e');
    }
  }

  /// Change app locale
  Future<void> changeLocale(Locale locale) async {
    if (!isLocaleSupported(locale)) {
      throw ArgumentError('Locale $locale is not supported');
    }

    try {
      _currentLocale = locale;
      
      // Save to preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localeKey, '${locale.languageCode}_${locale.countryCode}');
      
      debugPrint('Locale changed to: $locale');
    } catch (e) {
      debugPrint('Failed to change locale: $e');
      rethrow;
    }
  }

  /// Load translations for all supported locales
  Future<void> _loadTranslations() async {
    for (final locale in _supportedLocales) {
      final localeKey = '${locale.languageCode}_${locale.countryCode}';
      _translations[localeKey] = _getTranslationsForLocale(locale);
    }
    debugPrint('Loaded translations for ${_translations.length} locales');
  }

  /// Get translations for specific locale
  Map<String, String> _getTranslationsForLocale(Locale locale) {
    final localeKey = '${locale.languageCode}_${locale.countryCode}';
    
    switch (localeKey) {
      case 'ko_KR':
        return _koreanTranslations;
      case 'en_US':
        return _englishTranslations;
      case 'ja_JP':
        return _japaneseTranslations;
      case 'zh_CN':
        return _chineseSimplifiedTranslations;
      case 'zh_TW':
        return _chineseTraditionalTranslations;
      default:
        return _englishTranslations; // Fallback to English
    }
  }

  /// Translate text key
  String translate(String key, {Locale? locale}) {
    final targetLocale = locale ?? _currentLocale;
    final localeKey = '${targetLocale.languageCode}_${targetLocale.countryCode}';
    
    final translations = _translations[localeKey] ?? _translations['en_US']!;
    final translation = translations[key];
    
    if (translation == null) {
      debugPrint('Translation not found for key: $key (locale: $localeKey)');
      return key; // Return key if translation not found
    }
    
    return translation;
  }

  /// Translate with parameters
  String translateWithParams(String key, Map<String, dynamic> params, {Locale? locale}) {
    String translation = translate(key, locale: locale);
    
    params.forEach((paramKey, value) {
      translation = translation.replaceAll('{$paramKey}', value.toString());
    });
    
    return translation;
  }

  /// Format number according to locale
  String formatNumber(num number, {Locale? locale}) {
    final targetLocale = locale ?? _currentLocale;
    final formatter = NumberFormat.decimalPattern(targetLocale.toString());
    return formatter.format(number);
  }

  /// Format currency according to locale
  String formatCurrency(num amount, {String? currencyCode, Locale? locale}) {
    final targetLocale = locale ?? _currentLocale;
    final currency = currencyCode ?? _getCurrencyForLocale(targetLocale);
    final formatter = NumberFormat.currency(
      locale: targetLocale.toString(),
      symbol: _getCurrencySymbol(currency),
    );
    return formatter.format(amount);
  }

  /// Format date according to locale
  String formatDate(DateTime date, {String? pattern, Locale? locale}) {
    final targetLocale = locale ?? _currentLocale;
    final formatter = DateFormat(pattern ?? 'yyyy-MM-dd', targetLocale.toString());
    return formatter.format(date);
  }

  /// Format time according to locale
  String formatTime(DateTime time, {Locale? locale}) {
    final targetLocale = locale ?? _currentLocale;
    final formatter = DateFormat.Hm(targetLocale.toString());
    return formatter.format(time);
  }

  /// Get currency for locale
  String _getCurrencyForLocale(Locale locale) {
    switch (locale.countryCode) {
      case 'KR':
        return 'KRW';
      case 'US':
        return 'USD';
      case 'JP':
        return 'JPY';
      case 'CN':
      case 'TW':
        return 'CNY';
      default:
        return 'USD';
    }
  }

  /// Get currency symbol
  String _getCurrencySymbol(String currencyCode) {
    switch (currencyCode) {
      case 'KRW':
        return '₩';
      case 'USD':
        return '\$';
      case 'JPY':
        return '¥';
      case 'CNY':
        return '¥';
      default:
        return '\$';
    }
  }

  /// Get locale-specific configurations
  LocaleConfig getLocaleConfig({Locale? locale}) {
    final targetLocale = locale ?? _currentLocale;
    
    switch (targetLocale.languageCode) {
      case 'ko':
        return const LocaleConfig(
          isRTL: false,
          dateFormat: 'yyyy년 MM월 dd일',
          timeFormat: 'HH:mm',
          firstDayOfWeek: 1, // Monday
        );
      case 'ja':
        return const LocaleConfig(
          isRTL: false,
          dateFormat: 'yyyy年MM月dd日',
          timeFormat: 'HH:mm',
          firstDayOfWeek: 1,
        );
      case 'zh':
        return const LocaleConfig(
          isRTL: false,
          dateFormat: 'yyyy年MM月dd日',
          timeFormat: 'HH:mm',
          firstDayOfWeek: 1,
        );
      case 'en':
      default:
        return const LocaleConfig(
          isRTL: false,
          dateFormat: 'MMM dd, yyyy',
          timeFormat: 'HH:mm',
          firstDayOfWeek: 0, // Sunday
        );
    }
  }

  /// Get localized asset path
  String getLocalizedAssetPath(String assetPath, {Locale? locale}) {
    final targetLocale = locale ?? _currentLocale;
    final languageCode = targetLocale.languageCode;
    
    // Try language-specific asset first
    final localizedPath = assetPath.replaceAll('.', '_$languageCode.');
    
    // For assets that might not have localized versions, return original path
    return localizedPath;
  }

  /// Check if current locale requires special handling
  bool get isAsianLocale {
    return ['ko', 'ja', 'zh'].contains(_currentLocale.languageCode);
  }

  bool get isRTL {
    return getLocaleConfig().isRTL;
  }

  /// Get direction based on locale
  TextDirection get textDirection {
    return isRTL ? TextDirection.rtl : TextDirection.ltr;
  }
}

/// Korean translations
const Map<String, String> _koreanTranslations = {
  'app_name': '피크닉',
  'welcome': '환영합니다',
  'login': '로그인',
  'logout': '로그아웃',
  'signup': '회원가입',
  'email': '이메일',
  'password': '비밀번호',
  'confirm_password': '비밀번호 확인',
  'forgot_password': '비밀번호를 잊으셨나요?',
  'home': '홈',
  'profile': '프로필',
  'settings': '설정',
  'notifications': '알림',
  'messages': '메시지',
  'search': '검색',
  'cancel': '취소',
  'save': '저장',
  'delete': '삭제',
  'edit': '편집',
  'loading': '로딩 중...',
  'error': '오류',
  'success': '성공',
  'retry': '다시 시도',
  'yes': '예',
  'no': '아니오',
  'ok': '확인',
  'language': '언어',
  'theme': '테마',
  'dark_mode': '다크 모드',
  'light_mode': '라이트 모드',
  'vote': '투표',
  'comment': '댓글',
  'share': '공유',
  'like': '좋아요',
  'follow': '팔로우',
  'unfollow': '언팔로우',
  'gallery': '갤러리',
  'photo': '사진',
  'video': '동영상',
  'upload': '업로드',
  'download': '다운로드',
};

/// English translations
const Map<String, String> _englishTranslations = {
  'app_name': 'Picnic',
  'welcome': 'Welcome',
  'login': 'Login',
  'logout': 'Logout',
  'signup': 'Sign Up',
  'email': 'Email',
  'password': 'Password',
  'confirm_password': 'Confirm Password',
  'forgot_password': 'Forgot Password?',
  'home': 'Home',
  'profile': 'Profile',
  'settings': 'Settings',
  'notifications': 'Notifications',
  'messages': 'Messages',
  'search': 'Search',
  'cancel': 'Cancel',
  'save': 'Save',
  'delete': 'Delete',
  'edit': 'Edit',
  'loading': 'Loading...',
  'error': 'Error',
  'success': 'Success',
  'retry': 'Retry',
  'yes': 'Yes',
  'no': 'No',
  'ok': 'OK',
  'language': 'Language',
  'theme': 'Theme',
  'dark_mode': 'Dark Mode',
  'light_mode': 'Light Mode',
  'vote': 'Vote',
  'comment': 'Comment',
  'share': 'Share',
  'like': 'Like',
  'follow': 'Follow',
  'unfollow': 'Unfollow',
  'gallery': 'Gallery',
  'photo': 'Photo',
  'video': 'Video',
  'upload': 'Upload',
  'download': 'Download',
};

/// Japanese translations
const Map<String, String> _japaneseTranslations = {
  'app_name': 'ピクニック',
  'welcome': 'ようこそ',
  'login': 'ログイン',
  'logout': 'ログアウト',
  'signup': '新規登録',
  'email': 'メール',
  'password': 'パスワード',
  'confirm_password': 'パスワード確認',
  'forgot_password': 'パスワードを忘れた？',
  'home': 'ホーム',
  'profile': 'プロフィール',
  'settings': '設定',
  'notifications': '通知',
  'messages': 'メッセージ',
  'search': '検索',
  'cancel': 'キャンセル',
  'save': '保存',
  'delete': '削除',
  'edit': '編集',
  'loading': '読み込み中...',
  'error': 'エラー',
  'success': '成功',
  'retry': '再試行',
  'yes': 'はい',
  'no': 'いいえ',
  'ok': 'OK',
  'language': '言語',
  'theme': 'テーマ',
  'dark_mode': 'ダークモード',
  'light_mode': 'ライトモード',
  'vote': '投票',
  'comment': 'コメント',
  'share': '共有',
  'like': 'いいね',
  'follow': 'フォロー',
  'unfollow': 'フォロー解除',
  'gallery': 'ギャラリー',
  'photo': '写真',
  'video': '動画',
  'upload': 'アップロード',
  'download': 'ダウンロード',
};

/// Chinese Simplified translations
const Map<String, String> _chineseSimplifiedTranslations = {
  'app_name': '野餐',
  'welcome': '欢迎',
  'login': '登录',
  'logout': '退出',
  'signup': '注册',
  'email': '邮箱',
  'password': '密码',
  'confirm_password': '确认密码',
  'forgot_password': '忘记密码？',
  'home': '主页',
  'profile': '个人资料',
  'settings': '设置',
  'notifications': '通知',
  'messages': '消息',
  'search': '搜索',
  'cancel': '取消',
  'save': '保存',
  'delete': '删除',
  'edit': '编辑',
  'loading': '加载中...',
  'error': '错误',
  'success': '成功',
  'retry': '重试',
  'yes': '是',
  'no': '否',
  'ok': '确定',
  'language': '语言',
  'theme': '主题',
  'dark_mode': '深色模式',
  'light_mode': '浅色模式',
  'vote': '投票',
  'comment': '评论',
  'share': '分享',
  'like': '点赞',
  'follow': '关注',
  'unfollow': '取消关注',
  'gallery': '画廊',
  'photo': '照片',
  'video': '视频',
  'upload': '上传',
  'download': '下载',
};

/// Chinese Traditional translations
const Map<String, String> _chineseTraditionalTranslations = {
  'app_name': '野餐',
  'welcome': '歡迎',
  'login': '登入',
  'logout': '登出',
  'signup': '註冊',
  'email': '郵箱',
  'password': '密碼',
  'confirm_password': '確認密碼',
  'forgot_password': '忘記密碼？',
  'home': '主頁',
  'profile': '個人資料',
  'settings': '設定',
  'notifications': '通知',
  'messages': '訊息',
  'search': '搜尋',
  'cancel': '取消',
  'save': '儲存',
  'delete': '刪除',
  'edit': '編輯',
  'loading': '載入中...',
  'error': '錯誤',
  'success': '成功',
  'retry': '重試',
  'yes': '是',
  'no': '否',
  'ok': '確定',
  'language': '語言',
  'theme': '主題',
  'dark_mode': '深色模式',
  'light_mode': '淺色模式',
  'vote': '投票',
  'comment': '評論',
  'share': '分享',
  'like': '點讚',
  'follow': '關注',
  'unfollow': '取消關注',
  'gallery': '畫廊',
  'photo': '照片',
  'video': '影片',
  'upload': '上傳',
  'download': '下載',
};

/// Locale configuration
class LocaleConfig {
  final bool isRTL;
  final String dateFormat;
  final String timeFormat;
  final int firstDayOfWeek;

  const LocaleConfig({
    required this.isRTL,
    required this.dateFormat,
    required this.timeFormat,
    required this.firstDayOfWeek,
  });
}

/// Localization helper functions
class L10n {
  static LocalizationService get _service => LocalizationService();

  static String t(String key) => _service.translate(key);
  
  static String tp(String key, Map<String, dynamic> params) => 
      _service.translateWithParams(key, params);
  
  static String formatNumber(num number) => _service.formatNumber(number);
  
  static String formatCurrency(num amount, {String? currencyCode}) => 
      _service.formatCurrency(amount, currencyCode: currencyCode);
  
  static String formatDate(DateTime date, {String? pattern}) => 
      _service.formatDate(date, pattern: pattern);
  
  static String formatTime(DateTime time) => _service.formatTime(time);
}
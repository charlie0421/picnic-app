import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/constatns/constants.dart';
import 'package:picnic_lib/data/models/navigator/bottom_navigation_item.dart';
import 'package:picnic_lib/data/models/navigator/screen_info.dart';
import 'package:picnic_lib/enums.dart';

import '../../helpers/test_environment.dart';

void main() {
  setUpAll(() {
    initTestColors();
  });

  group('Constants', () {
    test('webWidth and webHeight', () {
      expect(Constants.webWidth, 375);
      expect(Constants.webHeight, 812);
    });

    test('snackBarDuration', () {
      expect(Constants.snackBarDuration, const Duration(seconds: 5));
    });
  });

  group('NavBarConstants', () {
    test('bottomNavHeight', () {
      expect(NavBarConstants.bottomNavHeight, 52.0);
    });

    test('bottomNavOuterMargin', () {
      expect(NavBarConstants.bottomNavOuterMargin, 16.0);
    });
  });

  group('parseLocale', () {
    test('simple code', () {
      final locale = parseLocale('ko');
      expect(locale.languageCode, 'ko');
    });

    test('code with country', () {
      final locale = parseLocale('zh_CN');
      expect(locale.languageCode, 'zh');
      expect(locale.countryCode, 'CN');
    });

    test('code with underscore but no country', () {
      final locale = parseLocale('en_');
      expect(locale.languageCode, 'en');
    });

    test('bn_BD', () {
      final locale = parseLocale('bn_BD');
      expect(locale.languageCode, 'bn');
      expect(locale.countryCode, 'BD');
    });
  });

  group('countryMap', () {
    test('contains expected entries', () {
      expect(countryMap['ko'], 'KR');
      expect(countryMap['en'], 'US');
      expect(countryMap['ja'], 'JP');
      expect(countryMap['zh_CN'], 'CN');
      expect(countryMap['zh_TW'], 'TW');
      expect(countryMap.length, 12);
    });
  });

  group('languageMap', () {
    test('contains expected entries', () {
      expect(languageMap['ko'], '한국어');
      expect(languageMap['en'], 'English');
      expect(languageMap['ja'], '日本語');
      expect(languageMap.length, 12);
    });
  });

  group('webDesignSize', () {
    test('values', () {
      expect(webDesignSize.width, 600);
      expect(webDesignSize.height, 800);
    });
  });

  group('BottomNavigationItem', () {
    test('constructor', () {
      const item = BottomNavigationItem(
        title: 'Test',
        assetPath: 'assets/icon.svg',
        index: 0,
        pageWidget: SizedBox.shrink(),
        needLogin: true,
      );
      expect(item.title, 'Test');
      expect(item.assetPath, 'assets/icon.svg');
      expect(item.index, 0);
      expect(item.needLogin, isTrue);
    });
  });

  group('ScreenInfo', () {
    test('constructor', () {
      final info = ScreenInfo(
        type: PortalType.vote,
        color: Colors.red,
        pages: const [
          BottomNavigationItem(
            title: 'nav',
            assetPath: 'icon.svg',
            index: 0,
            pageWidget: SizedBox.shrink(),
            needLogin: false,
          ),
        ],
      );
      expect(info.type, PortalType.vote);
      expect(info.color, Colors.red);
      expect(info.pages.length, 1);
    });
  });

  group('color constants', () {
    test('are initialized after initTestColors', () {
      expect(voteMainColor, isNotNull);
      expect(goongHapMainColor, isNotNull);
      expect(picMainColor, isNotNull);
      expect(communityMainColor, isNotNull);
      expect(novelMainColor, isNotNull);
    });
  });
}

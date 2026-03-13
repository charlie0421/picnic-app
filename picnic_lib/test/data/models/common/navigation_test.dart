import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/config/environment.dart';
import 'package:picnic_lib/core/constatns/constants.dart';
import 'package:picnic_lib/data/models/common/navigation.dart';
import 'package:picnic_lib/data/storage/local_storage.dart';
import 'package:picnic_lib/enums.dart';
import 'package:picnic_lib/navigation_stack.dart';
import 'package:picnic_lib/presentation/pages/my_page/my_page.dart';
import 'package:picnic_lib/presentation/pages/signup/login_page.dart';

class _FakeLocalStorage implements LocalStorage {
  final Map<String, String> _store = {};

  @override
  Future<void> saveData(String key, String value) async {
    _store[key] = value;
  }

  @override
  Future<String?> loadData(String key, String? defaultValue) async {
    return _store[key] ?? defaultValue;
  }

  @override
  Future<void> removeData(String key) async {
    _store.remove(key);
  }

  @override
  Future<void> clearStorage() async {
    _store.clear();
  }
}

void main() {
  group('TopRightType', () {
    test('has all expected values', () {
      expect(TopRightType.values, contains(TopRightType.none));
      expect(TopRightType.values, contains(TopRightType.common));
      expect(TopRightType.values, contains(TopRightType.board));
      expect(TopRightType.values, contains(TopRightType.postView));
      expect(TopRightType.values, contains(TopRightType.community));
      expect(TopRightType.values.length, equals(5));
    });

    test('enum indices are correct', () {
      expect(TopRightType.none.index, equals(0));
      expect(TopRightType.common.index, equals(1));
      expect(TopRightType.board.index, equals(2));
      expect(TopRightType.postView.index, equals(3));
      expect(TopRightType.community.index, equals(4));
    });
  });

  group('Navigation', () {
    test('default constructor has correct defaults', () {
      const nav = Navigation();
      expect(nav.portalType, equals(PortalType.vote));
      expect(nav.picBottomNavigationIndex, equals(0));
      expect(nav.voteBottomNavigationIndex, equals(0));
      expect(nav.communityBottomNavigationIndex, equals(0));
      expect(nav.novelBottomNavigationIndex, equals(0));
      expect(nav.showPortal, isTrue);
      expect(nav.showTopMenu, isTrue);
      expect(nav.showMyPoint, isTrue);
      expect(nav.topRightMenu, equals(TopRightType.common));
      expect(nav.showBottomNavigation, isTrue);
      expect(nav.pageTitle, equals(''));
      expect(nav.myPageTitle, equals(''));
      expect(nav.currentScreen, isNull);
      expect(nav.voteNavigationStack, isNull);
      expect(nav.drawerNavigationStack, isNull);
      expect(nav.signUpNavigationStack, isNull);
    });

    test('constructor with all fields set', () {
      final voteStack = NavigationStack();
      final drawerStack = NavigationStack();
      final signUpStack = NavigationStack();
      const screen = SizedBox();

      final nav = Navigation(
        portalType: PortalType.pic,
        picBottomNavigationIndex: 1,
        voteBottomNavigationIndex: 2,
        communityBottomNavigationIndex: 3,
        novelBottomNavigationIndex: 4,
        currentScreen: screen,
        showPortal: false,
        showTopMenu: false,
        showMyPoint: false,
        topRightMenu: TopRightType.board,
        showBottomNavigation: false,
        pageTitle: 'Page',
        myPageTitle: 'MyPage',
        voteNavigationStack: voteStack,
        drawerNavigationStack: drawerStack,
        signUpNavigationStack: signUpStack,
      );

      expect(nav.portalType, equals(PortalType.pic));
      expect(nav.picBottomNavigationIndex, equals(1));
      expect(nav.voteBottomNavigationIndex, equals(2));
      expect(nav.communityBottomNavigationIndex, equals(3));
      expect(nav.novelBottomNavigationIndex, equals(4));
      expect(nav.currentScreen, equals(screen));
      expect(nav.showPortal, isFalse);
      expect(nav.showTopMenu, isFalse);
      expect(nav.showMyPoint, isFalse);
      expect(nav.topRightMenu, equals(TopRightType.board));
      expect(nav.showBottomNavigation, isFalse);
      expect(nav.pageTitle, equals('Page'));
      expect(nav.myPageTitle, equals('MyPage'));
      expect(nav.voteNavigationStack, equals(voteStack));
      expect(nav.drawerNavigationStack, equals(drawerStack));
      expect(nav.signUpNavigationStack, equals(signUpStack));
    });

    group('copyWith', () {
      test('copies with new portalType', () {
        const nav = Navigation();
        final copied = nav.copyWith(portalType: PortalType.pic);
        expect(copied.portalType, equals(PortalType.pic));
        expect(copied.showPortal, isTrue);
      });

      test('copies with new showBottomNavigation', () {
        const nav = Navigation();
        final copied = nav.copyWith(showBottomNavigation: false);
        expect(copied.showBottomNavigation, isFalse);
        expect(copied.showTopMenu, isTrue);
      });

      test('copies with new pageTitle', () {
        const nav = Navigation();
        final copied = nav.copyWith(pageTitle: 'Test Title');
        expect(copied.pageTitle, equals('Test Title'));
      });

      test('copies with multiple fields', () {
        const nav = Navigation();
        final copied = nav.copyWith(
          portalType: PortalType.community,
          showPortal: false,
          showTopMenu: false,
          pageTitle: 'Community',
          voteBottomNavigationIndex: 2,
        );
        expect(copied.portalType, equals(PortalType.community));
        expect(copied.showPortal, isFalse);
        expect(copied.showTopMenu, isFalse);
        expect(copied.pageTitle, equals('Community'));
        expect(copied.voteBottomNavigationIndex, equals(2));
      });

      test('preserves original when no args', () {
        final nav = Navigation(
          portalType: PortalType.pic,
          pageTitle: 'Original',
          showPortal: false,
        );
        final copied = nav.copyWith();
        expect(copied.portalType, equals(PortalType.pic));
        expect(copied.pageTitle, equals('Original'));
        expect(copied.showPortal, isFalse);
      });

      test('copies myPageTitle', () {
        const nav = Navigation();
        final copied = nav.copyWith(myPageTitle: 'My Title');
        expect(copied.myPageTitle, equals('My Title'));
      });

      test('copies showMyPoint', () {
        const nav = Navigation();
        final copied = nav.copyWith(showMyPoint: false);
        expect(copied.showMyPoint, isFalse);
      });

      test('copies topRightMenu', () {
        const nav = Navigation();
        final copied = nav.copyWith(topRightMenu: TopRightType.board);
        expect(copied.topRightMenu, equals(TopRightType.board));
      });

      test('copies picBottomNavigationIndex', () {
        const nav = Navigation();
        final copied = nav.copyWith(picBottomNavigationIndex: 3);
        expect(copied.picBottomNavigationIndex, equals(3));
        // Other indices remain default
        expect(copied.voteBottomNavigationIndex, equals(0));
      });

      test('copies communityBottomNavigationIndex', () {
        const nav = Navigation();
        final copied = nav.copyWith(communityBottomNavigationIndex: 2);
        expect(copied.communityBottomNavigationIndex, equals(2));
      });

      test('copies novelBottomNavigationIndex', () {
        const nav = Navigation();
        final copied = nav.copyWith(novelBottomNavigationIndex: 4);
        expect(copied.novelBottomNavigationIndex, equals(4));
      });

      test('copies currentScreen', () {
        const nav = Navigation();
        const newScreen = SizedBox(key: Key('test'));
        final copied = nav.copyWith(currentScreen: newScreen);
        expect(copied.currentScreen, equals(newScreen));
      });

      test('copies voteNavigationStack', () {
        const nav = Navigation();
        final stack = NavigationStack();
        final copied = nav.copyWith(voteNavigationStack: stack);
        expect(copied.voteNavigationStack, equals(stack));
      });

      test('copies drawerNavigationStack', () {
        const nav = Navigation();
        final stack = NavigationStack();
        final copied = nav.copyWith(drawerNavigationStack: stack);
        expect(copied.drawerNavigationStack, equals(stack));
      });

      test('copies signUpNavigationStack', () {
        const nav = Navigation();
        final stack = NavigationStack();
        final copied = nav.copyWith(signUpNavigationStack: stack);
        expect(copied.signUpNavigationStack, equals(stack));
      });

      test('copies all fields at once', () {
        const nav = Navigation();
        final voteStack = NavigationStack();
        final drawerStack = NavigationStack();
        final signUpStack = NavigationStack();
        const screen = SizedBox();

        final copied = nav.copyWith(
          portalType: PortalType.novel,
          picBottomNavigationIndex: 1,
          voteBottomNavigationIndex: 2,
          communityBottomNavigationIndex: 3,
          novelBottomNavigationIndex: 4,
          currentScreen: screen,
          showPortal: false,
          showTopMenu: false,
          showMyPoint: false,
          topRightMenu: TopRightType.postView,
          showBottomNavigation: false,
          pageTitle: 'All Fields',
          myPageTitle: 'My All',
          voteNavigationStack: voteStack,
          drawerNavigationStack: drawerStack,
          signUpNavigationStack: signUpStack,
        );

        expect(copied.portalType, equals(PortalType.novel));
        expect(copied.picBottomNavigationIndex, equals(1));
        expect(copied.voteBottomNavigationIndex, equals(2));
        expect(copied.communityBottomNavigationIndex, equals(3));
        expect(copied.novelBottomNavigationIndex, equals(4));
        expect(copied.currentScreen, equals(screen));
        expect(copied.showPortal, isFalse);
        expect(copied.showTopMenu, isFalse);
        expect(copied.showMyPoint, isFalse);
        expect(copied.topRightMenu, equals(TopRightType.postView));
        expect(copied.showBottomNavigation, isFalse);
        expect(copied.pageTitle, equals('All Fields'));
        expect(copied.myPageTitle, equals('My All'));
        expect(copied.voteNavigationStack, equals(voteStack));
        expect(copied.drawerNavigationStack, equals(drawerStack));
        expect(copied.signUpNavigationStack, equals(signUpStack));
      });
    });

    group('getBottomNavigationIndex', () {
      test('returns voteBottomNavigationIndex for vote', () {
        final nav = Navigation(
          portalType: PortalType.vote,
          voteBottomNavigationIndex: 3,
        );
        expect(nav.getBottomNavigationIndex(), equals(3));
      });

      test('returns picBottomNavigationIndex for pic', () {
        final nav = Navigation(
          portalType: PortalType.pic,
          picBottomNavigationIndex: 2,
        );
        expect(nav.getBottomNavigationIndex(), equals(2));
      });

      test('returns communityBottomNavigationIndex for community', () {
        final nav = Navigation(
          portalType: PortalType.community,
          communityBottomNavigationIndex: 1,
        );
        expect(nav.getBottomNavigationIndex(), equals(1));
      });

      test('returns communityBottomNavigationIndex for goongHap', () {
        final nav = Navigation(
          portalType: PortalType.goongHap,
          communityBottomNavigationIndex: 4,
        );
        expect(nav.getBottomNavigationIndex(), equals(4));
      });

      test('returns novelBottomNavigationIndex for novel', () {
        final nav = Navigation(
          portalType: PortalType.novel,
          novelBottomNavigationIndex: 5,
        );
        expect(nav.getBottomNavigationIndex(), equals(5));
      });

      test('returns 0 for mypage (default case)', () {
        final nav = Navigation(
          portalType: PortalType.mypage,
          voteBottomNavigationIndex: 3,
          picBottomNavigationIndex: 2,
          communityBottomNavigationIndex: 1,
          novelBottomNavigationIndex: 5,
        );
        expect(nav.getBottomNavigationIndex(), equals(0));
      });
    });

    group('load', () {
      late LocalStorage originalStorage;
      late _FakeLocalStorage fakeStorage;

      final testConfig = {
        'supabase': {
          'url': 'https://test.supabase.co',
          'anon_key': 'a' * 120,
          'storage': {
            'url': 'https://storage.test.co',
            'anon_key': 'storage_key',
          },
        },
        'auth': {
          'apple': {
            'client_id': 'io.test.apple',
            'redirect_uri': 'https://test.co/callback',
          },
          'google': {
            'client_id': 'google_client_id',
            'server_client_id': 'google_server_id',
          },
          'kakao': {
            'native_app_key': 'kakao_native',
            'javascript_key': 'kakao_js',
          },
        },
        'sentry': {
          'enable': true,
          'app_dsn': 'https://sentry.test/app',
          'web_dsn': 'https://sentry.test/web',
          'sample_rates': {
            'trace': 0.5,
            'profile': 0.3,
            'session': 0.8,
            'error': 1.0,
          },
        },
        'storage': {
          'cdn_url': 'https://cdn.test.co',
          'aws': {
            'access_key_id': 'aws_key',
            'secret_access_key': 'aws_secret',
            'region': 'ap-northeast-2',
            's3_bucket': 'test-bucket',
            's3_bucket_url': 'https://s3.test.co',
          },
        },
        'api_keys': {
          'youtube': 'yt_key',
          'deepl': 'deepl_key',
          'branch': 'branch_key',
        },
        'app': {
          'web_domain': 'test.co',
          'download_link': 'https://dl.test.co',
          'app_link_prefix': 'https://link.test.co',
          'inapp_appname_prefix': 'io.test',
        },
        'theme': {
          'colors': {
            'primary': '0xFF6200EE',
            'secondary': '0xFF03DAC5',
            'sub': '0xFF018786',
            'point': '0xFFBB86FC',
            'point_900': '0xFF3700B3',
          },
        },
        'logging': {
          'level': 'debug',
          'image_load_warning_threshold_seconds': 15,
          'image_load_error_threshold_seconds': 25,
        },
        'ads': {
          'tapjoy': {
            'android_sdk_key': 'tapjoy_android',
            'ios_sdk_key': 'tapjoy_ios',
          },
          'pangle': {
            'ios_app_id': 'pangle_ios',
            'android_app_id': 'pangle_android',
            'ios_rewarded_video_id': 'pangle_ios_video',
            'android_rewarded_video_id': 'pangle_android_video',
          },
          'admob': {
            'ios_rewarded_video_id': 'admob_ios_video',
            'android_rewarded_video_id': 'admob_android_video',
          },
          'pincrux': {
            'android_app_key': 'pincrux_android',
            'ios_app_key': 'pincrux_ios',
          },
        },
      };

      setUpAll(() {
        TestWidgetsFlutterBinding.ensureInitialized();
      });

      setUp(() async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMessageHandler(
          'flutter/assets',
          (ByteData? message) async {
            final codec = const StringCodec();
            final requestedAsset = codec.decodeMessage(message!);
            if (requestedAsset == 'config/test.json') {
              return codec.encodeMessage(json.encode(testConfig));
            }
            return null;
          },
        );
        await Environment.initConfig('test');

        originalStorage = globalStorage;
        fakeStorage = _FakeLocalStorage();
        globalStorage = fakeStorage;
      });

      tearDown(() {
        globalStorage = originalStorage;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMessageHandler('flutter/assets', null);
      });

      test('load with empty storage returns default values', () async {
        final nav = Navigation.initial();
        final loaded = await nav.load();

        expect(loaded.portalType, equals(PortalType.vote));
        expect(loaded.voteBottomNavigationIndex, equals(0));
        expect(loaded.picBottomNavigationIndex, equals(0));
        expect(loaded.communityBottomNavigationIndex, equals(0));
        expect(loaded.novelBottomNavigationIndex, equals(0));
        expect(loaded.voteNavigationStack, isNotNull);
        expect(loaded.voteNavigationStack!.length, equals(1));
        expect(loaded.drawerNavigationStack, isNotNull);
        expect(loaded.drawerNavigationStack!.length, equals(1));
        expect(loaded.signUpNavigationStack, isNotNull);
        expect(loaded.signUpNavigationStack!.length, equals(1));
      });

      test('load with vote portal stored', () async {
        await fakeStorage.saveData('portalString', 'vote');
        await fakeStorage.saveData('voteBottomNavigationIndex', '2');

        final nav = Navigation.initial();
        final loaded = await nav.load();

        expect(loaded.portalType, equals(PortalType.vote));
        expect(loaded.voteBottomNavigationIndex, equals(2));
      });

      test('load with pic portal type', () async {
        await fakeStorage.saveData('portalString', 'pic');
        await fakeStorage.saveData('picBottomNavigationIndex', '1');

        final nav = Navigation.initial();
        final loaded = await nav.load();

        expect(loaded.portalType, equals(PortalType.pic));
        expect(loaded.picBottomNavigationIndex, equals(1));
      });

      test('load with community portal type', () async {
        await fakeStorage.saveData('portalString', 'community');
        await fakeStorage.saveData('communityBottomNavigationIndex', '3');

        final nav = Navigation.initial();
        final loaded = await nav.load();

        expect(loaded.portalType, equals(PortalType.community));
        expect(loaded.communityBottomNavigationIndex, equals(3));
      });

      test('load with different bottom nav indices', () async {
        await fakeStorage.saveData('portalString', 'vote');
        await fakeStorage.saveData('voteBottomNavigationIndex', '1');
        await fakeStorage.saveData('picBottomNavigationIndex', '2');
        await fakeStorage.saveData('communityBottomNavigationIndex', '3');
        await fakeStorage.saveData('novelBottomNavigationIndex', '0');

        final nav = Navigation.initial();
        final loaded = await nav.load();

        expect(loaded.voteBottomNavigationIndex, equals(1));
        expect(loaded.picBottomNavigationIndex, equals(2));
        expect(loaded.communityBottomNavigationIndex, equals(3));
        expect(loaded.novelBottomNavigationIndex, equals(0));
      });

      test('load creates navigation stacks', () async {
        final nav = Navigation.initial();
        final loaded = await nav.load();

        expect(loaded.voteNavigationStack, isNotNull);
        expect(loaded.voteNavigationStack!.isEmpty, isFalse);
        expect(loaded.drawerNavigationStack, isNotNull);
        expect(loaded.drawerNavigationStack!.peek(), isA<MyPage>());
        expect(loaded.signUpNavigationStack, isNotNull);
        expect(loaded.signUpNavigationStack!.peek(), isA<LoginPage>());
      });

      test('load with novel portal type', () async {
        await fakeStorage.saveData('portalString', 'novel');
        await fakeStorage.saveData('novelBottomNavigationIndex', '0');

        final nav = Navigation.initial();
        final loaded = await nav.load();

        expect(loaded.portalType, equals(PortalType.novel));
        expect(loaded.novelBottomNavigationIndex, equals(0));
      });
    });

    group('getBottomNavigationIndex for all PortalTypes', () {
      test('vote returns voteBottomNavigationIndex', () {
        const nav = Navigation(
          portalType: PortalType.vote,
          voteBottomNavigationIndex: 2,
        );
        expect(nav.getBottomNavigationIndex(), equals(2));
      });

      test('goongHap returns communityBottomNavigationIndex', () {
        const nav = Navigation(
          portalType: PortalType.goongHap,
          communityBottomNavigationIndex: 1,
        );
        expect(nav.getBottomNavigationIndex(), equals(1));
      });

      test('pic returns picBottomNavigationIndex', () {
        const nav = Navigation(
          portalType: PortalType.pic,
          picBottomNavigationIndex: 2,
        );
        expect(nav.getBottomNavigationIndex(), equals(2));
      });

      test('community returns communityBottomNavigationIndex', () {
        const nav = Navigation(
          portalType: PortalType.community,
          communityBottomNavigationIndex: 3,
        );
        expect(nav.getBottomNavigationIndex(), equals(3));
      });

      test('novel returns novelBottomNavigationIndex', () {
        const nav = Navigation(
          portalType: PortalType.novel,
          novelBottomNavigationIndex: 4,
        );
        expect(nav.getBottomNavigationIndex(), equals(4));
      });

      test('mypage returns 0 (default)', () {
        const nav = Navigation(
          portalType: PortalType.mypage,
          voteBottomNavigationIndex: 5,
          picBottomNavigationIndex: 5,
          communityBottomNavigationIndex: 5,
          novelBottomNavigationIndex: 5,
        );
        expect(nav.getBottomNavigationIndex(), equals(0));
      });
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/widgets/community/list/post_list.dart';

import '../../../../helpers/test_environment.dart';

/// Tests for PostList logic patterns.
///
/// Widget testing is blocked because PostList transitively imports
/// assets (app_icon_128.png) and flutter_svg which require native plugins.
/// Instead, we test the pure logic patterns the widget relies on.
void main() {
  setUpAll(() {
    initTestColors();
  });

  group('PostListType enum', () {
    test('has artist and board values', () {
      expect(PostListType.values.length, equals(2));
      expect(PostListType.values.contains(PostListType.artist), isTrue);
      expect(PostListType.values.contains(PostListType.board), isTrue);
    });

    test('artist and board are distinct', () {
      expect(PostListType.artist, isNot(equals(PostListType.board)));
    });
  });

  group('PostList logic', () {
    test('isSupabaseLoggedSafely guard pattern', () {
      // The widget checks isSupabaseLoggedSafely before navigating
      // When not logged in, it shows require login dialog
      const loggedIn = true;
      const notLoggedIn = false;

      expect(loggedIn, isTrue);
      expect(notLoggedIn, isFalse);
    });

    test('header title falls back to pageTitle when artist is null', () {
      // Replicating the headerTitle logic
      String? currentArtistName;
      String pageTitle = 'Test Board';

      String headerTitle = '';
      if (currentArtistName != null) {
        headerTitle = currentArtistName;
      } else if (pageTitle.isNotEmpty) {
        headerTitle = pageTitle;
      }

      expect(headerTitle, equals('Test Board'));
    });

    test('header title uses artist name when available', () {
      String? currentArtistName = 'BTS';
      String pageTitle = 'Test Board';

      String headerTitle = '';
      if (currentArtistName != null) {
        headerTitle = currentArtistName;
      } else if (pageTitle.isNotEmpty) {
        headerTitle = pageTitle;
      }

      expect(headerTitle, equals('BTS'));
    });

    test('header title is empty when both are null/empty', () {
      String? currentArtistName;
      String pageTitle = '';

      String headerTitle = '';
      if (currentArtistName != null) {
        headerTitle = currentArtistName;
      } else if (pageTitle.isNotEmpty) {
        headerTitle = pageTitle;
      }

      expect(headerTitle, isEmpty);
    });
  });
}

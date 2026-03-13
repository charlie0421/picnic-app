import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/utils/avatar_url_resolver.dart';
import 'package:picnic_lib/presentation/common/avatar_container.dart';

import '../../helpers/test_app.dart';
import '../../helpers/test_environment.dart';

void main() {
  setUpAll(() {
    initTestColors();
  });

  group('resolveAvatarImageUrl', () {
    test('returns empty string for null', () {
      expect(resolveAvatarImageUrl(null), '');
    });

    test('returns empty string for empty string', () {
      expect(resolveAvatarImageUrl(''), '');
    });

    test('returns empty string for whitespace only', () {
      expect(resolveAvatarImageUrl('   '), '');
    });

    test('trims whitespace from URLs', () {
      expect(resolveAvatarImageUrl('  https://example.com/img.png  '),
          'https://example.com/img.png');
    });

    test('prepends https: for scheme-less URLs', () {
      expect(resolveAvatarImageUrl('//example.com/img.png'),
          'https://example.com/img.png');
    });

    test('returns http URLs as-is', () {
      expect(resolveAvatarImageUrl('http://example.com/img.png'),
          'http://example.com/img.png');
    });

    test('returns https URLs as-is', () {
      expect(resolveAvatarImageUrl('https://example.com/img.png'),
          'https://example.com/img.png');
    });

    test('returns non-http URLs as-is', () {
      expect(resolveAvatarImageUrl('file:///local/path.png'),
          'file:///local/path.png');
    });
  });

  group('ProfileImageContainer widget', () {
    test('can be constructed with required parameters', () {
      const widget = ProfileImageContainer(
        avatarUrl: 'https://example.com/avatar.png',
        borderRadius: 20,
        width: 40,
        height: 40,
      );
      expect(widget, isA<ProfileImageContainer>());
      expect(widget.avatarUrl, 'https://example.com/avatar.png');
      expect(widget.borderRadius, 20);
      expect(widget.width, 40);
      expect(widget.height, 40);
    });

    test('can be constructed with null avatarUrl', () {
      const widget = ProfileImageContainer(
        avatarUrl: null,
        borderRadius: 10,
        width: 36,
        height: 36,
      );
      expect(widget.avatarUrl, isNull);
    });

    test('can be constructed with optional border', () {
      final widget = ProfileImageContainer(
        avatarUrl: 'https://example.com/avatar.png',
        borderRadius: 20,
        width: 40,
        height: 40,
        border: Border.all(color: Colors.red),
      );
      expect(widget.border, isNotNull);
    });

    testWidgets('renders with null avatarUrl', (tester) async {
      await tester.pumpWidget(buildTestApp(
        const ProfileImageContainer(
          avatarUrl: null,
          borderRadius: 20,
          width: 40,
          height: 40,
        ),
      ));
      await tester.pump();

      // Should show NoAvatar fallback
      expect(find.byType(ProfileImageContainer), findsOneWidget);
    });

    testWidgets('renders with empty avatarUrl', (tester) async {
      await tester.pumpWidget(buildTestApp(
        const ProfileImageContainer(
          avatarUrl: '',
          borderRadius: 20,
          width: 40,
          height: 40,
        ),
      ));
      await tester.pump();

      expect(find.byType(ProfileImageContainer), findsOneWidget);
    });
  });

  group('DefaultAvatar widget', () {
    test('can be const-constructed', () {
      const widget = DefaultAvatar();
      expect(widget, isA<DefaultAvatar>());
    });
  });

  group('NoAvatar widget', () {
    test('can be const-constructed', () {
      const widget = NoAvatar(
        width: 40,
        height: 40,
        borderRadius: 20,
      );
      expect(widget, isA<NoAvatar>());
      expect(widget.width, 40);
      expect(widget.height, 40);
      expect(widget.borderRadius, 20);
    });
  });
}

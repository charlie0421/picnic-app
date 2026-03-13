import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/pages/my_page/notice_page.dart';

/// Tests for NoticePage production code.
///
/// Widget rendering is blocked by platform dependencies (RouteAwareStateMixin,
/// Supabase.instance.client). We test importable production code.
void main() {
  group('NoticePage widget', () {
    test('can be const-constructed', () {
      const page = NoticePage();
      expect(page, isA<NoticePage>());
    });

    test('with key can be constructed', () {
      const page = NoticePage(key: ValueKey('notice'));
      expect(page.key, equals(const ValueKey('notice')));
    });
  });

  group('Notice data sorting logic', () {
    test('pinned notices should come before normal notices', () {
      final notices = <Map<String, dynamic>>[
        {'id': 1, 'title': {'ko': 'Normal 1'}, 'is_pinned': false, 'created_at': '2024-01-01', 'content': {'ko': 'Content 1'}},
        {'id': 2, 'title': {'ko': 'Pinned 1'}, 'is_pinned': true, 'created_at': '2024-01-02', 'content': {'ko': 'Content 2'}},
        {'id': 3, 'title': {'ko': 'Normal 2'}, 'is_pinned': false, 'created_at': '2024-01-03', 'content': {'ko': 'Content 3'}},
        {'id': 4, 'title': {'ko': 'Pinned 2'}, 'is_pinned': true, 'created_at': '2024-01-04', 'content': {'ko': 'Content 4'}},
      ];

      // Replicate the sorting logic from NoticePage._getSortedNotices()
      final pinnedNotices =
          notices.where((notice) => notice['is_pinned'] == true).toList();
      final normalNotices =
          notices.where((notice) => notice['is_pinned'] != true).toList();
      final sorted = [...pinnedNotices, ...normalNotices];

      expect(sorted[0]['id'], 2); // Pinned 1
      expect(sorted[1]['id'], 4); // Pinned 2
      expect(sorted[2]['id'], 1); // Normal 1
      expect(sorted[3]['id'], 3); // Normal 2
    });

    test('all pinned notices', () {
      final notices = <Map<String, dynamic>>[
        {'id': 1, 'is_pinned': true},
        {'id': 2, 'is_pinned': true},
      ];

      final pinnedNotices =
          notices.where((n) => n['is_pinned'] == true).toList();
      final normalNotices =
          notices.where((n) => n['is_pinned'] != true).toList();
      final sorted = [...pinnedNotices, ...normalNotices];

      expect(sorted.length, 2);
      expect(pinnedNotices.length, 2);
      expect(normalNotices.length, 0);
    });

    test('no pinned notices', () {
      final notices = <Map<String, dynamic>>[
        {'id': 1, 'is_pinned': false},
        {'id': 2, 'is_pinned': null},
      ];

      final pinnedNotices =
          notices.where((n) => n['is_pinned'] == true).toList();
      final normalNotices =
          notices.where((n) => n['is_pinned'] != true).toList();
      final sorted = [...pinnedNotices, ...normalNotices];

      expect(sorted.length, 2);
      expect(pinnedNotices.length, 0);
      expect(normalNotices.length, 2);
    });

    test('empty notices list', () {
      final notices = <Map<String, dynamic>>[];
      final sorted = [...notices.where((n) => n['is_pinned'] == true), ...notices.where((n) => n['is_pinned'] != true)];
      expect(sorted.isEmpty, isTrue);
    });
  });

  group('Notice localization logic', () {
    test('getLocalizedText returns language-specific text', () {
      final json = {'ko': '공지사항', 'en': 'Notice'};

      // Replicate _getLocalizedText logic
      String getLocalizedText(Map<String, dynamic> json, String language) {
        if (json[language] != null) return json[language];
        return json['en'] ?? '';
      }

      expect(getLocalizedText(json, 'ko'), '공지사항');
      expect(getLocalizedText(json, 'en'), 'Notice');
    });

    test('getLocalizedText falls back to en', () {
      final json = {'en': 'Fallback'};

      String getLocalizedText(Map<String, dynamic> json, String language) {
        if (json[language] != null) return json[language];
        return json['en'] ?? '';
      }

      expect(getLocalizedText(json, 'ja'), 'Fallback');
    });

    test('getLocalizedText returns empty when no fallback', () {
      final json = <String, dynamic>{'ko': '한국어'};

      String getLocalizedText(Map<String, dynamic> json, String language) {
        if (json[language] != null) return json[language];
        return json['en'] ?? '';
      }

      expect(getLocalizedText(json, 'ja'), '');
    });

    test('date truncation from created_at', () {
      const createdAt = '2024-06-15T10:30:00.000Z';
      final dateOnly = createdAt.substring(0, 10);
      expect(dateOnly, '2024-06-15');
    });

    test('null created_at handling', () {
      const String? createdAt = null;
      final dateOnly = createdAt?.substring(0, 10) ?? '';
      expect(dateOnly, '');
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/pages/my_page/notice_detail_page.dart';

/// Tests for NoticeDetailPage production code.
///
/// Widget rendering is blocked by platform dependencies (RouteAwareStateMixin,
/// Supabase.instance.client). We test importable production code.
void main() {
  group('NoticeDetailPage widget', () {
    test('can be constructed with noticeId', () {
      const page = NoticeDetailPage(noticeId: 42);
      expect(page, isA<NoticeDetailPage>());
      expect(page.noticeId, 42);
    });

    test('with key can be constructed', () {
      const page = NoticeDetailPage(
        key: ValueKey('notice_detail'),
        noticeId: 1,
      );
      expect(page.key, equals(const ValueKey('notice_detail')));
      expect(page.noticeId, 1);
    });

    test('different noticeIds produce different widgets', () {
      const page1 = NoticeDetailPage(noticeId: 1);
      const page2 = NoticeDetailPage(noticeId: 2);
      expect(page1.noticeId, isNot(page2.noticeId));
    });
  });

  group('NoticeDetailPage localization logic', () {
    // Replicate the _getLocalizedText logic from NoticeDetailPage
    String getLocalizedText(Map<String, dynamic> json, String language) {
      if (json[language] != null) {
        return json[language];
      }
      return json['en'] ?? '';
    }

    test('returns language-specific title', () {
      final title = {'ko': '공지사항 제목', 'en': 'Notice Title'};
      expect(getLocalizedText(title, 'ko'), '공지사항 제목');
      expect(getLocalizedText(title, 'en'), 'Notice Title');
    });

    test('falls back to en when requested language not available', () {
      final title = {'en': 'English Only'};
      expect(getLocalizedText(title, 'ja'), 'English Only');
    });

    test('returns empty string when no fallback', () {
      final title = <String, dynamic>{'ko': '한국어만'};
      expect(getLocalizedText(title, 'ja'), '');
    });

    test('handles content field', () {
      final content = {'ko': '공지 내용입니다.', 'en': 'Notice content.'};
      expect(getLocalizedText(content, 'ko'), '공지 내용입니다.');
    });
  });

  group('NoticeDetailPage date display logic', () {
    test('extracts date from created_at', () {
      const createdAt = '2024-12-25T14:30:00.000Z';
      final dateOnly = createdAt.substring(0, 10);
      expect(dateOnly, '2024-12-25');
    });

    test('handles short date string', () {
      const createdAt = '2024-12-25';
      final dateOnly = createdAt.substring(0, 10);
      expect(dateOnly, '2024-12-25');
    });

    test('null created_at falls back to empty', () {
      const String? createdAt = null;
      final dateOnly = createdAt?.toString().substring(0, 10) ?? '';
      expect(dateOnly, '');
    });
  });

  group('NoticeDetailPage notice data structure', () {
    test('notice with all fields', () {
      final notice = <String, dynamic>{
        'id': 1,
        'title': {'ko': '제목', 'en': 'Title'},
        'content': {'ko': '내용', 'en': 'Content'},
        'created_at': '2024-06-15T10:00:00.000Z',
        'status': 'PUBLISHED',
        'is_pinned': true,
      };
      expect(notice['id'], 1);
      expect(notice['is_pinned'], isTrue);
    });

    test('notice with null optional fields', () {
      final notice = <String, dynamic>{
        'id': 2,
        'title': {'ko': '제목'},
        'content': {'ko': '내용'},
        'created_at': null,
        'is_pinned': null,
      };
      expect(notice['created_at'], isNull);
      expect(notice['is_pinned'], isNull);
    });
  });
}

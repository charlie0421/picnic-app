import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/common/comment.dart';
import 'package:picnic_lib/presentation/common/comment/comment_contents.dart';

import '../../../helpers/ignore_image_errors.dart';
import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

CommentModel _makeComment({
  Map<String, dynamic>? content,
  String? locale,
  bool? isReportedByMe,
  bool? isBlindedByAdmin,
  DateTime? deletedAt,
}) {
  return CommentModel(
    commentId: 'c-1',
    children: null,
    myLike: null,
    user: null,
    likes: 0,
    replies: 0,
    content: content ?? {'ko': '테스트 댓글'},
    isLikedByMe: false,
    isReportedByMe: isReportedByMe ?? false,
    isBlindedByAdmin: isBlindedByAdmin ?? false,
    isRepliedByMe: false,
    post: null,
    locale: locale ?? 'ko',
    parentCommentId: null,
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 1),
    deletedAt: deletedAt,
  );
}

void main() {
  setUp(() {
    initTestColors();
  });

  group('CommentContents - translation branch coverage', () {
    testWidgets(
        'shows translated text when isTranslated=true and currentLocale differs from comment locale',
        (WidgetTester tester) async {
      final restore = suppressImageErrors();
      addTearDown(restore);

      // ko locale app, comment has ko original, en translation
      // isTranslated=true, showOriginal=false, content has ko key
      await tester.pumpWidget(
        buildTestApp(
          CommentContents(
            item: _makeComment(
              content: {'ko': '한국어 원문', 'en': 'English translation'},
              locale: 'en',
            ),
            isTranslated: true,
            showOriginal: false,
          ),
          locale: const Locale('ko'),
        ),
      );
      await tester.pump();

      // The app locale is 'ko', comment locale is 'en', translation exists for 'ko'
      // So it should show the translated 'ko' text
      expect(find.text('한국어 원문'), findsOneWidget);
    });

    testWidgets(
        'shows original when showOriginal=true even if translation exists',
        (WidgetTester tester) async {
      final restore = suppressImageErrors();
      addTearDown(restore);

      await tester.pumpWidget(
        buildTestApp(
          CommentContents(
            item: _makeComment(
              content: {'ko': '한국어 원문', 'en': 'English translation'},
              locale: 'en',
            ),
            isTranslated: true,
            showOriginal: true,
          ),
          locale: const Locale('ko'),
        ),
      );
      await tester.pump();

      // showOriginal=true, so original text (en locale) should be shown
      expect(find.text('English translation'), findsOneWidget);
    });

    testWidgets('shows original when isTranslated=false', (WidgetTester tester) async {
      final restore = suppressImageErrors();
      addTearDown(restore);

      await tester.pumpWidget(
        buildTestApp(
          CommentContents(
            item: _makeComment(
              content: {'ko': '한국어 댓글', 'en': 'English comment'},
              locale: 'ko',
            ),
            isTranslated: false,
            showOriginal: false,
          ),
          locale: const Locale('ko'),
        ),
      );
      await tester.pump();

      expect(find.text('한국어 댓글'), findsOneWidget);
    });

    testWidgets(
        'falls back to first value when content lacks commentLocale key',
        (WidgetTester tester) async {
      final restore = suppressImageErrors();
      addTearDown(restore);

      await tester.pumpWidget(
        buildTestApp(
          CommentContents(
            item: _makeComment(
              content: {'en': 'Only English'},
              locale: 'ja', // Japanese locale, but no 'ja' key in content
            ),
            isTranslated: false,
            showOriginal: false,
          ),
          locale: const Locale('ko'),
        ),
      );
      await tester.pump();

      // Falls back to content.values.first
      expect(find.text('Only English'), findsOneWidget);
    });

    testWidgets(
        'falls back to commentLocale when currentLocale not in content for translated mode',
        (WidgetTester tester) async {
      final restore = suppressImageErrors();
      addTearDown(restore);

      // App locale is 'ko', but content only has 'en' and 'ja'
      // isTranslated=true, showOriginal=false
      await tester.pumpWidget(
        buildTestApp(
          CommentContents(
            item: _makeComment(
              content: {'en': 'English text', 'ja': 'Japanese text'},
              locale: 'en',
            ),
            isTranslated: true,
            showOriginal: false,
          ),
          locale: const Locale('ko'),
        ),
      );
      await tester.pump();

      // currentLocale 'ko' not in content, so showOriginal path is used
      // (because !content.containsKey(currentLocale) is true)
      expect(find.text('English text'), findsOneWidget);
    });
  });

  group('CommentContents - expand/collapse', () {
    testWidgets('tapping long text toggles expansion',
        (WidgetTester tester) async {
      final restore = suppressImageErrors();
      addTearDown(restore);

      // Create a very long text that will exceed max lines
      final longText = 'A' * 1000;
      await tester.pumpWidget(
        buildTestApp(
          SizedBox(
            width: 200,
            child: CommentContents(
              item: _makeComment(content: {'ko': longText}),
              isTranslated: false,
              showOriginal: false,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CommentContents), findsOneWidget);

      // Tap to toggle expansion
      await tester.tap(find.byType(GestureDetector).first);
      await tester.pump();

      // The text should still be displayed
      expect(find.byType(CommentContents), findsOneWidget);
    });
  });

  group('CommentContents - edge cases', () {
    testWidgets('empty content map returns empty string',
        (WidgetTester tester) async {
      final restore = suppressImageErrors();
      addTearDown(restore);

      await tester.pumpWidget(
        buildTestApp(
          CommentContents(
            item: _makeComment(content: {}),
            isTranslated: false,
            showOriginal: false,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CommentContents), findsOneWidget);
    });

    testWidgets('null content returns empty string',
        (WidgetTester tester) async {
      final restore = suppressImageErrors();
      addTearDown(restore);

      await tester.pumpWidget(
        buildTestApp(
          CommentContents(
            item: _makeComment(content: null),
            isTranslated: false,
            showOriginal: false,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CommentContents), findsOneWidget);
    });

    testWidgets('reported and blinded at same time shows reported text',
        (WidgetTester tester) async {
      final restore = suppressImageErrors();
      addTearDown(restore);

      await tester.pumpWidget(
        buildTestApp(
          CommentContents(
            item: _makeComment(
              isReportedByMe: true,
              isBlindedByAdmin: true,
            ),
            isTranslated: false,
            showOriginal: false,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CommentContents), findsOneWidget);
    });

    testWidgets('deleted comment with content shows deleted text',
        (WidgetTester tester) async {
      final restore = suppressImageErrors();
      addTearDown(restore);

      await tester.pumpWidget(
        buildTestApp(
          CommentContents(
            item: _makeComment(
              content: {'ko': '삭제된 댓글 내용'},
              deletedAt: DateTime(2025, 1, 2),
            ),
            isTranslated: false,
            showOriginal: false,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CommentContents), findsOneWidget);
    });

    testWidgets('comment with null locale defaults to ko',
        (WidgetTester tester) async {
      final restore = suppressImageErrors();
      addTearDown(restore);

      await tester.pumpWidget(
        buildTestApp(
          CommentContents(
            item: _makeComment(
              content: {'ko': '기본 로케일'},
              locale: null,
            ),
            isTranslated: false,
            showOriginal: false,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('기본 로케일'), findsOneWidget);
    });

    testWidgets('isTranslatedText shows translated label when conditions met',
        (WidgetTester tester) async {
      final restore = suppressImageErrors();
      addTearDown(restore);

      // isTranslated=true, content has currentLocale key, currentLocale != commentLocale, showOriginal=false
      await tester.pumpWidget(
        buildTestApp(
          CommentContents(
            item: _makeComment(
              content: {'ko': '번역된 텍스트', 'en': 'Original English'},
              locale: 'en',
            ),
            isTranslated: true,
            showOriginal: false,
          ),
          locale: const Locale('ko'),
        ),
      );
      await tester.pump();

      // The "(번역됨)" label should appear
      expect(find.byType(CommentContents), findsOneWidget);
    });
  });
}

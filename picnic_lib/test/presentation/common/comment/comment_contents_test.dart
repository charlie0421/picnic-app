import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/data/models/common/comment.dart';
import 'package:picnic_lib/presentation/common/comment/comment_contents.dart';

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

  group('CommentContents', () {
    testWidgets('renders normal comment content', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          CommentContents(
            item: _makeComment(content: {'ko': '안녕하세요'}),
            isTranslated: false,
            showOriginal: false,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CommentContents), findsOneWidget);
      expect(find.text('안녕하세요'), findsOneWidget);
    });

    testWidgets('renders reported comment', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          CommentContents(
            item: _makeComment(isReportedByMe: true),
            isTranslated: false,
            showOriginal: false,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CommentContents), findsOneWidget);
    });

    testWidgets('renders blinded comment', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          CommentContents(
            item: _makeComment(isBlindedByAdmin: true),
            isTranslated: false,
            showOriginal: false,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CommentContents), findsOneWidget);
    });

    testWidgets('renders deleted comment', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          CommentContents(
            item: _makeComment(deletedAt: DateTime(2025, 1, 2)),
            isTranslated: false,
            showOriginal: false,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CommentContents), findsOneWidget);
    });

    testWidgets('renders with empty content', (WidgetTester tester) async {
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

    testWidgets('renders with null content', (WidgetTester tester) async {
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

    testWidgets('renders translated state', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          CommentContents(
            item: _makeComment(
              content: {'ko': '한국어 댓글', 'en': 'Korean comment'},
              locale: 'ko',
            ),
            isTranslated: true,
            showOriginal: false,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CommentContents), findsOneWidget);
    });

    testWidgets('renders showOriginal state', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildTestApp(
          CommentContents(
            item: _makeComment(
              content: {'ko': '원문입니다', 'en': 'This is original'},
              locale: 'ko',
            ),
            isTranslated: true,
            showOriginal: true,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CommentContents), findsOneWidget);
      expect(find.text('원문입니다'), findsOneWidget);
    });
  });
}

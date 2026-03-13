import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:picnic_lib/data/models/common/comment.dart';
import 'package:picnic_lib/data/models/user_profiles.dart';
import 'package:picnic_lib/presentation/common/comment/comment_reply_layer.dart';
import 'package:picnic_lib/presentation/providers/comment_list_provider.dart';
import 'package:picnic_lib/ui/style.dart';

import '../../../helpers/test_app.dart';
import '../../../helpers/test_environment.dart';

void main() {
  late CommentModel parentComment;
  late PagingController<int, CommentModel> pagingController;

  setUp(() {
    initTestColors();

    parentComment = CommentModel(
      commentId: 'c-1',
      children: null,
      myLike: null,
      user: UserProfilesModel(
        id: 'u1',
        nickname: 'TestNickname',
        avatarUrl: null,
        isAdmin: null,
        starCandy: null,
        starCandyBonus: null,
        jmaCandy: null,
      ),
      likes: 0,
      replies: 0,
      content: {'ko': 'test'},
      isLikedByMe: false,
      isReportedByMe: false,
      isBlindedByAdmin: false,
      isRepliedByMe: false,
      post: null,
      locale: 'ko',
      parentCommentId: null,
      createdAt: DateTime(2025, 1, 1),
      updatedAt: DateTime(2025, 1, 1),
    );

    pagingController = PagingController<int, CommentModel>(
      getNextPageKey: (state) => (state.keys?.last ?? 0) + 1,
      fetchPage: (pageKey) async => [],
    );
  });

  tearDown(() {
    pagingController.dispose();
  });

  Widget buildWidget() {
    return buildTestApp(
      CommentReplyLayer(
        pagingController: pagingController,
        parentComment: parentComment,
      ),
      extraOverrides: [
        parentItemProvider.overrideWith(() => ParentItem()),
      ],
    );
  }

  group('CommentReplyLayer', () {
    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.byType(CommentReplyLayer), findsOneWidget);
    });

    testWidgets('container has primary500 background color', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.color;
      expect(decoration, equals(AppColors.primary500));
    });

    testWidgets('shows parent comment nickname in text', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.textContaining('TestNickname'), findsOneWidget);
    });

    testWidgets('contains close IconButton', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.byType(IconButton), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('has height 40', (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      final renderBox = tester.renderObject<RenderBox>(
        find.byType(CommentReplyLayer),
      );
      expect(renderBox.size.height, equals(40.0));
    });
  });
}

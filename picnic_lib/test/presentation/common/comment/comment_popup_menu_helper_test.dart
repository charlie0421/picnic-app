import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/common/comment/comment_popup_menu_helper.dart';

void main() {
  group('CommentPopupMenuHelper', () {
    group('canDeleteComment', () {
      test('returns true when user is comment author and not deleted', () {
        expect(
          CommentPopupMenuHelper.canDeleteComment(
            commentUserId: 'user-1',
            currentUserId: 'user-1',
            deletedAt: null,
          ),
          isTrue,
        );
      });

      test('returns false when user is not comment author', () {
        expect(
          CommentPopupMenuHelper.canDeleteComment(
            commentUserId: 'user-1',
            currentUserId: 'user-2',
            deletedAt: null,
          ),
          isFalse,
        );
      });

      test('returns false when comment is already deleted', () {
        expect(
          CommentPopupMenuHelper.canDeleteComment(
            commentUserId: 'user-1',
            currentUserId: 'user-1',
            deletedAt: DateTime(2024, 1, 1),
          ),
          isFalse,
        );
      });

      test('returns false when currentUserId is null', () {
        expect(
          CommentPopupMenuHelper.canDeleteComment(
            commentUserId: 'user-1',
            currentUserId: null,
            deletedAt: null,
          ),
          isFalse,
        );
      });

      test('returns false when commentUserId is null and currentUserId is null', () {
        expect(
          CommentPopupMenuHelper.canDeleteComment(
            commentUserId: null,
            currentUserId: null,
            deletedAt: null,
          ),
          isFalse,
        );
      });

      test('returns false when commentUserId is null', () {
        expect(
          CommentPopupMenuHelper.canDeleteComment(
            commentUserId: null,
            currentUserId: 'user-1',
            deletedAt: null,
          ),
          isFalse,
        );
      });

      test('returns false when both user is author and comment is deleted', () {
        expect(
          CommentPopupMenuHelper.canDeleteComment(
            commentUserId: 'user-1',
            currentUserId: 'user-1',
            deletedAt: DateTime.now(),
          ),
          isFalse,
        );
      });
    });

    group('canReportComment', () {
      test('returns true when user is not comment author and not deleted', () {
        expect(
          CommentPopupMenuHelper.canReportComment(
            commentUserId: 'user-1',
            currentUserId: 'user-2',
            deletedAt: null,
          ),
          isTrue,
        );
      });

      test('returns false when user is comment author', () {
        expect(
          CommentPopupMenuHelper.canReportComment(
            commentUserId: 'user-1',
            currentUserId: 'user-1',
            deletedAt: null,
          ),
          isFalse,
        );
      });

      test('returns false when comment is deleted', () {
        expect(
          CommentPopupMenuHelper.canReportComment(
            commentUserId: 'user-1',
            currentUserId: 'user-2',
            deletedAt: DateTime(2024, 1, 1),
          ),
          isFalse,
        );
      });

      test('returns false when currentUserId is null', () {
        expect(
          CommentPopupMenuHelper.canReportComment(
            commentUserId: 'user-1',
            currentUserId: null,
            deletedAt: null,
          ),
          isFalse,
        );
      });

      test('returns false when both null (user cannot report own null)', () {
        expect(
          CommentPopupMenuHelper.canReportComment(
            commentUserId: null,
            currentUserId: null,
            deletedAt: null,
          ),
          isFalse,
        );
      });

      test('returns true when commentUserId is null but currentUserId is set', () {
        expect(
          CommentPopupMenuHelper.canReportComment(
            commentUserId: null,
            currentUserId: 'user-1',
            deletedAt: null,
          ),
          isTrue,
        );
      });
    });

    group('getAvailableActions', () {
      test('returns delete for own non-deleted comment', () {
        final actions = CommentPopupMenuHelper.getAvailableActions(
          commentUserId: 'user-1',
          currentUserId: 'user-1',
          deletedAt: null,
        );
        expect(actions, [CommentMenuAction.delete]);
      });

      test('returns report for other user non-deleted comment', () {
        final actions = CommentPopupMenuHelper.getAvailableActions(
          commentUserId: 'user-1',
          currentUserId: 'user-2',
          deletedAt: null,
        );
        expect(actions, [CommentMenuAction.report]);
      });

      test('returns empty for deleted comment by author', () {
        final actions = CommentPopupMenuHelper.getAvailableActions(
          commentUserId: 'user-1',
          currentUserId: 'user-1',
          deletedAt: DateTime(2024, 1, 1),
        );
        expect(actions, isEmpty);
      });

      test('returns empty for deleted comment by other user', () {
        final actions = CommentPopupMenuHelper.getAvailableActions(
          commentUserId: 'user-1',
          currentUserId: 'user-2',
          deletedAt: DateTime(2024, 1, 1),
        );
        expect(actions, isEmpty);
      });

      test('returns empty when not logged in (null currentUserId)', () {
        final actions = CommentPopupMenuHelper.getAvailableActions(
          commentUserId: 'user-1',
          currentUserId: null,
          deletedAt: null,
        );
        expect(actions, isEmpty);
      });

      test('delete and report are mutually exclusive', () {
        // Own comment: only delete
        final ownActions = CommentPopupMenuHelper.getAvailableActions(
          commentUserId: 'user-1',
          currentUserId: 'user-1',
          deletedAt: null,
        );
        expect(ownActions.contains(CommentMenuAction.delete), isTrue);
        expect(ownActions.contains(CommentMenuAction.report), isFalse);

        // Other's comment: only report
        final otherActions = CommentPopupMenuHelper.getAvailableActions(
          commentUserId: 'user-1',
          currentUserId: 'user-2',
          deletedAt: null,
        );
        expect(otherActions.contains(CommentMenuAction.delete), isFalse);
        expect(otherActions.contains(CommentMenuAction.report), isTrue);
      });
    });
  });

  group('CommentMenuAction', () {
    test('has expected values', () {
      expect(CommentMenuAction.values.length, 2);
      expect(CommentMenuAction.values, contains(CommentMenuAction.delete));
      expect(CommentMenuAction.values, contains(CommentMenuAction.report));
    });
  });
}

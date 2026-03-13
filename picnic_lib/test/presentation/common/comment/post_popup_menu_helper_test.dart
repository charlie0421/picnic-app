import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/common/comment/post_popup_menu_helper.dart';

void main() {
  group('PostPopupMenuHelper', () {
    group('canDeletePost', () {
      test('returns true when user is post author and not deleted', () {
        expect(
          PostPopupMenuHelper.canDeletePost(
            postUserId: 'user-1',
            currentUserId: 'user-1',
            deletedAt: null,
          ),
          isTrue,
        );
      });

      test('returns false when user is not post author', () {
        expect(
          PostPopupMenuHelper.canDeletePost(
            postUserId: 'user-1',
            currentUserId: 'user-2',
            deletedAt: null,
          ),
          isFalse,
        );
      });

      test('returns false when post is already deleted', () {
        expect(
          PostPopupMenuHelper.canDeletePost(
            postUserId: 'user-1',
            currentUserId: 'user-1',
            deletedAt: DateTime(2024, 1, 1),
          ),
          isFalse,
        );
      });

      test('returns false when currentUserId is null', () {
        expect(
          PostPopupMenuHelper.canDeletePost(
            postUserId: 'user-1',
            currentUserId: null,
            deletedAt: null,
          ),
          isFalse,
        );
      });

      test('returns false when both userIds are null', () {
        expect(
          PostPopupMenuHelper.canDeletePost(
            postUserId: null,
            currentUserId: null,
            deletedAt: null,
          ),
          isFalse,
        );
      });

      test('returns false when postUserId is null but currentUserId is set', () {
        expect(
          PostPopupMenuHelper.canDeletePost(
            postUserId: null,
            currentUserId: 'user-1',
            deletedAt: null,
          ),
          isFalse,
        );
      });
    });

    group('canReportPost', () {
      test('returns true when user is not post author and not deleted', () {
        expect(
          PostPopupMenuHelper.canReportPost(
            postUserId: 'user-1',
            currentUserId: 'user-2',
            deletedAt: null,
          ),
          isTrue,
        );
      });

      test('returns false when user is post author', () {
        expect(
          PostPopupMenuHelper.canReportPost(
            postUserId: 'user-1',
            currentUserId: 'user-1',
            deletedAt: null,
          ),
          isFalse,
        );
      });

      test('returns false when post is deleted', () {
        expect(
          PostPopupMenuHelper.canReportPost(
            postUserId: 'user-1',
            currentUserId: 'user-2',
            deletedAt: DateTime(2024, 1, 1),
          ),
          isFalse,
        );
      });

      test('returns false when currentUserId is null', () {
        expect(
          PostPopupMenuHelper.canReportPost(
            postUserId: 'user-1',
            currentUserId: null,
            deletedAt: null,
          ),
          isFalse,
        );
      });

      test('returns true when postUserId is null but currentUserId is set', () {
        expect(
          PostPopupMenuHelper.canReportPost(
            postUserId: null,
            currentUserId: 'user-1',
            deletedAt: null,
          ),
          isTrue,
        );
      });
    });

    group('getAvailableActions', () {
      test('returns delete for own non-deleted post', () {
        final actions = PostPopupMenuHelper.getAvailableActions(
          postUserId: 'user-1',
          currentUserId: 'user-1',
          deletedAt: null,
        );
        expect(actions, [PostMenuAction.delete]);
      });

      test('returns report for other user non-deleted post', () {
        final actions = PostPopupMenuHelper.getAvailableActions(
          postUserId: 'user-1',
          currentUserId: 'user-2',
          deletedAt: null,
        );
        expect(actions, [PostMenuAction.report]);
      });

      test('returns empty for deleted post', () {
        final actions = PostPopupMenuHelper.getAvailableActions(
          postUserId: 'user-1',
          currentUserId: 'user-1',
          deletedAt: DateTime(2024, 1, 1),
        );
        expect(actions, isEmpty);
      });

      test('returns empty when not logged in', () {
        final actions = PostPopupMenuHelper.getAvailableActions(
          postUserId: 'user-1',
          currentUserId: null,
          deletedAt: null,
        );
        expect(actions, isEmpty);
      });

      test('delete and report are mutually exclusive', () {
        final ownActions = PostPopupMenuHelper.getAvailableActions(
          postUserId: 'user-1',
          currentUserId: 'user-1',
          deletedAt: null,
        );
        expect(ownActions.contains(PostMenuAction.delete), isTrue);
        expect(ownActions.contains(PostMenuAction.report), isFalse);

        final otherActions = PostPopupMenuHelper.getAvailableActions(
          postUserId: 'user-1',
          currentUserId: 'user-2',
          deletedAt: null,
        );
        expect(otherActions.contains(PostMenuAction.delete), isFalse);
        expect(otherActions.contains(PostMenuAction.report), isTrue);
      });
    });

    group('resolveMenuAction', () {
      test('returns report_and_refresh for Report with refresh', () {
        expect(
          PostPopupMenuHelper.resolveMenuAction(
            selectedValue: 'Report',
            hasReportFunction: true,
            hasDeleteFunction: false,
            hasRefreshFunction: true,
          ),
          'report_and_refresh',
        );
      });

      test('returns report for Report without refresh', () {
        expect(
          PostPopupMenuHelper.resolveMenuAction(
            selectedValue: 'Report',
            hasReportFunction: true,
            hasDeleteFunction: false,
            hasRefreshFunction: false,
          ),
          'report',
        );
      });

      test('returns delete for Delete action', () {
        expect(
          PostPopupMenuHelper.resolveMenuAction(
            selectedValue: 'Delete',
            hasReportFunction: false,
            hasDeleteFunction: true,
            hasRefreshFunction: false,
          ),
          'delete',
        );
      });

      test('returns null for Report without report function', () {
        expect(
          PostPopupMenuHelper.resolveMenuAction(
            selectedValue: 'Report',
            hasReportFunction: false,
            hasDeleteFunction: false,
            hasRefreshFunction: false,
          ),
          isNull,
        );
      });

      test('returns null for unknown action', () {
        expect(
          PostPopupMenuHelper.resolveMenuAction(
            selectedValue: 'Unknown',
            hasReportFunction: true,
            hasDeleteFunction: true,
            hasRefreshFunction: true,
          ),
          isNull,
        );
      });
    });
  });

  group('PostMenuAction', () {
    test('has expected values', () {
      expect(PostMenuAction.values.length, 2);
      expect(PostMenuAction.values, contains(PostMenuAction.delete));
      expect(PostMenuAction.values, contains(PostMenuAction.report));
    });
  });
}

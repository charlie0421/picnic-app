import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/presentation/common/comment/comment_item_helper.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Status flags
  // ---------------------------------------------------------------------------
  group('CommentItemHelper - status flags', () {
    group('isReportedByMe', () {
      test('returns true when flag is true', () {
        expect(
          CommentItemHelper.isReportedByMe(isReportedByMe: true),
          isTrue,
        );
      });

      test('returns false when flag is false', () {
        expect(
          CommentItemHelper.isReportedByMe(isReportedByMe: false),
          isFalse,
        );
      });

      test('returns false when flag is null', () {
        expect(
          CommentItemHelper.isReportedByMe(isReportedByMe: null),
          isFalse,
        );
      });
    });

    group('isBlindedByAdmin', () {
      test('returns true when flag is true', () {
        expect(
          CommentItemHelper.isBlindedByAdmin(isBlindedByAdmin: true),
          isTrue,
        );
      });

      test('returns false when flag is false', () {
        expect(
          CommentItemHelper.isBlindedByAdmin(isBlindedByAdmin: false),
          isFalse,
        );
      });

      test('returns false when flag is null', () {
        expect(
          CommentItemHelper.isBlindedByAdmin(isBlindedByAdmin: null),
          isFalse,
        );
      });
    });

    group('isDeleted', () {
      test('returns true when deletedAt is set', () {
        expect(
          CommentItemHelper.isDeleted(deletedAt: DateTime(2024, 1, 1)),
          isTrue,
        );
      });

      test('returns false when deletedAt is null', () {
        expect(
          CommentItemHelper.isDeleted(deletedAt: null),
          isFalse,
        );
      });
    });

    group('isHidden', () {
      test('returns true when reported by me', () {
        expect(
          CommentItemHelper.isHidden(
            isReportedByMe: true,
            isBlindedByAdmin: false,
          ),
          isTrue,
        );
      });

      test('returns true when blinded by admin', () {
        expect(
          CommentItemHelper.isHidden(
            isReportedByMe: false,
            isBlindedByAdmin: true,
          ),
          isTrue,
        );
      });

      test('returns true when both reported and blinded', () {
        expect(
          CommentItemHelper.isHidden(
            isReportedByMe: true,
            isBlindedByAdmin: true,
          ),
          isTrue,
        );
      });

      test('returns false when neither reported nor blinded', () {
        expect(
          CommentItemHelper.isHidden(
            isReportedByMe: false,
            isBlindedByAdmin: false,
          ),
          isFalse,
        );
      });

      test('returns false when both null', () {
        expect(
          CommentItemHelper.isHidden(
            isReportedByMe: null,
            isBlindedByAdmin: null,
          ),
          isFalse,
        );
      });

      test('returns true when reported is true and blinded is null', () {
        expect(
          CommentItemHelper.isHidden(
            isReportedByMe: true,
            isBlindedByAdmin: null,
          ),
          isTrue,
        );
      });

      test('returns true when reported is null and blinded is true', () {
        expect(
          CommentItemHelper.isHidden(
            isReportedByMe: null,
            isBlindedByAdmin: true,
          ),
          isTrue,
        );
      });
    });
  });

  // ---------------------------------------------------------------------------
  // Author display name
  // ---------------------------------------------------------------------------
  group('CommentItemHelper - resolveAuthorName', () {
    test('returns nickname when present', () {
      expect(
        CommentItemHelper.resolveAuthorName(nickname: 'Alice'),
        'Alice',
      );
    });

    test('returns empty string when nickname is null', () {
      expect(
        CommentItemHelper.resolveAuthorName(nickname: null),
        '',
      );
    });

    test('returns empty string when nickname is empty', () {
      expect(
        CommentItemHelper.resolveAuthorName(nickname: ''),
        '',
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Translation state
  // ---------------------------------------------------------------------------
  group('CommentItemHelper - isTranslationAvailable', () {
    test('returns true when content has current locale and language differs', () {
      expect(
        CommentItemHelper.isTranslationAvailable(
          content: {'ko': 'hello', 'en': 'hello-en'},
          currentLocale: 'en',
          commentLocale: 'ko',
        ),
        isTrue,
      );
    });

    test('returns false when content does not have current locale', () {
      expect(
        CommentItemHelper.isTranslationAvailable(
          content: {'ko': 'hello'},
          currentLocale: 'en',
          commentLocale: 'ko',
        ),
        isFalse,
      );
    });

    test('returns false when current locale equals comment locale', () {
      expect(
        CommentItemHelper.isTranslationAvailable(
          content: {'ko': 'hello'},
          currentLocale: 'ko',
          commentLocale: 'ko',
        ),
        isFalse,
      );
    });

    test('returns false when content is null', () {
      expect(
        CommentItemHelper.isTranslationAvailable(
          content: null,
          currentLocale: 'en',
          commentLocale: 'ko',
        ),
        isFalse,
      );
    });

    test('returns false when content is empty', () {
      expect(
        CommentItemHelper.isTranslationAvailable(
          content: {},
          currentLocale: 'en',
          commentLocale: 'ko',
        ),
        isFalse,
      );
    });

    test('defaults commentLocale to ko when null', () {
      expect(
        CommentItemHelper.isTranslationAvailable(
          content: {'ko': 'hello', 'en': 'hi'},
          currentLocale: 'en',
          commentLocale: null,
        ),
        isTrue,
      );
    });

    test('returns false when commentLocale is null and currentLocale is ko', () {
      expect(
        CommentItemHelper.isTranslationAvailable(
          content: {'ko': 'hello'},
          currentLocale: 'ko',
          commentLocale: null,
        ),
        isFalse,
      );
    });
  });

  group('CommentItemHelper - isDifferentLanguage', () {
    test('returns true when locales differ', () {
      expect(
        CommentItemHelper.isDifferentLanguage(
          currentLocale: 'en',
          commentLocale: 'ko',
        ),
        isTrue,
      );
    });

    test('returns false when locales match', () {
      expect(
        CommentItemHelper.isDifferentLanguage(
          currentLocale: 'ko',
          commentLocale: 'ko',
        ),
        isFalse,
      );
    });

    test('defaults to ko when commentLocale is null', () {
      expect(
        CommentItemHelper.isDifferentLanguage(
          currentLocale: 'ko',
          commentLocale: null,
        ),
        isFalse,
      );
    });

    test('returns true when commentLocale is null and currentLocale is not ko', () {
      expect(
        CommentItemHelper.isDifferentLanguage(
          currentLocale: 'en',
          commentLocale: null,
        ),
        isTrue,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Display content resolution
  // ---------------------------------------------------------------------------
  group('CommentItemHelper - resolveDisplayContent', () {
    const hiddenPlaceholder = '(reported comment)';
    const deletedPlaceholder = '(deleted comment)';

    test('returns hidden placeholder when reported by me', () {
      expect(
        CommentItemHelper.resolveDisplayContent(
          content: {'ko': 'hello'},
          commentLocale: 'ko',
          currentLocale: 'ko',
          isTranslated: false,
          showOriginal: false,
          isReportedByMe: true,
          isBlindedByAdmin: false,
          deletedAt: null,
          hiddenPlaceholder: hiddenPlaceholder,
          deletedPlaceholder: deletedPlaceholder,
        ),
        hiddenPlaceholder,
      );
    });

    test('returns hidden placeholder when blinded by admin', () {
      expect(
        CommentItemHelper.resolveDisplayContent(
          content: {'ko': 'hello'},
          commentLocale: 'ko',
          currentLocale: 'ko',
          isTranslated: false,
          showOriginal: false,
          isReportedByMe: false,
          isBlindedByAdmin: true,
          deletedAt: null,
          hiddenPlaceholder: hiddenPlaceholder,
          deletedPlaceholder: deletedPlaceholder,
        ),
        hiddenPlaceholder,
      );
    });

    test('returns deleted placeholder when deleted', () {
      expect(
        CommentItemHelper.resolveDisplayContent(
          content: {'ko': 'hello'},
          commentLocale: 'ko',
          currentLocale: 'ko',
          isTranslated: false,
          showOriginal: false,
          isReportedByMe: false,
          isBlindedByAdmin: false,
          deletedAt: DateTime(2024, 1, 1),
          hiddenPlaceholder: hiddenPlaceholder,
          deletedPlaceholder: deletedPlaceholder,
        ),
        deletedPlaceholder,
      );
    });

    test('hidden takes priority over deleted', () {
      expect(
        CommentItemHelper.resolveDisplayContent(
          content: {'ko': 'hello'},
          commentLocale: 'ko',
          currentLocale: 'ko',
          isTranslated: false,
          showOriginal: false,
          isReportedByMe: true,
          isBlindedByAdmin: false,
          deletedAt: DateTime(2024, 1, 1),
          hiddenPlaceholder: hiddenPlaceholder,
          deletedPlaceholder: deletedPlaceholder,
        ),
        hiddenPlaceholder,
      );
    });

    test('returns empty string when content is null', () {
      expect(
        CommentItemHelper.resolveDisplayContent(
          content: null,
          commentLocale: 'ko',
          currentLocale: 'ko',
          isTranslated: false,
          showOriginal: false,
          isReportedByMe: false,
          isBlindedByAdmin: false,
          deletedAt: null,
          hiddenPlaceholder: hiddenPlaceholder,
          deletedPlaceholder: deletedPlaceholder,
        ),
        '',
      );
    });

    test('returns empty string when content is empty map', () {
      expect(
        CommentItemHelper.resolveDisplayContent(
          content: {},
          commentLocale: 'ko',
          currentLocale: 'ko',
          isTranslated: false,
          showOriginal: false,
          isReportedByMe: false,
          isBlindedByAdmin: false,
          deletedAt: null,
          hiddenPlaceholder: hiddenPlaceholder,
          deletedPlaceholder: deletedPlaceholder,
        ),
        '',
      );
    });

    test('returns original text when showOriginal is true', () {
      expect(
        CommentItemHelper.resolveDisplayContent(
          content: {'ko': 'original', 'en': 'translated'},
          commentLocale: 'ko',
          currentLocale: 'en',
          isTranslated: true,
          showOriginal: true,
          isReportedByMe: false,
          isBlindedByAdmin: false,
          deletedAt: null,
          hiddenPlaceholder: hiddenPlaceholder,
          deletedPlaceholder: deletedPlaceholder,
        ),
        'original',
      );
    });

    test('returns original text when not translated', () {
      expect(
        CommentItemHelper.resolveDisplayContent(
          content: {'ko': 'original'},
          commentLocale: 'ko',
          currentLocale: 'en',
          isTranslated: false,
          showOriginal: false,
          isReportedByMe: false,
          isBlindedByAdmin: false,
          deletedAt: null,
          hiddenPlaceholder: hiddenPlaceholder,
          deletedPlaceholder: deletedPlaceholder,
        ),
        'original',
      );
    });

    test('returns translated text when translated and not showing original', () {
      expect(
        CommentItemHelper.resolveDisplayContent(
          content: {'ko': 'original', 'en': 'translated'},
          commentLocale: 'ko',
          currentLocale: 'en',
          isTranslated: true,
          showOriginal: false,
          isReportedByMe: false,
          isBlindedByAdmin: false,
          deletedAt: null,
          hiddenPlaceholder: hiddenPlaceholder,
          deletedPlaceholder: deletedPlaceholder,
        ),
        'translated',
      );
    });

    test('falls back to commentLocale when currentLocale key missing', () {
      expect(
        CommentItemHelper.resolveDisplayContent(
          content: {'ko': 'original'},
          commentLocale: 'ko',
          currentLocale: 'en',
          isTranslated: true,
          showOriginal: false,
          isReportedByMe: false,
          isBlindedByAdmin: false,
          deletedAt: null,
          hiddenPlaceholder: hiddenPlaceholder,
          deletedPlaceholder: deletedPlaceholder,
        ),
        'original',
      );
    });

    test('falls back to first value when commentLocale key missing', () {
      expect(
        CommentItemHelper.resolveDisplayContent(
          content: {'ja': 'japanese'},
          commentLocale: 'ko',
          currentLocale: 'en',
          isTranslated: false,
          showOriginal: false,
          isReportedByMe: false,
          isBlindedByAdmin: false,
          deletedAt: null,
          hiddenPlaceholder: hiddenPlaceholder,
          deletedPlaceholder: deletedPlaceholder,
        ),
        'japanese',
      );
    });

    test('defaults commentLocale to ko when null', () {
      expect(
        CommentItemHelper.resolveDisplayContent(
          content: {'ko': 'korean text'},
          commentLocale: null,
          currentLocale: 'ko',
          isTranslated: false,
          showOriginal: false,
          isReportedByMe: false,
          isBlindedByAdmin: false,
          deletedAt: null,
          hiddenPlaceholder: hiddenPlaceholder,
          deletedPlaceholder: deletedPlaceholder,
        ),
        'korean text',
      );
    });
  });

  // ---------------------------------------------------------------------------
  // shouldShowTranslatedLabel
  // ---------------------------------------------------------------------------
  group('CommentItemHelper - shouldShowTranslatedLabel', () {
    test('returns true when translated, has locale key, different language, not showing original', () {
      expect(
        CommentItemHelper.shouldShowTranslatedLabel(
          content: {'ko': 'original', 'en': 'translated'},
          commentLocale: 'ko',
          currentLocale: 'en',
          isTranslated: true,
          showOriginal: false,
        ),
        isTrue,
      );
    });

    test('returns false when not translated', () {
      expect(
        CommentItemHelper.shouldShowTranslatedLabel(
          content: {'ko': 'original', 'en': 'translated'},
          commentLocale: 'ko',
          currentLocale: 'en',
          isTranslated: false,
          showOriginal: false,
        ),
        isFalse,
      );
    });

    test('returns false when content is null', () {
      expect(
        CommentItemHelper.shouldShowTranslatedLabel(
          content: null,
          commentLocale: 'ko',
          currentLocale: 'en',
          isTranslated: true,
          showOriginal: false,
        ),
        isFalse,
      );
    });

    test('returns false when content does not contain currentLocale', () {
      expect(
        CommentItemHelper.shouldShowTranslatedLabel(
          content: {'ko': 'original'},
          commentLocale: 'ko',
          currentLocale: 'en',
          isTranslated: true,
          showOriginal: false,
        ),
        isFalse,
      );
    });

    test('returns false when currentLocale equals commentLocale', () {
      expect(
        CommentItemHelper.shouldShowTranslatedLabel(
          content: {'ko': 'original'},
          commentLocale: 'ko',
          currentLocale: 'ko',
          isTranslated: true,
          showOriginal: false,
        ),
        isFalse,
      );
    });

    test('returns false when showOriginal is true', () {
      expect(
        CommentItemHelper.shouldShowTranslatedLabel(
          content: {'ko': 'original', 'en': 'translated'},
          commentLocale: 'ko',
          currentLocale: 'en',
          isTranslated: true,
          showOriginal: true,
        ),
        isFalse,
      );
    });

    test('defaults commentLocale to ko when null', () {
      expect(
        CommentItemHelper.shouldShowTranslatedLabel(
          content: {'ko': 'original', 'en': 'translated'},
          commentLocale: null,
          currentLocale: 'en',
          isTranslated: true,
          showOriginal: false,
        ),
        isTrue,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Reply / nesting
  // ---------------------------------------------------------------------------
  group('CommentItemHelper - nesting', () {
    group('isTopLevelComment', () {
      test('returns true when parentCommentId is null', () {
        expect(
          CommentItemHelper.isTopLevelComment(parentCommentId: null),
          isTrue,
        );
      });

      test('returns false when parentCommentId is set', () {
        expect(
          CommentItemHelper.isTopLevelComment(parentCommentId: 'parent-1'),
          isFalse,
        );
      });

      test('returns false when parentCommentId is empty string', () {
        expect(
          CommentItemHelper.isTopLevelComment(parentCommentId: ''),
          isFalse,
        );
      });
    });

    group('shouldShowReplyCounter', () {
      test('returns true for top-level comment', () {
        expect(
          CommentItemHelper.shouldShowReplyCounter(parentCommentId: null),
          isTrue,
        );
      });

      test('returns false for reply comment', () {
        expect(
          CommentItemHelper.shouldShowReplyCounter(parentCommentId: 'parent-1'),
          isFalse,
        );
      });
    });
  });

  // ---------------------------------------------------------------------------
  // Translate button mode
  // ---------------------------------------------------------------------------
  group('CommentItemHelper - resolveTranslateButtonMode', () {
    test('returns hidden when same language', () {
      expect(
        CommentItemHelper.resolveTranslateButtonMode(
          content: {'ko': 'hello'},
          commentLocale: 'ko',
          currentLocale: 'ko',
          showOriginal: false,
        ),
        TranslateButtonMode.hidden,
      );
    });

    test('returns hidden when commentLocale is null and currentLocale is ko', () {
      expect(
        CommentItemHelper.resolveTranslateButtonMode(
          content: {'ko': 'hello'},
          commentLocale: null,
          currentLocale: 'ko',
          showOriginal: false,
        ),
        TranslateButtonMode.hidden,
      );
    });

    test('returns translate when no translation exists', () {
      expect(
        CommentItemHelper.resolveTranslateButtonMode(
          content: {'ko': 'hello'},
          commentLocale: 'ko',
          currentLocale: 'en',
          showOriginal: false,
        ),
        TranslateButtonMode.translate,
      );
    });

    test('returns showOriginal when translation exists and showing translated', () {
      expect(
        CommentItemHelper.resolveTranslateButtonMode(
          content: {'ko': 'hello', 'en': 'hi'},
          commentLocale: 'ko',
          currentLocale: 'en',
          showOriginal: false,
        ),
        TranslateButtonMode.showOriginal,
      );
    });

    test('returns showTranslation when translation exists and showing original', () {
      expect(
        CommentItemHelper.resolveTranslateButtonMode(
          content: {'ko': 'hello', 'en': 'hi'},
          commentLocale: 'ko',
          currentLocale: 'en',
          showOriginal: true,
        ),
        TranslateButtonMode.showTranslation,
      );
    });

    test('returns translate when content is null', () {
      expect(
        CommentItemHelper.resolveTranslateButtonMode(
          content: null,
          commentLocale: 'ko',
          currentLocale: 'en',
          showOriginal: false,
        ),
        TranslateButtonMode.translate,
      );
    });

    test('returns translate when content is empty', () {
      expect(
        CommentItemHelper.resolveTranslateButtonMode(
          content: {},
          commentLocale: 'ko',
          currentLocale: 'en',
          showOriginal: false,
        ),
        TranslateButtonMode.translate,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Content style
  // ---------------------------------------------------------------------------
  group('CommentItemHelper - resolveContentStyle', () {
    test('returns reported when reported by me', () {
      expect(
        CommentItemHelper.resolveContentStyle(
          isReportedByMe: true,
          isBlindedByAdmin: false,
          deletedAt: null,
        ),
        CommentContentStyle.reported,
      );
    });

    test('returns reported when blinded by admin', () {
      expect(
        CommentItemHelper.resolveContentStyle(
          isReportedByMe: false,
          isBlindedByAdmin: true,
          deletedAt: null,
        ),
        CommentContentStyle.reported,
      );
    });

    test('returns deleted when deleted', () {
      expect(
        CommentItemHelper.resolveContentStyle(
          isReportedByMe: false,
          isBlindedByAdmin: false,
          deletedAt: DateTime(2024, 1, 1),
        ),
        CommentContentStyle.deleted,
      );
    });

    test('reported takes priority over deleted', () {
      expect(
        CommentItemHelper.resolveContentStyle(
          isReportedByMe: true,
          isBlindedByAdmin: false,
          deletedAt: DateTime(2024, 1, 1),
        ),
        CommentContentStyle.reported,
      );
    });

    test('returns normal for regular comment', () {
      expect(
        CommentItemHelper.resolveContentStyle(
          isReportedByMe: false,
          isBlindedByAdmin: false,
          deletedAt: null,
        ),
        CommentContentStyle.normal,
      );
    });

    test('returns normal when flags are null', () {
      expect(
        CommentItemHelper.resolveContentStyle(
          isReportedByMe: null,
          isBlindedByAdmin: null,
          deletedAt: null,
        ),
        CommentContentStyle.normal,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // Delete / translation guards
  // ---------------------------------------------------------------------------
  group('CommentItemHelper - action guards', () {
    group('canProceedWithDelete', () {
      test('returns true when not deleting and not processing', () {
        expect(
          CommentItemHelper.canProceedWithDelete(
            isDeleting: false,
            isProcessing: false,
          ),
          isTrue,
        );
      });

      test('returns false when deleting', () {
        expect(
          CommentItemHelper.canProceedWithDelete(
            isDeleting: true,
            isProcessing: false,
          ),
          isFalse,
        );
      });

      test('returns false when processing', () {
        expect(
          CommentItemHelper.canProceedWithDelete(
            isDeleting: false,
            isProcessing: true,
          ),
          isFalse,
        );
      });

      test('returns false when both deleting and processing', () {
        expect(
          CommentItemHelper.canProceedWithDelete(
            isDeleting: true,
            isProcessing: true,
          ),
          isFalse,
        );
      });
    });

    group('canProceedWithTranslation', () {
      test('returns true when not translating', () {
        expect(
          CommentItemHelper.canProceedWithTranslation(isTranslating: false),
          isTrue,
        );
      });

      test('returns false when translating', () {
        expect(
          CommentItemHelper.canProceedWithTranslation(isTranslating: true),
          isFalse,
        );
      });
    });
  });

  // ---------------------------------------------------------------------------
  // Enums
  // ---------------------------------------------------------------------------
  group('TranslateButtonMode', () {
    test('has expected values', () {
      expect(TranslateButtonMode.values.length, 4);
      expect(TranslateButtonMode.values, contains(TranslateButtonMode.hidden));
      expect(TranslateButtonMode.values, contains(TranslateButtonMode.translate));
      expect(TranslateButtonMode.values, contains(TranslateButtonMode.showOriginal));
      expect(TranslateButtonMode.values, contains(TranslateButtonMode.showTranslation));
    });
  });

  group('CommentContentStyle', () {
    test('has expected values', () {
      expect(CommentContentStyle.values.length, 3);
      expect(CommentContentStyle.values, contains(CommentContentStyle.normal));
      expect(CommentContentStyle.values, contains(CommentContentStyle.reported));
      expect(CommentContentStyle.values, contains(CommentContentStyle.deleted));
    });
  });
}

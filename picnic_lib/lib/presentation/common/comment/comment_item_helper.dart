/// Pure logic helpers extracted from CommentItem widget and its sub-widgets
/// (CommentContents, CommentActions, CommentHeader).
///
/// All methods are static and free of Flutter/widget dependencies so they
/// can be unit-tested without a widget harness.
class CommentItemHelper {
  CommentItemHelper._();

  // ---------------------------------------------------------------------------
  // Comment status flags
  // ---------------------------------------------------------------------------

  /// Whether the comment has been reported by the current user.
  static bool isReportedByMe({required bool? isReportedByMe}) {
    return isReportedByMe ?? false;
  }

  /// Whether the comment has been blinded (hidden) by an admin.
  static bool isBlindedByAdmin({required bool? isBlindedByAdmin}) {
    return isBlindedByAdmin ?? false;
  }

  /// Whether the comment is soft-deleted.
  static bool isDeleted({required DateTime? deletedAt}) {
    return deletedAt != null;
  }

  /// Whether the comment should be hidden from normal display
  /// (reported by me OR blinded by admin).
  static bool isHidden({
    required bool? isReportedByMe,
    required bool? isBlindedByAdmin,
  }) {
    return (isReportedByMe ?? false) || (isBlindedByAdmin ?? false);
  }

  // ---------------------------------------------------------------------------
  // Author display name
  // ---------------------------------------------------------------------------

  /// Returns the display name for the comment author.
  /// Falls back to an empty string when the nickname is null.
  static String resolveAuthorName({required String? nickname}) {
    return nickname ?? '';
  }

  // ---------------------------------------------------------------------------
  // Translation state
  // ---------------------------------------------------------------------------

  /// Determines whether a translation is available and applicable.
  ///
  /// A comment is considered "translated" when:
  /// 1. The content map contains an entry for [currentLocale], AND
  /// 2. [currentLocale] differs from the comment's original [commentLocale].
  static bool isTranslationAvailable({
    required Map<String, dynamic>? content,
    required String currentLocale,
    required String? commentLocale,
  }) {
    final locale = commentLocale ?? 'ko';
    final hasTranslation = content?.containsKey(currentLocale) ?? false;
    final isDifferentLanguage = currentLocale != locale;
    return hasTranslation && isDifferentLanguage;
  }

  /// Whether the comment is in a different language than the device locale.
  static bool isDifferentLanguage({
    required String currentLocale,
    required String? commentLocale,
  }) {
    return currentLocale != (commentLocale ?? 'ko');
  }

  // ---------------------------------------------------------------------------
  // Display content resolution
  // ---------------------------------------------------------------------------

  /// Resolves which text content to display for a comment.
  ///
  /// Priority:
  /// 1. If hidden (reported/blinded) -> [hiddenPlaceholder]
  /// 2. If deleted -> [deletedPlaceholder]
  /// 3. If content is null/empty -> empty string
  /// 4. If [showOriginal] is true, or translation is not available -> original text
  /// 5. Otherwise -> translated text
  static String resolveDisplayContent({
    required Map<String, dynamic>? content,
    required String? commentLocale,
    required String currentLocale,
    required bool isTranslated,
    required bool showOriginal,
    required bool? isReportedByMe,
    required bool? isBlindedByAdmin,
    required DateTime? deletedAt,
    required String hiddenPlaceholder,
    required String deletedPlaceholder,
  }) {
    if (isHidden(
      isReportedByMe: isReportedByMe,
      isBlindedByAdmin: isBlindedByAdmin,
    )) {
      return hiddenPlaceholder;
    }

    if (isDeleted(deletedAt: deletedAt)) {
      return deletedPlaceholder;
    }

    if (content == null || content.isEmpty) {
      return '';
    }

    final locale = commentLocale ?? 'ko';

    if (showOriginal || !isTranslated || !content.containsKey(currentLocale)) {
      return (content[locale] ?? content.values.first ?? '') as String;
    }

    return (content[currentLocale] ?? content[locale] ?? '') as String;
  }

  /// Whether the "(translated)" label should be shown beneath the content.
  static bool shouldShowTranslatedLabel({
    required Map<String, dynamic>? content,
    required String? commentLocale,
    required String currentLocale,
    required bool isTranslated,
    required bool showOriginal,
  }) {
    final locale = commentLocale ?? 'ko';
    return isTranslated &&
        content != null &&
        content.containsKey(currentLocale) &&
        currentLocale != locale &&
        !showOriginal;
  }

  // ---------------------------------------------------------------------------
  // Reply / nesting
  // ---------------------------------------------------------------------------

  /// Whether the comment is a top-level comment (not a reply).
  static bool isTopLevelComment({required String? parentCommentId}) {
    return parentCommentId == null;
  }

  /// Whether the reply counter should be visible.
  /// Only top-level comments show their reply count.
  static bool shouldShowReplyCounter({required String? parentCommentId}) {
    return isTopLevelComment(parentCommentId: parentCommentId);
  }

  // ---------------------------------------------------------------------------
  // Translation button mode
  // ---------------------------------------------------------------------------

  /// Determines which translation action to present to the user.
  ///
  /// Returns:
  /// - [TranslateButtonMode.hidden] when the comment locale matches the device locale
  /// - [TranslateButtonMode.translate] when no translation exists yet
  /// - [TranslateButtonMode.showOriginal] when a translation exists and is being shown
  /// - [TranslateButtonMode.showTranslation] when a translation exists but original is shown
  static TranslateButtonMode resolveTranslateButtonMode({
    required Map<String, dynamic>? content,
    required String? commentLocale,
    required String currentLocale,
    required bool showOriginal,
  }) {
    final locale = commentLocale ?? 'ko';

    if (currentLocale == locale) {
      return TranslateButtonMode.hidden;
    }

    final hasTranslation = content?.containsKey(currentLocale) ?? false;

    if (hasTranslation) {
      return showOriginal
          ? TranslateButtonMode.showTranslation
          : TranslateButtonMode.showOriginal;
    }

    return TranslateButtonMode.translate;
  }

  // ---------------------------------------------------------------------------
  // Comment content style hint
  // ---------------------------------------------------------------------------

  /// Returns a [CommentContentStyle] hint indicating how the comment text
  /// should be styled (e.g. highlighted for reported, greyed for deleted).
  static CommentContentStyle resolveContentStyle({
    required bool? isReportedByMe,
    required bool? isBlindedByAdmin,
    required DateTime? deletedAt,
  }) {
    if (isHidden(
      isReportedByMe: isReportedByMe,
      isBlindedByAdmin: isBlindedByAdmin,
    )) {
      return CommentContentStyle.reported;
    }
    if (isDeleted(deletedAt: deletedAt)) {
      return CommentContentStyle.deleted;
    }
    return CommentContentStyle.normal;
  }

  // ---------------------------------------------------------------------------
  // Delete guard
  // ---------------------------------------------------------------------------

  /// Whether a delete action should be allowed to proceed.
  /// Returns false if already deleting or processing.
  static bool canProceedWithDelete({
    required bool isDeleting,
    required bool isProcessing,
  }) {
    return !isDeleting && !isProcessing;
  }

  /// Whether a translation request should be allowed to proceed.
  static bool canProceedWithTranslation({required bool isTranslating}) {
    return !isTranslating;
  }
}

/// Describes which translate button variant to show.
enum TranslateButtonMode {
  /// Do not show any translate button (same language).
  hidden,

  /// Show "Translate" — no translation available yet.
  translate,

  /// Show "Show original" — translation is currently displayed.
  showOriginal,

  /// Show "Show translation" — original is currently displayed.
  showTranslation,
}

/// Style hint for comment content text.
enum CommentContentStyle {
  /// Normal visible comment.
  normal,

  /// Comment hidden due to report / admin blind.
  reported,

  /// Soft-deleted comment.
  deleted,
}

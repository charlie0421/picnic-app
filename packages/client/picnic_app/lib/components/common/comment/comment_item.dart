// comment_item.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:picnic_app/components/common/avatar_container.dart';
import 'package:picnic_app/components/common/comment/comment_actions.dart';
import 'package:picnic_app/components/common/comment/comment_contents.dart';
import 'package:picnic_app/components/common/comment/comment_header.dart';
import 'package:picnic_app/components/common/comment/comment_popup_menu.dart';
import 'package:picnic_app/config/environment.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/models/common/comment.dart';
import 'package:picnic_app/providers/community/comments_provider.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/deepl_translate_service.dart';
import 'package:picnic_app/util/i18n.dart';
import 'package:picnic_app/util/logger.dart';
import 'package:picnic_app/util/snackbar_util.dart';
import 'package:picnic_app/util/ui.dart';

class CommentItem extends ConsumerStatefulWidget {
  const CommentItem({
    super.key,
    required this.pagingController,
    required this.commentModel,
    required this.postId,
    this.shouldHighlight = false,
    this.showReplyButton = true,
    this.openCommentsModal,
    this.openReportModal,
    this.onLike,
    this.onReply,
    this.onDelete,
    this.onReport,
  });

  final PagingController<int, CommentModel>? pagingController;
  final CommentModel commentModel;
  final String postId;
  final bool shouldHighlight;
  final bool showReplyButton;
  final Function? openCommentsModal;
  final Function? openReportModal;
  final Function()? onLike;
  final Function()? onReply;
  final Function()? onDelete;
  final Function(String, String)? onReport;

  @override
  ConsumerState<CommentItem> createState() => _CommentItemState();
}

class _CommentItemState extends ConsumerState<CommentItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _animation;
  Color _backgroundColor = Colors.white;
  bool _isDeleting = false;
  bool _isProcessing = false;
  late bool _isTranslated = false;
  bool _isTranslating = false;
  bool _showOriginal = false;

  @override
  void initState() {
    super.initState();
    _initializeTranslationState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _animation = Tween<double>(begin: 1, end: .95).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _setupAnimationListener();
    _handleInitialHighlight();
  }

  void _initializeTranslationState() {
    final currentLocale = getLocaleLanguage();
    final hasTranslation =
        widget.commentModel.content?.containsKey(currentLocale) ?? false;
    final isDifferentLanguage =
        currentLocale != (widget.commentModel.locale ?? 'ko');

    _isTranslated = hasTranslation && isDifferentLanguage;
    _showOriginal = false;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeTranslationState();
  }

  void _setupAnimationListener() {
    _animationController.addStatusListener((status) {
      if (!mounted) return;

      if (status == AnimationStatus.forward) {
        setState(() => _backgroundColor = AppColors.grey100);
      } else if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        setState(() => _backgroundColor = Colors.white);
      }
    });
  }

  void _handleInitialHighlight() {
    if (widget.shouldHighlight) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _animationController.forward().then((_) {
          if (mounted) {
            _animationController.reverse();
          }
        });
      });
    }
  }

  void _toggleOriginal() {
    setState(() {
      _showOriginal = !_showOriginal;
    });
  }

  Future<void> _handleDelete() async {
    if (_isDeleting || _isProcessing) return;

    setState(() {
      _isDeleting = true;
      _isProcessing = true;
    });

    try {
      await _animationController.forward();

      if (!mounted) return;

      await Future.delayed(const Duration(milliseconds: 300));
      widget.onDelete?.call();

      if (mounted) {
        widget.pagingController?.refresh();
      }
    } catch (e, s) {
      logger.e('exception:', error: e, stackTrace: s);
      if (mounted) {
        SnackbarUtil().showSnackbar(S.of(context).post_comment_delete_fail);
      }
      rethrow;
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _handleTranslation(String currentLocale) async {
    if (_isTranslating) return;

    setState(() {
      _isTranslating = true;
    });

    try {
      final translationService = DeepLTranslationService(
        apiKey: Environment.deepLApiKey,
      );

      logger.i('widget.commentModel.content: ${widget.commentModel.content}');
      logger.i('widget.commentModel.locale: ${widget.commentModel.locale}');
      final translatedText = await translationService.translateText(
        widget.commentModel.content![widget.commentModel.locale]!,
        widget.commentModel.locale!,
        currentLocale,
      );

      if (!mounted) return;

      final translationNotifier = ref.read(
        commentTranslationNotifierProvider.notifier,
      );

      await translationNotifier.updateTranslation(
        widget.commentModel.commentId,
        currentLocale,
        translatedText,
      );

      setState(() {
        _isTranslated = !_isTranslated;
      });
    } catch (e, s) {
      logger.e('Translation error:', error: e, stackTrace: s);
      if (!mounted) return;

      SnackbarUtil().showSnackbar(
        S.of(context).post_comment_translate_fail,
        backgroundColor: Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isTranslating = false;
        });
      }
    }
  }

  Widget _buildProfileImage() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary500,
          width: 1,
        ),
      ),
      child: ProfileImageContainer(
        avatarUrl: widget.commentModel.user?.avatarUrl,
        borderRadius: 16,
        width: 32,
        height: 32,
      ),
    );
  }

  Widget _buildCommentContent() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CommentHeader(item: widget.commentModel),
          const SizedBox(height: 4),
          CommentContents(
            item: widget.commentModel,
            isTranslated: _isTranslated,
            showOriginal: _showOriginal,
          ),
          const SizedBox(height: 4),
          CommentActions(
            item: widget.commentModel,
            postId: widget.postId,
            showReplyButton: widget.showReplyButton,
            openCommentsModal: widget.openCommentsModal,
            onLike: widget.onLike,
            onReply: widget.onReply,
            isTranslating: _isTranslating,
            isTranslated: _isTranslated,
            showOriginal: _showOriginal,
            onTranslate: (currentLocale) => _handleTranslation(currentLocale),
            onToggleOriginal: _toggleOriginal,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    logger.i('CommentItem build');
    if (_isDeleting) {
      return const SizedBox.shrink();
    }

    return ScaleTransition(
      scale: _animation,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          border: Border.all(
            color: _backgroundColor,
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: _backgroundColor.withValues(alpha: 0.5),
              spreadRadius: 5,
              blurRadius: 7,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 16.cw,
            vertical: 8,
          ),
          width: getPlatformScreenSize(context).width,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProfileImage(),
              SizedBox(width: 10.cw),
              _buildCommentContent(),
              SizedBox(width: 10.cw),
              if (_isProcessing)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              else
                CommentPopupMenu(
                  postId: widget.postId,
                  comment: widget.commentModel,
                  refreshFunction: widget.pagingController?.refresh,
                  openReportModal: widget.openReportModal,
                  onDelete: _handleDelete,
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

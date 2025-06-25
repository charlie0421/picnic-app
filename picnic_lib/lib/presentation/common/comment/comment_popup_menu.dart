import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/snackbar_util.dart';
import 'package:picnic_lib/data/models/common/comment.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/presentation/common/navigator_key.dart';
import 'package:picnic_lib/presentation/dialogs/require_login_dialog.dart';
import 'package:picnic_lib/presentation/dialogs/simple_dialog.dart';
import 'package:picnic_lib/presentation/providers/community/comments_provider.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:picnic_lib/presentation/widgets/ui/pulse_loading_indicator.dart';
import 'package:picnic_lib/ui/style.dart';

class CommentPopupMenu extends ConsumerStatefulWidget {
  final String postId;
  final CommentModel comment;
  final Function? refreshFunction;
  final Function? openReportModal;
  final Function? onDelete;

  const CommentPopupMenu({
    super.key,
    required this.postId,
    required this.comment,
    this.refreshFunction,
    this.openReportModal,
    this.onDelete,
  });

  @override
  ConsumerState<CommentPopupMenu> createState() => _CommentPopupMenuState();
}

class _CommentPopupMenuState extends ConsumerState<CommentPopupMenu> {
  bool _isProcessing = false;

  Future<void> _handleDelete() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      showSimpleDialog(
        title: t('popup_label_delete'),
        content: t('post_comment_delete_confirm'),
        onOk: () async {
          try {
            final commentsNotifier = ref.read(
              commentsNotifierProvider(widget.postId, 1, 10).notifier,
            );
            await commentsNotifier.deleteComment(widget.comment.commentId);

            widget.onDelete?.call();

            if (widget.refreshFunction != null) {
              widget.refreshFunction!();
            }

            if (navigatorKey.currentContext != null) {
              Navigator.of(navigatorKey.currentContext!).pop();
            }
          } catch (e, s) {
            logger.e('exception:', error: e, stackTrace: s);

            if (mounted) {
              SnackbarUtil().showSnackbar(t('post_comment_delete_fail'));
            }
            rethrow;
          }
        },
        onCancel: () {
          Navigator.of(context).pop();
        },
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _handleReport() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      if (widget.openReportModal != null) {
        widget.openReportModal!(
          t('label_title_report'),
          widget.comment,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isProcessing) {
              return SizedBox(
          width: 20,
          height: 20,
          child: SmallPulseLoadingIndicator(
            iconColor: AppColors.primary500,
          ),
        );
    }

    return GestureDetector(
      onTap: () {
        if (!isSupabaseLoggedSafely) {
          showRequireLoginDialog();
          return;
        }
      },
      child: PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        enabled: isSupabaseLoggedSafely,
        onOpened: () {
          if (!isSupabaseLoggedSafely) {
            showRequireLoginDialog();
          }
        },
        onSelected: (String result) async {
          if (result == 'Report') {
            await _handleReport();
          } else if (result == 'Delete') {
            await _handleDelete();
          }
        },
        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
          if (_canDeleteComment())
            PopupMenuItem<String>(
              value: 'Delete',
              child: Text(t('popup_label_delete')),
            ),
          if (_canReportComment())
            PopupMenuItem<String>(
              value: 'Report',
              child: Text(t('label_title_report')),
            ),
        ],
        child: SvgPicture.asset(
          package: 'picnic_lib',
          'assets/icons/more_style=line.svg',
          width: 20,
          height: 20,
          colorFilter: ColorFilter.mode(
            Theme.of(context).primaryColor,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }

  bool _canDeleteComment() {
    return widget.comment.userId == supabase.auth.currentUser?.id &&
        widget.comment.deletedAt == null;
  }

  bool _canReportComment() {
    return widget.comment.userId != supabase.auth.currentUser?.id &&
        widget.comment.deletedAt == null;
  }
}

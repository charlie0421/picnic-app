import 'dart:io';

import 'package:picnic_lib/presentation/pages/my_page/qna/qna_media_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mime/mime.dart';
import 'package:picnic_lib/core/utils/date.dart';
import 'package:picnic_lib/data/models/qna/qna_attachment.dart';
import 'package:picnic_lib/data/models/qna/qna_message.dart';
import 'package:picnic_lib/data/models/qna/qna_thread.dart';
import 'package:picnic_lib/data/repositories/qna_repository.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/pages/my_page/qna/qna_full_screen_image_viewer.dart';
import 'package:picnic_lib/presentation/pages/my_page/qna/qna_video_player_page.dart';
import 'package:picnic_lib/presentation/widgets/loading_view.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:picnic_lib/presentation/widgets/media/video_thumbnail.dart';
import 'package:picnic_lib/presentation/widgets/media/image_thumbnail.dart';
import 'package:picnic_lib/core/utils/snackbar_util.dart';

class QnaThreadDetailPage extends ConsumerStatefulWidget {
  final QnaThread thread;

  const QnaThreadDetailPage({super.key, required this.thread});

  @override
  ConsumerState<QnaThreadDetailPage> createState() =>
      _QaThreadDetailPageState();
}

class _QaThreadDetailPageState extends ConsumerState<QnaThreadDetailPage> {
  final QnaRepository _repository = QnaRepository();
  final TextEditingController _messageController = TextEditingController();

  List<QnaMessage> _messages = [];
  List<File> _attachments = [];
  bool _isLoading = true;
  bool _isSending = false;
  bool _isAttaching = false;
  String? _errorMessage;
  String? _categoryLabel;
  static const int _maxFileSizeInBytes = 10 * 1024 * 1024; // 10MB

  @override
  void initState() {
    super.initState();
    _loadThreadDetails();
  }

  Future<void> _loadThreadDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final threadWithMessages = await _repository.getQaThreadById(
        widget.thread.id,
      );
      setState(() {
        _messages = threadWithMessages.messages;
        _categoryLabel = threadWithMessages.categoryLabel;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty && _attachments.isEmpty) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isSending = true;
    });

    final userId = Supabase.instance.client.auth.currentUser!.id;

    try {
      final newMessage = await _repository.createQaMessage(
        threadId: widget.thread.id,
        userId: userId,
        content: content,
        attachments: _attachments,
      );

      _messageController.clear();
      if (mounted) {
        setState(() {
          _messages.add(newMessage);
          _attachments = [];
        });

        SnackbarUtil().success(
          AppLocalizations.of(context).qna_message_sent_success,
          context: context,
        );
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtil().error(
          '${AppLocalizations.of(context).qna_message_sent_fail}: $e',
          context: context,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Future<void> _pickMedia() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _isAttaching = true;
    });
    try {
      final result = await pickQnaMedia(
        context: context,
        maxFileSizeInBytes: _maxFileSizeInBytes,
      );
      if (!mounted) return;
      setState(() {
        _attachments.addAll(result.selectedFiles);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isAttaching = false;
        });
      }
    }
  }

  void _removeAttachment(int index) {
    FocusScope.of(context).unfocus();
    setState(() {
      _attachments.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Stack(
        children: [
          Scaffold(
            appBar: AppBar(
              title: Text(
                widget.thread.title,
                style: getTextStyle(AppTypo.body14M, AppColors.grey900),
              ),
              backgroundColor: AppColors.grey00,
              elevation: 0,
              scrolledUnderElevation: 0,
              foregroundColor: AppColors.grey900,
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: _buildStatusChip(),
                ),
              ],
            ),
            body: Column(
              children: [
                if (_categoryLabel != null && _categoryLabel!.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.point500,
                              AppColors.point500.withValues(alpha: 0.85),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.point500.withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          _categoryLabel!,
                          style: getTextStyle(AppTypo.caption12B, Colors.white),
                        ),
                      ),
                    ),
                  ),
                Expanded(child: _buildBody()),
                _buildMessageInput(),
              ],
            ),
          ),
          if (_isSending || _isAttaching)
            Container(
              color: Colors.black.withAlpha(128),
              child: const Center(child: LoadingView()),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusChip() {
    final s = widget.thread.status.toUpperCase();
    late Color chipColor;
    late Color textColor;
    // Reuse existing i18n: open for RECEIVED/IN_PROGRESS, closed for RESOLVED
    final statusText = s == 'RESOLVED'
        ? AppLocalizations.of(context).qna_status_closed
        : AppLocalizations.of(context).qna_status_open;

    if (s == 'RESOLVED') {
      chipColor = AppColors.secondary500;
      textColor = AppColors.grey900;
    } else if (s == 'IN_PROGRESS') {
      chipColor = AppColors.primary500;
      textColor = Colors.white;
    } else {
      chipColor = AppColors.sub500;
      textColor = Colors.white;
    }

    return Chip(
      label: Text(
        statusText,
        style: getTextStyle(AppTypo.caption12M, textColor),
      ),
      backgroundColor: chipColor,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide.none,
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    }
    if (_messages.isEmpty) {
      return Center(
        child: Text(AppLocalizations.of(context).qna_no_answer_yet),
      );
    }
    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.all(8.0),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final reversedMessages = _messages.reversed.toList();
        final message = reversedMessages[index];

        bool showDateDivider = false;
        if (index == reversedMessages.length - 1) {
          showDateDivider = true;
        } else {
          final prevMessage = reversedMessages[index + 1];
          final currentMessageDate = message.createdAt.toLocal();
          final prevMessageDate = prevMessage.createdAt.toLocal();
          if (currentMessageDate.day != prevMessageDate.day ||
              currentMessageDate.month != prevMessageDate.month ||
              currentMessageDate.year != prevMessageDate.year) {
            showDateDivider = true;
          }
        }

        return Column(
          children: [
            if (showDateDivider) _buildDateDivider(message.createdAt.toLocal()),
            _buildMessageBubble(message),
          ],
        );
      },
    );
  }

  Widget _buildDateDivider(DateTime date) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        decoration: BoxDecoration(
          color: AppColors.grey300,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Text(
          DateFormat(
            'yyyy년 M월 d일',
            AppLocalizations.of(context).localeName,
          ).format(date),
          style: getTextStyle(AppTypo.caption12R, AppColors.grey900),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(QnaMessage message) {
    final isMyMessage =
        message.userId == Supabase.instance.client.auth.currentUser!.id;
    final hasText = message.content != null && message.content!.isNotEmpty;

    final attachments = _buildAttachments(message, hasText, isMyMessage);

    if (!hasText && attachments.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        alignment: isMyMessage ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          child: Column(
            crossAxisAlignment: isMyMessage
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: attachments,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      alignment: isMyMessage ? Alignment.centerRight : Alignment.centerLeft,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.0),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.7,
          ),
          color: isMyMessage ? AppColors.primary500 : AppColors.grey200,
          child: Column(
            crossAxisAlignment: isMyMessage
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasText)
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    message.content!,
                    style: getTextStyle(
                      AppTypo.body14R,
                      isMyMessage ? AppColors.grey00 : AppColors.grey900,
                    ),
                  ),
                ),
              ...attachments,
              if (hasText)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12.0, 4.0, 12.0, 8.0),
                  child: Text(
                    formatTimeAgo(context, message.createdAt.toLocal()),
                    style: getTextStyle(
                      AppTypo.caption12R,
                      isMyMessage
                          ? AppColors.grey00.withAlpha(204)
                          : AppColors.grey400,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildAttachments(
    QnaMessage message,
    bool hasText,
    bool isMyMessage,
  ) {
    return message.attachments.map((att) {
      final isImageByMime = att.fileType?.startsWith('image/') ?? false;
      final isImageByExtension = [
        'jpg',
        'jpeg',
        'png',
        'gif',
      ].any((ext) => att.fileName.toLowerCase().endsWith('.$ext'));
      final isImage = isImageByMime || isImageByExtension;
      final isVideo = att.fileType?.startsWith('video/') ?? false;

      if (isImage) {
        final imageWidget = _buildImageAttachment(
          att,
          message,
          hasText,
          isMyMessage,
        );
        return hasText
            ? Padding(
                padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 8.0),
                child: imageWidget,
              )
            : imageWidget;
      } else if (isVideo) {
        final videoWidget = _buildVideoAttachment(att);
        return hasText
            ? Padding(
                padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 8.0),
                child: videoWidget,
              )
            : videoWidget;
      } else {
        return InkWell(
          onTap: () {
            // TODO: Implement attachment download/view
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              att.fileName,
              style: const TextStyle(
                color: Colors.blue,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        );
      }
    }).toList();
  }

  Widget _buildImageAttachment(
    QnaAttachment att,
    QnaMessage message,
    bool hasText,
    bool isMyMessage,
  ) {
    final imageUrl = _getPublicUrl(att.filePath);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12.0),
      child: GestureDetector(
        onTap: () {
          final imageAttachments = message.attachments.where((attachment) {
            final isImageByMime =
                attachment.fileType?.startsWith('image/') ?? false;
            final isImageByExtension = [
              'jpg',
              'jpeg',
              'png',
              'gif',
            ].any((ext) => attachment.fileName.toLowerCase().endsWith('.$ext'));
            return isImageByMime || isImageByExtension;
          }).toList();
          final imageUrls = imageAttachments
              .map((a) => _getPublicUrl(a.filePath))
              .toList();
          final currentIndex = imageAttachments.indexOf(att);

          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => QnaFullScreenImageViewer(
                imageUrls: imageUrls,
                initialIndex: currentIndex,
              ),
            ),
          );
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            ImageThumbnailFromUrl(imageUrl: imageUrl, fit: BoxFit.cover),
            if (!hasText)
              Positioned(
                bottom: 4,
                right: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(178),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    formatTimeAgo(context, message.createdAt.toLocal()),
                    style: getTextStyle(
                      AppTypo.caption12R,
                      AppColors.grey00.withAlpha(204),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoAttachment(QnaAttachment att) {
    final videoUrl = _getPublicUrl(att.filePath);
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => QnaVideoPlayerPage(videoUrl: videoUrl),
          ),
        );
      },
      child: VideoThumbnailFromUrl(videoUrl: videoUrl),
    );
  }

  String _getPublicUrl(String path) {
    return _repository.getPublicUrl(path);
  }

  Widget _buildMessageInput() {
    final isThreadOpen = widget.thread.isOpen;

    if (!isThreadOpen) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.grey100,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withAlpha(25),
              spreadRadius: 1,
              blurRadius: 5,
            ),
          ],
        ),
        child: SafeArea(
          child: Text(
            AppLocalizations.of(context).qna_cannot_send_message_closed,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.grey500),
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(25),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_shouldShowAutoCloseNotice()) _buildAutoCloseNotice(),
            if (_attachments.isNotEmpty)
              SizedBox(
                height: 70,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _attachments.length,
                  itemBuilder: (context, index) {
                    final file = _attachments[index];
                    final isImage =
                        lookupMimeType(file.path)?.startsWith('image/') ??
                        false;
                    final isVideo =
                        lookupMimeType(file.path)?.startsWith('video/') ??
                        false;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0, top: 8.0),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          SizedBox(
                            width: 60,
                            height: 60,
                            child: isImage
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: ImageThumbnailFromFile(
                                      file: file,
                                      width: 60,
                                      height: 60,
                                      borderRadius: 8,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : isVideo
                                ? VideoThumbnailFromFile(
                                    file: file,
                                    width: 60,
                                    height: 60,
                                  )
                                : Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.grey200,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.insert_drive_file,
                                      color: AppColors.grey500,
                                    ),
                                  ),
                          ),
                          Positioned(
                            top: -10,
                            right: -10,
                            child: GestureDetector(
                              onTap: () => _removeAttachment(index),
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.perm_media_outlined),
                  onPressed: _pickMedia,
                  tooltip: AppLocalizations.of(context).qna_add_media_tooltip,
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration.collapsed(
                      hintText: AppLocalizations.of(context).qna_message_hint,
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                if (_isSending)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _sendMessage,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool _shouldShowAutoCloseNotice() {
    if (widget.thread.isResolved) return false;
    if (_messages.isEmpty) return false;
    // Find the latest message by createdAt to be safe
    final latest = _messages.reduce(
      (a, b) => a.createdAt.isAfter(b.createdAt) ? a : b,
    );
    return latest.isAdminMessage;
  }

  Widget _buildAutoCloseNotice() {
    final loc = AppLocalizations.of(context);
    final text = loc.qna_auto_close_after_14_days_notice;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: AppColors.grey100,
        borderRadius: BorderRadius.circular(8.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(25),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: getTextStyle(AppTypo.caption12R, AppColors.grey600),
      ),
    );
  }
}

// URL thumbnail widget replaced by shared component.

// Local file thumbnail widget replaced by shared component.

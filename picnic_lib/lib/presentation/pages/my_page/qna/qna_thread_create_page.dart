import 'dart:io';
import 'package:flutter/material.dart';
import 'package:picnic_lib/presentation/pages/my_page/qna/qna_media_picker.dart';
import 'package:mime/mime.dart';
import 'package:picnic_lib/data/repositories/qna_repository.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/widgets/loading_view.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'dart:typed_data';

class QnaThreadCreatePage extends StatefulWidget {
  final String userId;

  const QnaThreadCreatePage({
    super.key,
    required this.userId,
  });

  @override
  State<QnaThreadCreatePage> createState() => _QnaThreadCreatePageState();
}

class _QnaThreadCreatePageState extends State<QnaThreadCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _scrollController = ScrollController();
  final QnaRepository _repository = QnaRepository();

  final List<File> _attachments = [];
  bool _isSubmitting = false;
  bool _isAttaching = false;
  static const int _maxFileSizeInBytes = 10 * 1024 * 1024; // 10MB

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _scrollController.dispose();
    super.dispose();
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
      _scrollToBottom();
    } finally {
      if (mounted) {
        setState(() {
          _isAttaching = false;
        });
      }
    }
  }

  void _removeAttachment(int index) {
    setState(() {
      _attachments.removeAt(index);
    });
  }

  Future<void> _submitThread() async {
    FocusScope.of(context).unfocus();
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      try {
        await _repository.createQaThread(
          userId: widget.userId,
          title: _titleController.text,
          initialMessage: _contentController.text,
          attachments: _attachments,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(AppLocalizations.of(context).qna_submit_success),
                duration: const Duration(seconds: 2)),
          );
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('${AppLocalizations.of(context).qna_submit_fail}: $e'),
                duration: const Duration(seconds: 2)),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isSubmitting = false;
          });
        }
      }
    }
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Stack(
        children: [
          Scaffold(
            appBar: AppBar(
              title: Text(AppLocalizations.of(context).qna_create_title),
              actions: [
                TextButton(
                  onPressed: _isSubmitting ? null : _submitThread,
                  child: _isSubmitting
                      ? const SizedBox.shrink()
                      : Text(
                          AppLocalizations.of(context).qna_submit_button,
                          style: TextStyle(
                              color: _isSubmitting
                                  ? AppColors.grey500
                                  : Colors.black),
                        ),
                ),
              ],
            ),
            body: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context).qna_form_title,
                        hintText:
                            AppLocalizations.of(context).qna_form_title_hint,
                        hintStyle:
                            getTextStyle(AppTypo.caption12R, AppColors.grey500),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().length < 5) {
                          return AppLocalizations.of(context)
                              .qna_title_min_length;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _contentController,
                      maxLines: 10,
                      decoration: InputDecoration(
                        labelText:
                            AppLocalizations.of(context).qna_form_content,
                        hintText:
                            AppLocalizations.of(context).qna_form_content_hint,
                        hintStyle:
                            getTextStyle(AppTypo.caption12R, AppColors.grey500),
                        alignLabelWithHint: true,
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().length < 10) {
                          return AppLocalizations.of(context)
                              .qna_content_min_length;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildAttachmentSection(),
                  ],
                ),
              ),
            ),
          ),
          if (_isSubmitting || _isAttaching)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: const Center(
                child: LoadingView(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAttachmentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton.icon(
          onPressed: _pickMedia,
          icon: const Icon(Icons.perm_media),
          label: Text(AppLocalizations.of(context).qna_attach_media),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            AppLocalizations.of(context).qna_file_size_limit_notice(10),
            style: getTextStyle(AppTypo.caption12R, AppColors.grey500),
          ),
        ),
        if (_attachments.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: List.generate(_attachments.length, (index) {
                final file = _attachments[index];
                final mimeType = lookupMimeType(file.path) ?? '';
                final isImage = mimeType.startsWith('image/');
                final isVideo = mimeType.startsWith('video/');

                return SizedBox(
                  width: 88,
                  height: 88,
                  child: Stack(
                    children: [
                      Positioned(
                        left: 0,
                        bottom: 0,
                        child: SizedBox(
                          width: 80,
                          height: 80,
                          child: isImage
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    file,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : isVideo
                                  ? _VideoThumbnailFromFile(file: file)
                                  : Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.grey200,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.insert_drive_file,
                                        color: AppColors.grey500,
                                      ),
                                    ),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () {
                            _removeAttachment(index);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }
}

class _VideoThumbnailFromFile extends StatefulWidget {
  final File file;

  const _VideoThumbnailFromFile({required this.file});

  @override
  State<_VideoThumbnailFromFile> createState() =>
      _VideoThumbnailFromFileState();
}

class _VideoThumbnailFromFileState extends State<_VideoThumbnailFromFile> {
  Uint8List? _thumbnailData;

  @override
  void initState() {
    super.initState();
    _generateThumbnail();
  }

  Future<void> _generateThumbnail() async {
    final thumbnailData = await VideoThumbnail.thumbnailData(
      video: widget.file.path,
      imageFormat: ImageFormat.PNG,
      maxWidth: 160,
      quality: 25,
    );
    if (mounted) {
      setState(() {
        _thumbnailData = thumbnailData;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8.0),
      child: Container(
        width: 80,
        height: 80,
        color: AppColors.grey200,
        child: _thumbnailData != null
            ? Image.memory(
                _thumbnailData!,
                fit: BoxFit.cover,
              )
            : const Center(
                child: LoadingView(),
              ),
      ),
    );
  }
}

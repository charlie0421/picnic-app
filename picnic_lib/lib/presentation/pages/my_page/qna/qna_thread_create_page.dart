import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mime/mime.dart';
import 'package:picnic_lib/data/repositories/qna_repository.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/ui/style.dart';

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
  final QnaRepository _repository = QnaRepository();

  List<File> _attachments = [];
  bool _isSubmitting = false;
  static const int _maxFileSizeInBytes = 10 * 1024 * 1024; // 10MB

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickMedia() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.media,
    );

    if (result != null) {
      final List<File> newAttachments = [];
      final List<String> oversizedFiles = [];

      for (final platformFile in result.files) {
        if (platformFile.size > _maxFileSizeInBytes) {
          oversizedFiles.add(platformFile.name);
          continue;
        }
        if (platformFile.path != null) {
          newAttachments.add(File(platformFile.path!));
        }
      }

      setState(() {
        _attachments.addAll(newAttachments);
      });

      if (oversizedFiles.isNotEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).file_too_large_message(
                oversizedFiles.join(', '),
                _maxFileSizeInBytes ~/ (1024 * 1024),
              ),
            ),
          ),
        );
      }
    }
  }

  void _removeAttachment(int index) {
    setState(() {
      _attachments.removeAt(index);
    });
  }

  Future<void> _submitThread() async {
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
                content: Text(AppLocalizations.of(context).qna_submit_success)),
          );
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    '${AppLocalizations.of(context).qna_submit_fail}: $e')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).qna_create_title),
        actions: [
          TextButton(
            onPressed: _isSubmitting ? null : _submitThread,
            child: _isSubmitting
                ? const CircularProgressIndicator()
                : Text(
                    AppLocalizations.of(context).qna_submit_button,
                    style: TextStyle(
                        color:
                            _isSubmitting ? AppColors.grey500 : Colors.black),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
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
                  hintText: AppLocalizations.of(context).qna_form_title_hint,
                  hintStyle:
                      getTextStyle(AppTypo.caption12R, AppColors.grey500),
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().length < 5) {
                    return AppLocalizations.of(context).qna_title_min_length;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contentController,
                maxLines: 10,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).qna_form_content,
                  hintText: AppLocalizations.of(context).qna_form_content_hint,
                  hintStyle:
                      getTextStyle(AppTypo.caption12R, AppColors.grey500),
                  alignLabelWithHint: true,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().length < 10) {
                    return AppLocalizations.of(context).qna_content_min_length;
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
                                  ? Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.grey200,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          Icons.play_circle_outline,
                                          color: AppColors.grey500,
                                          size: 40,
                                        ),
                                      ),
                                    )
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

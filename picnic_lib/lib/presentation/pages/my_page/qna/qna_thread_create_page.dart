import 'dart:io';
import 'package:flutter/material.dart';
import 'package:picnic_lib/presentation/pages/my_page/qna/qna_media_picker.dart';
import 'package:mime/mime.dart';
import 'package:picnic_lib/data/repositories/qna_repository.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/widgets/loading_view.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:picnic_lib/presentation/widgets/media/video_thumbnail.dart';
import 'package:picnic_lib/presentation/widgets/media/image_thumbnail.dart';
import 'package:picnic_lib/core/utils/snackbar_util.dart';
import 'package:picnic_lib/data/models/qna/qna_category.dart';
import 'package:picnic_lib/presentation/widgets/custom_dropdown_button.dart';
import 'package:picnic_lib/presentation/pages/my_page/qna/qna_submit_button.dart';

class QnaThreadCreatePage extends StatefulWidget {
  final String userId;

  const QnaThreadCreatePage({super.key, required this.userId});

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
  List<QnaCategory> _categories = [];
  QnaCategory? _selectedCategory;
  bool _categoryError = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await _repository.getCategories();
      if (!mounted) return;
      setState(() {
        _categories = cats;
      });
    } catch (_) {
      // 카테고리 로드는 실패해도 폼 사용은 가능해야 함
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

    // 카테고리 필수: 카테고리 목록이 있는 경우 반드시 선택
    if (_categories.isNotEmpty &&
        (_selectedCategory == null || _selectedCategory!.code.isEmpty)) {
      setState(() {
        _categoryError = true;
      });
      SnackbarUtil().error(
        AppLocalizations.of(context).qna_category_required,
        context: context,
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      try {
        await _repository.createQaThread(
          userId: widget.userId,
          title: _titleController.text,
          initialMessage: _contentController.text,
          categoryCode: _selectedCategory?.code,
          attachments: _attachments,
        );

        if (mounted) {
          SnackbarUtil().success(
            AppLocalizations.of(context).qna_submit_success,
            context: context,
          );
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        if (mounted) {
          SnackbarUtil().error(
            '${AppLocalizations.of(context).qna_submit_fail}: $e',
            context: context,
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
              title: Text(
                AppLocalizations.of(context).qna_create_page_title,
                style: getTextStyle(AppTypo.body14M, AppColors.grey900),
              ),
              backgroundColor: AppColors.grey00,
              elevation: 0,
              scrolledUnderElevation: 0,
              foregroundColor: AppColors.grey900,
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: QnaSubmitButton.primary(
                    context,
                    onPressed: _submitThread,
                    isLoading: _isSubmitting,
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
                    if (_categories.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomDropdown(
                            value: (_selectedCategory?.code ?? ''),
                            onChanged: (value) {
                              setState(() {
                                if (value == null || value.isEmpty) {
                                  _selectedCategory = null;
                                  _categoryError = true;
                                  _contentController.clear();
                                } else {
                                  final found = _categories.firstWhere(
                                    (c) => c.code == value,
                                    orElse: () => _categories.first,
                                  );
                                  _selectedCategory = found;
                                  _categoryError = false;
                                  final tmpl = found.questionTemplate;
                                  // 템플릿이 없더라도 입력창을 항상 업데이트 (없으면 빈 문자열로 초기화)
                                  _contentController.text = (tmpl ?? '');
                                }
                              });
                            },
                            items: [
                              CustomDropdownMenuItem(
                                value: '',
                                text: AppLocalizations.of(
                                  context,
                                ).qna_category_label,
                              ),
                              ..._categories.map(
                                (c) => CustomDropdownMenuItem(
                                  value: c.code,
                                  text: c.label,
                                ),
                              ),
                            ],
                          ),
                          if (_categoryError)
                            Padding(
                              padding: const EdgeInsets.only(top: 6.0),
                              child: Text(
                                AppLocalizations.of(
                                  context,
                                ).qna_category_required,
                                style: getTextStyle(
                                  AppTypo.caption12R,
                                  AppColors.statusError,
                                ),
                              ),
                            ),
                        ],
                      ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context).qna_title,
                        hintText: AppLocalizations.of(
                          context,
                        ).qna_form_title_hint,
                        labelStyle: getTextStyle(
                          AppTypo.caption12R,
                          AppColors.grey400,
                        ),
                        hintStyle: getTextStyle(
                          AppTypo.caption12R,
                          AppColors.grey300,
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().length < 5) {
                          return AppLocalizations.of(
                            context,
                          ).qna_title_min_length;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _contentController,
                      maxLines: 10,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context).qna_content,
                        hintText: AppLocalizations.of(
                          context,
                        ).qna_form_content_hint,
                        labelStyle: getTextStyle(
                          AppTypo.caption12R,
                          AppColors.grey400,
                        ),
                        hintStyle: getTextStyle(
                          AppTypo.caption12R,
                          AppColors.grey300,
                        ),
                        alignLabelWithHint: true,
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().length < 10) {
                          return AppLocalizations.of(
                            context,
                          ).qna_content_min_length;
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
              color: Colors.black.withAlpha(128),
              child: const Center(child: LoadingView()),
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
                              ? ImageThumbnailFromFile(
                                  file: file,
                                  width: 80,
                                  height: 80,
                                  borderRadius: 8,
                                  fit: BoxFit.cover,
                                )
                              : isVideo
                              ? VideoThumbnailFromFile(file: file)
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

// 로컬 전용 썸네일 위젯은 공통 컴포넌트로 대체되었습니다.

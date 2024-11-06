import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:overlay_loading_progress/overlay_loading_progress.dart';
import 'package:picnic_app/components/community/write/post_write_body.dart';
import 'package:picnic_app/components/community/write/post_write_bottom_bar.dart';
import 'package:picnic_app/components/community/write/post_write_header.dart';
import 'package:picnic_app/components/ui/s3_uploader.dart';
import 'package:picnic_app/config/environment.dart';
import 'package:picnic_app/dialogs/simple_dialog.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/providers/app_setting_provider.dart';
import 'package:picnic_app/providers/community_navigation_provider.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:picnic_app/util/logger.dart';
import 'package:picnic_app/util/openai.dart';

class PostWrite extends ConsumerStatefulWidget {
  const PostWrite({
    super.key,
  });

  @override
  ConsumerState<PostWrite> createState() => _PostWriteViewState();
}

class _PostWriteViewState extends ConsumerState<PostWrite> {
  final TextEditingController _titleController = TextEditingController();
  final quill.QuillController _contentController =
      quill.QuillController.basic();
  final List<PlatformFile> _attachments = [];
  final Map<String, double> _uploadProgress = {};
  late final S3Uploader _s3Uploader;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _s3Uploader = S3Uploader(
      accessKey: Environment.awsAccessKey,
      secretKey: Environment.awsSecretKey,
      region: Environment.awsRegion,
      bucketName: Environment.awsBucket,
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<String> _uploadAttachment(PlatformFile file) async {
    try {
      setState(() {
        _uploadProgress[file.path!] = 0.0;
      });

      final uploadedUrl = await _s3Uploader.uploadFile(
        'post/attachments',
        File(file.path!),
        (progress) {
          setState(() {
            _uploadProgress[file.path!] = progress;
          });
        },
      );

      setState(() {
        _uploadProgress.remove(file.path);
      });

      return uploadedUrl;
    } catch (e, s) {
      logger.e('Error uploading file: $e', stackTrace: s);
      rethrow;
    }
  }

  Future<void> _savePost({bool isTemporary = false}) async {
    OverlayLoadingProgress.start(context);
    logger.i('_titleController.text: ${_titleController.text}');
    logger.i(
        '_titleController.text: ${_contentController.document.toPlainText()}');

    final title = _titleController.text;
    final content = _contentController.document.toPlainText();

    final checkResult = await checkContent('$title\n$content');

    // null safety 처리 추가
    final isFlagged = checkResult['flagged'] as bool? ?? false;
    final categories = checkResult['categories'] as Map<String, dynamic>? ?? {};

    if (isFlagged) {
      OverlayLoadingProgress.stop();
      showSimpleDialog(
        title: Intl.message('dialog_caution'),
        content: Intl.message('post_flagged'),
      );
      return;
    }

    final postAnonymousMode = ref
        .watch(appSettingProvider.select((value) => value.postAnonymousMode));

    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    String? postId;

    try {
      // Create post first
      final postData = {
        'title': _titleController.text,
        'content': _contentController.document.toDelta().toJson(),
        'is_anonymous': postAnonymousMode,
        'user_id': supabase.auth.currentUser!.id,
        'board_id': ref.read(communityStateInfoProvider).currentBoard?.boardId,
        'is_temporary': isTemporary,
      };

      final postResponse =
          await supabase.from('posts').insert(postData).select();
      postId = postResponse[0]['post_id'];

      // Upload attachments and save to attachments table
      List<Map<String, dynamic>> attachmentData = [];
      for (var file in _attachments) {
        final uploadedUrl = await _uploadAttachment(file);

        attachmentData.add({
          'post_id': postId,
          'file_name': file.name,
          'file_path': uploadedUrl,
          'file_type': file.extension ?? 'unknown',
          'file_size': file.size,
        });
      }

      // Insert all attachments
      await supabase.from('post_attachments').insert(attachmentData);

      if (isTemporary) {
        showSimpleDialog(
          title: S.of(context).post_temporary_save_complete,
          content: S.of(context).post_ask_go_to_temporary_save_list,
          onOk: () {},
          onCancel: () {
            Navigator.of(context).pop();
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post saved successfully!')),
        );
        ref.read(navigationInfoProvider.notifier).goBack();
      }
    } catch (e, s) {
      logger.e('Error saving post: $e', stackTrace: s);

      // Rollback: Delete the post if it was created
      if (postId != null) {
        try {
          await supabase.from('posts').delete().eq('id', postId);
        } catch (rollbackError) {
          logger.e('Error during rollback: $rollbackError');
          rethrow;
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving post: $e')),
      );
      rethrow;
    } finally {
      OverlayLoadingProgress.stop();

      setState(() {
        _isSaving = false;
      });
    }
  }

  bool _isTitleValid = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SingleChildScrollView(
        child: Column(
          children: [
            PostWriteHeader(
              onSave: (isTemporary) {
                if (isTemporary) {
                  _savePost(isTemporary: true);
                } else {
                  _savePost(isTemporary: false);
                }
              },
              isTitleValid: _isTitleValid, // _isTitleValid는 부모 위젯에서 관리하는 상태 변수
              // isSaving: _isSaving,
            ),
            PostWriteBody(
              titleController: _titleController,
              contentController: _contentController,
              attachments: _attachments,
              onAttachmentAdded: (files) async {
                setState(() => _attachments.addAll(files));
              },
              onAttachmentRemoved: (index) {
                setState(() {
                  _attachments.removeAt(index);
                });
              },
              onValidityChanged: (isValid) {
                setState(() {
                  _isTitleValid = isValid;
                });
              },
            ),
            if (_uploadProgress.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Uploading attachments:'),
                    ..._uploadProgress.entries.map(
                      (entry) => LinearProgressIndicator(
                        value: entry.value,
                        backgroundColor: Colors.grey[200],
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),
            const PostWriteBottomBar(),
          ],
        ),
      ),
    );
  }
}

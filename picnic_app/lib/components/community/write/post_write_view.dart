import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_app/components/community/write/post_write_body.dart';
import 'package:picnic_app/components/community/write/post_write_bottom_bar.dart';
import 'package:picnic_app/components/community/write/post_write_header.dart';
import 'package:picnic_app/components/ui/s3_uploader.dart';
import 'package:picnic_app/config/environment.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/supabase_options.dart';

class PostWriteView extends ConsumerStatefulWidget {
  const PostWriteView({
    super.key,
    required this.boardId,
  });
  final String boardId;

  @override
  ConsumerState<PostWriteView> createState() => _PostWriteViewState();
}

class _PostWriteViewState extends ConsumerState<PostWriteView> {
  final TextEditingController _titleController = TextEditingController();
  final quill.QuillController _contentController =
      quill.QuillController.basic();
  bool _isAnonymous = false;
  List<PlatformFile> _attachments = [];
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
    } catch (e) {
      print('Error uploading file: $e');
      rethrow;
    }
  }

  Future<void> _savePost() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
    });

    String? postId;

    try {
      // Create post first
      final postData = {
        'board_id': widget.boardId,
        'title': _titleController.text,
        'content': _contentController.document.toDelta().toJson(),
        'is_anonymous': _isAnonymous,
        'user_id': supabase.auth.currentUser!.id,
      };

      final postResponse = await supabase
          .schema('community')
          .from('posts')
          .insert(postData)
          .select();
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

      logger.d('Attachment data: $attachmentData');

      // Insert all attachments
      await supabase
          .schema('community')
          .from('attachments')
          .insert(attachmentData);

      // Show success message or navigate back
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post saved successfully!')),
      );
    } catch (e, s) {
      logger.e('Error saving post: $e', stackTrace: s);

      // Rollback: Delete the post if it was created
      if (postId != null) {
        try {
          await supabase
              .schema('community')
              .from('posts')
              .delete()
              .eq('id', postId);
        } catch (rollbackError) {
          logger.e('Error during rollback: $rollbackError');
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving post: $e')),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              PostWriteHeader(
                onSave: _savePost,
                // isSaving: _isSaving,
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
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
                      ),
                      if (_uploadProgress.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Uploading attachments:'),
                              ..._uploadProgress.entries.map(
                                (entry) => LinearProgressIndicator(
                                  value: entry.value,
                                  backgroundColor: Colors.grey[200],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.blue),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              PostWriteBottomBar(
                isAnonymous: _isAnonymous,
                onAnonymousChanged: (value) =>
                    setState(() => _isAnonymous = value),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

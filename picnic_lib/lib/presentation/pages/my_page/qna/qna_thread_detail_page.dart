import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:picnic_lib/core/utils/date.dart';
import 'package:picnic_lib/data/models/qna/qna_message.dart';
import 'package:picnic_lib/data/models/qna/qna_thread.dart';
import 'package:picnic_lib/data/repositories/qna_repository.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/pages/my_page/qna/qna_full_screen_image_viewer.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  bool _isLoading = true;
  bool _isSending = false;
  String? _errorMessage;
  File? _attachment;
  final Map<String, Future<String>> _signedUrlCache = {};

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

      final threadWithMessages =
          await _repository.getQaThreadById(widget.thread.id);
      setState(() {
        _messages = threadWithMessages.messages;
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
    if (content.isEmpty && _attachment == null) return;

    setState(() {
      _isSending = true;
    });

    final userId = Supabase.instance.client.auth.currentUser!.id;

    try {
      List<Map<String, dynamic>>? attachments;
      if (_attachment != null) {
        final file = _attachment!;
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
        final filePath = '$userId/${widget.thread.id}/$fileName';

        await Supabase.instance.client.storage
            .from('qna_attachments')
            .upload(filePath, file);

        attachments = [
          {
            'file_name': fileName,
            'file_path': filePath,
            'file_type': file.path.split('.').last,
            'file_size': await file.length(),
          }
        ];
      }

      final newMessage = await _repository.createQaMessage(
        threadId: widget.thread.id,
        userId: userId,
        content: content,
        attachments: attachments,
      );

      _messageController.clear();
      if (mounted) {
        setState(() {
          _messages.add(newMessage);
          _attachment = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('메시지를 성공적으로 보냈습니다.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('메시지 전송 실패: $e')),
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

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _attachment = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.thread.title),
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildBody(),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    }
    return ListView.builder(
      reverse: true,
      itemCount: _messages.length,
      padding: const EdgeInsets.all(8.0),
      itemBuilder: (context, index) {
        final message = _messages.reversed.toList()[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(QnaMessage message) {
    final isMyMessage =
        message.userId == Supabase.instance.client.auth.currentUser!.id;
    final hasText = message.content != null && message.content!.isNotEmpty;

    final attachments = _buildAttachments(message, hasText, isMyMessage);

    // 텍스트 없이 첨부파일만 있는 경우, 버블 없이 첨부파일만 표시
    if (!hasText && attachments.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
        alignment: isMyMessage ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          child: Column(
            crossAxisAlignment:
                isMyMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: attachments,
          ),
        ),
      );
    }

    // 텍스트가 있는 경우, 기존 버블 스타일 유지
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
            crossAxisAlignment:
                isMyMessage ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (hasText)
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Text(
                    message.content!,
                    style: getTextStyle(AppTypo.body14R,
                        isMyMessage ? AppColors.grey00 : AppColors.grey900),
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
                            ? AppColors.grey00.withOpacity(0.8)
                            : AppColors.grey400),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildAttachments(
      QnaMessage message, bool hasText, bool isMyMessage) {
    return message.attachments.map((att) {
      final isImage = ['jpg', 'jpeg', 'png', 'gif']
          .any((ext) => att.fileName.toLowerCase().endsWith(ext));

      if (isImage) {
        final imageWidget = ClipRRect(
          borderRadius: BorderRadius.circular(12.0),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: FutureBuilder<String>(
              future: _getSignedUrl(att.filePath),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting ||
                    !snapshot.hasData ||
                    snapshot.data!.isEmpty) {
                  return Container(
                    color: isMyMessage
                        ? AppColors.primary500.withOpacity(0.5)
                        : AppColors.grey200,
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  debugPrint(
                      'FutureBuilder error getting signed URL: ${snapshot.error}');
                  return const SizedBox(
                      width: 50, height: 50, child: Icon(Icons.error));
                }

                final imageUrl = snapshot.data!;
                return GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          QnaFullScreenImageViewer(imageUrl: imageUrl),
                    ),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: isMyMessage
                                ? AppColors.primary500.withOpacity(0.5)
                                : AppColors.grey200,
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          debugPrint('Error loading network image: $error');
                          return const Icon(Icons.error);
                        },
                      ),
                      if (!hasText)
                        Positioned(
                          bottom: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              formatTimeAgo(
                                  context, message.createdAt.toLocal()),
                              style: getTextStyle(AppTypo.caption12R,
                                  AppColors.grey00.withOpacity(0.8)),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        );

        return hasText
            ? Padding(
                padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 8.0),
                child: imageWidget,
              )
            : imageWidget;
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

  Future<String> _getSignedUrl(String path) {
    if (_signedUrlCache.containsKey(path)) {
      return _signedUrlCache[path]!;
    } else {
      final future = _repository.getSignedUrl(path);
      _signedUrlCache[path] = future;
      return future;
    }
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_attachment != null)
              Row(
                children: [
                  Image.file(_attachment!,
                      width: 50, height: 50, fit: BoxFit.cover),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_attachment!.path.split('/').last)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      setState(() {
                        _attachment = null;
                      });
                    },
                  ),
                ],
              ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.attach_file),
                  onPressed: _pickImage,
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
}

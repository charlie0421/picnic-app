import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_app/components/community/write/embed_builder/link_embed_builder.dart';
import 'package:picnic_app/components/community/write/embed_builder/media_embed_builder.dart';
import 'package:picnic_app/components/community/write/embed_builder/youtube_embed_builder.dart';
import 'package:picnic_app/models/community/post.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/ui/style.dart';

class PostViewPage extends ConsumerStatefulWidget {
  const PostViewPage(
    this.post, {
    super.key,
  });

  final PostModel post;

  @override
  ConsumerState<PostViewPage> createState() => _PostViewPageState();
}

class _PostViewPageState extends ConsumerState<PostViewPage> {
  quill.QuillController? _quillController;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeQuillController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(navigationInfoProvider.notifier)
          .settingNavigation(showPortal: true, showBottomNavigation: false);
    });
  }

  void _initializeQuillController() {
    try {
      final content = _parseContent(widget.post.content);
      _quillController = quill.QuillController(
        document: quill.Document.fromJson(content),
        selection: const TextSelection.collapsed(offset: 0),
      );
    } catch (e) {
      print('Error initializing QuillController: $e');
      setState(() {
        _errorMessage = '내용을 불러오는 중 오류가 발생했습니다.';
      });
    }
  }

  List<dynamic> _parseContent(dynamic content) {
    if (content is String) {
      try {
        final List<dynamic> parsedContent = jsonDecode(content);
        return parsedContent.map((item) {
          if (item is String) {
            return jsonDecode(item);
          }
          return item;
        }).toList();
      } catch (e) {
        throw FormatException('Failed to parse content as JSON: $e');
      }
    } else if (content is List) {
      return content.map((item) {
        if (item is String) {
          return jsonDecode(item);
        }
        return item;
      }).toList();
    } else {
      throw const FormatException('Unexpected content format');
    }
  }

  @override
  void dispose() {
    _quillController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              widget.post.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              widget.post.user_id,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Text(
                  '조회수: ${widget.post.view_count}',
                  style: const TextStyle(
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '작성일: ${widget.post.created_at.toString()}',
                  style: const TextStyle(
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.grey500),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_errorMessage != null) {
      return Text(_errorMessage!, style: const TextStyle(color: Colors.red));
    }

    if (_quillController == null) {
      return const CircularProgressIndicator();
    }

    return quill.QuillEditor(
      controller: _quillController!,
      scrollController: ScrollController(),
      focusNode: FocusNode(),
      configurations: quill.QuillEditorConfigurations(
        embedBuilders: [
          LinkEmbedBuilder(),
          YouTubeEmbedBuilder(),
          NetworkImageEmbedBuilder(),
        ],
      ),
    );
  }
}

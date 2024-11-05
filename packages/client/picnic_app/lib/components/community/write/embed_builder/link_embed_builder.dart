// lib/components/link_embed.dart
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:picnic_app/components/community/write/embed_builder/deletable_embed_builder.dart';
import 'package:picnic_app/services/link_service.dart';
import 'package:url_launcher/url_launcher.dart';

class LinkEmbedBuilder extends EmbedBuilder {
  @override
  String get key => 'link';

  @override
  Widget build(BuildContext context, QuillController controller, Embed node,
      bool readOnly, bool inline, TextStyle textStyle) {
    return readOnly
        ? _ReadOnlyLinkPreviewWidget(node: node, textStyle: textStyle)
        : _EditableLinkPreviewWidget(node: node);
  }
}

class EditableLinkEmbedBuilder extends EmbedBuilder {
  @override
  String get key => 'link';

  @override
  Widget build(BuildContext context, QuillController controller, Embed node,
      bool readOnly, bool inline, TextStyle textStyle) {
    return _EditableLinkPreviewWidget(node: node);
  }
}

class DeletableLinkEmbedBuilder extends DeletableEmbedBuilder {
  DeletableLinkEmbedBuilder()
      : super(
          embedType: 'link',
          contentBuilder: (BuildContext context, Embed node) {
            return _EditableLinkPreviewWidget(node: node);
          },
        );
}

class _ReadOnlyLinkPreviewWidget extends StatefulWidget {
  final Embed node;
  final TextStyle textStyle;

  const _ReadOnlyLinkPreviewWidget({
    required this.node,
    required this.textStyle,
  });

  @override
  _ReadOnlyLinkPreviewWidgetState createState() =>
      _ReadOnlyLinkPreviewWidgetState();
}

class _ReadOnlyLinkPreviewWidgetState
    extends State<_ReadOnlyLinkPreviewWidget> {
  final _linkService = LinkService();
  bool isLoading = true;
  late String url;
  String? title;
  String? description;
  String? imageUrl;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _extractUrl();
    _fetchLinkPreview();
  }

  void _extractUrl() {
    final data = widget.node.value.data;
    debugPrint('Raw data: $data');

    if (data is String) {
      try {
        final jsonData = json.decode(data);
        debugPrint('Parsed JSON data: $jsonData');
        url = jsonData['url'] as String? ?? '';
      } catch (e) {
        debugPrint('JSON parsing error: $e');
        url = data;
      }
    } else if (data is Map<String, dynamic>) {
      url = data['url'] as String? ?? '';
    }

    debugPrint('Extracted URL: $url');
  }

  String _decodeText(String text) {
    try {
      return utf8.decode(text.runes.toList());
    } catch (e) {
      debugPrint('UTF-8 decoding error: $e');
      try {
        return latin1.decode(text.codeUnits);
      } catch (e) {
        debugPrint('Latin1 decoding error: $e');
        return text;
      }
    }
  }

  Future<void> _fetchLinkPreview() async {
    if (url.isEmpty) {
      setState(() {
        isLoading = false;
        errorMessage = 'Empty URL';
      });
      return;
    }

    try {
      debugPrint('Fetching preview for URL: $url');
      final preview = await _linkService.fetchLinkPreview(url);
      debugPrint('Preview data: $preview');

      setState(() {
        title = _decodeText(preview.title);
        description = _decodeText(preview.description);
        imageUrl = preview.imageUrl;
        isLoading = false;
        errorMessage = null;
      });
    } catch (e) {
      debugPrint('Link preview error: $e');
      setState(() {
        title = Uri.parse(_linkService.normalizeUrl(url)).host;
        description = 'Error loading preview: ${e.toString()}';
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth * 0.5;
        return Align(
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth,
              minWidth: min(maxWidth, 300.0),
            ),
            child: Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: InkWell(
                onTap: () => _launchURL(url),
                borderRadius: BorderRadius.circular(8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (imageUrl != null)
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Image.network(
                            imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              debugPrint('Image loading error: $error');
                              return Container(
                                color: Colors.grey[300],
                                child: const Center(
                                  child: Icon(Icons.broken_image, size: 40),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isLoading)
                            const Center(child: CircularProgressIndicator())
                          else ...[
                            if (errorMessage != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  'Error: $errorMessage',
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            Text(
                              title ?? 'Untitled',
                              style: widget.textStyle.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              description ?? 'No description available',
                              style: widget.textStyle.copyWith(
                                fontSize: 12,
                                height: 1.3,
                                color: Colors.grey[700],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              url,
                              style: widget.textStyle.copyWith(
                                color: Colors.blue,
                                fontSize: 11,
                                decoration: TextDecoration.underline,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _launchURL(String url) async {
    final normalizedUrl = _linkService.normalizeUrl(url);
    final uri = Uri.parse(normalizedUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

class _EditableLinkPreviewWidget extends StatefulWidget {
  final Embed node;

  const _EditableLinkPreviewWidget({required this.node});

  @override
  _EditableLinkPreviewWidgetState createState() =>
      _EditableLinkPreviewWidgetState();
}

class _EditableLinkPreviewWidgetState
    extends State<_EditableLinkPreviewWidget> {
  final _linkService = LinkService();
  bool isLoading = true;
  late String url;
  String? title;
  String? description;
  String? imageUrl;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _extractUrl();
    _fetchLinkPreview();
  }

  void _extractUrl() {
    final data = widget.node.value.data;
    debugPrint('Raw data: $data');

    if (data is String) {
      try {
        final jsonData = json.decode(data);
        debugPrint('Parsed JSON data: $jsonData');
        url = jsonData['url'] as String? ?? '';
      } catch (e) {
        debugPrint('JSON parsing error: $e');
        url = data;
      }
    } else if (data is Map<String, dynamic>) {
      url = data['url'] as String? ?? '';
    }

    debugPrint('Extracted URL: $url');
  }

  String _decodeText(String text) {
    try {
      return utf8.decode(text.runes.toList());
    } catch (e) {
      debugPrint('UTF-8 decoding error: $e');
      try {
        return latin1.decode(text.codeUnits);
      } catch (e) {
        debugPrint('Latin1 decoding error: $e');
        return text;
      }
    }
  }

  Future<void> _fetchLinkPreview() async {
    if (url.isEmpty) {
      setState(() {
        isLoading = false;
        errorMessage = 'Empty URL';
      });
      return;
    }

    try {
      debugPrint('Fetching preview for URL: $url');
      final preview = await _linkService.fetchLinkPreview(url);
      debugPrint('Preview data: $preview');

      setState(() {
        title = _decodeText(preview.title);
        description = _decodeText(preview.description);
        imageUrl = preview.imageUrl;
        isLoading = false;
        errorMessage = null;
      });
    } catch (e) {
      debugPrint('Link preview error: $e');
      setState(() {
        title = Uri.parse(_linkService.normalizeUrl(url)).host;
        description = 'Error loading preview: ${e.toString()}';
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth * 0.5;
        return Align(
          alignment: Alignment.centerLeft,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth,
              minWidth: min(maxWidth, 300.0),
            ),
            child: Card(
              elevation: 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: InkWell(
                onTap: () => _launchURL(url),
                borderRadius: BorderRadius.circular(8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (imageUrl != null)
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Image.network(
                            imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              debugPrint('Image loading error: $error');
                              return Container(
                                color: Colors.grey[300],
                                child: const Center(
                                  child: Icon(Icons.broken_image, size: 40),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isLoading)
                            const Center(child: CircularProgressIndicator())
                          else ...[
                            if (errorMessage != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  'Error: $errorMessage',
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            Text(
                              title ?? 'Untitled',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              description ?? 'No description available',
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.3,
                                color: Colors.grey[700],
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              url,
                              style: const TextStyle(
                                color: Colors.blue,
                                fontSize: 11,
                                decoration: TextDecoration.underline,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _launchURL(String url) async {
    final normalizedUrl = _linkService.normalizeUrl(url);
    final uri = Uri.parse(normalizedUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

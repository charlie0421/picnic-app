import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:html/dom.dart' as html;
import 'package:html/parser.dart' show parse;
import 'package:http/http.dart' as http;
import 'package:picnic_app/components/community/write/embed_builder/deletable_embed_builder.dart';
import 'package:picnic_app/constants.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class LinkEmbedBuilder extends EmbedBuilder {
  @override
  String get key => 'link';

  @override
  Widget build(BuildContext context, QuillController controller, Embed node,
      bool readOnly, bool inline, TextStyle textStyle) {
    return readOnly
        ? _ReadOnlyLinkPreviewWidget(node: node, textStyle: textStyle)
        : EditableLinkEmbedBuilder()
            .build(context, controller, node, readOnly, inline, textStyle);
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

  const _ReadOnlyLinkPreviewWidget(
      {required this.node, required this.textStyle});

  @override
  _ReadOnlyLinkPreviewWidgetState createState() =>
      _ReadOnlyLinkPreviewWidgetState();
}

class _EditableLinkPreviewWidget extends StatefulWidget {
  final Embed node;

  const _EditableLinkPreviewWidget({required this.node});

  @override
  _EditableLinkPreviewWidgetState createState() =>
      _EditableLinkPreviewWidgetState();
}

mixin _LinkPreviewWidgetStateMixin<T extends StatefulWidget> on State<T> {
  String? title;
  String? description;
  String? imageUrl;
  bool isLoading = true;
  String url = '';

  @override
  void initState() {
    super.initState();
    _extractUrl();
    _fetchLinkPreview();
  }

  void _extractUrl() {
    final data = (widget as dynamic).node.value.data;
    logger.d('Original data: $data');

    if (data is String) {
      try {
        final jsonData = json.decode(data);
        if (jsonData is Map<String, dynamic>) {
          url = jsonData['url'] as String? ?? '';
        } else {
          url = data;
        }
      } catch (e, s) {
        logger.e(e, stackTrace: s);
        url = data;
      }
    } else if (data is Map<String, dynamic>) {
      url = data['url'] as String? ?? '';
    }

    logger.d('Extracted URL before validation: $url');
    url = _validateAndCorrectUrl(url);
    logger.d('Final URL after validation: $url');
  }

  String _validateAndCorrectUrl(String inputUrl) {
    if (inputUrl.isEmpty) return '';

    inputUrl = inputUrl.trim();

    if (!inputUrl.startsWith('http://') && !inputUrl.startsWith('https://')) {
      inputUrl = 'https://$inputUrl';
    }

    Uri? uri;
    try {
      uri = Uri.parse(inputUrl);
    } catch (e, s) {
      logger.e('Invalid URL: $inputUrl', stackTrace: s);
      Sentry.captureException(
        e,
        stackTrace: s,
      );
      return '';
    }

    if (uri.host.isEmpty) {
      logger.e('Invalid URL (no host): $inputUrl');
      return '';
    }

    return uri.toString();
  }

  Future<void> _fetchLinkPreview() async {
    if (url.isEmpty) {
      setState(() => isLoading = false);
      return;
    }

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final document = parse(response.body);
        setState(() {
          title = _extractMetadata(
              document, ['og:title', 'twitter:title', 'title']);
          description = _extractMetadata(document,
              ['og:description', 'twitter:description', 'description']);
          imageUrl = _extractMetadata(document, ['og:image', 'twitter:image']);
          isLoading = false;
        });
      } else {
        logger.e('HTTP request failed with status: ${response.statusCode}');
        setState(() => isLoading = false);
      }
    } catch (e, s) {
      logger.e('Error fetching link preview: $e', stackTrace: s);
      setState(() => isLoading = false);
    }
  }

  String? _extractMetadata(html.Document document, List<String> tags) {
    for (final tag in tags) {
      final meta = document.querySelector('meta[property="$tag"]') ??
          document.querySelector('meta[name="$tag"]');
      if (meta != null) {
        return meta.attributes['content'];
      }
    }
    if (tags.contains('title')) {
      return document.querySelector('title')?.text;
    }
    return null;
  }

  Future<void> _launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      logger.e('Could not launch $url');
    }
  }
}

class _ReadOnlyLinkPreviewWidgetState extends State<_ReadOnlyLinkPreviewWidget>
    with _LinkPreviewWidgetStateMixin {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        return SizedBox(
          width: maxWidth,
          child: Card(
            elevation: 1,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: InkWell(
              onTap: () => _launchURL(url),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (imageUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                          imageUrl!,
                          height: 70,
                          width: 70,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            height: 70,
                            width: 70,
                            color: Colors.grey[300],
                            child: const Icon(Icons.broken_image, size: 30),
                          ),
                        ),
                      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isLoading)
                            const Center(child: CircularProgressIndicator())
                          else ...[
                            Text(
                              title ?? 'Untitled',
                              style: widget.textStyle.copyWith(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              description ?? 'No description available',
                              style: widget.textStyle.copyWith(fontSize: 12),
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
}

class _EditableLinkPreviewWidgetState extends State<_EditableLinkPreviewWidget>
    with _LinkPreviewWidgetStateMixin {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth * 2 / 3;
        return SizedBox(
          width: maxWidth,
          child: Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: InkWell(
              onTap: () => _launchURL(url),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (imageUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                          imageUrl!,
                          height: 60,
                          width: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            height: 60,
                            width: 60,
                            color: Colors.grey[300],
                            child: const Icon(Icons.broken_image, size: 30),
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isLoading)
                            const Center(child: CircularProgressIndicator())
                          else ...[
                            Text(
                              title ?? 'Untitled',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              description ?? 'No description available',
                              style: const TextStyle(fontSize: 10),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              url,
                              style: const TextStyle(
                                color: Colors.blue,
                                fontSize: 9,
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
}

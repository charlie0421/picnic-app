import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:picnic_app/util/logger.dart';

class DeletableEmbedBuilder extends EmbedBuilder {
  final String embedType;
  final Widget Function(BuildContext, Embed) contentBuilder;

  DeletableEmbedBuilder({
    required this.embedType,
    required this.contentBuilder,
  });

  @override
  String get key => embedType;

  @override
  Widget build(BuildContext context, QuillController controller, Embed node,
      bool readOnly, bool inline, TextStyle textStyle) {
    return _DeletableEmbedWidget(
      controller: controller,
      node: node,
      embedType: embedType,
      contentBuilder: contentBuilder,
    );
  }
}

class _DeletableEmbedWidget extends StatefulWidget {
  final QuillController controller;
  final Embed node;
  final String embedType;
  final Widget Function(BuildContext, Embed) contentBuilder;

  const _DeletableEmbedWidget({
    required this.controller,
    required this.node,
    required this.embedType,
    required this.contentBuilder,
  });

  @override
  _DeletableEmbedWidgetState createState() => _DeletableEmbedWidgetState();
}

class _DeletableEmbedWidgetState extends State<_DeletableEmbedWidget> {
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    if (_isDeleting) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        widget.contentBuilder(context, widget.node),
        Positioned(
          top: 0,
          right: 0,
          child: IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: _deleteEmbed,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ),
      ],
    );
  }

  Future<void> _deleteEmbed() async {
    setState(() {
      _isDeleting = true;
    });

    await Future.delayed(const Duration(milliseconds: 100));

    if (!mounted) return;

    final index = _findEmbedIndex();
    if (index != -1) {
      widget.controller.replaceText(index, 1, '', null);
    }
  }

  int _findEmbedIndex() {
    final doc = widget.controller.document;
    final delta = doc.toDelta();

    for (int i = 0; i < delta.length; i++) {
      try {
        final operation = delta.elementAt(i);
        if (operation.key == 'insert' &&
            operation.data is Map<String, dynamic>) {
          final Map<String, dynamic> data =
              operation.data as Map<String, dynamic>;
          if (data.containsKey(widget.embedType)) {
            return doc.toPlainText().indexOf(data[widget.embedType].toString());
          }
        }
      } catch (e, s) {
        logger.e('Error while searching for embed: $e', stackTrace: s);
        rethrow;
      }
    }
    return -1;
  }
}

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

class PostWriteAttachments extends StatelessWidget {
  final List<PlatformFile> attachments;
  final Function(int) onAttachmentRemoved;

  const PostWriteAttachments({
    Key? key,
    required this.attachments,
    required this.onAttachmentRemoved,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: attachments.isNotEmpty ? 100 : 0,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: attachments.length,
        itemBuilder: (context, index) {
          final file = attachments[index];
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Stack(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      file.extension ?? '',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 0,
                  child: IconButton(
                    icon: Icon(Icons.close, size: 20),
                    onPressed: () => onAttachmentRemoved(index),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
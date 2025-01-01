import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/core/utils/ui.dart';

class PostWriteAttachments extends StatelessWidget {
  final List<PlatformFile> attachments;
  final Function(List<PlatformFile>) onAttachmentAdded;
  final Function(int) onAttachmentRemoved;

  const PostWriteAttachments({
    super.key,
    required this.attachments,
    required this.onAttachmentAdded,
    required this.onAttachmentRemoved,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 17),
      height: attachments.isNotEmpty ? 100 : 0,
      child: ListView.builder(
        scrollDirection: Axis.vertical,
        itemCount: attachments.length,
        itemBuilder: (context, index) {
          final file = attachments[index];
          return Row(
            children: [
              SvgPicture.asset(
                'assets/icons/post/post_attachment.svg',
                width: 18,
                height: 18,
              ),
              SizedBox(width: 8.cw),
              Text(
                file.name,
                style: getTextStyle(
                  AppTypo.caption12R,
                  AppColors.grey800,
                ),
              ),
              SizedBox(width: 8.cw),
              GestureDetector(
                onTap: () => onAttachmentRemoved(index),
                child: SvgPicture.asset(
                  'assets/icons/cancel_style=line.svg',
                  width: 20,
                  height: 20,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class PostWriteBottomBar extends StatelessWidget {
  final Function(PlatformFile) onMediaPicked;
  final Function(String) onYoutubeLinkInserted;
  final Function(String) onLinkInserted;
  final Function(List<PlatformFile>) onFilesPicked;

  const PostWriteBottomBar({
    super.key,
    required this.onMediaPicked,
    required this.onYoutubeLinkInserted,
    required this.onLinkInserted,
    required this.onFilesPicked,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _pickMediaFiles(context),
            child: SvgPicture.asset(
              'assets/icons/post_media_style=line.svg',
              width: 24,
              height: 24,
              colorFilter:
                  const ColorFilter.mode(AppColors.grey600, BlendMode.srcIn),
            ),
          ),
          SizedBox(width: 24.w),
          GestureDetector(
            onTap: () => _insertYoutubeLink(context),
            child: SvgPicture.asset(
              'assets/icons/post_youtube_style=line.svg',
              width: 24,
              height: 24,
              colorFilter:
                  const ColorFilter.mode(AppColors.grey600, BlendMode.srcIn),
            ),
          ),
          SizedBox(width: 24.w),
          GestureDetector(
            onTap: () => _insertLink(context),
            child: SvgPicture.asset(
              'assets/icons/post_link_style=line.svg',
              width: 24,
              height: 24,
              colorFilter:
                  const ColorFilter.mode(AppColors.grey600, BlendMode.srcIn),
            ),
          ),
          SizedBox(width: 24.w),
          GestureDetector(
            onTap: () => _pickFiles(context),
            child: SvgPicture.asset(
              'assets/icons/post_attach_style=line.svg',
              width: 24,
              height: 24,
              colorFilter:
                  const ColorFilter.mode(AppColors.grey600, BlendMode.srcIn),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickMediaFiles(BuildContext context) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'mp4', 'mov', 'avi'],
    );

    if (result != null && result.files.isNotEmpty) {
      onMediaPicked(result.files.first);
    }
  }

  Future<void> _insertYoutubeLink(BuildContext context) async {
    final link = await showDialog<String>(
      context: context,
      builder: (context) => _LinkDialog(title: 'Insert YouTube Link'),
    );
    if (link != null && link.isNotEmpty) {
      final videoId = YoutubePlayer.convertUrlToId(link);
      if (videoId != null) {
        onYoutubeLinkInserted(videoId);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid YouTube link')),
        );
      }
    }
  }

  Future<void> _insertLink(BuildContext context) async {
    final link = await showDialog<String>(
      context: context,
      builder: (context) => _LinkDialog(title: 'Insert Link'),
    );
    if (link != null && link.isNotEmpty) {
      onLinkInserted(link);
    }
  }

  Future<void> _pickFiles(BuildContext context) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: true,
    );

    if (result != null && result.files.isNotEmpty) {
      onFilesPicked(result.files);
    }
  }
}

class _LinkDialog extends StatelessWidget {
  final TextEditingController _controller = TextEditingController();
  final String title;

  _LinkDialog({required this.title});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(hintText: "Enter link here"),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Cancel'),
          onPressed: () => Navigator.of(context).pop(),
        ),
        TextButton(
          child: const Text('Insert'),
          onPressed: () => Navigator.of(context).pop(_controller.text),
        ),
      ],
    );
  }
}

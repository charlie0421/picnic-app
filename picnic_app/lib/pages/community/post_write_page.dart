// import 'dart:convert';
//
// import 'package:file_picker/file_picker.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_quill/flutter_quill.dart' as quill;
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:picnic_app/providers/navigation_provider.dart';
// import 'package:picnic_app/ui/style.dart';
// import 'package:youtube_player_flutter/youtube_player_flutter.dart';
//
// class PostWritePage extends ConsumerStatefulWidget {
//   const PostWritePage({super.key, required this.boardId});
//   final String boardId;
//
//   @override
//   ConsumerState<PostWritePage> createState() => _PostWritePageState();
// }
//
// class _PostWritePageState extends ConsumerState<PostWritePage> {
//   late quill.QuillController _controller;
//   final FocusNode _editorFocusNode = FocusNode();
//   final TextEditingController _titleController = TextEditingController();
//   bool _isEditorFocused = false;
//   bool _isAnonymous = false;
//   List<PlatformFile> _attachments = [];
//   String? _youtubeLink;
//
//   @override
//   void initState() {
//     super.initState();
//     _controller = quill.QuillController.basic();
//     _editorFocusNode.addListener(_onFocusChange);
//     WidgetsBinding.instance!.addPostFrameCallback((_) {
//       ref.read(navigationInfoProvider.notifier).setShowBottomNavigation(false);
//     });
//   }
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     _editorFocusNode.removeListener(_onFocusChange);
//     _editorFocusNode.dispose();
//     _titleController.dispose();
//     super.dispose();
//   }
//
//   void _onFocusChange() {
//     setState(() {
//       _isEditorFocused = _editorFocusNode.hasFocus;
//     });
//   }
//
//   Future<void> _pickMediaFiles() async {
//     FilePickerResult? result = await FilePicker.platform.pickFiles(
//       type: FileType.custom,
//       allowedExtensions: ['jpg', 'jpeg', 'png', 'gif', 'mp4', 'mov', 'avi'],
//     );
//
//     if (result != null) {
//       final file = result.files.single;
//       _controller.document.insert(_controller.selection.baseOffset, file.name);
//     }
//   }
//
//   Future<void> _pickFiles() async {
//     FilePickerResult? result = await FilePicker.platform.pickFiles(
//       type: FileType.any,
//       allowMultiple: true,
//     );
//
//     if (result != null) {
//       setState(() {
//         _attachments.addAll(result.files);
//       });
//     }
//   }
//
//   Future<void> _insertYoutubeLink() async {
//     final link = await showDialog<String>(
//       context: context,
//       builder: (context) => _LinkDialog(title: 'Insert YouTube Link'),
//     );
//     if (link != null && link.isNotEmpty) {
//       setState(() {
//         _youtubeLink = YoutubePlayer.convertUrlToId(link);
//       });
//     }
//   }
//
//   Future<void> _insertLink() async {
//     final link = await showDialog<String>(
//       context: context,
//       builder: (context) => _LinkDialog(title: 'Insert Link'),
//     );
//     if (link != null && link.isNotEmpty) {
//       _controller.document.insert(_controller.selection.baseOffset, link);
//     }
//   }
//
//   Future<void> _savePost() async {
//     final title = _titleController.text;
//     final content = jsonEncode(_controller.document.toDelta().toJson());
//
//     print('Saving post:');
//     print('Title: $title');
//     print('Content: $content');
//     print('Is Anonymous: $_isAnonymous');
//     print('YouTube Link: $_youtubeLink');
//
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text('Post saved successfully')),
//     );
//   }
//
//   void _unfocus() {
//     FocusScope.of(context).unfocus();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: _unfocus,
//       child: Scaffold(
//         resizeToAvoidBottomInset: false,
//         body: SingleChildScrollView(
//           child: Column(
//             children: [
//               Container(
//                 padding: const EdgeInsets.all(16),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.end,
//                   children: [
//                     Text('임시저장',
//                         style: getTextStyle(
//                             AppTypo.body14B, AppColors.primary500)),
//                     SizedBox(width: 16.w),
//                     SizedBox(
//                       height: 30,
//                       child: ElevatedButton(
//                           style: ElevatedButton.styleFrom(
//                             foregroundColor: AppColors.primary500,
//                             backgroundColor: AppColors.grey00,
//                             textStyle: getTextStyle(AppTypo.body14B),
//                             padding: EdgeInsets.symmetric(horizontal: 20.w),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(20),
//                               side: const BorderSide(
//                                 color: AppColors.primary500,
//                                 width: 1,
//                               ),
//                             ),
//                           ),
//                           onPressed: _savePost,
//                           child: const Text('게시')),
//                     )
//                   ],
//                 ),
//               ),
//               Container(
//                 padding: EdgeInsets.symmetric(horizontal: 16.w),
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.start,
//                   children: [
//                     Container(
//                       height: 48,
//                       child: CupertinoTextField(
//                         controller: _titleController,
//                         placeholder: 'Title',
//                         padding: const EdgeInsets.symmetric(
//                             horizontal: 10, vertical: 12),
//                         decoration: BoxDecoration(
//                           border: Border.all(color: Colors.grey),
//                           borderRadius: BorderRadius.circular(8.0),
//                         ),
//                         textInputAction: TextInputAction.next,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     quill.QuillToolbar.simple(
//                       controller: _controller,
//                       configurations:
//                           const quill.QuillSimpleToolbarConfigurations(
//                         showAlignmentButtons: false,
//                         showListNumbers: false,
//                         showListBullets: false,
//                         showCodeBlock: false,
//                         showQuote: false,
//                         showClearFormat: false,
//                         showLink: true,
//                         showUndo: true,
//                         showRedo: true,
//                         showSubscript: false,
//                         showSuperscript: false,
//                         showClipboardCut: false,
//                         showClipboardCopy: false,
//                         showClipboardPaste: false,
//                         showDirection: false,
//                         showSearchButton: false,
//                         showFontFamily: false,
//                         showFontSize: false,
//                         showBoldButton: true,
//                         showItalicButton: true,
//                         showSmallButton: false,
//                         showUnderLineButton: true,
//                         showLineHeightButton: false,
//                         showStrikeThrough: false,
//                         showInlineCode: false,
//                         showColorButton: false,
//                         showBackgroundColorButton: false,
//                         showJustifyAlignment: false,
//                         showLeftAlignment: false,
//                         showCenterAlignment: false,
//                         showRightAlignment: false,
//                         showHeaderStyle: false,
//                         showListCheck: false,
//                         showDividers: false,
//                         showIndent: false,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Container(
//                       height: 400,
//                       padding: const EdgeInsets.all(16),
//                       decoration: BoxDecoration(
//                         border: Border.all(
//                           color: _isEditorFocused
//                               ? AppColors.primary500
//                               : Colors.grey,
//                           width: _isEditorFocused ? 2.0 : 1.0,
//                         ),
//                         borderRadius: BorderRadius.circular(8.0),
//                       ),
//                       child: quill.QuillEditor.basic(
//                         controller: _controller,
//                         focusNode: _editorFocusNode,
//                       ),
//                     ),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         const Text('익명 게시'),
//                         Switch(
//                           value: _isAnonymous,
//                           onChanged: (value) {
//                             setState(() {
//                               _isAnonymous = value;
//                             });
//                           },
//                         ),
//                       ],
//                     ),
//                     if (_youtubeLink != null) _buildYoutubePreview(),
//                     _buildAttachmentsSection(),
//                     _buildBottomBar(),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildYoutubePreview() {
//     return Container(
//       margin: const EdgeInsets.symmetric(vertical: 8),
//       height: 200,
//       child: YoutubePlayer(
//         controller: YoutubePlayerController(
//           initialVideoId: _youtubeLink!,
//           flags: const YoutubePlayerFlags(autoPlay: false),
//         ),
//         showVideoProgressIndicator: true,
//       ),
//     );
//   }
//
//   Widget _buildAttachmentsSection() {
//     return Container(
//       height: _attachments.isNotEmpty ? 100 : 0,
//       child: ListView.builder(
//         scrollDirection: Axis.horizontal,
//         itemCount: _attachments.length,
//         itemBuilder: (context, index) {
//           final file = _attachments[index];
//           return Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: Stack(
//               children: [
//                 Container(
//                   width: 80,
//                   height: 80,
//                   decoration: BoxDecoration(
//                     color: Colors.grey[200],
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Center(
//                     child: Text(
//                       file.extension ?? '',
//                       style:
//                           TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//                     ),
//                   ),
//                 ),
//                 Positioned(
//                   right: 0,
//                   top: 0,
//                   child: IconButton(
//                     icon: Icon(Icons.close, size: 20),
//                     onPressed: () {
//                       setState(() {
//                         _attachments.removeAt(index);
//                       });
//                     },
//                   ),
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }
//
//   Widget _buildBottomBar() {
//     return Container(
//       padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.start,
//         children: [
//           GestureDetector(
//             onTap: _pickFiles,
//             child: SvgPicture.asset(
//               'assets/icons/post_media_style=line.svg',
//               width: 24,
//               height: 24,
//               colorFilter:
//                   const ColorFilter.mode(AppColors.grey600, BlendMode.srcIn),
//             ),
//           ),
//           SizedBox(width: 24.w),
//           GestureDetector(
//             onTap: _insertYoutubeLink,
//             child: SvgPicture.asset(
//               'assets/icons/post_youtube_style=line.svg',
//               width: 24,
//               height: 24,
//               colorFilter:
//                   const ColorFilter.mode(AppColors.grey600, BlendMode.srcIn),
//             ),
//           ),
//           SizedBox(width: 24.w),
//           GestureDetector(
//             onTap: _insertLink,
//             child: Icon(Icons.link, size: 24, color: AppColors.grey600),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class _LinkDialog extends StatelessWidget {
//   final TextEditingController _controller = TextEditingController();
//   final String title;
//
//   _LinkDialog({required this.title});
//
//   @override
//   Widget build(BuildContext context) {
//     return AlertDialog(
//       title: Text(title),
//       content: TextField(
//         controller: _controller,
//         decoration: const InputDecoration(hintText: "Enter link here"),
//       ),
//       actions: <Widget>[
//         TextButton(
//           child: const Text('Cancel'),
//           onPressed: () => Navigator.of(context).pop(),
//         ),
//         TextButton(
//           child: const Text('Insert'),
//           onPressed: () => Navigator.of(context).pop(_controller.text),
//         ),
//       ],
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_app/components/community/write/post_write_view.dart';
import 'package:picnic_app/providers/navigation_provider.dart';

class PostWritePage extends ConsumerStatefulWidget {
  const PostWritePage({super.key, required this.boardId});
  final String boardId;

  @override
  ConsumerState<PostWritePage> createState() => _PostWritePageState();
}

class _PostWritePageState extends ConsumerState<PostWritePage> {
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(navigationInfoProvider.notifier)
          .settingNavigation(showPortal: false, showBottomNavigation: false);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return PostWriteView(boardId: widget.boardId);
  }
}

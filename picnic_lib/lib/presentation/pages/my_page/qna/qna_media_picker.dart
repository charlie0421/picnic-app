import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/core/utils/snackbar_util.dart';

class PickMediaResult {
  PickMediaResult({required this.selectedFiles, required this.oversizedFiles});

  final List<File> selectedFiles;
  final List<String> oversizedFiles;
}

Future<PickMediaResult> pickQnaMedia({
  required BuildContext context,
  int maxFileSizeInBytes = 10 * 1024 * 1024,
  List<String> allowedExtensions = const [
    'jpg',
    'jpeg',
    'png',
    'mp4',
    'mov',
    'avi',
    'mkv',
  ],
}) async {
  final FilePickerResult? result = await FilePicker.platform.pickFiles(
    allowMultiple: false,
    type: FileType.custom,
    allowedExtensions: allowedExtensions,
  );

  final List<File> newAttachments = [];
  final List<String> oversizedFiles = [];

  if (result != null) {
    for (final platformFile in result.files) {
      if (platformFile.size > maxFileSizeInBytes) {
        oversizedFiles.add(platformFile.name);
        continue;
      }
      if (platformFile.path != null) {
        newAttachments.add(File(platformFile.path!));
      }
    }

    if (oversizedFiles.isNotEmpty) {
      SnackbarUtil().warning(
        AppLocalizations.of(context).file_too_large_message(
          oversizedFiles.join(', '),
          maxFileSizeInBytes ~/ (1024 * 1024),
        ),
        context: context,
      );
    }
  }

  return PickMediaResult(
    selectedFiles: newAttachments,
    oversizedFiles: oversizedFiles,
  );
}

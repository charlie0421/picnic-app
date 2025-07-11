import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:picnic_lib/core/config/environment.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/common/navigator_key.dart';
import 'package:picnic_lib/presentation/dialogs/simple_dialog.dart';
import 'package:share_plus/share_plus.dart';

class ShareUtils {
  static const _initialDelay = Duration(milliseconds: 300);

  static Future<XFile?> _captureContent(GlobalKey key) async {
    try {
      await Future.delayed(_initialDelay);

      final boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        logger.e('RenderRepaintBoundary not found');
        return null;
      }

      // 캡처 및 이미지 생성
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        logger.e('ByteData is null');
        return null;
      }

      final bytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final filename = 'share_${DateTime.now().millisecondsSinceEpoch}.png';
      final path = '${tempDir.path}/$filename';

      final file = File(path);
      await file.writeAsBytes(bytes);

      return XFile(path);
    } catch (e, stack) {
      logger.e('Content capture failed', error: e, stackTrace: stack);
      return null;
    }
  }

  static Future<bool> shareToSocial(
    GlobalKey key, {
    required String message,
    required String hashtag,
    String? downloadLink,
    VoidCallback? onStart,
    VoidCallback? onComplete,
  }) async {
    XFile? capturedFile;

    // 네비게이션 키를 통해 안전하게 context 가져오기
    final context = navigatorKey.currentContext;
    if (context == null) {
      logger.e('NavigatorKey context is null - cannot proceed with share');
      return false;
    }

    try {
      onStart?.call();

      capturedFile = await _captureContent(key);
      if (capturedFile == null) {
        logger.e('Failed to capture content for sharing');
        if (navigatorKey.currentContext != null) {
          showSimpleDialog(
            type: DialogType.error,
            content: AppLocalizations.of(navigatorKey.currentContext!)
                .capture_failed,
          );
        }
        return false;
      }

      final finalDownloadLink = downloadLink ?? Environment.downloadLink;
      final shareText = '$message\n $hashtag $finalDownloadLink     ';

      // share_plus를 사용한 공유
      final result = await SharePlus.instance.share(
        ShareParams(
          text: shareText,
          subject: message,
          files: [capturedFile],
        ),
      );

      // 공유 결과 확인
      return result.status == ShareResultStatus.success;
    } catch (e, s) {
      logger.e('Social share failed', error: e, stackTrace: s);
      // context가 여전히 유효한지 재확인
      if (navigatorKey.currentContext != null) {
        showSimpleDialog(
          type: DialogType.error,
          content: AppLocalizations.of(navigatorKey.currentContext!).error_action_failed,
        );
      }
      return false;
    } finally {
      onComplete?.call();
      if (capturedFile != null) {
        try {
          final file = File(capturedFile.path);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (e, s) {
          logger.e('Temp file cleanup failed', error: e, stackTrace: s);
        }
      }
    }
  }

  static Future<bool> saveImage(
    GlobalKey key, {
    VoidCallback? onStart,
    VoidCallback? onComplete,
  }) async {
    XFile? capturedFile;

    // 네비게이션 키를 통해 안전하게 context 가져오기
    final context = navigatorKey.currentContext;
    if (context == null) {
      logger.e('NavigatorKey context is null - cannot proceed with save');
      return false;
    }

    try {
      onStart?.call();

      capturedFile = await _captureContent(key);
      if (capturedFile == null) {
        logger.e('Failed to capture content');
        if (navigatorKey.currentContext != null) {
        showSimpleDialog(
            type: DialogType.error,
            content: AppLocalizations.of(navigatorKey.currentContext!).capture_failed,
          );
        }
        return false;
      }

      // Verify file exists before saving
      final file = File(capturedFile.path);
      if (!await file.exists()) {
        logger.e('Captured file does not exist: ${capturedFile.path}');
        if (navigatorKey.currentContext != null) {
          showSimpleDialog(
            type: DialogType.error,
            content: AppLocalizations.of(navigatorKey.currentContext!).message_pic_pic_save_fail,
          );
        }
        return false;
      }

      final bytes = await capturedFile.readAsBytes();
      if (bytes.isEmpty) {
        logger.e('Captured file is empty');
        if (navigatorKey.currentContext != null) {
          showSimpleDialog(
            type: DialogType.error,
            content: AppLocalizations.of(navigatorKey.currentContext!).message_pic_pic_save_fail,
          );
        }
        return false;
      }

      final result = await ImageGallerySaverPlus.saveImage(
        bytes,
        quality: 100,
        name: "compatibility_result_${DateTime.now().millisecondsSinceEpoch}",
      );

      if (result?['isSuccess'] != true) throw Exception('Save failed');

      if (navigatorKey.currentContext != null) {
        showSimpleDialog(
          content: AppLocalizations.of(navigatorKey.currentContext!).image_save_success,
        );
      }
      return true;
    } catch (e, s) {
      logger.e('Image save failed', error: e, stackTrace: s);
      // context가 여전히 유효한지 재확인
      if (navigatorKey.currentContext != null) {
        showSimpleDialog(
          type: DialogType.error,
          content: AppLocalizations.of(navigatorKey.currentContext!).message_pic_pic_save_fail,
        );
      }
      return false;
    } finally {
      onComplete?.call();
      if (capturedFile != null) {
        try {
          final file = File(capturedFile.path);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (e, s) {
          logger.e('Temp file cleanup failed', error: e, stackTrace: s);
        }
      }
    }
  }
}

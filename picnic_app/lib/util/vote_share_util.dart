import 'dart:io';
import 'dart:ui' as ui;
import 'dart:ui';

import 'package:appinio_social_share/appinio_social_share.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:picnic_app/dialogs/simple_dialog.dart';
import 'package:picnic_app/util/logger.dart';

class ShareUtils {
  static final AppinioSocialShare _appinioSocialShare = AppinioSocialShare();

  static Future<ui.Image?> captureWidget(GlobalKey key) async {
    try {
      RenderRepaintBoundary? boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: 3.0);
      return image;
    } catch (e) {
      logger.e('Failed to capture widget: $e');
      return null;
    }
  }

  static Future<String?> saveImageToTemp(ui.Image image) async {
    try {
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      final pngBytes = byteData.buffer.asUint8List();
      final Directory directory;
      if (Platform.isAndroid) {
        directory = (await getExternalStorageDirectory())!;
      } else {
        directory = await getTemporaryDirectory();
      }

      final path = '${directory.path}/vote_result.png';
      final file = File(path);
      await file.writeAsBytes(pngBytes);

      return path;
    } catch (e) {
      logger.e('Failed to save image to temp: $e');
      return null;
    }
  }

  static Future<Uint8List?> captureScrollableContent(GlobalKey key) async {
    try {
      final context = key.currentContext;
      if (context == null) return null;

      await Future.delayed(Duration(milliseconds: 500));
      final boundary = context.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ImageByteFormat.png);

      return byteData?.buffer.asUint8List();
    } catch (e, stack) {
      logger.e('Error capturing content', error: e, stackTrace: stack);
      return null;
    }
  }

  static Future<bool> captureAndSaveImage(
    GlobalKey saveKey, {
    VoidCallback? onStart,
    VoidCallback? onComplete,
  }) async {
    try {
      if (onStart != null) onStart();

      // 렌더링 대기 시간을 더 길게 설정
      await Future.delayed(const Duration(seconds: 2));

      final bytes = await captureScrollableContent(saveKey);
      if (bytes == null) return false;

      // 이미지 저장
      final result = await ImageGallerySaverPlus.saveImage(
        bytes,
        quality: 100,
        name: "compatibility_result_${DateTime.now().millisecondsSinceEpoch}",
      );

      if (result == null || result['isSuccess'] != true) {
        throw Exception('Failed to save image');
      }

      showSimpleDialog(
        content: Intl.message('image_save_success'),
      );

      return true;
    } catch (e) {
      logger.e('Failed to capture and save image: $e');
      showSimpleDialog(
        type: DialogType.error,
        content: Intl.message('message_pic_pic_save_fail'),
      );
      return false;
    } finally {
      if (onComplete != null) onComplete();
    }
  }

  static Future<bool> shareToTwitter(
    GlobalKey key,
    BuildContext context, {
    required String message,
    required String hashtag,
    VoidCallback? onStart,
    VoidCallback? onComplete,
  }) async {
    logger.i('shareToTwitter');
    try {
      if (onStart != null) onStart();

      await Future.delayed(const Duration(milliseconds: 500));

      final image = await captureWidget(key);
      if (image == null) return false;

      final path = await saveImageToTemp(image);
      if (path == null) return false;

      final shareMessage = '$message $hashtag';

      logger.i('shareMessage: $shareMessage');

      final result = Platform.isIOS
          ? await _appinioSocialShare.iOS.shareToTwitter(shareMessage, path)
          : await _appinioSocialShare.android
              .shareToTwitter(shareMessage, path);

      logger.i('result: $result');

      await File(path).delete();

      if (result == 'ERROR_APP_NOT_AVAILABLE') {
        logger.e(Intl.message('share_no_twitter'));
        showSimpleDialog(
          type: DialogType.error,
          content: Intl.message('share_no_twitter'),
        );
        return false;
      }

      return result == 'SUCCESS';
    } catch (e) {
      logger.e('Failed to share to Twitter: $e');
      showSimpleDialog(
        type: DialogType.error,
        content: Intl.message('share_image_fail'),
      );
      return false;
    } finally {
      if (onComplete != null) onComplete();
    }
  }
}

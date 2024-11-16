import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:appinio_social_share/appinio_social_share.dart';
import 'package:picnic_app/util/logger.dart';

class VoteShareUtils {
  static final AppinioSocialShare _appinioSocialShare = AppinioSocialShare();

  /// 위젯을 이미지로 캡처
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

  /// 캡처한 이미지를 파일로 저장
  static Future<String?> saveImageToTemp(ui.Image image) async {
    try {
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      final pngBytes = byteData.buffer.asUint8List();
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/vote_result.png';
      final file = File(path);
      await file.writeAsBytes(pngBytes);

      return path;
    } catch (e) {
      logger.e('Failed to save image to temp: $e');
      return null;
    }
  }

  /// 이미지 캡처 및 저장
  static Future<bool> captureAndSaveImage(
    GlobalKey key,
    BuildContext context, {
    VoidCallback? onStart,
    VoidCallback? onComplete,
  }) async {
    try {
      if (onStart != null) onStart();

      // 렌더링 대기
      await Future.delayed(const Duration(milliseconds: 500));

      final image = await captureWidget(key);
      if (image == null) return false;

      final path = await saveImageToTemp(image);
      if (path == null) return false;

      final result = await ImageGallerySaverPlus.saveFile(path);
      await File(path).delete();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            duration: Duration(milliseconds: 300),
            content: Text('이미지가 성공적으로 저장되었습니다.'),
          ),
        );
      }

      return true;
    } catch (e) {
      logger.e('Failed to capture and save image: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            duration: Duration(milliseconds: 300),
            content: Text('이미지 저장에 실패했습니다.'),
          ),
        );
      }
      return false;
    } finally {
      if (onComplete != null) onComplete();
    }
  }

  /// 트위터로 공유
  static Future<bool> shareToTwitter(
    GlobalKey key,
    BuildContext context, {
    required String title,
    VoidCallback? onStart,
    VoidCallback? onComplete,
  }) async {
    try {
      if (onStart != null) onStart();

      await Future.delayed(const Duration(milliseconds: 500));

      final image = await captureWidget(key);
      if (image == null) return false;

      final path = await saveImageToTemp(image);
      if (path == null) return false;

      final shareMessage = '''$title 투표 결과
#Picnic #Vote #PicnicApp''';

      final result = Platform.isIOS
          ? await _appinioSocialShare.iOS.shareToTwitter(shareMessage, path)
          : await _appinioSocialShare.android
              .shareToTwitter(shareMessage, path);

      await File(path).delete();

      if (result == 'ERROR_APP_NOT_AVAILABLE') {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Twitter 앱이 설치되어 있지 않습니다.'),
            ),
          );
        }
        return false;
      }

      return result == 'SUCCESS';
    } catch (e) {
      logger.e('Failed to share to Twitter: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            duration: Duration(milliseconds: 300),
            content: Text('공유에 실패했습니다.'),
          ),
        );
      }
      return false;
    } finally {
      if (onComplete != null) onComplete();
    }
  }
}

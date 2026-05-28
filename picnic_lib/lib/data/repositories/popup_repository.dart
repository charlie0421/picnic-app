import 'dart:io';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/data/models/common/popup.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PopupRepository {
  final _client = Supabase.instance.client;

  Future<List<Popup>> fetchPopups() async {
    try {
      final now = DateTime.now().toIso8601String();
      final response = await _client
          .from('popup')
          .select()
          .lte('start_at', now)
          .or('stop_at.is.null,stop_at.gte.$now')
          .filter('deleted_at', 'is', null)
          .order('start_at', ascending: true);

      final popups = (response as List)
          .map((e) => Popup.fromJson(e as Map<String, dynamic>))
          .toList();

      return popups.where(_isForCurrentPlatform).toList();
    } catch (e, s) {
      logger.e('Error fetching popups', error: e, stackTrace: s);
      return [];
    }
  }

  bool _isForCurrentPlatform(Popup popup) {
    final platform = popup.platform;
    if (platform == null || platform.isEmpty || platform == 'all') {
      return true;
    }
    if (Platform.isAndroid) return platform == 'android';
    if (Platform.isIOS) return platform == 'ios';
    return false;
  }
}

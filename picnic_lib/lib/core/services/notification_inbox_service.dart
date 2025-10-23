import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:picnic_lib/data/models/user_notification.dart';

class NotificationInboxService {
  static Future<List<UserNotification>> fetch({
    int from = 0,
    int limit = 20,
  }) async {
    try {
      // 엣지 함수 미사용: 개인 + 방송을 클라이언트에서 병합 정렬
      final user = supabase.auth.currentUser;
      final fetchCount = (from + limit).clamp(0, 200); // 과도한 로드 방지 상한

      // 개인 알림
      List<dynamic> userRows = [];
      try {
        if (user != null) {
          userRows = await supabase
              .from('user_notifications')
              .select('*')
              .eq('user_id', user.id)
              .order('created_at', ascending: false)
              .limit(fetchCount);
        }
      } catch (_) {}

      // 방송 알림
      List<dynamic> broadcastRows = [];
      try {
        broadcastRows = await supabase
            .from('broadcast_notifications')
            .select('*')
            .order('created_at', ascending: false)
            .limit(fetchCount);
      } catch (_) {}

      final userList = (userRows)
          .map((e) => UserNotification.fromJson(e as Map<String, dynamic>))
          .toList();

      final broadcastList = (broadcastRows).map((e) {
        final map = Map<String, dynamic>.from(e as Map);
        // user_id 없음 → null 유지, is_read 기본값 false 활용
        return UserNotification.fromJson(map);
      }).toList();

      final all = <UserNotification>[...userList, ...broadcastList];
      all.sort((a, b) {
        final ca = a.createdAt ?? '';
        final cb = b.createdAt ?? '';
        final cmp = cb.compareTo(ca); // desc
        if (cmp != 0) return cmp;
        return (b.id).compareTo(a.id);
      });

      final start = from.clamp(0, all.length);
      final end = (from + limit).clamp(0, all.length);
      return all.sublist(start, end);
    } catch (e, s) {
      logger.e('fetch notifications (db) failed', error: e, stackTrace: s);
      return [];
    }
  }

  static Future<bool> markRead(int id) async {
    try {
      await supabase
          .from('user_notifications')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id);
      return true;
    } catch (e, s) {
      logger.e('mark read failed', error: e, stackTrace: s);
      return false;
    }
  }
}

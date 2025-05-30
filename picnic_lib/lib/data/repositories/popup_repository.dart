import 'dart:convert';
import 'package:picnic_lib/data/models/common/popup.dart';
import 'package:picnic_lib/data/repositories/offline_first_repository.dart';
import 'package:picnic_lib/core/utils/logger.dart';

class PopupRepository extends OfflineFirstRepository<Popup> {
  @override
  String get tableName => 'popups';

  @override
  String get remoteTableName => 'popup';

  @override
  Popup fromJson(Map<String, dynamic> json) {
    // SQLite에서 읽을 때: JSON 문자열을 Map으로 변환
    final processedJson = Map<String, dynamic>.from(json);

    // title이 문자열이면 JSON으로 파싱
    if (processedJson['title'] is String) {
      try {
        processedJson['title'] = jsonDecode(processedJson['title']);
      } catch (e) {
        logger.w('Failed to parse title JSON: ${processedJson['title']}');
        processedJson['title'] = {'en': processedJson['title']};
      }
    }

    // content가 문자열이면 JSON으로 파싱
    if (processedJson['content'] is String) {
      try {
        processedJson['content'] = jsonDecode(processedJson['content']);
      } catch (e) {
        logger.w('Failed to parse content JSON: ${processedJson['content']}');
        processedJson['content'] = {'en': processedJson['content']};
      }
    }

    // image가 문자열이면 JSON으로 파싱
    if (processedJson['image'] is String && processedJson['image'] != null) {
      try {
        processedJson['image'] = jsonDecode(processedJson['image']);
      } catch (e) {
        logger.w('Failed to parse image JSON: ${processedJson['image']}');
        processedJson['image'] = null;
      }
    }

    return Popup.fromJson(processedJson);
  }

  @override
  Map<String, dynamic> toJson(Popup model) {
    final json = model.toJson();

    // SQLite에 저장할 때: Map을 JSON 문자열로 변환
    json['title'] = jsonEncode(model.title);
    json['content'] = jsonEncode(model.content);
    if (model.image != null) {
      json['image'] = jsonEncode(model.image);
    }

    return json;
  }

  @override
  String getId(Popup model) => model.id.toString();

  /// 활성 상태인 팝업들을 가져옵니다 (시작일과 종료일 기준)
  Future<List<Popup>> fetchPopups() async {
    try {
      final now = DateTime.now().toIso8601String();

      final results = await getAll(
        where: 'start_at <= ? AND stop_at >= ? AND deleted_at IS NULL',
        whereArgs: [now, now],
        orderBy: 'start_at ASC',
      );

      logger.d('Fetched ${results.length} active popups');
      return results;
    } catch (e, s) {
      logger.e('Error fetching active popups', error: e, stackTrace: s);
      return [];
    }
  }

  /// 모든 팝업을 가져옵니다 (삭제되지 않은 것만)
  Future<List<Popup>> fetchAllPopups() async {
    try {
      final results = await getAll(
        where: 'deleted_at IS NULL',
        orderBy: 'created_at DESC',
      );

      logger.d('Fetched ${results.length} popups');
      return results;
    } catch (e, s) {
      logger.e('Error fetching all popups', error: e, stackTrace: s);
      return [];
    }
  }
}

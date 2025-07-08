// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'ピクニック';

  @override
  String get vote_item_request_title => 'Vote Candidate Application';

  @override
  String get vote_item_request_button => '投票申請';

  @override
  String get artist_name_label => 'アーティスト名';

  @override
  String get group_name_label => 'グループ名';

  @override
  String get application_reason_label => '申請理由';

  @override
  String get artist_name_hint => 'アーティスト名を入力してください';

  @override
  String get group_name_hint => 'グループ名を入力してください（任意）';

  @override
  String get application_reason_hint => '申請理由を入力してください（任意）';

  @override
  String get submit_application => '申請する';

  @override
  String get vote_item_request_search_artist_hint =>
      'Search for artist or group';

  @override
  String get application_success => '投票候補者申請が完了しました。';

  @override
  String get success => '成功';

  @override
  String get vote_period => '投票期間';

  @override
  String get error_artist_not_selected => 'アーティストを選択してください';

  @override
  String get error_application_reason_required => '申請理由を入力してください';

  @override
  String get searching => '検索中...';

  @override
  String get no_search_results => 'No search results found';

  @override
  String get vote_item_request_current_item_request => '現在のアイテムリクエスト';

  @override
  String get vote_item_request_no_item_request_yet => 'まだアイテムリクエストがありません';

  @override
  String get vote_item_request_search_artist => 'Search Artist';

  @override
  String get vote_item_request_search_artist_prompt => 'アーティストを検索して申請してください';

  @override
  String vote_item_request_item_request_count(Object count) {
    return '$count個のアイテムリクエスト';
  }

  @override
  String vote_item_request_total_item_requests(Object count) {
    return '合計$count個のアイテムリクエスト';
  }

  @override
  String get vote_item_request_submit => '申請する';

  @override
  String get vote_item_request_already_registered => '既に登録済み';

  @override
  String get vote_item_request_can_apply => 'Can apply';

  @override
  String get vote_item_request_status_pending => '待機中';

  @override
  String get vote_item_request_status_approved => '承認済み';

  @override
  String get vote_item_request_status_rejected => '拒否済み';

  @override
  String get vote_item_request_status_in_progress => 'In Progress';

  @override
  String get vote_item_request_status_cancelled => 'Cancelled';

  @override
  String get vote_item_request_status_unknown => 'Unknown';

  @override
  String get vote_item_request_artist_name_missing => 'アーティスト名がありません';

  @override
  String get vote_item_request_user_info_not_found => 'ユーザー情報が見つかりません。';

  @override
  String get vote_item_request_already_applied_artist =>
      'You have already applied for this artist.';

  @override
  String get vote_item_request_addition_request => '投票アイテム追加リクエスト';

  @override
  String get label_tabbar_vote_active => 'Active';

  @override
  String get label_tabbar_vote_image => '画像投票';

  @override
  String get label_tabbar_vote_end => 'Ended';

  @override
  String get label_tabbar_vote_upcoming => 'Upcoming';
}

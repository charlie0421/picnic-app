// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '野餐';

  @override
  String get vote_item_request_title => 'Vote Candidate Application';

  @override
  String get vote_item_request_button => '申请投票';

  @override
  String get artist_name_label => '艺术家姓名';

  @override
  String get group_name_label => '组合名称';

  @override
  String get application_reason_label => '申请理由';

  @override
  String get artist_name_hint => '请输入艺术家姓名';

  @override
  String get group_name_hint => '请输入组合名称（可选）';

  @override
  String get application_reason_hint => '请输入申请理由（可选）';

  @override
  String get submit_application => '提交申请';

  @override
  String get vote_item_request_search_artist_hint =>
      'Search for artist or group';

  @override
  String get application_success => '投票候选人申请已完成。';

  @override
  String get success => '成功';

  @override
  String get vote_period => '投票期间';

  @override
  String get error_artist_not_selected => '请选择艺术家';

  @override
  String get error_application_reason_required => '请输入申请理由';

  @override
  String get searching => '搜索中...';

  @override
  String get no_search_results => 'No search results found';

  @override
  String get vote_item_request_current_item_request => '当前项目请求';

  @override
  String get vote_item_request_no_item_request_yet => '暂无项目请求';

  @override
  String get vote_item_request_search_artist => 'Search Artist';

  @override
  String get vote_item_request_search_artist_prompt => '搜索艺术家进行申请';

  @override
  String vote_item_request_item_request_count(Object count) {
    return '$count个项目请求';
  }

  @override
  String vote_item_request_total_item_requests(Object count) {
    return '总共$count个项目请求';
  }

  @override
  String get vote_item_request_submit => '提交申请';

  @override
  String get vote_item_request_already_registered => '已注册';

  @override
  String get vote_item_request_can_apply => 'Can apply';

  @override
  String get vote_item_request_status_pending => '等待中';

  @override
  String get vote_item_request_status_approved => '已批准';

  @override
  String get vote_item_request_status_rejected => '已拒绝';

  @override
  String get vote_item_request_status_in_progress => 'In Progress';

  @override
  String get vote_item_request_status_cancelled => 'Cancelled';

  @override
  String get vote_item_request_status_unknown => 'Unknown';

  @override
  String get vote_item_request_artist_name_missing => '艺术家姓名缺失';

  @override
  String get vote_item_request_user_info_not_found => '找不到用户信息。';

  @override
  String get vote_item_request_already_applied_artist =>
      'You have already applied for this artist.';

  @override
  String get vote_item_request_addition_request => '投票项目添加请求';

  @override
  String get label_tabbar_vote_active => 'Active';

  @override
  String get label_tabbar_vote_image => '图片投票';

  @override
  String get label_tabbar_vote_end => 'Ended';

  @override
  String get label_tabbar_vote_upcoming => 'Upcoming';
}

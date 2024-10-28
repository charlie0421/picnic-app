// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a ja locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names, avoid_escaping_inner_quotes
// ignore_for_file:unnecessary_string_interpolations, unnecessary_string_escapes

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'ja';

  static String m0(day) => "${day}日前";

  static String m1(hour) => "${hour}時間前";

  static String m2(minute) => "${minute}分前";

  static String m3(nickname) => "${nickname}さんへの返信中...";

  static String m4(num1) => "${num1}개 +${num1}개 보너스";

  static String m5(rank) => "${rank}位";

  static String m6(version) => "新しいバージョン(${version})が利用可能です。";

  static String m7(version) => "新しいバージョン(${version})へのアップデートが必要です。";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "ads_available_time": MessageLookupByLibrary.simpleMessage("広告視聴可能時間"),
        "anonymous": MessageLookupByLibrary.simpleMessage("匿名"),
        "anonymous_mode": MessageLookupByLibrary.simpleMessage("匿名モード"),
        "app_name": MessageLookupByLibrary.simpleMessage("ピクニック"),
        "button_cancel": MessageLookupByLibrary.simpleMessage("キャンセル"),
        "button_complete": MessageLookupByLibrary.simpleMessage("完了"),
        "button_login": MessageLookupByLibrary.simpleMessage("ログイン"),
        "button_ok": MessageLookupByLibrary.simpleMessage("確認"),
        "button_pic_pic_save": MessageLookupByLibrary.simpleMessage("保存する"),
        "candy_disappear_next_month":
            MessageLookupByLibrary.simpleMessage("消滅予定ボーナス星空キャンディー😢(消失予定)"),
        "candy_usage_policy_contents": MessageLookupByLibrary.simpleMessage(
            "今月獲得したボーナススターキャンディーは、翌月15日に消滅します。"),
        "candy_usage_policy_contents2": MessageLookupByLibrary.simpleMessage(
            "星飴を使用する場合、消滅が近い星飴が優先的に使用されます。"),
        "candy_usage_policy_guide":
            MessageLookupByLibrary.simpleMessage("*ボーナスは獲得した翌月に消滅します！"),
        "candy_usage_policy_guide_button":
            MessageLookupByLibrary.simpleMessage("詳細を見る"),
        "candy_usage_policy_title":
            MessageLookupByLibrary.simpleMessage("スターキャンディー使用ポリシー"),
        "common_all": MessageLookupByLibrary.simpleMessage("全体"),
        "common_fail": MessageLookupByLibrary.simpleMessage("失敗"),
        "common_retry_label": MessageLookupByLibrary.simpleMessage("再試行"),
        "common_success": MessageLookupByLibrary.simpleMessage("成功"),
        "common_text_no_data":
            MessageLookupByLibrary.simpleMessage("データがありません。"),
        "common_text_no_search_result":
            MessageLookupByLibrary.simpleMessage("検索結果がありません。"),
        "common_text_search_error":
            MessageLookupByLibrary.simpleMessage("検索中にエラーが発生しました。"),
        "common_text_search_recent_label":
            MessageLookupByLibrary.simpleMessage("最近の検索ワード"),
        "common_text_search_result_label":
            MessageLookupByLibrary.simpleMessage("検索結果"),
        "dialog_button_cancel": MessageLookupByLibrary.simpleMessage("キャンセル"),
        "dialog_button_ok": MessageLookupByLibrary.simpleMessage("確認"),
        "dialog_content_ads_exhausted":
            MessageLookupByLibrary.simpleMessage("広告がなくなりました。次回、もう一度お試しください。"),
        "dialog_content_ads_loading":
            MessageLookupByLibrary.simpleMessage("広告の読み込み中です。"),
        "dialog_content_ads_retrying": MessageLookupByLibrary.simpleMessage(
            "広告を再呼び出し中です。しばらくしてからもう一度お試しください。"),
        "dialog_content_login_required":
            MessageLookupByLibrary.simpleMessage("ログインが必要です"),
        "dialog_message_can_resignup":
            MessageLookupByLibrary.simpleMessage("今すぐ退会した場合、再入会可能日"),
        "dialog_message_purchase_canceled":
            MessageLookupByLibrary.simpleMessage("購入がキャンセルされました。"),
        "dialog_message_purchase_failed": MessageLookupByLibrary.simpleMessage(
            "購入中にエラーが発生しました。 後ほど再試行してください。"),
        "dialog_message_purchase_success":
            MessageLookupByLibrary.simpleMessage("購入が正常に完了しました。"),
        "dialog_purchases_fail":
            MessageLookupByLibrary.simpleMessage("購入に失敗しました。"),
        "dialog_purchases_success":
            MessageLookupByLibrary.simpleMessage("購入が完了しました。"),
        "dialog_title_ads_exhausted":
            MessageLookupByLibrary.simpleMessage("広告完売しました"),
        "dialog_title_vote_fail": MessageLookupByLibrary.simpleMessage("投票失敗"),
        "dialog_will_delete_star_candy":
            MessageLookupByLibrary.simpleMessage("削除予定 星飴"),
        "dialog_withdraw_button_cancel":
            MessageLookupByLibrary.simpleMessage("もう一度考えてみます"),
        "dialog_withdraw_button_ok":
            MessageLookupByLibrary.simpleMessage("退会する"),
        "dialog_withdraw_error":
            MessageLookupByLibrary.simpleMessage("退会中にエラーが発生しました。"),
        "dialog_withdraw_message": MessageLookupByLibrary.simpleMessage(
            "退会時、ピクニックで保有している星キャンディーとアカウント情報は即座に削除され、再入会時、既存の情報及びデータは復旧されません。"),
        "dialog_withdraw_success":
            MessageLookupByLibrary.simpleMessage("退会が正常に処理されました。"),
        "dialog_withdraw_title":
            MessageLookupByLibrary.simpleMessage("本当に退会しますか？"),
        "error_message_login_failed":
            MessageLookupByLibrary.simpleMessage("ログイン中にエラーが発生しました。"),
        "error_message_no_user":
            MessageLookupByLibrary.simpleMessage("会員情報が存在しません。"),
        "error_message_withdrawal":
            MessageLookupByLibrary.simpleMessage("退会した会員です。"),
        "error_title": MessageLookupByLibrary.simpleMessage("エラー"),
        "hint_library_add": MessageLookupByLibrary.simpleMessage("アルバム名"),
        "hint_nickname_input":
            MessageLookupByLibrary.simpleMessage("ニックネームを入力してください。"),
        "image_save_success":
            MessageLookupByLibrary.simpleMessage("画像が保存されました。"),
        "label_ads_exceeded":
            MessageLookupByLibrary.simpleMessage("IDごとに視聴可能な広告を使い切りました。"),
        "label_ads_next_available_time":
            MessageLookupByLibrary.simpleMessage("次の広告視聴可能時間。"),
        "label_agreement_privacy":
            MessageLookupByLibrary.simpleMessage("個人情報収集及び利用同意"),
        "label_agreement_terms":
            MessageLookupByLibrary.simpleMessage("利用規約に同意する"),
        "label_album_add": MessageLookupByLibrary.simpleMessage("新しいアルバムを追加"),
        "label_article_comment_empty":
            MessageLookupByLibrary.simpleMessage("最初のコメントの主人公になりましょう！"),
        "label_bonus": MessageLookupByLibrary.simpleMessage("ボーナス"),
        "label_button_agreement": MessageLookupByLibrary.simpleMessage("同意する"),
        "label_button_close": MessageLookupByLibrary.simpleMessage("閉じる"),
        "label_button_disagreement":
            MessageLookupByLibrary.simpleMessage("非同意"),
        "label_button_recharge": MessageLookupByLibrary.simpleMessage("充電する"),
        "label_button_save_vote_paper":
            MessageLookupByLibrary.simpleMessage("投票券の保存"),
        "label_button_share": MessageLookupByLibrary.simpleMessage("シェアする"),
        "label_button_vote": MessageLookupByLibrary.simpleMessage("投票する"),
        "label_button_watch_and_charge":
            MessageLookupByLibrary.simpleMessage("広告を見てチャージする"),
        "label_celeb_ask_to_you":
            MessageLookupByLibrary.simpleMessage("アーティストがあなたに尋ねる！"),
        "label_celeb_gallery":
            MessageLookupByLibrary.simpleMessage("アーティストギャラリー"),
        "label_celeb_recommend":
            MessageLookupByLibrary.simpleMessage("アーティスト推薦"),
        "label_checkbox_entire_use":
            MessageLookupByLibrary.simpleMessage("全体使用"),
        "label_current_language": MessageLookupByLibrary.simpleMessage("現在の言語"),
        "label_draw_image":
            MessageLookupByLibrary.simpleMessage("ランダム画像獲得チャンス"),
        "label_dropdown_oldest": MessageLookupByLibrary.simpleMessage("古い順"),
        "label_dropdown_recent": MessageLookupByLibrary.simpleMessage("最新順"),
        "label_find_celeb":
            MessageLookupByLibrary.simpleMessage("その他のアーティストを探す"),
        "label_gallery_tab_article": MessageLookupByLibrary.simpleMessage("記事"),
        "label_gallery_tab_chat": MessageLookupByLibrary.simpleMessage("チャット"),
        "label_hint_comment":
            MessageLookupByLibrary.simpleMessage("コメントを残してください。"),
        "label_input_input": MessageLookupByLibrary.simpleMessage("入力"),
        "label_last_provider": MessageLookupByLibrary.simpleMessage("最近のログイン"),
        "label_library_save": MessageLookupByLibrary.simpleMessage("ライブラリ保存"),
        "label_library_tab_ai_photo":
            MessageLookupByLibrary.simpleMessage("AIフォト"),
        "label_library_tab_library":
            MessageLookupByLibrary.simpleMessage("ライブラリ"),
        "label_library_tab_pic": MessageLookupByLibrary.simpleMessage("PIC"),
        "label_loading_ads": MessageLookupByLibrary.simpleMessage("広告読み込み中"),
        "label_loading_ads_fail":
            MessageLookupByLibrary.simpleMessage("広告の読み込みに失敗"),
        "label_moveto_celeb_gallery":
            MessageLookupByLibrary.simpleMessage("アーティストギャラリーへ"),
        "label_mypage_charge_history":
            MessageLookupByLibrary.simpleMessage("料金内訳"),
        "label_mypage_customer_center":
            MessageLookupByLibrary.simpleMessage("お客様センター"),
        "label_mypage_logout": MessageLookupByLibrary.simpleMessage("ログアウト"),
        "label_mypage_membership_history":
            MessageLookupByLibrary.simpleMessage("メンバーシップ履歴"),
        "label_mypage_my_artist":
            MessageLookupByLibrary.simpleMessage("私のアーティスト"),
        "label_mypage_no_artist":
            MessageLookupByLibrary.simpleMessage("マイアーティストを登録してください。"),
        "label_mypage_notice": MessageLookupByLibrary.simpleMessage("お知らせ"),
        "label_mypage_picnic_id":
            MessageLookupByLibrary.simpleMessage("アイデンティティ"),
        "label_mypage_privacy_policy":
            MessageLookupByLibrary.simpleMessage("個人情報保護方針"),
        "label_mypage_setting": MessageLookupByLibrary.simpleMessage("設定"),
        "label_mypage_should_login":
            MessageLookupByLibrary.simpleMessage("ログインしてください"),
        "label_mypage_terms_of_use":
            MessageLookupByLibrary.simpleMessage("利用規約"),
        "label_mypage_vote_history":
            MessageLookupByLibrary.simpleMessage("スターキャンディーの投票履歴"),
        "label_mypage_withdrawal": MessageLookupByLibrary.simpleMessage("退会する"),
        "label_no_ads": MessageLookupByLibrary.simpleMessage("広告なし"),
        "label_no_celeb":
            MessageLookupByLibrary.simpleMessage("まだブックマークしたアーティストはいません！"),
        "label_pic_image_cropping":
            MessageLookupByLibrary.simpleMessage("画像の切り抜き"),
        "label_pic_pic_initializing_camera":
            MessageLookupByLibrary.simpleMessage("カメラの初期化中..."),
        "label_pic_pic_save_gallery":
            MessageLookupByLibrary.simpleMessage("ギャラリーに保存"),
        "label_pic_pic_synthesizing_image":
            MessageLookupByLibrary.simpleMessage("画像合成中..."),
        "label_read_more_comment":
            MessageLookupByLibrary.simpleMessage("コメントをもっと見る"),
        "label_reply": MessageLookupByLibrary.simpleMessage("返信する"),
        "label_retry": MessageLookupByLibrary.simpleMessage("再試行する"),
        "label_screen_title_agreement":
            MessageLookupByLibrary.simpleMessage("規約に同意する"),
        "label_setting_alarm": MessageLookupByLibrary.simpleMessage("お知らせ"),
        "label_setting_appinfo": MessageLookupByLibrary.simpleMessage("アプリ情報"),
        "label_setting_current_version":
            MessageLookupByLibrary.simpleMessage("現在のバージョン"),
        "label_setting_event_alarm":
            MessageLookupByLibrary.simpleMessage("イベントお知らせ"),
        "label_setting_event_alarm_desc":
            MessageLookupByLibrary.simpleMessage("各種イベントや行事をご案内します。"),
        "label_setting_language": MessageLookupByLibrary.simpleMessage("言語設定"),
        "label_setting_push_alarm":
            MessageLookupByLibrary.simpleMessage("プッシュ通知"),
        "label_setting_recent_version":
            MessageLookupByLibrary.simpleMessage("最新バージョン"),
        "label_setting_recent_version_up_to_date":
            MessageLookupByLibrary.simpleMessage("最新バージョン"),
        "label_setting_remove_cache":
            MessageLookupByLibrary.simpleMessage("キャッシュメモリの削除"),
        "label_setting_remove_cache_complete":
            MessageLookupByLibrary.simpleMessage("完了"),
        "label_setting_storage":
            MessageLookupByLibrary.simpleMessage("ストレージスペース管理"),
        "label_setting_update": MessageLookupByLibrary.simpleMessage("最新情報"),
        "label_star_candy_pouch":
            MessageLookupByLibrary.simpleMessage("スターキャンディーの袋"),
        "label_tab_buy_star_candy":
            MessageLookupByLibrary.simpleMessage("スターキャンディーの購入"),
        "label_tab_free_charge_station":
            MessageLookupByLibrary.simpleMessage("無料充電ステーション"),
        "label_tab_my_artist": MessageLookupByLibrary.simpleMessage("マイアーティスト"),
        "label_tab_search_my_artist":
            MessageLookupByLibrary.simpleMessage("マイアーティストを探す"),
        "label_tabbar_picchart_daily":
            MessageLookupByLibrary.simpleMessage("日足チャート"),
        "label_tabbar_picchart_monthly":
            MessageLookupByLibrary.simpleMessage("月間チャート"),
        "label_tabbar_picchart_weekly":
            MessageLookupByLibrary.simpleMessage("週間チャート"),
        "label_tabbar_vote_active": MessageLookupByLibrary.simpleMessage("進行中"),
        "label_tabbar_vote_end": MessageLookupByLibrary.simpleMessage("終了"),
        "label_tabbar_vote_upcoming":
            MessageLookupByLibrary.simpleMessage("予定"),
        "label_time_ago_day": m0,
        "label_time_ago_hour": m1,
        "label_time_ago_minute": m2,
        "label_time_ago_right_now": MessageLookupByLibrary.simpleMessage("先ほど"),
        "label_title_comment": MessageLookupByLibrary.simpleMessage("コメント"),
        "label_title_report": MessageLookupByLibrary.simpleMessage("報告する"),
        "label_vote_end": MessageLookupByLibrary.simpleMessage("投票終了"),
        "label_vote_reward_list":
            MessageLookupByLibrary.simpleMessage("リワードリスト"),
        "label_vote_screen_title": MessageLookupByLibrary.simpleMessage("投票"),
        "label_vote_tab_birthday":
            MessageLookupByLibrary.simpleMessage("誕生日投票"),
        "label_vote_tab_pic": MessageLookupByLibrary.simpleMessage("PIC投票"),
        "label_vote_upcoming": MessageLookupByLibrary.simpleMessage("投票開始まで"),
        "label_vote_vote_gather":
            MessageLookupByLibrary.simpleMessage("投票集を見る"),
        "label_watch_ads": MessageLookupByLibrary.simpleMessage("広告を見る"),
        "lable_my_celeb": MessageLookupByLibrary.simpleMessage("私のアーティスト"),
        "message_agreement_success":
            MessageLookupByLibrary.simpleMessage("規約の同意が完了しました。"),
        "message_error_occurred":
            MessageLookupByLibrary.simpleMessage("エラーが発生しました。"),
        "message_noitem_vote_active":
            MessageLookupByLibrary.simpleMessage("現在進行中の投票はありません。"),
        "message_noitem_vote_end":
            MessageLookupByLibrary.simpleMessage("現在、終了した投票はありません。"),
        "message_noitem_vote_upcoming":
            MessageLookupByLibrary.simpleMessage("現在予定されている投票はありません。"),
        "message_pic_pic_save_fail":
            MessageLookupByLibrary.simpleMessage("画像の保存に失敗しました。"),
        "message_pic_pic_save_success":
            MessageLookupByLibrary.simpleMessage("画像が保存されました。"),
        "message_report_confirm":
            MessageLookupByLibrary.simpleMessage("申告しますか？"),
        "message_report_ok": MessageLookupByLibrary.simpleMessage("申告が完了しました。"),
        "message_setting_remove_cache":
            MessageLookupByLibrary.simpleMessage("キャッシュメモリの削除が完了しました"),
        "message_update_nickname_fail": MessageLookupByLibrary.simpleMessage(
            "ニックネームの変更に失敗しました。\n別のニックネームを選択してください。"),
        "message_update_nickname_success":
            MessageLookupByLibrary.simpleMessage("ニックネームが正常に変更されました。"),
        "message_vote_is_ended":
            MessageLookupByLibrary.simpleMessage("投票は終了しました"),
        "message_vote_is_upcoming":
            MessageLookupByLibrary.simpleMessage("予定されている投票です"),
        "mypage_comment": MessageLookupByLibrary.simpleMessage("コメント管理"),
        "mypage_language": MessageLookupByLibrary.simpleMessage("言語設定"),
        "mypage_purchases": MessageLookupByLibrary.simpleMessage("私の購入"),
        "mypage_setting": MessageLookupByLibrary.simpleMessage("設定"),
        "mypage_subscription": MessageLookupByLibrary.simpleMessage("購読情報"),
        "nav_ads": MessageLookupByLibrary.simpleMessage("広告"),
        "nav_board": MessageLookupByLibrary.simpleMessage("掲示板"),
        "nav_gallery": MessageLookupByLibrary.simpleMessage("ギャラリー"),
        "nav_home": MessageLookupByLibrary.simpleMessage("ホーム"),
        "nav_library": MessageLookupByLibrary.simpleMessage("ライブラリ"),
        "nav_media": MessageLookupByLibrary.simpleMessage("メディア"),
        "nav_my": MessageLookupByLibrary.simpleMessage("マイ"),
        "nav_picchart": MessageLookupByLibrary.simpleMessage("PICチャート"),
        "nav_purchases": MessageLookupByLibrary.simpleMessage("購入"),
        "nav_setting": MessageLookupByLibrary.simpleMessage("設定"),
        "nav_store": MessageLookupByLibrary.simpleMessage("ショップ"),
        "nav_subscription": MessageLookupByLibrary.simpleMessage("サブスクリプション"),
        "nav_vote": MessageLookupByLibrary.simpleMessage("投票"),
        "nickname_validation_error":
            MessageLookupByLibrary.simpleMessage("20文字以内、特殊文字を除くことができます。"),
        "page_title_mypage": MessageLookupByLibrary.simpleMessage("マイページ"),
        "page_title_myprofile":
            MessageLookupByLibrary.simpleMessage("私のプロフィール"),
        "page_title_post_write": MessageLookupByLibrary.simpleMessage("投稿の作成"),
        "page_title_privacy": MessageLookupByLibrary.simpleMessage("個人情報保護方針"),
        "page_title_setting": MessageLookupByLibrary.simpleMessage("環境設定"),
        "page_title_terms_of_use": MessageLookupByLibrary.simpleMessage("利用規約"),
        "page_title_vote_detail": MessageLookupByLibrary.simpleMessage("投票する"),
        "page_title_vote_gather":
            MessageLookupByLibrary.simpleMessage("投票集を見る"),
        "popup_label_delete": MessageLookupByLibrary.simpleMessage("削除"),
        "post_anonymous": MessageLookupByLibrary.simpleMessage("匿名投稿"),
        "post_ask_go_to_temporary_save_list":
            MessageLookupByLibrary.simpleMessage("一時保存リストに移動しますか？"),
        "post_board_already_exist":
            MessageLookupByLibrary.simpleMessage("すでに存在する掲示板です。"),
        "post_board_create_request_complete":
            MessageLookupByLibrary.simpleMessage("掲示板のオープンリクエストが完了しました。"),
        "post_board_create_request_condition":
            MessageLookupByLibrary.simpleMessage(
                "*1つのIDにつき1つのマイナー掲示板のみ申請が可能です。"),
        "post_board_create_request_label":
            MessageLookupByLibrary.simpleMessage("掲示板オープンリクエスト"),
        "post_board_create_request_reviewing":
            MessageLookupByLibrary.simpleMessage("掲示板オープンリクエスト検討中"),
        "post_board_request_label":
            MessageLookupByLibrary.simpleMessage("オープンリクエスト"),
        "post_cannot_open_youtube":
            MessageLookupByLibrary.simpleMessage("Youtubeを開くことができません。"),
        "post_comment_action_translate":
            MessageLookupByLibrary.simpleMessage("翻訳"),
        "post_comment_content_more":
            MessageLookupByLibrary.simpleMessage("もっと見る"),
        "post_comment_delete_confirm":
            MessageLookupByLibrary.simpleMessage("コメントを削除しますか？"),
        "post_comment_delete_fail":
            MessageLookupByLibrary.simpleMessage("コメントの削除に失敗しました。"),
        "post_comment_deleted_comment":
            MessageLookupByLibrary.simpleMessage("削除されたコメントです。"),
        "post_comment_like_processing_fail":
            MessageLookupByLibrary.simpleMessage("いいね処理に失敗しました。"),
        "post_comment_loading_fail":
            MessageLookupByLibrary.simpleMessage("コメントの読み込みに失敗しました。"),
        "post_comment_register_fail":
            MessageLookupByLibrary.simpleMessage("コメント登録に失敗しました。"),
        "post_comment_registered_comment":
            MessageLookupByLibrary.simpleMessage("コメントが登録されました。"),
        "post_comment_reported_comment":
            MessageLookupByLibrary.simpleMessage("報告されたコメントです。"),
        "post_comment_translate_complete":
            MessageLookupByLibrary.simpleMessage("翻訳が完了しました。"),
        "post_comment_translate_fail":
            MessageLookupByLibrary.simpleMessage("翻訳に失敗しました。"),
        "post_comment_translated": MessageLookupByLibrary.simpleMessage("翻訳済み"),
        "post_comment_write_label":
            MessageLookupByLibrary.simpleMessage("コメントを書く"),
        "post_content_placeholder":
            MessageLookupByLibrary.simpleMessage("内容を入力してください。"),
        "post_delete_scrap_confirm":
            MessageLookupByLibrary.simpleMessage("スクラップを削除しますか？"),
        "post_delete_scrap_title":
            MessageLookupByLibrary.simpleMessage("スクラップ削除"),
        "post_go_to_boards": MessageLookupByLibrary.simpleMessage("掲示板に移動"),
        "post_header_publish": MessageLookupByLibrary.simpleMessage("投稿"),
        "post_header_temporary_save":
            MessageLookupByLibrary.simpleMessage("一時保存"),
        "post_hint_title":
            MessageLookupByLibrary.simpleMessage("タイトルを入力してください。"),
        "post_hyperlink": MessageLookupByLibrary.simpleMessage("ハイパーリンク"),
        "post_insert_link": MessageLookupByLibrary.simpleMessage("リンク挿入"),
        "post_loading_post_fail":
            MessageLookupByLibrary.simpleMessage("投稿の読み込みに失敗しました。"),
        "post_minor_board_condition":
            MessageLookupByLibrary.simpleMessage("説明は5文字以上20文字以内で入力してください。"),
        "post_minor_board_create_request_message":
            MessageLookupByLibrary.simpleMessage("* 掲示板オープンリクエストのメッセージ。"),
        "post_minor_board_create_request_message_condition":
            MessageLookupByLibrary.simpleMessage(
                "掲示板オープンリクエストメッセージは10文字以上入力してください。"),
        "post_minor_board_create_request_message_input":
            MessageLookupByLibrary.simpleMessage("掲示板オープンリクエストメッセージを入力してください。"),
        "post_minor_board_description":
            MessageLookupByLibrary.simpleMessage("マイナー掲示板の説明"),
        "post_minor_board_description_input":
            MessageLookupByLibrary.simpleMessage("マイナー掲示板の説明を入力してください。"),
        "post_minor_board_name":
            MessageLookupByLibrary.simpleMessage("マイナー掲示板名"),
        "post_minor_board_name_input":
            MessageLookupByLibrary.simpleMessage("マイナー掲示板名を入力してください。"),
        "post_my_written_post": MessageLookupByLibrary.simpleMessage("私が書いた記事"),
        "post_my_written_reply":
            MessageLookupByLibrary.simpleMessage("私が書いたコメント"),
        "post_my_written_scrap":
            MessageLookupByLibrary.simpleMessage("私のスクラップ"),
        "post_no_comment": MessageLookupByLibrary.simpleMessage("コメントはありません。"),
        "post_replying_comment": m3,
        "post_report_fail": MessageLookupByLibrary.simpleMessage("申告に失敗しました。"),
        "post_report_label": MessageLookupByLibrary.simpleMessage("報告する"),
        "post_report_other_input":
            MessageLookupByLibrary.simpleMessage("その他の理由を入力してください。"),
        "post_report_reason_1":
            MessageLookupByLibrary.simpleMessage("公序良俗に反する投稿"),
        "post_report_reason_2":
            MessageLookupByLibrary.simpleMessage("男女、人種差別的な投稿"),
        "post_report_reason_3":
            MessageLookupByLibrary.simpleMessage("不愉快な罵詈雑言を含む投稿"),
        "post_report_reason_4":
            MessageLookupByLibrary.simpleMessage("広告・宣伝性の投稿"),
        "post_report_reason_5": MessageLookupByLibrary.simpleMessage("その他"),
        "post_report_reason_input":
            MessageLookupByLibrary.simpleMessage("申告理由を選択してください。"),
        "post_report_reason_label":
            MessageLookupByLibrary.simpleMessage("申告理由"),
        "post_report_success":
            MessageLookupByLibrary.simpleMessage("申告が完了しました。"),
        "post_temporary_save_complete":
            MessageLookupByLibrary.simpleMessage("一時保存完了。"),
        "post_title_placeholder":
            MessageLookupByLibrary.simpleMessage("タイトルを入力してください。"),
        "post_write_board_post": MessageLookupByLibrary.simpleMessage("投稿する"),
        "post_write_post_recommend_write":
            MessageLookupByLibrary.simpleMessage("投稿をお願いします。"),
        "post_youtube_link": MessageLookupByLibrary.simpleMessage("ユーチューブリンク"),
        "purchase_web_message": MessageLookupByLibrary.simpleMessage(
            "アプリ決済ができない方のための決済画面です.\\nあらかじめ乱数IDをコピーしてください.\\nコピーした後、下のボタンを押して決済を行ってください。"),
        "replies": MessageLookupByLibrary.simpleMessage("コメント"),
        "share_image_fail": MessageLookupByLibrary.simpleMessage("画像共有に失敗"),
        "share_image_success": MessageLookupByLibrary.simpleMessage("画像共有成功"),
        "share_no_twitter": MessageLookupByLibrary.simpleMessage("Xアプリがありません。"),
        "share_twitter": MessageLookupByLibrary.simpleMessage("Twitter共有"),
        "text_ads_random":
            MessageLookupByLibrary.simpleMessage("広告表示とランダム画像収集。"),
        "text_bonus": MessageLookupByLibrary.simpleMessage("ボーナス"),
        "text_bookmark_failed":
            MessageLookupByLibrary.simpleMessage("ブックマーク解除に失敗しました"),
        "text_bookmark_over_5":
            MessageLookupByLibrary.simpleMessage("ブックマークは最大5個まで可能です。"),
        "text_comming_soon_pic_chart1": MessageLookupByLibrary.simpleMessage(
            "ピックチャートへようこそ！\n2024年11月にお会いしましょう！"),
        "text_comming_soon_pic_chart2": MessageLookupByLibrary.simpleMessage(
            "ピックチャートは、日次、週次、月次のスコアを反映している\nピクニックならではの新しいチャートです。"),
        "text_comming_soon_pic_chart3": MessageLookupByLibrary.simpleMessage(
            "リアルタイムで反映される\nアーティストのブランド評判をご確認ください！"),
        "text_comming_soon_pic_chart_title":
            MessageLookupByLibrary.simpleMessage("ピクチャーチャートとは？"),
        "text_community_board_search":
            MessageLookupByLibrary.simpleMessage("アーティスト掲示板検索"),
        "text_community_post_search":
            MessageLookupByLibrary.simpleMessage("検索"),
        "text_copied_address":
            MessageLookupByLibrary.simpleMessage("アドレスがコピーされました。"),
        "text_dialog_ad_dismissed":
            MessageLookupByLibrary.simpleMessage("広告を途中で止めました。"),
        "text_dialog_ad_failed_to_show":
            MessageLookupByLibrary.simpleMessage("広告の読み込みに失敗"),
        "text_dialog_star_candy_received":
            MessageLookupByLibrary.simpleMessage("星飴が支給されました。"),
        "text_dialog_vote_amount_should_not_zero":
            MessageLookupByLibrary.simpleMessage("投票数は0にすることはできません。"),
        "text_draw_image":
            MessageLookupByLibrary.simpleMessage("全ギャラリーのうち、1枚の画像を確定的に所蔵"),
        "text_hint_search": MessageLookupByLibrary.simpleMessage("アーティスト検索"),
        "text_moveto_celeb_gallery":
            MessageLookupByLibrary.simpleMessage("選択したアーティストの家に移動します。"),
        "text_need_recharge": MessageLookupByLibrary.simpleMessage("充電が必要です。"),
        "text_no_artist": MessageLookupByLibrary.simpleMessage("アーティストがいません"),
        "text_no_search_result":
            MessageLookupByLibrary.simpleMessage("検索結果がありません。"),
        "text_purchase_vat_included":
            MessageLookupByLibrary.simpleMessage("*価格はVAT込みの価格です。"),
        "text_star_candy": MessageLookupByLibrary.simpleMessage("スターキャンディー"),
        "text_star_candy_with_bonus": m4,
        "text_this_time_vote": MessageLookupByLibrary.simpleMessage("今回の投票"),
        "text_vote_complete": MessageLookupByLibrary.simpleMessage("投票完了"),
        "text_vote_rank": m5,
        "text_vote_rank_in_reward":
            MessageLookupByLibrary.simpleMessage("ランクインリワード"),
        "text_vote_where_is_my_bias":
            MessageLookupByLibrary.simpleMessage("私のお気に入りはどこ？"),
        "title_dialog_library_add":
            MessageLookupByLibrary.simpleMessage("新しいアルバムを追加"),
        "title_dialog_success": MessageLookupByLibrary.simpleMessage("成功"),
        "title_select_language": MessageLookupByLibrary.simpleMessage("言語の選択"),
        "toast_max_five_celeb":
            MessageLookupByLibrary.simpleMessage("マイアーティストは最大5人まで追加できます。"),
        "update_button": MessageLookupByLibrary.simpleMessage("最新情報"),
        "update_cannot_open_appstore":
            MessageLookupByLibrary.simpleMessage("アプリストアを開くことができません。"),
        "update_recommend_text": m6,
        "update_required_text": m7,
        "update_required_title":
            MessageLookupByLibrary.simpleMessage("アップデートが必要です。"),
        "views": MessageLookupByLibrary.simpleMessage("再生回数")
      };
}

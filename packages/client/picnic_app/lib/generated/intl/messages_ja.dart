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

  static String m0(day) => "${day}일 전";

  static String m1(hour) => "${hour}시간 전";

  static String m2(minute) => "${minute}분 전";

  static String m3(num1) => "${num1}개 +${num1}개 보너스";

  static String m4(rank) => "第${rank}位";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "app_name": MessageLookupByLibrary.simpleMessage("ピクニック"),
        "button_cancel": MessageLookupByLibrary.simpleMessage("キャンセル"),
        "button_complete": MessageLookupByLibrary.simpleMessage("完了"),
        "button_login": MessageLookupByLibrary.simpleMessage("ログイン"),
        "button_ok": MessageLookupByLibrary.simpleMessage("確認"),
        "button_pic_pic_save": MessageLookupByLibrary.simpleMessage("保存する"),
        "candy_usage_policy_contents": MessageLookupByLibrary.simpleMessage(
            "### 有効期限\n\n- 星飴は獲得日から1年間有効です。\n\n星飴獲得 ### 星飴獲得\n\nログイン : 1日1回\n- 投票 : 1回につき1個\n購入星飴 : なし(無制限)\nボーナス星飴：獲得した翌月の15日に一括消滅\n\n##### 星飴を使う\n\n消滅日が迫っている星飴から使用されます。\n有効期限が同じ場合は、獲得日が早い順に使用されます。"),
        "candy_usage_policy_guide":
            MessageLookupByLibrary.simpleMessage("*ボーナスは獲得した翌月に無くなります！ ⓘ※ボーナス"),
        "candy_usage_policy_title":
            MessageLookupByLibrary.simpleMessage("スターキャンディー使用ポリシー"),
        "dialog_button_cancel": MessageLookupByLibrary.simpleMessage("キャンセル"),
        "dialog_button_ok": MessageLookupByLibrary.simpleMessage("確認"),
        "dialog_content_ads_loading":
            MessageLookupByLibrary.simpleMessage("広告の読み込み中です。"),
        "dialog_content_login_required":
            MessageLookupByLibrary.simpleMessage("ログインが必要です"),
        "dialog_title_vote_fail": MessageLookupByLibrary.simpleMessage("投票失敗"),
        "dialog_withdraw_button_cancel":
            MessageLookupByLibrary.simpleMessage("もう一度考えてみます。"),
        "dialog_withdraw_button_ok":
            MessageLookupByLibrary.simpleMessage("退会する"),
        "dialog_withdraw_error":
            MessageLookupByLibrary.simpleMessage("退会中にエラーが発生しました。"),
        "dialog_withdraw_message": MessageLookupByLibrary.simpleMessage(
            "退会すると、ピクニックで保有している星キャンディーとアカウント情報は即座に削除されます。"),
        "dialog_withdraw_success":
            MessageLookupByLibrary.simpleMessage("退会が正常に処理されました。"),
        "dialog_withdraw_title":
            MessageLookupByLibrary.simpleMessage("本当に退会しますか？"),
        "hint_library_add": MessageLookupByLibrary.simpleMessage("アルバム名"),
        "hint_nickname_input":
            MessageLookupByLibrary.simpleMessage("ニックネームを入力してください。"),
        "image_save_success":
            MessageLookupByLibrary.simpleMessage("画像が保存されました。"),
        "label_album_add": MessageLookupByLibrary.simpleMessage("新しいアルバムを追加"),
        "label_article_comment_empty":
            MessageLookupByLibrary.simpleMessage("最初のコメントの主人公になりましょう！"),
        "label_bonus": MessageLookupByLibrary.simpleMessage("ボーナス"),
        "label_button_clse": MessageLookupByLibrary.simpleMessage("閉じる"),
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
        "label_library_save": MessageLookupByLibrary.simpleMessage("ライブラリ保存"),
        "label_library_tab_ai_photo":
            MessageLookupByLibrary.simpleMessage("AIフォト"),
        "label_library_tab_library":
            MessageLookupByLibrary.simpleMessage("ライブラリ"),
        "label_library_tab_pic": MessageLookupByLibrary.simpleMessage("PIC"),
        "label_moveto_celeb_gallery":
            MessageLookupByLibrary.simpleMessage("アーティストギャラリーへ"),
        "label_mypage_charge_history":
            MessageLookupByLibrary.simpleMessage("料金内訳"),
        "label_mypage_customer_center":
            MessageLookupByLibrary.simpleMessage("お客様センター"),
        "label_mypage_logout": MessageLookupByLibrary.simpleMessage("ログアウト"),
        "label_mypage_membership_history":
            MessageLookupByLibrary.simpleMessage("メンバーシップ履歴"),
        "label_mypage_mystar": MessageLookupByLibrary.simpleMessage("マイスター"),
        "label_mypage_notice": MessageLookupByLibrary.simpleMessage("お知らせ"),
        "label_mypage_privacy_policy":
            MessageLookupByLibrary.simpleMessage("個人情報保護方針"),
        "label_mypage_setting": MessageLookupByLibrary.simpleMessage("設定"),
        "label_mypage_terms_of_use":
            MessageLookupByLibrary.simpleMessage("利用規約"),
        "label_mypage_vote_history":
            MessageLookupByLibrary.simpleMessage("投票履歴"),
        "label_mypage_withdrawal": MessageLookupByLibrary.simpleMessage("退会する"),
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
        "label_setting_remove_cache":
            MessageLookupByLibrary.simpleMessage("キャッシュ削除"),
        "label_setting_storage":
            MessageLookupByLibrary.simpleMessage("ストレージスペース管理"),
        "label_setting_update": MessageLookupByLibrary.simpleMessage("最新情報"),
        "label_star_candy_pouch":
            MessageLookupByLibrary.simpleMessage("スターキャンディーの袋"),
        "label_tab_buy_star_candy":
            MessageLookupByLibrary.simpleMessage("スターキャンディーの購入"),
        "label_tab_free_charge_station":
            MessageLookupByLibrary.simpleMessage("無料充電ステーション"),
        "label_tabbar_picchart_daily":
            MessageLookupByLibrary.simpleMessage("日足チャート"),
        "label_tabbar_picchart_monthly":
            MessageLookupByLibrary.simpleMessage("月次チャート"),
        "label_tabbar_picchart_weekly":
            MessageLookupByLibrary.simpleMessage("週間チャート"),
        "label_tabbar_vote_active": MessageLookupByLibrary.simpleMessage("進行中"),
        "label_tabbar_vote_end": MessageLookupByLibrary.simpleMessage("終了"),
        "label_time_ago_day": m0,
        "label_time_ago_hour": m1,
        "label_time_ago_minute": m2,
        "label_time_ago_right_now": MessageLookupByLibrary.simpleMessage("先ほど"),
        "label_title_comment": MessageLookupByLibrary.simpleMessage("コメント"),
        "label_title_report": MessageLookupByLibrary.simpleMessage("報告する"),
        "label_vote_reward_list":
            MessageLookupByLibrary.simpleMessage("リワードリスト"),
        "label_vote_screen_title": MessageLookupByLibrary.simpleMessage("投票"),
        "label_vote_tab_birthday":
            MessageLookupByLibrary.simpleMessage("誕生日投票"),
        "label_vote_tab_pic": MessageLookupByLibrary.simpleMessage("PIC投票"),
        "label_vote_vote_gather":
            MessageLookupByLibrary.simpleMessage("投票集を見る"),
        "label_watch_ads": MessageLookupByLibrary.simpleMessage("広告を見る"),
        "lable_my_celeb": MessageLookupByLibrary.simpleMessage("私のアーティスト"),
        "message_error_occurred":
            MessageLookupByLibrary.simpleMessage("エラーが発生しました。"),
        "message_pic_pic_save_fail":
            MessageLookupByLibrary.simpleMessage("画像の保存に失敗しました。"),
        "message_pic_pic_save_success":
            MessageLookupByLibrary.simpleMessage("画像が保存されました。"),
        "message_report_confirm":
            MessageLookupByLibrary.simpleMessage("申告しますか？"),
        "message_report_ok": MessageLookupByLibrary.simpleMessage("申告が完了しました。"),
        "mypage_comment": MessageLookupByLibrary.simpleMessage("コメント管理"),
        "mypage_language": MessageLookupByLibrary.simpleMessage("言語設定"),
        "mypage_purchases": MessageLookupByLibrary.simpleMessage("私の購入"),
        "mypage_setting": MessageLookupByLibrary.simpleMessage("設定"),
        "mypage_subscription": MessageLookupByLibrary.simpleMessage("購読情報"),
        "nav_ads": MessageLookupByLibrary.simpleMessage("広告"),
        "nav_gallery": MessageLookupByLibrary.simpleMessage("ギャラリー"),
        "nav_home": MessageLookupByLibrary.simpleMessage("홈"),
        "nav_library": MessageLookupByLibrary.simpleMessage("ライブラリ"),
        "nav_media": MessageLookupByLibrary.simpleMessage("メディア"),
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
        "page_title_privacy": MessageLookupByLibrary.simpleMessage("個人情報保護方針"),
        "page_title_setting": MessageLookupByLibrary.simpleMessage("環境設定"),
        "page_title_terms_of_use": MessageLookupByLibrary.simpleMessage("利用規約"),
        "page_title_vote_detail": MessageLookupByLibrary.simpleMessage("投票する"),
        "page_title_vote_gather":
            MessageLookupByLibrary.simpleMessage("投票集を見る"),
        "share_image_fail": MessageLookupByLibrary.simpleMessage("画像共有に失敗"),
        "share_image_success": MessageLookupByLibrary.simpleMessage("画像共有成功"),
        "share_no_twitter":
            MessageLookupByLibrary.simpleMessage("Twitterアプリがありません"),
        "share_twitter": MessageLookupByLibrary.simpleMessage("Twitter共有"),
        "text_ads_random":
            MessageLookupByLibrary.simpleMessage("広告表示とランダム画像収集。"),
        "text_bonus": MessageLookupByLibrary.simpleMessage("ボーナス"),
        "text_copied_address":
            MessageLookupByLibrary.simpleMessage("アドレスがコピーされました。"),
        "text_dialog_star_candy_received":
            MessageLookupByLibrary.simpleMessage("星飴が支給されました。"),
        "text_dialog_vote_amount_should_not_zero":
            MessageLookupByLibrary.simpleMessage("投票数は0にすることはできません。"),
        "text_draw_image":
            MessageLookupByLibrary.simpleMessage("全ギャラリーのうち、1枚の画像を確定的に所蔵"),
        "text_hint_search":
            MessageLookupByLibrary.simpleMessage("アーティストを検索してください。"),
        "text_moveto_celeb_gallery":
            MessageLookupByLibrary.simpleMessage("選択したアーティストの家に移動します。"),
        "text_need_recharge": MessageLookupByLibrary.simpleMessage("充電が必要です。"),
        "text_no_search_result":
            MessageLookupByLibrary.simpleMessage("検索結果がありません。"),
        "text_purchase_vat_included":
            MessageLookupByLibrary.simpleMessage("*価格はVAT込みの価格です。"),
        "text_star_candy": MessageLookupByLibrary.simpleMessage("スターキャンディー"),
        "text_star_candy_with_bonus": m3,
        "text_this_time_vote": MessageLookupByLibrary.simpleMessage("今回の投票"),
        "text_vote_complete": MessageLookupByLibrary.simpleMessage("投票完了"),
        "text_vote_rank": m4,
        "text_vote_rank_in_reward":
            MessageLookupByLibrary.simpleMessage("ランクインリワード"),
        "text_vote_where_is_my_bias":
            MessageLookupByLibrary.simpleMessage("私のお気に入りはどこ？"),
        "title_dialog_library_add":
            MessageLookupByLibrary.simpleMessage("新しいアルバムを追加"),
        "title_select_language": MessageLookupByLibrary.simpleMessage("言語の選択"),
        "toast_max_five_celeb":
            MessageLookupByLibrary.simpleMessage("マイアーティストは最大5人まで追加できます。")
      };
}

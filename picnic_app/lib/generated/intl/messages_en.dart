// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a en locale. All the
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
  String get localeName => 'en';

  static String m0(day) => "${day}일 전";

  static String m1(hour) => "${hour}시간 전";

  static String m2(minute) => "${minute}분 전";

  static String m3(num1) => "${num1}개 +${num1}개 보너스";

  static String m4(rank) => "rank ${rank}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "app_name": MessageLookupByLibrary.simpleMessage("Picnic"),
        "button_cancel": MessageLookupByLibrary.simpleMessage("Cancel"),
        "button_complete": MessageLookupByLibrary.simpleMessage("Done"),
        "button_login": MessageLookupByLibrary.simpleMessage("Sign in"),
        "button_ok": MessageLookupByLibrary.simpleMessage("Confirm"),
        "button_pic_pic_save": MessageLookupByLibrary.simpleMessage("Save"),
        "candy_usage_policy_contents": MessageLookupByLibrary.simpleMessage(
            "### Validity\n\n- Star Candies are valid for one year from the date of acquisition.\n\n### Earned Star Candy\n\nLogin: 1 per day\n- Votes: 1 per day\nStar Candy Purchases: None (unlimited)\nBonus Star Candy: Expires in batches on the 15th of the month after earned\n\n##### Redeem Star Candy\n\nStar Candies with an expiration date nearing the end of the month will be used first.\nIf they have the same expiration date, the earliest one will be used."),
        "candy_usage_policy_guide": MessageLookupByLibrary.simpleMessage(
            "*Bonuses disappear the month after you earn them! ⓘ"),
        "candy_usage_policy_title":
            MessageLookupByLibrary.simpleMessage("Stardust Usage Policy"),
        "dialog_button_cancel": MessageLookupByLibrary.simpleMessage("Cancel"),
        "dialog_button_ok": MessageLookupByLibrary.simpleMessage("Confirm"),
        "dialog_content_ads_exhausted": MessageLookupByLibrary.simpleMessage(
            "All ads have been exhausted. Please try again next time."),
        "dialog_content_ads_loading":
            MessageLookupByLibrary.simpleMessage("Ads are loading."),
        "dialog_content_ads_retrying": MessageLookupByLibrary.simpleMessage(
            "The ad is reloading. Please try again in a moment."),
        "dialog_content_login_required":
            MessageLookupByLibrary.simpleMessage("Login required"),
        "dialog_purchases_fail":
            MessageLookupByLibrary.simpleMessage("The purchase failed."),
        "dialog_purchases_success":
            MessageLookupByLibrary.simpleMessage("Your purchase is complete."),
        "dialog_title_ads_exhausted":
            MessageLookupByLibrary.simpleMessage("Exhausted all ads"),
        "dialog_title_vote_fail":
            MessageLookupByLibrary.simpleMessage("Voting Failed"),
        "dialog_withdraw_button_cancel": MessageLookupByLibrary.simpleMessage(
            "Let me think about this one more time"),
        "dialog_withdraw_button_ok":
            MessageLookupByLibrary.simpleMessage("Unsubscribing"),
        "dialog_withdraw_error": MessageLookupByLibrary.simpleMessage(
            "An error occurred during unsubscribe."),
        "dialog_withdraw_message": MessageLookupByLibrary.simpleMessage(
            "If you cancel your membership, any Star Candy you have on Picnic and your account information will be deleted immediately."),
        "dialog_withdraw_success": MessageLookupByLibrary.simpleMessage(
            "The unsubscribe was processed successfully."),
        "dialog_withdraw_title": MessageLookupByLibrary.simpleMessage(
            "Are you sure you want to leave?"),
        "error_message_login_failed": MessageLookupByLibrary.simpleMessage(
            "An error occurred during login."),
        "error_message_no_user": MessageLookupByLibrary.simpleMessage(
            "The membership information doesn\'t exist."),
        "error_message_withdrawal": MessageLookupByLibrary.simpleMessage(
            "A member who has unsubscribed."),
        "error_title": MessageLookupByLibrary.simpleMessage("Errors"),
        "hint_library_add": MessageLookupByLibrary.simpleMessage("Album name"),
        "hint_nickname_input":
            MessageLookupByLibrary.simpleMessage("Please enter a nickname."),
        "image_save_success":
            MessageLookupByLibrary.simpleMessage("The image has been saved."),
        "label_agreement_privacy": MessageLookupByLibrary.simpleMessage(
            "Consent to the collection and use of personal information"),
        "label_agreement_terms":
            MessageLookupByLibrary.simpleMessage("Accept the Terms of Use"),
        "label_album_add":
            MessageLookupByLibrary.simpleMessage("Add a new album"),
        "label_article_comment_empty":
            MessageLookupByLibrary.simpleMessage("Be the first to comment!"),
        "label_bonus": MessageLookupByLibrary.simpleMessage("Bonuses"),
        "label_button_agreement":
            MessageLookupByLibrary.simpleMessage("Accept"),
        "label_button_clse": MessageLookupByLibrary.simpleMessage("Close"),
        "label_button_disagreement":
            MessageLookupByLibrary.simpleMessage("Non-Consent"),
        "label_button_recharge":
            MessageLookupByLibrary.simpleMessage("Charging"),
        "label_button_save_vote_paper":
            MessageLookupByLibrary.simpleMessage("Save your ballot"),
        "label_button_share": MessageLookupByLibrary.simpleMessage("Share"),
        "label_button_vote": MessageLookupByLibrary.simpleMessage("Vote"),
        "label_button_watch_and_charge": MessageLookupByLibrary.simpleMessage(
            "Viewing and charging for ads"),
        "label_celeb_ask_to_you":
            MessageLookupByLibrary.simpleMessage("The Artist Asks You!"),
        "label_celeb_gallery":
            MessageLookupByLibrary.simpleMessage("Artist Gallery"),
        "label_celeb_recommend":
            MessageLookupByLibrary.simpleMessage("Artist recommendations"),
        "label_checkbox_entire_use":
            MessageLookupByLibrary.simpleMessage("Full Use"),
        "label_current_language":
            MessageLookupByLibrary.simpleMessage("Current language"),
        "label_draw_image": MessageLookupByLibrary.simpleMessage(
            "Chance to win a random image"),
        "label_dropdown_oldest": MessageLookupByLibrary.simpleMessage("Oldest"),
        "label_dropdown_recent": MessageLookupByLibrary.simpleMessage("Newest"),
        "label_find_celeb":
            MessageLookupByLibrary.simpleMessage("Find more artists"),
        "label_gallery_tab_article":
            MessageLookupByLibrary.simpleMessage("Articles"),
        "label_gallery_tab_chat": MessageLookupByLibrary.simpleMessage("Chat"),
        "label_hint_comment":
            MessageLookupByLibrary.simpleMessage("Leave a comment."),
        "label_input_input": MessageLookupByLibrary.simpleMessage("Input"),
        "label_last_provider":
            MessageLookupByLibrary.simpleMessage("Recent logins"),
        "label_library_save":
            MessageLookupByLibrary.simpleMessage("Save the library"),
        "label_library_tab_ai_photo":
            MessageLookupByLibrary.simpleMessage("AI Photos"),
        "label_library_tab_library":
            MessageLookupByLibrary.simpleMessage("Libraries"),
        "label_library_tab_pic": MessageLookupByLibrary.simpleMessage("PIC"),
        "label_moveto_celeb_gallery":
            MessageLookupByLibrary.simpleMessage("Go to the Artist Gallery"),
        "label_mypage_charge_history":
            MessageLookupByLibrary.simpleMessage("Charges"),
        "label_mypage_customer_center":
            MessageLookupByLibrary.simpleMessage("Help Center"),
        "label_mypage_logout": MessageLookupByLibrary.simpleMessage("Log out"),
        "label_mypage_membership_history":
            MessageLookupByLibrary.simpleMessage("Membership history"),
        "label_mypage_mystar": MessageLookupByLibrary.simpleMessage("My Star"),
        "label_mypage_notice":
            MessageLookupByLibrary.simpleMessage("Announcements"),
        "label_mypage_privacy_policy":
            MessageLookupByLibrary.simpleMessage("Privacy Policy"),
        "label_mypage_setting":
            MessageLookupByLibrary.simpleMessage("Settings"),
        "label_mypage_terms_of_use":
            MessageLookupByLibrary.simpleMessage("Terms of Use"),
        "label_mypage_vote_history":
            MessageLookupByLibrary.simpleMessage("Voting history"),
        "label_mypage_withdrawal":
            MessageLookupByLibrary.simpleMessage("Withdrawal"),
        "label_no_ads": MessageLookupByLibrary.simpleMessage("No ads"),
        "label_no_celeb": MessageLookupByLibrary.simpleMessage(
            "You don\'t have any artists bookmarked yet!"),
        "label_pic_image_cropping":
            MessageLookupByLibrary.simpleMessage("Crop an image"),
        "label_pic_pic_initializing_camera":
            MessageLookupByLibrary.simpleMessage("Initializing camera..."),
        "label_pic_pic_save_gallery":
            MessageLookupByLibrary.simpleMessage("Save to Gallery"),
        "label_pic_pic_synthesizing_image":
            MessageLookupByLibrary.simpleMessage("Compositing an image..."),
        "label_read_more_comment":
            MessageLookupByLibrary.simpleMessage("More comments"),
        "label_reply":
            MessageLookupByLibrary.simpleMessage("Replying to a reply"),
        "label_retry": MessageLookupByLibrary.simpleMessage("Retrying"),
        "label_screen_title_agreement":
            MessageLookupByLibrary.simpleMessage("Accept the terms"),
        "label_setting_alarm":
            MessageLookupByLibrary.simpleMessage("Notifications"),
        "label_setting_appinfo":
            MessageLookupByLibrary.simpleMessage("App info"),
        "label_setting_current_version":
            MessageLookupByLibrary.simpleMessage("Current version"),
        "label_setting_event_alarm":
            MessageLookupByLibrary.simpleMessage("Event notifications"),
        "label_setting_event_alarm_desc":
            MessageLookupByLibrary.simpleMessage("Events and happenings."),
        "label_setting_language":
            MessageLookupByLibrary.simpleMessage("Language settings"),
        "label_setting_push_alarm":
            MessageLookupByLibrary.simpleMessage("Push notifications"),
        "label_setting_recent_version":
            MessageLookupByLibrary.simpleMessage("Latest version"),
        "label_setting_remove_cache":
            MessageLookupByLibrary.simpleMessage("Delete Cache"),
        "label_setting_remove_cache_complete":
            MessageLookupByLibrary.simpleMessage("Done"),
        "label_setting_storage":
            MessageLookupByLibrary.simpleMessage("Manage storage"),
        "label_setting_update": MessageLookupByLibrary.simpleMessage("Update"),
        "label_star_candy_pouch":
            MessageLookupByLibrary.simpleMessage("Star Candy Pouch"),
        "label_tab_buy_star_candy":
            MessageLookupByLibrary.simpleMessage("Buy star candy"),
        "label_tab_free_charge_station":
            MessageLookupByLibrary.simpleMessage("Free charging stations"),
        "label_tabbar_picchart_daily":
            MessageLookupByLibrary.simpleMessage("Daily charts"),
        "label_tabbar_picchart_monthly":
            MessageLookupByLibrary.simpleMessage("Monthly Charts"),
        "label_tabbar_picchart_weekly":
            MessageLookupByLibrary.simpleMessage("Weekly charts"),
        "label_tabbar_vote_active":
            MessageLookupByLibrary.simpleMessage("In Progress"),
        "label_tabbar_vote_end": MessageLookupByLibrary.simpleMessage("Exit"),
        "label_time_ago_day": m0,
        "label_time_ago_hour": m1,
        "label_time_ago_minute": m2,
        "label_time_ago_right_now":
            MessageLookupByLibrary.simpleMessage("Just a moment ago"),
        "label_title_comment": MessageLookupByLibrary.simpleMessage("Comments"),
        "label_title_report":
            MessageLookupByLibrary.simpleMessage("Make a report"),
        "label_vote_reward_list":
            MessageLookupByLibrary.simpleMessage("Rewards list"),
        "label_vote_screen_title":
            MessageLookupByLibrary.simpleMessage("Voting"),
        "label_vote_tab_birthday":
            MessageLookupByLibrary.simpleMessage("Birthday polls"),
        "label_vote_tab_pic":
            MessageLookupByLibrary.simpleMessage("PIC Voting"),
        "label_vote_vote_gather":
            MessageLookupByLibrary.simpleMessage("Collecting votes"),
        "label_watch_ads": MessageLookupByLibrary.simpleMessage("View ads"),
        "lable_my_celeb": MessageLookupByLibrary.simpleMessage("My Artists"),
        "message_agreement_success":
            MessageLookupByLibrary.simpleMessage("You\'ve accepted the terms."),
        "message_error_occurred":
            MessageLookupByLibrary.simpleMessage("An error occurred."),
        "message_pic_pic_save_fail":
            MessageLookupByLibrary.simpleMessage("Saving the image failed."),
        "message_pic_pic_save_success":
            MessageLookupByLibrary.simpleMessage("The image has been saved."),
        "message_report_confirm":
            MessageLookupByLibrary.simpleMessage("Want to report?"),
        "message_report_ok":
            MessageLookupByLibrary.simpleMessage("The report is complete."),
        "mypage_comment":
            MessageLookupByLibrary.simpleMessage("Manage comments"),
        "mypage_language":
            MessageLookupByLibrary.simpleMessage("Language settings"),
        "mypage_purchases":
            MessageLookupByLibrary.simpleMessage("My purchases"),
        "mypage_setting": MessageLookupByLibrary.simpleMessage("Settings"),
        "mypage_subscription":
            MessageLookupByLibrary.simpleMessage("Subscription information"),
        "nav_ads": MessageLookupByLibrary.simpleMessage("Ads"),
        "nav_gallery": MessageLookupByLibrary.simpleMessage("Gallery"),
        "nav_home": MessageLookupByLibrary.simpleMessage("홈"),
        "nav_library": MessageLookupByLibrary.simpleMessage("Libraries"),
        "nav_media": MessageLookupByLibrary.simpleMessage("Media"),
        "nav_picchart": MessageLookupByLibrary.simpleMessage("PIC Charts"),
        "nav_purchases": MessageLookupByLibrary.simpleMessage("Purchase"),
        "nav_setting": MessageLookupByLibrary.simpleMessage("Settings"),
        "nav_store": MessageLookupByLibrary.simpleMessage("Shop"),
        "nav_subscription":
            MessageLookupByLibrary.simpleMessage("Subscriptions"),
        "nav_vote": MessageLookupByLibrary.simpleMessage("Voting"),
        "nickname_validation_error": MessageLookupByLibrary.simpleMessage(
            "20 characters or less, excluding special characters."),
        "page_title_mypage": MessageLookupByLibrary.simpleMessage("My Page"),
        "page_title_myprofile":
            MessageLookupByLibrary.simpleMessage("My profile"),
        "page_title_privacy":
            MessageLookupByLibrary.simpleMessage("Privacy Policy"),
        "page_title_setting":
            MessageLookupByLibrary.simpleMessage("Preferences"),
        "page_title_terms_of_use":
            MessageLookupByLibrary.simpleMessage("Terms of Use"),
        "page_title_vote_detail": MessageLookupByLibrary.simpleMessage("Vote"),
        "page_title_vote_gather":
            MessageLookupByLibrary.simpleMessage("Collecting votes"),
        "share_image_fail":
            MessageLookupByLibrary.simpleMessage("Image sharing failed"),
        "share_image_success":
            MessageLookupByLibrary.simpleMessage("Shared image successfully"),
        "share_no_twitter": MessageLookupByLibrary.simpleMessage(
            "I don\'t have the Twitter app"),
        "share_twitter":
            MessageLookupByLibrary.simpleMessage("Share on Twitter"),
        "text_ads_random": MessageLookupByLibrary.simpleMessage(
            "Viewing ads and collecting random images."),
        "text_bonus": MessageLookupByLibrary.simpleMessage("Bonuses"),
        "text_comming_soon_pic_chart1": MessageLookupByLibrary.simpleMessage(
            "Welcome to Pic Chart!\nSee you in August 2024!"),
        "text_comming_soon_pic_chart2": MessageLookupByLibrary.simpleMessage(
            "Pic Chart is Picnic\'s new chart that\nreflects daily, weekly, and monthly scores."),
        "text_comming_soon_pic_chart3": MessageLookupByLibrary.simpleMessage(
            "Check out the real-time\nbrand reputation of artists!"),
        "text_comming_soon_pic_chart_title":
            MessageLookupByLibrary.simpleMessage("Pic Chart?"),
        "text_copied_address": MessageLookupByLibrary.simpleMessage(
            "The address has been copied."),
        "text_dialog_star_candy_received": MessageLookupByLibrary.simpleMessage(
            "Star candy has been awarded."),
        "text_dialog_vote_amount_should_not_zero":
            MessageLookupByLibrary.simpleMessage(
                "The number of votes cannot be zero."),
        "text_draw_image": MessageLookupByLibrary.simpleMessage(
            "Confirmed ownership of 1 image from the entire gallery"),
        "text_hint_search":
            MessageLookupByLibrary.simpleMessage("Search for an artist."),
        "text_moveto_celeb_gallery": MessageLookupByLibrary.simpleMessage(
            "Navigate to the selected artist\'s home."),
        "text_need_recharge":
            MessageLookupByLibrary.simpleMessage("Requires charging."),
        "text_no_search_result":
            MessageLookupByLibrary.simpleMessage("No search results."),
        "text_purchase_vat_included":
            MessageLookupByLibrary.simpleMessage("*Price includes VAT."),
        "text_star_candy": MessageLookupByLibrary.simpleMessage("Star Candy"),
        "text_star_candy_with_bonus": m3,
        "text_this_time_vote":
            MessageLookupByLibrary.simpleMessage("This Vote"),
        "text_vote_complete":
            MessageLookupByLibrary.simpleMessage("Voting complete"),
        "text_vote_rank": m4,
        "text_vote_rank_in_reward":
            MessageLookupByLibrary.simpleMessage("Rank in Rewards"),
        "text_vote_where_is_my_bias":
            MessageLookupByLibrary.simpleMessage("Where\'s My Favorite?"),
        "title_dialog_library_add":
            MessageLookupByLibrary.simpleMessage("Add a new album"),
        "title_dialog_success": MessageLookupByLibrary.simpleMessage("成功"),
        "title_select_language":
            MessageLookupByLibrary.simpleMessage("Select a language"),
        "toast_max_five_celeb": MessageLookupByLibrary.simpleMessage(
            "You can add up to five of your own artists.")
      };
}

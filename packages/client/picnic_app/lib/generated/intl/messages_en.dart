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

  static String m0(day) => "${day} days ago";

  static String m1(hour) => "${hour} hours ago";

  static String m2(minute) => "${minute} minutes ago";

  static String m3(nickname) => "Replying to ${nickname}...";

  static String m4(num1) => "${num1}개 +${num1}개 보너스";

  static String m5(rank) => "Rank ${rank}";

  static String m6(version) => "A new version (${version}) is available.";

  static String m7(version) =>
      "You need to update to a new version (${version}).";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "ads_available_time":
            MessageLookupByLibrary.simpleMessage("Ad availability"),
        "anonymous": MessageLookupByLibrary.simpleMessage("Anonymous"),
        "anonymous_mode":
            MessageLookupByLibrary.simpleMessage("Anonymous Mode"),
        "app_name": MessageLookupByLibrary.simpleMessage("Picnic"),
        "button_cancel": MessageLookupByLibrary.simpleMessage("Cancel"),
        "button_complete": MessageLookupByLibrary.simpleMessage("Done"),
        "button_login": MessageLookupByLibrary.simpleMessage("Sign in"),
        "button_ok": MessageLookupByLibrary.simpleMessage("Confirm"),
        "button_pic_pic_save": MessageLookupByLibrary.simpleMessage("Save"),
        "candy_disappear_next_month":
            MessageLookupByLibrary.simpleMessage("소멸 예정 보너스 별사탕 😢"),
        "candy_usage_policy_contents": MessageLookupByLibrary.simpleMessage(
            "Bonus Star Candy earned in the current month will expire on the 15th of the following month."),
        "candy_usage_policy_contents2": MessageLookupByLibrary.simpleMessage(
            "When using Star Candy, Star Candy that is about to expire is prioritized."),
        "candy_usage_policy_guide": MessageLookupByLibrary.simpleMessage(
            "*Bonuses will disappear the month after they are earned!"),
        "candy_usage_policy_guide_button":
            MessageLookupByLibrary.simpleMessage("Learn more"),
        "candy_usage_policy_title":
            MessageLookupByLibrary.simpleMessage("Stardust Usage Policy"),
        "common_all": MessageLookupByLibrary.simpleMessage("All"),
        "common_fail": MessageLookupByLibrary.simpleMessage("Failed"),
        "common_retry_label": MessageLookupByLibrary.simpleMessage("Try again"),
        "common_success": MessageLookupByLibrary.simpleMessage("성공"),
        "common_text_no_data":
            MessageLookupByLibrary.simpleMessage("No data is available."),
        "common_text_no_search_result":
            MessageLookupByLibrary.simpleMessage("No search results found."),
        "common_text_search_error": MessageLookupByLibrary.simpleMessage(
            "An error occurred during the search."),
        "common_text_search_recent_label":
            MessageLookupByLibrary.simpleMessage("Recent searches"),
        "common_text_search_result_label":
            MessageLookupByLibrary.simpleMessage("Search results"),
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
        "dialog_message_can_resignup": MessageLookupByLibrary.simpleMessage(
            "When you can rejoin if you cancel your membership now"),
        "dialog_message_purchase_canceled":
            MessageLookupByLibrary.simpleMessage(
                "Your purchase has been canceled."),
        "dialog_message_purchase_failed": MessageLookupByLibrary.simpleMessage(
            "There was an error with your purchase, please try again later."),
        "dialog_message_purchase_success": MessageLookupByLibrary.simpleMessage(
            "Your purchase has been successfully completed."),
        "dialog_purchases_fail":
            MessageLookupByLibrary.simpleMessage("The purchase failed."),
        "dialog_purchases_success":
            MessageLookupByLibrary.simpleMessage("Your purchase is complete."),
        "dialog_title_ads_exhausted":
            MessageLookupByLibrary.simpleMessage("Exhausted all ads"),
        "dialog_title_vote_fail":
            MessageLookupByLibrary.simpleMessage("Voting Failed"),
        "dialog_will_delete_star_candy":
            MessageLookupByLibrary.simpleMessage("Starscapes to be deleted"),
        "dialog_withdraw_button_cancel": MessageLookupByLibrary.simpleMessage(
            "Let me think about this one more time"),
        "dialog_withdraw_button_ok":
            MessageLookupByLibrary.simpleMessage("Unsubscribing"),
        "dialog_withdraw_error": MessageLookupByLibrary.simpleMessage(
            "An error occurred during unsubscribe."),
        "dialog_withdraw_message": MessageLookupByLibrary.simpleMessage(
            "If you cancel your membership, your star candy and account information on Picnic will be deleted immediately, and your existing information and data will not be restored when you rejoin."),
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
        "label_ads_exceeded": MessageLookupByLibrary.simpleMessage(
            "You have exhausted the ads available per ID."),
        "label_ads_next_available_time": MessageLookupByLibrary.simpleMessage(
            "When the next ad will be available."),
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
        "label_button_close": MessageLookupByLibrary.simpleMessage("닫기"),
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
        "label_loading_ads": MessageLookupByLibrary.simpleMessage("Loading ad"),
        "label_moveto_celeb_gallery":
            MessageLookupByLibrary.simpleMessage("Go to the Artist Gallery"),
        "label_mypage_charge_history":
            MessageLookupByLibrary.simpleMessage("Charges"),
        "label_mypage_customer_center":
            MessageLookupByLibrary.simpleMessage("Help Center"),
        "label_mypage_logout": MessageLookupByLibrary.simpleMessage("Log out"),
        "label_mypage_membership_history":
            MessageLookupByLibrary.simpleMessage("Membership history"),
        "label_mypage_my_artist":
            MessageLookupByLibrary.simpleMessage("My Artists"),
        "label_mypage_no_artist":
            MessageLookupByLibrary.simpleMessage("Sign up for MyArtist."),
        "label_mypage_notice":
            MessageLookupByLibrary.simpleMessage("Announcements"),
        "label_mypage_picnic_id": MessageLookupByLibrary.simpleMessage("Id."),
        "label_mypage_privacy_policy":
            MessageLookupByLibrary.simpleMessage("Privacy Policy"),
        "label_mypage_setting":
            MessageLookupByLibrary.simpleMessage("Settings"),
        "label_mypage_should_login":
            MessageLookupByLibrary.simpleMessage("Please sign in"),
        "label_mypage_terms_of_use":
            MessageLookupByLibrary.simpleMessage("Terms of Use"),
        "label_mypage_vote_history":
            MessageLookupByLibrary.simpleMessage("Star Candy Voting History"),
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
        "label_reply": MessageLookupByLibrary.simpleMessage("Replying"),
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
        "label_setting_recent_version_up_to_date":
            MessageLookupByLibrary.simpleMessage("Latest version"),
        "label_setting_remove_cache":
            MessageLookupByLibrary.simpleMessage("Delete cache memory"),
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
        "label_tab_my_artist": MessageLookupByLibrary.simpleMessage("MyArtist"),
        "label_tab_search_my_artist":
            MessageLookupByLibrary.simpleMessage("Find MyArtist"),
        "label_tabbar_picchart_daily":
            MessageLookupByLibrary.simpleMessage("Daily charts"),
        "label_tabbar_picchart_monthly":
            MessageLookupByLibrary.simpleMessage("Monthly Charts"),
        "label_tabbar_picchart_weekly":
            MessageLookupByLibrary.simpleMessage("Weekly charts"),
        "label_tabbar_vote_active":
            MessageLookupByLibrary.simpleMessage("In Progress"),
        "label_tabbar_vote_end": MessageLookupByLibrary.simpleMessage("Exit"),
        "label_tabbar_vote_upcoming":
            MessageLookupByLibrary.simpleMessage("Upcoming"),
        "label_time_ago_day": m0,
        "label_time_ago_hour": m1,
        "label_time_ago_minute": m2,
        "label_time_ago_right_now":
            MessageLookupByLibrary.simpleMessage("Just a moment ago"),
        "label_title_comment": MessageLookupByLibrary.simpleMessage("Comments"),
        "label_title_report":
            MessageLookupByLibrary.simpleMessage("Make a report"),
        "label_vote_end":
            MessageLookupByLibrary.simpleMessage("Close the poll"),
        "label_vote_reward_list":
            MessageLookupByLibrary.simpleMessage("Rewards list"),
        "label_vote_screen_title":
            MessageLookupByLibrary.simpleMessage("Voting"),
        "label_vote_tab_birthday":
            MessageLookupByLibrary.simpleMessage("Birthday polls"),
        "label_vote_tab_pic":
            MessageLookupByLibrary.simpleMessage("PIC voting"),
        "label_vote_upcoming":
            MessageLookupByLibrary.simpleMessage("Until voting begins"),
        "label_vote_vote_gather":
            MessageLookupByLibrary.simpleMessage("Collecting votes"),
        "label_watch_ads": MessageLookupByLibrary.simpleMessage("View ads"),
        "lable_my_celeb": MessageLookupByLibrary.simpleMessage("My Artists"),
        "message_agreement_success": MessageLookupByLibrary.simpleMessage(
            "Acceptance of the terms is complete."),
        "message_error_occurred":
            MessageLookupByLibrary.simpleMessage("An error occurred."),
        "message_noitem_vote_active": MessageLookupByLibrary.simpleMessage(
            "There are currently no active polls."),
        "message_noitem_vote_end": MessageLookupByLibrary.simpleMessage(
            "There are currently no closed polls."),
        "message_noitem_vote_upcoming": MessageLookupByLibrary.simpleMessage(
            "There are currently no upcoming polls."),
        "message_pic_pic_save_fail":
            MessageLookupByLibrary.simpleMessage("Saving the image failed."),
        "message_pic_pic_save_success":
            MessageLookupByLibrary.simpleMessage("The image has been saved."),
        "message_report_confirm":
            MessageLookupByLibrary.simpleMessage("Want to report?"),
        "message_report_ok":
            MessageLookupByLibrary.simpleMessage("The report is complete."),
        "message_setting_remove_cache": MessageLookupByLibrary.simpleMessage(
            "Cache memory deletion is complete"),
        "message_update_nickname_fail": MessageLookupByLibrary.simpleMessage(
            "Nickname change failed.\nPlease select a different nickname."),
        "message_update_nickname_success": MessageLookupByLibrary.simpleMessage(
            "Your nickname has been successfully changed."),
        "message_vote_is_ended":
            MessageLookupByLibrary.simpleMessage("Poll closed"),
        "message_vote_is_upcoming":
            MessageLookupByLibrary.simpleMessage("This is an upcoming vote"),
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
        "nav_board": MessageLookupByLibrary.simpleMessage("Boards"),
        "nav_gallery": MessageLookupByLibrary.simpleMessage("Gallery"),
        "nav_home": MessageLookupByLibrary.simpleMessage("홈"),
        "nav_library": MessageLookupByLibrary.simpleMessage("Libraries"),
        "nav_media": MessageLookupByLibrary.simpleMessage("Media"),
        "nav_my": MessageLookupByLibrary.simpleMessage("My"),
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
        "page_title_post_write":
            MessageLookupByLibrary.simpleMessage("Create a post"),
        "page_title_privacy":
            MessageLookupByLibrary.simpleMessage("Privacy Policy"),
        "page_title_setting":
            MessageLookupByLibrary.simpleMessage("Preferences"),
        "page_title_terms_of_use":
            MessageLookupByLibrary.simpleMessage("Terms of Use"),
        "page_title_vote_detail": MessageLookupByLibrary.simpleMessage("Vote"),
        "page_title_vote_gather":
            MessageLookupByLibrary.simpleMessage("Collecting votes"),
        "popup_label_delete": MessageLookupByLibrary.simpleMessage("Delete"),
        "post_anonymous":
            MessageLookupByLibrary.simpleMessage("Anonymous posting"),
        "post_ask_go_to_temporary_save_list":
            MessageLookupByLibrary.simpleMessage(
                "Want to go to the Drafts list?"),
        "post_board_already_exist": MessageLookupByLibrary.simpleMessage(
            "A board that already exists."),
        "post_board_create_request_complete":
            MessageLookupByLibrary.simpleMessage(
                "Your request to open a board is complete."),
        "post_board_create_request_condition":
            MessageLookupByLibrary.simpleMessage(
                "*Only one minor board can be applied per ID."),
        "post_board_create_request_label":
            MessageLookupByLibrary.simpleMessage("Request to open a board"),
        "post_board_create_request_reviewing":
            MessageLookupByLibrary.simpleMessage(
                "Reviewing a request to open a board"),
        "post_board_request_label":
            MessageLookupByLibrary.simpleMessage("Open requests"),
        "post_cannot_open_youtube":
            MessageLookupByLibrary.simpleMessage("I can\'t open Youtube."),
        "post_comment_action_translate":
            MessageLookupByLibrary.simpleMessage("Translation"),
        "post_comment_content_more":
            MessageLookupByLibrary.simpleMessage("More"),
        "post_comment_delete_confirm": MessageLookupByLibrary.simpleMessage(
            "Are you sure you want to delete the comment?"),
        "post_comment_delete_fail":
            MessageLookupByLibrary.simpleMessage("Comment deletion failed."),
        "post_comment_deleted_comment":
            MessageLookupByLibrary.simpleMessage("This is a deleted comment."),
        "post_comment_like_processing_fail":
            MessageLookupByLibrary.simpleMessage("Failed to process like."),
        "post_comment_loading_fail":
            MessageLookupByLibrary.simpleMessage("Comment failed to load."),
        "post_comment_register_fail": MessageLookupByLibrary.simpleMessage(
            "Comment registration failed."),
        "post_comment_registered_comment": MessageLookupByLibrary.simpleMessage(
            "Your comment has been registered."),
        "post_comment_reported_comment":
            MessageLookupByLibrary.simpleMessage("This is a reported comment."),
        "post_comment_translate_complete": MessageLookupByLibrary.simpleMessage(
            "The translation is complete."),
        "post_comment_translate_fail":
            MessageLookupByLibrary.simpleMessage("The translation failed."),
        "post_comment_translated":
            MessageLookupByLibrary.simpleMessage("Translated"),
        "post_comment_write_label":
            MessageLookupByLibrary.simpleMessage("Write a comment"),
        "post_content_placeholder":
            MessageLookupByLibrary.simpleMessage("Please enter something."),
        "post_delete_scrap_confirm": MessageLookupByLibrary.simpleMessage(
            "Do you want to delete the scrap?"),
        "post_delete_scrap_title":
            MessageLookupByLibrary.simpleMessage("Delete a scrap"),
        "post_go_to_boards":
            MessageLookupByLibrary.simpleMessage("Go to the board"),
        "post_header_publish":
            MessageLookupByLibrary.simpleMessage("Publishing"),
        "post_header_temporary_save":
            MessageLookupByLibrary.simpleMessage("Drafts"),
        "post_hint_title":
            MessageLookupByLibrary.simpleMessage("Please enter a title."),
        "post_hyperlink": MessageLookupByLibrary.simpleMessage("Hyperlinks"),
        "post_insert_link":
            MessageLookupByLibrary.simpleMessage("Inserting links"),
        "post_loading_post_fail":
            MessageLookupByLibrary.simpleMessage("The post failed to load."),
        "post_minor_board_condition": MessageLookupByLibrary.simpleMessage(
            "Please enter a description of at least 5 characters and no more than 20 characters."),
        "post_minor_board_create_request_message":
            MessageLookupByLibrary.simpleMessage(
                "* Message requesting to open a board."),
        "post_minor_board_create_request_message_condition":
            MessageLookupByLibrary.simpleMessage(
                "Please include at least 10 characters in your message requesting to open a board."),
        "post_minor_board_create_request_message_input":
            MessageLookupByLibrary.simpleMessage(
                "Enter a message requesting to open a board."),
        "post_minor_board_description": MessageLookupByLibrary.simpleMessage(
            "Minor bulletin board descriptions"),
        "post_minor_board_description_input":
            MessageLookupByLibrary.simpleMessage(
                "Please enter a description for your minor board."),
        "post_minor_board_name":
            MessageLookupByLibrary.simpleMessage("Minor board name"),
        "post_minor_board_name_input": MessageLookupByLibrary.simpleMessage(
            "Please enter a name for your minor board."),
        "post_my_written_post":
            MessageLookupByLibrary.simpleMessage("Posts I\'ve written"),
        "post_my_written_reply":
            MessageLookupByLibrary.simpleMessage("Comments I wrote"),
        "post_my_written_scrap":
            MessageLookupByLibrary.simpleMessage("My Scraps"),
        "post_no_comment": MessageLookupByLibrary.simpleMessage("No comments."),
        "post_replying_comment": m3,
        "post_report_fail":
            MessageLookupByLibrary.simpleMessage("The report failed."),
        "post_report_label":
            MessageLookupByLibrary.simpleMessage("Make a report"),
        "post_report_other_input": MessageLookupByLibrary.simpleMessage(
            "Please enter any other reason."),
        "post_report_reason_1":
            MessageLookupByLibrary.simpleMessage("Unsavory posts"),
        "post_report_reason_2":
            MessageLookupByLibrary.simpleMessage("Sexist, racist posts"),
        "post_report_reason_3": MessageLookupByLibrary.simpleMessage(
            "Posts containing offensive profanity"),
        "post_report_reason_4": MessageLookupByLibrary.simpleMessage(
            "Advertising/Promotional Posts"),
        "post_report_reason_5": MessageLookupByLibrary.simpleMessage("Other"),
        "post_report_reason_input": MessageLookupByLibrary.simpleMessage(
            "Please select a reason for your report."),
        "post_report_reason_label":
            MessageLookupByLibrary.simpleMessage("Reasons for reporting"),
        "post_report_success":
            MessageLookupByLibrary.simpleMessage("The report is complete."),
        "post_temporary_save_complete":
            MessageLookupByLibrary.simpleMessage("Draft complete."),
        "post_title_placeholder":
            MessageLookupByLibrary.simpleMessage("Please enter a title."),
        "post_write_board_post":
            MessageLookupByLibrary.simpleMessage("Create a post"),
        "post_write_post_recommend_write":
            MessageLookupByLibrary.simpleMessage("Please create a post."),
        "post_youtube_link":
            MessageLookupByLibrary.simpleMessage("YouTube link"),
        "purchase_web_message": MessageLookupByLibrary.simpleMessage(
            "This is the payment window for those who cannot pay for the app:\\n Please copy the random ID in advance:\\n After copying, click the button below to proceed with the payment."),
        "replies": MessageLookupByLibrary.simpleMessage("Comments"),
        "share_image_fail":
            MessageLookupByLibrary.simpleMessage("Image sharing failed"),
        "share_image_success":
            MessageLookupByLibrary.simpleMessage("Shared image successfully"),
        "share_no_twitter":
            MessageLookupByLibrary.simpleMessage("X app is missing."),
        "share_twitter":
            MessageLookupByLibrary.simpleMessage("Share on Twitter"),
        "text_ads_random": MessageLookupByLibrary.simpleMessage(
            "Viewing ads and collecting random images."),
        "text_bonus": MessageLookupByLibrary.simpleMessage("Bonuses"),
        "text_bookmark_failed":
            MessageLookupByLibrary.simpleMessage("Failed to unbookmark"),
        "text_bookmark_over_5": MessageLookupByLibrary.simpleMessage(
            "You can have up to five bookmarks"),
        "text_comming_soon_pic_chart1": MessageLookupByLibrary.simpleMessage(
            "Welcome to Peek Charts!\nSee you in November 2024!"),
        "text_comming_soon_pic_chart2": MessageLookupByLibrary.simpleMessage(
            "Pie charts are a new chart unique to Peeknick that reflects daily, weekly, and monthly scores.\nPeeknick\'s new chart that reflects daily, weekly, and monthly scores."),
        "text_comming_soon_pic_chart3": MessageLookupByLibrary.simpleMessage(
            "Get a real-time reflection\nartist\'s brand reputation in real-time!"),
        "text_comming_soon_pic_chart_title":
            MessageLookupByLibrary.simpleMessage("What is a Pie Chart?"),
        "text_community_board_search":
            MessageLookupByLibrary.simpleMessage("Searching the Artist Board"),
        "text_community_post_search":
            MessageLookupByLibrary.simpleMessage("Search"),
        "text_copied_address": MessageLookupByLibrary.simpleMessage(
            "The address has been copied."),
        "text_dialog_ad_dismissed": MessageLookupByLibrary.simpleMessage(
            "The ad stopped midway through."),
        "text_dialog_ad_failed_to_show":
            MessageLookupByLibrary.simpleMessage("Failed to load ads"),
        "text_dialog_star_candy_received": MessageLookupByLibrary.simpleMessage(
            "Star candy has been awarded."),
        "text_dialog_vote_amount_should_not_zero":
            MessageLookupByLibrary.simpleMessage(
                "The number of votes cannot be zero."),
        "text_draw_image": MessageLookupByLibrary.simpleMessage(
            "Confirmed ownership of 1 image from the entire gallery"),
        "text_hint_search":
            MessageLookupByLibrary.simpleMessage("Search for artists"),
        "text_moveto_celeb_gallery": MessageLookupByLibrary.simpleMessage(
            "Navigate to the selected artist\'s home."),
        "text_need_recharge":
            MessageLookupByLibrary.simpleMessage("Requires charging."),
        "text_no_artist": MessageLookupByLibrary.simpleMessage("No artist"),
        "text_no_search_result":
            MessageLookupByLibrary.simpleMessage("No search results."),
        "text_purchase_vat_included":
            MessageLookupByLibrary.simpleMessage("*Price includes VAT."),
        "text_star_candy": MessageLookupByLibrary.simpleMessage("Star Candy"),
        "text_star_candy_with_bonus": m4,
        "text_this_time_vote":
            MessageLookupByLibrary.simpleMessage("This Vote"),
        "text_vote_complete":
            MessageLookupByLibrary.simpleMessage("Voting complete"),
        "text_vote_rank": m5,
        "text_vote_rank_in_reward":
            MessageLookupByLibrary.simpleMessage("Rank in Rewards"),
        "text_vote_where_is_my_bias":
            MessageLookupByLibrary.simpleMessage("Where\'s My Favorite?"),
        "title_dialog_library_add":
            MessageLookupByLibrary.simpleMessage("Add a new album"),
        "title_dialog_success": MessageLookupByLibrary.simpleMessage("성공"),
        "title_select_language":
            MessageLookupByLibrary.simpleMessage("Select a language"),
        "toast_max_five_celeb": MessageLookupByLibrary.simpleMessage(
            "You can add up to five of your own artists."),
        "update_button": MessageLookupByLibrary.simpleMessage("Update"),
        "update_cannot_open_appstore": MessageLookupByLibrary.simpleMessage(
            "I can\'t open the app store."),
        "update_recommend_text": m6,
        "update_required_text": m7,
        "update_required_title":
            MessageLookupByLibrary.simpleMessage("An update is required."),
        "views": MessageLookupByLibrary.simpleMessage("Views")
      };
}

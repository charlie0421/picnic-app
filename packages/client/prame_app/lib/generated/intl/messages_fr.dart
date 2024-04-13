// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a fr locale. All the
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
  String get localeName => 'fr';

  static String m0(day) => "Il y a ${day} jours";

  static String m1(hour) => "Il y a ${hour} heures";

  static String m2(minute) => "Il y a ${minute} minutes";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "button_cancel": MessageLookupByLibrary.simpleMessage("取消"),
        "button_ok": MessageLookupByLibrary.simpleMessage("Confirmer"),
        "label_celeb_gallery":
            MessageLookupByLibrary.simpleMessage("Galerie Salop."),
        "label_celeb_recommend": MessageLookupByLibrary.simpleMessage(
            "Recommandations de célébrités"),
        "label_current_language":
            MessageLookupByLibrary.simpleMessage("Langue actuelle"),
        "label_draw_image": MessageLookupByLibrary.simpleMessage(
            "Une chance de gagner une image au hasard"),
        "label_find_celeb":
            MessageLookupByLibrary.simpleMessage("Trouver plus de célébrités"),
        "label_gallery_tab_chat": MessageLookupByLibrary.simpleMessage("Chat"),
        "label_gallery_tab_gallery":
            MessageLookupByLibrary.simpleMessage("Galerie"),
        "label_hint_comment":
            MessageLookupByLibrary.simpleMessage("Laissez un commentaire."),
        "label_moveto_celeb_gallery": MessageLookupByLibrary.simpleMessage(
            "Aller à la galerie des célébrités"),
        "label_no_celeb": MessageLookupByLibrary.simpleMessage(
            "Vous n\'avez pas encore de célébrités dans vos favoris !"),
        "label_read_more_comment":
            MessageLookupByLibrary.simpleMessage("Plus de commentaires"),
        "label_reply": MessageLookupByLibrary.simpleMessage("Répondre"),
        "label_time_ago_day": m0,
        "label_time_ago_hour": m1,
        "label_time_ago_minute": m2,
        "label_time_ago_right_now":
            MessageLookupByLibrary.simpleMessage("Il y a quelques instants"),
        "label_title_comment":
            MessageLookupByLibrary.simpleMessage("Commentaire"),
        "label_title_report":
            MessageLookupByLibrary.simpleMessage("Faire un rapport"),
        "lable_my_celeb": MessageLookupByLibrary.simpleMessage("Ma Célébrité"),
        "message_report_confirm":
            MessageLookupByLibrary.simpleMessage("Voulez-vous le signaler ?"),
        "message_report_ok":
            MessageLookupByLibrary.simpleMessage("Le rapport est complet."),
        "mypage_comment":
            MessageLookupByLibrary.simpleMessage("Gestion des Commentaires"),
        "mypage_language":
            MessageLookupByLibrary.simpleMessage("Paramètres de Langue"),
        "mypage_purchases": MessageLookupByLibrary.simpleMessage("Mes Achats"),
        "mypage_setting": MessageLookupByLibrary.simpleMessage("Paramètres"),
        "mypage_subscription":
            MessageLookupByLibrary.simpleMessage("Info Abonnement"),
        "nav_ads": MessageLookupByLibrary.simpleMessage("Publicités"),
        "nav_gallery": MessageLookupByLibrary.simpleMessage("Galerie"),
        "nav_home": MessageLookupByLibrary.simpleMessage("Accueil"),
        "nav_library": MessageLookupByLibrary.simpleMessage("Bibliothèque"),
        "nav_purchases": MessageLookupByLibrary.simpleMessage("Achats"),
        "text_ads_random": MessageLookupByLibrary.simpleMessage(
            "Visualisation de publicités et collecte d\'images aléatoires."),
        "text_draw_image": MessageLookupByLibrary.simpleMessage(
            "1 image de l\'ensemble de la galerie Collection confirmée"),
        "text_hint_search":
            MessageLookupByLibrary.simpleMessage("Recherche de célébrités."),
        "text_moveto_celeb_gallery": MessageLookupByLibrary.simpleMessage(
            "Permet d\'accéder à la maison de la célébrité sélectionnée."),
        "title_select_language":
            MessageLookupByLibrary.simpleMessage("Sélectionnez la langue"),
        "toast_max_5_celeb": MessageLookupByLibrary.simpleMessage(
            "Vous pouvez ajouter jusqu\'à 5 My Celebrities.")
      };
}

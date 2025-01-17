'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"flutter_bootstrap.js": "c5f94645c8611f7b3df6cdefc2e94b1a",
".vercel/project.json": "563d234e39c4e5ca78f542507b0fb170",
".vercel/README.txt": "2b13c79d37d6ed82a3255b83b6815034",
"version.json": "7a5e863356a553c6a8cc4ccd4bfc29b1",
"splash/img/light-2x.png": "c7f186e6f81b851a4d861cd101eba970",
"splash/img/dark-4x.png": "80afe9dcfeae8e7d2c21fe8e4a69113b",
"splash/img/light-3x.png": "e768dfb4cecb5001c613ff8c5afd3044",
"splash/img/dark-3x.png": "e768dfb4cecb5001c613ff8c5afd3044",
"splash/img/light-4x.png": "80afe9dcfeae8e7d2c21fe8e4a69113b",
"splash/img/dark-2x.png": "c7f186e6f81b851a4d861cd101eba970",
"splash/img/dark-1x.png": "b3ae954f257f5b443736876e920b30b4",
"splash/img/light-1x.png": "b3ae954f257f5b443736876e920b30b4",
"index.html": "0fa90eca7c59e1686bd8250ee655db1b",
"/": "0fa90eca7c59e1686bd8250ee655db1b",
"vercel.json": "542d74011e16031f385de2ccc69ce811",
"main.dart.js": "29655282f5212048ca64bae099230785",
"flutter.js": "4b2350e14c6650ba82871f60906437ea",
"app-ads.txt": "038a5d051be4e7ba2ce5c707e7c45ae1",
"favicon.png": "63ad12632721ea564a5fd5e77cac9f28",
"icons/Icon-192.png": "a8cbe7763f0d313bdabbb72af04dd0ed",
"icons/Icon-maskable-192.png": "a8cbe7763f0d313bdabbb72af04dd0ed",
"icons/Icon-maskable-512.png": "98fb42034cfabce1c6a71df7a7531199",
"icons/Icon-512.png": "98fb42034cfabce1c6a71df7a7531199",
"manifest.json": "561f62344127f49267ed3e263093c425",
"download.html": "c81df0a66f1b204ac20835632284b730",
"assets/config/dev.json": "c484da2726b06eddcb81ad2f6ed605b9",
"assets/config/prod.json": "2830ac8790d287401ff00056a0b6345b",
"assets/config/local.json": "c484da2726b06eddcb81ad2f6ed605b9",
"assets/AssetManifest.json": "0528d844b5fc7372693bde1e67b400a8",
"assets/NOTICES": "ccccd27b91b3af0ca332bdad4c908bf8",
"assets/FontManifest.json": "7c8b7c0d97b810b2cf50da378ff7437a",
"assets/AssetManifest.bin.json": "2a90b8da77257b882b0bc10cdc2a0a13",
"assets/packages/font_awesome_flutter/lib/fonts/fa-solid-900.ttf": "a2eb084b706ab40c90610942d98886ec",
"assets/packages/font_awesome_flutter/lib/fonts/fa-regular-400.ttf": "3ca5dc7621921b901d513cc1ce23788c",
"assets/packages/font_awesome_flutter/lib/fonts/fa-brands-400.ttf": "d8a34039274f077621eef943bebecde3",
"assets/packages/flutter_inappwebview_web/assets/web/web_support.js": "509ae636cfdd93e49b5a6eaf0f06d79f",
"assets/packages/flutter_inappwebview/assets/t_rex_runner/t-rex.css": "5a8d0222407e388155d7d1395a75d5b9",
"assets/packages/flutter_inappwebview/assets/t_rex_runner/t-rex.html": "16911fcc170c8af1c5457940bd0bf055",
"assets/packages/picnic_lib/lib/l10n/intl_ko.arb": "b85a1e0180f2aa32c82df572d5a98e29",
"assets/packages/picnic_lib/lib/l10n/intl_zh.arb": "abd6bb2a375cbbfd36e66bf241eb4216",
"assets/packages/picnic_lib/lib/l10n/intl_ja.arb": "2a2e784a8e5dad7a9e83e2507aa3334e",
"assets/packages/picnic_lib/lib/l10n/intl_en.arb": "c2fdd8db85034233efcee42bd166d201",
"assets/packages/picnic_lib/assets/landing/no_celeb.svg": "ccf6d25b493f037e9b0bd4c4402dd51a",
"assets/packages/picnic_lib/assets/landing/search_icon.svg": "cb95cbfb1a03237995837eba2139ab6a",
"assets/packages/picnic_lib/assets/landing/bookmark_added.svg": "5ddbd46860a6a0d1eda2b1c7abb2508d",
"assets/packages/picnic_lib/assets/landing/bookmark_add.svg": "3a3452a777fe4770b2189b1276f50311",
"assets/packages/picnic_lib/assets/images/vote/banner_complete_bottom_ko.jpg": "2ff118544561c55a59ad448d7f7676e6",
"assets/packages/picnic_lib/assets/images/vote/banner_complete_bottom_en.jpg": "b0f214087773d06e813fc85864e8122e",
"assets/packages/picnic_lib/assets/images/pic_demo.png": "ad0c8695d12f4e940596fca11940ff66",
"assets/packages/picnic_lib/assets/images/reward_location.png": "3c08fd4c9b4cac2e01fdc0119ece04a8",
"assets/packages/picnic_lib/assets/images/reward_size_guide.png": "d5b82f251f8dac8c6b20db58a75979d3",
"assets/packages/picnic_lib/assets/images/logo.png": "da945b8540f63a3c632754ff9b6661b7",
"assets/packages/picnic_lib/assets/images/random_image.webp": "dd71eb22e4afebffa8b6213187b575ef",
"assets/packages/picnic_lib/assets/images/reward_overview.png": "7291e6e748fa4098883edd40065bad07",
"assets/packages/picnic_lib/assets/images/picchart_comming_soon.png": "7c1c08b6e6f95c105d01c6c657b621cf",
"assets/packages/picnic_lib/assets/images/fortune/title_zh.svg": "1827f3df857595444009764567ce7984",
"assets/packages/picnic_lib/assets/images/fortune/picnic_logo.svg": "4a5bd27dc50cedcb71e4fab89ce49e8a",
"assets/packages/picnic_lib/assets/images/fortune/no_item_zh.svg": "0181ea35abee617cb88f57b3bdb39029",
"assets/packages/picnic_lib/assets/images/fortune/no_item_en.svg": "8813e2685ee482a809f1281ca0513637",
"assets/packages/picnic_lib/assets/images/fortune/no_item_ja.svg": "24ffaf46d45f2510364fdfdfe1355d78",
"assets/packages/picnic_lib/assets/images/fortune/fortune_tips.svg": "e57b4cd43f8d07cdfc81f7867f5f4f2d",
"assets/packages/picnic_lib/assets/images/fortune/title_ja.svg": "6f8444c35db6adf562bb858fcf06da3d",
"assets/packages/picnic_lib/assets/images/fortune/title_en.svg": "329f0557efbe861c751f0ddebe1837a8",
"assets/packages/picnic_lib/assets/images/fortune/no_item_ko.svg": "6aa5e7b757fb06c7c6e201e44ec24607",
"assets/packages/picnic_lib/assets/images/fortune/title_ko.svg": "d7ce67500d8aedbfd27ab8b0bea4de96",
"assets/packages/picnic_lib/assets/images/fortune/fortune_style.svg": "e253073487591cdc42e7310237b437bd",
"assets/packages/picnic_lib/assets/images/fortune/fortune_activities.svg": "cb64335851d49c9eb2239efcafb3dc8f",
"assets/packages/picnic_lib/assets/web/google-play-badge.png": "e6d552c5deec92675d47f9b89d816ab8",
"assets/packages/picnic_lib/assets/web/screenshot_1.png": "01d5d9e0d53b5394930534ed00ea8095",
"assets/packages/picnic_lib/assets/web/screenshot_3.png": "2ec5627f4f49ebe52a205e1cce9932da",
"assets/packages/picnic_lib/assets/web/app-store-badge.png": "d7cd949e60f0eb7fd950f10a0f1f9b3b",
"assets/packages/picnic_lib/assets/web/screenshot_2.png": "d9e77df6c529a9fbdf412aff0016788b",
"assets/packages/picnic_lib/assets/splash_original.webp": "5b2db8b479876d02eac0fcd806a7ed52",
"assets/packages/picnic_lib/assets/splash.webp": "fc6bbd05f7b0644bbd382c935ebca609",
"assets/packages/picnic_lib/assets/splash_original.png": "9abcae143ec4e9a397b99c269c43b5db",
"assets/packages/picnic_lib/assets/splash.png": "35a5dbc2e2deb9cb1fa0a00260333f14",
"assets/packages/picnic_lib/assets/icons/save_gallery.svg": "2259956b80fac3dfac42814ab20e86bd",
"assets/packages/picnic_lib/assets/icons/vote/crown1.svg": "adeb6af8c70c20ea72810cf5b5672401",
"assets/packages/picnic_lib/assets/icons/vote/crown3.svg": "e02bb6a0385923999ed6f0756308eefa",
"assets/packages/picnic_lib/assets/icons/vote/crown2.svg": "d0101b11a4d2d70da6b6c3d49e20cb9a",
"assets/packages/picnic_lib/assets/icons/vote/search_icon.svg": "168ae589347c906e814a0edb158250a8",
"assets/packages/picnic_lib/assets/icons/vote/checkbox.svg": "af5fd23b5fd1d3e94f3c6cff5fc2eeaa",
"assets/packages/picnic_lib/assets/icons/pencil_style=fill.svg": "6df12d1d2fcbe3fa27eb9341dae49ac0",
"assets/packages/picnic_lib/assets/icons/heart_style=fill.svg": "4d4326d86407e757525313f18523422e",
"assets/packages/picnic_lib/assets/icons/menu_style=line.svg": "802b14038cfd4b1d284d60d3c83a4dea",
"assets/packages/picnic_lib/assets/icons/search_style=line.svg": "923ddc1d06e2ad6af6c4ba3c37a749ac",
"assets/packages/picnic_lib/assets/icons/cancel_style=fill.svg": "7ca28edf662b21cb330e39cde52df2d7",
"assets/packages/picnic_lib/assets/icons/arrow_left_style=line.svg": "3370e17cb8ebf7b60813adbe5c52c271",
"assets/packages/picnic_lib/assets/icons/camera_style=line.svg": "872d9fae0263530e707816215d85a25e",
"assets/packages/picnic_lib/assets/icons/post/post_underline.svg": "50ce547a482c0ff4d1d75cad76481ab3",
"assets/packages/picnic_lib/assets/icons/post/post_bold.svg": "fac316ec5e2fc22c10a477c46e5f6947",
"assets/packages/picnic_lib/assets/icons/post/post_link.svg": "3bb9f714073be6e67751eb87085a1df3",
"assets/packages/picnic_lib/assets/icons/post/post_media.svg": "d463ae31b2c1f3dc52933565a7eff160",
"assets/packages/picnic_lib/assets/icons/post/post_italic.svg": "e71266608988170aa17fba6e71163d74",
"assets/packages/picnic_lib/assets/icons/post/post_attachment.svg": "0a9fcd7c447f12a95b3173c198c3182c",
"assets/packages/picnic_lib/assets/icons/post/post_undo.svg": "14afbe71daeeaa4fa78c0ae00232ceb5",
"assets/packages/picnic_lib/assets/icons/post/post_youtube.svg": "ee2b003920d01818756f72eda1cc5ec3",
"assets/packages/picnic_lib/assets/icons/post/post_redo.svg": "fd82433cde73e3dc2302b525ea4db5c5",
"assets/packages/picnic_lib/assets/icons/reset_style=line.svg": "81eb8282bfd409dbeb8cb6b3ac096f60",
"assets/packages/picnic_lib/assets/icons/book_style=line.svg": "d5922c28b5f26182176d12bf3fb83487",
"assets/packages/picnic_lib/assets/icons/post_youtube_style=line.svg": "e1390e1c7d13e043d72b7b3704527020",
"assets/packages/picnic_lib/assets/icons/arrow_right_style=line.svg": "07779824fe78ccf1516edcababde84e7",
"assets/packages/picnic_lib/assets/icons/heart_style=line.svg": "4e6a5d53de1d2bb526f8e0e426399270",
"assets/packages/picnic_lib/assets/icons/cancel_style=line.svg": "ca0c7f32dd74704b44e28f58ffd98a8b",
"assets/packages/picnic_lib/assets/icons/twitter_style=fill.svg": "cbefe99a3002f300efcd5021b215204e",
"assets/packages/picnic_lib/assets/icons/add_style=line.svg": "363dca2bb78e3d9b9210f26726034d57",
"assets/packages/picnic_lib/assets/icons/arrow_up_style=line.svg": "aec1ac772cb1a121a4ba9b86003da392",
"assets/packages/picnic_lib/assets/icons/mystar_style=line.svg": "7a6210e39b1fa62e81e5cd91bf24f8c0",
"assets/packages/picnic_lib/assets/icons/post_attach_style=line.svg": "3940289bc96659d32fac7a21335c837a",
"assets/packages/picnic_lib/assets/icons/post_media_style=line.svg": "b351aaa6f2e6593c7053efd3d2036084",
"assets/packages/picnic_lib/assets/icons/hypen_style=line.svg": "b33f770d1ddae481603ab82804f7ab85",
"assets/packages/picnic_lib/assets/icons/scrap_style=fill.svg": "943422e0c719df0e22a0924c36a3b302",
"assets/packages/picnic_lib/assets/icons/camera_style=fill.svg": "70d6c7a70cf0a91f960a84ea06ff5d96",
"assets/packages/picnic_lib/assets/icons/my_style=line.svg": "055f5760632c057a1b40f81a650e370a",
"assets/packages/picnic_lib/assets/icons/cs_style=line.svg": "a26652ae03b692cfbd2ccfa7a3851ab4",
"assets/packages/picnic_lib/assets/icons/check_green.svg": "18a4f8cd6b4a762ec727b2eb14da7fa5",
"assets/packages/picnic_lib/assets/icons/bookmark_style=line.svg": "c8510f1b372d37133a0bba7eaead745d",
"assets/packages/picnic_lib/assets/icons/information_style=fill.svg": "15c5623cae34c24146058144642e5238",
"assets/packages/picnic_lib/assets/icons/reply_style=fill.svg": "a1d81898ab01ef06d22a6726c532e063",
"assets/packages/picnic_lib/assets/icons/alarm_style=line.svg": "af1414ebe53872658e5514257954c997",
"assets/packages/picnic_lib/assets/icons/delete_style=line.svg": "b7dcd9d4a4590d448f3aad0b4fdcc532",
"assets/packages/picnic_lib/assets/icons/post_link_style=line.svg": "7709bff3e965e68716cadb892984f1e7",
"assets/packages/picnic_lib/assets/icons/global_style=line.svg": "53c4121ee53c23282a9e015b2e6aa795",
"assets/packages/picnic_lib/assets/icons/switch_thumb.svg": "09daa56f288c3a287469449782a0af0a",
"assets/packages/picnic_lib/assets/icons/calendar_style=line.svg": "bf4b6082c09d75c3be9d79f6989bf1ae",
"assets/packages/picnic_lib/assets/icons/more_style=line.svg": "c60940a953dbee258c6beff1f383a07d",
"assets/packages/picnic_lib/assets/icons/check_style=fill.svg": "894a6ab5304261462eff2a4c7a098676",
"assets/packages/picnic_lib/assets/icons/compatibility_style=fill.svg": "939db5f64976de35024b7e3d48943cf0",
"assets/packages/picnic_lib/assets/icons/media_style=line.svg": "3acecfab470d6622370b9ecbada4d374",
"assets/packages/picnic_lib/assets/icons/dropdown.svg": "22dbb562216240e44b8042937760cbec",
"assets/packages/picnic_lib/assets/icons/writer_style=line.svg": "240583993020bc607fffc001947c4ddf",
"assets/packages/picnic_lib/assets/icons/store_style=line.svg": "1600b18234d260e29f16b8311559f182",
"assets/packages/picnic_lib/assets/icons/bookmark_style=fill.svg": "0ca13d694535035256b0a756a4556dae",
"assets/packages/picnic_lib/assets/icons/information_style=line.svg": "d49e47482593a3c00c10c1ab77bd7ab6",
"assets/packages/picnic_lib/assets/icons/arrow_down_style=line.svg": "4b317348e9ee49206be1f61b2f69330c",
"assets/packages/picnic_lib/assets/icons/star_candy_icon.svg": "05dd869fbafa40bb3ac8c68b6fdeed23",
"assets/packages/picnic_lib/assets/icons/send_style=fill.svg": "f9eba96f41274c5619cc2e5618024b9b",
"assets/packages/picnic_lib/assets/icons/switch_thumb.png": "82ad4888ca9ef73be01ec82990de99ed",
"assets/packages/picnic_lib/assets/icons/reply_style=line.svg": "322cf3836aabb6dd4d68bd314adc6a6e",
"assets/packages/picnic_lib/assets/icons/setting_style=line.svg": "74429892093522b6f954dc3eda14adee",
"assets/packages/picnic_lib/assets/icons/textclear.svg": "1d2790d7377157f6f4b5837b04838ab1",
"assets/packages/picnic_lib/assets/icons/check_style=line.svg": "2a3bd857af754f771a92b7b1426c32fc",
"assets/packages/picnic_lib/assets/icons/vote_style=line.svg": "ad1277fedf6fcbb039173228407610ac",
"assets/packages/picnic_lib/assets/icons/play_style=fill.svg": "3b08889545192dcf3f5fc8c325b36c2c",
"assets/packages/picnic_lib/assets/icons/bottom/home.svg": "ef6a2f179068e39bf4c687a8828c4439",
"assets/packages/picnic_lib/assets/icons/bottom/library.svg": "0ba47864b52df33168f5e052bb0f4789",
"assets/packages/picnic_lib/assets/icons/bottom/store.svg": "c100f1f68bc0cfd06b6870c5369f7509",
"assets/packages/picnic_lib/assets/icons/bottom/vote.svg": "c119fb0ba3f076cf972e667afc458c7a",
"assets/packages/picnic_lib/assets/icons/bottom/gallery.svg": "625af97b014e70ae53a812483798dc9b",
"assets/packages/picnic_lib/assets/icons/bottom/pic_chart.svg": "ce61403fbbab79f3e98f48204a9a96fb",
"assets/packages/picnic_lib/assets/icons/bottom/subscription.svg": "81b4245c67a80b4e55c9413f883a244d",
"assets/packages/picnic_lib/assets/icons/bottom/my.svg": "c2f129499f80cbe46545fe47530ca86e",
"assets/packages/picnic_lib/assets/icons/bottom/media.svg": "588c2be841c7aabdbbd8e64555ad65e9",
"assets/packages/picnic_lib/assets/icons/bottom/board.svg": "526b844da8dcfb98fe749d7cb9fcd897",
"assets/packages/picnic_lib/assets/icons/login/apple.png": "345aba0171ab18b2f7763c49ac0f05b5",
"assets/packages/picnic_lib/assets/icons/login/kakao.png": "eb74c59dc13adc1bd7faacac8ad274b9",
"assets/packages/picnic_lib/assets/icons/login/google.png": "54f5552b8b0e65c0c4c99b0347502cec",
"assets/packages/picnic_lib/assets/icons/header/plus.png": "519482b8ad5160e364a34593aa7727a3",
"assets/packages/picnic_lib/assets/icons/header/no_avatar.png": "bd595429e0be9dbc7270ffc56ad7638f",
"assets/packages/picnic_lib/assets/icons/header/default_avatar.svg": "5cb6d52dd29b691df8178f45cde28d60",
"assets/packages/picnic_lib/assets/icons/header/star.png": "4334100de689d587d2d2b56978ebc608",
"assets/packages/picnic_lib/assets/icons/chart_style=line.svg": "9477c27ac792487144497d5ac3c73ec4",
"assets/packages/picnic_lib/assets/icons/plus_style=fill.svg": "18352bb260e572addbf67434439c1d16",
"assets/packages/picnic_lib/assets/icons/share_style=line.svg": "77f69f857f5b6a9bcc3493dbc78ef452",
"assets/packages/picnic_lib/assets/icons/store/star_200.png": "2c4b0c0ee9945b1ce1eee6e196f895a6",
"assets/packages/picnic_lib/assets/icons/store/star_4000.png": "ce91c4bde03f5d7eb18a4f784c5a22ce",
"assets/packages/picnic_lib/assets/icons/store/star_600.png": "cbd89ac35886e2e703336040e0c7005a",
"assets/packages/picnic_lib/assets/icons/store/star_100.png": "77b070e9163d83ed1d2247d26c0a852f",
"assets/packages/picnic_lib/assets/icons/store/star_10000.png": "b3ffb86e33ca7cda907be09f4ced7555",
"assets/packages/picnic_lib/assets/icons/store/star_2000.png": "780e7076da6780941cece6b7c7348bc6",
"assets/packages/picnic_lib/assets/icons/store/star_7000.png": "e12bc7db14ea27b00486028276b56bb7",
"assets/packages/picnic_lib/assets/icons/store/star_5000.png": "c9c2b38ed43fa156922ae2808e1354cc",
"assets/packages/picnic_lib/assets/icons/store/star_1000.png": "d1cbace968650b4e4e10b091ca900422",
"assets/packages/picnic_lib/assets/icons/store/star_3000.png": "040ecff5b7f51bc5f7faf521aa937492",
"assets/packages/picnic_lib/assets/icons/fortune/quote_open.svg": "2b107da5404838cf283059bae066d727",
"assets/packages/picnic_lib/assets/icons/fortune/quote_close.svg": "1623cf51812f2bc3dde9da7578818993",
"assets/packages/picnic_lib/assets/icons/fortune/fortune_teller_title.svg": "7023ca681c4ebcad15aac943ac806453",
"assets/packages/picnic_lib/assets/icons/fortune/time.svg": "79eda7409b50b7fd4e04eece29163827",
"assets/packages/picnic_lib/assets/icons/fortune/calendar.svg": "83e0f5573768fce02cd7f581f6a0d62d",
"assets/packages/picnic_lib/assets/icons/fortune/heart.svg": "00b12d2f7d9eb03d1f74be578d189fc4",
"assets/packages/picnic_lib/assets/mockup/ko4.png": "c478a0aaf004dd5a744cfd55909df0f8",
"assets/packages/picnic_lib/assets/mockup/pic/replay.png": "aac1e43b2b13a9b9e41228145cc99aaf",
"assets/packages/picnic_lib/assets/mockup/pic/prame4.png": "d876038c4047bba975a77ce1b0e17099",
"assets/packages/picnic_lib/assets/mockup/pic/prame5.png": "270cb46a19e103a0d16cab8629679257",
"assets/packages/picnic_lib/assets/mockup/pic/prame1.png": "9ea06358f22a5ca897bddd3fa5e6e4ca",
"assets/packages/picnic_lib/assets/mockup/pic/prame2.png": "19279b2eb886bb8c527031345f4f7444",
"assets/packages/picnic_lib/assets/mockup/pic/prame3.png": "5b6909111466f88495ab0ea125f84678",
"assets/packages/picnic_lib/assets/mockup/pic/che1.png": "b8716b8fed85fcbd09ddf4ea447e674c",
"assets/packages/picnic_lib/assets/mockup/pic/che2.png": "27187b9c076125a8d66934afeae4dfa7",
"assets/packages/picnic_lib/assets/mockup/pic/che3.png": "c13cc25b5b21bf864079b1f745ba36f7",
"assets/packages/picnic_lib/assets/mockup/pic/reply.png": "a0bc553ac5f6b834927affe869511556",
"assets/packages/picnic_lib/assets/mockup/pic/prompt_suggestion.png": "2e91f72d0d28d90a28f9632fb4782634",
"assets/packages/picnic_lib/assets/mockup/pic/sign.png": "d7cd270d55b2bfb5b41cd6cfc03960ca",
"assets/packages/picnic_lib/assets/mockup/pic/background.png": "c88caf15d658d85417f26827010ae193",
"assets/packages/picnic_lib/assets/mockup/pic/ko4.png": "7ee68d3660164d3cdc5384de5d801d0e",
"assets/packages/picnic_lib/assets/mockup/pic/ko5.png": "7f96498585e92e59000c6dd55301510c",
"assets/packages/picnic_lib/assets/mockup/pic/help.png": "5409cfeddca2e953ae8e5b2efe768ffa",
"assets/packages/picnic_lib/assets/mockup/pic/more_vert.png": "2ea5e2c456b61be78f4171428bd2c85d",
"assets/packages/picnic_lib/assets/mockup/pic/ko2.png": "9a97024e2ae8b8b09b7126775ec32179",
"assets/packages/picnic_lib/assets/mockup/pic/ko3.png": "31e6d12fd7d28bab92c74dc7e8a3340e",
"assets/packages/picnic_lib/assets/mockup/pic/ko1.png": "3cdc2c7b680bc35fb48062c98ff80166",
"assets/packages/picnic_lib/assets/mockup/pic/delete.png": "60cbcacdaf13817cac287e7997b5e607",
"assets/packages/picnic_lib/assets/mockup/pic/decoration.png": "697c02952013783bfe89531dcff5ab1d",
"assets/packages/picnic_lib/assets/mockup/pic/camera.png": "e9f390f318b054723f32ac76ee735c19",
"assets/packages/picnic_lib/assets/mockup/pic/%25ED%2594%2584%25EB%25A0%2588%25EC%259E%2584%2520%25EB%25B0%25B0%25EA%25B2%25BD%25201.png": "c9bb607a4e3e5751e06479c17ea6d238",
"assets/packages/picnic_lib/assets/mockup/pic/save.png": "ec1bc74119e0486aebf65b923350253c",
"assets/packages/picnic_lib/assets/mockup/ko2.png": "e50725aa459575283da9da7a6fde2865",
"assets/packages/picnic_lib/assets/mockup/ko3.png": "8148123ba22a80d9f775572133cc5f84",
"assets/packages/picnic_lib/assets/fonts/Pretendard/Pretendard-Regular.otf": "46b0c48afd8b0ddc2ed4fcbb2df81d8b",
"assets/packages/picnic_lib/assets/fonts/Pretendard/Pretendard-Black.otf": "6bc3f501ba4e736b706074a29826ec0a",
"assets/packages/picnic_lib/assets/fonts/Pretendard/Pretendard-Medium.otf": "9ac30a1a68a5140a58b23aaf8025f1db",
"assets/packages/picnic_lib/assets/fonts/Pretendard/Pretendard-Light.otf": "aef3dc5f5592a0a9bfd7e8de7abdc2c5",
"assets/packages/picnic_lib/assets/fonts/Pretendard/Pretendard-ExtraBold.otf": "dac19e30ed93b7aed171830c38cda6a2",
"assets/packages/picnic_lib/assets/fonts/Pretendard/Pretendard-Bold.otf": "e93f79700405e1b4c1b3e70d8c378ca4",
"assets/packages/picnic_lib/assets/fonts/Pretendard/Pretendard-Thin.otf": "0b09a12c024a6380cd40dbfaf2fd79cd",
"assets/packages/picnic_lib/assets/fonts/Pretendard/Pretendard-ExtraLight.otf": "23002daa2dee07f8a652bb0ab06af079",
"assets/packages/picnic_lib/assets/fonts/Pretendard/Pretendard-SemiBold.otf": "d9d912f2630bae445757f4769271c35c",
"assets/packages/quill_native_bridge_linux/assets/xclip": "d37b0dbbc8341839cde83d351f96279e",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/AssetManifest.bin": "5466dcb1a0982298243c449d80fafd92",
"assets/fonts/MaterialIcons-Regular.otf": "646c07a08eca4589fd151b30c3db2c0d",
"assets/assets/app_icon.png": "d8182231ed626e86faf27482146ca440",
"assets/assets/app_icon_256.png": "4970c7abdafab8ef64c9a7ec8677443a",
"assets/assets/splash.webp": "15d5039b89963e575ea6578a2eab9946",
"assets/assets/top_logo.svg": "13771a453ed53f050ece222e8690d32d",
"assets/assets/splash.png": "6268d6c89dfc3a9cc5fce7ccf6735bcd",
"assets/assets/app_icon_128.png": "fa2fceca08d188f155935d3bdd0b9233",
"assets/assets/login/ja_1.png": "8f7f7becd7e87d2c3306b7dc1b33a7ff",
"assets/assets/login/en_2.png": "62eb6cd08781ce50953d56bbbe44fda5",
"assets/assets/login/ja_2.png": "62eb6cd08781ce50953d56bbbe44fda5",
"assets/assets/login/ko_2.png": "62eb6cd08781ce50953d56bbbe44fda5",
"assets/assets/login/ko_1.png": "8f7f7becd7e87d2c3306b7dc1b33a7ff",
"assets/assets/login/zh_2.png": "62eb6cd08781ce50953d56bbbe44fda5",
"assets/assets/login/zh_1.png": "8f7f7becd7e87d2c3306b7dc1b33a7ff",
"canvaskit/skwasm_st.js": "d1326ceef381ad382ab492ba5d96f04d",
"canvaskit/skwasm.js": "ac0f73826b925320a1e9b0d3fd7da61c",
"canvaskit/skwasm.js.symbols": "96263e00e3c9bd9cd878ead867c04f3c",
"canvaskit/canvaskit.js.symbols": "efc2cd87d1ff6c586b7d4c7083063a40",
"canvaskit/skwasm.wasm": "828c26a0b1cc8eb1adacbdd0c5e8bcfa",
"canvaskit/chromium/canvaskit.js.symbols": "e115ddcfad5f5b98a90e389433606502",
"canvaskit/chromium/canvaskit.js": "b7ba6d908089f706772b2007c37e6da4",
"canvaskit/chromium/canvaskit.wasm": "ea5ab288728f7200f398f60089048b48",
"canvaskit/skwasm_st.js.symbols": "327a3060925e525407f4f2747a4712d6",
"canvaskit/canvaskit.js": "26eef3024dbc64886b7f48e1b6fb05cf",
"canvaskit/canvaskit.wasm": "e7602c687313cfac5f495c5eac2fb324",
"canvaskit/skwasm_st.wasm": "809674c831d83f7f9c71d9dd93771403",
"canvaskit/skwasm.worker.js": "89990e8c92bcb123999aa81f7e203b1c"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:overlay_loading_progress/overlay_loading_progress.dart';
import 'package:path/path.dart' as path;
import 'package:picnic_app/components/common/avatar_container.dart';
import 'package:picnic_app/components/common/picnic_list_item.dart';
import 'package:picnic_app/components/star_candy_info_text.dart';
import 'package:picnic_app/config/environment.dart';
import 'package:picnic_app/dialogs/simple_dialog.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/pages/my_page/privacy_page.dart';
import 'package:picnic_app/pages/my_page/terms_page.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/providers/user_info_provider.dart';
import 'package:picnic_app/services/auth/auth_service.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/logger.dart';
import 'package:picnic_app/util/ui.dart';
import 'package:picnic_app/util/util.dart';
import 'package:supabase_extensions/supabase_extensions.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MyProfilePage extends ConsumerStatefulWidget {
  final String pageName = 'page_title_myprofile';

  const MyProfilePage({super.key});

  @override
  ConsumerState<MyProfilePage> createState() => _SettingPageState();
}

class _SettingPageState extends ConsumerState<MyProfilePage> {
  final TextEditingController _textEditingController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool isValid = true;
  late FocusNode _focusNode;

  @override
  initState() {
    super.initState();
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _textEditingController.text =
          ref.watch(userInfoProvider).value?.nickname ?? '';
    });

    _textEditingController.addListener(() {
      setState(() {
        isValid = validateInput(_textEditingController.text) == null;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.cw),
        child: ListView(
          children: [
            const SizedBox(height: 24),
            buildProfileImage(),
            const SizedBox(height: 24),
            buildNicknameInput(context),
            const SizedBox(height: 4),
            buildValidationMsg(context),
            const SizedBox(height: 26),
            if (supabase.isLogged)
              PicnicListItem(
                leading: S.of(context).label_mypage_picnic_id,
                title: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    supabase.auth.currentUser?.id ?? '',
                    style: getTextStyle(AppTypo.body14B, AppColors.grey900),
                  ),
                ),
                tailing:
                    Icon(Icons.copy, color: AppColors.primary500, size: 16.cw),
                assetPath: 'assets/icons/arrow_right_style=line.svg',
                onTap: () => copyToClipboard(
                    context, supabase.auth.currentUser?.id ?? ''),
              ),
            PicnicListItem(
                leading: S.of(context).label_mypage_terms_of_use,
                assetPath: 'assets/icons/arrow_right_style=line.svg',
                onTap: () {
                  ref
                      .read(navigationInfoProvider.notifier)
                      .setCurrentMyPage(const TermsPage());
                }),
            PicnicListItem(
                leading: S.of(context).label_mypage_privacy_policy,
                assetPath: 'assets/icons/arrow_right_style=line.svg',
                onTap: () {
                  ref
                      .read(navigationInfoProvider.notifier)
                      .setCurrentMyPage(const PrivacyPage());
                }),
            PicnicListItem(
                leading: S.of(context).label_mypage_logout,
                assetPath: 'assets/icons/arrow_right_style=line.svg',
                onTap: () {
                  ref.read(userInfoProvider.notifier).logout();
                  ref
                      .read(navigationInfoProvider.notifier)
                      .setResetStackMyPage();
                  Navigator.of(context).pop();
                }),
            PicnicListItem(
                leading: S.of(context).label_mypage_withdrawal,
                assetPath: 'assets/icons/arrow_right_style=line.svg',
                onTap: () => _showWithdrawalModal()),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadProfileImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    final userId = supabase.auth.currentUser?.id;

    if (image != null) {
      // 이미지 크롭
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: image.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
              toolbarTitle: '',
              toolbarColor: AppColors.primary500,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true),
          IOSUiSettings(title: ''),
        ],
      );

      if (croppedFile != null) {
        try {
          OverlayLoadingProgress.start(context);
          final Uint8List fileBytes = await croppedFile.readAsBytes();

          // 파일 이름 생성
          final String fileName =
              '$userId/avatar_${DateTime.now().millisecondsSinceEpoch}${path.extension(croppedFile.path)}';

          // Supabase Storage에 이미지 업로드
          final storageResponse =
              await supabase.storage.from('avatars').uploadBinary(
                    fileName,
                    fileBytes,
                    fileOptions: const FileOptions(
                      cacheControl: '3600',
                      upsert: true,
                    ),
                  );

          if (storageResponse.isNotEmpty) {
            // 업로드된 이미지의 공개 URL 가져오기
            final String imageUrl =
                supabase.storage.from('avatars').getPublicUrl(fileName);

            // 사용자 프로필 업데이트
            await ref.read(userInfoProvider.notifier).updateAvatar(imageUrl);

            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(S.of(context).common_success),
                duration: const Duration(seconds: 2)));
          } else {
            throw Exception('Failed to upload image');
          }
        } catch (e, s) {
          logger.e('error', error: e, stackTrace: s);

          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(S.of(context).common_fail),
          ));
          rethrow;
        } finally {
          OverlayLoadingProgress.stop();
        }
      }
    }
  }

  _showWithdrawalModal() {
    DateTime now = DateTime.now();

    // 30일을 더합니다
    DateTime futureDate = now.add(const Duration(days: 30));

    // 로케일을 가져옵니다
    String locale = Localizations.localeOf(context).toString();

    // DateFormat을 사용하여 로케일에 맞는 형식으로 날짜를 포맷팅합니다
    String formattedDate =
        DateFormat.yMMMMd(locale).add_jm().format(futureDate);

    showModalBottomSheet(
        context: context,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(48).r,
            topRight: const Radius.circular(48).r,
          ),
        ),
        builder: (context) => StatefulBuilder(
              builder: (context, setState) => Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 16.cw, vertical: 40.h),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(
                    S.of(context).dialog_withdraw_title,
                    style: getTextStyle(AppTypo.title18SB, AppColors.grey900),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    S.of(context).dialog_will_delete_star_candy,
                    style: getTextStyle(AppTypo.body14B, AppColors.grey900),
                  ),
                  const StarCandyInfoText(),
                  const SizedBox(height: 24),
                  Text(S.of(context).dialog_withdraw_message,
                      style:
                          getTextStyle(AppTypo.caption12R, AppColors.grey700),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  Text(S.of(context).dialog_message_can_resignup,
                      style:
                          getTextStyle(AppTypo.caption12R, AppColors.grey700),
                      textAlign: TextAlign.center),
                  Text(formattedDate,
                      style:
                          getTextStyle(AppTypo.caption12B, AppColors.grey700),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: MaterialButton(
                            onPressed: () => _deleteAccount(),
                            child: Container(
                                alignment: Alignment.center,
                                padding: EdgeInsets.symmetric(
                                    horizontal: 20.cw, vertical: 8),
                                constraints: BoxConstraints(
                                  minWidth: 100.cw,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.grey300,
                                  borderRadius: BorderRadius.circular(30.cw),
                                ),
                                child: Text(
                                    S.of(context).dialog_withdraw_button_ok,
                                    style: getTextStyle(
                                        AppTypo.title18SB, AppColors.grey00)))),
                      ),
                      Expanded(
                        child: MaterialButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Container(
                                alignment: Alignment.center,
                                padding: EdgeInsets.symmetric(
                                    horizontal: 20.cw, vertical: 8),
                                constraints: BoxConstraints(
                                  minWidth: 100.cw,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.grey00,
                                  borderRadius: BorderRadius.circular(30.cw),
                                  border: Border.all(
                                      color: AppColors.primary500,
                                      width: 1.5.cw),
                                ),
                                child: Text(S.of(context).dialog_button_cancel,
                                    style: getTextStyle(AppTypo.title18SB,
                                        AppColors.primary500)))),
                      ),
                    ],
                  )
                ]),
              ),
            ));
  }

  Future<void> _deleteAccount() async {
    try {
      // 현재 로그인된 사용자 가져오기
      final user = supabase.auth.currentUser;
      if (user == null) {
        logger.i('No user is signed in');
        return;
      }

      // Edge Function 호출
      final response = await http.post(
        Uri.parse('${Environment.supabaseUrl}/functions/v1/delete-user'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization':
              'Bearer ${supabase.auth.currentSession!.accessToken}',
        },
        body: jsonEncode(<String, String>{
          'userId': user.id,
        }),
      );

      logger.d('Response status: ${response.statusCode}');
      logger.d('Response body: ${response.body}');

      if (response.statusCode == 200) {
        logger.i('User deleted successfully');
        ref.read(navigationInfoProvider.notifier).setBottomNavigationIndex(0);
        final authService = AuthService();
        await authService.signOut();
      } else {
        throw Exception('Failed to delete user: ${response.body}');
      }
    } catch (e, s) {
      logger.e(s, stackTrace: s);
      rethrow;
    }
  }

  Container buildValidationMsg(BuildContext context) {
    return Container(
      height: 32,
      alignment: Alignment.topLeft,
      padding: EdgeInsets.only(left: 16.cw),
      margin: EdgeInsets.symmetric(horizontal: 57.cw),
      child: isValid == false
          ? Text(
              S.of(context).nickname_validation_error,
              style: getTextStyle(AppTypo.caption10SB, AppColors.statusError),
            )
          : null,
    );
  }

  Widget buildNicknameInput(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24.cw),
              border: Border.all(
                  color: isValid ? AppColors.primary500 : AppColors.statusError,
                  strokeAlign: BorderSide.strokeAlignInside,
                  width: 1.5.cw),
            ),
            padding: EdgeInsets.symmetric(horizontal: 16.cw),
            alignment: Alignment.center,
            height: 48,
            width: 200.cw,
            child: Form(
              key: _formKey,
              child: TextFormField(
                controller: _textEditingController,
                // autovalidateMode: AutovalidateMode.onUserInteraction,
                onChanged: (value) {
                  logger.d('onChanged');
                  setState(() {
                    isValid = validateInput(value) == null;
                  });
                },
                cursorColor: AppColors.primary500,
                focusNode: _focusNode,
                cursorHeight: 16.cw,
                keyboardType: TextInputType.text,
                style: getTextStyle(AppTypo.body16B, AppColors.grey900),
                decoration: InputDecoration(
                  hintText: S.of(context).hint_nickname_input,
                  hintStyle: getTextStyle(AppTypo.body14B, AppColors.grey300),
                  border: InputBorder.none,
                  fillColor: AppColors.grey900,
                  focusColor: AppColors.primary500,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  suffixIconConstraints: BoxConstraints(
                    minWidth: 20.cw,
                    minHeight: 20.cw,
                  ),
                  suffixIcon: _focusNode.hasFocus
                      ? GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            _textEditingController.clear();
                            setState(() {
                              isValid =
                                  validateInput(_textEditingController.text) ==
                                      null;
                            });
                          },
                          child: _textEditingController.text.isEmpty
                              ? SvgPicture.asset(
                                  'assets/icons/cancel_style=fill.svg',
                                  colorFilter: const ColorFilter.mode(
                                    AppColors.grey300,
                                    BlendMode.srcIn,
                                  ),
                                  width: 20.cw,
                                  height: 20,
                                )
                              : GestureDetector(
                                  onTap: () {
                                    _textEditingController.clear();
                                    setState(() {
                                      isValid = validateInput(
                                              _textEditingController.text) ==
                                          null;
                                    });
                                  },
                                  child: SvgPicture.asset(
                                    'assets/icons/cancel_style=fill.svg',
                                    colorFilter: const ColorFilter.mode(
                                      AppColors.grey700,
                                      BlendMode.srcIn,
                                    ),
                                    width: 20.cw,
                                    height: 20,
                                  ),
                                ),
                        )
                      : null,
                ),
              ),
            )),
        GestureDetector(
          onTap: () async {
            _focusNode.unfocus();
            if (isValid &&
                _textEditingController.text !=
                    ref.watch(userInfoProvider).value?.nickname) {
              OverlayLoadingProgress.start(context);
              ref
                  .read(userInfoProvider.notifier)
                  .updateNickname(_textEditingController.text)
                  .then((success) {
                if (success) {
                  // 닉네임 변경 성공
                  showSimpleDialog(
                      content: S.of(context).message_update_nickname_success);
                } else {
                  // 닉네임 변경 실패 (중복 또는 오류)
                  showSimpleDialog(
                      content: S.of(context).message_update_nickname_fail);
                }
                OverlayLoadingProgress.stop();
              });
            }
          },
          child: Container(
            width: 48.cw,
            height: 48,
            alignment: Alignment.center,
            margin: EdgeInsets.only(left: 8.cw),
            decoration: BoxDecoration(
              color: isValid &&
                      _textEditingController.text !=
                          ref.watch(userInfoProvider).value?.nickname
                  ? AppColors.primary500
                  : AppColors.grey300,
              borderRadius: BorderRadius.circular(24.cw),
            ),
            child: SvgPicture.asset('assets/icons/pencil_style=fill.svg',
                colorFilter: const ColorFilter.mode(
                  AppColors.grey900,
                  BlendMode.srcIn,
                ),
                width: 24.cw,
                height: 24),
          ),
        ),
      ],
    );
  }

  Container buildProfileImage() {
    final userInfo = ref.watch(userInfoProvider);
    return userInfo.when(
        data: (data) => data != null
            ? Container(
                width: 100.cw,
                height: 100.cw,
                alignment: Alignment.center,
                child: Stack(
                  children: [
                    SizedBox(
                      width: 100.cw,
                      height: 100.cw,
                      child: ProfileImageContainer(
                        avatarUrl: userInfo.value?.avatarUrl,
                        borderRadius: 50.cw,
                        width: 100.cw,
                        height: 100.cw,
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: GestureDetector(
                        onTap: () => _uploadProfileImage(),
                        child: Container(
                            width: 24.cw,
                            height: 24,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.primary500,
                              borderRadius: BorderRadius.circular(50.cw),
                            ),
                            child: SvgPicture.asset(
                                'assets/icons/camera_style=line.svg',
                                width: 16.cw,
                                height: 16,
                                colorFilter: const ColorFilter.mode(
                                  AppColors.grey00,
                                  BlendMode.srcIn,
                                ))),
                      ),
                    ),
                  ],
                ),
              )
            : Container(),
        loading: () => Container(),
        error: (error, stackTrace) => Container());
  }

  String? validateInput(String? value) {
    // 한글, 일본어, 중국어, 영문, 숫자를 허용하는 정규 표현식 (공백과 특수문자 허용하지 않음)
    final regExp = RegExp(r'^[\w\d가-힣ぁ-ゔァ-ヴー々〆〤一-龥]+$');
    if (value == null ||
        value.isEmpty ||
        value.length > 20 ||
        !regExp.hasMatch(value)) {
      return S.of(context).nickname_validation_error;
    }
    return null;
  }
}

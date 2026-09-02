import 'dart:async';
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
import 'package:picnic_lib/core/config/environment.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/snackbar_util.dart';
import 'package:picnic_lib/core/utils/util.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/common/avatar_container.dart';
import 'package:picnic_lib/presentation/common/navigator_key.dart';
import 'package:picnic_lib/presentation/common/picnic_list_item.dart';
import 'package:picnic_lib/presentation/dialogs/simple_dialog.dart';
import 'package:picnic_lib/presentation/pages/my_page/privacy_page.dart';
import 'package:picnic_lib/presentation/pages/my_page/terms_page.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';
import 'package:picnic_lib/presentation/widgets/star_candy_info_text.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:picnic_lib/ui/style.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// 테스트에서 delete-user Edge Function 호출을 가로채기 위한 주입 지점.
///
/// 프로덕션에서는 항상 null 이고, 그때는 기존과 똑같이 top-level [http.post] 를
/// 쓴다. 테스트는 tearDown 에서 반드시 null 로 되돌린다.
@visibleForTesting
http.Client? testWithdrawalHttpClient;

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
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: ListView(
          children: [
            const SizedBox(height: 24),
            buildProfileImage(),
            const SizedBox(height: 24),
            buildNicknameInput(context),
            const SizedBox(height: 4),
            buildValidationMsg(context),
            const SizedBox(height: 26),
            if (isSupabaseLoggedSafely)
              PicnicListItem(
                leading: AppLocalizations.of(context).label_mypage_picnic_id,
                title: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    supabase.auth.currentUser?.id ?? '',
                    style: getTextStyle(AppTypo.body14B, AppColors.grey900),
                  ),
                ),
                tailing:
                    Icon(Icons.copy, color: AppColors.primary500, size: 16.w),
                assetPath: 'assets/icons/arrow_right_style=line.svg',
                onTap: () => copyToClipboard(
                    context, supabase.auth.currentUser?.id ?? ''),
              ),
            PicnicListItem(
                leading: AppLocalizations.of(context).label_mypage_terms_of_use,
                assetPath: 'assets/icons/arrow_right_style=line.svg',
                onTap: () {
                  ref
                      .read(navigationInfoProvider.notifier)
                      .setCurrentMyPage(const TermsPage());
                }),
            PicnicListItem(
                leading:
                    AppLocalizations.of(context).label_mypage_privacy_policy,
                assetPath: 'assets/icons/arrow_right_style=line.svg',
                onTap: () {
                  ref
                      .read(navigationInfoProvider.notifier)
                      .setCurrentMyPage(const PrivacyPage());
                }),
            PicnicListItem(
                leading: AppLocalizations.of(context).label_mypage_logout,
                assetPath: 'assets/icons/arrow_right_style=line.svg',
                onTap: () {
                  ref.read(userInfoProvider.notifier).logout();
                  ref
                      .read(navigationInfoProvider.notifier)
                      .setResetStackMyPage();
                  Navigator.of(context).pop();
                }),
            PicnicListItem(
                leading: AppLocalizations.of(context).label_mypage_withdrawal,
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

    if (image != null && mounted) {
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

      if (croppedFile != null && mounted) {
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

            if (navigatorKey.currentContext != null) {
              SnackbarUtil().info(
                  AppLocalizations.of(navigatorKey.currentContext!)
                      .common_success);
            }
          } else {
            throw Exception('Failed to upload image');
          }
        } catch (e, s) {
          logger.e('error', error: e, stackTrace: s);

          if (navigatorKey.currentContext != null) {
            SnackbarUtil().error(
                AppLocalizations.of(navigatorKey.currentContext!).common_fail);
          }
          rethrow;
        } finally {
          if (mounted) {
            OverlayLoadingProgress.stop();
          }
        }
      }
    }
  }

  Future<void> _showWithdrawalModal() async {
    DateTime now = DateTime.now();

    // 30일을 더합니다
    DateTime futureDate = now.add(const Duration(days: 30));

    // 로케일을 가져옵니다
    String locale = Localizations.localeOf(context).toString();

    // DateFormat을 사용하여 로케일에 맞는 형식으로 날짜를 포맷팅합니다
    String formattedDate =
        DateFormat.yMMMMd(locale).add_jm().format(futureDate);

    // 요청이 진행 중인지. StatefulBuilder 의 builder 는 setState 마다 다시
    // 불리므로 상태는 반드시 그 바깥에 둔다.
    bool isWithdrawing = false;

    showModalBottomSheet(
        context: context,
        // 진행 중 이탈 차단 1 — scrim 탭과 드래그.
        //
        // 버튼만 잠가서는 부족했다. 요청이 떠 있는 동안 scrim 을 누르거나
        // 시트를 아래로 밀어 닫아 버리면, 뒤늦게 200 이 도착했을 때 성공
        // 경로의 pop 이 이미 사라진 시트 대신 그 아래(프로필 또는 그때의
        // 최상단) 라우트를 닫는다. 두 인자는 showModalBottomSheet 호출
        // 시점에 고정돼 조건부로 줄 수 없으므로 항상 잠근다 — 파괴적
        // 확인 시트라 명시적인 취소 버튼으로만 닫는 편이 맞다.
        isDismissible: false,
        enableDrag: false,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(48),
            topRight: const Radius.circular(48),
          ),
        ),
        builder: (sheetContext) =>
            StatefulBuilder(builder: (sheetContext, setModalState) {
              /// 확인 버튼 핸들러.
              ///
              /// 예전에는 `onPressed: () => _deleteAccount()` 라서 서버가 500 을
              /// 돌려주면 예외가 버튼 콜백 안에서 사라지고 화면에 아무 변화가
              /// 없었다. 사용자는 "버튼이 안 눌린다" 고 인지했고(PICNIC-2520),
              /// 응답을 기다리는 동안 계속 다시 탭할 수도 있었다.
              Future<void> handleWithdraw() async {
                if (isWithdrawing) return;
                setModalState(() => isWithdrawing = true);
                try {
                  await _deleteAccount(sheetContext);
                } catch (e, s) {
                  // 사용자 피드백이 먼저다. _deleteAccount 가 남긴 로그와 별개로
                  // Sentry 에는 계속 올라가야 하므로(PICNIC-APP-5GA) 여기서
                  // 명시적으로 보고한다 — rethrow 로 unhandled async error 를
                  // 만들어 zone 핸들러에 맡기면 이 catch 가 UI 를 복구할 기회를
                  // 잃는다.
                  final dialogContext = navigatorKey.currentContext;
                  if (dialogContext != null && dialogContext.mounted) {
                    showSimpleDialog(
                      content: AppLocalizations.of(dialogContext)
                          .withdrawal_failed,
                      type: DialogType.error,
                    );
                  }
                  unawaited(Sentry.captureException(e, stackTrace: s));
                } finally {
                  // 성공하면 _deleteAccount 가 이미 모달을 닫았다. 그때는
                  // StatefulBuilder 가 사라졌으므로 setState 를 건너뛴다.
                  if (sheetContext.mounted) {
                    setModalState(() => isWithdrawing = false);
                  }
                }
              }

              return PopScope(
                // 진행 중 이탈 차단 2 — 시스템 뒤로가기.
                //
                // isDismissible/enableDrag 과 달리 canPop 은 매 빌드마다 다시
                // 평가되므로, 요청 중에만 막고 평상시에는 뒤로가기로 닫히는
                // 기존 동작을 그대로 남길 수 있다.
                canPop: !isWithdrawing,
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 40.h),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(
                      AppLocalizations.of(sheetContext).dialog_withdraw_title,
                      style: getTextStyle(AppTypo.title18SB, AppColors.grey900),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      AppLocalizations.of(sheetContext)
                          .dialog_will_delete_star_candy,
                      style: getTextStyle(AppTypo.body14B, AppColors.grey900),
                    ),
                    const StarCandyInfoText(),
                    const SizedBox(height: 24),
                    Text(
                        AppLocalizations.of(sheetContext)
                            .dialog_withdraw_message,
                        style:
                            getTextStyle(AppTypo.caption12R, AppColors.grey700),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    Text(
                        AppLocalizations.of(sheetContext)
                            .dialog_message_can_resignup,
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
                              onPressed: isWithdrawing ? null : handleWithdraw,
                              child: Container(
                                  alignment: Alignment.center,
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 20.w, vertical: 8),
                                  constraints: BoxConstraints(
                                    minWidth: 100.w,
                                  ),
                                  decoration: BoxDecoration(
                                    // 활성 상태를 grey300 으로 칠해 두면 비활성
                                    // 버튼처럼 보인다 — CS 로 실제 접수된 오인이다.
                                    // 잠긴 동안에만 grey300 으로 낮춘다.
                                    color: isWithdrawing
                                        ? AppColors.grey300
                                        : AppColors.primary500,
                                    borderRadius: BorderRadius.circular(30.w),
                                  ),
                                  child: isWithdrawing
                                      ? SizedBox(
                                          width: 24.w,
                                          height: 24.w,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.w,
                                            color: AppColors.grey00,
                                          ),
                                        )
                                      : Text(
                                          AppLocalizations.of(sheetContext)
                                              .dialog_withdraw_button_ok,
                                          style: getTextStyle(AppTypo.title18SB,
                                              AppColors.grey00)))),
                        ),
                        Expanded(
                          child: MaterialButton(
                              // 요청 중에 모달을 닫으면 응답이 돌아왔을 때
                              // _deleteAccount 의 pop 이 엉뚱한 라우트를 닫는다.
                              // 닫을 때는 페이지가 아니라 **시트 자신의**
                              // 라우트를 대상으로 한다.
                              onPressed: isWithdrawing
                                  ? null
                                  : () => Navigator.of(sheetContext).pop(),
                              child: Container(
                                  alignment: Alignment.center,
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 20.w, vertical: 8),
                                  constraints: BoxConstraints(
                                    minWidth: 100.w,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.grey00,
                                    borderRadius: BorderRadius.circular(30.w),
                                    border: Border.all(
                                        color: isWithdrawing
                                            ? AppColors.grey300
                                            : AppColors.primary500,
                                        width: 1.5.w),
                                  ),
                                  child: Text(
                                      AppLocalizations.of(sheetContext)
                                          .dialog_button_cancel,
                                      style: getTextStyle(
                                          AppTypo.title18SB,
                                          isWithdrawing
                                              ? AppColors.grey300
                                              : AppColors.primary500)))),
                        ),
                      ],
                    )
                  ]),
                ),
              );
            }));
  }

  /// [sheetContext] 는 탈퇴 확인 바텀시트 **자신의** BuildContext 다.
  /// 성공했을 때 닫아야 하는 라우트가 바로 그 시트이므로, 페이지 context 로
  /// pop 하면 안 된다(아래 pop 지점 주석 참고).
  Future<void> _deleteAccount(BuildContext sheetContext) async {
    // ProviderContainer 캡쳐 — delete-user Edge Function 호출 중 setting page
    // 가 unmount 되면 (사용자가 뒤로가기 등) ref 접근이 StateError 를 던진다
    // (PICNIC-APP-W1). container 는 ProviderScope root 와 함께 살아있어 안전.
    final container = ProviderScope.containerOf(context);
    try {
      // 현재 로그인된 사용자 가져오기
      final user = supabase.auth.currentUser;
      if (user == null) {
        logger.i('No user is signed in');
        return;
      }

      // Edge Function 호출.
      // [testWithdrawalHttpClient] 이 주입돼 있으면 그쪽으로 보낸다 — 프로덕션
      // 에서는 항상 null 이라 기존과 동일하게 top-level http.post 를 탄다.
      final post = testWithdrawalHttpClient?.post ?? http.post;
      final response = await post(
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
        container
            .read(navigationInfoProvider.notifier)
            .setBottomNavigationIndex(0);
        container.read(userInfoProvider.notifier).logout();
        container.read(navigationInfoProvider.notifier).setResetStackMyPage();

        // 진행 중 이탈 차단 3 — pop 대상 고정.
        //
        // 예전에는 페이지 context 로 pop 해서 "그 Navigator 의 최상단" 을
        // 닫았다. 응답이 늦게 오는 동안 시트가 이미 사라졌다면 그 최상단은
        // 프로필(또는 그 위에 올라온 라우트)이라 엉뚱한 화면이 닫힌다.
        // 시트 잠금이 1차 방어지만 프로그램적으로 라우트가 밀리는 경우까지
        // 막히지는 않으므로, 여기서 (1) 시트 element 가 살아 있고 (2) 시트
        // 라우트가 아직 최상단일 때만 시트 자신을 닫는다. 닫을 대상이 시트
        // 라우트이므로 페이지의 `mounted` 는 판단 근거가 아니다.
        if (sheetContext.mounted &&
            ModalRoute.of(sheetContext)?.isCurrent == true) {
          Navigator.of(sheetContext).pop();
        }

        if (!mounted) return;
        if (navigatorKey.currentContext != null) {
          showSimpleDialog(
              content: AppLocalizations.of(navigatorKey.currentContext!)
                  .withdrawal_success);
        }
      } else {
        throw Exception('Failed to delete user: ${response.body}');
      }
    } catch (e, s) {
      logger.e('Failed to delete account', error: e, stackTrace: s);
      rethrow;
    }
  }

  Container buildValidationMsg(BuildContext context) {
    return Container(
      height: 32,
      alignment: Alignment.topLeft,
      padding: EdgeInsets.only(left: 16.w),
      margin: EdgeInsets.symmetric(horizontal: 57.w),
      child: isValid == false
          ? Text(
              AppLocalizations.of(context).nickname_validation_error,
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
              borderRadius: BorderRadius.circular(24.w),
              border: Border.all(
                  color: isValid ? AppColors.primary500 : AppColors.statusError,
                  strokeAlign: BorderSide.strokeAlignInside,
                  width: 1.5.w),
            ),
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            alignment: Alignment.center,
            height: 48,
            width: 200.w,
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
                cursorHeight: 16.w,
                keyboardType: TextInputType.text,
                style: getTextStyle(AppTypo.body16B, AppColors.grey900),
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context).hint_nickname_input,
                  hintStyle: getTextStyle(AppTypo.body14B, AppColors.grey300),
                  border: InputBorder.none,
                  fillColor: AppColors.grey900,
                  focusColor: AppColors.primary500,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  suffixIconConstraints: BoxConstraints(
                    minWidth: 20.w,
                    minHeight: 20.w,
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
                                  package: 'picnic_lib',
                                  'assets/icons/cancel_style=fill.svg',
                                  colorFilter: const ColorFilter.mode(
                                    AppColors.grey300,
                                    BlendMode.srcIn,
                                  ),
                                  width: 20.w,
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
                                    package: 'picnic_lib',
                                    'assets/icons/cancel_style=fill.svg',
                                    colorFilter: const ColorFilter.mode(
                                      AppColors.grey700,
                                      BlendMode.srcIn,
                                    ),
                                    width: 20.w,
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
                  if (navigatorKey.currentContext != null) {
                    showSimpleDialog(
                        content:
                            AppLocalizations.of(navigatorKey.currentContext!)
                                .message_update_nickname_success);
                  }
                } else {
                  // 닉네임 변경 실패 (중복 또는 오류)
                  if (navigatorKey.currentContext != null) {
                    showSimpleDialog(
                        content:
                            AppLocalizations.of(navigatorKey.currentContext!)
                                .message_update_nickname_fail);
                  }
                }
                OverlayLoadingProgress.stop();
              });
            }
          },
          child: Container(
            width: 48.w,
            height: 48,
            alignment: Alignment.center,
            margin: EdgeInsets.only(left: 8.w),
            decoration: BoxDecoration(
              color: isValid &&
                      _textEditingController.text !=
                          ref.watch(userInfoProvider).value?.nickname
                  ? AppColors.primary500
                  : AppColors.grey300,
              borderRadius: BorderRadius.circular(24.w),
            ),
            child: SvgPicture.asset(
                package: 'picnic_lib',
                'assets/icons/pencil_style=fill.svg',
                colorFilter: const ColorFilter.mode(
                  AppColors.grey900,
                  BlendMode.srcIn,
                ),
                width: 24.w,
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
                width: 100.w,
                height: 100.w,
                alignment: Alignment.center,
                child: Stack(
                  children: [
                    SizedBox(
                      width: 100.w,
                      height: 100.w,
                      child: ProfileImageContainer(
                        avatarUrl: userInfo.value?.avatarUrl,
                        borderRadius: 50.w,
                        width: 100.w,
                        height: 100.w,
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: GestureDetector(
                        onTap: () => _uploadProfileImage(),
                        child: Container(
                            width: 24.w,
                            height: 24,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: AppColors.primary500,
                              borderRadius: BorderRadius.circular(50.w),
                            ),
                            child: SvgPicture.asset(
                                package: 'picnic_lib',
                                'assets/icons/camera_style=line.svg',
                                width: 16.w,
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
      return AppLocalizations.of(context).nickname_validation_error;
    }
    return null;
  }
}

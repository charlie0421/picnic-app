import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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
import 'package:picnic_lib/core/services/profile_image_diagnostics.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/snackbar_util.dart';
import 'package:picnic_lib/core/utils/util.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/common/avatar_container.dart';
import 'package:picnic_lib/presentation/common/picnic_image_request.dart';
import 'package:picnic_lib/presentation/common/navigator_key.dart';
import 'package:picnic_lib/presentation/common/picnic_list_item.dart';
import 'package:picnic_lib/presentation/dialogs/simple_dialog.dart';
import 'package:picnic_lib/presentation/pages/my_page/privacy_page.dart';
import 'package:picnic_lib/presentation/pages/my_page/terms_page.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';
import 'package:picnic_lib/presentation/widgets/ui/pulse_loading_indicator.dart';
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
                tailing: Icon(
                  Icons.copy,
                  color: AppColors.primary500,
                  size: 16.w,
                ),
                assetPath: 'assets/icons/arrow_right_style=line.svg',
                onTap: () => copyToClipboard(
                  context,
                  supabase.auth.currentUser?.id ?? '',
                ),
              ),
            PicnicListItem(
              leading: AppLocalizations.of(context).label_mypage_terms_of_use,
              assetPath: 'assets/icons/arrow_right_style=line.svg',
              onTap: () {
                ref
                    .read(navigationInfoProvider.notifier)
                    .setCurrentMyPage(const TermsPage());
              },
            ),
            PicnicListItem(
              leading: AppLocalizations.of(context).label_mypage_privacy_policy,
              assetPath: 'assets/icons/arrow_right_style=line.svg',
              onTap: () {
                ref
                    .read(navigationInfoProvider.notifier)
                    .setCurrentMyPage(const PrivacyPage());
              },
            ),
            PicnicListItem(
              leading: AppLocalizations.of(context).label_mypage_logout,
              assetPath: 'assets/icons/arrow_right_style=line.svg',
              onTap: () {
                ref.read(userInfoProvider.notifier).logout();
                ref.read(navigationInfoProvider.notifier).setResetStackMyPage();
                Navigator.of(context).pop();
              },
            ),
            PicnicListItem(
              leading: AppLocalizations.of(context).label_mypage_withdrawal,
              assetPath: 'assets/icons/arrow_right_style=line.svg',
              onTap: () => _showWithdrawalModal(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // 진행 중인 사진 변경은 여기서 소유권을 잃는다. 늦게 끝나는 단계는
    // [_ownsImageOperation] 에서 멈추고, 로딩 오버레이는 지금 내린다.
    _imageOperation?.hideLoading();
    _imageOperation = null;
    unawaited(_authEvents?.cancel());
    _authEvents = null;
    _authEventsClient = null;
    super.dispose();
  }

  /// 진행 중인 프로필 사진 변경. 페이지 인스턴스당 하나만 진행한다.
  _ProfileImageOperation? _imageOperation;

  /// [_authEventsClient] 의 계정 전환 구독. 페이지당 하나이고 dispose 에서
  /// 해제한다. 작업마다 구독하지 않는다.
  StreamSubscription<AuthState>? _authEvents;
  SupabaseClient? _authEventsClient;

  /// [_authEventsClient] 에서 관측한 계정 전환 횟수. 사용자 ID 가 바뀔 때만
  /// 센다. 같은 계정의 토큰 갱신은 전환이 아니다.
  int _authTransitions = 0;

  /// 카메라 버튼 콜백. 작업을 시작만 하고 기다리지 않는다.
  void _onProfileImagePressed() {
    // 이미 진행 중이면 무시한다. 연속 탭이 picker 를 두 번 열지 않는다.
    if (_imageOperation != null) return;

    // 첫 await 전에 소유자를 잡는다. 로그인 전이면 저장 경로의 소유자가
    // 없으므로 picker 를 열지 않는다.
    final client = _currentAuthClient();
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) return;

    _watchAccountTransitions(client);
    final operation = _ProfileImageOperation(
      client: client,
      userId: userId,
      session: client.auth.currentSession,
      transitions: _authTransitions,
      overlay: Overlay.maybeOf(context),
    );
    _imageOperation = operation;
    // 처리한 실패는 _changeProfileImage 안에서 끝난다. 여기로 나오는 오류는
    // 예상하지 못한 결함이므로 삼키지 않고 zone 의 오류 보고로 보낸다.
    unawaited(
      _changeProfileImage(
        operation,
      ).whenComplete(() => _finishImageOperation(operation)),
    );
  }

  /// 각 단계는 그 단계가 예상하는 외부 실패만 처리하고 한 번 보고한다. 그
  /// 밖의 오류는 결함이므로 스택과 함께 다시 던진다. 가드와 오버레이는
  /// [_finishImageOperation] 이 정리한다.
  Future<void> _changeProfileImage(_ProfileImageOperation operation) async {
    final XFile? picked;
    try {
      picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    } catch (e, s) {
      if (!_isExpected(ProfileImagePhase.pick, e)) rethrow;
      return _failImageOperation(operation, ProfileImagePhase.pick, e, s);
    }
    // null 은 사용자 취소다. 실패가 아니므로 보고하지 않는다.
    if (picked == null) return;
    do {
      if (!await _confirmImageOwner(operation)) return;
    } while (!_holdsImageOwner(operation));

    final CroppedFile? cropped;
    try {
      cropped = await ImageCropper().cropImage(
        sourcePath: picked.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: '',
            toolbarColor: AppColors.primary500,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
          IOSUiSettings(title: ''),
        ],
      );
    } catch (e, s) {
      if (!_isExpected(ProfileImagePhase.crop, e)) rethrow;
      return _failImageOperation(operation, ProfileImagePhase.crop, e, s);
    }
    if (cropped == null) return;
    do {
      if (!await _confirmImageOwner(operation)) return;
    } while (!_holdsImageOwner(operation));

    operation.showLoading();

    final Uint8List fileBytes;
    try {
      fileBytes = await cropped.readAsBytes();
    } catch (e, s) {
      if (!_isExpected(ProfileImagePhase.read, e)) rethrow;
      return _failImageOperation(operation, ProfileImagePhase.read, e, s);
    }
    do {
      if (!await _confirmImageOwner(operation)) return;
    } while (!_holdsImageOwner(operation));

    // 경로의 소유자는 버튼을 누른 계정이다. 업로드는 그 계정의 클라이언트로
    // 보낸다. 바로 위에서 그 계정이 아직 현재 계정임을 확인했다.
    final fileName =
        '${operation.userId}/avatar_${DateTime.now().millisecondsSinceEpoch}'
        '${path.extension(cropped.path)}';
    final avatars = operation.client.storage.from('avatars');
    final String storageKey;
    try {
      storageKey = await avatars.uploadBinary(
        fileName,
        fileBytes,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
      );
    } catch (e, s) {
      if (!_isExpected(ProfileImagePhase.upload, e)) rethrow;
      return _failImageOperation(operation, ProfileImagePhase.upload, e, s);
    }
    if (storageKey.isEmpty) {
      return _failImageOperation(
        operation,
        ProfileImagePhase.upload,
        const ProfileImageEmptyStorageKey(),
        StackTrace.current,
      );
    }
    // 이미 보낸 업로드는 되돌리지 않는다. 소유자가 바뀌었으면 이후 단계만
    // 멈춘다.
    do {
      if (!await _confirmImageOwner(operation)) return;
    } while (!_holdsImageOwner(operation));

    try {
      await ref
          .read(userInfoProvider.notifier)
          .updateAvatar(avatars.getPublicUrl(fileName));
    } catch (e, s) {
      if (!_isExpected(ProfileImagePhase.update, e)) rethrow;
      return _failImageOperation(operation, ProfileImagePhase.update, e, s);
    }
    do {
      if (!await _confirmImageOwner(operation)) return;
    } while (!_holdsImageOwner(operation));

    operation.hideLoading();
    final messageContext = navigatorKey.currentContext;
    if (messageContext != null && messageContext.mounted) {
      SnackbarUtil().info(AppLocalizations.of(messageContext).common_success);
    }
  }

  static bool _isExpected(ProfileImagePhase phase, Object error) =>
      ProfileImageDiagnostics.isExpectedFailure(phase, error);

  void _finishImageOperation(_ProfileImageOperation operation) {
    operation.hideLoading();
    if (identical(_imageOperation, operation)) _imageOperation = null;
  }

  /// 처리한 실패. 같은 계정이면 한 번 보고하고, 화면이 그 작업의 것이면
  /// 오류를 알린다.
  void _failImageOperation(
    _ProfileImageOperation operation,
    ProfileImagePhase phase,
    Object error,
    StackTrace stackTrace,
  ) {
    logger.w('Profile image ${phase.name} failed: ${error.runtimeType}');

    // 계정이 바뀐 뒤의 실패는 그 전환 때문일 수 있고, 지금 Sentry 범위는 다른
    // 계정의 것이다. 이 경우에는 보고하지 않는다. 원본 예외는 보내지 않는다.
    // 메시지에 기기 경로, 저장 경로(계정 ID), 서버 응답 본문이 들어 있을 수
    // 있다.
    if (_isImageAccountCurrent(operation)) {
      ProfileImageDiagnostics.report(phase, error, stackTrace);
    }

    if (!_ownsImageOperation(operation)) return;
    operation.hideLoading();
    final messageContext = navigatorKey.currentContext;
    if (messageContext != null && messageContext.mounted) {
      SnackbarUtil().error(AppLocalizations.of(messageContext).common_fail);
    }
  }

  /// 현재 Supabase 클라이언트. 초기화되지 않았으면 null.
  SupabaseClient? _currentAuthClient() {
    try {
      return supabase;
    } on StateError {
      return null;
    }
  }

  /// [client] 의 계정 전환을 센다. 이미 그 클라이언트를 관측 중이면 그대로 둔다.
  void _watchAccountTransitions(SupabaseClient client) {
    if (identical(_authEventsClient, client)) return;
    unawaited(_authEvents?.cancel());
    _authEventsClient = client;
    var current = client.auth.currentUser?.id;
    _authEvents = client.auth.onAuthStateChange.listen(
      (state) {
        final next = state.session?.user.id;
        if (next == current) return;
        current = next;
        _authTransitions++;
        // 진행 중인 작업은 더 이상 이 계정의 것이 아니다. 요청이 끝나기를
        // 기다리지 않고 로딩을 내린다. 이후 단계는 소유권 확인에서 멈춘다.
        _imageOperation?.hideLoading();
      },
      // 인증 오류에는 세션 정보가 담길 수 있다. 기록하지 않는다.
      onError: (Object _, StackTrace _) {},
    );
  }

  /// [operation] 을 시작한 계정이, 같은 클라이언트에서, 관측된 전환 없이
  /// 아직 로그인해 있는지. 화면 수명과는 별개다.
  bool _isImageAccountCurrent(_ProfileImageOperation operation) {
    final client = _currentAuthClient();
    return identical(client, operation.client) &&
        identical(_authEventsClient, operation.client) &&
        _authTransitions == operation.transitions &&
        client?.auth.currentUser?.id == operation.userId;
  }

  /// 이 화면이 살아 있고 [operation] 이 아직 이 화면의 작업이며 같은 계정인지.
  bool _ownsImageOperation(_ProfileImageOperation operation) =>
      mounted &&
      identical(_imageOperation, operation) &&
      _isImageAccountCurrent(operation);

  /// [_confirmImageOwner] 를 기다린 뒤, 같은 턴에서 다음 단계 바로 전에 본다.
  ///
  /// 확인 결과를 받는 await 도 microtask 한 번을 거친다. 그 사이 세션이
  /// 바뀌었거나 소유권을 잃었으면 false 다. 호출자는 다시 확인한다. 세션이
  /// 바뀐 경우에는 그 확인이 아직 전달되지 않은 전환을 받아 낸다.
  bool _holdsImageOwner(_ProfileImageOperation operation) =>
      _ownsImageOperation(operation) &&
      identical(operation.client.auth.currentSession, operation.session);

  /// await 뒤, 다음 단계 전에 부른다. 결과를 기다린 뒤에는
  /// [_holdsImageOwner] 로 다시 본다.
  ///
  /// 세션 인스턴스만 바뀌었으면 같은 계정의 토큰 갱신일 수도, 이벤트가 아직
  /// 전달되지 않은 계정 전환(A → B → A 포함)일 수도 있다. gotrue 는 세션을
  /// 바꾸는 턴에 이벤트를 microtask 로 예약하므로, 한 프레임 뒤 다시 확인한다.
  /// 그 사이 세션이 그대로면 같은 계정의 새 세션으로 받아들인다.
  Future<bool> _confirmImageOwner(_ProfileImageOperation operation) async {
    while (true) {
      if (!_ownsImageOperation(operation)) return false;
      final session = operation.client.auth.currentSession;
      if (identical(session, operation.session)) return true;
      await SchedulerBinding.instance.endOfFrame;
      if (!_ownsImageOperation(operation)) return false;
      if (identical(operation.client.auth.currentSession, session)) {
        operation.session = session;
        return true;
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
    String formattedDate = DateFormat.yMMMMd(
      locale,
    ).add_jm().format(futureDate);

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
      isScrollControlled: true,
      useSafeArea: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(48),
          topRight: const Radius.circular(48),
        ),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setModalState) {
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
                  content: AppLocalizations.of(dialogContext).withdrawal_failed,
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
            child: SingleChildScrollView(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 40.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppLocalizations.of(sheetContext).dialog_withdraw_title,
                      style: getTextStyle(AppTypo.title18SB, AppColors.grey900),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      AppLocalizations.of(
                        sheetContext,
                      ).dialog_will_delete_star_candy,
                      style: getTextStyle(AppTypo.body14B, AppColors.grey900),
                    ),
                    const StarCandyInfoText(),
                    const SizedBox(height: 24),
                    Text(
                      AppLocalizations.of(sheetContext).dialog_withdraw_message,
                      style: getTextStyle(
                        AppTypo.caption12R,
                        AppColors.grey700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      AppLocalizations.of(
                        sheetContext,
                      ).dialog_message_can_resignup,
                      style: getTextStyle(
                        AppTypo.caption12R,
                        AppColors.grey700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      formattedDate,
                      style: getTextStyle(
                        AppTypo.caption12B,
                        AppColors.grey700,
                      ),
                      textAlign: TextAlign.center,
                    ),
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
                                horizontal: 20.w,
                                vertical: 8,
                              ),
                              constraints: BoxConstraints(minWidth: 100.w),
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
                                      child: SmallPulseLoadingIndicator(),
                                    )
                                  : Text(
                                      AppLocalizations.of(
                                        sheetContext,
                                      ).dialog_withdraw_button_ok,
                                      style: getTextStyle(
                                        AppTypo.title18SB,
                                        AppColors.grey00,
                                      ),
                                    ),
                            ),
                          ),
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
                                horizontal: 20.w,
                                vertical: 8,
                              ),
                              constraints: BoxConstraints(minWidth: 100.w),
                              decoration: BoxDecoration(
                                color: AppColors.grey00,
                                borderRadius: BorderRadius.circular(30.w),
                                border: Border.all(
                                  color: isWithdrawing
                                      ? AppColors.grey300
                                      : AppColors.primary500,
                                  width: 1.5.w,
                                ),
                              ),
                              child: Text(
                                AppLocalizations.of(
                                  sheetContext,
                                ).dialog_button_cancel,
                                style: getTextStyle(
                                  AppTypo.title18SB,
                                  isWithdrawing
                                      ? AppColors.grey300
                                      : AppColors.primary500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
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
        body: jsonEncode(<String, String>{'userId': user.id}),
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
            content: AppLocalizations.of(
              navigatorKey.currentContext!,
            ).withdrawal_success,
          );
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
      // A minimum, not a fixed height (PICNIC-2738). The sentence is two lines
      // in English at 1.0x and a fixed 32 clipped it from 1.3x in every
      // language but Korean. The empty slot still reserves 32 so the page
      // does not jump when the message appears.
      constraints: const BoxConstraints(minHeight: 32),
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
    final canSave =
        isValid &&
        _textEditingController.text !=
            ref.watch(userInfoProvider).value?.nickname;
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
              width: 1.5.w,
            ),
          ),
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          alignment: Alignment.center,
          // Reserve the clear control's 48px plus the container borders
          // before focus. Larger text can still grow the pill.
          constraints: BoxConstraints(minHeight: 48 + 2 * 1.5.w),
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
                // Dense padding keeps the text inside the bordered pill.
                // The parent reserves the clear control space before focus.
                isDense: true,
                contentPadding: EdgeInsets.fromLTRB(0, 12, 0, 12 - 2 * 1.5.w),
                // Shrunk to fit rather than cut: the field is 141px wide on
                // a 393dp screen and even Korean needs 146, so hintText
                // showed "닉네임을 입력해주세…" in every language.
                hint: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    AppLocalizations.of(context).hint_nickname_input,
                    style: getTextStyle(AppTypo.body14B, AppColors.grey300),
                    maxLines: 1,
                  ),
                ),
                border: InputBorder.none,
                fillColor: AppColors.grey900,
                focusColor: AppColors.primary500,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                suffixIconConstraints: const BoxConstraints(
                  minWidth: 48,
                  minHeight: 48,
                ),
                suffixIcon: _focusNode.hasFocus
                    ? IconButton(
                        tooltip: MaterialLocalizations.of(
                          context,
                        ).deleteButtonTooltip,
                        constraints: const BoxConstraints(
                          minWidth: 48,
                          minHeight: 48,
                        ),
                        onPressed: () {
                          _textEditingController.clear();
                          setState(() {
                            isValid =
                                validateInput(_textEditingController.text) ==
                                null;
                          });
                        },
                        icon: SvgPicture.asset(
                          'assets/icons/cancel_style=fill.svg',
                          package: 'picnic_lib',
                          width: 20.w,
                          height: 20,
                          colorFilter: ColorFilter.mode(
                            _textEditingController.text.isEmpty
                                ? AppColors.grey300
                                : AppColors.grey700,
                            BlendMode.srcIn,
                          ),
                        ),
                      )
                    : null,
              ),
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(left: 8.w),
          child: IconButton(
            tooltip: AppLocalizations.of(context).save,
            onPressed: canSave
                ? () async {
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
                                  content: AppLocalizations.of(
                                    navigatorKey.currentContext!,
                                  ).message_update_nickname_success,
                                );
                              }
                            } else {
                              // 닉네임 변경 실패 (중복 또는 오류)
                              if (navigatorKey.currentContext != null) {
                                showSimpleDialog(
                                  content: AppLocalizations.of(
                                    navigatorKey.currentContext!,
                                  ).message_update_nickname_fail,
                                );
                              }
                            }
                            OverlayLoadingProgress.stop();
                          });
                    }
                  }
                : null,
            style: IconButton.styleFrom(
              minimumSize: Size(48.w.clamp(48, double.infinity), 48),
              backgroundColor: AppColors.primary500,
              disabledBackgroundColor: AppColors.grey300,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24.w),
              ),
            ),
            icon: SvgPicture.asset(
              'assets/icons/pencil_style=fill.svg',
              package: 'picnic_lib',
              colorFilter: const ColorFilter.mode(
                AppColors.grey900,
                BlendMode.srcIn,
              ),
              width: 24.w,
              height: 24,
            ),
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
                      cdnVariant: PicnicCdnImageVariant.thumbnail,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: IconButton(
                      tooltip: AppLocalizations.of(
                        context,
                      ).profile_photo_change,
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                      padding: EdgeInsets.zero,
                      alignment: Alignment.bottomRight,
                      onPressed: _onProfileImagePressed,
                      icon: Container(
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
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : Container(),
      loading: () => Container(),
      error: (error, stackTrace) => Container(),
    );
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

/// 프로필 사진 변경 한 번. 버튼을 누른 순간의 계정과 클라이언트를 갖는다.
final class _ProfileImageOperation {
  _ProfileImageOperation({
    required this.client,
    required this.userId,
    required this.session,
    required this.transitions,
    required OverlayState? overlay,
  }) : _overlay = overlay;

  final SupabaseClient client;
  final String userId;

  /// 비교에만 쓴다. 세션 내용은 읽거나 기록하지 않는다.
  Session? session;

  /// 시작할 때까지 관측한 계정 전환 횟수.
  final int transitions;

  final OverlayState? _overlay;
  OverlayEntry? _loading;

  /// 이 작업의 로딩 오버레이. 전역 OverlayLoadingProgress 를 쓰지 않는다 -
  /// 그것을 내리면 다른 기능이 띄운 오버레이까지 내려간다.
  void showLoading() {
    final overlay = _overlay;
    if (_loading != null || overlay == null || !overlay.mounted) return;
    final entry = OverlayEntry(builder: (_) => const _ProfileImageLoading());
    _loading = entry;
    overlay.insert(entry);
  }

  /// 이 작업이 띄운 오버레이만 내린다. 여러 번 불러도 된다.
  void hideLoading() {
    final entry = _loading;
    if (entry == null) return;
    _loading = null;
    entry.remove();
    entry.dispose();
  }
}

class _ProfileImageLoading extends StatelessWidget {
  const _ProfileImageLoading();

  @override
  Widget build(BuildContext context) => const Stack(
    children: [
      ModalBarrier(dismissible: false, color: Colors.black54),
      Center(child: CircularProgressIndicator(strokeWidth: 3)),
    ],
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:picnic_app/components/common/picnic_list_item.dart';
import 'package:picnic_app/components/picnic_cached_network_image.dart';
import 'package:picnic_app/components/ui/large_popup.dart';
import 'package:picnic_app/components/vote/common_vote_info.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/models/user_profiles.dart';
import 'package:picnic_app/pages/mypage/privacy_page.dart';
import 'package:picnic_app/pages/mypage/terms_page.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/providers/user_info_provider.dart';
import 'package:picnic_app/ui/style.dart';

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
      logger.d('addListener');
      setState(() {
        isValid = validateInput(_textEditingController.text) == null;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final userInfo = ref.watch(userInfoProvider);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: ListView(
        children: [
          SizedBox(height: 24.w),
          buildProfileImage(userInfo),
          SizedBox(height: 24.w),
          buildNicknameInput(context),
          SizedBox(height: 4.w),
          buildValidationMsg(context),
          SizedBox(height: 26.w),
          Divider(
            color: AppColors.Grey300,
            thickness: 1,
            height: 24.w,
          ),
          ListItem(
              leading: S.of(context).label_mypage_terms_of_use,
              assetPath: 'assets/icons/arrow_right_style=line.svg',
              onTap: () {
                ref
                    .read(navigationInfoProvider.notifier)
                    .setCurrentMyPage(const TermsPage());
              }),
          Divider(
            color: AppColors.Grey300,
            thickness: 1,
            height: 24.w,
          ),
          ListItem(
              leading: S.of(context).label_mypage_privacy_policy,
              assetPath: 'assets/icons/arrow_right_style=line.svg',
              onTap: () {
                ref
                    .read(navigationInfoProvider.notifier)
                    .setCurrentMyPage(const PrivacyPage());
              }),
          Divider(
            color: AppColors.Grey300,
            thickness: 1,
            height: 24.w,
          ),
          ListItem(
              leading: S.of(context).label_mypage_logout,
              assetPath: 'assets/icons/arrow_right_style=line.svg',
              onTap: () {
                ref.read(userInfoProvider.notifier).logout();
                Navigator.of(context).pop();
              }),
          Divider(
            color: AppColors.Grey300,
            thickness: 1,
            height: 24.w,
          ),
          ListItem(
              leading: S.of(context).label_mypage_withdrawal,
              assetPath: 'assets/icons/arrow_right_style=line.svg',
              onTap: () => showDialog(
                  context: context,
                  builder: (context) => LargePopupWidget(
                        width: MediaQuery.of(context).size.width - 32.w,
                        content: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 40.w, vertical: 64.w),
                          child: Column(children: [
                            Text(
                              S.of(context).dialog_withdraw_title,
                              style: getTextStyle(
                                  AppTypo.TITLE18SB, AppColors.Grey900),
                            ),
                            SizedBox(height: 32.w),
                            StorePointInfo(
                                title: S.of(context).label_star_candy_pouch,
                                width: 231.w,
                                titlePadding: 10.w,
                                height: 78.w),
                            SizedBox(height: 44.w),
                            SizedBox(
                              width: 216.w,
                              child: Text(
                                S.of(context).dialog_withdraw_message,
                                style: getTextStyle(
                                    AppTypo.CAPTION12R, AppColors.Grey700),
                              ),
                            ),
                            SizedBox(height: 32.w),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: MaterialButton(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 20.w),
                                      color: AppColors.Grey00,
                                      shape: RoundedRectangleBorder(
                                          side: BorderSide(
                                              color: AppColors.Primary500,
                                              width: 1.5.w),
                                          borderRadius:
                                              BorderRadius.circular(20.w)),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: Text(
                                          S
                                              .of(context)
                                              .dialog_withdraw_button_ok,
                                          style: getTextStyle(AppTypo.BODY14B,
                                              AppColors.Primary500))),
                                ),
                                SizedBox(width: 10.w),
                                Expanded(
                                  flex: 2,
                                  child: MaterialButton(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 20.w),
                                      color: AppColors.Primary500,
                                      shape: RoundedRectangleBorder(
                                          side: BorderSide(
                                              color: AppColors.Primary500,
                                              width: 1.5.w),
                                          borderRadius:
                                              BorderRadius.circular(20.w)),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: Text(
                                          S
                                              .of(context)
                                              .dialog_withdraw_button_cancel,
                                          style: getTextStyle(AppTypo.BODY14B,
                                              AppColors.Grey00))),
                                ),
                              ],
                            )
                          ]),
                        ),
                      ))),
          Divider(
            color: AppColors.Grey300,
            thickness: 1,
            height: 24.w,
          ),
        ],
      ),
    );
  }

  Container buildValidationMsg(BuildContext context) {
    return Container(
      height: 32.w,
      alignment: Alignment.topLeft,
      padding: EdgeInsets.only(left: 16.w),
      margin: EdgeInsets.symmetric(horizontal: 57.w),
      child: isValid == false
          ? Text(
              S.of(context).nickname_validation_error,
              style: getTextStyle(AppTypo.CAPTION10SB, AppColors.StatusError),
            )
          : null,
    );
  }

  Container buildNicknameInput(BuildContext context) {
    return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24.w),
          border: Border.all(
              color: isValid ? AppColors.Primary500 : AppColors.StatusError,
              strokeAlign: BorderSide.strokeAlignInside,
              width: 1.5.w),
        ),
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        margin: EdgeInsets.symmetric(horizontal: 57.w),
        alignment: Alignment.center,
        height: 48.w,
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
            cursorColor: AppColors.Primary500,
            focusNode: _focusNode,
            cursorHeight: 16.w,
            keyboardType: TextInputType.text,
            style: getTextStyle(AppTypo.BODY16B, AppColors.Grey900),
            decoration: InputDecoration(
              hintText: S.of(context).hint_nickname_input,
              hintStyle: getTextStyle(AppTypo.BODY14B, AppColors.Grey300),
              border: InputBorder.none,
              fillColor: AppColors.Grey900,
              focusColor: AppColors.Primary500,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              suffixIconConstraints: BoxConstraints(
                minWidth: 20.w,
                minHeight: 20.w,
              ),
              suffixIcon: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  _textEditingController.clear();
                },
                child: _textEditingController.text ==
                        ref.watch(userInfoProvider).value?.nickname
                    ? SvgPicture.asset('assets/icons/pencil_style=fill.svg',
                        colorFilter: const ColorFilter.mode(
                          AppColors.Grey700,
                          BlendMode.srcIn,
                        ))
                    : _textEditingController.text.isEmpty
                        ? SvgPicture.asset(
                            'assets/icons/cancle_style=fill.svg',
                            colorFilter: const ColorFilter.mode(
                              AppColors.Grey300,
                              BlendMode.srcIn,
                            ),
                            width: 20.w,
                            height: 20.w,
                          )
                        : GestureDetector(
                            onTap: () {
                              _textEditingController.clear();
                            },
                            child: SvgPicture.asset(
                              'assets/icons/cancle_style=fill.svg',
                              colorFilter: const ColorFilter.mode(
                                AppColors.Grey700,
                                BlendMode.srcIn,
                              ),
                              width: 20.w,
                              height: 20.w,
                            ),
                          ),
              ),
            ),
            onFieldSubmitted: (value) {
              logger.d('onFieldSubmitted');
              _focusNode.unfocus();
              if (isValid) {
                ref
                    .read(userInfoProvider.notifier)
                    .updateNickname(_textEditingController.text);
              }
            },
          ),
        ));
  }

  Container buildProfileImage(AsyncValue<UserProfilesModel?> userInfo) {
    return Container(
      width: 100.w,
      height: 100.w,
      alignment: Alignment.center,
      child: Stack(
        children: [
          SizedBox(
            width: 100.w,
            height: 100.w,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(50.w),
              clipBehavior: Clip.hardEdge,
              child: PicnicCachedNetworkImage(
                Key: userInfo.value?.avatar_url ?? '',
                fit: BoxFit.cover,
                width: 100.w,
                height: 100.w,
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
                width: 24.w,
                height: 24.w,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.Primary500,
                  borderRadius: BorderRadius.circular(50.w),
                ),
                child: SvgPicture.asset('assets/icons/camera_style=line.svg',
                    width: 16.w,
                    height: 16.w,
                    colorFilter: const ColorFilter.mode(
                      AppColors.Grey00,
                      BlendMode.srcIn,
                    ))),
          ),
        ],
      ),
    );
  }

  String? validateInput(String? value) {
    final regExp = RegExp(r'^[\w\s]+$');
    if (value == null ||
        value.isEmpty ||
        value.length > 20 ||
        !regExp.hasMatch(value)) {
      return S.of(context).nickname_validation_error;
    }
    return null;
  }
}

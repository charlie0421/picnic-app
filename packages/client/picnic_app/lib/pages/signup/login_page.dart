import 'package:bubble_box/bubble_box.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:overlay_loading_progress/overlay_loading_progress.dart';
import 'package:picnic_app/app.dart';
import 'package:picnic_app/components/common/custom_pagination.dart';
import 'package:picnic_app/config/environment.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/dialogs/simple_dialog.dart';
import 'package:picnic_app/exceptions/auth_exception.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/pages/signup/agreement_terms_page.dart';
import 'package:picnic_app/providers/app_setting_provider.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/providers/user_info_provider.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:picnic_app/ui/common_gradient.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util/auth_service.dart';
import 'package:picnic_app/util/logger.dart';
import 'package:picnic_app/util/ui.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:universal_platform/universal_platform.dart';

class LoginPage extends ConsumerStatefulWidget {
  static const String routeName = '/login';

  const LoginPage({super.key});

  @override
  createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginPage> {
  final AuthService _authService = AuthService();

  String? lastProvider;

  @override
  void initState() {
    super.initState();
    const storage = FlutterSecureStorage();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      lastProvider = await storage.read(key: 'last_provider');
      logger.i(lastProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: commonGradient),
      child: Center(
        child: Container(
          color: voteMainColor,
          constraints: BoxConstraints(
            maxWidth: UniversalPlatform.isWeb
                ? Constants.webWidth
                : getPlatformScreenSize(context).width,
          ),
          child: Scaffold(
            body: SafeArea(
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                        },
                        child: SvgPicture.asset(
                          'assets/icons/arrow_left_style=line.svg',
                          width: 24.cw,
                          height: 24,
                          colorFilter: const ColorFilter.mode(
                              AppColors.grey900, BlendMode.srcIn),
                        ),
                      ),
                    ),
                    Expanded(child: _buildSwiper()),
                    const SizedBox(height: 24),
                    _buildLanguageSelector(context, ref),
                    const SizedBox(height: 24),
                    _buildLoginButton(context, ref),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSwiper() {
    return Swiper(
      itemCount: 3,
      autoplay: true,
      pagination: SwiperPagination(
        builder: CustomPaginationBuilder(),
      ),
      itemBuilder: (BuildContext context, int index) {
        return Image.asset(
            'assets/images/login/${Intl.getCurrentLocale()}_${index + 1}.png');
      },
    );
  }

  Widget _buildLanguageSelector(BuildContext context, ref) {
    final appSettingState = ref.watch(appSettingProvider);
    final appSettingNotifier = ref.read(appSettingProvider.notifier);
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          useSafeArea: false,
          builder: (context) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: languageMap.entries.map((entry) {
                  return GestureDetector(
                    onTap: () {
                      if (appSettingState.locale.languageCode == entry.key) {
                        return;
                      }
                      appSettingNotifier.setLocale(
                          Locale(entry.key, countryMap[entry.key] ?? ''));
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      alignment: Alignment.center,
                      width: double.infinity,
                      height: 61,
                      child: Text(
                        entry.value,
                        style: getTextStyle(
                            AppTypo.body14B,
                            Intl.getCurrentLocale() == entry.key
                                ? AppColors.grey800
                                : AppColors.grey400),
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          },
        );
      },
      child: Container(
        height: 48,
        padding: EdgeInsets.symmetric(horizontal: 16.cw),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primary500, width: 1.5),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SvgPicture.asset(
              'assets/icons/global_style=line.svg',
              colorFilter:
                  const ColorFilter.mode(AppColors.primary500, BlendMode.srcIn),
              width: 20.cw,
              height: 20,
            ),
            SizedBox(width: 20.cw),
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  languageMap[appSettingState.locale.languageCode]!,
                  style: getTextStyle(AppTypo.body16M, AppColors.grey900),
                ),
              ),
            ),
            Transform.rotate(
              angle: 1.57,
              child: SvgPicture.asset(
                'assets/icons/play_style=fill.svg',
                colorFilter:
                    const ColorFilter.mode(AppColors.grey900, BlendMode.srcIn),
                width: 20.cw,
                height: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginButton(BuildContext context, WidgetRef ref) {
    return ElevatedButtonTheme(
      data: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(AppColors.primary500),
          foregroundColor: WidgetStateProperty.all(AppColors.grey00),
          textStyle: WidgetStateProperty.all(
              getTextStyle(AppTypo.title18SB, AppColors.grey00)),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
              side: const BorderSide(
                  color: AppColors.mint500,
                  width: 1,
                  strokeAlign: BorderSide.strokeAlignInside),
            ),
          ),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              useSafeArea: true,
              showDragHandle: true,
              builder: (context) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: _buildLoginOptions(context, ref),
                );
              },
            );
          },
          child: Text(S.of(context).button_login),
        ),
      ),
    );
  }

  Widget _buildLoginOptions(BuildContext context, WidgetRef ref) {
    return Container(
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (isIOS()) _buildAppleLogin(context),
          _buildGoogleLogin(
            context,
          ),
          _buildKakaoLogin(
            context,
          ),
        ],
      ),
    );
  }

  void _handleSuccessfulLogin() async {
    try {
      OverlayLoadingProgress.start(context,
          color: AppColors.primary500, barrierDismissible: false);

      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Failed to get current user');
      }

      final userProfile =
          await ref.read(userInfoProvider.notifier).getUserProfiles();

      OverlayLoadingProgress.stop();

      if (userProfile == null) {
        ref
            .read(navigationInfoProvider.notifier)
            .setCurrentSignUpPage(const AgreementTermsPage());
        Navigator.of(navigatorKey.currentContext!).pop();
      } else if (userProfile.deletedAt != null) {
        showSimpleDialog(
            content: Intl.message('error_message_withdrawal'),
            onOk: () {
              Navigator.of(context).pop();
            });
      } else if (userProfile.userAgreement == null) {
        ref
            .read(navigationInfoProvider.notifier)
            .setCurrentSignUpPage(const AgreementTermsPage());
        Navigator.of(navigatorKey.currentContext!).pop();
      } else {
        ref.read(navigationInfoProvider.notifier).setResetStackMyPage();
        Navigator.of(navigatorKey.currentContext!).pop();
        Navigator.of(navigatorKey.currentContext!).pop();
      }
    } catch (e, s) {
      OverlayLoadingProgress.stop();
      logger.e('error', error: e, stackTrace: s);
      showSimpleDialog(
          title: Intl.message('error_title'),
          content: Intl.message('error_message_login_failed'),
          onOk: () {
            Navigator.of(context).pop();
          });
      rethrow;
    }
  }

  Widget _buildAppleLogin(BuildContext context) {
    ref.watch(userInfoProvider);

    return Stack(
      children: [
        Container(
          width: 240,
          height: 44,
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: SignInWithAppleButton(
            height: 44,
            onPressed: () async {
              try {
                OverlayLoadingProgress.start(context,
                    color: AppColors.primary500, barrierDismissible: false);
                final user =
                    await _authService.signInWithProvider(OAuthProvider.apple);
                OverlayLoadingProgress.stop();

                if (user != null) {
                  _handleSuccessfulLogin();
                }
              } on PicnicAuthException catch (e) {
                OverlayLoadingProgress.stop();
                logger.e(
                    'Apple login PicnicAuthException: $e (originalError: ${e.originalError})');

                if (e.code == 'canceled') {
                  return;
                }

                showSimpleDialog(
                    type: DialogType.error,
                    title: Intl.message('error_title'),
                    content: e.message,
                    onOk: () {
                      Navigator.of(context).pop();
                    });
              } catch (e, s) {
                OverlayLoadingProgress.stop();
                logger.e('Error signing in with Apple: $e', stackTrace: s);

                showSimpleDialog(
                    type: DialogType.error,
                    title: Intl.message('error_title'),
                    content: Intl.message('error_message_login_failed'),
                    onOk: () {
                      Navigator.of(context).pop();
                    });
                rethrow;
              }
            },
            style: SignInWithAppleButtonStyle.black,
          ),
        ),
        if (lastProvider == 'apple') LastProvider()
      ],
    );
  }

  Widget _buildGoogleLogin(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: () async {
            try {
              OverlayLoadingProgress.start(context,
                  color: AppColors.primary500, barrierDismissible: false);

              if (kIsWeb) {
                await supabase.auth.signInWithOAuth(
                  OAuthProvider.google,
                  redirectTo: '${Environment.webDomain}/auth/callback',
                  scopes: 'email profile',
                );
              } else {
                final user =
                    await _authService.signInWithProvider(OAuthProvider.google);
                OverlayLoadingProgress.stop();
                if (user != null) {
                  _handleSuccessfulLogin();
                } else {
                  throw PicnicAuthExceptions.unknown();
                }
              }
            } on PicnicAuthException catch (e) {
              OverlayLoadingProgress.stop();
              logger.e(
                  'Google login PicnicAuthException: $e (originalError: ${e.originalError})');

              if (e.code == 'canceled') {
                return;
              }

              showSimpleDialog(
                  type: DialogType.error,
                  title: Intl.message('error_title'),
                  content: e.message,
                  onOk: () {
                    Navigator.of(context).pop();
                  });
            } catch (e, s) {
              OverlayLoadingProgress.stop();
              logger.e('Error signing in with Google: $e', stackTrace: s);

              showSimpleDialog(
                  type: DialogType.error,
                  title: Intl.message('error_title'),
                  content: Intl.message('error_message_login_failed'),
                  onOk: () {
                    Navigator.of(context).pop();
                  });
              rethrow;
            }
          },
          child: Center(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.grey400, width: 1),
                borderRadius: BorderRadius.circular(12),
              ),
              width: 240,
              height: 44,
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset('assets/icons/login/google.png',
                      width: 20.cw, height: 20),
                  SizedBox(width: 8.cw),
                  Text('Sign in with Google',
                      style: getTextStyle(AppTypo.body14M, AppColors.grey800)),
                ],
              ),
            ),
          ),
        ),
        if (lastProvider == 'google') LastProvider()
      ],
    );
  }

  Widget _buildKakaoLogin(BuildContext context) {
    ref.watch(userInfoProvider);
    return LayoutBuilder(builder: (context, constraints) {
      return Stack(children: [
        GestureDetector(
          onTap: () async {
            try {
              OverlayLoadingProgress.start(context,
                  color: AppColors.primary500, barrierDismissible: false);
              if (kIsWeb) {
                await supabase.auth.signInWithOAuth(
                  OAuthProvider.kakao,
                  redirectTo: '${Environment.webDomain}/auth/callback',
                  scopes: 'account_email profile_image profile_nickname',
                );
              } else {
                final user =
                    await _authService.signInWithProvider(OAuthProvider.kakao);
                OverlayLoadingProgress.stop();
                if (user != null) {
                  _handleSuccessfulLogin();
                }
              }
            } on PicnicAuthException catch (e) {
              OverlayLoadingProgress.stop();
              logger.e(
                  'Kakao login PicnicAuthException: $e (originalError: ${e.originalError})');

              if (e.code == 'canceled') {
                return;
              }

              showSimpleDialog(
                  type: DialogType.error,
                  title: Intl.message('error_title'),
                  content: e.message,
                  onOk: () {
                    Navigator.of(context).pop();
                  });
            } catch (e, s) {
              OverlayLoadingProgress.stop();
              logger.e('Error signing in with Kakao: $e', stackTrace: s);

              showSimpleDialog(
                  type: DialogType.error,
                  title: Intl.message('error_title'),
                  content: Intl.message('error_message_login_failed'),
                  onOk: () {
                    Navigator.of(context).pop();
                  });
              rethrow;
            }
          },
          child: Center(
            child: Container(
              width: 240,
              height: 44,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.grey400, width: 1),
                borderRadius: BorderRadius.circular(12),
                color: Colors.yellow,
              ),
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset('assets/icons/login/kakao.png',
                      width: 20.cw, height: 20),
                  SizedBox(width: 8.cw),
                  Text('Login with Kakao',
                      style: getTextStyle(AppTypo.body14M, AppColors.grey800)),
                ],
              ),
            ),
          ),
        ),
        if (lastProvider == 'kakao') LastProvider(),
      ]);
    });
  }
}

class LastProvider extends StatelessWidget {
  const LastProvider({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 10,
      bottom: 10,
      left: 10.cw,
      child: BubbleBox(
        shape: BubbleShapeBorder(
          border: BubbleBoxBorder(
            color: AppColors.primary500,
            width: 1.5,
            style: BubbleBoxBorderStyle.dashed,
          ),
          position: const BubblePosition.center(0),
          direction: BubbleDirection.right,
        ),
        backgroundColor: AppColors.mint500,
        child: Center(
          child: Text(
            S.of(context).label_last_provider,
            style: getTextStyle(AppTypo.caption10SB, AppColors.primary500),
          ),
        ),
      ),
    );
  }
}

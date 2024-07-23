import 'dart:convert';

import 'package:bubble/bubble.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:overlay_loading_progress/overlay_loading_progress.dart';
import 'package:picnic_app/auth_service.dart';
import 'package:picnic_app/components/common/custom_pagination.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/dialogs/simple_dialog.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/pages/signup/agreement_terms_page.dart';
import 'package:picnic_app/providers/app_setting_provider.dart';
import 'package:picnic_app/providers/navigation_provider.dart';
import 'package:picnic_app/providers/user_info_provider.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:picnic_app/ui/common_gradient.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:picnic_app/util.dart';
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
  initState() {
    const storage = FlutterSecureStorage();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      lastProvider = await storage.read(key: 'last_provider');
      logger.i(lastProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final navigationInfoNotifier = ref.read(navigationInfoProvider.notifier);

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
                          width: 24.w,
                          height: 24.h,
                          color: AppColors.Grey900,
                        ),
                      ),
                    ),
                    Expanded(child: _buildSwiper()),
                    SizedBox(height: 24.w),
                    _buildLanguageSelector(context, ref),
                    SizedBox(height: 24.w),
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
                      height: 61.w,
                      child: Text(
                        entry.value,
                        style: getTextStyle(
                            AppTypo.BODY14B,
                            Intl.getCurrentLocale() == entry.key
                                ? AppColors.Grey800
                                : AppColors.Grey400),
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
        height: 48.h,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.Primary500, width: 1.5),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SvgPicture.asset(
              'assets/icons/global_style=line.svg',
              colorFilter:
                  const ColorFilter.mode(AppColors.Primary500, BlendMode.srcIn),
              width: 20.w,
              height: 20.w,
            ),
            SizedBox(width: 20.w),
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  languageMap[appSettingState.locale.languageCode]!,
                  style: getTextStyle(AppTypo.BODY16M, AppColors.Grey900),
                ),
              ),
            ),
            Transform.rotate(
              angle: 1.57,
              child: SvgPicture.asset(
                'assets/icons/play_style=fill.svg',
                colorFilter:
                    const ColorFilter.mode(AppColors.Grey900, BlendMode.srcIn),
                width: 20.w,
                height: 20.w,
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
          backgroundColor: WidgetStateProperty.all(AppColors.Primary500),
          foregroundColor: WidgetStateProperty.all(AppColors.Grey00),
          textStyle: WidgetStateProperty.all(
              getTextStyle(AppTypo.TITLE18SB, AppColors.Grey00)),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
              side: const BorderSide(
                  color: AppColors.Mint500,
                  width: 1,
                  strokeAlign: BorderSide.strokeAlignInside),
            ),
          ),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 48.h,
        child: ElevatedButton(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              useSafeArea: false,
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isIOS()) _buildAppleLogin(context),
        _buildGoogleLogin(
          context,
        ),
        if (isIOS())
          _buildKakaoLogin(
            context,
          ),
      ],
    );
  }

  void _handleSuccessfulLogin(BuildContext context) async {
    try {
      OverlayLoadingProgress.start(context,
          color: AppColors.Primary500, barrierDismissible: false);

      // 현재 사용자 정보 가져오기
      final user = supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Failed to get current user');
      }

      // 사용자 프로필 정보 가져오기
      final userProfile =
          await ref.read(userInfoProvider.notifier).getUserProfiles();

      OverlayLoadingProgress.stop();

      if (userProfile == null) {
        // 사용자 프로필이 없는 경우 (새 사용자)
        ref
            .read(navigationInfoProvider.notifier)
            .setCurrentSignUpPage(const AgreementTermsPage());
        Navigator.of(context).pop();
      } else if (userProfile.deleted_at != null) {
        // 탈퇴한 사용자
        showSimpleDialog(
            context: context,
            content: S.of(context).error_message_withdrawal,
            onOk: () {
              Navigator.of(context).pop();
            });
      } else if (userProfile.user_agreement == null) {
        // 약관 동의가 필요한 경우
        ref
            .read(navigationInfoProvider.notifier)
            .setCurrentSignUpPage(const AgreementTermsPage());
        Navigator.of(context).pop();
      } else {
        // 정상적인 로그인 완료
        Navigator.of(context).pop();
        Navigator.of(context).pop();
      }
    } catch (e) {
      OverlayLoadingProgress.stop();
      print('Error handling successful login: $e');
      showSimpleDialog(
          context: context,
          title: S.of(context).error_title,
          content: S.of(context).error_message_login_failed,
          onOk: () {
            Navigator.of(context).pop();
          });
    }
  }

  Widget _buildAppleLogin(
    BuildContext context,
  ) {
    final userInfoState = ref.watch(userInfoProvider);

    return Stack(
      children: [
        InkWell(
          onTap: () async {
            OverlayLoadingProgress.start(context,
                color: AppColors.Primary500, barrierDismissible: false);
            final user =
                await _authService.signInWithProvider(OAuthProvider.apple);
            OverlayLoadingProgress.stop();

            if (user != null) {
              _handleSuccessfulLogin(context);
            }
          },
          child: SizedBox(
            height: 50.h,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset('assets/icons/login/apple.png',
                    width: 20.w, height: 20.w),
                SizedBox(width: 8.w),
                Text('Apple',
                    style: getTextStyle(AppTypo.BODY14M, AppColors.Grey800)),
              ],
            ),
          ),
        ),
        if (lastProvider == 'apple')
          Positioned(
            top: 0,
            bottom: 0,
            left: 30.w,
            child: Bubble(
              color: AppColors.Primary500.withOpacity(.9),
              alignment: Alignment.center,
              elevation: 0.5,
              nip: BubbleNip.rightCenter,
              stick: true,
              child: Text(
                S.of(context).label_last_provider,
                style: getTextStyle(AppTypo.CAPTION10SB, AppColors.Grey00),
              ),
            ),
          )
      ],
    );
  }

  Widget _buildGoogleLogin(
    BuildContext context,
  ) {
    return LayoutBuilder(builder: (context, constraints) {
      return Stack(
        children: [
          InkWell(
            onTap: () async {
              OverlayLoadingProgress.start(context,
                  color: AppColors.Primary500, barrierDismissible: false);
              final user =
                  await _authService.signInWithProvider(OAuthProvider.google);
              OverlayLoadingProgress.stop();
              if (user != null) {
                _handleSuccessfulLogin(context);
              }
            },
            child: SizedBox(
              height: 50.h,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset('assets/icons/login/google.png',
                      width: 20.w, height: 20.w),
                  SizedBox(width: 8.w),
                  Text('Google',
                      style: getTextStyle(AppTypo.BODY14M, AppColors.Grey800)),
                ],
              ),
            ),
          ),
          if (lastProvider == 'google')
            Positioned(
              top: 0,
              bottom: 0,
              left: 30.w,
              child: Bubble(
                color: AppColors.Primary500.withOpacity(.9),
                alignment: Alignment.center,
                elevation: 0.5,
                nip: BubbleNip.rightCenter,
                stick: true,
                child: Text(
                  S.of(context).label_last_provider,
                  style: getTextStyle(AppTypo.CAPTION10SB, AppColors.Grey00),
                ),
              ),
            )
        ],
      );
    });
  }

  Widget _buildKakaoLogin(
    BuildContext context,
  ) {
    final userInfoState = ref.watch(userInfoProvider);
    return LayoutBuilder(builder: (context, constraints) {
      return Stack(children: [
        InkWell(
          onTap: () async {
            OverlayLoadingProgress.start(context,
                color: AppColors.Primary500, barrierDismissible: false);
            final user =
                await _authService.signInWithProvider(OAuthProvider.kakao);
            OverlayLoadingProgress.stop();
            if (user != null) {
              _handleSuccessfulLogin(context);
            }
          },
          child: SizedBox(
            height: 50.h,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset('assets/icons/login/kakao.png',
                    width: 20.w, height: 20.w),
                SizedBox(width: 8.w),
                Text('Kakao Talk',
                    style: getTextStyle(AppTypo.BODY14M, AppColors.Grey800)),
              ],
            ),
          ),
        ),
        if (lastProvider == 'kakao')
          Positioned(
            top: 0,
            bottom: 0,
            left: 30.w,
            child: Bubble(
              color: AppColors.Primary500.withOpacity(.9),
              alignment: Alignment.center,
              elevation: 0.5,
              nip: BubbleNip.rightCenter,
              stick: true,
              child: Text(
                S.of(context).label_last_provider,
                style: getTextStyle(AppTypo.CAPTION10SB, AppColors.Grey00),
              ),
            ),
          )
      ]);
    });
  }

  //
  // Future<bool> _nativeAppleSignIn() async {
  //   try {
  //     final rawNonce = supabase.auth.generateRawNonce();
  //     final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();
  //
  //     final credential = await SignInWithApple.getAppleIDCredential(
  //       scopes: [
  //         AppleIDAuthorizationScopes.email,
  //         AppleIDAuthorizationScopes.fullName
  //       ],
  //       webAuthenticationOptions: WebAuthenticationOptions(
  //         clientId: 'io.iconcasting.picnic.app.apple',
  //         redirectUri: Uri.parse('https://api.picnic.fan/auth/v1/callback'),
  //       ),
  //     );
  //
  //     final idToken = credential.identityToken;
  //     if (idToken == null) {
  //       throw const AuthException(
  //           'Could not find ID Token from generated credential.');
  //     }
  //
  //     final response = await supabase.auth.signInWithIdToken(
  //         provider: OAuthProvider.apple, idToken: credential.identityToken!);
  //
  //     if (response.session != null) {
  //       await storeSession(response.session!);
  //       logger.i('Login successful and session stored');
  //     } else {
  //       logger.e('Login failed: No session returned');
  //     }
  //
  //     return true;
  //   } catch (e, s) {
  //     logger.e(e);
  //     logger.e(s);
  //     return false;
  //   }
  // }
  //
  // Future<bool> _nativeGoogleSignIn() async {
  //   try {
  //     const webClientId =
  //         '853406219989-jrfkss5a0lqe5sq43t4uhm7n6i0g6s1b.apps.googleusercontent.com';
  //     const iosClientId =
  //         '853406219989-ntnler0e2qe0gfheh3qdjt3k2h4kpvj4.apps.googleusercontent.com';
  //
  //     final GoogleSignIn googleSignIn =
  //         GoogleSignIn(clientId: iosClientId, serverClientId: webClientId);
  //
  //     final googleUser = await googleSignIn.signIn();
  //     final googleAuth = await googleUser!.authentication;
  //     final accessToken = googleAuth.accessToken;
  //     final idToken = googleAuth.idToken;
  //
  //     // try {
  //     //   Map<String, dynamic> decodedToken = JwtDecoder.decode(idToken!);
  //     //   logger.i('Decoded Token: $decodedToken');
  //     // } catch (e) {
  //     //   logger.i('Failed to decode id_token: $e');
  //     // }
  //
  //     if (accessToken == null) {
  //       throw 'No Access Token found.';
  //     }
  //     if (idToken == null) {
  //       throw 'No ID Token found.';
  //     }
  //
  //     // decodeAndPrintToken(idToken);
  //
  //     final response = await supabase.auth.signInWithIdToken(
  //         provider: OAuthProvider.google,
  //         idToken: idToken,
  //         accessToken: accessToken);
  //
  //     if (response.session != null) {
  //       await storeSession(response.session!);
  //       logger.i('Login successful and session stored');
  //       logger.i(response.session);
  //     } else {
  //       logger.e('Login failed: No session returned');
  //     }
  //
  //     return true;
  //   } catch (e, s) {
  //     logger.e(e);
  //     logger.e(s);
  //     return false;
  //   }
  // }
  //
  // Future<bool> _KakaoSignIn() async {
  //   try {
  //     KakaoSdk.init(
  //         nativeAppKey: '08a8a85e49aa423ff34ddc11a61db3ac',
  //         javaScriptAppKey: '0c6601457b7eb75b96967728abd638cb');
  //
  //     OAuthToken? token;
  //     if (await isKakaoTalkInstalled()) {
  //       try {
  //         token = await UserApi.instance.loginWithKakaoTalk();
  //         logger.i('카카오톡으로 로그인 성공');
  //       } catch (error) {
  //         logger.i('카카오톡으로 로그인 실패 $error');
  //         if (error is PlatformException && error.code == 'CANCELED') {
  //           return false;
  //         }
  //         try {
  //           token = await UserApi.instance.loginWithKakaoAccount();
  //           logger.i('카카오계정으로 로그인 성공');
  //         } catch (error) {
  //           logger.i('카카오계정으로 로그인 실패 $error');
  //         }
  //       }
  //     } else {
  //       try {
  //         token = await UserApi.instance.loginWithKakaoAccount();
  //         logger.i('카카오계정으로 로그인 성공');
  //       } catch (error) {
  //         logger.i('카카오계정으로 로그인 실패 $error');
  //       }
  //     }
  //
  //     logger.i('Token: $token');
  //     if (token == null || token.idToken == null) {
  //       throw 'Kakao login failed';
  //     }
  //
  //     decodeAndPrintToken(token.idToken!);
  //     final decodedToken = JwtDecoder.decode(token.idToken!);
  //     const expectedAudience = '08a8a85e49aa423ff34ddc11a61db3ac';
  //     if (decodedToken['aud'] != expectedAudience) {
  //       throw 'Invalid audience: ${decodedToken['aud']}';
  //     }
  //
  //     logger.i('ID Token: ${token.idToken}');
  //     logger.i('Access Token: ${token.accessToken}');
  //
  //     final response = await supabase.auth.signInWithIdToken(
  //         provider: OAuthProvider.kakao,
  //         idToken: token.idToken!,
  //         accessToken: token.accessToken,
  //         nonce: decodedToken['nonce']);
  //
  //     if (response.session != null) {
  //       await storeSession(response.session!);
  //       logger.i('Login successful and session stored');
  //     } else {
  //       logger.e('Login failed: No session returned');
  //     }
  //
  //     return true;
  //   } catch (e, s) {
  //     logger.e(e);
  //     logger.e(s);
  //     return false;
  //   }
  // }

  void decodeAndPrintToken(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      throw Exception('Invalid token');
    }

    final payload =
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
    final payloadMap = json.decode(payload) as Map<String, dynamic>;

    logger.i('Token Payload: $payloadMap');
    if (payloadMap.containsKey('aud')) {
      logger.i('Audience: ${payloadMap['aud']}');
    } else {
      logger.i('Audience not found in token');
    }
  }
}

import 'dart:convert';
import 'dart:io';

import 'package:card_swiper/card_swiper.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:overlay_loading_progress/overlay_loading_progress.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/providers/app_setting_provider.dart';
import 'package:picnic_app/providers/user_info_provider.dart';
import 'package:picnic_app/supabase_options.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const optionText = Text(
  'Or',
  style: TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
  ),
  textAlign: TextAlign.center,
);

const spacer = SizedBox(
  height: 12,
);

class LoginScreen extends ConsumerWidget {
  static const String routeName = '/login';

  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appSettingState = ref.watch(appSettingProvider);
    final appSettingNotifier = ref.read(appSettingProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Expanded(
                  child: Swiper(
                itemCount: 3,
                pagination: const SwiperPagination(),
                itemBuilder: (BuildContext context, int index) {
                  return Container(color: Colors.grey);
                },
              )),
              SizedBox(
                height: 24.w,
              ),
              GestureDetector(
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
                                  if (appSettingState.locale.languageCode ==
                                      entry.key) return;
                                  appSettingNotifier.setLocale(Locale(
                                    entry.key,
                                    countryMap[entry.key] ?? '',
                                  ));
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
                      });
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
                        colorFilter: const ColorFilter.mode(
                            AppColors.Primary500, BlendMode.srcIn),
                        width: 20.w,
                        height: 20.w,
                      ),
                      SizedBox(
                        width: 20.w,
                      ),
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            languageMap[appSettingState.locale.languageCode]!,
                            style: getTextStyle(
                                AppTypo.BODY16M, AppColors.Grey900),
                          ),
                        ),
                      ),
                      Transform.rotate(
                        angle: 1.57,
                        child: SvgPicture.asset(
                          'assets/icons/play_style=fill.svg',
                          colorFilter: const ColorFilter.mode(
                              AppColors.Grey900, BlendMode.srcIn),
                          width: 20.w,
                          height: 20.w,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: 24.w,
              ),
              ElevatedButtonTheme(
                data: ElevatedButtonThemeData(
                  style: ButtonStyle(
                    backgroundColor:
                        WidgetStateProperty.all(AppColors.Primary500),
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
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (Platform.isIOS)
                                      InkWell(
                                          onTap: () {
                                            OverlayLoadingProgress.start(
                                                context,
                                                color: AppColors.Primary500,
                                                barrierDismissible: false);

                                            _nativeAppleSignIn().then((value) {
                                              if (value) {
                                                ref
                                                    .read(userInfoProvider
                                                        .notifier)
                                                    .getUserProfiles()
                                                    .then((value) {
                                                  logger.i(value);
                                                  OverlayLoadingProgress.stop();

                                                  Navigator.of(context).pop();
                                                  Navigator.of(context).pop();
                                                });
                                              } else {
                                                OverlayLoadingProgress.stop();
                                              }
                                            });
                                          },
                                          child: Container(
                                            alignment: Alignment.center,
                                            width: double.infinity,
                                            height: 61.w,
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Image.asset(
                                                  'assets/icons/login/apple.png',
                                                  width: 20.w,
                                                  height: 20.w,
                                                ),
                                                SizedBox(
                                                  width: 8.w,
                                                ),
                                                Text('Apple',
                                                    style: getTextStyle(
                                                        AppTypo.BODY14M,
                                                        AppColors.Grey800)),
                                                // AppColors.Grey800)),
                                              ],
                                            ),
                                          )),
                                    InkWell(
                                        onTap: () {
                                          OverlayLoadingProgress.start(context,
                                              color: AppColors.Primary500,
                                              barrierDismissible: false);

                                          _nativeGoogleSignIn().then((value) {
                                            if (value) {
                                              ref
                                                  .read(
                                                      userInfoProvider.notifier)
                                                  .getUserProfiles()
                                                  .then((value) {
                                                logger.i(value);
                                                OverlayLoadingProgress.stop();

                                                Navigator.of(context).pop();
                                                Navigator.of(context).pop();
                                              });
                                            } else {
                                              OverlayLoadingProgress.stop();
                                            }
                                          });
                                        },
                                        child: Container(
                                          alignment: Alignment.center,
                                          width: double.infinity,
                                          height: 61.w,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Image.asset(
                                                'assets/icons/login/google.png',
                                                width: 20.w,
                                                height: 20.w,
                                              ),
                                              SizedBox(
                                                width: 8.w,
                                              ),
                                              Text('Google',
                                                  style: getTextStyle(
                                                      AppTypo.BODY14M,
                                                      AppColors.Grey800)),
                                            ],
                                          ),
                                        )),
                                    InkWell(
                                        onTap: () async {
                                          OverlayLoadingProgress.start(context,
                                              color: AppColors.Primary500,
                                              barrierDismissible: false);
                                          _KakaoSignIn().then((value) {
                                            if (value) {
                                              ref
                                                  .read(
                                                      userInfoProvider.notifier)
                                                  .getUserProfiles()
                                                  .then((value) {
                                                logger.i(value);
                                                OverlayLoadingProgress.stop();

                                                Navigator.of(context).pop();
                                                Navigator.of(context).pop();
                                              });
                                            } else {
                                              OverlayLoadingProgress.stop();
                                            }
                                          });
                                        },
                                        child: Container(
                                          alignment: Alignment.center,
                                          width: double.infinity,
                                          height: 61.w,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Image.asset(
                                                'assets/icons/login/kakao.png',
                                                width: 20.w,
                                                height: 20.w,
                                              ),
                                              SizedBox(
                                                width: 8.w,
                                              ),
                                              Text('Kakao Talk',
                                                  style: getTextStyle(
                                                      AppTypo.BODY14M,
                                                      AppColors.Grey800)),
                                            ],
                                          ),
                                        )),
                                  ],
                                ),
                              );
                            });
                      },
                      child: Text(S.of(context).button_login)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _nativeAppleSignIn() async {
    try {
      final rawNonce = supabase.auth.generateRawNonce();
      final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

      final webAuthenticationOptions = WebAuthenticationOptions(
        clientId: 'io.iconcasting.picnic.app.apple',
        // Apple Developer Console에서 설정한 서비스 ID
        redirectUri: Uri.parse('https://api.picnic.fan/auth/v1/callback'),
      );

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        webAuthenticationOptions: WebAuthenticationOptions(
          clientId: 'io.iconcasting.picnic.app.apple',
          redirectUri: Uri.parse('https://api.picnic.fan/auth/v1/callback'),
        ),
      );

      final idToken = credential.identityToken;
      if (idToken == null) {
        throw const AuthException(
            'Could not find ID Token from generated credential.');
      }

      final response = await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: credential.identityToken!,
      );

      return true;
    } catch (e, s) {
      logger.e(e);
      logger.e(s);
      return false;
    }
  }

  Future<bool> _nativeGoogleSignIn() async {
    try {
      const webClientId =
          '853406219989-jrfkss5a0lqe5sq43t4uhm7n6i0g6s1b.apps.googleusercontent.com';

      const iosClientId =
          '853406219989-ntnler0e2qe0gfheh3qdjt3k2h4kpvj4.apps.googleusercontent.com';

      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: iosClientId,
        serverClientId: webClientId,
      );

      final googleUser = await googleSignIn.signIn();
      final googleAuth = await googleUser!.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      try {
        Map<String, dynamic> decodedToken = JwtDecoder.decode(idToken!);
        logger.i('Decoded Token: $decodedToken');
      } catch (e) {
        logger.i('Failed to decode id_token: $e');
      }

      if (accessToken == null) {
        throw 'No Access Token found.';
      }
      if (idToken == null) {
        throw 'No ID Token found.';
      }

      decodeAndPrintToken(
          idToken); // Add this line to decode and logger.i the token

      await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      return true;
    } catch (e, s) {
      logger.e(e);
      logger.e(s);
      return false;
    }
  }

  Future<bool> _KakaoSignIn() async {
    try {
      KakaoSdk.init(
        nativeAppKey: '08a8a85e49aa423ff34ddc11a61db3ac',
        javaScriptAppKey: '0c6601457b7eb75b96967728abd638cb',
        // nativeAppKey: '75e247f5d29512f84749e64aac77ebfa',
        // javaScriptAppKey: 'fe170eb02c6ff6a488a5848f9db41335',
      );

      OAuthToken? token;
      if (await isKakaoTalkInstalled()) {
        try {
          token = await UserApi.instance.loginWithKakaoTalk();
          logger.i('카카오톡으로 로그인 성공');
        } catch (error) {
          logger.i('카카오톡으로 로그인 실패 $error');

          // 사용자가 카카오톡 설치 후 디바이스 권한 요청 화면에서 로그인을 취소한 경우,
          // 의도적인 로그인 취소로 보고 카카오계정으로 로그인 시도 없이 로그인 취소로 처리 (예: 뒤로 가기)
          if (error is PlatformException && error.code == 'CANCELED') {
            return false;
          }
          // 카카오톡에 연결된 카카오계정이 없는 경우, 카카오계정으로 로그인
          try {
            token = await UserApi.instance.loginWithKakaoAccount();
            logger.i('카카오계정으로 로그인 성공');
          } catch (error) {
            logger.i('카카오계정으로 로그인 실패 $error');
          }
        }
      } else {
        try {
          token = await UserApi.instance.loginWithKakaoAccount();
          logger.i('카카오계정으로 로그인 성공');
        } catch (error) {
          logger.i('카카오계정으로 로그인 실패 $error');
        }
      }

      logger.i('Token: $token');

      if (token == null || token.idToken == null) {
        throw 'Kakao login failed';
      }

      decodeAndPrintToken(token.idToken!); // 토큰 디코딩 및 출력

      final decodedToken = JwtDecoder.decode(token.idToken!);
      const expectedAudience = '08a8a85e49aa423ff34ddc11a61db3ac';
      // const expectedAudience = '75e247f5d29512f84749e64aac77ebfa';

      if (decodedToken['aud'] != expectedAudience) {
        throw 'Invalid audience: ${decodedToken['aud']}';
      }

      // 토큰 정보 출력
      logger.i('ID Token: ${token.idToken}');
      logger.i('Access Token: ${token.accessToken}');

      await supabase.auth.signInWithIdToken(
        provider: OAuthProvider.kakao,
        idToken: token.idToken!,
        accessToken: token.accessToken,
        nonce: decodedToken['nonce'],
      );

      return true;
    } catch (e, s) {
      logger.e(e);
      logger.e(s);
      return false;
    }
  }

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

class LoginScreenArguments {
  final String? email;
  final String? password;

  LoginScreenArguments({this.email, this.password});
}

import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/intl.dart';
import 'package:picnic_app/constants.dart';
import 'package:picnic_app/providers/app_setting_provider.dart';
import 'package:picnic_app/ui/style.dart';
import 'package:supabase_auth_ui/supabase_auth_ui.dart';

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
                        colorFilter: ColorFilter.mode(
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
                          colorFilter: ColorFilter.mode(
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
                                  GestureDetector(
                                      behavior: HitTestBehavior.translucent,
                                      onTap: () {
                                        _nativeGoogleSignIn();
                                        //   .then((value) {
                                        // if (value) {
                                        //   ref
                                        //       .read(userInfoProvider.notifier)
                                        //       .getUserProfiles()
                                        //       .then((value) {
                                        //     logger.i(value);
                                        //
                                        //     // Navigator.of(context).pop();
                                        //     // Navigator.of(context).pop();
                                        //   });
                                        // }
                                        // });
                                      },
                                      child: Container(
                                        alignment: Alignment.center,
                                        width: double.infinity,
                                        height: 61.w,
                                        child: Text('Google',
                                            style: getTextStyle(AppTypo.BODY16M,
                                                AppColors.Grey900)),
                                      )),
                                ],
                              ),
                            );
                          });
                    },
                    child: const Text('Log in'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

      if (accessToken == null) {
        throw 'No Access Token found.';
      }
      if (idToken == null) {
        throw 'No ID Token found.';
      }

      logger.i('googleUser: $googleUser');
      logger.i('googleAuth: $googleAuth');
      logger.i('accessToken: $accessToken');
      logger.i('idToken: $idToken');

      final response = await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      logger.i('response: $response');
      logger.i('response.user: ${response.user}');

      return true;
    } catch (e, s) {
      logger.e(e);
      logger.e(s);
      return false;
    }
  }
}

class LoginScreenArguments {
  final String? email;
  final String? password;

  LoginScreenArguments({this.email, this.password});
}

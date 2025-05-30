import 'package:bubble_box/bubble_box.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:overlay_loading_progress/overlay_loading_progress.dart';
import 'package:picnic_lib/core/config/environment.dart';
import 'package:picnic_lib/core/constatns/constants.dart';
import 'package:picnic_lib/core/errors/auth_exception.dart';
import 'package:picnic_lib/core/services/region_detection_service.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/ui.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/presentation/common/custom_pagination.dart';
import 'package:picnic_lib/presentation/common/navigator_key.dart';
import 'package:picnic_lib/presentation/dialogs/simple_dialog.dart';
import 'package:picnic_lib/presentation/pages/signup/agreement_terms_page.dart';
import 'package:picnic_lib/presentation/providers/app_setting_provider.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:picnic_lib/ui/common_gradient.dart';
import 'package:picnic_lib/ui/style.dart';
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

  String? lastProvider;
  RegionInfo? regionInfo;
  bool isDetectingRegion = true;

  @override
  void initState() {
    super.initState();
    _loadLastProvider();
    _detectUserRegion();
  }

  Future<void> _loadLastProvider() async {
    const storage = FlutterSecureStorage();
    final provider = await storage.read(key: 'last_provider');
    if (mounted) {
      setState(() {
        lastProvider = provider;
      });
    }
  }

  Future<void> _detectUserRegion() async {
    try {
      logger.i('Starting region detection...');

      if (mounted) {
        setState(() {
          isDetectingRegion = true;
        });
      }

      final region = await RegionDetectionService.detectRegion();
      logger
          .i('Region detected: ${region.countryCode} (${region.region.name})');

      if (kDebugMode) {
        final debugOverride = RegionDetectionService.debugRegionOverride;
        if (debugOverride != null) {
          logger.i('Debug override active: $debugOverride');
        } else {
          logger.i('No debug override active');
        }
      }

      if (mounted) {
        setState(() {
          regionInfo = region;
          isDetectingRegion = false;
        });
        logger.i('UI updated with new region info');
      }
    } catch (e, s) {
      logger.e('Failed to detect user region', error: e, stackTrace: s);
      if (mounted) {
        setState(() {
          // Fallback to 'other' region if detection fails
          regionInfo = const RegionInfo(
            region: UserRegion.other,
            countryCode: 'UNKNOWN',
            countryName: 'Unknown',
            detectedAt: null,
          );
          isDetectingRegion = false;
        });
      }
    }
  }

  Future<void> _saveLastProvider(String provider) async {
    const storage = FlutterSecureStorage();
    await storage.write(key: 'last_provider', value: provider);
    if (mounted) {
      setState(() {
        lastProvider = provider;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: commonGradient),
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
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          }
                        },
                        child: SvgPicture.asset(
                          package: 'picnic_lib',
                          'assets/icons/arrow_left_style=line.svg',
                          width: 24.w,
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
      itemCount: 2,
      autoplay: true,
      pagination: SwiperPagination(
        builder: CustomPaginationBuilder(),
      ),
      itemBuilder: (BuildContext context, int index) {
        return Image.asset(
            'assets/login/${getLocaleLanguage()}_${index + 1}.png');
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
                      if (appSettingState.language == entry.key) {
                        return;
                      }
                      appSettingNotifier.setLanguage(entry.key);
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
                            getLocaleLanguage() == entry.key
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
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primary500, width: 1.5),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SvgPicture.asset(
              package: 'picnic_lib',
              'assets/icons/global_style=line.svg',
              colorFilter:
                  ColorFilter.mode(AppColors.primary500, BlendMode.srcIn),
              width: 20.w,
              height: 20,
            ),
            SizedBox(width: 20.w),
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  languageMap[appSettingState.language]!,
                  style: getTextStyle(AppTypo.body16M, AppColors.grey900),
                ),
              ),
            ),
            Transform.rotate(
              angle: 1.57,
              child: SvgPicture.asset(
                package: 'picnic_lib',
                'assets/icons/play_style=fill.svg',
                colorFilter:
                    const ColorFilter.mode(AppColors.grey900, BlendMode.srcIn),
                width: 20.w,
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
              side: BorderSide(
                  color: AppColors.secondary500,
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
                return StatefulBuilder(
                  builder: (context, setModalState) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 40),
                      child: _buildLoginOptionsContent(
                          context, ref, setModalState),
                    );
                  },
                );
              },
            );
          },
          child: Text(t('button_login')),
        ),
      ),
    );
  }

  Widget _buildLoginOptionsContent(
      BuildContext context, WidgetRef ref, setModalState) {
    // Show loading indicator while detecting region
    if (isDetectingRegion) {
      return const SizedBox(
        width: double.infinity,
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Detecting your region...'),
            ],
          ),
        ),
      );
    }

    // Get available providers for the detected region
    final availableProviders = regionInfo != null
        ? RegionDetectionService.getAvailableLoginProviders(regionInfo!.region)
        : ['apple', 'google', 'kakao', 'wechat']; // Fallback to all providers

    return SizedBox(
      width: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Show region info for debugging (can be removed in production)
          if (regionInfo != null && kDebugMode)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'DEBUG MODE - kDebugMode: $kDebugMode',
                          style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.red),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Region: ${regionInfo!.countryCode} (${regionInfo!.region.name})',
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Providers: ${availableProviders.join(', ')}',
                          style:
                              const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                        if (RegionDetectionService.debugRegionOverride != null)
                          Text(
                            'Override: ${RegionDetectionService.debugRegionOverride}',
                            style: const TextStyle(
                                fontSize: 10,
                                color: Colors.orange,
                                fontWeight: FontWeight.bold),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Debug region simulation controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          logger.i('Debug: CN button pressed');
                          try {
                            await RegionDetectionService.simulateChina();
                            logger.i('Debug: China simulation set');

                            // Update region info and refresh modal
                            final newRegionInfo =
                                await RegionDetectionService.detectRegion();
                            setState(() {
                              regionInfo = newRegionInfo;
                            });
                            setModalState(() {
                              // Trigger modal rebuild
                            });
                          } catch (e) {
                            logger
                                .e('Debug: Error setting China simulation: $e');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          minimumSize: const Size(60, 30),
                        ),
                        child: const Text('CN', style: TextStyle(fontSize: 10)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          logger.i('Debug: US button pressed');
                          try {
                            await RegionDetectionService.simulateOtherRegion(
                                'US');
                            logger.i('Debug: US simulation set');

                            // Update region info and refresh modal
                            final newRegionInfo =
                                await RegionDetectionService.detectRegion();
                            setState(() {
                              regionInfo = newRegionInfo;
                            });
                            setModalState(() {
                              // Trigger modal rebuild
                            });
                          } catch (e) {
                            logger.e('Debug: Error setting US simulation: $e');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          minimumSize: const Size(60, 30),
                        ),
                        child: const Text('US', style: TextStyle(fontSize: 10)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          logger.i('Debug: Clear button pressed');
                          try {
                            await RegionDetectionService.clearSimulation();
                            // Also clear the cache to force fresh detection
                            await RegionDetectionService.clearCache();
                            logger.i('Debug: Simulation and cache cleared');

                            // Update region info and refresh modal
                            final newRegionInfo =
                                await RegionDetectionService.detectRegion();
                            setState(() {
                              regionInfo = newRegionInfo;
                            });
                            setModalState(() {
                              // Trigger modal rebuild
                            });
                          } catch (e) {
                            logger.e('Debug: Error clearing simulation: $e');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          minimumSize: const Size(60, 30),
                        ),
                        child:
                            const Text('Clear', style: TextStyle(fontSize: 10)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // Apple Login (iOS only, and if available in region)
          if (isIOS() && availableProviders.contains('apple'))
            _buildAppleLogin(context),

          // Google Login (if available in region)
          if (availableProviders.contains('google')) _buildGoogleLogin(context),

          // Kakao Login (if available in region)
          if (availableProviders.contains('kakao')) _buildKakaoLogin(context),

          // WeChat Login (if available in region)
          if (availableProviders.contains('wechat')) _buildWeChatLogin(context),
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
            content: t('error_message_withdrawal'),
            onOk: () {
              ref.read(userInfoProvider.notifier).logout();
              Navigator.of(navigatorKey.currentContext!).pop();
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
          title: t('error_title'),
          content: t('error_message_login_failed'),
          onOk: () {
            Navigator.of(navigatorKey.currentContext!).pop();
          });
      rethrow;
    }
  }

  Widget _buildAppleLogin(BuildContext context) {
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

                await _saveLastProvider('apple');
                _handleSuccessfulLogin();
                            } on PicnicAuthException catch (e, s) {
                logger.e(
                    'Apple login PicnicAuthException: $e (originalError: ${e.originalError})',
                    error: e,
                    stackTrace: s);

                if (e.code == 'canceled') {
                  return;
                }

                showSimpleDialog(
                    type: DialogType.error,
                    title: t('error_title'),
                    content: e.message,
                    onOk: () {
                      Navigator.of(navigatorKey.currentContext!).pop();
                    });
              } catch (e, s) {
                OverlayLoadingProgress.stop();
                logger.e('Error signing in with Apple: $e', stackTrace: s);

                showSimpleDialog(
                    type: DialogType.error,
                    title: t('error_title'),
                    content: t('error_message_login_failed'),
                    onOk: () {
                      Navigator.of(navigatorKey.currentContext!).pop();
                    });
                rethrow;
              } finally {
                OverlayLoadingProgress.stop();
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
                await _saveLastProvider('google');
                _handleSuccessfulLogin();
                            }
            } catch (e, s) {
              logger.e('Error signing in with Google: $e', stackTrace: s);

              if (e is PicnicAuthException) {
                if (e.code == 'canceled') {
                  return;
                }
              }
              showSimpleDialog(
                  type: DialogType.error,
                  title: t('error_title'),
                  content: t('error_message_login_failed'),
                  onOk: () {
                    Navigator.of(navigatorKey.currentContext!).pop();
                  });
              rethrow;
            } finally {
              OverlayLoadingProgress.stop();
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
                  Image.asset(
                      package: 'picnic_lib',
                      'assets/icons/login/google.png',
                      width: 20.w,
                      height: 20),
                  SizedBox(width: 8.w),
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
                await _saveLastProvider('kakao');
                _handleSuccessfulLogin();
                            }
            } on PicnicAuthException catch (e) {
              if (e.code == 'canceled') {
                return;
              }

              showSimpleDialog(
                  type: DialogType.error,
                  title: t('error_title'),
                  content: e.message,
                  onOk: () {
                    Navigator.of(navigatorKey.currentContext!).pop();
                  });
            } catch (e, s) {
              OverlayLoadingProgress.stop();
              logger.e('Error signing in with Kakao: $e', stackTrace: s);

              showSimpleDialog(
                  type: DialogType.error,
                  title: t('error_title'),
                  content: t('error_message_login_failed'),
                  onOk: () {
                    Navigator.of(navigatorKey.currentContext!).pop();
                  });
              rethrow;
            } finally {
              OverlayLoadingProgress.stop();
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
                  Image.asset(
                      package: 'picnic_lib',
                      'assets/icons/login/kakao.png',
                      width: 20.w,
                      height: 20),
                  SizedBox(width: 8.w),
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

  Widget _buildWeChatLogin(BuildContext context) {
    return Stack(
      children: [
        GestureDetector(
          onTap: () async {
            try {
              OverlayLoadingProgress.start(context,
                  color: AppColors.primary500, barrierDismissible: false);

              // WeChat login implementation

              // Save last provider for future reference
              await _saveLastProvider('wechat');

              _handleSuccessfulLogin();
                        } on PicnicAuthException catch (e, s) {
              logger.e(
                  'WeChat login PicnicAuthException: $e (originalError: ${e.originalError})',
                  error: e,
                  stackTrace: s);

              if (e.code == 'canceled') {
                return;
              }

              showSimpleDialog(
                  type: DialogType.error,
                  title: t('error_title'),
                  content: e.message,
                  onOk: () {
                    Navigator.of(navigatorKey.currentContext!).pop();
                  });
            } catch (e, s) {
              OverlayLoadingProgress.stop();
              logger.e('Error signing in with WeChat: $e', stackTrace: s);

              showSimpleDialog(
                  type: DialogType.error,
                  title: t('error_title'),
                  content: t('error_message_login_failed'),
                  onOk: () {
                    Navigator.of(navigatorKey.currentContext!).pop();
                  });
              rethrow;
            } finally {
              OverlayLoadingProgress.stop();
            }
          },
          child: Center(
            child: Container(
              width: 240,
              height: 44,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.grey400, width: 1),
                borderRadius: BorderRadius.circular(12),
                color: const Color(0xFF07C160), // WeChat brand color
              ),
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // WeChat icon - using a placeholder for now
                  Container(
                    width: 20.w,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.chat_bubble_outline,
                      color: Color(0xFF07C160),
                      size: 16,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    t('button_login_wechat'),
                    style: getTextStyle(AppTypo.body14M, Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (lastProvider == 'wechat') const LastProvider(),
      ],
    );
  }
}

class LastProvider extends StatelessWidget {
  const LastProvider({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 10,
      bottom: 10,
      left: 10.w,
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
        backgroundColor: AppColors.secondary500,
        child: Center(
          child: Text(
            t('label_last_provider'),
            style: getTextStyle(AppTypo.caption10SB, AppColors.primary500),
          ),
        ),
      ),
    );
  }
}

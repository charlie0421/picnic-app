import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/core/utils/app_builder.dart';
import 'package:picnic_lib/core/utils/app_initializer.dart';
import 'package:picnic_lib/core/utils/app_lifecycle_initializer.dart';
import 'package:picnic_lib/core/utils/language_manager.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/main_initializer.dart';
import 'package:picnic_lib/core/utils/route_manager.dart';
import 'package:picnic_lib/enums.dart';
import 'package:picnic_lib/presentation/common/navigator_key.dart';
import 'package:picnic_lib/presentation/dialogs/update_dialog.dart';
import 'package:picnic_lib/presentation/providers/app_setting_provider.dart';
import 'package:picnic_lib/presentation/providers/global_media_query.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/providers/screen_infos_provider.dart';
import 'package:picnic_lib/presentation/providers/screen_protector_provider.dart';
import 'package:picnic_lib/ui/community_theme.dart';
import 'package:picnic_lib/ui/mypage_theme.dart';
import 'package:picnic_lib/ui/novel_theme.dart';
import 'package:picnic_lib/ui/pic_theme.dart';
import 'package:picnic_lib/ui/vote_theme.dart';
import 'package:ttja_app/bottom_navigation_menu.dart';
import 'package:ttja_app/presenstation/screens/portal.dart';
import 'package:universal_platform/universal_platform.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:picnic_lib/services/localization_service.dart';
import 'package:ttja_app/generated/l10n.dart';
import 'package:ttja_app/main.dart' as main_file;

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  createState() => _AppState();
}

class _AppState extends ConsumerState<App> with WidgetsBindingObserver {
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey =
      GlobalKey<ScaffoldMessengerState>();

  bool _isAppInitialized = false;
  Widget? initScreen;
  StreamSubscription? _authSubscription;
  StreamSubscription? _appLinksSubscription;

  // 지원되는 언어 목록
  static const List<Locale> _supportedLocales = [
    Locale('ko'), // 한국어 (기본값)
    Locale('en'), // 영어
    Locale('ja'), // 일본어
    Locale('zh'), // 중국어
    Locale('id'), // 인도네시아어
  ];

  // 앱의 라우트 맵 - 앱 고유 라우트만 포함 (공통 라우트는 RouteManager에서 관리)
  final Map<String, WidgetBuilder> _appSpecificRoutes = {
    Portal.routeName: (context) => const Portal(),
  };

  @override
  void initState() {
    super.initState();
    logger.i('App initState 호출됨');

    // AppLifecycleInitializer를 사용하여 앱 초기화 및 리스너 설정
    AppLifecycleInitializer.setupAppInitializers(ref, context);

    // 앱 라우트 설정
    AppLifecycleInitializer.setupAppRoutes(ref, _appSpecificRoutes);

    // 초기화 로직을 initState()에서 수행 - 별도 Future로 선언하지 않고 즉시 실행
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    logger.i('_initializeApp 시작');

    // 앱이 이미 초기화되었다면 바로 반환
    if (_isAppInitialized) {
      logger.i('앱이 이미 초기화됨. 초기화 과정 스킵');
      return;
    }

    // 모바일 환경에서만 시스템 UI 초기화
    if (UniversalPlatform.isMobile && !kIsWeb) {
      await AppInitializer.initializeSystemUI();
    }

    if (!mounted) {
      logger.e('앱 초기화 중 위젯이 dispose됨');
      _isAppInitialized = false;
      return;
    }

    // 언어 초기화는 다른 초기화와 병렬로 진행
    _initializeLanguage();

    // 앱 초기화 (모바일/웹 구분)
    try {
      if (UniversalPlatform.isMobile) {
        await AppInitializer.initializeAppWithSplash(context, ref);
      } else {
        await AppInitializer.initializeWebApp(context, ref);
      }

      if (!mounted) return;

      // 스크린 정보 맵 생성
      final screenInfoMap = {
        PortalType.vote.name.toString(): voteScreenInfo,
        PortalType.pic.name.toString(): picScreenInfo,
        PortalType.community.name.toString(): communityScreenInfo,
        PortalType.novel.name.toString(): novelScreenInfo,
      };

      // screenInfosProvider에 스크린 정보 설정
      ref.read(screenInfosProvider.notifier).setScreenInfoMap(screenInfoMap);

      // 앱 초기화 완료 플래그 설정
      if (mounted) {
        setState(() {
          _isAppInitialized = true;
        });

        // 앱 초기화 완료 표시
        AppLifecycleInitializer.markAppInitialized(ref);
      }
    } catch (e, stackTrace) {
      logger.e('앱 초기화 중 오류 발생', error: e, stackTrace: stackTrace);
      if (mounted) {
        setState(() {
          _isAppInitialized = false;
        });
      }
    }

    logger.i('_initializeApp 완료');
  }

  // 언어 초기화를 위한 별도 메서드
  Future<void> _initializeLanguage() async {
    // 먼저 앱 설정이 로드될 때까지 대기
    await ref.read(appSettingProvider.notifier).loadSettings();

    // MainInitializer의 initializeLanguageAsync 메서드를 사용하여 언어 초기화
    await MainInitializer.initializeLanguageAsync(
      ref,
      context,
      S.load,
      (success, language) {
        logger.i('언어 초기화 완료: 성공=$success, 언어=$language');

        // main.dart의 전역 변수 업데이트
        main_file.isLanguageInitialized = success;
        main_file.currentLanguage = language;

        // 앱 설정에 언어 반영
        if (success) {
          ref.read(appSettingProvider.notifier).setLanguage(language);

          // PicnicLibL10n을 올바른 ProviderContainer와 함께 초기화
          try {
            final appSetting = ref.read(appSettingProvider);
            PicnicLibL10n.initialize(appSetting);
            logger.i('PicnicLibL10n 명시적 초기화 완료');
          } catch (e) {
            logger.e('PicnicLibL10n 명시적 초기화 실패', error: e);
            // 실패해도 계속 진행 (t 메서드가 대체 값을 반환하도록 개선됨)
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // 앱 설정 관련 상태 구독
    final appSettingState = ref.watch(appSettingProvider);
    final isScreenProtector = ref.watch(isScreenProtectorProvider);

    // 화면 보호기 설정 업데이트
    AppBuilder.updateScreenProtector(isScreenProtector);

    // 언어 변경 감지 및 적용 로직
    ref.listen<Setting>(
      appSettingProvider,
      (previous, current) {
        if (previous?.language != current.language) {
          logger.i('언어 변경 감지: ${previous?.language} -> ${current.language}');
          _applyLanguageChange(current.language);
        }
      },
    );

    // 내비게이션 관련 프로바이더 구독
    ref.watch(navigationInfoProvider);
    ref.watch(globalMediaQueryProvider);

    // 앱 홈 화면 결정
    Widget homeWidget = _isAppInitialized
        ? const Portal() // Portal 위젯으로 변경
        : const SizedBox.shrink(); // 초기화 중에는 빈 위젯 표시 (스플래시는 AppBuilder에서 처리)

    // 라우트 처리
    final routes = RouteManager.mergeRoutes(_appSpecificRoutes);

    // AppBuilder를 사용하여 앱 UI 구성
    return AppBuilder.buildApp(
      navigatorKey: navigatorKey,
      scaffoldKey: _scaffoldKey,
      routes: routes,
      title: 'TTJA',
      theme: _getCurrentTheme(ref),
      home: UpdateDialog(child: homeWidget),
      localizationsDelegates: [
        ...LocalizationService.localizationDelegates,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: _supportedLocales,
      locale: Locale(appSettingState.language),
      enableScreenProtector: isScreenProtector,
    );
  }

  ThemeData _getCurrentTheme(WidgetRef ref) {
    final currentPortal = ref.watch(navigationInfoProvider);
    switch (currentPortal.portalType) {
      case PortalType.vote:
        return voteThemeLight;
      case PortalType.pic:
        return picThemeLight;
      case PortalType.community:
        return communityThemeLight;
      case PortalType.novel:
        return novelThemeLight;
      case PortalType.mypage:
        return mypageThemeLight;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    // 앱 리스너 정리
    AppLifecycleInitializer.disposeAppListeners(
      _authSubscription,
      _appLinksSubscription,
    );

    // 화면 보호기 해제는 AppBuilder의 updateScreenProtector로 처리
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    logger.i('앱 생명주기 상태 변경: $state');

    switch (state) {
      case AppLifecycleState.resumed:
        // 앱이 포그라운드로 돌아올 때 필요한 작업
        break;
      case AppLifecycleState.inactive:
        // 앱이 비활성화될 때 필요한 작업
        break;
      case AppLifecycleState.paused:
        // 앱이 백그라운드로 전환될 때 필요한 작업
        break;
      case AppLifecycleState.detached:
        // 앱이 분리될 때 필요한 작업
        break;
      default:
        break;
    }
  }

  // 언어 변경 적용 - 번역을 즉시 로드하고 UI를 업데이트하는 강화된 메서드
  Future<void> _applyLanguageChange(String language) async {
    try {
      logger.i('언어 변경 시작: $language');

      // mounted 상태 확인 및 UI 상태 변경
      if (!mounted) return;

      // UI 상태 업데이트 - 로딩 화면 표시
      setState(() {
        _isAppInitialized = false;
        logger.i('언어 변경 중 일시적으로 화면 초기화');
      });

      // LanguageManager를 사용하여 언어 변경 및 앱 리로드 처리
      await LanguageManager.changeAppLanguage(
        ref,
        context,
        language,
        S.load,
        callback: (isInitialized, language) {
          // main.dart의 전역 변수 업데이트
          main_file.isLanguageInitialized = isInitialized;
          main_file.currentLanguage = language;
          logger.i('main.dart 전역 변수 업데이트: $language');
        },
        shouldReload: true, // Phoenix.rebirth를 통한 앱 재시작 활성화
      );

      // Phoenix.rebirth가 성공하면 여기까지 실행되지 않음
      // 실패한 경우에만 UI 상태 복구
      if (!mounted) return;

      setState(() {
        _isAppInitialized = true;
        logger.i('Phoenix.rebirth 실패 - UI 상태 복원');
      });
    } catch (e) {
      logger.e('언어 변경 중 오류 발생', error: e);

      // 오류 발생 시에도 UI 상태 복구
      if (mounted) {
        setState(() {
          _isAppInitialized = true;
        });
      }
    }
  }
}

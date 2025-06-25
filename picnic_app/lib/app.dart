import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_app/generated/l10n.dart';
import 'package:picnic_app/main.dart' as main_file;
import 'package:picnic_app/presentation/screens/portal.dart';
import 'package:picnic_lib/core/utils/app_builder.dart';
import 'package:picnic_lib/core/utils/app_initializer.dart';
import 'package:picnic_lib/core/utils/app_lifecycle_initializer.dart';
import 'package:picnic_lib/core/utils/language_manager.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/core/utils/main_initializer.dart';
import 'package:picnic_lib/core/utils/route_manager.dart';
import 'package:picnic_lib/enums.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/presentation/common/navigator_key.dart';
import 'package:picnic_lib/presentation/dialogs/force_update_overlay.dart';
import 'package:picnic_lib/presentation/dialogs/update_dialog.dart';
import 'package:picnic_lib/presentation/providers/app_initialization_provider.dart';
import 'package:picnic_lib/presentation/providers/app_setting_provider.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/providers/check_update_provider.dart';
import 'package:picnic_lib/presentation/providers/patch_info_provider.dart';
import 'package:picnic_lib/presentation/screens/ban_screen.dart';
import 'package:picnic_lib/presentation/screens/network_error_screen.dart';
import 'package:picnic_lib/presentation/widgets/splash_image.dart';
import 'package:picnic_lib/ui/community_theme.dart';
import 'package:picnic_lib/ui/mypage_theme.dart';
import 'package:picnic_lib/ui/novel_theme.dart';
import 'package:picnic_lib/ui/pic_theme.dart';
import 'package:picnic_lib/ui/vote_theme.dart';
import 'package:picnic_lib/core/config/environment.dart';
import 'package:picnic_lib/services/localization_service.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'package:picnic_lib/ui/style.dart';

class App extends ConsumerStatefulWidget {
  const App({super.key});

  @override
  createState() => _AppState();
}

class _AppState extends ConsumerState<App> with WidgetsBindingObserver {
  Widget? initScreen;
  StreamSubscription? _authSubscription;
  StreamSubscription? _appLinksSubscription;

  // 앱이 이미 초기화되었는지 여부를 추적하는 플래그
  bool _isAppInitialized = false;
  
  // 패치 상태 메시지
  String? _patchStatusMessage;
  
  // 업데이트 정보
  Map<String, dynamic>? _updateInfo;
  
  // 업데이트 다이얼로그 표시 여부
  bool _updateDialogShown = false;
  
  // 업데이트 적용 대기 시간 (밀리초)
  Timer? _updateTimer;
  
  // 앱 비활성 상태 추적
  bool _isAppInactive = false;
  DateTime? _lastUserInteraction;
  
  // 현재 화면이 Portal(메인 화면)인지 추적
  bool _isOnMainScreen = false;

  // 스캐폴드 메신저 키
  final GlobalKey<ScaffoldMessengerState> _scaffoldKey =
      GlobalKey<ScaffoldMessengerState>();

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

    // 라우트 설정
    AppLifecycleInitializer.setupAppRoutes(ref, _appSpecificRoutes);

    // 기존 코드의 나머지 부분은 유지
    WidgetsBinding.instance.addObserver(this);
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    logger.i('_initializeApp 시작');

    // 앱이 이미 초기화되었다면 바로 반환
    if (_isAppInitialized) {
      logger.i('앱이 이미 초기화됨. 초기화 과정 스킵');
      return;
    }

    try {
      // 컨텍스트 없이 실행 가능한 초기화 부분
      await _initializeAppBasics();

      // mounted 상태 확인
      if (!mounted) {
        logger.e('앱 초기화 중 위젯이 dispose됨');
        return;
      }

      // 컨텍스트가 필요한 부분 동기적으로 실행
      _initializeAppWithContext();

      logger.i('_initializeApp 완료');
    } catch (e, stackTrace) {
      logger.e('앱 초기화 중 오류 발생', error: e, stackTrace: stackTrace);
      if (mounted) {
        setState(() {
          _isAppInitialized = false;
        });
      }
    }
  }

  // 컨텍스트가 필요 없는 초기화 작업
  Future<void> _initializeAppBasics() async {
    // 기본 초기화
    logger.i('기본 초기화 시작');
    await AppInitializer.initializeBasics();
    logger.i('기본 초기화 완료');

    // 환경 초기화
    logger.i('환경 초기화 시작');
    await AppInitializer.initializeEnvironment(Environment.currentEnvironment);
    logger.i('환경 초기화 완료');

    // 시스템 UI 초기화
    logger.i('시스템 UI 초기화 시작');
    await AppInitializer.initializeSystemUI();
    logger.i('시스템 UI 초기화 완료');

    // 언어 및 국제화 초기화
    await _initializeLanguage();
    logger.i('언어 및 국제화 초기화 완료');
  }

  // 컨텍스트가 필요한 초기화 작업 (동기적으로 실행)
  void _initializeAppWithContext() {
    if (!mounted) return;

    // 앱 초기화 (필요한 경우 Future.microtask로 래핑)
    Future.microtask(() async {
      try {
        logger.i('앱 초기화 시작 (with context)');

        // ignore: use_build_context_synchronously
        // 이 경고를 무시하는 이유: Future.microtask 내부에서 사용되는 context는
        // 하위 위젯 빌드 없이 초기화 목적으로만 사용되며, mounted 체크를 통해 안전하게 관리됨
        if (mounted) {
          // 1. 백그라운드에서 패치 체크 수행
          final updateInfo = await AppInitializer.checkPatchInBackground(
            onStatusUpdate: (message) {
              if (mounted) {
                setState(() {
                  _patchStatusMessage = message;
                });
              }
            },
          );
          
          // 패치 체크 완료 후 메시지 초기화 및 Provider 업데이트
          if (mounted) {
            setState(() {
              _patchStatusMessage = null;
              _updateInfo = updateInfo;
            });
            
            // 패치 정보 Provider 업데이트
            ref.read(patchInfoProvider.notifier).updatePatchInfo(updateInfo);
          }
          
          // 2. 일반 앱 초기화 진행
          await AppInitializer.initializeAppWithSplash(context, ref);
        }

        logger.i('앱 초기화 완료 (with context)');

        if (!mounted) return;

        // 최종 언어가 제대로 설정되었는지 확인
        final currentLanguage = ref.read(appSettingProvider).language;
        logger.i('앱 초기화 완료 후 최종 언어 확인: $currentLanguage');

        setState(() {
          _isAppInitialized = true;
          logger.i('_isAppInitialized 상태를 true로 변경, 앱 UI 리빌드 트리거');
        });
      } catch (e) {
        logger.e('컨텍스트 초기화 중 오류 발생', error: e);
        if (mounted) {
          setState(() {
            _isAppInitialized = false;
          });
        }
      }
    });
  }

  /// 앱 재시작 처리 로직
  Future<void> _performAppRestart() async {
    if (!mounted) return;

    try {
      logger.i('Phoenix.rebirth를 통한 앱 재시작 시도');

      // 현재 컨텍스트 유효성 확인
      if (!context.mounted) {
        logger.e('Phoenix.rebirth 시도 시 컨텍스트가 유효하지 않음');
        return;
      }

      // 최상위 네비게이터 컨텍스트 사용
      final navigatorContext = Navigator.of(context, rootNavigator: true).context;

      // 현재 프레임 완료 후 재시작 실행
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (navigatorContext.mounted && mounted) {
          try {
            Phoenix.rebirth(navigatorContext);
            logger.i('Phoenix.rebirth 성공적으로 호출됨');
          } catch (e) {
            logger.e('Phoenix.rebirth 실행 중 오류: $e');
          }
        } else {
          logger.w('Phoenix.rebirth 시도 시 네비게이터 컨텍스트가 유효하지 않음');
        }
      });

    } catch (e) {
      logger.e('앱 재시작 처리 중 오류: $e');
    }
  }

  // 언어 초기화를 위한 별도 메서드
  Future<void> _initializeLanguage() async {
    logger.i('언어 초기화 시작 (picnic_app)');

    try {
      // 먼저 앱 설정이 로드될 때까지 대기
      await ref.read(appSettingProvider.notifier).loadSettings();
      logger.i('앱 설정 로드 완료');

      // MainInitializer를 사용하여 언어 초기화
      await MainInitializer.initializeLanguageAsync(
        ref,
        context,
        S.load,
        (success, language) {
          logger.i('언어 초기화 콜백 호출: 성공=$success, 언어=$language');

          // main.dart의 전역 변수 업데이트
          main_file.isLanguageInitialized = success;
          main_file.currentLanguage = language;

          // 앱 설정에 언어 반영
          if (success) {
            ref.read(appSettingProvider.notifier).setLanguage(language);

            // PicnicLibL10n 명시적 초기화 시도
            try {
              final appSetting = ref.read(appSettingProvider);
              PicnicLibL10n.initialize(appSetting);
              logger.i('PicnicLibL10n 명시적 초기화 완료 (picnic_app)');
            } catch (e) {
              logger.e('PicnicLibL10n 명시적 초기화 실패 (picnic_app)', error: e);
              // 실패해도 계속 진행 (t 메서드가 대체 값을 반환하도록 개선됨)
            }
          }
        },
      );

      logger.i('언어 초기화 완료 (picnic_app)');
    } catch (e, stackTrace) {
      logger.e('언어 초기화 중 오류 발생 (picnic_app)', error: e, stackTrace: stackTrace);
      // 오류 발생 시에도 기본값으로 설정
      main_file.isLanguageInitialized = false;
      main_file.currentLanguage = 'ko';
    }
  }

  @override
  Widget build(BuildContext context) {
    // 사용자 상호작용 추적
    _lastUserInteraction = DateTime.now();
    
    final initState = ref.watch(appInitializationProvider);
    final appSettingState = ref.watch(appSettingProvider);

    // 언어 변경 감지 리스너
    ref.listen<Setting>(
      appSettingProvider,
      (previous, current) {
        if (previous?.language != current.language) {
          logger.i('언어 변경 감지: ${previous?.language} -> ${current.language}');

          // LanguageManager를 사용하여 언어 변경 처리
          _applyLanguageChange(current.language);
        }
      },
    );

    // 화면 보호기 상태 감지 및 처리
    final isScreenProtector = false; // 필요한 경우 Provider 추가
    AppBuilder.updateScreenProtector(isScreenProtector);

    Widget currentScreen;
    if (!_isAppInitialized) {
      logger.i('앱이 초기화되지 않음 - 스플래시 화면 표시');
      currentScreen = SplashImage(statusMessage: _patchStatusMessage);
      _isOnMainScreen = false;
    } else if (!initState.hasNetwork) {
      logger.i('네트워크 오류 - 네트워크 오류 화면 표시');
      currentScreen = NetworkErrorScreen(onRetry: _retryConnection);
      _isOnMainScreen = false;
    } else if (initState.isBanned) {
      logger.i('밴 상태 - 밴 화면 표시');
      currentScreen = const BanScreen();
      _isOnMainScreen = false;
    } else if (initState.updateInfo?.status == UpdateStatus.updateRequired) {
      logger.i('업데이트 필요 - 업데이트 화면 표시');
      currentScreen = ForceUpdateOverlay(updateInfo: initState.updateInfo!);
      _isOnMainScreen = false;
    } else {
      logger.i('정상 상태 - 포털 화면 표시');
      currentScreen = const Portal();
      
      // 메인 화면 상태 업데이트
      if (!_isOnMainScreen) {
        _isOnMainScreen = true;
        logger.i('메인 화면(Portal) 진입 감지');
      }
      
      // 메인 화면에서만 업데이트 적용 스케줄링
      if (_updateInfo?['needsRestart'] == true && !_updateDialogShown) {
        _updateDialogShown = true;
        logger.i('메인 화면에서 업데이트 스케줄링 시작');
        _scheduleUpdateApplication();
      }
    }

    // 현재 언어 정보 로깅
    final currentLocale = Locale(appSettingState.language);
    logger.i('현재 언어: ${currentLocale.languageCode}');

    // 라우트 처리
    final routes = RouteManager.mergeRoutes(_appSpecificRoutes);

    // AppBuilder를 사용하여 앱 UI 구성
    return AppBuilder.buildApp(
      navigatorKey: navigatorKey,
      scaffoldKey: _scaffoldKey,
      routes: routes,
      title: 'PICNIC',
      theme: _getCurrentTheme(ref),
      home: UpdateDialog(child: currentScreen),
      localizationsDelegates: [
        ...LocalizationService.localizationDelegates,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: _supportedLocales,
      locale: currentLocale,
      enableScreenProtector: isScreenProtector,
    );
  }

  Future<void> _retryConnection() async {
    await AppInitializer.retryConnection(ref);
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

  Future<void> _applyLanguageChange(String language) async {
    try {
      logger.i('언어 변경 시작: $language');

      // mounted 상태 확인 및 UI 상태 변경
      if (!mounted) return;

      // UI 상태 업데이트 - 로딩 화면 표시
      setState(() {
        _isAppInitialized = false;
        logger.i('언어 변경 중 일시적으로 스플래시 화면으로 전환');
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

  /// 업데이트 적용 스케줄링
  void _scheduleUpdateApplication() {
    if (!mounted) return;
    
    logger.i('업데이트 스케줄링 시작 - 안정된 시점에 자동 적용');
    // 모든 패치를 안정된 시점에 적용
    _scheduleStableUpdate();
  }

  /// 안정된 시점에 업데이트 스케줄링
  void _scheduleStableUpdate() {
    if (!mounted) return;
    
    logger.i('업데이트 스케줄링 시작 - 15초 후 안정된 시점 체크');
    
    // 사용자 상호작용 추적 시작
    _lastUserInteraction = DateTime.now();
    
    // 15초 후 첫 번째 시도 (30초 → 15초로 단축)
    _updateTimer = Timer(const Duration(seconds: 15), () {
      _attemptStableUpdate();
    });
  }

  /// 안정된 시점에 업데이트 시도
  void _attemptStableUpdate() {
    if (!mounted) return;
    
    // 메인 화면이 아니면 업데이트 적용하지 않음
    if (!_isOnMainScreen) {
      logger.i('메인 화면이 아님 - 업데이트 적용 대기 중 (5초 후 재시도)');
      _updateTimer = Timer(const Duration(seconds: 5), () {
        _attemptStableUpdate();
      });
      return;
    }
    
    final now = DateTime.now();
    final timeSinceLastInteraction = _lastUserInteraction != null
        ? now.difference(_lastUserInteraction!)
        : Duration.zero;
    
    // 조건 확인: 
    // 1. 앱이 백그라운드 상태이거나
    // 2. 10초 이상 사용자 상호작용이 없었거나 (15초 → 10초로 단축)
    // 3. 앱이 비활성 상태일 때
    // 4. 메인 화면(Portal)일 때만
    if (_isAppInactive || 
        timeSinceLastInteraction.inSeconds > 10 ||
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.paused) {
      
      logger.i('메인 화면에서 안정된 시점 감지됨 (비활성 ${timeSinceLastInteraction.inSeconds}초), 업데이트 적용');
      _showUpdateNotification();
      
      // 3초 후 재시작
      Timer(const Duration(seconds: 3), () {
        if (mounted) {
          _applyUpdateAndRestart();
        }
      });
      
    } else {
      // 아직 안정되지 않았으면 5초 후 다시 시도 (10초 → 5초로 단축)
      logger.i('메인 화면이지만 아직 안정되지 않음 (비활성 ${timeSinceLastInteraction.inSeconds}초 < 10초), 5초 후 재시도');
      _updateTimer = Timer(const Duration(seconds: 5), () {
        _attemptStableUpdate();
      });
    }
  }

  /// 업데이트 노티피케이션 표시
  void _showUpdateNotification() {
    if (!mounted) return;
    
    _scaffoldKey.currentState?.showSnackBar(
      SnackBar(
        content: const Text('📱 App update applying in 3 seconds...'),
        duration: const Duration(seconds: 3),
        backgroundColor: AppColors.primary500,
      ),
    );
  }

  /// 업데이트 적용 및 재시작
  Future<void> _applyUpdateAndRestart() async {
    if (!mounted) return;
    
    // 재시작 진행 중임을 표시
    setState(() {
      _patchStatusMessage = 'Applying update...';
      _isAppInitialized = false; // 스플래시 화면으로 전환
    });
    
    // 잠시 대기 후 재시작
    await Future.delayed(const Duration(milliseconds: 500));
    await _performAppRestart();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    // 업데이트 타이머 정리
    _updateTimer?.cancel();

    // 앱 리스너 정리
    AppLifecycleInitializer.disposeAppListeners(
      _authSubscription,
      _appLinksSubscription,
    );

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    logger.i('앱 생명주기 상태 변경: $state');

    switch (state) {
      case AppLifecycleState.resumed:
        // 앱이 포그라운드로 돌아올 때
        _isAppInactive = false;
        _lastUserInteraction = DateTime.now();
        break;
      case AppLifecycleState.inactive:
        // 앱이 비활성화될 때
        _isAppInactive = true;
        break;
      case AppLifecycleState.paused:
        // 앱이 백그라운드로 전환될 때
        _isAppInactive = true;
        // 메인 화면에서만 백그라운드 상태에서 업데이트 적용 시도
        if (_updateInfo?['needsRestart'] == true && _isOnMainScreen) {
          logger.i('메인 화면에서 백그라운드 전환 - 업데이트 적용 시도');
          _attemptStableUpdate();
        } else if (_updateInfo?['needsRestart'] == true) {
          logger.i('메인 화면이 아닌 상태에서 백그라운드 전환 - 업데이트 적용 대기');
        }
        break;
      case AppLifecycleState.detached:
        // 앱이 분리될 때
        _isAppInactive = true;
        break;
      default:
        break;
    }
  }
}

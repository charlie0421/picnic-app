// Run only through scripts/qa/run_notification_delivery_ios.py. The runner
// copies this file to lib/notification_delivery_ios_qa.dart (and
// notification_delivery/ next to it) in a generated QA app,
// io.picnic.qa.notificationDelivery, builds it for one owned iOS simulator,
// installs it and launches it with `simctl launch`. It is a regular runApp
// app, not a flutter test: the person who runs the QA operates the simulator
// GUI (permission sheet, Home, notification tap, list filters).
//
// Path under test (all product code, nothing replaced):
//   native UNUserNotificationCenter response -> FLTFirebaseMessagingPlugin
//   -> FirebaseMessaging.onMessageOpenedApp (the real stream)
//   -> PushTokenInitializationCoordinator (product)
//   -> PushTokenService.debugHandleNotificationTap (product tap dispatch)
//   -> AppInitializer.buildPushTapHandler (product) -> DeepLinkHandler
//   -> NavigationInfo -> VoteListPage / VoteList / AsyncVoteList provider.
// The QA app never adds an opened event itself and never navigates itself.
//
// Controlled boundaries (and nothing else):
// - Push dependencies: PushTokenService.debugUseCoordinatorFactory supplies
//   the real coordinator. Permission (requestPermission and
//   getNotificationSettings), the initial message and both message streams
//   are the real FirebaseMessaging calls. The FCM token is always null; the
//   topic subscription and backend registration are no-ops. Local
//   notification setup is skipped. Nothing here registers for APNs.
// - Backend: Environment.initTestConfig and testSupabaseClient point at an
//   in-process 127.0.0.1 server that serves synthetic votes. No session
//   exists, so the app is signed out.
// - Firebase: demo options that name no real project. Messaging auto-init
//   is off in Info.plist (the runner checks it).
//
// Not covered: the full App, Portal, startup retry, the production push
// coordinator (_createCoordinator), cold start from a notification, real
// APNs/FCM delivery, token registration, and native SDK network traffic.
//
// Evidence: every step is appended to Library/Caches/notification-delivery-
// ios.json in the app data container. The directory comes from the platform
// path provider (getTemporaryDirectory); the locked path_provider_foundation
// 2.6.0 answers it with NSCachesDirectory, which is Library/Caches, not tmp/.
// A provider directory that is not Library/Caches stops the app, because the
// runner reads only that location. Each write replaces the whole file atomically
// (temporary file, then rename). The runner validates the order, the run
// nonce, the process ID and the full message ID. The run nonce is compiled
// into this per-run build (--dart-define=PICNIC_QA_RUN_NONCE=<nonce>) and read
// with String.fromEnvironment; the launch environment does not carry it. A
// missing or malformed nonce is recorded as null, and the runner refuses it.
//
// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
// picnic_lib depends on path_provider; only the temporary directory is read.
// ignore: depend_on_referenced_packages
import 'package:path_provider/path_provider.dart';
import 'package:picnic_lib/core/config/environment.dart';
import 'package:picnic_lib/core/services/push_token_initialization_coordinator.dart';
import 'package:picnic_lib/core/services/push_token_service.dart';
import 'package:picnic_lib/core/utils/app_builder.dart';
import 'package:picnic_lib/core/utils/app_initializer.dart';
import 'package:picnic_lib/data/models/common/navigation.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/common/navigator_key.dart';
import 'package:picnic_lib/presentation/pages/vote/vote_list_page.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/providers/vote_list_provider.dart';
import 'package:picnic_lib/presentation/widgets/ui/picnic_filter_chip.dart';
import 'package:picnic_lib/presentation/widgets/vote/list/vote_info_card.dart';
import 'package:picnic_lib/presentation/widgets/vote/list/vote_list.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'notification_delivery/vote_list_loopback.dart';

/// Shared with the runner (run_notification_delivery_ios.py).
const evidenceSchema = 'picnic-notification-delivery-ios/1';
const evidenceFileName = 'notification-delivery-ios.json';
const evidenceDirectory = 'Library/Caches'; // In the app data container.
/// The run nonce compiled into this build by the runner (empty if absent).
const _compiledRunNonce = String.fromEnvironment('PICNIC_QA_RUN_NONCE');
const beforeMarker = 'qa-notification-delivery-before';
const maxEvents = 400;

const _bundleId = 'io.picnic.qa.notificationDelivery';

/// Demo values only. They identify no real Firebase project.
const _demoOptions = FirebaseOptions(
  // Synthetic. It only matches the format native Firebase Installations
  // checks at configure time; it is not a usable credential.
  apiKey: 'AqaDemoApiKeyNotAValidCredential0000000',
  appId: '1:000000000000:ios:0000000000000000',
  messagingSenderId: '000000000000',
  projectId: 'picnic-qa-demo',
  iosBundleId: _bundleId,
);

final _nonceFormat = RegExp(r'^[0-9a-f]{32}$');

/// Appends events and rewrites the evidence file after each one.
class QaEvidence {
  QaEvidence._(this.path, this.runNonce);

  final String path;
  final String? runNonce;
  final List<Map<String, Object?>> _events = <Map<String, Object?>>[];
  VoteListLoopback? loopback;
  bool _overflow = false;

  static Future<QaEvidence> open() async {
    // On iOS, NSCachesDirectory of the app data container (Library/Caches).
    var directory = (await getTemporaryDirectory()).path;
    while (directory.length > 1 && directory.endsWith('/')) {
      directory = directory.substring(0, directory.length - 1);
    }
    if (!directory.endsWith('/$evidenceDirectory')) {
      throw StateError(
        'the platform temporary directory is not $evidenceDirectory; the '
        'runner reads only <container>/$evidenceDirectory/$evidenceFileName',
      );
    }
    final nonce = _nonceFormat.hasMatch(_compiledRunNonce)
        ? _compiledRunNonce
        : null;
    return QaEvidence._('$directory/$evidenceFileName', nonce);
  }

  void record(String type, [Map<String, Object?> fields = const {}]) {
    if (_overflow) return;
    if (_events.length >= maxEvents - 1) {
      _overflow = true;
      _events.add(_event('overflow', const {}));
    } else {
      _events.add(_event(type, fields));
    }
    write();
  }

  Map<String, Object?> _event(String type, Map<String, Object?> fields) => {
        'seq': _events.length + 1,
        'wallMs': DateTime.now().millisecondsSinceEpoch,
        'type': type,
        ...fields,
      };

  /// Replaces the evidence file in one rename, so a reader never sees a
  /// partial file.
  void write() {
    final document = <String, Object?>{
      'schema': evidenceSchema,
      'runNonce': runNonce,
      'pid': pid,
      'evidencePath': path,
      'events': _events,
      'loopback': {
        'requests': loopback?.requests ?? const <Object>[],
        'unexpected': loopback?.unexpected ?? const <Object>[],
      },
    };
    try {
      final temporary = File('$path.partial');
      temporary.writeAsStringSync(jsonEncode(document), flush: true);
      temporary.renameSync(path);
    } catch (error) {
      debugPrint('QA_EVIDENCE_WRITE_FAILED ${error.runtimeType}');
    }
  }
}

String _typeName(Object? value) =>
    value == null ? 'null' : value.runtimeType.toString();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final evidence = await QaEvidence.open();
  evidence.record('launched', {'nonceValid': evidence.runNonce != null});

  final presentError = FlutterError.onError;
  FlutterError.onError = (details) {
    evidence.record('flutter_error', {
      'library': details.library,
      'exception': _typeName(details.exception),
    });
    presentError?.call(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    evidence.record('uncaught_error', {'exception': _typeName(error)});
    return true;
  };

  final loopback = await VoteListLoopback.start(log: debugPrint);
  evidence.loopback = loopback;
  loopback.onRequest = evidence.write;
  Environment.initTestConfig(syntheticQaConfig(loopback.base));
  final client = testSupabaseClient = SupabaseClient(
    loopback.base.toString(),
    qaSyntheticAnonKey,
    authOptions: const AuthClientOptions(autoRefreshToken: false),
  );
  evidence.record('auth_state', {
    'signedIn': client.auth.currentSession != null,
    'loopbackHost': loopback.base.host,
  });

  await Firebase.initializeApp(options: _demoOptions);
  final messaging = FirebaseMessaging.instance;
  evidence.record('firebase_ready', {
    'defaultApp': Firebase.apps.any((app) => app.name == defaultFirebaseAppName),
    'autoInit': messaging.isAutoInitEnabled,
  });

  PushTokenService.debugUseCoordinatorFactory(
    _ControlledPush(evidence, messaging).build,
  );
  WidgetsBinding.instance.addObserver(_LifecycleRecorder(evidence));

  runApp(ProviderScope(child: _QaApp(evidence: evidence)));
}

/// The real coordinator with the permission sheet, initial message and both
/// message streams from FirebaseMessaging. Token, topic and registration are
/// controlled.
class _ControlledPush {
  _ControlledPush(this.evidence, this.messaging);

  final QaEvidence evidence;
  final FirebaseMessaging messaging;

  static bool _authorized(AuthorizationStatus status) =>
      status == AuthorizationStatus.authorized ||
      status == AuthorizationStatus.provisional;

  PushTokenInitializationCoordinator build() {
    evidence.record('coordinator_created');
    return PushTokenInitializationCoordinator(
      PushInitializationDependencies(
        initializeLocalNotifications: () async =>
            evidence.record('local_notifications_skipped'),
        requestPermission: () async {
          evidence.record('permission_requested');
          final settings = await messaging.requestPermission(
            alert: true,
            badge: true,
            sound: true,
          );
          evidence.record('permission_result', {
            'status': settings.authorizationStatus.name,
          });
          return _authorized(settings.authorizationStatus)
              ? PushPermissionStatus.granted
              : PushPermissionStatus.denied;
        },
        checkPermission: () async {
          final settings = await messaging.getNotificationSettings();
          evidence.record('permission_check', {
            'status': settings.authorizationStatus.name,
          });
          return _authorized(settings.authorizationStatus)
              ? PushPermissionStatus.granted
              : PushPermissionStatus.denied;
        },
        getToken: () async {
          evidence.record('token_requested', {'returned': null});
          return null;
        },
        subscribeToBroadcastTopic: () async => evidence.record('topic_noop'),
        registerToken: (_) async => evidence.record('register_noop'),
        tokenRefreshes: const Stream<String>.empty(),
        foregroundMessages: FirebaseMessaging.onMessage.cast<Object>(),
        openedMessages: FirebaseMessaging.onMessageOpenedApp.cast<Object>(),
        authChanges: const Stream<Object>.empty(),
        isSignedIn: () {
          evidence.record('signed_in_checked', {'signedIn': false});
          return false;
        },
        isSignedInEvent: (_) => false,
        onForegroundMessage: (message) => evidence.record(
          'foreground_message',
          {'messageId': (message as RemoteMessage).messageId},
        ),
        onOpenedMessage: (message) {
          final remote = message as RemoteMessage;
          evidence.record('opened', {
            'messageId': remote.messageId,
            'actionUrl': remote.data['action_url'],
            'dataKeys': remote.data.keys.toList()..sort(),
          });
          PushTokenService.debugHandleNotificationTap(remote);
          evidence.record('tap_forwarded', {'messageId': remote.messageId});
        },
        getInitialMessage: () async {
          final initial = await messaging.getInitialMessage();
          evidence.record('initial_message', {
            'isNull': initial == null,
            'messageId': initial?.messageId,
          });
          return initial;
        },
        onError: (error, _) =>
            evidence.record('push_step_error', {'exception': _typeName(error)}),
      ),
    );
  }
}

class _LifecycleRecorder with WidgetsBindingObserver {
  _LifecycleRecorder(this.evidence);

  final QaEvidence evidence;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) =>
      evidence.record('lifecycle', {'state': state.name});
}

class _QaApp extends StatelessWidget {
  const _QaApp({required this.evidence});

  final QaEvidence evidence;

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: kAppDesignSize,
      minTextAdapt: true,
      splitScreenMode: kAppSplitScreenMode,
      child: MaterialApp(
        navigatorKey: navigatorKey,
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: _QaHome(evidence: evidence),
      ),
    );
  }
}

/// Starts product push initialization the way AppInitializer does, then
/// shows the top of the product vote navigation stack once it is the vote
/// list. Until then it shows a start screen that is not the vote list.
class _QaHome extends ConsumerStatefulWidget {
  const _QaHome({required this.evidence});

  final QaEvidence evidence;

  @override
  ConsumerState<_QaHome> createState() => _QaHomeState();
}

class _QaHomeState extends ConsumerState<_QaHome> {
  Timer? _treeWatch;
  String? _lastNavigation;
  String? _lastListState;

  QaEvidence get evidence => widget.evidence;

  @override
  void initState() {
    super.initState();
    evidence.record('push_initialize_started');
    unawaited(
      PushTokenService.initialize(
        onNotificationTap:
            AppInitializer.buildPushTapHandler(ref, () => mounted),
        onActionUrlTap:
            AppInitializer.buildActionUrlTapHandler(ref, () => mounted),
      ).then(
        (_) => evidence.record('push_initialize_done'),
        onError: (Object error) => evidence
            .record('push_step_error', {'exception': _typeName(error)}),
      ),
    );
    _treeWatch = Timer.periodic(
      const Duration(milliseconds: 400),
      (_) => _recordListState(),
    );
  }

  @override
  void dispose() {
    _treeWatch?.cancel();
    super.dispose();
  }

  void _recordNavigation(Navigation? navigation) {
    final stack = navigation?.voteNavigationStack;
    final top = stack == null || stack.isEmpty ? null : stack.peek();
    final fields = <String, Object?>{
      'stackTop': _typeName(top),
      'stackLength': stack?.length ?? 0,
      'portal': navigation?.portalType.name,
    };
    final key = jsonEncode(fields);
    if (key == _lastNavigation) return;
    _lastNavigation = key;
    evidence.record('navigation', fields);
  }

  /// Reads the rendered widget tree: the product page, its list widgets,
  /// the rendered vote cards and the selected filter controls.
  void _recordListState() {
    final root = WidgetsBinding.instance.rootElement;
    if (root == null) return;
    var pageMounted = false;
    final lists = <Map<String, Object?>>[];
    final cards = <int>[];
    final chips = <String>[];
    final statusValues = <String>[];
    void visit(Element element) {
      final widget = element.widget;
      if (widget is VoteListPage) pageMounted = true;
      if (widget is VoteList) {
        lists.add({'area': widget.area, 'status': widget.status.name});
      }
      if (widget is VoteInfoCard) cards.add(widget.vote.id);
      if (widget is PicnicFilterChip && widget.selected) chips.add(widget.label);
      if (widget is DropdownButton<VoteStatus>) {
        statusValues.add(widget.value?.name ?? 'null');
      }
      element.visitChildren(visit);
    }

    root.visitChildren(visit);
    if (!pageMounted) return;
    final fields = <String, Object?>{
      'voteLists': lists,
      'cardIds': cards,
      'selectedChips': chips,
      'statusValues': statusValues,
    };
    final key = jsonEncode(fields);
    if (key == _lastListState) return;
    _lastListState = key;
    evidence.record('list_state', fields);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<Navigation>(
      navigationInfoProvider,
      (_, next) => _recordNavigation(next),
    );
    final navigation = ref.watch(navigationInfoProvider);
    if (_lastNavigation == null) _recordNavigation(navigation);
    final stack = navigation.voteNavigationStack;
    final top = stack == null || stack.isEmpty ? null : stack.peek();
    if (top is VoteListPage) {
      return Scaffold(body: SafeArea(child: top));
    }
    return _BeforeScreen(
      evidence: evidence,
      stackTop: _typeName(top),
    );
  }
}

class _BeforeScreen extends StatefulWidget {
  const _BeforeScreen({required this.evidence, required this.stackTop});

  final QaEvidence evidence;
  final String stackTop;

  @override
  State<_BeforeScreen> createState() => _BeforeScreenState();
}

class _BeforeScreenState extends State<_BeforeScreen> {
  static bool _recorded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_recorded || !mounted) return;
      _recorded = true;
      widget.evidence.record('before_screen', {
        'marker': beforeMarker,
        'stackTop': widget.stackTop,
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      key: Key(beforeMarker),
      backgroundColor: Color(0xFF1D2B53),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'PICNIC QA - notification delivery\n\n'
              'Start screen (not the vote list).\n'
              'Allow notifications, press Home, then tap the notification.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ),
      ),
    );
  }
}

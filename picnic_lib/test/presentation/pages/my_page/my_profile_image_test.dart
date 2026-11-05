// Profile photo change on MyProfilePage (Sentry T4-A).
//
// The camera button runs pick -> crop -> read -> upload -> profile update.
// Each external step is held by the test, so each test decides what happens
// while a step is pending: a second press, a cancel, a failure, the page
// leaving, or the signed-in account changing.
//
// The native picker and cropper are replaced at their platform interface. The
// Supabase client is real; only its HTTP transport is a MockClient, so the
// storage upload and the user_profiles update are real SDK calls. Sentry is a
// real hub whose transport is in memory, set up like the existing Sentry
// harness tests.
// ignore_for_file: invalid_use_of_internal_member, implementation_imports
import 'dart:async';
import 'dart:convert';
import 'dart:io' show FileSystemException;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
// ignore: depend_on_referenced_packages
import 'package:image_cropper_platform_interface/image_cropper_platform_interface.dart';
// ignore: depend_on_referenced_packages
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:overlay_loading_progress/overlay_loading_progress.dart';
import 'package:picnic_lib/core/services/profile_image_diagnostics.dart';
import 'package:picnic_lib/core/services/purchase_diagnostics.dart';
import 'package:picnic_lib/core/utils/snackbar_util.dart';
import 'package:picnic_lib/data/models/user_profiles.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:picnic_lib/presentation/common/navigator_key.dart';
import 'package:picnic_lib/presentation/pages/my_page/my_profile.dart';
import 'package:picnic_lib/presentation/providers/navigation_provider.dart';
import 'package:picnic_lib/presentation/providers/user_info_provider.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:sentry_flutter/src/integrations/load_contexts_integration.dart';
import 'package:sentry_flutter/src/native/sentry_native_binding.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthClientOptions, SupabaseClient;

import '../../../helpers/host_app_asset_bundle.dart';
import '../../../helpers/ignore_image_errors.dart';
import '../../../helpers/mock_data.dart';
import '../../../helpers/mock_providers.dart';
import '../../../helpers/test_environment.dart';

const _userA = 'user-a';
const _userB = 'user-b';

/// Marks data that must never reach a Sentry event.
const _secret = 'synthetic-secret';

final _l10n = lookupAppLocalizations(const Locale('en'));

UserProfilesModel _profile(String id, {String? avatarUrl}) =>
    MockData.userProfile(id: id, avatarUrl: avatarUrl);

// --- Native picker and cropper ------------------------------------------------

class _FakePicker extends ImagePickerPlatform {
  final List<Completer<XFile?>> picks = [];

  /// Runs in the same microtask that delivers the pick result, just before
  /// the caller resumes. Auth changes made here are not delivered yet when
  /// the caller checks its owner.
  void Function()? beforeResult;

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) {
    final pick = Completer<XFile?>();
    picks.add(pick);
    // Registered before the caller's listener, so it runs first.
    pick.future.then((_) => beforeResult?.call(), onError: (Object _) {});
    return pick.future;
  }
}

class _FakeCropper extends ImageCropperPlatform {
  final List<Completer<CroppedFile?>> crops = [];

  @override
  Future<CroppedFile?> cropImage({
    required String sourcePath,
    int? maxWidth,
    int? maxHeight,
    CropAspectRatio? aspectRatio,
    ImageCompressFormat compressFormat = ImageCompressFormat.jpg,
    int compressQuality = 90,
    List<PlatformUiSettings>? uiSettings,
  }) {
    final crop = Completer<CroppedFile?>();
    crops.add(crop);
    return crop.future;
  }

  @override
  Future<CroppedFile?> recoverImage() async => null;
}

/// A cropped file whose bytes come from memory, so no disk I/O runs under the
/// fake clock. [readError] makes the production read step fail.
class _MemoryCroppedFile extends CroppedFile {
  _MemoryCroppedFile({this.readError})
    : super('/synthetic/$_secret/cropped.jpg');

  final Object? readError;

  @override
  Future<Uint8List> readAsBytes() async {
    if (readError != null) throw readError!;
    return Uint8List.fromList(const [0xff, 0xd8, 0xff, 0xd9]);
  }
}

// --- Supabase HTTP backend ----------------------------------------------------

String _encode(Object value) =>
    base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');

/// A synthetic, unexpired session for [userId]. No network is needed to
/// install it with recoverSession.
Map<String, dynamic> _session(String userId, String tag) {
  final expiry =
      DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
      1000;
  return {
    'access_token':
        '${_encode({'alg': 'HS256', 'typ': 'JWT'})}.'
        '${_encode({'sub': userId, 'exp': expiry, 'role': 'authenticated'})}'
        '.qa-synthetic-$tag',
    'token_type': 'bearer',
    'expires_in': 3600,
    'expires_at': expiry,
    'refresh_token': 'qa-synthetic-refresh-$tag',
    'user': {
      'id': userId,
      'aud': 'authenticated',
      'role': 'authenticated',
      'app_metadata': <String, dynamic>{},
      'user_metadata': <String, dynamic>{},
      'created_at': '2026-11-01T00:00:00Z',
    },
  };
}

class _Backend {
  _Backend() {
    transport = MockClient(_handle);
  }

  late final http.Client transport;

  /// Paths of storage uploads, in order.
  final List<String> uploads = [];

  /// Query strings of user_profiles PATCH requests, in order.
  final List<String> profileUpdates = [];

  /// When set, the next upload waits for the test.
  Completer<http.Response>? uploadGate;

  /// When set, the next profile update waits for the test.
  Completer<http.Response>? updateGate;

  /// Runs when the test releases [updateGate], before the response travels
  /// back through the SDK to the provider.
  void Function()? onUpdateResponse;

  /// The user the token endpoint answers for (same-account refresh).
  String tokenUser = _userA;
  int refreshes = 0;

  Future<http.Response> _handle(http.Request request) async {
    // The SDKs read the request back from the response.
    final response = await _route(request);
    return http.Response(
      response.body,
      response.statusCode,
      headers: response.headers,
      request: request,
    );
  }

  Future<http.Response> _route(http.Request request) async {
    final path = request.url.path;
    if (path.startsWith('/auth/v1/token')) {
      refreshes++;
      return _json(_session(tokenUser, 'refresh-$refreshes'), 200);
    }
    if (path.startsWith('/auth/v1/logout')) {
      return http.Response('', 204);
    }
    if (path.startsWith('/storage/v1/object/') && request.method == 'POST') {
      uploads.add(path);
      final transportError = uploadTransportError;
      uploadTransportError = null;
      if (transportError != null) throw transportError;
      final gate = uploadGate;
      uploadGate = null;
      if (gate != null) return gate.future;
      return uploadOk(path);
    }
    if (path == '/rest/v1/user_profiles' && request.method == 'PATCH') {
      profileUpdates.add(request.url.query);
      final gate = updateGate;
      updateGate = null;
      if (gate != null) {
        return gate.future.then((response) {
          onUpdateResponse?.call();
          return response;
        });
      }
      return http.Response('', 204);
    }
    return http.Response('unexpected request', 500);
  }

  static http.Response _json(Object body, int status) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json'},
  );

  /// When set, the next upload fails in the transport with this error.
  Object? uploadTransportError;

  static http.Response uploadOk(String path) => _json({
    'Key': path.substring('/storage/v1/object/'.length),
    'Id': 'synthetic-object-id',
  }, 200);

  /// A storage rejection whose body carries the owner path and a secret.
  /// [statusCode] is the body field the SDK copies into its error code.
  static http.Response uploadRejected({String statusCode = '403'}) => _json({
    'statusCode': statusCode,
    'error': 'Unauthorized',
    'message': 'denied for avatars/$_userA/$_secret',
  }, 403);

  /// A PostgREST error body. The SDK copies [code] into its error code.
  static http.Response updateRejected(String code, int status) => _json({
    'code': code,
    'message': 'denied for $_userA',
    'details': null,
    'hint': null,
  }, status);
}

SupabaseClient _newClient(_Backend backend) => SupabaseClient(
  'http://localhost:54321',
  'test-anon-key-for-testing-purposes-only',
  httpClient: backend.transport,
  authOptions: const AuthClientOptions(autoRefreshToken: false),
);

Future<SupabaseClient> _signedInClient(_Backend backend, String userId) async {
  final client = _newClient(backend);
  await client.auth.recoverSession(jsonEncode(_session(userId, 'initial')));
  return client;
}

// --- Sentry -------------------------------------------------------------------

/// Marks data that the native SDK or another enricher adds to every event.
const _nativeSecret = 'native-secret';

/// What the transport received: the serialized event and the file names of
/// the attachments in the same envelope.
class _SentEnvelope {
  _SentEnvelope(this.event, this.attachments);

  final Map<String, dynamic> event;
  final List<String> attachments;
}

class _EnvelopeTransport implements Transport {
  final List<_SentEnvelope> sent = [];

  @override
  Future<SentryId?> send(SentryEnvelope envelope) async {
    Map<String, dynamic>? event;
    final attachments = <String>[];
    for (final item in envelope.items) {
      final type = item.header.type;
      if (type == 'event') {
        final data = await item.dataFactory();
        event = jsonDecode(utf8.decode(data)) as Map<String, dynamic>;
      } else if (type == 'attachment') {
        attachments.add(item.header.fileName ?? '');
      }
    }
    if (event != null) sent.add(_SentEnvelope(event, attachments));
    return envelope.header.eventId;
  }
}

/// The native SDK's scope, as LoadContextsIntegration reads it on iOS and
/// Android. Every value is synthetic.
class _FakeNative extends Fake implements SentryNativeBinding {
  @override
  bool get supportsLoadContexts => true;

  @override
  FutureOr<Map<String, dynamic>?> loadContexts() => {
    'contexts': {
      'device': {
        'name': '$_nativeSecret-device-name',
        'model': 'iPhone15,2',
        'family': 'iOS',
        'simulator': false,
      },
      'os': {'name': 'iOS', 'version': '18.0'},
      'app': {
        'app_version': '1.3.6',
        'app_build': '130602',
        'device_app_hash': '$_nativeSecret-app-hash',
      },
      'culture': {'timezone': '$_nativeSecret-timezone'},
    },
    'tags': {'native_tag': _nativeSecret},
    'extra': {'native_extra': _nativeSecret},
    'user': {'id': '$_nativeSecret-install', 'email': 'n@native-secret.test'},
    'fingerprint': [_nativeSecret],
    'breadcrumbs': [
      {
        'message': '$_nativeSecret-breadcrumb',
        'category': 'log',
        'level': 'info',
        'timestamp': '2026-11-01T00:00:00.000Z',
      },
    ],
  };
}

/// Another enricher: it adds request data, a server name and a screenshot
/// of the selected photo to every event.
class _Enricher implements EventProcessor {
  @override
  SentryEvent? apply(SentryEvent event, Hint hint) {
    hint.screenshot = SentryAttachment.fromIntList(const [1, 2], 'screen.png');
    hint.viewHierarchy = SentryAttachment.fromIntList(const [3], 'view.json');
    hint.attachments.add(
      SentryAttachment.fromIntList(const [4], 'hint-photo.jpg'),
    );
    return event
      ..serverName = '$_nativeSecret-host'
      ..request = SentryRequest(url: 'https://cdn.test/$_nativeSecret.jpg');
  }
}

/// Fills the global scope with data a profile image report must not carry.
FutureOr<void> _contaminateScope() => Sentry.configureScope((scope) async {
  await scope.setTag('scope_tag', _secret);
  // ignore: deprecated_member_use
  await scope.setExtra('scope_extra', _secret);
  await scope.setUser(SentryUser(id: _userA, email: 'a@$_secret.test'));
  await scope.addBreadcrumb(Breadcrumb(message: '$_secret-breadcrumb'));
  await scope.setContexts('picnic_private', {'path': '/private/$_secret'});
  scope.transaction = '/profile/$_secret';
  scope.addAttachment(
    SentryAttachment.fromIntList(const [5], 'scope-photo.jpg'),
  );
});

/// A real Sentry hub with the real native-contexts integration. Only the
/// native binding, one enricher and the HTTP transport are fakes.
class _SentryRecorder {
  /// Events as `beforeSend` returned them.
  final List<SentryEvent> events = [];
  final transport = _EnvelopeTransport();

  Future<void> start() async {
    final options = SentryFlutterOptions()
      ..dsn = 'https://public@o0.ingest.sentry.io/0'
      ..automatedTestMode = true
      ..transport = transport
      ..autoInitializeNativeSdk = false
      ..enableDartSymbolication = false
      ..enableDeduplication = false
      // The same calls, in the same order, as AppInitializer.initializeSentry.
      ..beforeSend = (event, hint) {
        event = PurchaseDiagnostics.sanitizeForSend(event, hint);
        event = ProfileImageDiagnostics.sanitizeForSend(event, hint);
        events.add(event);
        return event;
      };
    options
      ..addIntegration(LoadContextsIntegration(_FakeNative()))
      ..addEventProcessor(_Enricher());
    await Sentry.init((o) => o.debug = false, options: options);
  }

  Future<void> stop() => Sentry.close();
}

// --- Harness ------------------------------------------------------------------

class _TestUserInfo extends MockUserInfo {
  _TestUserInfo(super.profile);

  /// Stands in for the app replacing the profile after an account change.
  void show(UserProfilesModel? profile) => state = AsyncData(profile);
}

class _Harness {
  _Harness(this.userInfo);

  final _TestUserInfo userInfo;
  final showPage = ValueNotifier<bool>(true);

  Widget build() => ProviderScope(
    overrides: [
      navigationInfoProvider.overrideWith(
        () => MockNavigationInfo(MockData.navigation()),
      ),
      userInfoProvider.overrideWith(() => userInfo),
    ],
    child: ScreenUtilInit(
      designSize: const Size(375, 812),
      child: MaterialApp(
        navigatorKey: navigatorKey,
        scaffoldMessengerKey: SnackbarUtil.scaffoldMessengerKey,
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) =>
            DefaultAssetBundle(bundle: hostAppAssetBundle, child: child!),
        home: Scaffold(
          body: ValueListenableBuilder<bool>(
            valueListenable: showPage,
            builder: (_, show, _) =>
                show ? const MyProfilePage() : const SizedBox.shrink(),
          ),
        ),
      ),
    ),
  );

  UserProfilesModel? get profile => userInfo.state.value;
}

final _camera = find.ancestor(
  of: find.byTooltip(_l10n.profile_photo_change),
  matching: find.byType(IconButton),
);

/// The loading overlay this flow shows while it reads, uploads and updates.
final _loading = find.byType(CircularProgressIndicator);

/// Host scheduling at one await boundary of the product code.
///
/// Code run in [zone] behaves as usual. After [armed] is set, a microtask
/// that [frame] schedules for itself is the continuation of an await on a
/// future that has already completed, for example the result of an owner
/// confirmation. The zone skips the first [skip] of them. Just before the
/// next one, it queues [inject] once. The continuation and its value stay
/// unchanged.
///
/// This proves only what a callback queued in that gap can do. It is not
/// evidence of native or OS timing.
class _AwaitBoundary {
  _AwaitBoundary(this.frame, this.inject, {this.skip = 0});

  /// The product frame, by member name, that schedules the continuation.
  final String frame;
  final void Function() inject;
  int skip;

  bool armed = false;
  bool get injected => _injected;
  bool _injected = false;

  /// What happened at the boundary, in order.
  final trace = <String>[];

  late final Zone zone = Zone.current.fork(
    specification: ZoneSpecification(
      scheduleMicrotask: (self, parent, zone, callback) {
        if (armed && !_injected && _scheduledBy(frame) && skip-- == 0) {
          _injected = true;
          trace.add('continuation scheduled');
          parent.scheduleMicrotask(zone, () {
            trace.add('injected');
            inject();
          });
        }
        parent.scheduleMicrotask(zone, callback);
      },
      registerUnaryCallback: <R, T>(self, parent, zone, R Function(T) f) =>
          parent.registerUnaryCallback(zone, (T value) {
            if (_injected && value is bool) trace.add('resumed with $value');
            return f(value);
          }),
    ),
  );

  /// Whether the first frame outside dart:async and this file is [frame].
  static bool _scheduledBy(String frame) {
    for (final line in StackTrace.current.toString().split('\n')) {
      if (line.trim().isEmpty ||
          line.contains('dart:async') ||
          line.contains('my_profile_image_test.dart')) {
        continue;
      }
      return line.contains(' $frame ');
    }
    return false;
  }
}

void main() {
  late _Backend backend;
  late SupabaseClient clientA;
  late _FakePicker picker;
  late _FakeCropper cropper;
  late _SentryRecorder sentry;
  late ImagePickerPlatform originalPicker;
  late ImageCropperPlatform originalCropper;

  setUp(() async {
    initTestColors();
    backend = _Backend();
    clientA = await _signedInClient(backend, _userA);
    testSupabaseClient = clientA;

    originalPicker = ImagePickerPlatform.instance;
    originalCropper = ImageCropperPlatform.instance;
    picker = _FakePicker();
    cropper = _FakeCropper();
    ImagePickerPlatform.instance = picker;
    ImageCropperPlatform.instance = cropper;

    sentry = _SentryRecorder();
    await sentry.start();
  });

  tearDown(() async {
    // OverlayLoadingProgress is a process-wide singleton. A test that ends
    // with it shown would make every later start() a no-op.
    try {
      OverlayLoadingProgress.stop();
    } catch (error) {
      debugPrint('overlay teardown ignored: $error');
    }
    ImagePickerPlatform.instance = originalPicker;
    ImageCropperPlatform.instance = originalCropper;
    testSupabaseClient = null;
    await sentry.stop();
  });

  Future<_Harness> pumpPage(
    WidgetTester tester, {
    UserProfilesModel? profile,
  }) async {
    final harness = _Harness(_TestUserInfo(profile ?? _profile(_userA)));
    addTearDown(harness.showPage.dispose);
    await pumpWidgetAndIgnoreErrors(tester, harness.build());
    await pumpAndIgnoreErrors(tester);
    expect(_camera, findsOneWidget);
    return harness;
  }

  /// Calls the camera button's real onPressed, like a tap.
  Future<void> press(WidgetTester tester) async {
    tester.widget<IconButton>(_camera).onPressed!();
    await pumpAndIgnoreErrors(tester);
  }

  /// Lets queued work, frames and the snackbar entrance run.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await pumpAndIgnoreErrors(tester, const Duration(milliseconds: 50));
    }
  }

  Future<void> completePick(WidgetTester tester, [int index = 0]) async {
    picker.picks[index].complete(XFile('/synthetic/$_secret/picked.jpg'));
    await pumpAndIgnoreErrors(tester);
  }

  Future<void> completeCrop(
    WidgetTester tester, {
    int index = 0,
    Object? readError,
  }) async {
    cropper.crops[index].complete(_MemoryCroppedFile(readError: readError));
    await pumpAndIgnoreErrors(tester);
  }

  /// Press, pick and crop; the upload is then pending on [Backend.uploadGate].
  Future<Completer<http.Response>> startUpload(WidgetTester tester) async {
    final gate = backend.uploadGate = Completer<http.Response>();
    await press(tester);
    await completePick(tester);
    await completeCrop(tester);
    // One more frame: an overlay inserted after a frame becomes visible.
    await pumpAndIgnoreErrors(tester);
    expect(backend.uploads, hasLength(1), reason: 'the upload is pending');
    return gate;
  }

  /// Runs to the profile update; the update is then pending.
  Future<Completer<http.Response>> startProfileUpdate(
    WidgetTester tester,
  ) async {
    final gate = backend.updateGate = Completer<http.Response>();
    await press(tester);
    await completePick(tester);
    await completeCrop(tester);
    await settle(tester);
    expect(backend.profileUpdates, hasLength(1), reason: 'update pending');
    return gate;
  }

  Future<void> leave(WidgetTester tester, _Harness harness) async {
    harness.showPage.value = false;
    await pumpAndIgnoreErrors(tester);
    expect(find.byType(MyProfilePage), findsNothing);
  }

  /// Moves the SAME client to [userId] and waits until the event arrived.
  Future<void> deliverAuth(WidgetTester tester, String userId) async {
    await tester.runAsync(
      () => clientA.auth.recoverSession(
        jsonEncode(_session(userId, 'delivered-$userId')),
      ),
    );
    await pumpAndIgnoreErrors(tester);
    expect(clientA.auth.currentUser!.id, userId);
  }

  /// Moves the SAME client to [userId] now; its auth event is still queued.
  /// Returns the user the client reports right after the call. It may run
  /// inside a pump, so it does not call expect itself.
  String? queueAuth(String userId) {
    unawaited(
      clientA.auth.recoverSession(
        jsonEncode(_session(userId, 'queued-$userId')),
      ),
    );
    return clientA.auth.currentUser?.id;
  }

  void expectNoSnackbar() {
    expect(find.text(_l10n.common_success), findsNothing);
    expect(find.text(_l10n.common_fail), findsNothing);
  }

  /// Adds every auth event that the SAME client delivers after [boundary]
  /// is armed to its trace.
  Future<void> traceAuth(WidgetTester tester, _AwaitBoundary boundary) async {
    final events = clientA.auth.onAuthStateChange.listen((state) {
      if (boundary.armed) boundary.trace.add('auth ${state.session?.user.id}');
    });
    addTearDown(() => unawaited(events.cancel()));
    // The replay of the current session arrives before the boundary is armed.
    await pumpAndIgnoreErrors(tester);
  }

  /// The trace of an owner check that accepted, a callback queued after it,
  /// and the caller that resumed with the accepted result.
  const acceptedThenInjected = [
    'continuation scheduled',
    'injected',
    'resumed with true',
  ];

  String eventJson(SentryEvent event) => jsonEncode(event.toJson());

  group('one image operation at a time', () {
    testWidgets('two immediate presses open the native picker once', (
      tester,
    ) async {
      await pumpPage(tester);

      final onPressed = tester.widget<IconButton>(_camera).onPressed!;
      onPressed();
      onPressed();
      await pumpAndIgnoreErrors(tester);

      expect(picker.picks, hasLength(1));
    });

    testWidgets('a cancelled picker lets the next press open it again', (
      tester,
    ) async {
      await pumpPage(tester);
      await press(tester);

      picker.picks.single.complete(null);
      await settle(tester);
      await press(tester);

      expect(picker.picks, hasLength(2));
      expect(cropper.crops, isEmpty);
      expect(sentry.events, isEmpty, reason: 'a cancel is not a failure');
      expectNoSnackbar();
    });

    testWidgets('a cancelled crop lets the next press open the picker', (
      tester,
    ) async {
      await pumpPage(tester);
      await press(tester);
      await completePick(tester);

      cropper.crops.single.complete(null);
      await settle(tester);
      await press(tester);

      expect(picker.picks, hasLength(2));
      expect(backend.uploads, isEmpty);
      expect(sentry.events, isEmpty, reason: 'a cancel is not a failure');
      expectNoSnackbar();
    });

    testWidgets('a picker failure is handled, reported once without the '
        'device path, and the next press opens the picker', (tester) async {
      await pumpPage(tester);
      await press(tester);

      picker.picks.single.completeError(
        PlatformException(
          code: 'photo_access_denied',
          message: 'no access to /private/$_secret/IMG_0001.jpg',
        ),
      );
      await settle(tester);

      expect(tester.takeException(), isNull);
      expect(find.text(_l10n.common_fail), findsOneWidget);
      expect(sentry.events, hasLength(1));
      final event = sentry.events.single;
      expect(event.tags?['profile_image_phase'], 'pick');
      expect(event.tags?['profile_image_error_type'], 'PlatformException');
      expect(event.tags?['profile_image_error_code'], 'photo_access_denied');
      expect(eventJson(event), isNot(contains(_secret)));

      await press(tester);
      expect(picker.picks, hasLength(2));
    });

    testWidgets('a crop failure is handled, reported once, and the next press '
        'opens the picker', (tester) async {
      await pumpPage(tester);
      await press(tester);
      await completePick(tester);

      cropper.crops.single.completeError(
        PlatformException(
          code: 'crop_error',
          message: 'failed for /private/$_secret/IMG_0001.jpg',
        ),
      );
      await settle(tester);

      expect(tester.takeException(), isNull);
      expect(find.text(_l10n.common_fail), findsOneWidget);
      expect(sentry.events, hasLength(1));
      expect(sentry.events.single.tags?['profile_image_phase'], 'crop');
      expect(
        sentry.events.single.tags?['profile_image_error_code'],
        'crop_error',
      );
      expect(eventJson(sentry.events.single), isNot(contains(_secret)));
      expect(backend.uploads, isEmpty);

      await press(tester);
      expect(picker.picks, hasLength(2));
    });

    testWidgets('a read failure is reported once without the file path', (
      tester,
    ) async {
      await pumpPage(tester);
      await press(tester);
      await completePick(tester);

      await completeCrop(
        tester,
        readError: FileSystemException(
          'Cannot open file',
          '/private/$_secret/cropped.jpg',
        ),
      );
      await settle(tester);

      expect(tester.takeException(), isNull);
      expect(find.text(_l10n.common_fail), findsOneWidget);
      expect(_loading, findsNothing);
      expect(backend.uploads, isEmpty);
      expect(sentry.events, hasLength(1));
      expect(sentry.events.single.tags?['profile_image_phase'], 'read');
      expect(eventJson(sentry.events.single), isNot(contains(_secret)));

      await press(tester);
      expect(picker.picks, hasLength(2));
    });

    testWidgets('an upload failure shows the error, removes the loading '
        'overlay, is reported once, and allows a new attempt', (tester) async {
      await pumpPage(tester);
      final upload = await startUpload(tester);
      expect(_loading, findsOneWidget);

      upload.complete(_Backend.uploadRejected());
      await settle(tester);

      expect(tester.takeException(), isNull);
      expect(find.text(_l10n.common_fail), findsOneWidget);
      expect(_loading, findsNothing);
      expect(backend.profileUpdates, isEmpty);
      expect(sentry.events, hasLength(1));
      final event = sentry.events.single;
      expect(event.tags?['profile_image_phase'], 'upload');
      expect(event.tags?['profile_image_error_type'], 'StorageException');
      expect(event.tags?['profile_image_error_code'], '403');
      expect(eventJson(event), isNot(contains(_secret)));
      expect(eventJson(event), isNot(contains(_userA)));

      await press(tester);
      expect(picker.picks, hasLength(2));
    });
  });

  group('the reported error code comes only from a closed set', () {
    Future<SentryEvent> failPick(WidgetTester tester, String code) async {
      await pumpPage(tester);
      await press(tester);
      picker.picks.single.completeError(PlatformException(code: code));
      await settle(tester);
      expect(tester.takeException(), isNull);
      expect(find.text(_l10n.common_fail), findsOneWidget);
      expect(sentry.events, hasLength(1));
      return sentry.events.single;
    }

    Future<SentryEvent> failUpdate(
      WidgetTester tester,
      http.Response response,
    ) async {
      await pumpPage(tester);
      final update = await startProfileUpdate(tester);
      update.complete(response);
      await settle(tester);
      expect(tester.takeException(), isNull);
      expect(find.text(_l10n.common_fail), findsOneWidget);
      expect(sentry.events, hasLength(1));
      final event = sentry.events.single;
      expect(event.tags?['profile_image_phase'], 'update');
      expect(event.tags?['profile_image_error_type'], 'PostgrestException');
      return event;
    }

    testWidgets('a short platform code that is not a known code is sent as '
        'unknown', (tester) async {
      final event = await failPick(tester, _secret);

      expect(event.tags?['profile_image_error_code'], 'unknown');
      expect(eventJson(event), isNot(contains(_secret)));
    });

    testWidgets('a known platform code is kept', (tester) async {
      final event = await failPick(tester, 'multiple_request');

      expect(event.tags?['profile_image_error_code'], 'multiple_request');
    });

    testWidgets('a storage status code that is a path is sent as unknown', (
      tester,
    ) async {
      await pumpPage(tester);
      final upload = await startUpload(tester);

      upload.complete(
        _Backend.uploadRejected(statusCode: '/private/$_secret.jpg'),
      );
      await settle(tester);

      expect(tester.takeException(), isNull);
      expect(sentry.events, hasLength(1));
      final event = sentry.events.single;
      expect(event.tags?['profile_image_error_type'], 'StorageException');
      expect(event.tags?['profile_image_error_code'], 'unknown');
      expect(eventJson(event), isNot(contains(_secret)));
    });

    testWidgets('a PostgREST code that is not a known code is sent as '
        'unknown', (tester) async {
      final event = await failUpdate(
        tester,
        _Backend.updateRejected(_secret, 400),
      );

      expect(event.tags?['profile_image_error_code'], 'unknown');
      expect(eventJson(event), isNot(contains(_secret)));
      expect(eventJson(event), isNot(contains(_userA)));
    });

    testWidgets('a known PostgREST code is kept', (tester) async {
      final event = await failUpdate(
        tester,
        _Backend.updateRejected('42501', 403),
      );

      expect(event.tags?['profile_image_error_code'], '42501');
      expect(eventJson(event), isNot(contains(_userA)));
    });
  });

  group('only expected external failures are handled', () {
    /// Calls the camera button's real onPressed in a zone that records the
    /// errors nobody handled, with their stack traces.
    Future<List<(Object, StackTrace)>> pressInGuardedZone(
      WidgetTester tester,
    ) async {
      final unhandled = <(Object, StackTrace)>[];
      runZonedGuarded(
        tester.widget<IconButton>(_camera).onPressed!,
        (error, stack) => unhandled.add((error, stack)),
      );
      await pumpAndIgnoreErrors(tester);
      return unhandled;
    }

    testWidgets('a programming error in the read step reaches the zone with '
        'its stack, is not reported as a handled failure, and still '
        'releases the guard and the overlay', (tester) async {
      await pumpPage(tester);
      final unhandled = await pressInGuardedZone(tester);
      await completePick(tester);

      await completeCrop(
        tester,
        readError: StateError('synthetic programming bug'),
      );
      await settle(tester);

      expect(unhandled, hasLength(1));
      final (error, stack) = unhandled.single;
      expect(error, isA<StateError>());
      expect(stack.toString(), contains('_MemoryCroppedFile.readAsBytes'));
      expect(sentry.events, isEmpty, reason: 'not a handled failure');
      expect(find.text(_l10n.common_fail), findsNothing);
      expect(_loading, findsNothing);
      expect(tester.takeException(), isNull);

      await press(tester);
      expect(picker.picks, hasLength(2), reason: 'the guard is released');
    });

    testWidgets('an assertion error from the picker reaches the zone', (
      tester,
    ) async {
      await pumpPage(tester);
      final unhandled = await pressInGuardedZone(tester);

      picker.picks.single.completeError(AssertionError('synthetic'));
      await settle(tester);

      expect(unhandled.map((e) => e.$1), [isA<AssertionError>()]);
      expect(sentry.events, isEmpty);

      await press(tester);
      expect(picker.picks, hasLength(2));
    });

    testWidgets('an upload that returns no key is one handled storage '
        'failure', (tester) async {
      await pumpPage(tester);
      final upload = await startUpload(tester);

      upload.complete(
        _Backend._json({'Key': '', 'Id': 'synthetic-object-id'}, 200),
      );
      await settle(tester);

      expect(tester.takeException(), isNull);
      expect(find.text(_l10n.common_fail), findsOneWidget);
      expect(_loading, findsNothing);
      expect(backend.profileUpdates, isEmpty);
      expect(sentry.events, hasLength(1));
      expect(sentry.events.single.tags, {
        'profile_image_phase': 'upload',
        'profile_image_error_type': 'EmptyStorageKey',
        'profile_image_error_code': 'unknown',
      });
    });

    testWidgets('a network failure during the upload is one handled '
        'failure', (tester) async {
      await pumpPage(tester);
      backend.uploadTransportError = http.ClientException(
        'connection reset for /private/$_secret',
      );
      await press(tester);
      await completePick(tester);
      await completeCrop(tester);
      await settle(tester);

      expect(tester.takeException(), isNull);
      expect(find.text(_l10n.common_fail), findsOneWidget);
      expect(_loading, findsNothing);
      expect(sentry.events, hasLength(1));
      expect(sentry.events.single.tags?['profile_image_phase'], 'upload');
      // storage_client passes the transport error through unchanged.
      expect(
        sentry.events.single.tags?['profile_image_error_type'],
        'ClientException',
      );
      expect(eventJson(sentry.events.single), isNot(contains(_secret)));

      await press(tester);
      expect(picker.picks, hasLength(2));
    });
  });

  testWidgets('a mounted, same-account change uploads under the owner, '
      'updates the profile and shows success', (tester) async {
    final harness = await pumpPage(tester);
    final upload = await startUpload(tester);
    expect(_loading, findsOneWidget);
    // The same indicator as the OverlayLoadingProgress default it replaced.
    expect(tester.widget<CircularProgressIndicator>(_loading).strokeWidth, 3);

    final path = backend.uploads.single;
    upload.complete(_Backend.uploadOk(path));
    await settle(tester);

    expect(path, startsWith('/storage/v1/object/avatars/$_userA/avatar_'));
    expect(path, endsWith('.jpg'));
    expect(backend.profileUpdates, ['id=eq.$_userA']);
    expect(harness.profile?.id, _userA);
    expect(
      harness.profile?.avatarUrl,
      'http://localhost:54321/storage/v1/object/public/'
      '${path.substring('/storage/v1/object/'.length)}',
    );
    expect(find.text(_l10n.common_success), findsOneWidget);
    expect(_loading, findsNothing);
    expect(sentry.events, isEmpty);
    expect(tester.takeException(), isNull);

    await press(tester);
    expect(picker.picks, hasLength(2), reason: 'success releases the guard');
  });

  group('the page left while a step was pending', () {
    testWidgets('picker: the picked image is not cropped', (tester) async {
      final harness = await pumpPage(tester);
      await press(tester);

      await leave(tester, harness);
      await completePick(tester);
      await settle(tester);

      expect(tester.takeException(), isNull);
      expect(cropper.crops, isEmpty);
    });

    testWidgets('crop: the cropped image is not uploaded', (tester) async {
      final harness = await pumpPage(tester);
      await press(tester);
      await completePick(tester);

      await leave(tester, harness);
      await completeCrop(tester);
      await settle(tester);

      expect(tester.takeException(), isNull);
      expect(backend.uploads, isEmpty);
      expect(_loading, findsNothing);
    });

    testWidgets('upload: the overlay goes with the page and the profile is '
        'not updated', (tester) async {
      final harness = await pumpPage(tester);
      final upload = await startUpload(tester);

      await leave(tester, harness);
      // An entry removed while the tree is being finalized is rebuilt away
      // in the next frame. The upload is still pending here.
      await pumpAndIgnoreErrors(tester);
      expect(_loading, findsNothing, reason: 'the overlay left with the page');

      upload.complete(_Backend.uploadOk(backend.uploads.single));
      await settle(tester);

      expect(tester.takeException(), isNull);
      expect(backend.profileUpdates, isEmpty);
      expectNoSnackbar();
      expect(_loading, findsNothing);
    });

    testWidgets('profile update: no success message after the page left', (
      tester,
    ) async {
      final harness = await pumpPage(tester);
      final update = await startProfileUpdate(tester);

      await leave(tester, harness);
      update.complete(http.Response('', 204));
      await settle(tester);

      expect(tester.takeException(), isNull);
      expectNoSnackbar();
      expect(_loading, findsNothing);
    });
  });

  group('the signed-in account', () {
    testWidgets('signed out: the press opens no picker and uploads nothing', (
      tester,
    ) async {
      testSupabaseClient = _newClient(backend);
      await pumpPage(tester);

      await press(tester);
      await settle(tester);

      expect(picker.picks, isEmpty);
      expect(backend.uploads, isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('changed to B while the picker was open: no crop', (
      tester,
    ) async {
      await pumpPage(tester);
      await press(tester);

      testSupabaseClient = await tester.runAsync(
        () => _signedInClient(backend, _userB),
      );
      await completePick(tester);
      await settle(tester);

      expect(tester.takeException(), isNull);
      expect(cropper.crops, isEmpty);
    });

    testWidgets('logged out during the upload: the overlay goes when the '
        'logout arrives and the profile is not updated', (tester) async {
      await pumpPage(tester);
      final upload = await startUpload(tester);
      expect(_loading, findsOneWidget);

      await tester.runAsync(() => clientA.auth.signOut());
      await pumpAndIgnoreErrors(tester);
      expect(_loading, findsNothing);

      upload.complete(_Backend.uploadOk(backend.uploads.single));
      await settle(tester);

      expect(tester.takeException(), isNull);
      expect(backend.profileUpdates, isEmpty);
      expectNoSnackbar();
    });

    testWidgets('A to B to A delivered during the upload: the profile is not '
        'updated', (tester) async {
      await pumpPage(tester);
      final upload = await startUpload(tester);

      await deliverAuth(tester, _userB);
      await deliverAuth(tester, _userA);
      upload.complete(_Backend.uploadOk(backend.uploads.single));
      await settle(tester);

      expect(tester.takeException(), isNull);
      expect(backend.profileUpdates, isEmpty);
      expectNoSnackbar();
      expect(_loading, findsNothing);
    });

    testWidgets('A to B to A still queued when the picked image returns: no '
        'crop', (tester) async {
      await pumpPage(tester);
      await press(tester);
      final seen = <String?>[];
      final events = clientA.auth.onAuthStateChange.listen(
        (state) => seen.add(state.session?.user.id),
      );
      addTearDown(() => unawaited(events.cancel()));
      await pumpAndIgnoreErrors(tester);
      seen.clear(); // Drop the replay of the current session.

      final installed = <String?>[];
      List<String?>? seenAtSwitch;
      picker.beforeResult = () {
        installed
          ..add(queueAuth(_userB))
          ..add(queueAuth(_userA));
        seenAtSwitch = List.of(seen);
      };
      await completePick(tester);
      await settle(tester);

      expect(installed, [_userB, _userA], reason: 'sessions switched now');
      expect(seenAtSwitch, isEmpty, reason: 'no event delivered yet');
      expect(seen, containsAllInOrder([_userB, _userA]));
      expect(tester.takeException(), isNull);
      expect(cropper.crops, isEmpty);
    });

    testWidgets('a same-account session still queued when the picked image '
        'returns: the crop opens', (tester) async {
      await pumpPage(tester);
      await press(tester);

      final before = clientA.auth.currentSession;
      Object? replaced;
      picker.beforeResult = () {
        queueAuth(_userA);
        replaced = clientA.auth.currentSession;
      };
      await completePick(tester);
      await settle(tester);

      expect(identical(replaced, before), isFalse, reason: 'new session');
      expect(tester.takeException(), isNull);
      expect(cropper.crops, hasLength(1));
    });

    group('after a page owner check accepted', () {
      const page = '_SettingPageState._changeProfileImage';

      /// Presses the camera button in [boundary]'s zone, so the whole image
      /// operation runs there.
      Future<void> pressIn(WidgetTester tester, _AwaitBoundary boundary) async {
        boundary.zone.run(tester.widget<IconButton>(_camera).onPressed!);
        await pumpAndIgnoreErrors(tester);
      }

      _AwaitBoundary queuedAba({int skip = 0}) => _AwaitBoundary(page, () {
        queueAuth(_userB);
        queueAuth(_userA);
      }, skip: skip);

      void expectAbaAfterAcceptance(_AwaitBoundary boundary) {
        expect(boundary.injected, isTrue);
        expect(boundary.trace.take(3), acceptedThenInjected);
        expect(
          boundary.trace,
          containsAllInOrder([...acceptedThenInjected, 'auth $_userB']),
        );
        expect(identical(testSupabaseClient, clientA), isTrue);
      }

      testWidgets('A to B to A queued at the pick result: no crop', (
        tester,
      ) async {
        await pumpPage(tester);
        final boundary = queuedAba();
        await traceAuth(tester, boundary);
        await pressIn(tester, boundary);

        boundary.armed = true;
        await completePick(tester);
        await settle(tester);

        expectAbaAfterAcceptance(boundary);
        expect(tester.takeException(), isNull);
        expect(cropper.crops, isEmpty);
      });

      testWidgets('a same-account session queued at the pick result: the '
          'crop opens', (tester) async {
        await pumpPage(tester);
        final before = clientA.auth.currentSession;
        final boundary = _AwaitBoundary(page, () => queueAuth(_userA));
        await traceAuth(tester, boundary);
        await pressIn(tester, boundary);

        boundary.armed = true;
        await completePick(tester);
        await settle(tester);

        expect(boundary.trace.take(3), acceptedThenInjected);
        expect(identical(clientA.auth.currentSession, before), isFalse);
        expect(tester.takeException(), isNull);
        expect(cropper.crops, hasLength(1));
      });

      testWidgets('A to B to A queued at the read result: no upload', (
        tester,
      ) async {
        await pumpPage(tester);
        // After the crop, the page schedules three continuations of its own:
        // the crop owner check, the in-memory read (already complete), and
        // the read owner check. The third is the boundary.
        final boundary = queuedAba(skip: 2);
        await traceAuth(tester, boundary);
        await pressIn(tester, boundary);
        await completePick(tester);

        boundary.armed = true;
        await completeCrop(tester);
        await settle(tester);

        expectAbaAfterAcceptance(boundary);
        expect(tester.takeException(), isNull);
        expect(backend.uploads, isEmpty);
        expect(_loading, findsNothing);
      });

      testWidgets('A to B to A queued at the upload result: no profile '
          'update', (tester) async {
        await pumpPage(tester);
        final boundary = queuedAba();
        await traceAuth(tester, boundary);
        final upload = backend.uploadGate = Completer<http.Response>();
        await pressIn(tester, boundary);
        await completePick(tester);
        await completeCrop(tester);
        await pumpAndIgnoreErrors(tester);
        expect(backend.uploads, hasLength(1));

        boundary.armed = true;
        upload.complete(_Backend.uploadOk(backend.uploads.single));
        await settle(tester);

        expectAbaAfterAcceptance(boundary);
        expect(tester.takeException(), isNull);
        expect(backend.profileUpdates, isEmpty);
        expectNoSnackbar();
        expect(_loading, findsNothing);
      });

      testWidgets('A to B to A queued at the profile update result: no '
          'success message', (tester) async {
        await pumpPage(tester);
        final boundary = queuedAba();
        await traceAuth(tester, boundary);
        final update = backend.updateGate = Completer<http.Response>();
        await pressIn(tester, boundary);
        await completePick(tester);
        await completeCrop(tester);
        await settle(tester);
        expect(backend.profileUpdates, hasLength(1));

        boundary.armed = true;
        update.complete(http.Response('', 204));
        await settle(tester);

        expectAbaAfterAcceptance(boundary);
        expect(tester.takeException(), isNull);
        expectNoSnackbar();
        expect(_loading, findsNothing);
      });
    });

    testWidgets('a same-account token refresh during the upload still '
        'completes the change', (tester) async {
      final harness = await pumpPage(tester);
      final upload = await startUpload(tester);
      final before = clientA.auth.currentSession;

      await tester.runAsync(() => clientA.auth.refreshSession());
      await pumpAndIgnoreErrors(tester);
      expect(identical(clientA.auth.currentSession, before), isFalse);
      expect(clientA.auth.currentUser!.id, _userA);

      upload.complete(_Backend.uploadOk(backend.uploads.single));
      await settle(tester);

      expect(tester.takeException(), isNull);
      expect(backend.profileUpdates, ['id=eq.$_userA']);
      expect(harness.profile?.avatarUrl, contains('/avatars/$_userA/avatar_'));
      expect(find.text(_l10n.common_success), findsOneWidget);
    });
  });

  group('the profile update response arrives after the owner changed', () {
    /// Records the user of every auth event the SAME client delivers from
    /// now on. The replay of the current session is dropped.
    Future<List<String?>> recordAuthEvents(WidgetTester tester) async {
      final seen = <String?>[];
      final events = clientA.auth.onAuthStateChange.listen(
        (state) => seen.add(state.session?.user.id),
      );
      addTearDown(() => unawaited(events.cancel()));
      await pumpAndIgnoreErrors(tester);
      seen.clear();
      return seen;
    }

    testWidgets('A to B to A delivered on the same client: the later A '
        'profile keeps its avatar and no success is shown', (tester) async {
      final harness = await pumpPage(tester);
      final update = await startProfileUpdate(tester);

      await deliverAuth(tester, _userB);
      await deliverAuth(tester, _userA);
      expect(identical(testSupabaseClient, clientA), isTrue);
      final laterA = _profile(
        _userA,
        avatarUrl: 'https://cdn.test/later-a.jpg',
      );
      harness.userInfo.show(laterA);
      await pumpAndIgnoreErrors(tester);

      update.complete(http.Response('', 204));
      await settle(tester);

      expect(tester.takeException(), isNull);
      expect(backend.profileUpdates, ['id=eq.$_userA']);
      expect(harness.profile, same(laterA));
      expectNoSnackbar();
      expect(_loading, findsNothing);
    });

    testWidgets('A to B to A still queued when the profile update returns: '
        'the avatar is not applied', (tester) async {
      final harness = await pumpPage(tester);
      final before = harness.profile;
      final update = await startProfileUpdate(tester);
      final seen = await recordAuthEvents(tester);

      final installed = <String?>[];
      List<String?>? seenAtSwitch;
      backend.onUpdateResponse = () {
        installed
          ..add(queueAuth(_userB))
          ..add(queueAuth(_userA));
        seenAtSwitch = List.of(seen);
      };
      update.complete(http.Response('', 204));
      await settle(tester);

      expect(installed, [_userB, _userA], reason: 'sessions switched now');
      expect(seenAtSwitch, isEmpty, reason: 'no event delivered yet');
      expect(seen, containsAllInOrder([_userB, _userA]));
      expect(tester.takeException(), isNull);
      expect(harness.profile, same(before));
      expectNoSnackbar();
      expect(_loading, findsNothing);
    });

    /// Runs the inherited production [UserInfo.updateAvatar] in
    /// [boundary]'s zone with the PATCH held, arms [boundary], and releases
    /// the PATCH.
    Future<void> updateAvatarAcross(
      WidgetTester tester,
      _Harness harness,
      _AwaitBoundary boundary,
      String url,
    ) async {
      final gate = backend.updateGate = Completer<http.Response>();
      late Future<void> operation;
      boundary.zone.run(() {
        operation = harness.userInfo.updateAvatar(url);
      });
      await pumpAndIgnoreErrors(tester);
      expect(backend.profileUpdates, ['id=eq.$_userA']);

      boundary.armed = true;
      gate.complete(http.Response('', 204));
      await settle(tester);
      await operation;
      expect(boundary.injected, isTrue);
    }

    testWidgets('A to B to A queued after the provider owner check accepted: '
        'the later A profile keeps its avatar', (tester) async {
      final harness = await pumpPage(tester);
      final laterA = _profile(
        _userA,
        avatarUrl: 'https://cdn.test/later-a.jpg',
      );
      late final _AwaitBoundary boundary;
      boundary = _AwaitBoundary('UserInfo.updateAvatar', () {
        queueAuth(_userB);
        queueAuth(_userA);
        harness.userInfo.show(laterA);
      });
      await traceAuth(tester, boundary);

      await updateAvatarAcross(
        tester,
        harness,
        boundary,
        'https://cdn.test/old-operation.jpg',
      );

      expect(boundary.trace.take(3), acceptedThenInjected);
      expect(
        boundary.trace,
        containsAllInOrder([...acceptedThenInjected, 'auth $_userB']),
      );
      expect(identical(testSupabaseClient, clientA), isTrue);
      expect(tester.takeException(), isNull);
      expect(harness.profile, same(laterA));
    });

    testWidgets('a same-account session queued after the provider owner '
        'check accepted: the avatar is applied', (tester) async {
      final harness = await pumpPage(tester);
      final before = clientA.auth.currentSession;
      late final _AwaitBoundary boundary;
      boundary = _AwaitBoundary('UserInfo.updateAvatar', () {
        queueAuth(_userA);
      });
      await traceAuth(tester, boundary);

      await updateAvatarAcross(
        tester,
        harness,
        boundary,
        'https://cdn.test/old-operation.jpg',
      );

      expect(boundary.trace.take(3), acceptedThenInjected);
      expect(identical(clientA.auth.currentSession, before), isFalse);
      expect(tester.takeException(), isNull);
      expect(harness.profile?.avatarUrl, 'https://cdn.test/old-operation.jpg');
    });

    testWidgets('a same-account token refresh during the profile update '
        'still applies the avatar', (tester) async {
      final harness = await pumpPage(tester);
      final update = await startProfileUpdate(tester);
      final before = clientA.auth.currentSession;

      await tester.runAsync(() => clientA.auth.refreshSession());
      await pumpAndIgnoreErrors(tester);
      expect(identical(clientA.auth.currentSession, before), isFalse);
      expect(clientA.auth.currentUser!.id, _userA);

      update.complete(http.Response('', 204));
      await settle(tester);

      expect(tester.takeException(), isNull);
      expect(harness.profile?.avatarUrl, contains('/avatars/$_userA/avatar_'));
      expect(find.text(_l10n.common_success), findsOneWidget);
    });

    testWidgets('a same-account session still queued when the profile '
        'update returns: the avatar is applied', (tester) async {
      final harness = await pumpPage(tester);
      final update = await startProfileUpdate(tester);
      final before = clientA.auth.currentSession;

      Object? replaced;
      backend.onUpdateResponse = () {
        queueAuth(_userA);
        replaced = clientA.auth.currentSession;
      };
      update.complete(http.Response('', 204));
      await settle(tester);

      expect(identical(replaced, before), isFalse, reason: 'new session');
      expect(tester.takeException(), isNull);
      expect(harness.profile?.avatarUrl, contains('/avatars/$_userA/avatar_'));
      expect(find.text(_l10n.common_success), findsOneWidget);
    });

    testWidgets('switched to B: B keeps its profile and sees no success', (
      tester,
    ) async {
      final harness = await pumpPage(tester);
      final update = await startProfileUpdate(tester);

      testSupabaseClient = await tester.runAsync(
        () => _signedInClient(backend, _userB),
      );
      final profileB = _profile(_userB, avatarUrl: 'https://cdn.test/b.jpg');
      harness.userInfo.show(profileB);
      await pumpAndIgnoreErrors(tester);

      update.complete(http.Response('', 204));
      await settle(tester);

      expect(tester.takeException(), isNull);
      expect(harness.profile, profileB);
      expectNoSnackbar();
      expect(_loading, findsNothing);
    });

    testWidgets('logged out: no error and no message', (tester) async {
      final harness = await pumpPage(tester);
      final update = await startProfileUpdate(tester);

      await tester.runAsync(() => clientA.auth.signOut());
      harness.userInfo.show(null);
      await pumpAndIgnoreErrors(tester);

      update.complete(http.Response('', 204));
      await settle(tester);

      expect(tester.takeException(), isNull);
      expect(harness.profile, isNull);
      expectNoSnackbar();
      expect(sentry.events, isEmpty);
    });

    testWidgets('the ProviderScope was disposed: no error', (tester) async {
      await pumpPage(tester);
      final update = await startProfileUpdate(tester);

      await pumpWidgetAndIgnoreErrors(tester, const SizedBox.shrink());
      update.complete(http.Response('', 204));
      await settle(tester);

      expect(tester.takeException(), isNull);
      expect(_loading, findsNothing);
    });

    testWidgets('the ProviderScope was disposed, then the account changed: '
        'no error', (tester) async {
      await pumpPage(tester);
      final update = await startProfileUpdate(tester);

      await pumpWidgetAndIgnoreErrors(tester, const SizedBox.shrink());
      await deliverAuth(tester, _userB);
      update.complete(http.Response('', 204));
      await settle(tester);

      expect(tester.takeException(), isNull);
      expect(_loading, findsNothing);
    });
  });

  group('after the scope and native enrichment', () {
    testWidgets('a profile image report carries only its phase, type and '
        'code, and no attachment', (tester) async {
      await _contaminateScope();
      await pumpPage(tester);
      await press(tester);

      picker.picks.single.completeError(
        PlatformException(
          code: 'photo_access_denied',
          message: 'no access to /private/$_secret/IMG_0001.jpg',
        ),
      );
      await settle(tester);

      expect(tester.takeException(), isNull);
      expect(sentry.transport.sent, hasLength(1));
      final sent = sentry.transport.sent.single;
      final json = jsonEncode(sent.event);
      expect(json, isNot(contains(_secret)));
      expect(json, isNot(contains(_nativeSecret)));
      expect(json, isNot(contains(_userA)));
      expect(sent.event['tags'], {
        'profile_image_phase': 'pick',
        'profile_image_error_type': 'PlatformException',
        'profile_image_error_code': 'photo_access_denied',
      });
      expect(sent.event['fingerprint'], [
        'profile-image-failure',
        'pick',
        'PlatformException',
      ]);
      for (final field in const [
        'user',
        'breadcrumbs',
        'extra',
        'request',
        'server_name',
        'transaction',
      ]) {
        expect(sent.event[field], isNull, reason: field);
      }
      expect(sent.attachments, isEmpty);
      // Device, OS and app versions stay for diagnosis.
      final contexts = sent.event['contexts'] as Map<String, dynamic>;
      expect(contexts['os'], {'name': 'iOS', 'version': '18.0'});
      expect((contexts['device'] as Map)['model'], 'iPhone15,2');
      expect((contexts['app'] as Map)['app_version'], '1.3.6');
    });

    testWidgets('an unrelated event keeps the scope, the enrichment and the '
        'attachments', (tester) async {
      await _contaminateScope();

      await Sentry.captureMessage('unrelated');
      await settle(tester);

      expect(sentry.transport.sent, hasLength(1));
      final sent = sentry.transport.sent.single;
      expect((sent.event['tags'] as Map)['scope_tag'], _secret);
      expect((sent.event['tags'] as Map)['native_tag'], _nativeSecret);
      expect((sent.event['user'] as Map)['id'], _userA);
      expect(jsonEncode(sent.event), contains('$_nativeSecret-breadcrumb'));
      expect(
        sent.attachments,
        containsAll(const [
          'scope-photo.jpg',
          'hint-photo.jpg',
          'screen.png',
          'view.json',
        ]),
      );
    });
  });

  testWidgets('finishing does not dismiss another feature loading overlay', (
    tester,
  ) async {
    addTearDown(OverlayLoadingProgress.stop);
    await pumpPage(tester);
    const foreignKey = ValueKey('foreign-overlay');
    OverlayLoadingProgress.start(
      tester.element(find.byType(MyProfilePage)),
      widget: const SizedBox(key: foreignKey),
    );
    await pumpAndIgnoreErrors(tester);
    await pumpAndIgnoreErrors(tester);
    expect(find.byKey(foreignKey), findsOneWidget);

    final upload = await startUpload(tester);
    upload.complete(_Backend.uploadOk(backend.uploads.single));
    await settle(tester);

    expect(find.text(_l10n.common_success), findsOneWidget);
    expect(find.byKey(foreignKey), findsOneWidget);
  });
}

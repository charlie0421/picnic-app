"""Run the iOS notification display and GUI tap QA on one owned simulator.

Builds a disposable Flutter app, io.picnic.qa.notificationDelivery, installs
it on the simulator given by --simulator-udid, launches it, and waits while
the person who runs the QA (the GUI operator) operates the simulator GUI.
The runner injects exactly one `simctl push` and checks that the actual GUI
tap on that notification reaches the product vote list:

  native notification response -> FirebaseMessaging.onMessageOpenedApp
  -> PushTokenService.debugHandleNotificationTap
  -> AppInitializer.buildPushTapHandler -> DeepLinkHandler
  -> NavigationInfo -> VoteListPage / VoteList / AsyncVoteList.

The QA app is picnic_app/test_support/notification_delivery_ios_qa.dart; read
its header for the controlled boundaries. Not covered: the full App, Portal,
startup retry, the production push coordinator, cold start, real APNs/FCM
delivery, token registration, native SDK network traffic, physical devices.

Phases (printed as QA_PHASE=<name> and QA_ROOT_ACTION=<text>):
  await_start       the start screen (not the vote list) is rendered.
  await_permission  the GUI operator taps Allow on the permission sheet.
  await_paused      the GUI operator goes to the Home Screen.
  (push)            the runner sends one simctl push with a new message ID.
  await_tap         the GUI operator sees the notification, writes the
                    acknowledgement (QA_ACK_FILE / QA_ACK_TOKEN), and taps it.
  await_list        the product vote list shows the synthetic active rows.
  await_filter      the GUI operator selects PICNIC and the ended status.
  await_ack         only if the display acknowledgement is still missing.
A `simctl push` exit code 0 is not proof that a notification was displayed.
The runtime evidence and the GUI operator's display acknowledgement are
reported separately (runtime_evidence, visual). The run passes only if both
pass and the cleanup is verified.

Target and ownership:
- The simulator must be an available, Booted "Picnic Firebase QA" simulator
  on --simulator-runtime. The runner never boots, shuts down, or erases a
  simulator and never opens Simulator.app.
- The complete `simctl listapps` list is read before any build and again
  right before install. Only a bundle proven absent then becomes this run's
  app. A present or unknown state stops the run and nothing is removed.
- Every simctl command names the validated UDID and BUNDLE_ID only.
- Cleanup on pass, failure, timeout, or interruption: terminate and
  uninstall only the owned bundle, then require it absent in a fresh full
  list, the launched app process gone, every step process group stopped, and
  no process holding the workspace path. Anything unverified fails the run.

Evidence: the app writes Library/Caches/notification-delivery-ios.json in its
data container (from `simctl get_app_container ... data`, which must be in
this simulator's container directory). The app takes the directory from the
platform path provider (getTemporaryDirectory); the locked
path_provider_foundation 2.6.0 answers it with NSCachesDirectory, which is
Library/Caches, not tmp/. evidence_path() is the runner side of that
contract. The file must be absent before launch. The
runner reads at most MAX_EVIDENCE_BYTES and rejects a stale, malformed,
foreign, duplicate, wrong-ID, or out-of-order record.

Build isolation reuses the reviewed helpers: run_firebase_device_ios.py
(credential boundary for create, SwiftPM off, one simulator ARCHS, product
Podfile and pod pins, Info.plist Firebase switches, child environment) and
run_full_app_retry_android.py (product lib copy without main.dart,
firebase_options.dart, config/ and shorebird.yaml; product lock). Only
picnic_lib is a path dependency. The generated bundle io.picnic.qa.picnicApp
(and its RunnerTests id) is renamed only after its exact values are checked.
The AppDelegate gets only the notification center delegate line; no APNs
registration, credentials, entitlements, or product native code are added.
"""
import argparse
from collections import Counter
from dataclasses import dataclass
import fnmatch
import json
import os
from pathlib import Path
import plistlib
import re
import secrets
import signal
import stat
import subprocess
import sys
import tempfile
import time

sys.path.insert(0, str(Path(__file__).resolve().parent))
import run_firebase_device_android as android_base  # noqa: E402
import run_firebase_device_ios as ios_base  # noqa: E402
import run_full_app_retry_android as full_app  # noqa: E402

RunnerError = android_base.RunnerError
Interrupted = android_base.Interrupted
run_bounded = android_base.run_bounded
workspace_processes = ios_base.workspace_processes

ROOT = ios_base.ROOT
PROJECT_NAME = 'picnic_app'
ORG = 'io.picnic.qa'
GENERATED_BUNDLE = 'io.picnic.qa.picnicApp'  # What `flutter create` derives.
BUNDLE_ID = 'io.picnic.qa.notificationDelivery'
TESTS_SUFFIX = '.RunnerTests'
HARNESS_DIR = ROOT / 'picnic_app/test_support'
QA_SOURCES = ('notification_delivery_ios_qa.dart',
              'notification_delivery/vote_list_loopback.dart')
ENTRY = 'lib/notification_delivery_ios_qa.dart'

# Shared with notification_delivery_ios_qa.dart.
EVIDENCE_SCHEMA = 'picnic-notification-delivery-ios/1'
EVIDENCE_FILE = 'notification-delivery-ios.json'
EVIDENCE_DIRECTORY = 'Library/Caches'  # Relative to the app data container.
# The run nonce is compiled into the per-run QA build with
# --dart-define=PICNIC_QA_RUN_NONCE=<nonce>; the app reads it with
# String.fromEnvironment. The launch passes no environment: on the installed
# simulator the SIMCTL_CHILD_ launch environment did not reach the app
# (root native diagnostic, runNonce null twice on the same artifact).
NONCE_DEFINE = 'PICNIC_QA_RUN_NONCE'
BEFORE_MARKER = 'qa-notification-delivery-before'
MAX_EVENTS = 400

ACTION_URL = 'https://applink.picnic.fan/vote/list'
MESSAGE_PREFIX = 'qa-ios-sim-'
NONCE_FORMAT = re.compile(r'^[0-9a-f]{32}$')
UUID_FORMAT = re.compile(r'^[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}$')
MAX_EVIDENCE_BYTES = 256 * 1024
MAX_PAYLOAD_BYTES = 4096  # APNs payload limit.
MAX_ACK_BYTES = 256
CLOCK_SKEW_MS = 2000
POLL_INTERVAL_S = 1.0
APP_COMMAND_TIMEOUT_S = 60
ACK_NAME = 'notification-displayed'
IMAGE_ERROR_LIBRARY = 'image resource service'

MILESTONES = ('started', 'before', 'permission', 'paused', 'opened', 'navigated',
              'list_active', 'list_filtered')
EVENT_TYPES = frozenset({
    'launched', 'auth_state', 'firebase_ready', 'coordinator_created',
    'push_initialize_started', 'push_initialize_done', 'local_notifications_skipped',
    'permission_requested', 'permission_result', 'permission_check',
    'initial_message', 'token_requested', 'topic_noop', 'register_noop',
    'signed_in_checked', 'foreground_message', 'opened', 'tap_forwarded',
    'push_step_error', 'lifecycle', 'navigation', 'before_screen', 'list_state',
    'flutter_error', 'uncaught_error', 'overflow',
})
# Event types that fail the run wherever they appear.
FORBIDDEN_EVENTS = {
    'overflow': 'evidence overflow: the app stopped recording events',
    'uncaught_error': 'uncaught error in the QA app',
    'push_step_error': 'a push initialization step reported an error',
    'foreground_message': 'a foreground message arrived: the app was not paused',
    'register_noop': 'a backend registration was attempted: the token is controlled',
}
ACTIVE_ALL = {'area': 'all', 'voteStatus': 'active', 'ids': [910001, 910002]}
FILTERED = {'area': 'kpop', 'voteStatus': 'end', 'ids': [910003]}

# The installed Flutter 3.41.4 iOS template (FlutterImplicitEngineDelegate
# and FlutterSceneDelegate). A different template stops the run.
TEMPLATE_APP_DELEGATE = '''import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
'''
TEMPLATE_SCENE_DELEGATE = '''import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {

}
'''
QA_IMPORT_LINE = 'import UserNotifications\n'
# FlutterAppDelegate is a FlutterAppLifeCycleProvider, so the Firebase
# Messaging plugin keeps it as the delegate and receives the forwarded
# notification callbacks. A plain assignment does not compile if the type
# does not conform, so a template change cannot silently set nil.
QA_DELEGATE_LINES = (
    '    // Added by run_notification_delivery_ios.py (QA only): the app delegate\n'
    '    // owns the notification center and forwards responses to plugins.\n'
    '    UNUserNotificationCenter.current().delegate = self\n')
_SUPER_CALL = '    return super.application(application, didFinishLaunchingWithOptions: launchOptions)\n'

OVERRIDES = [
    'PushTokenService.debugUseCoordinatorFactory: real coordinator; real permission, '
    'initial message and message streams; token null; topic and registration no-op',
    'Environment.initTestConfig and testSupabaseClient on a 127.0.0.1 server with '
    'synthetic votes; signed out',
    'demo Firebase options; Info.plist: Messaging auto-init and collection disabled',
    'AppDelegate: UNUserNotificationCenter delegate = app delegate (QA only)',
    'one simctl push with a run-unique gcm.message_id; display acknowledged by the '
    'GUI operator',
]


@dataclass
class RunIdentity:
    """Values that tie evidence to this run."""
    nonce: str
    pid: int = None
    evidence_path: str = None
    launch_started_ms: int = None
    push_started_ms: int = None
    message_id: str = None


class RunState:
    def __init__(self):
        self.sim = None
        self.owned = False
        self.pid = None
        self.initial_state = None
        self.progress = dict.fromkeys(MILESTONES, False)
        self.ack_path = None
        self.ack_token = None
        self.ack_not_before = None
        self.acked = False


def now_ms():
    return int(time.time() * 1000)


def new_nonce():
    return secrets.token_hex(16)


def new_ack_token():
    return new_nonce()


def require_run_nonce(nonce):
    """The run nonce, if it is 32 lowercase hex characters; else RunnerError."""
    if not isinstance(nonce, str) or not NONCE_FORMAT.match(nonce):
        raise RunnerError('the run nonce must be 32 lowercase hex characters')
    return nonce


# --- Payload ---------------------------------------------------------------

def build_payload(message_nonce):
    """The one simctl push payload. gcm.message_id is qa-ios-sim-<nonce>."""
    if not isinstance(message_nonce, str) or not NONCE_FORMAT.match(message_nonce):
        raise RunnerError('the message nonce must be 32 lowercase hex characters')
    return {
        'Simulator Target Bundle': BUNDLE_ID,
        'aps': {'alert': {'title': 'Picnic QA', 'body': 'Tap to open the vote list'},
                'sound': 'default'},
        'gcm.message_id': MESSAGE_PREFIX + message_nonce,
        'action_url': ACTION_URL,
    }


def encode_payload(payload):
    data = json.dumps(payload, ensure_ascii=True, sort_keys=True).encode()
    if len(data) > MAX_PAYLOAD_BYTES:
        raise RunnerError(f'the push payload is {len(data)} bytes; the limit is '
                          f'{MAX_PAYLOAD_BYTES}')
    return data


# --- Evidence --------------------------------------------------------------

def read_evidence(path):
    """The parsed evidence file, or None while it does not exist."""
    path = Path(path)
    try:
        info = os.lstat(path)
    except FileNotFoundError:
        return None
    if not stat.S_ISREG(info.st_mode):
        raise RunnerError(f'the evidence file is not a regular file: {path}')
    if info.st_size > MAX_EVIDENCE_BYTES:
        raise RunnerError(f'the evidence file is {info.st_size} bytes; the limit is '
                          f'{MAX_EVIDENCE_BYTES}')
    with open(path, 'rb') as source:
        data = source.read(MAX_EVIDENCE_BYTES + 1)
    if len(data) > MAX_EVIDENCE_BYTES:
        raise RunnerError(f'the evidence file grew past {MAX_EVIDENCE_BYTES} bytes')
    try:
        return json.loads(data.decode('utf-8'))
    except (UnicodeDecodeError, ValueError):
        raise RunnerError('the evidence file is malformed (not complete JSON)') from None


def _is_int(value):
    return isinstance(value, int) and not isinstance(value, bool)


def _check_document(doc, run, now):
    if not isinstance(doc, dict):
        raise RunnerError('the evidence is malformed: not an object')
    if doc.get('schema') != EVIDENCE_SCHEMA:
        raise RunnerError(f'the evidence schema is {doc.get("schema")!r}, not {EVIDENCE_SCHEMA}')
    if doc.get('runNonce') != run.nonce:
        raise RunnerError('the evidence run nonce does not match this run (stale or foreign)')
    if run.pid is not None and (not _is_int(doc.get('pid')) or doc.get('pid') != run.pid):
        raise RunnerError(f'the evidence pid {doc.get("pid")!r} is not the launched '
                          f'process {run.pid}')
    path = doc.get('evidencePath')
    if not isinstance(path, str) or os.path.normpath(path) != os.path.normpath(
            str(run.evidence_path)):
        raise RunnerError('the evidence path is not the file in the owned data container')
    events = doc.get('events')
    loopback = doc.get('loopback')
    if not isinstance(events, list) or not isinstance(loopback, dict) or not isinstance(
            loopback.get('requests'), list) or not isinstance(loopback.get('unexpected'), list):
        raise RunnerError('the evidence is malformed: events or loopback missing')
    if len(events) > MAX_EVENTS:
        raise RunnerError(f'the evidence has more than {MAX_EVENTS} events')
    previous = None
    for index, event in enumerate(events, 1):
        if not isinstance(event, dict):
            raise RunnerError('the evidence is malformed: an event is not an object')
        if event.get('seq') != index or not _is_int(event.get('seq')):
            raise RunnerError(f'evidence seq {event.get("seq")!r} at position {index}')
        if event.get('type') not in EVENT_TYPES:
            raise RunnerError(f'unknown evidence event type {event.get("type")!r}')
        wall = event.get('wallMs')
        if not _is_int(wall):
            raise RunnerError(f'evidence event {index} has no integer wallMs')
        if wall < run.launch_started_ms:
            raise RunnerError(f'evidence event {index} is from before the launch (stale)')
        if wall > now + CLOCK_SKEW_MS:
            raise RunnerError(f'evidence event {index} time is in the future')
        if previous is not None and wall < previous:
            raise RunnerError(f'evidence time goes backwards at event {index}')
        previous = wall
    return events, loopback['requests']


def _single(events, kind):
    items = [event for event in events if event['type'] == kind]
    if len(items) > 1:
        raise RunnerError(f'more than one {kind} event')
    return items[0] if items else None


def _served(requests, spec):
    return any(isinstance(request, dict) and request.get('method') == 'GET'
               and request.get('path') == '/rest/v1/vote'
               and request.get('statusCode') == 200
               and request.get('area') == spec['area']
               and request.get('voteStatus') == spec['voteStatus']
               and request.get('ids') == spec['ids'] for request in requests)


def _list_matches(event, area, status, chip, ids_ok):
    cards = event.get('cardIds')
    return (event.get('voteLists') == [{'area': area, 'status': status}]
            and event.get('selectedChips') == [chip]
            and event.get('statusValues') == [status]
            and isinstance(cards, list) and bool(cards)
            and all(_is_int(card) for card in cards) and ids_ok(cards))


def validate_evidence(doc, run, now_ms):
    """Checks the evidence so far; returns {milestone: reached}.

    Raises RunnerError for any record that must never appear in a good run,
    even if the run is not complete yet.
    """
    events, requests = _check_document(doc, run, now_ms)
    if events and events[0]['type'] != 'launched':
        raise RunnerError('the first evidence event is not launched')
    launched = _single(events, 'launched')
    if launched is not None and launched.get('nonceValid') is not True:
        raise RunnerError('the app did not receive a valid run nonce')
    for kind, message in FORBIDDEN_EVENTS.items():
        if any(event['type'] == kind for event in events):
            raise RunnerError(message)
    errors = [event for event in events if event['type'] == 'flutter_error'
              and event.get('library') != IMAGE_ERROR_LIBRARY]
    if errors:
        raise RunnerError(f'Flutter error in the QA app: '
                          f'{[(e.get("library"), e.get("exception")) for e in errors]}')

    auth = _single(events, 'auth_state')
    if auth is not None and (auth.get('signedIn') is not False
                             or auth.get('loopbackHost') != '127.0.0.1'):
        raise RunnerError('the QA app is signed in or not on the loopback backend')
    if any(event.get('signedIn') is not False for event in events
           if event['type'] == 'signed_in_checked'):
        raise RunnerError('the controlled push dependencies reported signed in')
    firebase = _single(events, 'firebase_ready')
    if firebase is not None and (firebase.get('autoInit') is not False
                                 or firebase.get('defaultApp') is not True):
        raise RunnerError('Messaging auto-init is on or no default Firebase app exists')
    permission = _single(events, 'permission_result')
    if permission is not None and permission.get('status') != 'authorized':
        raise RunnerError(f'notification permission is {permission.get("status")!r}, '
                          'not authorized')
    initial = _single(events, 'initial_message')
    if initial is not None and (initial.get('isNull') is not True
                                or initial.get('messageId') is not None):
        raise RunnerError('the initial message is not null')
    token = _single(events, 'token_requested')
    if token is not None and token.get('returned') is not None:
        raise RunnerError('the controlled token is not null')
    before = _single(events, 'before_screen')
    if before is not None and (before.get('marker') != BEFORE_MARKER
                               or before.get('stackTop') == 'VoteListPage'):
        raise RunnerError('the start screen is not distinct from the vote list')

    opened = _single(events, 'opened')
    tap = _single(events, 'tap_forwarded')
    opened_seq = opened['seq'] if opened is not None else None
    for event in events:
        shows_list = event['type'] == 'list_state' or (
            event['type'] == 'navigation' and event.get('stackTop') == 'VoteListPage')
        if shows_list and (opened_seq is None or event['seq'] < opened_seq):
            raise RunnerError('the vote list appeared before the notification tap')
    if before is not None and opened is not None and before['seq'] > opened_seq:
        raise RunnerError('the start screen was recorded after the opened event')
    if opened is not None:
        if run.push_started_ms is None or opened['wallMs'] < run.push_started_ms:
            raise RunnerError('the opened event is from before the push was sent')
        if opened.get('messageId') != run.message_id:
            raise RunnerError(f'the opened message ID {opened.get("messageId")!r} is not '
                              "this run's message")
        if opened.get('actionUrl') != ACTION_URL:
            raise RunnerError(f'the opened action_url {opened.get("actionUrl")!r} is not '
                              f'{ACTION_URL}')
        lower = before['seq'] if before is not None else 0
        if not any(event['type'] == 'lifecycle' and event.get('state') == 'paused'
                   and lower < event['seq'] < opened_seq for event in events):
            raise RunnerError('the opened event has no paused lifecycle before it')
    if tap is not None and (opened is None or tap['seq'] <= opened_seq
                            or tap.get('messageId') != opened.get('messageId')):
        raise RunnerError('tap_forwarded does not follow the opened event of this message')

    progress = dict.fromkeys(MILESTONES, False)
    progress['started'] = launched is not None
    progress['before'] = before is not None
    progress['permission'] = None not in (permission, initial, token, auth, firebase)
    if progress['before'] and progress['permission']:
        after = max(before['seq'], permission['seq'])
        progress['paused'] = any(event['type'] == 'lifecycle'
                                 and event.get('state') == 'paused'
                                 and event['seq'] > after for event in events)
    progress['opened'] = opened is not None and tap is not None
    navigation = next((event for event in events if tap is not None
                       and event['type'] == 'navigation'
                       and event.get('stackTop') == 'VoteListPage'
                       and event['seq'] > tap['seq']), None)
    progress['navigated'] = navigation is not None
    if navigation is None:
        return progress
    states = [event for event in events
              if event['type'] == 'list_state' and event['seq'] > navigation['seq']]
    active_ids = set(ACTIVE_ALL['ids'])
    active = next((event for event in states if _list_matches(
        event, 'all', 'active', 'ALL',
        lambda cards: cards[0] == ACTIVE_ALL['ids'][0] and set(cards) <= active_ids)),
        None)
    progress['list_active'] = active is not None and _served(requests, ACTIVE_ALL)
    if not progress['list_active']:
        return progress
    filtered = next((event for event in states if event['seq'] > active['seq']
                     and _list_matches(event, 'kpop', 'end', 'PICNIC',
                                       lambda cards: cards == FILTERED['ids'])), None)
    progress['list_filtered'] = filtered is not None and _served(requests, FILTERED)
    return progress


def check_ack(path, token, not_before):
    """True if the GUI operator acknowledged the display; False if not yet.

    The acknowledgement is a regular file that holds exactly [token] (one
    trailing newline allowed) and was written after [not_before] (epoch
    seconds). Anything else raises RunnerError.
    """
    path = Path(path)
    try:
        info = os.lstat(path)
    except FileNotFoundError:
        return False
    if not stat.S_ISREG(info.st_mode):
        raise RunnerError(f'the acknowledgement {path.name} is not a regular file')
    if info.st_size > MAX_ACK_BYTES:
        raise RunnerError(f'the acknowledgement {path.name} is too large')
    if info.st_mtime < not_before - 1:
        raise RunnerError(f'the acknowledgement {path.name} is stale (written before '
                          'the prompt)')
    text = path.read_text(errors='replace')
    if text.rstrip('\n') != token or text.count('\n') > 1:
        raise RunnerError(f'the acknowledgement {path.name} does not hold this run token')
    return True


# --- Project ---------------------------------------------------------------

def check_ios_template(ios):
    ios = Path(ios)
    if (ios / 'Runner/AppDelegate.swift').read_text() != TEMPLATE_APP_DELEGATE:
        raise RunnerError('the generated AppDelegate.swift is not the expected template')
    if (ios / 'Runner/SceneDelegate.swift').read_text() != TEMPLATE_SCENE_DELEGATE:
        raise RunnerError('the generated SceneDelegate.swift is not the expected template')
    with open(ios / 'Runner/Info.plist', 'rb') as source:
        plist = plistlib.load(source)
    if plist.get('CFBundleIdentifier') != '$(PRODUCT_BUNDLE_IDENTIFIER)':
        raise RunnerError('the generated Info.plist has an unexpected CFBundleIdentifier')
    manifest = plist.get('UIApplicationSceneManifest')
    roles = (manifest or {}).get('UISceneConfigurations', {}).get(
        'UIWindowSceneSessionRoleApplication') if isinstance(manifest, dict) else None
    if not isinstance(roles, list) or len(roles) != 1 or roles[0].get(
            'UISceneDelegateClassName') != '$(PRODUCT_MODULE_NAME).SceneDelegate':
        raise RunnerError('the generated Info.plist has no single SceneDelegate scene '
                          'configuration')


def write_qa_app_delegate(ios):
    path = Path(ios) / 'Runner/AppDelegate.swift'
    text = path.read_text()
    if text != TEMPLATE_APP_DELEGATE:
        raise RunnerError('AppDelegate.swift changed before the QA edit')
    text = text.replace('import UIKit\n', 'import UIKit\n' + QA_IMPORT_LINE, 1)
    text = text.replace(_SUPER_CALL, QA_DELEGATE_LINES + _SUPER_CALL, 1)
    path.write_text(text)


def rewrite_bundle_ids(text):
    """Renames the exact generated bundle ids; anything else is refused."""
    values = Counter(re.findall(r'PRODUCT_BUNDLE_IDENTIFIER = ([^;]+);', text))
    expected = Counter({GENERATED_BUNDLE: 3, GENERATED_BUNDLE + TESTS_SUFFIX: 3})
    if values != expected or ios_base.PRODUCT_BUNDLE_ID in text:
        raise RunnerError(f'generated bundle identifiers are {dict(values)}, not '
                          f'{dict(expected)}')
    text = text.replace(f'PRODUCT_BUNDLE_IDENTIFIER = {GENERATED_BUNDLE}{TESTS_SUFFIX};',
                        f'PRODUCT_BUNDLE_IDENTIFIER = {BUNDLE_ID}{TESTS_SUFFIX};')
    return text.replace(f'PRODUCT_BUNDLE_IDENTIFIER = {GENERATED_BUNDLE};',
                        f'PRODUCT_BUNDLE_IDENTIFIER = {BUNDLE_ID};')


def kept_assets(product_text):
    """The declared product assets that the QA app may copy (copy_product rule)."""
    declared = full_app.declared_assets(
        full_app.top_level_blocks(product_text).get('flutter', []))
    return [asset for asset in declared
            if asset not in full_app.EXCLUDED_ASSETS and not asset.startswith('config/')
            and not full_app.SENSITIVE_NAME.search(asset)]


def build_qa_pubspec(product_text, picnic_lib, locked, assets):
    """The full_app_retry QA pubspec plus the project SwiftPM switch (off)."""
    text = full_app.build_pubspec(product_text, picnic_lib, locked, assets)
    dependencies = full_app.top_level_blocks(product_text)['dependencies']
    indent = re.match(r'^([ \t]+)', next(
        line for line in dependencies if line.strip())).group(1)
    return (text.rstrip('\n') + f'\n{indent}config:\n'
            f'{indent * 2}enable-swift-package-manager: false\n')


def check_locks(product_lock, qa_lock):
    report = full_app.compare_locks(product_lock, qa_lock)
    actual = android_base.locked_versions(Path(qa_lock))
    missing = [name for name in ios_base.PINNED_PACKAGES if name not in actual]
    if missing:
        raise RunnerError(f'pinned packages were not resolved: {missing}')
    report['pinned'] = {name: actual[name] for name in ios_base.PINNED_PACKAGES}
    return report


def copy_qa_sources(workspace):
    lib = Path(workspace) / 'lib'
    files = {}
    for rel in QA_SOURCES:
        target = lib / rel
        if target.exists():
            raise RunnerError(f'lib/{rel} already exists; a product file is not replaced')
        files[rel] = full_app.copy_checked(HARNESS_DIR / rel, target)
    return files


def check_built_app(app):
    """Checks the exact app that will be installed."""
    app = Path(app)
    plist = ios_base.check_plist_settings(app / 'Info.plist')
    if plist.get('CFBundleIdentifier') != BUNDLE_ID:
        raise RunnerError(f'the built app CFBundleIdentifier is '
                          f'{plist.get("CFBundleIdentifier")!r}, not {BUNDLE_ID}')
    assets = app / 'Frameworks/App.framework/flutter_assets'
    if not assets.is_dir():
        raise RunnerError('the built app has no flutter_assets; it cannot be verified')
    if (assets / 'config').exists():
        raise RunnerError('the built app has config/ assets')
    forbidden, count = [], 0
    for path in sorted(app.rglob('*')):
        if path.is_dir() and not path.is_symlink():
            continue
        count += 1
        rel = path.relative_to(app).as_posix()
        name = ('assets/flutter_assets/' + path.relative_to(assets).as_posix()
                if assets in path.parents else rel)
        if (full_app.is_forbidden_artifact(name) or full_app.SENSITIVE_NAME.search(rel)
                or any(fnmatch.fnmatch(path.name, pattern)
                       for pattern in ios_base.FORBIDDEN_FILES)):
            forbidden.append(rel)
    if forbidden:
        raise RunnerError(f'the built app has forbidden files: {forbidden[:10]}')
    return {'bundle_id': BUNDLE_ID, 'files': count}


def prepare_ios(qa, arch):
    workspace = qa.workspace
    ios = workspace / 'ios'
    if (workspace / 'android').exists():
        raise RunnerError('the QA project must be iOS only')
    ios_base.check_no_spm_wiring(workspace)
    check_ios_template(ios)
    pbxproj = ios / 'Runner.xcodeproj/project.pbxproj'
    project = rewrite_bundle_ids(pbxproj.read_text())
    for setting in ('CODE_SIGN_ENTITLEMENTS', 'DEVELOPMENT_TEAM', 'PROVISIONING_PROFILE'):
        if setting in project:
            raise RunnerError(f'generated project must not set {setting}')
    if 'RunnerTests' not in project:
        raise RunnerError('generated project has no RunnerTests target for the product Podfile')
    product_project = (ROOT / 'picnic_app/ios/Runner.xcodeproj/project.pbxproj').read_text()
    targets = set(re.findall(r'IPHONEOS_DEPLOYMENT_TARGET = ([^;]+);', product_project))
    if len(targets) != 1:
        raise RunnerError(f'product deployment targets are not uniform: {sorted(targets)}')
    deployment = targets.pop()
    project, count = re.subn(r'IPHONEOS_DEPLOYMENT_TARGET = [^;]+;',
                             f'IPHONEOS_DEPLOYMENT_TARGET = {deployment};', project)
    if count == 0:
        raise RunnerError('generated project has no IPHONEOS_DEPLOYMENT_TARGET')
    pbxproj.write_text(project)
    ios_base.set_simulator_arch(workspace, arch)
    write_qa_app_delegate(ios)
    ios_base.apply_plist_settings(ios / 'Runner/Info.plist')
    ios_base.check_plist_settings(ios / 'Runner/Info.plist')
    product_podfile = ROOT / 'picnic_app/ios/Podfile'
    sdk = android_base.product_version(r"^\$FirebaseSDKVersion = '([^']+)'", product_podfile)
    full_app.copy_checked(product_podfile, ios / 'Podfile')
    full_app.copy_checked(ROOT / 'picnic_app/ios/Podfile.lock', ios / 'Podfile.lock')
    qa.result['toolchain'] = {'ios_deployment_target': deployment,
                              'firebase_sdk_version': sdk}
    ios_base.check_no_forbidden_files(workspace)


def build_app(qa, args, arch, run_nonce):
    """Creates, prepares, resolves and builds the QA app; returns Runner.app.

    [run_nonce] is compiled into this build only (one --dart-define), so the
    inspected and installed app carries this run's identity.
    """
    run_nonce = require_run_nonce(run_nonce)
    workspace = qa.workspace
    product_text = (ROOT / 'picnic_app/pubspec.yaml').read_text()
    product_lock = ROOT / 'picnic_app/pubspec.lock'
    assets = kept_assets(product_text)
    pubspec = build_qa_pubspec(product_text, ROOT / 'picnic_lib',
                               android_base.locked_versions(product_lock), assets)
    (workspace / 'pubspec.yaml').write_text(pubspec)
    ios_base.create_project(qa, args.create_timeout, project_name=PROJECT_NAME, org=ORG)
    lib_files, _, copied = full_app.copy_product(qa, ROOT)
    if copied != assets or (workspace / 'pubspec.yaml').read_text() != pubspec:
        raise RunnerError('the copied assets or the QA pubspec changed during the copy')
    qa.result['product_lib'] = {'count': len(lib_files),
                                'sha256': full_app.tree_digest(lib_files)}
    qa.result['qa_sources'] = copy_qa_sources(workspace)
    prepare_ios(qa, arch)
    full_app.scan_workspace(workspace)

    full_app.copy_checked(product_lock, workspace / 'pubspec.lock')
    qa.run('pub-get', ['flutter', 'pub', 'get'], args.pub_timeout)
    qa.result['lock'] = check_locks(product_lock, workspace / 'pubspec.lock')
    ios_base.check_dependency_manager(qa)
    qa.run('build-simulator', ['flutter', 'build', 'ios', '--simulator', '--debug',
                               '--no-pub', '--target', ENTRY,
                               f'--dart-define={NONCE_DEFINE}={run_nonce}'],
           args.build_timeout)
    ios_base.check_dependency_manager(qa)
    ios_base.check_simulator_arch(workspace, arch)
    ios_base.check_pods(qa)
    app = workspace / ios_base.BUILT_APP
    qa.result['built_app'] = check_built_app(app)
    full_app.scan_workspace(workspace)
    return app


# --- Simulator -------------------------------------------------------------

def check_container(output, home, udid):
    """The app data container path, only inside the target simulator."""
    text = output.strip()
    if not text or '\n' in text:
        raise RunnerError('simctl get_app_container did not return one path')
    path = Path(text)
    parent = (Path(home) / 'Library/Developer/CoreSimulator/Devices' / udid /
              'data/Containers/Data/Application')
    if (not path.is_absolute() or path.parent != parent or not UUID_FORMAT.match(path.name)
            or os.path.realpath(path) != os.path.join(os.path.realpath(parent), path.name)):
        raise RunnerError("the app data container is not in the target simulator's "
                          'container directory')
    return path


def evidence_path(container):
    """The evidence file that the QA app writes in its data [container].

    The app writes in the directory that the platform path provider returns
    for getTemporaryDirectory. On iOS the locked path_provider_foundation
    2.6.0 returns NSCachesDirectory, <container>/Library/Caches. The Dart
    host test evidence_path_test.dart compares this path with the path of
    the actual QaEvidence.open.
    """
    return Path(container) / EVIDENCE_DIRECTORY / EVIDENCE_FILE


def parse_launch_output(output):
    lines = [line.strip() for line in output.splitlines() if line.strip()]
    match = re.fullmatch(re.escape(BUNDLE_ID) + r': (\d+)', lines[0]) if len(lines) == 1 \
        else None
    if match is None or int(match.group(1)) <= 0:
        raise RunnerError('simctl launch did not report one process ID for the QA app')
    return int(match.group(1))


class Simulator:
    """simctl for exactly one validated UDID and BUNDLE_ID."""

    def __init__(self, developer_dir, env, udid, logs, workspace, home, timeouts):
        self.tool = ios_base.simctl(developer_dir)
        self.env, self.udid, self.logs = env, udid, logs
        self.workspace, self.home, self.timeouts = workspace, home, timeouts

    def app_state(self):
        """'present' or 'absent'; an unreadable list raises RunnerError."""
        code, output = ios_base._inspect([self.tool, 'listapps', self.udid], self.env,
                                         include_stderr=False)
        if code != 0:
            raise RunnerError('cannot list installed apps on the target simulator')
        return 'present' if ios_base.bundle_listed(output, BUNDLE_ID) else 'absent'

    def _run(self, name, arguments, timeout, env=None):
        with (self.logs / f'simctl-{name}.log').open('a') as out:
            return run_bounded([self.tool, *arguments], cwd=self.workspace,
                               env=self.env if env is None else env, stdout=out,
                               timeout=timeout)

    def _capture(self, name, arguments, timeout, env=None):
        """stdout of one bounded simctl call in its own process group."""
        out_path = self.logs / f'simctl-{name}.stdout.log'
        err_path = self.logs / f'simctl-{name}.stderr.log'
        with out_path.open('w') as out, err_path.open('w') as err:
            process = subprocess.Popen([self.tool, *arguments], cwd=self.workspace,
                                       env=self.env if env is None else env, stdout=out,
                                       stderr=err, start_new_session=True)
            try:
                code = process.wait(timeout=timeout)
            except subprocess.TimeoutExpired:
                code = None
            finally:
                group = android_base.stop_process_group(process)
        if group['remaining'] or code != 0:
            raise RunnerError(f'simctl {name} did not succeed (see {err_path})')
        return out_path.read_text(errors='replace')

    def install(self, app):
        return self._run('install', ['install', self.udid, str(app)],
                         self.timeouts['install'])

    def data_container(self):
        output = self._capture('get-app-container',
                               ['get_app_container', self.udid, BUNDLE_ID, 'data'],
                               APP_COMMAND_TIMEOUT_S)
        return check_container(output, self.home, self.udid)

    def launch(self):
        """Starts the owned app; its run nonce is in the build, not the launch."""
        output = self._capture('launch', ['launch', self.udid, BUNDLE_ID],
                               self.timeouts['launch'])
        return parse_launch_output(output)

    def push(self, payload):
        return self._run('push', ['push', self.udid, BUNDLE_ID, str(payload)],
                         APP_COMMAND_TIMEOUT_S)

    def terminate(self):
        return self._run('terminate', ['terminate', self.udid, BUNDLE_ID],
                         APP_COMMAND_TIMEOUT_S)

    def uninstall(self):
        return self._run('uninstall', ['uninstall', self.udid, BUNDLE_ID],
                         APP_COMMAND_TIMEOUT_S)

    def process_alive(self, pid):
        return not android_base._confirmed_absent(pid)


# --- Run -------------------------------------------------------------------

def check_target(qa, args):
    """The Booted owned QA simulator; the runner never boots one."""
    qa.result['xcode'] = ios_base.check_xcode(args.developer_dir, qa.env)
    arch = qa.result['simulator_arch'] = ios_base.host_simulator_arch()
    device = ios_base.simulator_state(args.developer_dir, qa.env, args.simulator_udid,
                                      args.simulator_runtime)
    if device.get('state') != 'Booted':
        raise RunnerError(f'the target simulator is {device.get("state")}, not Booted; this '
                          'runner never boots, shuts down, or erases a simulator')
    return {'name': device['name'], 'runtime': device['runtime'], 'state': 'Booted',
            'arch': arch}


def _say(key, value):
    print(f'{key}={value}', flush=True)


def _poll_ack(state):
    if state.ack_token is not None and not state.acked:
        state.acked = check_ack(state.ack_path, state.ack_token, state.ack_not_before)
        if state.acked:
            _say('QA_ACK_RECEIVED', ACK_NAME)


def wait_for(run, state, phase, milestones, timeout, action):
    _say('QA_PHASE', phase)
    _say('QA_ROOT_ACTION', action)
    _say('QA_PHASE_TIMEOUT_S', timeout)
    deadline = time.monotonic() + timeout
    while True:
        doc = read_evidence(run.evidence_path)
        if doc is not None:
            state.progress = validate_evidence(doc, run, now_ms())
        _poll_ack(state)
        if all(state.progress[name] for name in milestones):
            _say('QA_PHASE_DONE', phase)
            return doc
        if time.monotonic() >= deadline:
            reached = [name for name in MILESTONES if state.progress[name]]
            raise RunnerError(f'{phase}: timed out after {timeout} s waiting for '
                              f'{list(milestones)}; reached {reached}')
        time.sleep(POLL_INTERVAL_S)


def wait_ack(state, timeout):
    if state.acked:
        return
    _say('QA_PHASE', 'await_ack')
    _say('QA_ROOT_ACTION', 'If the notification was displayed, write the token to the '
                           'acknowledgement file')
    deadline = time.monotonic() + timeout
    while not state.acked and time.monotonic() < deadline:
        _poll_ack(state)
        if not state.acked:
            time.sleep(POLL_INTERVAL_S)


def execute(qa, args, run, state, home):
    require_run_nonce(run.nonce)  # Before any simulator query or build.
    target = check_target(qa, args)
    state.initial_state = target['state']
    qa.result['simulator'] = {'name': target['name'], 'runtime': target['runtime'],
                              'initial_state': target['state']}
    timeouts = {'install': args.install_timeout, 'launch': args.launch_timeout}
    sim = state.sim = Simulator(args.developer_dir, qa.env, args.simulator_udid, qa.logs,
                                qa.workspace, home, timeouts)
    preflight = qa.result['app_preflight'] = sim.app_state()
    if preflight != 'absent':
        raise RunnerError(f'{BUNDLE_ID} is already installed on the target simulator; '
                          "it is not this run's app and is left untouched")

    app = build_app(qa, args, target.get('arch'), run.nonce)

    # Install boundary: the target again, then proven absence, then install.
    check_target(qa, args)
    if sim.app_state() != 'absent':
        raise RunnerError(f'{BUNDLE_ID} appeared on the target simulator during the build; '
                          'it is left untouched')
    state.owned = True
    _say('QA_STEP', 'simctl-install')
    outcome = sim.install(app)
    if outcome.get('exit_code') != 0 or outcome['cleanup']['remaining']:
        raise RunnerError('simctl install did not succeed')
    if sim.app_state() != 'present':
        raise RunnerError(f'{BUNDLE_ID} is not listed after install')
    container = sim.data_container()
    evidence = evidence_path(container)
    run.evidence_path = str(evidence)
    if os.path.lexists(evidence):
        raise RunnerError('a stale evidence file exists before the launch')
    _say('QA_EVIDENCE_FILE', qa.redact(str(evidence)))

    ack_dir = qa.workspace / 'qa-ack'
    ack_dir.mkdir(exist_ok=True)
    state.ack_path = ack_dir / ACK_NAME

    run.launch_started_ms = now_ms()
    _say('QA_STEP', 'simctl-launch')
    run.pid = state.pid = sim.launch()
    qa.result['app_pid'] = run.pid

    wait_for(run, state, 'await_start', ('started', 'before'), args.observe_timeout,
             'Record the dark blue "PICNIC QA - notification delivery" start screen '
             '(it is not the vote list)')
    wait_for(run, state, 'await_permission', ('permission',), args.permission_timeout,
             'Tap Allow on the notification permission sheet')
    wait_for(run, state, 'await_paused', ('paused',), args.observe_timeout,
             'Go to the Home Screen (Device > Home). Do not close the app')

    run.message_id = MESSAGE_PREFIX + new_nonce()
    payload = qa.workspace / 'qa-push/payload.apns'
    payload.parent.mkdir(exist_ok=True)
    payload.write_bytes(encode_payload(build_payload(run.message_id[len(MESSAGE_PREFIX):])))
    state.ack_token = new_ack_token()
    state.ack_not_before = time.time()
    _say('QA_MESSAGE_ID', run.message_id)
    _say('QA_ACK_FILE', state.ack_path)
    _say('QA_ACK_TOKEN', state.ack_token)
    _say('QA_ACK_COMMAND', f"printf '%s\\n' {state.ack_token} > {state.ack_path}")
    run.push_started_ms = now_ms()
    _say('QA_STEP', 'simctl-push')
    outcome = sim.push(payload)
    qa.result['push_command'] = {
        'exit_code': outcome.get('exit_code'), 'message_id': run.message_id,
        'note': 'exit code 0 means simctl accepted the payload, not that a '
                'notification was displayed'}
    if outcome.get('exit_code') != 0 or outcome['cleanup']['remaining']:
        raise RunnerError('simctl push did not succeed')

    wait_for(run, state, 'await_tap', ('opened',), args.tap_timeout,
             'When the notification is displayed, run QA_ACK_COMMAND, then tap the '
             'notification')
    wait_for(run, state, 'await_list', ('navigated', 'list_active'), args.list_timeout,
             'Wait for the vote list with the QA Active PICNIC card')
    doc = wait_for(run, state, 'await_filter', ('list_filtered',), args.filter_timeout,
                   'Tap the PICNIC chip, then choose the ended status ("Closed") in the '
                   'status menu')
    wait_ack(state, args.ack_timeout)

    final = validate_evidence(doc, run, now_ms())
    if not all(final.values()):
        raise RunnerError(f'final evidence check failed: {final}')
    loopback = doc['loopback']
    qa.result['runtime_evidence'] = {
        'status': 'passed', 'milestones': final, 'events': len(doc['events']),
        'message_id': run.message_id, 'pid': run.pid,
        'loopback_requests': loopback['requests'],
        'loopback_unexpected': loopback['unexpected'],
        'image_errors': sum(1 for event in doc['events']
                            if event['type'] == 'flutter_error'),
    }
    (qa.workspace / 'qa-evidence.json').write_text(
        qa.redact(json.dumps(doc, indent=2) + '\n'))


def cleanup(qa, state):
    """Removes only the owned app; 'verified' is True only if all is clean."""
    report = {'qa_app': None, 'app_process': None, 'workspace_processes': None,
              'simulator': {'left_as': state.initial_state}, 'verified': False}
    problems = []
    if state.owned:
        app = report['qa_app'] = {'actions': [], 'final': 'unknown'}
        try:
            if state.sim.app_state() == 'present':
                for action in ('terminate', 'uninstall'):
                    outcome = getattr(state.sim, action)()
                    app['actions'].append({'action': action, **outcome})
            app['final'] = state.sim.app_state()
        except RunnerError as error:
            app['error'] = str(error)
        except BaseException as error:  # Includes a second interrupt.
            app['error'] = repr(error)
        if app['final'] != 'absent':
            problems.append("this run's QA app is not verified as removed")
        unverified = [action['action'] for action in app['actions']
                      if (action.get('cleanup') or {}).get('remaining') is not False]
        if unverified:
            problems.append(f'QA app cleanup actions left process groups: {unverified}')
        if state.pid is not None:
            try:
                alive = state.sim.process_alive(state.pid)
                report['app_process'] = 'running' if alive else 'gone'
            except RunnerError as error:
                alive, report['app_process'] = True, f'unknown: {error}'
            if alive:
                problems.append('the launched QA app process is not verified as gone')
    try:
        report['workspace_processes'] = workspace_processes(qa.workspace)
    except RunnerError as error:
        report['workspace_processes'] = f'unknown: {error}'
        problems.append('processes holding the workspace path cannot be listed')
    else:
        if report['workspace_processes']:
            problems.append('processes that hold the workspace path are still running')
    report['problems'] = problems
    report['verified'] = not problems
    return report


def parse_args(argv):
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument('--simulator-udid', required=True,
                        help=f'UDID of a Booted "{ios_base.OWNED_SIMULATOR_PREFIX} ..." '
                             'simulator')
    parser.add_argument('--simulator-runtime', required=True,
                        help='runtime identifier, for example '
                             'com.apple.CoreSimulator.SimRuntime.iOS-26-5')
    parser.add_argument('--developer-dir', required=True, type=Path,
                        help='Xcode developer directory')
    for name, default in (('create', 300), ('pub', 900), ('build', 3600), ('install', 120),
                          ('launch', 60), ('permission', 180), ('observe', 120),
                          ('tap', 300), ('list', 60), ('filter', 180), ('ack', 120)):
        parser.add_argument(f'--{name}-timeout', type=int, default=default)
    return parser.parse_args(argv)


def main(argv=None, environ=None):
    args = parse_args(argv)
    environ = os.environ if environ is None else environ
    workspace = Path(tempfile.mkdtemp(prefix='picnic-notification-delivery-ios-qa-'))
    _say('QA_WORKSPACE', workspace)
    qa = ios_base.QaRun(workspace, {}, private=[args.simulator_udid])
    qa.result.update({'bundle_id': BUNDLE_ID, 'overrides': OVERRIDES})
    run = RunIdentity(nonce=new_nonce())
    state = RunState()
    status, error, code = 'failed', None, 1
    previous = signal.signal(signal.SIGTERM, ios_base._raise_interrupted)
    try:
        try:
            qa.env = ios_base.child_env(environ, args.developer_dir)
            execute(qa, args, run, state, environ.get('HOME', ''))
            status, code = 'passed', 0
        except RunnerError as caught:
            error = str(caught)
        except (KeyboardInterrupt, Interrupted):
            status, error, code = 'interrupted', 'the runner was interrupted', 130
        except Exception as caught:  # Reported, after cleanup, as a failure.
            error = f'unexpected error: {caught!r}'
        if 'runtime_evidence' not in qa.result:
            qa.result['runtime_evidence'] = {'status': 'failed', 'milestones': state.progress,
                                             'error': error}
        qa.result['visual'] = {
            'notification_displayed': 'acknowledged' if state.acked else 'missing',
            'note': 'GUI operator acknowledgement; simctl push exit 0 is not display proof'}
        if status == 'passed' and not state.acked:
            status, code = 'failed', 1
            error = ('the notification display was not acknowledged by the GUI operator; '
                     'the runtime evidence is reported separately')

        try:
            report = cleanup(qa, state)
        except BaseException as caught:  # Includes a second interrupt.
            report = {'error': repr(caught), 'verified': False}
        qa.result['cleanup'] = report
        if report.get('verified') is not True:
            problem = f'cleanup is not verified; the workspace is kept: {report}'
            error = f'{error}; {problem}' if error else problem
            if status == 'passed':
                status, code = 'failed', 1

        message = qa.redact(error) if error else None
        qa.write_result(status, message)
        if status == 'interrupted':
            print(f'QA_INTERRUPTED: {message}', file=sys.stderr, flush=True)
        elif status == 'failed':
            print(f'QA_FAILED: {message}', file=sys.stderr, flush=True)
        return code
    finally:
        signal.signal(signal.SIGTERM, previous)


if __name__ == '__main__':
    sys.exit(main())

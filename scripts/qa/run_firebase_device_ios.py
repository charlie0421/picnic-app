"""Run the native Firebase readiness probe on one owned iOS simulator.

Builds a disposable Flutter iOS app (bundle id io.picnic.qa.firebaseReadiness)
in a new temporary workspace that depends on the current picnic_lib source,
then runs picnic_app/test_support/firebase_readiness_ios_qa.dart on the
simulator given by --simulator-udid.

Target:
- --simulator-udid must be a simulator UDID that `simctl list` reports as
  available, whose name starts with OWNED_SIMULATOR_PREFIX, on the runtime
  given by --simulator-runtime (for example
  com.apple.CoreSimulator.SimRuntime.iOS-26-5). A physical device ID, an
  unknown UDID, a simulator on another runtime, or any other simulator is
  rejected before any build step.
- By default the simulator must already be Booted, and the runner leaves it
  as it was. Only with --boot-if-shutdown does the runner boot a Shutdown
  simulator (`simctl bootstatus -b`); it then shuts down that simulator, and
  only that one, at the end. A bootstatus output that reports a failure (for
  example "Data Migration Failed") fails the run even if the exit code is 0.
  The runner never erases a simulator and never opens Simulator.app.

QA app ownership:
- Before the test step the runner lists the target simulator's apps (`simctl
  listapps`). If BUNDLE_ID is already installed, the run fails and that app
  is not touched. Only an absent bundle makes the app installed by this run
  "owned". `flutter test` installs the app and normally uninstalls it again
  (IntegrationTestTestDevice.kill), but a failed stop or uninstall is only
  logged there.
- After an owned run - pass, failure, timeout, or interruption - the runner
  lists the apps again. If BUNDLE_ID is still installed it runs `simctl
  terminate` (a "not running" failure is allowed) and `simctl uninstall`
  for that bundle on that simulator only, then lists the apps again. The
  cleanup is verified only if the bundle is absent. A failed or unreadable
  query, or a bundle that stays installed, makes the cleanup unverified. No
  other app is terminated or uninstalled, and no process is matched by name.
  The native Firebase app inside the process is never deleted.
- Each app list is the stdout of `simctl listapps`, converted completely by
  a bounded `/usr/bin/plutil -convert json` on stdin. Only a top-level
  dictionary is accepted, and only an exact top-level key counts as
  installed. A failed, timed-out, invalid, or non-dictionary result is
  unknown: before the test it stops the run without ownership, and after
  the test it makes the cleanup unverified.

Isolation:
- --developer-dir is required and must be an Xcode whose `xcodebuild
  -version` is in SUPPORTED_XCODE. Every child gets that DEVELOPER_DIR; the
  global Xcode selection is not changed.
- Signing discovery: the installed `flutter create --platforms=ios` looks
  for a development team before it writes the project (create.dart
  417-428). That path runs `which security` and `which openssl` and returns
  without a team if either fails (code_signing.dart 331-334, 420-433);
  otherwise it runs `security find-identity`, then `security
  find-certificate` and `openssl`. For the create step only, the runner puts
  qa-credential-boundary/bin first on PATH. Its `which` fails for these two
  names and passes every other lookup to /usr/bin/which, and its `security`
  and `openssl` record the call and exit 1, so a lookup by name never
  reaches the real tools. Any recorded `security` or `openssl` call fails
  the run. A failed find-identity gives an empty identity list, so the
  signing-choice save path is not reached. HOME and the Flutter settings
  are not changed; Flutter still reads its settings file at startup.
- CocoaPods, not Swift Package Manager: pubspec.yaml is written before
  `flutter create` with `flutter: config: enable-swift-package-manager:
  false`. The project setting wins over a global `flutter config` value and
  FLUTTER_SWIFT_PACKAGE_MANAGER (flutter_features_config.dart 104-154), and
  the process working directory is the project, so create, pub get, build,
  and test all read it. The run fails if create changes pubspec.yaml, if
  the Xcode project gets FlutterGeneratedPluginSwiftPackage wiring, or if
  .flutter-plugins-dependencies reports swift_package_manager_enabled.ios
  true (the value podhelper.rb reads to skip plugin pods).
- One simulator architecture: with Xcode 27.2, Flutter 3.41.4
  debug_unpack_ios fails because it calls `lipo -verify_arch` with both
  simulator architectures and this lipo accepts only one
  (flutter/flutter#188461, fixed upstream by #188625; the installed SDK is
  not changed). The runner appends `ARCHS[sdk=iphonesimulator*] = <arch>`
  to the generated ios/Flutter/Debug.xcconfig, the base configuration of
  the Runner Debug build, so `flutter build ios --simulator --debug` and
  `flutter test` build one architecture. <arch> is the host's native
  architecture (host_simulator_arch: arm64 or x86_64; anything else fails
  before any step) and is recorded as simulator_arch. The run fails if the
  generated project already sets ARCHS, if Runner Debug does not use
  Debug.xcconfig, or if the setting is missing after the build. Release and
  Profile, the Pods project, product files, and global Xcode settings are
  not changed. Limit: the QA app is built for that one simulator
  architecture only, and a command-line ARCHS from Flutter would still
  override it.
- No GoogleService-Info.plist, google-services.json, env, entitlements,
  provisioning, or signing files are used, and the project must not set
  CODE_SIGN_ENTITLEMENTS. The test supplies demo FirebaseOptions only.
- APNs: the installed firebase_messaging 17.0.1 iOS plugin requests APNs
  registration only when a native default app exists AND Messaging
  auto-init is enabled (registerForRemoteNotificationsIfAutoInitEnabled, at
  launch and again from pluginConstantsForFIRApp after Dart configures the
  app). FirebaseMessagingAutoInitEnabled=false closes that gate, and the
  probe asserts auto-init is off after the default app exists. The missing
  entitlement and FirebaseAppDelegateProxyEnabled=false are extra settings,
  not the proof that no APNs request is made.
- Before the first build the generated Info.plist gets QA_PLIST_SETTINGS:
  Messaging auto-init, the Firebase app delegate proxy, data collection,
  Analytics collection, and ad ID / IDFV collection are off. After the build
  the runner checks the same values in the built Runner.app.
- The product Podfile and Podfile.lock are copied, so CocoaPods resolves the
  product's FirebaseSDKVersion override (12.19.0, FirebaseCore 12.19.3).
  After the build the QA Podfile.lock must match the product lock for
  POD_PINS, and pubspec.lock must match picnic_lib/pubspec.lock for
  PINNED_PACKAGES.
- The project is iOS only: no android directory, no Gradle. Child processes
  get only TOOLCHAIN_ENV plus the fixed values in child_env(); no Gradle,
  Java, or Android variable is passed.
- Each step runs in its own process group (run_bounded from the Android
  runner). On timeout, interruption, or exit the group gets SIGTERM, then
  SIGKILL. Processes outside the group (CoreSimulatorService, Xcode build
  services, a shared adb server that Flutter device discovery can start) are
  never signalled. After the run the runner lists processes whose command
  line holds the workspace path; any such process makes the cleanup
  unverified. The runner does not signal it.
- pub, CocoaPods, and Xcode use their normal user caches (pub cache,
  CocoaPods repos and download cache, DerivedData). The runner adds entries
  through normal resolution only; it changes no setting and deletes nothing.
- qa-result.json is written only after cleanup. Its status is "passed" only
  if every step succeeded and the cleanup is verified. The simulator UDID is
  replaced by <simulator> in the result and on stdout. Raw step logs stay in
  the private workspace, which is kept for diagnosis.

The registered push token is a controlled test value, not FCM or APNs proof.
"""
import argparse
import json
import os
from pathlib import Path
import plistlib
import re
import shlex
import shutil
import signal
import subprocess
import sys
import tempfile
import time

from run_firebase_device_android import (  # Shared process primitives.
    INSPECT_ENV, Interrupted, RunnerError, locked_versions, product_version,
    run_bounded)

ROOT = Path(__file__).resolve().parents[2]
PROJECT_NAME = 'firebase_readiness'
ORG = 'io.picnic.qa'
BUNDLE_ID = 'io.picnic.qa.firebaseReadiness'  # What `flutter create` derives.
PRODUCT_BUNDLE_ID = 'io.iconcasting.picnic.app'
TEST_SOURCE = ROOT / 'picnic_app/test_support/firebase_readiness_ios_qa.dart'
TEST_TARGET = 'integration_test/firebase_readiness_ios_test.dart'
OWNED_SIMULATOR_PREFIX = 'Picnic Firebase QA'
RUNTIME_ID = re.compile(r'^com\.apple\.CoreSimulator\.SimRuntime\.iOS-\d+(-\d+)*$')
SUPPORTED_XCODE = ('27.2',)
SIMULATOR_UDID = re.compile(
    r'^[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}$')
CREDENTIAL_TOOLS = ('security', 'openssl')
BOUNDARY_DIR = 'qa-credential-boundary'
SPM_WIRING = 'FlutterGeneratedPluginSwiftPackage'
APP_COMMAND_TIMEOUT_S = 60
TOOLCHAIN_ENV = (
    'PATH', 'HOME', 'TMPDIR', 'LANG', 'LC_ALL', 'PUB_CACHE', 'XDG_CONFIG_HOME',
)
PINNED_PACKAGES = (
    'firebase_core', 'firebase_core_platform_interface', 'firebase_messaging',
    'firebase_messaging_platform_interface', 'firebase_analytics',
    'flutter_local_notifications',
)
POD_PINS = (
    'Firebase/CoreOnly', 'Firebase/Messaging', 'FirebaseCore',
    'FirebaseCoreInternal', 'FirebaseInstallations', 'FirebaseMessaging',
    'FirebaseAnalytics', 'firebase_core', 'firebase_messaging',
    'firebase_analytics',
)
# Read by the Firebase SDKs before native Core starts. The AdMob sample iOS
# app ID (https://developers.google.com/admob/ios/quick-start) keeps the
# google_mobile_ads plugin from failing at process start.
QA_PLIST_SETTINGS = {
    'FirebaseMessagingAutoInitEnabled': False,
    'FirebaseAppDelegateProxyEnabled': False,
    'FirebaseDataCollectionDefaultEnabled': False,
    'FIREBASE_ANALYTICS_COLLECTION_ENABLED': False,
    'FIREBASE_ANALYTICS_COLLECTION_DEACTIVATED': True,
    'GOOGLE_ANALYTICS_ADID_COLLECTION_ENABLED': False,
    'GOOGLE_ANALYTICS_IDFV_COLLECTION_ENABLED': False,
    'GOOGLE_ANALYTICS_DEFAULT_ALLOW_AD_PERSONALIZATION_SIGNALS': False,
    'GADApplicationIdentifier': 'ca-app-pub-3940256099942544~1458002511',
}
FORBIDDEN_FILES = (
    'GoogleService-Info.plist', 'google-services.json', '.env', '.env.*',
    '*.entitlements', '*.mobileprovision', '*.p12', '*.cer', 'key.properties',
)
BUILT_APP = 'build/ios/iphonesimulator/Runner.app'


def child_env(environ, developer_dir):
    """Returns the environment for every child process.

    Only TOOLCHAIN_ENV is inherited. DEVELOPER_DIR is always [developer_dir];
    CocoaPods gets a UTF-8 locale and no usage statistics.
    """
    env = {k: environ[k] for k in TOOLCHAIN_ENV if k in environ}
    env['DEVELOPER_DIR'] = str(developer_dir)
    env.setdefault('LANG', 'en_US.UTF-8')
    env['COCOAPODS_DISABLE_STATS'] = 'true'
    return env


def _inspect(command, env, timeout=60, include_stderr=True):
    """Runs a short read-only tool command; returns (exit code, output)."""
    try:
        done = subprocess.run(command, env=env, capture_output=True, text=True,
                              timeout=timeout)
    except (OSError, subprocess.TimeoutExpired) as error:
        raise RunnerError(f'{Path(command[0]).name} did not complete: {error}') from None
    return done.returncode, done.stdout + (done.stderr if include_stderr else '')


def check_xcode(developer_dir, env):
    """Returns the `xcodebuild -version` lines of a supported Xcode."""
    xcodebuild = Path(developer_dir) / 'usr/bin/xcodebuild'
    if not xcodebuild.is_file():
        raise RunnerError(f'{developer_dir} is not an Xcode developer directory')
    code, output = _inspect([str(xcodebuild), '-version'], env)
    lines = output.strip().splitlines()
    match = re.fullmatch(r'Xcode (\d+\.\d+)(?:\.\d+)?', lines[0].strip()) if lines else None
    if code != 0 or not match or match.group(1) not in SUPPORTED_XCODE:
        raise RunnerError(f'unsupported Xcode {lines[:1]}; supported: {SUPPORTED_XCODE}')
    return lines


def simctl(developer_dir):
    return str(Path(developer_dir) / 'usr/bin/simctl')


def find_simulator(listing, udid, runtime_id):
    """The `simctl list devices --json` entry of the owned QA simulator.

    Raises RunnerError for a physical device ID, an unknown UDID, an
    unavailable device, another runtime, or a simulator that is not an owned
    QA simulator.
    """
    if not SIMULATOR_UDID.match(udid):
        raise RunnerError('the target is not a simulator UDID; physical devices '
                          'are not supported')
    if not RUNTIME_ID.match(runtime_id):
        raise RunnerError(f'{runtime_id} is not an iOS simulator runtime identifier')
    for runtime, devices in listing.get('devices', {}).items():
        for device in devices:
            if device.get('udid') != udid:
                continue
            if device.get('isAvailable') is not True:
                raise RunnerError('the target simulator is not available')
            if not str(device.get('name', '')).startswith(OWNED_SIMULATOR_PREFIX):
                raise RunnerError(
                    f'the target simulator name does not start with "{OWNED_SIMULATOR_PREFIX}"')
            if runtime != runtime_id:
                raise RunnerError(f'the target simulator runtime is not {runtime_id}')
            return dict(device, runtime=runtime)
    raise RunnerError('the target UDID is not a simulator on this host')


def simulator_state(developer_dir, env, udid, runtime_id):
    code, output = _inspect([simctl(developer_dir), 'list', 'devices', '--json'], env)
    if code != 0:
        raise RunnerError('simctl list devices did not succeed')
    try:
        listing = json.loads(output)
    except ValueError:
        raise RunnerError('simctl list devices returned no JSON') from None
    return find_simulator(listing, udid, runtime_id)


_FAILED = re.compile(r'fail\w*', re.IGNORECASE)
_NEGATED = re.compile(r'\s*[:=]\s*(false|no|0)\b', re.IGNORECASE)


def boot_failed(lines):
    """True if a bootstatus line reports a failure.

    "Data Migration Failed" fails; "Data Migration Failed=false" (a status
    field with a false value) does not.
    """
    return any(not _NEGATED.match(line, match.end())
               for line in lines for match in _FAILED.finditer(line))


def replace_once(path, old, new):
    text = path.read_text()
    if text.count(old) != 1:
        raise RunnerError(f'expected one "{old}" in {path.name}')
    path.write_text(text.replace(old, new, 1))


def pod_versions(lock):
    """Maps each pod in a Podfile.lock PODS section to its version."""
    text = Path(lock).read_text()
    pods = text.split('\nDEPENDENCIES:', 1)[0]
    return dict(re.findall(r'^  - "?([^\s"(]+) \(([^)]+)\)', pods, re.MULTILINE))


def apply_plist_settings(info_plist):
    with open(info_plist, 'rb') as source:
        plist = plistlib.load(source)
    if plist.get('CFBundleIdentifier') != '$(PRODUCT_BUNDLE_IDENTIFIER)':
        raise RunnerError('generated Info.plist has an unexpected CFBundleIdentifier')
    plist.update(QA_PLIST_SETTINGS)
    with open(info_plist, 'wb') as target:
        plistlib.dump(plist, target)


def check_plist_settings(info_plist):
    """Raises RunnerError unless [info_plist] has every QA_PLIST_SETTINGS value."""
    if not Path(info_plist).is_file():
        raise RunnerError(f'{info_plist} does not exist')
    with open(info_plist, 'rb') as source:
        plist = plistlib.load(source)
    wrong = {key: plist.get(key) for key, value in QA_PLIST_SETTINGS.items()
             if plist.get(key) != value}
    if wrong:
        raise RunnerError(f'Info.plist QA settings are missing or changed: {wrong}')
    return plist


def check_no_forbidden_files(directory):
    found = sorted(str(path.relative_to(directory)) for pattern in FORBIDDEN_FILES
                   for path in Path(directory).rglob(pattern))
    if found:
        raise RunnerError(f'forbidden files in the QA workspace: {found}')


def workspace_processes(workspace):
    """PIDs (other than this one) whose command line holds the workspace path."""
    code, output = _inspect(['/bin/ps', '-axww', '-o', 'pid=,command='], INSPECT_ENV)
    if code != 0:
        raise RunnerError('cannot list processes to verify cleanup')
    roots = {str(workspace), os.path.realpath(workspace)}
    found = []
    for line in output.splitlines():
        pid, _, command = line.strip().partition(' ')
        if pid.isdigit() and int(pid) != os.getpid() and any(
                root in command for root in roots):
            found.append(int(pid))
    return found


_WHICH_BOUNDARY = """#!/bin/sh
# Written by run_firebase_device_ios.py for `flutter create` only.
for name in "$@"; do
  case "${{name##*/}}" in
    security|openssl) printf 'which\\t%s\\n' "$*" >> {log}; exit 1;;
  esac
done
exec /usr/bin/which "$@"
"""
_TOOL_BOUNDARY = """#!/bin/sh
# Written by run_firebase_device_ios.py: records the call, never runs the tool.
printf '{name}\\t%s\\n' "$*" >> {log}
exit 1
"""


def write_credential_boundary(directory, log):
    """Writes the create-step `which`, `security`, and `openssl`; returns bin."""
    bin_dir = Path(directory) / 'bin'
    bin_dir.mkdir(parents=True)
    Path(log).touch()
    quoted = shlex.quote(str(log))
    scripts = {'which': _WHICH_BOUNDARY.format(log=quoted)}
    scripts.update({name: _TOOL_BOUNDARY.format(name=name, log=quoted)
                    for name in CREDENTIAL_TOOLS})
    for name, text in scripts.items():
        (bin_dir / name).write_text(text)
        (bin_dir / name).chmod(0o755)
    return bin_dir


def read_credential_log(log):
    """{'blocked_lookups': [tool], 'credential_tool_calls': [call]}."""
    blocked, calls = [], []
    for line in Path(log).read_text(errors='replace').splitlines():
        tool, _, arguments = line.partition('\t')
        if tool == 'which':
            blocked += [Path(arg).name for arg in arguments.split()
                        if Path(arg).name in CREDENTIAL_TOOLS]
        elif tool:
            calls.append(line)
    return {'blocked_lookups': sorted(set(blocked)), 'credential_tool_calls': calls}


PLUTIL = '/usr/bin/plutil'
PLIST_CONVERT_TIMEOUT_S = 10


def parse_app_list(output):
    """The complete `simctl listapps` property list as a top-level dict.

    The text goes to a bounded `plutil -convert json` on stdin only. A
    conversion failure or timeout, invalid JSON, or a result that is not a
    dictionary raises RunnerError; it is never taken as "absent".
    """
    try:
        done = subprocess.run([PLUTIL, '-convert', 'json', '-o', '-', '--', '-'],
                              input=output, capture_output=True, text=True,
                              timeout=PLIST_CONVERT_TIMEOUT_S, env=INSPECT_ENV)
    except (OSError, subprocess.TimeoutExpired) as error:
        raise RunnerError(f'cannot parse the installed app list: {error}') from None
    if done.returncode != 0:
        raise RunnerError('cannot parse the installed app list: plutil rejected it')
    try:
        apps = json.loads(done.stdout)
    except ValueError:
        raise RunnerError('cannot parse the installed app list: invalid JSON') from None
    if not isinstance(apps, dict):
        raise RunnerError('the installed app list is not a dictionary')
    return apps


def bundle_listed(output, bundle):
    """True if [bundle] is a top-level key of the complete app list."""
    return bundle in parse_app_list(output)


def installed_state(developer_dir, env, udid):
    """True if BUNDLE_ID is installed on [udid], False if it is absent.

    Raises RunnerError if the app list cannot be read or parsed completely;
    that is never taken as "absent". stderr is not part of the list.
    """
    code, output = _inspect([simctl(developer_dir), 'listapps', udid], env,
                            include_stderr=False)
    if code != 0:
        raise RunnerError('cannot list installed apps on the target simulator')
    return bundle_listed(output, BUNDLE_ID)


class QaRun:
    def __init__(self, workspace, env, private=()):
        self.workspace = workspace
        self.env = env
        # Values (the simulator UDID) kept out of qa-result.json and stdout.
        self.private = [value for value in private if value]
        self.logs = workspace / 'qa-logs'
        self.logs.mkdir(exist_ok=True)
        self.result_path = workspace / 'qa-result.json'
        self.result = {'workspace': str(workspace), 'bundle_id': BUNDLE_ID,
                       'steps': []}

    def redact(self, text):
        for value in self.private:
            text = text.replace(value, '<simulator>')
        return text

    def write_result(self, status, error=None):
        self.result['status'] = status
        if error is not None:
            self.result['error'] = error
        text = self.redact(json.dumps(self.result, indent=2) + '\n')
        self.result_path.write_text(text)
        print(f'QA_RESULT={self.result_path}', flush=True)

    def run(self, name, command, timeout, env=None):
        """Runs one bounded step; its output goes to qa-logs/<name>.log."""
        log = self.logs / f'{name}.log'
        started = time.monotonic()
        step = {'name': name, 'command': [self.redact(part) for part in command],
                'log': str(log)}
        self.result['steps'].append(step)
        print(f'QA_STEP={name}', flush=True)
        try:
            with log.open('w') as out:
                step.update(run_bounded(command, cwd=self.workspace,
                                        env=self.env if env is None else env,
                                        stdout=out, timeout=timeout))
        finally:
            step['elapsed_s'] = round(time.monotonic() - started, 1)
            lines = log.read_text(errors='replace').splitlines()
            step['tail'] = [self.redact(line) for line in lines[-15:]]
            print('\n'.join(step['tail']), flush=True)
        if step['cleanup']['remaining']:
            raise RunnerError(f'step {name} left processes that did not stop')
        if step['exit_code'] != 0:
            raise RunnerError(f'step {name} did not succeed (see {log})')
        return lines


def write_pubspec(workspace):
    """Writes the QA pubspec.yaml; it must exist before `flutter create`.

    flutter: config: enable-swift-package-manager: false is the project
    setting that keeps every Flutter step on CocoaPods.
    """
    lib_pubspec = ROOT / 'picnic_lib/pubspec.yaml'
    core = product_version(r'^\s+firebase_core:\s*(\S+)', lib_pubspec)
    messaging = product_version(r'^\s+firebase_messaging:\s*(\S+)', lib_pubspec)
    (Path(workspace) / 'pubspec.yaml').write_text(f"""name: {PROJECT_NAME}
publish_to: none
version: 0.0.1+000101
environment:
  sdk: ^3.9.0
dependencies:
  flutter:
    sdk: flutter
  picnic_lib:
    path: {ROOT / 'picnic_lib'}
  firebase_core: {core}
  firebase_messaging: {messaging}
dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
flutter:
  uses-material-design: true
  config:
    enable-swift-package-manager: false
""")


def create_project(qa, timeout, boundary=None, *, project_name=None, org=None):
    """Runs `flutter create` behind the credential boundary.

    Raises RunnerError if create called `security` or `openssl`, or changed
    the QA pubspec.yaml. [boundary] defaults to a new boundary bin directory
    in the workspace; the log is qa-logs/credential-sentinel.log.
    [project_name] and [org] default to PROJECT_NAME and ORG; another runner
    (run_notification_delivery_ios.py) passes its own values.
    """
    project_name = PROJECT_NAME if project_name is None else project_name
    org = ORG if org is None else org
    log = qa.logs / 'credential-sentinel.log'
    if boundary is None:
        boundary = write_credential_boundary(qa.workspace / BOUNDARY_DIR, log)
    pubspec = qa.workspace / 'pubspec.yaml'
    before = pubspec.read_text()
    env = dict(qa.env, PATH=f'{boundary}{os.pathsep}{qa.env.get("PATH", "")}')
    try:
        qa.run('flutter-create', [
            'flutter', 'create', '--platforms=ios', '--project-name', project_name,
            '--org', org, '--no-pub', str(qa.workspace),
        ], timeout, env=env)
    finally:
        report = qa.result['signing_boundary'] = read_credential_log(log)
        if report['credential_tool_calls']:
            raise RunnerError('flutter create reached a credential tool through the '
                              f'boundary: {report["credential_tool_calls"]}')
    if pubspec.read_text() != before:
        raise RunnerError('flutter create changed the QA pubspec.yaml')


def check_no_spm_wiring(workspace):
    project = (Path(workspace) / 'ios/Runner.xcodeproj/project.pbxproj').read_text()
    if SPM_WIRING in project:
        raise RunnerError(f'the Xcode project has Swift Package Manager wiring ({SPM_WIRING})')


def check_dependency_manager(qa):
    """Raises RunnerError unless Flutter resolved iOS plugins for CocoaPods."""
    check_no_spm_wiring(qa.workspace)
    path = qa.workspace / '.flutter-plugins-dependencies'
    try:
        data = json.loads(path.read_text())
    except (OSError, ValueError):
        raise RunnerError('.flutter-plugins-dependencies is missing or unreadable') from None
    enabled = (data.get('swift_package_manager_enabled') or {}).get('ios')
    qa.result['dependency_manager'] = {'swift_package_manager_enabled': enabled,
                                       'manager': 'cocoapods'}
    if enabled is True:
        qa.result['dependency_manager']['manager'] = 'swiftpm'
        raise RunnerError('Flutter selected Swift Package Manager for iOS plugins')


SIMULATOR_ARCHS = ('arm64', 'x86_64')
_SIM_ARCH_SETTING = re.compile(r'^ARCHS\[sdk=iphonesimulator\*\] = (\S+)$', re.MULTILINE)
_ANY_ARCHS_SETTING = re.compile(r'^\s*ARCHS(\[[^\]]*\])?\s*=', re.MULTILINE)


def host_simulator_arch():
    """The host's native architecture, which the QA simulator build uses.

    `uname -m` reports x86_64 in a translated (Rosetta) process on Apple
    silicon, so x86_64 is confirmed with hw.optional.arm64. Anything other
    than arm64 or x86_64 raises RunnerError.
    """
    code, output = _inspect(['/usr/bin/uname', '-m'], INSPECT_ENV, include_stderr=False)
    machine = output.strip() if code == 0 else ''
    if machine == 'x86_64':
        code, output = _inspect(['/usr/sbin/sysctl', '-n', 'hw.optional.arm64'],
                                INSPECT_ENV, include_stderr=False)
        if code == 0 and output.strip() == '1':
            machine = 'arm64'
    if machine not in SIMULATOR_ARCHS:
        raise RunnerError(f'unsupported simulator architecture for this host: '
                          f'{machine or "unknown"}')
    return machine


def set_simulator_arch(workspace, arch):
    """Limits the QA Runner Debug simulator build to [arch].

    The setting goes into ios/Flutter/Debug.xcconfig, the base configuration
    of the generated Runner Debug build; Release and Profile are unchanged.
    """
    ios = Path(workspace) / 'ios'
    project = (ios / 'Runner.xcodeproj/project.pbxproj').read_text()
    if not re.search(r'baseConfigurationReference = \w+ /\* Debug\.xcconfig \*/;', project):
        raise RunnerError('the generated Runner Debug build does not use Flutter/Debug.xcconfig')
    xcconfig = ios / 'Flutter/Debug.xcconfig'
    text = xcconfig.read_text()
    if _ANY_ARCHS_SETTING.search(project) or _ANY_ARCHS_SETTING.search(text):
        raise RunnerError('the generated project already sets ARCHS')
    xcconfig.write_text(text + '\n// Added by run_firebase_device_ios.py (QA only): one '
                        'simulator architecture.\n'
                        f'ARCHS[sdk=iphonesimulator*] = {arch}\n')


def check_simulator_arch(workspace, arch):
    text = (Path(workspace) / 'ios/Flutter/Debug.xcconfig').read_text()
    if _SIM_ARCH_SETTING.findall(text) != [arch]:
        raise RunnerError(f'the QA Debug simulator architecture setting ({arch}) is '
                          'missing or changed')


def prepare_project(qa, arch):
    workspace = qa.workspace
    ios = workspace / 'ios'
    if (workspace / 'android').exists():
        raise RunnerError('the QA project must be iOS only')
    check_no_spm_wiring(workspace)
    pbxproj = ios / 'Runner.xcodeproj/project.pbxproj'
    project = pbxproj.read_text()
    bundle_ids = set(re.findall(r'PRODUCT_BUNDLE_IDENTIFIER = ([^;]+);', project))
    if (BUNDLE_ID not in bundle_ids or PRODUCT_BUNDLE_ID in project
            or any(not value.startswith(BUNDLE_ID) for value in bundle_ids)):
        raise RunnerError(f'generated bundle identifier is not {BUNDLE_ID}: {sorted(bundle_ids)}')
    for setting in ('CODE_SIGN_ENTITLEMENTS', 'DEVELOPMENT_TEAM', 'PROVISIONING_PROFILE'):
        if setting in project:
            raise RunnerError(f'generated project must not set {setting}')
    if 'RunnerTests' not in project:
        raise RunnerError('generated project has no RunnerTests target for the product Podfile')

    # The product app's deployment target, so the app links the product pods.
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
    set_simulator_arch(workspace, arch)

    (workspace / 'integration_test').mkdir(exist_ok=True)
    shutil.copyfile(TEST_SOURCE, workspace / TEST_TARGET)

    apply_plist_settings(ios / 'Runner/Info.plist')
    check_plist_settings(ios / 'Runner/Info.plist')

    product_podfile = ROOT / 'picnic_app/ios/Podfile'
    sdk = product_version(r"^\$FirebaseSDKVersion = '([^']+)'", product_podfile)
    shutil.copyfile(product_podfile, ios / 'Podfile')
    shutil.copyfile(ROOT / 'picnic_app/ios/Podfile.lock', ios / 'Podfile.lock')
    qa.result['toolchain'] = {'ios_deployment_target': deployment,
                              'firebase_sdk_version': sdk}
    check_no_forbidden_files(workspace)


def check_pods(qa):
    expected = pod_versions(ROOT / 'picnic_app/ios/Podfile.lock')
    actual = pod_versions(qa.workspace / 'ios/Podfile.lock')
    qa.result['pod_versions'] = {name: actual.get(name) for name in POD_PINS}
    drift = {name: [expected.get(name), actual.get(name)] for name in POD_PINS
             if actual.get(name) is None or actual.get(name) != expected.get(name)}
    if drift:
        raise RunnerError(f'Podfile.lock differs from the product lock: {drift}')


def execute(qa, args, sim):
    developer_dir = args.developer_dir
    qa.result['xcode'] = check_xcode(developer_dir, qa.env)
    arch = qa.result['simulator_arch'] = host_simulator_arch()
    device = simulator_state(developer_dir, qa.env, args.simulator_udid,
                             args.simulator_runtime)
    sim['initial_state'] = device.get('state')
    qa.result['simulator'] = {'name': device['name'], 'runtime': device['runtime'],
                              'initial_state': device.get('state')}
    if device.get('state') == 'Shutdown' and not args.boot_if_shutdown:
        raise RunnerError('the target simulator is Shutdown; boot it first or pass '
                          '--boot-if-shutdown')
    if device.get('state') not in ('Booted', 'Shutdown'):
        raise RunnerError(f'the target simulator is {device.get("state")}')

    write_pubspec(qa.workspace)
    create_project(qa, args.create_timeout)
    prepare_project(qa, arch)

    shutil.copyfile(ROOT / 'picnic_lib/pubspec.lock', qa.workspace / 'pubspec.lock')
    qa.run('pub-get', ['flutter', 'pub', 'get'], args.pub_timeout)
    expected = locked_versions(ROOT / 'picnic_lib/pubspec.lock')
    actual = locked_versions(qa.workspace / 'pubspec.lock')
    qa.result['locked_versions'] = {name: actual.get(name) for name in PINNED_PACKAGES}
    missing = [name for name in PINNED_PACKAGES if name not in actual]
    drift = {name: [expected[name], actual[name]]
             for name in expected if name in actual and expected[name] != actual[name]}
    if missing or drift:
        raise RunnerError(
            f'lock mismatch with picnic_lib/pubspec.lock: missing={missing} drift={drift}')
    check_dependency_manager(qa)

    # Builds (and runs `pod install`) before anything is installed, so the
    # pod versions and the built Info.plist are checked first.
    qa.run('build-simulator', [
        'flutter', 'build', 'ios', '--simulator', '--debug', '--no-pub',
        '--target', TEST_TARGET,
    ], args.build_timeout)
    check_dependency_manager(qa)
    check_simulator_arch(qa.workspace, arch)
    check_pods(qa)
    app = qa.workspace / BUILT_APP
    check_plist_settings(app / 'Info.plist')
    check_no_forbidden_files(app)

    if device.get('state') == 'Shutdown':
        sim['booted_by_runner'] = True
        lines = qa.run('simulator-boot', [simctl(developer_dir), 'bootstatus',
                                          args.simulator_udid, '-b'], args.boot_timeout)
        if boot_failed(lines):
            raise RunnerError('simctl bootstatus reported a boot failure')
    device = simulator_state(developer_dir, qa.env, args.simulator_udid,
                             args.simulator_runtime)
    if device.get('state') != 'Booted':
        raise RunnerError(f'the target simulator is {device.get("state")}, not Booted')

    # Ownership: only a bundle that is absent now can become this run's app.
    if installed_state(developer_dir, qa.env, args.simulator_udid):
        raise RunnerError(f'{BUNDLE_ID} is already installed on the target simulator; '
                          "it is not this run's app and is left untouched")
    sim['qa_app_owned'] = True

    lines = qa.run('simulator-test', [
        'flutter', 'test', '--no-pub', TEST_TARGET, '-d', args.simulator_udid,
        '--timeout', '10m',
    ], args.test_timeout)
    summary = [line for line in lines
               if 'All tests passed' in line or 'Some tests failed' in line]
    qa.result['test_summary'] = qa.redact(summary[-1]) if summary else None


def remove_owned_app(qa, args):
    """Removes this run's QA app if it is still installed.

    Only BUNDLE_ID on the validated simulator is touched. 'final' is
    'absent', 'installed', or 'unknown' (the app list could not be read).
    """
    report = {'actions': [], 'final': 'unknown'}
    try:
        if installed_state(args.developer_dir, qa.env, args.simulator_udid):
            with (qa.logs / 'qa-app-cleanup.log').open('a') as out:
                # terminate fails if the app is not running; uninstall decides.
                for action in ('terminate', 'uninstall'):
                    outcome = run_bounded(
                        [simctl(args.developer_dir), action, args.simulator_udid,
                         BUNDLE_ID], cwd=qa.workspace, env=qa.env, stdout=out,
                        timeout=APP_COMMAND_TIMEOUT_S)
                    report['actions'].append({'action': action, **outcome})
        installed = installed_state(args.developer_dir, qa.env, args.simulator_udid)
        report['final'] = 'installed' if installed else 'absent'
    except RunnerError as error:
        report['error'] = str(error)
    return report


def cleanup(qa, args, sim):
    """Restores what the runner changed; 'verified' is True only if clean."""
    report = {'simulator': None, 'workspace_processes': None, 'verified': False}
    problems = []
    if sim.get('qa_app_owned'):
        report['qa_app'] = remove_owned_app(qa, args)
        if report['qa_app']['final'] != 'absent':
            problems.append("this run's QA app is not verified as removed")
        # A nonzero exit is allowed (terminate of a stopped app); a process
        # group that remains or has no verified result is not.
        unverified = [action['action'] for action in report['qa_app']['actions']
                      if (action.get('cleanup') or {}).get('remaining') is not False]
        if unverified:
            problems.append(f'QA app cleanup actions did not verify their process '
                            f'groups: {unverified}')
    if sim.get('booted_by_runner'):
        log = qa.logs / 'simulator-shutdown.log'
        with log.open('w') as out:
            outcome = run_bounded([simctl(args.developer_dir), 'shutdown',
                                   args.simulator_udid], cwd=qa.workspace,
                                  env=qa.env, stdout=out, timeout=args.boot_timeout)
        state = simulator_state(args.developer_dir, qa.env, args.simulator_udid,
                                args.simulator_runtime).get('state')
        report['simulator'] = {'shutdown': outcome, 'final_state': state}
        if state != 'Shutdown' or outcome['cleanup']['remaining']:
            problems.append('the simulator that the runner booted is not Shutdown')
    else:
        report['simulator'] = {'left_as': sim.get('initial_state')}
    report['workspace_processes'] = workspace_processes(qa.workspace)
    if report['workspace_processes']:
        problems.append('processes that hold the workspace path are still running')
    report['problems'] = problems
    report['verified'] = not problems
    return report


def parse_args(argv):
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument('--simulator-udid', required=True,
                        help=f'UDID of an owned "{OWNED_SIMULATOR_PREFIX} ..." simulator')
    parser.add_argument('--simulator-runtime', required=True,
                        help='runtime identifier the target must use, for example '
                             'com.apple.CoreSimulator.SimRuntime.iOS-26-5')
    parser.add_argument('--developer-dir', required=True, type=Path,
                        help='Xcode developer directory, for example '
                             '/Applications/Xcode.app/Contents/Developer')
    parser.add_argument('--boot-if-shutdown', action='store_true',
                        help='boot a Shutdown target and shut it down at the end')
    parser.add_argument('--create-timeout', type=int, default=300)
    parser.add_argument('--pub-timeout', type=int, default=900)
    parser.add_argument('--build-timeout', type=int, default=3600,
                        help='seconds for pod install and the simulator build')
    parser.add_argument('--boot-timeout', type=int, default=300)
    parser.add_argument('--test-timeout', type=int, default=2400,
                        help='seconds for the incremental build and the test')
    return parser.parse_args(argv)


def _raise_interrupted(signum, frame):
    raise Interrupted()


def main(argv=None, environ=None):
    args = parse_args(argv)
    workspace = Path(tempfile.mkdtemp(prefix='picnic-firebase-readiness-ios-qa-'))
    print(f'QA_WORKSPACE={workspace}', flush=True)
    qa = QaRun(workspace, {}, private=[args.simulator_udid])
    sim = {}
    status, error, code = 'failed', None, 1
    previous = signal.signal(signal.SIGTERM, _raise_interrupted)
    try:
        try:
            qa.env = child_env(os.environ if environ is None else environ,
                               args.developer_dir)
            qa.result['developer_dir'] = qa.env['DEVELOPER_DIR']
            execute(qa, args, sim)
            status, code = 'passed', 0
        except RunnerError as caught:
            error = str(caught)
        except (KeyboardInterrupt, Interrupted):
            status, error, code = 'interrupted', 'the runner was interrupted', 130
        except Exception as caught:  # Reported, after cleanup, as a failure.
            error = f'unexpected error: {caught!r}'

        try:
            report = cleanup(qa, args, sim)
        except BaseException as caught:  # Includes a second interrupt.
            report = {'error': repr(caught), 'verified': False}
        qa.result['cleanup'] = report
        if report.get('verified') is not True:
            problem = ('cleanup is not verified; the workspace is kept for '
                       f'inspection: {report}')
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

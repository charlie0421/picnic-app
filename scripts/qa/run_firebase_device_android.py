"""Run the native Firebase readiness probe on one Android device.

Builds a disposable Flutter app (package io.picnic.qa.firebase_readiness) in a
new temporary workspace that depends on the current picnic_lib source, then
runs picnic_app/test_support/firebase_readiness_device_qa.dart on the device
given by --device.

Isolation:
- No google-services configuration, env, signing, or account files are used.
  The test supplies demo FirebaseOptions only.
- Firebase Messaging auto-init and Analytics collection are disabled in the
  manifest, so they are off before native Firebase Core starts.
- The product package and repository pubspec/lock files are not changed. The
  runner does not uninstall or start any other package and uses no adb
  command except a read-only device state check.
- Child processes get only the toolchain environment variables listed in
  TOOLCHAIN_ENV. On macOS every child also gets
  DEVELOPER_DIR=/Library/Developer/CommandLineTools: `flutter -d` starts
  every device discoverer, and with the Xcode selection the iOS discoverer
  can start `xcodebuild -runFirstLaunch`. The global Xcode selection is not
  changed.
- Each step runs in its own process group. On timeout, interruption, or exit
  the runner stops that group with SIGTERM, then SIGKILL, and waits before it
  reports. Processes outside the group (for example a shared adb server) are
  never signalled.
- Every child gets the fixed GRADLE_OPTS below (an inherited value is never
  used) and GRADLE_USER_HOME=<workspace>/gradle-user-home, a new directory
  for this run only. No shared gradle.properties, init script, daemon
  registry, or cache is used, so the Gradle wrapper downloads the pinned
  distribution and the build downloads its dependencies into that home. HOME
  is not changed.
- A Gradle daemon JVM can still start (a single-use daemon when the build's
  JVM arguments differ from the client's). It is detached from the step's
  process group, so group cleanup does not stop it. After every run - pass,
  failure, timeout, KeyboardInterrupt, or SIGTERM - and before the result is
  written, stop_owned_gradle() runs `gradle --stop` with the owned home's own
  distribution (it never downloads one for this), then finds every daemon PID
  from <owned home>/daemon/*/daemon-<pid>.out.log. A PID counts as owned only
  if the live process holds a file inside the owned home (`lsof`); its `ps`
  start time is recorded and must be unchanged before each SIGTERM or
  SIGKILL. A GradleDaemon that holds nothing there, or whose identity
  changes, is never signalled and makes the cleanup unverified. A live PID
  that cannot be inspected is an error, not "gone". If `--stop` leaves a
  process, an owned PID survives, or ownership is ambiguous, the run fails
  and the workspace is kept. No other process is signalled.
- The generated app's android.kotlinOptions { jvmTarget = JavaVersion
  .VERSION_17.toString() } block, which Kotlin 2.4 rejects, is replaced by
  kotlin.compilerOptions with JvmTarget.JVM_17. Java stays at 17; any other
  block shape fails the run.

The registered push token is a controlled test value, not FCM server proof.
"""
import argparse
import json
import os
from pathlib import Path
import re
import shutil
import signal
import subprocess
import sys
import tempfile
import time

ROOT = Path(__file__).resolve().parents[2]
PROJECT_NAME = 'firebase_readiness'
ORG = 'io.picnic.qa'
PACKAGE = f'{ORG}.{PROJECT_NAME}'
PRODUCT_PACKAGE = 'io.iconcasting.picnic.app'
TEST_SOURCE = ROOT / 'picnic_app/test_support/firebase_readiness_device_qa.dart'
TEST_TARGET = 'integration_test/firebase_readiness_test.dart'
TOOLCHAIN_ENV = (
    'PATH', 'HOME', 'TMPDIR', 'LANG', 'LC_ALL', 'ANDROID_HOME',
    'ANDROID_SDK_ROOT', 'JAVA_HOME', 'PUB_CACHE', 'XDG_CONFIG_HOME',
)
OWNED_GRADLE_HOME = 'gradle-user-home'
GRADLE_STOP_TIMEOUT_S = 60
# Rounding allowance for the 1-second `ps` start time. A process that started
# before the owned home existed is excluded; this never proves ownership.
START_SLACK_S = 2.0
COMMAND_LINE_TOOLS = '/Library/Developer/CommandLineTools'
# Packages whose resolved versions must equal picnic_lib/pubspec.lock.
PINNED_PACKAGES = (
    'firebase_core', 'firebase_core_platform_interface', 'firebase_messaging',
    'firebase_messaging_platform_interface', 'firebase_analytics',
    'flutter_local_notifications',
)
# Fixed for every child. They ask for no persistent daemon and an in-process
# Kotlin compiler; they do not stop Gradle from forking a single-use daemon
# JVM, which stop_owned_gradle() handles.
GRADLE_OPTS = (
    '-Dorg.gradle.daemon=false '
    '-Dorg.gradle.project.kotlin.compiler.execution.strategy=in-process'
)
# Same request in the project file, for tools that read only that file.
GRADLE_PROPERTIES = (
    '\n# Added by run_firebase_device_android.py (GRADLE_OPTS is the effective control).\n'
    'org.gradle.daemon=false\n'
    'kotlin.compiler.execution.strategy=in-process\n'
)
TERM_GRACE_S = 10.0
KILL_WAIT_S = 5.0


class RunnerError(Exception):
    """A precondition or step failed; the run is reported as failed."""


class Interrupted(BaseException):
    """The runner received SIGTERM."""


def child_env(environ, platform=None, path_exists=os.path.isdir,
              gradle_user_home=None):
    """Returns the environment for every child process.

    Only TOOLCHAIN_ENV is inherited. GRADLE_OPTS is always the fixed value
    and GRADLE_USER_HOME is [gradle_user_home] (unset when it is None). On
    macOS DEVELOPER_DIR is always the Command Line Tools path. Inherited
    values of these three are never used.
    """
    platform = sys.platform if platform is None else platform
    env = {k: environ[k] for k in TOOLCHAIN_ENV if k in environ}
    env['GRADLE_OPTS'] = GRADLE_OPTS
    if gradle_user_home is not None:
        env['GRADLE_USER_HOME'] = str(gradle_user_home)
    if platform == 'darwin':
        if not path_exists(COMMAND_LINE_TOOLS):
            raise RunnerError(
                f'{COMMAND_LINE_TOOLS} is required: it keeps Flutter device '
                'discovery from starting xcodebuild -runFirstLaunch')
        env['DEVELOPER_DIR'] = COMMAND_LINE_TOOLS
    return env


def _group_alive(pgid):
    try:
        os.killpg(pgid, 0)
    except ProcessLookupError:
        return False
    except PermissionError:
        return True
    return True


def _wait_group_gone(process, pgid, seconds):
    deadline = time.monotonic() + seconds
    while True:
        process.poll()  # Reaps the leader, so a zombie does not count.
        if not _group_alive(pgid):
            return True
        if time.monotonic() >= deadline:
            return False
        time.sleep(0.05)


def stop_process_group(process, grace=TERM_GRACE_S, kill_wait=KILL_WAIT_S):
    """Stops every process left in the step's own process group.

    The group ID is the leader's PID (start_new_session). A PID is not reused
    while a group with that ID exists, so only owned processes get signals.
    """
    pgid = process.pid
    report = {'signal': None, 'remaining': False}
    process.poll()
    if not _group_alive(pgid):
        return report
    report['signal'] = 'SIGTERM'
    try:
        os.killpg(pgid, signal.SIGTERM)
    except ProcessLookupError:
        pass
    if not _wait_group_gone(process, pgid, grace):
        report['signal'] = 'SIGKILL'
        try:
            os.killpg(pgid, signal.SIGKILL)
        except ProcessLookupError:
            pass
        report['remaining'] = not _wait_group_gone(process, pgid, kill_wait)
    try:
        process.wait(timeout=kill_wait)
    except subprocess.TimeoutExpired:
        report['remaining'] = True
    return report


def run_bounded(command, *, cwd, env, stdout, timeout, grace=TERM_GRACE_S,
                on_start=None):
    """Runs one command in a new process group, bounded by [timeout].

    The group is stopped before this returns or re-raises, also after
    KeyboardInterrupt, Interrupted, or any other error. [on_start] receives
    the process group ID.
    """
    process = subprocess.Popen(
        command, cwd=cwd, env=env, stdout=stdout, stderr=subprocess.STDOUT,
        start_new_session=True,
    )
    outcome = {'exit_code': None}
    try:
        if on_start is not None:
            on_start(process.pid)
        outcome['exit_code'] = process.wait(timeout=timeout)
    except subprocess.TimeoutExpired:
        outcome['timed_out_after_s'] = timeout
    finally:
        outcome['cleanup'] = stop_process_group(process, grace)
    return outcome


INSPECT_ENV = {'PATH': '/usr/sbin:/usr/bin:/sbin:/bin', 'LC_ALL': 'C'}


def _confirmed_absent(pid):
    """True only on ESRCH. A PID that exists but cannot be probed is an error."""
    try:
        os.kill(pid, 0)
    except ProcessLookupError:
        return True
    except PermissionError:
        raise RunnerError(f'PID {pid} exists but cannot be inspected') from None
    return False


def process_info(pid):
    """Returns (command, birth) for a live PID, or None if it is confirmed gone.

    birth is the `ps` start time (lstart). It stays the same for the life of
    a process, so a changed birth means the PID now belongs to another
    process. Raises RunnerError if a live PID cannot be read.
    """
    try:
        completed = subprocess.run(
            ['/bin/ps', '-ww', '-o', 'lstart=,command=', '-p', str(pid)],
            capture_output=True, text=True, timeout=10, env=INSPECT_ENV)
    except (OSError, subprocess.TimeoutExpired) as error:
        raise RunnerError(f'cannot inspect PID {pid}: {error}') from None
    fields = completed.stdout.split(None, 5)
    if completed.returncode != 0 or len(fields) < 6:
        if _confirmed_absent(pid):
            return None
        raise RunnerError(f'PID {pid} is alive but ps returned no usable data')
    birth = ' '.join(fields[:5])
    try:
        time.strptime(birth, '%a %b %d %H:%M:%S %Y')
    except ValueError:
        raise RunnerError(f'cannot read the start time of PID {pid}') from None
    return fields[5].strip(), birth


def open_paths(pid):
    """Paths that PID has open, or None if it is confirmed gone."""
    lsof = shutil.which('lsof', path=INSPECT_ENV['PATH'])
    if lsof is None:
        raise RunnerError('lsof is required to check Gradle daemon ownership')
    try:
        completed = subprocess.run(
            [lsof, '-n', '-P', '-a', '-p', str(pid), '-Fn'],
            capture_output=True, text=True, timeout=30, env=INSPECT_ENV)
    except (OSError, subprocess.TimeoutExpired) as error:
        raise RunnerError(f'cannot list open files of PID {pid}: {error}') from None
    paths = [line[1:] for line in completed.stdout.splitlines() if line.startswith('n')]
    if completed.returncode != 0 or not paths:
        if _confirmed_absent(pid):
            return None
        raise RunnerError(f'cannot list open files of live PID {pid}')
    return paths


def _classify(pid, gradle_home, created_at):
    """('absent'|'owned'|'foreign'|'ambiguous', birth) for one logged PID.

    'owned' requires both a GradleDaemon command line and a positive binding:
    the live process holds a file inside [gradle_home] (a Gradle daemon holds
    its log there). Any other process is 'foreign', even if it holds a file
    there (a log viewer). A GradleDaemon that holds nothing there is
    'ambiguous': it is never signalled, and the cleanup is not verified.
    """
    info = process_info(pid)
    if info is None:
        return 'absent', None
    command, birth = info
    if 'GradleDaemon' not in command:
        return 'foreign', birth
    started = time.mktime(time.strptime(birth, '%a %b %d %H:%M:%S %Y'))
    if started < created_at - START_SLACK_S:
        return 'foreign', birth  # Started before this home existed.
    paths = open_paths(pid)
    if paths is None:
        return 'absent', None
    roots = {str(gradle_home), os.path.realpath(gradle_home)}
    if any(path == root or path.startswith(root + os.sep)
           for path in paths for root in roots):
        return 'owned', birth
    return 'ambiguous', birth


def owned_daemon_pids(gradle_home):
    """PIDs from the daemon logs that Gradle writes in this home only."""
    pids = set()
    for log in Path(gradle_home).glob('daemon/*/daemon-*.out.log'):
        match = re.fullmatch(r'daemon-(\d+)\.out\.log', log.name)
        if match:
            pids.add(int(match.group(1)))
    return sorted(pids)


def stop_owned_gradle(gradle_home, env, created_at, *, cwd, log, launcher=None,
                      grace=TERM_GRACE_S, kill_wait=KILL_WAIT_S,
                      stop_timeout=GRADLE_STOP_TIMEOUT_S):
    """Stops every Gradle daemon JVM that belongs to [gradle_home].

    [created_at] is when [gradle_home] was created. [launcher] defaults to the
    distribution inside [gradle_home]; if there is none, no `--stop` runs,
    because a daemon needs that distribution and `--stop` through the wrapper
    could download it. Each owned PID's birth is recorded and checked again
    before every signal; a changed identity stops signalling it. The report's
    'verified' is True only if `--stop` left no process, no owned PID
    remains, and no PID was ambiguous. Raises RunnerError if a live PID
    cannot be inspected.
    """
    gradle_home = Path(gradle_home)
    report = {'gradle_user_home': str(gradle_home), 'launcher': None,
              'stop': None, 'daemon_pids': [], 'ignored': [], 'ambiguous': [],
              'signalled': [], 'remaining': [], 'verified': False}
    if launcher is None:
        found = sorted(gradle_home.glob('wrapper/dists/*/*/gradle-*/bin/gradle'))
        launcher = found[-1] if found else None
    if launcher is not None:
        report['launcher'] = str(launcher)
        with open(log, 'w') as out:
            report['stop'] = run_bounded(
                [str(launcher), '--stop'], cwd=cwd, stdout=out,
                env=dict(env, GRADLE_USER_HOME=str(gradle_home)),
                timeout=stop_timeout)

    report['daemon_pids'] = owned_daemon_pids(gradle_home)
    owned = {}  # PID -> birth recorded when ownership was proven.
    for pid in report['daemon_pids']:
        state, birth = _classify(pid, gradle_home, created_at)
        if state == 'owned':
            owned[pid] = birth
        elif state in ('ambiguous', 'foreign'):
            report['ignored' if state == 'foreign' else 'ambiguous'].append(pid)

    def still_owned(pid):
        """Re-checks one owned PID; drops it if gone or no longer the same."""
        state, birth = _classify(pid, gradle_home, created_at)
        if state == 'owned' and birth == owned[pid]:
            return True
        if state != 'absent':
            report['ambiguous'].append(pid)  # Same PID, another process.
        del owned[pid]
        return False

    for signum, wait in ((signal.SIGTERM, grace), (signal.SIGKILL, kill_wait)):
        live = [pid for pid in list(owned) if still_owned(pid)]
        if not live:
            break
        for pid in live:
            try:
                os.kill(pid, signum)
                report['signalled'].append([pid, signum.name])
            except ProcessLookupError:
                pass
        deadline = time.monotonic() + wait
        while time.monotonic() < deadline and any(
                still_owned(pid) for pid in list(owned) if pid in live):
            time.sleep(0.2)
    report['remaining'] = [pid for pid in list(owned) if still_owned(pid)]
    stop_left_processes = bool(report['stop'] and report['stop']['cleanup']['remaining'])
    report['verified'] = not (stop_left_processes or report['remaining']
                              or report['ambiguous'])
    return report


# The block that `flutter create` writes into android { } of the generated
# app/build.gradle.kts. Kotlin 2.4 rejects this String DSL.
GENERATED_KOTLIN_OPTIONS = re.compile(
    r'\n[ \t]*kotlinOptions \{\n'
    r'[ \t]*jvmTarget = JavaVersion\.VERSION_17\.toString\(\)\n'
    r'[ \t]*\}\n')
TYPED_KOTLIN_JVM_TARGET = '''
kotlin {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
    }
}
'''


def migrate_kotlin_jvm_target(app_gradle):
    """Moves the generated JVM 17 target to the typed kotlin.compilerOptions DSL.

    Only the exact generated block is accepted, and Java must target 17 too.
    Anything else fails, so the runner never guesses a JVM target.
    """
    text = app_gradle.read_text()
    for java in ('sourceCompatibility = JavaVersion.VERSION_17',
                 'targetCompatibility = JavaVersion.VERSION_17'):
        if java not in text:
            raise RunnerError(f'generated app/build.gradle.kts lacks "{java}"')
    text, count = GENERATED_KOTLIN_OPTIONS.subn('\n', text)
    if count != 1 or 'kotlinOptions' in text:
        raise RunnerError(
            'generated app/build.gradle.kts has no single supported kotlinOptions '
            '{ jvmTarget = JavaVersion.VERSION_17.toString() } block to migrate')
    app_gradle.write_text(text + TYPED_KOTLIN_JVM_TARGET)


def replace_once(path, old, new):
    text = path.read_text()
    if text.count(old) != 1:
        raise RunnerError(f'expected one "{old}" in {path.name}')
    path.write_text(text.replace(old, new, 1))


def product_version(pattern, source):
    match = re.search(pattern, source.read_text(), re.MULTILINE)
    if not match:
        raise RunnerError(f'no version for {pattern} in {source}')
    return match.group(1)


def locked_versions(lock):
    """Maps each package in a pubspec.lock to its resolved version."""
    return dict(re.findall(
        r'^  ([a-z0-9_]+):\n(?:    .*\n)*?    version: "([^"]+)"',
        lock.read_text(), re.MULTILINE,
    ))


class QaRun:
    def __init__(self, workspace, env, private=()):
        self.workspace = workspace
        self.env = env
        # Values (the device serial) kept out of qa-result.json and stdout.
        # The raw step logs in qa-logs/ stay private to the workspace.
        self.private = [value for value in private if value]
        self.logs = workspace / 'qa-logs'
        self.logs.mkdir(exist_ok=True)
        self.result_path = workspace / 'qa-result.json'
        self.result = {'workspace': str(workspace), 'package': PACKAGE, 'steps': []}

    def redact(self, text):
        for value in self.private:
            text = text.replace(value, '<device>')
        return text

    def write_result(self, status, error=None):
        self.result['status'] = status
        if error is not None:
            self.result['error'] = error
        self.result_path.write_text(json.dumps(self.result, indent=2) + '\n')
        print(f'QA_RESULT={self.result_path}', flush=True)

    def run(self, name, command, timeout):
        """Runs one bounded step; its output goes to qa-logs/<name>.log."""
        log = self.logs / f'{name}.log'
        started = time.monotonic()
        step = {'name': name, 'command': [self.redact(part) for part in command],
                'log': str(log)}
        self.result['steps'].append(step)
        print(f'QA_STEP={name}', flush=True)
        try:
            with log.open('w') as out:
                step.update(run_bounded(command, cwd=self.workspace, env=self.env,
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


def prepare_project(qa, args):
    workspace = qa.workspace
    lib_pubspec = ROOT / 'picnic_lib/pubspec.yaml'
    core = product_version(r'^\s+firebase_core:\s*(\S+)', lib_pubspec)
    messaging = product_version(r'^\s+firebase_messaging:\s*(\S+)', lib_pubspec)
    (workspace / 'pubspec.yaml').write_text(f"""name: {PROJECT_NAME}
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
""")
    (workspace / 'integration_test').mkdir(exist_ok=True)
    shutil.copyfile(TEST_SOURCE, workspace / TEST_TARGET)

    android = workspace / 'android'
    app_gradle = android / 'app/build.gradle.kts'
    app_text = app_gradle.read_text()
    if f'applicationId = "{PACKAGE}"' not in app_text or PRODUCT_PACKAGE in app_text:
        raise RunnerError(f'generated applicationId is not {PACKAGE}')

    # Match the product's Kotlin, AGP, and Gradle versions (Kotlin 2.4.x
    # plugins do not build with an older Kotlin Gradle plugin). The product
    # declares AGP with single quotes and Kotlin with double quotes.
    product_settings = ROOT / 'picnic_app/android/settings.gradle'
    kotlin = product_version(r'"org\.jetbrains\.kotlin\.android" version "([^"]+)"', product_settings)
    agp = product_version(r'"com\.android\.application" version \'([^\']+)\'', product_settings)
    settings = android / 'settings.gradle.kts'
    text, kotlin_count = re.subn(
        r'(id\("org\.jetbrains\.kotlin\.android"\) version ")[^"]+"',
        rf'\g<1>{kotlin}"', settings.read_text())
    text, agp_count = re.subn(
        r'(id\("com\.android\.application"\) version ")[^"]+"',
        rf'\g<1>{agp}"', text)
    if kotlin_count != 1 or agp_count != 1:
        raise RunnerError('generated settings.gradle.kts has an unexpected plugin block')
    settings.write_text(text)
    wrapper = android / 'gradle/wrapper/gradle-wrapper.properties'
    product_wrapper = ROOT / 'picnic_app/android/gradle/wrapper/gradle-wrapper.properties'
    distribution = product_version(r'^(distributionUrl=.*)$', product_wrapper)
    wrapper.write_text(re.sub(r'^distributionUrl=.*$', lambda _: distribution,
                              wrapper.read_text(), flags=re.MULTILINE))
    qa.result['toolchain'] = {'kotlin': kotlin, 'agp': agp, 'gradle': distribution}

    gradle_properties = android / 'gradle.properties'
    existing = gradle_properties.read_text() if gradle_properties.exists() else ''
    gradle_properties.write_text(existing + GRADLE_PROPERTIES)

    # Firebase switches, read by the SDKs before native Core starts. The AdMob
    # sample app ID (https://developers.google.com/admob/android/quick-start)
    # keeps the google_mobile_ads plugin from failing at process start.
    manifest = android / 'app/src/main/AndroidManifest.xml'
    replace_once(manifest, '</application>', '''
        <meta-data android:name="firebase_messaging_auto_init_enabled" android:value="false"/>
        <meta-data android:name="firebase_analytics_collection_enabled" android:value="false"/>
        <meta-data android:name="firebase_analytics_collection_deactivated" android:value="true"/>
        <meta-data android:name="google_analytics_adid_collection_enabled" android:value="false"/>
        <meta-data android:name="com.google.android.gms.ads.APPLICATION_ID" android:value="ca-app-pub-3940256099942544~3347511713"/>
    </application>''')

    # Native compatibility that picnic_lib's transitive plugins require, as in
    # scripts/qa/run_ad_device_android.py.
    replace_once(app_gradle, 'compileOptions {',
                 'compileOptions {\n        isCoreLibraryDesugaringEnabled = true')
    migrate_kotlin_jvm_target(app_gradle)
    app_gradle.write_text(app_gradle.read_text() + '''
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    // The Tapjoy Flutter plugin requires the host to expose its SDK, as in picnic_app.
    implementation("com.tapjoy:tapjoy-android-sdk:14.4.0")
}
''')
    root_gradle = android / 'build.gradle.kts'
    replace_once(root_gradle, 'repositories {', '''repositories {
        maven { url = uri("https://artifact.bytedance.com/repository/pangle") }
        maven { url = uri("https://sdk.tapjoy.com/") }
        maven { url = uri("https://jitpack.io") }
''')
    compat = (ROOT / 'picnic_app/android/build.gradle').read_text()
    start = compat.index('// AGP 8+')
    end = compat.index('\nbuildscript {', start)
    (android / 'namespace-compat.gradle').write_text(compat[start:end])
    root_gradle.write_text('apply(from = "namespace-compat.gradle")\n' + root_gradle.read_text())

    for forbidden in ('google-services.json', 'key.properties', '.env'):
        if any(workspace.rglob(forbidden)):
            raise RunnerError(f'{forbidden} must not exist in the QA workspace')


def execute(qa, args):
    adb = shutil.which('adb', path=qa.env.get('PATH')) or str(
        Path.home() / 'Library/Android/sdk/platform-tools/adb')
    try:
        # adb may start the shared adb server, which must survive the run, so
        # this read-only check is not put in a process group that gets killed.
        state = subprocess.run([adb, '-s', args.device, 'get-state'], env=qa.env,
                               capture_output=True, text=True, timeout=30)
    except (OSError, subprocess.TimeoutExpired) as error:
        raise RunnerError(f'adb get-state did not complete: {error}') from None
    if state.returncode != 0 or state.stdout.strip() != 'device':
        raise RunnerError('device is not attached in the "device" state')

    qa.run('flutter-create', [
        'flutter', 'create', '--platforms=android', '--project-name', PROJECT_NAME,
        '--org', ORG, '--no-pub', str(qa.workspace),
    ], args.create_timeout)
    prepare_project(qa, args)

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

    lines = qa.run('device-test', [
        'flutter', 'test', '--no-pub', TEST_TARGET, '-d', args.device,
        '--timeout', '10m',
    ], args.test_timeout)
    summary = [line for line in lines
               if 'All tests passed' in line or 'Some tests failed' in line]
    qa.result['test_summary'] = qa.redact(summary[-1]) if summary else None


def parse_args(argv):
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument('--device', required=True, help='adb serial of the device')
    parser.add_argument('--create-timeout', type=int, default=300)
    parser.add_argument('--pub-timeout', type=int, default=900)
    parser.add_argument('--test-timeout', type=int, default=2400,
                        help='seconds for the Gradle build and the device test')
    return parser.parse_args(argv)


def _raise_interrupted(signum, frame):
    raise Interrupted()


def main(argv=None, environ=None):
    args = parse_args(argv)
    workspace = Path(tempfile.mkdtemp(prefix='picnic-firebase-readiness-qa-'))
    print(f'QA_WORKSPACE={workspace}', flush=True)
    gradle_home_created_at = time.time()
    gradle_home = workspace / OWNED_GRADLE_HOME
    gradle_home.mkdir()
    qa = QaRun(workspace, {}, private=[args.device])
    qa.result['gradle_user_home'] = str(gradle_home)
    status, error, code = 'failed', None, 1
    previous = signal.signal(signal.SIGTERM, _raise_interrupted)
    try:
        try:
            qa.env = child_env(os.environ if environ is None else environ,
                               gradle_user_home=gradle_home)
            qa.result['developer_dir'] = qa.env.get('DEVELOPER_DIR')
            qa.result['gradle_opts'] = qa.env['GRADLE_OPTS']
            execute(qa, args)
            status, code = 'passed', 0
        except RunnerError as caught:
            error = str(caught)
        except (KeyboardInterrupt, Interrupted):
            status, error, code = 'interrupted', 'the runner was interrupted', 130
        except Exception as caught:  # Reported, after cleanup, as a failure.
            error = f'unexpected error: {caught!r}'

        # No child ran if the environment could not be built.
        if qa.env:
            try:
                cleanup = stop_owned_gradle(
                    gradle_home, qa.env, gradle_home_created_at,
                    cwd=workspace, log=qa.logs / 'gradle-stop.log')
            except BaseException as caught:  # Includes a second interrupt.
                cleanup = {'error': repr(caught), 'verified': False}
            qa.result['gradle_cleanup'] = cleanup
            if cleanup.get('verified') is not True:
                problem = ('owned Gradle daemon cleanup is not verified; the '
                           f'workspace is kept for inspection: {cleanup}')
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

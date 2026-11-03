"""Regression tests for run_firebase_device_android.py.

Run from the repository root:
    python3 scripts/qa/test_run_firebase_device_android.py -v

`flutter`, `adb`, the Gradle launcher, and Gradle daemons are replaced by stub
scripts and harmless Python processes. A pass here proves the runner's
environment and process handling only. It is not a native device or Firebase
result. GradleDaemonProbe (opt-in) runs the real cached Gradle distribution.
"""
import _thread
import contextlib
import io
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import textwrap
import threading
import time
import unittest
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parent))
import run_firebase_device_android as runner  # noqa: E402

SERIAL = 'QA-FAKE-SERIAL-0001'
XCODE_DIR = '/Applications/Xcode.app/Contents/Developer'
HOSTILE_GRADLE_OPTS = '-Dorg.gradle.daemon=true -Xmx64m'
FIXED_GRADLE_OPTS = (
    '-Dorg.gradle.daemon=false '
    '-Dorg.gradle.project.kotlin.compiler.execution.strategy=in-process')
DAEMON_MAIN = 'org.gradle.launcher.daemon.bootstrap.GradleDaemon'

# A leader that starts a child, which starts a grandchild that ignores
# SIGTERM. Each writes its PID; the leader then hangs or exits with 1.
FIXTURE = textwrap.dedent('''
    import os, signal, subprocess, sys, time
    role, pids, mode = sys.argv[1], sys.argv[2], sys.argv[3]
    if role == 'grandchild':
        signal.signal(signal.SIGTERM, signal.SIG_IGN)
    with open(pids, 'a') as f:
        f.write(f'{os.getpid()}\\n')
    if role == 'leader':
        subprocess.Popen([sys.executable, __file__, 'child', pids, mode])
        while len(open(pids).read().split()) < 3:
            time.sleep(0.02)
        if mode == 'exit1':
            sys.exit(1)
    elif role == 'child':
        subprocess.Popen([sys.executable, __file__, 'grandchild', pids, mode])
    time.sleep(600)
''')


def alive(pid):
    try:
        os.kill(pid, 0)
    except ProcessLookupError:
        return False
    return True


def wait_all_dead(pids, seconds=5.0):
    deadline = time.monotonic() + seconds
    while any(alive(pid) for pid in pids) and time.monotonic() < deadline:
        time.sleep(0.05)
    return [pid for pid in pids if alive(pid)]


def read_pids(path, count=3, seconds=5.0):
    deadline = time.monotonic() + seconds
    while time.monotonic() < deadline:
        if path.exists():
            pids = [int(p) for p in path.read_text().split()]
            if len(pids) >= count:
                return pids
        time.sleep(0.02)
    return [int(p) for p in path.read_text().split()] if path.exists() else []


def kill_if_marked(pid, marker):
    """Test-owned safety net: kills [pid] only if its command has [marker]."""
    try:
        info = runner.process_info(pid)
    except runner.RunnerError:
        return
    if info is not None and marker in info[0]:
        os.kill(pid, 9)


def snapshot(directory):
    return {str(path.relative_to(directory)): path.read_bytes()
            for path in sorted(Path(directory).rglob('*')) if path.is_file()}


def write_daemon_log(gradle_home, pid):
    log = Path(gradle_home) / 'daemon/8.14.1' / f'daemon-{pid}.out.log'
    log.parent.mkdir(parents=True, exist_ok=True)
    log.write_text('')


class TempDirCase(unittest.TestCase):
    def setUp(self):
        self._dir = tempfile.TemporaryDirectory()
        self.tmp = Path(self._dir.name)
        self.addCleanup(self._dir.cleanup)

    def spawn(self, *args, ignore_term=False, log_home=None):
        """Starts a harmless detached process like a Gradle daemon; its PID.

        An intermediate process starts it in its own session and exits, so,
        as with a real daemon, this test process is not its parent. With
        [log_home] it opens and holds <log_home>/daemon/8.14.1/daemon-<pid>
        .out.log, as a real daemon holds its log. It sleeps at most 120 s,
        and a test cleanup kills it if its command line still holds this
        test's temporary directory.
        """
        parts = ['import os, signal, time']
        if ignore_term:
            parts.append('signal.signal(signal.SIGTERM, signal.SIG_IGN)')
        if log_home is not None:
            parts += [f'd = os.path.join({str(log_home)!r}, "daemon", "8.14.1")',
                      'os.makedirs(d, exist_ok=True)',
                      'log = open(os.path.join(d, "daemon-%d.out.log" % os.getpid()), "a")']
        parts.append('time.sleep(120)')
        code = '; '.join(parts)
        starter = ('import subprocess, sys; d = subprocess.DEVNULL; '
                   'p = subprocess.Popen([sys.executable, "-c", *sys.argv[1:]], '
                   'start_new_session=True, stdin=d, stdout=d, stderr=d); print(p.pid)')
        started = subprocess.run(
            [sys.executable, '-c', starter, code, *args, str(self.tmp)],
            capture_output=True, text=True, check=True, timeout=10)
        pid = int(started.stdout.strip())
        self.addCleanup(kill_if_marked, pid, str(self.tmp))
        if log_home is not None:
            log = Path(log_home) / 'daemon/8.14.1' / f'daemon-{pid}.out.log'
            deadline = time.monotonic() + 5
            while not log.exists() and time.monotonic() < deadline:
                time.sleep(0.02)
        time.sleep(0.3)  # Lets `ps` see the final command line.
        return pid


class ChildEnvTest(TempDirCase):
    """P1 and P2 environment: no Xcode first launch, no shared Gradle state."""

    environ = {
        'PATH': '/usr/bin:/bin', 'HOME': '/Users/qa', 'XDG_CONFIG_HOME': '/xdg',
        'DEVELOPER_DIR': XCODE_DIR, 'QA_FAKE_SECRET': 'must-not-leak',
        'GRADLE_OPTS': HOSTILE_GRADLE_OPTS, 'JAVA_OPTS': HOSTILE_GRADLE_OPTS,
        'JAVA_TOOL_OPTIONS': HOSTILE_GRADLE_OPTS,
        'GRADLE_USER_HOME': '/Users/qa/.gradle',
    }

    def test_caller_gradle_options_are_replaced_by_the_fixed_daemon_override(self):
        # Catches: an inherited GRADLE_OPTS/JAVA_OPTS (or one appended to the
        # fixed value) that turns the persistent Gradle daemon back on.
        env = runner.child_env(self.environ, platform='linux')

        self.assertEqual(env['GRADLE_OPTS'], FIXED_GRADLE_OPTS)
        self.assertNotIn('JAVA_OPTS', env)
        self.assertNotIn('JAVA_TOOL_OPTIONS', env)

    def test_the_owned_gradle_home_replaces_the_callers_without_changing_home(self):
        # Catches: a shared GRADLE_USER_HOME (its gradle.properties, init
        # scripts, and daemon registry) reaching the QA build.
        env = runner.child_env(self.environ, platform='linux',
                               gradle_user_home=self.tmp / 'owned')

        self.assertEqual(env['GRADLE_USER_HOME'], str(self.tmp / 'owned'))
        self.assertEqual(env['HOME'], '/Users/qa')
        self.assertNotIn('GRADLE_USER_HOME',
                         runner.child_env(self.environ, platform='linux'))

    def test_macos_forces_command_line_tools_over_inherited_value(self):
        env = runner.child_env(self.environ, platform='darwin',
                               path_exists=lambda path: True)

        self.assertEqual(env['DEVELOPER_DIR'], '/Library/Developer/CommandLineTools')
        self.assertNotIn('QA_FAKE_SECRET', env)
        self.assertEqual(env['XDG_CONFIG_HOME'], '/xdg')

    def test_macos_without_command_line_tools_fails_before_any_step(self):
        with self.assertRaisesRegex(runner.RunnerError, 'CommandLineTools'):
            runner.child_env(self.environ, platform='darwin',
                             path_exists=lambda path: False)

    def test_other_hosts_get_no_developer_dir(self):
        env = runner.child_env(self.environ, platform='linux')

        self.assertNotIn('DEVELOPER_DIR', env)


class ProcessGroupTest(TempDirCase):
    """P2: a step must not leave descendants running after it ends."""

    def start(self, mode, timeout, grace=0.5):
        fixture = self.tmp / 'fixture.py'
        fixture.write_text(FIXTURE)
        self.pids_file = self.tmp / 'pids'
        with open(self.tmp / 'out.log', 'w') as out:
            return runner.run_bounded(
                [sys.executable, str(fixture), 'leader', str(self.pids_file), mode],
                cwd=self.tmp, env={'PATH': os.environ['PATH']}, stdout=out,
                timeout=timeout, grace=grace)

    def assert_tree_gone(self):
        pids = read_pids(self.pids_file)
        self.assertEqual(len(pids), 3, 'precondition: the whole tree started')
        self.assertEqual(wait_all_dead(pids), [])

    def test_timeout_kills_the_tree_including_a_term_ignoring_grandchild(self):
        outcome = self.start('hang', timeout=3)

        self.assertIsNone(outcome['exit_code'])
        self.assertEqual(outcome['timed_out_after_s'], 3)
        self.assertEqual(outcome['cleanup'], {'signal': 'SIGKILL', 'remaining': False})
        self.assert_tree_gone()

    def test_a_failed_leader_does_not_leave_its_descendants(self):
        outcome = self.start('exit1', timeout=30)

        self.assertEqual(outcome['exit_code'], 1)
        self.assertEqual(outcome['cleanup']['signal'], 'SIGKILL')
        self.assertFalse(outcome['cleanup']['remaining'])
        self.assert_tree_gone()

    def test_keyboard_interrupt_stops_the_tree_and_propagates(self):
        timer = threading.Timer(1.5, _thread.interrupt_main)
        timer.start()
        self.addCleanup(timer.cancel)

        with self.assertRaises(KeyboardInterrupt):
            self.start('hang', timeout=30)

        self.assert_tree_gone()

    def test_a_finished_step_with_no_descendants_sends_no_signal(self):
        with open(self.tmp / 'out.log', 'w') as out:
            outcome = runner.run_bounded(
                [sys.executable, '-c', 'print("ok")'], cwd=self.tmp,
                env={'PATH': os.environ['PATH']}, stdout=out, timeout=30)

        self.assertEqual(outcome['exit_code'], 0)
        self.assertEqual(outcome['cleanup'], {'signal': None, 'remaining': False})


class ProcessInfoTest(TempDirCase):
    """Finding 2: no `ps` answer is not proof that a PID is gone."""

    def ps_answers(self, returncode, stdout):
        answer = subprocess.CompletedProcess(['ps'], returncode, stdout, '')
        return mock.patch.object(runner.subprocess, 'run', return_value=answer)

    def test_a_failed_ps_for_a_live_pid_is_unverified(self):
        with self.ps_answers(1, ''), self.assertRaises(runner.RunnerError):
            runner.process_info(os.getpid())

    def test_an_empty_ps_answer_for_a_live_pid_is_unverified(self):
        with self.ps_answers(0, ''), self.assertRaises(runner.RunnerError):
            runner.process_info(os.getpid())

    def test_a_pid_that_cannot_be_probed_is_unverified(self):
        with self.ps_answers(1, ''), \
                mock.patch.object(runner.os, 'kill', side_effect=PermissionError), \
                self.assertRaises(runner.RunnerError):
            runner.process_info(os.getpid())

    def test_a_process_that_exited_is_reported_absent(self):
        gone = subprocess.Popen([sys.executable, '-c', 'pass'])
        gone.wait(10)

        self.assertIsNone(runner.process_info(gone.pid))


class StopOwnedGradleTest(TempDirCase):
    """P2: detached daemon JVMs of the owned home are stopped, nothing else."""

    def stop(self, created_at, **kwargs):
        self.home = self.tmp / 'gradle-user-home'
        self.home.mkdir(exist_ok=True)
        return runner.stop_owned_gradle(
            self.home, {'PATH': os.environ['PATH']}, created_at, cwd=self.tmp,
            log=self.tmp / 'gradle-stop.log', grace=0.5, **kwargs)

    @property
    def owned_home(self):
        return self.tmp / 'gradle-user-home'

    def test_a_detached_owned_daemon_is_killed_even_if_it_ignores_sigterm(self):
        # Catches: cleanup that relies on the step's process group, which a
        # forked Gradle daemon has left (the failed real Gradle probe).
        created_at = time.time() - 1
        daemon = self.spawn(DAEMON_MAIN, ignore_term=True, log_home=self.owned_home)

        report = self.stop(created_at)

        self.assertIsNone(report['launcher'])
        self.assertIsNone(report['stop'])
        self.assertEqual(report['daemon_pids'], [daemon])
        self.assertEqual(report['signalled'], [[daemon, 'SIGTERM'], [daemon, 'SIGKILL']])
        self.assertEqual(report['remaining'], [])
        self.assertTrue(report['verified'])
        self.assertEqual(wait_all_dead([daemon]), [])

    def test_a_newer_unrelated_daemon_reusing_a_logged_pid_is_never_signalled(self):
        # Catches (finding 1): ownership guessed from a log name, the
        # GradleDaemon substring, and a start after the home was created. A
        # newer daemon of another home that reuses a stale logged PID meets
        # all three, but holds nothing in the owned home.
        created_at = time.time() - 1
        newer = self.spawn(DAEMON_MAIN, log_home=self.tmp / 'shared-gradle-home')
        write_daemon_log(self.owned_home, newer)  # The stale owned log.

        report = self.stop(created_at)

        self.assertEqual(report['signalled'], [])
        self.assertEqual(report['ambiguous'], [newer])
        self.assertFalse(report['verified'])
        self.assertTrue(alive(newer))

    def test_an_identity_change_before_a_signal_stops_signalling(self):
        # Catches (finding 1): a PID that is re-checked by substring only, so
        # a process that replaced the owned daemon between checks is signalled.
        created_at = time.time() - 1
        daemon = self.spawn(DAEMON_MAIN, log_home=self.owned_home)
        real = runner.process_info
        calls = []

        def changed_after_first(pid):
            calls.append(pid)
            info = real(pid)
            if info is None or len(calls) == 1:
                return info
            # A different, later birth for the same PID.
            if isinstance(info[1], float):
                return info[0], info[1] + 3600
            return info[0], 'Mon Jan  1 00:00:00 2091'

        with mock.patch.object(runner, 'process_info', changed_after_first):
            report = self.stop(created_at)

        self.assertEqual(report['signalled'], [])
        self.assertEqual(report['ambiguous'], [daemon])
        self.assertFalse(report['verified'])
        self.assertTrue(alive(daemon))

    def test_a_non_gradle_process_holding_an_owned_file_is_never_signalled(self):
        # Catches: ownership proven by an open file alone. A log viewer or
        # editor that reused a stale logged PID and holds the QA daemon log
        # is not a Gradle daemon.
        viewer = self.spawn('qa-log-viewer', log_home=self.owned_home)

        report = self.stop(created_at=time.time() - 10)

        self.assertEqual(report['daemon_pids'], [viewer])
        self.assertEqual(report['signalled'], [])
        self.assertEqual(report['ignored'], [viewer])
        self.assertTrue(alive(viewer))

    def test_classify_requires_the_gradle_daemon_command(self):
        # The coordinator's in-memory reproduction of the same defect.
        log = self.owned_home / 'daemon/8.14.1/daemon-42424.out.log'
        birth = time.strftime('%a %b %d %H:%M:%S %Y')
        with mock.patch.object(runner, 'process_info', return_value=(
                    '/Applications/Editor.app/Contents/MacOS/Editor', birth)), \
                mock.patch.object(runner, 'open_paths', return_value=[str(log)]):
            state, _ = runner._classify(42424, self.owned_home, time.time() - 10)

        self.assertEqual(state, 'foreign')

    def test_an_unrelated_process_with_a_logged_pid_is_never_signalled(self):
        unrelated = self.spawn('qa-unrelated-process')
        write_daemon_log(self.owned_home, unrelated)

        report = self.stop(created_at=time.time() - 30)

        self.assertEqual(report['ignored'], [unrelated])
        self.assertEqual(report['signalled'], [])
        self.assertTrue(report['verified'])
        self.assertTrue(alive(unrelated))

    def test_a_daemon_of_another_gradle_home_is_never_signalled(self):
        other = self.spawn(DAEMON_MAIN, 'another-home',
                           log_home=self.tmp / 'another-gradle-home')

        report = self.stop(created_at=time.time() - 30)

        self.assertEqual(report['daemon_pids'], [])
        self.assertTrue(report['verified'])
        self.assertTrue(alive(other))

    def test_a_stop_step_that_leaves_processes_is_not_verified(self):
        # Catches (finding 3): `--stop` group leftovers ignored because the
        # top-level owned daemon list is empty.
        self.write_launcher(exit_code=0)
        leftover = {'exit_code': 0, 'cleanup': {'signal': 'SIGKILL', 'remaining': True}}
        with mock.patch.object(runner, 'run_bounded', return_value=leftover):
            report = self.stop(created_at=time.time() - 1)

        self.assertEqual(report['remaining'], [])
        self.assertFalse(report['verified'])

    def test_a_failed_stop_with_no_leftovers_is_still_verified(self):
        self.write_launcher(exit_code=1)

        report = self.stop(created_at=time.time() - 1)

        self.assertEqual(report['stop']['exit_code'], 1)
        self.assertEqual(report['remaining'], [])
        self.assertTrue(report['verified'])

    def write_launcher(self, exit_code):
        launcher = self.owned_home / 'wrapper/dists/gradle-8.14.1-all/qa/gradle-8.14.1/bin/gradle'
        launcher.parent.mkdir(parents=True)
        launcher.write_text(f'#!{sys.executable}\nimport sys\nsys.exit({exit_code})\n')
        launcher.chmod(0o755)
        return launcher

    def test_stop_uses_the_owned_distribution_and_owned_home_only(self):
        # Catches: `--stop` sent to the caller's (shared) home.
        record = self.tmp / 'launcher.jsonl'
        home = self.tmp / 'gradle-user-home'
        launcher = home / 'wrapper/dists/gradle-8.14.1-all/qa/gradle-8.14.1/bin/gradle'
        launcher.parent.mkdir(parents=True)
        launcher.write_text(
            f'#!{sys.executable}\nimport json, os, sys\n'
            f'print(json.dumps([sys.argv[1:], os.environ.get("GRADLE_USER_HOME")]), '
            f'file=open({str(record)!r}, "a"))\n')
        launcher.chmod(0o755)

        report = runner.stop_owned_gradle(
            home, {'PATH': os.environ['PATH'], 'GRADLE_USER_HOME': '/shared/.gradle'},
            time.time(), cwd=self.tmp, log=self.tmp / 'gradle-stop.log')

        self.assertEqual(report['launcher'], str(launcher))
        self.assertEqual(report['stop']['exit_code'], 0)
        self.assertEqual(json.loads(record.read_text()), [['--stop'], str(home)])


# The `flutter create --platforms=android` output that the runner edits, as
# generated by the installed Flutter (Kotlin DSL, Java/Kotlin JVM 17).
CREATE_TEMPLATE = {
    'app/build.gradle.kts': textwrap.dedent('''\
        plugins {
            id("com.android.application")
            id("kotlin-android")
            // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
            id("dev.flutter.flutter-gradle-plugin")
        }

        android {
            namespace = "io.picnic.qa.firebase_readiness"
            compileSdk = flutter.compileSdkVersion
            ndkVersion = flutter.ndkVersion

            compileOptions {
                sourceCompatibility = JavaVersion.VERSION_17
                targetCompatibility = JavaVersion.VERSION_17
            }

            kotlinOptions {
                jvmTarget = JavaVersion.VERSION_17.toString()
            }

            defaultConfig {
                applicationId = "io.picnic.qa.firebase_readiness"
                minSdk = flutter.minSdkVersion
                targetSdk = flutter.targetSdkVersion
                versionCode = flutter.versionCode
                versionName = flutter.versionName
            }

            buildTypes {
                release {
                    signingConfig = signingConfigs.getByName("debug")
                }
            }
        }

        flutter {
            source = "../.."
        }
        '''),
    'settings.gradle.kts': textwrap.dedent('''\
        plugins {
            id("dev.flutter.flutter-plugin-loader") version "1.0.0"
            id("com.android.application") version "8.7.3" apply false
            id("org.jetbrains.kotlin.android") version "2.1.0" apply false
        }

        include(":app")
        '''),
    'gradle/wrapper/gradle-wrapper.properties':
        'distributionUrl=https\\://services.gradle.org/distributions/gradle-8.12-all.zip\n',
    'app/src/main/AndroidManifest.xml': '<manifest><application></application></manifest>\n',
    'build.gradle.kts': 'allprojects {\n    repositories {\n        google()\n    }\n}\n',
    'gradle.properties': 'org.gradle.jvmargs=-Xmx1G\n',
}

STUB_FLUTTER = '''#!{python}
import json, os, shutil, signal, subprocess, sys, time
from pathlib import Path
record, mode, pids, template = {record!r}, {mode!r}, {pids!r}, {template!r}
with open(record, 'a') as f:
    f.write(json.dumps({{'tool': 'flutter', 'argv': sys.argv[1:],
                        'DEVELOPER_DIR': os.environ.get('DEVELOPER_DIR'),
                        'GRADLE_OPTS': os.environ.get('GRADLE_OPTS'),
                        'GRADLE_USER_HOME': os.environ.get('GRADLE_USER_HOME'),
                        'XDG_CONFIG_HOME': os.environ.get('XDG_CONFIG_HOME'),
                        'keys': sorted(os.environ)}}) + '\\n')
if sys.argv[1] == 'create':
    shutil.copytree(template, Path(sys.argv[-1]) / 'android', dirs_exist_ok=True)
elif sys.argv[1] == 'test':
    print('Running on ' + sys.argv[sys.argv.index('-d') + 1])
    if mode == 'pass':
        print('00:10 +1: All tests passed!')
    elif mode == 'pass-daemon':
        # Like the wrapper and a forked single-use daemon: a distribution in
        # the owned home and a detached JVM that outlives this process group.
        home = Path(os.environ['GRADLE_USER_HOME'])
        launcher = home / 'wrapper/dists/gradle-8.14.1-all/qa/gradle-8.14.1/bin/gradle'
        launcher.parent.mkdir(parents=True, exist_ok=True)
        launcher.write_text('#!' + sys.executable + '\\nimport json, os, sys\\n'
            'print(json.dumps({{"tool": "gradle", "argv": sys.argv[1:], '
            '"GRADLE_USER_HOME": os.environ.get("GRADLE_USER_HOME")}}), '
            'file=open(' + repr(record) + ', "a"))\\n')
        launcher.chmod(0o755)
        # Like a real daemon, it creates and holds its own log in the home.
        daemon = subprocess.Popen([sys.executable, '-c',
            'import os, time; d = os.path.join(os.environ["GRADLE_USER_HOME"], "daemon", "8.14.1"); '
            'os.makedirs(d, exist_ok=True); '
            'log = open(os.path.join(d, "daemon-%d.out.log" % os.getpid()), "a"); time.sleep(120)',
            'org.gradle.launcher.daemon.bootstrap.GradleDaemon', pids],
            start_new_session=True, stdin=subprocess.DEVNULL,
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        log = home / 'daemon/8.14.1' / ('daemon-' + str(daemon.pid) + '.out.log')
        while not log.exists():
            time.sleep(0.02)
        open(pids, 'a').write(str(daemon.pid) + ' ')
        time.sleep(0.3)
        print('00:10 +1: All tests passed!')
    else:
        orphan = subprocess.Popen([sys.executable, '-c',
            'import os, signal, sys, time; signal.signal(signal.SIGTERM, signal.SIG_IGN); '
            'open(sys.argv[1], "a").write(str(os.getpid()) + " "); time.sleep(600)', pids])
        while not os.path.exists(pids) or not open(pids).read().strip():
            time.sleep(0.02)
        if mode == 'fail':
            sys.exit(1)
        time.sleep(600)
'''

STUB_ADB = '''#!{python}
import json, sys
with open({record!r}, 'a') as f:
    f.write(json.dumps({{'tool': 'adb', 'argv': sys.argv[1:]}}) + '\\n')
print('device')
'''


class MainWithStubToolsTest(TempDirCase):
    """Drives main() end to end with stub flutter/adb; no device or SDK."""

    def run_main(self, mode, interrupt_after=None, template=None):
        bin_dir = self.tmp / 'bin'
        bin_dir.mkdir()
        self.record = self.tmp / 'record.jsonl'
        self.pids_file = self.tmp / 'orphan.pid'
        template_dir = self.tmp / 'create-template'
        for name, text in (template or CREATE_TEMPLATE).items():
            path = template_dir / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(text)
        values = {'python': sys.executable, 'record': str(self.record),
                  'mode': mode, 'pids': str(self.pids_file),
                  'template': str(template_dir)}
        for name, template in (('flutter', STUB_FLUTTER), ('adb', STUB_ADB)):
            tool = bin_dir / name
            tool.write_text(template.format(**values))
            tool.chmod(0o755)
        tools = self.tmp / 'CommandLineTools'
        tools.mkdir()
        self.caller_home = self.tmp / 'caller-gradle-home'
        (self.caller_home / 'init.d').mkdir(parents=True)
        (self.caller_home / 'gradle.properties').write_text('org.gradle.daemon=true\n')
        (self.caller_home / 'init.d/caller.gradle').write_text("println 'CALLER'\n")
        self.caller_before = snapshot(self.caller_home)
        self.workspace = self.tmp / 'workspace'
        self.workspace.mkdir()
        environ = {
            'PATH': f'{bin_dir}:/usr/bin:/bin', 'HOME': str(self.tmp),
            'XDG_CONFIG_HOME': '/xdg-original', 'DEVELOPER_DIR': XCODE_DIR,
            'QA_FAKE_SECRET': 'must-not-leak', 'GRADLE_OPTS': HOSTILE_GRADLE_OPTS,
            'GRADLE_USER_HOME': str(self.caller_home),
        }
        if interrupt_after is not None:
            timer = threading.Timer(interrupt_after, _thread.interrupt_main)
            timer.start()
            self.addCleanup(timer.cancel)
        stdout, stderr = io.StringIO(), io.StringIO()
        with mock.patch.object(runner, 'COMMAND_LINE_TOOLS', str(tools)), \
                mock.patch.object(runner.sys, 'platform', 'darwin'), \
                mock.patch.object(runner.tempfile, 'mkdtemp',
                                  lambda prefix: str(self.workspace)), \
                contextlib.redirect_stdout(stdout), contextlib.redirect_stderr(stderr):
            code = runner.main(['--device', SERIAL, '--test-timeout', '60'],
                               environ=environ)
        self.stdout = stdout.getvalue() + stderr.getvalue()
        self.result = json.loads((self.workspace / 'qa-result.json').read_text())
        self.calls = [json.loads(line) for line in self.record.read_text().splitlines()]
        self.tools_dir = str(tools)
        self.owned_home = str(self.workspace / 'gradle-user-home')
        return code

    def flutter_calls(self):
        return [call for call in self.calls if call['tool'] == 'flutter']

    def test_every_flutter_step_runs_with_the_isolated_environment(self):
        code = self.run_main('pass')

        self.assertEqual(code, 0, self.stdout)
        flutter = self.flutter_calls()
        self.assertEqual([call['argv'][0] for call in flutter], ['create', 'pub', 'test'])
        for call in flutter:
            self.assertEqual(call['DEVELOPER_DIR'], self.tools_dir)
            self.assertEqual(call['GRADLE_OPTS'], FIXED_GRADLE_OPTS)
            self.assertEqual(call['GRADLE_USER_HOME'], self.owned_home)
            self.assertEqual(call['XDG_CONFIG_HOME'], '/xdg-original')
            self.assertNotIn('QA_FAKE_SECRET', call['keys'])
        adb = [call['argv'] for call in self.calls if call['tool'] == 'adb']
        self.assertEqual(adb, [['-s', SERIAL, 'get-state']])
        self.assertEqual(snapshot(self.caller_home), self.caller_before)

    def test_a_detached_daemon_is_stopped_before_a_pass_is_reported(self):
        # Catches: a pass reported while an owned Gradle JVM outside the step
        # group is still running (the failed real Gradle probe).
        code = self.run_main('pass-daemon')
        daemon_pid = read_pids(self.pids_file, count=1)[0]
        self.addCleanup(kill_if_marked, daemon_pid, str(self.tmp))

        self.assertEqual(code, 0, self.stdout)
        cleanup = self.result['gradle_cleanup']
        self.assertEqual(cleanup['daemon_pids'], [daemon_pid])
        self.assertEqual(cleanup['signalled'], [[daemon_pid, 'SIGTERM']])
        self.assertEqual(cleanup['remaining'], [])
        self.assertTrue(cleanup['verified'])
        self.assertEqual(wait_all_dead([daemon_pid]), [])
        stops = [call for call in self.calls if call['tool'] == 'gradle']
        self.assertEqual(stops, [{'tool': 'gradle', 'argv': ['--stop'],
                                  'GRADLE_USER_HOME': self.owned_home}])
        self.assertEqual(snapshot(self.caller_home), self.caller_before)

    def test_an_unverified_gradle_cleanup_turns_a_pass_into_a_failure(self):
        unverified = {'remaining': [], 'ambiguous': [424242], 'verified': False}
        with mock.patch.object(runner, 'stop_owned_gradle', return_value=unverified):
            code = self.run_main('pass')

        self.assertEqual(code, 1)
        self.assertEqual(self.result['status'], 'failed')
        self.assertIn('cleanup is not verified', self.result['error'])
        self.assertTrue((self.workspace / 'gradle-user-home').is_dir())

    def test_stop_step_leftovers_turn_a_pass_into_a_failure(self):
        # Catches (finding 3): the `--stop` step's own group cleanup left a
        # process, but the top-level owned daemon list is empty.
        real = runner.run_bounded

        def stop_leaves_a_process(command, **kwargs):
            outcome = real(command, **kwargs)
            if command[-1] == '--stop':
                outcome['cleanup'] = {'signal': 'SIGKILL', 'remaining': True}
            return outcome

        with mock.patch.object(runner, 'run_bounded', stop_leaves_a_process):
            code = self.run_main('pass-daemon')
        self.addCleanup(kill_if_marked, read_pids(self.pids_file, count=1)[0], str(self.tmp))

        self.assertEqual(self.result['gradle_cleanup']['remaining'], [])
        self.assertEqual(code, 1)
        self.assertEqual(self.result['status'], 'failed')
        self.assertIn('cleanup is not verified', self.result['error'])

    def test_the_generated_app_uses_the_typed_kotlin_jvm_target(self):
        # Catches (finding 4): the template's android.kotlinOptions String
        # DSL, which Kotlin 2.4.21 rejects (native run failure at line 20).
        self.run_main('pass')

        app = (self.workspace / 'android/app/build.gradle.kts').read_text()
        self.assertNotIn('kotlinOptions', app)
        self.assertIn('kotlin {\n    compilerOptions {\n'
                      '        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)\n'
                      '    }\n}\n', app)
        self.assertIn('sourceCompatibility = JavaVersion.VERSION_17', app)
        self.assertIn('targetCompatibility = JavaVersion.VERSION_17', app)

    def test_an_unexpected_kotlin_options_block_fails_clearly(self):
        app = CREATE_TEMPLATE['app/build.gradle.kts'].replace(
            'JavaVersion.VERSION_17.toString()', '"11"')
        code = self.run_main('pass', template=dict(CREATE_TEMPLATE, **{'app/build.gradle.kts': app}))

        self.assertEqual(code, 1)
        self.assertIn('kotlinOptions', self.result['error'])
        self.assertEqual([call['argv'][0] for call in self.flutter_calls()], ['create'])

    def test_the_qa_project_file_also_requests_no_daemon(self):
        # A second request only; the fixed GRADLE_OPTS and the owned home are
        # the controls, and GradleDaemonProbe checks the real effect.
        self.run_main('pass')

        properties = (self.workspace / 'android/gradle.properties').read_text()
        self.assertIn('org.gradle.jvmargs=-Xmx1G', properties)
        self.assertIn('org.gradle.daemon=false', properties)
        self.assertIn('kotlin.compiler.execution.strategy=in-process', properties)

    def test_the_device_serial_stays_out_of_the_result_and_stdout(self):
        self.run_main('pass')

        self.assertNotIn(SERIAL, (self.workspace / 'qa-result.json').read_text())
        self.assertNotIn(SERIAL, self.stdout)
        self.assertEqual(self.result['status'], 'passed')

    def test_a_failed_step_is_reported_only_after_cleanup(self):
        code = self.run_main('fail')

        self.assertEqual(code, 1)
        self.assertEqual(self.result['status'], 'failed')
        self.assertIn('device-test', self.result['error'])
        step = self.result['steps'][-1]
        self.assertEqual(step['exit_code'], 1)
        self.assertEqual(step['cleanup'], {'signal': 'SIGKILL', 'remaining': False})
        self.assertEqual(self.result['gradle_cleanup']['remaining'], [])
        self.assertEqual(wait_all_dead(read_pids(self.pids_file, count=1)), [])

    def test_an_interrupted_run_is_cleaned_up_and_reported(self):
        code = self.run_main('hang', interrupt_after=3.0)

        self.assertEqual(code, 130)
        self.assertEqual(self.result['status'], 'interrupted')
        self.assertEqual(self.result['gradle_cleanup']['remaining'], [])
        self.assertEqual(wait_all_dead(read_pids(self.pids_file, count=1)), [])


GRADLE_PROBE_BUILD = textwrap.dedent('''
    def strategy = providers.gradleProperty('kotlin.compiler.execution.strategy').getOrNull()
    tasks.register('qaProbe') {
        doLast {
            println "QA_BUILD_PID=${ProcessHandle.current().pid()}"
            println "QA_KOTLIN_STRATEGY=${strategy}"
            println 'QA_READY'
            System.out.flush()
            Thread.sleep(600000)
        }
    }
''')


def cached_gradle():
    """The cached Gradle 8.14.1 launcher; QA_GRADLE_BIN overrides the search."""
    explicit = os.environ.get('QA_GRADLE_BIN')
    if explicit:
        return Path(explicit)
    home = Path(os.environ.get('GRADLE_USER_HOME') or Path.home() / '.gradle')
    matches = sorted(home.glob('wrapper/dists/gradle-8.14.1-all/*/gradle-8.14.1/bin/gradle'))
    return matches[0] if len(matches) == 1 else None


@unittest.skipUnless(os.environ.get('QA_RUN_GRADLE_PROBE') == '1',
                     'real Gradle probe; the coordinator sets QA_RUN_GRADLE_PROBE=1')
class GradleDaemonProbe(TempDirCase):
    """Runs the cached Gradle distribution offline through the runner's path.

    No Flutter, plugin, network, or device. The build uses the runner's
    child_env() with a new owned GRADLE_USER_HOME, then the runner's own
    stop_owned_gradle(). Only the launcher is given explicitly: the owned home
    has no distribution because this test must not download one. The project
    sets org.gradle.jvmargs as the Flutter template does, so Gradle forks a
    build JVM. The caller passes a hostile GRADLE_OPTS and a caller Gradle home
    with daemon=true and an init script; neither may take effect. A
    daemon-like unrelated process must survive.
    """

    def test_production_cleanup_stops_the_detached_build_jvm(self):
        gradle = cached_gradle()
        self.assertIsNotNone(gradle, 'no single cached gradle-8.14.1; set QA_GRADLE_BIN')
        caller_home = self.tmp / 'caller-gradle-home'
        (caller_home / 'init.d').mkdir(parents=True)
        (caller_home / 'gradle.properties').write_text(
            'org.gradle.daemon=true\nkotlin.compiler.execution.strategy=daemon\n')
        (caller_home / 'init.d/caller.gradle').write_text(
            "println 'QA_CALLER_INIT_SCRIPT_RAN'\n")
        caller_before = snapshot(caller_home)
        workspace = self.tmp / 'workspace'
        workspace.mkdir()
        created_at = time.time()
        owned_home = workspace / runner.OWNED_GRADLE_HOME
        owned_home.mkdir()
        project = workspace / 'project'
        project.mkdir()
        (project / 'settings.gradle').write_text("rootProject.name = 'qa-daemon-probe'\n")
        (project / 'gradle.properties').write_text(
            'org.gradle.jvmargs=-Xmx256m -Dqa.force.forked.build.jvm=1\n')
        (project / 'build.gradle').write_text(GRADLE_PROBE_BUILD)
        sentinel = self.spawn(DAEMON_MAIN, 'qa-unrelated-sentinel')  # A PID.
        environ = dict(os.environ, GRADLE_USER_HOME=str(caller_home),
                       GRADLE_OPTS=HOSTILE_GRADLE_OPTS)
        env = runner.child_env(environ, gradle_user_home=owned_home)
        command = [str(gradle), '--offline', '--console=plain', '-p', str(project), 'qaProbe']
        timeout = int(os.environ.get('QA_GRADLE_PROBE_TIMEOUT', '150'))
        log = workspace / 'gradle.log'
        # Last-resort safety net; it runs after the assertions, so it cannot
        # hide a production cleanup failure.
        self.addCleanup(self._last_resort_stop, gradle, project, env)

        group, box = {}, {}

        def build():
            with open(log, 'w') as out:
                box['outcome'] = runner.run_bounded(
                    command, cwd=project, env=env, stdout=out, timeout=timeout,
                    grace=5, on_start=lambda pgid: group.setdefault('pgid', pgid))

        thread = threading.Thread(target=build)
        thread.start()
        build_pid, in_group = None, None
        deadline = time.monotonic() + timeout
        while time.monotonic() < deadline and thread.is_alive():
            text = log.read_text(errors='replace') if log.exists() else ''
            if 'QA_READY' in text:
                build_pid = int(text.split('QA_BUILD_PID=')[1].split()[0])
                in_group = os.getpgid(build_pid) == group['pgid']
                break
            time.sleep(0.2)
        thread.join(timeout + 30)
        alive_after_group_cleanup = build_pid is not None and alive(build_pid)
        report = runner.stop_owned_gradle(
            owned_home, env, created_at, cwd=project,
            log=workspace / 'gradle-stop.log', launcher=gradle)
        text = log.read_text(errors='replace')
        leftovers = subprocess.run(['pgrep', '-f', str(workspace)],
                                   capture_output=True, text=True).stdout.split()
        evidence = {
            'gradle_user_home': env['GRADLE_USER_HOME'],
            'gradle_opts': env['GRADLE_OPTS'],
            'build_pid': build_pid,
            'build_pid_in_step_group': in_group,
            'build_pid_alive_after_group_cleanup': alive_after_group_cleanup,
            'kotlin_strategy': text.split('QA_KOTLIN_STRATEGY=')[1].split()[0]
            if 'QA_KOTLIN_STRATEGY=' in text else None,
            'outcome': box.get('outcome'),
            'owned_cleanup': report,
            'build_pid_alive_after_owned_cleanup': build_pid is not None and alive(build_pid),
            'leftover_pids': leftovers,
            'sentinel_alive': alive(sentinel),
            'logs': {'build': str(log), 'stop': str(workspace / 'gradle-stop.log'),
                     'daemon_dir': str(owned_home / 'daemon')},
        }
        print('QA_GRADLE_PROBE=' + json.dumps(evidence), flush=True)

        self.assertIsNotNone(build_pid, 'Gradle did not reach the probe task:\n' + text[-3000:])
        self.assertTrue(in_group or build_pid in report['daemon_pids'],
                        'the detached build JVM has no daemon log in the owned home')
        self.assertEqual(report['remaining'], [])
        self.assertTrue(report['verified'], report)
        self.assertEqual(wait_all_dead([build_pid]), [])
        self.assertEqual(leftovers, [])
        self.assertEqual(evidence['kotlin_strategy'], 'in-process')
        self.assertNotIn('QA_CALLER_INIT_SCRIPT_RAN', text)
        self.assertEqual(snapshot(caller_home), caller_before)
        self.assertTrue(alive(sentinel), 'an unrelated process was signalled')

    def _last_resort_stop(self, gradle, project, env):
        with open(self.tmp / 'last-resort-stop.log', 'w') as out:
            runner.run_bounded([str(gradle), '--stop'], cwd=project, env=env,
                               stdout=out, timeout=60)


if __name__ == '__main__':
    unittest.main()

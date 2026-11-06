"""Regression tests for run_firebase_device_ios.py.

Run from the repository root:
    python3 scripts/qa/test_run_firebase_device_ios.py -v

`flutter`, `xcodebuild`, and `simctl` are replaced by stub scripts; no
simulator, Xcode build, CocoaPods, or network is used. A pass here proves the
runner's target checks, project edits, and process handling only. It is not
a native simulator or Firebase result. Product files (Podfile, Podfile.lock,
project.pbxproj, pubspec.lock) are read, never written.

The stub `flutter create` imitates the installed Flutter 3.41.4 paths that
the runner must control: signing discovery (create.dart 417-428 and
code_signing.dart 331-336: `which security`, `which openssl`, then
`security find-identity`) and the Swift Package Manager choice (project
`flutter: config:` first, then an inherited global enablement). Every
credential tool that a stub can reach by name is a fake in this test's own
bin directory, so a regression cannot reach the real `security` or
`openssl`.

FlutterCreateProbe (opt-in, QA_RUN_FLUTTER_CREATE_PROBE=1) runs only the
runner's create step with the installed Flutter executable; see its
docstring. Nothing in this file runs a native build, install, or simulator
operation.
"""
import _thread
import contextlib
import io
import json
import os
from pathlib import Path
import plistlib
import subprocess
import sys
import tempfile
import re
import textwrap
import threading
import time
import unittest
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parent))
import run_firebase_device_ios as runner  # noqa: E402

ROOT_DIR = Path(__file__).resolve().parents[2]

SIM_UDID = 'A1B2C3D4-1111-4222-8333-0000000000AA'
OTHER_UDID = 'A1B2C3D4-1111-4222-8333-0000000000BB'
PHYSICAL_ID = '00008110-001A2B3C4D5E801E'
RUNTIME = 'com.apple.CoreSimulator.SimRuntime.iOS-26-5'
OTHER_RUNTIME = 'com.apple.CoreSimulator.SimRuntime.iOS-27-1'
SIM_NAME = 'Picnic Firebase QA 26.5'
BUNDLE = 'io.picnic.qa.firebaseReadiness'
OTHER_APP = 'com.example.preexisting'


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


def read_pids(path, count=1, seconds=5.0):
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
    done = subprocess.run(['/bin/ps', '-ww', '-o', 'command=', '-p', str(pid)],
                          capture_output=True, text=True)
    if done.returncode == 0 and marker in done.stdout:
        os.kill(pid, 9)


def listing(*devices):
    by_runtime = {}
    for udid, name, runtime, state, available in devices:
        by_runtime.setdefault(runtime, []).append(
            {'udid': udid, 'name': name, 'state': state, 'isAvailable': available,
             'deviceTypeIdentifier': 'com.apple.CoreSimulator.SimDeviceType.iPhone-16-Pro'})
    return {'devices': by_runtime}


TEMPLATE_PLIST = {
    'CFBundleIdentifier': '$(PRODUCT_BUNDLE_IDENTIFIER)',
    'CFBundleName': 'firebase_readiness',
    'UILaunchStoryboardName': 'LaunchScreen',
}
TEMPLATE_PBXPROJ = textwrap.dedent('''\
    /* Begin PBXNativeTarget section */
    \t\t331C8080294A63A400263BE5 /* RunnerTests */ = {
    /* Begin XCBuildConfiguration section */
    \t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 13.0;
    \t\t97C147061CF9000F007C117D /* Debug */ = {
    \t\t\tisa = XCBuildConfiguration;
    \t\t\tbaseConfigurationReference = 9740EEB21CF90195004384FC /* Debug.xcconfig */;
    \t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = io.picnic.qa.firebaseReadiness;
    \t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = io.picnic.qa.firebaseReadiness.RunnerTests;
    \t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = 13.0;
    ''')
# The ios/Flutter xcconfig files that `flutter create` writes.
TEMPLATE_DEBUG_XCCONFIG = '#include "Generated.xcconfig"\n'
TEMPLATE_RELEASE_XCCONFIG = '#include "Generated.xcconfig"\n'
SIM_ARCHS = re.compile(r'^ARCHS\[sdk=iphonesimulator\*\] = (\S+)$', re.MULTILINE)
SPM_WIRING = ('\t\t78A318202AECB46A00862997 /* FlutterGeneratedPluginSwiftPackage */ '
              '= {isa = XCSwiftPackageProductDependency; };\n')

STUB_FLUTTER = '''#!{python}
import json, os, re, plistlib, shutil, subprocess, sys, time
from pathlib import Path
record, mode, pids, template = {record!r}, {mode!r}, {pids!r}, {template!r}
apps_file, inherited_spm = {apps!r}, {inherited_spm!r}
# The simulator ARCHS that Xcode would read from the Runner Debug base
# configuration (ios/Flutter/Debug.xcconfig) for this step.
debug_xcconfig = Path('ios/Flutter/Debug.xcconfig')
sim_archs = re.findall(r'^ARCHS\\[sdk=iphonesimulator\\*\\] = (\\S+)$',
                       debug_xcconfig.read_text(), re.M) if debug_xcconfig.exists() else None
with open(record, 'a') as f:
    f.write(json.dumps({{'tool': 'flutter', 'argv': sys.argv[1:],
                        'DEVELOPER_DIR': os.environ.get('DEVELOPER_DIR'),
                        'PATH': os.environ.get('PATH'),
                        'sim_archs': sim_archs,
                        'keys': sorted(os.environ)}}) + '\\n')

def orphan_then(exit_code):
    subprocess.Popen([sys.executable, '-c',
        'import os, signal, sys, time; signal.signal(signal.SIGTERM, signal.SIG_IGN); '
        'open(sys.argv[1], "a").write(str(os.getpid()) + " "); time.sleep(600)', pids])
    while not os.path.exists(pids) or not open(pids).read().strip():
        time.sleep(0.02)
    if exit_code is None:
        time.sleep(600)
    sys.exit(exit_code)

def spm_enabled():
    # Project `flutter: config:` first, then the inherited (global) value,
    # as in flutter_features_config.dart 104-154.
    if mode == 'spm-forced':
        return True
    text = Path('pubspec.yaml').read_text() if Path('pubspec.yaml').exists() else ''
    match = re.search(r'^    enable-swift-package-manager: (true|false)$', text, re.M)
    return match.group(1) == 'true' if match else inherited_spm

def write_plugin_dependencies():
    Path('.flutter-plugins-dependencies').write_text(json.dumps(
        {{'plugins': {{}}, 'swift_package_manager_enabled': {{'ios': spm_enabled()}}}}))

def apps():
    return json.load(open(apps_file))

def set_installed(udid, installed):
    data = apps()
    listed = [app for app in data.get(udid, []) if app != {bundle!r}]
    data[udid] = listed + ([{bundle!r}] if installed else [])
    json.dump(data, open(apps_file, 'w'))

if sys.argv[1] == 'create':
    # Signing discovery by tool name, as the installed Flutter does it.
    tools_found = mode == 'skip-which' or all(
        subprocess.run(['which', tool], capture_output=True).returncode == 0
        for tool in ('security', 'openssl'))
    if tools_found:
        subprocess.run(['security', 'find-identity', '-p', 'codesigning', '-v'],
                       capture_output=True)
    shutil.copytree(template, Path(sys.argv[-1]), dirs_exist_ok=True)
    if spm_enabled():
        pbxproj = Path(sys.argv[-1]) / 'ios/Runner.xcodeproj/project.pbxproj'
        pbxproj.write_text(pbxproj.read_text() + {spm_wiring!r})
elif sys.argv[1] == 'pub':
    write_plugin_dependencies()
elif sys.argv[1] == 'build':
    write_plugin_dependencies()
    if mode == 'build-fail':
        orphan_then(1)
    app = Path('build/ios/iphonesimulator/Runner.app')
    app.mkdir(parents=True)
    source = Path(template) / 'ios/Runner/Info.plist' if mode == 'built-plist-reset' \\
        else Path('ios/Runner/Info.plist')
    shutil.copyfile(source, app / 'Info.plist')
    if mode == 'pod-drift':
        lock = Path('ios/Podfile.lock')
        lock.write_text(lock.read_text().replace('  - FirebaseCore (12.19.3):',
                                                 '  - FirebaseCore (12.20.0):'))
    if mode == 'xcconfig-reset':
        shutil.copyfile(Path(template) / 'ios/Flutter/Debug.xcconfig', debug_xcconfig)
    print('Built build/ios/iphonesimulator/Runner.app')
elif sys.argv[1] == 'test':
    udid = sys.argv[sys.argv.index('-d') + 1]
    print('Running on ' + udid)
    set_installed(udid, True)  # flutter test installs the fixture app.
    if mode == 'leftover':
        # A detached process that keeps the workspace path, like a stray
        # tool that left its process group.
        subprocess.Popen([sys.executable, '-c', 'import time; time.sleep(120)',
                          os.getcwd(), pids], start_new_session=True,
                         stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL,
                         stderr=subprocess.DEVNULL)
    if mode == 'test-fail':
        orphan_then(1)
    elif mode == 'hang':
        orphan_then(None)
    if mode != 'app-survives':
        set_installed(udid, False)  # IntegrationTestTestDevice.kill() uninstall.
    print('00:10 +1: All tests passed!')
'''

STUB_SIMCTL = '''#!{python}
import json, sys
record, state_file, boot_output = {record!r}, {state!r}, {boot_output!r}
apps_file, faults = {apps!r}, {faults!r}
with open(record, 'a') as f:
    f.write(json.dumps({{'tool': 'simctl', 'argv': sys.argv[1:]}}) + '\\n')
data = json.load(open(state_file))
apps = json.load(open(apps_file))
action = sys.argv[1]
if action in faults:
    print('simctl: injected failure for ' + action, file=sys.stderr)
    sys.exit(faults[action])
if sys.argv[1:4] == ['list', 'devices', '--json']:
    print(json.dumps(data))
elif action in ('bootstatus', 'shutdown'):
    udid = sys.argv[2]
    for devices in data['devices'].values():
        for device in devices:
            if device['udid'] == udid:
                device['state'] = 'Booted' if action == 'bootstatus' else 'Shutdown'
    json.dump(data, open(state_file, 'w'))
    if action == 'bootstatus':
        print(boot_output)
elif action == 'listapps':
    style = faults.get('listapps_output')
    listed = apps.get(sys.argv[2], [])
    if style == 'truncated':
        print('{{')  # Exit 0 with an incomplete list.
    elif style == 'compact':
        print('{{ ' + ' '.join('"%s" = {{}};' % app for app in listed) + ' }}')
    else:
        # The old-style property list that simctl prints, one entry per app.
        print('simctl: a diagnostic line on stderr', file=sys.stderr)
        print('{{')
        for app in listed:
            print('    "%s" =     {{\\n        CFBundleIdentifier = "%s";\\n    }};' % (app, app))
        print('}}')
elif action == 'terminate':
    if sys.argv[3] not in apps.get(sys.argv[2], []):
        print('found nothing to terminate', file=sys.stderr)
        sys.exit(3)
elif action == 'uninstall':
    apps[sys.argv[2]] = [a for a in apps.get(sys.argv[2], []) if a != sys.argv[3]]
    json.dump(apps, open(apps_file, 'w'))
else:
    sys.exit(64)
'''

STUB_XCODEBUILD = '''#!{python}
import json, sys
with open({record!r}, 'a') as f:
    f.write(json.dumps({{'tool': 'xcodebuild', 'argv': sys.argv[1:]}}) + '\\n')
print({version!r})
print('Build version 27C000')
'''

# Stand-ins for the real credential tools, found by name after the runner's
# boundary. A call here means the boundary did not stop the lookup.
FAKE_REAL_TOOL = '''#!{python}
import json, sys
with open({record!r}, 'a') as f:
    f.write(json.dumps({{'tool': 'real-' + {name!r}, 'argv': sys.argv[1:]}}) + '\\n')
print('  1) 0000000000000000000000000000000000000000 "Apple Development: QA Fake (FAKE000000)"')
print('     1 valid identities found')
'''


class TempDirCase(unittest.TestCase):
    def setUp(self):
        self._dir = tempfile.TemporaryDirectory()
        self.tmp = Path(self._dir.name)
        self.addCleanup(self._dir.cleanup)


class TargetTest(unittest.TestCase):
    """Only the explicit, available, owned simulator on the given runtime."""

    owned = (SIM_UDID, SIM_NAME, RUNTIME, 'Booted', True)

    def test_the_owned_simulator_is_accepted(self):
        device = runner.find_simulator(listing(self.owned), SIM_UDID, RUNTIME)

        self.assertEqual(device['name'], SIM_NAME)
        self.assertEqual(device['runtime'], RUNTIME)

    def test_a_physical_device_id_is_rejected(self):
        with self.assertRaisesRegex(runner.RunnerError, 'physical'):
            runner.find_simulator(listing(self.owned), PHYSICAL_ID, RUNTIME)

    def test_an_unknown_udid_is_rejected(self):
        with self.assertRaisesRegex(runner.RunnerError, 'not a simulator on this host'):
            runner.find_simulator(listing(self.owned), OTHER_UDID, RUNTIME)

    def test_a_simulator_that_is_not_an_owned_qa_simulator_is_rejected(self):
        other = (OTHER_UDID, 'iPhone 16 Pro', RUNTIME, 'Booted', True)
        with self.assertRaisesRegex(runner.RunnerError, 'name'):
            runner.find_simulator(listing(self.owned, other), OTHER_UDID, RUNTIME)

    def test_the_owned_simulator_on_another_runtime_is_rejected(self):
        # Catches: the preserved iOS 27.1 QA simulator used when the caller
        # asked for the 26.5 one.
        old = (OTHER_UDID, 'Picnic Firebase QA', OTHER_RUNTIME, 'Shutdown', True)
        with self.assertRaisesRegex(runner.RunnerError, 'runtime'):
            runner.find_simulator(listing(self.owned, old), OTHER_UDID, RUNTIME)

    def test_an_unavailable_simulator_is_rejected(self):
        broken = (SIM_UDID, SIM_NAME, RUNTIME, 'Shutdown', False)
        with self.assertRaisesRegex(runner.RunnerError, 'not available'):
            runner.find_simulator(listing(broken), SIM_UDID, RUNTIME)

    def test_a_runtime_that_is_not_an_ios_runtime_id_is_rejected(self):
        with self.assertRaisesRegex(runner.RunnerError, 'runtime identifier'):
            runner.find_simulator(listing(self.owned), SIM_UDID, 'iOS 26.5')


class BootStatusTest(unittest.TestCase):
    def test_a_terminal_data_migration_failure_is_a_failure(self):
        # The coordinator's iOS 27.1 observation: exit 0, but this status.
        self.assertTrue(runner.boot_failed(['Monitoring boot status for QA.',
                                            'Data Migration Failed']))

    def test_a_false_failure_field_is_not_a_failure(self):
        self.assertFalse(runner.boot_failed(['Finished=true',
                                             'Data Migration Failed=false',
                                             'Data Migration Failed: NO']))


class ChildEnvTest(unittest.TestCase):
    def test_only_the_toolchain_and_the_explicit_xcode_reach_children(self):
        environ = {
            'PATH': '/usr/bin:/bin', 'HOME': '/Users/qa', 'QA_FAKE_SECRET': 'x',
            'DEVELOPER_DIR': '/Library/Developer/CommandLineTools',
            'GRADLE_OPTS': '-Dorg.gradle.daemon=true', 'GRADLE_USER_HOME': '/g',
            'JAVA_HOME': '/jdk', 'ANDROID_HOME': '/sdk', 'GOOGLE_APPLICATION_CREDENTIALS': '/c',
            'FLUTTER_SWIFT_PACKAGE_MANAGER': 'true',
        }
        env = runner.child_env(environ, Path('/Applications/Xcode.app/Contents/Developer'))

        self.assertEqual(env['DEVELOPER_DIR'], '/Applications/Xcode.app/Contents/Developer')
        self.assertEqual(env['COCOAPODS_DISABLE_STATS'], 'true')
        self.assertEqual(env['LANG'], 'en_US.UTF-8')
        for key in ('QA_FAKE_SECRET', 'GRADLE_OPTS', 'GRADLE_USER_HOME', 'JAVA_HOME',
                    'ANDROID_HOME', 'GOOGLE_APPLICATION_CREDENTIALS',
                    'FLUTTER_SWIFT_PACKAGE_MANAGER'):
            self.assertNotIn(key, env)


class HostSimulatorArchTest(unittest.TestCase):
    """One simulator architecture: the host's native one (mocked tools).

    Xcode 27.2 lipo rejects the two-architecture -verify_arch call that
    Flutter 3.41.4 debug_unpack_ios makes (flutter/flutter#188461).
    """

    def arch(self, answers):
        """[answers] maps a tool name to its (exit code, stdout)."""
        def fake_inspect(command, env, **kwargs):
            return answers[Path(command[0]).name]
        with mock.patch.object(runner, '_inspect', side_effect=fake_inspect):
            return runner.host_simulator_arch()

    def test_an_apple_silicon_host_selects_arm64(self):
        self.assertEqual(self.arch({'uname': (0, 'arm64\n')}), 'arm64')

    def test_an_intel_host_selects_x86_64(self):
        self.assertEqual(self.arch({'uname': (0, 'x86_64\n'), 'sysctl': (1, '')}), 'x86_64')

    def test_a_translated_process_on_apple_silicon_still_selects_arm64(self):
        # uname -m reports x86_64 under Rosetta; the hardware is arm64.
        self.assertEqual(self.arch({'uname': (0, 'x86_64\n'), 'sysctl': (0, '1\n')}),
                         'arm64')

    def test_an_unsupported_machine_fails_clearly(self):
        with self.assertRaisesRegex(runner.RunnerError, 'simulator architecture'):
            self.arch({'uname': (0, 'i386\n')})

    def test_an_unreadable_machine_fails_clearly(self):
        with self.assertRaisesRegex(runner.RunnerError, 'simulator architecture'):
            self.arch({'uname': (1, '')})


class AppStateTest(unittest.TestCase):
    """F2: installed, absent, and unknown stay distinct."""

    def test_an_installed_bundle_is_found_in_the_listapps_output(self):
        output = '{\n    "io.picnic.qa.firebaseReadiness" =     {\n    };\n}\n'
        self.assertTrue(runner.bundle_listed(output, BUNDLE))

    def test_an_unquoted_key_is_found_too(self):
        output = '{\n    io.picnic.qa.firebaseReadiness =     {\n    };\n}\n'
        self.assertTrue(runner.bundle_listed(output, BUNDLE))

    def test_a_longer_bundle_id_with_the_same_prefix_is_not_this_app(self):
        output = '{\n    "io.picnic.qa.firebaseReadiness.RunnerTests" =     {\n    };\n}\n'
        self.assertFalse(runner.bundle_listed(output, BUNDLE))

    # Remaining F2 finding: the app list must be parsed completely. These run
    # the bounded /usr/bin/plutil conversion on synthetic text only.

    def test_a_compact_dictionary_with_the_bundle_is_present(self):
        output = '{ "io.picnic.qa.firebaseReadiness" = {}; }'
        self.assertTrue(runner.bundle_listed(output, BUNDLE))

    def test_a_compact_dictionary_without_the_bundle_is_absent(self):
        output = '{ "com.example.other" = {}; }'
        self.assertFalse(runner.bundle_listed(output, BUNDLE))

    def test_a_nested_key_is_not_top_level_presence(self):
        output = '{ "com.example.other" = { "io.picnic.qa.firebaseReadiness" = {}; }; }'
        self.assertFalse(runner.bundle_listed(output, BUNDLE))

    def test_prefix_and_suffix_bundle_names_are_not_this_app(self):
        output = ('{ "io.picnic.qa.firebaseReadines" = {}; '
                  '"x.io.picnic.qa.firebaseReadiness" = {}; '
                  '"io.picnic.qa.firebaseReadiness.RunnerTests" = {}; }')
        self.assertFalse(runner.bundle_listed(output, BUNDLE))

    def test_truncated_output_is_unknown_not_absent(self):
        with self.assertRaises(runner.RunnerError):
            runner.bundle_listed('{\n', BUNDLE)

    def test_trailing_garbage_is_unknown_not_absent(self):
        with self.assertRaises(runner.RunnerError):
            runner.bundle_listed('{} garbage', BUNDLE)

    def test_a_top_level_array_is_unknown_not_absent(self):
        with self.assertRaises(runner.RunnerError):
            runner.bundle_listed('()', BUNDLE)


class AppListConverterTest(unittest.TestCase):
    """The converter's own failures are unknown, never absent (mocked)."""

    def converted(self, **kwargs):
        if 'side_effect' in kwargs:
            return mock.patch.object(runner.subprocess, 'run', side_effect=kwargs['side_effect'])
        done = subprocess.CompletedProcess(['plutil'], kwargs.get('code', 0),
                                           kwargs.get('stdout', ''), '')
        return mock.patch.object(runner.subprocess, 'run', return_value=done)

    def assert_unknown(self, **kwargs):
        with self.converted(**kwargs), self.assertRaises(runner.RunnerError):
            runner.bundle_listed('{ }', BUNDLE)

    def test_a_failed_conversion_is_unknown(self):
        self.assert_unknown(code=1, stdout='{}')

    def test_a_conversion_timeout_is_unknown(self):
        self.assert_unknown(side_effect=subprocess.TimeoutExpired(['plutil'], 10))

    def test_a_converter_that_cannot_start_is_unknown(self):
        self.assert_unknown(side_effect=OSError('no plutil'))

    def test_invalid_converted_json_is_unknown(self):
        self.assert_unknown(stdout='{"io.picnic.qa.firebaseReadiness": ')

    def test_a_converted_non_dictionary_is_unknown(self):
        self.assert_unknown(stdout='["io.picnic.qa.firebaseReadiness"]')

    def test_the_converter_is_bounded_and_reads_only_the_supplied_text(self):
        with self.converted(stdout='{}') as run:
            runner.bundle_listed('{ "a" = {}; }', BUNDLE)

        command = run.call_args.args[0]
        self.assertEqual(command[0], '/usr/bin/plutil')
        self.assertEqual(command[-1], '-')
        self.assertEqual(run.call_args.kwargs['input'], '{ "a" = {}; }')
        self.assertTrue(0 < run.call_args.kwargs['timeout'] <= 30)


class CredentialBoundaryScriptTest(TempDirCase):
    """Runs the boundary scripts themselves; no Flutter and no real tool."""

    def boundary(self):
        self.log = self.tmp / 'credential-sentinel.log'
        return runner.write_credential_boundary(self.tmp / 'boundary', self.log)

    def test_other_lookups_pass_through_to_the_system_which(self):
        # Flutter startup and create use `which` for other tools too.
        bin_dir = self.boundary()
        done = subprocess.run([str(bin_dir / 'which'), 'sh'], capture_output=True,
                              text=True, env={'PATH': '/usr/bin:/bin'})

        self.assertEqual(done.returncode, 0)
        self.assertTrue(done.stdout.strip().endswith('/sh'))
        self.assertEqual(self.log.read_text(), '')

    def test_a_path_form_lookup_of_a_credential_tool_is_blocked(self):
        bin_dir = self.boundary()
        done = subprocess.run([str(bin_dir / 'which'), '/usr/bin/security'],
                              capture_output=True, env={'PATH': '/usr/bin:/bin'})

        self.assertEqual(done.returncode, 1)
        self.assertEqual(runner.read_credential_log(self.log),
                         {'blocked_lookups': ['security'], 'credential_tool_calls': []})

    def test_the_boundary_tools_record_and_fail_without_output(self):
        bin_dir = self.boundary()
        for name in ('security', 'openssl'):
            done = subprocess.run([str(bin_dir / name), 'find-identity', '-v'],
                                  capture_output=True, text=True)
            self.assertEqual((done.returncode, done.stdout), (1, ''))

        self.assertEqual(runner.read_credential_log(self.log)['credential_tool_calls'],
                         ['security\tfind-identity -v', 'openssl\tfind-identity -v'])


class OwnedAppCleanupResultTest(TempDirCase):
    """F2 follow-up: each terminate/uninstall group cleanup must be verified.

    Mocked boundaries only: no simctl command runs and no signal is sent. A
    simctl child need not hold the workspace path, so workspace_processes()
    cannot stand in for the action's own group cleanup.
    """

    CLEAN = {'signal': None, 'remaining': False}
    LEFT = {'signal': 'SIGKILL', 'remaining': True}

    def cleanup(self, outcomes):
        """Runs cleanup() for an owned app that ends absent; [outcomes] maps
        each simctl action to its run_bounded result."""
        qa = runner.QaRun(self.tmp, {})
        args = mock.Mock(developer_dir=Path('/Developer'), simulator_udid=SIM_UDID,
                         simulator_runtime=RUNTIME, boot_timeout=30)
        self.actions = []

        def fake_run_bounded(command, **kwargs):
            self.actions.append(command[1])
            return outcomes[command[1]]

        with mock.patch.object(runner, 'installed_state', side_effect=[True, False]), \
                mock.patch.object(runner, 'run_bounded', fake_run_bounded), \
                mock.patch.object(runner, 'workspace_processes', return_value=[]):
            return runner.cleanup(qa, args, {'qa_app_owned': True,
                                             'initial_state': 'Booted'})

    def test_a_terminate_that_leaves_its_process_group_is_unverified(self):
        report = self.cleanup({'terminate': {'exit_code': 0, 'cleanup': self.LEFT},
                               'uninstall': {'exit_code': 0, 'cleanup': self.CLEAN}})

        self.assertEqual(self.actions, ['terminate', 'uninstall'])
        self.assertEqual(report['qa_app']['final'], 'absent')
        self.assertFalse(report['verified'])
        self.assertTrue(report['problems'])

    def test_an_uninstall_that_leaves_its_process_group_is_unverified(self):
        report = self.cleanup({'terminate': {'exit_code': 0, 'cleanup': self.CLEAN},
                               'uninstall': {'exit_code': 0, 'cleanup': self.LEFT}})

        self.assertEqual(report['qa_app']['final'], 'absent')
        self.assertFalse(report['verified'])

    def test_an_action_without_a_group_cleanup_result_is_unverified(self):
        for action in ('terminate', 'uninstall'):
            with self.subTest(action=action):
                outcomes = {'terminate': {'exit_code': 0, 'cleanup': self.CLEAN},
                            'uninstall': {'exit_code': 0, 'cleanup': self.CLEAN}}
                outcomes[action] = {'exit_code': 0, 'cleanup': {}}
                report = self.cleanup(outcomes)

                self.assertFalse(report['verified'])

    def test_a_truncated_final_app_list_is_unknown_and_unverified(self):
        # The final listapps exits 0 but is incomplete: not "absent".
        qa = runner.QaRun(self.tmp, {})
        args = mock.Mock(developer_dir=Path('/Developer'), simulator_udid=SIM_UDID,
                         simulator_runtime=RUNTIME, boot_timeout=30)
        with mock.patch.object(runner, '_inspect', return_value=(0, '{\n')), \
                mock.patch.object(runner, 'run_bounded') as run_bounded, \
                mock.patch.object(runner, 'workspace_processes', return_value=[]):
            report = runner.cleanup(qa, args, {'qa_app_owned': True,
                                               'initial_state': 'Booted'})

        run_bounded.assert_not_called()  # No terminate/uninstall on unknown.
        self.assertEqual(report['qa_app']['final'], 'unknown')
        self.assertFalse(report['verified'])

    def test_a_terminate_of_a_stopped_app_with_a_clean_group_is_accepted(self):
        # `simctl terminate` exits nonzero when the app is not running.
        report = self.cleanup({'terminate': {'exit_code': 3, 'cleanup': self.CLEAN},
                               'uninstall': {'exit_code': 0, 'cleanup': self.CLEAN}})

        self.assertEqual(report['qa_app']['final'], 'absent')
        self.assertTrue(report['verified'])
        self.assertEqual(report['problems'], [])


class MainWithStubToolsTest(TempDirCase):
    """Drives main() end to end with stub flutter/xcodebuild/simctl."""

    def run_main(self, mode, *, state='Booted', boot=False, xcode='Xcode 27.2',
                 udid=SIM_UDID, runtime=RUNTIME, boot_output='Finished=true',
                 template_edit=None, interrupt_after=None, installed=(),
                 faults=None, inherited_spm=True):
        bin_dir = self.tmp / 'bin'
        bin_dir.mkdir()
        developer = self.tmp / 'Xcode.app/Contents/Developer'
        (developer / 'usr/bin').mkdir(parents=True)
        self.record = self.tmp / 'record.jsonl'
        self.record.write_text('')
        self.pids_file = self.tmp / 'orphan.pid'
        self.state_file = self.tmp / 'simulators.json'
        self.state_file.write_text(json.dumps(listing(
            (SIM_UDID, SIM_NAME, RUNTIME, state, True),
            (OTHER_UDID, 'Picnic Firebase QA', OTHER_RUNTIME, 'Shutdown', True))))
        self.apps_file = self.tmp / 'apps.json'
        self.apps_file.write_text(json.dumps({SIM_UDID: [OTHER_APP, *installed]}))
        template = self.tmp / 'create-template'
        (template / 'ios/Runner.xcodeproj').mkdir(parents=True)
        (template / 'ios/Runner.xcodeproj/project.pbxproj').write_text(TEMPLATE_PBXPROJ)
        (template / 'ios/Runner').mkdir()
        with open(template / 'ios/Runner/Info.plist', 'wb') as out:
            plistlib.dump(TEMPLATE_PLIST, out)
        (template / 'ios/Flutter').mkdir()
        (template / 'ios/Flutter/Debug.xcconfig').write_text(TEMPLATE_DEBUG_XCCONFIG)
        (template / 'ios/Flutter/Release.xcconfig').write_text(TEMPLATE_RELEASE_XCCONFIG)
        if template_edit is not None:
            template_edit(template)
        values = {'python': sys.executable, 'record': str(self.record), 'mode': mode,
                  'pids': str(self.pids_file), 'template': str(template),
                  'state': str(self.state_file), 'boot_output': boot_output,
                  'version': xcode, 'apps': str(self.apps_file),
                  'faults': faults or {}, 'inherited_spm': inherited_spm,
                  'bundle': BUNDLE, 'spm_wiring': SPM_WIRING}
        for path, text in ((bin_dir / 'flutter', STUB_FLUTTER),
                           (developer / 'usr/bin/simctl', STUB_SIMCTL),
                           (developer / 'usr/bin/xcodebuild', STUB_XCODEBUILD)):
            path.write_text(text.format(**values))
            path.chmod(0o755)
        for name in ('security', 'openssl'):
            tool = bin_dir / name
            tool.write_text(FAKE_REAL_TOOL.format(name=name, **values))
            tool.chmod(0o755)
        self.workspace = self.tmp / 'workspace'
        self.workspace.mkdir()
        environ = {'PATH': f'{bin_dir}:/usr/bin:/bin', 'HOME': str(self.tmp),
                   'QA_FAKE_SECRET': 'must-not-leak', 'GRADLE_OPTS': '-Dx=1',
                   'FLUTTER_SWIFT_PACKAGE_MANAGER': 'true'}
        argv = ['--simulator-udid', udid, '--simulator-runtime', runtime,
                '--developer-dir', str(developer), '--build-timeout', '60',
                '--test-timeout', '60', '--boot-timeout', '30']
        if boot:
            argv.append('--boot-if-shutdown')
        if interrupt_after is not None:
            timer = threading.Timer(interrupt_after, _thread.interrupt_main)
            timer.start()
            self.addCleanup(timer.cancel)
        stdout, stderr = io.StringIO(), io.StringIO()
        with mock.patch.object(runner.tempfile, 'mkdtemp',
                               lambda prefix: str(self.workspace)), \
                contextlib.redirect_stdout(stdout), contextlib.redirect_stderr(stderr):
            code = runner.main(argv, environ=environ)
        self.stdout = stdout.getvalue() + stderr.getvalue()
        self.result_text = (self.workspace / 'qa-result.json').read_text()
        self.result = json.loads(self.result_text)
        self.calls = [json.loads(line) for line in self.record.read_text().splitlines()]
        self.developer = str(developer)
        return code

    def flutter_steps(self):
        return [call['argv'][0] for call in self.calls if call['tool'] == 'flutter']

    def simctl_actions(self):
        return [call['argv'][0] for call in self.calls
                if call['tool'] == 'simctl' and call['argv'][0] not in ('list', 'listapps')]

    def simctl_app_calls(self):
        return [call['argv'] for call in self.calls if call['tool'] == 'simctl'
                and call['argv'][0] in ('terminate', 'uninstall')]

    def real_credential_calls(self):
        return [call for call in self.calls if call['tool'].startswith('real-')]

    def sim_state(self):
        data = json.loads(self.state_file.read_text())
        return {d['udid']: d['state'] for ds in data['devices'].values() for d in ds}

    def installed(self):
        return json.loads(self.apps_file.read_text()).get(SIM_UDID, [])

    def test_a_pass_builds_checks_and_tests_on_the_booted_simulator_only(self):
        code = self.run_main('pass')

        self.assertEqual(code, 0, self.stdout)
        self.assertEqual(self.result['status'], 'passed')
        self.assertEqual(self.flutter_steps(), ['create', 'pub', 'build', 'test'])
        create = next(c for c in self.calls if c['tool'] == 'flutter')
        self.assertIn('--platforms=ios', create['argv'])
        test = [c for c in self.calls if c['tool'] == 'flutter'][-1]['argv']
        self.assertEqual(test[test.index('-d') + 1], SIM_UDID)
        for call in self.calls:
            if call['tool'] == 'flutter':
                self.assertEqual(call['DEVELOPER_DIR'], self.developer)
                self.assertNotIn('QA_FAKE_SECRET', call['keys'])
                self.assertNotIn('GRADLE_OPTS', call['keys'])
        # No boot, shutdown, erase, or install through simctl.
        self.assertEqual(self.simctl_actions(), [])
        self.assertEqual(self.sim_state(), {SIM_UDID: 'Booted', OTHER_UDID: 'Shutdown'})
        self.assertFalse((self.workspace / 'android').exists())
        self.assertTrue(self.result['cleanup']['verified'])
        self.assertEqual(self.result['cleanup']['simulator'], {'left_as': 'Booted'})

    def test_the_qa_plist_disables_firebase_collection_before_the_build(self):
        self.run_main('pass')

        with open(self.workspace / 'ios/Runner/Info.plist', 'rb') as source:
            plist = plistlib.load(source)
        for key, value in runner.QA_PLIST_SETTINGS.items():
            self.assertEqual(plist[key], value, key)
        self.assertFalse(plist['FirebaseMessagingAutoInitEnabled'])
        self.assertFalse(plist['FirebaseAppDelegateProxyEnabled'])
        self.assertTrue(plist['FIREBASE_ANALYTICS_COLLECTION_DEACTIVATED'])
        self.assertEqual(list(self.workspace.rglob('GoogleService-Info.plist')), [])

    def test_the_product_pod_override_and_deployment_target_are_used(self):
        self.run_main('pass')

        podfile = (self.workspace / 'ios/Podfile').read_text()
        self.assertIn("$FirebaseSDKVersion = '12.19.0'", podfile)
        self.assertEqual(self.result['pod_versions']['FirebaseCore'], '12.19.3')
        self.assertEqual(self.result['pod_versions']['FirebaseMessaging'], '12.19.0')
        project = (self.workspace / 'ios/Runner.xcodeproj/project.pbxproj').read_text()
        self.assertNotIn('IPHONEOS_DEPLOYMENT_TARGET = 13.0;', project)
        self.assertEqual(self.result['toolchain']['firebase_sdk_version'], '12.19.0')

    def test_the_simulator_udid_stays_out_of_the_result_and_stdout(self):
        self.run_main('pass')

        self.assertNotIn(SIM_UDID, self.result_text)
        self.assertNotIn(SIM_UDID, self.stdout)

    def test_a_physical_device_is_rejected_before_any_step(self):
        code = self.run_main('pass', udid=PHYSICAL_ID)

        self.assertEqual(code, 1)
        self.assertIn('physical', self.result['error'])
        self.assertEqual(self.flutter_steps(), [])

    def test_the_preserved_simulator_on_another_runtime_is_rejected(self):
        code = self.run_main('pass', udid=OTHER_UDID)

        self.assertEqual(code, 1)
        self.assertIn('runtime', self.result['error'])
        self.assertEqual(self.flutter_steps(), [])
        self.assertEqual(self.simctl_actions(), [])

    def test_an_unsupported_xcode_is_rejected_before_any_step(self):
        code = self.run_main('pass', xcode='Xcode 26.4')

        self.assertEqual(code, 1)
        self.assertIn('unsupported Xcode', self.result['error'])
        self.assertEqual(self.flutter_steps(), [])

    def test_a_shutdown_simulator_is_not_booted_without_the_flag(self):
        code = self.run_main('pass', state='Shutdown')

        self.assertEqual(code, 1)
        self.assertIn('Shutdown', self.result['error'])
        self.assertEqual(self.flutter_steps(), [])
        self.assertEqual(self.simctl_actions(), [])
        self.assertEqual(self.sim_state()[SIM_UDID], 'Shutdown')

    def test_a_simulator_the_runner_booted_is_shut_down_after_a_pass(self):
        code = self.run_main('pass', state='Shutdown', boot=True)

        self.assertEqual(code, 0, self.stdout)
        self.assertEqual(self.simctl_actions(), ['bootstatus', 'shutdown'])
        self.assertEqual(self.sim_state(), {SIM_UDID: 'Shutdown', OTHER_UDID: 'Shutdown'})
        self.assertEqual(self.result['cleanup']['simulator']['final_state'], 'Shutdown')

    def test_a_reported_boot_failure_fails_and_restores_the_simulator(self):
        # Catches: bootstatus exit 0 taken as a clean boot (iOS 27.1 run).
        code = self.run_main('pass', state='Shutdown', boot=True,
                             boot_output='Data Migration Failed')

        self.assertEqual(code, 1)
        self.assertIn('boot failure', self.result['error'])
        self.assertEqual(self.flutter_steps(), ['create', 'pub', 'build'])
        self.assertEqual(self.simctl_actions(), ['bootstatus', 'shutdown'])
        self.assertEqual(self.sim_state()[SIM_UDID], 'Shutdown')

    def test_a_build_failure_is_reported_only_after_cleanup(self):
        code = self.run_main('build-fail')

        self.assertEqual(code, 1)
        self.assertEqual(self.result['status'], 'failed')
        self.assertIn('build-simulator', self.result['error'])
        step = self.result['steps'][-1]
        self.assertEqual(step['cleanup'], {'signal': 'SIGKILL', 'remaining': False})
        self.assertEqual(wait_all_dead(read_pids(self.pids_file)), [])
        self.assertEqual(self.flutter_steps(), ['create', 'pub', 'build'])
        self.assertEqual(self.sim_state()[SIM_UDID], 'Booted', 'not ours to stop')

    def test_pod_drift_from_the_product_lock_fails_before_the_test(self):
        code = self.run_main('pod-drift')

        self.assertEqual(code, 1)
        self.assertIn('FirebaseCore', self.result['error'])
        self.assertEqual(self.flutter_steps(), ['create', 'pub', 'build'])

    def test_a_built_app_without_the_qa_plist_settings_is_not_tested(self):
        code = self.run_main('built-plist-reset')

        self.assertEqual(code, 1)
        self.assertIn('Info.plist QA settings', self.result['error'])
        self.assertEqual(self.flutter_steps(), ['create', 'pub', 'build'])

    def test_a_template_with_another_bundle_id_fails_before_pub_get(self):
        def product_id(template):
            path = template / 'ios/Runner.xcodeproj/project.pbxproj'
            path.write_text(path.read_text().replace(
                'io.picnic.qa.firebaseReadiness', 'io.iconcasting.picnic.app'))

        code = self.run_main('pass', template_edit=product_id)

        self.assertEqual(code, 1)
        self.assertIn('bundle identifier', self.result['error'])
        self.assertEqual(self.flutter_steps(), ['create'])

    def test_a_template_with_entitlements_fails_before_pub_get(self):
        def entitlements(template):
            path = template / 'ios/Runner.xcodeproj/project.pbxproj'
            path.write_text(path.read_text() +
                            '\t\t\t\tCODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;\n')

        code = self.run_main('pass', template_edit=entitlements)

        self.assertEqual(code, 1)
        self.assertIn('CODE_SIGN_ENTITLEMENTS', self.result['error'])
        self.assertEqual(self.flutter_steps(), ['create'])

    def test_a_firebase_config_file_in_the_project_fails_before_pub_get(self):
        def google_plist(template):
            (template / 'ios/Runner/GoogleService-Info.plist').write_text('<plist/>')

        code = self.run_main('pass', template_edit=google_plist)

        self.assertEqual(code, 1)
        self.assertIn('GoogleService-Info.plist', self.result['error'])
        self.assertEqual(self.flutter_steps(), ['create'])

    def test_an_android_directory_fails_before_pub_get(self):
        code = self.run_main('pass', template_edit=lambda t: (t / 'android').mkdir())

        self.assertEqual(code, 1)
        self.assertIn('iOS only', self.result['error'])

    def test_a_left_process_holding_the_workspace_is_reported_not_signalled(self):
        code = self.run_main('leftover')
        found = self.result['cleanup']['workspace_processes']
        for pid in found:
            self.addCleanup(kill_if_marked, pid, str(self.pids_file))

        self.assertEqual(code, 1)
        self.assertEqual(self.result['status'], 'failed')
        self.assertIn('cleanup is not verified', self.result['error'])
        self.assertEqual(len(found), 1)
        self.assertTrue(alive(found[0]), 'the runner must not signal it')

    def test_a_failed_test_is_reported_only_after_cleanup(self):
        code = self.run_main('test-fail')

        self.assertEqual(code, 1)
        self.assertIn('simulator-test', self.result['error'])
        self.assertEqual(self.result['steps'][-1]['cleanup']['remaining'], False)
        self.assertEqual(wait_all_dead(read_pids(self.pids_file)), [])

    def test_an_interrupted_run_is_cleaned_up_and_reported(self):
        code = self.run_main('hang', interrupt_after=3.0)

        self.assertEqual(code, 130)
        self.assertEqual(self.result['status'], 'interrupted')
        self.assertEqual(wait_all_dead(read_pids(self.pids_file)), [])
        self.assertIn('cleanup', self.result)

    # --- F1: signing discovery during `flutter create` ---------------------

    def test_create_signing_discovery_never_reaches_a_credential_tool(self):
        # Catches (F1): create.dart 417-428 runs `security find-identity`
        # through code_signing.dart 331-336 before any runner check.
        code = self.run_main('pass')

        self.assertEqual(code, 0, self.stdout)
        self.assertEqual(self.real_credential_calls(), [])
        boundary = self.result['signing_boundary']
        self.assertIn('security', boundary['blocked_lookups'])
        self.assertEqual(boundary['credential_tool_calls'], [])

    def test_the_credential_boundary_is_only_on_the_create_step(self):
        self.run_main('pass')

        paths = {call['argv'][0]: call['PATH'] for call in self.calls
                 if call['tool'] == 'flutter'}
        boundary = str(self.workspace / 'qa-credential-boundary')
        self.assertTrue(paths['create'].startswith(boundary + '/'))
        for step in ('pub', 'build', 'test'):
            self.assertNotIn(boundary, paths[step])

    def test_a_direct_credential_tool_call_is_caught_and_fails_the_run(self):
        # Fail-closed: a Flutter that skips `which` still finds the
        # boundary's tool first, which records the call and exits 1.
        code = self.run_main('skip-which')

        self.assertEqual(code, 1)
        self.assertEqual(self.real_credential_calls(), [])
        self.assertIn('credential tool', self.result['error'])
        self.assertEqual(self.flutter_steps(), ['create'])

    # --- F3: CocoaPods, not Swift Package Manager -------------------------

    def test_inherited_spm_enablement_is_overridden_by_the_project_config(self):
        # Catches (F3): a globally enabled SPM (flutter config or the
        # environment) selecting SwiftPM, so podhelper.rb 325-328 skips the
        # Firebase pods and Package.swift pins firebase-ios-sdk 13.1.1.
        code = self.run_main('pass', inherited_spm=True)

        self.assertEqual(code, 0, self.stdout)
        pubspec = (self.workspace / 'pubspec.yaml').read_text()
        self.assertIn('  config:\n    enable-swift-package-manager: false\n', pubspec)
        project = (self.workspace / 'ios/Runner.xcodeproj/project.pbxproj').read_text()
        self.assertNotIn('FlutterGeneratedPluginSwiftPackage', project)
        self.assertEqual(self.result['dependency_manager'],
                         {'swift_package_manager_enabled': False, 'manager': 'cocoapods'})

    def test_spm_wiring_that_survives_the_config_fails_before_pub_get(self):
        code = self.run_main('spm-forced')

        self.assertEqual(code, 1)
        self.assertIn('Swift Package Manager', self.result['error'])
        self.assertEqual(self.flutter_steps(), ['create'])

    # --- F2: ownership and teardown of this run's QA app ------------------

    def test_a_preexisting_qa_bundle_is_refused_and_left_installed(self):
        code = self.run_main('pass', installed=[BUNDLE])

        self.assertEqual(code, 1)
        self.assertIn('already installed', self.result['error'])
        self.assertNotIn('test', self.flutter_steps())
        self.assertEqual(self.simctl_app_calls(), [])
        self.assertEqual(sorted(self.installed()), sorted([OTHER_APP, BUNDLE]))

    def test_an_app_that_survives_flutter_teardown_is_removed_and_verified(self):
        # Flutter's kill() only logs a failed uninstall
        # (integration_test_device.dart 138-146); the app process path is in
        # the simulator, not the workspace.
        code = self.run_main('app-survives')

        self.assertEqual(code, 0, self.stdout)
        self.assertEqual(self.simctl_app_calls(), [['terminate', SIM_UDID, BUNDLE],
                                                   ['uninstall', SIM_UDID, BUNDLE]])
        self.assertEqual(self.installed(), [OTHER_APP])
        self.assertEqual(self.result['cleanup']['qa_app']['final'], 'absent')
        self.assertTrue(self.result['cleanup']['verified'])

    def test_a_passed_test_fails_if_an_app_cleanup_action_leaves_processes(self):
        real = runner.run_bounded

        def uninstall_leaves_its_group(command, **kwargs):
            outcome = real(command, **kwargs)
            if command[1:2] == ['uninstall']:
                outcome['cleanup'] = {'signal': 'SIGKILL', 'remaining': True}
            return outcome

        with mock.patch.object(runner, 'run_bounded', uninstall_leaves_its_group):
            code = self.run_main('app-survives')

        self.assertEqual(code, 1)
        self.assertEqual(self.result['status'], 'failed')
        self.assertIn('cleanup is not verified', self.result['error'])
        self.assertEqual(self.result['cleanup']['qa_app']['final'], 'absent')

    def test_an_app_removed_by_flutter_is_verified_without_simctl_changes(self):
        code = self.run_main('pass')

        self.assertEqual(code, 0, self.stdout)
        self.assertEqual(self.simctl_app_calls(), [])
        self.assertEqual(self.installed(), [OTHER_APP])
        self.assertEqual(self.result['cleanup']['qa_app']['final'], 'absent')

    def test_a_failed_uninstall_makes_the_cleanup_unverified(self):
        code = self.run_main('app-survives', faults={'uninstall': 1})

        self.assertEqual(code, 1)
        self.assertIn('cleanup is not verified', self.result['error'])
        self.assertIn(BUNDLE, self.installed())
        self.assertIn(OTHER_APP, self.installed())

    def test_a_failed_app_query_before_the_test_stops_the_run(self):
        code = self.run_main('pass', faults={'listapps': 1})

        self.assertEqual(code, 1)
        self.assertIn('installed apps', self.result['error'])
        self.assertNotIn('test', self.flutter_steps())
        self.assertEqual(self.simctl_app_calls(), [])

    def test_a_truncated_app_list_with_exit_0_prevents_ownership(self):
        code = self.run_main('pass', faults={'listapps_output': 'truncated'})

        self.assertEqual(code, 1)
        self.assertIn('installed app list', self.result['error'])
        self.assertNotIn('test', self.flutter_steps())
        self.assertEqual(self.simctl_app_calls(), [])
        self.assertNotIn('qa_app', self.result['cleanup'])
        self.assertEqual(self.sim_state()[SIM_UDID], 'Booted')

    def test_a_preexisting_bundle_in_a_compact_list_is_refused(self):
        code = self.run_main('pass', installed=[BUNDLE],
                             faults={'listapps_output': 'compact'})

        self.assertEqual(code, 1)
        self.assertIn('already installed', self.result['error'])
        self.assertNotIn('test', self.flutter_steps())
        self.assertEqual(self.simctl_app_calls(), [])
        self.assertIn(BUNDLE, self.installed())

    def test_a_compact_list_without_the_bundle_allows_a_verified_pass(self):
        code = self.run_main('pass', faults={'listapps_output': 'compact'})

        self.assertEqual(code, 0, self.stdout)
        self.assertEqual(self.result['cleanup']['qa_app']['final'], 'absent')
        self.assertTrue(self.result['cleanup']['verified'])

    # --- Xcode 27.2 / Flutter 3.41.4: one simulator architecture -----------

    def test_build_and_test_use_one_qa_debug_simulator_architecture(self):
        # Catches: debug_unpack_ios failing at `lipo -verify_arch arm64
        # x86_64` (native run 1) because the QA build has two simulator archs.
        product = ROOT_DIR / 'picnic_app/ios/Flutter/Debug.xcconfig'
        product_before = product.read_bytes()

        code = self.run_main('pass')

        self.assertEqual(code, 0, self.stdout)
        arch = self.result['simulator_arch']
        self.assertIn(arch, ('arm64', 'x86_64'))
        steps = {c['argv'][0]: c['sim_archs'] for c in self.calls if c['tool'] == 'flutter'}
        self.assertEqual(steps['build'], [arch])
        self.assertEqual(steps['test'], [arch])
        release = (self.workspace / 'ios/Flutter/Release.xcconfig').read_text()
        self.assertEqual(release, TEMPLATE_RELEASE_XCCONFIG)
        self.assertEqual(product.read_bytes(), product_before)

    def test_the_selected_architecture_is_the_hosts(self):
        with mock.patch.object(runner, 'host_simulator_arch', return_value='x86_64'):
            code = self.run_main('pass')

        self.assertEqual(code, 0, self.stdout)
        self.assertEqual(self.result['simulator_arch'], 'x86_64')
        debug = (self.workspace / 'ios/Flutter/Debug.xcconfig').read_text()
        self.assertEqual(SIM_ARCHS.findall(debug), ['x86_64'])

    def test_an_unsupported_host_fails_before_any_step(self):
        with mock.patch.object(runner, 'host_simulator_arch',
                               side_effect=runner.RunnerError('unsupported simulator '
                                                              'architecture: i386')):
            code = self.run_main('pass')

        self.assertEqual(code, 1)
        self.assertIn('simulator architecture', self.result['error'])
        self.assertEqual(self.flutter_steps(), [])

    def test_a_template_that_already_sets_archs_fails_before_pub_get(self):
        def preset(template):
            path = template / 'ios/Flutter/Debug.xcconfig'
            path.write_text(path.read_text() + 'ARCHS = arm64 x86_64\n')

        code = self.run_main('pass', template_edit=preset)

        self.assertEqual(code, 1)
        self.assertIn('ARCHS', self.result['error'])
        self.assertEqual(self.flutter_steps(), ['create'])

    def test_a_runner_debug_config_without_the_xcconfig_base_fails(self):
        def no_base(template):
            path = template / 'ios/Runner.xcodeproj/project.pbxproj'
            path.write_text(path.read_text().replace(' /* Debug.xcconfig */', ''))

        code = self.run_main('pass', template_edit=no_base)

        self.assertEqual(code, 1)
        self.assertIn('Debug.xcconfig', self.result['error'])
        self.assertEqual(self.flutter_steps(), ['create'])

    def test_a_build_that_drops_the_setting_is_not_tested(self):
        code = self.run_main('xcconfig-reset')

        self.assertEqual(code, 1)
        self.assertIn('simulator architecture', self.result['error'])
        self.assertEqual(self.flutter_steps(), ['create', 'pub', 'build'])

    def test_a_failed_app_query_after_the_test_is_unverified(self):
        real = runner.installed_state
        calls = []

        def fails_after_ownership(*args):
            calls.append(args)
            if len(calls) == 1:
                return real(*args)
            raise runner.RunnerError('cannot list installed apps (injected)')

        with mock.patch.object(runner, 'installed_state', fails_after_ownership):
            code = self.run_main('pass')

        self.assertEqual(code, 1)
        self.assertIn('cleanup is not verified', self.result['error'])
        self.assertEqual(self.result['cleanup']['qa_app']['final'], 'unknown')

    def test_an_interrupted_test_removes_this_runs_app_only(self):
        code = self.run_main('hang', interrupt_after=3.0)

        self.assertEqual(code, 130)
        self.assertEqual(self.installed(), [OTHER_APP])
        self.assertEqual(self.simctl_app_calls(), [['terminate', SIM_UDID, BUNDLE],
                                                   ['uninstall', SIM_UDID, BUNDLE]])
        self.assertEqual(self.sim_state()[SIM_UDID], 'Booted')

    def test_no_app_cleanup_runs_before_ownership_is_established(self):
        # A build failure happens before the ownership check: nothing on the
        # simulator belongs to this run, so nothing there is touched.
        self.run_main('build-fail', installed=[BUNDLE])

        self.assertEqual(self.simctl_app_calls(), [])
        self.assertIn(BUNDLE, self.installed())


def flutter_settings_files(environ):
    """The settings files that the installed Flutter Config can use
    (base/config.dart 195-210): ~/.flutter_settings, or
    $XDG_CONFIG_HOME/settings, or ~/.config/flutter/settings."""
    home = Path(environ['HOME'])
    xdg = environ.get('XDG_CONFIG_HOME')
    return [home / '.flutter_settings',
            Path(xdg) / 'settings' if xdg else home / '.config/flutter/settings']


def stat_signature(paths):
    """(size, mtime_ns) per path, or None; no file content is read."""
    result = {}
    for path in paths:
        try:
            info = path.stat()
            result[str(path)] = (info.st_size, info.st_mtime_ns)
        except FileNotFoundError:
            result[str(path)] = None
    return result


@unittest.skipUnless(os.environ.get('QA_RUN_FLUTTER_CREATE_PROBE') == '1',
                     'installed-Flutter create probe; the coordinator sets '
                     'QA_RUN_FLUTTER_CREATE_PROBE=1 after inspecting the boundary')
class FlutterCreateProbe(TempDirCase):
    """Runs only the runner's create step with the installed `flutter`.

    No pub get, build, install, simulator, or network step runs. The probe
    uses the runner's own boundary, then replaces its `security` with a fake
    that prints one synthetic development identity (one identity is
    auto-selected and never saved, code_signing.dart 763-765), so a wrong
    boundary still ends at fakes: the fake `security` and `openssl` record
    the call and exit 1 for anything but find-identity. The real tools are
    reachable only by absolute path, which the installed create path does
    not use. stdin is not a terminal, so no selection prompt can appear.

    It checks: the boundary was consulted (`which security` blocked), no
    credential tool was called, the generated project has no
    DEVELOPMENT_TEAM, the project config keeps SPM off, and the size and
    modification time of the Flutter settings files did not change. Flutter
    still reads its settings file at startup; this probe does not claim
    that no configuration file is read. HOME, XDG_CONFIG_HOME, and Flutter
    settings are not changed.
    """

    def test_create_with_the_installed_flutter_stays_behind_the_boundary(self):
        developer = Path(os.environ.get('QA_DEVELOPER_DIR',
                                        '/Applications/Xcode.app/Contents/Developer'))
        workspace = self.tmp / 'workspace'
        workspace.mkdir()
        qa = runner.QaRun(workspace, runner.child_env(os.environ, developer))
        boundary = runner.write_credential_boundary(
            workspace / 'qa-credential-boundary', qa.logs / 'credential-sentinel.log')
        fake = boundary / 'security'
        fake.write_text(fake.read_text().replace(
            'exit 1\n',
            'case "$1" in find-identity) echo \'  1) 0000000000000000000000000000000000000000 '
            '"Apple Development: QA Fake (FAKE000000)"\'; exit 0;; esac\nexit 1\n', 1))
        settings = flutter_settings_files(qa.env)
        before = stat_signature(settings)

        try:
            runner.write_pubspec(workspace)
            runner.create_project(qa, timeout=300, boundary=boundary)
        finally:
            after = stat_signature(settings)
            print('QA_FLUTTER_CREATE_PROBE=' + json.dumps({
                'signing_boundary': qa.result.get('signing_boundary'),
                'settings_unchanged': before == after,
                'steps': qa.result['steps']}), flush=True)

        self.assertEqual(qa.result['signing_boundary']['credential_tool_calls'], [])
        self.assertIn('security', qa.result['signing_boundary']['blocked_lookups'])
        project = (workspace / 'ios/Runner.xcodeproj/project.pbxproj').read_text()
        self.assertNotIn('DEVELOPMENT_TEAM', project)
        self.assertNotIn('FlutterGeneratedPluginSwiftPackage', project)
        self.assertIn('enable-swift-package-manager: false',
                      (workspace / 'pubspec.yaml').read_text())
        self.assertEqual(before, after, 'a Flutter settings file changed')


if __name__ == '__main__':
    unittest.main()

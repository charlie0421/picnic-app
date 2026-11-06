"""Regression tests for run_full_app_retry_android.py.

Run from the repository root:
    python3 scripts/qa/test_run_full_app_retry_android.py -v

`flutter`, `adb` and `apkanalyzer` are stub scripts, the Android SDK and the
device are directories, and the product source root is a synthetic tree in a
temporary directory. No device, emulator, Gradle build, network or real
configuration is used, and no test signals a process: interruptions are
injected as exceptions after a stub step returns. A pass proves the runner's
isolation, artifact, user scope, ownership and cleanup logic only. It is not
a native device or Firebase result.
"""
import contextlib
import hashlib
import io
import json
import os
from pathlib import Path
import sys
import tempfile
import textwrap
import unittest
from unittest import mock
import zipfile

sys.path.insert(0, str(Path(__file__).resolve().parent))
import run_firebase_device_android as base  # noqa: E402
import run_full_app_retry_android as runner  # noqa: E402

SERIAL = 'QA-FAKE-SERIAL-0002'
PACKAGE = 'io.picnic.qa.full.picnic_app'
PRODUCT_PACKAGE = 'io.iconcasting.picnic.app'
SECRET = 'QA-SECRET-SENTINEL-must-never-be-copied'
DEFINES = ['--dart-define=PANGLE_ENVIRONMENT=sandbox',
           '--dart-define=PAYMENT_ENVIRONMENT=sandbox']
EXPECTED_CHECKPOINTS = ['A1', 'A2', 'A3', 'A4', 'A5', 'cleanup']
ONE_USER = {'code': 0, 'out': 'Users:\n\tUserInfo{0:Owner:c13} running\n', 'err': ''}
TWO_USERS = {'code': 0, 'out': ('Users:\n\tUserInfo{0:Owner:c13} running\n'
                                '\tUserInfo{10:Work profile:1030} running\n'), 'err': ''}
CURRENT_0 = {'code': 0, 'out': '0\n', 'err': ''}

PRODUCT_PUBSPEC = textwrap.dedent('''\
    name: picnic_app
    description: "Picnic App"
    publish_to: 'none'

    version: 1.3.6+130605

    environment:
        sdk: '>=3.3.1 <4.0.0'

    dependencies:
        flutter:
            sdk: flutter
        picnic_lib:
            path: ../picnic_lib
        firebase_core: ^5.1.0
        flutter_phoenix: ^1.1.1
    dev_dependencies:
        firebase_messaging: ^17.0.1
        build_runner: ^2.4.13
        flutter_test:
            sdk: flutter

    dependency_overrides:
    flutter:
        uses-material-design: true
        generate: true
        assets:
            - config/
            - assets/login/
            - assets/splash.webp
            - shorebird.yaml
    ''')

PRODUCT_LOCK = textwrap.dedent('''\
    packages:
      firebase_core:
        dependency: "direct main"
        source: hosted
        version: "5.1.0"
      firebase_core_platform_interface:
        dependency: transitive
        source: hosted
        version: "8.1.1"
      firebase_messaging:
        dependency: "direct dev"
        source: hosted
        version: "17.0.1"
      flutter_driver:
        dependency: transitive
        description: flutter
        source: sdk
        version: "0.0.0"
      build_runner:
        dependency: "direct dev"
        source: hosted
        version: "2.4.13"
      picnic_lib:
        dependency: "direct main"
        description:
          path: "../picnic_lib"
          relative: true
        source: path
        version: "0.0.1"
    ''')

CREATE_TEMPLATE = {
    'app/build.gradle.kts': textwrap.dedent('''\
        android {
            namespace = "io.picnic.qa.full.picnic_app"
            compileOptions {
                sourceCompatibility = JavaVersion.VERSION_17
                targetCompatibility = JavaVersion.VERSION_17
            }

            kotlinOptions {
                jvmTarget = JavaVersion.VERSION_17.toString()
            }

            defaultConfig {
                applicationId = "io.picnic.qa.full.picnic_app"
            }
        }
        '''),
    'settings.gradle.kts': textwrap.dedent('''\
        plugins {
            id("com.android.application") version "8.7.3" apply false
            id("org.jetbrains.kotlin.android") version "2.1.0" apply false
        }
        '''),
    'gradle/wrapper/gradle-wrapper.properties':
        'distributionUrl=https\\://services.gradle.org/distributions/gradle-8.12-all.zip\n',
    'app/src/main/AndroidManifest.xml': '<manifest><application></application></manifest>\n',
    'build.gradle.kts': 'allprojects {\n    repositories {\n        google()\n    }\n}\n',
    'gradle.properties': 'org.gradle.jvmargs=-Xmx1G\n',
    # flutter create writes the SDK paths here; it is not a product secret.
    'local.properties': 'flutter.sdk=/opt/flutter\n',
}

META = {
    'firebase_messaging_auto_init_enabled': 'false',
    'firebase_analytics_collection_enabled': 'false',
    'firebase_analytics_collection_deactivated': 'true',
    'google_analytics_adid_collection_enabled': 'false',
    'com.google.android.gms.ads.APPLICATION_ID': 'ca-app-pub-3940256099942544~3347511713',
}


def manifest_xml(package=PACKAGE, meta=None, extra=''):
    meta = META if meta is None else meta
    items = ''.join(f'    <meta-data android:name="{name}" android:value="{value}"/>\n'
                    for name, value in meta.items())
    return ('<?xml version="1.0" encoding="utf-8"?>\n'
            '<manifest xmlns:android="http://schemas.android.com/apk/res/android" '
            f'android:versionCode="1" android:versionName="0.0.1" package="{package}">\n'
            '  <application android:label="picnic_app">\n'
            '    <meta-data android:name="flutterEmbedding" android:value="2"/>\n'
            f'{items}{extra}'
            '    <activity android:name=".MainActivity"/>\n'
            '  </application>\n'
            '</manifest>\n')


MANIFESTS = {
    'good': manifest_xml(),
    'wrong-package': manifest_xml(package=PACKAGE + '.other'),
    'auto-init-true': manifest_xml(meta=dict(META, firebase_messaging_auto_init_enabled='true')),
    'missing-meta': manifest_xml(meta={k: v for k, v in META.items()
                                       if k != 'firebase_analytics_collection_enabled'}),
    'duplicate-meta': manifest_xml(extra='    <meta-data android:name='
                                         '"firebase_messaging_auto_init_enabled" '
                                         'android:value="false"/>\n'),
    'malformed': '<manifest package="io.picnic.qa.full.picnic_app"><application>',
}

STUB_FLUTTER = '''#!{python}
import json, os, shutil, sys, zipfile
from pathlib import Path
record, mode, template, device, sdk = {record!r}, {mode!r}, {template!r}, {device!r}, {sdk!r}
manifest = {manifest!r}
argv = sys.argv[1:]
with open(record, 'a') as f:
    f.write(json.dumps({{'tool': 'flutter', 'argv': argv, 'cwd': os.getcwd(),
                        'keys': sorted(os.environ)}}) + '\\n')
ws = Path(os.getcwd())
built = ws / 'build/app/outputs/flutter-apk/app-debug.apk'
if argv[:2] == ['config', '--machine']:
    if mode == 'config-malformed':
        print('Settings: not json')
    elif mode == 'config-no-sdk':
        print(json.dumps({{'enable-analytics': False}}))
    else:
        print(json.dumps({{'android-sdk': sdk, 'jdk-dir': '/qa/jdk'}}))
elif argv[0] == 'create':
    target = Path(argv[-1])
    shutil.copytree(template, target / 'android', dirs_exist_ok=True)
    (target / 'lib').mkdir(exist_ok=True)
    (target / 'lib/main.dart').write_text('// generated counter app\\n')
    (target / 'test').mkdir(exist_ok=True)
    (target / 'test/widget_test.dart').write_text('// generated test\\n')
    (target / 'pubspec.yaml').write_text('name: picnic_app\\n')
elif argv[0] == 'pub':
    lock = ws / 'pubspec.lock'
    text = lock.read_text()
    if mode == 'drift':
        text = text.replace('version: "5.1.0"', 'version: "5.2.0"')
    if mode == 'extra':
        text += '  qa_extra:\\n    source: hosted\\n    version: "1.0.0"\\n'
    lock.write_text(text)
elif argv[0] == 'build':
    built.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(built, 'w') as z:
        z.writestr('AndroidManifest.xml', 'binary')
        z.writestr('qa-stub-manifest.xml', manifest)
        z.writestr('assets/flutter_assets/AssetManifest.bin', 'manifest')
        z.writestr('assets/flutter_assets/assets/splash.webp', 'webp')
        if mode == 'leak':
            z.writestr('assets/flutter_assets/config/prod.json', '{{}}')
elif argv[0] == 'drive':
    binary = [a.split('=', 1)[1] for a in argv if a.startswith('--use-application-binary=')]
    user = argv[argv.index('--device-user') + 1]
    installed = json.loads((Path(device) / 'installed.json').read_text())
    installed.append(user)
    (Path(device) / 'installed.json').write_text(json.dumps(installed))
    if mode == 'rebuild':
        built.write_bytes(built.read_bytes() + b'rebuilt during drive')
    checkpoints = ['A1', 'A2', 'A3', 'A4', 'A5', 'cleanup']
    if mode == 'missing-checkpoint':
        checkpoints = checkpoints[:4]
    data = {{'checkpoints': checkpoints, 'facts': {{name: {{'ok': True}} for name in checkpoints}},
            'summary': {{'loopbackUnexpected': ['POST /rest/v1/x']}}, 'bodyCompleted': True}}
    print('QA_FULL_APP_CHECKPOINT A1 {{}}')  # Console lines are diagnostics only.
    if mode not in ('no-response', 'connection-error'):
        response = ws / 'qa-driver/response.json'
        response.parent.mkdir(parents=True, exist_ok=True)
        if mode == 'fail':
            data['bodyCompleted'] = False
        response.write_text(json.dumps(data))
    if mode == 'connection-error':
        print('DriverError: Failed to connect to the VM service')
        sys.exit(1)
    if mode == 'fail':
        print('Failure Details: A4 timed out')
        sys.exit(1)
    if mode != 'keep-installed':
        # flutter drive stops and uninstalls the app for the same user.
        installed.remove(user)
        (Path(device) / 'installed.json').write_text(json.dumps(installed))
    print('All tests passed.')
'''

STUB_ADB = '''#!{python}
import json, sys
from pathlib import Path
record, device = {record!r}, Path({device!r})
argv = sys.argv[1:]
with open(record, 'a') as f:
    f.write(json.dumps({{'tool': 'adb', 'argv': argv}}) + '\\n')
config = json.loads((device / 'config.json').read_text())
installed = json.loads((device / 'installed.json').read_text())

def bump(kind):
    counter = device / ('count-' + kind)
    count = int(counter.read_text()) + 1 if counter.exists() else 1
    counter.write_text(str(count))
    return count

def answer(entries, count):
    entry = entries[min(count, len(entries)) - 1]
    sys.stdout.write(entry['out'])
    sys.stderr.write(entry['err'])
    sys.exit(entry['code'])

args = argv[2:] if argv[:1] == ['-s'] else argv
if args == ['get-state']:
    print('device')
elif args == ['shell', 'pm', 'list', 'users']:
    answer(config['users'], bump('users'))
elif args == ['shell', 'am', 'get-current-user']:
    answer(config['current'], bump('current'))
elif args[:4] == ['shell', 'pm', 'list', 'packages']:
    count = bump('pm')
    override = config.get('pm_override', {{}}).get(str(count))
    if override is not None:
        answer([override], 1)
    if args[4:6] != ['--user', '0'] or len(args) != 7:
        print('unqualified package query', file=sys.stderr)
        sys.exit(2)
    print('package:{product}')
    print('package:{package}.other')
    print('package:io.picnic.qa.full.picnic')
    if '0' in installed:
        print('package:{package}')
elif args[:3] == ['shell', 'am', 'force-stop']:
    if args[3:5] != ['--user', '0']:
        sys.exit(2)
elif args[:1] == ['uninstall']:
    if args[1:3] != ['--user', '0']:
        print('unqualified uninstall', file=sys.stderr)
        sys.exit(2)
    if config.get('uninstall_fails'):
        print('Failure [DELETE_FAILED_INTERNAL_ERROR]')
        sys.exit(1)
    if '0' in installed:
        installed.remove('0')
        (device / 'installed.json').write_text(json.dumps(installed))
        print('Success')
    else:
        print('Failure [DELETE_FAILED_INTERNAL_ERROR]')
        sys.exit(1)
elif args[:2] == ['shell', 'pidof']:
    if config.get('pid_remains'):
        print('4321')
        sys.exit(0)
    sys.exit(1)
else:
    print('unexpected adb call', file=sys.stderr)
    sys.exit(2)
'''

STUB_APKANALYZER = '''#!{python}
import json, os, sys, zipfile
from pathlib import Path
record, mode = {record!r}, {mode!r}
argv = sys.argv[1:]
with open(record, 'a') as f:
    f.write(json.dumps({{'tool': 'apkanalyzer', 'argv': argv}}) + '\\n')
if argv[:2] != ['manifest', 'print'] or len(argv) != 3:
    sys.exit(2)
apk = Path(argv[2])
if mode == 'fail':
    print('Exception in thread "main" java.lang.NoClassDefFoundError', file=sys.stderr)
    sys.exit(1)
with zipfile.ZipFile(apk) as z:
    text = z.read('qa-stub-manifest.xml').decode()
print('WARNING: a JVM warning on stderr', file=sys.stderr)
sys.stdout.write(text)
if mode == 'tamper':
    os.chmod(apk, 0o644)
    apk.write_bytes(apk.read_bytes() + b'replaced after inspection')
'''


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def write(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    if isinstance(text, bytes):
        path.write_bytes(text)
    else:
        path.write_text(text)


class FullAppRunnerCase(unittest.TestCase):
    """Drives main() end to end with stub tools and a fake source root."""

    def setUp(self):
        self._dir = tempfile.TemporaryDirectory()
        self.tmp = Path(self._dir.name)
        self.addCleanup(self._dir.cleanup)
        self.source = self.tmp / 'source-root'
        self.make_source(self.source)
        self.device = self.tmp / 'device'
        self.device.mkdir()
        self.sdk = self.tmp / 'android-sdk'
        for directory in ('licenses', 'platform-tools', 'platforms/android-35',
                          'build-tools/35.0.0', 'cmdline-tools/latest/bin'):
            (self.sdk / directory).mkdir(parents=True)
        self.device_config({})

    def device_config(self, overrides, installed=()):
        config = {'users': [ONE_USER], 'current': [CURRENT_0]}
        config.update(overrides)
        (self.device / 'config.json').write_text(json.dumps(config))
        (self.device / 'installed.json').write_text(json.dumps(list(installed)))

    def make_source(self, root):
        app = root / 'picnic_app'
        write(app / 'pubspec.yaml', PRODUCT_PUBSPEC)
        write(app / 'pubspec.lock', PRODUCT_LOCK)
        write(app / 'lib/app.dart', 'class App {}\n// éè product bytes\r\n')
        write(app / 'lib/presentation/screens/portal.dart', 'class Portal {}\n')
        write(app / 'lib/main.dart', f'// product entry {SECRET}\n')
        write(app / 'lib/firebase_options.dart', f'// {SECRET}\n')
        write(app / 'config/local.json', f'{{"k": "{SECRET}"}}')
        write(app / 'config/prod.json', f'{{"k": "{SECRET}"}}')
        write(app / 'config/local.json.example', '{"k": "${K}"}')
        write(app / 'shorebird.yaml', f'app_id: {SECRET}\n')
        write(app / '.env', f'KEY={SECRET}\n')
        write(app / 'assets/login/ko_1.png', b'\x89PNG-login')
        write(app / 'assets/login/nested/skip.png', b'nested')
        write(app / 'assets/splash.webp', b'RIFF-splash')
        write(app / 'android/settings.gradle', textwrap.dedent('''\
            plugins {
                id "com.android.application" version '8.9.1' apply false
                id "org.jetbrains.kotlin.android" version "2.4.21" apply false
            }
            '''))
        write(app / 'android/gradle/wrapper/gradle-wrapper.properties',
              'distributionUrl=https\\://services.gradle.org/distributions/gradle-8.14.1-all.zip\n')
        write(app / 'android/build.gradle',
              '// AGP 8+ namespace compat\nsubprojects { }\n\nbuildscript {\n}\n')
        write(app / 'android/app/google-services.json', f'{{"k": "{SECRET}"}}')
        write(app / 'android/key.properties', f'storePassword={SECRET}\n')
        write(root / 'picnic_lib/pubspec.yaml', 'name: picnic_lib\n')
        write(root / 'picnic_lib/lib/picnic_lib.dart', '// lib\n')

    def run_main(self, flutter_mode='pass', manifest='good', apkanalyzer_mode='ok',
                 extra_args=(), after_drive=None, install_tools=True):
        bin_dir = self.tmp / 'bin'
        bin_dir.mkdir(exist_ok=True)
        self.record = self.tmp / 'record.jsonl'
        template_dir = self.tmp / 'create-template'
        for name, text in CREATE_TEMPLATE.items():
            write(template_dir / name, text)
        values = {'python': sys.executable, 'record': str(self.record),
                  'template': str(template_dir), 'device': str(self.device),
                  'sdk': str(self.sdk), 'package': PACKAGE, 'product': PRODUCT_PACKAGE,
                  'manifest': MANIFESTS[manifest]}
        tools = [(bin_dir / 'flutter', STUB_FLUTTER, flutter_mode)]
        if install_tools:
            tools += [(self.sdk / 'platform-tools/adb', STUB_ADB, None),
                      (self.sdk / 'cmdline-tools/latest/bin/apkanalyzer', STUB_APKANALYZER,
                       apkanalyzer_mode)]
        for path, template, mode in tools:
            path.write_text(template.format(mode=mode, **values))
            path.chmod(0o755)
        clt = self.tmp / 'CommandLineTools'
        clt.mkdir(exist_ok=True)
        self.workspace = self.tmp / 'workspace'
        self.workspace.mkdir()
        environ = {'PATH': f'{bin_dir}:/usr/bin:/bin', 'HOME': str(self.tmp),
                   'QA_FAKE_SECRET': 'must-not-leak'}
        patches = [
            mock.patch.object(base, 'COMMAND_LINE_TOOLS', str(clt)),
            mock.patch.object(base.sys, 'platform', 'darwin'),
            mock.patch.object(runner.tempfile, 'mkdtemp', lambda prefix: str(self.workspace)),
        ]
        if after_drive is not None:
            real = base.run_bounded

            def run_then_raise(command, **kwargs):
                outcome = real(command, **kwargs)
                if command[:2] == ['flutter', 'drive']:
                    raise after_drive()
                return outcome

            patches.append(mock.patch.object(base, 'run_bounded', run_then_raise))
        stdout, stderr = io.StringIO(), io.StringIO()
        with contextlib.ExitStack() as stack:
            for patch in patches:
                stack.enter_context(patch)
            stack.enter_context(contextlib.redirect_stdout(stdout))
            stack.enter_context(contextlib.redirect_stderr(stderr))
            code = runner.main(['--device', SERIAL, '--source-root', str(self.source),
                                *extra_args], environ=environ)
        self.stdout = stdout.getvalue() + stderr.getvalue()
        self.result_text = (self.workspace / 'qa-result.json').read_text()
        self.result = json.loads(self.result_text)
        self.calls = ([json.loads(line) for line in self.record.read_text().splitlines()]
                      if self.record.exists() else [])
        return code

    def tool_calls(self, tool):
        return [call['argv'] for call in self.calls if call['tool'] == tool]

    def flutter_steps(self):
        return [argv[0] for argv in self.tool_calls('flutter')]

    def installed(self):
        return json.loads((self.device / 'installed.json').read_text())

    def device_mutations(self):
        """adb calls that change the device, plus drive (which installs)."""
        mutations = [argv for argv in self.tool_calls('adb')
                     if argv[2:3] == ['uninstall'] or argv[2:5] == ['shell', 'am', 'force-stop']]
        return mutations + [argv for argv in self.tool_calls('flutter') if argv[0] == 'drive']

    def assert_scoped_to_user_0_and_this_package(self):
        for argv in self.tool_calls('adb'):
            self.assertEqual(argv[:2], ['-s', SERIAL], argv)
            self.assertNotIn(PRODUCT_PACKAGE, ' '.join(argv))
            if argv[2:3] == ['uninstall'] or argv[2:5] == ['shell', 'am', 'force-stop'] or \
                    argv[2:6] == ['shell', 'pm', 'list', 'packages']:
                self.assertIn('--user', argv, argv)
                self.assertEqual(argv[argv.index('--user') + 1], '0', argv)
                self.assertEqual(argv[-1], PACKAGE, argv)

    def assert_no_device_mutation(self):
        self.assertEqual(self.device_mutations(), [])
        self.assertFalse(self.result['device_cleanup']['owned'])
        self.assertEqual(self.result['device_cleanup']['actions'], [])

    def workspace_files(self):
        skip = {'qa-logs', 'gradle-user-home'}
        return [path for path in self.workspace.rglob('*')
                if path.is_file() and not skip.intersection(path.relative_to(self.workspace).parts)]


class PassAndIsolationTest(FullAppRunnerCase):
    def test_a_pass_drives_the_inspected_artifact_for_user_0_and_removes_only_its_package(self):
        code = self.run_main()

        self.assertEqual(code, 0, self.stdout)
        self.assertEqual(self.result['status'], 'passed')
        self.assertEqual(self.flutter_steps(), ['config', 'create', 'pub', 'build', 'drive'])
        _, create, _, build, drive = self.tool_calls('flutter')
        self.assertEqual(create[:7], ['create', '--platforms=android', '--project-name',
                                      'picnic_app', '--org', 'io.picnic.qa.full', '--no-pub'])
        self.assertEqual(build[:3], ['build', 'apk', '--debug'])
        self.assertIn('integration_test/full_app_retry_test.dart', build)
        for define in DEFINES:
            self.assertIn(define, build)
        artifact = self.workspace / 'qa-artifact/full-app-retry-qa.apk'
        self.assertIn(f'--use-application-binary={artifact}', drive)
        self.assertEqual(drive[drive.index('--device-user') + 1], '0')
        self.assertEqual(drive[drive.index('--driver') + 1], 'test_driver/full_app_retry_driver.dart')
        self.assertEqual(drive[drive.index('-d') + 1], SERIAL)
        self.assertIn('--no-pub', drive)
        self.assertEqual(sha(artifact), self.result['artifact']['sha256'])
        for call in self.calls:
            if call['tool'] == 'flutter':
                self.assertNotIn('QA_FAKE_SECRET', call['keys'])
        self.assertEqual(self.result['package'], PACKAGE)
        self.assertEqual(self.result['checkpoints'], EXPECTED_CHECKPOINTS)
        self.assertEqual(self.result['loopback_unexpected'], ['POST /rest/v1/x'])
        self.assertEqual(self.result['user_scope']['user'], 0)
        cleanup = self.result['device_cleanup']
        self.assertTrue(cleanup['owned'])
        self.assertTrue(cleanup['verified'])
        self.assertEqual(cleanup['package_after'], 'absent')
        self.assertEqual(self.installed(), [])
        self.assert_scoped_to_user_0_and_this_package()
        self.assertEqual(self.result['package_preflight'], 'absent')
        self.assertEqual(self.result['package_before_install'], 'absent')

    def test_the_serial_and_raw_device_output_stay_out_of_the_result(self):
        self.run_main()

        self.assertNotIn(SERIAL, self.result_text)
        self.assertNotIn(SERIAL, self.stdout)
        self.assertTrue((self.workspace / 'qa-logs').is_dir(), 'raw logs stay private')

    def test_product_lib_comes_from_the_source_root_byte_for_byte_and_the_harness_from_here(self):
        self.run_main()

        source_lib = self.source / 'picnic_app/lib'
        for rel in ('app.dart', 'presentation/screens/portal.dart'):
            self.assertEqual((self.workspace / 'lib' / rel).read_bytes(),
                             (source_lib / rel).read_bytes())
        self.assertFalse((self.workspace / 'lib/main.dart').exists(),
                         'neither product nor generated main.dart')
        self.assertFalse((self.workspace / 'lib/firebase_options.dart').exists())
        self.assertFalse((self.workspace / 'test').exists())
        harness = runner.ROOT / 'picnic_app/test_support'
        self.assertEqual((self.workspace / 'integration_test/full_app_retry_test.dart').read_bytes(),
                         (harness / 'full_app_retry_android_qa.dart').read_bytes())
        self.assertEqual((self.workspace / 'test_driver/full_app_retry_driver.dart').read_bytes(),
                         (harness / 'full_app_retry_driver.dart').read_bytes())
        for name in ('loopback_backend.dart', 'rejecting_firebase_platform.dart'):
            self.assertEqual(
                (self.workspace / 'integration_test/full_app_retry' / name).read_bytes(),
                (harness / 'full_app_retry' / name).read_bytes())
        source = self.result['source']
        self.assertEqual(source['root'], str(self.source))
        self.assertEqual(source['product_lib']['files']['app.dart'], sha(source_lib / 'app.dart'))
        self.assertEqual(source['pubspec_sha256'], sha(self.source / 'picnic_app/pubspec.yaml'))
        self.assertEqual(source['lock_sha256'], sha(self.source / 'picnic_app/pubspec.lock'))
        self.assertIsNone(source['revision_label'])
        self.assertFalse((self.source / '.git').exists(), 'no .git is required')
        self.assertEqual(self.result['harness']['root'], str(runner.ROOT))
        self.assertEqual(self.result['harness']['files']['full_app_retry_android_qa.dart'],
                         sha(harness / 'full_app_retry_android_qa.dart'))
        self.assertIn('overrides', self.result)

    def test_a_root_given_revision_label_is_recorded_without_using_git(self):
        self.run_main(extra_args=['--source-revision', 'd544f015b-snapshot'])

        self.assertEqual(self.result['source']['revision_label'], 'd544f015b-snapshot')

    def test_no_sensitive_input_reaches_the_workspace(self):
        self.run_main()

        for path in self.workspace_files():
            self.assertNotIn(SECRET.encode(), path.read_bytes(), str(path))
        names = {path.name for path in self.workspace_files()}
        for forbidden in ('local.json', 'prod.json', 'shorebird.yaml', '.env',
                          'google-services.json', 'key.properties', 'firebase_options.dart'):
            self.assertNotIn(forbidden, names)
        self.assertFalse((self.workspace / 'config').exists())
        copied = sorted(str(path.relative_to(self.workspace / 'assets'))
                        for path in (self.workspace / 'assets').rglob('*') if path.is_file())
        self.assertEqual(copied, ['login/ko_1.png', 'splash.webp'],
                         'declared directories are copied without subdirectories')
        self.assertEqual(self.result['assets']['excluded'], ['config/', 'shorebird.yaml'])
        artifacts = sorted(path.name for path in (self.workspace / 'qa-artifact').iterdir())
        self.assertEqual(artifacts, ['full-app-retry-qa.apk'], 'only the one APK is kept')

    def test_the_generated_pubspec_pins_the_package_root_and_product_dependencies(self):
        self.run_main()

        pubspec = (self.workspace / 'pubspec.yaml').read_text()
        self.assertIn('name: picnic_app\n', pubspec)
        self.assertIn('version: 0.0.1+1\n', pubspec)
        picnic_lib = json.dumps(str(self.source / 'picnic_lib'))
        self.assertIn(f'    picnic_lib:\n        path: {picnic_lib}\n', pubspec)
        self.assertIn('    flutter_phoenix: ^1.1.1\n', pubspec)
        self.assertIn('    firebase_messaging: ^17.0.1\n', pubspec)
        self.assertIn('    firebase_core_platform_interface: 8.1.1\n', pubspec)
        self.assertIn('    integration_test:\n        sdk: flutter\n', pubspec)
        self.assertIn('    flutter_driver:\n        sdk: flutter\n', pubspec)
        self.assertNotIn('build_runner', pubspec)
        self.assertNotIn('config/', pubspec)
        self.assertNotIn('shorebird.yaml', pubspec)
        self.assertNotIn('generate: true', pubspec)
        self.assertIn('        - assets/login/\n        - assets/splash.webp\n', pubspec)
        app = (self.workspace / 'android/app/build.gradle.kts').read_text()
        self.assertIn(f'applicationId = "{PACKAGE}"', app)
        self.assertNotIn(PRODUCT_PACKAGE, app)
        manifest = (self.workspace / 'android/app/src/main/AndroidManifest.xml').read_text()
        self.assertIn('firebase_messaging_auto_init_enabled" android:value="false"', manifest)
        self.assertIn('ca-app-pub-3940256099942544~3347511713', manifest)
        settings = (self.workspace / 'android/settings.gradle.kts').read_text()
        self.assertIn('version "8.9.1"', settings)
        self.assertIn('version "2.4.21"', settings)
        self.assertEqual(self.result['lock']['drift'], {})


class ArtifactBoundaryTest(FullAppRunnerCase):
    """F1: only the inspected final APK may reach the installer."""

    def assert_rejected_before_device_mutation(self, code, message):
        self.assertEqual(code, 1)
        self.assertIn(message, self.result['error'])
        self.assert_no_device_mutation()
        self.assertEqual(self.installed(), [])
        self.assertNotIn('drive', self.flutter_steps())

    def test_a_wrong_package_in_the_merged_manifest_is_rejected_before_install(self):
        self.assert_rejected_before_device_mutation(
            self.run_main(manifest='wrong-package'), 'package')

    def test_messaging_auto_init_enabled_in_the_merged_manifest_is_rejected(self):
        self.assert_rejected_before_device_mutation(
            self.run_main(manifest='auto-init-true'), 'firebase_messaging_auto_init_enabled')

    def test_a_missing_collection_switch_is_rejected(self):
        self.assert_rejected_before_device_mutation(
            self.run_main(manifest='missing-meta'), 'firebase_analytics_collection_enabled')

    def test_a_duplicated_switch_is_ambiguous_and_rejected(self):
        self.assert_rejected_before_device_mutation(
            self.run_main(manifest='duplicate-meta'), 'firebase_messaging_auto_init_enabled')

    def test_a_manifest_that_does_not_parse_is_not_treated_as_safe(self):
        self.assert_rejected_before_device_mutation(
            self.run_main(manifest='malformed'), 'manifest')

    def test_a_failed_manifest_tool_is_a_failure_not_a_skip(self):
        self.assert_rejected_before_device_mutation(
            self.run_main(apkanalyzer_mode='fail'), 'apkanalyzer')

    def test_an_artifact_replaced_after_inspection_never_reaches_the_installer(self):
        self.assert_rejected_before_device_mutation(
            self.run_main(apkanalyzer_mode='tamper'), 'inspected')

    def test_a_config_file_in_the_built_apk_stops_the_run_before_install(self):
        self.assert_rejected_before_device_mutation(
            self.run_main(flutter_mode='leak'), 'assets/flutter_assets/config/prod.json')

    def test_a_missing_manifest_tool_fails_before_any_build(self):
        self.sdk.joinpath('cmdline-tools/latest/bin').rmdir()
        (self.sdk / 'platform-tools/adb').write_text(
            STUB_ADB.format(python=sys.executable, record=str(self.tmp / 'record.jsonl'),
                            device=str(self.device), package=PACKAGE, product=PRODUCT_PACKAGE))
        (self.sdk / 'platform-tools/adb').chmod(0o755)
        code = self.run_main(install_tools=False)

        self.assertEqual(code, 1)
        self.assertIn('apkanalyzer', self.result['error'])
        self.assertEqual(self.flutter_steps(), ['config'])
        self.assert_no_device_mutation()

    def test_sdk_evidence_that_allows_the_drive_fallback_build_fails_preflight(self):
        # android_device.dart startApp builds again when licenses exist and
        # no platform/build-tools pair gives a latest SDK version.
        (self.sdk / 'platforms/android-35').rmdir()
        code = self.run_main()

        self.assertEqual(code, 1)
        self.assertIn('latest', self.result['error'])
        self.assertEqual(self.flutter_steps(), ['config'])
        self.assert_no_device_mutation()

    def test_missing_build_tools_also_leave_no_latest_version(self):
        (self.sdk / 'build-tools/35.0.0').rmdir()
        code = self.run_main()

        self.assertEqual(code, 1)
        self.assertIn('latest', self.result['error'])
        self.assertEqual(self.flutter_steps(), ['config'])

    def test_unreadable_flutter_sdk_configuration_fails_closed(self):
        for mode in ('config-malformed', 'config-no-sdk'):
            with self.subTest(mode=mode):
                self.setUp()
                code = self.run_main(flutter_mode=mode)
                self.assertEqual(code, 1)
                self.assertIn('android-sdk', self.result['error'])
                self.assertEqual(self.flutter_steps(), ['config'])
                self.assert_no_device_mutation()

    def test_a_rebuild_during_drive_is_reported_as_a_failure(self):
        code = self.run_main(flutter_mode='rebuild')

        self.assertEqual(code, 1)
        self.assertIn('rebuilt', self.result['error'])
        self.assertTrue(self.result['device_cleanup']['verified'])

    def test_drive_without_a_driver_response_is_not_a_pass(self):
        code = self.run_main(flutter_mode='no-response')

        self.assertEqual(code, 1)
        self.assertIn('response', self.result['error'])
        self.assertTrue(self.result['device_cleanup']['verified'])

    def test_a_driver_connection_error_is_a_failure(self):
        code = self.run_main(flutter_mode='connection-error')

        self.assertEqual(code, 1)
        self.assertIn('device-drive', self.result['error'])
        self.assertIsNone(self.result['driver_response'])
        self.assertTrue(self.result['device_cleanup']['verified'])
        self.assertEqual(self.installed(), [])

    def test_a_missing_checkpoint_is_not_a_pass(self):
        code = self.run_main(flutter_mode='missing-checkpoint')

        self.assertEqual(code, 1)
        self.assertIn('checkpoints', self.result['error'])
        self.assertTrue(self.result['device_cleanup']['verified'])

    def test_a_failed_device_test_keeps_its_structured_report_and_removes_the_package(self):
        code = self.run_main(flutter_mode='fail')

        self.assertEqual(code, 1)
        self.assertEqual(self.result['status'], 'failed')
        self.assertIn('device-drive', self.result['error'])
        self.assertFalse(self.result['driver_response']['bodyCompleted'])
        self.assertTrue(self.result['device_cleanup']['verified'])
        self.assertEqual(self.installed(), [])
        self.assert_scoped_to_user_0_and_this_package()


class UserScopeTest(FullAppRunnerCase):
    """F2: only a device whose complete user list is exactly user 0."""

    def test_a_second_user_with_its_own_qa_app_is_refused_and_left_untouched(self):
        self.device_config({'users': [TWO_USERS]}, installed=['10'])

        code = self.run_main()

        self.assertEqual(code, 1)
        self.assertIn('user', self.result['error'])
        self.assertEqual(self.flutter_steps(), ['config'])
        self.assert_no_device_mutation()
        self.assertEqual(self.installed(), ['10'])
        self.assertEqual(self.tool_calls('adb')[-1][2:], ['shell', 'am', 'get-current-user'])

    def test_a_current_user_other_than_0_is_refused(self):
        self.device_config({'current': [{'code': 0, 'out': '10\n', 'err': ''}]})

        code = self.run_main()

        self.assertEqual(code, 1)
        self.assertIn('current user', self.result['error'])
        self.assert_no_device_mutation()

    def test_malformed_or_failed_user_lists_are_unknown(self):
        cases = {
            'garbled record': {'code': 0, 'out': 'Users:\n\tUserInfo{0:Owner:c13\n', 'err': ''},
            'no header': {'code': 0, 'out': '\tUserInfo{0:Owner:c13} running\n', 'err': ''},
            'empty list': {'code': 0, 'out': 'Users:\n', 'err': ''},
            'failed query': {'code': 255, 'out': '', 'err': 'error: closed\n'},
            'stderr noise': {'code': 0, 'out': ONE_USER['out'], 'err': 'Security exception\n'},
        }
        for label, users in cases.items():
            with self.subTest(label):
                self.setUp()
                self.device_config({'users': [users]})
                code = self.run_main()
                self.assertEqual(code, 1)
                self.assertIn('user scope', self.result['error'])
                self.assertEqual(self.flutter_steps(), ['config'])
                self.assert_no_device_mutation()

    def test_a_user_added_before_the_install_boundary_stops_the_run_unowned(self):
        self.device_config({'users': [ONE_USER, TWO_USERS]})

        code = self.run_main()

        self.assertEqual(code, 1)
        self.assertIn('user', self.result['error'])
        self.assertEqual(self.flutter_steps(), ['config', 'create', 'pub', 'build'])
        self.assert_no_device_mutation()

    def test_cleanup_never_mutates_when_the_user_scope_became_unknown(self):
        failed = {'code': 255, 'out': '', 'err': 'error: closed\n'}
        self.device_config({'users': [ONE_USER, ONE_USER, failed]})

        code = self.run_main(flutter_mode='keep-installed')

        self.assertEqual(code, 1)
        cleanup = self.result['device_cleanup']
        self.assertTrue(cleanup['owned'])
        self.assertFalse(cleanup['verified'])
        self.assertEqual(cleanup['actions'], [])
        self.assertEqual(cleanup['user_scope']['state'], 'unknown')
        self.assertEqual(self.installed(), ['0'], 'left for manual review, not guessed')
        uninstalls = [argv for argv in self.tool_calls('adb') if argv[2:3] == ['uninstall']]
        self.assertEqual(uninstalls, [])


class PackageQueryTest(FullAppRunnerCase):
    """F3: every package record must parse completely."""

    MALFORMED = {
        'empty identifier': {'code': 0, 'out': 'package:\n', 'err': ''},
        'identifier with spaces': {'code': 0, 'out': 'package:garbage with spaces\n', 'err': ''},
        'not a record': {'code': 0, 'out': 'Exception occurred while executing list:\n', 'err': ''},
        'failed query': {'code': 255, 'out': '', 'err': 'error: closed\n'},
    }

    def test_malformed_records_at_preflight_are_unknown(self):
        for label, answer in self.MALFORMED.items():
            with self.subTest(label):
                self.setUp()
                self.device_config({'pm_override': {'1': answer}})
                code = self.run_main()
                self.assertEqual(code, 1)
                self.assertEqual(self.result['package_preflight'], 'unknown')
                self.assertEqual(self.flutter_steps(), ['config'])
                self.assert_no_device_mutation()

    def test_malformed_records_at_the_install_gate_are_unknown(self):
        for label, answer in self.MALFORMED.items():
            with self.subTest(label):
                self.setUp()
                self.device_config({'pm_override': {'2': answer}})
                code = self.run_main()
                self.assertEqual(code, 1)
                self.assertEqual(self.result['package_before_install'], 'unknown')
                self.assertEqual(self.flutter_steps(), ['config', 'create', 'pub', 'build'])
                self.assert_no_device_mutation()

    def test_a_malformed_record_after_cleanup_is_not_verified(self):
        self.device_config({'pm_override': {'3': self.MALFORMED['identifier with spaces']}})

        code = self.run_main()

        self.assertEqual(code, 1)
        self.assertEqual(self.result['device_cleanup']['package_after'], 'unknown')
        self.assertFalse(self.result['device_cleanup']['verified'])

    def test_a_preexisting_qa_package_is_refused_and_left_untouched(self):
        self.device_config({}, installed=['0'])

        code = self.run_main()

        self.assertEqual(code, 1)
        self.assertIn('already installed', self.result['error'])
        self.assertEqual(self.flutter_steps(), ['config'])
        self.assertEqual(self.installed(), ['0'])
        self.assert_no_device_mutation()

    def test_prefix_and_suffix_packages_do_not_count_as_present(self):
        # The stub always lists io.picnic.qa.full.picnic and ...picnic_app.other.
        code = self.run_main()

        self.assertEqual(code, 0, self.stdout)
        self.assertEqual(self.result['package_preflight'], 'absent')


class GateAndCleanupTest(FullAppRunnerCase):
    def test_lock_drift_from_the_product_lock_fails_before_the_build(self):
        code = self.run_main(flutter_mode='drift')

        self.assertEqual(code, 1)
        self.assertIn('firebase_core', self.result['error'])
        self.assertEqual(self.flutter_steps(), ['config', 'create', 'pub'])

    def test_a_package_outside_the_product_lock_fails_before_the_build(self):
        code = self.run_main(flutter_mode='extra')

        self.assertEqual(code, 1)
        self.assertIn('qa_extra', self.result['error'])
        self.assertEqual(self.flutter_steps(), ['config', 'create', 'pub'])

    def test_a_sensitive_file_inside_product_lib_fails_before_any_device_step(self):
        write(self.source / 'picnic_app/lib/google-services.json', SECRET)

        code = self.run_main()

        self.assertEqual(code, 1)
        self.assertIn('google-services.json', self.result['error'])
        self.assert_no_device_mutation()

    def test_an_interrupted_run_removes_the_owned_package_before_reporting(self):
        code = self.run_main(flutter_mode='keep-installed', after_drive=KeyboardInterrupt)

        self.assertEqual(code, 130)
        self.assertEqual(self.result['status'], 'interrupted')
        self.assertTrue(self.result['device_cleanup']['verified'])
        self.assertEqual(self.installed(), [])

    def test_a_sigterm_interruption_is_cleaned_up_the_same_way(self):
        code = self.run_main(flutter_mode='keep-installed', after_drive=base.Interrupted)

        self.assertEqual(code, 130)
        self.assertEqual(self.result['status'], 'interrupted')
        self.assertEqual(self.installed(), [])

    def test_a_failed_uninstall_is_a_failure_not_a_verified_cleanup(self):
        self.device_config({'uninstall_fails': True})

        code = self.run_main(flutter_mode='keep-installed')

        self.assertEqual(code, 1)
        self.assertEqual(self.result['status'], 'failed')
        self.assertFalse(self.result['device_cleanup']['verified'])
        self.assertEqual(self.result['device_cleanup']['package_after'], 'present')
        self.assertIn('device cleanup is not verified', self.result['error'])

    def test_a_remaining_app_process_is_a_failure(self):
        self.device_config({'pid_remains': True})

        code = self.run_main()

        self.assertEqual(code, 1)
        self.assertFalse(self.result['device_cleanup']['verified'])
        self.assertEqual(self.result['device_cleanup']['pids_after'], 1)


class SdkSettingTest(unittest.TestCase):
    """The android-sdk setting must name the same SDK for the runner and Flutter.

    The runner inspects paths from its own working directory, but Flutter and
    apkanalyzer run in the QA workspace. A relative setting can therefore name
    two different directories, so it must be refused before any inspection.
    """

    def setUp(self):
        self._dir = tempfile.TemporaryDirectory()
        self.tmp = Path(self._dir.name).resolve()
        self.addCleanup(self._dir.cleanup)
        # Runner's cwd holds a complete SDK; the workspace holds none.
        self.parent = self.tmp / 'parent-cwd'
        self.workspace = self.tmp / 'qa-workspace'
        self.workspace.mkdir(parents=True)
        self.sdk = self.parent / 'relative-sdk'
        for directory in ('licenses', 'platform-tools', 'platforms/android-35',
                          'build-tools/35.0.0', 'cmdline-tools/latest/bin'):
            (self.sdk / directory).mkdir(parents=True)
        for tool in ('platform-tools/adb', 'cmdline-tools/latest/bin/apkanalyzer'):
            (self.sdk / tool).write_text('#!/bin/sh\nexit 99\n')
            (self.sdk / tool).chmod(0o755)
        previous = Path.cwd()
        os.chdir(self.parent)
        self.addCleanup(os.chdir, previous)

    def resolve(self, configured):
        qa = mock.Mock(workspace=self.workspace, result={})
        forbidden = AssertionError('no process may start after the config response')
        inspected = []
        real_valid, real_latest = runner._valid_sdk_directory, runner.sdk_latest_version

        def spy_valid(path):
            inspected.append(('valid', str(path)))
            return real_valid(path)

        def spy_latest(path):
            inspected.append(('latest', str(path)))
            return real_latest(path)

        with mock.patch.object(runner, 'run_separated',
                               return_value=json.dumps({'android-sdk': configured})), \
                mock.patch.object(runner, '_valid_sdk_directory', spy_valid), \
                mock.patch.object(runner, 'sdk_latest_version', spy_latest), \
                mock.patch.object(runner.subprocess, 'Popen', side_effect=forbidden), \
                mock.patch.object(runner.subprocess, 'run', side_effect=forbidden):
            try:
                return runner.resolve_android_sdk(qa), inspected
            except base.RunnerError as error:
                return error, inspected

    def test_a_relative_sdk_setting_is_refused_before_any_sdk_inspection(self):
        self.assertFalse((self.workspace / 'relative-sdk').exists(),
                         'Flutter, running in the workspace, would not find this SDK')

        outcome, inspected = self.resolve('relative-sdk')

        self.assertIsInstance(outcome, base.RunnerError,
                              f'a relative android-sdk was accepted as {outcome}')
        self.assertIn('relative', str(outcome))
        self.assertIn('relative-sdk', str(outcome))
        self.assertEqual(inspected, [], 'no SDK path may be inspected for a relative setting')

    def test_an_absolute_sdk_setting_and_its_sdk_fallback_still_resolve(self):
        outcome, _ = self.resolve(str(self.sdk))
        self.assertEqual(outcome[0], self.sdk)
        self.assertEqual(outcome[1], self.sdk / 'platform-tools/adb')

        nested = self.tmp / 'android-home'
        nested.mkdir()
        (self.sdk).rename(nested / 'sdk')
        outcome, _ = self.resolve(str(nested))
        self.assertEqual(outcome[0], nested / 'sdk')


class PureRuleTest(unittest.TestCase):
    def test_forbidden_artifact_names(self):
        for name in ('assets/flutter_assets/config/local.json',
                     'assets/flutter_assets/config/anything.txt',
                     'assets/flutter_assets/shorebird.yaml',
                     'assets/flutter_assets/prod.json',
                     'res/raw/google-services.json',
                     'assets/key.properties',
                     'assets/flutter_assets/.env'):
            self.assertTrue(runner.is_forbidden_artifact(name), name)
        for name in ('assets/flutter_assets/assets/splash.webp',
                     'assets/flutter_assets/packages/picnic_lib/assets/splash.png',
                     'classes.dex', 'META-INF/CERT.RSA'):
            self.assertFalse(runner.is_forbidden_artifact(name), name)

    def test_inspect_apk_rejects_an_empty_or_unreadable_artifact(self):
        with tempfile.TemporaryDirectory() as tmp:
            apk = Path(tmp) / 'app-debug.apk'
            with zipfile.ZipFile(apk, 'w') as z:
                z.writestr('classes.dex', 'dex')
            with self.assertRaisesRegex(base.RunnerError, 'flutter_assets'):
                runner.inspect_apk(apk)
            apk.write_bytes(b'not a zip')
            with self.assertRaisesRegex(base.RunnerError, 'cannot read'):
                runner.inspect_apk(apk)

    def test_package_records_must_be_canonical_identifiers(self):
        parse = runner.parse_package_list
        self.assertEqual(parse(0, f'package:{PACKAGE}\npackage:{PACKAGE}.other\n', ''), 'present')
        self.assertEqual(parse(0, f'package:{PACKAGE}.other\n', ''), 'absent')
        self.assertEqual(parse(0, '', ''), 'absent')
        for out in ('package:\n', 'package:garbage with spaces\n', 'package:1bad.name\n',
                    f'package:{PACKAGE}\njunk\n', f'package: {PACKAGE}\n'):
            self.assertEqual(parse(0, out, ''), 'unknown', out)
        self.assertEqual(parse(1, '', ''), 'unknown')
        self.assertEqual(parse(0, f'package:{PACKAGE}\n', 'warning\n'), 'unknown')

    def test_sdk_latest_version_follows_the_flutter_tool_rule(self):
        with tempfile.TemporaryDirectory() as tmp:
            sdk = Path(tmp)
            (sdk / 'licenses').mkdir()
            self.assertIsNone(runner.sdk_latest_version(sdk))
            (sdk / 'platforms/android-UpsideDownCake').mkdir(parents=True)
            (sdk / 'build-tools/not-a-version').mkdir(parents=True)
            self.assertIsNone(runner.sdk_latest_version(sdk), 'no parseable pair')
            (sdk / 'platforms/android-UpsideDownCake/build.prop').write_text(
                'ro.build.version.sdk=34\n')
            self.assertIsNone(runner.sdk_latest_version(sdk), 'still no build-tools')
            (sdk / 'build-tools/36.0.0').mkdir()
            self.assertEqual(runner.sdk_latest_version(sdk), {'sdk_level': 34,
                                                              'build_tools': '36.0.0'})
            (sdk / 'platforms/android-35').mkdir()
            (sdk / 'build-tools/35.0.0').mkdir()
            self.assertEqual(runner.sdk_latest_version(sdk), {'sdk_level': 35,
                                                              'build_tools': '35.0.0'})


if __name__ == '__main__':
    unittest.main()

"""Run the full App retry chain QA on one Android device.

Builds a disposable Flutter app, io.picnic.qa.full.picnic_app, in a new
temporary workspace and runs picnic_app/test_support/full_app_retry_android_qa
.dart on the device given by --device. The test runs the actual chain
MainInitializer.initializeApp -> App failure UI -> retry ->
MainInitializer.retrySdkInitialization -> AppInitializer.initializeApp ->
PushTokenService.initialize with a controlled push coordinator. The
registered token is a controlled test value, not proof of FCM registration.

Sources:
- The test harness always comes from this checkout (ROOT).
- The product picnic_app lib, its pubspec and lock, picnic_lib (by path) and
  the product Android version pins come from --source-root (default ROOT).
  A root-created snapshot of an older product revision can be given there;
  it needs no .git. The runner records file hashes and an optional
  --source-revision label; it never creates a checkout.

Isolation:
- Copied: product lib except main.dart and firebase_options.dart, and the
  declared app assets except config/ and shorebird.yaml (directory entries
  without subdirectories). Never copied or opened: config/*.json,
  shorebird.yaml, google-services, env, key, keystore or signing files. A
  sensitive file name inside the copied set fails the run.
- The generated Gradle project is used, with the same compatibility edits as
  run_firebase_device_android.py: product Kotlin/AGP/Gradle pins, Kotlin JVM
  target migration, desugaring, the Tapjoy SDK, extra repositories, the
  namespace compatibility block, Firebase auto-init/collection disabled and
  the AdMob sample application ID. No product signing script is used.
- The product lock is copied before `pub get`; every resolved package must
  be in it with the same version.
- Process groups, the child environment and owned Gradle daemon cleanup are
  the reviewed helpers of run_firebase_device_android.py (imported, not
  changed).

Artifact boundary (installed flutter_tools behavior this relies on):
- `flutter build apk --debug` builds the app once. Only its APK is copied to
  qa-artifact/full-app-retry-qa.apk (read-only). That exact file is
  inspected: no configuration or credential entry, and the merged manifest
  printed by the SDK's `apkanalyzer manifest print` must parse as XML with
  package io.picnic.qa.full.picnic_app and each Firebase/AdMob switch exactly
  once with the expected value. Its SHA-256 must not change during or after
  inspection, and is checked again right before the installer.
- The installer is `flutter drive --use-application-binary=<that file>
  --device-user 0`. drive_service.dart passes the file to the package factory
  and calls AndroidDevice.startApp with prebuiltApplication=true and the
  user identifier; startApp then force-stops, `adb install -t -r --user 0`
  and starts it, and drive's stop uninstalls with `--user 0`.
- AndroidDevice.startApp still builds when the SDK has a licenses directory
  and no latest platform/build-tools pair. The runner reads the SDK that
  Flutter uses (`flutter config --machine`, key android-sdk, with the same
  "<dir>/sdk" fallback) and fails before any work unless that SDK has a
  latest version by the android_sdk.dart rule. As a secondary check, the
  project build output must be unchanged after drive.
- The test result comes from the driver (integrationDriver exits 0 only when
  every test passed) and from the structured reportData it writes to
  qa-driver/response.json; console lines are diagnostics only.

Device ownership:
- Every adb command names the selected serial. The complete user list
  (`pm list users`) must be exactly user 0 and `am get-current-user` must be
  0, before any work and again at the install boundary; any other, unknown
  or malformed scope is refused. Package queries, force-stop and uninstall
  name `--user 0`.
- The QA package is queried before any work and again right before the
  installer runs. Every package record must be a complete package name. A
  present package is refused and left untouched; a failed or malformed query
  is "unknown" and is refused too. Ownership is claimed only from proven
  absence immediately before the installer.
- On pass, failure or interruption, an owned package is force-stopped and
  uninstalled for user 0 after the user scope is validated again; then its
  absence and the absence of its process are verified. If the scope is not
  exactly user 0 at cleanup, nothing is changed and cleanup is unverified.
  Unknown or remaining state fails the run. No other package (including the
  product app) is ever named in an adb command.
- The serial stays out of qa-result.json and stdout; raw step logs stay in
  the workspace, which is kept for diagnostics.
"""
import argparse
import hashlib
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
from xml.etree import ElementTree
import zipfile

sys.path.insert(0, str(Path(__file__).resolve().parent))
import run_firebase_device_android as base  # noqa: E402

ROOT = base.ROOT
PROJECT_NAME = 'picnic_app'
ORG = 'io.picnic.qa.full'
PACKAGE = f'{ORG}.{PROJECT_NAME}'
PRODUCT_PACKAGE = base.PRODUCT_PACKAGE
QA_VERSION = '0.0.1+1'
HARNESS_DIR = ROOT / 'picnic_app/test_support'
HARNESS_TEST = 'full_app_retry_android_qa.dart'
HARNESS_SUPPORT = 'full_app_retry'
TEST_TARGET = 'integration_test/full_app_retry_test.dart'
DART_DEFINES = (
    '--dart-define=PANGLE_ENVIRONMENT=sandbox',
    '--dart-define=PAYMENT_ENVIRONMENT=sandbox',
)
HARNESS_DRIVER = 'full_app_retry_driver.dart'
DRIVER_TARGET = 'test_driver/full_app_retry_driver.dart'
DRIVER_RESPONSE = Path('qa-driver/response.json')
APK = Path('build/app/outputs/flutter-apk/app-debug.apk')
ARTIFACT = Path('qa-artifact/full-app-retry-qa.apk')
DEVICE_USER = 0
EXCLUDED_LIB_FILES = ('main.dart', 'firebase_options.dart')
EXCLUDED_ASSETS = ('config/', 'shorebird.yaml')
EXPECTED_CHECKPOINTS = ['A1', 'A2', 'A3', 'A4', 'A5', 'cleanup']
ADB_TIMEOUT_S = 60
TOOL_TIMEOUT_S = 300
ANDROID_NS = '{http://schemas.android.com/apk/res/android}'
# Application meta-data that the merged manifest must carry exactly once.
REQUIRED_META = {
    'firebase_messaging_auto_init_enabled': 'false',
    'firebase_analytics_collection_enabled': 'false',
    'firebase_analytics_collection_deactivated': 'true',
    'google_analytics_adid_collection_enabled': 'false',
    'com.google.android.gms.ads.APPLICATION_ID': 'ca-app-pub-3940256099942544~3347511713',
}
PACKAGE_RECORD = re.compile(r'package:([A-Za-z][A-Za-z0-9_]*(?:\.[A-Za-z][A-Za-z0-9_]*)+)')
USER_RECORD = re.compile(r'\s+UserInfo\{(\d+):[^{}:]*:[0-9A-Fa-f]+\}(?: running)?')
# android_sdk.dart: _numberedAndroidPlatformRe, _sdkVersionRe, Version.parse.
NUMBERED_PLATFORM = re.compile(r'^android-([0-9]+)$')
BUILD_PROP_SDK = re.compile(r'^ro.build.version.sdk=([0-9]+)$')
TOOL_VERSION = re.compile(r'^(\d+)(\.(\d+)(\.(\d+))?)?')
# File names that must never be copied into the workspace. (android/
# local.properties is not listed: flutter create writes SDK paths there.)
SENSITIVE_NAME = re.compile(
    r'(^|/)(google-services\.json|GoogleService-Info\.plist|shorebird\.yaml|'
    r'key\.properties|firebase_options\.dart|\.env[^/]*|'
    r'[^/]*\.(jks|keystore|p12|pem|mobileprovision))$', re.IGNORECASE)
# Entries that must never be in the built APK.
ARTIFACT_FORBIDDEN = re.compile(
    r'(^assets/flutter_assets/config/|'
    r'^assets/flutter_assets/(local|prod|dev)\.json$|'
    r'(^|/)(google-services\.json|GoogleService-Info\.plist|shorebird\.yaml|'
    r'key\.properties|firebase_options\.dart|\.env[^/]*|[^/]*\.(jks|keystore))$)',
    re.IGNORECASE)
OVERRIDES = [
    'config/local.json and config/prod.json asset reads answered with '
    'synthetic values; other assets forwarded',
    'first Firebase.initializeApp rejected before the native call; later '
    'calls forwarded to the native platform with demo options',
    'PushTokenService.debugUseCoordinatorFactory: real coordinator, controlled '
    'permission/token/registration/streams',
    'App(portalBuilder: ready marker) after App readiness; no Portal coverage',
    'Supabase, storage, CDN and Sentry DSN on an in-process loopback server',
    'manifest: Messaging auto-init and Analytics collection disabled, AdMob '
    'sample application ID',
    f'--dart-define {" ".join(define.split("=", 1)[1] for define in DART_DEFINES)}',
]


def sha256(path):
    digest = hashlib.sha256()
    with open(path, 'rb') as stream:
        for chunk in iter(lambda: stream.read(1 << 20), b''):
            digest.update(chunk)
    return digest.hexdigest()


def tree_digest(files):
    """One SHA-256 over sorted 'relative path NUL file hash' lines."""
    digest = hashlib.sha256()
    for rel in sorted(files):
        digest.update(f'{rel}\0{files[rel]}\n'.encode())
    return digest.hexdigest()


def hash_tree(root):
    root = Path(root)
    files = {str(path.relative_to(root)): sha256(path)
             for path in sorted(root.rglob('*')) if path.is_file()}
    return {'count': len(files), 'sha256': tree_digest(files)}


def is_forbidden_artifact(name):
    return bool(ARTIFACT_FORBIDDEN.search(name))


def inspect_apk(apk):
    """Lists the APK and fails if a configuration or credential file is in it."""
    try:
        with zipfile.ZipFile(apk) as archive:
            names = archive.namelist()
    except (OSError, zipfile.BadZipFile) as error:
        raise base.RunnerError(f'cannot read the built APK {apk}: {error}') from None
    if not any(name.startswith('assets/flutter_assets/') for name in names):
        raise base.RunnerError('the built APK has no flutter_assets; it cannot be verified')
    leaked = sorted(name for name in names if is_forbidden_artifact(name))
    if leaked:
        raise base.RunnerError(f'the built APK contains forbidden files: {leaked[:10]}')
    return {'sha256': sha256(apk), 'entries': len(names)}


def run_separated(qa, name, command, timeout=TOOL_TIMEOUT_S):
    """Runs a host tool in its own process group; stdout and stderr stay apart.

    Returns stdout. A non-zero exit, a timeout or a process left in the group
    fails the run. stderr is kept only in qa-logs/<name>.stderr.log.
    """
    out_path = qa.logs / f'{name}.stdout.log'
    err_path = qa.logs / f'{name}.stderr.log'
    step = {'name': name, 'command': [qa.redact(part) for part in command]}
    qa.result['steps'].append(step)
    try:
        with out_path.open('w') as out, err_path.open('w') as err:
            process = subprocess.Popen(command, cwd=qa.workspace, env=qa.env, stdout=out,
                                       stderr=err, start_new_session=True)
            try:
                step['exit_code'] = process.wait(timeout=timeout)
            except subprocess.TimeoutExpired:
                step['timed_out_after_s'] = timeout
                step['exit_code'] = None
            finally:
                step['cleanup'] = base.stop_process_group(process)
    except OSError as error:
        raise base.RunnerError(f'{name} could not start: {error}') from None
    if step['cleanup']['remaining']:
        raise base.RunnerError(f'step {name} left processes that did not stop')
    if step['exit_code'] != 0:
        raise base.RunnerError(f'step {name} did not succeed (see {err_path})')
    return out_path.read_text(errors='replace')


def _tool_version(name):
    match = TOOL_VERSION.match(name)
    if match is None:
        return None
    return tuple(int(match.group(index) or 0) for index in (1, 3, 5))


def sdk_latest_version(sdk):
    """AndroidSdk.latestVersion of android_sdk.dart reinitialize(), or None.

    Each platform directory (not a link) gives a level from `android-<N>` or
    from build.prop; it pairs with the highest build-tools version of the
    same major, else the highest of all. The highest level wins.
    """
    sdk = Path(sdk)
    tools = []
    if (sdk / 'build-tools').is_dir():
        tools = [version for version in (_tool_version(entry.name)
                                         for entry in (sdk / 'build-tools').iterdir())
                 if version is not None]
    versions = []
    platforms = sdk / 'platforms'
    if platforms.is_dir():
        for directory in platforms.iterdir():
            if directory.is_symlink() or not directory.is_dir():
                continue
            numbered = NUMBERED_PLATFORM.match(directory.name)
            if numbered:
                level = int(numbered.group(1))
            else:
                try:
                    lines = (directory / 'build.prop').read_text().splitlines()
                except OSError:
                    continue
                levels = [int(match.group(1)) for match in map(BUILD_PROP_SDK.match, lines)
                          if match]
                if not levels:
                    continue
                level = levels[0]
            same_major = [version for version in tools if version[0] == level]
            chosen = max(same_major or tools, default=None)
            if chosen is not None:
                versions.append((level, chosen))
    if not versions:
        return None
    level, chosen = max(versions, key=lambda pair: pair[0])
    return {'sdk_level': level, 'build_tools': '.'.join(map(str, chosen))}


def _valid_sdk_directory(path):
    return (path / 'licenses').is_dir() or (path / 'platform-tools').is_dir()


def resolve_android_sdk(qa):
    """The Android SDK that flutter_tools uses, proven to need no drive rebuild."""
    text = run_separated(qa, 'flutter-config', ['flutter', 'config', '--machine'])
    try:
        settings = json.loads(text)
    except ValueError:
        raise base.RunnerError('flutter config --machine is not JSON; the android-sdk '
                               'that flutter drive uses is unknown') from None
    configured = settings.get('android-sdk') if isinstance(settings, dict) else None
    if not isinstance(configured, str) or not configured:
        raise base.RunnerError('flutter config --machine reports no android-sdk; the SDK '
                               'that flutter drive uses is unknown')
    # A relative setting would be read from this runner's cwd here but from the
    # QA workspace by flutter and apkanalyzer, so it may name another SDK.
    if not Path(configured).is_absolute():
        raise base.RunnerError(
            f'unsupported relative android-sdk setting {configured!r}: the runner cannot '
            'prove it names the SDK that flutter drive uses; refused before any SDK '
            'inspection or device step')
    sdk = Path(configured)
    if not _valid_sdk_directory(sdk):
        sdk = sdk / 'sdk'
        if not _valid_sdk_directory(sdk):
            raise base.RunnerError(f'android-sdk {configured} is not a valid SDK directory')
    latest = sdk_latest_version(sdk)
    evidence = {'directory': str(sdk), 'licenses': (sdk / 'licenses').is_dir(),
                'latest': latest}
    qa.result['android_sdk'] = evidence
    if latest is None:
        raise base.RunnerError(
            'the Android SDK has no latest platform/build-tools version; flutter drive '
            'would build again instead of installing the inspected APK')
    adb = next((path for path in (sdk / 'cmdline-tools/adb', sdk / 'platform-tools/adb')
                if path.is_file()), None)
    apkanalyzer = sdk / 'cmdline-tools/latest/bin/apkanalyzer'
    if not apkanalyzer.is_file():
        versioned = sorted(
            (version, path) for version, path in (
                (_tool_version(directory.name), directory / 'bin/apkanalyzer')
                for directory in (sdk / 'cmdline-tools').glob('*'))
            if version is not None and path.is_file())
        apkanalyzer = versioned[-1][1] if versioned else None
    if adb is None or not os.access(adb, os.X_OK):
        raise base.RunnerError(f'adb is missing from the Android SDK {sdk}')
    if apkanalyzer is None or not os.access(apkanalyzer, os.X_OK):
        raise base.RunnerError(f'apkanalyzer is missing from the Android SDK {sdk}; the '
                               'merged manifest cannot be inspected')
    evidence.update({'adb': str(adb), 'apkanalyzer': str(apkanalyzer)})
    return sdk, adb, apkanalyzer


def check_manifest(text):
    """Checks the complete merged manifest; anything not proven fails."""
    try:
        root = ElementTree.fromstring(text)
    except ElementTree.ParseError as error:
        raise base.RunnerError(f'the merged manifest does not parse: {error}') from None
    if root.tag != 'manifest':
        raise base.RunnerError(f'the merged manifest root is <{root.tag}>, not <manifest>')
    package = root.get('package')
    if package != PACKAGE:
        raise base.RunnerError(f'the merged manifest package is {package!r}, not {PACKAGE}')
    applications = root.findall('application')
    if len(applications) != 1:
        raise base.RunnerError(f'the merged manifest has {len(applications)} <application>')
    entries = applications[0].findall('meta-data')
    found = {}
    for name, expected in REQUIRED_META.items():
        values = [entry.get(f'{ANDROID_NS}value') for entry in entries
                  if entry.get(f'{ANDROID_NS}name') == name]
        if values != [expected]:
            raise base.RunnerError(
                f'merged manifest meta-data {name} is {values}, not exactly [{expected!r}]')
        found[name] = values[0]
    return {'package': package, 'meta_data': found}


def inspect_artifact(qa, apkanalyzer):
    """Copies the built APK once and inspects exactly that copy."""
    artifact = qa.workspace / ARTIFACT
    copy_checked(qa.workspace / APK, artifact)
    artifact.chmod(0o444)
    before = sha256(artifact)
    report = inspect_apk(artifact)
    manifest = run_separated(qa, 'apkanalyzer-manifest',
                             [str(apkanalyzer), 'manifest', 'print', str(artifact)])
    report['manifest'] = check_manifest(manifest)
    after = sha256(artifact)
    if not (before == report['sha256'] == after):
        raise base.RunnerError('the artifact changed during inspection; it is not the '
                               'inspected build')
    report['path'] = str(artifact)
    report['build_output_sha256'] = sha256(qa.workspace / APK)
    return report


def top_level_blocks(text):
    """Maps each top-level pubspec key to the lines of its block body."""
    blocks, current = {}, None
    for line in text.splitlines():
        match = re.match(r'^([A-Za-z_][\w-]*):', line)
        if match:
            current = match.group(1)
            blocks[current] = []
        elif current is not None:
            blocks[current].append(line)
    return blocks


def declared_assets(flutter_block):
    """The `flutter: assets:` entries, in order."""
    assets, inside, indent = [], False, None
    for line in flutter_block:
        if re.match(r'^\s+assets:\s*$', line):
            inside, indent = True, len(line) - len(line.lstrip())
            continue
        if inside:
            item = re.match(r'^(\s+)-\s+(\S.*?)\s*$', line)
            if item and len(item.group(1)) > indent:
                assets.append(item.group(2).strip('\'"'))
            elif line.strip():
                inside = False
    return assets


def build_pubspec(product_text, picnic_lib, locked, assets):
    """The QA pubspec: product dependencies with an absolute picnic_lib path."""
    blocks = top_level_blocks(product_text)
    for key in ('environment', 'dependencies', 'dev_dependencies'):
        if key not in blocks:
            raise base.RunnerError(f'product pubspec has no {key} block')
    dependencies, count = re.subn(
        r'^([ \t]+)picnic_lib:[ \t]*\n([ \t]+)path:[ \t]*\S+[ \t]*$',
        lambda match: f'{match.group(1)}picnic_lib:\n{match.group(2)}path: '
                      f'{json.dumps(str(picnic_lib))}',
        '\n'.join(blocks['dependencies']), flags=re.MULTILINE)
    if count != 1:
        raise base.RunnerError('product pubspec has no single picnic_lib path dependency')
    indent = re.match(r'^([ \t]+)', next(
        line for line in blocks['dependencies'] if line.strip())).group(1)
    messaging = re.search(r'^\s+firebase_messaging:\s*(\S+)\s*$',
                          '\n'.join(blocks['dev_dependencies']), re.MULTILINE)
    if messaging is None:
        raise base.RunnerError('product pubspec has no firebase_messaging dev dependency')
    platform_interface = locked.get('firebase_core_platform_interface')
    if platform_interface is None:
        raise base.RunnerError('product lock has no firebase_core_platform_interface')
    i2 = indent * 2
    asset_lines = ''.join(f'{i2}- {asset}\n' for asset in assets)
    return (
        f'name: {PROJECT_NAME}\n'
        'description: "Disposable full App retry QA build (generated)."\n'
        'publish_to: none\n'
        f'version: {QA_VERSION}\n'
        'environment:\n' + '\n'.join(blocks['environment']).rstrip() + '\n'
        'dependencies:\n' + dependencies.rstrip() + '\n'
        'dev_dependencies:\n'
        f'{indent}flutter_test:\n{i2}sdk: flutter\n'
        f'{indent}integration_test:\n{i2}sdk: flutter\n'
        f'{indent}flutter_driver:\n{i2}sdk: flutter\n'
        f'{indent}firebase_messaging: {messaging.group(1)}\n'
        f'{indent}firebase_core_platform_interface: {platform_interface}\n'
        'flutter:\n'
        f'{indent}uses-material-design: true\n'
        f'{indent}assets:\n{asset_lines}'
    )


def compare_locks(product_lock, qa_lock):
    """Every resolved QA package must be in the product lock, same version."""
    expected = base.locked_versions(product_lock)
    actual = base.locked_versions(qa_lock)
    drift = {name: [expected[name], actual[name]]
             for name in sorted(actual) if name in expected and expected[name] != actual[name]}
    extra = sorted(name for name in actual if name not in expected)
    report = {'resolved': len(actual), 'drift': drift, 'extra': extra,
              'product_only': len(set(expected) - set(actual))}
    if drift or extra:
        raise base.RunnerError(
            f'lock mismatch with the product pubspec.lock: drift={drift} extra={extra}')
    return report


def copy_checked(source, target):
    """Copies bytes and confirms the copy has the same SHA-256."""
    target.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(source, target)
    digest = sha256(source)
    if sha256(target) != digest:
        raise base.RunnerError(f'copy of {source} changed its bytes')
    return digest


def refuse_sensitive(rel):
    if SENSITIVE_NAME.search(rel):
        raise base.RunnerError(f'refusing to copy a sensitive file: {rel}')


def copy_product(qa, source):
    """Copies product lib and declared non-secret assets from the source root."""
    workspace = qa.workspace
    app = source / 'picnic_app'
    lib = app / 'lib'
    shutil.rmtree(workspace / 'lib', ignore_errors=True)  # Generated main.dart only.
    shutil.rmtree(workspace / 'test', ignore_errors=True)  # Generated widget test.
    lib_files = {}
    for path in sorted(lib.rglob('*')):
        if not path.is_file():
            continue
        rel = str(path.relative_to(lib))
        if rel in EXCLUDED_LIB_FILES:
            continue
        refuse_sensitive(rel)
        lib_files[rel] = copy_checked(path, workspace / 'lib' / rel)
    if 'app.dart' not in lib_files:
        raise base.RunnerError('source root has no picnic_app/lib/app.dart')

    product_pubspec = (app / 'pubspec.yaml').read_text()
    declared = declared_assets(top_level_blocks(product_pubspec).get('flutter', []))
    kept, excluded, copied = [], [], []
    for asset in declared:
        if asset in EXCLUDED_ASSETS or asset.startswith('config/') or SENSITIVE_NAME.search(asset):
            excluded.append(asset)
            continue
        kept.append(asset)
        origin = app / asset
        if asset.endswith('/'):
            if not origin.is_dir():
                raise base.RunnerError(f'declared asset directory is missing: {asset}')
            files = sorted(path for path in origin.iterdir() if path.is_file())
        else:
            if not origin.is_file():
                raise base.RunnerError(f'declared asset is missing: {asset}')
            files = [origin]
        for path in files:
            rel = str(path.relative_to(app))
            refuse_sensitive(rel)
            copy_checked(path, workspace / rel)
            copied.append(rel)
    qa.result['assets'] = {'kept': kept, 'excluded': excluded, 'copied': copied}
    return lib_files, product_pubspec, kept


def copy_harness(qa):
    workspace = qa.workspace
    files = {HARNESS_TEST: copy_checked(HARNESS_DIR / HARNESS_TEST, workspace / TEST_TARGET)}
    support = HARNESS_DIR / HARNESS_SUPPORT
    for path in sorted(support.glob('*.dart')):
        files[path.name] = copy_checked(
            path, workspace / 'integration_test' / HARNESS_SUPPORT / path.name)
    files[HARNESS_DRIVER] = copy_checked(HARNESS_DIR / HARNESS_DRIVER, workspace / DRIVER_TARGET)
    qa.result['harness'] = {'root': str(ROOT), 'git_head': harness_head(), 'files': files}


def harness_head():
    """The harness checkout's HEAD, if it can be read; informational only."""
    try:
        completed = subprocess.run(
            ['git', '-C', str(ROOT), 'rev-parse', 'HEAD'], capture_output=True,
            text=True, timeout=10, env=base.INSPECT_ENV)
    except (OSError, subprocess.TimeoutExpired):
        return None
    head = completed.stdout.strip()
    return head if completed.returncode == 0 and re.fullmatch(r'[0-9a-f]{40}', head) else None


def prepare_android(qa, source):
    """The generated Gradle project with the reviewed compatibility edits."""
    android = qa.workspace / 'android'
    product_android = source / 'picnic_app/android'
    app_gradle = android / 'app/build.gradle.kts'
    app_text = app_gradle.read_text()
    if (f'applicationId = "{PACKAGE}"' not in app_text
            or f'namespace = "{PACKAGE}"' not in app_text
            or PRODUCT_PACKAGE in app_text):
        raise base.RunnerError(f'generated applicationId/namespace is not {PACKAGE}')

    product_settings = product_android / 'settings.gradle'
    kotlin = base.product_version(
        r'"org\.jetbrains\.kotlin\.android" version "([^"]+)"', product_settings)
    agp = base.product_version(
        r'"com\.android\.application" version \'([^\']+)\'', product_settings)
    settings = android / 'settings.gradle.kts'
    text, kotlin_count = re.subn(
        r'(id\("org\.jetbrains\.kotlin\.android"\) version ")[^"]+"',
        rf'\g<1>{kotlin}"', settings.read_text())
    text, agp_count = re.subn(
        r'(id\("com\.android\.application"\) version ")[^"]+"', rf'\g<1>{agp}"', text)
    if kotlin_count != 1 or agp_count != 1:
        raise base.RunnerError('generated settings.gradle.kts has an unexpected plugin block')
    settings.write_text(text)
    wrapper = android / 'gradle/wrapper/gradle-wrapper.properties'
    distribution = base.product_version(
        r'^(distributionUrl=.*)$', product_android / 'gradle/wrapper/gradle-wrapper.properties')
    wrapper.write_text(re.sub(r'^distributionUrl=.*$', lambda _: distribution,
                              wrapper.read_text(), flags=re.MULTILINE))
    qa.result['toolchain'] = {'kotlin': kotlin, 'agp': agp, 'gradle': distribution}

    properties = android / 'gradle.properties'
    existing = properties.read_text() if properties.exists() else ''
    properties.write_text(existing + base.GRADLE_PROPERTIES)

    base.replace_once(android / 'app/src/main/AndroidManifest.xml', '</application>', '''
        <meta-data android:name="firebase_messaging_auto_init_enabled" android:value="false"/>
        <meta-data android:name="firebase_analytics_collection_enabled" android:value="false"/>
        <meta-data android:name="firebase_analytics_collection_deactivated" android:value="true"/>
        <meta-data android:name="google_analytics_adid_collection_enabled" android:value="false"/>
        <meta-data android:name="com.google.android.gms.ads.APPLICATION_ID" android:value="ca-app-pub-3940256099942544~3347511713"/>
    </application>''')
    base.replace_once(app_gradle, 'compileOptions {',
                      'compileOptions {\n        isCoreLibraryDesugaringEnabled = true')
    base.migrate_kotlin_jvm_target(app_gradle)
    app_gradle.write_text(app_gradle.read_text() + '''
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    // The Tapjoy Flutter plugin requires the host to expose its SDK, as in picnic_app.
    implementation("com.tapjoy:tapjoy-android-sdk:14.4.0")
}
''')
    root_gradle = android / 'build.gradle.kts'
    base.replace_once(root_gradle, 'repositories {', '''repositories {
        maven { url = uri("https://artifact.bytedance.com/repository/pangle") }
        maven { url = uri("https://sdk.tapjoy.com/") }
        maven { url = uri("https://jitpack.io") }
''')
    compat = (product_android / 'build.gradle').read_text()
    start = compat.index('// AGP 8+')
    end = compat.index('\nbuildscript {', start)
    (android / 'namespace-compat.gradle').write_text(compat[start:end])
    root_gradle.write_text('apply(from = "namespace-compat.gradle")\n' + root_gradle.read_text())


def scan_workspace(workspace):
    """Fails if a sensitive file or a config directory is in the workspace."""
    owned = {base.OWNED_GRADLE_HOME, 'qa-logs'}
    for path in workspace.rglob('*'):
        rel = path.relative_to(workspace)
        if owned.intersection(rel.parts[:1]):
            continue
        if path.is_file() and SENSITIVE_NAME.search(str(rel)):
            raise base.RunnerError(f'{rel} must not exist in the QA workspace')
    if (workspace / 'config').exists():
        raise base.RunnerError('config/ must not exist in the QA workspace')


class Device:
    """adb access to exactly one serial. Raw output never leaves this class."""

    def __init__(self, adb, serial, env):
        self.adb, self.serial, self.env = adb, serial, env

    def _run(self, *args):
        """(exit code, stdout, stderr), or None if adb did not complete.

        adb may start the shared adb server, which must survive the run, so
        these short calls are bounded by a timeout instead of a process group.
        """
        try:
            completed = subprocess.run(
                [self.adb, '-s', self.serial, *args], env=self.env,
                capture_output=True, text=True, timeout=ADB_TIMEOUT_S)
        except (OSError, subprocess.TimeoutExpired):
            return None
        return completed.returncode, completed.stdout, completed.stderr

    def attached(self):
        outcome = self._run('get-state')
        return outcome is not None and outcome[0] == 0 and outcome[1].strip() == 'device'

    def package_state(self):
        """'present', 'absent' or 'unknown'; a failed query is never 'absent'."""
        outcome = self._run('shell', 'pm', 'list', 'packages', '--user', str(DEVICE_USER),
                            PACKAGE)
        if outcome is None:
            return 'unknown'
        return parse_package_list(*outcome)

    def user_scope(self):
        """Validates that the complete user list is user 0 and 0 is current.

        Returns {'state': 'valid'|'refused'|'unknown', ...}. Only 'valid'
        allows work. Both queries always run, so the record is complete.
        """
        users = parse_user_list(self._run('shell', 'pm', 'list', 'users'))
        current = parse_current_user(self._run('shell', 'am', 'get-current-user'))
        report = {'users': users, 'current': current, 'user': None}
        if users is None or current is None:
            report.update(state='unknown', reason='the user list or current user did not parse')
        elif users != [DEVICE_USER]:
            report.update(state='refused',
                          reason=f'users are {users}; only a device with exactly user '
                                 f'{DEVICE_USER} is supported')
        elif current != DEVICE_USER:
            report.update(state='refused',
                          reason=f'the current user is {current}, not {DEVICE_USER}')
        else:
            report.update(state='valid', reason=None, user=DEVICE_USER)
        return report

    def package_pids(self):
        """PIDs of the QA package, [] when none run, None when unknown."""
        outcome = self._run('shell', 'pidof', PACKAGE)
        if outcome is None:
            return None
        code, out, err = outcome
        pids = out.split()
        if code == 0 and pids and all(pid.isdigit() for pid in pids):
            return pids
        if code == 1 and not pids and not err.strip():
            return []
        return None

    def force_stop(self):
        outcome = self._run('shell', 'am', 'force-stop', '--user', str(DEVICE_USER), PACKAGE)
        return None if outcome is None else outcome[0]

    def uninstall(self):
        outcome = self._run('uninstall', '--user', str(DEVICE_USER), PACKAGE)
        return None if outcome is None else outcome[0]


def parse_package_list(code, out, err):
    """'present', 'absent' or 'unknown' for `pm list packages` output.

    Every non-empty line must be one complete `package:<name>` record; a
    failed query, stderr output or any other line is 'unknown', never absent.
    """
    if code != 0 or err.strip():
        return 'unknown'
    names = []
    for line in out.splitlines():
        if not line.strip():
            continue
        record = PACKAGE_RECORD.fullmatch(line.rstrip('\r'))
        if record is None:
            return 'unknown'
        names.append(record.group(1))
    return 'present' if PACKAGE in names else 'absent'


def parse_user_list(outcome):
    """User IDs from `pm list users`, or None if the output is not complete."""
    if outcome is None:
        return None
    code, out, err = outcome
    if code != 0 or err.strip():
        return None
    lines = [line.rstrip('\r') for line in out.splitlines() if line.strip()]
    if not lines or lines[0] != 'Users:':
        return None
    users = []
    for line in lines[1:]:
        record = USER_RECORD.fullmatch(line.rstrip())
        if record is None:
            return None
        users.append(int(record.group(1)))
    return users or None


def parse_current_user(outcome):
    if outcome is None:
        return None
    code, out, err = outcome
    text = out.strip()
    if code != 0 or err.strip() or not re.fullmatch(r'\d+', text):
        return None
    return int(text)


def cleanup_device(device, owned):
    """Removes this run's package for user 0 only, then verifies it is gone.

    The user scope is validated first. If it is no longer exactly user 0,
    nothing is changed and the cleanup is unverified.
    """
    report = {'owned': owned, 'actions': [], 'verified': not owned}
    if not owned:
        return report
    try:
        scope = report['user_scope'] = device.user_scope()
        if scope['state'] != 'valid':
            report['verified'] = False
            return report
        report['actions'].append(['force-stop', device.force_stop()])
        report['actions'].append(['uninstall', device.uninstall()])
        report['package_after'] = device.package_state()
        pids = device.package_pids()
        report['pids_after'] = 'unknown' if pids is None else len(pids)
        report['verified'] = report['package_after'] == 'absent' and pids == []
    except BaseException as caught:  # Includes a second interrupt.
        report['error'] = type(caught).__name__
        report['verified'] = False
    return report


def read_driver_response(path):
    """The reportData the driver wrote, or None if there is no valid file."""
    try:
        data = json.loads(path.read_text())
    except (OSError, ValueError):
        return None
    return data if isinstance(data, dict) else None


class Ownership:
    def __init__(self):
        self.owned = False
        self.device = None


def require_user_scope(device):
    scope = device.user_scope()
    if scope['state'] != 'valid':
        raise base.RunnerError(f'the device user scope is {scope["state"]}: {scope["reason"]}; '
                               'refused')
    return scope


def execute(qa, args, source, ownership):
    _, adb, apkanalyzer = resolve_android_sdk(qa)
    device = ownership.device = Device(str(adb), args.device, qa.env)
    if not device.attached():
        raise base.RunnerError('the selected device is not attached in the "device" state')
    qa.result['user_scope'] = require_user_scope(device)
    preflight = qa.result['package_preflight'] = device.package_state()
    if preflight == 'present':
        raise base.RunnerError(
            f'{PACKAGE} is already installed on the device; it is left untouched '
            'and this run is refused')
    if preflight != 'absent':
        raise base.RunnerError(f'the state of {PACKAGE} on the device is unknown; refused')

    qa.run('flutter-create', [
        'flutter', 'create', '--platforms=android', '--project-name', PROJECT_NAME,
        '--org', ORG, '--no-pub', str(qa.workspace),
    ], args.create_timeout)
    lib_files, product_pubspec, assets = copy_product(qa, source)
    product_lock = source / 'picnic_app/pubspec.lock'
    locked = base.locked_versions(product_lock)
    (qa.workspace / 'pubspec.yaml').write_text(
        build_pubspec(product_pubspec, source / 'picnic_lib', locked, assets))
    copy_harness(qa)
    prepare_android(qa, source)
    scan_workspace(qa.workspace)
    qa.result['source']['product_lib'] = {
        'files': lib_files, 'count': len(lib_files), 'sha256': tree_digest(lib_files)}

    copy_checked(product_lock, qa.workspace / 'pubspec.lock')
    qa.run('pub-get', ['flutter', 'pub', 'get'], args.pub_timeout)
    qa.result['lock'] = compare_locks(product_lock, qa.workspace / 'pubspec.lock')

    qa.run('build-apk', ['flutter', 'build', 'apk', '--debug', '--no-pub',
                         '--target', TEST_TARGET, *DART_DEFINES], args.build_timeout)
    inspected = qa.result['artifact'] = inspect_artifact(qa, apkanalyzer)
    artifact = qa.workspace / ARTIFACT

    # The install boundary: scope, absence and artifact identity, then drive.
    qa.result['user_scope_before_install'] = require_user_scope(device)
    before_install = qa.result['package_before_install'] = device.package_state()
    if before_install != 'absent':
        raise base.RunnerError(
            f'{PACKAGE} is not provably absent right before install '
            f'({before_install}); refused')
    if sha256(artifact) != inspected['sha256']:
        raise base.RunnerError('the artifact is not the inspected build; refused')
    response = qa.workspace / DRIVER_RESPONSE
    if response.exists():
        response.unlink()
    ownership.owned = True
    drive_error = None
    try:
        qa.run('device-drive', [
            'flutter', 'drive', '--no-pub', '--debug', '--target', TEST_TARGET,
            '--driver', DRIVER_TARGET, f'--use-application-binary={artifact}',
            '-d', args.device, '--device-user', str(DEVICE_USER),
        ], args.test_timeout)
    except base.RunnerError as caught:
        drive_error = caught
    data = qa.result['driver_response'] = read_driver_response(response)
    if isinstance(data, dict):
        qa.result['checkpoints'] = data.get('checkpoints')
        qa.result['checkpoint_facts'] = data.get('facts')
        summary = data.get('summary')
        qa.result['loopback_unexpected'] = (
            summary.get('loopbackUnexpected') if isinstance(summary, dict) else None)
    if drive_error is not None:
        raise drive_error
    if sha256(artifact) != inspected['sha256']:
        raise base.RunnerError('the artifact changed while flutter drive used it')
    built = qa.workspace / APK
    if not built.is_file() or sha256(built) != inspected['build_output_sha256']:
        raise base.RunnerError('the project was rebuilt during flutter drive; the run does '
                               'not prove that only the inspected APK was installed')
    if data is None:
        raise base.RunnerError('flutter drive passed but the driver wrote no response data')
    if data.get('checkpoints') != EXPECTED_CHECKPOINTS or data.get('bodyCompleted') is not True:
        raise base.RunnerError(
            f'the driver response checkpoints were {data.get("checkpoints")} '
            f'(bodyCompleted={data.get("bodyCompleted")}), not {EXPECTED_CHECKPOINTS}')


def describe_source(source, label):
    app, lib = source / 'picnic_app', source / 'picnic_lib'
    for required in (app / 'pubspec.yaml', app / 'pubspec.lock', app / 'lib/app.dart',
                     lib / 'pubspec.yaml', app / 'android/settings.gradle'):
        if not required.is_file():
            raise base.RunnerError(f'source root has no {required.relative_to(source)}')
    picnic_lib = {'lib': hash_tree(lib / 'lib'), 'pubspec_sha256': sha256(lib / 'pubspec.yaml')}
    if (lib / 'pubspec.lock').is_file():
        picnic_lib['lock_sha256'] = sha256(lib / 'pubspec.lock')
    return {
        'root': str(source), 'is_harness_root': source == ROOT,
        'revision_label': label,
        'pubspec_sha256': sha256(app / 'pubspec.yaml'),
        'lock_sha256': sha256(app / 'pubspec.lock'),
        'picnic_lib': picnic_lib,
    }


def parse_args(argv):
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument('--device', required=True, help='adb serial of the device')
    parser.add_argument('--source-root', type=Path, default=ROOT,
                        help='tree that holds picnic_app/ and picnic_lib/ for the product')
    parser.add_argument('--source-revision', default=None,
                        help='label of the source root revision, recorded only')
    parser.add_argument('--create-timeout', type=int, default=300)
    parser.add_argument('--pub-timeout', type=int, default=900)
    parser.add_argument('--build-timeout', type=int, default=2400)
    parser.add_argument('--test-timeout', type=int, default=2400,
                        help='seconds for flutter drive (install, test and uninstall)')
    return parser.parse_args(argv)


def main(argv=None, environ=None):
    args = parse_args(argv)
    source = Path(os.path.abspath(args.source_root))
    workspace = Path(tempfile.mkdtemp(prefix='picnic-full-app-retry-qa-'))
    print(f'QA_WORKSPACE={workspace}', flush=True)
    gradle_home_created_at = time.time()
    gradle_home = workspace / base.OWNED_GRADLE_HOME
    gradle_home.mkdir()
    qa = base.QaRun(workspace, {}, private=[args.device])
    qa.result.update({'package': PACKAGE, 'gradle_user_home': str(gradle_home),
                      'overrides': OVERRIDES, 'source': {'root': str(source)}})
    ownership = Ownership()
    status, error, code = 'failed', None, 1
    previous = signal.signal(signal.SIGTERM, base._raise_interrupted)
    try:
        try:
            qa.result['source'] = describe_source(source, args.source_revision)
            qa.env = base.child_env(os.environ if environ is None else environ,
                                    gradle_user_home=gradle_home)
            qa.result['developer_dir'] = qa.env.get('DEVELOPER_DIR')
            execute(qa, args, source, ownership)
            status, code = 'passed', 0
        except base.RunnerError as caught:
            error = str(caught)
        except (KeyboardInterrupt, base.Interrupted):
            status, error, code = 'interrupted', 'the runner was interrupted', 130
        except Exception as caught:  # Reported, after cleanup, as a failure.
            error = f'unexpected error: {caught!r}'

        problems = []
        device_cleanup = cleanup_device(ownership.device, ownership.owned)
        qa.result['device_cleanup'] = device_cleanup
        if device_cleanup['verified'] is not True:
            problems.append(f'device cleanup is not verified: {device_cleanup}')
        if qa.env:
            try:
                gradle_cleanup = base.stop_owned_gradle(
                    gradle_home, qa.env, gradle_home_created_at,
                    cwd=workspace, log=qa.logs / 'gradle-stop.log')
            except BaseException as caught:  # Includes a second interrupt.
                gradle_cleanup = {'error': repr(caught), 'verified': False}
            qa.result['gradle_cleanup'] = gradle_cleanup
            if gradle_cleanup.get('verified') is not True:
                problems.append('owned Gradle daemon cleanup is not verified; the '
                                f'workspace is kept for inspection: {gradle_cleanup}')
        for problem in problems:
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

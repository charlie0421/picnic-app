"""Build an isolated Android QA package using the current picnic_lib source.

Requires the disposable server bridge's --ready-file. Never changes the product
package, signing files, app version, or environment. Does not load/show real ads.
"""
import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import urllib.request
import atexit

ROOT = Path(__file__).resolve().parents[2]
parser = argparse.ArgumentParser()
parser.add_argument('--device', required=True)
parser.add_argument('--bridge-ready', type=Path, required=True)
args = parser.parse_args()
port = json.loads(args.bridge_ready.read_text())['port']
assert isinstance(port, int) and 1024 < port < 65536
workspace = Path(tempfile.mkdtemp(prefix='picnic-ad-device-qa-'))
adb = shutil.which('adb') or str(Path.home() / 'Library/Android/sdk/platform-tools/adb')
env = {k: os.environ[k] for k in ('PATH', 'HOME', 'TMPDIR', 'LANG', 'LC_ALL', 'ANDROID_HOME', 'ANDROID_SDK_ROOT', 'JAVA_HOME') if k in os.environ}


def run(command, cwd=workspace):
    subprocess.run(command, cwd=cwd, env=env, check=True)


def cleanup():
    subprocess.run([adb, '-s', args.device, 'reverse', '--remove', f'tcp:{port}'], env=env, capture_output=True)
    request = urllib.request.Request(f'http://127.0.0.1:{port}/qa/finish', data=b'{}', headers={'Content-Type': 'application/json'})
    try:
        urllib.request.urlopen(request, timeout=5).close()
    except OSError:
        pass


atexit.register(cleanup)
print(f'QA_WORKSPACE={workspace}', flush=True)
run(['flutter', 'create', '--platforms=android', '--project-name', 'ad_device_qa', '--org', 'io.picnic.qa', '--no-pub', str(workspace)])
(workspace / 'pubspec.yaml').write_text(f"""name: ad_device_qa
publish_to: none
version: 0.0.1+000101
environment:
  sdk: ^3.9.0
dependencies:
  flutter:
    sdk: flutter
  picnic_lib:
    path: {ROOT / 'picnic_lib'}
  http: ^1.2.2
  supabase_flutter: ^2.10.3
dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
flutter:
  uses-material-design: true
""")
integration = workspace / 'integration_test'
integration.mkdir()
shutil.copyfile(ROOT / 'picnic_app/test_support/ad_device_android_qa.dart', integration / 'ad_device_test.dart')
native = workspace / 'android/app/src/main/kotlin/io/picnic/qa/ad_device_qa/MainActivity.kt'
native.write_text('''package io.picnic.qa.ad_device_qa
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "picnic/device_id")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getAndroidId" -> result.success(
                        Settings.Secure.getString(contentResolver, Settings.Secure.ANDROID_ID)
                    )
                    else -> result.notImplemented()
                }
            }
    }
}
''')
manifest = workspace / 'android/app/src/main/AndroidManifest.xml'
s = manifest.read_text().replace('<application', '<uses-permission android:name="android.permission.INTERNET"/><application android:usesCleartextTraffic="true"', 1)
# Official sample app ID: https://firebase.google.com/docs/admob/android/quick-start
s = s.replace('</application>', '<meta-data android:name="com.google.android.gms.ads.APPLICATION_ID" android:value="ca-app-pub-3940256099942544~3347511713"/></application>')
manifest.write_text(s)
gradle = workspace / 'android/app/build.gradle.kts'
s = gradle.read_text().replace('compileOptions {', 'compileOptions {\n        isCoreLibraryDesugaringEnabled = true', 1)
s += '''
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    // The Tapjoy Flutter plugin requires the host to expose its SDK, as in picnic_app.
    implementation("com.tapjoy:tapjoy-android-sdk:14.4.0")
}
'''
gradle.write_text(s)
root_gradle = workspace / 'android/build.gradle.kts'
s = root_gradle.read_text().replace('repositories {', '''repositories {
        maven { url = uri("https://artifact.bytedance.com/repository/pangle") }
        maven { url = uri("https://sdk.tapjoy.com/") }
        maven { url = uri("https://jitpack.io") }
''', 1)
root_gradle.write_text(s)
# Preserve the product's AGP compatibility shim for older transitive plugins.
compat = (ROOT / 'picnic_app/android/build.gradle').read_text()
start = compat.index('// AGP 8+')
end = compat.index('\nbuildscript {', start)
(workspace / 'android/namespace-compat.gradle').write_text(compat[start:end])
root_gradle.write_text('apply(from = "namespace-compat.gradle")\n' + root_gradle.read_text())
shutil.copyfile(ROOT / 'picnic_lib/pubspec.lock', workspace / 'pubspec.lock')
run(['flutter', 'pub', 'get'])
run([adb, '-s', args.device, 'reverse', f'tcp:{port}', f'tcp:{port}'])
run(['flutter', 'test', '--no-pub', 'integration_test/ad_device_test.dart', '-d', args.device,
     f'--dart-define=QA_PORT={port}', '--timeout', '5m'])

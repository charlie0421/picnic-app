// Host regression for the evidence file location shared by the iOS
// notification delivery QA app and its runner
// (scripts/qa/run_notification_delivery_ios.py).
//
// The app gets its directory from the platform path provider
// (getTemporaryDirectory). On iOS the locked path_provider_foundation 2.6.0
// answers that call with NSCachesDirectory, which is <data container>/
// Library/Caches, not <data container>/tmp. Here the platform provider is
// replaced by one that answers like that, the ACTUAL QaEvidence.open runs,
// and its path is compared with the path that the runner's pure contract
// function (evidence_path) computes for the same synthetic container. The
// Python call only imports the runner module and computes a path: no
// simulator, build or network command runs.
// ignore_for_file: depend_on_referenced_packages
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import '../../test_support/notification_delivery_ios_qa.dart';

const _container = '/Users/qa/Library/Developer/CoreSimulator/Devices/'
    'A1B2C3D4-1111-4222-8333-0000000000AA/data/Containers/Data/Application/'
    '0A1B2C3D-0000-4000-8000-000000000001';

class _ContainerPathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  _ContainerPathProvider(this.temporaryPath);

  final String temporaryPath;
  int temporaryCalls = 0;

  @override
  Future<String?> getTemporaryPath() async {
    temporaryCalls++;
    return temporaryPath;
  }
}

/// The runner's evidence file for [container], from its own pure function.
Future<String> _runnerEvidencePath(String container) async {
  final scripts = Directory('${Directory.current.parent.path}/scripts/qa');
  expect(
    File('${scripts.path}/run_notification_delivery_ios.py').existsSync(),
    isTrue,
    reason: 'run from picnic_app/: the runner is ../scripts/qa',
  );
  final result = await Process.run('python3', [
    '-c',
    'import sys; sys.path.insert(0, sys.argv[1]); '
        'import run_notification_delivery_ios as runner; '
        'print(runner.evidence_path(sys.argv[2]))',
    scripts.path,
    container,
  ]);
  expect(result.exitCode, 0, reason: '${result.stderr}');
  return (result.stdout as String).trim();
}

void main() {
  late PathProviderPlatform original;

  setUp(() => original = PathProviderPlatform.instance);
  tearDown(() => PathProviderPlatform.instance = original);

  test('the app writes where the runner reads: <container>/Library/Caches',
      () async {
    final provider = _ContainerPathProvider('$_container/Library/Caches');
    PathProviderPlatform.instance = provider;

    final evidence = await QaEvidence.open();

    expect(provider.temporaryCalls, 1,
        reason: 'the app uses the platform path provider');
    expect(evidence.path, await _runnerEvidencePath(_container));
    expect(evidence.path,
        '$_container/Library/Caches/notification-delivery-ios.json');
  });

  test('a trailing slash from the provider gives the same file', () async {
    PathProviderPlatform.instance =
        _ContainerPathProvider('$_container/Library/Caches/');

    final evidence = await QaEvidence.open();

    expect(evidence.path, await _runnerEvidencePath(_container));
  });

  test('a provider directory that is not Library/Caches is refused', () async {
    for (final directory in ['$_container/tmp', '$_container/Library']) {
      PathProviderPlatform.instance = _ContainerPathProvider(directory);
      await expectLater(
        QaEvidence.open(),
        throwsA(isA<StateError>()),
        reason: directory,
      );
    }
  });
}

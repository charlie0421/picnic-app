import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/services/shorebird_update_coordinator.dart';
import 'package:picnic_lib/core/utils/shorebird_utils.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart' as shorebird;

class FakeShorebirdUpdateClient implements ShorebirdUpdateClient {
  FakeShorebirdUpdateClient({
    this.status = shorebird.UpdateStatus.upToDate,
    this.available = true,
    this.currentPatchNumber,
    this.nextPatchNumber,
    this.checkCompleter,
  });

  shorebird.UpdateStatus status;
  bool available;
  int? currentPatchNumber;
  int? nextPatchNumber;
  Completer<shorebird.UpdateStatus>? checkCompleter;
  int checkCalls = 0;
  int updateCalls = 0;

  @override
  bool get isAvailable => available;

  @override
  Future<shorebird.UpdateStatus> checkForUpdate() {
    checkCalls++;
    return checkCompleter?.future ?? Future.value(status);
  }

  @override
  Future<int?> readCurrentPatchNumber() async => currentPatchNumber;

  @override
  Future<int?> readNextPatchNumber() async => nextPatchNumber;

  @override
  Future<void> update() async {
    updateCalls++;
  }
}

void main() {
  test('동시에 실행된 확인은 하나의 Shorebird 호출을 공유한다', () async {
    final completer = Completer<shorebird.UpdateStatus>();
    final client = FakeShorebirdUpdateClient(checkCompleter: completer);
    final coordinator = ShorebirdUpdateCoordinator(clientFactory: () => client);

    final first = coordinator.run();
    final second = coordinator.run();
    completer.complete(shorebird.UpdateStatus.upToDate);

    expect(await first, const ShorebirdRunResult.upToDate());
    expect(await second, const ShorebirdRunResult.upToDate());
    expect(client.checkCalls, 1);
  });

  test('새 패치는 한 번 다운로드하고 재시작 필요 결과를 반환한다', () async {
    final client = FakeShorebirdUpdateClient(
      status: shorebird.UpdateStatus.outdated,
      currentPatchNumber: 3,
      nextPatchNumber: 4,
    );
    final coordinator = ShorebirdUpdateCoordinator(clientFactory: () => client);

    final result = await coordinator.run();

    expect(
      result,
      const ShorebirdRunResult.restartRequired(
        currentPatchNumber: 3,
        nextPatchNumber: 4,
      ),
    );
    expect(client.updateCalls, 1);
  });

  test('확인 제한 시간을 넘기면 오류 결과로 종료한다', () async {
    final client = FakeShorebirdUpdateClient(
      checkCompleter: Completer<shorebird.UpdateStatus>(),
    );
    final coordinator = ShorebirdUpdateCoordinator(
      clientFactory: () => client,
      checkTimeout: const Duration(milliseconds: 1),
    );

    final result = await coordinator.run();

    expect(result.state, ShorebirdRunState.error);
  });

  test('제한 시간이 지난 네이티브 호출이 끝나기 전에는 새 호출을 시작하지 않는다', () async {
    final completer = Completer<shorebird.UpdateStatus>();
    final client = FakeShorebirdUpdateClient(checkCompleter: completer);
    final coordinator = ShorebirdUpdateCoordinator(
      clientFactory: () => client,
      checkTimeout: const Duration(milliseconds: 1),
    );

    expect((await coordinator.run()).state, ShorebirdRunState.error);
    expect((await coordinator.run()).state, ShorebirdRunState.error);
    expect(client.checkCalls, 1);

    completer.complete(shorebird.UpdateStatus.upToDate);
  });

  test('재시작 필요 결과는 기존 재시작 대기 이벤트로 매핑된다', () {
    const result = ShorebirdRunResult.restartRequired(nextPatchNumber: 4);

    expect(
      ShorebirdUtils.eventForResult(result),
      ShorebirdPatchEvent.restartPending,
    );
  });
}

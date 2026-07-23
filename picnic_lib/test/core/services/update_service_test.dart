import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/services/update_service.dart';
import 'package:picnic_lib/presentation/providers/check_update_provider.dart';

void main() {
  test('시작 업데이트 확인은 스토어 버전 결과만 반환한다', () async {
    const expected = UpdateInfo(
      status: UpdateStatus.upToDate,
      currentVersion: '1.0.0',
      latestVersion: '1.0.0',
      forceVersion: '1.0.0',
    );
    var calls = 0;

    final result = await checkForUpdates(
      null,
      storeUpdateCheck: () async {
        calls++;
        return expected;
      },
    );

    expect(result, same(expected));
    expect(calls, 1);
  });
}

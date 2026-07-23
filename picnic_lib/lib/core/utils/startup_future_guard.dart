import 'dart:async';

Future<void> waitForNonCriticalStartup(
  Future<void> work, {
  required Duration timeout,
  required void Function() onTimeout,
}) async {
  await work.timeout(
    timeout,
    onTimeout: () {
      onTimeout();
    },
  );
}

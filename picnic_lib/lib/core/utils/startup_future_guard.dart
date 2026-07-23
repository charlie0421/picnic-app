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

Future<T> waitForStartupValue<T>(
  Future<T> work, {
  required Duration timeout,
  required T fallback,
  required void Function() onTimeout,
}) async {
  return work.timeout(
    timeout,
    onTimeout: () {
      onTimeout();
      return fallback;
    },
  );
}

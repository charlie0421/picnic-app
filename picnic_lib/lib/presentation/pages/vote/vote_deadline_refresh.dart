import 'dart:math';

import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final voteDeadlineClockProvider = Provider<Clock>((ref) => const Clock());

/// Sample once per deadline, in milliseconds so clients do not form five bursts.
final voteDeadlineRefreshDelayProvider = Provider<Duration Function()>((ref) {
  final random = Random();
  return () => Duration(milliseconds: 1000 + random.nextInt(4001));
});

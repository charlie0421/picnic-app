import 'dart:math';

import 'package:clock/clock.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final voteDeadlineClockProvider = Provider<Clock>((ref) => const Clock());

/// Sample once per deadline, in milliseconds so clients do not form five bursts.
final voteDeadlineRefreshDelayProvider = Provider<Duration Function()>((ref) {
  final random = Random();
  return () => Duration(milliseconds: 1000 + random.nextInt(4001));
});

/// How long after the deadline the detail page keeps polling totals.
///
/// The last votes reach `vote_item.vote_total` after the deadline: the server
/// tallies them from a queue, about a second behind and later still on the
/// hour (seen up to ~5s late). The delayed final refresh can run before that,
/// and a device clock can run ahead of the server. Past this window the
/// totals are final.
const voteEndedPollGrace = Duration(minutes: 1);

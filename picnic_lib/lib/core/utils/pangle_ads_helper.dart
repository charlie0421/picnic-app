import 'package:flutter/foundation.dart';

/// Pure helper methods for PangleAds logic, extracted for testability.
class PangleAdsHelper {
  PangleAdsHelper._();

  /// Ad event types recognized by the Pangle event handler.
  static const adShownEvent = 'onAdShown';
  static const adClickedEvent = 'onAdClicked';
  static const adDismissedEvent = 'onAdDismissed';
  static const adClosedEvent = 'onAdClosed';
  static const rewardEarnedEvent = 'onRewardEarned';
  static const rewardFailedEvent = 'onRewardFailed';

  /// Classifies a method call name into a canonical event type.
  ///
  /// Returns one of the event constants above, or `null` if unrecognized.
  static String? classifyEvent(String methodName) {
    switch (methodName) {
      case adShownEvent:
        return adShownEvent;
      case adClickedEvent:
        return adClickedEvent;
      case adDismissedEvent:
      case adClosedEvent:
        return adDismissedEvent;
      case rewardEarnedEvent:
        return rewardEarnedEvent;
      case rewardFailedEvent:
        return rewardFailedEvent;
      default:
        return null;
    }
  }

  /// Whether an unrecognized event name should be treated as an ad-related
  /// event (and thus trigger a profile refresh).
  @visibleForTesting
  static bool isUnknownAdEvent(String methodName) {
    return methodName.toLowerCase().contains('ad');
  }

  /// Extracts a timestamp value from event arguments.
  ///
  /// Falls back to the current time (in seconds) when the arguments map does
  /// not contain a `timestamp` key.
  @visibleForTesting
  static dynamic extractTimestamp(Map<String, dynamic>? arguments) {
    if (arguments != null && arguments.containsKey('timestamp')) {
      return arguments['timestamp'];
    }
    return DateTime.now().millisecondsSinceEpoch / 1000;
  }

  /// Parses reward-earned arguments into a typed map.
  ///
  /// Returns `null` if [arguments] is not a valid map.
  static Map<String, dynamic>? parseRewardArgs(dynamic arguments) {
    if (arguments is Map) {
      try {
        return Map<String, dynamic>.from(arguments);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  /// Extracts the error message from reward-failed arguments.
  ///
  /// Returns a default Korean error string when the message is absent.
  static String extractErrorMessage(dynamic arguments) {
    if (arguments is Map) {
      try {
        final args = Map<String, dynamic>.from(arguments);
        return args['errorMessage'] as String? ?? '\uc54c \uc218 \uc5c6\ub294 \uc624\ub958';
      } catch (_) {
        return '\uc54c \uc218 \uc5c6\ub294 \uc624\ub958';
      }
    }
    return '\uc54c \uc218 \uc5c6\ub294 \uc624\ub958';
  }

  /// Whether a profile refresh callback should be invoked for the given event.
  @visibleForTesting
  static bool shouldRefreshProfile(String methodName) {
    final classified = classifyEvent(methodName);
    if (classified == adDismissedEvent ||
        classified == rewardEarnedEvent ||
        classified == rewardFailedEvent) {
      return true;
    }
    // Unrecognized but ad-related
    if (classified == null && isUnknownAdEvent(methodName)) {
      return true;
    }
    return false;
  }
}

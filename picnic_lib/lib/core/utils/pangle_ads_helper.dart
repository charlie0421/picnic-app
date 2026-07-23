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
        return args['errorMessage'] as String? ??
            '\uc54c \uc218 \uc5c6\ub294 \uc624\ub958';
      } catch (_) {
        return '\uc54c \uc218 \uc5c6\ub294 \uc624\ub958';
      }
    }
    return '\uc54c \uc218 \uc5c6\ub294 \uc624\ub958';
  }
}

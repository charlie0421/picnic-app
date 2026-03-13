import 'dart:convert';

import 'package:flutter/foundation.dart' show visibleForTesting;

/// Pure-logic helpers extracted from [PostWriteBody] for testability.
class PostWriteBodyHelper {
  const PostWriteBodyHelper._();

  /// Returns `true` when [text] contains at least one non-whitespace character.
  @visibleForTesting
  static bool isTitleValid(String text) {
    return text.trim().isNotEmpty;
  }

  /// Calculates the editor height depending on the platform and keyboard state.
  ///
  /// [screenHeight] is the full screen height from `MediaQuery`.
  /// [keyboardHeight] is the current software-keyboard height (0 on web).
  /// [isKeyboardVisible] indicates whether the keyboard is currently shown.
  /// [isWeb] indicates whether the app is running on the web platform.
  ///
  /// The base height is `screenHeight - 420`.  When the keyboard is visible on
  /// a non-web platform the keyboard height is subtracted (with a +40 offset).
  @visibleForTesting
  static double calculateEditorHeight({
    required double screenHeight,
    required double keyboardHeight,
    required bool isKeyboardVisible,
    required bool isWeb,
  }) {
    final double containerSize = screenHeight - 420;
    if (!isWeb && isKeyboardVisible) {
      return containerSize - keyboardHeight + 40;
    }
    return containerSize;
  }

  /// Returns `true` when the given [featuresList] contains the [feature].
  ///
  /// Safely handles a `null` features list by returning `false`.
  @visibleForTesting
  static bool isBoardFeatureEnabled(List<String>? featuresList, String feature) {
    return featuresList != null && featuresList.contains(feature);
  }

  /// Encodes link data into the JSON format expected by the link embed builder.
  ///
  /// Returns `null` when [url] is null or empty.
  @visibleForTesting
  static String? encodeLinkEmbedData({String? name, required String? url}) {
    if (url == null || url.isEmpty) return null;
    return jsonEncode({'name': name, 'url': url});
  }

  /// Returns `true` when the YouTube dialog result is non-null and non-empty,
  /// meaning it should be inserted into the editor.
  @visibleForTesting
  static bool isYouTubeResultValid(String? result) {
    return result != null && result.isNotEmpty;
  }

  /// Returns `true` when the link dialog result contains a non-empty URL.
  @visibleForTesting
  static bool isLinkResultValid(Map<String, String>? result) {
    return result != null && result['url'] != null && result['url']!.isNotEmpty;
  }

  /// Finds the index of a local-image embed whose data equals [localPath]
  /// inside a list of Quill delta operations.
  ///
  /// Each operation is expected to be a `Map<String, dynamic>` with a `data`
  /// field.  Returns `-1` when no match is found.
  @visibleForTesting
  static int findLocalImageIndex(
    List<Map<String, dynamic>> operations,
    String localPath,
  ) {
    for (int i = 0; i < operations.length; i++) {
      final opData = operations[i]['data'];
      if (opData is Map<String, dynamic> && opData['local-image'] == localPath) {
        return i;
      }
    }
    return -1;
  }

  /// Computes the keyboard height, returning 0 when the listener has not been
  /// initialized or when running on the web platform.
  @visibleForTesting
  static double effectiveKeyboardHeight({
    required bool isListenerInitialized,
    required bool isWeb,
    required double rawHeight,
  }) {
    if (!isListenerInitialized || isWeb) {
      return 0;
    }
    return rawHeight;
  }
}

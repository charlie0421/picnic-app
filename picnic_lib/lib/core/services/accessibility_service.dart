import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Accessibility service for enhanced screen reader compatibility
class AccessibilityService {
  static final AccessibilityService _instance =
      AccessibilityService._internal();
  factory AccessibilityService() => _instance;
  AccessibilityService._internal();

  static const String _prefixKey = 'accessibility_';
  bool _isEnabled = false;
  bool _isHighContrastEnabled = false;
  bool _isLargeTextEnabled = false;
  bool _isReduceMotionEnabled = false;
  double _textScaleFactor = 1.0;

  /// Initialize accessibility service
  Future<void> initialize() async {
    try {
      await _loadAccessibilitySettings();
      _setupSystemAccessibilityListeners();
      debugPrint('AccessibilityService initialized');
    } catch (e) {
      debugPrint('Failed to initialize AccessibilityService: $e');
    }
  }

  /// Load accessibility settings from preferences
  Future<void> _loadAccessibilitySettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isEnabled = prefs.getBool('${_prefixKey}enabled') ?? false;
    _isHighContrastEnabled =
        prefs.getBool('${_prefixKey}high_contrast') ?? false;
    _isLargeTextEnabled = prefs.getBool('${_prefixKey}large_text') ?? false;
    _isReduceMotionEnabled =
        prefs.getBool('${_prefixKey}reduce_motion') ?? false;
    _textScaleFactor = prefs.getDouble('${_prefixKey}text_scale') ?? 1.0;
  }

  /// Setup system accessibility listeners
  void _setupSystemAccessibilityListeners() {
    // Listen for system accessibility changes
    WidgetsBinding.instance.platformDispatcher.onAccessibilityFeaturesChanged =
        () {
      _updateSystemAccessibilityFeatures();
    };

    _updateSystemAccessibilityFeatures();
  }

  /// Update system accessibility features
  void _updateSystemAccessibilityFeatures() {
    final features =
        WidgetsBinding.instance.platformDispatcher.accessibilityFeatures;

    // Update based on system settings
    if (features.boldText != _isLargeTextEnabled) {
      _isLargeTextEnabled = features.boldText;
      _saveAccessibilitySetting('large_text', _isLargeTextEnabled);
    }

    if (features.reduceMotion != _isReduceMotionEnabled) {
      _isReduceMotionEnabled = features.reduceMotion;
      _saveAccessibilitySetting('reduce_motion', _isReduceMotionEnabled);
    }

    if (features.highContrast != _isHighContrastEnabled) {
      _isHighContrastEnabled = features.highContrast;
      _saveAccessibilitySetting('high_contrast', _isHighContrastEnabled);
    }
  }

  /// Save accessibility setting
  Future<void> _saveAccessibilitySetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool('$_prefixKey$key', value);
    } else if (value is double) {
      await prefs.setDouble('$_prefixKey$key', value);
    }
  }

  /// Enable accessibility features
  Future<void> enableAccessibility() async {
    _isEnabled = true;
    await _saveAccessibilitySetting('enabled', true);
    debugPrint('Accessibility enabled');
  }

  /// Disable accessibility features
  Future<void> disableAccessibility() async {
    _isEnabled = false;
    await _saveAccessibilitySetting('enabled', false);
    debugPrint('Accessibility disabled');
  }

  /// Set text scale factor
  Future<void> setTextScaleFactor(double factor) async {
    _textScaleFactor = factor.clamp(0.8, 2.0);
    await _saveAccessibilitySetting('text_scale', _textScaleFactor);
    debugPrint('Text scale factor set to: $_textScaleFactor');
  }

  /// Toggle high contrast mode
  Future<void> toggleHighContrast() async {
    _isHighContrastEnabled = !_isHighContrastEnabled;
    await _saveAccessibilitySetting('high_contrast', _isHighContrastEnabled);
    debugPrint('High contrast: $_isHighContrastEnabled');
  }

  /// Toggle reduce motion
  Future<void> toggleReduceMotion() async {
    _isReduceMotionEnabled = !_isReduceMotionEnabled;
    await _saveAccessibilitySetting('reduce_motion', _isReduceMotionEnabled);
    debugPrint('Reduce motion: $_isReduceMotionEnabled');
  }

  /// Generate semantic label for UI elements
  String generateSemanticLabel({
    required String text,
    String? hint,
    String? value,
    bool isButton = false,
    bool isSelected = false,
    bool isEnabled = true,
  }) {
    final buffer = StringBuffer(text);

    if (value != null && value.isNotEmpty) {
      buffer.write(', $value');
    }

    if (isButton) {
      buffer.write(', button');
    }

    if (isSelected) {
      buffer.write(', selected');
    }

    if (!isEnabled) {
      buffer.write(', disabled');
    }

    if (hint != null && hint.isNotEmpty) {
      buffer.write(', $hint');
    }

    return buffer.toString();
  }

  /// Create accessible semantics for complex widgets
  Semantics createAccessibleSemantics({
    required Widget child,
    required String label,
    String? hint,
    String? value,
    VoidCallback? onTap,
    bool isButton = false,
    bool isSelected = false,
    bool isEnabled = true,
    bool excludeSemantics = false,
  }) {
    return Semantics(
      label: generateSemanticLabel(
        text: label,
        hint: hint,
        value: value,
        isButton: isButton,
        isSelected: isSelected,
        isEnabled: isEnabled,
      ),
      hint: hint,
      value: value,
      button: isButton,
      selected: isSelected,
      enabled: isEnabled,
      excludeSemantics: excludeSemantics,
      onTap: onTap,
      child: child,
    );
  }

  /// Create accessible button
  Widget createAccessibleButton({
    required Widget child,
    required String label,
    String? hint,
    required VoidCallback onPressed,
    bool isEnabled = true,
  }) {
    return createAccessibleSemantics(
      label: label,
      hint: hint ?? 'Double tap to activate',
      isButton: true,
      isEnabled: isEnabled,
      onTap: isEnabled ? onPressed : null,
      child: child,
    );
  }

  /// Create accessible text field
  Widget createAccessibleTextField({
    required Widget child,
    required String label,
    String? hint,
    String? value,
    bool isRequired = false,
  }) {
    final semanticHint = StringBuffer();
    if (hint != null) semanticHint.write(hint);
    if (isRequired) {
      if (semanticHint.isNotEmpty) semanticHint.write(', ');
      semanticHint.write('required');
    }

    return createAccessibleSemantics(
      label: label,
      hint: semanticHint.toString(),
      value: value,
      child: child,
    );
  }

  /// Create accessible list item
  Widget createAccessibleListItem({
    required Widget child,
    required String label,
    String? subtitle,
    int? index,
    int? totalCount,
    VoidCallback? onTap,
  }) {
    final buffer = StringBuffer(label);

    if (subtitle != null && subtitle.isNotEmpty) {
      buffer.write(', $subtitle');
    }

    if (index != null && totalCount != null) {
      buffer.write(', item ${index + 1} of $totalCount');
    }

    return createAccessibleSemantics(
      label: buffer.toString(),
      onTap: onTap,
      child: child,
    );
  }

  /// Create accessible image
  Widget createAccessibleImage({
    required Widget child,
    required String label,
    String? description,
    bool isDecorative = false,
  }) {
    if (isDecorative) {
      return ExcludeSemantics(child: child);
    }

    return createAccessibleSemantics(
      label: label,
      hint: description,
      child: child,
    );
  }

  /// Create accessible navigation item
  Widget createAccessibleNavItem({
    required Widget child,
    required String label,
    bool isSelected = false,
    int? index,
    int? totalCount,
    VoidCallback? onTap,
  }) {
    final buffer = StringBuffer(label);

    if (index != null && totalCount != null) {
      buffer.write(', tab ${index + 1} of $totalCount');
    }

    return createAccessibleSemantics(
      label: buffer.toString(),
      isButton: true,
      isSelected: isSelected,
      onTap: onTap,
      child: child,
    );
  }

  /// Announce message to screen reader
  void announceMessage(String message, {bool polite = true}) {
    SemanticsService.announce(
      message,
      polite
          ? Directionality.of(WidgetsBinding.instance.rootElement!)
          : TextDirection.ltr,
    );
  }

  /// Provide haptic feedback
  void provideHapticFeedback() {
    if (_isEnabled) {
      HapticFeedback.lightImpact();
    }
  }

  /// Get accessible colors based on contrast settings
  AccessibleColors getAccessibleColors(BuildContext context) {
    final theme = Theme.of(context);

    if (_isHighContrastEnabled) {
      return AccessibleColors.highContrast(theme.brightness);
    }

    return AccessibleColors.standard(theme);
  }

  /// Get accessible text theme
  TextTheme getAccessibleTextTheme(BuildContext context) {
    final theme = Theme.of(context);
    final baseTextTheme = theme.textTheme;

    if (_isLargeTextEnabled || _textScaleFactor != 1.0) {
      return baseTextTheme.apply(
        fontSizeFactor: _textScaleFactor,
      );
    }

    return baseTextTheme;
  }

  /// Check if animations should be reduced
  bool shouldReduceMotion() {
    return _isReduceMotionEnabled;
  }

  /// Get animation duration based on motion settings
  Duration getAnimationDuration(Duration defaultDuration) {
    if (_isReduceMotionEnabled) {
      return Duration.zero;
    }
    return defaultDuration;
  }

  /// Getters for accessibility state
  bool get isEnabled => _isEnabled;
  bool get isHighContrastEnabled => _isHighContrastEnabled;
  bool get isLargeTextEnabled => _isLargeTextEnabled;
  bool get isReduceMotionEnabled => _isReduceMotionEnabled;
  double get textScaleFactor => _textScaleFactor;
}

/// Accessible colors for high contrast mode
class AccessibleColors {
  final Color primary;
  final Color onPrimary;
  final Color secondary;
  final Color onSecondary;
  final Color background;
  final Color onBackground;
  final Color surface;
  final Color onSurface;
  final Color error;
  final Color onError;

  const AccessibleColors({
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.onSecondary,
    required this.background,
    required this.onBackground,
    required this.surface,
    required this.onSurface,
    required this.error,
    required this.onError,
  });

  factory AccessibleColors.standard(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    return AccessibleColors(
      primary: colorScheme.primary,
      onPrimary: colorScheme.onPrimary,
      secondary: colorScheme.secondary,
      onSecondary: colorScheme.onSecondary,
      background: colorScheme.background,
      onBackground: colorScheme.onBackground,
      surface: colorScheme.surface,
      onSurface: colorScheme.onSurface,
      error: colorScheme.error,
      onError: colorScheme.onError,
    );
  }

  factory AccessibleColors.highContrast(Brightness brightness) {
    if (brightness == Brightness.dark) {
      return const AccessibleColors(
        primary: Colors.white,
        onPrimary: Colors.black,
        secondary: Color(0xFFFFD700), // Gold
        onSecondary: Colors.black,
        background: Colors.black,
        onBackground: Colors.white,
        surface: Color(0xFF1A1A1A),
        onSurface: Colors.white,
        error: Color(0xFFFF6B6B),
        onError: Colors.black,
      );
    } else {
      return const AccessibleColors(
        primary: Colors.black,
        onPrimary: Colors.white,
        secondary: Color(0xFF0066CC), // Dark blue
        onSecondary: Colors.white,
        background: Colors.white,
        onBackground: Colors.black,
        surface: Color(0xFFF5F5F5),
        onSurface: Colors.black,
        error: Color(0xFFCC0000),
        onError: Colors.white,
      );
    }
  }
}

/// Accessibility helper widgets
class AccessibilityWidgets {
  /// Screen reader only text
  static Widget screenReaderOnly(String text) {
    return Semantics(
      label: text,
      child: const SizedBox.shrink(),
    );
  }

  /// Skip link for navigation
  static Widget skipLink({
    required String label,
    required VoidCallback onPressed,
  }) {
    return Positioned(
      top: -100,
      left: 0,
      child: Focus(
        onFocusChange: (hasFocus) {
          // Move skip link into view when focused
        },
        child: ElevatedButton(
          onPressed: onPressed,
          child: Text(label),
        ),
      ),
    );
  }

  /// Focus trap for modal dialogs
  static Widget focusTrap({
    required Widget child,
    bool trapFocus = true,
  }) {
    if (!trapFocus) return child;

    return FocusScope(
      child: child,
    );
  }

  /// Accessible loading indicator
  static Widget loadingIndicator({
    String? label,
    double? value,
  }) {
    return Semantics(
      label: label ?? 'Loading',
      value: value != null ? '${(value * 100).round()}%' : null,
      child: CircularProgressIndicator(value: value),
    );
  }

  /// Accessible alert dialog
  static Widget alertDialog({
    required String title,
    required String content,
    List<Widget>? actions,
  }) {
    return Semantics(
      label: 'Alert dialog',
      child: AlertDialog(
        title: Semantics(
          label: 'Alert title',
          child: Text(title),
        ),
        content: Semantics(
          label: 'Alert content',
          child: Text(content),
        ),
        actions: actions,
      ),
    );
  }
}

/// Focus management helper
class FocusManager {
  static final FocusManager _instance = FocusManager._internal();
  factory FocusManager() => _instance;
  FocusManager._internal();

  final Map<String, FocusNode> _focusNodes = {};

  /// Get or create focus node
  FocusNode getFocusNode(String key) {
    return _focusNodes[key] ??= FocusNode();
  }

  /// Move focus to next element
  void focusNext(BuildContext context) {
    FocusScope.of(context).nextFocus();
  }

  /// Move focus to previous element
  void focusPrevious(BuildContext context) {
    FocusScope.of(context).previousFocus();
  }

  /// Request focus for specific element
  void requestFocus(String key) {
    final node = _focusNodes[key];
    if (node != null) {
      node.requestFocus();
    }
  }

  /// Clear focus
  void clearFocus(BuildContext context) {
    FocusScope.of(context).unfocus();
  }

  /// Dispose all focus nodes
  void dispose() {
    for (final node in _focusNodes.values) {
      node.dispose();
    }
    _focusNodes.clear();
  }
}

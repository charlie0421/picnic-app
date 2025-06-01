import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// High contrast mode service for enhanced visual accessibility
class HighContrastService {
  static final HighContrastService _instance = HighContrastService._internal();
  factory HighContrastService() => _instance;
  HighContrastService._internal();

  static const String _prefixKey = 'high_contrast_';
  
  bool _isEnabled = false;
  HighContrastLevel _contrastLevel = HighContrastLevel.standard;
  bool _invertColors = false;
  bool _reduceTransparency = false;
  bool _increaseBorderWidth = false;
  double _borderMultiplier = 1.5;
  bool _useCustomColors = false;
  HighContrastColorSet _customColors = HighContrastColorSet.defaultSet();

  /// Initialize high contrast service
  Future<void> initialize() async {
    try {
      await _loadSettings();
      _setupSystemListeners();
      debugPrint('HighContrastService initialized');
    } catch (e) {
      debugPrint('Failed to initialize HighContrastService: $e');
    }
  }

  /// Load high contrast settings
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isEnabled = prefs.getBool('${_prefixKey}enabled') ?? false;
    _invertColors = prefs.getBool('${_prefixKey}invert_colors') ?? false;
    _reduceTransparency = prefs.getBool('${_prefixKey}reduce_transparency') ?? false;
    _increaseBorderWidth = prefs.getBool('${_prefixKey}increase_borders') ?? false;
    _borderMultiplier = prefs.getDouble('${_prefixKey}border_multiplier') ?? 1.5;
    _useCustomColors = prefs.getBool('${_prefixKey}use_custom_colors') ?? false;
    
    final contrastLevelIndex = prefs.getInt('${_prefixKey}contrast_level') ?? 0;
    _contrastLevel = HighContrastLevel.values[contrastLevelIndex.clamp(0, HighContrastLevel.values.length - 1)];
    
    await _loadCustomColors();
  }

  /// Load custom colors
  Future<void> _loadCustomColors() async {
    final prefs = await SharedPreferences.getInstance();
    
    final primaryValue = prefs.getInt('${_prefixKey}custom_primary');
    final onPrimaryValue = prefs.getInt('${_prefixKey}custom_on_primary');
    final backgroundValue = prefs.getInt('${_prefixKey}custom_background');
    final onBackgroundValue = prefs.getInt('${_prefixKey}custom_on_background');
    final surfaceValue = prefs.getInt('${_prefixKey}custom_surface');
    final onSurfaceValue = prefs.getInt('${_prefixKey}custom_on_surface');
    final errorValue = prefs.getInt('${_prefixKey}custom_error');
    final onErrorValue = prefs.getInt('${_prefixKey}custom_on_error');

    if (primaryValue != null && onPrimaryValue != null && 
        backgroundValue != null && onBackgroundValue != null &&
        surfaceValue != null && onSurfaceValue != null &&
        errorValue != null && onErrorValue != null) {
      _customColors = HighContrastColorSet(
        primary: Color(primaryValue),
        onPrimary: Color(onPrimaryValue),
        background: Color(backgroundValue),
        onBackground: Color(onBackgroundValue),
        surface: Color(surfaceValue),
        onSurface: Color(onSurfaceValue),
        error: Color(errorValue),
        onError: Color(onErrorValue),
      );
    }
  }

  /// Save high contrast settings
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('${_prefixKey}enabled', _isEnabled);
    await prefs.setInt('${_prefixKey}contrast_level', _contrastLevel.index);
    await prefs.setBool('${_prefixKey}invert_colors', _invertColors);
    await prefs.setBool('${_prefixKey}reduce_transparency', _reduceTransparency);
    await prefs.setBool('${_prefixKey}increase_borders', _increaseBorderWidth);
    await prefs.setDouble('${_prefixKey}border_multiplier', _borderMultiplier);
    await prefs.setBool('${_prefixKey}use_custom_colors', _useCustomColors);
    
    await _saveCustomColors();
  }

  /// Save custom colors
  Future<void> _saveCustomColors() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('${_prefixKey}custom_primary', _customColors.primary.value);
    await prefs.setInt('${_prefixKey}custom_on_primary', _customColors.onPrimary.value);
    await prefs.setInt('${_prefixKey}custom_background', _customColors.background.value);
    await prefs.setInt('${_prefixKey}custom_on_background', _customColors.onBackground.value);
    await prefs.setInt('${_prefixKey}custom_surface', _customColors.surface.value);
    await prefs.setInt('${_prefixKey}custom_on_surface', _customColors.onSurface.value);
    await prefs.setInt('${_prefixKey}custom_error', _customColors.error.value);
    await prefs.setInt('${_prefixKey}custom_on_error', _customColors.onError.value);
  }

  /// Setup system accessibility listeners
  void _setupSystemListeners() {
    WidgetsBinding.instance.platformDispatcher.onAccessibilityFeaturesChanged = () {
      _updateFromSystemSettings();
    };
    _updateFromSystemSettings();
  }

  /// Update settings from system accessibility features
  void _updateFromSystemSettings() {
    final features = WidgetsBinding.instance.platformDispatcher.accessibilityFeatures;
    
    if (features.highContrast != _isEnabled) {
      _isEnabled = features.highContrast;
      _saveSettings();
      debugPrint('High contrast updated from system: $_isEnabled');
    }
    
    if (features.reduceMotion) {
      // Reduce transparency when reduce motion is enabled
      _reduceTransparency = true;
      _saveSettings();
    }
  }

  /// Enable high contrast mode
  Future<void> enable() async {
    _isEnabled = true;
    await _saveSettings();
    debugPrint('High contrast mode enabled');
  }

  /// Disable high contrast mode
  Future<void> disable() async {
    _isEnabled = false;
    await _saveSettings();
    debugPrint('High contrast mode disabled');
  }

  /// Set contrast level
  Future<void> setContrastLevel(HighContrastLevel level) async {
    _contrastLevel = level;
    await _saveSettings();
    debugPrint('Contrast level set to: $level');
  }

  /// Toggle color inversion
  Future<void> toggleInvertColors() async {
    _invertColors = !_invertColors;
    await _saveSettings();
    debugPrint('Invert colors: $_invertColors');
  }

  /// Toggle transparency reduction
  Future<void> toggleReduceTransparency() async {
    _reduceTransparency = !_reduceTransparency;
    await _saveSettings();
    debugPrint('Reduce transparency: $_reduceTransparency');
  }

  /// Toggle border width increase
  Future<void> toggleIncreaseBorderWidth() async {
    _increaseBorderWidth = !_increaseBorderWidth;
    await _saveSettings();
    debugPrint('Increase border width: $_increaseBorderWidth');
  }

  /// Set border multiplier
  Future<void> setBorderMultiplier(double multiplier) async {
    _borderMultiplier = multiplier.clamp(1.0, 3.0);
    await _saveSettings();
    debugPrint('Border multiplier set to: $_borderMultiplier');
  }

  /// Set custom colors
  Future<void> setCustomColors(HighContrastColorSet colors) async {
    _customColors = colors;
    await _saveCustomColors();
    debugPrint('Custom colors updated');
  }

  /// Toggle use custom colors
  Future<void> toggleUseCustomColors() async {
    _useCustomColors = !_useCustomColors;
    await _saveSettings();
    debugPrint('Use custom colors: $_useCustomColors');
  }

  /// Get high contrast theme data
  ThemeData getHighContrastTheme(ThemeData baseTheme) {
    if (!_isEnabled) return baseTheme;

    final colorScheme = getHighContrastColorScheme(baseTheme.colorScheme);
    
    return baseTheme.copyWith(
      colorScheme: colorScheme,
      brightness: colorScheme.brightness,
      primaryColor: colorScheme.primary,
      scaffoldBackgroundColor: colorScheme.background,
      cardColor: colorScheme.surface,
      dividerColor: colorScheme.onSurface.withOpacity(0.8),
      iconTheme: IconThemeData(
        color: colorScheme.onSurface,
        size: baseTheme.iconTheme.size,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: _increaseBorderWidth ? 4.0 : 0.0,
        shadowColor: colorScheme.onSurface.withOpacity(0.3),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          side: _increaseBorderWidth 
              ? BorderSide(
                  color: colorScheme.onPrimary,
                  width: 2.0 * _borderMultiplier,
                )
              : null,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(
            color: colorScheme.primary,
            width: (_increaseBorderWidth ? 2.0 : 1.0) * _borderMultiplier,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        border: OutlineInputBorder(
          borderSide: BorderSide(
            color: colorScheme.onSurface,
            width: (_increaseBorderWidth ? 2.0 : 1.0) * _borderMultiplier,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: colorScheme.onSurface.withOpacity(0.7),
            width: (_increaseBorderWidth ? 2.0 : 1.0) * _borderMultiplier,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: colorScheme.primary,
            width: 2.0 * _borderMultiplier,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: colorScheme.error,
            width: 2.0 * _borderMultiplier,
          ),
        ),
        labelStyle: TextStyle(color: colorScheme.onSurface),
        hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.6)),
      ),
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        shadowColor: colorScheme.onSurface.withOpacity(0.3),
        elevation: _increaseBorderWidth ? 4.0 : 1.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4.0),
          side: _increaseBorderWidth
              ? BorderSide(
                  color: colorScheme.onSurface.withOpacity(0.3),
                  width: 1.0 * _borderMultiplier,
                )
              : BorderSide.none,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
          side: _increaseBorderWidth
              ? BorderSide(
                  color: colorScheme.onSurface,
                  width: 2.0 * _borderMultiplier,
                )
              : BorderSide.none,
        ),
      ),
    );
  }

  /// Get high contrast color scheme
  ColorScheme getHighContrastColorScheme(ColorScheme baseScheme) {
    if (!_isEnabled) return baseScheme;

    if (_useCustomColors) {
      return ColorScheme(
        brightness: baseScheme.brightness,
        primary: _customColors.primary,
        onPrimary: _customColors.onPrimary,
        secondary: _customColors.primary,
        onSecondary: _customColors.onPrimary,
        error: _customColors.error,
        onError: _customColors.onError,
        background: _customColors.background,
        onBackground: _customColors.onBackground,
        surface: _customColors.surface,
        onSurface: _customColors.onSurface,
      );
    }

    return _getPresetColorScheme(baseScheme.brightness);
  }

  /// Get preset color scheme based on contrast level
  ColorScheme _getPresetColorScheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    switch (_contrastLevel) {
      case HighContrastLevel.standard:
        return _getStandardContrastColors(isDark);
      case HighContrastLevel.high:
        return _getHighContrastColors(isDark);
      case HighContrastLevel.maximum:
        return _getMaximumContrastColors(isDark);
    }
  }

  /// Get standard contrast colors
  ColorScheme _getStandardContrastColors(bool isDark) {
    if (_invertColors) isDark = !isDark;

    if (isDark) {
      return const ColorScheme.dark(
        primary: Color(0xFFBB86FC),
        onPrimary: Color(0xFF000000),
        secondary: Color(0xFF03DAC6),
        onSecondary: Color(0xFF000000),
        background: Color(0xFF121212),
        onBackground: Color(0xFFFFFFFF),
        surface: Color(0xFF1E1E1E),
        onSurface: Color(0xFFFFFFFF),
        error: Color(0xFFCF6679),
        onError: Color(0xFF000000),
      );
    } else {
      return const ColorScheme.light(
        primary: Color(0xFF6200EE),
        onPrimary: Color(0xFFFFFFFF),
        secondary: Color(0xFF03DAC6),
        onSecondary: Color(0xFF000000),
        background: Color(0xFFFFFFFF),
        onBackground: Color(0xFF000000),
        surface: Color(0xFFFFFFFF),
        onSurface: Color(0xFF000000),
        error: Color(0xFFB00020),
        onError: Color(0xFFFFFFFF),
      );
    }
  }

  /// Get high contrast colors
  ColorScheme _getHighContrastColors(bool isDark) {
    if (_invertColors) isDark = !isDark;

    if (isDark) {
      return const ColorScheme.dark(
        primary: Color(0xFFFFFFFF),
        onPrimary: Color(0xFF000000),
        secondary: Color(0xFFFFD700),
        onSecondary: Color(0xFF000000),
        background: Color(0xFF000000),
        onBackground: Color(0xFFFFFFFF),
        surface: Color(0xFF1A1A1A),
        onSurface: Color(0xFFFFFFFF),
        error: Color(0xFFFF6B6B),
        onError: Color(0xFF000000),
      );
    } else {
      return const ColorScheme.light(
        primary: Color(0xFF000000),
        onPrimary: Color(0xFFFFFFFF),
        secondary: Color(0xFF0066CC),
        onSecondary: Color(0xFFFFFFFF),
        background: Color(0xFFFFFFFF),
        onBackground: Color(0xFF000000),
        surface: Color(0xFFF5F5F5),
        onSurface: Color(0xFF000000),
        error: Color(0xFFCC0000),
        onError: Color(0xFFFFFFFF),
      );
    }
  }

  /// Get maximum contrast colors
  ColorScheme _getMaximumContrastColors(bool isDark) {
    if (_invertColors) isDark = !isDark;

    if (isDark) {
      return const ColorScheme.dark(
        primary: Color(0xFFFFFFFF),
        onPrimary: Color(0xFF000000),
        secondary: Color(0xFFFFFF00),
        onSecondary: Color(0xFF000000),
        background: Color(0xFF000000),
        onBackground: Color(0xFFFFFFFF),
        surface: Color(0xFF000000),
        onSurface: Color(0xFFFFFFFF),
        error: Color(0xFFFF0000),
        onError: Color(0xFF000000),
      );
    } else {
      return const ColorScheme.light(
        primary: Color(0xFF000000),
        onPrimary: Color(0xFFFFFFFF),
        secondary: Color(0xFF000000),
        onSecondary: Color(0xFFFFFFFF),
        background: Color(0xFFFFFFFF),
        onBackground: Color(0xFF000000),
        surface: Color(0xFFFFFFFF),
        onSurface: Color(0xFF000000),
        error: Color(0xFF000000),
        onError: Color(0xFFFFFFFF),
      );
    }
  }

  /// Create high contrast widget
  Widget createHighContrastWidget({
    required Widget child,
    bool useBackground = true,
    bool useBorder = true,
  }) {
    if (!_isEnabled) return child;

    final context = WidgetsBinding.instance.rootElement;
    if (context == null) return child;

    final theme = Theme.of(context);
    final colorScheme = getHighContrastColorScheme(theme.colorScheme);

    Widget result = child;

    if (useBackground) {
      result = Container(
        color: colorScheme.surface,
        child: result,
      );
    }

    if (useBorder && _increaseBorderWidth) {
      result = Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: colorScheme.onSurface,
            width: 1.0 * _borderMultiplier,
          ),
        ),
        child: result,
      );
    }

    if (_reduceTransparency) {
      // Remove any opacity from the widget tree
      result = _removeTransparency(result);
    }

    return result;
  }

  /// Remove transparency from widget
  Widget _removeTransparency(Widget widget) {
    // This is a simplified implementation
    // In a real implementation, you would need to traverse the widget tree
    // and modify any widgets that use opacity or transparency
    return widget;
  }

  /// Get high contrast status
  HighContrastStatus getStatus() {
    return HighContrastStatus(
      isEnabled: _isEnabled,
      contrastLevel: _contrastLevel,
      invertColors: _invertColors,
      reduceTransparency: _reduceTransparency,
      increaseBorderWidth: _increaseBorderWidth,
      borderMultiplier: _borderMultiplier,
      useCustomColors: _useCustomColors,
      customColors: _customColors,
    );
  }

  /// Getters
  bool get isEnabled => _isEnabled;
  HighContrastLevel get contrastLevel => _contrastLevel;
  bool get invertColors => _invertColors;
  bool get reduceTransparency => _reduceTransparency;
  bool get increaseBorderWidth => _increaseBorderWidth;
  double get borderMultiplier => _borderMultiplier;
  bool get useCustomColors => _useCustomColors;
  HighContrastColorSet get customColors => _customColors;
}

/// High contrast level enum
enum HighContrastLevel {
  standard,
  high,
  maximum,
}

/// High contrast color set
class HighContrastColorSet {
  final Color primary;
  final Color onPrimary;
  final Color background;
  final Color onBackground;
  final Color surface;
  final Color onSurface;
  final Color error;
  final Color onError;

  const HighContrastColorSet({
    required this.primary,
    required this.onPrimary,
    required this.background,
    required this.onBackground,
    required this.surface,
    required this.onSurface,
    required this.error,
    required this.onError,
  });

  factory HighContrastColorSet.defaultSet() {
    return const HighContrastColorSet(
      primary: Color(0xFF000000),
      onPrimary: Color(0xFFFFFFFF),
      background: Color(0xFFFFFFFF),
      onBackground: Color(0xFF000000),
      surface: Color(0xFFF5F5F5),
      onSurface: Color(0xFF000000),
      error: Color(0xFFCC0000),
      onError: Color(0xFFFFFFFF),
    );
  }
}

/// High contrast status
class HighContrastStatus {
  final bool isEnabled;
  final HighContrastLevel contrastLevel;
  final bool invertColors;
  final bool reduceTransparency;
  final bool increaseBorderWidth;
  final double borderMultiplier;
  final bool useCustomColors;
  final HighContrastColorSet customColors;

  const HighContrastStatus({
    required this.isEnabled,
    required this.contrastLevel,
    required this.invertColors,
    required this.reduceTransparency,
    required this.increaseBorderWidth,
    required this.borderMultiplier,
    required this.useCustomColors,
    required this.customColors,
  });

  @override
  String toString() {
    return 'HighContrastStatus('
        'enabled: $isEnabled, '
        'level: $contrastLevel, '
        'invertColors: $invertColors, '
        'reduceTransparency: $reduceTransparency, '
        'increaseBorders: $increaseBorderWidth, '
        'borderMultiplier: $borderMultiplier, '
        'useCustomColors: $useCustomColors'
        ')';
  }
}

/// High contrast widgets
class HighContrastWidgets {
  /// Contrast level selector
  static Widget contrastLevelSelector({
    required HighContrastLevel currentLevel,
    required ValueChanged<HighContrastLevel> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Contrast Level:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...HighContrastLevel.values.map((level) {
          return RadioListTile<HighContrastLevel>(
            title: Text(_getLevelLabel(level)),
            subtitle: Text(_getLevelDescription(level)),
            value: level,
            groupValue: currentLevel,
            onChanged: (value) {
              if (value != null) onChanged(value);
            },
          );
        }).toList(),
      ],
    );
  }

  /// Get level label
  static String _getLevelLabel(HighContrastLevel level) {
    switch (level) {
      case HighContrastLevel.standard:
        return 'Standard';
      case HighContrastLevel.high:
        return 'High';
      case HighContrastLevel.maximum:
        return 'Maximum';
    }
  }

  /// Get level description
  static String _getLevelDescription(HighContrastLevel level) {
    switch (level) {
      case HighContrastLevel.standard:
        return 'Improved contrast while maintaining design aesthetics';
      case HighContrastLevel.high:
        return 'Strong contrast for better visibility';
      case HighContrastLevel.maximum:
        return 'Maximum contrast - black and white only';
    }
  }

  /// Color picker widget
  static Widget colorPicker({
    required String label,
    required Color currentColor,
    required ValueChanged<Color> onChanged,
  }) {
    return ListTile(
      title: Text(label),
      trailing: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: currentColor,
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      onTap: () {
        // In a real implementation, this would open a color picker dialog
        // For now, we'll cycle through some predefined colors
        final colors = [
          Colors.black,
          Colors.white,
          Colors.red,
          Colors.blue,
          Colors.green,
          Colors.yellow,
        ];
        final currentIndex = colors.indexOf(currentColor);
        final nextIndex = (currentIndex + 1) % colors.length;
        onChanged(colors[nextIndex]);
      },
    );
  }

  /// Settings panel
  static Widget settingsPanel({
    required HighContrastStatus status,
    required VoidCallback onToggleEnabled,
    required ValueChanged<HighContrastLevel> onLevelChanged,
    required VoidCallback onToggleInvertColors,
    required VoidCallback onToggleReduceTransparency,
    required VoidCallback onToggleIncreaseBorders,
    required ValueChanged<double> onBorderMultiplierChanged,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'High Contrast Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Enable High Contrast'),
              value: status.isEnabled,
              onChanged: (_) => onToggleEnabled(),
            ),
            if (status.isEnabled) ...[
              const SizedBox(height: 16),
              contrastLevelSelector(
                currentLevel: status.contrastLevel,
                onChanged: onLevelChanged,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Invert Colors'),
                subtitle: const Text('Swap light and dark colors'),
                value: status.invertColors,
                onChanged: (_) => onToggleInvertColors(),
              ),
              SwitchListTile(
                title: const Text('Reduce Transparency'),
                subtitle: const Text('Make all elements fully opaque'),
                value: status.reduceTransparency,
                onChanged: (_) => onToggleReduceTransparency(),
              ),
              SwitchListTile(
                title: const Text('Increase Border Width'),
                subtitle: const Text('Make borders more visible'),
                value: status.increaseBorderWidth,
                onChanged: (_) => onToggleIncreaseBorders(),
              ),
              if (status.increaseBorderWidth) ...[
                const SizedBox(height: 8),
                Text('Border Width: ${status.borderMultiplier.toStringAsFixed(1)}x'),
                Slider(
                  value: status.borderMultiplier,
                  min: 1.0,
                  max: 3.0,
                  divisions: 20,
                  label: '${status.borderMultiplier.toStringAsFixed(1)}x',
                  onChanged: onBorderMultiplierChanged,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
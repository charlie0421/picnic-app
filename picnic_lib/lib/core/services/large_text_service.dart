import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Large text support service for enhanced accessibility
class LargeTextService {
  static final LargeTextService _instance = LargeTextService._internal();
  factory LargeTextService() => _instance;
  LargeTextService._internal();

  static const String _prefixKey = 'large_text_';
  
  bool _isEnabled = false;
  double _textScaleFactor = 1.0;
  double _lineHeight = 1.4;
  double _letterSpacing = 0.0;
  FontWeight _fontWeight = FontWeight.normal;
  String _fontFamily = 'default';
  bool _useHighContrast = false;
  bool _reduceFontVariations = false;
  
  static const double _minScaleFactor = 0.5;
  static const double _maxScaleFactor = 3.0;
  static const double _defaultLineHeight = 1.4;
  static const double _maxLineHeight = 2.0;
  static const double _maxLetterSpacing = 2.0;

  final List<String> _accessibleFonts = [
    'default',
    'Roboto',
    'OpenSans',
    'Lato',
    'SourceSansPro',
    'Raleway',
  ];

  /// Initialize large text service
  Future<void> initialize() async {
    try {
      await _loadSettings();
      _setupSystemListeners();
      debugPrint('LargeTextService initialized');
    } catch (e) {
      debugPrint('Failed to initialize LargeTextService: $e');
    }
  }

  /// Load large text settings
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isEnabled = prefs.getBool('${_prefixKey}enabled') ?? false;
    _textScaleFactor = prefs.getDouble('${_prefixKey}scale_factor') ?? 1.0;
    _lineHeight = prefs.getDouble('${_prefixKey}line_height') ?? _defaultLineHeight;
    _letterSpacing = prefs.getDouble('${_prefixKey}letter_spacing') ?? 0.0;
    _fontFamily = prefs.getString('${_prefixKey}font_family') ?? 'default';
    _useHighContrast = prefs.getBool('${_prefixKey}high_contrast') ?? false;
    _reduceFontVariations = prefs.getBool('${_prefixKey}reduce_variations') ?? false;
    
    final fontWeightIndex = prefs.getInt('${_prefixKey}font_weight') ?? FontWeight.normal.index;
    _fontWeight = FontWeight.values[fontWeightIndex.clamp(0, FontWeight.values.length - 1)];
  }

  /// Save large text settings
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('${_prefixKey}enabled', _isEnabled);
    await prefs.setDouble('${_prefixKey}scale_factor', _textScaleFactor);
    await prefs.setDouble('${_prefixKey}line_height', _lineHeight);
    await prefs.setDouble('${_prefixKey}letter_spacing', _letterSpacing);
    await prefs.setString('${_prefixKey}font_family', _fontFamily);
    await prefs.setBool('${_prefixKey}high_contrast', _useHighContrast);
    await prefs.setBool('${_prefixKey}reduce_variations', _reduceFontVariations);
    await prefs.setInt('${_prefixKey}font_weight', _fontWeight.index);
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
    
    if (features.boldText) {
      _fontWeight = FontWeight.bold;
      _saveSettings();
    }
    
    if (features.highContrast != _useHighContrast) {
      _useHighContrast = features.highContrast;
      _saveSettings();
    }
  }

  /// Enable large text support
  Future<void> enable() async {
    _isEnabled = true;
    await _saveSettings();
    debugPrint('Large text support enabled');
  }

  /// Disable large text support
  Future<void> disable() async {
    _isEnabled = false;
    await _saveSettings();
    debugPrint('Large text support disabled');
  }

  /// Set text scale factor
  Future<void> setTextScaleFactor(double factor) async {
    _textScaleFactor = factor.clamp(_minScaleFactor, _maxScaleFactor);
    await _saveSettings();
    debugPrint('Text scale factor set to: $_textScaleFactor');
  }

  /// Increase text size
  Future<void> increaseTextSize() async {
    const increment = 0.1;
    await setTextScaleFactor(_textScaleFactor + increment);
  }

  /// Decrease text size
  Future<void> decreaseTextSize() async {
    const decrement = 0.1;
    await setTextScaleFactor(_textScaleFactor - decrement);
  }

  /// Reset text size to normal
  Future<void> resetTextSize() async {
    await setTextScaleFactor(1.0);
  }

  /// Set line height
  Future<void> setLineHeight(double height) async {
    _lineHeight = height.clamp(_defaultLineHeight, _maxLineHeight);
    await _saveSettings();
    debugPrint('Line height set to: $_lineHeight');
  }

  /// Set letter spacing
  Future<void> setLetterSpacing(double spacing) async {
    _letterSpacing = spacing.clamp(0.0, _maxLetterSpacing);
    await _saveSettings();
    debugPrint('Letter spacing set to: $_letterSpacing');
  }

  /// Set font weight
  Future<void> setFontWeight(FontWeight weight) async {
    _fontWeight = weight;
    await _saveSettings();
    debugPrint('Font weight set to: $weight');
  }

  /// Set font family
  Future<void> setFontFamily(String fontFamily) async {
    if (_accessibleFonts.contains(fontFamily)) {
      _fontFamily = fontFamily;
      await _saveSettings();
      debugPrint('Font family set to: $fontFamily');
    } else {
      throw ArgumentError('Unsupported font family: $fontFamily');
    }
  }

  /// Toggle high contrast
  Future<void> toggleHighContrast() async {
    _useHighContrast = !_useHighContrast;
    await _saveSettings();
    debugPrint('High contrast: $_useHighContrast');
  }

  /// Toggle reduced font variations
  Future<void> toggleReduceFontVariations() async {
    _reduceFontVariations = !_reduceFontVariations;
    await _saveSettings();
    debugPrint('Reduce font variations: $_reduceFontVariations');
  }

  /// Get accessible text theme
  TextTheme getAccessibleTextTheme(TextTheme baseTheme) {
    if (!_isEnabled) return baseTheme;

    final fontFamily = _fontFamily == 'default' ? null : _fontFamily;

    return baseTheme.apply(
      fontSizeFactor: _textScaleFactor,
      fontFamily: fontFamily,
    ).copyWith(
      displayLarge: _applyTextStyle(baseTheme.displayLarge),
      displayMedium: _applyTextStyle(baseTheme.displayMedium),
      displaySmall: _applyTextStyle(baseTheme.displaySmall),
      headlineLarge: _applyTextStyle(baseTheme.headlineLarge),
      headlineMedium: _applyTextStyle(baseTheme.headlineMedium),
      headlineSmall: _applyTextStyle(baseTheme.headlineSmall),
      titleLarge: _applyTextStyle(baseTheme.titleLarge),
      titleMedium: _applyTextStyle(baseTheme.titleMedium),
      titleSmall: _applyTextStyle(baseTheme.titleSmall),
      bodyLarge: _applyTextStyle(baseTheme.bodyLarge),
      bodyMedium: _applyTextStyle(baseTheme.bodyMedium),
      bodySmall: _applyTextStyle(baseTheme.bodySmall),
      labelLarge: _applyTextStyle(baseTheme.labelLarge),
      labelMedium: _applyTextStyle(baseTheme.labelMedium),
      labelSmall: _applyTextStyle(baseTheme.labelSmall),
    );
  }

  /// Apply text style modifications
  TextStyle? _applyTextStyle(TextStyle? baseStyle) {
    if (baseStyle == null) return null;

    final fontSize = (baseStyle.fontSize ?? 14.0) * _textScaleFactor;
    final fontFamily = _fontFamily == 'default' ? baseStyle.fontFamily : _fontFamily;

    return baseStyle.copyWith(
      fontSize: fontSize,
      height: _lineHeight,
      letterSpacing: _letterSpacing,
      fontWeight: _fontWeight,
      fontFamily: fontFamily,
    );
  }

  /// Get accessible color scheme for high contrast
  ColorScheme getAccessibleColorScheme(ColorScheme baseScheme) {
    if (!_useHighContrast) return baseScheme;

    // High contrast color adjustments
    final brightness = baseScheme.brightness;
    
    if (brightness == Brightness.dark) {
      return baseScheme.copyWith(
        primary: Colors.white,
        onPrimary: Colors.black,
        secondary: const Color(0xFFFFD700), // Gold
        onSecondary: Colors.black,
        background: Colors.black,
        onBackground: Colors.white,
        surface: const Color(0xFF1A1A1A),
        onSurface: Colors.white,
        error: const Color(0xFFFF6B6B),
        onError: Colors.black,
      );
    } else {
      return baseScheme.copyWith(
        primary: Colors.black,
        onPrimary: Colors.white,
        secondary: const Color(0xFF0066CC), // Dark blue
        onSecondary: Colors.white,
        background: Colors.white,
        onBackground: Colors.black,
        surface: const Color(0xFFF5F5F5),
        onSurface: Colors.black,
        error: const Color(0xFFCC0000),
        onError: Colors.white,
      );
    }
  }

  /// Create accessible text widget
  Widget createAccessibleText(
    String text, {
    TextStyle? style,
    TextAlign? textAlign,
    int? maxLines,
    TextOverflow? overflow,
    bool useSemantics = true,
  }) {
    final accessibleStyle = _isEnabled ? _applyTextStyle(style) : style;
    
    Widget textWidget = Text(
      text,
      style: accessibleStyle,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );

    if (useSemantics) {
      textWidget = Semantics(
        label: text,
        readOnly: true,
        child: textWidget,
      );
    }

    return textWidget;
  }

  /// Create accessible rich text widget
  Widget createAccessibleRichText(
    List<TextSpan> children, {
    TextAlign? textAlign,
    int? maxLines,
    TextOverflow? overflow,
    bool useSemantics = true,
  }) {
    final accessibleChildren = _isEnabled 
        ? children.map((span) => _applyTextSpanStyle(span)).toList()
        : children;

    Widget richTextWidget = RichText(
      text: TextSpan(children: accessibleChildren),
      textAlign: textAlign ?? TextAlign.start,
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.clip,
    );

    if (useSemantics) {
      final combinedText = children
          .map((span) => span.text ?? '')
          .join();
      
      richTextWidget = Semantics(
        label: combinedText,
        readOnly: true,
        child: richTextWidget,
      );
    }

    return richTextWidget;
  }

  /// Apply text span style modifications
  TextSpan _applyTextSpanStyle(TextSpan span) {
    final accessibleStyle = _applyTextStyle(span.style);
    
    return TextSpan(
      text: span.text,
      style: accessibleStyle,
      children: span.children?.map((child) {
        if (child is TextSpan) {
          return _applyTextSpanStyle(child);
        }
        return child;
      }).toList(),
      recognizer: span.recognizer,
      semanticsLabel: span.semanticsLabel,
    );
  }

  /// Create accessible text field
  Widget createAccessibleTextField({
    TextEditingController? controller,
    String? labelText,
    String? hintText,
    TextStyle? style,
    bool readOnly = false,
    int? maxLines,
    ValueChanged<String>? onChanged,
  }) {
    final accessibleStyle = _isEnabled ? _applyTextStyle(style) : style;
    
    return Semantics(
      label: labelText ?? hintText ?? 'Text field',
      textField: true,
      child: TextField(
        controller: controller,
        style: accessibleStyle,
        readOnly: readOnly,
        maxLines: maxLines,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          labelStyle: accessibleStyle,
          hintStyle: accessibleStyle?.copyWith(
            color: accessibleStyle.color?.withOpacity(0.6),
          ),
        ),
      ),
    );
  }

  /// Get text size preset
  LargeTextPreset getCurrentPreset() {
    if (_textScaleFactor <= 1.0) return LargeTextPreset.normal;
    if (_textScaleFactor <= 1.3) return LargeTextPreset.large;
    if (_textScaleFactor <= 1.6) return LargeTextPreset.extraLarge;
    return LargeTextPreset.huge;
  }

  /// Apply text size preset
  Future<void> applyPreset(LargeTextPreset preset) async {
    switch (preset) {
      case LargeTextPreset.normal:
        await setTextScaleFactor(1.0);
        await setLineHeight(1.4);
        await setLetterSpacing(0.0);
        break;
      case LargeTextPreset.large:
        await setTextScaleFactor(1.3);
        await setLineHeight(1.5);
        await setLetterSpacing(0.5);
        break;
      case LargeTextPreset.extraLarge:
        await setTextScaleFactor(1.6);
        await setLineHeight(1.6);
        await setLetterSpacing(1.0);
        break;
      case LargeTextPreset.huge:
        await setTextScaleFactor(2.0);
        await setLineHeight(1.8);
        await setLetterSpacing(1.5);
        break;
    }
  }

  /// Get large text status
  LargeTextStatus getStatus() {
    return LargeTextStatus(
      isEnabled: _isEnabled,
      textScaleFactor: _textScaleFactor,
      lineHeight: _lineHeight,
      letterSpacing: _letterSpacing,
      fontWeight: _fontWeight,
      fontFamily: _fontFamily,
      useHighContrast: _useHighContrast,
      reduceFontVariations: _reduceFontVariations,
      currentPreset: getCurrentPreset(),
    );
  }

  /// Getters
  bool get isEnabled => _isEnabled;
  double get textScaleFactor => _textScaleFactor;
  double get lineHeight => _lineHeight;
  double get letterSpacing => _letterSpacing;
  FontWeight get fontWeight => _fontWeight;
  String get fontFamily => _fontFamily;
  bool get useHighContrast => _useHighContrast;
  bool get reduceFontVariations => _reduceFontVariations;
  List<String> get accessibleFonts => List.unmodifiable(_accessibleFonts);
  double get minScaleFactor => _minScaleFactor;
  double get maxScaleFactor => _maxScaleFactor;
}

/// Large text preset options
enum LargeTextPreset {
  normal,
  large,
  extraLarge,
  huge,
}

/// Large text status
class LargeTextStatus {
  final bool isEnabled;
  final double textScaleFactor;
  final double lineHeight;
  final double letterSpacing;
  final FontWeight fontWeight;
  final String fontFamily;
  final bool useHighContrast;
  final bool reduceFontVariations;
  final LargeTextPreset currentPreset;

  const LargeTextStatus({
    required this.isEnabled,
    required this.textScaleFactor,
    required this.lineHeight,
    required this.letterSpacing,
    required this.fontWeight,
    required this.fontFamily,
    required this.useHighContrast,
    required this.reduceFontVariations,
    required this.currentPreset,
  });

  @override
  String toString() {
    return 'LargeTextStatus('
        'enabled: $isEnabled, '
        'scaleFactor: $textScaleFactor, '
        'lineHeight: $lineHeight, '
        'letterSpacing: $letterSpacing, '
        'fontWeight: $fontWeight, '
        'fontFamily: $fontFamily, '
        'highContrast: $useHighContrast, '
        'reduceFontVariations: $reduceFontVariations, '
        'preset: $currentPreset'
        ')';
  }
}

/// Large text widgets
class LargeTextWidgets {
  /// Text size control slider
  static Widget textSizeSlider({
    required double value,
    required ValueChanged<double> onChanged,
    double min = 0.5,
    double max = 3.0,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Text Size: ${(value * 100).round()}%'),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: ((max - min) * 10).round(),
          label: '${(value * 100).round()}%',
          onChanged: onChanged,
        ),
      ],
    );
  }

  /// Font family selector
  static Widget fontFamilySelector({
    required String currentFont,
    required List<String> availableFonts,
    required ValueChanged<String> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: currentFont,
      decoration: const InputDecoration(
        labelText: 'Font Family',
      ),
      items: availableFonts.map((font) {
        return DropdownMenuItem(
          value: font,
          child: Text(
            font == 'default' ? 'Default' : font,
            style: TextStyle(
              fontFamily: font == 'default' ? null : font,
            ),
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }

  /// Preset buttons
  static Widget presetButtons({
    required LargeTextPreset currentPreset,
    required ValueChanged<LargeTextPreset> onPresetChanged,
  }) {
    return Wrap(
      spacing: 8.0,
      children: LargeTextPreset.values.map((preset) {
        final isSelected = preset == currentPreset;
        
        return ChoiceChip(
          label: Text(_getPresetLabel(preset)),
          selected: isSelected,
          onSelected: (_) => onPresetChanged(preset),
        );
      }).toList(),
    );
  }

  /// Get preset label
  static String _getPresetLabel(LargeTextPreset preset) {
    switch (preset) {
      case LargeTextPreset.normal:
        return 'Normal';
      case LargeTextPreset.large:
        return 'Large';
      case LargeTextPreset.extraLarge:
        return 'Extra Large';
      case LargeTextPreset.huge:
        return 'Huge';
    }
  }

  /// Settings panel
  static Widget settingsPanel({
    required LargeTextStatus status,
    required VoidCallback onToggleEnabled,
    required ValueChanged<double> onScaleChanged,
    required ValueChanged<LargeTextPreset> onPresetChanged,
    required VoidCallback onToggleHighContrast,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Large Text Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Enable Large Text'),
              value: status.isEnabled,
              onChanged: (_) => onToggleEnabled(),
            ),
            if (status.isEnabled) ...[
              const SizedBox(height: 16),
              textSizeSlider(
                value: status.textScaleFactor,
                onChanged: onScaleChanged,
              ),
              const SizedBox(height: 16),
              const Text('Presets:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              presetButtons(
                currentPreset: status.currentPreset,
                onPresetChanged: onPresetChanged,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('High Contrast'),
                value: status.useHighContrast,
                onChanged: (_) => onToggleHighContrast(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
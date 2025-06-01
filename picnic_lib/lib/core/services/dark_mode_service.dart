import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Dark mode service for complete theme management
class DarkModeService {
  static final DarkModeService _instance = DarkModeService._internal();
  factory DarkModeService() => _instance;
  DarkModeService._internal();

  static const String _prefixKey = 'dark_mode_';
  
  ThemeMode _themeMode = ThemeMode.system;
  bool _useSystemTheme = true;
  bool _isInitialized = false;
  DarkModeVariant _darkVariant = DarkModeVariant.standard;
  bool _useTrueBlack = false;
  bool _adaptToSystem = true;
  
  // Theme customization
  Color _primaryColor = const Color(0xFF2196F3);
  Color _accentColor = const Color(0xFF03DAC6);
  Color _backgroundDark = const Color(0xFF121212);
  Color _surfaceDark = const Color(0xFF1E1E1E);
  Color _onBackgroundDark = const Color(0xFFFFFFFF);
  Color _onSurfaceDark = const Color(0xFFFFFFFF);

  // Auto theme switching
  TimeOfDay? _darkModeStartTime;
  TimeOfDay? _darkModeEndTime;
  bool _useAutoSwitch = false;
  bool _followBatteryLevel = false;
  double _batteryThreshold = 20.0;

  /// Initialize dark mode service
  Future<void> initialize() async {
    try {
      await _loadSettings();
      _setupSystemListeners();
      _isInitialized = true;
      debugPrint('DarkModeService initialized');
    } catch (e) {
      debugPrint('Failed to initialize DarkModeService: $e');
    }
  }

  /// Load dark mode settings
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    final themeModeIndex = prefs.getInt('${_prefixKey}theme_mode') ?? ThemeMode.system.index;
    _themeMode = ThemeMode.values[themeModeIndex.clamp(0, ThemeMode.values.length - 1)];
    
    _useSystemTheme = prefs.getBool('${_prefixKey}use_system') ?? true;
    _useTrueBlack = prefs.getBool('${_prefixKey}true_black') ?? false;
    _adaptToSystem = prefs.getBool('${_prefixKey}adapt_system') ?? true;
    _useAutoSwitch = prefs.getBool('${_prefixKey}auto_switch') ?? false;
    _followBatteryLevel = prefs.getBool('${_prefixKey}follow_battery') ?? false;
    _batteryThreshold = prefs.getDouble('${_prefixKey}battery_threshold') ?? 20.0;
    
    final darkVariantIndex = prefs.getInt('${_prefixKey}dark_variant') ?? 0;
    _darkVariant = DarkModeVariant.values[darkVariantIndex.clamp(0, DarkModeVariant.values.length - 1)];
    
    // Load custom colors
    final primaryValue = prefs.getInt('${_prefixKey}primary_color');
    if (primaryValue != null) _primaryColor = Color(primaryValue);
    
    final accentValue = prefs.getInt('${_prefixKey}accent_color');
    if (accentValue != null) _accentColor = Color(accentValue);
    
    final backgroundValue = prefs.getInt('${_prefixKey}background_dark');
    if (backgroundValue != null) _backgroundDark = Color(backgroundValue);
    
    final surfaceValue = prefs.getInt('${_prefixKey}surface_dark');
    if (surfaceValue != null) _surfaceDark = Color(surfaceValue);
    
    // Load auto switch times
    final startHour = prefs.getInt('${_prefixKey}start_hour');
    final startMinute = prefs.getInt('${_prefixKey}start_minute');
    if (startHour != null && startMinute != null) {
      _darkModeStartTime = TimeOfDay(hour: startHour, minute: startMinute);
    }
    
    final endHour = prefs.getInt('${_prefixKey}end_hour');
    final endMinute = prefs.getInt('${_prefixKey}end_minute');
    if (endHour != null && endMinute != null) {
      _darkModeEndTime = TimeOfDay(hour: endHour, minute: endMinute);
    }
  }

  /// Save dark mode settings
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('${_prefixKey}theme_mode', _themeMode.index);
    await prefs.setBool('${_prefixKey}use_system', _useSystemTheme);
    await prefs.setInt('${_prefixKey}dark_variant', _darkVariant.index);
    await prefs.setBool('${_prefixKey}true_black', _useTrueBlack);
    await prefs.setBool('${_prefixKey}adapt_system', _adaptToSystem);
    await prefs.setBool('${_prefixKey}auto_switch', _useAutoSwitch);
    await prefs.setBool('${_prefixKey}follow_battery', _followBatteryLevel);
    await prefs.setDouble('${_prefixKey}battery_threshold', _batteryThreshold);
    
    // Save custom colors
    await prefs.setInt('${_prefixKey}primary_color', _primaryColor.value);
    await prefs.setInt('${_prefixKey}accent_color', _accentColor.value);
    await prefs.setInt('${_prefixKey}background_dark', _backgroundDark.value);
    await prefs.setInt('${_prefixKey}surface_dark', _surfaceDark.value);
    
    // Save auto switch times
    if (_darkModeStartTime != null) {
      await prefs.setInt('${_prefixKey}start_hour', _darkModeStartTime!.hour);
      await prefs.setInt('${_prefixKey}start_minute', _darkModeStartTime!.minute);
    }
    
    if (_darkModeEndTime != null) {
      await prefs.setInt('${_prefixKey}end_hour', _darkModeEndTime!.hour);
      await prefs.setInt('${_prefixKey}end_minute', _darkModeEndTime!.minute);
    }
  }

  /// Setup system theme listeners
  void _setupSystemListeners() {
    WidgetsBinding.instance.platformDispatcher.onPlatformBrightnessChanged = () {
      if (_adaptToSystem) {
        _updateThemeFromSystem();
      }
    };
  }

  /// Update theme from system
  void _updateThemeFromSystem() {
    final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    final shouldUseDark = brightness == Brightness.dark;
    
    if (_useSystemTheme) {
      _themeMode = shouldUseDark ? ThemeMode.dark : ThemeMode.light;
      _saveSettings();
      debugPrint('Theme updated from system: ${_themeMode}');
    }
  }

  /// Set theme mode
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    _useSystemTheme = mode == ThemeMode.system;
    await _saveSettings();
    _updateSystemUI();
    debugPrint('Theme mode set to: $mode');
  }

  /// Toggle theme
  Future<void> toggleTheme() async {
    switch (_themeMode) {
      case ThemeMode.light:
        await setThemeMode(ThemeMode.dark);
        break;
      case ThemeMode.dark:
        await setThemeMode(ThemeMode.light);
        break;
      case ThemeMode.system:
        final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
        await setThemeMode(brightness == Brightness.dark ? ThemeMode.light : ThemeMode.dark);
        break;
    }
  }

  /// Set dark mode variant
  Future<void> setDarkVariant(DarkModeVariant variant) async {
    _darkVariant = variant;
    await _saveSettings();
    debugPrint('Dark variant set to: $variant');
  }

  /// Toggle true black mode
  Future<void> toggleTrueBlack() async {
    _useTrueBlack = !_useTrueBlack;
    await _saveSettings();
    debugPrint('True black mode: $_useTrueBlack');
  }

  /// Set custom colors
  Future<void> setCustomColors({
    Color? primary,
    Color? accent,
    Color? backgroundDark,
    Color? surfaceDark,
  }) async {
    if (primary != null) _primaryColor = primary;
    if (accent != null) _accentColor = accent;
    if (backgroundDark != null) _backgroundDark = backgroundDark;
    if (surfaceDark != null) _surfaceDark = surfaceDark;
    await _saveSettings();
    debugPrint('Custom colors updated');
  }

  /// Set auto switch times
  Future<void> setAutoSwitchTimes({
    TimeOfDay? startTime,
    TimeOfDay? endTime,
  }) async {
    if (startTime != null) _darkModeStartTime = startTime;
    if (endTime != null) _darkModeEndTime = endTime;
    await _saveSettings();
    debugPrint('Auto switch times updated');
  }

  /// Toggle auto switch
  Future<void> toggleAutoSwitch() async {
    _useAutoSwitch = !_useAutoSwitch;
    await _saveSettings();
    debugPrint('Auto switch: $_useAutoSwitch');
  }

  /// Toggle battery level follow
  Future<void> toggleFollowBatteryLevel() async {
    _followBatteryLevel = !_followBatteryLevel;
    await _saveSettings();
    debugPrint('Follow battery level: $_followBatteryLevel');
  }

  /// Set battery threshold
  Future<void> setBatteryThreshold(double threshold) async {
    _batteryThreshold = threshold.clamp(0.0, 100.0);
    await _saveSettings();
    debugPrint('Battery threshold set to: $_batteryThreshold%');
  }

  /// Get light theme
  ThemeData getLightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      primarySwatch: _createMaterialColor(_primaryColor),
      primaryColor: _primaryColor,
      colorScheme: ColorScheme.light(
        primary: _primaryColor,
        secondary: _accentColor,
        surface: Colors.white,
        background: const Color(0xFFFAFAFA),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.black,
        onBackground: Colors.black,
      ),
      scaffoldBackgroundColor: const Color(0xFFFAFAFA),
      cardColor: Colors.white,
      dividerColor: Colors.grey[300],
      textTheme: _getLightTextTheme(),
      iconTheme: const IconThemeData(color: Colors.black54),
      appBarTheme: AppBarTheme(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _primaryColor,
          side: BorderSide(color: _primaryColor),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Colors.grey[100],
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: _primaryColor,
        unselectedItemColor: Colors.grey,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  /// Get dark theme
  ThemeData getDarkTheme() {
    final backgroundColor = _useTrueBlack ? Colors.black : _getDarkBackground();
    final surfaceColor = _useTrueBlack ? Colors.black : _getDarkSurface();
    
    return ThemeData(
      brightness: Brightness.dark,
      primarySwatch: _createMaterialColor(_primaryColor),
      primaryColor: _primaryColor,
      colorScheme: ColorScheme.dark(
        primary: _primaryColor,
        secondary: _accentColor,
        surface: surfaceColor,
        background: backgroundColor,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: _useTrueBlack ? Colors.white : _onSurfaceDark,
        onBackground: _useTrueBlack ? Colors.white : _onBackgroundDark,
      ),
      scaffoldBackgroundColor: backgroundColor,
      cardColor: surfaceColor,
      dividerColor: Colors.grey[700],
      textTheme: _getDarkTextTheme(),
      iconTheme: const IconThemeData(color: Colors.white70),
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceColor,
        foregroundColor: Colors.white,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _primaryColor,
          side: BorderSide(color: _primaryColor),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: surfaceColor,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceColor,
        selectedItemColor: _primaryColor,
        unselectedItemColor: Colors.grey,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  /// Get dark background color based on variant
  Color _getDarkBackground() {
    switch (_darkVariant) {
      case DarkModeVariant.standard:
        return const Color(0xFF121212);
      case DarkModeVariant.deep:
        return const Color(0xFF000000);
      case DarkModeVariant.blue:
        return const Color(0xFF0D1117);
      case DarkModeVariant.green:
        return const Color(0xFF0D1F0D);
      case DarkModeVariant.custom:
        return _backgroundDark;
    }
  }

  /// Get dark surface color based on variant
  Color _getDarkSurface() {
    switch (_darkVariant) {
      case DarkModeVariant.standard:
        return const Color(0xFF1E1E1E);
      case DarkModeVariant.deep:
        return const Color(0xFF0A0A0A);
      case DarkModeVariant.blue:
        return const Color(0xFF21262D);
      case DarkModeVariant.green:
        return const Color(0xFF1F2F1F);
      case DarkModeVariant.custom:
        return _surfaceDark;
    }
  }

  /// Get light text theme
  TextTheme _getLightTextTheme() {
    return const TextTheme(
      displayLarge: TextStyle(color: Colors.black87),
      displayMedium: TextStyle(color: Colors.black87),
      displaySmall: TextStyle(color: Colors.black87),
      headlineLarge: TextStyle(color: Colors.black87),
      headlineMedium: TextStyle(color: Colors.black87),
      headlineSmall: TextStyle(color: Colors.black87),
      titleLarge: TextStyle(color: Colors.black87),
      titleMedium: TextStyle(color: Colors.black87),
      titleSmall: TextStyle(color: Colors.black87),
      bodyLarge: TextStyle(color: Colors.black87),
      bodyMedium: TextStyle(color: Colors.black87),
      bodySmall: TextStyle(color: Colors.black54),
      labelLarge: TextStyle(color: Colors.black87),
      labelMedium: TextStyle(color: Colors.black87),
      labelSmall: TextStyle(color: Colors.black54),
    );
  }

  /// Get dark text theme
  TextTheme _getDarkTextTheme() {
    return const TextTheme(
      displayLarge: TextStyle(color: Colors.white),
      displayMedium: TextStyle(color: Colors.white),
      displaySmall: TextStyle(color: Colors.white),
      headlineLarge: TextStyle(color: Colors.white),
      headlineMedium: TextStyle(color: Colors.white),
      headlineSmall: TextStyle(color: Colors.white),
      titleLarge: TextStyle(color: Colors.white),
      titleMedium: TextStyle(color: Colors.white),
      titleSmall: TextStyle(color: Colors.white),
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white),
      bodySmall: TextStyle(color: Colors.white70),
      labelLarge: TextStyle(color: Colors.white),
      labelMedium: TextStyle(color: Colors.white),
      labelSmall: TextStyle(color: Colors.white70),
    );
  }

  /// Create material color from color
  MaterialColor _createMaterialColor(Color color) {
    final strengths = <double>[.05];
    final swatch = <int, Color>{};
    final int r = color.red, g = color.green, b = color.blue;

    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }
    
    for (final strength in strengths) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }
    
    return MaterialColor(color.value, swatch);
  }

  /// Update system UI overlay style
  void _updateSystemUI() {
    final isDark = _getCurrentEffectiveTheme() == Brightness.dark;
    
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: isDark ? _getDarkSurface() : Colors.white,
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
    );
  }

  /// Get current effective theme brightness
  Brightness _getCurrentEffectiveTheme() {
    switch (_themeMode) {
      case ThemeMode.light:
        return Brightness.light;
      case ThemeMode.dark:
        return Brightness.dark;
      case ThemeMode.system:
        return WidgetsBinding.instance.platformDispatcher.platformBrightness;
    }
  }

  /// Check if should use dark mode based on conditions
  bool shouldUseDarkMode() {
    if (_useAutoSwitch && _darkModeStartTime != null && _darkModeEndTime != null) {
      final now = TimeOfDay.now();
      final isInDarkPeriod = _isTimeInRange(now, _darkModeStartTime!, _darkModeEndTime!);
      if (isInDarkPeriod) return true;
    }
    
    // Check battery level
    if (_followBatteryLevel) {
      // In a real implementation, you would check actual battery level
      // For simulation, we'll assume battery is low
      // final batteryLevel = await _getBatteryLevel();
      // if (batteryLevel <= _batteryThreshold) return true;
    }
    
    return _getCurrentEffectiveTheme() == Brightness.dark;
  }

  /// Check if time is in range
  bool _isTimeInRange(TimeOfDay current, TimeOfDay start, TimeOfDay end) {
    final currentMinutes = current.hour * 60 + current.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    
    if (startMinutes <= endMinutes) {
      // Same day range
      return currentMinutes >= startMinutes && currentMinutes <= endMinutes;
    } else {
      // Overnight range
      return currentMinutes >= startMinutes || currentMinutes <= endMinutes;
    }
  }

  /// Get dark mode status
  DarkModeStatus getStatus() {
    return DarkModeStatus(
      themeMode: _themeMode,
      darkVariant: _darkVariant,
      useTrueBlack: _useTrueBlack,
      useSystemTheme: _useSystemTheme,
      adaptToSystem: _adaptToSystem,
      useAutoSwitch: _useAutoSwitch,
      followBatteryLevel: _followBatteryLevel,
      batteryThreshold: _batteryThreshold,
      darkModeStartTime: _darkModeStartTime,
      darkModeEndTime: _darkModeEndTime,
      primaryColor: _primaryColor,
      accentColor: _accentColor,
      isInitialized: _isInitialized,
      isDarkModeActive: shouldUseDarkMode(),
    );
  }

  /// Getters
  ThemeMode get themeMode => _themeMode;
  DarkModeVariant get darkVariant => _darkVariant;
  bool get useTrueBlack => _useTrueBlack;
  bool get useSystemTheme => _useSystemTheme;
  bool get adaptToSystem => _adaptToSystem;
  bool get useAutoSwitch => _useAutoSwitch;
  bool get followBatteryLevel => _followBatteryLevel;
  double get batteryThreshold => _batteryThreshold;
  TimeOfDay? get darkModeStartTime => _darkModeStartTime;
  TimeOfDay? get darkModeEndTime => _darkModeEndTime;
  Color get primaryColor => _primaryColor;
  Color get accentColor => _accentColor;
  bool get isInitialized => _isInitialized;
}

/// Dark mode variants
enum DarkModeVariant {
  standard,
  deep,
  blue,
  green,
  custom,
}

/// Dark mode status
class DarkModeStatus {
  final ThemeMode themeMode;
  final DarkModeVariant darkVariant;
  final bool useTrueBlack;
  final bool useSystemTheme;
  final bool adaptToSystem;
  final bool useAutoSwitch;
  final bool followBatteryLevel;
  final double batteryThreshold;
  final TimeOfDay? darkModeStartTime;
  final TimeOfDay? darkModeEndTime;
  final Color primaryColor;
  final Color accentColor;
  final bool isInitialized;
  final bool isDarkModeActive;

  const DarkModeStatus({
    required this.themeMode,
    required this.darkVariant,
    required this.useTrueBlack,
    required this.useSystemTheme,
    required this.adaptToSystem,
    required this.useAutoSwitch,
    required this.followBatteryLevel,
    required this.batteryThreshold,
    this.darkModeStartTime,
    this.darkModeEndTime,
    required this.primaryColor,
    required this.accentColor,
    required this.isInitialized,
    required this.isDarkModeActive,
  });

  @override
  String toString() {
    return 'DarkModeStatus('
        'themeMode: $themeMode, '
        'variant: $darkVariant, '
        'trueBlack: $useTrueBlack, '
        'useSystem: $useSystemTheme, '
        'autoSwitch: $useAutoSwitch, '
        'followBattery: $followBatteryLevel, '
        'isDarkActive: $isDarkModeActive'
        ')';
  }
}

/// Dark mode widgets
class DarkModeWidgets {
  /// Theme mode selector
  static Widget themeModeSelector({
    required ThemeMode currentMode,
    required ValueChanged<ThemeMode> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Theme Mode:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...ThemeMode.values.map((mode) {
          return RadioListTile<ThemeMode>(
            title: Text(_getThemeModeLabel(mode)),
            subtitle: Text(_getThemeModeDescription(mode)),
            value: mode,
            groupValue: currentMode,
            onChanged: (value) {
              if (value != null) onChanged(value);
            },
          );
        }).toList(),
      ],
    );
  }

  /// Get theme mode label
  static String _getThemeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  /// Get theme mode description
  static String _getThemeModeDescription(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Always use light theme';
      case ThemeMode.dark:
        return 'Always use dark theme';
      case ThemeMode.system:
        return 'Follow system theme';
    }
  }

  /// Dark variant selector
  static Widget darkVariantSelector({
    required DarkModeVariant currentVariant,
    required ValueChanged<DarkModeVariant> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Dark Theme Variant:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          children: DarkModeVariant.values.map((variant) {
            final isSelected = variant == currentVariant;
            
            return ChoiceChip(
              label: Text(_getDarkVariantLabel(variant)),
              selected: isSelected,
              onSelected: (_) => onChanged(variant),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Get dark variant label
  static String _getDarkVariantLabel(DarkModeVariant variant) {
    switch (variant) {
      case DarkModeVariant.standard:
        return 'Standard';
      case DarkModeVariant.deep:
        return 'Deep';
      case DarkModeVariant.blue:
        return 'Blue';
      case DarkModeVariant.green:
        return 'Green';
      case DarkModeVariant.custom:
        return 'Custom';
    }
  }

  /// Time picker
  static Widget timePicker({
    required String label,
    required TimeOfDay? time,
    required ValueChanged<TimeOfDay> onChanged,
    required BuildContext context,
  }) {
    return ListTile(
      title: Text(label),
      subtitle: Text(time?.format(context) ?? 'Not set'),
      trailing: const Icon(Icons.access_time),
      onTap: () async {
        final pickedTime = await showTimePicker(
          context: context,
          initialTime: time ?? TimeOfDay.now(),
        );
        if (pickedTime != null) {
          onChanged(pickedTime);
        }
      },
    );
  }

  /// Settings panel
  static Widget settingsPanel({
    required DarkModeStatus status,
    required ValueChanged<ThemeMode> onThemeModeChanged,
    required ValueChanged<DarkModeVariant> onVariantChanged,
    required VoidCallback onToggleTrueBlack,
    required VoidCallback onToggleAutoSwitch,
    required ValueChanged<TimeOfDay> onStartTimeChanged,
    required ValueChanged<TimeOfDay> onEndTimeChanged,
    required BuildContext context,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dark Mode Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            themeModeSelector(
              currentMode: status.themeMode,
              onChanged: onThemeModeChanged,
            ),
            const SizedBox(height: 16),
            if (status.themeMode == ThemeMode.dark || status.themeMode == ThemeMode.system) ...[
              darkVariantSelector(
                currentVariant: status.darkVariant,
                onChanged: onVariantChanged,
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('True Black'),
                subtitle: const Text('Use pure black background'),
                value: status.useTrueBlack,
                onChanged: (_) => onToggleTrueBlack(),
              ),
              SwitchListTile(
                title: const Text('Auto Switch'),
                subtitle: const Text('Automatically switch theme at specific times'),
                value: status.useAutoSwitch,
                onChanged: (_) => onToggleAutoSwitch(),
              ),
              if (status.useAutoSwitch) ...[
                const SizedBox(height: 8),
                timePicker(
                  label: 'Dark mode start time',
                  time: status.darkModeStartTime,
                  onChanged: onStartTimeChanged,
                  context: context,
                ),
                timePicker(
                  label: 'Dark mode end time',
                  time: status.darkModeEndTime,
                  onChanged: onEndTimeChanged,
                  context: context,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  /// Theme toggle button
  static Widget themeToggleButton({
    required bool isDark,
    required VoidCallback onPressed,
  }) {
    return FloatingActionButton(
      onPressed: onPressed,
      child: Icon(
        isDark ? Icons.light_mode : Icons.dark_mode,
      ),
    );
  }
}
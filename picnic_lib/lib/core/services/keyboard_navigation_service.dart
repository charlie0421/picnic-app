import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keyboard navigation service for enhanced accessibility
class KeyboardNavigationService {
  static final KeyboardNavigationService _instance = KeyboardNavigationService._internal();
  factory KeyboardNavigationService() => _instance;
  KeyboardNavigationService._internal();

  static const String _prefixKey = 'keyboard_nav_';
  bool _isEnabled = false;
  bool _showFocusIndicator = true;
  double _focusIndicatorWidth = 2.0;
  Color _focusIndicatorColor = Colors.blue;
  final Map<LogicalKeySet, VoidCallback> _shortcuts = {};
  final Map<String, FocusNode> _namedFocusNodes = {};
  FocusNode? _currentFocus;

  /// Initialize keyboard navigation service
  Future<void> initialize() async {
    try {
      await _loadSettings();
      _setupDefaultShortcuts();
      debugPrint('KeyboardNavigationService initialized');
    } catch (e) {
      debugPrint('Failed to initialize KeyboardNavigationService: $e');
    }
  }

  /// Load keyboard navigation settings
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isEnabled = prefs.getBool('${_prefixKey}enabled') ?? true;
    _showFocusIndicator = prefs.getBool('${_prefixKey}show_focus') ?? true;
    _focusIndicatorWidth = prefs.getDouble('${_prefixKey}focus_width') ?? 2.0;
    
    final colorValue = prefs.getInt('${_prefixKey}focus_color');
    if (colorValue != null) {
      _focusIndicatorColor = Color(colorValue);
    }
  }

  /// Save keyboard navigation settings
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('${_prefixKey}enabled', _isEnabled);
    await prefs.setBool('${_prefixKey}show_focus', _showFocusIndicator);
    await prefs.setDouble('${_prefixKey}focus_width', _focusIndicatorWidth);
    await prefs.setInt('${_prefixKey}focus_color', _focusIndicatorColor.value);
  }

  /// Setup default keyboard shortcuts
  void _setupDefaultShortcuts() {
    // Tab navigation
    _shortcuts[LogicalKeySet(LogicalKeyboardKey.tab)] = () {
      _navigateNext();
    };
    
    _shortcuts[LogicalKeySet(LogicalKeyboardKey.tab, LogicalKeyboardKey.shift)] = () {
      _navigatePrevious();
    };

    // Arrow key navigation
    _shortcuts[LogicalKeySet(LogicalKeyboardKey.arrowDown)] = () {
      _navigateNext();
    };
    
    _shortcuts[LogicalKeySet(LogicalKeyboardKey.arrowUp)] = () {
      _navigatePrevious();
    };

    // Home/End navigation
    _shortcuts[LogicalKeySet(LogicalKeyboardKey.home)] = () {
      _navigateToFirst();
    };
    
    _shortcuts[LogicalKeySet(LogicalKeyboardKey.end)] = () {
      _navigateToLast();
    };

    // Escape key
    _shortcuts[LogicalKeySet(LogicalKeyboardKey.escape)] = () {
      _handleEscape();
    };

    // Enter/Space activation
    _shortcuts[LogicalKeySet(LogicalKeyboardKey.enter)] = () {
      _activateCurrentFocus();
    };
    
    _shortcuts[LogicalKeySet(LogicalKeyboardKey.space)] = () {
      _activateCurrentFocus();
    };
  }

  /// Navigate to next focusable element
  void _navigateNext() {
    if (!_isEnabled) return;
    FocusManager.instance.primaryFocus?.nextFocus();
  }

  /// Navigate to previous focusable element
  void _navigatePrevious() {
    if (!_isEnabled) return;
    FocusManager.instance.primaryFocus?.previousFocus();
  }

  /// Navigate to first focusable element
  void _navigateToFirst() {
    if (!_isEnabled) return;
    final rootScope = FocusManager.instance.rootScope;
    if (rootScope.children.isNotEmpty) {
      rootScope.children.first.requestFocus();
    }
  }

  /// Navigate to last focusable element
  void _navigateToLast() {
    if (!_isEnabled) return;
    final rootScope = FocusManager.instance.rootScope;
    if (rootScope.children.isNotEmpty) {
      rootScope.children.last.requestFocus();
    }
  }

  /// Handle escape key press
  void _handleEscape() {
    if (!_isEnabled) return;
    FocusManager.instance.primaryFocus?.unfocus();
  }

  /// Activate current focused element
  void _activateCurrentFocus() {
    if (!_isEnabled) return;
    final currentFocus = FocusManager.instance.primaryFocus;
    if (currentFocus != null) {
      // Trigger semantic action if available
      SystemSound.play(SystemSoundType.click);
    }
  }

  /// Add custom keyboard shortcut
  void addShortcut(LogicalKeySet keys, VoidCallback callback) {
    _shortcuts[keys] = callback;
  }

  /// Remove keyboard shortcut
  void removeShortcut(LogicalKeySet keys) {
    _shortcuts.remove(keys);
  }

  /// Create keyboard navigation wrapper
  Widget createNavigationWrapper({
    required Widget child,
    Map<LogicalKeySet, VoidCallback>? shortcuts,
    bool autofocus = false,
  }) {
    final combinedShortcuts = <LogicalKeySet, VoidCallback>{
      ..._shortcuts,
      if (shortcuts != null) ...shortcuts,
    };

    return Shortcuts(
      shortcuts: <LogicalKeySet, Intent>{
        for (final entry in combinedShortcuts.entries)
          entry.key: _KeyboardNavigationIntent(entry.key),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          _KeyboardNavigationIntent: CallbackAction<_KeyboardNavigationIntent>(
            onInvoke: (intent) {
              final callback = combinedShortcuts[intent.keys];
              callback?.call();
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: autofocus,
          child: child,
        ),
      ),
    );
  }

  /// Create focusable widget
  Widget createFocusableWidget({
    required Widget child,
    required String semanticLabel,
    VoidCallback? onPressed,
    VoidCallback? onFocusChange,
    bool canRequestFocus = true,
    bool autofocus = false,
    String? focusKey,
  }) {
    final focusNode = focusKey != null 
        ? (_namedFocusNodes[focusKey] ??= FocusNode())
        : FocusNode();

    return Focus(
      focusNode: focusNode,
      canRequestFocus: canRequestFocus,
      autofocus: autofocus,
      onFocusChange: (hasFocus) {
        if (hasFocus) {
          _currentFocus = focusNode;
        }
        onFocusChange?.call();
      },
      child: Builder(
        builder: (context) {
          final isFocused = Focus.of(context).hasFocus;
          
          return Container(
            decoration: _showFocusIndicator && isFocused
                ? BoxDecoration(
                    border: Border.all(
                      color: _focusIndicatorColor,
                      width: _focusIndicatorWidth,
                    ),
                  )
                : null,
            child: Semantics(
              label: semanticLabel,
              button: onPressed != null,
              focusable: canRequestFocus,
              focused: isFocused,
              onTap: onPressed,
              child: GestureDetector(
                onTap: onPressed,
                child: child,
              ),
            ),
          );
        },
      ),
    );
  }

  /// Create keyboard navigable list
  Widget createNavigableList({
    required List<Widget> children,
    bool vertical = true,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
  }) {
    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: vertical
          ? Column(
              crossAxisAlignment: crossAxisAlignment,
              mainAxisAlignment: mainAxisAlignment,
              children: children.map((child) => FocusTraversalOrder(
                order: NumericFocusOrder(children.indexOf(child).toDouble()),
                child: child,
              )).toList(),
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: mainAxisAlignment,
              children: children.map((child) => FocusTraversalOrder(
                order: NumericFocusOrder(children.indexOf(child).toDouble()),
                child: child,
              )).toList(),
            ),
    );
  }

  /// Create keyboard navigable grid
  Widget createNavigableGrid({
    required List<Widget> children,
    required int crossAxisCount,
    double mainAxisSpacing = 0.0,
    double crossAxisSpacing = 0.0,
  }) {
    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: GridView.count(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: mainAxisSpacing,
        crossAxisSpacing: crossAxisSpacing,
        children: children.asMap().entries.map((entry) {
          final index = entry.key;
          final child = entry.value;
          
          return FocusTraversalOrder(
            order: NumericFocusOrder(index.toDouble()),
            child: child,
          );
        }).toList(),
      ),
    );
  }

  /// Create skip link
  Widget createSkipLink({
    required String label,
    required VoidCallback onPressed,
    bool showOnFocus = true,
  }) {
    return Positioned(
      top: showOnFocus ? -100 : 16,
      left: 16,
      child: Focus(
        child: Builder(
          builder: (context) {
            final isFocused = Focus.of(context).hasFocus;
            return AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              top: isFocused ? 16 : -100,
              left: 16,
              child: createFocusableWidget(
                semanticLabel: label,
                onPressed: onPressed,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Focus specific element by key
  void focusElement(String key) {
    final node = _namedFocusNodes[key];
    if (node != null && node.canRequestFocus) {
      node.requestFocus();
    }
  }

  /// Clear all focus
  void clearFocus() {
    FocusManager.instance.primaryFocus?.unfocus();
    _currentFocus = null;
  }

  /// Enable keyboard navigation
  Future<void> enable() async {
    _isEnabled = true;
    await _saveSettings();
    debugPrint('Keyboard navigation enabled');
  }

  /// Disable keyboard navigation
  Future<void> disable() async {
    _isEnabled = false;
    await _saveSettings();
    debugPrint('Keyboard navigation disabled');
  }

  /// Set focus indicator properties
  Future<void> setFocusIndicator({
    bool? show,
    double? width,
    Color? color,
  }) async {
    if (show != null) _showFocusIndicator = show;
    if (width != null) _focusIndicatorWidth = width;
    if (color != null) _focusIndicatorColor = color;
    
    await _saveSettings();
  }

  /// Get current focus information
  FocusInformation getCurrentFocusInfo() {
    final currentFocus = FocusManager.instance.primaryFocus;
    
    return FocusInformation(
      hasFocus: currentFocus != null,
      focusPath: currentFocus?.debugLabel ?? 'None',
      canRequestFocus: currentFocus?.canRequestFocus ?? false,
      isKeyboardNavigable: _isEnabled,
    );
  }

  /// Get all registered focus nodes
  Map<String, bool> getFocusNodeStatus() {
    return _namedFocusNodes.map((key, node) => MapEntry(key, node.hasFocus));
  }

  /// Getters
  bool get isEnabled => _isEnabled;
  bool get showFocusIndicator => _showFocusIndicator;
  double get focusIndicatorWidth => _focusIndicatorWidth;
  Color get focusIndicatorColor => _focusIndicatorColor;
}

/// Focus information data class
class FocusInformation {
  final bool hasFocus;
  final String focusPath;
  final bool canRequestFocus;
  final bool isKeyboardNavigable;

  const FocusInformation({
    required this.hasFocus,
    required this.focusPath,
    required this.canRequestFocus,
    required this.isKeyboardNavigable,
  });

  @override
  String toString() {
    return 'FocusInformation('
        'hasFocus: $hasFocus, '
        'focusPath: $focusPath, '
        'canRequestFocus: $canRequestFocus, '
        'isKeyboardNavigable: $isKeyboardNavigable'
        ')';
  }
}

/// Custom intent for keyboard navigation
class _KeyboardNavigationIntent extends Intent {
  final LogicalKeySet keys;
  
  const _KeyboardNavigationIntent(this.keys);
}

/// Keyboard navigation widgets
class KeyboardNavigationWidgets {
  /// Create focusable card
  static Widget focusableCard({
    required Widget child,
    required String semanticLabel,
    VoidCallback? onPressed,
    bool autofocus = false,
  }) {
    final service = KeyboardNavigationService();
    
    return service.createFocusableWidget(
      semanticLabel: semanticLabel,
      onPressed: onPressed,
      autofocus: autofocus,
      child: Card(child: child),
    );
  }

  /// Create focusable button
  static Widget focusableButton({
    required Widget child,
    required String semanticLabel,
    required VoidCallback onPressed,
    bool autofocus = false,
  }) {
    final service = KeyboardNavigationService();
    
    return service.createFocusableWidget(
      semanticLabel: semanticLabel,
      onPressed: onPressed,
      autofocus: autofocus,
      child: ElevatedButton(
        onPressed: onPressed,
        child: child,
      ),
    );
  }

  /// Create focusable list tile
  static Widget focusableListTile({
    required String title,
    String? subtitle,
    Widget? leading,
    Widget? trailing,
    VoidCallback? onTap,
    bool autofocus = false,
  }) {
    final service = KeyboardNavigationService();
    
    return service.createFocusableWidget(
      semanticLabel: subtitle != null ? '$title, $subtitle' : title,
      onPressed: onTap,
      autofocus: autofocus,
      child: ListTile(
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle) : null,
        leading: leading,
        trailing: trailing,
        onTap: onTap,
      ),
    );
  }

  /// Create tab navigation
  static Widget createTabNavigation({
    required List<String> tabs,
    required int currentIndex,
    required ValueChanged<int> onTabSelected,
  }) {
    final service = KeyboardNavigationService();
    
    return service.createNavigableList(
      vertical: false,
      children: tabs.asMap().entries.map((entry) {
        final index = entry.key;
        final title = entry.value;
        final isSelected = index == currentIndex;
        
        return service.createFocusableWidget(
          semanticLabel: 'Tab $title, ${isSelected ? 'selected' : 'not selected'}',
          onPressed: () => onTabSelected(index),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Create breadcrumb navigation
  static Widget createBreadcrumb({
    required List<String> items,
    ValueChanged<int>? onItemTap,
  }) {
    final service = KeyboardNavigationService();
    
    return service.createNavigableList(
      vertical: false,
      children: items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final isLast = index == items.length - 1;
        
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            service.createFocusableWidget(
              semanticLabel: 'Breadcrumb $item',
              onPressed: onItemTap != null ? () => onItemTap(index) : null,
              child: Text(
                item,
                style: TextStyle(
                  color: isLast ? Colors.black : Colors.blue,
                  decoration: isLast ? null : TextDecoration.underline,
                ),
              ),
            ),
            if (!isLast) ...[
              const SizedBox(width: 4),
              const Text(' > '),
              const SizedBox(width: 4),
            ],
          ],
        );
      }).toList(),
    );
  }
}
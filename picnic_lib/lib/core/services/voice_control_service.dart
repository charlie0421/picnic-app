import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Voice control service for enhanced accessibility
class VoiceControlService {
  static final VoiceControlService _instance = VoiceControlService._internal();
  factory VoiceControlService() => _instance;
  VoiceControlService._internal();

  static const String _prefixKey = 'voice_control_';
  bool _isEnabled = false;
  bool _isListening = false;
  bool _isInitialized = false;
  String _currentLanguage = 'en-US';
  double _confidenceThreshold = 0.7;
  
  final Map<String, VoiceCommand> _commands = {};
  final List<String> _supportedLanguages = [
    'en-US', 'ko-KR', 'ja-JP', 'zh-CN', 'zh-TW'
  ];
  
  StreamController<VoiceResult>? _resultController;
  StreamController<VoiceStatus>? _statusController;
  Timer? _listeningTimer;

  /// Initialize voice control service
  Future<void> initialize() async {
    try {
      await _loadSettings();
      await _setupDefaultCommands();
      _resultController = StreamController<VoiceResult>.broadcast();
      _statusController = StreamController<VoiceStatus>.broadcast();
      _isInitialized = true;
      debugPrint('VoiceControlService initialized');
    } catch (e) {
      debugPrint('Failed to initialize VoiceControlService: $e');
    }
  }

  /// Load voice control settings
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isEnabled = prefs.getBool('${_prefixKey}enabled') ?? false;
    _currentLanguage = prefs.getString('${_prefixKey}language') ?? 'en-US';
    _confidenceThreshold = prefs.getDouble('${_prefixKey}confidence') ?? 0.7;
  }

  /// Save voice control settings
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('${_prefixKey}enabled', _isEnabled);
    await prefs.setString('${_prefixKey}language', _currentLanguage);
    await prefs.setDouble('${_prefixKey}confidence', _confidenceThreshold);
  }

  /// Setup default voice commands
  Future<void> _setupDefaultCommands() async {
    // Navigation commands
    _commands['go back'] = VoiceCommand(
      phrase: 'go back',
      description: 'Navigate back',
      action: () => _executeSystemAction('back'),
      category: VoiceCommandCategory.navigation,
    );

    _commands['go home'] = VoiceCommand(
      phrase: 'go home',
      description: 'Navigate to home',
      action: () => _executeSystemAction('home'),
      category: VoiceCommandCategory.navigation,
    );

    _commands['scroll up'] = VoiceCommand(
      phrase: 'scroll up',
      description: 'Scroll page up',
      action: () => _executeSystemAction('scroll_up'),
      category: VoiceCommandCategory.navigation,
    );

    _commands['scroll down'] = VoiceCommand(
      phrase: 'scroll down',
      description: 'Scroll page down',
      action: () => _executeSystemAction('scroll_down'),
      category: VoiceCommandCategory.navigation,
    );

    // UI interaction commands
    _commands['tap button'] = VoiceCommand(
      phrase: 'tap button',
      description: 'Tap the focused button',
      action: () => _executeSystemAction('tap'),
      category: VoiceCommandCategory.interaction,
    );

    _commands['open menu'] = VoiceCommand(
      phrase: 'open menu',
      description: 'Open the main menu',
      action: () => _executeSystemAction('menu'),
      category: VoiceCommandCategory.interaction,
    );

    _commands['close'] = VoiceCommand(
      phrase: 'close',
      description: 'Close current dialog or screen',
      action: () => _executeSystemAction('close'),
      category: VoiceCommandCategory.interaction,
    );

    // Accessibility commands
    _commands['start listening'] = VoiceCommand(
      phrase: 'start listening',
      description: 'Start voice recognition',
      action: () => startListening(),
      category: VoiceCommandCategory.accessibility,
    );

    _commands['stop listening'] = VoiceCommand(
      phrase: 'stop listening',
      description: 'Stop voice recognition',
      action: () => stopListening(),
      category: VoiceCommandCategory.accessibility,
    );

    _commands['repeat'] = VoiceCommand(
      phrase: 'repeat',
      description: 'Repeat last announcement',
      action: () => _executeSystemAction('repeat'),
      category: VoiceCommandCategory.accessibility,
    );

    // Text input commands
    _commands['clear text'] = VoiceCommand(
      phrase: 'clear text',
      description: 'Clear text field',
      action: () => _executeSystemAction('clear_text'),
      category: VoiceCommandCategory.textInput,
    );

    _commands['select all'] = VoiceCommand(
      phrase: 'select all',
      description: 'Select all text',
      action: () => _executeSystemAction('select_all'),
      category: VoiceCommandCategory.textInput,
    );

    // Language-specific commands
    await _addLanguageSpecificCommands();
  }

  /// Add language-specific commands
  Future<void> _addLanguageSpecificCommands() async {
    switch (_currentLanguage) {
      case 'ko-KR':
        _commands['뒤로 가기'] = VoiceCommand(
          phrase: '뒤로 가기',
          description: '이전 화면으로 이동',
          action: () => _executeSystemAction('back'),
          category: VoiceCommandCategory.navigation,
        );
        _commands['홈으로'] = VoiceCommand(
          phrase: '홈으로',
          description: '홈 화면으로 이동',
          action: () => _executeSystemAction('home'),
          category: VoiceCommandCategory.navigation,
        );
        _commands['위로 스크롤'] = VoiceCommand(
          phrase: '위로 스크롤',
          description: '페이지를 위로 스크롤',
          action: () => _executeSystemAction('scroll_up'),
          category: VoiceCommandCategory.navigation,
        );
        break;

      case 'ja-JP':
        _commands['戻る'] = VoiceCommand(
          phrase: '戻る',
          description: '前の画面に戻る',
          action: () => _executeSystemAction('back'),
          category: VoiceCommandCategory.navigation,
        );
        _commands['ホーム'] = VoiceCommand(
          phrase: 'ホーム',
          description: 'ホーム画面に移動',
          action: () => _executeSystemAction('home'),
          category: VoiceCommandCategory.navigation,
        );
        break;

      case 'zh-CN':
        _commands['返回'] = VoiceCommand(
          phrase: '返回',
          description: '返回上一屏幕',
          action: () => _executeSystemAction('back'),
          category: VoiceCommandCategory.navigation,
        );
        _commands['主页'] = VoiceCommand(
          phrase: '主页',
          description: '导航到主页',
          action: () => _executeSystemAction('home'),
          category: VoiceCommandCategory.navigation,
        );
        break;
    }
  }

  /// Execute system action
  void _executeSystemAction(String action) {
    switch (action) {
      case 'back':
        SystemNavigator.pop();
        break;
      case 'home':
        // Navigate to home - implementation depends on app structure
        debugPrint('Navigate to home');
        break;
      case 'scroll_up':
        // Scroll up implementation
        debugPrint('Scroll up');
        break;
      case 'scroll_down':
        // Scroll down implementation
        debugPrint('Scroll down');
        break;
      case 'tap':
        // Tap focused element
        HapticFeedback.lightImpact();
        debugPrint('Tap action');
        break;
      case 'menu':
        // Open menu
        debugPrint('Open menu');
        break;
      case 'close':
        // Close dialog/screen
        debugPrint('Close action');
        break;
      case 'repeat':
        // Repeat last announcement
        debugPrint('Repeat announcement');
        break;
      case 'clear_text':
        // Clear text field
        debugPrint('Clear text');
        break;
      case 'select_all':
        // Select all text
        debugPrint('Select all text');
        break;
    }
  }

  /// Start voice recognition
  Future<void> startListening() async {
    if (!_isInitialized || !_isEnabled || _isListening) return;

    try {
      _isListening = true;
      _statusController?.add(VoiceStatus.listening);
      
      // Simulate voice recognition start
      _listeningTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        // Simulated voice input processing
        _processVoiceInput();
      });

      debugPrint('Voice recognition started');
    } catch (e) {
      _isListening = false;
      _statusController?.add(VoiceStatus.error);
      debugPrint('Failed to start voice recognition: $e');
    }
  }

  /// Stop voice recognition
  Future<void> stopListening() async {
    if (!_isListening) return;

    try {
      _isListening = false;
      _listeningTimer?.cancel();
      _statusController?.add(VoiceStatus.stopped);
      debugPrint('Voice recognition stopped');
    } catch (e) {
      debugPrint('Failed to stop voice recognition: $e');
    }
  }

  /// Process voice input (simulation)
  void _processVoiceInput() {
    // This is a simulation - in real implementation, this would process actual speech
    final simulatedResults = [
      'go back',
      'scroll down',
      'tap button',
      'open menu',
      'close'
    ];

    if (simulatedResults.isNotEmpty) {
      final randomResult = simulatedResults[DateTime.now().millisecond % simulatedResults.length];
      final confidence = 0.8 + (DateTime.now().millisecond % 20) / 100;
      
      _handleVoiceResult(randomResult, confidence);
    }
  }

  /// Handle voice recognition result
  void _handleVoiceResult(String text, double confidence) {
    if (confidence < _confidenceThreshold) {
      _resultController?.add(VoiceResult(
        text: text,
        confidence: confidence,
        isCommand: false,
        timestamp: DateTime.now(),
      ));
      return;
    }

    final normalizedText = text.toLowerCase().trim();
    final command = _commands[normalizedText];
    
    if (command != null) {
      _resultController?.add(VoiceResult(
        text: text,
        confidence: confidence,
        isCommand: true,
        command: command,
        timestamp: DateTime.now(),
      ));
      
      // Execute command
      command.action();
      HapticFeedback.selectionClick();
    } else {
      // Check for partial matches
      final partialMatch = _findPartialMatch(normalizedText);
      
      _resultController?.add(VoiceResult(
        text: text,
        confidence: confidence,
        isCommand: partialMatch != null,
        command: partialMatch,
        timestamp: DateTime.now(),
      ));
      
      if (partialMatch != null) {
        partialMatch.action();
        HapticFeedback.selectionClick();
      }
    }
  }

  /// Find partial command match
  VoiceCommand? _findPartialMatch(String text) {
    for (final entry in _commands.entries) {
      if (entry.key.contains(text) || text.contains(entry.key)) {
        return entry.value;
      }
    }
    return null;
  }

  /// Add custom voice command
  void addCommand(String phrase, VoiceCommand command) {
    _commands[phrase.toLowerCase().trim()] = command;
  }

  /// Remove voice command
  void removeCommand(String phrase) {
    _commands.remove(phrase.toLowerCase().trim());
  }

  /// Set language
  Future<void> setLanguage(String languageCode) async {
    if (!_supportedLanguages.contains(languageCode)) {
      throw ArgumentError('Unsupported language: $languageCode');
    }
    
    _currentLanguage = languageCode;
    await _saveSettings();
    await _addLanguageSpecificCommands();
    debugPrint('Voice control language set to: $languageCode');
  }

  /// Set confidence threshold
  Future<void> setConfidenceThreshold(double threshold) async {
    _confidenceThreshold = threshold.clamp(0.0, 1.0);
    await _saveSettings();
    debugPrint('Confidence threshold set to: $_confidenceThreshold');
  }

  /// Enable voice control
  Future<void> enable() async {
    _isEnabled = true;
    await _saveSettings();
    debugPrint('Voice control enabled');
  }

  /// Disable voice control
  Future<void> disable() async {
    if (_isListening) {
      await stopListening();
    }
    _isEnabled = false;
    await _saveSettings();
    debugPrint('Voice control disabled');
  }

  /// Get available commands
  List<VoiceCommand> getAvailableCommands() {
    return _commands.values.toList();
  }

  /// Get commands by category
  List<VoiceCommand> getCommandsByCategory(VoiceCommandCategory category) {
    return _commands.values.where((cmd) => cmd.category == category).toList();
  }

  /// Get voice control status
  VoiceControlStatus getStatus() {
    return VoiceControlStatus(
      isEnabled: _isEnabled,
      isListening: _isListening,
      isInitialized: _isInitialized,
      currentLanguage: _currentLanguage,
      confidenceThreshold: _confidenceThreshold,
      commandCount: _commands.length,
    );
  }

  /// Dispose service
  void dispose() {
    _listeningTimer?.cancel();
    _resultController?.close();
    _statusController?.close();
  }

  /// Getters for streams
  Stream<VoiceResult>? get onResult => _resultController?.stream;
  Stream<VoiceStatus>? get onStatusChange => _statusController?.stream;
  
  /// Getters
  bool get isEnabled => _isEnabled;
  bool get isListening => _isListening;
  bool get isInitialized => _isInitialized;
  String get currentLanguage => _currentLanguage;
  double get confidenceThreshold => _confidenceThreshold;
  List<String> get supportedLanguages => List.unmodifiable(_supportedLanguages);
}

/// Voice command class
class VoiceCommand {
  final String phrase;
  final String description;
  final VoidCallback action;
  final VoiceCommandCategory category;
  final List<String> aliases;

  const VoiceCommand({
    required this.phrase,
    required this.description,
    required this.action,
    required this.category,
    this.aliases = const [],
  });
}

/// Voice command categories
enum VoiceCommandCategory {
  navigation,
  interaction,
  textInput,
  accessibility,
  custom,
}

/// Voice recognition result
class VoiceResult {
  final String text;
  final double confidence;
  final bool isCommand;
  final VoiceCommand? command;
  final DateTime timestamp;

  const VoiceResult({
    required this.text,
    required this.confidence,
    required this.isCommand,
    this.command,
    required this.timestamp,
  });
}

/// Voice recognition status
enum VoiceStatus {
  stopped,
  listening,
  processing,
  error,
}

/// Voice control status
class VoiceControlStatus {
  final bool isEnabled;
  final bool isListening;
  final bool isInitialized;
  final String currentLanguage;
  final double confidenceThreshold;
  final int commandCount;

  const VoiceControlStatus({
    required this.isEnabled,
    required this.isListening,
    required this.isInitialized,
    required this.currentLanguage,
    required this.confidenceThreshold,
    required this.commandCount,
  });

  @override
  String toString() {
    return 'VoiceControlStatus('
        'enabled: $isEnabled, '
        'listening: $isListening, '
        'initialized: $isInitialized, '
        'language: $currentLanguage, '
        'threshold: $confidenceThreshold, '
        'commands: $commandCount'
        ')';
  }
}

/// Voice control widgets
class VoiceControlWidgets {
  /// Voice control button
  static Widget voiceButton({
    VoidCallback? onPressed,
    bool isListening = false,
    Color? activeColor,
    Color? inactiveColor,
  }) {
    return FloatingActionButton(
      onPressed: onPressed,
      backgroundColor: isListening 
          ? (activeColor ?? Colors.red) 
          : (inactiveColor ?? Colors.blue),
      child: Icon(
        isListening ? Icons.mic : Icons.mic_none,
        color: Colors.white,
      ),
    );
  }

  /// Voice status indicator
  static Widget statusIndicator({
    required VoiceStatus status,
    double size = 16.0,
  }) {
    Color color;
    IconData icon;
    
    switch (status) {
      case VoiceStatus.listening:
        color = Colors.red;
        icon = Icons.fiber_manual_record;
        break;
      case VoiceStatus.processing:
        color = Colors.orange;
        icon = Icons.sync;
        break;
      case VoiceStatus.error:
        color = Colors.red;
        icon = Icons.error;
        break;
      case VoiceStatus.stopped:
      default:
        color = Colors.grey;
        icon = Icons.stop;
        break;
    }
    
    return Icon(icon, color: color, size: size);
  }

  /// Commands list widget
  static Widget commandsList({
    required List<VoiceCommand> commands,
    VoiceCommandCategory? filterCategory,
  }) {
    final filteredCommands = filterCategory != null
        ? commands.where((cmd) => cmd.category == filterCategory).toList()
        : commands;
    
    return ListView.builder(
      itemCount: filteredCommands.length,
      itemBuilder: (context, index) {
        final command = filteredCommands[index];
        
        return ListTile(
          title: Text(command.phrase),
          subtitle: Text(command.description),
          leading: Icon(_getCategoryIcon(command.category)),
          onTap: () => command.action(),
        );
      },
    );
  }

  /// Get category icon
  static IconData _getCategoryIcon(VoiceCommandCategory category) {
    switch (category) {
      case VoiceCommandCategory.navigation:
        return Icons.navigation;
      case VoiceCommandCategory.interaction:
        return Icons.touch_app;
      case VoiceCommandCategory.textInput:
        return Icons.text_fields;
      case VoiceCommandCategory.accessibility:
        return Icons.accessibility;
      case VoiceCommandCategory.custom:
        return Icons.extension;
    }
  }
}
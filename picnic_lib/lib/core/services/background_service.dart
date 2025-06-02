import 'dart:async';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

/// Background service for efficient background execution
class BackgroundService {
  static final BackgroundService _instance = BackgroundService._internal();
  factory BackgroundService() => _instance;
  BackgroundService._internal();

  bool _isInitialized = false;
  final Map<String, Isolate> _activeIsolates = {};
  final Map<String, StreamSubscription> _isolateSubscriptions = {};
  final List<Timer> _periodicTasks = [];

  /// Initialize background service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Request battery optimization permission
      await _requestBatteryOptimizationPermission();
      _isInitialized = true;
      debugPrint('BackgroundService initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize BackgroundService: $e');
      rethrow;
    }
  }

  /// Request battery optimization permission
  Future<void> _requestBatteryOptimizationPermission() async {
    if (await Permission.ignoreBatteryOptimizations.isDenied) {
      await Permission.ignoreBatteryOptimizations.request();
    }
  }

  /// Register periodic task using Timer
  void registerPeriodicTask({
    required String taskName,
    required Duration frequency,
    required VoidCallback callback,
  }) {
    if (!_isInitialized) {
      throw StateError('BackgroundService not initialized');
    }

    final timer = Timer.periodic(frequency, (timer) {
      try {
        debugPrint('Executing periodic task: $taskName');
        callback();
      } catch (e) {
        debugPrint('Periodic task failed: $taskName, Error: $e');
      }
    });

    _periodicTasks.add(timer);
    debugPrint('Registered periodic task: $taskName');
  }

  /// Start isolate for background execution
  Future<void> startBackgroundIsolate({
    required String isolateName,
    required Function entryPoint,
    Map<String, dynamic>? data,
  }) async {
    if (_activeIsolates.containsKey(isolateName)) {
      debugPrint('Isolate $isolateName already running');
      return;
    }

    try {
      final receivePort = ReceivePort();
      final isolate = await Isolate.spawn(
        _isolateEntryPoint,
        IsolateData(
          sendPort: receivePort.sendPort,
          entryPoint: entryPoint,
          data: data ?? {},
        ),
      );

      _activeIsolates[isolateName] = isolate;

      // Listen for messages from isolate
      final subscription = receivePort.listen((message) {
        _handleIsolateMessage(isolateName, message);
      });
      _isolateSubscriptions[isolateName] = subscription;

      debugPrint('Started background isolate: $isolateName');
    } catch (e) {
      debugPrint('Failed to start isolate $isolateName: $e');
      rethrow;
    }
  }

  /// Stop background isolate
  Future<void> stopBackgroundIsolate(String isolateName) async {
    final isolate = _activeIsolates[isolateName];
    final subscription = _isolateSubscriptions[isolateName];

    if (isolate != null) {
      isolate.kill(priority: Isolate.immediate);
      _activeIsolates.remove(isolateName);
      debugPrint('Stopped isolate: $isolateName');
    }

    if (subscription != null) {
      await subscription.cancel();
      _isolateSubscriptions.remove(isolateName);
    }
  }

  /// Handle messages from isolates
  void _handleIsolateMessage(String isolateName, dynamic message) {
    if (message is IsolateMessage) {
      switch (message.type) {
        case IsolateMessageType.log:
          debugPrint('Isolate $isolateName: ${message.data}');
          break;
        case IsolateMessageType.error:
          debugPrint('Isolate $isolateName error: ${message.data}');
          break;
        case IsolateMessageType.completed:
          debugPrint('Isolate $isolateName completed: ${message.data}');
          stopBackgroundIsolate(isolateName);
          break;
        case IsolateMessageType.progress:
          debugPrint('Isolate $isolateName progress: ${message.data}');
          break;
      }
    }
  }

  /// Cancel all tasks
  Future<void> cancelAllTasks() async {
    // Stop all periodic tasks
    for (final timer in _periodicTasks) {
      timer.cancel();
    }
    _periodicTasks.clear();

    // Stop all active isolates
    for (final isolateName in _activeIsolates.keys.toList()) {
      await stopBackgroundIsolate(isolateName);
    }

    debugPrint('Cancelled all background tasks');
  }

  /// Get active isolates
  List<String> get activeIsolates => _activeIsolates.keys.toList();

  /// Check if isolate is active
  bool isIsolateActive(String isolateName) {
    return _activeIsolates.containsKey(isolateName);
  }

  /// Dispose service
  Future<void> dispose() async {
    await cancelAllTasks();
    _isInitialized = false;
    debugPrint('BackgroundService disposed');
  }
}

/// Entry point for isolates
@pragma('vm:entry-point')
void _isolateEntryPoint(IsolateData data) async {
  try {
    final sendPort = data.sendPort;

    // Send log message
    sendPort.send(IsolateMessage(
      type: IsolateMessageType.log,
      data: 'Isolate started',
    ));

    // Execute the entry point function
    if (data.entryPoint is Function) {
      await data.entryPoint(data.data);
    }

    // Send completion message
    sendPort.send(IsolateMessage(
      type: IsolateMessageType.completed,
      data: 'Task completed successfully',
    ));
  } catch (e) {
    // Send error message
    data.sendPort.send(IsolateMessage(
      type: IsolateMessageType.error,
      data: e.toString(),
    ));
  }
}

/// Data class for isolate communication
class IsolateData {
  final SendPort sendPort;
  final Function entryPoint;
  final Map<String, dynamic> data;

  IsolateData({
    required this.sendPort,
    required this.entryPoint,
    required this.data,
  });
}

/// Message types for isolate communication
enum IsolateMessageType {
  log,
  error,
  completed,
  progress,
}

/// Message class for isolate communication
class IsolateMessage {
  final IsolateMessageType type;
  final dynamic data;

  IsolateMessage({
    required this.type,
    required this.data,
  });
}

/// Background service helper
class BackgroundServiceHelper {
  /// Execute background data processing
  static Future<void> processDataInBackground(
    String taskName,
    List<Map<String, dynamic>> data,
    Function(Map<String, dynamic>) processor,
  ) async {
    final service = BackgroundService();

    await service.startBackgroundIsolate(
      isolateName: taskName,
      entryPoint: (Map<String, dynamic> isolateData) async {
        final dataList = isolateData['data'] as List<Map<String, dynamic>>;
        final results = <Map<String, dynamic>>[];

        for (int i = 0; i < dataList.length; i++) {
          final item = dataList[i];
          final result = await processor(item);
          results.add(result);

          // Send progress update every 10 items
          if (i % 10 == 0) {
            // Progress reporting implementation would go here
          }
        }

        return results;
      },
      data: {'data': data},
    );
  }
}

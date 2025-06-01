import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'background_service.dart';

/// Geofencing service for battery-efficient location monitoring
class GeofencingService {
  static final GeofencingService _instance = GeofencingService._internal();
  factory GeofencingService() => _instance;
  GeofencingService._internal();

  final Map<String, Geofence> _geofences = {};
  final List<GeofenceEvent> _eventHistory = [];
  StreamSubscription<Position>? _positionSubscription;
  Position? _lastKnownPosition;
  Timer? _periodicLocationTimer;
  bool _isMonitoring = false;
  
  // Battery optimization settings
  LocationAccuracy _currentAccuracy = LocationAccuracy.balanced;
  Duration _updateInterval = const Duration(minutes: 5);
  int _maxEventHistory = 100;

  /// Initialize geofencing service
  Future<void> initialize() async {
    try {
      await _requestLocationPermissions();
      debugPrint('GeofencingService initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize GeofencingService: $e');
      rethrow;
    }
  }

  /// Request location permissions
  Future<void> _requestLocationPermissions() async {
    final locationPermission = await Permission.location.status;
    final locationAlwaysPermission = await Permission.locationAlways.status;

    if (locationPermission.isDenied) {
      final result = await Permission.location.request();
      if (result.isDenied) {
        throw Exception('Location permission denied');
      }
    }

    if (locationAlwaysPermission.isDenied) {
      final result = await Permission.locationAlways.request();
      if (result.isDenied) {
        debugPrint('Background location permission denied - limited functionality');
      }
    }
  }

  /// Add geofence
  Future<void> addGeofence(Geofence geofence) async {
    _geofences[geofence.id] = geofence;
    debugPrint('Added geofence: ${geofence.id}');
    
    if (!_isMonitoring) {
      await startMonitoring();
    }
  }

  /// Remove geofence
  Future<void> removeGeofence(String geofenceId) async {
    final removed = _geofences.remove(geofenceId);
    if (removed != null) {
      debugPrint('Removed geofence: $geofenceId');
    }
    
    if (_geofences.isEmpty && _isMonitoring) {
      await stopMonitoring();
    }
  }

  /// Start location monitoring
  Future<void> startMonitoring() async {
    if (_isMonitoring) return;
    
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      // Get initial position
      _lastKnownPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: _currentAccuracy,
        timeLimit: const Duration(seconds: 30),
      );

      // Start position stream with battery-optimized settings
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: _currentAccuracy,
          distanceFilter: 10, // Only update when moved 10 meters
          timeLimit: const Duration(seconds: 30),
        ),
      ).listen(
        _onPositionUpdate,
        onError: _onLocationError,
      );

      // Start periodic location checks as backup
      _startPeriodicLocationCheck();

      _isMonitoring = true;
      debugPrint('Started geofencing monitoring');
    } catch (e) {
      debugPrint('Failed to start monitoring: $e');
      rethrow;
    }
  }

  /// Stop location monitoring
  Future<void> stopMonitoring() async {
    if (!_isMonitoring) return;

    await _positionSubscription?.cancel();
    _positionSubscription = null;
    
    _periodicLocationTimer?.cancel();
    _periodicLocationTimer = null;

    _isMonitoring = false;
    debugPrint('Stopped geofencing monitoring');
  }

  /// Start periodic location check for battery efficiency
  void _startPeriodicLocationCheck() {
    _periodicLocationTimer = Timer.periodic(_updateInterval, (timer) async {
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: _currentAccuracy,
          timeLimit: const Duration(seconds: 15),
        );
        _onPositionUpdate(position);
      } catch (e) {
        debugPrint('Periodic location check failed: $e');
      }
    });
  }

  /// Handle position updates
  void _onPositionUpdate(Position position) {
    _lastKnownPosition = position;
    _checkGeofences(position);
    _optimizeLocationSettings(position);
  }

  /// Check all geofences for entry/exit events
  void _checkGeofences(Position position) {
    for (final geofence in _geofences.values) {
      final distance = _calculateDistance(
        position.latitude,
        position.longitude,
        geofence.latitude,
        geofence.longitude,
      );

      final isInside = distance <= geofence.radius;
      final wasInside = geofence.isInside;

      if (isInside != wasInside) {
        geofence._updateState(isInside);
        
        final event = GeofenceEvent(
          geofenceId: geofence.id,
          type: isInside ? GeofenceEventType.enter : GeofenceEventType.exit,
          timestamp: DateTime.now(),
          position: position,
          distance: distance,
        );

        _addEvent(event);
        _notifyGeofenceEvent(event);
      }
    }
  }

  /// Optimize location settings based on proximity to geofences
  void _optimizeLocationSettings(Position position) {
    double minDistance = double.infinity;
    
    for (final geofence in _geofences.values) {
      final distance = _calculateDistance(
        position.latitude,
        position.longitude,
        geofence.latitude,
        geofence.longitude,
      );
      minDistance = math.min(minDistance, distance);
    }

    // Adjust accuracy and update interval based on proximity
    if (minDistance < 100) {
      // Close to geofence - high accuracy, frequent updates
      _currentAccuracy = LocationAccuracy.high;
      _updateInterval = const Duration(minutes: 1);
    } else if (minDistance < 500) {
      // Moderate distance - balanced accuracy
      _currentAccuracy = LocationAccuracy.medium;
      _updateInterval = const Duration(minutes: 3);
    } else {
      // Far from geofences - low accuracy, infrequent updates
      _currentAccuracy = LocationAccuracy.low;
      _updateInterval = const Duration(minutes: 10);
    }
  }

  /// Calculate distance between two points
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  /// Add event to history
  void _addEvent(GeofenceEvent event) {
    _eventHistory.add(event);
    
    // Limit event history size for memory efficiency
    while (_eventHistory.length > _maxEventHistory) {
      _eventHistory.removeAt(0);
    }
  }

  /// Notify geofence event
  void _notifyGeofenceEvent(GeofenceEvent event) {
    debugPrint('Geofence event: ${event.type.name} for ${event.geofenceId}');
    
    // Trigger background task for handling the event
    _scheduleBackgroundEventHandler(event);
  }

  /// Schedule background event handler
  void _scheduleBackgroundEventHandler(GeofenceEvent event) {
    final backgroundService = BackgroundService();
    
    backgroundService.registerOneOffTask(
      taskName: 'geofence_event_${event.geofenceId}_${DateTime.now().millisecondsSinceEpoch}',
      inputData: {
        'geofenceId': event.geofenceId,
        'eventType': event.type.name,
        'timestamp': event.timestamp.toIso8601String(),
        'latitude': event.position.latitude,
        'longitude': event.position.longitude,
      },
      initialDelay: const Duration(seconds: 1),
    );
  }

  /// Handle location errors
  void _onLocationError(dynamic error) {
    debugPrint('Location error: $error');
    
    // Implement fallback strategies
    if (error is LocationServiceDisabledException) {
      stopMonitoring();
    } else if (error is PermissionDeniedException) {
      stopMonitoring();
    }
  }

  /// Get all geofences
  List<Geofence> get geofences => _geofences.values.toList();

  /// Get event history
  List<GeofenceEvent> get eventHistory => List.unmodifiable(_eventHistory);

  /// Get last known position
  Position? get lastKnownPosition => _lastKnownPosition;

  /// Check if monitoring is active
  bool get isMonitoring => _isMonitoring;

  /// Get geofence by id
  Geofence? getGeofence(String id) => _geofences[id];

  /// Clear event history
  void clearEventHistory() {
    _eventHistory.clear();
    debugPrint('Cleared geofence event history');
  }

  /// Set battery optimization level
  void setBatteryOptimizationLevel(BatteryOptimizationLevel level) {
    switch (level) {
      case BatteryOptimizationLevel.aggressive:
        _currentAccuracy = LocationAccuracy.lowest;
        _updateInterval = const Duration(minutes: 15);
        break;
      case BatteryOptimizationLevel.balanced:
        _currentAccuracy = LocationAccuracy.medium;
        _updateInterval = const Duration(minutes: 5);
        break;
      case BatteryOptimizationLevel.performance:
        _currentAccuracy = LocationAccuracy.high;
        _updateInterval = const Duration(minutes: 1);
        break;
    }
    
    debugPrint('Battery optimization level set to: ${level.name}');
  }

  /// Dispose service
  Future<void> dispose() async {
    await stopMonitoring();
    _geofences.clear();
    _eventHistory.clear();
    debugPrint('GeofencingService disposed');
  }
}

/// Geofence definition
class Geofence {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double radius;
  final GeofenceAction action;
  bool _isInside = false;
  DateTime? _lastUpdate;

  Geofence({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radius,
    this.action = GeofenceAction.notify,
  });

  bool get isInside => _isInside;
  DateTime? get lastUpdate => _lastUpdate;

  void _updateState(bool isInside) {
    _isInside = isInside;
    _lastUpdate = DateTime.now();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'radius': radius,
      'action': action.name,
      'isInside': _isInside,
      'lastUpdate': _lastUpdate?.toIso8601String(),
    };
  }

  factory Geofence.fromMap(Map<String, dynamic> map) {
    final geofence = Geofence(
      id: map['id'] as String,
      name: map['name'] as String,
      latitude: map['latitude'] as double,
      longitude: map['longitude'] as double,
      radius: map['radius'] as double,
      action: GeofenceAction.values.firstWhere(
        (e) => e.name == map['action'],
        orElse: () => GeofenceAction.notify,
      ),
    );
    
    geofence._isInside = map['isInside'] as bool? ?? false;
    final lastUpdateStr = map['lastUpdate'] as String?;
    if (lastUpdateStr != null) {
      geofence._lastUpdate = DateTime.parse(lastUpdateStr);
    }
    
    return geofence;
  }
}

/// Geofence event
class GeofenceEvent {
  final String geofenceId;
  final GeofenceEventType type;
  final DateTime timestamp;
  final Position position;
  final double distance;

  const GeofenceEvent({
    required this.geofenceId,
    required this.type,
    required this.timestamp,
    required this.position,
    required this.distance,
  });

  Map<String, dynamic> toMap() {
    return {
      'geofenceId': geofenceId,
      'type': type.name,
      'timestamp': timestamp.toIso8601String(),
      'latitude': position.latitude,
      'longitude': position.longitude,
      'distance': distance,
    };
  }
}

/// Geofence event types
enum GeofenceEventType {
  enter,
  exit,
}

/// Geofence actions
enum GeofenceAction {
  notify,
  track,
  trigger,
}

/// Battery optimization levels
enum BatteryOptimizationLevel {
  aggressive,
  balanced,
  performance,
}

/// Geofencing service helper
class GeofencingServiceHelper {
  /// Create geofence around current location
  static Future<Geofence?> createGeofenceHere({
    required String name,
    required double radius,
    GeofenceAction action = GeofenceAction.notify,
  }) async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return Geofence(
        id: 'geofence_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        latitude: position.latitude,
        longitude: position.longitude,
        radius: radius,
        action: action,
      );
    } catch (e) {
      debugPrint('Failed to create geofence at current location: $e');
      return null;
    }
  }

  /// Import geofences from list
  static Future<void> importGeofences(List<Map<String, dynamic>> geofenceData) async {
    final service = GeofencingService();
    
    for (final data in geofenceData) {
      try {
        final geofence = Geofence.fromMap(data);
        await service.addGeofence(geofence);
      } catch (e) {
        debugPrint('Failed to import geofence: $e');
      }
    }
  }

  /// Export geofences to list
  static List<Map<String, dynamic>> exportGeofences() {
    final service = GeofencingService();
    return service.geofences.map((geofence) => geofence.toMap()).toList();
  }

  /// Get distance to nearest geofence
  static double? getDistanceToNearestGeofence(Position position) {
    final service = GeofencingService();
    double? minDistance;

    for (final geofence in service.geofences) {
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        geofence.latitude,
        geofence.longitude,
      );

      if (minDistance == null || distance < minDistance) {
        minDistance = distance;
      }
    }

    return minDistance;
  }

  /// Check if position is inside any geofence
  static bool isInsideAnyGeofence(Position position) {
    final service = GeofencingService();
    
    for (final geofence in service.geofences) {
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        geofence.latitude,
        geofence.longitude,
      );

      if (distance <= geofence.radius) {
        return true;
      }
    }

    return false;
  }
}
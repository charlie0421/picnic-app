import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/foundation.dart';
import 'dart:math' as math;

/// Available scroll physics types
enum ScrollPhysicsType {
  bouncing,
  clamping,
  custom,
  elastic,
  smooth,
  snapping,
}

/// Custom scroll physics service for optimized scrolling experience
class ScrollPhysicsService {
  static final ScrollPhysicsService _instance =
      ScrollPhysicsService._internal();
  factory ScrollPhysicsService() => _instance;
  ScrollPhysicsService._internal();

  /// Platform-specific physics configuration
  static const Map<TargetPlatform, ScrollPhysicsType> _platformDefaults = {
    TargetPlatform.iOS: ScrollPhysicsType.bouncing,
    TargetPlatform.android: ScrollPhysicsType.clamping,
    TargetPlatform.fuchsia: ScrollPhysicsType.clamping,
    TargetPlatform.linux: ScrollPhysicsType.clamping,
    TargetPlatform.macOS: ScrollPhysicsType.bouncing,
    TargetPlatform.windows: ScrollPhysicsType.clamping,
  };

  /// Get platform-appropriate scroll physics
  ScrollPhysics getPlatformPhysics() {
    final platform = defaultTargetPlatform;
    final physicsType =
        _platformDefaults[platform] ?? ScrollPhysicsType.clamping;
    return getPhysics(physicsType);
  }

  /// Get specific scroll physics by type
  ScrollPhysics getPhysics(ScrollPhysicsType type) {
    switch (type) {
      case ScrollPhysicsType.bouncing:
        return const BouncingScrollPhysics();
      case ScrollPhysicsType.clamping:
        return const ClampingScrollPhysics();
      case ScrollPhysicsType.custom:
        return const CustomScrollPhysics();
      case ScrollPhysicsType.elastic:
        return const ElasticScrollPhysics();
      case ScrollPhysicsType.smooth:
        return const SmoothScrollPhysics();
      case ScrollPhysicsType.snapping:
        return const SnappingScrollPhysics();
    }
  }

  /// Get optimized physics for lists
  ScrollPhysics getListPhysics() {
    return const OptimizedListScrollPhysics();
  }

  /// Get optimized physics for grids
  ScrollPhysics getGridPhysics() {
    return const OptimizedGridScrollPhysics();
  }

  /// Get physics for infinite scrolling
  ScrollPhysics getInfiniteScrollPhysics() {
    return const InfiniteScrollPhysics();
  }
}

/// Custom scroll physics with optimized behavior
class CustomScrollPhysics extends ScrollPhysics {
  const CustomScrollPhysics({super.parent});

  @override
  CustomScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return CustomScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  double frictionFactor(double overscrollFraction) {
    return 0.52 * math.pow(1 - overscrollFraction, 2);
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    final tolerance = toleranceFor(position);

    if (position.outOfRange) {
      double? end;
      if (position.pixels > position.maxScrollExtent) {
        end = position.maxScrollExtent;
      }
      if (position.pixels < position.minScrollExtent) {
        end = position.minScrollExtent;
      }

      if (end != null) {
        return ScrollSpringSimulation(
          spring,
          position.pixels,
          end,
          math.min(0.0, velocity),
          tolerance: tolerance,
        );
      }
    }

    if (velocity.abs() < tolerance.velocity) {
      return null;
    }

    if (velocity > 0.0 && position.pixels >= position.maxScrollExtent) {
      return null;
    }
    if (velocity < 0.0 && position.pixels <= position.minScrollExtent) {
      return null;
    }

    return ClampingScrollSimulation(
      position: position.pixels,
      velocity: velocity,
      tolerance: tolerance,
    );
  }

  @override
  SpringDescription get spring => SpringDescription.withDampingRatio(
        mass: 0.5,
        stiffness: 100.0,
        ratio: 1.1,
      );
}

/// Elastic scroll physics with rubber band effect
class ElasticScrollPhysics extends ScrollPhysics {
  const ElasticScrollPhysics({super.parent});

  @override
  ElasticScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return ElasticScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  double frictionFactor(double overscrollFraction) {
    return 0.52 * math.pow(1 - overscrollFraction, 2);
  }

  @override
  SpringDescription get spring => SpringDescription.withDampingRatio(
        mass: 0.3,
        stiffness: 120.0,
        ratio: 0.9,
      );
}

/// Smooth scroll physics for fluid animations
class SmoothScrollPhysics extends ScrollPhysics {
  const SmoothScrollPhysics({super.parent});

  @override
  SmoothScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return SmoothScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  double frictionFactor(double overscrollFraction) {
    return 0.48 * math.pow(1 - overscrollFraction, 2.5);
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    final tolerance = toleranceFor(position);

    if (velocity.abs() < tolerance.velocity) {
      return null;
    }

    return FrictionSimulation.through(
      position.pixels,
      position.pixels + velocity * 0.2,
      velocity,
      tolerance.velocity * 0.5,
    );
  }
}

/// Snapping scroll physics for grid or list items
class SnappingScrollPhysics extends ScrollPhysics {
  final double snapSize;

  const SnappingScrollPhysics({
    super.parent,
    this.snapSize = 100.0,
  });

  @override
  SnappingScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return SnappingScrollPhysics(
      parent: buildParent(ancestor),
      snapSize: snapSize,
    );
  }

  double _getTargetPixels(double position, double velocity) {
    final snapPosition = (position / snapSize).round() * snapSize;

    if (velocity.abs() > 100) {
      if (velocity > 0) {
        return snapPosition + snapSize;
      } else {
        return snapPosition - snapSize;
      }
    }

    return snapPosition;
  }

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    final tolerance = toleranceFor(position);
    final target = _getTargetPixels(position.pixels, velocity);

    if ((target - position.pixels).abs() < tolerance.distance) {
      return null;
    }

    return ScrollSpringSimulation(
      spring,
      position.pixels,
      target,
      velocity,
      tolerance: tolerance,
    );
  }

  @override
  SpringDescription get spring => SpringDescription.withDampingRatio(
        mass: 0.4,
        stiffness: 100.0,
        ratio: 1.0,
      );
}

/// Optimized scroll physics for lists
class OptimizedListScrollPhysics extends ScrollPhysics {
  const OptimizedListScrollPhysics({super.parent});

  @override
  OptimizedListScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return OptimizedListScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  double frictionFactor(double overscrollFraction) {
    // Reduced friction for smoother scrolling in lists
    return 0.45 * math.pow(1 - overscrollFraction, 2);
  }

  @override
  double get dragStartDistanceMotionThreshold => 3.5;

  @override
  double get minFlingDistance => 25.0;

  @override
  double get minFlingVelocity => 50.0;

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    final tolerance = toleranceFor(position);

    if (velocity.abs() < tolerance.velocity) {
      return null;
    }

    // Enhanced friction simulation for better deceleration
    return FrictionSimulation(
      0.135, // Reduced drag coefficient for smoother scrolling
      position.pixels,
      velocity,
      tolerance: tolerance,
    );
  }
}

/// Optimized scroll physics for grids
class OptimizedGridScrollPhysics extends ScrollPhysics {
  const OptimizedGridScrollPhysics({super.parent});

  @override
  OptimizedGridScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return OptimizedGridScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  double frictionFactor(double overscrollFraction) {
    // Slightly higher friction for grid stability
    return 0.55 * math.pow(1 - overscrollFraction, 2);
  }

  @override
  double get dragStartDistanceMotionThreshold => 2.0;

  @override
  double get minFlingDistance => 30.0;

  @override
  double get minFlingVelocity => 75.0;
}

/// Physics for infinite scrolling scenarios
class InfiniteScrollPhysics extends ScrollPhysics {
  const InfiniteScrollPhysics({super.parent});

  @override
  InfiniteScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return InfiniteScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  bool shouldAcceptUserOffset(ScrollMetrics position) {
    // Always allow scrolling for infinite scroll
    return true;
  }

  @override
  double frictionFactor(double overscrollFraction) {
    // Minimal overscroll for infinite lists
    return 0.3 * math.pow(1 - overscrollFraction, 3);
  }

  @override
  double get minFlingVelocity => 25.0;

  @override
  Simulation? createBallisticSimulation(
    ScrollMetrics position,
    double velocity,
  ) {
    final tolerance = toleranceFor(position);

    if (velocity.abs() < tolerance.velocity) {
      return null;
    }

    // Optimized for continuous scrolling
    return FrictionSimulation(
      0.12, // Lower friction for infinite scrolling
      position.pixels,
      velocity,
      tolerance: tolerance,
    );
  }
}

/// Scroll physics manager for dynamic physics switching
class ScrollPhysicsManager {
  static final ScrollPhysicsManager _instance =
      ScrollPhysicsManager._internal();
  factory ScrollPhysicsManager() => _instance;
  ScrollPhysicsManager._internal();

  ScrollPhysicsType _currentType = ScrollPhysicsType.custom;
  final ScrollPhysicsService _service = ScrollPhysicsService();

  ScrollPhysicsType get currentType => _currentType;

  void setPhysicsType(ScrollPhysicsType type) {
    _currentType = type;
  }

  ScrollPhysics getCurrentPhysics() {
    return _service.getPhysics(_currentType);
  }

  /// Get physics based on content type
  ScrollPhysics getPhysicsForContent(String contentType) {
    switch (contentType.toLowerCase()) {
      case 'list':
        return _service.getListPhysics();
      case 'grid':
        return _service.getGridPhysics();
      case 'infinite':
        return _service.getInfiniteScrollPhysics();
      default:
        return _service.getPlatformPhysics();
    }
  }

  /// Auto-select physics based on scroll behavior
  ScrollPhysics getAdaptivePhysics(ScrollMetrics metrics) {
    // If content is shorter than viewport, use bouncing physics
    if (metrics.maxScrollExtent <= 0) {
      return _service.getPhysics(ScrollPhysicsType.bouncing);
    }

    // For long lists, use optimized list physics
    if (metrics.maxScrollExtent > 2000) {
      return _service.getListPhysics();
    }

    // Default to platform physics
    return _service.getPlatformPhysics();
  }
}

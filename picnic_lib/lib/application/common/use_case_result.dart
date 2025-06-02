/// Represents the result of a use case execution
/// Can be either success or failure
sealed class UseCaseResult<T> {
  const UseCaseResult();

  /// Create a successful result
  factory UseCaseResult.success(T data) = UseCaseSuccess<T>;

  /// Create a failure result
  factory UseCaseResult.failure(UseCaseFailure failure) = UseCaseFailureResult<T>;

  /// Check if the result is successful
  bool get isSuccess => this is UseCaseSuccess<T>;

  /// Check if the result is a failure
  bool get isFailure => this is UseCaseFailureResult<T>;

  /// Get the data if successful, null otherwise
  T? get data => switch (this) {
    UseCaseSuccess<T>(data: final data) => data,
    UseCaseFailureResult<T>() => null,
  };

  /// Get the failure if failed, null otherwise
  UseCaseFailure? get failure => switch (this) {
    UseCaseSuccess<T>() => null,
    UseCaseFailureResult<T>(failure: final failure) => failure,
  };

  /// Transform the data if successful
  UseCaseResult<R> map<R>(R Function(T data) transform) {
    return switch (this) {
      UseCaseSuccess<T>(data: final data) => UseCaseResult.success(transform(data)),
      UseCaseFailureResult<T>(failure: final failure) => UseCaseResult.failure(failure),
    };
  }

  /// Transform the data if successful, can return failure
  UseCaseResult<R> flatMap<R>(UseCaseResult<R> Function(T data) transform) {
    return switch (this) {
      UseCaseSuccess<T>(data: final data) => transform(data),
      UseCaseFailureResult<T>(failure: final failure) => UseCaseResult.failure(failure),
    };
  }

  /// Execute a callback when successful
  UseCaseResult<T> onSuccess(void Function(T data) callback) {
    if (this is UseCaseSuccess<T>) {
      callback((this as UseCaseSuccess<T>).data);
    }
    return this;
  }

  /// Execute a callback when failed
  UseCaseResult<T> onFailure(void Function(UseCaseFailure failure) callback) {
    if (this is UseCaseFailureResult<T>) {
      callback((this as UseCaseFailureResult<T>).failure);
    }
    return this;
  }

  /// Get data or throw exception
  T getOrThrow() {
    return switch (this) {
      UseCaseSuccess<T>(data: final data) => data,
      UseCaseFailureResult<T>(failure: final failure) => throw UseCaseException(failure),
    };
  }

  /// Get data or return default value
  T getOrElse(T defaultValue) {
    return switch (this) {
      UseCaseSuccess<T>(data: final data) => data,
      UseCaseFailureResult<T>() => defaultValue,
    };
  }

  /// Get data or compute default value
  T getOrElseCompute(T Function() computeDefault) {
    return switch (this) {
      UseCaseSuccess<T>(data: final data) => data,
      UseCaseFailureResult<T>() => computeDefault(),
    };
  }
}

/// Successful use case result
final class UseCaseSuccess<T> extends UseCaseResult<T> {
  final T data;

  const UseCaseSuccess(this.data);

  @override
  String toString() => 'UseCaseSuccess($data)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UseCaseSuccess<T> && other.data == data;
  }

  @override
  int get hashCode => data.hashCode;
}

/// Failed use case result
final class UseCaseFailureResult<T> extends UseCaseResult<T> {
  final UseCaseFailure failure;

  const UseCaseFailureResult(this.failure);

  @override
  String toString() => 'UseCaseFailureResult($failure)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UseCaseFailureResult<T> && other.failure == failure;
  }

  @override
  int get hashCode => failure.hashCode;
}

/// Represents different types of use case failures
sealed class UseCaseFailure {
  final String message;
  final String? code;
  final Map<String, dynamic>? details;

  const UseCaseFailure(this.message, {this.code, this.details});

  /// Invalid input parameters
  factory UseCaseFailure.invalidInput(String message, {String? code, Map<String, dynamic>? details}) =
      InvalidInputFailure;

  /// Resource not found
  factory UseCaseFailure.notFound(String message, {String? code, Map<String, dynamic>? details}) =
      NotFoundFailure;

  /// Business rule violation
  factory UseCaseFailure.businessRule(String message, {String? code, Map<String, dynamic>? details}) =
      BusinessRuleFailure;

  /// Permission denied
  factory UseCaseFailure.permissionDenied(String message, {String? code, Map<String, dynamic>? details}) =
      PermissionDeniedFailure;

  /// Network or connectivity issue
  factory UseCaseFailure.network(String message, {String? code, Map<String, dynamic>? details}) =
      NetworkFailure;

  /// Server error
  factory UseCaseFailure.server(String message, {String? code, Map<String, dynamic>? details}) =
      ServerFailure;

  /// Unexpected error
  factory UseCaseFailure.unexpected(String message, {String? code, Map<String, dynamic>? details}) =
      UnexpectedFailure;

  @override
  String toString() => '$runtimeType: $message';
}

/// Invalid input parameters failure
final class InvalidInputFailure extends UseCaseFailure {
  const InvalidInputFailure(super.message, {super.code, super.details});
}

/// Resource not found failure
final class NotFoundFailure extends UseCaseFailure {
  const NotFoundFailure(super.message, {super.code, super.details});
}

/// Business rule violation failure
final class BusinessRuleFailure extends UseCaseFailure {
  const BusinessRuleFailure(super.message, {super.code, super.details});
}

/// Permission denied failure
final class PermissionDeniedFailure extends UseCaseFailure {
  const PermissionDeniedFailure(super.message, {super.code, super.details});
}

/// Network failure
final class NetworkFailure extends UseCaseFailure {
  const NetworkFailure(super.message, {super.code, super.details});
}

/// Server failure
final class ServerFailure extends UseCaseFailure {
  const ServerFailure(super.message, {super.code, super.details});
}

/// Unexpected failure
final class UnexpectedFailure extends UseCaseFailure {
  const UnexpectedFailure(super.message, {super.code, super.details});
}

/// Exception thrown when getOrThrow is called on a failure
class UseCaseException implements Exception {
  final UseCaseFailure failure;

  const UseCaseException(this.failure);

  @override
  String toString() => 'UseCaseException: ${failure.message}';
}
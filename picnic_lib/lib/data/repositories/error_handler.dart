import 'package:picnic_lib/core/utils/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum RepositoryErrorType {
  network,
  authentication,
  authorization,
  validation,
  notFound,
  conflict,
  rateLimit,
  serverError,
  unknown,
}

class RepositoryError {
  final RepositoryErrorType type;
  final String message;
  final String? userMessage;
  final String? code;
  final Map<String, dynamic>? details;
  final dynamic originalError;
  final StackTrace? stackTrace;

  RepositoryError({
    required this.type,
    required this.message,
    this.userMessage,
    this.code,
    this.details,
    this.originalError,
    this.stackTrace,
  });

  String get displayMessage => userMessage ?? message;

  bool get isRetryable {
    switch (type) {
      case RepositoryErrorType.network:
      case RepositoryErrorType.serverError:
      case RepositoryErrorType.rateLimit:
        return true;
      case RepositoryErrorType.authentication:
      case RepositoryErrorType.authorization:
      case RepositoryErrorType.validation:
      case RepositoryErrorType.notFound:
      case RepositoryErrorType.conflict:
      case RepositoryErrorType.unknown:
        return false;
    }
  }

  @override
  String toString() {
    return 'RepositoryError(type: $type, message: $message, code: $code)';
  }
}

class RepositoryErrorHandler {
  static RepositoryError handleError(dynamic error, [StackTrace? stackTrace]) {
    logger.e('Repository error occurred', error: error, stackTrace: stackTrace);

    if (error is PostgrestException) {
      return _handlePostgrestException(error, stackTrace);
    }

    if (error is AuthException) {
      return _handleAuthException(error, stackTrace);
    }

    if (error is StorageException) {
      return _handleStorageException(error, stackTrace);
    }

    if (error is FunctionException) {
      return _handleFunctionException(error, stackTrace);
    }

    if (error is RealtimeException) {
      return _handleRealtimeException(error, stackTrace);
    }

    if (error is RepositoryError) {
      return error;
    }

    // Handle network and other common errors
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('network') || 
        errorString.contains('connection') ||
        errorString.contains('timeout') ||
        errorString.contains('unreachable')) {
      return RepositoryError(
        type: RepositoryErrorType.network,
        message: 'Network connection error: $error',
        userMessage: 'Connection failed. Please check your internet connection and try again.',
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    return RepositoryError(
      type: RepositoryErrorType.unknown,
      message: 'Unknown error: $error',
      userMessage: 'An unexpected error occurred. Please try again.',
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  static RepositoryError _handlePostgrestException(PostgrestException error, StackTrace? stackTrace) {
    final code = error.code;
    final message = error.message;

    switch (code) {
      case '401':
        return RepositoryError(
          type: RepositoryErrorType.authentication,
          message: 'Authentication failed: $message',
          userMessage: 'Please log in again to continue.',
          code: code,
          originalError: error,
          stackTrace: stackTrace,
        );

      case '403':
        return RepositoryError(
          type: RepositoryErrorType.authorization,
          message: 'Authorization failed: $message',
          userMessage: 'You do not have permission to perform this action.',
          code: code,
          originalError: error,
          stackTrace: stackTrace,
        );

      case '404':
        return RepositoryError(
          type: RepositoryErrorType.notFound,
          message: 'Resource not found: $message',
          userMessage: 'The requested item could not be found.',
          code: code,
          originalError: error,
          stackTrace: stackTrace,
        );

      case '409':
        return RepositoryError(
          type: RepositoryErrorType.conflict,
          message: 'Conflict error: $message',
          userMessage: 'This action conflicts with existing data. Please refresh and try again.',
          code: code,
          originalError: error,
          stackTrace: stackTrace,
        );

      case '422':
        return RepositoryError(
          type: RepositoryErrorType.validation,
          message: 'Validation error: $message',
          userMessage: 'Please check your input and try again.',
          code: code,
          details: error.details as Map<String, dynamic>?,
          originalError: error,
          stackTrace: stackTrace,
        );

      case '429':
        return RepositoryError(
          type: RepositoryErrorType.rateLimit,
          message: 'Rate limit exceeded: $message',
          userMessage: 'Too many requests. Please wait a moment and try again.',
          code: code,
          originalError: error,
          stackTrace: stackTrace,
        );

      case '500':
      case '502':
      case '503':
      case '504':
        return RepositoryError(
          type: RepositoryErrorType.serverError,
          message: 'Server error: $message',
          userMessage: 'Server is temporarily unavailable. Please try again later.',
          code: code,
          originalError: error,
          stackTrace: stackTrace,
        );

      default:
        return RepositoryError(
          type: RepositoryErrorType.unknown,
          message: 'Database error: $message',
          userMessage: 'An error occurred while processing your request.',
          code: code,
          originalError: error,
          stackTrace: stackTrace,
        );
    }
  }

  static RepositoryError _handleAuthException(AuthException error, StackTrace? stackTrace) {
    final message = error.message;

    if (message.toLowerCase().contains('invalid') ||
        message.toLowerCase().contains('expired') ||
        message.toLowerCase().contains('token')) {
      return RepositoryError(
        type: RepositoryErrorType.authentication,
        message: 'Authentication error: $message',
        userMessage: 'Your session has expired. Please log in again.',
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    return RepositoryError(
      type: RepositoryErrorType.authentication,
      message: 'Authentication error: $message',
      userMessage: 'Authentication failed. Please try logging in again.',
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  static RepositoryError _handleStorageException(StorageException error, StackTrace? stackTrace) {
    final message = error.message;

    if (message.toLowerCase().contains('not found')) {
      return RepositoryError(
        type: RepositoryErrorType.notFound,
        message: 'File not found: $message',
        userMessage: 'The requested file could not be found.',
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    if (message.toLowerCase().contains('unauthorized')) {
      return RepositoryError(
        type: RepositoryErrorType.authorization,
        message: 'Storage access denied: $message',
        userMessage: 'You do not have permission to access this file.',
        originalError: error,
        stackTrace: stackTrace,
      );
    }

    return RepositoryError(
      type: RepositoryErrorType.unknown,
      message: 'Storage error: $message',
      userMessage: 'An error occurred while accessing the file.',
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  static RepositoryError _handleFunctionException(FunctionException error, StackTrace? stackTrace) {
    return RepositoryError(
      type: RepositoryErrorType.serverError,
      message: 'Function error: ${error.details}',
      userMessage: 'Service temporarily unavailable. Please try again later.',
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  static RepositoryError _handleRealtimeException(RealtimeException error, StackTrace? stackTrace) {
    return RepositoryError(
      type: RepositoryErrorType.network,
      message: 'Realtime connection error: ${error.message}',
      userMessage: 'Connection lost. Attempting to reconnect...',
      originalError: error,
      stackTrace: stackTrace,
    );
  }

  static String getRetryAdvice(RepositoryErrorType type) {
    switch (type) {
      case RepositoryErrorType.network:
        return 'Check your internet connection and try again.';
      case RepositoryErrorType.serverError:
        return 'The server is temporarily unavailable. Try again in a few minutes.';
      case RepositoryErrorType.rateLimit:
        return 'You\'ve made too many requests. Wait a moment and try again.';
      case RepositoryErrorType.authentication:
        return 'Please log in again to continue.';
      case RepositoryErrorType.authorization:
        return 'You don\'t have permission for this action.';
      case RepositoryErrorType.validation:
        return 'Please check your input and correct any errors.';
      case RepositoryErrorType.notFound:
        return 'The requested item no longer exists.';
      case RepositoryErrorType.conflict:
        return 'This action conflicts with existing data. Refresh and try again.';
      case RepositoryErrorType.unknown:
        return 'An unexpected error occurred. Please try again.';
    }
  }
}

// Enhanced repository exception with better error handling
class RepositoryException implements Exception {
  final RepositoryError error;

  RepositoryException(String message, {
    RepositoryErrorType? type,
    String? userMessage,
    String? code,
    Map<String, dynamic>? details,
    dynamic originalError,
    StackTrace? stackTrace,
  }) : error = RepositoryError(
    type: type ?? RepositoryErrorType.unknown,
    message: message,
    userMessage: userMessage,
    code: code,
    details: details,
    originalError: originalError,
    stackTrace: stackTrace,
  );

  RepositoryException.fromError(this.error);

  @override
  String toString() => error.toString();
}
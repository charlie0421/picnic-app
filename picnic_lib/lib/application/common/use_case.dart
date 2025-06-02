import 'package:picnic_lib/application/common/use_case_result.dart';

/// Base interface for all use cases
/// T = Parameters type, R = Return type
abstract class UseCase<T, R> {
  Future<UseCaseResult<R>> execute(T params);
}

/// Use case that doesn't require parameters
abstract class NoParamsUseCase<R> {
  Future<UseCaseResult<R>> execute();
}

/// Synchronous use case
abstract class SyncUseCase<T, R> {
  UseCaseResult<R> execute(T params);
}

/// Synchronous use case without parameters
abstract class SyncNoParamsUseCase<R> {
  UseCaseResult<R> execute();
}

/// Stream use case for real-time data
abstract class StreamUseCase<T, R> {
  Stream<UseCaseResult<R>> execute(T params);
}

/// Stream use case without parameters
abstract class StreamNoParamsUseCase<R> {
  Stream<UseCaseResult<R>> execute();
}
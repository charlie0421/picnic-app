import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:picnic_lib/data/repositories/vote_request_repository.dart';
import 'package:picnic_lib/services/duplicate_prevention_service.dart';
import 'package:picnic_lib/services/vote_status_validation_service.dart';
import 'package:picnic_lib/services/data_validation_service.dart';
import 'package:picnic_lib/services/error_handling_service.dart';
import 'package:picnic_lib/services/vote_application_service.dart';
import 'package:picnic_lib/supabase_options.dart';

/// VoteRequestRepository 프로바이더
final voteRequestRepositoryProvider = Provider<VoteRequestRepository>((ref) {
  return VoteRequestRepository(supabase);
});

/// DuplicatePreventionService 프로바이더
final duplicatePreventionServiceProvider =
    Provider<DuplicatePreventionService>((ref) {
  final voteRequestRepository = ref.watch(voteRequestRepositoryProvider);
  return DuplicatePreventionService(voteRequestRepository);
});

/// VoteStatusValidationService 프로바이더
final voteStatusValidationServiceProvider =
    Provider<VoteStatusValidationService>((ref) {
  return VoteStatusValidationService();
});

/// DataValidationService 프로바이더
final dataValidationServiceProvider = Provider<DataValidationService>((ref) {
  return DataValidationService();
});

/// ErrorHandlingService 프로바이더
final errorHandlingServiceProvider = Provider<ErrorHandlingService>((ref) {
  return ErrorHandlingService();
});

/// VoteApplicationService 프로바이더
final voteApplicationServiceProvider = Provider<VoteApplicationService>((ref) {
  final voteRequestRepository = ref.watch(voteRequestRepositoryProvider);
  final duplicatePreventionService =
      ref.watch(duplicatePreventionServiceProvider);
  final voteStatusValidationService =
      ref.watch(voteStatusValidationServiceProvider);
  final dataValidationService = ref.watch(dataValidationServiceProvider);
  final errorHandlingService = ref.watch(errorHandlingServiceProvider);

  return VoteApplicationService(
    voteRequestRepository,
    duplicatePreventionService,
    voteStatusValidationService,
    dataValidationService,
    errorHandlingService,
  );
});

/// 캐시 정리를 위한 프로바이더 (주기적 정리용)
final cacheCleanupProvider = Provider<void>((ref) {
  final duplicatePreventionService =
      ref.watch(duplicatePreventionServiceProvider);

  // 5분마다 만료된 캐시 정리
  final timer = Timer.periodic(const Duration(minutes: 5), (timer) {
    duplicatePreventionService.cleanupExpiredCache();
  });

  // 프로바이더가 dispose될 때 타이머 정리
  ref.onDispose(() {
    timer.cancel();
  });
});

import 'package:picnic_lib/core/errors/vote_request_exceptions.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/data/models/vote/vote_request.dart';
import 'package:picnic_lib/data/repositories/vote_request_repository.dart';
import 'package:picnic_lib/services/duplicate_prevention_service.dart';
import 'package:picnic_lib/services/vote_status_validation_service.dart';
import 'package:picnic_lib/services/data_validation_service.dart';
import 'package:picnic_lib/services/error_handling_service.dart';
import 'package:picnic_lib/core/utils/logger.dart';

/// 투표 신청 비즈니스 로직을 처리하는 서비스 클래스
class VoteItemRequestService {
  final VoteRequestRepository _voteRequestRepository;
  final DuplicatePreventionService _duplicatePreventionService;
  final VoteStatusValidationService _voteStatusValidationService;
  final DataValidationService _dataValidationService;
  final ErrorHandlingService _errorHandlingService;

  VoteItemRequestService(
    this._voteRequestRepository,
    this._duplicatePreventionService,
    this._voteStatusValidationService,
    this._dataValidationService,
    this._errorHandlingService,
  );

  /// 중복 신청 방지를 포함한 투표 신청 처리
  ///
  /// [voteId] 투표 ID
  /// [userId] 사용자 ID
  /// [title] 신청 제목
  /// [artistName] 아티스트 이름 (선택사항)
  /// [groupName] 그룹 이름 (선택사항)
  Future<VoteRequest> submitApplication({
    required String voteId,
    required String userId,
    required String title,
    String? artistName,
    String? groupName,
  }) async {
    final context = {
      'voteId': voteId,
      'userId': userId,
      'title': title,
      'hasArtistName': artistName != null,
      'hasGroupName': groupName != null,
    };

    try {
      logger.i('투표 신청 처리 시작 - voteId: $voteId, userId: $userId');

      // 1. 중복 신청 확인
      await _duplicatePreventionService.validateNoDuplicateRequest(
          userId, voteId);

      // 2. 신청 제한 검증 (사용자당 한 번의 신청 제한 포함)
      await _validateApplicationLimits(userId, voteId);

      // 3. 투표 상태 검증 (새로운 서비스 사용)
      // 참고: voteModel이 필요하므로 별도로 호출해야 함

      // 4. 입력 데이터 유효성 검사 (새로운 서비스 사용)
      _dataValidationService.validateAndThrow(
        artistName: artistName,
        groupName: groupName,
      );

      // 5. 투표 요청 객체 생성
      final voteRequest = VoteRequest(
        id: '', // 서버에서 생성됨
        voteId: voteId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // 6. 투표 요청 및 사용자 정보 생성 (트랜잭션)
      final result = await _voteRequestRepository.createVoteRequestWithUser(
        request: voteRequest,
        userId: userId,
        status: 'pending',
      );

      // 7. 신청 완료 후 캐시 업데이트
      _duplicatePreventionService.markUserAsRequested(userId, voteId);

      logger.i('투표 신청 처리 완료 - requestId: ${result.id}');
      return result;
    } catch (e, stackTrace) {
      // 포괄적인 오류 처리
      final errorResult = _errorHandlingService.handleVoteItemRequestError(
        e,
        stackTrace: stackTrace,
        context: context,
      );

      // 오류 로깅
      _errorHandlingService.logError(errorResult, e, context: context);

      logger.e('투표 신청 처리 실패 - ${errorResult.technicalMessage}', error: e);

      // 사용자 친화적인 오류 메시지로 예외 재발생
      throw VoteRequestException(errorResult.userMessage);
    }
  }

  /// 아티스트별 투표 신청 (전체 투표 중복 체크 없이)
  ///
  /// 같은 투표에서 다른 아티스트에 대한 신청을 허용하되,
  /// 같은 아티스트에 대한 중복 신청만 방지합니다.
  ///
  /// [voteId] 투표 ID
  /// [userId] 사용자 ID
  /// [title] 신청 제목 (일반적으로 아티스트 이름)
  /// [artistName] 아티스트 이름
  /// [groupName] 그룹 이름 (선택사항)
  ///
  /// Returns: 생성된 [VoteRequest] 객체
  /// Throws: [DuplicateVoteRequestException] 같은 아티스트에 이미 신청한 경우
  /// Throws: [VoteRequestException] 기타 처리 오류 시
  Future<VoteRequest> submitArtistApplication({
    required String voteId,
    required String userId,
    required String title,
    String? artistName,
    String? groupName,
  }) async {
    final context = {
      'voteId': voteId,
      'userId': userId,
      'title': title,
      'artistName': artistName,
      'hasArtistName': artistName != null,
      'hasGroupName': groupName != null,
    };

    try {
      logger.i(
          '아티스트별 투표 신청 처리 시작 - voteId: $voteId, userId: $userId, artist: $artistName');

      // 1. 아티스트별 중복 신청 확인 (전체 투표 중복 체크 제외)
      if (artistName != null) {
        final existingApplication = await _voteRequestRepository
            .getUserApplicationStatus(voteId, userId, artistName);

        if (existingApplication != null) {
          final status = existingApplication.status.toLowerCase();
          if (status == 'pending' ||
              status == 'approved' ||
              status == 'in-progress') {
            throw const DuplicateVoteRequestException(
                '이미 해당 아티스트에 대해 신청하셨습니다.');
          }
        }
      }

      // 2. 신청 제한 검증 (사용자당 신청 제한)
      await _validateApplicationLimits(userId, voteId);

      // 3. 입력 데이터 유효성 검사
      _dataValidationService.validateAndThrow(
        artistName: artistName,
        groupName: groupName,
      );

      // 4. 투표 요청 객체 생성
      final voteRequest = VoteRequest(
        id: '', // 서버에서 생성됨
        voteId: voteId,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // 5. 투표 요청 및 사용자 정보 생성 (전체 투표 중복 체크 우회)
      final result =
          await _voteRequestRepository.createArtistVoteRequestWithUser(
        request: voteRequest,
        userId: userId,
        status: 'pending',
      );

      logger.i(
          '아티스트별 투표 신청 처리 완료 - requestId: ${result.id}, artist: $artistName');
      return result;
    } catch (e, stackTrace) {
      // 포괄적인 오류 처리
      final errorResult = _errorHandlingService.handleVoteItemRequestError(
        e,
        stackTrace: stackTrace,
        context: context,
      );

      // 오류 로깅
      _errorHandlingService.logError(errorResult, e, context: context);

      logger.e('아티스트별 투표 신청 처리 실패 - ${errorResult.technicalMessage}', error: e);

      // 사용자 친화적인 오류 메시지로 예외 재발생
      throw VoteRequestException(errorResult.userMessage);
    }
  }

  /// 사용자가 특정 투표에 이미 신청했는지 확인
  ///
  /// [userId] 사용자 ID
  /// [voteId] 투표 ID
  /// [useCache] 캐시 사용 여부 (기본값: true)
  ///
  /// Returns: 이미 신청한 경우 true, 아닌 경우 false
  Future<bool> hasUserApplied(String userId, String voteId,
      {bool useCache = true}) async {
    try {
      return await _duplicatePreventionService.hasUserRequestedVote(
        userId,
        voteId,
        forceRefresh: !useCache,
      );
    } catch (e, stackTrace) {
      final errorResult = _errorHandlingService.handleVoteItemRequestError(
        e,
        stackTrace: stackTrace,
        context: {'userId': userId, 'voteId': voteId, 'useCache': useCache},
      );

      _errorHandlingService.logError(errorResult, e);

      // 신청 여부 확인 실패 시 안전하게 false 반환 (재신청 허용)
      logger.w('신청 여부 확인 실패, 안전하게 false 반환 - ${errorResult.technicalMessage}');
      return false;
    }
  }

  /// 중복 신청 방지 검증 (캐시 지원)
  ///
  /// [userId] 사용자 ID
  /// [voteId] 투표 ID
  /// [useCache] 캐시 사용 여부 (기본값: true)
  ///
  /// Throws: [DuplicateVoteRequestException] 이미 신청한 경우
  Future<void> validateNoDuplicateApplication(String userId, String voteId,
      {bool useCache = true}) async {
    await _duplicatePreventionService.validateNoDuplicateRequest(
      userId,
      voteId,
      forceRefresh: !useCache,
    );
  }

  /// 투표 상태 검증 (새로운 서비스 사용)
  ///
  /// [voteModel] 투표 모델
  ///
  /// 투표 신청이 불가능한 경우 [InvalidVoteRequestStatusException] 발생
  void validateVoteStatus(VoteModel voteModel) {
    try {
      _voteStatusValidationService.validateCanApply(voteModel);
      logger.d('투표 상태 검증 완료 - 신청 가능한 상태');
    } catch (e) {
      if (e is InvalidVoteRequestStatusException) {
        rethrow;
      }
      logger.e('투표 상태 검증 중 오류 발생', error: e);
      throw VoteRequestException('투표 상태 검증 중 오류가 발생했습니다: $e');
    }
  }

  /// 투표 참여 가능 여부 검증
  ///
  /// [voteModel] 투표 모델
  ///
  /// 투표 참여가 불가능한 경우 [InvalidVoteRequestStatusException] 발생
  void validateCanVote(VoteModel voteModel) {
    try {
      _voteStatusValidationService.validateCanVote(voteModel);
      logger.d('투표 참여 검증 완료 - 투표 가능한 상태');
    } catch (e) {
      if (e is InvalidVoteRequestStatusException) {
        rethrow;
      }
      logger.e('투표 참여 검증 중 오류 발생', error: e);
      throw VoteRequestException('투표 참여 검증 중 오류가 발생했습니다: $e');
    }
  }

  /// 투표 상태 정보 조회
  ///
  /// [voteModel] 투표 모델
  ///
  /// Returns: [VoteStatusValidationResult] 투표 상태 정보
  VoteStatusValidationResult getVoteStatusInfo(VoteModel voteModel) {
    return _voteStatusValidationService.validateVoteStatus(voteModel);
  }

  /// 투표 상태 요약 문자열 조회
  ///
  /// [voteModel] 투표 모델
  ///
  /// Returns: 사용자에게 표시할 상태 요약 문자열
  String getVoteStatusSummary(VoteModel voteModel) {
    return _voteStatusValidationService.getStatusSummary(voteModel);
  }

  /// 포괄적인 데이터 유효성 검사 (ValidationResult 반환)
  ///
  /// [title] 신청 제목
  /// [description] 신청 설명
  /// [artistName] 아티스트 이름
  /// [groupName] 그룹 이름
  /// [strictMode] 엄격 모드 (기본값: true)
  ///
  /// Returns: [ValidationResult] 검증 결과
  ValidationResult validateApplicationData({
    required String title,
    required String description,
    String? artistName,
    String? groupName,
    bool strictMode = true,
  }) {
    return _dataValidationService.validateVoteItemRequestData(
      artistName: artistName,
      groupName: groupName,
      strictMode: strictMode,
    );
  }

  /// 오류 처리 및 사용자 친화적 메시지 생성
  ///
  /// [error] 발생한 오류
  /// [context] 추가 컨텍스트 정보
  ///
  /// Returns: [ErrorHandlingResult] 처리된 오류 정보
  ErrorHandlingResult handleError(
    dynamic error, {
    Map<String, dynamic>? context,
  }) {
    return _errorHandlingService.handleVoteItemRequestError(
      error,
      context: context,
    );
  }

  /// 네트워크 오류 처리
  ///
  /// [error] 네트워크 오류
  /// [context] 추가 컨텍스트 정보
  ///
  /// Returns: [ErrorHandlingResult] 처리된 오류 정보
  ErrorHandlingResult handleNetworkError(
    dynamic error, {
    Map<String, dynamic>? context,
  }) {
    return _errorHandlingService.handleNetworkError(
      error,
      context: context,
    );
  }

  /// 서버 오류 처리
  ///
  /// [statusCode] HTTP 상태 코드
  /// [message] 서버 오류 메시지
  /// [context] 추가 컨텍스트 정보
  ///
  /// Returns: [ErrorHandlingResult] 처리된 오류 정보
  ErrorHandlingResult handleServerError(
    int statusCode,
    String message, {
    Map<String, dynamic>? context,
  }) {
    return _errorHandlingService.handleServerError(
      statusCode,
      message,
      context: context,
    );
  }

  /// 사용자 친화적 오류 메시지 생성
  ///
  /// [errorType] 오류 유형
  /// [originalMessage] 원본 오류 메시지
  ///
  /// Returns: 사용자에게 표시할 친화적인 메시지
  String generateUserFriendlyMessage(
      ErrorType errorType, String originalMessage) {
    return _errorHandlingService.generateUserFriendlyMessage(
        errorType, originalMessage);
  }

  /// 전체 설명 구성
  ///
  /// [description] 기본 설명
  /// [artistName] 아티스트 이름
  /// [groupName] 그룹 이름
  String _buildFullDescription({
    String? artistName,
    String? groupName,
  }) {
    final buffer = StringBuffer();

    if (artistName != null && artistName.trim().isNotEmpty) {
      buffer.write('\n\n아티스트: ${artistName.trim()}');
    }

    if (groupName != null && groupName.trim().isNotEmpty) {
      buffer.write('\n그룹: ${groupName.trim()}');
    }

    return buffer.toString();
  }

  /// 신청 제한 검증 (사용자당 한 번의 신청 제한 포함)
  ///
  /// [userId] 사용자 ID
  /// [voteId] 투표 ID
  ///
  /// Throws: [VoteRequestException] 제한 초과 시
  Future<void> _validateApplicationLimits(String userId, String voteId) async {
    try {
      // 1. 사용자당 투표별 한 번 제한 (이미 중복 방지 서비스에서 처리됨)
      // 추가적인 제한 정책들을 여기에 구현할 수 있음

      // 2. 일일 신청 제한 (예: 하루에 최대 10개)
      await _validateDailyApplicationLimit(userId);

      // 3. 시간당 신청 제한 (예: 시간당 최대 3개)
      await _validateHourlyApplicationLimit(userId);

      logger.d('신청 제한 검증 완료 - userId: $userId, voteId: $voteId');
    } catch (e) {
      if (e is VoteRequestException) {
        rethrow;
      }
      logger.e('신청 제한 검증 중 오류 발생', error: e);
      throw VoteRequestException('신청 제한 검증 중 오류가 발생했습니다: $e');
    }
  }

  /// 일일 신청 제한 검증
  ///
  /// [userId] 사용자 ID
  /// [dailyLimit] 일일 제한 수 (기본값: 10)
  ///
  /// Throws: [VoteRequestException] 제한 초과 시
  Future<void> _validateDailyApplicationLimit(String userId,
      {int dailyLimit = 10}) async {
    final now = DateTime.now().toUtc();
    final startOfDay = DateTime(now.year, now.month, now.day).toUtc();

    final todayCount = await _voteRequestRepository
        .getUserApplicationCountSince(userId, startOfDay);

    if (todayCount >= dailyLimit) {
      throw VoteRequestException(
          '일일 신청 한도($dailyLimit개)를 초과했습니다. 내일 다시 시도해주세요.');
    }

    logger.d('일일 신청 제한 검증 완료 - 현재: $todayCount/$dailyLimit');
  }

  /// 시간당 신청 제한 검증
  ///
  /// [userId] 사용자 ID
  /// [hourlyLimit] 시간당 제한 수 (기본값: 3)
  ///
  /// Throws: [VoteRequestException] 제한 초과 시
  Future<void> _validateHourlyApplicationLimit(String userId,
      {int hourlyLimit = 3}) async {
    final now = DateTime.now().toUtc();
    final oneHourAgo = now.subtract(const Duration(hours: 1));

    final hourlyCount = await _voteRequestRepository
        .getUserApplicationCountSince(userId, oneHourAgo);

    if (hourlyCount >= hourlyLimit) {
      throw VoteRequestException(
          '시간당 신청 한도($hourlyLimit개)를 초과했습니다. 잠시 후 다시 시도해주세요.');
    }

    logger.d('시간당 신청 제한 검증 완료 - 현재: $hourlyCount/$hourlyLimit');
  }

  /// 사용자의 투표별 신청 내역 조회
  ///
  /// [userId] 사용자 ID
  /// [voteId] 투표 ID (선택사항, 지정하지 않으면 모든 투표)
  Future<List<VoteRequest>> getUserApplications(String userId,
      {String? voteId}) async {
    try {
      if (voteId != null) {
        // 특정 투표에 대한 신청 내역
        final hasRequested =
            await _voteRequestRepository.hasUserRequestedVote(voteId, userId);
        if (!hasRequested) {
          return [];
        }
        return await _voteRequestRepository.getVoteRequestsByVoteId(voteId);
      } else {
        // 사용자의 모든 신청 내역
        return await _voteRequestRepository.getUserVoteRequests(userId);
      }
    } catch (e) {
      logger.e('사용자 신청 내역 조회 실패', error: e);
      throw VoteRequestException('신청 내역을 조회하는 중 오류가 발생했습니다: $e');
    }
  }

  /// 신청 상태 업데이트 (관리자용)
  ///
  /// [requestId] 요청 ID
  /// [status] 새로운 상태 ('pending', 'approved', 'rejected', 'cancelled')
  Future<VoteRequest> updateApplicationStatus(
      String requestId, String status) async {
    try {
      // 유효한 상태 값 검증
      const validStatuses = ['pending', 'approved', 'rejected', 'cancelled'];
      if (!validStatuses.contains(status)) {
        throw VoteRequestException('유효하지 않은 상태 값입니다: $status');
      }

      final result = await _voteRequestRepository.updateVoteRequestStatus(
          requestId, status);
      logger.i('신청 상태 업데이트 완료 - requestId: $requestId, status: $status');

      return result;
    } catch (e) {
      logger.e('신청 상태 업데이트 실패', error: e);
      rethrow;
    }
  }
}

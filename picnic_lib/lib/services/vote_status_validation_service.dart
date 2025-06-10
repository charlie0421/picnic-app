import 'package:picnic_lib/core/errors/vote_request_exceptions.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/core/utils/logger.dart';

/// 투표 상태를 나타내는 열거형
enum VoteState {
  /// 아직 공개되지 않은 투표
  notVisible,

  /// 공개되었지만 아직 시작되지 않은 투표 (예정)
  upcoming,

  /// 진행 중인 투표
  ongoing,

  /// 종료된 투표
  ended,

  /// 상태를 알 수 없는 투표 (데이터 오류)
  unknown,
}

/// 투표 상태 검증 결과
class VoteStatusValidationResult {
  final VoteState state;
  final bool canApply;
  final bool canVote;
  final String? message;
  final DateTime? timeUntilStateChange;

  const VoteStatusValidationResult({
    required this.state,
    required this.canApply,
    required this.canVote,
    this.message,
    this.timeUntilStateChange,
  });

  @override
  String toString() {
    return 'VoteStatusValidationResult(state: $state, canApply: $canApply, canVote: $canVote, message: $message)';
  }
}

/// 투표 상태 검증 전담 서비스
///
/// 투표의 현재 상태를 정확히 판단하고, 신청/투표 가능 여부를 검증합니다.
/// 시간 기반 검증과 상태 전환 로직을 포함합니다.
class VoteStatusValidationService {
  /// 투표의 현재 상태를 확인
  ///
  /// [voteModel] 투표 모델
  /// [currentTime] 현재 시간 (테스트용, 기본값은 현재 시간)
  ///
  /// Returns: [VoteState] 현재 투표 상태
  VoteState getCurrentVoteState(VoteModel voteModel, {DateTime? currentTime}) {
    final now = currentTime ?? DateTime.now().toUtc();

    try {
      // 1. 필수 시간 정보 확인
      if (voteModel.startAt == null || voteModel.stopAt == null) {
        logger.w('투표 시간 정보 누락 - voteId: ${voteModel.id}');
        return VoteState.unknown;
      }

      final startAt = voteModel.startAt!.toUtc();
      final stopAt = voteModel.stopAt!.toUtc();
      final visibleAt = voteModel.visibleAt?.toUtc();

      // 2. 시간 순서 검증
      if (startAt.isAfter(stopAt)) {
        logger.e('잘못된 투표 시간 설정 - 시작시간이 종료시간보다 늦음: voteId: ${voteModel.id}');
        return VoteState.unknown;
      }

      // 3. 공개 시간 확인 (visibleAt이 있는 경우)
      if (visibleAt != null && now.isBefore(visibleAt)) {
        return VoteState.notVisible;
      }

      // 4. 상태 플래그 우선 확인 (서버에서 계산된 값)
      if (voteModel.isEnded == true) {
        return VoteState.ended;
      }

      if (voteModel.isUpcoming == true) {
        return VoteState.upcoming;
      }

      // 5. 시간 기반 상태 계산 (플래그가 없거나 신뢰할 수 없는 경우)
      if (now.isBefore(startAt)) {
        return VoteState.upcoming;
      } else if (now.isAfter(stopAt)) {
        return VoteState.ended;
      } else {
        return VoteState.ongoing;
      }
    } catch (e) {
      logger.e('투표 상태 확인 중 오류 발생', error: e);
      return VoteState.unknown;
    }
  }

  /// 투표 상태 종합 검증
  ///
  /// [voteModel] 투표 모델
  /// [currentTime] 현재 시간 (테스트용)
  ///
  /// Returns: [VoteStatusValidationResult] 검증 결과
  VoteStatusValidationResult validateVoteStatus(VoteModel voteModel,
      {DateTime? currentTime}) {
    final now = currentTime ?? DateTime.now().toUtc();
    final state = getCurrentVoteState(voteModel, currentTime: now);

    switch (state) {
      case VoteState.notVisible:
        return VoteStatusValidationResult(
          state: state,
          canApply: false,
          canVote: false,
          message: '아직 공개되지 않은 투표입니다.',
          timeUntilStateChange: voteModel.visibleAt,
        );

      case VoteState.upcoming:
        return VoteStatusValidationResult(
          state: state,
          canApply: true, // 예정된 투표에는 신청 가능
          canVote: false,
          message: '투표 시작 전입니다. 후보 신청은 가능합니다.',
          timeUntilStateChange: voteModel.startAt,
        );

      case VoteState.ongoing:
        return VoteStatusValidationResult(
          state: state,
          canApply: true, // 진행 중인 투표에도 신청 가능 (정책에 따라 변경 가능)
          canVote: true,
          message: '투표가 진행 중입니다.',
          timeUntilStateChange: voteModel.stopAt,
        );

      case VoteState.ended:
        return VoteStatusValidationResult(
          state: state,
          canApply: false,
          canVote: false,
          message: '이미 종료된 투표입니다.',
        );

      case VoteState.unknown:
        return VoteStatusValidationResult(
          state: state,
          canApply: false,
          canVote: false,
          message: '투표 상태를 확인할 수 없습니다.',
        );
    }
  }

  /// 투표 신청 가능 여부 검증 (예외 발생)
  ///
  /// [voteModel] 투표 모델
  /// [currentTime] 현재 시간 (테스트용)
  ///
  /// Throws: [InvalidVoteRequestStatusException] 신청 불가능한 경우
  void validateCanApply(VoteModel voteModel, {DateTime? currentTime}) {
    final result = validateVoteStatus(voteModel, currentTime: currentTime);

    if (!result.canApply) {
      throw InvalidVoteRequestStatusException(
          result.message ?? '현재 투표 신청이 불가능합니다.');
    }

    logger.d('투표 신청 가능 - voteId: ${voteModel.id}, state: ${result.state}');
  }

  /// 투표 참여 가능 여부 검증 (예외 발생)
  ///
  /// [voteModel] 투표 모델
  /// [currentTime] 현재 시간 (테스트용)
  ///
  /// Throws: [InvalidVoteRequestStatusException] 투표 불가능한 경우
  void validateCanVote(VoteModel voteModel, {DateTime? currentTime}) {
    final result = validateVoteStatus(voteModel, currentTime: currentTime);

    if (!result.canVote) {
      throw InvalidVoteRequestStatusException(
          result.message ?? '현재 투표 참여가 불가능합니다.');
    }

    logger.d('투표 참여 가능 - voteId: ${voteModel.id}, state: ${result.state}');
  }

  /// 투표 마감까지 남은 시간 계산
  ///
  /// [voteModel] 투표 모델
  /// [currentTime] 현재 시간 (테스트용)
  ///
  /// Returns: 마감까지 남은 시간 (Duration), 이미 마감된 경우 null
  Duration? getTimeUntilDeadline(VoteModel voteModel, {DateTime? currentTime}) {
    final now = currentTime ?? DateTime.now().toUtc();

    if (voteModel.stopAt == null) {
      return null;
    }

    final stopAt = voteModel.stopAt!.toUtc();

    if (now.isAfter(stopAt)) {
      return null; // 이미 마감됨
    }

    return stopAt.difference(now);
  }

  /// 투표 시작까지 남은 시간 계산
  ///
  /// [voteModel] 투표 모델
  /// [currentTime] 현재 시간 (테스트용)
  ///
  /// Returns: 시작까지 남은 시간 (Duration), 이미 시작된 경우 null
  Duration? getTimeUntilStart(VoteModel voteModel, {DateTime? currentTime}) {
    final now = currentTime ?? DateTime.now().toUtc();

    if (voteModel.startAt == null) {
      return null;
    }

    final startAt = voteModel.startAt!.toUtc();

    if (now.isAfter(startAt)) {
      return null; // 이미 시작됨
    }

    return startAt.difference(now);
  }

  /// 투표가 곧 마감되는지 확인 (기본: 10분 이내)
  ///
  /// [voteModel] 투표 모델
  /// [warningThreshold] 경고 임계값 (기본: 10분)
  /// [currentTime] 현재 시간 (테스트용)
  ///
  /// Returns: 곧 마감되는 경우 true
  bool isNearDeadline(
    VoteModel voteModel, {
    Duration warningThreshold = const Duration(minutes: 10),
    DateTime? currentTime,
  }) {
    final timeLeft = getTimeUntilDeadline(voteModel, currentTime: currentTime);

    if (timeLeft == null) {
      return false; // 이미 마감됨
    }

    return timeLeft <= warningThreshold;
  }

  /// 투표 상태 변경 이력 생성 (로깅용)
  ///
  /// [voteModel] 투표 모델
  /// [previousState] 이전 상태
  /// [currentTime] 현재 시간
  void logStateChange(VoteModel voteModel, VoteState? previousState,
      {DateTime? currentTime}) {
    final currentState =
        getCurrentVoteState(voteModel, currentTime: currentTime);

    if (previousState != null && previousState != currentState) {
      logger.i(
          '투표 상태 변경 - voteId: ${voteModel.id}, ${previousState.name} → ${currentState.name}');
    }
  }

  /// 투표 상태 요약 정보 생성
  ///
  /// [voteModel] 투표 모델
  /// [currentTime] 현재 시간 (테스트용)
  ///
  /// Returns: 사용자에게 표시할 상태 요약 문자열
  String getStatusSummary(VoteModel voteModel, {DateTime? currentTime}) {
    final result = validateVoteStatus(voteModel, currentTime: currentTime);
    final timeLeft = getTimeUntilDeadline(voteModel, currentTime: currentTime);
    final timeUntilStart =
        getTimeUntilStart(voteModel, currentTime: currentTime);

    switch (result.state) {
      case VoteState.notVisible:
        return '공개 예정';

      case VoteState.upcoming:
        if (timeUntilStart != null) {
          final days = timeUntilStart.inDays;
          final hours = timeUntilStart.inHours % 24;
          final minutes = timeUntilStart.inMinutes % 60;

          if (days > 0) {
            return '${days}일 후 시작';
          } else if (hours > 0) {
            return '${hours}시간 후 시작';
          } else {
            return '${minutes}분 후 시작';
          }
        }
        return '시작 예정';

      case VoteState.ongoing:
        if (timeLeft != null) {
          final days = timeLeft.inDays;
          final hours = timeLeft.inHours % 24;
          final minutes = timeLeft.inMinutes % 60;

          if (days > 0) {
            return '${days}일 남음';
          } else if (hours > 0) {
            return '${hours}시간 남음';
          } else {
            return '${minutes}분 남음';
          }
        }
        return '진행 중';

      case VoteState.ended:
        return '종료됨';

      case VoteState.unknown:
        return '상태 불명';
    }
  }
}

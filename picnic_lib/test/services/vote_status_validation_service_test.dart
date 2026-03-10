import 'package:picnic_lib/core/errors/vote_request_exceptions.dart';
import 'package:picnic_lib/data/models/vote/vote.dart';
import 'package:picnic_lib/services/vote_status_validation_service.dart';
import 'package:test/test.dart';

/// 테스트용 VoteModel 인스턴스를 생성하는 헬퍼 함수
VoteModel createTestVoteModel({
  int id = 1,
  DateTime? visibleAt,
  DateTime? startAt,
  DateTime? stopAt,
  bool? isEnded,
  bool? isUpcoming,
}) {
  return VoteModel(
    id: id,
    title: {'ko': '테스트 투표', 'en': 'Test Vote'},
    voteCategory: 'test',
    mainImage: null,
    waitImage: null,
    resultImage: null,
    voteContent: null,
    voteItem: null,
    createdAt: DateTime.utc(2025, 1, 1),
    visibleAt: visibleAt,
    startAt: startAt,
    stopAt: stopAt,
    isEnded: isEnded,
    isUpcoming: isUpcoming,
    isPartnership: false,
    partner: null,
    reward: null,
  );
}

void main() {
  late VoteStatusValidationService service;

  setUp(() {
    service = VoteStatusValidationService();
  });

  // =========================================================================
  // getCurrentVoteState 테스트
  // =========================================================================
  group('getCurrentVoteState', () {
    test('현재 시간이 startAt과 stopAt 사이이면 ongoing을 반환한다', () {
      final now = DateTime.utc(2025, 6, 15, 12, 0);
      final vote = createTestVoteModel(
        startAt: DateTime.utc(2025, 6, 1),
        stopAt: DateTime.utc(2025, 6, 30),
      );

      final state = service.getCurrentVoteState(vote, currentTime: now);
      expect(state, equals(VoteState.ongoing));
    });

    test('현재 시간이 startAt 이전이면 upcoming을 반환한다', () {
      final now = DateTime.utc(2025, 5, 15);
      final vote = createTestVoteModel(
        startAt: DateTime.utc(2025, 6, 1),
        stopAt: DateTime.utc(2025, 6, 30),
      );

      final state = service.getCurrentVoteState(vote, currentTime: now);
      expect(state, equals(VoteState.upcoming));
    });

    test('현재 시간이 stopAt 이후이면 ended를 반환한다', () {
      final now = DateTime.utc(2025, 7, 15);
      final vote = createTestVoteModel(
        startAt: DateTime.utc(2025, 6, 1),
        stopAt: DateTime.utc(2025, 6, 30),
      );

      final state = service.getCurrentVoteState(vote, currentTime: now);
      expect(state, equals(VoteState.ended));
    });

    test('현재 시간이 visibleAt 이전이면 notVisible을 반환한다', () {
      final now = DateTime.utc(2025, 4, 15);
      final vote = createTestVoteModel(
        visibleAt: DateTime.utc(2025, 5, 1),
        startAt: DateTime.utc(2025, 6, 1),
        stopAt: DateTime.utc(2025, 6, 30),
      );

      final state = service.getCurrentVoteState(vote, currentTime: now);
      expect(state, equals(VoteState.notVisible));
    });

    test('startAt 또는 stopAt이 null이면 unknown을 반환한다', () {
      final now = DateTime.utc(2025, 6, 15);

      final voteNoStart = createTestVoteModel(
        startAt: null,
        stopAt: DateTime.utc(2025, 6, 30),
      );
      expect(
        service.getCurrentVoteState(voteNoStart, currentTime: now),
        equals(VoteState.unknown),
      );

      final voteNoStop = createTestVoteModel(
        startAt: DateTime.utc(2025, 6, 1),
        stopAt: null,
      );
      expect(
        service.getCurrentVoteState(voteNoStop, currentTime: now),
        equals(VoteState.unknown),
      );

      final voteBothNull = createTestVoteModel(
        startAt: null,
        stopAt: null,
      );
      expect(
        service.getCurrentVoteState(voteBothNull, currentTime: now),
        equals(VoteState.unknown),
      );
    });

    test('startAt이 stopAt보다 늦으면 (잘못된 데이터) unknown을 반환한다', () {
      final now = DateTime.utc(2025, 6, 15);
      final vote = createTestVoteModel(
        startAt: DateTime.utc(2025, 7, 1),
        stopAt: DateTime.utc(2025, 6, 1),
      );

      final state = service.getCurrentVoteState(vote, currentTime: now);
      expect(state, equals(VoteState.unknown));
    });

    test('서버 플래그 isEnded=true이면 시간과 관계없이 ended를 반환한다', () {
      // 시간으로는 ongoing이지만 서버 플래그가 ended
      final now = DateTime.utc(2025, 6, 15, 12, 0);
      final vote = createTestVoteModel(
        startAt: DateTime.utc(2025, 6, 1),
        stopAt: DateTime.utc(2025, 6, 30),
        isEnded: true,
      );

      final state = service.getCurrentVoteState(vote, currentTime: now);
      expect(state, equals(VoteState.ended));
    });

    test('서버 플래그 isUpcoming=true이면 시간과 관계없이 upcoming을 반환한다', () {
      // 시간으로는 ongoing이지만 서버 플래그가 upcoming
      final now = DateTime.utc(2025, 6, 15, 12, 0);
      final vote = createTestVoteModel(
        startAt: DateTime.utc(2025, 6, 1),
        stopAt: DateTime.utc(2025, 6, 30),
        isUpcoming: true,
      );

      final state = service.getCurrentVoteState(vote, currentTime: now);
      expect(state, equals(VoteState.upcoming));
    });

    test('visibleAt 확인이 서버 플래그보다 우선한다', () {
      final now = DateTime.utc(2025, 4, 15);
      final vote = createTestVoteModel(
        visibleAt: DateTime.utc(2025, 5, 1),
        startAt: DateTime.utc(2025, 6, 1),
        stopAt: DateTime.utc(2025, 6, 30),
        isEnded: true, // 서버 플래그로는 ended이지만 visibleAt 이전
      );

      final state = service.getCurrentVoteState(vote, currentTime: now);
      expect(state, equals(VoteState.notVisible));
    });
  });

  // =========================================================================
  // validateVoteStatus 테스트
  // =========================================================================
  group('validateVoteStatus', () {
    test('upcoming 상태: canApply=true, canVote=false', () {
      final now = DateTime.utc(2025, 5, 15);
      final vote = createTestVoteModel(
        startAt: DateTime.utc(2025, 6, 1),
        stopAt: DateTime.utc(2025, 6, 30),
      );

      final result = service.validateVoteStatus(vote, currentTime: now);

      expect(result.state, equals(VoteState.upcoming));
      expect(result.canApply, isTrue);
      expect(result.canVote, isFalse);
      expect(result.message, isNotNull);
      expect(result.timeUntilStateChange, equals(vote.startAt));
    });

    test('ongoing 상태: canApply=true, canVote=true', () {
      final now = DateTime.utc(2025, 6, 15, 12, 0);
      final vote = createTestVoteModel(
        startAt: DateTime.utc(2025, 6, 1),
        stopAt: DateTime.utc(2025, 6, 30),
      );

      final result = service.validateVoteStatus(vote, currentTime: now);

      expect(result.state, equals(VoteState.ongoing));
      expect(result.canApply, isTrue);
      expect(result.canVote, isTrue);
      expect(result.message, isNotNull);
      expect(result.timeUntilStateChange, equals(vote.stopAt));
    });

    test('ended 상태: canApply=false, canVote=false', () {
      final now = DateTime.utc(2025, 7, 15);
      final vote = createTestVoteModel(
        startAt: DateTime.utc(2025, 6, 1),
        stopAt: DateTime.utc(2025, 6, 30),
      );

      final result = service.validateVoteStatus(vote, currentTime: now);

      expect(result.state, equals(VoteState.ended));
      expect(result.canApply, isFalse);
      expect(result.canVote, isFalse);
      expect(result.message, isNotNull);
      expect(result.timeUntilStateChange, isNull);
    });

    test('notVisible 상태: canApply=false, canVote=false', () {
      final now = DateTime.utc(2025, 4, 15);
      final vote = createTestVoteModel(
        visibleAt: DateTime.utc(2025, 5, 1),
        startAt: DateTime.utc(2025, 6, 1),
        stopAt: DateTime.utc(2025, 6, 30),
      );

      final result = service.validateVoteStatus(vote, currentTime: now);

      expect(result.state, equals(VoteState.notVisible));
      expect(result.canApply, isFalse);
      expect(result.canVote, isFalse);
      expect(result.message, contains('공개'));
      expect(result.timeUntilStateChange, equals(vote.visibleAt));
    });

    test('unknown 상태: canApply=false, canVote=false', () {
      final now = DateTime.utc(2025, 6, 15);
      final vote = createTestVoteModel(
        startAt: null,
        stopAt: null,
      );

      final result = service.validateVoteStatus(vote, currentTime: now);

      expect(result.state, equals(VoteState.unknown));
      expect(result.canApply, isFalse);
      expect(result.canVote, isFalse);
      expect(result.message, isNotNull);
    });

    test('각 상태별 올바른 메시지를 반환한다', () {
      final now = DateTime.utc(2025, 6, 15, 12, 0);

      // ongoing
      final ongoingVote = createTestVoteModel(
        startAt: DateTime.utc(2025, 6, 1),
        stopAt: DateTime.utc(2025, 6, 30),
      );
      final ongoingResult =
          service.validateVoteStatus(ongoingVote, currentTime: now);
      expect(ongoingResult.message, contains('진행 중'));

      // ended
      final endedVote = createTestVoteModel(
        startAt: DateTime.utc(2025, 5, 1),
        stopAt: DateTime.utc(2025, 5, 30),
      );
      final endedResult =
          service.validateVoteStatus(endedVote, currentTime: now);
      expect(endedResult.message, contains('종료'));

      // upcoming
      final upcomingVote = createTestVoteModel(
        startAt: DateTime.utc(2025, 7, 1),
        stopAt: DateTime.utc(2025, 7, 30),
      );
      final upcomingResult =
          service.validateVoteStatus(upcomingVote, currentTime: now);
      expect(upcomingResult.message, contains('시작 전'));
    });
  });

  // =========================================================================
  // validateCanApply 테스트
  // =========================================================================
  group('validateCanApply', () {
    test('ongoing 상태에서는 예외를 던지지 않는다', () {
      final now = DateTime.utc(2025, 6, 15, 12, 0);
      final vote = createTestVoteModel(
        startAt: DateTime.utc(2025, 6, 1),
        stopAt: DateTime.utc(2025, 6, 30),
      );

      expect(
        () => service.validateCanApply(vote, currentTime: now),
        returnsNormally,
      );
    });

    test('upcoming 상태에서는 예외를 던지지 않는다', () {
      final now = DateTime.utc(2025, 5, 15);
      final vote = createTestVoteModel(
        startAt: DateTime.utc(2025, 6, 1),
        stopAt: DateTime.utc(2025, 6, 30),
      );

      expect(
        () => service.validateCanApply(vote, currentTime: now),
        returnsNormally,
      );
    });

    test('ended 상태에서는 InvalidVoteRequestStatusException을 던진다', () {
      final now = DateTime.utc(2025, 7, 15);
      final vote = createTestVoteModel(
        startAt: DateTime.utc(2025, 6, 1),
        stopAt: DateTime.utc(2025, 6, 30),
      );

      expect(
        () => service.validateCanApply(vote, currentTime: now),
        throwsA(isA<InvalidVoteRequestStatusException>()),
      );
    });

    test('notVisible 상태에서는 InvalidVoteRequestStatusException을 던진다', () {
      final now = DateTime.utc(2025, 4, 15);
      final vote = createTestVoteModel(
        visibleAt: DateTime.utc(2025, 5, 1),
        startAt: DateTime.utc(2025, 6, 1),
        stopAt: DateTime.utc(2025, 6, 30),
      );

      expect(
        () => service.validateCanApply(vote, currentTime: now),
        throwsA(isA<InvalidVoteRequestStatusException>()),
      );
    });

    test('unknown 상태에서는 InvalidVoteRequestStatusException을 던진다', () {
      final now = DateTime.utc(2025, 6, 15);
      final vote = createTestVoteModel(startAt: null, stopAt: null);

      expect(
        () => service.validateCanApply(vote, currentTime: now),
        throwsA(isA<InvalidVoteRequestStatusException>()),
      );
    });
  });

  // =========================================================================
  // validateCanVote 테스트
  // =========================================================================
  group('validateCanVote', () {
    test('ongoing 상태에서는 예외를 던지지 않는다', () {
      final now = DateTime.utc(2025, 6, 15, 12, 0);
      final vote = createTestVoteModel(
        startAt: DateTime.utc(2025, 6, 1),
        stopAt: DateTime.utc(2025, 6, 30),
      );

      expect(
        () => service.validateCanVote(vote, currentTime: now),
        returnsNormally,
      );
    });

    test('upcoming 상태에서는 InvalidVoteRequestStatusException을 던진다', () {
      final now = DateTime.utc(2025, 5, 15);
      final vote = createTestVoteModel(
        startAt: DateTime.utc(2025, 6, 1),
        stopAt: DateTime.utc(2025, 6, 30),
      );

      expect(
        () => service.validateCanVote(vote, currentTime: now),
        throwsA(isA<InvalidVoteRequestStatusException>()),
      );
    });

    test('ended 상태에서는 InvalidVoteRequestStatusException을 던진다', () {
      final now = DateTime.utc(2025, 7, 15);
      final vote = createTestVoteModel(
        startAt: DateTime.utc(2025, 6, 1),
        stopAt: DateTime.utc(2025, 6, 30),
      );

      expect(
        () => service.validateCanVote(vote, currentTime: now),
        throwsA(isA<InvalidVoteRequestStatusException>()),
      );
    });

    test('notVisible 상태에서는 InvalidVoteRequestStatusException을 던진다', () {
      final now = DateTime.utc(2025, 4, 15);
      final vote = createTestVoteModel(
        visibleAt: DateTime.utc(2025, 5, 1),
        startAt: DateTime.utc(2025, 6, 1),
        stopAt: DateTime.utc(2025, 6, 30),
      );

      expect(
        () => service.validateCanVote(vote, currentTime: now),
        throwsA(isA<InvalidVoteRequestStatusException>()),
      );
    });
  });

  // =========================================================================
  // getTimeUntilDeadline 테스트
  // =========================================================================
  group('getTimeUntilDeadline', () {
    test('진행 중인 투표에 대해 올바른 Duration을 반환한다', () {
      final now = DateTime.utc(2025, 6, 15, 12, 0);
      final stopAt = DateTime.utc(2025, 6, 30, 12, 0);
      final vote = createTestVoteModel(
        startAt: DateTime.utc(2025, 6, 1),
        stopAt: stopAt,
      );

      final duration = service.getTimeUntilDeadline(vote, currentTime: now);

      expect(duration, isNotNull);
      expect(duration!.inDays, equals(15));
    });

    test('종료된 투표에 대해 null을 반환한다', () {
      final now = DateTime.utc(2025, 7, 15);
      final vote = createTestVoteModel(
        startAt: DateTime.utc(2025, 6, 1),
        stopAt: DateTime.utc(2025, 6, 30),
      );

      final duration = service.getTimeUntilDeadline(vote, currentTime: now);
      expect(duration, isNull);
    });

    test('stopAt이 null이면 null을 반환한다', () {
      final now = DateTime.utc(2025, 6, 15);
      final vote = createTestVoteModel(
        startAt: DateTime.utc(2025, 6, 1),
        stopAt: null,
      );

      final duration = service.getTimeUntilDeadline(vote, currentTime: now);
      expect(duration, isNull);
    });
  });

  // =========================================================================
  // getTimeUntilStart 테스트
  // =========================================================================
  group('getTimeUntilStart', () {
    test('예정된 투표에 대해 올바른 Duration을 반환한다', () {
      final now = DateTime.utc(2025, 5, 15, 12, 0);
      final startAt = DateTime.utc(2025, 6, 1, 12, 0);
      final vote = createTestVoteModel(
        startAt: startAt,
        stopAt: DateTime.utc(2025, 6, 30),
      );

      final duration = service.getTimeUntilStart(vote, currentTime: now);

      expect(duration, isNotNull);
      expect(duration!.inDays, equals(17));
    });

    test('이미 시작된 (ongoing) 투표에 대해 null을 반환한다', () {
      final now = DateTime.utc(2025, 6, 15);
      final vote = createTestVoteModel(
        startAt: DateTime.utc(2025, 6, 1),
        stopAt: DateTime.utc(2025, 6, 30),
      );

      final duration = service.getTimeUntilStart(vote, currentTime: now);
      expect(duration, isNull);
    });

    test('이미 종료된 (ended) 투표에 대해 null을 반환한다', () {
      final now = DateTime.utc(2025, 7, 15);
      final vote = createTestVoteModel(
        startAt: DateTime.utc(2025, 6, 1),
        stopAt: DateTime.utc(2025, 6, 30),
      );

      final duration = service.getTimeUntilStart(vote, currentTime: now);
      expect(duration, isNull);
    });

    test('startAt이 null이면 null을 반환한다', () {
      final now = DateTime.utc(2025, 6, 15);
      final vote = createTestVoteModel(startAt: null, stopAt: null);

      final duration = service.getTimeUntilStart(vote, currentTime: now);
      expect(duration, isNull);
    });
  });

  // =========================================================================
  // isNearDeadline 테스트
  // =========================================================================
  group('isNearDeadline', () {
    test('마감까지 임계값(기본 10분) 미만이면 true를 반환한다', () {
      final stopAt = DateTime.utc(2025, 6, 30, 12, 0);
      final now = DateTime.utc(2025, 6, 30, 11, 55); // 5분 남음
      final vote = createTestVoteModel(
        startAt: DateTime.utc(2025, 6, 1),
        stopAt: stopAt,
      );

      expect(service.isNearDeadline(vote, currentTime: now), isTrue);
    });

    test('마감까지 임계값(기본 10분) 이상이면 false를 반환한다', () {
      final stopAt = DateTime.utc(2025, 6, 30, 12, 0);
      final now = DateTime.utc(2025, 6, 30, 11, 0); // 1시간 남음
      final vote = createTestVoteModel(
        startAt: DateTime.utc(2025, 6, 1),
        stopAt: stopAt,
      );

      expect(service.isNearDeadline(vote, currentTime: now), isFalse);
    });

    test('이미 종료된 투표에 대해 false를 반환한다', () {
      final now = DateTime.utc(2025, 7, 15);
      final vote = createTestVoteModel(
        startAt: DateTime.utc(2025, 6, 1),
        stopAt: DateTime.utc(2025, 6, 30),
      );

      expect(service.isNearDeadline(vote, currentTime: now), isFalse);
    });

    test('커스텀 임계값이 올바르게 적용된다', () {
      final stopAt = DateTime.utc(2025, 6, 30, 12, 0);
      final now = DateTime.utc(2025, 6, 30, 11, 0); // 1시간 남음
      final vote = createTestVoteModel(
        startAt: DateTime.utc(2025, 6, 1),
        stopAt: stopAt,
      );

      // 기본 임계값(10분)으로는 false
      expect(service.isNearDeadline(vote, currentTime: now), isFalse);

      // 2시간 임계값으로는 true
      expect(
        service.isNearDeadline(
          vote,
          warningThreshold: const Duration(hours: 2),
          currentTime: now,
        ),
        isTrue,
      );
    });

    test('정확히 임계값과 같은 시간이 남으면 true를 반환한다', () {
      final stopAt = DateTime.utc(2025, 6, 30, 12, 0);
      final now = DateTime.utc(2025, 6, 30, 11, 50); // 정확히 10분 남음
      final vote = createTestVoteModel(
        startAt: DateTime.utc(2025, 6, 1),
        stopAt: stopAt,
      );

      expect(service.isNearDeadline(vote, currentTime: now), isTrue);
    });
  });

  // =========================================================================
  // getStatusSummary 테스트
  // =========================================================================
  group('getStatusSummary', () {
    test('notVisible 상태에서 "공개 예정"을 반환한다', () {
      final now = DateTime.utc(2025, 4, 15);
      final vote = createTestVoteModel(
        visibleAt: DateTime.utc(2025, 5, 1),
        startAt: DateTime.utc(2025, 6, 1),
        stopAt: DateTime.utc(2025, 6, 30),
      );

      final summary = service.getStatusSummary(vote, currentTime: now);
      expect(summary, equals('공개 예정'));
    });

    test('ended 상태에서 "종료됨"을 반환한다', () {
      final now = DateTime.utc(2025, 7, 15);
      final vote = createTestVoteModel(
        startAt: DateTime.utc(2025, 6, 1),
        stopAt: DateTime.utc(2025, 6, 30),
      );

      final summary = service.getStatusSummary(vote, currentTime: now);
      expect(summary, equals('종료됨'));
    });

    test('unknown 상태에서 "상태 불명"을 반환한다', () {
      final now = DateTime.utc(2025, 6, 15);
      final vote = createTestVoteModel(startAt: null, stopAt: null);

      final summary = service.getStatusSummary(vote, currentTime: now);
      expect(summary, equals('상태 불명'));
    });

    test('upcoming 상태에서 일 단위로 포맷한다', () {
      final now = DateTime.utc(2025, 5, 15, 12, 0);
      final vote = createTestVoteModel(
        startAt: DateTime.utc(2025, 5, 20, 12, 0), // 5일 후
        stopAt: DateTime.utc(2025, 6, 30),
      );

      final summary = service.getStatusSummary(vote, currentTime: now);
      expect(summary, equals('5일 후 시작'));
    });

    test('upcoming 상태에서 시간 단위로 포맷한다', () {
      final now = DateTime.utc(2025, 5, 15, 12, 0);
      final vote = createTestVoteModel(
        startAt: DateTime.utc(2025, 5, 15, 15, 0), // 3시간 후
        stopAt: DateTime.utc(2025, 6, 30),
      );

      final summary = service.getStatusSummary(vote, currentTime: now);
      expect(summary, equals('3시간 후 시작'));
    });

    test('upcoming 상태에서 분 단위로 포맷한다', () {
      final now = DateTime.utc(2025, 5, 15, 12, 0);
      final vote = createTestVoteModel(
        startAt: DateTime.utc(2025, 5, 15, 12, 30), // 30분 후
        stopAt: DateTime.utc(2025, 6, 30),
      );

      final summary = service.getStatusSummary(vote, currentTime: now);
      expect(summary, equals('30분 후 시작'));
    });

    test('ongoing 상태에서 일 단위로 포맷한다', () {
      final now = DateTime.utc(2025, 6, 15, 12, 0);
      final vote = createTestVoteModel(
        startAt: DateTime.utc(2025, 6, 1),
        stopAt: DateTime.utc(2025, 6, 25, 12, 0), // 10일 남음
      );

      final summary = service.getStatusSummary(vote, currentTime: now);
      expect(summary, equals('10일 남음'));
    });

    test('ongoing 상태에서 시간 단위로 포맷한다', () {
      final now = DateTime.utc(2025, 6, 15, 12, 0);
      final vote = createTestVoteModel(
        startAt: DateTime.utc(2025, 6, 1),
        stopAt: DateTime.utc(2025, 6, 15, 18, 0), // 6시간 남음
      );

      final summary = service.getStatusSummary(vote, currentTime: now);
      expect(summary, equals('6시간 남음'));
    });

    test('ongoing 상태에서 분 단위로 포맷한다', () {
      final now = DateTime.utc(2025, 6, 15, 12, 0);
      final vote = createTestVoteModel(
        startAt: DateTime.utc(2025, 6, 1),
        stopAt: DateTime.utc(2025, 6, 15, 12, 45), // 45분 남음
      );

      final summary = service.getStatusSummary(vote, currentTime: now);
      expect(summary, equals('45분 남음'));
    });
  });
}

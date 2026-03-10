import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/errors/vote_request_exceptions.dart';
import 'package:picnic_lib/data/repositories/vote_item_request_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../helpers/mocks/mock_supabase.dart';

/// 에러를 시뮬레이션하기 위한 Fake SupabaseClient
/// rpc와 from 호출 시 지정된 에러를 던진다
class FakeErrorSupabaseClient extends Fake implements SupabaseClient {
  final Exception? rpcError;
  final Exception? fromError;

  FakeErrorSupabaseClient({this.rpcError, this.fromError});

  @override
  SupabaseQueryBuilder from(String table) {
    if (fromError != null) throw fromError!;
    throw UnimplementedError('from not mocked for success path');
  }

  @override
  PostgrestFilterBuilder<T> rpc<T>(String fn,
      {Map<String, dynamic>? params, get = false}) {
    if (rpcError != null) throw rpcError!;
    throw UnimplementedError('rpc not mocked for success path');
  }
}

void main() {
  group('VoteItemRequestRepository', () {
    group('인스턴스 생성', () {
      test('mock 클라이언트로 인스턴스를 생성할 수 있다', () {
        final mockClient = MockSupabaseClient();
        final repository = VoteItemRequestRepository(supabase: mockClient);
        expect(repository, isNotNull);
        expect(repository, isA<VoteItemRequestRepository>());
      });

      test('다른 mock 클라이언트로도 인스턴스를 생성할 수 있다', () {
        final anotherClient = MockSupabaseClient();
        final anotherRepo =
            VoteItemRequestRepository(supabase: anotherClient);
        expect(anotherRepo, isNotNull);
      });
    });

    group('에러 처리 - createVoteItemRequestWithUser', () {
      test('Supabase rpc 호출 실패 시 VoteRequestException을 던진다', () async {
        final fakeClient = FakeErrorSupabaseClient(
          rpcError: Exception('네트워크 오류'),
        );
        final repository = VoteItemRequestRepository(supabase: fakeClient);

        expect(
          () => repository.createVoteItemRequestWithUser(
            voteId: 1,
            artistId: 100,
            userId: 'user-123',
          ),
          throwsA(isA<VoteRequestException>()),
        );
      });

      test('중복 신청 시 DuplicateVoteRequestException을 던진다', () async {
        final fakeClient = FakeErrorSupabaseClient(
          rpcError: Exception('이미 해당 아티스트에 대해 신청하셨습니다'),
        );
        final repository = VoteItemRequestRepository(supabase: fakeClient);

        expect(
          () => repository.createVoteItemRequestWithUser(
            voteId: 1,
            artistId: 100,
            userId: 'user-123',
          ),
          throwsA(isA<DuplicateVoteRequestException>()),
        );
      });

      test('존재하지 않는 아티스트일 때 VoteRequestException을 던진다', () async {
        final fakeClient = FakeErrorSupabaseClient(
          rpcError: Exception('존재하지 않는 아티스트입니다'),
        );
        final repository = VoteItemRequestRepository(supabase: fakeClient);

        expect(
          () => repository.createVoteItemRequestWithUser(
            voteId: 1,
            artistId: 999,
            userId: 'user-123',
          ),
          throwsA(
            isA<VoteRequestException>().having(
              (e) => e.message,
              'message',
              '존재하지 않는 아티스트입니다.',
            ),
          ),
        );
      });
    });

    group('에러 처리 - getArtistRequestCount', () {
      test('rpc 호출 실패 시 VoteRequestException을 던진다', () async {
        final fakeClient = FakeErrorSupabaseClient(
          rpcError: Exception('서버 오류'),
        );
        final repository = VoteItemRequestRepository(supabase: fakeClient);

        expect(
          () => repository.getArtistRequestCount(1, 100),
          throwsA(isA<VoteRequestException>()),
        );
      });
    });

    group('에러 처리 - getVoteItemRequestCount', () {
      test('쿼리 실패 시 VoteRequestException을 던진다', () async {
        final fakeClient = FakeErrorSupabaseClient(
          fromError: Exception('테이블 접근 오류'),
        );
        final repository = VoteItemRequestRepository(supabase: fakeClient);

        expect(
          () => repository.getVoteItemRequestCount(1),
          throwsA(isA<VoteRequestException>()),
        );
      });
    });

    group('에러 처리 - deleteVoteItemRequest', () {
      test('삭제 실패 시 VoteRequestException을 던진다', () async {
        final fakeClient = FakeErrorSupabaseClient(
          fromError: Exception('삭제 권한 없음'),
        );
        final repository = VoteItemRequestRepository(supabase: fakeClient);

        expect(
          () => repository.deleteVoteItemRequest('req-123'),
          throwsA(isA<VoteRequestException>()),
        );
      });
    });

    group('에러 처리 - deleteUserRequest', () {
      test('사용자 신청 삭제 실패 시 VoteRequestException을 던진다', () async {
        final fakeClient = FakeErrorSupabaseClient(
          fromError: Exception('삭제 실패'),
        );
        final repository = VoteItemRequestRepository(supabase: fakeClient);

        expect(
          () => repository.deleteUserRequest('user-req-456'),
          throwsA(isA<VoteRequestException>()),
        );
      });
    });

    group('에러 처리 - getCurrentUserApplicationsWithDetails', () {
      test('쿼리 실패 시 VoteRequestException을 던진다', () async {
        final fakeClient = FakeErrorSupabaseClient(
          fromError: Exception('조회 실패'),
        );
        final repository = VoteItemRequestRepository(supabase: fakeClient);

        expect(
          () => repository.getCurrentUserApplicationsWithDetails('user-123'),
          throwsA(isA<VoteRequestException>()),
        );
      });
    });

    group('에러 처리 - getUserApplicationStatus', () {
      test('쿼리 실패 시 VoteRequestException을 던진다', () async {
        final fakeClient = FakeErrorSupabaseClient(
          fromError: Exception('상태 조회 실패'),
        );
        final repository = VoteItemRequestRepository(supabase: fakeClient);

        expect(
          () => repository.getUserApplicationStatus('user-123', 1, 100),
          throwsA(isA<VoteRequestException>()),
        );
      });
    });

    group('에러 처리 - hasUserRequestedArtist', () {
      test('쿼리 실패 시 VoteRequestException을 던진다', () async {
        final fakeClient = FakeErrorSupabaseClient(
          fromError: Exception('확인 실패'),
        );
        final repository = VoteItemRequestRepository(supabase: fakeClient);

        expect(
          () => repository.hasUserRequestedArtist(1, 100, 'user-123'),
          throwsA(isA<VoteRequestException>()),
        );
      });
    });

    group('에러 처리 - getVoteItemRequestsByVoteId', () {
      test('쿼리 실패 시 VoteRequestException을 던진다', () async {
        final fakeClient = FakeErrorSupabaseClient(
          fromError: Exception('목록 조회 실패'),
        );
        final repository = VoteItemRequestRepository(supabase: fakeClient);

        expect(
          () => repository.getVoteItemRequestsByVoteId(1),
          throwsA(isA<VoteRequestException>()),
        );
      });
    });

    group('에러 처리 - getUserRequestsByVoteId', () {
      test('쿼리 실패 시 VoteRequestException을 던진다', () async {
        final fakeClient = FakeErrorSupabaseClient(
          fromError: Exception('사용자 신청 내역 조회 실패'),
        );
        final repository = VoteItemRequestRepository(supabase: fakeClient);

        expect(
          () => repository.getUserRequestsByVoteId('user-123', 1),
          throwsA(isA<VoteRequestException>()),
        );
      });
    });

    group('에러 처리 - getAllUserRequests', () {
      test('쿼리 실패 시 VoteRequestException을 던진다', () async {
        final fakeClient = FakeErrorSupabaseClient(
          fromError: Exception('전체 신청 내역 조회 실패'),
        );
        final repository = VoteItemRequestRepository(supabase: fakeClient);

        expect(
          () => repository.getAllUserRequests('user-123'),
          throwsA(isA<VoteRequestException>()),
        );
      });
    });

    group('예외 클래스 검증', () {
      test('VoteRequestException은 메시지를 포함한다', () {
        const exception = VoteRequestException('테스트 에러');
        expect(exception.message, '테스트 에러');
        expect(exception.toString(), contains('VoteRequestException'));
        expect(exception.toString(), contains('테스트 에러'));
      });

      test('DuplicateVoteRequestException은 VoteRequestException의 하위 클래스이다',
          () {
        const exception = DuplicateVoteRequestException('중복');
        expect(exception, isA<VoteRequestException>());
        expect(exception.toString(), contains('DuplicateVoteRequestException'));
      });

      test('VoteRequestNotFoundException은 VoteRequestException의 하위 클래스이다',
          () {
        const exception = VoteRequestNotFoundException('찾을 수 없음');
        expect(exception, isA<VoteRequestException>());
        expect(
            exception.toString(), contains('VoteRequestNotFoundException'));
      });

      test(
          'InvalidVoteRequestStatusException은 VoteRequestException의 하위 클래스이다',
          () {
        const exception = InvalidVoteRequestStatusException('상태 변경 불가');
        expect(exception, isA<VoteRequestException>());
        expect(exception.toString(),
            contains('InvalidVoteRequestStatusException'));
      });
    });
  });
}

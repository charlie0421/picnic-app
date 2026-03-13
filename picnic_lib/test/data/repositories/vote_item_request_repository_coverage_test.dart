import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/errors/vote_request_exceptions.dart';
import 'package:picnic_lib/data/repositories/vote_item_request_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Fake SupabaseClient that throws on from() and rpc() calls
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

/// Additional tests targeting uncovered lines in vote_item_request_repository.dart.
///
/// Targets:
/// - getApplicationCountByTitle error path (line 54)
/// - createVoteItemRequestUser error wrapping (lines 78-93)
/// - getUserVoteItemRequests delegation (lines 97-104)
/// - updateVoteItemRequestStatus error (line 240)
/// - getArtistRequestStatistics error (line 255)
/// - getVoteRequestStatusSummary error (line 271)
/// - getUserRequestHistory error (line 287)
void main() {
  group('VoteItemRequestRepository - error handling', () {
    test('getApplicationCountByTitle throws VoteRequestException on error',
        () async {
      final fakeClient = FakeErrorSupabaseClient(
        fromError: Exception('table access error'),
      );
      final repository = VoteItemRequestRepository(supabase: fakeClient);

      expect(
        () => repository.getApplicationCountByTitle('test'),
        throwsA(isA<VoteRequestException>()),
      );
    });

    test('createVoteItemRequestUser wraps rpc error as VoteRequestException',
        () async {
      final fakeClient = FakeErrorSupabaseClient(
        rpcError: Exception('generic rpc error'),
      );
      final repository = VoteItemRequestRepository(supabase: fakeClient);

      expect(
        () => repository.createVoteItemRequestUser(
          voteId: 1,
          artistId: 100,
          userId: 'user-123',
        ),
        throwsA(isA<VoteRequestException>()),
      );
    });

    test('createVoteItemRequestUser wraps duplicate error', () async {
      final fakeClient = FakeErrorSupabaseClient(
        rpcError: Exception('이미 해당 아티스트에 대해 신청하셨습니다'),
      );
      final repository = VoteItemRequestRepository(supabase: fakeClient);

      expect(
        () => repository.createVoteItemRequestUser(
          voteId: 1,
          artistId: 100,
          userId: 'user-123',
        ),
        throwsA(isA<VoteRequestException>()),
      );
    });

    test('getUserVoteItemRequests throws VoteRequestException on error',
        () async {
      final fakeClient = FakeErrorSupabaseClient(
        fromError: Exception('query error'),
      );
      final repository = VoteItemRequestRepository(supabase: fakeClient);

      expect(
        () => repository.getUserVoteItemRequests('user-123'),
        throwsA(isA<VoteRequestException>()),
      );
    });

    test('updateVoteItemRequestStatus throws VoteRequestException on error',
        () async {
      final fakeClient = FakeErrorSupabaseClient(
        fromError: Exception('update error'),
      );
      final repository = VoteItemRequestRepository(supabase: fakeClient);

      expect(
        () => repository.updateVoteItemRequestStatus('req-123', 'approved'),
        throwsA(isA<VoteRequestException>()),
      );
    });

    test('getArtistRequestStatistics throws VoteRequestException on error',
        () async {
      final fakeClient = FakeErrorSupabaseClient(
        fromError: Exception('stats error'),
      );
      final repository = VoteItemRequestRepository(supabase: fakeClient);

      expect(
        () => repository.getArtistRequestStatistics(100),
        throwsA(isA<VoteRequestException>()),
      );
    });

    test('getVoteRequestStatusSummary throws VoteRequestException on error',
        () async {
      final fakeClient = FakeErrorSupabaseClient(
        fromError: Exception('summary error'),
      );
      final repository = VoteItemRequestRepository(supabase: fakeClient);

      expect(
        () => repository.getVoteRequestStatusSummary(1),
        throwsA(isA<VoteRequestException>()),
      );
    });

    test('getUserRequestHistory throws VoteRequestException on error',
        () async {
      final fakeClient = FakeErrorSupabaseClient(
        fromError: Exception('history error'),
      );
      final repository = VoteItemRequestRepository(supabase: fakeClient);

      expect(
        () => repository.getUserRequestHistory('user-123'),
        throwsA(isA<VoteRequestException>()),
      );
    });
  });

  group('VoteItemRequestRepository - specific error messages', () {
    test('createVoteItemRequestWithUser detects non-existent artist error',
        () async {
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

    test(
        'createVoteItemRequestWithUser detects duplicate request error as DuplicateVoteRequestException',
        () async {
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

    test(
        'createVoteItemRequestWithUser wraps generic error as VoteRequestException',
        () async {
      final fakeClient = FakeErrorSupabaseClient(
        rpcError: Exception('unknown server error'),
      );
      final repository = VoteItemRequestRepository(supabase: fakeClient);

      expect(
        () => repository.createVoteItemRequestWithUser(
          voteId: 1,
          artistId: 100,
          userId: 'user-123',
        ),
        throwsA(
          isA<VoteRequestException>().having(
            (e) => e.message,
            'message',
            contains('투표 아이템 요청 생성 실패'),
          ),
        ),
      );
    });
  });

  group('VoteItemRequestRepository - exception class tests', () {
    test('VoteRequestException stores and displays message', () {
      const e = VoteRequestException('test error');
      expect(e.message, 'test error');
      expect(e.toString(), contains('VoteRequestException'));
      expect(e.toString(), contains('test error'));
    });

    test('DuplicateVoteRequestException is a VoteRequestException', () {
      const e = DuplicateVoteRequestException('duplicate');
      expect(e, isA<VoteRequestException>());
      expect(e.message, 'duplicate');
    });

    test('VoteRequestNotFoundException is a VoteRequestException', () {
      const e = VoteRequestNotFoundException('not found');
      expect(e, isA<VoteRequestException>());
    });

    test('InvalidVoteRequestStatusException is a VoteRequestException', () {
      const e = InvalidVoteRequestStatusException('bad status');
      expect(e, isA<VoteRequestException>());
    });
  });
}

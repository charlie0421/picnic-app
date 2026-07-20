import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:picnic_lib/core/errors/anti_abuse_exception.dart';
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
  PostgrestFilterBuilder<T> rpc<T>(
    String fn, {
    Map<String, dynamic>? params,
    get = false,
  }) {
    if (rpcError != null) throw rpcError!;
    throw UnimplementedError('rpc not mocked for success path');
  }
}

/// artist-request-add edge fn 응답을 시뮬레이션하는 SupabaseClient.
///
/// [responseStatus] / [responseBody] 로 단일 응답을 강제. functions.invoke 가 호출되면 동일
/// 응답 반환. ip_hash 등 다른 호출은 mock 하지 않음 (이 테스트 범위 외).
SupabaseClient _edgeFnClient({
  required int responseStatus,
  required Map<String, dynamic> responseBody,
}) {
  final mock = MockClient((req) async {
    return http.Response(
      jsonEncode(responseBody),
      responseStatus,
      headers: {'content-type': 'application/json'},
    );
  });
  return SupabaseClient(
    'http://localhost:54321',
    'test-anon-key',
    httpClient: mock,
    authOptions: const AuthClientOptions(autoRefreshToken: false),
  );
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
        final anotherRepo = VoteItemRequestRepository(supabase: anotherClient);
        expect(anotherRepo, isNotNull);
      });
    });

    group('에러 처리 - createVoteItemRequestWithUser (edge fn 경로)', () {
      test('artist-request-add 호출 실패 (네트워크) 시 VoteRequestException', () async {
        final mock = MockClient((req) async {
          throw Exception('네트워크 오류');
        });
        final client = SupabaseClient(
          'http://localhost:54321',
          'test-anon-key',
          httpClient: mock,
          authOptions: const AuthClientOptions(autoRefreshToken: false),
        );
        final repository = VoteItemRequestRepository(supabase: client);

        expect(
          () => repository.createVoteItemRequestWithUser(
            voteId: 1,
            artistId: 100,
            userId: 'user-123',
          ),
          throwsA(isA<VoteRequestException>()),
        );
      });

      test('createVoteItemRequestUser는 중복 예외를 보존한다', () async {
        final client = _edgeFnClient(
          responseStatus: 409,
          responseBody: {
            'success': false,
            'error': {
              'message': 'Already requested',
              'code': 'ALREADY_REQUESTED',
              'details': null,
            },
          },
        );
        final repository = VoteItemRequestRepository(supabase: client);

        expect(
          () => repository.createVoteItemRequestUser(
            voteId: 1,
            artistId: 100,
            userId: 'user-123',
          ),
          throwsA(isA<DuplicateVoteRequestException>()),
        );
      });

      test('ALREADY_REQUESTED (409) → DuplicateVoteRequestException', () async {
        final client = _edgeFnClient(
          responseStatus: 409,
          responseBody: {
            'success': false,
            'error': {
              'message': 'Already requested',
              'code': 'ALREADY_REQUESTED',
              'details': null,
            },
          },
        );
        final repository = VoteItemRequestRepository(supabase: client);

        expect(
          () => repository.createVoteItemRequestWithUser(
            voteId: 1,
            artistId: 100,
            userId: 'user-123',
          ),
          throwsA(isA<DuplicateVoteRequestException>()),
        );
      });

      test('ARTIST_NOT_FOUND (404) → VoteRequestException', () async {
        final client = _edgeFnClient(
          responseStatus: 404,
          responseBody: {
            'success': false,
            'error': {
              'message': 'Artist not found',
              'code': 'ARTIST_NOT_FOUND',
              'details': null,
            },
          },
        );
        final repository = VoteItemRequestRepository(supabase: client);

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
        '429 RATE_LIMITED → AntiAbuseException(channel: artist_request)',
        () async {
          final client = _edgeFnClient(
            responseStatus: 429,
            responseBody: {
              'success': false,
              'error': {
                'message': '...',
                'code': 'RATE_LIMITED',
                'details': {
                  'reason': 'artist_request_ip_quota',
                  'retry_after_seconds': 86400,
                  'support_contact': 'cs@picnic.fan',
                },
              },
            },
          );
          final repository = VoteItemRequestRepository(supabase: client);

          expect(
            () => repository.createVoteItemRequestWithUser(
              voteId: 1,
              artistId: 100,
              userId: 'user-123',
            ),
            throwsA(
              isA<AntiAbuseException>().having(
                (e) => e.channel,
                'channel',
                'artist_request',
              ),
            ),
          );
        },
      );

      test(
        '서버가 success=true 인데 data 가 null/비-Map → VoteRequestException',
        () async {
          final client = _edgeFnClient(
            responseStatus: 200,
            responseBody: {'success': true, 'data': null},
          );
          final repository = VoteItemRequestRepository(supabase: client);

          expect(
            () => repository.createVoteItemRequestWithUser(
              voteId: 1,
              artistId: 100,
              userId: 'user-123',
            ),
            throwsA(isA<VoteRequestException>()),
          );
        },
      );
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

      test('42P01은 기능 사용 불가 메시지로 변환한다', () async {
        final missingTable = PostgrestException(
          message: 'relation "vote_item_requests" does not exist',
          code: '42P01',
        );
        final repository = VoteItemRequestRepository(
          supabase: FakeErrorSupabaseClient(fromError: missingTable),
        );

        expect(
          () => repository.getCurrentUserApplicationsWithDetails('user-123'),
          throwsA(
            isA<VoteRequestException>().having(
              (error) => error.message,
              'message',
              '현재 투표 신청 기능을 사용할 수 없습니다.',
            ),
          ),
        );
      });
    });

    group('테이블 기반 메서드 에러 매핑', () {
      final methods =
          <String, Future<dynamic> Function(VoteItemRequestRepository)>{
            'getApplicationCountByTitle': (repository) =>
                repository.getApplicationCountByTitle('지민'),
            'updateVoteItemRequestStatus': (repository) =>
                repository.updateVoteItemRequestStatus('req-123', 'approved'),
            'getArtistRequestStatistics': (repository) =>
                repository.getArtistRequestStatistics(100),
            'getVoteRequestStatusSummary': (repository) =>
                repository.getVoteRequestStatusSummary(1),
            'getUserRequestHistory': (repository) =>
                repository.getUserRequestHistory('user-123'),
          };

      for (final entry in methods.entries) {
        test('${entry.key} 실패를 VoteRequestException으로 변환한다', () async {
          final repository = VoteItemRequestRepository(
            supabase: FakeErrorSupabaseClient(
              fromError: Exception('${entry.key} failure'),
            ),
          );

          expect(
            () => entry.value(repository),
            throwsA(isA<VoteRequestException>()),
          );
        });
      }
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

      test('DuplicateVoteRequestException은 VoteRequestException의 하위 클래스이다', () {
        const exception = DuplicateVoteRequestException('중복');
        expect(exception, isA<VoteRequestException>());
        expect(exception.toString(), contains('DuplicateVoteRequestException'));
      });

      test('VoteRequestNotFoundException은 VoteRequestException의 하위 클래스이다', () {
        const exception = VoteRequestNotFoundException('찾을 수 없음');
        expect(exception, isA<VoteRequestException>());
        expect(exception.toString(), contains('VoteRequestNotFoundException'));
      });

      test(
        'InvalidVoteRequestStatusException은 VoteRequestException의 하위 클래스이다',
        () {
          const exception = InvalidVoteRequestStatusException('상태 변경 불가');
          expect(exception, isA<VoteRequestException>());
          expect(
            exception.toString(),
            contains('InvalidVoteRequestStatusException'),
          );
        },
      );
    });
  });
}

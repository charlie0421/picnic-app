import 'package:flutter_test/flutter_test.dart';
import 'package:picnic_lib/core/errors/vote_request_exceptions.dart';
import 'package:picnic_lib/services/data_validation_service.dart';

void main() {
  late DataValidationService service;

  setUp(() {
    service = DataValidationService();
  });

  group('ValidationResult', () {
    test('success는 isValid=true이고 에러/경고가 없음', () {
      const result = ValidationResult.success;
      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
      expect(result.warnings, isEmpty);
      expect(result.firstError, isNull);
    });

    test('failure는 에러 목록을 포함', () {
      final result =
          ValidationResult.failure(['에러1', '에러2'], warnings: ['경고1']);
      expect(result.isValid, isFalse);
      expect(result.errors, hasLength(2));
      expect(result.warnings, hasLength(1));
      expect(result.firstError, equals('에러1'));
      expect(result.allErrors, equals('에러1\n에러2'));
      expect(result.allWarnings, equals('경고1'));
    });

    test('successWithWarnings는 isValid=true이고 경고 포함', () {
      final result = ValidationResult.successWithWarnings(['경고1']);
      expect(result.isValid, isTrue);
      expect(result.warnings, hasLength(1));
      expect(result.errors, isEmpty);
    });
  });

  group('validateField', () {
    test('필수 필드가 null이면 실패', () {
      final result = service.validateField(
        value: null,
        rule: const FieldValidationRule(
          fieldName: '테스트',
          required: true,
        ),
      );
      expect(result.isValid, isFalse);
      expect(result.firstError, contains('입력해주세요'));
    });

    test('필수 필드가 빈 문자열이면 실패', () {
      final result = service.validateField(
        value: '   ',
        rule: const FieldValidationRule(
          fieldName: '테스트',
          required: true,
        ),
      );
      expect(result.isValid, isFalse);
    });

    test('선택 필드가 null이면 성공', () {
      final result = service.validateField(
        value: null,
        rule: const FieldValidationRule(
          fieldName: '테스트',
          required: false,
          minLength: 5,
        ),
      );
      expect(result.isValid, isTrue);
    });

    test('최소 길이 미달 시 실패', () {
      final result = service.validateField(
        value: 'a',
        rule: const FieldValidationRule(
          fieldName: '이름',
          minLength: 3,
        ),
      );
      expect(result.isValid, isFalse);
      expect(result.firstError, contains('최소 3자'));
    });

    test('최대 길이 초과 시 실패', () {
      final result = service.validateField(
        value: 'a' * 60,
        rule: const FieldValidationRule(
          fieldName: '이름',
          maxLength: 50,
        ),
      );
      expect(result.isValid, isFalse);
      expect(result.firstError, contains('최대 50자'));
    });

    test('패턴 불일치 시 실패', () {
      final result = service.validateField(
        value: 'abc',
        rule: FieldValidationRule(
          fieldName: '숫자',
          pattern: RegExp(r'^\d+$'),
          patternErrorMessage: '숫자만 입력 가능합니다.',
        ),
      );
      expect(result.isValid, isFalse);
      expect(result.firstError, equals('숫자만 입력 가능합니다.'));
    });

    test('패턴 불일치 시 기본 메시지 사용', () {
      final result = service.validateField(
        value: 'abc',
        rule: FieldValidationRule(
          fieldName: '숫자',
          pattern: RegExp(r'^\d+$'),
        ),
      );
      expect(result.isValid, isFalse);
      expect(result.firstError, contains('형식이 올바르지 않습니다'));
    });

    test('허용된 값 목록에 없는 값이면 실패', () {
      final result = service.validateField(
        value: 'invalid',
        rule: const FieldValidationRule(
          fieldName: '상태',
          allowedValues: ['pending', 'approved'],
          checkSecurity: false,
        ),
      );
      expect(result.isValid, isFalse);
      expect(result.firstError, contains('허용되지 않는 값'));
    });

    test('허용된 값 목록에 있으면 성공', () {
      final result = service.validateField(
        value: 'approved',
        rule: const FieldValidationRule(
          fieldName: '상태',
          allowedValues: ['pending', 'approved'],
          checkSecurity: false,
        ),
      );
      expect(result.isValid, isTrue);
    });

    test('유효한 값이면 성공', () {
      final result = service.validateField(
        value: '정상 텍스트',
        rule: const FieldValidationRule(
          fieldName: '테스트',
          required: true,
          minLength: 2,
          maxLength: 100,
        ),
      );
      expect(result.isValid, isTrue);
    });
  });

  group('validateSecurity', () {
    test('일반 텍스트는 통과', () {
      final result = service.validateSecurity('안녕하세요 테스트입니다');
      expect(result.isValid, isTrue);
    });

    test('script 태그 차단', () {
      final result = service.validateSecurity('<script>alert("xss")</script>');
      expect(result.isValid, isFalse);
      expect(result.firstError, contains('허용되지 않는 문자'));
    });

    test('iframe 태그 차단', () {
      final result =
          service.validateSecurity('<iframe src="evil.com"></iframe>');
      expect(result.isValid, isFalse);
    });

    test('javascript: 프로토콜 차단', () {
      final result = service.validateSecurity('javascript:alert(1)');
      expect(result.isValid, isFalse);
    });

    test('onclick 이벤트 핸들러 차단', () {
      final result = service.validateSecurity('onclick=alert(1)');
      expect(result.isValid, isFalse);
    });

    test('SQL 인젝션 패턴 차단', () {
      // SQL 패턴: '...' 뒤에 SQL 키워드
      final result =
          service.validateSecurity("test' 'union select * from users");
      expect(result.isValid, isFalse);
    });

    test('SQL 주석 패턴 차단', () {
      final result = service.validateSecurity('admin -- comment');
      expect(result.isValid, isFalse);
    });

    test('HTML 태그 포함 시 경고', () {
      final result = service.validateSecurity('<b>bold</b>');
      // 위험하지 않은 HTML 태그는 경고만
      expect(result.warnings, isNotEmpty);
    });

    test('URL 인코딩 포함 시 경고', () {
      final result = service.validateSecurity('hello%20world');
      expect(result.warnings, isNotEmpty);
    });
  });

  group('validateVoteItemRequestData', () {
    test('아티스트 이름과 그룹 이름 모두 없으면 경고', () {
      final result = service.validateVoteItemRequestData(strictMode: true);
      // strictMode에서 아티스트/그룹 이름 없으면 경고
      expect(result.warnings, isNotEmpty);
    });

    test('아티스트 이름이 있으면 경고 없이 성공', () {
      final result = service.validateVoteItemRequestData(
        artistName: 'BTS',
        strictMode: true,
      );
      expect(result.isValid, isTrue);
    });

    test('그룹 이름만 있어도 성공', () {
      final result = service.validateVoteItemRequestData(
        groupName: '방탄소년단',
        strictMode: true,
      );
      expect(result.isValid, isTrue);
    });

    test('strictMode=false이면 아티스트/그룹 없어도 경고 없음', () {
      final result = service.validateVoteItemRequestData(strictMode: false);
      expect(result.isValid, isTrue);
      expect(result.warnings, isEmpty);
    });

    test('아티스트 이름이 너무 길면 실패', () {
      final result = service.validateVoteItemRequestData(
        artistName: 'a' * 60,
      );
      expect(result.isValid, isFalse);
      expect(result.firstError, contains('최대 50자'));
    });

    test('스팸성 내용 포함 시 경고', () {
      final result = service.validateVoteItemRequestData(
        artistName: 'ㅋㅋㅋㅋㅋㅋ',
      );
      expect(result.warnings.any((w) => w.contains('스팸')), isTrue);
    });

    test('부적절한 내용 포함 시 실패', () {
      final result = service.validateVoteItemRequestData(
        artistName: 'fuck',
      );
      expect(result.isValid, isFalse);
      expect(result.firstError, contains('부적절한 내용'));
    });
  });

  group('validateEmail', () {
    test('유효한 이메일은 통과', () {
      final result = service.validateEmail('user@example.com');
      expect(result.isValid, isTrue);
    });

    test('유효하지 않은 이메일은 실패', () {
      final result = service.validateEmail('not-an-email');
      expect(result.isValid, isFalse);
      expect(result.firstError, contains('이메일'));
    });

    test('빈 이메일은 필수 필드 검증 실패', () {
      final result = service.validateEmail('');
      expect(result.isValid, isFalse);
    });
  });

  group('validatePhoneNumber', () {
    test('유효한 전화번호는 통과', () {
      final result = service.validatePhoneNumber('010-1234-5678');
      expect(result.isValid, isTrue);
    });

    test('하이픈 없는 전화번호도 통과', () {
      final result = service.validatePhoneNumber('01012345678');
      expect(result.isValid, isTrue);
    });

    test('유효하지 않은 전화번호는 실패', () {
      final result = service.validatePhoneNumber('123456');
      expect(result.isValid, isFalse);
    });
  });

  group('validateUserId', () {
    test('유효한 ID는 통과', () {
      final result = service.validateUserId('user_123');
      expect(result.isValid, isTrue);
    });

    test('너무 짧은 ID는 실패', () {
      final result = service.validateUserId('ab');
      expect(result.isValid, isFalse);
    });

    test('특수문자 포함 ID는 실패', () {
      final result = service.validateUserId('user@name');
      expect(result.isValid, isFalse);
    });
  });

  group('validateVoteStatus', () {
    test('유효한 상태는 통과', () {
      for (final status in ['pending', 'approved', 'rejected', 'cancelled']) {
        final result = service.validateVoteStatus(status);
        expect(result.isValid, isTrue, reason: '$status should be valid');
      }
    });

    test('유효하지 않은 상태는 실패', () {
      final result = service.validateVoteStatus('unknown');
      expect(result.isValid, isFalse);
    });
  });

  group('validateAndThrow', () {
    test('유효한 데이터면 예외 없음', () {
      expect(
        () => service.validateAndThrow(artistName: 'BTS'),
        returnsNormally,
      );
    });

    test('유효하지 않은 데이터면 VoteRequestException 발생', () {
      expect(
        () => service.validateAndThrow(artistName: 'fuck'),
        throwsA(isA<VoteRequestException>()),
      );
    });
  });
}

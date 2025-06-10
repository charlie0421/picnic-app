import 'package:logger/logger.dart';
import 'package:picnic_lib/core/errors/vote_request_exceptions.dart';

/// 투표 신청 데이터 유효성 검사 결과
class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  const ValidationResult({
    required this.isValid,
    this.errors = const [],
    this.warnings = const [],
  });

  /// 성공적인 검증 결과
  static const ValidationResult success = ValidationResult(isValid: true);

  /// 실패한 검증 결과 생성
  static ValidationResult failure(List<String> errors,
      {List<String> warnings = const []}) {
    return ValidationResult(
      isValid: false,
      errors: errors,
      warnings: warnings,
    );
  }

  /// 경고가 있는 성공 결과 생성
  static ValidationResult successWithWarnings(List<String> warnings) {
    return ValidationResult(
      isValid: true,
      warnings: warnings,
    );
  }

  /// 첫 번째 오류 메시지 반환
  String? get firstError => errors.isNotEmpty ? errors.first : null;

  /// 모든 오류를 하나의 문자열로 결합
  String get allErrors => errors.join('\n');

  /// 모든 경고를 하나의 문자열로 결합
  String get allWarnings => warnings.join('\n');
}

/// 필드별 유효성 검사 규칙
class FieldValidationRule {
  final String fieldName;
  final bool required;
  final int? minLength;
  final int? maxLength;
  final RegExp? pattern;
  final String? patternErrorMessage;
  final List<String>? allowedValues;
  final bool checkSecurity;

  const FieldValidationRule({
    required this.fieldName,
    this.required = false,
    this.minLength,
    this.maxLength,
    this.pattern,
    this.patternErrorMessage,
    this.allowedValues,
    this.checkSecurity = true,
  });
}

/// 투표 신청 데이터 유효성 검사 서비스
class DataValidationService {
  static final Logger logger = Logger();

  /// 투표 신청 데이터 전체 검증
  ///
  /// [title] 신청 제목
  /// [description] 신청 설명
  /// [artistName] 아티스트 이름 (선택사항)
  /// [groupName] 그룹 이름 (선택사항)
  /// [strictMode] 엄격 모드 (기본값: true)
  ///
  /// Returns: [ValidationResult] 검증 결과
  ValidationResult validateVoteApplicationData({
    required String title,
    required String description,
    String? artistName,
    String? groupName,
    bool strictMode = true,
  }) {
    try {
      final errors = <String>[];
      final warnings = <String>[];

      // 1. 필수 필드 검증
      final titleResult = validateField(
        value: title,
        rule: const FieldValidationRule(
          fieldName: '신청 제목',
          required: true,
          minLength: 2,
          maxLength: 100,
        ),
      );
      if (!titleResult.isValid) errors.addAll(titleResult.errors);
      warnings.addAll(titleResult.warnings);

      final descriptionResult = validateField(
        value: description,
        rule: const FieldValidationRule(
          fieldName: '신청 설명',
          required: true,
          minLength: 10,
          maxLength: 1000,
        ),
      );
      if (!descriptionResult.isValid) errors.addAll(descriptionResult.errors);
      warnings.addAll(descriptionResult.warnings);

      // 2. 선택적 필드 검증
      if (artistName != null && artistName.trim().isNotEmpty) {
        final artistResult = validateField(
          value: artistName,
          rule: const FieldValidationRule(
            fieldName: '아티스트 이름',
            required: false,
            minLength: 1,
            maxLength: 50,
          ),
        );
        if (!artistResult.isValid) errors.addAll(artistResult.errors);
        warnings.addAll(artistResult.warnings);
      }

      if (groupName != null && groupName.trim().isNotEmpty) {
        final groupResult = validateField(
          value: groupName,
          rule: const FieldValidationRule(
            fieldName: '그룹 이름',
            required: false,
            minLength: 1,
            maxLength: 50,
          ),
        );
        if (!groupResult.isValid) errors.addAll(groupResult.errors);
        warnings.addAll(groupResult.warnings);
      }

      // 3. 비즈니스 로직 검증
      final businessResult = _validateBusinessRules(
        title: title,
        description: description,
        artistName: artistName,
        groupName: groupName,
        strictMode: strictMode,
      );
      if (!businessResult.isValid) errors.addAll(businessResult.errors);
      warnings.addAll(businessResult.warnings);

      // 4. 결과 반환
      if (errors.isNotEmpty) {
        logger.w('데이터 유효성 검사 실패: ${errors.join(', ')}');
        return ValidationResult.failure(errors, warnings: warnings);
      }

      if (warnings.isNotEmpty) {
        logger.d('데이터 유효성 검사 성공 (경고 있음): ${warnings.join(', ')}');
        return ValidationResult.successWithWarnings(warnings);
      }

      logger.d('데이터 유효성 검사 성공');
      return ValidationResult.success;
    } catch (e) {
      logger.e('데이터 유효성 검사 중 오류 발생', error: e);
      return ValidationResult.failure(['데이터 유효성 검사 중 오류가 발생했습니다: $e']);
    }
  }

  /// 개별 필드 유효성 검사
  ///
  /// [value] 검사할 값
  /// [rule] 검사 규칙
  ///
  /// Returns: [ValidationResult] 검증 결과
  ValidationResult validateField({
    required String? value,
    required FieldValidationRule rule,
  }) {
    final errors = <String>[];
    final warnings = <String>[];

    // 1. 필수 필드 검증
    if (rule.required && (value == null || value.trim().isEmpty)) {
      errors.add('${rule.fieldName}을(를) 입력해주세요.');
      return ValidationResult.failure(errors);
    }

    // 값이 없으면 더 이상 검증하지 않음
    if (value == null || value.trim().isEmpty) {
      return ValidationResult.success;
    }

    final trimmedValue = value.trim();

    // 2. 길이 검증
    if (rule.minLength != null && trimmedValue.length < rule.minLength!) {
      errors.add('${rule.fieldName}은(는) 최소 ${rule.minLength}자 이상 입력해주세요.');
    }

    if (rule.maxLength != null && trimmedValue.length > rule.maxLength!) {
      errors.add('${rule.fieldName}은(는) 최대 ${rule.maxLength}자 이내로 입력해주세요.');
    }

    // 3. 패턴 검증
    if (rule.pattern != null && !rule.pattern!.hasMatch(trimmedValue)) {
      errors
          .add(rule.patternErrorMessage ?? '${rule.fieldName}의 형식이 올바르지 않습니다.');
    }

    // 4. 허용된 값 검증
    if (rule.allowedValues != null &&
        !rule.allowedValues!.contains(trimmedValue)) {
      errors.add('${rule.fieldName}에 허용되지 않는 값입니다.');
    }

    // 5. 보안 검증
    if (rule.checkSecurity) {
      final securityResult = validateSecurity(trimmedValue);
      if (!securityResult.isValid) {
        errors.addAll(securityResult.errors);
      }
      warnings.addAll(securityResult.warnings);
    }

    // 6. 결과 반환
    if (errors.isNotEmpty) {
      return ValidationResult.failure(errors, warnings: warnings);
    }

    if (warnings.isNotEmpty) {
      return ValidationResult.successWithWarnings(warnings);
    }

    return ValidationResult.success;
  }

  /// 보안 검증 (XSS, 인젝션 공격 방지)
  ///
  /// [input] 검증할 입력 문자열
  ///
  /// Returns: [ValidationResult] 검증 결과
  ValidationResult validateSecurity(String input) {
    final errors = <String>[];
    final warnings = <String>[];

    // 1. 위험한 HTML 태그 및 스크립트 검증
    final dangerousPatterns = [
      RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false),
      RegExp(r'<iframe[^>]*>.*?</iframe>', caseSensitive: false),
      RegExp(r'<object[^>]*>.*?</object>', caseSensitive: false),
      RegExp(r'<embed[^>]*>.*?</embed>', caseSensitive: false),
      RegExp(r'javascript:', caseSensitive: false),
      RegExp(r'vbscript:', caseSensitive: false),
      RegExp(r'on\w+\s*=', caseSensitive: false), // onclick, onload 등
      RegExp(r'data:text/html', caseSensitive: false),
    ];

    for (final pattern in dangerousPatterns) {
      if (pattern.hasMatch(input)) {
        errors.add('허용되지 않는 문자가 포함되어 있습니다.');
        break;
      }
    }

    // 2. SQL 인젝션 패턴 검증
    final sqlPatterns = [
      RegExp(r"'.*?'.*?(union|select|insert|update|delete|drop|create|alter)",
          caseSensitive: false),
      RegExp(r'--.*$', multiLine: true),
      RegExp(r'/\*.*?\*/', multiLine: true),
    ];

    for (final pattern in sqlPatterns) {
      if (pattern.hasMatch(input)) {
        errors.add('허용되지 않는 문자가 포함되어 있습니다.');
        break;
      }
    }

    // 3. 의심스러운 패턴 경고
    final suspiciousPatterns = [
      RegExp(r'<[^>]+>', caseSensitive: false), // HTML 태그
      RegExp(r'&[a-zA-Z]+;', caseSensitive: false), // HTML 엔티티
      RegExp(r'%[0-9a-fA-F]{2}', caseSensitive: false), // URL 인코딩
    ];

    for (final pattern in suspiciousPatterns) {
      if (pattern.hasMatch(input)) {
        warnings.add('의심스러운 문자가 포함되어 있습니다. 검토가 필요할 수 있습니다.');
        break;
      }
    }

    // 4. 결과 반환
    if (errors.isNotEmpty) {
      return ValidationResult.failure(errors, warnings: warnings);
    }

    if (warnings.isNotEmpty) {
      return ValidationResult.successWithWarnings(warnings);
    }

    return ValidationResult.success;
  }

  /// 비즈니스 로직 검증
  ///
  /// [title] 신청 제목
  /// [description] 신청 설명
  /// [artistName] 아티스트 이름
  /// [groupName] 그룹 이름
  /// [strictMode] 엄격 모드
  ///
  /// Returns: [ValidationResult] 검증 결과
  ValidationResult _validateBusinessRules({
    required String title,
    required String description,
    String? artistName,
    String? groupName,
    bool strictMode = true,
  }) {
    final errors = <String>[];
    final warnings = <String>[];

    // 1. 아티스트 이름과 그룹 이름 중 하나는 필수 (엄격 모드에서)
    if (strictMode) {
      final hasArtist = artistName != null && artistName.trim().isNotEmpty;
      final hasGroup = groupName != null && groupName.trim().isNotEmpty;

      if (!hasArtist && !hasGroup) {
        warnings.add('아티스트 이름 또는 그룹 이름 중 하나는 입력하는 것이 좋습니다.');
      }
    }

    // 2. 제목과 설명의 중복 내용 검증
    final titleWords = title.toLowerCase().split(RegExp(r'\s+'));
    final descriptionWords = description.toLowerCase().split(RegExp(r'\s+'));

    final commonWords = titleWords
        .where((word) => word.length > 2 && descriptionWords.contains(word))
        .toList();

    if (commonWords.length > titleWords.length * 0.7) {
      warnings.add('제목과 설명이 너무 유사합니다. 더 구체적인 설명을 추가해주세요.');
    }

    // 3. 스팸성 내용 검증
    final spamPatterns = [
      RegExp(r'(.)\1{4,}'), // 같은 문자 5번 이상 반복
      RegExp(r'[!]{3,}'), // 느낌표 3개 이상
      RegExp(r'[?]{3,}'), // 물음표 3개 이상
      RegExp(r'[ㅋㅎ]{5,}'), // ㅋㅋㅋㅋㅋ, ㅎㅎㅎㅎㅎ 등
    ];

    final allText =
        '$title $description ${artistName ?? ''} ${groupName ?? ''}';
    for (final pattern in spamPatterns) {
      if (pattern.hasMatch(allText)) {
        warnings.add('스팸성 내용이 포함되어 있을 수 있습니다.');
        break;
      }
    }

    // 4. 욕설 및 부적절한 내용 검증 (기본적인 패턴만)
    final inappropriatePatterns = [
      RegExp(r'(시발|씨발|개새끼|병신|멍청이)', caseSensitive: false),
      RegExp(r'(fuck|shit|damn)', caseSensitive: false),
    ];

    for (final pattern in inappropriatePatterns) {
      if (pattern.hasMatch(allText)) {
        errors.add('부적절한 내용이 포함되어 있습니다.');
        break;
      }
    }

    // 5. 결과 반환
    if (errors.isNotEmpty) {
      return ValidationResult.failure(errors, warnings: warnings);
    }

    if (warnings.isNotEmpty) {
      return ValidationResult.successWithWarnings(warnings);
    }

    return ValidationResult.success;
  }

  /// 이메일 형식 검증
  ///
  /// [email] 검증할 이메일 주소
  ///
  /// Returns: [ValidationResult] 검증 결과
  ValidationResult validateEmail(String email) {
    final emailPattern = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    return validateField(
      value: email,
      rule: FieldValidationRule(
        fieldName: '이메일',
        required: true,
        pattern: emailPattern,
        patternErrorMessage: '올바른 이메일 형식을 입력해주세요.',
      ),
    );
  }

  /// 전화번호 형식 검증
  ///
  /// [phoneNumber] 검증할 전화번호
  ///
  /// Returns: [ValidationResult] 검증 결과
  ValidationResult validatePhoneNumber(String phoneNumber) {
    final phonePattern = RegExp(
      r'^01[0-9]-?[0-9]{3,4}-?[0-9]{4}$',
    );

    return validateField(
      value: phoneNumber,
      rule: FieldValidationRule(
        fieldName: '전화번호',
        required: true,
        pattern: phonePattern,
        patternErrorMessage: '올바른 전화번호 형식을 입력해주세요. (예: 010-1234-5678)',
      ),
    );
  }

  /// 사용자 ID 형식 검증
  ///
  /// [userId] 검증할 사용자 ID
  ///
  /// Returns: [ValidationResult] 검증 결과
  ValidationResult validateUserId(String userId) {
    final userIdPattern = RegExp(r'^[a-zA-Z0-9_-]{3,50}$');

    return validateField(
      value: userId,
      rule: FieldValidationRule(
        fieldName: '사용자 ID',
        required: true,
        minLength: 3,
        maxLength: 50,
        pattern: userIdPattern,
        patternErrorMessage: '사용자 ID는 영문, 숫자, _, - 만 사용 가능합니다.',
      ),
    );
  }

  /// 투표 상태 검증
  ///
  /// [status] 검증할 상태 값
  ///
  /// Returns: [ValidationResult] 검증 결과
  ValidationResult validateVoteStatus(String status) {
    const validStatuses = ['pending', 'approved', 'rejected', 'cancelled'];

    return validateField(
      value: status,
      rule: FieldValidationRule(
        fieldName: '투표 상태',
        required: true,
        allowedValues: validStatuses,
      ),
    );
  }

  /// 예외 발생 형태의 검증 (기존 코드와의 호환성)
  ///
  /// [title] 신청 제목
  /// [description] 신청 설명
  /// [artistName] 아티스트 이름
  /// [groupName] 그룹 이름
  ///
  /// Throws: [VoteRequestException] 검증 실패 시
  void validateAndThrow({
    required String title,
    required String description,
    String? artistName,
    String? groupName,
  }) {
    final result = validateVoteApplicationData(
      title: title,
      description: description,
      artistName: artistName,
      groupName: groupName,
    );

    if (!result.isValid) {
      throw VoteRequestException(result.firstError ?? '데이터 유효성 검사에 실패했습니다.');
    }
  }
}

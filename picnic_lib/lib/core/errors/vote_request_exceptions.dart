/// 투표 요청 관련 예외 클래스들
class VoteRequestException implements Exception {
  final String message;
  
  const VoteRequestException(this.message);
  
  @override
  String toString() => 'VoteRequestException: $message';
}

/// 중복 투표 요청 예외
class DuplicateVoteRequestException extends VoteRequestException {
  const DuplicateVoteRequestException(String message) : super(message);
  
  @override
  String toString() => 'DuplicateVoteRequestException: $message';
}

/// 투표 요청을 찾을 수 없는 예외
class VoteRequestNotFoundException extends VoteRequestException {
  const VoteRequestNotFoundException(String message) : super(message);
  
  @override
  String toString() => 'VoteRequestNotFoundException: $message';
}

/// 투표 요청 상태 변경 불가 예외
class InvalidVoteRequestStatusException extends VoteRequestException {
  const InvalidVoteRequestStatusException(String message) : super(message);
  
  @override
  String toString() => 'InvalidVoteRequestStatusException: $message';
} 
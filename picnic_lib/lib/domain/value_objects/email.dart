class Email {
  final String value;

  const Email._(this.value);

  /// Create an Email from a string value
  factory Email(String value) {
    if (value.isEmpty) {
      throw EmailValidationException('Email cannot be empty');
    }

    if (!_isValidEmail(value)) {
      throw EmailValidationException('Invalid email format: $value');
    }

    return Email._(value.toLowerCase().trim());
  }

  /// Create an Email without validation (use only for trusted sources)
  factory Email.unsafe(String value) {
    return Email._(value.toLowerCase().trim());
  }

  /// Validate email format using regex
  static bool _isValidEmail(String value) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$',
    );
    return emailRegex.hasMatch(value.trim());
  }

  /// Check if email is valid
  bool get isValid => _isValidEmail(value);

  /// Get the domain part of the email
  String get domain {
    final atIndex = value.indexOf('@');
    if (atIndex == -1) return '';
    return value.substring(atIndex + 1);
  }

  /// Get the local part of the email (before @)
  String get localPart {
    final atIndex = value.indexOf('@');
    if (atIndex == -1) return value;
    return value.substring(0, atIndex);
  }

  /// Check if email domain is common provider
  bool get isCommonProvider {
    final commonDomains = {
      'gmail.com',
      'yahoo.com',
      'hotmail.com',
      'outlook.com',
      'naver.com',
      'daum.net',
      'kakao.com',
      'icloud.com',
    };
    return commonDomains.contains(domain.toLowerCase());
  }

  /// Check if email appears to be disposable/temporary
  bool get isDisposableEmail {
    final disposableDomains = {
      '10minutemail.com',
      'tempmail.org',
      'guerrillamail.com',
      'mailinator.com',
      'throwaway.email',
    };
    return disposableDomains.contains(domain.toLowerCase());
  }

  /// Generate a masked version for display
  String get masked {
    if (value.length <= 6) return value;
    
    final atIndex = value.indexOf('@');
    if (atIndex <= 3) return value;
    
    final localPart = value.substring(0, atIndex);
    final domainPart = value.substring(atIndex);
    
    if (localPart.length <= 3) return value;
    
    final visibleChars = localPart.length ~/ 3;
    final maskedChars = localPart.length - (visibleChars * 2);
    
    return localPart.substring(0, visibleChars) +
           '*' * maskedChars +
           localPart.substring(localPart.length - visibleChars) +
           domainPart;
  }

  /// Create a copy with different case (normalized)
  Email normalize() {
    return Email._(value.toLowerCase().trim());
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Email && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}

class EmailValidationException implements Exception {
  final String message;
  const EmailValidationException(this.message);

  @override
  String toString() => 'EmailValidationException: $message';
}
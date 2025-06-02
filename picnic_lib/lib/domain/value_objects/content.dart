class Content {
  final String value;
  final ContentType type;

  const Content._(this.value, this.type);

  /// Create content with validation
  factory Content.create(String value, ContentType type) {
    final trimmedValue = value.trim();

    if (trimmedValue.isEmpty) {
      throw ContentValidationException('Content cannot be empty');
    }

    if (!_isValidLength(trimmedValue, type)) {
      throw ContentValidationException(
        'Content length invalid for ${type.name}: ${trimmedValue.length} characters'
      );
    }

    if (_containsProhibitedContent(trimmedValue)) {
      throw ContentValidationException('Content contains prohibited words or phrases');
    }

    if (!_isValidFormat(trimmedValue, type)) {
      throw ContentValidationException('Invalid content format for ${type.name}');
    }

    return Content._(trimmedValue, type);
  }

  /// Create content without validation (use for trusted sources)
  factory Content.unsafe(String value, ContentType type) {
    return Content._(value.trim(), type);
  }

  /// Empty content
  static Content empty(ContentType type) => Content._('', type);

  /// Check if content is valid
  bool get isValid {
    return value.isNotEmpty && 
           _isValidLength(value, type) &&
           !_containsProhibitedContent(value) &&
           _isValidFormat(value, type);
  }

  /// Check if content is empty
  bool get isEmpty => value.isEmpty;

  /// Check if content is not empty
  bool get isNotEmpty => value.isNotEmpty;

  /// Get content length
  int get length => value.length;

  /// Get word count
  int get wordCount => value.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).length;

  /// Check if content exceeds recommended length
  bool get exceedsRecommendedLength {
    switch (type) {
      case ContentType.comment:
        return length > 200;
      case ContentType.post:
        return length > 1000;
      case ContentType.title:
        return length > 100;
      case ContentType.description:
        return length > 500;
      case ContentType.message:
        return length > 300;
      case ContentType.nickname:
        return length > 20;
    }
  }

  /// Get content preview (truncated version)
  String get preview {
    const maxLength = 100;
    if (length <= maxLength) return value;
    return '${value.substring(0, maxLength)}...';
  }

  /// Check if content contains mentions (@username)
  bool get containsMentions => value.contains(RegExp(r'@\w+'));

  /// Extract mentions from content
  List<String> get mentions {
    final mentionRegex = RegExp(r'@(\w+)');
    return mentionRegex.allMatches(value)
        .map((match) => match.group(1)!)
        .toList();
  }

  /// Check if content contains hashtags (#tag)
  bool get containsHashtags => value.contains(RegExp(r'#\w+'));

  /// Extract hashtags from content
  List<String> get hashtags {
    final hashtagRegex = RegExp(r'#(\w+)');
    return hashtagRegex.allMatches(value)
        .map((match) => match.group(1)!)
        .toList();
  }

  /// Check if content contains URLs
  bool get containsUrls => value.contains(RegExp(r'https?://[^\s]+'));

  /// Extract URLs from content
  List<String> get urls {
    final urlRegex = RegExp(r'https?://[^\s]+');
    return urlRegex.allMatches(value)
        .map((match) => match.group(0)!)
        .toList();
  }

  /// Sanitize content (remove harmful scripts, normalize whitespace)
  Content sanitize() {
    String sanitized = value
        .replaceAll(RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false), '')
        .replaceAll(RegExp(r'<[^>]*>'), '') // Remove HTML tags
        .replaceAll(RegExp(r'\s+'), ' ') // Normalize whitespace
        .trim();

    return Content._(sanitized, type);
  }

  /// Censor prohibited words
  Content censor() {
    String censored = value;
    for (final word in _prohibitedWords) {
      final regex = RegExp(word, caseSensitive: false);
      censored = censored.replaceAll(regex, '*' * word.length);
    }
    return Content._(censored, type);
  }

  /// Convert to different content type (with validation)
  Content convertTo(ContentType newType) {
    return Content.create(value, newType);
  }

  /// Append content
  Content append(String additional) {
    final newValue = '$value $additional'.trim();
    return Content.create(newValue, type);
  }

  /// Prepend content
  Content prepend(String prefix) {
    final newValue = '$prefix $value'.trim();
    return Content.create(newValue, type);
  }

  /// Static validation methods
  static bool _isValidLength(String value, ContentType type) {
    switch (type) {
      case ContentType.comment:
        return value.length <= 500;
      case ContentType.post:
        return value.length <= 2000;
      case ContentType.title:
        return value.length <= 200;
      case ContentType.description:
        return value.length <= 1000;
      case ContentType.message:
        return value.length <= 500;
      case ContentType.nickname:
        return value.length >= 2 && value.length <= 50;
    }
  }

  static bool _containsProhibitedContent(String value) {
    final lowercaseValue = value.toLowerCase();
    return _prohibitedWords.any((word) => 
        lowercaseValue.contains(word.toLowerCase()));
  }

  static bool _isValidFormat(String value, ContentType type) {
    switch (type) {
      case ContentType.nickname:
        // Alphanumeric and some special characters only
        return RegExp(r'^[a-zA-Z0-9가-힣_.-]+$').hasMatch(value);
      case ContentType.comment:
      case ContentType.post:
      case ContentType.title:
      case ContentType.description:
      case ContentType.message:
        // Most content types allow any printable characters
        return true;
    }
  }

  // Basic prohibited words list (expand as needed)
  static const List<String> _prohibitedWords = [
    'spam',
    'scam',
    'hack',
    'illegal',
    // Add more prohibited words as needed
  ];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Content && other.value == value && other.type == type;
  }

  @override
  int get hashCode => Object.hash(value, type);

  @override
  String toString() => value;
}

enum ContentType {
  comment('comment'),
  post('post'),
  title('title'),
  description('description'),
  message('message'),
  nickname('nickname');

  const ContentType(this.name);
  final String name;

  @override
  String toString() => name;
}

class ContentValidationException implements Exception {
  final String message;
  const ContentValidationException(this.message);

  @override
  String toString() => 'ContentValidationException: $message';
}
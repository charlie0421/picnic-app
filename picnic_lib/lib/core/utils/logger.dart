import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:picnic_lib/core/config/environment.dart';
import 'package:stack_trace/stack_trace.dart';

// 로그 레벨 설정을 위한 전역 변수 (Environment 클래스에서 가져오도록 수정)
// Environment가 초기화되기 전에는 기본값 사용
Level get _defaultLogLevel => kDebugMode ? Level.all : Level.warning;

// 현재 로그 레벨 가져오기 (Environment가 초기화된 후에는 설정값 사용)
Level _getLogLevel() {
  try {
    return Environment.logLevel;
  } catch (e) {
    return _defaultLogLevel;
  }
}

// 느린 리소스 로딩에 대한 로그를 처리하기 위한 Set
final Set<String> _throttledLogKeys = <String>{};

class LongMessagePrinter extends PrettyPrinter {
  static const int _skipFrames = 4;
  static const int _maxStackTraceLines = 20;
  static final _emojiMap = {
    Level.debug: '🔍',
    Level.info: 'ℹ️',
    Level.warning: '⚠️',
    Level.error: '❌',
    Level.off: '📝',
  };

  static final _postgresPatterns = {
    'code': r'code[\":\s]+([^,}\s]+)',
    'details': r'detail[s]?[\":\s]+([^,}\s]+[^,}]*)',
    'hint': r'hint[\":\s]+([^,}\s]+[^,}]*)',
    'table': r'table[\":\s]+([^,}\s]+)',
    'column': r'column[\":\s]+([^,}\s]+)',
    'constraint': r'constraint[\":\s]+([^,}\s]+)',
    'severity': r'severity[\":\s]+([^,}\s]+)',
  };

  LongMessagePrinter()
      : super(
          methodCount: 0,
          errorMethodCount: 8,
          lineLength: 100000,
          colors: true,
          printEmojis: true,
          dateTimeFormat: DateTimeFormat.dateAndTime,
        );

  String _getCallerInfo() {
    final frames = Trace.current().frames;
    if (frames.length > _skipFrames) {
      final frame = frames[_skipFrames];
      return '${frame.uri}:${frame.line}';
    }
    return '';
  }

  String _getClassName() {
    final frames = Trace.current().frames;
    if (frames.length > _skipFrames) {
      final frame = frames[_skipFrames];
      final member = frame.member;
      if (member != null) {
        if (member.contains('.')) {
          return member.split('.')[0];
        }
        return member;
      }
    }
    return '';
  }

  String _getTimestamp() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}.${now.millisecond.toString().padLeft(3, '0')}';
  }

  String _extractErrorDetails(dynamic error) {
    final details = <String>[];
    final errorString = error.toString();

    details.add('Error Details:');
    details.add('  • Type: ${error.runtimeType}');
    details.add('  • Message: $errorString');

    _extractPostgresErrors(errorString, details);
    _extractJsonData(errorString, details);

    return details.join('\n');
  }

  void _extractPostgresErrors(String errorString, List<String> details) {
    for (final entry in _postgresPatterns.entries) {
      try {
        final match =
            RegExp(entry.value, caseSensitive: false).firstMatch(errorString);
        if (match != null) {
          final value =
              match.group(1)?.replaceAll('"', '').replaceAll("'", '').trim();
          if (value != null && value.isNotEmpty) {
            final key = entry.key;
            details
                .add('  • ${key[0].toUpperCase()}${key.substring(1)}: $value');
          }
        }
      } catch (e, s) {
        if (kDebugMode) {
          print('Error extracting ${entry.key}: $e');
          print('Stack trace:');
          print(s);
        }
      }
    }
  }

  void _extractJsonData(String errorString, List<String> details) {
    try {
      final jsonMatch = RegExp(r'\{[^}]+\}').firstMatch(errorString);
      if (jsonMatch?.group(0) != null) {
        final jsonData =
            json.decode(jsonMatch!.group(0)!) as Map<String, dynamic>;
        for (final entry in jsonData.entries) {
          if (!details.any((detail) =>
              detail.toLowerCase().contains(entry.key.toLowerCase()))) {
            details.add(
                '  • ${entry.key[0].toUpperCase()}${entry.key.substring(1)}: ${entry.value}');
          }
        }
      }
    } catch (e, s) {
      if (kDebugMode) {
        print('Stack trace:');
        print(s);
      }
    }
  }

  @override
  List<String> log(LogEvent event) {
    final messages = <String>[];
    final emoji = _emojiMap[event.level] ?? '📝';
    final callerInfo = _getCallerInfo();
    final timestamp = _getTimestamp();
    final className = _getClassName();

    messages.add(_createBorder('┌'));
    messages.add('│ 🕒 $timestamp');
    messages.add('│ 📍 $callerInfo');

    final formattedMessage = _formatMessage(event.message);
    final tag = className.isNotEmpty ? '[$className] ' : '';
    messages.addAll(
        formattedMessage.split('\n').map((line) => '│ $emoji $tag$line'));

    if (event.error != null) {
      messages.add('│');
      messages.add('│ 🚫 Error:');
      messages.addAll(_extractErrorDetails(event.error)
          .split('\n')
          .map((line) => '│   $line'));
    }

    if (event.stackTrace != null) {
      messages.add('│');
      messages.add('│ 📍 StackTrace:');
      messages.addAll(event.stackTrace
          .toString()
          .split('\n')
          .take(_maxStackTraceLines)
          .map((line) => '│   $line'));
    }

    messages.add(_createBorder('└'));
    messages.add('');

    return messages;
  }

  String _createBorder(String edge) => '$edge${'─' * 67}';

  String _formatMessage(dynamic message) {
    if (message is Map || message is Iterable) {
      try {
        const jsonEncoder = JsonEncoder.withIndent('  ');
        return jsonEncoder.convert(message);
      } on Exception catch (e, s) {
        if (kDebugMode) {
          print('Stack trace:');
          print(s);
        }
        return message.toString();
      }
    }
    return message.toString();
  }
}

class LongOutputHandler extends LogOutput {
  @override
  void output(OutputEvent event) {
    final currentLogLevel = _getLogLevel();
    // kDebugMode 체크 대신 로그 레벨을 사용하여 더 세밀하게 제어
    if (currentLogLevel != Level.off) {
      // ignore: avoid_print
      event.lines.forEach(print);
    }
  }
}

// 로거 인스턴스 초기화 함수 (앱 초기화 시 호출)
void initLogger() {
  _logger = Logger(
    printer: LongMessagePrinter(),
    output: LongOutputHandler(),
    level: _getLogLevel(),
  );
}

// 기본 로거 인스턴스
Logger? _logger;

// 싱글톤 로거 인스턴스 가져오기
Logger get logger {
  _logger ??= Logger(
    printer: LongMessagePrinter(),
    output: LongOutputHandler(),
    level: _getLogLevel(),
  );
  return _logger!;
}

extension LoggerJsonExtension on Logger {
  void logJson(String title, dynamic json) {
    try {
      if (json is Map || json is Iterable) {
        const jsonEncoder = JsonEncoder.withIndent('  ');
        final formattedJson = jsonEncoder
            .convert(json)
            .split('\n')
            .map((line) => line)
            .join('\n');
        d('$title:\n$formattedJson');
      } else {
        d('$title: $json');
      }
    } on Exception catch (e, s) {
      if (kDebugMode) {
        print('Stack trace:');
        print(s);
      }
      d('$title: $json');
    }
  }

  // 이미지 로딩과 같은 반복적인 로그를 제한하는 도우미 메서드
  void throttledWarn(String message, String key, {Duration? throttleDuration}) {
    // 기본 제한 시간: 1시간 (throttleDuration 변수는 현재 사용되지 않음)
    // duration 변수 대신 throttleDuration 파라미터를 사용하여 경고 수정
    final now = DateTime.now();

    // 일, 시간 기준으로 제한 (기본 값으로 하루에 한 번)
    final throttleKey = '${key}_${now.day}_${now.hour}';

    // 같은 키로 이미 로그를 출력했는지 확인
    if (!_throttledLogKeys.contains(throttleKey)) {
      _throttledLogKeys.add(throttleKey);
      // 최대 1000개까지만 저장하고 오래된 항목 제거
      if (_throttledLogKeys.length > 1000) {
        _throttledLogKeys.clear();
      }

      // 실제 로그 출력
      w(message);
    }
  }
}

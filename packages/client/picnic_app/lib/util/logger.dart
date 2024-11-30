import 'dart:convert';

import 'package:logger/logger.dart';
import 'package:stack_trace/stack_trace.dart';

class LongMessagePrinter extends PrettyPrinter {
  LongMessagePrinter()
      : super(
            methodCount: 0,
            errorMethodCount: 8,
            lineLength: 10000,
            colors: true,
            printEmojis: true,
            printTime: true);

  String _getCallerInfo() {
    final frames = Trace.current().frames;
    const skipFrames = 4;
    if (frames.length > skipFrames) {
      final frame = frames[skipFrames];
      return '${frame.uri}:${frame.line}';
    }
    return '';
  }

  String _extractErrorDetails(dynamic error) {
    final details = <String>[];
    final errorString = error.toString();

    details.add('Error Details:');
    details.add('  • Type: ${error.runtimeType}');
    details.add('  • Message: $errorString');

    // Postgres 관련 에러 정보 추출
    final patterns = {
      'code': r'code[\":\s]+([^,}\s]+)',
      'details': r'detail[s]?[\":\s]+([^,}\s]+[^,}]*)',
      'hint': r'hint[\":\s]+([^,}\s]+[^,}]*)',
      'table': r'table[\":\s]+([^,}\s]+)',
      'column': r'column[\":\s]+([^,}\s]+)',
      'constraint': r'constraint[\":\s]+([^,}\s]+)',
      'severity': r'severity[\":\s]+([^,}\s]+)',
    };

    patterns.forEach((key, pattern) {
      try {
        final match =
            RegExp(pattern, caseSensitive: false).firstMatch(errorString);
        if (match != null) {
          String? value = match.group(1);
          value = value?.replaceAll('"', '');
          value = value?.replaceAll("'", '');
          if (value != null && value.isNotEmpty) {
            details.add(
                '  • ${key.substring(0, 1).toUpperCase()}${key.substring(1)}: $value');
          }
        }
      } catch (_) {}
    });

    // JSON 형태의 데이터가 있는지 확인
    try {
      final jsonMatch = RegExp(r'\{[^}]+\}').firstMatch(errorString);
      if (jsonMatch != null) {
        final jsonStr = jsonMatch.group(0);
        if (jsonStr != null) {
          final Map<String, dynamic> jsonData = json.decode(jsonStr);
          jsonData.forEach((key, value) {
            if (!details.any(
                (detail) => detail.toLowerCase().contains(key.toLowerCase()))) {
              details.add(
                  '  • ${key.substring(0, 1).toUpperCase()}${key.substring(1)}: $value');
            }
          });
        }
      }
    } catch (_) {}

    return details.join('\n');
  }

  @override
  List<String> log(LogEvent event) {
    String? emoji;
    switch (event.level) {
      case Level.debug:
        emoji = '🔍';
        break;
      case Level.info:
        emoji = 'ℹ️';
        break;
      case Level.warning:
        emoji = '⚠️';
        break;
      case Level.error:
        emoji = '❌';
        break;
      default:
        emoji = '📝';
    }

    final messages = <String>[];
    final callerInfo = _getCallerInfo();

    messages.add(
        '┌───────────────────────────────────────────────────────────────────────');
    messages.add('│ 📍 $callerInfo');

    final formattedMessage = _formatMessage(event.message);
    messages
        .addAll(formattedMessage.split('\n').map((line) => '│ $emoji $line'));

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
          .take(20)
          .map((line) => '│   $line'));
    }

    messages.add(
        '└───────────────────────────────────────────────────────────────────────\n');

    return messages;
  }

  String _formatMessage(dynamic message) {
    if (message is Map || message is Iterable) {
      try {
        const jsonEncoder = JsonEncoder.withIndent('  ');
        return jsonEncoder.convert(message);
      } catch (e) {
        return message.toString();
      }
    }
    return message.toString();
  }
}

class LongOutputHandler extends LogOutput {
  @override
  void output(OutputEvent event) {
    event.lines.forEach(print);
  }
}

final logger = Logger(
  printer: LongMessagePrinter(),
  output: LongOutputHandler(),
  level: Level.all,
);

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
    } catch (e) {
      d('$title: $json');
    }
  }
}

// lib/util/logger.dart
import 'dart:convert';
import 'package:logger/logger.dart';

class LongMessagePrinter extends PrettyPrinter {
  // 매우 긴 라인 길이 설정
  LongMessagePrinter()
      : super(
            methodCount: 0,
            errorMethodCount: 8,
            lineLength: 10000,
            // 매우 큰 값으로 설정
            colors: true,
            printEmojis: true,
            printTime: true);

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
    final time = DateTime.now().toString().split('.').first;

    // 로그 시작 구분선
    messages.add('\n[$time] ${event.level.name} $emoji');
    messages.add('┌──────────────────────────────────────────────────');

    // 메시지 처리
    final formattedMessage = _formatMessage(event.message);
    messages.addAll(formattedMessage.split('\n').map((line) => '│ $line'));

    // 에러 처리
    if (event.error != null) {
      messages.add('│');
      messages.add('│ 🚫 Error:');
      messages.addAll(
          event.error.toString().split('\n').map((line) => '│   $line'));
    }

    // 스택트레이스 처리
    if (event.stackTrace != null) {
      messages.add('│');
      messages.add('│ 📍 StackTrace:');
      messages.addAll(event.stackTrace
          .toString()
          .split('\n')
          .take(20) // 스택트레이스는 20줄로 제한
          .map((line) => '│   $line'));
    }

    // 로그 종료 구분선
    messages.add('└──────────────────────────────────────────────────\n');

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

// 긴 출력을 위한 커스텀 출력 핸들러
class LongOutputHandler extends LogOutput {
  @override
  void output(OutputEvent event) {
    event.lines.forEach(print); // 각 라인을 그대로 출력
  }
}

final logger = Logger(
  printer: LongMessagePrinter(),
  output: LongOutputHandler(),
  level: Level.all,
);

// JSON 로깅을 위한 확장 메서드
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

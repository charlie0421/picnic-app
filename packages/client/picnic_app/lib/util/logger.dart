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
    // Skip frames related to logging infrastructure
    const skipFrames = 4;
    if (frames.length > skipFrames) {
      final frame = frames[skipFrames];
      return '${frame.uri}:${frame.line}';
    }
    return '';
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
      messages.addAll(
          event.error.toString().split('\n').map((line) => '│   $line'));
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

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:stack_trace/stack_trace.dart';

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

    messages.add(_createBorder('┌'));
    messages.add('│ 🕒 $timestamp');
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
    if (kDebugMode) {
      event.lines.forEach(print);
    }
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
    } on Exception catch (e, s) {
      if (kDebugMode) {
        print('Stack trace:');
        print(s);
      }
      d('$title: $json');
    }
  }
}

import 'package:logger/logger.dart';

final Logger logger = Logger(
  printer: PrettyPrinter(),
  output: ConsoleOutput(),
  level: Level.all,
);

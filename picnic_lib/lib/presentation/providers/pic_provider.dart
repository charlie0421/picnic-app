import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

class IntNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void set(int value) => state = value;
}

class NullableFileNotifier extends Notifier<File?> {
  @override
  File? build() => null;

  void set(File? value) => state = value;
}

final parmePageIndexProvider = NotifierProvider<IntNotifier, int>(
  IntNotifier.new,
);

final picSelectedIndexProvider = NotifierProvider<IntNotifier, int>(
  IntNotifier.new,
);

final userImageProvider = NotifierProvider<NullableFileNotifier, File?>(
  NullableFileNotifier.new,
);

final convertedImageProvider = NotifierProvider<NullableFileNotifier, File?>(
  NullableFileNotifier.new,
);

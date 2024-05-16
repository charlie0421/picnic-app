import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

final parmePageIndexProvider = StateProvider<int>((ref) => 0);

final prameSelectedIndexProvider = StateProvider<int>((ref) => 0);
final userImageProvider = StateProvider<File?>((ref) => null);
final convertedImageProvider = StateProvider<File?>((ref) => null);
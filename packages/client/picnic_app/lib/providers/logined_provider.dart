import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_extensions/supabase_extensions.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'logined_provider.g.dart';

@riverpod
class Logined extends _$Logined {
  @override
  bool build() => Supabase.instance.client.isLogged;

  void setLogined(bool value) {
    state = value;
  }
}

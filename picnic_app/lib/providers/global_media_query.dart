import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '../generated/providers/global_media_query.g.dart';

@Riverpod(keepAlive: true)
class GlobalMediaQuery extends _$GlobalMediaQuery {
  @override
  MediaQueryData build() {
    return const MediaQueryData();
  }

  void updateMediaQueryData(MediaQueryData data) {
    state = data;
  }
}

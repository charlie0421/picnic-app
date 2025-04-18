// l10n.dart 파일 (기존 파일 재활용)
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:crowdin_sdk/crowdin_sdk.dart';

class S {
  static S? _current;

  static S get current {
    assert(_current != null, 'S not initialized');
    return _current!;
  }

  static S of(BuildContext context) {
    return current;
  }

  static Future<S> load(Locale locale) {
    S instance = S();
    _current = instance;
    return SynchronousFuture<S>(instance);
  }

  // 동적으로 모든 getter 처리
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.isGetter) {
      final key = invocation.memberName.toString().split('"')[1];
      final locale = Intl.defaultLocale ?? 'ko';
      return Crowdin.getText(locale, key) ?? key;
    }
    return super.noSuchMethod(invocation);
  }
}

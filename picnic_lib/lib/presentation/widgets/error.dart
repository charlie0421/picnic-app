import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/l10n/app_localizations.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

Widget buildErrorView(final BuildContext context,
    {void Function()? retryFunction,
    required Object? error,
    required StackTrace? stackTrace}) {
  logger.e(error, stackTrace: stackTrace);
  Sentry.captureException(
    error,
    stackTrace: stackTrace,
  );

  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        const Icon(Icons.error_outline, color: Colors.red, size: 60),
        Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
                // 예외 원문(PostgrestException(...) 등)은 사용자 안내가 아니라
                // 디버깅 정보다 - 릴리스에서는 로그/Sentry로만 남기고 화면에는
                // 안내 문구만 보여 준다 (iOS 홈 배너 노출 사례, 2026-07-28).
                kDebugMode
                    ? '${AppLocalizations.of(context).message_error_occurred}\n ${error.toString()}'
                    : AppLocalizations.of(context).message_error_occurred,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge)),
        if (retryFunction != null)
          SizedBox(
            width: 200,
            child: ElevatedButton(
              onPressed: retryFunction,
              child: Text(
                AppLocalizations.of(context).label_retry,
              ),
            ),
          )
      ],
    ),
  );
}

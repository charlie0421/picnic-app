import 'package:flutter/material.dart';
import 'package:picnic_lib/generated/l10n.dart';
import 'package:picnic_lib/core/utils/logger.dart';
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
                '${S.of(context).message_error_occurred}\n ${error.toString()}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge)),
        if (retryFunction != null)
          SizedBox(
            width: 200,
            child: ElevatedButton(
              onPressed: retryFunction,
              child: Text(S.of(context).label_retry),
            ),
          ),
      ],
    ),
  );
}

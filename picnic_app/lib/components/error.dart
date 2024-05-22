import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../constants.dart';

Widget ErrorView(final BuildContext context,
    {void Function()? retryFunction,
    required Object? error,
    required StackTrace? stackTrace}) {
  logger.e('error: $error');
  logger.e('stackTrace: $stackTrace');
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        const Icon(Icons.error_outline, color: Colors.red, size: 60),
        Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
                '${Intl.message('message_error_occurred')}\n ${error.toString()}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge)),
        if (retryFunction != null)
          SizedBox(
            width: 200,
            child: ElevatedButton(
              onPressed: retryFunction,
              child: Text('${Intl.message('message_retry')}'),
            ),
          ),
      ],
    ),
  );
}

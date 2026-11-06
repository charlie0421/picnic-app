// Host-side driver for scripts/qa/run_full_app_retry_android.py. The runner
// copies it to test_driver/full_app_retry_driver.dart in the generated QA app
// and runs it with `flutter drive --use-application-binary=<inspected APK>`.
//
// integrationDriver exits 0 only when every test in the app passed. The
// app's IntegrationTestWidgetsFlutterBinding.reportData (checkpoints, facts
// and summary) is written to qa-driver/response.json, also on failure. A
// connection error writes no file, so the runner never mistakes it for a
// pass.
import 'dart:convert';
import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver(
      timeout: const Duration(minutes: 12),
      writeResponseOnFailure: true,
      responseDataCallback: (data) async {
        final file = File('qa-driver/response.json');
        await file.parent.create(recursive: true);
        await file.writeAsString(jsonEncode(data));
      },
    );

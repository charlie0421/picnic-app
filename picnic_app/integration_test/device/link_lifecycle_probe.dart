// Build this entry point, then open the registered scheme with simctl openurl.
// It records delivery without routing into login, purchases, or backend services.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final links = AppLinks();
  final events = <String>[];
  final display = ValueNotifier<String>('Waiting for a regression link');
  final output = File('${Directory.systemTemp.path}/link-lifecycle-probe.json');
  String? initialLink;
  Future<void> writes = Future<void>.value();

  void recordSnapshot() {
    final snapshot = jsonEncode({'initialLink': initialLink, 'events': events});
    writes = writes.then((_) => output.writeAsString(snapshot, flush: true));
    display.value = snapshot;
  }

  links.uriLinkStream.listen((uri) {
    if (uri.host != 'foldable-regression') return;
    events.add(uri.toString());
    recordSnapshot();
  });
  initialLink = (await links.getInitialLink())?.toString();
  recordSnapshot();

  runApp(MaterialApp(
    home: Scaffold(
      appBar: AppBar(title: const Text('Link lifecycle regression probe')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ValueListenableBuilder<String>(
            valueListenable: display,
            builder: (context, value, child) => Text(value)),
      ),
    ),
  ));
}

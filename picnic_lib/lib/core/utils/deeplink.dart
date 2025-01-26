import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:picnic_lib/core/config/environment.dart';
import 'package:picnic_lib/core/utils/logger.dart';

Future<String> createBranchLink(String? title, String? longUrl) async {
  final url = Uri.parse('https://api2.branch.io/v1/url');
  final branchKey = Environment.branchKey;

  final response = await http.post(url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'branch_key': branchKey,
        'data': {'title': title, '\$desktop_url': longUrl}
      }));

  if (response.statusCode == 200) {
    return jsonDecode(response.body)['url'];
  } else {
    throw Exception('Failed to create Branch link');
  }
}

Future<String> getLongUrl(String shortUrl) async {
  final branchKey = Environment.branchKey;
  final response = await http.get(Uri.parse(
      'https://api2.branch.io/v1/url?url=${Uri.encodeComponent(shortUrl)}&branch_key=$branchKey'));

  if (response.statusCode == 200) {
    logger.i(response.body);
    return jsonDecode(response.body)['long_url'];
  } else {
    throw Exception('Failed to get long URL');
  }
}

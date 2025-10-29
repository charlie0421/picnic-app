import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class YouTubeMissionService {
  final String supabaseEdgeBaseUrl; // e.g., https://<project-ref>.functions.supabase.co
  final Map<String, String> defaultHeaders;

  YouTubeMissionService({
    required this.supabaseEdgeBaseUrl,
    this.defaultHeaders = const {},
  });

  Future<({String clickId, String videoId, String youtubeUrl})> createClick({
    required String campaignId,
    String? userId,
  }) async {
    final uri = Uri.parse('$supabaseEdgeBaseUrl/ads-create-click');
    final res = await http.post(
      uri,
      headers: {
        'content-type': 'application/json',
        ...defaultHeaders,
      },
      body: jsonEncode({
        'campaignId': campaignId,
        'userId': userId,
      }),
    );
    if (res.statusCode != 200) {
      throw Exception('create-click failed: ${res.body}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return (
      clickId: data['clickId'] as String,
      videoId: data['videoId'] as String,
      youtubeUrl: data['youtubeUrl'] as String,
    );
  }

  Future<({String path, String signedUrl})> createSignedUploadUrl({
    required String path,
  }) async {
    final uri = Uri.parse('$supabaseEdgeBaseUrl/ads-sign-url');
    final res = await http.post(
      uri,
      headers: {
        'content-type': 'application/json',
        ...defaultHeaders,
      },
      body: jsonEncode({
        'path': path,
        'type': 'upload',
      }),
    );
    if (res.statusCode != 200) {
      throw Exception('sign-url(upload) failed: ${res.body}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return (
      path: path,
      signedUrl: data['signedUrl'] as String,
    );
  }

  Future<void> uploadWithSignedUrl({
    required String signedUrl,
    required File file,
    String contentType = 'image/jpeg',
  }) async {
    final bytes = await file.readAsBytes();
    final res = await http.put(
      Uri.parse(signedUrl),
      headers: {
        'content-type': contentType,
      },
      body: bytes,
    );
    if (res.statusCode >= 400) {
      throw Exception('signed upload failed: ${res.statusCode} ${res.body}');
    }
  }

  Future<String> createSignedDownloadUrl({
    required String path,
    int expiresInSec = 600,
  }) async {
    final uri = Uri.parse('$supabaseEdgeBaseUrl/ads-sign-url');
    final res = await http.post(
      uri,
      headers: {
        'content-type': 'application/json',
        ...defaultHeaders,
      },
      body: jsonEncode({
        'path': path,
        'type': 'download',
        'expiresIn': expiresInSec,
      }),
    );
    if (res.statusCode != 200) {
      throw Exception('sign-url(download) failed: ${res.body}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return data['signedUrl'] as String;
  }

  Future<({String decision, Map<String, dynamic> metrics})> validateProof({
    required String clickId,
    required String proofUrl,
  }) async {
    final uri = Uri.parse('$supabaseEdgeBaseUrl/ads-validate-proof');
    final res = await http.post(
      uri,
      headers: {
        'content-type': 'application/json',
        ...defaultHeaders,
      },
      body: jsonEncode({
        'clickId': clickId,
        'proofUrl': proofUrl,
      }),
    );
    if (res.statusCode != 200) {
      throw Exception('validate-proof failed: ${res.body}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return (
      decision: data['decision'] as String,
      metrics: (data['metrics'] as Map<String, dynamic>?) ?? <String, dynamic>{},
    );
  }
}



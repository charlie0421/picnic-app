import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:picnic_lib/core/config/environment.dart';
import 'package:picnic_lib/core/utils/logger.dart';
import 'package:picnic_lib/presentation/common/picnic_cached_network_image.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// 네트워크 및 이미지 로딩 디버깅 페이지
class NetworkDebugPage extends ConsumerStatefulWidget {
  const NetworkDebugPage({super.key});

  @override
  ConsumerState<NetworkDebugPage> createState() => _NetworkDebugPageState();
}

class _NetworkDebugPageState extends ConsumerState<NetworkDebugPage> {
  String _debugOutput = '';
  bool _isTestingNetwork = false;
  bool _isTestingCdn = false;
  bool _isTestingSupabase = false;

  // 테스트할 URL들
  final List<String> _testUrls = [
    'https://cdn.picnic.fan/picnic',
    'https://api.picnic.fan',
    'https://httpbin.org/image/jpeg',
    'https://dummyimage.com/300x300/FF6B6B/FFFFFF&text=Test',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('네트워크 & 이미지 디버깅'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 환경 정보 표시
            _buildEnvironmentInfo(),
            const SizedBox(height: 16),

            // 테스트 버튼들
            _buildTestButtons(),
            const SizedBox(height: 16),

            // 이미지 테스트 섹션
            _buildImageTestSection(),
            const SizedBox(height: 16),

            // 디버그 출력
            _buildDebugOutput(),
          ],
        ),
      ),
    );
  }

  Widget _buildEnvironmentInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '현재 환경 정보',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('CDN URL: ${Environment.cdnUrl}'),
            Text('Supabase URL: ${Environment.supabaseUrl}'),
            Text('Storage URL: ${Environment.supabaseStorageUrl}'),
          ],
        ),
      ),
    );
  }

  Widget _buildTestButtons() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '네트워크 테스트',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed:
                        _isTestingNetwork ? null : _testNetworkConnectivity,
                    child: _isTestingNetwork
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('네트워크 연결 테스트'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isTestingCdn ? null : _testCdnAccess,
                    child: _isTestingCdn
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('CDN 접근 테스트'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isTestingSupabase ? null : _testSupabaseAccess,
                child: _isTestingSupabase
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Supabase 접근 테스트'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageTestSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '이미지 로딩 테스트',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('다양한 이미지 소스로 로딩 테스트:'),
            const SizedBox(height: 16),

            // 일반 Image.network 테스트
            _buildImageTestRow(
              'Image.network (httpbin)',
              Image.network(
                'https://httpbin.org/image/jpeg',
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 80,
                    height: 80,
                    color: Colors.red[100],
                    child: const Icon(Icons.error),
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[200],
                    child: const CircularProgressIndicator(),
                  );
                },
              ),
            ),

            // CachedNetworkImage 테스트
            _buildImageTestRow(
              'CachedNetworkImage',
              CachedNetworkImage(
                imageUrl:
                    'https://dummyimage.com/300x300/4ECDC4/FFFFFF&text=Cached',
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  width: 80,
                  height: 80,
                  color: Colors.grey[200],
                  child: const CircularProgressIndicator(),
                ),
                errorWidget: (context, url, error) => Container(
                  width: 80,
                  height: 80,
                  color: Colors.red[100],
                  child: const Icon(Icons.error),
                ),
              ),
            ),

            // PicnicCachedNetworkImage 테스트
            _buildImageTestRow(
              'PicnicCachedNetworkImage',
              PicnicCachedNetworkImage(
                imageUrl:
                    'https://dummyimage.com/300x300/96CEB4/FFFFFF&text=Picnic',
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageTestRow(String title, Widget imageWidget) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(4),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: imageWidget,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebugOutput() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '디버그 출력',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _debugOutput = '';
                    });
                  },
                  child: const Text('지우기'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              height: 300,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SingleChildScrollView(
                child: Text(
                  _debugOutput.isEmpty
                      ? '테스트 실행 후 결과가 여기에 표시됩니다.'
                      : _debugOutput,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addToDebugOutput(String message) {
    setState(() {
      final timestamp = DateTime.now().toString().substring(11, 19);
      _debugOutput += '[$timestamp] $message\n';
    });
    logger.i(message);
  }

  Future<void> _testNetworkConnectivity() async {
    setState(() {
      _isTestingNetwork = true;
    });

    _addToDebugOutput('=== 네트워크 연결 테스트 시작 ===');

    try {
      // 기본 인터넷 연결 테스트
      _addToDebugOutput('Google DNS 연결 테스트...');
      final response = await http
          .get(
            Uri.parse('https://dns.google/resolve?name=google.com&type=A'),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        _addToDebugOutput('✅ Google DNS 연결 성공 (${response.statusCode})');
      } else {
        _addToDebugOutput('❌ Google DNS 연결 실패 (${response.statusCode})');
      }

      // 각 테스트 URL 확인
      for (final url in _testUrls) {
        _addToDebugOutput('테스트 중: $url');
        try {
          final testResponse = await http
              .head(Uri.parse(url))
              .timeout(const Duration(seconds: 10));
          _addToDebugOutput('  ✅ 응답: ${testResponse.statusCode}');
        } catch (e) {
          _addToDebugOutput('  ❌ 오류: $e');
        }
      }
    } catch (e) {
      _addToDebugOutput('❌ 네트워크 테스트 실패: $e');
    } finally {
      setState(() {
        _isTestingNetwork = false;
      });
      _addToDebugOutput('=== 네트워크 연결 테스트 완료 ===\n');
    }
  }

  Future<void> _testCdnAccess() async {
    setState(() {
      _isTestingCdn = true;
    });

    _addToDebugOutput('=== CDN 접근 테스트 시작 ===');

    try {
      final cdnUrl = Environment.cdnUrl;
      _addToDebugOutput('CDN URL: $cdnUrl');

      // CDN 루트 접근
      final response = await http
          .head(Uri.parse(cdnUrl))
          .timeout(const Duration(seconds: 10));
      _addToDebugOutput('CDN 루트 응답: ${response.statusCode}');

      // 일반적인 이미지 경로 테스트
      final testImagePaths = [
        '$cdnUrl/test.jpg',
        '$cdnUrl/avatars/test.jpg',
        '$cdnUrl/uploads/test.jpg',
      ];

      for (final path in testImagePaths) {
        try {
          final testResponse = await http
              .head(Uri.parse(path))
              .timeout(const Duration(seconds: 5));
          _addToDebugOutput('$path: ${testResponse.statusCode}');
        } catch (e) {
          _addToDebugOutput('$path: 오류 - $e');
        }
      }
    } catch (e) {
      _addToDebugOutput('❌ CDN 접근 테스트 실패: $e');
    } finally {
      setState(() {
        _isTestingCdn = false;
      });
      _addToDebugOutput('=== CDN 접근 테스트 완료 ===\n');
    }
  }

  Future<void> _testSupabaseAccess() async {
    setState(() {
      _isTestingSupabase = true;
    });

    _addToDebugOutput('=== Supabase 접근 테스트 시작 ===');

    try {
      final supabaseUrl = Environment.supabaseUrl;
      final storageUrl = Environment.supabaseStorageUrl;

      _addToDebugOutput('Supabase URL: $supabaseUrl');
      _addToDebugOutput('Storage URL: $storageUrl');

      // Supabase API 접근
      try {
        final response = await http
            .head(Uri.parse('$supabaseUrl/rest/v1/'))
            .timeout(const Duration(seconds: 10));
        _addToDebugOutput('Supabase API 응답: ${response.statusCode}');
      } catch (e) {
        _addToDebugOutput('Supabase API 오류: $e');
      }

      // Storage API 접근
      try {
        final storageResponse = await http
            .head(Uri.parse('$storageUrl/storage/v1/'))
            .timeout(const Duration(seconds: 10));
        _addToDebugOutput('Storage API 응답: ${storageResponse.statusCode}');
      } catch (e) {
        _addToDebugOutput('Storage API 오류: $e');
      }
    } catch (e) {
      _addToDebugOutput('❌ Supabase 접근 테스트 실패: $e');
    } finally {
      setState(() {
        _isTestingSupabase = false;
      });
      _addToDebugOutput('=== Supabase 접근 테스트 완료 ===\n');
    }
  }
}

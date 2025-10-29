import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/youtube_mission_service.dart';

class YouTubeMissionGuidePage extends StatefulWidget {
  final YouTubeMissionService service;
  final String campaignId;
  final String? userId;

  const YouTubeMissionGuidePage({
    super.key,
    required this.service,
    required this.campaignId,
    this.userId,
  });

  @override
  State<YouTubeMissionGuidePage> createState() => _YouTubeMissionGuidePageState();
}

class _YouTubeMissionGuidePageState extends State<YouTubeMissionGuidePage> {
  String? _clickId;
  String? _videoId;
  String? _status;
  bool _loading = false;

  Future<void> _goToYouTube() async {
    setState(() => _loading = true);
    try {
      final r = await widget.service.createClick(
        campaignId: widget.campaignId,
        userId: widget.userId,
      );
      _clickId = r.clickId;
      _videoId = r.videoId;
      setState(() {});
      // ignore: deprecated_member_use
      // Launch URL은 실제 앱 런처 사용(예: url_launcher 패키지)
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _pickAndUpload() async {
    if (_clickId == null) {
      setState(() => _status = '먼저 YouTube로 이동을 눌러 주세요');
      return;
    }
    final picker = ImagePicker();
    final x = await picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (x == null) return;
    final file = File(x.path);

    setState(() => _loading = true);
    try {
      final ext = x.name.split('.').last.toLowerCase();
      final path = 'proofs/${DateTime.now().millisecondsSinceEpoch}_${_clickId}.$ext';
      final up = await widget.service.createSignedUploadUrl(path: path);
      await widget.service.uploadWithSignedUrl(signedUrl: up.signedUrl, file: file);
      final downloadUrl = await widget.service.createSignedDownloadUrl(path: path);

      final result = await widget.service.validateProof(clickId: _clickId!, proofUrl: downloadUrl);
      setState(() => _status = '결과: ${result.decision} (${result.metrics})');
    } catch (e) {
      setState(() => _status = '오류: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('YouTube 미션')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('가이드'),
            const SizedBox(height: 8),
            const Text('1) 영상 재생 중 화면 한 번 탭 → 시간/진행바 보이게 캡처\n2) 30초 이상 경과가 보이도록 촬영\n3) 갤러리에서 그 1장을 업로드'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loading ? null : _goToYouTube,
              child: const Text('YouTube로 이동(더보기)'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loading ? null : _pickAndUpload,
              child: const Text('스크린샷 업로드'),
            ),
            const SizedBox(height: 16),
            if (_videoId != null) Text('videoId: $_videoId'),
            if (_status != null) Text(_status!),
            if (_loading) const Padding(
              padding: EdgeInsets.only(top: 12),
              child: LinearProgressIndicator(),
            ),
          ],
        ),
      ),
    );
  }
}



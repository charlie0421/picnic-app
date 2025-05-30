import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:picnic_lib/core/services/asset_loading_service.dart';

/// 에셋 로딩 모니터 위젯
///
/// 개발 모드에서 에셋 로딩 상태와 성능을 실시간으로 모니터링합니다.
/// 릴리즈 모드에서는 표시되지 않습니다.
class AssetLoadingMonitor extends StatefulWidget {
  final Widget child;
  final bool showOverlay;
  final Duration updateInterval;

  const AssetLoadingMonitor({
    super.key,
    required this.child,
    this.showOverlay = true,
    this.updateInterval = const Duration(seconds: 1),
  });

  @override
  State<AssetLoadingMonitor> createState() => _AssetLoadingMonitorState();
}

class _AssetLoadingMonitorState extends State<AssetLoadingMonitor> {
  Timer? _updateTimer;
  Map<String, dynamic> _stats = {};
  bool _isExpanded = false;
  final AssetLoadingService _assetService = AssetLoadingService();

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      _startMonitoring();
    }
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  void _startMonitoring() {
    _updateStats();
    _updateTimer = Timer.periodic(widget.updateInterval, (_) {
      if (mounted) {
        _updateStats();
      }
    });
  }

  void _updateStats() {
    setState(() {
      _stats = _assetService.getLoadingStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode || !widget.showOverlay) {
      return widget.child;
    }

    return Stack(
      children: [
        widget.child,
        Positioned(
          top: MediaQuery.of(context).padding.top + 10,
          right: 10,
          child: _buildMonitorOverlay(),
        ),
      ],
    );
  }

  Widget _buildMonitorOverlay() {
    return Material(
      color: Colors.black87,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: _isExpanded ? 300 : 120,
          maxHeight: _isExpanded ? 400 : 60,
        ),
        padding: const EdgeInsets.all(8),
        child: _isExpanded ? _buildExpandedView() : _buildCollapsedView(),
      ),
    );
  }

  Widget _buildCollapsedView() {
    final combined = _stats['combined'] as Map<String, dynamic>? ?? {};
    final totalItems = combined['totalItems'] as int? ?? 0;
    final loadedItems = combined['totalLoadedItems'] as int? ?? 0;
    final progress = totalItems > 0 ? loadedItems / totalItems : 0.0;

    return GestureDetector(
      onTap: () => setState(() => _isExpanded = true),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.assessment,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Assets',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[600],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress >= 1.0 ? Colors.green : Colors.blue,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$loadedItems/$totalItems',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Asset Loading Monitor',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            GestureDetector(
              onTap: () => setState(() => _isExpanded = false),
              child: Icon(
                Icons.close,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAssetSection(),
                const SizedBox(height: 8),
                _buildFontSection(),
                const SizedBox(height: 8),
                _buildCombinedSection(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAssetSection() {
    final assets = _stats['assets'] as Map<String, dynamic>? ?? {};

    return _buildSection(
      title: 'Assets',
      icon: Icons.image,
      data: {
        'Total': assets['totalAssets'] ?? 0,
        'Loaded': assets['loadedAssets'] ?? 0,
        'Loading': assets['loadingAssets'] ?? 0,
        'Failed': assets['failedAssets'] ?? 0,
        'Size': _formatBytes(assets['totalSizeBytes'] as int? ?? 0),
        'Avg Time': '${assets['averageLoadTimeMs'] ?? 0}ms',
      },
    );
  }

  Widget _buildFontSection() {
    final fonts = _stats['fonts'] as Map<String, dynamic>? ?? {};

    return _buildSection(
      title: 'Fonts',
      icon: Icons.font_download,
      data: {
        'Total': fonts['totalFonts'] ?? 0,
        'Loaded': fonts['loadedFonts'] ?? 0,
        'Loading': fonts['loadingFonts'] ?? 0,
        'Failed': fonts['failedFonts'] ?? 0,
        'Size': _formatBytes(fonts['totalSizeBytes'] as int? ?? 0),
        'Language': fonts['currentLanguage'] ?? 'N/A',
      },
    );
  }

  Widget _buildCombinedSection() {
    final combined = _stats['combined'] as Map<String, dynamic>? ?? {};

    return _buildSection(
      title: 'Combined',
      icon: Icons.analytics,
      data: {
        'Total Items': combined['totalItems'] ?? 0,
        'Loaded Items': combined['totalLoadedItems'] ?? 0,
        'Total Size': _formatBytes(combined['totalSizeBytes'] as int? ?? 0),
        'Progress': _formatProgress(combined),
      },
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Map<String, dynamic> data,
  }) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white70, size: 12),
              const SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ...data.entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.key,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 8,
                      ),
                    ),
                    Text(
                      entry.value.toString(),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  String _formatProgress(Map<String, dynamic> combined) {
    final total = combined['totalItems'] as int? ?? 0;
    final loaded = combined['totalLoadedItems'] as int? ?? 0;

    if (total == 0) return '0%';

    final percentage = (loaded / total * 100).toStringAsFixed(1);
    return '$percentage%';
  }
}

/// 에셋 로딩 성능 리포트 위젯
///
/// 에셋 로딩 완료 후 성능 분석 결과를 표시합니다.
class AssetLoadingReport extends StatelessWidget {
  final VoidCallback? onClose;

  const AssetLoadingReport({
    super.key,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();

    return Material(
      color: Colors.black87,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Asset Loading Performance Report',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (onClose != null)
                  IconButton(
                    onPressed: onClose,
                    icon: Icon(Icons.close, color: Colors.white),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<Map<String, dynamic>>(
                future: _generateReport(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error generating report: ${snapshot.error}',
                        style: TextStyle(color: Colors.red),
                      ),
                    );
                  }

                  final report = snapshot.data ?? {};
                  return _buildReportContent(report);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> _generateReport() async {
    final assetService = AssetLoadingService();
    final stats = assetService.getLoadingStats();

    // 추가 분석 수행
    final analysis = _analyzePerformance(stats);

    return {
      'stats': stats,
      'analysis': analysis,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  Map<String, dynamic> _analyzePerformance(Map<String, dynamic> stats) {
    final combined = stats['combined'] as Map<String, dynamic>? ?? {};
    final assets = stats['assets'] as Map<String, dynamic>? ?? {};
    final fonts = stats['fonts'] as Map<String, dynamic>? ?? {};

    final totalSize = combined['totalSizeBytes'] as int? ?? 0;
    final assetLoadTime = assets['totalLoadTimeMs'] as int? ?? 0;
    final fontLoadTime = fonts['totalLoadTimeMs'] as int? ?? 0;

    return {
      'totalLoadTime': assetLoadTime + fontLoadTime,
      'averageItemSize': totalSize > 0 && combined['totalItems'] != null
          ? totalSize / (combined['totalItems'] as int)
          : 0,
      'recommendations': _generateRecommendations(stats),
      'performance': _getPerformanceRating(assetLoadTime + fontLoadTime),
    };
  }

  List<String> _generateRecommendations(Map<String, dynamic> stats) {
    final recommendations = <String>[];
    final combined = stats['combined'] as Map<String, dynamic>? ?? {};
    final totalSize = combined['totalSizeBytes'] as int? ?? 0;

    if (totalSize > 10 * 1024 * 1024) {
      // 10MB
      recommendations.add(
          'Consider reducing asset sizes or implementing more aggressive lazy loading');
    }

    final assets = stats['assets'] as Map<String, dynamic>? ?? {};
    final failedAssets = assets['failedAssets'] as int? ?? 0;
    if (failedAssets > 0) {
      recommendations.add(
          '$failedAssets assets failed to load - check asset paths and availability');
    }

    final avgLoadTime = assets['averageLoadTimeMs'] as int? ?? 0;
    if (avgLoadTime > 500) {
      recommendations.add(
          'Average asset load time is high (${avgLoadTime}ms) - consider optimizing asset sizes');
    }

    if (recommendations.isEmpty) {
      recommendations.add('Asset loading performance looks good!');
    }

    return recommendations;
  }

  String _getPerformanceRating(int totalLoadTime) {
    if (totalLoadTime < 1000) return 'Excellent';
    if (totalLoadTime < 2000) return 'Good';
    if (totalLoadTime < 3000) return 'Fair';
    return 'Poor';
  }

  Widget _buildReportContent(Map<String, dynamic> report) {
    final stats = report['stats'] as Map<String, dynamic>? ?? {};
    final analysis = report['analysis'] as Map<String, dynamic>? ?? {};

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCard(stats, analysis),
          const SizedBox(height: 16),
          _buildRecommendationsCard(analysis),
          const SizedBox(height: 16),
          _buildDetailedStatsCard(stats),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
      Map<String, dynamic> stats, Map<String, dynamic> analysis) {
    final combined = stats['combined'] as Map<String, dynamic>? ?? {};
    final totalLoadTime = analysis['totalLoadTime'] as int? ?? 0;
    final performance = analysis['performance'] as String? ?? 'Unknown';

    return Card(
      color: Colors.grey[800],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Summary',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Total Items: ${combined['totalItems'] ?? 0}',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            Text(
              'Loaded: ${combined['totalLoadedItems'] ?? 0}',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            Text(
              'Total Size: ${_formatBytes(combined['totalSizeBytes'] as int? ?? 0)}',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            Text(
              'Load Time: ${totalLoadTime}ms',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            Text(
              'Performance: $performance',
              style: TextStyle(
                color: _getPerformanceColor(performance),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationsCard(Map<String, dynamic> analysis) {
    final recommendations = analysis['recommendations'] as List<String>? ?? [];

    return Card(
      color: Colors.grey[800],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recommendations',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...recommendations.map((rec) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• ', style: TextStyle(color: Colors.white70)),
                      Expanded(
                        child: Text(
                          rec,
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedStatsCard(Map<String, dynamic> stats) {
    return Card(
      color: Colors.grey[800],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detailed Statistics',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              stats.toString(),
              style: TextStyle(
                color: Colors.white70,
                fontSize: 10,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPerformanceColor(String performance) {
    switch (performance.toLowerCase()) {
      case 'excellent':
        return Colors.green;
      case 'good':
        return Colors.lightGreen;
      case 'fair':
        return Colors.orange;
      case 'poor':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }
}

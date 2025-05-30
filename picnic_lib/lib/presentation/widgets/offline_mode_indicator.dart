import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:picnic_lib/core/services/network_state_manager.dart';
import 'package:picnic_lib/core/services/enhanced_network_service.dart';

/// 오프라인 모드 상태를 표시하는 인디케이터 위젯
class OfflineModeIndicator extends StatefulWidget {
  final bool showWhenOnline;
  final EdgeInsets? padding;
  final Color? backgroundColor;
  final Color? textColor;
  final VoidCallback? onTap;

  const OfflineModeIndicator({
    super.key,
    this.showWhenOnline = false,
    this.padding,
    this.backgroundColor,
    this.textColor,
    this.onTap,
  });

  @override
  State<OfflineModeIndicator> createState() => _OfflineModeIndicatorState();
}

class _OfflineModeIndicatorState extends State<OfflineModeIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  DetailedNetworkState? _currentState;
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _listenToNetworkChanges();
  }

  void _listenToNetworkChanges() {
    NetworkStateManager.instance.detailedNetworkStream.listen((state) {
      if (mounted) {
        setState(() {
          _currentState = state;
          _updateVisibility(state);
        });
      }
    });
  }

  void _updateVisibility(DetailedNetworkState state) {
    final shouldShow = state.isEffectivelyOffline || 
                      (widget.showWhenOnline && state.isEffectivelyOnline);

    if (shouldShow && !_isVisible) {
      _isVisible = true;
      _animationController.forward();
    } else if (!shouldShow && _isVisible) {
      _isVisible = false;
      _animationController.reverse();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentState == null) {
      return const SizedBox.shrink();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: GestureDetector(
        onTap: widget.onTap ?? () => _showNetworkDetails(context),
        child: Container(
          width: double.infinity,
          padding: widget.padding ?? const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 8.0,
          ),
          decoration: BoxDecoration(
            color: widget.backgroundColor ?? _getBackgroundColor(_currentState!),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                _getStatusIcon(_currentState!),
                color: widget.textColor ?? _getTextColor(_currentState!),
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getStatusText(_currentState!),
                  style: TextStyle(
                    color: widget.textColor ?? _getTextColor(_currentState!),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (_currentState!.isEffectivelyOffline)
                Icon(
                  Icons.info_outline,
                  color: widget.textColor ?? _getTextColor(_currentState!),
                  size: 16,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor(DetailedNetworkState state) {
    if (state.isOfflineModeForced) {
      return Colors.orange.shade100;
    } else if (state.isEffectivelyOffline) {
      return Colors.red.shade100;
    } else if (state.quality == NetworkQuality.poor) {
      return Colors.yellow.shade100;
    } else {
      return Colors.green.shade100;
    }
  }

  Color _getTextColor(DetailedNetworkState state) {
    if (state.isOfflineModeForced) {
      return Colors.orange.shade800;
    } else if (state.isEffectivelyOffline) {
      return Colors.red.shade800;
    } else if (state.quality == NetworkQuality.poor) {
      return Colors.yellow.shade800;
    } else {
      return Colors.green.shade800;
    }
  }

  IconData _getStatusIcon(DetailedNetworkState state) {
    if (state.isOfflineModeForced) {
      return Icons.cloud_off;
    } else if (!state.isConnected) {
      return Icons.signal_wifi_off;
    } else if (!state.hasInternet) {
      return Icons.signal_wifi_connected_no_internet_4;
    } else {
      switch (state.quality) {
        case NetworkQuality.excellent:
          return Icons.signal_wifi_4_bar;
        case NetworkQuality.good:
          return Icons.signal_wifi_4_bar;
        case NetworkQuality.fair:
          return Icons.wifi;
        case NetworkQuality.poor:
          return Icons.signal_wifi_statusbar_null;
        case NetworkQuality.none:
          return Icons.signal_wifi_off;
      }
    }
  }

  String _getStatusText(DetailedNetworkState state) {
    if (state.isOfflineModeForced) {
      return '오프라인 모드 활성화됨';
    } else if (!state.isConnected) {
      return '인터넷 연결 없음';
    } else if (!state.hasInternet) {
      return '제한된 연결';
    } else {
      switch (state.quality) {
        case NetworkQuality.excellent:
          return '우수한 연결 (${state.latency}ms)';
        case NetworkQuality.good:
          return '양호한 연결 (${state.latency}ms)';
        case NetworkQuality.fair:
          return '보통 연결 (${state.latency}ms)';
        case NetworkQuality.poor:
          return '느린 연결 (${state.latency}ms)';
        case NetworkQuality.none:
          return '연결 없음';
      }
    }
  }

  void _showNetworkDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => NetworkDetailsBottomSheet(
        networkState: _currentState!,
      ),
    );
  }
}

/// 네트워크 상세 정보를 표시하는 바텀 시트
class NetworkDetailsBottomSheet extends StatelessWidget {
  final DetailedNetworkState networkState;

  const NetworkDetailsBottomSheet({
    super.key,
    required this.networkState,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.network_check,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                '네트워크 상태',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          _buildDetailRow('상태', networkState.statusDescription),
          _buildDetailRow('연결 타입', _getConnectionTypeText()),
          if (networkState.latency != null)
            _buildDetailRow('지연시간', '${networkState.latency}ms'),
          _buildDetailRow('품질', networkState.quality.name),
          _buildDetailRow('마지막 확인', _formatTimestamp()),
          
          const SizedBox(height: 24),
          
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    NetworkStateManager.instance.refreshNetworkState();
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('새로고침'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    _toggleOfflineMode(context);
                  },
                  icon: Icon(networkState.isOfflineModeForced 
                      ? Icons.cloud_queue 
                      : Icons.cloud_off),
                  label: Text(networkState.isOfflineModeForced 
                      ? '온라인 모드' 
                      : '오프라인 모드'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  String _getConnectionTypeText() {
    if (networkState.connectionTypes.isEmpty) {
      return '없음';
    }
    
    return networkState.connectionTypes
        .map((type) => _getConnectionTypeName(type))
        .join(', ');
  }

  String _getConnectionTypeName(ConnectivityResult type) {
    switch (type) {
      case ConnectivityResult.wifi:
        return 'Wi-Fi';
      case ConnectivityResult.mobile:
        return '모바일 데이터';
      case ConnectivityResult.ethernet:
        return '이더넷';
      case ConnectivityResult.bluetooth:
        return '블루투스';
      case ConnectivityResult.vpn:
        return 'VPN';
      case ConnectivityResult.other:
        return '기타';
      case ConnectivityResult.none:
        return '없음';
      }
  }

  String _formatTimestamp() {
    final now = DateTime.now();
    final diff = now.difference(networkState.timestamp);
    
    if (diff.inSeconds < 60) {
      return '방금 전';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}분 전';
    } else {
      return '${diff.inHours}시간 전';
    }
  }

  void _toggleOfflineMode(BuildContext context) {
    final newMode = !networkState.isOfflineModeForced;
    NetworkStateManager.instance.setOfflineMode(newMode);
    Navigator.of(context).pop();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(newMode 
            ? '오프라인 모드가 활성화되었습니다' 
            : '온라인 모드로 전환되었습니다'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
} 
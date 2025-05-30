import 'package:flutter/material.dart';
import 'package:picnic_lib/core/services/conflict_resolution_service.dart';
import 'package:picnic_lib/core/utils/logger.dart';

/// 충돌 해결 대화상자
/// 사용자가 수동으로 데이터 충돌을 해결할 수 있는 UI를 제공합니다.
class ConflictResolutionDialog extends StatefulWidget {
  final ConflictRecord conflictRecord;
  final VoidCallback? onResolved;

  const ConflictResolutionDialog({
    super.key,
    required this.conflictRecord,
    this.onResolved,
  });

  @override
  State<ConflictResolutionDialog> createState() => _ConflictResolutionDialogState();

  /// 충돌 해결 대화상자 표시
  static Future<void> show(
    BuildContext context,
    ConflictRecord conflictRecord, {
    VoidCallback? onResolved,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ConflictResolutionDialog(
        conflictRecord: conflictRecord,
        onResolved: onResolved,
      ),
    );
  }
}

class _ConflictResolutionDialogState extends State<ConflictResolutionDialog> {
  final ConflictResolutionService _conflictService = ConflictResolutionService.instance;
  
  dynamic _selectedValue;
  String _customValue = '';
  final TextEditingController _customController = TextEditingController();
  bool _isResolving = false;
  
  ConflictResolutionOption _selectedOption = ConflictResolutionOption.local;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.conflictRecord.conflict.localValue;
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    
    return AlertDialog(
      title: Row(
        children: [
          Icon(
            Icons.warning,
            color: Colors.orange,
            size: 24,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '데이터 충돌 해결',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildConflictInfo(),
            const SizedBox(height: 24),
            _buildResolutionOptions(),
            if (_selectedOption == ConflictResolutionOption.custom) ...[
              const SizedBox(height: 16),
              _buildCustomValueInput(),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isResolving ? null : () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: _isResolving ? null : _resolveConflict,
          child: _isResolving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('해결'),
        ),
      ],
    );
  }

  Widget _buildConflictInfo() {
    final conflict = widget.conflictRecord.conflict;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '충돌 정보',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('테이블', widget.conflictRecord.tableName),
            _buildInfoRow('레코드 ID', widget.conflictRecord.recordId),
            _buildInfoRow('필드', conflict.fieldName),
            _buildInfoRow('충돌 타입', _getConflictTypeText(conflict.conflictType)),
            _buildInfoRow('발생 시간', _formatDateTime(widget.conflictRecord.createdAt)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResolutionOptions() {
    final conflict = widget.conflictRecord.conflict;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '해결 방법 선택',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        // 로컬 값 선택
        _buildOptionTile(
          option: ConflictResolutionOption.local,
          title: '로컬 값 사용',
          subtitle: '현재 기기의 값을 유지합니다',
          value: conflict.localValue,
        ),
        
        const SizedBox(height: 8),
        
        // 원격 값 선택
        _buildOptionTile(
          option: ConflictResolutionOption.remote,
          title: '원격 값 사용',
          subtitle: '서버의 값으로 덮어씁니다',
          value: conflict.remoteValue,
        ),
        
        // 병합 가능한 경우만 표시
        if (_canMerge(conflict)) ...[
          const SizedBox(height: 8),
          _buildOptionTile(
            option: ConflictResolutionOption.merge,
            title: '병합',
            subtitle: '두 값을 자동으로 병합합니다',
            value: _getMergedValue(conflict),
          ),
        ],
        
        const SizedBox(height: 8),
        
        // 사용자 정의 값
        _buildOptionTile(
          option: ConflictResolutionOption.custom,
          title: '사용자 정의',
          subtitle: '직접 값을 입력합니다',
          value: null,
        ),
      ],
    );
  }

  Widget _buildOptionTile({
    required ConflictResolutionOption option,
    required String title,
    required String subtitle,
    required dynamic value,
  }) {
    return RadioListTile<ConflictResolutionOption>(
      value: option,
      groupValue: _selectedOption,
      onChanged: (value) {
        setState(() {
          _selectedOption = value!;
          if (option != ConflictResolutionOption.custom) {
            _selectedValue = _getOptionValue(option);
          }
        });
      },
      title: Text(title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subtitle),
          if (value != null) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                _formatValue(value),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ],
      ),
      dense: true,
    );
  }

  Widget _buildCustomValueInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '사용자 정의 값',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _customController,
          decoration: const InputDecoration(
            hintText: '새로운 값을 입력하세요',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {
            _customValue = value;
            _selectedValue = _parseCustomValue(value);
          },
          maxLines: null,
        ),
      ],
    );
  }

  dynamic _getOptionValue(ConflictResolutionOption option) {
    final conflict = widget.conflictRecord.conflict;
    
    switch (option) {
      case ConflictResolutionOption.local:
        return conflict.localValue;
      case ConflictResolutionOption.remote:
        return conflict.remoteValue;
      case ConflictResolutionOption.merge:
        return _getMergedValue(conflict);
      case ConflictResolutionOption.custom:
        return _parseCustomValue(_customValue);
    }
  }

  bool _canMerge(FieldConflict conflict) {
    final local = conflict.localValue;
    final remote = conflict.remoteValue;
    
    // 숫자, 문자열, 리스트는 병합 가능
    return (local is num && remote is num) ||
           (local is String && remote is String) ||
           (local is List && remote is List);
  }

  dynamic _getMergedValue(FieldConflict conflict) {
    final local = conflict.localValue;
    final remote = conflict.remoteValue;
    
    if (local is num && remote is num) {
      return local + remote;
    }
    
    if (local is String && remote is String) {
      if (local.isEmpty) return remote;
      if (remote.isEmpty) return local;
      return '$local | $remote';
    }
    
    if (local is List && remote is List) {
      final merged = List.from(local);
      for (final item in remote) {
        if (!merged.contains(item)) {
          merged.add(item);
        }
      }
      return merged;
    }
    
    return remote;
  }

  dynamic _parseCustomValue(String value) {
    if (value.isEmpty) return '';
    
    // 숫자 파싱 시도
    final numValue = num.tryParse(value);
    if (numValue != null) return numValue;
    
    // bool 파싱 시도
    if (value.toLowerCase() == 'true') return true;
    if (value.toLowerCase() == 'false') return false;
    
    // 기본값은 문자열
    return value;
  }

  String _formatValue(dynamic value) {
    if (value == null) return 'null';
    if (value is String) return '"$value"';
    if (value is List) return value.toString();
    return value.toString();
  }

  String _getConflictTypeText(ConflictType type) {
    switch (type) {
      case ConflictType.textConflict:
        return '텍스트 충돌';
      case ConflictType.numericConflict:
        return '숫자 충돌';
      case ConflictType.timestampConflict:
        return '시간 충돌';
      case ConflictType.nullValueConflict:
        return 'null 값 충돌';
      case ConflictType.dataTypeConflict:
        return '데이터 타입 충돌';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
           '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _resolveConflict() async {
    setState(() {
      _isResolving = true;
    });

    try {
      final success = await _conflictService.resolveManualConflict(
        conflictId: widget.conflictRecord.id,
        resolvedValue: _selectedValue,
      );

      if (success) {
        logger.i('Manual conflict resolved: ${widget.conflictRecord.id}');
        
        if (mounted) {
          Navigator.of(context).pop();
          widget.onResolved?.call();
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('충돌이 성공적으로 해결되었습니다.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('충돌 해결에 실패했습니다.');
      }
    } catch (e) {
      logger.e('Error resolving manual conflict', error: e);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('충돌 해결 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResolving = false;
        });
      }
    }
  }
}

/// 충돌 해결 옵션
enum ConflictResolutionOption {
  local,
  remote,
  merge,
  custom,
} 
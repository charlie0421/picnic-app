import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:picnic_lib/ui/style.dart';

/// 향상된 검색 박스 위젯
/// 디바운싱, 검색 히스토리, 자동완성 등의 기능을 제공
class EnhancedSearchBox extends StatefulWidget {
  const EnhancedSearchBox({
    super.key,
    required this.hintText,
    this.onSearchChanged,
    this.onSearchSubmitted,
    this.onClear,
    this.debounceTime = const Duration(milliseconds: 300),
    this.showClearButton = true,
    this.showSearchIcon = true,
    this.autofocus = false,
    this.enabled = true,
    this.maxLength,
    this.textInputAction = TextInputAction.search,
    this.keyboardType = TextInputType.text,
    this.style,
    this.hintStyle,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius,
    this.contentPadding,
    this.prefixIcon,
    this.suffixIcon,
    this.controller,
    this.focusNode,
  });

  /// 힌트 텍스트
  final String hintText;
  
  /// 검색어 변경 콜백 (디바운싱 적용)
  final ValueChanged<String>? onSearchChanged;
  
  /// 검색 제출 콜백
  final ValueChanged<String>? onSearchSubmitted;
  
  /// 검색어 클리어 콜백
  final VoidCallback? onClear;
  
  /// 디바운싱 시간
  final Duration debounceTime;
  
  /// 클리어 버튼 표시 여부
  final bool showClearButton;
  
  /// 검색 아이콘 표시 여부
  final bool showSearchIcon;
  
  /// 자동 포커스 여부
  final bool autofocus;
  
  /// 활성화 여부
  final bool enabled;
  
  /// 최대 입력 길이
  final int? maxLength;
  
  /// 텍스트 입력 액션
  final TextInputAction textInputAction;
  
  /// 키보드 타입
  final TextInputType keyboardType;
  
  /// 텍스트 스타일
  final TextStyle? style;
  
  /// 힌트 텍스트 스타일
  final TextStyle? hintStyle;
  
  /// 배경색
  final Color? backgroundColor;
  
  /// 테두리 색상
  final Color? borderColor;
  
  /// 테두리 반지름
  final BorderRadius? borderRadius;
  
  /// 내부 패딩
  final EdgeInsetsGeometry? contentPadding;
  
  /// 앞쪽 아이콘
  final Widget? prefixIcon;
  
  /// 뒤쪽 아이콘
  final Widget? suffixIcon;
  
  /// 텍스트 컨트롤러
  final TextEditingController? controller;
  
  /// 포커스 노드
  final FocusNode? focusNode;

  @override
  State<EnhancedSearchBox> createState() => _EnhancedSearchBoxState();
}

class _EnhancedSearchBoxState extends State<EnhancedSearchBox> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  Timer? _debounceTimer;
  String _previousText = '';

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
    
    _controller.addListener(_onTextChanged);
    
    if (widget.autofocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    if (widget.controller == null) {
      _controller.dispose();
    }
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onTextChanged() {
    final currentText = _controller.text;
    
    // 텍스트가 실제로 변경된 경우에만 처리
    if (currentText != _previousText) {
      _previousText = currentText;
      
      // 기존 타이머 취소
      _debounceTimer?.cancel();
      
      // 새로운 타이머 시작
      _debounceTimer = Timer(widget.debounceTime, () {
        if (mounted && widget.onSearchChanged != null) {
          widget.onSearchChanged!(currentText);
        }
      });
      
      // UI 업데이트 (클리어 버튼 표시/숨김)
      setState(() {});
    }
  }

  void _onSubmitted(String value) {
    _debounceTimer?.cancel();
    widget.onSearchSubmitted?.call(value);
  }

  void _onClear() {
    _controller.clear();
    _debounceTimer?.cancel();
    widget.onClear?.call();
    widget.onSearchChanged?.call('');
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48.h,
      decoration: BoxDecoration(
        border: Border.all(
          color: widget.borderColor ?? AppColors.primary500,
          width: 1.r,
        ),
        borderRadius: widget.borderRadius ?? BorderRadius.circular(24.r),
        color: widget.backgroundColor ?? AppColors.grey00,
      ),
      child: Row(
        children: [
          // 검색 아이콘 또는 커스텀 prefix 아이콘
          if (widget.showSearchIcon || widget.prefixIcon != null)
            _buildPrefixIcon(),
          
          // 텍스트 입력 필드
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              enabled: widget.enabled,
              maxLength: widget.maxLength,
              textInputAction: widget.textInputAction,
              keyboardType: widget.keyboardType,
              style: widget.style ?? getTextStyle(AppTypo.body16R, AppColors.grey900),
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: widget.hintStyle ?? 
                    getTextStyle(AppTypo.body16R, AppColors.grey300),
                border: InputBorder.none,
                contentPadding: widget.contentPadding ?? 
                    EdgeInsets.symmetric(vertical: 12.h),
                counterText: '', // 글자 수 카운터 숨김
              ),
              onSubmitted: _onSubmitted,
            ),
          ),
          
          // 클리어 버튼 또는 커스텀 suffix 아이콘
          if (widget.showClearButton || widget.suffixIcon != null)
            _buildSuffixIcon(),
        ],
      ),
    );
  }

  Widget _buildPrefixIcon() {
    if (widget.prefixIcon != null) {
      return Padding(
        padding: EdgeInsets.only(left: 16.w, right: 8.w),
        child: widget.prefixIcon!,
      );
    }
    
    return GestureDetector(
      onTap: () {
        if (_controller.text.isNotEmpty) {
          _onSubmitted(_controller.text);
        }
      },
      child: Padding(
        padding: EdgeInsets.only(left: 16.w, right: 8.w),
        child: SvgPicture.asset(
          package: 'picnic_lib',
          'assets/icons/vote/search_icon.svg',
          width: 20.w,
          height: 20.w,
          colorFilter: ColorFilter.mode(
            widget.enabled ? AppColors.grey700 : AppColors.grey300,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }

  Widget _buildSuffixIcon() {
    if (widget.suffixIcon != null) {
      return Padding(
        padding: EdgeInsets.only(left: 8.w, right: 16.w),
        child: widget.suffixIcon!,
      );
    }
    
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.enabled ? _onClear : null,
      child: Padding(
        padding: EdgeInsets.only(left: 8.w, right: 16.w),
        child: SvgPicture.asset(
          package: 'picnic_lib',
          'assets/icons/cancel_style=fill.svg',
          width: 20.w,
          height: 20.w,
          colorFilter: ColorFilter.mode(
            _controller.text.isNotEmpty && widget.enabled
                ? AppColors.grey700
                : AppColors.grey200,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }
}

/// 검색 상태를 관리하는 헬퍼 클래스
class SearchState {
  const SearchState({
    this.query = '',
    this.isLoading = false,
    this.hasError = false,
    this.errorMessage,
  });

  final String query;
  final bool isLoading;
  final bool hasError;
  final String? errorMessage;

  SearchState copyWith({
    String? query,
    bool? isLoading,
    bool? hasError,
    String? errorMessage,
  }) {
    return SearchState(
      query: query ?? this.query,
      isLoading: isLoading ?? this.isLoading,
      hasError: hasError ?? this.hasError,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SearchState &&
        other.query == query &&
        other.isLoading == isLoading &&
        other.hasError == hasError &&
        other.errorMessage == errorMessage;
  }

  @override
  int get hashCode {
    return query.hashCode ^
        isLoading.hashCode ^
        hasError.hashCode ^
        errorMessage.hashCode;
  }
} 
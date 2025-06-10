import 'package:flutter/material.dart';
import 'package:picnic_lib/data/models/vote/artist.dart';
import 'package:picnic_lib/l10n.dart';
import 'package:picnic_lib/ui/style.dart';

/// 아티스트 신청 상태 정보를 담는 클래스
class ArtistApplicationInfo {
  final String artistName;
  final int applicationCount;
  final String applicationStatus;
  final bool isAlreadyInVote;
  final bool isSubmitting;

  const ArtistApplicationInfo({
    required this.artistName,
    required this.applicationCount,
    required this.applicationStatus,
    required this.isAlreadyInVote,
    this.isSubmitting = false,
  });

  ArtistApplicationInfo copyWith({
    String? artistName,
    int? applicationCount,
    String? applicationStatus,
    bool? isAlreadyInVote,
    bool? isSubmitting,
  }) {
    return ArtistApplicationInfo(
      artistName: artistName ?? this.artistName,
      applicationCount: applicationCount ?? this.applicationCount,
      applicationStatus: applicationStatus ?? this.applicationStatus,
      isAlreadyInVote: isAlreadyInVote ?? this.isAlreadyInVote,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

/// 사용자 신청 정보를 담는 클래스
class UserApplicationInfo {
  final String id;
  final String artistName;
  final String? groupName;
  final String status;
  final int applicationCount;
  final ArtistModel? artist;

  const UserApplicationInfo({
    required this.id,
    required this.artistName,
    this.groupName,
    required this.status,
    required this.applicationCount,
    this.artist,
  });
}

/// 투표 신청 상태 유틸리티 클래스
class VoteRequestStatusUtils {
  /// 상태를 한글로 변환
  static String getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return t('vote_item_request_status_pending');
      case 'approved':
        return t('vote_item_request_status_approved');
      case 'rejected':
        return t('vote_item_request_status_rejected');
      case 'in-progress':
        return t('vote_item_request_status_in_progress');
      case 'cancelled':
        return t('vote_item_request_status_cancelled');
      default:
        return t('vote_item_request_status_unknown');
    }
  }

  /// 상태에 따른 색상 설정
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'in-progress':
        return AppColors.primary500;
      case 'cancelled':
        return AppColors.grey400;
      default:
        return AppColors.grey400;
    }
  }

  /// 신청 버튼을 표시할지 결정하는 조건
  static bool shouldShowApplicationButton(String status, bool isAlreadyInVote) {
    // 이미 투표에 등록된 경우
    if (isAlreadyInVote) return false;

    // 거절된 경우는 재신청 가능
    if (status == t('vote_item_request_status_rejected') ||
        status == t('vote_item_request_status_cancelled')) {
      return true;
    }

    // 내가 이미 신청한 경우 (대기중, 승인됨, 진행중)
    if (status == t('vote_item_request_status_pending') ||
        status == t('vote_item_request_status_approved') ||
        status == t('vote_item_request_status_in_progress')) {
      return false;
    }

    // 신청 가능한 경우만 true
    return status == t('vote_item_request_can_apply');
  }
}

/// 아티스트 이름 처리 유틸리티 클래스
class ArtistNameUtils {
  /// 한글/영어 모두 표시하되 사용자 언어에 따라 순서 조정
  static String getDisplayName(Map<String, dynamic> nameJson) {
    if (nameJson.isEmpty) return '';

    final currentLanguage = getLocaleLanguage();
    final koreanName = nameJson['ko'] as String? ?? '';
    final englishName = nameJson['en'] as String? ?? '';

    // 둘 다 없으면 빈 문자열
    if (koreanName.isEmpty && englishName.isEmpty) return '';

    // 하나만 있으면 그것만 반환
    if (koreanName.isEmpty) return englishName;
    if (englishName.isEmpty) return koreanName;

    // 둘 다 있으면 사용자 언어에 따라 순서 결정
    if (currentLanguage == 'ko') {
      // 한국어 사용자: 한글 먼저
      return '$koreanName ($englishName)';
    } else {
      // 한국어 이외 사용자: 영어 먼저
      return '$englishName ($koreanName)';
    }
  }

  /// 숫자에 3자리 콤마 포맷 적용
  static String formatNumber(int number) {
    return number.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
} 
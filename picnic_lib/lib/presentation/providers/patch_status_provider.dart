import 'package:picnic_lib/core/utils/shorebird_utils.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part '../../generated/providers/patch_status_provider.g.dart';

/// Shorebird 패치 상태
enum PatchStatus {
  /// 패치 체크 중
  checking,

  /// 패치 없음 또는 최신 상태
  upToDate,

  /// 패치 다운로드 중
  downloading,

  /// 패치 다운로드 완료 - 재시작 필요
  restartRequired,

  /// 패치 확인 실패
  error,
}

/// 패치 상태 정보
class PatchStatusInfo {
  final PatchStatus status;
  final int? currentPatchNumber;
  final int? nextPatchNumber;
  final String? errorMessage;
  final bool dialogShown; // 다이얼로그가 이미 표시되었는지

  const PatchStatusInfo({
    required this.status,
    this.currentPatchNumber,
    this.nextPatchNumber,
    this.errorMessage,
    this.dialogShown = false,
  });

  PatchStatusInfo copyWith({
    PatchStatus? status,
    int? currentPatchNumber,
    int? nextPatchNumber,
    String? errorMessage,
    bool? dialogShown,
  }) {
    return PatchStatusInfo(
      status: status ?? this.status,
      currentPatchNumber: currentPatchNumber ?? this.currentPatchNumber,
      nextPatchNumber: nextPatchNumber ?? this.nextPatchNumber,
      errorMessage: errorMessage ?? this.errorMessage,
      dialogShown: dialogShown ?? this.dialogShown,
    );
  }

  /// 재시작이 필요한지 여부
  bool get needsRestart => status == PatchStatus.restartRequired;

  /// 다이얼로그를 표시해야 하는지 여부
  bool get shouldShowDialog => needsRestart && !dialogShown;
}

/// 패치 상태 관리 Notifier
@Riverpod(keepAlive: true)
class PatchStatusNotifier extends _$PatchStatusNotifier {
  @override
  PatchStatusInfo build() {
    // Shorebird 콜백 등록
    ShorebirdUtils.setOnPatchStatusChanged(_handlePatchEvent);
    return const PatchStatusInfo(status: PatchStatus.upToDate);
  }

  /// Shorebird 이벤트 핸들러
  void _handlePatchEvent(ShorebirdPatchEvent event) {
    switch (event) {
      case ShorebirdPatchEvent.checking:
        state = state.copyWith(status: PatchStatus.checking);
        break;
      case ShorebirdPatchEvent.downloading:
        state = state.copyWith(status: PatchStatus.downloading);
        break;
      case ShorebirdPatchEvent.downloadCompleted:
      case ShorebirdPatchEvent.restartPending:
        state = state.copyWith(
          status: PatchStatus.restartRequired,
          dialogShown: false, // 새로운 다운로드 완료 시 다이얼로그 표시 허용
        );
        break;
      case ShorebirdPatchEvent.upToDate:
        state = state.copyWith(status: PatchStatus.upToDate);
        break;
      case ShorebirdPatchEvent.error:
        state = state.copyWith(status: PatchStatus.error);
        break;
    }
  }

  /// 패치 상태를 최신으로 설정
  void setUpToDate({int? currentPatchNumber}) {
    state = PatchStatusInfo(
      status: PatchStatus.upToDate,
      currentPatchNumber: currentPatchNumber,
    );
  }

  /// 패치 다운로드 중 상태로 설정
  void setDownloading() {
    state = state.copyWith(status: PatchStatus.downloading);
  }

  /// 패치 다운로드 완료 - 재시작 필요 상태로 설정
  void setRestartRequired({int? nextPatchNumber}) {
    state = PatchStatusInfo(
      status: PatchStatus.restartRequired,
      currentPatchNumber: state.currentPatchNumber,
      nextPatchNumber: nextPatchNumber,
    );
  }

  /// 에러 상태로 설정
  void setError(String message) {
    state = PatchStatusInfo(
      status: PatchStatus.error,
      currentPatchNumber: state.currentPatchNumber,
      errorMessage: message,
    );
  }

  /// 다이얼로그가 표시되었음을 기록 (중복 표시 방지)
  void markDialogShown() {
    state = state.copyWith(dialogShown: true);
  }
}

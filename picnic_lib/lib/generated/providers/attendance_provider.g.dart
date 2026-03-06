// GENERATED CODE - DO NOT MODIFY BY HAND

part of '../../presentation/providers/attendance_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Attendance)
const attendanceProvider = AttendanceProvider._();

final class AttendanceProvider
    extends $AsyncNotifierProvider<Attendance, AttendanceState> {
  const AttendanceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'attendanceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$attendanceHash();

  @$internal
  @override
  Attendance create() => Attendance();
}

String _$attendanceHash() => r'3576c215a2cccd4036ff1dd8795b8f1862a8cae2';

abstract class _$Attendance extends $AsyncNotifier<AttendanceState> {
  FutureOr<AttendanceState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<AttendanceState>, AttendanceState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<AttendanceState>, AttendanceState>,
              AsyncValue<AttendanceState>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

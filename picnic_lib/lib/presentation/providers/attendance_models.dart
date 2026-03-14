/// 출석체크 에러 유형
enum AttendanceErrorType {
  auth,
  network,
  server,
  unknown,
}

class AttendanceException implements Exception {
  final String message;
  final AttendanceErrorType type;

  const AttendanceException(this.message, this.type);

  @override
  String toString() => 'AttendanceException($type): $message';
}

class AttendanceDayStatus {
  final String date;
  final int dayOfWeek;
  final bool checked;
  final bool isToday;
  final bool isFuture;

  const AttendanceDayStatus({
    required this.date,
    required this.dayOfWeek,
    required this.checked,
    required this.isToday,
    required this.isFuture,
  });

  factory AttendanceDayStatus.fromJson(Map<String, dynamic> json) {
    return AttendanceDayStatus(
      date: json['date'] as String,
      dayOfWeek: json['dayOfWeek'] as int,
      checked: json['checked'] as bool,
      isToday: json['isToday'] as bool,
      isFuture: json['isFuture'] as bool,
    );
  }
}

class AttendanceWeeklyStatus {
  final String weekStart;
  final String weekEnd;
  final List<AttendanceDayStatus> days;
  final int checkedCount;
  final int totalRequired;
  final bool isWeeklyBonusEligible;
  final bool isNewUser;

  const AttendanceWeeklyStatus({
    required this.weekStart,
    required this.weekEnd,
    required this.days,
    required this.checkedCount,
    required this.totalRequired,
    required this.isWeeklyBonusEligible,
    required this.isNewUser,
  });

  factory AttendanceWeeklyStatus.fromJson(Map<String, dynamic> json) {
    return AttendanceWeeklyStatus(
      weekStart: json['weekStart'] as String,
      weekEnd: json['weekEnd'] as String,
      days: (json['days'] as List)
          .map((e) => AttendanceDayStatus.fromJson(e as Map<String, dynamic>))
          .toList(),
      checkedCount: json['checkedCount'] as int,
      totalRequired: json['totalRequired'] as int,
      isWeeklyBonusEligible: json['isWeeklyBonusEligible'] as bool,
      isNewUser: json['isNewUser'] as bool,
    );
  }
}

class AttendanceState {
  final AttendanceWeeklyStatus? weeklyStatus;
  final bool todayChecked;
  final String? serverTimeKST;
  final String? deadlineKST;

  const AttendanceState({
    this.weeklyStatus,
    this.todayChecked = false,
    this.serverTimeKST,
    this.deadlineKST,
  });
}

class AttendanceCheckResult {
  final int rewardAmount;
  final int weeklyBonusAmount;
  final int totalReward;

  const AttendanceCheckResult({
    required this.rewardAmount,
    required this.weeklyBonusAmount,
    required this.totalReward,
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:picnic_lib/presentation/dialogs/attendance_dialog.dart';
import 'package:picnic_lib/presentation/dialogs/require_login_dialog.dart';
import 'package:picnic_lib/presentation/providers/attendance_provider.dart';
import 'package:picnic_lib/supabase_options.dart';
import 'package:picnic_lib/ui/style.dart';

class AttendanceIconButton extends ConsumerWidget {
  const AttendanceIconButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final attendanceAsync = ref.watch(attendanceProvider);
    final todayChecked = attendanceAsync.maybeWhen(
      data: (state) => state.todayChecked,
      orElse: () => true,
    );

    final calendarIcon = SvgPicture.asset(
      package: 'picnic_lib',
      'assets/icons/calendar_style=line.svg',
      width: 22,
      height: 22,
      colorFilter: ColorFilter.mode(AppColors.grey700, BlendMode.srcIn),
    );

    Widget icon;
    if (!todayChecked && isSupabaseLoggedSafely) {
      icon = Stack(
        clipBehavior: Clip.none,
        children: [
          calendarIcon,
          Positioned(
            right: -2,
            top: -2,
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
            ),
          ),
        ],
      );
    } else {
      icon = calendarIcon;
    }

    return SizedBox(
      width: 36,
      height: 36,
      child: IconButton(
        icon: icon,
        onPressed: () {
          if (!isSupabaseLoggedSafely) {
            showRequireLoginDialog();
            return;
          }
          showAttendanceDialog(context);
        },
        tooltip: '출석체크',
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

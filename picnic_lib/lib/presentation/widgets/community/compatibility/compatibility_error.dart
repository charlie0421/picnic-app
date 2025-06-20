import 'package:flutter/material.dart';
import 'package:picnic_lib/ui/style.dart';

class CompatibilityErrorView extends StatelessWidget {
  const CompatibilityErrorView({super.key, required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: AppColors.point900,
          ),
          const SizedBox(height: 16),
          Text(
            error,
            textAlign: TextAlign.center,
            style: getTextStyle(AppTypo.body14M, AppColors.grey900),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

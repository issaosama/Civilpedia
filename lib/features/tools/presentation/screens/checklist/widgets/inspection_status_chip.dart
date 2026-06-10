import 'package:flutter/material.dart';
import '../models/inspection_status.dart';
import '../../../../../../core/theme/app_colors.dart';
import '../../../../../../core/theme/design_tokens.dart';

class InspectionStatusChip extends StatelessWidget {
  final InspectionStatus status;
  final String passLabel;
  final String failLabel;
  final String pendingLabel;

  const InspectionStatusChip({
    super.key,
    required this.status,
    required this.passLabel,
    required this.failLabel,
    required this.pendingLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(DesignTokens.radiusXs),
        border: Border.all(color: _borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 14, color: _iconColor),
          const SizedBox(width: 4),
          Text(
            _label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _textColor,
            ),
          ),
        ],
      ),
    );
  }

  String get _label {
    return switch (status) {
      InspectionStatus.pass => passLabel,
      InspectionStatus.fail => failLabel,
      InspectionStatus.pending => pendingLabel,
    };
  }

  Color get _backgroundColor {
    return switch (status) {
      InspectionStatus.pass => AppColors.success.withValues(alpha: 0.1),
      InspectionStatus.fail => AppColors.error.withValues(alpha: 0.1),
      InspectionStatus.pending => AppColors.textSecondary.withValues(alpha: 0.08),
    };
  }

  Color get _borderColor {
    return switch (status) {
      InspectionStatus.pass => AppColors.success.withValues(alpha: 0.4),
      InspectionStatus.fail => AppColors.error.withValues(alpha: 0.4),
      InspectionStatus.pending => AppColors.textSecondary.withValues(alpha: 0.2),
    };
  }

  Color get _iconColor {
    return switch (status) {
      InspectionStatus.pass => AppColors.success,
      InspectionStatus.fail => AppColors.error,
      InspectionStatus.pending => AppColors.textSecondary,
    };
  }

  Color get _textColor {
    return switch (status) {
      InspectionStatus.pass => AppColors.success,
      InspectionStatus.fail => AppColors.error,
      InspectionStatus.pending => AppColors.textSecondary,
    };
  }

  IconData get _icon {
    return switch (status) {
      InspectionStatus.pass => Icons.check_circle,
      InspectionStatus.fail => Icons.cancel,
      InspectionStatus.pending => Icons.schedule,
    };
  }
}

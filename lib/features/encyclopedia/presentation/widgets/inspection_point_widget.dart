import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/entities/content_block.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/services/language_provider.dart';
import '../../../../localization/ar.dart';
import '../../../../localization/en.dart';

class InspectionPointWidget extends StatelessWidget {
  final InspectionPointBlock block;

  const InspectionPointWidget({super.key, required this.block});

  @override
  Widget build(BuildContext context) {
    final isArabic = context.watch<LanguageProvider>().isArabic;
    String tr(String ar, String en) => isArabic ? ar : en;
    final point = block.point;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEF6C00).withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(DesignTokens.radiusSm),
        border: Border.all(
          color: point.isCritical
              ? AppColors.error.withValues(alpha: 0.4)
              : const Color(0xFFEF6C00).withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  point.criteria,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.5,
                      ),
                ),
              ),
                if (point.isCritical)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(DesignTokens.radiusXs),
                  ),
                  child: Text(
                    tr(Ar.inspectionCritical, En.inspectionCritical),
                    style: TextStyle(
                      color: AppColors.error,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          if (point.acceptableTolerance != null) ...[
            const SizedBox(height: 6),
            _metaRow(context, Icons.straighten, tr(Ar.allowedTolerance, En.allowedTolerance), point.acceptableTolerance!),
          ],
          if (point.method != null) ...[
            const SizedBox(height: 4),
            _metaRow(context, Icons.handyman, tr(Ar.inspectionMethodLabel, En.inspectionMethodLabel), point.method!),
          ],
        ],
      ),
    );
  }

  Widget _metaRow(BuildContext context, IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

/// Consistent section header used across the Home feed.
///
/// Title is positioned at the start (right in RTL, left in LTR), with an
/// optional action label at the end. Horizontal margins match the rest of the
/// Home sections. Title color is theme-aware; callers may supply the action
/// accent required by their surface while the shared default remains Blue.
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? actionColor;
  final bool homeAccent;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
    this.actionColor,
    this.homeAccent = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: AppConstants.paddingMedium,
        vertical: homeAccent ? 2 : 6,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (homeAccent) ...[
            Container(
              width: 3,
              height: 18,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.start,
              overflow: TextOverflow.ellipsis,
              style:
                  theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ) ??
                  const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          if (actionLabel != null)
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: actionColor ?? theme.colorScheme.secondary,
                padding: const EdgeInsetsDirectional.symmetric(horizontal: 8),
                minimumSize: const Size(48, 48),
              ),
              onPressed: onAction,
              child: Text(
                actionLabel!,
                textAlign: TextAlign.start,
                style: const TextStyle(fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}
